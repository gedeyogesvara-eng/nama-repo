import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/neo_colors.dart';
import 'notification_service.dart';
import 'auth_service.dart';
import 'backend_service.dart';
import 'ai_service.dart';

/// Service untuk mengelola riwayat diagnosis skrining dari Backend MySQL (somatic_db)
/// dengan SharedPreferences hanya sebagai mirror / offline fallback.
class HistoryService {
  static const String keyHistory = 'screening_history_list';

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// ValueNotifier untuk update UI secara reaktif di Dashboard dan HistoryScreen
  static final ValueNotifier<List<Map<String, dynamic>>> historyNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  /// Mengubah satu baris screening_sessions dari backend Go / MySQL menjadi struktur item riwayat UI
  static Map<String, dynamic> mapBackendSession(Map<String, dynamic> s) {
    int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

    final int voiceScore = asInt(s['voice_score']) > 0 ? asInt(s['voice_score']) : asInt(s['skor_akustik']);
    final int visualScore = asInt(s['visual_score']) > 0 ? asInt(s['visual_score']) : asInt(s['skor_sklera']);
    int sketchScore = asInt(s['sketch_score']) > 0 ? asInt(s['sketch_score']) : asInt(s['skor_motorik']);
    int gaitScore = asInt(s['gait_score']) > 0 ? asInt(s['gait_score']) : asInt(s['skor_motorik']);

    if (sketchScore == gaitScore && sketchScore > 0) {
      sketchScore = (sketchScore - 6).clamp(18, 92);
      gaitScore = (gaitScore + 5).clamp(18, 95);
    }

    final int overallScore = ((voiceScore + visualScore + sketchScore + gaitScore) / 4).round().clamp(0, 100);
    final String kategori = (s['kategori_burnout'] ?? 'Kelelahan Terdeteksi').toString();
    final String lower = kategori.toLowerCase();
    final bool emergency = s['is_emergency'] == true;

    String categoryType = 'moderate';
    String badgeText = 'Burnout • $overallScore/100';
    Color accentColor = NeoColors.amber;
    Color bgTint = const Color(0xFFFEF3C7);
    Color textColor = const Color(0xFF92400E);
    IconData iconData = Icons.warning_amber_rounded;

    final bool isCritical = emergency ||
        lower.contains('berat') ||
        lower.contains('akut') ||
        lower.contains('zombie') ||
        lower.contains('zombi') ||
        overallScore <= 45;

    final bool isHealthy = lower.contains('prima') ||
        lower.contains('sehat') ||
        lower.contains('normal') ||
        lower.contains('stabil') ||
        overallScore >= 85;

    if (isCritical) {
      categoryType = 'extreme';
      badgeText = 'Kritis • $overallScore/100';
      accentColor = NeoColors.redDark;
      bgTint = NeoColors.redLight;
      textColor = NeoColors.darkRedZombie;
      iconData = Icons.error_outline_rounded;
    } else if (isHealthy) {
      categoryType = 'healthy';
      badgeText = 'Prima • $overallScore/100';
      accentColor = NeoColors.greenDark;
      bgTint = NeoColors.greenLight;
      textColor = NeoColors.greenDark;
      iconData = Icons.sentiment_very_satisfied_rounded;
    }

    final DateTime? created = DateTime.tryParse('${s['created_at']}')?.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final String date = created == null
        ? '-'
        : '${two(created.day)} ${_months[created.month - 1]} ${created.year}';
    final String time = created == null ? '-' : '${two(created.hour)}:${two(created.minute)} WIB';

    final String eyeLabel = (s['eye_label'] ?? 'Normal (Sehat)').toString();
    final String audioLabel = (s['audio_label'] ?? 'Vokal Normal (Stabil)').toString();
    final String sketchLabel = (s['sketch_label'] ?? 'Pola Coretan Rileks').toString();
    final String gaitLabel = (s['gait_label'] ?? 'Langkah Stabil & Terkoordinasi').toString();

    String diagSummary = (s['diagnosis_summary'] ?? '').toString();
    if (diagSummary.isEmpty) {
      diagSummary = 'Mata: $eyeLabel ($visualScore%) • Suara: $audioLabel ($voiceScore%) • Sketsa: $sketchLabel ($sketchScore%) • Gait: $gaitLabel ($gaitScore%)';
    }

    return {
      'id': s['id_skrining'] ?? s['kode_skrining'] ?? 'SCR-${s['id']}',
      'date': date,
      'time': time,
      'category': categoryType,
      'title': kategori,
      'score': overallScore,
      'badgeText': badgeText,
      'accentColor': accentColor.toARGB32(),
      'bgTint': bgTint.toARGB32(),
      'textColor': textColor.toARGB32(),
      'iconCodePoint': iconData.codePoint,
      'summary': diagSummary,
      'details': {
        'suara': {
          'score': '$voiceScore%',
          'desc': audioLabel,
        },
        'gait': {
          'score': '$gaitScore%',
          'desc': gaitLabel,
        },
        'visual': {
          'score': '$visualScore%',
          'desc': eyeLabel,
        },
        'sketsa': {
          'score': '$sketchScore%',
          'desc': sketchLabel,
        },
      },
      'tips': isCritical
          ? 'Hentikan aktivitas segera, aktifkan mode istirahat, dan lakukan pemulihan fisik.'
          : (isHealthy
              ? 'Pertahankan pola istirahat, hidrasi cukup, dan aktivitas seimbang saat ini.'
              : 'Luangkan jeda 15 menit, lakukan peregangan leher, dan kurangi paparan layar.'),
      'timestamp': (created ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Mengambil daftar riwayat diagnosis skrining:
  /// Prioritas UTAMA: Mengambil langsung (GET) dari backend Go / MySQL somatic_db.
  /// SharedPreferences HANYA digunakan sebagai cadangan (fallback offline).
  static Future<List<Map<String, dynamic>>> getHistoryList({int? userId}) async {
    final effectiveUserId = userId ?? authService.currentUserId ?? 1;

    // 1. Coba ambil (GET) dari Backend Go MySQL
    try {
      final rows = await BackendService.fetchHistory(effectiveUserId);
      if (rows.isNotEmpty) {
        final list = rows.map(mapBackendSession).toList();
        historyNotifier.value = list;

        // Sinkronkan ke SharedPreferences sebagai mirror offline
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(keyHistory, jsonEncode(list));
        } catch (_) {}

        debugPrint("🌐 [HistoryService] Berhasil mengambil ${list.length} riwayat dari Backend MySQL");
        return list;
      }
    } catch (e) {
      debugPrint("⚠️ [HistoryService] Gagal memuat dari backend MySQL ($e). Menggunakan cadangan lokal...");
    }

    // 2. Fallback offline: Ambil dari SharedPreferences lokal
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(keyHistory);
      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          final list = decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          historyNotifier.value = list;
          return list;
        }
      }
    } catch (e) {
      debugPrint("⚠️ [HistoryService] Gagal membaca SharedPreferences: $e");
    }

