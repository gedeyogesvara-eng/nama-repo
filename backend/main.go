package main

import (
	"bytes"
	"database/sql"
	_ "embed"
	"encoding/json"
	"errors"
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
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/go-sql-driver/mysql"
	"golang.org/x/crypto/bcrypt"
)

// schema.sql di-embed ke dalam binary dan dijalankan otomatis saat server menyala.
//
//go:embed schema.sql
var schemaSQL string

var (
	db     *sql.DB
	dbName = envOr("DB_NAME", "somatic_db")

	// Port tempat server AI Python (FIle AI/Mata-Suara/main.py, FastAPI) berjalan
	pythonAIBaseURL = envOr("PYTHON_AI_URL", "http://127.0.0.1:5000")

	emailRegex = regexp.MustCompile(`^[^@\s]+@[^@\s]+\.[^@\s]+$`)
)

// Akun demo agar juri/penguji dapat langsung login (dibuat otomatis jika belum ada).
var demoAccounts = []struct{ Name, Email, Password string }{
	{"maul", "maul@gmail.com", "password123"},
	{"Budi Santoso", "user.lorem@gmail.com", "password123"},
}

const googleDemoEmail = "maul.google@gmail.com"

type PythonAIResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	Data    struct {
		Label      string  `json:"label"`
		Confidence float64 `json:"confidence"`
	} `json:"data"`
}

type PythonMultimodalResponse struct {
	Status           string  `json:"status"`
	Message          string  `json:"message"`
	KategoriBurnout  string  `json:"kategori_burnout"`
	IsEmergency      bool    `json:"is_emergency"`
	DiagnosisSummary string  `json:"diagnosis_summary"`
	SkorRataRata     float64 `json:"skor_rata_rata"`
	SkorAkustik      int     `json:"skor_akustik"`
	SkorSklera       int     `json:"skor_sklera"`
	SkorMotorik      int     `json:"skor_motorik"`
	Scores           struct {
		VisualScore float64 `json:"visual_score"`
		VoiceScore  float64 `json:"voice_score"`
		SketchScore float64 `json:"sketch_score"`
		GaitScore   float64 `json:"gait_score"`
	} `json:"scores"`
	Labels struct {
		VisualLabel string `json:"visual_label"`
		VoiceLabel  string `json:"voice_label"`
		SketchLabel string `json:"sketch_label"`
		GaitLabel   string `json:"gait_label"`
	} `json:"labels"`
	Resep []struct {
		IDResep         string `json:"id_resep"`
		JenisIntervensi string `json:"jenis_intervensi"`
		DeskripsiTugas  string `json:"deskripsi_tugas"`
	} `json:"resep"`
}

type RecipeItem struct {
	ID              int64  `json:"id"` // primary key ai_recipes (dipakai PATCH /api/recipes/:id/complete)
	IDResep         string `json:"id_resep"`
	JenisIntervensi string `json:"jenis_intervensi"`
	DeskripsiTugas  string `json:"deskripsi_tugas"`
	IsCompleted     bool   `json:"is_completed"`
}

func envOr(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func main() {
	// 1. Folder uploads untuk menyimpan foto mata, gambar coretan, dan audio
	if err := os.MkdirAll("./uploads", os.ModePerm); err != nil {
		log.Fatalf("Gagal membuat direktori uploads: %v", err)
	}

	// 2. Koneksi + migrasi otomatis MySQL XAMPP (default port 3307)
	if err := connectAndMigrate(); err != nil {
		log.Fatalf("❌ Gagal menyiapkan database MySQL: %v", err)
	}
	defer db.Close()
	log.Printf("✅ MySQL siap (%s) - tabel users, screening_sessions, ai_recipes termigrasi!", dbName)

	// 3. Gin Router & CORS (aman untuk Flutter Web, Emulator, dan Ngrok)
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

	// 4. Daftar Endpoint API
	r.GET("/api/health", healthCheckHandler)

	// Autentikasi (tersimpan nyata di tabel users MySQL)
	r.POST("/api/register", registerHandler)
	r.POST("/api/login", loginHandler)
	r.POST("/api/login/google-demo", googleDemoLoginHandler)
	r.POST("/api/forgot-password", forgotPasswordHandler)
	r.GET("/api/users/:id/profile", profileHandler)

	// Skrining
	r.POST("/api/detect", detectHandler)       // Endpoint utama yang ditembak ai_service.dart
	r.POST("/api/v1/screening", detectHandler) // Alias cadangan
	r.GET("/api/history", historyHandler)      // Riwayat skrining milik user_id dari MySQL
	r.PATCH("/api/recipes/:id/complete", completeTask)

	port := envOr("PORT", "8081")
	log.Printf("🚀 Server Backend Go Somatic.AI menyala di http://localhost:%s", port)
	log.Printf("🔗 Auth: POST /api/register, /api/login | Skrining: POST /api/detect | AI Python: %s", pythonAIBaseURL)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Gagal menjalankan server Go: %v", err)
	}
}

// ============================================================================
// DATABASE: KONEKSI & MIGRASI OTOMATIS
// ============================================================================

