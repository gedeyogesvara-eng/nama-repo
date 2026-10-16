import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service akses database MySQL lokal melalui REST API Backend Go.
///
/// Fitur Utama:
/// - Menggunakan HTTP Request murni (GET, POST, PATCH) tanpa ketergantungan Supabase.
/// - Base URL adaptif: Otomatis mendeteksi Emulator (10.0.2.2), HP Fisik (192.168.x.x), atau Desktop/Web (127.0.0.1).
/// - Safe JSON Parsing: Menjamin parsing tipe data MySQL (int, double, string, bool) tidak crash.
/// - Penanganan Error Komprehensif (try-catch) saat server lokal mati / offline.
class BackendService {
  // ==========================================================================
  // 1. KONFIGURASI BASE URL (MySQL Backend Server)
  // ==========================================================================

  /// URL untuk Android Emulator resmi (mengarah ke localhost komputer)
  static const String emulatorBaseUrl = 'http://10.0.2.2:8081';

  /// URL untuk testing langsung di Smartphone Android fisik via Wi-Fi lokal
  /// (Ganti dengan IP Laptop/PC Anda di jaringan Wi-Fi lokal yang sama)
  static const String physicalDeviceBaseUrl = 'http://192.168.18.12:8081';

  /// URL untuk Desktop (Windows/macOS/Linux) & Web Browser
  static const String desktopBaseUrl = 'http://127.0.0.1:8081';

  /// Custom URL manual jika Anda ingin menimpanya langsung di kode
  static String? customBaseUrl;

