<div align="center">
  <h1>Destress</h1>
  <p><strong>Deteksi Dini Kesehatan Mental dan Fisik Multimodal Terintegrasi</strong></p>
  <p><i>Submission for COMPE JOINTS UGM - Kategori Healthcare</i></p>
</div>

---

## 📖 Latar Belakang Masalah
Dalam ekosistem modern yang serba cepat, tingkat stres di kalangan pekerja profesional dan mahasiswa semakin tidak terkendali. Seringkali, individu **tidak menyadari bahwa mereka sedang mengalami stres kronis atau *burnout*** hingga kondisi tersebut bermanifestasi menjadi masalah kesehatan mental atau fisik yang parah. Saat ini, metode diagnosis dini yang tersedia mayoritas masih bergantung pada kuesioner subjektif yang rentan terhadap bias pelaporan diri (*self-reporting bias*). Aksesibilitas untuk melakukan deteksi dini terhadap penurunan kondisi kesehatan secara objektif masih sangat minim di masyarakat.

## 💡 Solusi: Destress
**Destress** adalah aplikasi kesehatan terpadu yang memanfaatkan kecerdasan buatan (AI) untuk melakukan deteksi dini terhadap kondisi kesehatan mental dan fisik pengguna secara objektif. Menggunakan pendekatan **Multimodal AI**, aplikasi ini menganalisis tiga parameter biologis manusia yang sering kali menunjukkan gejala awal stres dan kelelahan: visual (mata), akustik (suara), dan kinematik (gerakan tubuh).

### 🚀 Keunggulan Kompetitif (*Unique Value Proposition*)
Berbeda dengan aplikasi *mental health* konvensional yang hanya mengandalkan jurnal atau kuesioner, Destress menawarkan:
1. **Diagnosis Berbasis Bio-Signal (Objektif):** Terintegrasi secara *end-to-end* dengan 3 arsitektur *Deep Learning* yang menganalisis indikator fisik nyata.
2. **Ekosistem Terpusat:** Menyatukan analisis visual, audio, dan sensor gerak ke dalam satu *Super-API* yang ringan dan bekerja secara *real-time*.
3. **Privasi & Aksesibilitas:** Analisis dilakukan secara komputasional tanpa intervensi manusia, memberikan ruang aman bagi pengguna untuk memantau kesehatan mental mereka sendiri.

## 🎯 Target Pengguna
Solusi kami dirancang inklusif dan terskala untuk berbagai sektor kesehatan:
*   **Mahasiswa & Akademisi:** Untuk memantau tingkat stres dan kelelahan selama masa studi/ujian.
*   **Pekerja Kantoran (Korporat):** Sebagai alat pemantauan *occupational health* guna mencegah *burnout*.
*   **Fasilitas Kesehatan (Rumah Sakit/Klinik):** Sebagai alat bantu pra-skrining (triase digital) bagi pasien sebelum diagnosis medis lanjutan.
*   **Masyarakat Umum:** Edukasi dan pemantauan kesehatan preventif secara mandiri.

## ⚙️ Arsitektur AI & Teknologi

Aplikasi ini didukung oleh infrastruktur *microservices* dengan spesifikasi teknis berikut:

### 1. Modul 1: *RetinaGlow* (Visual Analysis)
*   **Fungsi:** Mendeteksi kelelahan ekstrem atau indikasi *jaundice* (penyakit kuning/gangguan liver) melalui pemindaian area mata.
*   **Model:** `MobileNetV2` (Transfer Learning) + OpenCV Haar Cascades dengan filter keamanan pra-pemrosesan.
*   **Input:** Gambar (RGB).

### 2. Modul 2: *Acoustic Burnout* (Voice Analysis)
*   **Fungsi:** Mendeteksi indikasi stres tinggi melalui anomali pada pita suara (Acoustic Burnout).
*   **Model:** `1D Convolutional Neural Network (CNN)` memproses ekstraksi fitur MFCC (Mel-frequency cepstral coefficients).
*   **Input:** Rekaman Suara (`.wav`).

### 3. Modul 3: *Kinematic Recognition* (Activity Analysis)
*   **Fungsi:** Mengklasifikasikan pola aktivitas berjalan/berlari stabil vs. bergetar (indikasi energi/kelesuan) dari data *Inertial Measurement Unit* (IMU).
*   **Model:** `1D Convolutional Neural Network (CNN)` ringan.
*   **Input:** Data Sensor Akselerometer (matriks 150x3 JSON).

### *Tech Stack* Utama
*   **Frontend:** Flutter & Dart
*   **Backend Database:** Golang & SQLite
*   **AI/Core Engine:** Python, FastAPI, TensorFlow/Keras, OpenCV, Librosa

---

## 🛠️ Instruksi Pengujian (*Testing Guide*)

Untuk tim penilai (Juri), aplikasi dapat diuji coba dengan langkah-langkah berikut:

### 1. Pengujian Aplikasi Android (Frontend)
1. Unduh *file* APK rilis kami: `"Destress.apk"`.
2. Instal *file* APK tersebut pada perangkat Android Anda.
3. Pastikan perangkat terhubung ke internet. Aplikasi akan otomatis berkomunikasi dengan *server backend* dan *Core Engine AI* kami yang telah di-*deploy*.

### 2. Pengujian Lokal Super-API AI (Opsional untuk Peninjauan Kode)
Jika Juri ingin meninjau dan menguji langsung *Core Engine AI* secara lokal (*offline*), ikuti langkah ini:
1. *Clone* repositori ini.
2. Buka terminal dan masuk ke direktori AI:
   ```bash
   cd "FIle AI/Mata-Suara"
   ```
3. Instal dependensi:
   ```bash
   pip install -r requirements.txt
   ```
4. Jalankan *server* FastAPI:
   ```bash
   python main.py
   ```
5. Buka **http://localhost:5000/docs** di *browser* untuk mengakses **Swagger UI** interaktif. Anda dapat langsung mengunggah foto, suara, atau data JSON ke tiga *endpoint* yang tersedia.

---

## 👨‍💻 Tim Pengembang

Proyek ini dikembangkan sepenuhnya oleh mahasiswa dengan pembagian peran komprehensif:

| Nama | Peran / Tanggung Jawab |
| :--- | :--- |
| **I Komang Arjuna Tudung Negara** | Frontend Developer (Flutter, UI/UX, Sensor Integration) |
| **Gede Yogi Yogesvara Dita Diasta** | Backend Developer 1 (Golang, Database Architecture) |
| **Bagas Manggala Putra** | Backend Developer 2 (API Integration, Server Deployment) |
| **I Kadek Indra Mahottama** | AI/ML Engineer (Model Architecture, Data Pipeline, FastAPI Engine) |