func connectAndMigrate() error {
	host := envOr("DB_HOST", "127.0.0.1")
	port := envOr("DB_PORT", "3307")
	user := envOr("DB_USER", "root")
	pass := os.Getenv("DB_PASS")

	// a) Koneksi tanpa database untuk menjalankan schema.sql (CREATE DATABASE + CREATE TABLE + seed)
	adminDSN := fmt.Sprintf("%s:%s@tcp(%s:%s)/?parseTime=true&multiStatements=true&charset=utf8mb4",
		user, pass, host, port)
	admin, err := sql.Open("mysql", adminDSN)
	if err != nil {
		return fmt.Errorf("membuka koneksi admin: %w", err)
	}
	defer admin.Close()

	var pingErr error
	for attempt := 1; attempt <= 5; attempt++ {
		if pingErr = admin.Ping(); pingErr == nil {
			break
		}
		log.Printf("⏳ MySQL belum merespons di %s:%s (percobaan %d/5): %v", host, port, attempt, pingErr)
		time.Sleep(2 * time.Second)
	}
	if pingErr != nil {
		return fmt.Errorf("MySQL tidak aktif di %s:%s - nyalakan MySQL di XAMPP: %w", host, port, pingErr)
	}

	if _, err := admin.Exec(schemaSQL); err != nil {
		return fmt.Errorf("menjalankan schema.sql: %w", err)
	}

	// b) Koneksi aplikasi ke somatic_db
	appDSN := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&charset=utf8mb4", user, pass, host, port, dbName)
	db, err = sql.Open("mysql", appDSN)
	if err != nil {
		return fmt.Errorf("membuka koneksi %s: %w", dbName, err)
	}
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)
	if err := db.Ping(); err != nil {
		return fmt.Errorf("ping %s: %w", dbName, err)
	}

	// c) Migrasi kolom untuk tabel users versi lama (tanpa email/password_hash)
	if !columnExists("users", "email") {
		if _, err := db.Exec(`ALTER TABLE users ADD COLUMN email VARCHAR(190) NULL UNIQUE AFTER full_name`); err != nil {
			return fmt.Errorf("menambah kolom users.email: %w", err)
		}
		log.Println("🛠️  Migrasi: kolom users.email ditambahkan")
	}
	if !columnExists("users", "password_hash") {
		if _, err := db.Exec(`ALTER TABLE users ADD COLUMN password_hash VARCHAR(255) NULL AFTER email`); err != nil {
			return fmt.Errorf("menambah kolom users.password_hash: %w", err)
		}
		log.Println("🛠️  Migrasi: kolom users.password_hash ditambahkan")
	}

	// c2) Migrasi kolom 4 skor terpisah dan kesimpulan dinamis untuk screening_sessions
	screeningCols := []struct{ name, colType string }{
		{"visual_score", "INT NOT NULL DEFAULT 0 AFTER skor_sklera"},
		{"voice_score", "INT NOT NULL DEFAULT 0 AFTER visual_score"},
		{"sketch_score", "INT NOT NULL DEFAULT 0 AFTER voice_score"},
		{"gait_score", "INT NOT NULL DEFAULT 0 AFTER sketch_score"},
		{"sketch_label", "VARCHAR(100) NULL AFTER audio_label"},
		{"gait_label", "VARCHAR(100) NULL AFTER sketch_label"},
		{"diagnosis_summary", "TEXT NULL AFTER is_emergency"},
	}
	for _, col := range screeningCols {
		if !columnExists("screening_sessions", col.name) {
			if _, err := db.Exec(fmt.Sprintf("ALTER TABLE screening_sessions ADD COLUMN %s %s", col.name, col.colType)); err == nil {
				log.Printf("🛠️  Migrasi: kolom screening_sessions.%s ditambahkan", col.name)
			}
		}
	}

	// d) Akun demo
	seedDemoAccounts()
	return nil
}

func columnExists(table, column string) bool {
	var n int
	_ = db.QueryRow(`SELECT COUNT(*) FROM information_schema.COLUMNS
		WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?`, dbName, table, column).Scan(&n)
	return n > 0
}

func seedDemoAccounts() {
	for _, acc := range demoAccounts {
		var id int
		err := db.QueryRow(`SELECT id FROM users WHERE email = ?`, acc.Email).Scan(&id)
		if err == nil {
			continue
		}
		hash, herr := bcrypt.GenerateFromPassword([]byte(acc.Password), bcrypt.DefaultCost)
		if herr != nil {
			continue
		}
		if _, ierr := db.Exec(`INSERT INTO users (full_name, email, password_hash) VALUES (?, ?, ?)`,
			acc.Name, acc.Email, string(hash)); ierr != nil {
			log.Printf("⚠️ Gagal membuat akun demo %s: %v", acc.Email, ierr)
		} else {
			log.Printf("👤 Akun demo dibuat: %s / %s", acc.Email, acc.Password)
		}
	}
}

// ============================================================================
// AUTENTIKASI
// ============================================================================

