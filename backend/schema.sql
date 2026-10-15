CREATE DATABASE IF NOT EXISTS somatic_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE somatic_db;

-- 1. Tabel Users (BCNF: id adalah Primary Key tunggal penentu seluruh atribut profil)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    recovery_score INT NOT NULL DEFAULT 40,
    zombie_stage ENUM('CRITICAL_ZOMBIE', 'TIRED_ZOMBIE', 'RECOVERING_HUMAN', 'HEALTHY_HUMAN') NOT NULL DEFAULT 'TIRED_ZOMBIE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabel Screening Sessions (BCNF: id dan kode_skrining adalah Candidate Keys)
CREATE TABLE IF NOT EXISTS screening_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kode_skrining VARCHAR(30) NOT NULL UNIQUE,
    user_id INT NOT NULL,
    kategori_burnout VARCHAR(100) NOT NULL,
    skor_akustik INT NOT NULL,
    skor_motorik INT NOT NULL,
    skor_sklera INT NOT NULL,
    eye_label VARCHAR(100) NOT NULL,
    audio_label VARCHAR(100) NOT NULL,
    face_image_path VARCHAR(255) NOT NULL,
    drawing_image_path VARCHAR(255) NOT NULL,
    audio_file_path VARCHAR(255) NOT NULL,
    gait_raw_data TEXT,
    is_emergency BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. Tabel AI Recipes (BCNF: Memisahkan daftar resep intervensi multi-value ke tabel tersendiri)
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

INSERT INTO users (id, full_name, recovery_score, zombie_stage) VALUES
(1, 'Demo User 1 (Mode Zombi)', 35, 'CRITICAL_ZOMBIE'),
(2, 'Demo User 2 (Mahasiswa)', 55, 'TIRED_ZOMBIE'),
(3, 'Demo User 3 (Pekerja)', 75, 'RECOVERING_HUMAN'),
(4, 'Demo User 4 (Juri Test)', 50, 'TIRED_ZOMBIE')
ON DUPLICATE KEY UPDATE full_name=VALUES(full_name);
