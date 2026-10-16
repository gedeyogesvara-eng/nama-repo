// ignore_for_file: prefer_const_constructors
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service untuk menangani inisialisasi, pengiriman, dan penjadwalan notifikasi lokal (Zoned Schedule).
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

  /// 1. Inisialisasi pengaturan Android & iOS dengan ikon bawaan @mipmap/ic_launcher
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
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        } catch (_) {
          // Fallback ke default timezone jika Asia/Jakarta tidak terpetakan
        }
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

      // Meminta izin runtime notifikasi untuk Android 13+ (API 33+)
      if (!kIsWeb) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
        try {
          await androidPlugin?.requestExactAlarmsPermission();
        } catch (e) {
          debugPrint("ℹ️ [NotificationService] Exact alarm notice: $e");
        }
      }

      _isInitialized = true;
      debugPrint("✅ [NotificationService] Berhasil diinisialisasi.");
    } catch (e) {
      debugPrint("⚠️ [NotificationService] Gagal inisialisasi: $e");
    }
  }

  /// 2. Menjadwalkan notifikasi presisi berbasis zona waktu (Zoned Schedule Notification)
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
    String type = 'reminder',
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    DateTime targetTime = scheduledDateTime;
    final now = DateTime.now();

    // Jika waktu yang dipilih sudah lewat hari ini dan tanpa pengulangan, sesuaikan ke 1 menit ke depan
    if (targetTime.isBefore(now) && matchDateTimeComponents == null) {
      targetTime = now.add(const Duration(minutes: 1));
    }

    tz.TZDateTime scheduledDate;
    try {
      scheduledDate = tz.TZDateTime.from(targetTime, tz.local);
    } catch (_) {
      try {
        tz.initializeTimeZones();
        scheduledDate = tz.TZDateTime.from(targetTime, tz.local);
      } catch (e) {
        debugPrint("⚠️ [NotificationService] TimeZone fallback: $e");
        scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
      }
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scheduled_reminders_channel',
      'Pengingat Jadwal & Goals RestGuard',
      channelDescription:
          'Kanal pengingat terjadwal untuk waktu skrining dan pencapaian target goals pemulihan',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF314BB5),
      enableVibration: true,
      playSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    if (!_isTestEnv) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          scheduledDate: scheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          title: title,
          body: body,
          payload: payload ?? 'schedule_$id',
          matchDateTimeComponents: matchDateTimeComponents,
        );
        debugPrint("📅 [NotificationService] ZonedSchedule berhasil dijadwalkan: #$id pada $scheduledDate");
      } catch (e) {
        debugPrint("⚠️ [NotificationService] Exact alarm fallback: $e");
        try {
          await _notificationsPlugin.zonedSchedule(
            id: id,
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: title,
            body: body,
            payload: payload ?? 'schedule_$id',
            matchDateTimeComponents: matchDateTimeComponents,
          );
        } catch (err) {
          debugPrint("⚠️ [NotificationService] Gagal zonedSchedule: $err");
        }
      }
    }

    // Catat ke riwayat lokal agar pengguna melihat notifikasi yang dijadwalkan
    await addNotificationToHistory(
      title: title,
      body: body,
      type: type,
    );

    return true;
  }

  /// 3. Menjadwalkan Pengingat Skrining (misal 15 menit sebelum waktu skrining tiba)
  Future<bool> scheduleScreeningReminder({
    required DateTime screeningDateTime,
    int minutesBefore = 15,
  }) async {
    final DateTime reminderTime =
        screeningDateTime.subtract(Duration(minutes: minutesBefore));
    final DateTime targetTime =
        reminderTime.isBefore(DateTime.now()) ? screeningDateTime : reminderTime;

    const String title = "Yuk, luangkan waktu sejenak untuk skrining!";
    final String timeStr =
        "${screeningDateTime.hour.toString().padLeft(2, '0')}:${screeningDateTime.minute.toString().padLeft(2, '0')}";
    final String body =
        "Pengingat Skrining: Waktunya cek ritme tubuh dan kesehatan mentalmu pukul $timeStr WIB (15 menit lagi)!";

    return await scheduleNotification(
      id: 1001,
      title: title,
      body: body,
      scheduledDateTime: targetTime,
      payload: 'screening_reminder_1001',
      type: 'reminder',
    );
  }

  /// 4. Menjadwalkan Pengingat Rutinitas Target Goals (Harian / Berulang)
  Future<bool> scheduleGoalReminder({
    required int goalId,
    required String goalTitle,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    var scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Jika jam hari ini sudah lewat, jadwalkan untuk besok
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    const String title = "Waktunya menyelesaikan goals pemulihanmu hari ini!";
    final String timeStr =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    final String body =
        "Fokus Pemulihan: Waktunya '$goalTitle' (Target $timeStr WIB). Yuk, luangkan waktu sejenak!";

    final int notifId = 3000 + (goalId % 5000);

    return await scheduleNotification(
      id: notifId,
      title: title,
      body: body,
      scheduledDateTime: scheduledDateTime,
      payload: 'goal_reminder_$goalId',
      type: 'reminder',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 5. Membatalkan Pengingat Notifikasi Berdasarkan ID
  Future<void> cancelNotification(int id) async {
    if (!_isTestEnv) {
      try {
        await _notificationsPlugin.cancel(id: id);
        debugPrint("🔕 [NotificationService] Notifikasi #$id berhasil dibatalkan.");
      } catch (e) {
        debugPrint("⚠️ [NotificationService] Gagal membatalkan notifikasi #$id: $e");
      }
    }
  }

  /// Membatalkan pengingat goal tertentu
  Future<void> cancelGoalReminder(int goalId) async {
    final int notifId = 3000 + (goalId % 5000);
    await cancelNotification(notifId);
  }

  /// Menampilkan / mencatat notifikasi peringatan zombi (format fleksibel)
  Future<void> showZombieWarning({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint("🚨 [NotificationService] $title: $body");
    await addNotificationToHistory(title: title, body: body, type: 'warning');
  }

  /// Notifikasi Darurat ketika pengguna mendapatkan hasil diagnosis buruk (Zombie/Burnout Akut)
  Future<void> showZombieWarningNotification({
    String? title,
    String? body,
    String? customBody,
    String? scoreText,
  }) async {
    final effectiveTitle = title ?? "⚠️ Peringatan Gejala Zombie/Burnout terdeteksi!";
    final effectiveBody = customBody ?? body ??
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
          title: effectiveTitle,
          body: effectiveBody,
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
      title: effectiveTitle,
      body: effectiveBody,
      type: 'warning',
    );
  }

  /// Menjadwalkan pengingat harian pada jam & menit tertentu
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    String type = 'scheduled',
  }) async {
    final now = DateTime.now();
    var scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: 2000 + hour * 60 + minute,
      title: title,
      body: body,
      scheduledDateTime: scheduledDateTime,
      type: type,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Menjadwalkan notifikasi tepat 24 jam setelah skrining terakhir dilakukan
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

  /// Alias kompatibilitas
  Future<void> clearHistory() => clearNotificationHistory();
}

final notificationService = NotificationService();