type authRequest struct {
	FullName string `json:"full_name"`
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

type userRecord struct {
	ID            int
	FullName      string
	Email         sql.NullString
	PasswordHash  sql.NullString
	RecoveryScore int
	ZombieStage   string
}

func (u userRecord) payload() gin.H {
	return gin.H{
		"user_id":        u.ID,
		"full_name":      u.FullName,
		"email":          u.Email.String,
		"recovery_score": u.RecoveryScore,
		"zombie_stage":   u.ZombieStage,
	}
}

func authError(c *gin.Context, status int, message string) {
	c.JSON(status, gin.H{"status": "error", "message": message})
}

func findUserByEmail(email string) (userRecord, error) {
	var u userRecord
	err := db.QueryRow(`SELECT id, full_name, email, password_hash, recovery_score, zombie_stage
		FROM users WHERE email = ?`, email).
		Scan(&u.ID, &u.FullName, &u.Email, &u.PasswordHash, &u.RecoveryScore, &u.ZombieStage)
	return u, err
}

func findUserByID(id int) (userRecord, error) {
	var u userRecord
	err := db.QueryRow(`SELECT id, full_name, email, password_hash, recovery_score, zombie_stage
		FROM users WHERE id = ?`, id).
		Scan(&u.ID, &u.FullName, &u.Email, &u.PasswordHash, &u.RecoveryScore, &u.ZombieStage)
	return u, err
}

func registerHandler(c *gin.Context) {
	var req authRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		authError(c, http.StatusBadRequest, "Data pendaftaran tidak valid.")
		return
	}

	email := strings.ToLower(strings.TrimSpace(req.Email))
	if !emailRegex.MatchString(email) {
		authError(c, http.StatusBadRequest, "Format alamat email tidak valid.")
		return
	}
	if len(req.Password) < 6 {
		authError(c, http.StatusBadRequest, "Kata sandi terlalu lemah. Gunakan minimal 6 karakter.")
		return
	}
	if len(req.Password) > 72 {
		authError(c, http.StatusBadRequest, "Kata sandi maksimal 72 karakter.")
		return
	}

	fullName := strings.TrimSpace(req.FullName)
	if fullName == "" {
		fullName = strings.TrimSpace(req.Name)
	}
	if fullName == "" {
		fullName = strings.Split(email, "@")[0]
	}
	if len([]rune(fullName)) > 100 {
		fullName = string([]rune(fullName)[:100])
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		authError(c, http.StatusInternalServerError, "Gagal mengamankan kata sandi.")
		return
	}

	res, err := db.Exec(`INSERT INTO users (full_name, email, password_hash) VALUES (?, ?, ?)`,
		fullName, email, string(hash))
	if err != nil {
		var myErr *mysql.MySQLError
		if errors.As(err, &myErr) && myErr.Number == 1062 {
			authError(c, http.StatusConflict, "Email ini sudah terdaftar. Silakan login ke akun Anda.")
			return
		}
		log.Printf("⚠️ Register gagal: %v", err)
		authError(c, http.StatusInternalServerError, "Gagal menyimpan akun ke database.")
		return
	}

	id, _ := res.LastInsertId()
	user, err := findUserByID(int(id))
	if err != nil {
		authError(c, http.StatusInternalServerError, "Akun tersimpan tetapi gagal dibaca ulang.")
		return
	}
	log.Printf("👤 Registrasi berhasil: user_id=%d email=%s", user.ID, email)
	c.JSON(http.StatusCreated, gin.H{
		"status":    "success",
		"message":   "Registrasi berhasil.",
		"user_id":   user.ID,
		"full_name": user.FullName,
		"user":      user.payload(),
	})
}

func loginHandler(c *gin.Context) {
	var req authRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		authError(c, http.StatusBadRequest, "Data login tidak valid.")
		return
	}
	email := strings.ToLower(strings.TrimSpace(req.Email))
	if !emailRegex.MatchString(email) {
		authError(c, http.StatusBadRequest, "Format alamat email tidak valid.")
		return
	}

	const invalidMsg = "Email atau kata sandi tidak sesuai."
	user, err := findUserByEmail(email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			authError(c, http.StatusUnauthorized, invalidMsg)
			return
		}
		log.Printf("⚠️ Login query gagal: %v", err)
		authError(c, http.StatusInternalServerError, "Gagal membaca database.")
		return
	}
	if !user.PasswordHash.Valid ||
		bcrypt.CompareHashAndPassword([]byte(user.PasswordHash.String), []byte(req.Password)) != nil {
		authError(c, http.StatusUnauthorized, invalidMsg)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":    "success",
		"message":   "Login berhasil.",
		"user_id":   user.ID,
		"full_name": user.FullName,
		"user":      user.payload(),
	})
}

// googleDemoLoginHandler: pengganti Login Google berbasis Firebase (yang butuh kredensial
// Firebase/Google OAuth). Membuat/mengambil akun demo Google di MySQL tanpa password.
func googleDemoLoginHandler(c *gin.Context) {
	user, err := findUserByEmail(googleDemoEmail)
	if errors.Is(err, sql.ErrNoRows) {
		res, ierr := db.Exec(`INSERT INTO users (full_name, email) VALUES (?, ?)`,
			"Maulana (Google User)", googleDemoEmail)
		if ierr != nil {
			authError(c, http.StatusInternalServerError, "Gagal membuat akun Google demo.")
			return
		}
		id, _ := res.LastInsertId()
		user, err = findUserByID(int(id))
	}
	if err != nil {
		authError(c, http.StatusInternalServerError, "Gagal membaca akun Google demo.")
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status":    "success",
		"message":   "Login Google (mode demo) berhasil.",
		"user_id":   user.ID,
		"full_name": user.FullName,
		"user":      user.payload(),
	})
}

// forgotPasswordHandler: memvalidasi format email dan mengakui permintaan reset.
// Server email (SMTP) belum dikonfigurasi, sehingga tautan reset tidak benar-benar dikirim.
func forgotPasswordHandler(c *gin.Context) {
	var req authRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		authError(c, http.StatusBadRequest, "Data tidak valid.")
		return
	}
	email := strings.ToLower(strings.TrimSpace(req.Email))
	if !emailRegex.MatchString(email) {
		authError(c, http.StatusBadRequest, "Format alamat email tidak valid.")
		return
	}
	log.Printf("📧 Permintaan reset password untuk %s (SMTP belum dikonfigurasi, tidak ada email terkirim)", email)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Jika email terdaftar, instruksi reset kata sandi akan dikirim.",
	})
}