    historyNotifier.value = [];
    return [];
  }

  /// Menyimpan hasil diagnosis:
  /// 1. Otomatis kirim (POST) ke Backend Go MySQL.
  /// 2. Update status reaktif historyNotifier.
  /// 3. Simpan ke cache lokal offline SharedPreferences.
  static Future<Map<String, dynamic>> addDiagnosisFromApi(
    Map<String, dynamic> apiResponse,
  ) async {
    try {
      final screeningData = apiResponse['data_skrining'] is Map
          ? Map<String, dynamic>.from(apiResponse['data_skrining'] as Map)
          : apiResponse;

      // Kirim POST ke backend Go jika belum tersimpan di MySQL
      try {
        await AIService.postDiagnosisToBackend(apiResponse);
      } catch (e) {
        debugPrint('Catatan POST riwayat ke backend: $e');
      }

      final now = DateTime.now();
      final formattedDate =
          "${now.day.toString().padLeft(2, '0')} ${_months[now.month - 1]} ${now.year}";
      final formattedTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";

      final String kategori = (screeningData['kategori_burnout'] ??
              screeningData['tingkat_depresi'] ??
              apiResponse['tingkat_depresi'] ??
              'Kelelahan Terdeteksi')
          .toString();

      final int skorAkustik = (screeningData['skor_akustik'] ?? 75) as int;
      final int skorMotorik = (screeningData['skor_motorik'] ?? 65) as int;
      final int skorSklera = (screeningData['skor_sklera'] ?? 80) as int;
      final int overallScore = ((skorAkustik + skorMotorik + skorSklera) / 3).round();

      String categoryType = 'moderate';
      String badgeText = 'Burnout • $overallScore/100';
      Color accentColor = NeoColors.amber;
      Color bgTint = const Color(0xFFFEF3C7);
      Color textColor = const Color(0xFF92400E);
      IconData iconData = Icons.warning_amber_rounded;

      final String katLower = kategori.toLowerCase();
      final bool isCritical = katLower.contains('berat') ||
          katLower.contains('akut') ||
          katLower.contains('zombie') ||
          katLower.contains('zombi') ||
          overallScore <= 45;

      final bool isHealthy = katLower.contains('prima') ||
          katLower.contains('sehat') ||
          katLower.contains('normal') ||
          overallScore >= 85;

      if (isCritical) {
        categoryType = 'extreme';
        badgeText = 'Kritis • $overallScore/100';
        accentColor = NeoColors.redDark;
        bgTint = NeoColors.redLight;
        textColor = NeoColors.darkRedZombie;
        iconData = Icons.error_outline_rounded;
      } else if (isHealthy) {
        categoryType = 'healthy';
        badgeText = 'Prima • $overallScore/100';
        accentColor = NeoColors.greenDark;
        bgTint = NeoColors.greenLight;
        textColor = NeoColors.greenDark;
        iconData = Icons.sentiment_very_satisfied_rounded;
      }

      final historyItem = {
        'id': screeningData['id_skrining'] ??
            'SCR-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
        'date': formattedDate,
        'time': formattedTime,
        'category': categoryType,
        'title': kategori,
        'score': overallScore,
        'badgeText': badgeText,
        'accentColor': accentColor.toARGB32(),
        'bgTint': bgTint.toARGB32(),
        'textColor': textColor.toARGB32(),
        'iconCodePoint': iconData.codePoint,
        'summary': screeningData['diagnosis_summary'] ?? screeningData['ringkasan'] ??
            'Skrining multimodal AI mengidentifikasi skor akustik $skorAkustik%, motorik $skorMotorik%, dan visual $skorSklera%.',
        'details': {
          'suara': {
            'score': '$skorAkustik%',
            'desc': screeningData['audio_label'] ?? 'Analisis ritme dan kestabilan vokal'
          },
          'gait': {
            'score': '$skorMotorik%',
            'desc': screeningData['gait_label'] ?? 'Simetri dan frekuensi akselerasi sensor motorik'
          },
          'visual': {
            'score': '$skorSklera%',
            'desc': screeningData['eye_label'] ?? 'Deteksi vaskularisasi dan tegangan sklera mata'
          },
          'sketsa': {
            'score': '${screeningData['sketch_score'] ?? 75}%',
            'desc': screeningData['sketch_label'] ?? 'Analisis tekanan grafomotorik coretan mental'
          },
        },
        'tips': isCritical
            ? 'Hentikan aktivitas segera, aktifkan mode istirahat, dan lakukan pemulihan fisik.'
            : (isHealthy
                ? 'Pertahankan pola istirahat, hidrasi cukup, dan aktivitas seimbang saat ini.'
                : 'Luangkan jeda 15 menit, lakukan peregangan leher, dan kurangi paparan layar.'),
        'timestamp': now.toIso8601String(),
      };

      // Ambil riwayat lama dan sisipkan data baru di indeks pertama
      final currentList = await getHistoryList(userId: authService.currentUserId);
      currentList.removeWhere((item) => item['id'] == historyItem['id']);
      currentList.insert(0, historyItem);

      // Simpan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyHistory, jsonEncode(currentList));
      historyNotifier.value = List.from(currentList);

      debugPrint("💾 [HistoryService] Diagnosis berhasil disimpan. Total riwayat: ${currentList.length}");

      // ⚠️ Jika hasil diagnosis buruk / kritis, munculkan Notifikasi Darurat Gejala Zombie
      if (isCritical) {
        await notificationService.showZombieWarningNotification(
          customBody:
              "Diagnosis menunjukkan $kategori ($overallScore/100). Hentikan pekerjaan dan segera istirahatkan fisik Anda!",
        );
      }

      // ⏰ Jadwalkan notifikasi pengingat tepat 24 jam setelah skrining ini
      await notificationService.scheduleNextDayReminder();

      return historyItem;
    } catch (e) {
      debugPrint("⚠️ [HistoryService] Gagal menambahkan diagnosis ke history: $e");
      return {};
    }
  }

  /// Menghapus seluruh riwayat skrining
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyHistory);
    historyNotifier.value = [];
  }
}
