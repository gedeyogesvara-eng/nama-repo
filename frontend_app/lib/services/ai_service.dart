import 'dart:async';

/// Service untuk menangani logika simulasi dan integrasi AI Backend.
class AIService {
  /// Meniru pemrosesan inferensi AI Multimodal (Sklera, Suara, Gait).
  /// Memiliki delay simulasi 4 detik, lalu mengembalikan data JSON/Map
  /// sesuai kontrak struktur database spesifik.
  static Future<Map<String, dynamic>> simulateAIDetection() async {
    await Future.delayed(const Duration(seconds: 4));

    return {
      "status": "success",
      "data_skrining": {
        "id_skrining": "SCR-9921",
        "kategori_burnout": "Kelelahan Fisik (Zombi Akut)",
        "skor_akustik": 78,
        "skor_motorik": 65,
        "skor_sklera": 88,
      },
      "ai_recipes": [
        {
          "id_resep": "REC-01",
          "jenis_intervensi": "Fisik",
          "deskripsi_tugas": "Lakukan stretching 5 menit sekarang",
          "is_completed": false,
        },
        {
          "id_resep": "REC-02",
          "jenis_intervensi": "Mental",
          "deskripsi_tugas": "Jauhi layar, buat kopi manual brew",
          "is_completed": false,
        },
      ],
    };
  }

  // ===========================================================================
  // KODE REFERENSI INTEGRASI NGROK (GO / PYTHON BACKEND)
  // ===========================================================================
  // Simpan kode ini sebagai referensi saat menghubungkan REST API asli.
  // Untuk mengaktifkan:
  // 1. Tambahkan dependency `http: ^1.2.0` dan `image_picker: ^1.0.7` di pubspec.yaml.
  // 2. Uncomment method di bawah ini.
  // ===========================================================================
  /*
  static Future<Map<String, dynamic>?> uploadDataToNgrok({
    required String ngrokBaseUrl, // Misal: "https://xxxx.ngrok-free.app"
    required String imagePath,
    required String audioPath,
    required Map<String, dynamic> gaitSensorData,
  }) async {
    try {
      final uri = Uri.parse('$ngrokBaseUrl/api/v1/detect');
      final request = http.MultipartRequest('POST', uri);

      // Bypass banner peringatan Ngrok Free Tier & tentukan headers
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'application/json',
      });

      // 1. Payload Berkas Gambar Sklera Mata
      if (imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file_sklera',
            imagePath,
            filename: 'sklera_capture.jpg',
          ),
        );
      }

      // 2. Payload Berkas Audio Rekaman Suara
      if (audioPath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file_audio',
            audioPath,
            filename: 'voice_recording.wav',
          ),
        );
      }

      // 3. Payload Data Sensor Akselerometer / Gyroscope (Gait)
      request.fields['gait_sensor_json'] = jsonEncode(gaitSensorData);

      // Kirim request multipart
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded;
      } else {
        throw Exception(
          'AI Server Error [${response.statusCode}]: ${response.body}',
        );
      }
    } catch (e) {
      // Tangani timeout atau koneksi putus
      rethrow;
    }
  }
  */
}