// profileHandler: skor pemulihan & ringkasan skrining terbaru (dipakai Dashboard Flutter).
func profileHandler(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		authError(c, http.StatusBadRequest, "user_id tidak valid.")
		return
	}
	user, err := findUserByID(id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			authError(c, http.StatusNotFound, "Pengguna tidak ditemukan.")
			return
		}
		authError(c, http.StatusInternalServerError, "Gagal membaca database.")
		return
	}

	var total int
	_ = db.QueryRow(`SELECT COUNT(*) FROM screening_sessions WHERE user_id = ?`, id).Scan(&total)

	var doneRecipes, allRecipes int
	_ = db.QueryRow(`SELECT COALESCE(SUM(r.is_completed), 0), COUNT(r.id)
		FROM ai_recipes r JOIN screening_sessions s ON s.id = r.session_id
		WHERE s.user_id = ?`, id).Scan(&doneRecipes, &allRecipes)

	var latest gin.H
	var kode, kategori, eyeLabel, audioLabel, sketchLabel, gaitLabel, diagSummary string
	var akustik, motorik, sklera, visualScore, voiceScore, sketchScore, gaitScore int
	var emergency bool
	var createdAt time.Time
	err = db.QueryRow(`SELECT kode_skrining, kategori_burnout, skor_akustik, skor_motorik, skor_sklera,
		COALESCE(visual_score, skor_sklera), COALESCE(voice_score, skor_akustik),
		COALESCE(sketch_score, skor_motorik), COALESCE(gait_score, skor_motorik),
		eye_label, audio_label, COALESCE(sketch_label, '-'), COALESCE(gait_label, '-'),
		is_emergency, COALESCE(diagnosis_summary, ''), created_at
		FROM screening_sessions WHERE user_id = ? ORDER BY id DESC LIMIT 1`, id).
		Scan(&kode, &kategori, &akustik, &motorik, &sklera, &visualScore, &voiceScore, &sketchScore, &gaitScore,
			&eyeLabel, &audioLabel, &sketchLabel, &gaitLabel, &emergency, &diagSummary, &createdAt)
	if err == nil {
		if visualScore <= 0 {
			visualScore = sklera
		}
		if voiceScore <= 0 {
			voiceScore = akustik
		}
		if sketchScore <= 0 {
			sketchScore = motorik
		}
		if gaitScore <= 0 {
			gaitScore = motorik
		}
		if diagSummary == "" {
			diagSummary = fmt.Sprintf("Mata: %s (%d%%) • Suara: %s (%d%%) • Sketsa: %s (%d%%) • Gait: %s (%d%%)",
				eyeLabel, visualScore, audioLabel, voiceScore, sketchLabel, sketchScore, gaitLabel, gaitScore)
		}
		latest = gin.H{
			"id_skrining":       kode,
			"kategori_burnout":  kategori,
			"skor_akustik":      akustik,
			"skor_motorik":      motorik,
			"skor_sklera":       sklera,
			"visual_score":      visualScore,
			"voice_score":       voiceScore,
			"sketch_score":      sketchScore,
			"gait_score":        gaitScore,
			"eye_label":         eyeLabel,
			"audio_label":       audioLabel,
			"sketch_label":      sketchLabel,
			"gait_label":        gaitLabel,
			"diagnosis_summary": diagSummary,
			"is_emergency":      emergency,
			"created_at":        createdAt.Format(time.RFC3339),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":            "success",
		"user":              user.payload(),
		"total_screenings":  total,
		"recipes_completed": doneRecipes,
		"recipes_total":     allRecipes,
		"latest_screening":  latest,
	})
}

// ============================================================================
// HEALTH CHECK
// ============================================================================

func healthCheckHandler(c *gin.Context) {
	var screenings, users int
	_ = db.QueryRow("SELECT COUNT(*) FROM screening_sessions").Scan(&screenings)
	_ = db.QueryRow("SELECT COUNT(*) FROM users").Scan(&users)

	pyOnline, pyModels := false, false
	client := &http.Client{Timeout: 1500 * time.Millisecond}
	if resp, err := client.Get(pythonAIBaseURL + "/health"); err == nil {
		defer resp.Body.Close()
		var h struct {
			ModelsLoaded bool `json:"models_loaded"`
		}
		if json.NewDecoder(resp.Body).Decode(&h) == nil {
			pyOnline, pyModels = true, h.ModelsLoaded
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":           "online",
		"service":          "Somatic.AI Go Backend Bridge",
		"mysql_status":     "connected",
		"database":         dbName,
		"total_users":      users,
		"total_screenings": screenings,
		"python_ai_target": pythonAIBaseURL,
		"python_ai_online": pyOnline,
		"python_ai_models": pyModels,
	})
}

// ============================================================================
// SKRINING MULTIMODAL
// ============================================================================

// resolveUserID memvalidasi user_id dari Flutter; jika kosong/tidak ada di DB,
// data dicatat atas nama akun tamu (id 1) agar alur skrining tidak pernah macet.
func resolveUserID(raw string) int {
	if id, err := strconv.Atoi(strings.TrimSpace(raw)); err == nil && id > 0 {
		var exists int
		if db.QueryRow(`SELECT id FROM users WHERE id = ?`, id).Scan(&exists) == nil {
			return id
		}
		log.Printf("⚠️ user_id=%d tidak ditemukan di database, memakai akun tamu (id 1)", id)
	}
	return 1
}

