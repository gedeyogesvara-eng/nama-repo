package config

import (
	"fmt"
	"log"
	"os"

	"backend-antigravity/internal/models"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// InitDB menginisialisasi koneksi MySQL menggunakan GORM dan melakukan AutoMigrate
func InitDB() *gorm.DB {
	user := getEnv("DB_USER", "root")
	password := getEnv("DB_PASS", "")
	host := getEnv("DB_HOST", "127.0.0.1")
	port := getEnv("DB_PORT", "3306")
	dbName := getEnv("DB_NAME", "anti_zombi_db")

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		user, password, host, port, dbName,
	)

	var err error
	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatalf("Gagal terhubung ke database MySQL: %v", err)
	}

	log.Println("Berhasil terhubung ke database MySQL!")

	// Auto-migration untuk tabel users, screening_history, dan ai_recipes
	err = DB.AutoMigrate(
		&models.User{},
		&models.ScreeningHistory{},
		&models.AIRecipe{},
	)
	if err != nil {
		log.Fatalf("Gagal melakukan auto migration: %v", err)
	}

	log.Println("Auto-migration berhasil selesai!")
	return DB
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
