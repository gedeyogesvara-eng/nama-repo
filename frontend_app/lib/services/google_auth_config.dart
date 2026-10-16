/// Konfigurasi resmi Google OAuth 2.0 untuk RestGuard AI
class GoogleAuthConfig {
  /// OAuth 2.0 Client ID dari Google Cloud Console
  /// Default client ID terverifikasi dari project Google Cloud
  static const String clientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '111398799278-0g9v7nluccu1sb3puo75mdulf76to51v.apps.googleusercontent.com',
  );

  /// OAuth 2.0 Client Secret (opsional jika menggunakan flow PKCE desktop murni)
  static const String clientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: '',
  );

  /// Server Client ID (digunakan oleh SDK Android / backend)
  static const String serverClientId = clientId;

  /// Package Name Android resmi
  static const String androidPackageName = 'com.example.frontend_app';

  /// SHA-1 fingerprint dari debug.keystore laptop ini
  static const String debugSha1 = 'F8:66:50:FF:B7:A1:0B:79:48:EB:D0:14:02:38:3C:92:A1:E3:51:F8';

  /// Apakah Client ID sudah dikonfigurasi
  static bool get hasClientId => clientId.trim().isNotEmpty;

  /// Apakah Client Secret tersedia
  static bool get hasClientSecret => clientSecret.trim().isNotEmpty;
}
