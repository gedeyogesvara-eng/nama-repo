-- ============================================================================
-- Somatic.AI / RESTGUARD - Skema Database MySQL (somatic_db)
-- File ini di-embed ke backend Go (main.go) dan dijalankan OTOMATIS setiap
-- server menyala. Semua statement bersifat idempotent (aman dijalankan ulang).
-- Kolom baru pada tabel lama (email, password_hash, 4 skor terpisah) ditambahkan
-- otomatis oleh migrasi di main.go jika tabel sudah ada dari versi sebelumnya.
-- ============================================================================
CREATE DATABASE IF NOT EXISTS somatic_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE somatic_db;

-- 1. Tabel Users (BCNF: id adalah Primary Key tunggal penentu seluruh atribut profil)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(190) NULL UNIQUE,
    password_hash VARCHAR(255) NULL,
    recovery_score INT NOT NULL DEFAULT 40,
    zombie_stage ENUM('CRITICAL_ZOMBIE', 'TIRED_ZOMBIE', 'RECOVERING_HUMAN', 'HEALTHY_HUMAN') NOT NULL DEFAULT 'TIRED_ZOMBIE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabel Screening Sessions (Menyimpan 4 skor terpisah dari model AI Python)
CREATE TABLE IF NOT EXISTS screening_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kode_skrining VARCHAR(30) NOT NULL UNIQUE,
    user_id INT NOT NULL,
    kategori_burnout VARCHAR(100) NOT NULL,
    skor_akustik INT NOT NULL,
    skor_motorik INT NOT NULL,
    skor_sklera INT NOT NULL,
    visual_score INT NOT NULL DEFAULT 0,
    voice_score INT NOT NULL DEFAULT 0,
    sketch_score INT NOT NULL DEFAULT 0,
    gait_score INT NOT NULL DEFAULT 0,
    eye_label VARCHAR(100) NOT NULL,
    audio_label VARCHAR(100) NOT NULL,
    sketch_label VARCHAR(100) NULL,
    gait_label VARCHAR(100) NULL,
    face_image_path VARCHAR(255) NOT NULL,
    drawing_image_path VARCHAR(255) NOT NULL,
    audio_file_path VARCHAR(255) NOT NULL,
    gait_raw_data TEXT,
    is_emergency BOOLEAN NOT NULL DEFAULT FALSE,
    diagnosis_summary TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. Tabel AI Recipes (Resep aksi personalisasi hasil rekomendasi AI)
CREATE TABLE IF NOT EXISTS ai_recipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    kode_resep VARCHAR(20) NOT NULL,
    jenis_intervensi VARCHAR(50) NOT NULL,
    deskripsi_tugas TEXT NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_recipe_session FOREIGN KEY (session_id) REFERENCES screening_sessions(id) ON DELETE CASCADE
);

-- 4. Akun demo bawaan
INSERT IGNORE INTO users (id, full_name, recovery_score, zombie_stage)
VALUES (1, 'Pengguna Tamu', 40, 'TIRED_ZOMBIE');
