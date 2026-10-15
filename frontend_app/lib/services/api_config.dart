import 'package:flutter/foundation.dart';

/// Konfigurasi alamat backend Go (Gin).
///
/// - Web (Chrome) & Desktop : http://127.0.0.1:8081
/// - Android Emulator       : http://10.0.2.2:8081
/// - HP fisik / alamat lain : jalankan dengan
///   `flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8081`
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8081';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // IP Laptop di jaringan Wi-Fi untuk testing APK di HP Android fisik
      return 'http://192.168.18.12:8081';
    }
    return 'http://localhost:8081';
  }
}
