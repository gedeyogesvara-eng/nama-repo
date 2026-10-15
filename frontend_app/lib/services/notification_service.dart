// ignore_for_file: prefer_const_constructors
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service untuk menangani inisialisasi, pengiriman, dan penjadwalan notifikasi lokal.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _keyNotificationHistory = 'notification_history_list';
  bool _isInitialized = false;

  bool get _isTestEnv =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// 1. Inisialisasi pengaturan Android dengan ikon bawaan @mipmap/ic_launcher
  Future<void> init() async {
    if (_isInitialized) return;

    if (_isTestEnv) {
      _isInitialized = true;
      return;
    }

    try {
      // Inisialisasi TimeZone untuk penjadwalan presisi
      try {
        tz.initializeTimeZones();
      } catch (tzError) {
        debugPrint("TimeZone init notice: $tzError");
      }

      // Pengaturan Android dengan ikon aplikasi default
      final AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Pengaturan Darwin / iOS
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("🔔 [NotificationService] Notifikasi diklik: ${response.payload}");
        },
      );

      // Meminta izin runtime notifikasi untuk Android 13+ (Tiramisu / API 33)
      if (!kIsWeb) {
        final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint("✅ [NotificationService] Berhasil diinisialisasi.");
    } catch (e) {
      debugPrint("⚠️ [NotificationService] Gagal inisialisasi: $e");
    }
  }

  /// 2. Notifikasi Darurat ketika pengguna mendapatkan hasil diagnosis buruk (Zombie/Burnout Akut)
  Future<void> showZombieWarningNotification({
    String? customBody,
  }) async {
    const String title = "⚠️ Peringatan Gejala Zombie/Burnout terdeteksi!";
    final String body = customBody ??
        "Hasil analisis multimodal mendeteksi kelelahan saraf akut & deselerasi motorik. Segera hentikan aktivitas dan ambil waktu istirahat!";

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'zombie_warning_channel',
      'Peringatan Darurat Gejala Zombie',
      channelDescription:
          'Kanal darurat saat AI mendeteksi tingkat burnout ekstrem atau kelelahan saraf parah',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFDC2626),
      enableVibration: true,
      playSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    if (!_isTestEnv) {
      try {
        await _notificationsPlugin.show(
          id: 999,
          title: title,
          body: body,
          notificationDetails: platformDetails,
          payload: 'zombie_warning_alert',
        );
        debugPrint("🚨 [NotificationService] Notifikasi Zombie Warning terkirim!");
      } catch (e) {
        debugPrint("⚠️ [NotificationService] Gagal show notification: $e");
      }
    }

    // Simpan ke riwayat state notifikasi
    await addNotificationToHistory(
      title: title,
      body: body,
      type: 'warning',
    );
  }

  /// 3. Menjadwalkan notifikasi tepat 24 jam setelah skrining terakhir dilakukan
  Future<void> scheduleNextDayReminder({
    String? customBody,
  }) async {
    const String title = "⏰ Waktunya skrining hari ini!";
    final String body = customBody ??
        "Sudah 24 jam sejak skrining terakhir. Luangkan waktu 1 menit untuk cek kondisi mental & fisik Anda.";

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'next_day_reminder_channel',
      'Pengingat Skrining 24 Jam',
      channelDescription:
          'Pengingat terjadwal yang otomatis aktif 24 jam setelah skrining terakhir',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF3046B4),
      playSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    if (!_isTestEnv) {
      try {
        final scheduledDate =
            tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

        await _notificationsPlugin.zonedSchedule(
          id: 2401,
          scheduledDate: scheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          title: title,
          body: body,
          payload: 'next_day_reminder_24h',
        );
        debugPrint("📅 [NotificationService] Pengingat dijadwalkan untuk: $scheduledDate");
      } catch (e) {
        debugPrint("⚠️ [NotificationService] ZonedSchedule warning: $e");
      }
    }

    // Catat juga ke riwayat notifikasi lokal agar pengguna melihat jadwal pengingatnya
    await addNotificationToHistory(
      title: title,
      body: "Pengingat aktif (24 Jam): $body",
      type: 'reminder',
    );
  }

  /// Mengambil daftar riwayat notifikasi dari state lokal SharedPreferences
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyNotificationHistory);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return [];
      }
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      debugPrint("⚠️ [NotificationService] Gagal membaca riwayat notifikasi: $e");
    }
    return [];
  }

  /// Menambahkan notifikasi baru ke dalam riwayat SharedPreferences
  Future<void> addNotificationToHistory({
    required String title,
    required String body,
    required String type, // 'warning' | 'reminder' | 'info'
  }) async {
    try {
      final list = await getNotificationHistory();
      final now = DateTime.now();
      final formattedTime =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";

      final newEntry = {
        'id': 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'body': body,
        'type': type,
        'time': formattedTime,
        'timestamp': now.toIso8601String(),
        'is_read': false,
      };

      // Tambahkan di urutan paling atas (terbaru)
      list.insert(0, newEntry);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNotificationHistory, jsonEncode(list));
    } catch (e) {
      debugPrint("⚠️ [NotificationService] Gagal menyimpan notifikasi: $e");
    }
  }

  /// Menghapus seluruh riwayat notifikasi
  Future<void> clearNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotificationHistory);
  }
}

final notificationService = NotificationService();
