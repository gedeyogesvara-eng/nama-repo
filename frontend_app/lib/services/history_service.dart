import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/neo_colors.dart';
import 'notification_service.dart';

/// Service untuk mengelola penyimpanan lokal riwayat diagnosis skrining secara persisten
class HistoryService {
  static const String keyHistory = 'screening_history_list';

  /// ValueNotifier untuk update UI secara reaktif di Dashboard dan HistoryScreen
  static final ValueNotifier<List<Map<String, dynamic>>> historyNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  /// Mengambil daftar riwayat skrining dari SharedPreferences (awalnya kosong [])
  static Future<List<Map<String, dynamic>>> getHistoryList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(keyHistory);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        historyNotifier.value = [];
        return [];
      }

      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        final list = decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        historyNotifier.value = list;
        return list;
      }
    } catch (e) {
      debugPrint("⚠️ [HistoryService] Gagal memuat riwayat: $e");
    }
    historyNotifier.value = [];
    return [];
  }

  /// Menyimpan hasil diagnosis sukses dari API AI ke dalam historyList & SharedPreferences
  static Future<Map<String, dynamic>> addDiagnosisFromApi(
    Map<String, dynamic> apiResponse,
  ) async {
    try {
      final screeningData = apiResponse['data_skrining'] is Map
          ? Map<String, dynamic>.from(apiResponse['data_skrining'] as Map)
          : apiResponse;

      final now = DateTime.now();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final formattedDate =
          "${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}";
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
          katLower.contains('ekstrem') ||
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
        'summary': screeningData['ringkasan'] ??
            'Skrining multimodal AI mengidentifikasi skor akustik $skorAkustik%, motorik $skorMotorik%, dan visual $skorSklera%.',
        'details': {
          'suara': {
            'score': '$skorAkustik%',
            'desc': screeningData['audio_label'] ?? 'Analisis ritme dan kestabilan vokal'
          },
          'gait': {
            'score': '$skorMotorik%',
            'desc': 'Simetri dan frekuensi akselerasi sensor motorik'
          },
          'visual': {
            'score': '$skorSklera%',
            'desc': screeningData['eye_label'] ?? 'Deteksi vaskularisasi dan tegangan sklera mata'
          },
          'sketsa': {
            'score': '75%',
            'desc': 'Analisis tekanan grafomotorik coretan mental'
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
      final currentList = await getHistoryList();
      currentList.insert(0, historyItem);

      // Simpan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyHistory, jsonEncode(currentList));
      historyNotifier.value = List.from(currentList);

      debugPrint("💾 [HistoryService] Diagnosis berhasil disimpan ke SharedPreferences. Total riwayat: ${currentList.length}");

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
