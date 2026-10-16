import 'package:flutter/foundation.dart';

/// Konfigurasi fallback database lokal (MySQL / Go Backend).
class SupabaseConfig {
  static const bool isInitialized = false;
  static const bool isConfigured = false;

  /// Client stub untuk backward-compatibility
  static dynamic get client => null;

  /// Inisialisasi offline fallback
  static Future<void> init() async {
    debugPrint('ℹ️ [Database] Menggunakan mode database MySQL Lokal.');
  }
}
