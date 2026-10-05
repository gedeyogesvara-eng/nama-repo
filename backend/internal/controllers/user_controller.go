package controllers

import (
	"net/http"

	"backend-antigravity/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type UserController struct {
	DB *gorm.DB
}

func NewUserController(db *gorm.DB) *UserController {
	return &UserController{DB: db}
}

type CreateUserRequest struct {
	NamaPengguna string `json:"nama_pengguna" binding:"required"`
	StatusAvatar string `json:"status_avatar"`
}

// CreateUser mendaftarkan user baru
// @Router /api/users [post]
func (uc *UserController) CreateUser(c *gin.Context) {
	var req CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Field 'nama_pengguna' wajib diisi",
			"details": err.Error(),
		})
		return
	}

	avatar := req.StatusAvatar
	if avatar == "" {
		avatar = "Zombi Akut"
	}

	user := models.User{
		NamaPengguna: req.NamaPengguna,
		StatusAvatar: avatar,
	}

	if err := uc.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal menyimpan user ke database",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "User berhasil didaftarkan",
		"data":    user,
	})
}

// GetUserHistory mengambil data user beserta relasi riwayat skrining dan resep AI (Preload)
// @Router /api/users/:id/history [get]
func (uc *UserController) GetUserHistory(c *gin.Context) {
	idParam := c.Param("id")
	userUUID, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Format user ID harus UUID yang valid",
		})
		return
	}

	var user models.User
	// Menggunakan GORM Preload untuk nested join: User -> ScreeningHistories -> AIRecipes
	err = uc.DB.
		Preload("ScreeningHistories", func(db *gorm.DB) *gorm.DB {
			return db.Order("waktu_tes DESC")
		}).
		Preload("ScreeningHistories.AIRecipes").
		First(&user, "id_user = ?", userUUID).Error

	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{
				"status":  "error",
				"message": "User tidak ditemukan",
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal mengambil data user history",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Data riwayat user berhasil diambil",
		"data":    user,
	})
}
