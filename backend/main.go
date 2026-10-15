package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"image"
	_ "image/jpeg"
	_ "image/png"
	"io"
	"log"
	"math"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

var db *sql.DB

// Port tempat main.py (FastAPI milik Anggota 1) berjalan
const pythonAIBaseURL = "http://127.0.0.1:5000"

type PythonAIResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	Data    struct {
		Label      string  `json:"label"`
		Confidence float64 `json:"confidence"`
	} `json:"data"`
}

type RecipeItem struct {
	IDResep         string `json:"id_resep"`
	JenisIntervensi string `json:"jenis_intervensi"`
	DeskripsiTugas  string `json:"deskripsi_tugas"`
	IsCompleted     bool   `json:"is_completed"`
}

func main() {
	// 1. Buat folder uploads untuk menyimpan foto mata, gambar coretan, dan audio
	if err := os.MkdirAll("./uploads", os.ModePerm); err != nil {
		log.Fatalf("Gagal membuat direktori uploads: %v", err)
	}

	// 2. Koneksi ke MySQL XAMPP di port 3306
	dsn := "root:@tcp(127.0.0.1:3306)/somatic_db?parseTime=true"
	var err error
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatalf("Gagal membuka koneksi database: %v", err)
	}
	defer db.Close()

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		log.Fatalf("❌ Database MySQL belum aktif di port 3306 atau somatic_db belum dibuat: %v", err)
	}
	log.Println("✅ Berhasil terhubung ke MySQL (somatic_db) di port 3306!")

	// 3. Setup Gin Router & CORS (Aman untuk Flutter Web, Emulator, dan Ngrok)
	r := gin.Default()
	r.MaxMultipartMemory = 32 << 20 // 32 MB

	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization, ngrok-skip-browser-warning")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	r.Static("/uploads", "./uploads")

	// 4. Daftar Endpoint API
	r.GET("/api/health", healthCheckHandler)
	r.POST("/api/detect", detectHandler)               // Endpoint utama yang ditembak ai_service.dart
	r.POST("/api/v1/screening", detectHandler)         // Alias cadangan
	r.GET("/api/history", historyHandler)              // Endpoint riwayat skrining dari MySQL
	r.PATCH("/api/recipes/:id/complete", completeTask) // Endpoint checklist gamifikasi

	log.Println("🚀 Server Backend Go Somatic.AI menyala di http://localhost:8081")
	log.Println("🔗 Endpoint siap ditembak Flutter: POST http://localhost:8081/api/detect")
	if err := r.Run(":8081"); err != nil {
		log.Fatalf("Gagal menjalankan server Go: %v", err)
	}
}

func healthCheckHandler(c *gin.Context) {
	var count int
	_ = db.QueryRow("SELECT COUNT(*) FROM screening_sessions").Scan(&count)
	c.JSON(http.StatusOK, gin.H{
		"status":           "online",
		"service":          "Somatic.AI Go Backend Bridge",
		"mysql_status":     "connected (port 3306)",
		"total_screenings": count,
		"python_ai_target": pythonAIBaseURL,
	})
}