  /// Mengembalikan Base URL aktif saat ini dengan prioritas:
  /// 1. `customBaseUrl` (jika disetel manual)
  /// 2. `ApiConfig.baseUrl` (dari SharedPreferences atau --dart-define)
  /// 3. Deteksi platform otomatis (Emulator / HP Fisik / Web / Desktop)
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim().replaceAll(RegExp(r'/+$'), '');
    }

    final configUrl = ApiConfig.baseUrl.trim();
    if (configUrl.isNotEmpty) {
      return configUrl.replaceAll(RegExp(r'/+$'), '');
    }

    if (kIsWeb) return desktopBaseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Default Android: Bisa emulatorBaseUrl atau physicalDeviceBaseUrl
      return physicalDeviceBaseUrl;
    }
    return desktopBaseUrl;
  }

  /// Timeout standar untuk permintaan HTTP (mencegah UI macet saat server mati)
  static const Duration requestTimeout = Duration(seconds: 8);

  /// Backward-compatibility stub untuk kode lama
  static dynamic get client => null;

  // ==========================================================================
  // 2. HELPER PARSING JSON DARI MYSQL (ANTI-CRASH)
  // ==========================================================================

  static int _parseInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }


  static String _parseString(dynamic value, String fallback) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static bool _parseBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return fallback;
  }

  // ==========================================================================
  // 3. RIWAYAT SKRINING (HTTP GET & POST -> MySQL `screening_sessions`)
  // ==========================================================================

  /// Mengambil daftar riwayat skrining milik [userId] dari MySQL lokal via HTTP GET.
  /// Endpoint: `GET /api/history?user_id=:id`
  static Future<List<Map<String, dynamic>>> fetchHistory(
    int userId, {
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final url = Uri.parse('$baseUrl/api/history?user_id=$userId');

    try {
      debugPrint('🌐 [BackendService-MySQL] GET $url');
      final res = await c
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(requestTimeout);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        dynamic rawList;

        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          rawList = decoded['data'];
        } else if (decoded is List) {
          rawList = decoded;
        }

        if (rawList is List) {
          final List<Map<String, dynamic>> parsedList = [];
          for (final item in rawList) {
            if (item is Map) {
              parsedList.add(_sanitizeHistoryRecord(Map<String, dynamic>.from(item)));
            }
          }
          debugPrint('✅ [BackendService-MySQL] Berhasil memuat ${parsedList.length} riwayat dari MySQL.');
          return parsedList;
        }
      } else {
        debugPrint('⚠️ [BackendService-MySQL] Server mengembalikan status code HTTP ${res.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('⚠️ [BackendService-MySQL] Server backend mati / koneksi ditolak: $e');
    } on TimeoutException catch (_) {
      debugPrint('⚠️ [BackendService-MySQL] Request timeout ($requestTimeout). Pastikan backend Go menyala di $baseUrl');
    } catch (e) {
      debugPrint('⚠️ [BackendService-MySQL] Error saat mengambil riwayat: $e');
    } finally {
      if (client == null) c.close();
    }

    return [];
  }

  /// Menyimpan data hasil skrining diagnosis AI ke MySQL lokal via HTTP POST.
  /// Endpoint: `POST /api/history`
  static Future<bool> insertScreeningHistory(
    Map<String, dynamic> diagnosisData, {
    int? userId,
    http.Client? client,
  }) async {
    final effectiveUserId = userId ?? 1;
    final c = client ?? http.Client();

    final screeningData = diagnosisData['data_skrining'] is Map
        ? Map<String, dynamic>.from(diagnosisData['data_skrining'] as Map)
        : diagnosisData;

    final visualScore = _parseInt(
      screeningData['visual_score'] ?? screeningData['skor_sklera'],
      50,
    );
    final voiceScore = _parseInt(
      screeningData['voice_score'] ?? screeningData['skor_akustik'],
      50,
    );
    final sketchScore = _parseInt(
      screeningData['sketch_score'] ?? screeningData['skor_motorik'],
      50,
    );
    final gaitScore = _parseInt(
      screeningData['gait_score'] ?? screeningData['skor_motorik'],
      50,
    );
    final overallScore = ((visualScore + voiceScore + sketchScore + gaitScore) / 4)
        .round()
        .clamp(0, 100);

    final payload = {
      'user_id': effectiveUserId,
      'id_skrining': _parseString(
        screeningData['id_skrining'] ?? diagnosisData['id_skrining'],
        'SCR-${DateTime.now().millisecondsSinceEpoch}',
      ),
      'kode_skrining': _parseString(
        screeningData['id_skrining'] ?? diagnosisData['id_skrining'],
        'SCR-${DateTime.now().millisecondsSinceEpoch}',
      ),
      'kategori_burnout': _parseString(
        screeningData['kategori_burnout'] ?? diagnosisData['tingkat_depresi'],
        'Kelelahan Terdeteksi',
      ),
      'tingkat_depresi': _parseString(
        screeningData['kategori_burnout'] ?? diagnosisData['tingkat_depresi'],
        'Kelelahan Terdeteksi',
      ),
      'skor_keseluruhan': overallScore,
      'visual_score': visualScore,
      'voice_score': voiceScore,
      'sketch_score': sketchScore,
      'gait_score': gaitScore,
      'skor_sklera': visualScore,
      'skor_akustik': voiceScore,
      'skor_motorik': sketchScore,
      'eye_label': _parseString(screeningData['eye_label'], 'Normal'),
      'audio_label': _parseString(screeningData['audio_label'], 'Stabil'),
      'sketch_label': _parseString(screeningData['sketch_label'], 'Relaks'),
      'gait_label': _parseString(screeningData['gait_label'], 'Simetris'),
      'diagnosis_summary': _parseString(screeningData['diagnosis_summary'], ''),
      'is_emergency': _parseBool(screeningData['is_emergency'], false),
      'ai_recipes': diagnosisData['ai_recipes'] is List ? diagnosisData['ai_recipes'] : [],
      'created_at': DateTime.now().toIso8601String(),
    };

    final url = Uri.parse('$baseUrl/api/history');

    try {
      debugPrint('🌐 [BackendService-MySQL] POST $url (Simpan Skrining)');
      final res = await c
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(requestTimeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint('✅ [BackendService-MySQL] Berhasil menyimpan hasil skrining ke MySQL: ${payload['id_skrining']}');
        return true;
      } else {
        debugPrint('⚠️ [BackendService-MySQL] Gagal simpan skrining. Server HTTP ${res.statusCode}: ${res.body}');
      }
    } on SocketException catch (_) {
      debugPrint('ℹ️ [BackendService] Server lokal mati. Skrining dicatat pada penyimpanan lokal.');
    } on TimeoutException catch (_) {
      debugPrint('ℹ️ [BackendService] Timeout saat menyimpan skrining. Beralih ke penyimpanan lokal.');
    } catch (e) {
      debugPrint('ℹ️ [BackendService] Error simpan skrining: $e');
    } finally {
      if (client == null) c.close();
    }

    return false;
  }

  // ==========================================================================
  // 4. MANAJEMEN PENGGUNA (HTTP POST -> MySQL `users`)
  // ==========================================================================

  /// Menyimpan atau memverifikasi data akun pengguna ke database MySQL lokal.
  /// Endpoint: `POST /api/users`
  static Future<Map<String, dynamic>?> insertUser(
    Map<String, dynamic> userData, {
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final email = _parseString(userData['email'], '');
    if (email.isEmpty) return null;

    final name = _parseString(
      userData['nama'] ?? userData['full_name'] ?? userData['displayName'],
      email.split('@').first,
    );
    final uid = _parseString(userData['uid'] ?? userData['google_id'], email);
    final photoUrl = userData['avatar_url'] ?? userData['photo_url'] ?? userData['photoURL'];

    final payload = {
      'uid': uid,
      'email': email,
      'nama': name,
      'avatar_url': photoUrl,
      'recovery_score': _parseInt(userData['recovery_score'], 40),
      'zombie_stage': _parseString(userData['zombie_stage'], 'TIRED_ZOMBIE'),
    };

    final url = Uri.parse('$baseUrl/api/users');

    try {
      debugPrint('🌐 [BackendService-MySQL] POST $url (User Sync)');
      final res = await c
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          debugPrint('✅ [BackendService-MySQL] User berhasil disinkronkan ke MySQL: $email');
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [BackendService] Server backend offline saat sync user, menggunakan data lokal: $e');
    } finally {
      if (client == null) c.close();
    }

    // Fallback data lokal jika backend sedang mati
    return {
      'id': 1,
      'user_id': 1,
      ...payload,
    };
  }

  // ==========================================================================
  // 5. GOALS & RESEP INTERVENSI (HTTP PATCH & POST -> MySQL `ai_recipes`)
  // ==========================================================================

  /// Memperbarui status selesai tugas / resep di MySQL lokal via HTTP PATCH.
  /// Endpoint: `PATCH /api/recipes/:id/complete`
  static Future<Map<String, dynamic>?> setRecipeCompleted(
    dynamic recipeId,
    bool completed, {
    http.Client? client,
  }) async {
    final id = _parseInt(recipeId, -1);
    if (id <= 0) return null;

    final c = client ?? http.Client();
    final url = Uri.parse('$baseUrl/api/recipes/$id/complete');

    try {
      debugPrint('🌐 [BackendService-MySQL] PATCH $url (Status: $completed)');
      final res = await c
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'is_completed': completed}),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        return decoded is Map<String, dynamic> ? decoded : null;
      }
    } catch (e) {
      debugPrint('ℹ️ [BackendService-MySQL] Gagal memperbarui status resep #$id di server: $e');
    } finally {
      if (client == null) c.close();
    }

    return {'id': id, 'is_completed': completed};
  }

  /// Menambahkan resep/goals mandiri kustom buatan pengguna ke MySQL lokal via HTTP POST.
  /// Endpoint: `POST /api/recipes/custom`
  static Future<Map<String, dynamic>?> addCustomRecipe({
    required int userId,
    required String deskripsi,
    String jenis = 'Mandiri',
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final url = Uri.parse('$baseUrl/api/recipes/custom');

    final payload = {
      'user_id': userId,
      'deskripsi_tugas': deskripsi.trim(),
      'jenis_intervensi': jenis.trim(),
    };

    try {
      debugPrint('🌐 [BackendService-MySQL] POST $url (Tambah Resep Mandiri)');
      final res = await c
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['recipe'] is Map) {
          return Map<String, dynamic>.from(decoded['recipe']);
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [BackendService-MySQL] Server offline saat tambah resep mandiri: $e');
    } finally {
      if (client == null) c.close();
    }

    return null;
  }

  // ==========================================================================
  // 6. SANITASI DATA MODEL
  // ==========================================================================

  /// Menjamin seluruh tipe data dari row database MySQL dipetakan dengan aman ke model Flutter
  static Map<String, dynamic> _sanitizeHistoryRecord(Map<String, dynamic> raw) {
    return {
      'id': _parseInt(raw['id'], 0),
      'id_skrining': _parseString(raw['id_skrining'] ?? raw['kode_skrining'], 'SCR-0'),
      'kode_skrining': _parseString(raw['kode_skrining'] ?? raw['id_skrining'], 'SCR-0'),
      'kategori_burnout': _parseString(raw['kategori_burnout'] ?? raw['tingkat_depresi'], 'Kelelahan Terdeteksi'),
      'tingkat_depresi': _parseString(raw['kategori_burnout'] ?? raw['tingkat_depresi'], 'Kelelahan Terdeteksi'),
      'skor_keseluruhan': _parseInt(raw['skor_keseluruhan'] ?? raw['skor_rata_rata'], 50),
      'visual_score': _parseInt(raw['visual_score'] ?? raw['skor_sklera'], 50),
      'voice_score': _parseInt(raw['voice_score'] ?? raw['skor_akustik'], 50),
      'sketch_score': _parseInt(raw['sketch_score'] ?? raw['skor_motorik'], 50),
      'gait_score': _parseInt(raw['gait_score'] ?? raw['skor_motorik'], 50),
      'skor_sklera': _parseInt(raw['skor_sklera'] ?? raw['visual_score'], 50),
      'skor_akustik': _parseInt(raw['skor_akustik'] ?? raw['voice_score'], 50),
      'skor_motorik': _parseInt(raw['skor_motorik'] ?? raw['sketch_score'], 50),
      'eye_label': _parseString(raw['eye_label'], 'Normal'),
      'audio_label': _parseString(raw['audio_label'], 'Stabil'),
      'sketch_label': _parseString(raw['sketch_label'], 'Relaks'),
      'gait_label': _parseString(raw['gait_label'], 'Simetris'),
      'diagnosis_summary': _parseString(raw['diagnosis_summary'], ''),
      'is_emergency': _parseBool(raw['is_emergency'], false),
      'created_at': _parseString(raw['created_at'], DateTime.now().toIso8601String()),
      'ai_recipes': raw['ai_recipes'] is List ? raw['ai_recipes'] : [],
    };
  }
}
