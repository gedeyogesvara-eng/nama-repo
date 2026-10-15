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
    _isInitialized = true;
    debugPrint("✅ [NotificationService] Berhasil diinisialisasi.");
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
    await showZombieWarning(
      title: title ?? 'Peringatan Zombie/Burnout',
      body: customBody ?? body ?? 'Kondisi kesehatan mental terdeteksi menurun.',
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

  /// Kompatibilitas untuk history_service
  Future<void> scheduleNextDayReminder() async {
    await scheduleDailyReminder(
      hour: 19,
      minute: 0,
      title: 'Waktunya Skrining Rutin',
      body: 'Cek kondisi energi dan pemulihan tubuh Anda malam ini.',
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