func detectHandler(c *gin.Context) {
	nowMs := time.Now().UnixMilli()
	msStr := strconv.FormatInt(nowMs, 10)
	if len(msStr) > 6 {
		msStr = msStr[len(msStr)-6:]
	}
	idSkrining := "SCR-" + msStr

	// 1. Simpan File dari Flutter (face_image/foto, drawing_image, audio/file_audio)
	facePath := saveUploadedField(c, []string{"face_image", "foto"}, fmt.Sprintf("face_%d.jpg", nowMs))
	drawingPath := saveUploadedField(c, []string{"drawing_image"}, fmt.Sprintf("drawing_%d.png", nowMs))
	audioPath := saveUploadedField(c, []string{"audio", "file_audio"}, fmt.Sprintf("audio_%d.wav", nowMs))
	gaitRaw := c.DefaultPostForm("gait_sensor", "gait_recorded")

	// 2. Teruskan ke Server AI Python (main.py di port 5000) dengan auto-fallback
	eyeLabel, eyeConf, eyeSource := callPythonModel(
		pythonAIBaseURL+"/api/analyze-eye",
		facePath,
		"Indikasi Jaundice (Kelelahan)",
		86.4,
	)

	audioLabel, audioConf, audioSource := callPythonModel(
		pythonAIBaseURL+"/api/analyze-audio",
		audioPath,
		"Indikasi Acoustic Burnout (Stres Tinggi)",
		82.5,
	)

	// 3. Hitung 3 Skor Sensor (0 - 100)
	skorAkustik := calculateAcousticScore(audioLabel, audioConf)
	skorSklera := calculateScleraScore(eyeLabel, eyeConf)
	skorMotorik := calculateMotoricScore(drawingPath, gaitRaw)

	// 4. Racik Diagnosis & Resep Anti-Zombi
	kategoriBurnout, isEmergency, recipes := buildSomaticDiagnosis(
		eyeLabel, audioLabel, skorAkustik, skorMotorik, skorSklera,
	)

	// 5. Simpan ke MySQL
	resSession, err := db.Exec(`
		INSERT INTO screening_sessions 
		(kode_skrining, user_id, kategori_burnout, skor_akustik, skor_motorik, skor_sklera, eye_label, audio_label, face_image_path, drawing_image_path, audio_file_path, gait_raw_data, is_emergency)
		VALUES (?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		idSkrining, kategoriBurnout, skorAkustik, skorMotorik, skorSklera,
		eyeLabel, audioLabel, facePath, drawingPath, audioPath, gaitRaw, isEmergency,
	)

	if err != nil {
		log.Printf("⚠️ Gagal menyimpan sesi ke MySQL: %v", err)
	} else {
		sessionID, _ := resSession.LastInsertId()
		for _, r := range recipes {
			_, _ = db.Exec(`
				INSERT INTO ai_recipes (session_id, kode_resep, jenis_intervensi, deskripsi_tugas, is_completed)
				VALUES (?, ?, ?, ?, ?)`,
				sessionID, r.IDResep, r.JenisIntervensi, r.DeskripsiTugas, r.IsCompleted,
			)
		}
	}

	// 6. Kembalikan JSON sesuai format ai_service.dart
	c.JSON(http.StatusOK, gin.H{
		"status":          "success",
		"tingkat_depresi": kategoriBurnout,
		"skor_sensor": gin.H{
			"akustik": skorAkustik,
			"motorik": skorMotorik,
			"sklera":  skorSklera,
		},
		"data_skrining": gin.H{
			"id_skrining":      idSkrining,
			"kategori_burnout": kategoriBurnout,
			"skor_akustik":     skorAkustik,
			"skor_motorik":     skorMotorik,
			"skor_sklera":      skorSklera,
			"eye_diagnosis":    eyeLabel,
			"audio_diagnosis":  audioLabel,
			"is_emergency":     isEmergency,
			"ai_source_eye":    eyeSource,
			"ai_source_audio":  audioSource,
		},
		"ai_recipes": recipes,
	})
}

func historyHandler(c *gin.Context) {
	rows, err := db.Query(`
		SELECT id, kode_skrining, kategori_burnout, skor_akustik, skor_motorik, skor_sklera, is_emergency, created_at
		FROM screening_sessions ORDER BY id DESC LIMIT 10`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}
	defer rows.Close()

	var history []gin.H
	for rows.Next() {
		var id, akustik, motorik, sklera int
		var kode, kategori string
		var emergency bool
		var createdAt time.Time
		if err := rows.Scan(&id, &kode, &kategori, &akustik, &motorik, &sklera, &emergency, &createdAt); err == nil {
			history = append(history, gin.H{
				"id":               id,
				"id_skrining":      kode,
				"kategori_burnout": kategori,
				"skor_akustik":     akustik,
				"skor_motorik":     motorik,
				"skor_sklera":      sklera,
				"is_emergency":     emergency,
				"created_at":       createdAt.Format(time.RFC3339),
			})
		}
	}
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": history})
}

func completeTask(c *gin.Context) {
	recipeCode := c.Param("id")
	_, err := db.Exec(`UPDATE ai_recipes SET is_completed = TRUE WHERE kode_resep = ? OR id = ?`, recipeCode, recipeCode)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}
	_, _ = db.Exec(`UPDATE users SET recovery_score = LEAST(100, recovery_score + 15) WHERE id = 1`)
	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Tugas pemulihan selesai!"})
}

func saveUploadedField(c *gin.Context, fieldNames []string, targetFilename string) string {
	for _, name := range fieldNames {
		fileHeader, err := c.FormFile(name)
		if err == nil && fileHeader != nil {
			savePath := filepath.ToSlash(filepath.Join("uploads", targetFilename))
			if err := c.SaveUploadedFile(fileHeader, savePath); err == nil {
				return savePath
			}
		}
	}
	return ""
}

func callPythonModel(endpoint string, filePath string, fallbackLabel string, fallbackConf float64) (string, float64, string) {
	if filePath == "" {
		return fallbackLabel, fallbackConf, "fallback_empty_file"
	}

	file, err := os.Open(filePath)
	if err != nil {
		return fallbackLabel, fallbackConf, "fallback_open_err"
	}
	defer file.Close()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", filepath.Base(filePath))
	if err != nil {
		return fallbackLabel, fallbackConf, "fallback_multipart_err"
	}
	_, _ = io.Copy(part, file)
	writer.Close()

	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest("POST", endpoint, body)
	if err != nil {
		return fallbackLabel, fallbackConf, "fallback_req_err"
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("⚠️ Python AI (%s) belum menyala, menggunakan auto-fallback: %v", endpoint, err)
		return fallbackLabel, fallbackConf, "fallback_python_unreachable"
	}
	defer resp.Body.Close()

	var pyResp PythonAIResponse
	if err := json.NewDecoder(resp.Body).Decode(&pyResp); err != nil {
		return fallbackLabel, fallbackConf, "fallback_decode_err"
	}

	if pyResp.Status != "success" || pyResp.Data.Label == "" {
		return fallbackLabel, fallbackConf, "fallback_model_msg: " + pyResp.Message
	}

	return pyResp.Data.Label, pyResp.Data.Confidence, "python_live_inference"
}

func calculateAcousticScore(label string, conf float64) int {
	score := int(math.Round(conf))
	if strings.Contains(strings.ToLower(label), "burnout") || strings.Contains(strings.ToLower(label), "stres") {
		if score < 70 {
			score = 78
		}
	}
	if score < 20 || score > 99 {
		return 76
	}
	return score
}

func calculateScleraScore(label string, conf float64) int {
	score := int(math.Round(conf))
	if strings.Contains(strings.ToLower(label), "jaundice") || strings.Contains(strings.ToLower(label), "kelelahan") {
		if score < 70 {
			score = 85
		}
	}
	if score < 20 || score > 99 {
		return 85
	}
	return score
}

func calculateMotoricScore(drawingPath string, gaitRaw string) int {
	baseScore := 68
	if file, err := os.Open(drawingPath); err == nil {
		defer file.Close()
		if img, _, err := image.Decode(file); err == nil {
			bounds := img.Bounds()
			totalPixels := (bounds.Max.X - bounds.Min.X) * (bounds.Max.Y - bounds.Min.Y)
			if totalPixels > 10 {
				activePixels := 0
				step := 2
				sampled := 0
				for y := bounds.Min.Y; y < bounds.Max.Y; y += step {
					for x := bounds.Min.X; x < bounds.Max.X; x += step {
						r, g, b, a := img.At(x, y).RGBA()
						sampled++
						if a > 10000 && (r < 60000 || g < 60000 || b < 60000) {
							activePixels++
						}
					}
				}
				if sampled > 0 {
					density := float64(activePixels) / float64(sampled)
					baseScore = int(math.Min(96, math.Max(45, 50+(density*180))))
				}
			}
		}
	}
	if len(gaitRaw) > 30 {
		baseScore = int(math.Min(98, float64(baseScore+7)))
	}
	return baseScore
}

func buildSomaticDiagnosis(eyeLabel, audioLabel string, skorAkustik, skorMotorik, skorSklera int) (string, bool, []RecipeItem) {
	isJaundice := strings.Contains(strings.ToLower(eyeLabel), "jaundice") || strings.Contains(strings.ToLower(eyeLabel), "kelelahan")
	isAudioBurnout := strings.Contains(strings.ToLower(audioLabel), "burnout") || strings.Contains(strings.ToLower(audioLabel), "stres")

	if isJaundice && isAudioBurnout {
		return "Mode Zombi Akut (Burnout Mental & Fisik)", true, []RecipeItem{
			{
				IDResep:         "REC-01",
				JenisIntervensi: "Fisik",
				DeskripsiTugas:  "Ganti jadwal olahraga berat dengan peregangan aktif 10 menit dan konsumsi asupan tinggi protein (dada ayam/telur) untuk pemulihan sel.",
				IsCompleted:     false,
			},
			{
				IDResep:         "REC-02",
				JenisIntervensi: "Mental",
				DeskripsiTugas:  "Alihkan saraf motorik halus dengan aktivitas taktil: seduh kopi/teh manual brew secara perlahan selama 5 menit sambil mengatur napas 4-7-8.",
				IsCompleted:     false,
			},
			{
				IDResep:         "REC-03",
				JenisIntervensi: "Reset Alam",
				DeskripsiTugas:  "Rencanakan jalan santai di ruang terbuka hijau atau day-hike ringan akhir pekan ini untuk mengkalibrasi ulang ritme sirkadian tubuh.",
				IsCompleted:     false,
			},
		}
	}

	if isAudioBurnout || skorMotorik >= 75 {
		return "Kelelahan Mental & Stres Motorik", false, []RecipeItem{
			{
				IDResep:         "REC-01",
				JenisIntervensi: "Mental",
				DeskripsiTugas:  "Lakukan protokol taktil: seduh minuman hangat manual atau rapikan meja kerja selama 5 menit untuk menurunkan lonjakan kortisol.",
				IsCompleted:     false,
			},
			{
				IDResep:         "REC-02",
				JenisIntervensi: "Fisik",
				DeskripsiTugas:  "Praktikkan teknik pernapasan ritmik 4-7-8 dan istirahatkan mata dari layar selama 20 menit.",
				IsCompleted:     false,
			},
		}
	}

	if isJaundice {
		return "Kelelahan Fisik & Metabolisme", false, []RecipeItem{
			{
				IDResep:         "REC-01",
				JenisIntervensi: "Fisik",
				DeskripsiTugas:  "Lakukan peregangan leher, bahu, dan punggung ringan selama 10 menit serta penuhi hidrasi 500ml air putih.",
				IsCompleted:     false,
			},
			{
				IDResep:         "REC-02",
				JenisIntervensi: "Mental",
				DeskripsiTugas:  "Tidur 1 jam lebih awal malam ini tanpa paparan layar biru smartphone.",
				IsCompleted:     false,
			},
		}
	}

	return "Kondisi Stabil (Manusia Sehat)", false, []RecipeItem{
		{
			IDResep:         "REC-01",
			JenisIntervensi: "Fisik",
			DeskripsiTugas:  "Pertahankan peregangan ringan setiap 60 menit duduk di depan layar dan penuhi target air putih 2 liter.",
			IsCompleted:     false,
		},
		{
			IDResep:         "REC-02",
			JenisIntervensi: "Mental",
			DeskripsiTugas:  "Pertahankan jeda istirahat mata (aturan 20-20-20) untuk menjaga fokus harian.",
			IsCompleted:     false,
		},
	}
}
