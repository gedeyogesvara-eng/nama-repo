import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Konfigurasi alamat backend Go (Gin).
///
/// - Web (Chrome) & Desktop : http://127.0.0.1:8081
/// - Android Emulator       : http://10.0.2.2:8081
/// - HP fisik / alamat lain : dapat diatur langsung di menu profil aplikasi
///   atau melalui `flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8081`
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');
  static String? _customUrl;

  /// Memuat kustom URL server yang tersimpan di memori perangkat
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customUrl = prefs.getString('custom_api_base_url');
    } catch (_) {}
  }

  /// Mengatur dan menyimpan alamat server baru secara instan
  static Future<void> setCustomBaseUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    _customUrl = cleaned.isEmpty ? null : cleaned;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customUrl == null) {
        await prefs.remove('custom_api_base_url');
      } else {
        await prefs.setString('custom_api_base_url', _customUrl!);
      }
    } catch (_) {}
  }

  /// Mengembalikan basis URL aktif saat ini
  static String get baseUrl {
    if (_customUrl != null && _customUrl!.isNotEmpty) {
      return _customUrl!;
    }
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8081';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // IP Laptop di jaringan Wi-Fi untuk testing APK di HP Android fisik
      return 'http://192.168.18.12:8081';
    }
    return 'http://localhost:8081';
  }
}
