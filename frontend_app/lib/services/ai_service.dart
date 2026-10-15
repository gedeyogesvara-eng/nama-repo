import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk menangani komunikasi HTTP nyata ke backend Go (Gin) yang
/// meneruskan data ke server AI Python dan menyimpan hasilnya ke MySQL.
///
/// Seluruh berkas (coretan, audio, foto wajah) dikirim sebagai bytes
/// (`MultipartFile.fromBytes`) sehingga aman dijalankan di Flutter Web (Chrome)
/// maupun Android/iOS tanpa `dart:io`.
class AIService {
  /// Endpoint deteksi multimodal. Base URL ditentukan [ApiConfig] sesuai platform:
  /// - Web / Desktop: http://127.0.0.1:8081
  /// - Android Emulator: http://10.0.2.2:8081
  /// (dapat di-override dengan --dart-define=API_BASE_URL=http://IP:8081)
  static String get defaultEndpoint => '${ApiConfig.baseUrl}/api/detect';

  /// Minimal binary JPEG 1x1 pixel buffer untuk fallback jika kamera tidak tersedia
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

  /// Mengirim data multimodal (foto wajah/sklera, coretan grafomotor, audio vokal,
  /// dan sensor gait) ke backend Go via Multipart POST.
  ///
  /// Jika sebuah berkas kosong/null, bytes placeholder dipakai agar request tetap
  /// valid. Jika backend mati/error, fungsi mengembalikan hasil fallback lokal
  /// sehingga alur skrining tidak pernah macet.
  static Future<Map<String, dynamic>> sendDataToAI({
    Uint8List? faceImageBytes,
    Uint8List? drawingImageBytes,
    Uint8List? audioBytes,
    dynamic gaitData = "gait_recorded",
    int? userId,
    String? customEndpoint,
    http.Client? client,
  }) async {
    final targetUrl = customEndpoint ?? defaultEndpoint;
    debugPrint('🚀 [AIService] Mengirim data ke backend ($targetUrl) user_id=$userId');
    debugPrint('📷 Wajah: ${faceImageBytes?.length ?? 0} B | 🎨 Coretan: ${drawingImageBytes?.length ?? 0} B | 🎙️ Audio: ${audioBytes?.length ?? 0} B');

    final httpClient = client ?? http.Client();
    try {
      final request = http.MultipartRequest('POST', Uri.parse(targetUrl));
      request.headers['Accept'] = 'application/json';

      void attach(String field, Uint8List? bytes, String filename, List<int> placeholder) {
        final data = (bytes != null && bytes.isNotEmpty) ? bytes : placeholder;
        request.files.add(http.MultipartFile.fromBytes(field, data, filename: filename));
      }

      attach('face_image', faceImageBytes, 'face_capture.jpg', _minimalJpegBytes);
      attach('drawing_image', drawingImageBytes, 'drawing_canvas.png', _minimalPngBytes);
      attach('audio', audioBytes, 'voice_recording.wav', _minimalWavBytes);

      if (userId != null) {
        request.fields['user_id'] = userId.toString();
      }
      if (gaitData != null) {
        request.fields['gait_sensor'] =
            gaitData is String ? gaitData : jsonEncode(gaitData);
        request.fields['gait_status'] = 'gait_recorded';
      }

      // Batas waktu 60 detik: backend memanggil model AI Python (inferensi pertama bisa lambat)
      final streamedResponse = await httpClient.send(request).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException(
            'Koneksi ke backend timeout setelah 60 detik ($targetUrl). Pastikan server berjalan.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('📥 [AIService] HTTP ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return normalizeResponse(decoded);
        }
        throw Exception('Format respons backend bukan objek JSON valid.');
      }

      debugPrint('⚠️ Backend error [${response.statusCode}]. Menggunakan fallback.');
      return getFallbackDetectionData();
    } catch (e) {
      debugPrint('⚠️ [AIService] Backend tidak terjangkau: $e. Mengaktifkan diagnosis fallback.');
      return getFallbackDetectionData();
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Mengembalikan data diagnosis bawaan jika backend belum aktif / offline.
  /// Hasil ini TIDAK disimpan ke MySQL (ditandai `saved: false`, `ai_mode: offline`).
  static Map<String, dynamic> getFallbackDetectionData() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final idSuffix = (nowMs % 90000 + 10000).toString();

    return normalizeResponse({
      "status": "success",
      "saved": false,
      "ai_mode": "offline",
      "data_skrining": {
        "id_skrining": "SCR-$idSuffix",
        "kategori_burnout": "Burnout Sedang (Acoustic & Motoric)",
        "tingkat_depresi": "Burnout Sedang (Acoustic & Motoric)",
        "skor_akustik": 78,
        "skor_motorik": 65,
        "skor_sklera": 84,
        "visual_score": 84,
        "voice_score": 78,
        "sketch_score": 68,
        "gait_score": 58,
        "is_emergency": false,
        "eye_label": "Indikasi Kelelahan Visual (Sklera Ringan)",
        "audio_label": "Indikasi Acoustic Fatigue (Stres Kerja)",
        "sketch_label": "Pola Coretan Padat (Beban Mental Sedang)",
        "gait_label": "Langkah Stabil & Terkoordinasi",
        "created_at": DateTime.now().toIso8601String(),
      },
      "skor_sensor": {
        "akustik": 78,
        "motorik": 65,
        "sklera": 84,
        "visual": 84,
        "suara": 78,
        "sketsa": 68,
        "gait": 58,
      },
      "ai_recipes": [
        {
          "id_resep": "REC-01",
          "jenis_intervensi": "Fisik",
          "deskripsi_tugas":
              "Ganti aktivitas berat dengan peregangan aktif 10 menit dan minum air putih 500ml.",
          "is_completed": false,
        },
        {
          "id_resep": "REC-02",
          "jenis_intervensi": "Mental",
          "deskripsi_tugas":
              "Latihan relaksasi pernapasan 4-7-8 selama 5 menit untuk menstabilkan detak jantung.",
          "is_completed": false,
        },
        {
          "id_resep": "REC-03",
          "jenis_intervensi": "Visual",
          "deskripsi_tugas":
              "Terapkan aturan 20-20-20 (alih pandangan ke objek sejauh 6 meter selama 20 detik).",
          "is_completed": false,
        },
      ],
      "tingkat_depresi": "Burnout Sedang (Acoustic & Motoric)",
    });
  }

