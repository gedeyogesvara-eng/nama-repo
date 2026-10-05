package controllers

import (
	"net/http"

	"backend-antigravity/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type RecipeController struct {
	DB *gorm.DB
}

func NewRecipeController(db *gorm.DB) *RecipeController {
	return &RecipeController{DB: db}
}

// CompleteRecipe menandai tugas resep intervensi telah selesai dikerjakan (is_completed = true)
// @Router /api/recipes/:id/complete [put]
func (rc *RecipeController) CompleteRecipe(c *gin.Context) {
	idParam := c.Param("id")
	recipeUUID, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Format ID resep harus UUID yang valid",
		})
		return
	}

	var recipe models.AIRecipe
	if err := rc.DB.First(&recipe, "id_resep = ?", recipeUUID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{
				"status":  "error",
				"message": "Resep tidak ditemukan",
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal mencari resep",
			"details": err.Error(),
		})
		return
	}

	// Update field is_completed menjadi true
	if err := rc.DB.Model(&recipe).Update("is_completed", true).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal memperbarui status resep",
			"details": err.Error(),
		})
		return
	}

	recipe.IsCompleted = true
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Status resep berhasil diperbarui menjadi selesai",
		"data":    recipe,
	})
}
