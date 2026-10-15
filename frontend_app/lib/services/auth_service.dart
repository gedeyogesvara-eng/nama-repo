import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Model representasi data pengguna lokal
class LocalUser {
  final String? displayName;
  final String? email;
  final String uid;

  const LocalUser({
    this.displayName,
    this.email,
    this.uid = 'local_user',
  });
}

/// ============================================================================
/// AUTH SERVICE DENGAN SIMULASI DATABASE LOKAL (SHARED PREFERENCES)
/// Menyimpan kredensial pendaftaran, session login, dan mendukung auto-login.
/// ============================================================================
class Auth {
  static final Auth _instance = Auth._internal();
  factory Auth() => _instance;
  Auth._internal();

  // Keys untuk SharedPreferences
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';
  static const String _keyName = 'user_name';
  static const String _keyIsLoggedIn = 'is_logged_in';

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  LocalUser? _currentUser;

  /// Mengambil data user yang sedang login saat ini (null jika belum login)
  LocalUser? get currentUser => _currentUser;

  final StreamController<LocalUser?> _authStateController =
      StreamController<LocalUser?>.broadcast();

  /// Stream untuk memantau perubahan status login pengguna secara realtime
  Stream<LocalUser?> get authStateChanges => _authStateController.stream;

  /// 1 & 2. Registrasi Akun Baru dengan SharedPreferences (Simulasi Database Lokal)
  /// Menyimpan user_name, user_email, user_password, serta mengubah is_logged_in menjadi true.
  Future<bool> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      String finalName = name.trim();
      String finalEmail = email.trim();
      String finalPassword = password;

      // Antisipasi jika posisi parameter tertukar saat pemanggilan
      if (name.contains('@') && !email.contains('@')) {
        finalEmail = name.trim();
        finalName = password.isNotEmpty ? password.trim() : "Pengguna";
        finalPassword = email;
      }

      if (finalName.isEmpty) {
        finalName = "Pengguna";
      }

      if (finalEmail.isEmpty || finalPassword.isEmpty) {
        throw Exception("Email dan password tidak boleh kosong.");
      }

      final prefs = await SharedPreferences.getInstance();

      // Simpan data pendaftaran secara persisten
      await prefs.setString(_keyName, finalName);
      await prefs.setString(_keyEmail, finalEmail);
      await prefs.setString(_keyPassword, finalPassword);

      // Set flag is_logged_in menjadi true
      await prefs.setBool(_keyIsLoggedIn, true);

      // Set user aktif
      _currentUser = LocalUser(
        displayName: finalName,
        email: finalEmail,
        uid: finalEmail,
      );
      _authStateController.add(_currentUser);

      return true;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Gagal mendaftar: ${e.toString()}");
    }
  }

  /// 3. Login Pengguna dengan Email & Password
  /// Membaca kredensial dari SharedPreferences, memvalidasi kecocokan, dan mengatur is_logged_in.
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      final cleanEmail = email.trim();
      final cleanPassword = password;

      if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
        throw Exception("Email dan kata sandi wajib diisi.");
      }

      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_keyEmail);
      final savedPassword = prefs.getString(_keyPassword);
      final savedName = prefs.getString(_keyName) ?? "Pengguna";

      // Cek apakah ada data pendaftaran yang tersimpan di lokal
      if (savedEmail == null || savedPassword == null) {
        throw Exception("Email atau Password salah");
      }

      // Verifikasi kecocokan email dan password
      if (savedEmail.toLowerCase() == cleanEmail.toLowerCase() &&
          savedPassword == cleanPassword) {
        // Set flag is_logged_in menjadi true
        await prefs.setBool(_keyIsLoggedIn, true);

        _currentUser = LocalUser(
          displayName: savedName,
          email: savedEmail,
          uid: savedEmail,
        );
        _authStateController.add(_currentUser);

        return true;
      } else {
        // Jika tidak cocok, lemparkan error agar UI menampilkan pesan "Email atau Password salah"
        throw Exception("Email atau Password salah");
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Gagal masuk: ${e.toString()}");
    }
  }

  /// 4. Fungsi checkLoginStatus()
  /// Membaca flag is_logged_in dari SharedPreferences.
  /// Jika true, otomatis memperbarui state _currentUser dan mengembalikan true agar app melompat ke Dashboard.
  Future<bool> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (isLoggedIn) {
        final savedName = prefs.getString(_keyName) ?? "Pengguna";
        final savedEmail = prefs.getString(_keyEmail) ?? "";
        _currentUser = LocalUser(
          displayName: savedName,
          email: savedEmail,
          uid: savedEmail.isNotEmpty ? savedEmail : 'local_user',
        );
        _authStateController.add(_currentUser);
      } else {
        _currentUser = null;
        _authStateController.add(null);
      }

      return isLoggedIn;
    } catch (e) {
      debugPrint("Error checking login status: $e");
      return false;
    }
  }

  /// 5. Fungsi logout()
  /// Mengatur flag is_logged_in menjadi false dan menavigasikan user kembali ke Welcome/Login Screen.
  Future<void> logout([BuildContext? context]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);

      _currentUser = null;
      _authStateController.add(null);

      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Navigasi kembali ke Welcome / Login screen
      final navContext = context ?? navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        Navigator.of(navContext).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error saat logout: $e");
    }
  }

  /// Alias signOut untuk kompatibilitas kode lama
  Future<void> signOut([BuildContext? context]) => logout(context);

  /// Login menggunakan Google dengan menyimpan profil ke SharedPreferences
  Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception("Login Google dibatalkan oleh pengguna.");
      }

      final String name = googleUser.displayName ?? "Pengguna Google";
      final String email = googleUser.email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, name);
      await prefs.setString(_keyEmail, email);
      await prefs.setBool(_keyIsLoggedIn, true);

      _currentUser = LocalUser(
        displayName: name,
        email: email,
        uid: email,
      );
      _authStateController.add(_currentUser);

      return true;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Gagal login dengan Google: ${e.toString()}");
    }
  }

  /// Reset Password Simulasi
  Future<bool> resetPassword(String email) async {
    try {
      final cleanEmail = email.trim();
      if (cleanEmail.isEmpty) {
        throw Exception("Alamat email tidak boleh kosong.");
      }

      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_keyEmail);

      if (savedEmail != null && savedEmail.toLowerCase() != cleanEmail.toLowerCase()) {
        throw Exception("Email ini belum terdaftar di sistem lokal.");
      }

      return true;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Gagal mengirim tautan reset: ${e.toString()}");
    }
  }
}

typedef AuthService = Auth;
final authService = Auth();
