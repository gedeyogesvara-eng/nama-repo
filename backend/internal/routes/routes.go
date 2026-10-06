package routes

import (
	"net/http"

	"backend-antigravity/internal/controllers"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// SetupRouter mengatur semua endpoint route API dan middleware
func SetupRouter(db *gorm.DB) *gin.Engine {
	r := gin.Default()

	// Middleware CORS sederhana
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	// Inisialisasi Controllers
	userCtrl := controllers.NewUserController(db)
	screeningCtrl := controllers.NewScreeningController(db)
	recipeCtrl := controllers.NewRecipeController(db)

	// Health check route
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"app":     "Anti-Zombi Backend API",
			"version": "1.0.0",
		})
	})

	// Grouping API Routes
	api := r.Group("/api")
	{
		// 1. User Endpoints
		api.POST("/users", userCtrl.CreateUser)
		api.GET("/users/:id/history", userCtrl.GetUserHistory)

		// 2. Recipe Endpoints
		api.PUT("/recipes/:id/complete", recipeCtrl.CompleteRecipe)

		// 3. Core Screening Endpoint (Gateway to Python AI)
		api.POST("/screening", screeningCtrl.ProcessScreening)
	}

	return r
}
