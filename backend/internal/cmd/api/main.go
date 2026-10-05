package main

import (
	"fmt"
	"log"
	"os"

	"backend-antigravity/internal/config"
	"backend-antigravity/internal/routes"
)

func main() {
	log.Println("Memulai server Anti-Zombi Backend API...")

	// 1. Inisialisasi Database MySQL & Auto-migration
	db := config.InitDB()

	// 2. Setup Gin Router & Endpoint Routes
	r := routes.SetupRouter(db)

	// 3. Port Configuration
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	addr := fmt.Sprintf(":%s", port)
	log.Printf("Server siap mendengarkan di http://localhost%s\n", addr)

	if err := r.Run(addr); err != nil {
		log.Fatalf("Gagal menjalankan server: %v", err)
	}
}
