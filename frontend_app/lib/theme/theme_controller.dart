import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengelola status tema (Light / Dark Mode) global dengan persistensi SharedPreferences
class ThemeController {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  static const String _themePrefKey = 'app_theme_mode';

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  /// Memuat tema tersimpan dari SharedPreferences saat aplikasi dinyalakan
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themePrefKey);
      if (savedMode == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else if (savedMode == 'light') {
        themeModeNotifier.value = ThemeMode.light;
      } else {
        themeModeNotifier.value = ThemeMode.light;
      }
    } catch (e) {
      debugPrint('Gagal memuat preferensi tema: $e');
    }
  }

  /// Mengatur tema secara eksplisit dan menyimpannya
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Gagal menyimpan tema: $e');
    }
  }

  /// Berpindah antara Tema Terang dan Tema Gelap secara instan
  Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

final themeController = ThemeController();