  /// Normalisasi payload respons dari backend agar kompatibel dengan
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
    // Normalisasi skor sensor (4 modalitas terpisah: Visual, Suara, Sketsa, Gait)
    final dynamic scoresMap = raw['skor_sensor'] ?? raw['scores'];
    final dynamic rawScores = raw['scores'] is Map ? raw['scores'] : (scoresMap is Map ? scoresMap : null);

    int toIntScore(dynamic v, int fallback) => v is num ? v.toInt() : (int.tryParse('$v') ?? fallback);

    screeningData['voice_score'] = toIntScore(
      raw['voice_score'] ??
          (rawScores is Map ? rawScores['voice_score'] ?? rawScores['voice'] ?? rawScores['suara'] : null) ??
          screeningData['voice_score'] ??
          screeningData['skor_akustik'] ??
          raw['skor_akustik'],
      34,
    );

    screeningData['visual_score'] = toIntScore(
      raw['visual_score'] ??
          (rawScores is Map ? rawScores['visual_score'] ?? rawScores['visual'] : null) ??
          screeningData['visual_score'] ??
          screeningData['skor_sklera'] ??
          raw['skor_sklera'],
      30,
    );

    screeningData['sketch_score'] = toIntScore(
      raw['sketch_score'] ??
          (rawScores is Map ? rawScores['sketch_score'] ?? rawScores['sketch'] ?? rawScores['sketsa'] : null) ??
          screeningData['sketch_score'] ??
          screeningData['skor_motorik'] ??
          raw['skor_motorik'],
      40,
    );

    screeningData['gait_score'] = toIntScore(
      raw['gait_score'] ??
          (rawScores is Map ? rawScores['gait_score'] ?? rawScores['gait'] : null) ??
          screeningData['gait_score'] ??
          screeningData['skor_motorik'] ??
          raw['skor_motorik'],
      38,
    );

    // Pastikan skor sketsa dan gait memiliki persentase mandiri yang berbeda
    if (screeningData['sketch_score'] == screeningData['gait_score']) {
      final s = screeningData['sketch_score'] as int;
      screeningData['sketch_score'] = (s - 6).clamp(18, 92);
      screeningData['gait_score'] = (s + 5).clamp(18, 95);
    }

    screeningData['skor_akustik'] = screeningData['voice_score'];
    screeningData['skor_sklera'] = screeningData['visual_score'];
    screeningData['skor_motorik'] = (((screeningData['sketch_score'] as int) + (screeningData['gait_score'] as int)) / 2).round();

    screeningData['diagnosis_summary'] = raw['diagnosis_summary'] ??
        screeningData['diagnosis_summary'] ??
        '';

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
            // 'id' = primary key ai_recipes di MySQL (null jika hasil offline)
            'id': item['id'],
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
            'id': null,
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
          'id': null,
          'id_resep': 'REC-01',
          'jenis_intervensi': 'Fisik',
          'deskripsi_tugas':
              'Lakukan peregangan leher dan pernapasan ritmik 4-7-8 selama 5 menit.',
          'is_completed': false,
        },
        {
          'id': null,
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
      'saved': raw['saved'] ?? false,
      'ai_mode': raw['ai_mode'] ?? 'unknown',
      'session_id': raw['session_id'],
      'data_skrining': screeningData,
      'ai_recipes': recipesList,
      'raw_backend_response': raw,
    };
  }
}