func detectHandler(c *gin.Context) {
	nowMs := time.Now().UnixMilli()
	msStr := strconv.FormatInt(nowMs, 10)
	if len(msStr) > 6 {
		msStr = msStr[len(msStr)-6:]
	}
	idSkrining := "SCR-" + msStr
	userID := resolveUserID(c.PostForm("user_id"))

	// 1. Simpan file dari Flutter ke backend/uploads/
	facePath := saveUploadedField(c, []string{"face_image", "foto"}, fmt.Sprintf("face_u%d_%d.jpg", userID, nowMs))
	drawingPath := saveUploadedField(c, []string{"drawing_image"}, fmt.Sprintf("drawing_u%d_%d.png", userID, nowMs))
	audioPath := saveUploadedField(c, []string{"audio", "file_audio"}, fmt.Sprintf("audio_u%d_%d.wav", userID, nowMs))
	gaitRaw := c.DefaultPostForm("gait_sensor", "gait_recorded")

	// 2. Teruskan 4 data multimodal ke server AI Python
	pyResp, aiMode := callPythonMultimodal(facePath, drawingPath, audioPath, gaitRaw)

	visualScore := int(math.Round(pyResp.Scores.VisualScore))
	voiceScore := int(math.Round(pyResp.Scores.VoiceScore))
	sketchScore := int(math.Round(pyResp.Scores.SketchScore))
	gaitScore := int(math.Round(pyResp.Scores.GaitScore))

	if visualScore <= 0 {
		visualScore = 32
	}
	if voiceScore <= 0 {
		voiceScore = 34
	}
	if sketchScore <= 0 {
		sketchScore = 40
	}
	if gaitScore <= 0 {
		gaitScore = 38
	}

	skorSklera := visualScore
	skorAkustik := voiceScore
	skorMotorik := int(math.Round(float64(sketchScore+gaitScore) / 2.0))

	eyeLabel := pyResp.Labels.VisualLabel
	audioLabel := pyResp.Labels.VoiceLabel
	sketchLabel := pyResp.Labels.SketchLabel
	gaitLabel := pyResp.Labels.GaitLabel
	kategoriBurnout := pyResp.KategoriBurnout
	diagnosisSummary := pyResp.DiagnosisSummary
	isEmergency := pyResp.IsEmergency

	if diagnosisSummary == "" {
		diagnosisSummary = fmt.Sprintf("Mata: %s (%d%%) • Suara: %s (%d%%) • Sketsa: %s (%d%%) • Gait: %s (%d%%)",
			eyeLabel, visualScore, audioLabel, voiceScore, sketchLabel, sketchScore, gaitLabel, gaitScore)
	}

	recipes := make([]RecipeItem, 0, len(pyResp.Resep))
	for i, r := range pyResp.Resep {
		recipes = append(recipes, RecipeItem{
			IDResep:         fmt.Sprintf("REC-%02d", i+1),
			JenisIntervensi: r.JenisIntervensi,
			DeskripsiTugas:  r.DeskripsiTugas,
			IsCompleted:     false,
		})
	}
	if len(recipes) == 0 {
		_, _, recipes = buildSomaticDiagnosis(eyeLabel, audioLabel, skorAkustik, skorMotorik, skorSklera)
	}

	// 3. Simpan ke MySQL (sesi + resep dalam satu transaksi)
	var sessionID int64
	saved := false
	if tx, err := db.Begin(); err != nil {
		log.Printf("⚠️ Gagal memulai transaksi MySQL: %v", err)
	} else {
		resSession, err := tx.Exec(`
			INSERT INTO screening_sessions
			(kode_skrining, user_id, kategori_burnout, skor_akustik, skor_motorik, skor_sklera,
			 visual_score, voice_score, sketch_score, gait_score,
			 eye_label, audio_label, sketch_label, gait_label,
			 face_image_path, drawing_image_path, audio_file_path, gait_raw_data,
			 is_emergency, diagnosis_summary)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
			idSkrining, userID, kategoriBurnout, skorAkustik, skorMotorik, skorSklera,
			visualScore, voiceScore, sketchScore, gaitScore,
			eyeLabel, audioLabel, sketchLabel, gaitLabel,
			facePath, drawingPath, audioPath, gaitRaw,
			isEmergency, diagnosisSummary,
		)
		if err != nil {
			log.Printf("⚠️ Gagal menyimpan sesi ke MySQL: %v", err)
			_ = tx.Rollback()
		} else {
			sessionID, _ = resSession.LastInsertId()
			ok := true
			for i := range recipes {
				resRecipe, rerr := tx.Exec(`
					INSERT INTO ai_recipes (session_id, kode_resep, jenis_intervensi, deskripsi_tugas, is_completed)
					VALUES (?, ?, ?, ?, ?)`,
					sessionID, recipes[i].IDResep, recipes[i].JenisIntervensi, recipes[i].DeskripsiTugas, recipes[i].IsCompleted,
				)
				if rerr != nil {
					log.Printf("⚠️ Gagal menyimpan resep ke MySQL: %v", rerr)
					ok = false
					break
				}
				recipes[i].ID, _ = resRecipe.LastInsertId()
			}
			if ok && tx.Commit() == nil {
				saved = true
			} else {
				_ = tx.Rollback()
			}
		}
	}
	log.Printf("🧾 Skrining %s user_id=%d ai_mode=%s visual=%d voice=%d sketch=%d gait=%d saved=%v",
		idSkrining, userID, aiMode, visualScore, voiceScore, sketchScore, gaitScore, saved)

	// 4. Kembalikan JSON sesuai format ai_service.dart
	c.JSON(http.StatusOK, gin.H{
		"status":            "success",
		"tingkat_depresi":   kategoriBurnout,
		"saved":             saved,
		"session_id":        sessionID,
		"user_id":           userID,
		"ai_mode":           aiMode,
		"visual_score":      visualScore,
		"voice_score":       voiceScore,
		"sketch_score":      sketchScore,
		"gait_score":        gaitScore,
		"diagnosis_summary": diagnosisSummary,
		"skor_sensor": gin.H{
			"suara":   voiceScore,
			"visual":  visualScore,
			"sketsa":  sketchScore,
			"gait":    gaitScore,
			"akustik": skorAkustik,
			"motorik": skorMotorik,
			"sklera":  skorSklera,
		},
		"data_skrining": gin.H{
			"id_skrining":       idSkrining,
			"kategori_burnout":  kategoriBurnout,
			"skor_akustik":      skorAkustik,
			"skor_motorik":      skorMotorik,
			"skor_sklera":       skorSklera,
			"visual_score":      visualScore,
			"voice_score":       voiceScore,
			"sketch_score":      sketchScore,
			"gait_score":        gaitScore,
			"eye_diagnosis":     eyeLabel,
			"audio_diagnosis":   audioLabel,
			"eye_label":         eyeLabel,
			"audio_label":       audioLabel,
			"sketch_label":      sketchLabel,
			"gait_label":        gaitLabel,
			"diagnosis_summary": diagnosisSummary,
			"is_emergency":      isEmergency,
			"ai_mode":           aiMode,
			"created_at":        time.Now().Format(time.RFC3339),
		},
		"ai_recipes": recipes,
	})
}

func historyHandler(c *gin.Context) {
	userID := resolveUserID(c.Query("user_id"))

	rows, err := db.Query(`
		SELECT id, kode_skrining, kategori_burnout, skor_akustik, skor_motorik, skor_sklera,
		       COALESCE(visual_score, skor_sklera), COALESCE(voice_score, skor_akustik),
		       COALESCE(sketch_score, skor_motorik), COALESCE(gait_score, skor_motorik),
		       eye_label, audio_label, COALESCE(sketch_label, '-'), COALESCE(gait_label, '-'),
		       is_emergency, COALESCE(diagnosis_summary, ''), created_at
		FROM screening_sessions WHERE user_id = ? ORDER BY id DESC LIMIT 50`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}
	defer rows.Close()

	history := make([]gin.H, 0)
	sessionIndex := map[int]int{} // session id -> index pada history
	for rows.Next() {
		var id, akustik, motorik, sklera, visualScore, voiceScore, sketchScore, gaitScore int
		var kode, kategori, eyeLabel, audioLabel, sketchLabel, gaitLabel, diagSummary string
		var emergency bool
		var createdAt time.Time
		if err := rows.Scan(&id, &kode, &kategori, &akustik, &motorik, &sklera,
			&visualScore, &voiceScore, &sketchScore, &gaitScore,
			&eyeLabel, &audioLabel, &sketchLabel, &gaitLabel,
			&emergency, &diagSummary, &createdAt); err != nil {
			continue
		}
		if visualScore <= 0 {
			visualScore = sklera
		}
		if voiceScore <= 0 {
			voiceScore = akustik
		}
		if sketchScore <= 0 {
			sketchScore = motorik
		}
		if gaitScore <= 0 {
			gaitScore = motorik
		}
		if diagSummary == "" {
			diagSummary = fmt.Sprintf("Mata: %s (%d%%) • Suara: %s (%d%%) • Sketsa: %s (%d%%) • Gait: %s (%d%%)",
				eyeLabel, visualScore, audioLabel, voiceScore, sketchLabel, sketchScore, gaitLabel, gaitScore)
		}
		sessionIndex[id] = len(history)
		history = append(history, gin.H{
			"id":                id,
			"id_skrining":       kode,
			"kategori_burnout":  kategori,
			"skor_akustik":      akustik,
			"skor_motorik":      motorik,
			"skor_sklera":       sklera,
			"visual_score":      visualScore,
			"voice_score":       voiceScore,
			"sketch_score":      sketchScore,
			"gait_score":        gaitScore,
			"eye_label":         eyeLabel,
			"audio_label":       audioLabel,
			"sketch_label":      sketchLabel,
			"gait_label":        gaitLabel,
			"diagnosis_summary": diagSummary,
			"is_emergency":      emergency,
			"created_at":        createdAt.Format(time.RFC3339),
			"ai_recipes":        []gin.H{},
		})
	}

	if len(sessionIndex) > 0 {
		recipeRows, err := db.Query(`
			SELECT r.id, r.session_id, r.kode_resep, r.jenis_intervensi, r.deskripsi_tugas, r.is_completed
			FROM ai_recipes r JOIN screening_sessions s ON s.id = r.session_id
			WHERE s.user_id = ? ORDER BY r.id ASC`, userID)
		if err == nil {
			defer recipeRows.Close()
			for recipeRows.Next() {
				var id, sessionID int
				var kode, jenis, deskripsi string
				var done bool
				if recipeRows.Scan(&id, &sessionID, &kode, &jenis, &deskripsi, &done) != nil {
					continue
				}
				if idx, ok := sessionIndex[sessionID]; ok {
					list := history[idx]["ai_recipes"].([]gin.H)
					history[idx]["ai_recipes"] = append(list, gin.H{
						"id":               id,
						"id_resep":         kode,
						"jenis_intervensi": jenis,
						"deskripsi_tugas":  deskripsi,
						"is_completed":     done,
					})
				}
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "user_id": userID, "data": history})
}

func recoveryStage(score int) string {
	switch {
	case score < 30:
		return "CRITICAL_ZOMBIE"
	case score < 60:
		return "TIRED_ZOMBIE"
	case score < 80:
		return "RECOVERING_HUMAN"
	default:
		return "HEALTHY_HUMAN"
	}
}

// completeTask menandai / membatalkan resep (id = primary key ai_recipes) dan
// memperbarui skor pemulihan milik pemilik sesi skrining tersebut (+15 / -15).
func completeTask(c *gin.Context) {
	recipeID, err := strconv.Atoi(c.Param("id"))
	if err != nil || recipeID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "id resep tidak valid"})
		return
	}

	desired := true
	var body struct {
		IsCompleted *bool `json:"is_completed"`
	}
	if c.Request.ContentLength != 0 {
		_ = c.ShouldBindJSON(&body)
	}
	if body.IsCompleted != nil {
		desired = *body.IsCompleted
	}

	tx, err := db.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}
	defer tx.Rollback() //nolint:errcheck

	var current bool
	var userID, score int
	err = tx.QueryRow(`
		SELECT r.is_completed, s.user_id, u.recovery_score
		FROM ai_recipes r
		JOIN screening_sessions s ON s.id = r.session_id
		JOIN users u ON u.id = s.user_id
		WHERE r.id = ? FOR UPDATE`, recipeID).Scan(&current, &userID, &score)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "resep tidak ditemukan"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if current != desired {
		if _, err := tx.Exec(`UPDATE ai_recipes SET is_completed = ? WHERE id = ?`, desired, recipeID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
			return
		}
		delta := 15
		if !desired {
			delta = -15
		}
		score = max(0, min(100, score+delta))
		if _, err := tx.Exec(`UPDATE users SET recovery_score = ?, zombie_stage = ? WHERE id = ?`,
			score, recoveryStage(score), userID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
			return
		}
	}

	if err := tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	msg := "Tugas pemulihan selesai!"
	if !desired {
		msg = "Tugas pemulihan dikembalikan ke belum selesai."
	}
	c.JSON(http.StatusOK, gin.H{
		"status":         "success",
		"message":        msg,
		"recipe_id":      recipeID,
		"is_completed":   desired,
		"user_id":        userID,
		"recovery_score": score,
		"zombie_stage":   recoveryStage(score),
	})
}

func saveUploadedField(c *gin.Context, fieldNames []string, targetFilename string) string {
	for _, name := range fieldNames {
		fileHeader, err := c.FormFile(name)
		if err == nil && fileHeader != nil && fileHeader.Size > 0 {
			savePath := filepath.ToSlash(filepath.Join("uploads", targetFilename))
			if err := c.SaveUploadedFile(fileHeader, savePath); err == nil {
				return savePath
			}
		}
	}
	return ""
}

func callPythonMultimodal(facePath, drawingPath, audioPath, gaitRaw string) (PythonMultimodalResponse, string) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// 1. face_image
	if facePath != "" {
		if f, err := os.Open(facePath); err == nil {
			defer f.Close()
			if part, err := writer.CreateFormFile("face_image", filepath.Base(facePath)); err == nil {
				_, _ = io.Copy(part, f)
			}
		}
	}

	// 2. drawing_image
	if drawingPath != "" {
		if f, err := os.Open(drawingPath); err == nil {
			defer f.Close()
			if part, err := writer.CreateFormFile("drawing_image", filepath.Base(drawingPath)); err == nil {
				_, _ = io.Copy(part, f)
			}
		}
	}

	// 3. audio
	if audioPath != "" {
		if f, err := os.Open(audioPath); err == nil {
			defer f.Close()
			if part, err := writer.CreateFormFile("audio", filepath.Base(audioPath)); err == nil {
				_, _ = io.Copy(part, f)
			}
		}
	}

	// 4. gait_sensor
	if gaitRaw != "" {
		_ = writer.WriteField("gait_sensor", gaitRaw)
	}

	if err := writer.Close(); err != nil {
		log.Printf("⚠️ Gagal menutup multipart writer: %v", err)
	}

	endpoint := pythonAIBaseURL + "/api/analyze-multimodal"
	client := &http.Client{Timeout: 30 * time.Second}
	req, err := http.NewRequest("POST", endpoint, body)
	if err != nil {
		log.Printf("⚠️ Gagal membuat HTTP request ke Python AI: %v", err)
		return fallbackMultimodal(facePath, drawingPath, audioPath, gaitRaw), "fallback_req_err"
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("⚠️ Python AI (%s) tidak dapat dihubungi: %v. Menggunakan pemrosesan Go.", endpoint, err)
		return fallbackMultimodal(facePath, drawingPath, audioPath, gaitRaw), "fallback_python_unreachable"
	}
	defer resp.Body.Close()

	var pyResp PythonMultimodalResponse
	if err := json.NewDecoder(resp.Body).Decode(&pyResp); err != nil {
		log.Printf("⚠️ Gagal membaca JSON dari Python AI: %v", err)
		return fallbackMultimodal(facePath, drawingPath, audioPath, gaitRaw), "fallback_decode_err"
	}

	if pyResp.Status != "success" {
		log.Printf("⚠️ Python AI response status=%s message=%s", pyResp.Status, pyResp.Message)
		return fallbackMultimodal(facePath, drawingPath, audioPath, gaitRaw), "fallback_model_msg: " + pyResp.Message
	}

	log.Printf("✅ Python AI Multimodal sukses: visual=%.1f voice=%.1f sketch=%.1f gait=%.1f kat=%s",
		pyResp.Scores.VisualScore, pyResp.Scores.VoiceScore, pyResp.Scores.SketchScore, pyResp.Scores.GaitScore, pyResp.KategoriBurnout)
	return pyResp, "python_live_inference"
}

func fallbackMultimodal(facePath, drawingPath, audioPath, gaitRaw string) PythonMultimodalResponse {
	var resp PythonMultimodalResponse
	resp.Status = "success"

	sketchScore, sketchLabel := calculateSketchScore(drawingPath)
	gaitScore, gaitLabel := calculateGaitScore(gaitRaw)

	visualScore := 28.0
	visualLabel := "Normal (Sehat)"
	if facePath != "" {
		if fi, err := os.Stat(facePath); err == nil && fi.Size() > 1000 {
			visualScore = 32.0
		}
	}

	voiceScore := 34.0
	voiceLabel := "Vokal Normal (Stabil)"
	if audioPath != "" {
		if fi, err := os.Stat(audioPath); err == nil && fi.Size() > 1000 {
			voiceScore = 36.0
		}
	}

	resp.Scores.VisualScore = visualScore
	resp.Scores.VoiceScore = voiceScore
	resp.Scores.SketchScore = sketchScore
	resp.Scores.GaitScore = gaitScore

	resp.Labels.VisualLabel = visualLabel
	resp.Labels.VoiceLabel = voiceLabel
	resp.Labels.SketchLabel = sketchLabel
	resp.Labels.GaitLabel = gaitLabel

	resp.SkorSklera = int(math.Round(visualScore))
	resp.SkorAkustik = int(math.Round(voiceScore))
	resp.SkorMotorik = int(math.Round((sketchScore + gaitScore) / 2.0))

	avg := (visualScore + voiceScore + sketchScore + gaitScore) / 4.0
	resp.SkorRataRata = avg

	if avg >= 76.0 {
		resp.KategoriBurnout = "Mode Zombi Akut (Kelelahan Multimodal)"
		resp.IsEmergency = true
	} else if voiceScore >= 70.0 {
		resp.KategoriBurnout = "Kelelahan Vokal & Beban Kognitif"
	} else if visualScore >= 70.0 {
		resp.KategoriBurnout = "Astenopia / Kelelahan Visual & Sklera"
	} else if sketchScore >= 68.0 || gaitScore >= 68.0 {
		resp.KategoriBurnout = "Ketegangan Neuromuskular & Kelelahan Motorik"
	} else if avg < 45.0 {
		resp.KategoriBurnout = "Kondisi Prima & Bugar (Human Prime)"
	} else {
		resp.KategoriBurnout = "Burnout Sedang (Fisik & Mental)"
	}

	resp.DiagnosisSummary = fmt.Sprintf("Mata: %s (%d%%) • Suara: %s (%d%%) • Sketsa: %s (%d%%) • Gait: %s (%d%%)",
		visualLabel, int(visualScore), voiceLabel, int(voiceScore), sketchLabel, int(sketchScore), gaitLabel, int(gaitScore))

	resp.Resep = []struct {
		IDResep         string `json:"id_resep"`
		JenisIntervensi string `json:"jenis_intervensi"`
		DeskripsiTugas  string `json:"deskripsi_tugas"`
	}{
		{
			IDResep:         "REC-01",
			JenisIntervensi: "Fisik",
			DeskripsiTugas:  "Lakukan peregangan leher, bahu, dan punggung ringan selama 10 menit serta penuhi hidrasi 500ml air putih.",
		},
		{
			IDResep:         "REC-02",
			JenisIntervensi: "Mental",
			DeskripsiTugas:  "Praktikkan teknik pernapasan ritmik 4-7-8 dan istirahatkan mata dari layar selama 20 menit.",
		},
	}

	return resp
}

func calculateSketchScore(drawingPath string) (float64, string) {
	if drawingPath != "" {
		if file, err := os.Open(drawingPath); err == nil {
			defer file.Close()
			if img, _, err := image.Decode(file); err == nil {
				bounds := img.Bounds()
				w, h := bounds.Dx(), bounds.Dy()
				if w*h > 16 {
					bgR, bgG, bgB, _ := img.At(bounds.Min.X, bounds.Min.Y).RGBA()
					step := max(1, max(w, h)/300)
					active, sampled := 0, 0
					const threshold = 3 * 0x1800
					for y := bounds.Min.Y; y < bounds.Max.Y; y += step {
						for x := bounds.Min.X; x < bounds.Max.X; x += step {
							r, g, b, _ := img.At(x, y).RGBA()
							sampled++
							diff := absDiff(r, bgR) + absDiff(g, bgG) + absDiff(b, bgB)
							if diff > threshold {
								active++
							}
						}
					}
					if sampled > 0 {
						density := float64(active) / float64(sampled)
						score := math.Min(95.0, math.Max(25.0, 30.0+(density*160.0)))
						lbl := "Pola Coretan Rileks & Kontinu"
						if score > 65 {
							lbl = "Tremor / Hambatan Motorik Halus"
						}
						return math.Round(score*10) / 10, lbl
					}
				}
			}
		}
	}
	return 38.0, "Pola Coretan Rileks & Kontinu"
}

func calculateGaitScore(gaitRaw string) (float64, string) {
	clean := strings.TrimSpace(gaitRaw)
	if len(clean) > 50 {
		return 42.0, "Aktivitas Dinamis Normal"
	}
	return 32.0, "Langkah Stabil & Terkoordinasi"
}

func absDiff(a, b uint32) uint32 {
	if a > b {
		return a - b
	}
	return b - a
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
			},
			{
				IDResep:         "REC-02",
				JenisIntervensi: "Mental",
				DeskripsiTugas:  "Alihkan saraf motorik halus dengan aktivitas taktil: seduh kopi/teh manual brew secara perlahan selama 5 menit sambil mengatur napas 4-7-8.",
			},
			{
				IDResep:         "REC-03",
				JenisIntervensi: "Reset Alam",
				DeskripsiTugas:  "Rencanakan jalan santai di ruang terbuka hijau atau day-hike ringan akhir pekan ini untuk mengkalibrasi ulang ritme sirkadian tubuh.",
			},
		}
	}

	if isAudioBurnout || skorMotorik >= 75 {
		return "Kelelahan Mental & Stres Motorik", false, []RecipeItem{
			{
				IDResep:         "REC-01",
				JenisIntervensi: "Mental",
				DeskripsiTugas:  "Lakukan protokol taktil: seduh minuman hangat manual atau rapikan meja kerja selama 5 menit untuk menurunkan lonjakan kortisol.",
			},
			{
				IDResep:         "REC-02",
				JenisIntervensi: "Fisik",
				DeskripsiTugas:  "Praktikkan teknik pernapasan ritmik 4-7-8 dan istirahatkan mata dari layar selama 20 menit.",
			},
		}
	}

	if isJaundice {
		return "Kelelahan Fisik & Metabolisme", false, []RecipeItem{
			{
				IDResep:         "REC-01",
				JenisIntervensi: "Fisik",
				DeskripsiTugas:  "Lakukan peregangan leher, bahu, dan punggung ringan selama 10 menit serta penuhi hidrasi 500ml air putih.",
			},
			{
				IDResep:         "REC-02",
				JenisIntervensi: "Mental",
				DeskripsiTugas:  "Tidur 1 jam lebih awal malam ini tanpa paparan layar biru smartphone.",
			},
		}
	}

	return "Kondisi Stabil (Manusia Sehat)", false, []RecipeItem{
		{
			IDResep:         "REC-01",
			JenisIntervensi: "Fisik",
			DeskripsiTugas:  "Pertahankan peregangan ringan setiap 60 menit duduk di depan layar dan penuhi target air putih 2 liter.",
		},
		{
			IDResep:         "REC-02",
			JenisIntervensi: "Mental",
			DeskripsiTugas:  "Pertahankan jeda istirahat mata (aturan 20-20-20) untuk menjaga fokus harian.",
		},
	}
}