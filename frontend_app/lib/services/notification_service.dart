// ignore_for_file: prefer_const_constructors
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menangani pengiriman dan pencatatan riwayat pengingat notifikasi lokal.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _keyNotificationHistory = 'notification_history_list';
  bool _isInitialized = false;

  /// Inisialisasi service notifikasi
  Future<void> init() async {
    if (_isInitialized) return;
<<<<<<< HEAD
    _isInitialized = true;
    debugPrint("✅ [NotificationService] Berhasil diinisialisasi.");
=======

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
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
  }

  /// Menampilkan / mencatat notifikasi peringatan zombi
  Future<void> showZombieWarning({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint("🚨 [NotificationService] $title: $body");
    await _saveToHistory(title: title, body: body, type: 'warning');
  }

  /// Kompatibilitas untuk history_service
  Future<void> showZombieWarningNotification({
    String? title,
    String? body,
    String? customBody,
    String? scoreText,
  }) async {
<<<<<<< HEAD
    await showZombieWarning(
      title: title ?? 'Peringatan Zombie/Burnout',
      body: customBody ?? body ?? 'Kondisi kesehatan mental terdeteksi menurun.',
=======
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
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
    );
  }

  /// Menjadwalkan pengingat harian
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    String type = 'scheduled',
  }) async {
    debugPrint("📅 [NotificationService] Pengingat dijadwalkan pada jam $hour:$minute - $title");
    await _saveToHistory(title: title, body: body, type: type);
  }

<<<<<<< HEAD
  /// Kompatibilitas untuk history_service
  Future<void> scheduleNextDayReminder() async {
    await scheduleDailyReminder(
      hour: 19,
      minute: 0,
      title: 'Waktunya Skrining Rutin',
      body: 'Cek kondisi energi dan pemulihan tubuh Anda malam ini.',
=======
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
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
      type: 'reminder',
    );
  }

  /// Membaca riwayat notifikasi dari SharedPreferences
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = prefs.getStringList(_keyNotificationHistory) ?? [];
      return rawList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint("⚠️ [NotificationService] Gagal membaca riwayat notifikasi: $e");
      return [];
    }
  }

  /// Menghapus seluruh riwayat notifikasi
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyNotificationHistory);
    } catch (_) {}
  }

  /// Kompatibilitas alias untuk dashboard_notification_history_test
  Future<void> clearNotificationHistory() => clearHistory();

  Future<void> addNotificationToHistory({
    required String title,
    required String body,
    String type = 'info',
  }) =>
      _saveToHistory(title: title, body: body, type: type);

  Future<void> _saveToHistory({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> current = prefs.getStringList(_keyNotificationHistory) ?? [];
      final newItem = jsonEncode({
        'title': title,
        'body': body,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      });
      current.insert(0, newItem);
      if (current.length > 50) current.removeLast();
      await prefs.setStringList(_keyNotificationHistory, current);
    } catch (e) {
      debugPrint("⚠️ [NotificationService] Gagal menyimpan notifikasi: $e");
    }
  }
}

final notificationService = NotificationService();
