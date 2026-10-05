package main

import (
	"fmt"
	"log"
	"os"

	"backend-antigravity/internal/config"
	"backend-antigravity/internal/routes"
)


	addr := fmt.Sprintf(":%s", port)
	log.Printf("Server siap mendengarkan di http://localhost%s\n", addr)

	if err := r.Run(addr); err != nil {
		log.Fatalf("Gagal menjalankan server: %v", err)
	}
}
