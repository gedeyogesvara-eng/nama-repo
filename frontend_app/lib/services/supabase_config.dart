import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi dan inisialisasi koneksi Supabase Cloud untuk Somatic.AI / RestGuard.
///
/// Anda dapat mengisi kredensial langsung pada konstanta di bawah ini,
/// atau menyuntikkannya via `--dart-define`:
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJh...
/// ```
class SupabaseConfig {
  /// URL Project Supabase Anda (ditemukan di: Project Settings -> API -> Project URL)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zqtcqkjxebrabrvifygn.supabase.co',
  );

  /// Anon Key Public Supabase Anda (ditemukan di: Project Settings -> API -> Project API keys -> `anon` `public`)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxdGNxa2p4ZWJyYWJydmlmeWduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIxNTM4NzEsImV4cCI6MjEwNzcyOTg3MX0.62WR8qPsDPz6Ij315VJYsctKoXOc3iR8lmwlZspd7OA',
  );

  static bool _isInitialized = false;

  /// Memeriksa apakah SDK Supabase telah diinisialisasi
  static bool get isInitialized => _isInitialized;

  /// Memeriksa apakah kredensial telah diganti dari nilai placeholder
  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR_SUPABASE_PROJECT_ID') &&
      !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY') &&
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty;

  /// Mengambil instance SupabaseClient aktif secara aman tanpa throw exception
  static SupabaseClient? get client {
    if (!_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return Supabase.instance.client;
  }

  /// Inisialisasi Supabase saat aplikasi Flutter booting di `main()`
  static Future<void> init() async {
    if (isConfigured) {
      try {
        await Supabase.initialize(
          url: supabaseUrl.trim(),
          // ignore: deprecated_member_use
          anonKey: supabaseAnonKey.trim(),
        );
        _isInitialized = true;
        debugPrint('⚡ [Supabase] Berhasil terhubung ke Supabase Cloud: $supabaseUrl');
      } catch (e) {
        debugPrint('⚠️ [Supabase] Inisialisasi gagal: $e');
      }
    } else {
      debugPrint('ℹ️ [Supabase] URL/Anon Key belum diatur. Menggunakan local fallback mode.');
    }
  }
}
