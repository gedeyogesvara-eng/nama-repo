package controllers

import (
	"bytes"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"time"

	"backend-antigravity/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ScreeningController struct {
	DB *gorm.DB
}

func NewScreeningController(db *gorm.DB) *ScreeningController {
	return &ScreeningController{DB: db}
}

// PythonRecipeResponse merepresentasikan item tugas intervensi dari Python AI
type PythonRecipeResponse struct {
	JenisIntervensi string `json:"jenis_intervensi"`
	DeskripsiTugas  string `json:"deskripsi_tugas"`
}

// PythonPredictionResponse merepresentasikan struktur payload respons dari service AI Python
type PythonPredictionResponse struct {
	SkorAkustik     float64                `json:"skor_akustik"`
	SkorMotorik     float64                `json:"skor_motorik"`
	SkorSklera      float64                `json:"skor_sklera"`
	KategoriBurnout string                 `json:"kategori_burnout"`
	Resep           []PythonRecipeResponse `json:"resep"`
}

// ProcessScreening bertindak sebagai API Gateway / Forwarder ke Python AI service di port 5000
// @Summary Memproses file suara dan foto untuk skrining burnout
// @Router /api/screening [post]
func (sc *ScreeningController) ProcessScreening(c *gin.Context) {
	// 1. Validasi input ID User dari form
	userIDStr := c.PostForm("id_user")
	if userIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Field 'id_user' wajib diisi",
		})
		return
	}

	userUUID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Format 'id_user' harus UUID yang valid",
		})
		return
	}

	// Validasi apakah user terdaftar di database
	var existingUser models.User
	if err := sc.DB.First(&existingUser, "id_user = ?", userUUID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "User dengan ID tersebut tidak ditemukan",
		})
		return
	}

	// 2. Mengambil file suara (audio) dan foto dari form multipart mobile
	audioFileHeader, err := c.FormFile("audio")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "File 'audio' wajib diunggah (form-data key: 'audio')",
		})
		return
	}

	fotoFileHeader, err := c.FormFile("foto")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "File 'foto' wajib diunggah (form-data key: 'foto')",
		})
		return
	}

	// Buka stream file audio
	audioFile, err := audioFileHeader.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal membaca stream audio"})
		return
	}
	defer audioFile.Close()

	// Buka stream file foto
	fotoFile, err := fotoFileHeader.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal membaca stream foto"})
		return
	}
	defer fotoFile.Close()

	// 3. Menyiapkan Multipart Form-Data baru untuk diforward ke service Python AI (port 5000)
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)

	// Tambahkan field id_user jika dibutuhkan oleh model python
	_ = writer.WriteField("id_user", userUUID.String())

	// Tulis part file audio
	audioPart, err := writer.CreateFormFile("audio", audioFileHeader.Filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menyiapkan multipart audio"})
		return
	}
	if _, err = io.Copy(audioPart, audioFile); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menyalin buffer audio"})
		return
	}

	// Tulis part file foto
	fotoPart, err := writer.CreateFormFile("foto", fotoFileHeader.Filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menyiapkan multipart foto"})
		return
	}
	if _, err = io.Copy(fotoPart, fotoFile); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menyalin buffer foto"})
		return
	}

	// Tutup multipart writer untuk menulis closing boundary
	if err := writer.Close(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menutup multipart buffer"})
		return
	}

	// 4. Eksekusi HTTP POST ke Python AI Service
	aiURL := os.Getenv("AI_SERVICE_URL")
	if aiURL == "" {
		aiURL = "http://localhost:5000/predict"
	}

	httpClient := &http.Client{
		Timeout: 60 * time.Second, // Memberi batas toleransi inferensi ML
	}

	req, err := http.NewRequestWithContext(c.Request.Context(), http.MethodPost, aiURL, &body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal membuat request ke service AI"})
		return
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	aiResp, err := httpClient.Do(req)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{
			"status":  "error",
			"message": "Gagal menghubungi Python AI Service di port 5000. Pastikan service AI aktif.",
			"details": err.Error(),
		})
		return
	}
	defer aiResp.Body.Close()

	if aiResp.StatusCode != http.StatusOK {
		rawErrBody, _ := io.ReadAll(aiResp.Body)
		c.JSON(http.StatusBadGateway, gin.H{
			"status":      "error",
			"message":     "Service Python AI mengembalikan status non-200",
			"status_code": aiResp.StatusCode,
			"response":    string(rawErrBody),
		})
		return
	}

	// 5. Decode response JSON dari Python AI
	var prediction PythonPredictionResponse
	if err := json.NewDecoder(aiResp.Body).Decode(&prediction); err != nil {
		c.JSON(http.StatusBadGateway, gin.H{
			"status":  "error",
			"message": "Format respons dari Python AI tidak sesuai dengan skema yang diharapkan",
			"details": err.Error(),
		})
		return
	}

	// 6. Menyimpan hasil ke database dalam 1 Database Transaction (Atomic)
	tx := sc.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	newScreening := models.ScreeningHistory{
		IDUser:          userUUID,
		SkorAkustik:     prediction.SkorAkustik,
		SkorMotorik:     prediction.SkorMotorik,
		SkorSklera:      prediction.SkorSklera,
		KategoriBurnout: prediction.KategoriBurnout,
		WaktuTes:        time.Now(),
	}

	if err := tx.Create(&newScreening).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal menyimpan entri screening_history",
			"details": err.Error(),
		})
		return
	}

	// Insert recipes
	recipes := make([]models.AIRecipe, 0, len(prediction.Resep))
	for _, item := range prediction.Resep {
		recipe := models.AIRecipe{
			IDSkrining:      newScreening.IDSkrining,
			JenisIntervensi: item.JenisIntervensi,
			DeskripsiTugas:  item.DeskripsiTugas,
			IsCompleted:     false,
		}
		if err := tx.Create(&recipe).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{
				"status":  "error",
				"message": "Gagal menyimpan entri ai_recipes",
				"details": err.Error(),
			})
			return
		}
		recipes = append(recipes, recipe)
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal melakukan commit transaksi ke database",
		})
		return
	}

	newScreening.AIRecipes = recipes

	// 7. Kembalikan response final ke client mobile
	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Screening berhasil diproses dan disimpan ke database",
		"data":    newScreening,
	})
}
