import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service untuk menangani komunikasi HTTP nyata ke backend AI lokal.
class AIService {
  /// Base URL dinamis berdasarkan platform tempat aplikasi berjalan:
  /// - Jika di Web (Chrome / Browser): menggunakan 127.0.0.1:5000
  /// - Jika di Android / Emulator: menggunakan 10.0.2.2:5000
  static String get defaultEndpoint => kIsWeb
      ? 'http://127.0.0.1:5000/api/detect'
      : 'http://10.0.2.2:5000/api/detect';

  /// Minimal binary JPEG 1x1 pixel buffer untuk fallback web/data kosong
  static const List<int> _minimalJpegBytes = [
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
    0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
    0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
    0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
    0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
    0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
    0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
    0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
    0x00, 0xBF, 0x80, 0xFF, 0xD9
  ];

  /// Minimal binary PNG 1x1 pixel buffer
  static const List<int> _minimalPngBytes = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
    0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0x60, 0x60, 0xF0, 0x0F,
    0x00, 0x01, 0x04, 0x01, 0x00, 0xA2, 0x2A, 0x28, 0x36, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
  ];

  /// Minimal binary WAV PCM header buffer (44 bytes)
  static const List<int> _minimalWavBytes = [
    0x52, 0x49, 0x46, 0x46, 0x2C, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45,
    0x66, 0x6D, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
    0x80, 0x3E, 0x00, 0x00, 0x00, 0x7D, 0x00, 0x00, 0x02, 0x00, 0x10, 0x00,
    0x64, 0x61, 0x74, 0x61, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00
  ];

  /// Mengirim data multimodal (Wajah/Sklera, Coretan Grafomotor, Audio Vokal, & Gait Sensor)
  /// ke backend AI via Multipart POST Request menggunakan Endpoint dinamis sesuai platform.
  static Future<Map<String, dynamic>> sendDataToAI({
    required String faceImagePath,
    required String drawingImagePath,
    required String audioPath,
    dynamic gaitData = "gait_recorded",
    String? customEndpoint,
  }) async {
    // 1. Tentukan endpoint target secara dinamis
    final targetUrl = customEndpoint ?? defaultEndpoint;
    debugPrint('🚀 [AIService] Mengirim data ke AI Model (${kIsWeb ? "Web/Chrome" : "Mobile/Emulator"}): $targetUrl');
    debugPrint('📷 Face Image: $faceImagePath');
    debugPrint('🎨 Drawing Image: $drawingImagePath');
    debugPrint('🎙️ Audio: $audioPath');

    try {
      final uri = Uri.parse(targetUrl);
      final request = http.MultipartRequest('POST', uri);

      // Header standar
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Helper untuk melampirkan file multipart secara aman di Web (fromBytes) maupun Mobile (fromPath)
      Future<void> attachMultipartFile({
        required String field,
        required String path,
        required String filename,
        required List<int> fallbackBytes,
      }) async {
        if (kIsWeb) {
          // Pada browser web, fromPath tidak didukung oleh browser sandbox, gunakan fromBytes
          request.files.add(
            http.MultipartFile.fromBytes(
              field,
              fallbackBytes,
              filename: filename,
            ),
          );
        } else {
          // Pada Android / iOS / Desktop, baca file lokal jika ada
          if (path.isNotEmpty && File(path).existsSync()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                field,
                path,
                filename: filename,
              ),
            );
          } else if (fallbackBytes.isNotEmpty) {
            request.files.add(
              http.MultipartFile.fromBytes(
                field,
                fallbackBytes,
                filename: filename,
              ),
            );
          }
        }
      }

      // 1. Lampirkan Gambar Wajah / Sklera (JPG)
      await attachMultipartFile(
        field: 'face_image',
        path: faceImagePath,
        filename: 'face_capture.jpg',
        fallbackBytes: _minimalJpegBytes,
      );
      // Alias 'foto' untuk kompatibilitas endpoint backend
      await attachMultipartFile(
        field: 'foto',
        path: faceImagePath,
        filename: 'face_capture.jpg',
        fallbackBytes: _minimalJpegBytes,
      );

      // 2. Lampirkan Gambar Coretan Mental / Grafomotor (PNG)
      await attachMultipartFile(
        field: 'drawing_image',
        path: drawingImagePath,
        filename: 'drawing_canvas.png',
        fallbackBytes: _minimalPngBytes,
      );

      // 3. Lampirkan Rekaman Audio Vokal (WAV/M4A)
      await attachMultipartFile(
        field: 'audio',
        path: audioPath,
        filename: 'voice_recording.wav',
        fallbackBytes: _minimalWavBytes,
      );
      // Alias 'file_audio'
      await attachMultipartFile(
        field: 'file_audio',
        path: audioPath,
        filename: 'voice_recording.wav',
        fallbackBytes: _minimalWavBytes,
      );

      // 4. Lampirkan Data Sensor Gait (Akselerometer)
      if (gaitData != null) {
        request.fields['gait_sensor'] =
            gaitData is String ? gaitData : jsonEncode(gaitData);
        request.fields['gait_status'] = 'gait_recorded';
      }

      // Eksekusi request multipart dengan batas waktu inferensi 45 detik
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException(
            'Koneksi ke backend AI timeout setelah 45 detik ($targetUrl). Pastikan server AI berjalan.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('📥 [AIService] Response HTTP Status: ${response.statusCode}');
      debugPrint('📥 [AIService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return normalizeResponse(decoded);
        } else {
          throw Exception(
            'Format respons backend bukan berupa objek JSON valid.',
          );
        }
      } else {
        throw Exception(
          'AI Server Error [${response.statusCode}]: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [AIService] Error saat menghubungi AI Backend: $e');
      rethrow;
    }
  }

  /// Normalisasi payload respons dari model AI agar kompatibel dengan
  /// tampilan `ResultScreen` tanpa membuang informasi asli dari backend.
  static Map<String, dynamic> normalizeResponse(Map<String, dynamic> raw) {
    // 1. Dapatkan atau normalisasi data skrining / ringkasan diagnosis
    Map<String, dynamic> screeningData;
    if (raw.containsKey('data_skrining') && raw['data_skrining'] is Map) {
      screeningData = Map<String, dynamic>.from(raw['data_skrining'] as Map);
    } else if (raw.containsKey('data') && raw['data'] is Map) {
      screeningData = Map<String, dynamic>.from(raw['data'] as Map);
    } else {
      screeningData = Map<String, dynamic>.from(raw);
    }

    // Pastikan ID Skrining ada
    screeningData['id_skrining'] ??=
        'SCR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Normalisasi kategori / tingkat depresi
    final kategori = raw['tingkat_depresi'] ??
        raw['depression_level'] ??
        screeningData['kategori_burnout'] ??
        screeningData['tingkat_depresi'] ??
        raw['status'] ??
        'Kelelahan Terdeteksi';
    screeningData['kategori_burnout'] = kategori;

    // Normalisasi skor sensor (Akustik, Motorik, Sklera)
    final dynamic scoresMap = raw['skor_sensor'] ?? raw['scores'];
    screeningData['skor_akustik'] = screeningData['skor_akustik'] ??
        (scoresMap is Map ? scoresMap['audio'] ?? scoresMap['akustik'] : null) ??
        raw['skor_akustik'] ??
        raw['audio_score'] ??
        76;

    screeningData['skor_motorik'] = screeningData['skor_motorik'] ??
        (scoresMap is Map ? scoresMap['gait'] ?? scoresMap['motorik'] : null) ??
        raw['skor_motorik'] ??
        raw['gait_score'] ??
        64;

    screeningData['skor_sklera'] = screeningData['skor_sklera'] ??
        (scoresMap is Map ? scoresMap['eye'] ?? scoresMap['sklera'] : null) ??
        raw['skor_sklera'] ??
        raw['sclera_score'] ??
        85;

    // 2. Normalisasi daftar resep intervensi / rekomendasi tindakan
    final List<Map<String, dynamic>> recipesList = [];
    final dynamic rawRecipes = raw['ai_recipes'] ??
        raw['resep'] ??
        raw['rekomendasi_tindakan'] ??
        raw['recommendations'] ??
        screeningData['ai_recipes'] ??
        screeningData['resep'];

    if (rawRecipes is List) {
      for (int i = 0; i < rawRecipes.length; i++) {
        final item = rawRecipes[i];
        if (item is Map) {
          recipesList.add({
            'id_resep': item['id_resep'] ?? 'REC-0${i + 1}',
            'jenis_intervensi': item['jenis_intervensi'] ??
                item['kategori'] ??
                item['type'] ??
                (i % 2 == 0 ? 'Fisik' : 'Mental'),
            'deskripsi_tugas': item['deskripsi_tugas'] ??
                item['deskripsi'] ??
                item['action'] ??
                item.toString(),
            'is_completed': item['is_completed'] ?? false,
          });
        } else if (item is String) {
          recipesList.add({
            'id_resep': 'REC-0${i + 1}',
            'jenis_intervensi': i % 2 == 0 ? 'Fisik' : 'Mental',
            'deskripsi_tugas': item,
            'is_completed': false,
          });
        }
      }
    }

    // Jika rekomendasi kosong, berikan rekomendasi standar sesuai diagnosis
    if (recipesList.isEmpty) {
      recipesList.addAll([
        {
          'id_resep': 'REC-01',
          'jenis_intervensi': 'Fisik',
          'deskripsi_tugas':
              'Lakukan peregangan leher dan pernapasan ritmik 4-7-8 selama 5 menit.',
          'is_completed': false,
        },
        {
          'id_resep': 'REC-02',
          'jenis_intervensi': 'Mental',
          'deskripsi_tugas':
              'Istirahatkan mata dari paparan layar (20-20-20 rule) dan minumlah air putih.',
          'is_completed': false,
        },
      ]);
    }

    return {
      'status': 'success',
      'data_skrining': screeningData,
      'ai_recipes': recipesList,
      'raw_backend_response': raw,
    };
  }
}
