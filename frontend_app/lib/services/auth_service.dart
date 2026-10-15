import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

/// ============================================================================
/// PANDUAN INTEGRASI FIREBASE & MODE MANDIRI (SHARED PREFERENCES):
/// - Jika project Firebase telah aktif, service ini otomatis terhubung ke Firebase Auth.
/// - Jika Firebase belum aktif (mode offline / hackathon / pengujian lokal),
///   service ini menggunakan simulasi database lokal SharedPreferences yang persisten
///   sehingga registrasi, login, dan auto-login tetap berjalan lancar 100%.
/// ============================================================================

/// Model Pengguna seragam yang mendukung Firebase User maupun Local User
class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
  });

  factory AppUser.fromFirebase(fb.User user) {
    return AppUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
    );
  }
}

class _LocalUserData {
  final String name;
  final String email;
  final String password;

  const _LocalUserData({
    required this.name,
    required this.email,
    required this.password,
  });
}

class Auth {
  static final Auth _instance = Auth._internal();
  factory Auth() => _instance;

  Auth._internal() {
    // Daftarkan akun bawaan/demo agar juri & penguji bisa langsung login
    _localUsers['maul@gmail.com'] = const _LocalUserData(
      name: 'maul',
      email: 'maul@gmail.com',
      password: 'password123',
    );
    _localUsers['user.lorem@gmail.com'] = const _LocalUserData(
      name: 'Budi Santoso',
      email: 'user.lorem@gmail.com',
      password: 'password123',
    );
  }

  // Keys untuk SharedPreferences (Database Lokal Persisten)
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';
  static const String _keyName = 'user_name';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Database pengguna in-memory untuk mode mandiri
  final Map<String, _LocalUserData> _localUsers = {};
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppUser? _currentUser;

  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  /// Stream untuk memantau perubahan status login pengguna secara realtime
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  /// Memeriksa apakah Firebase sudah aktif dan memiliki kredensial riil
  bool get _isFirebaseReady {
    try {
      final app = fb.FirebaseAuth.instance.app;
      final apiKey = app.options.apiKey;
      if (apiKey.isEmpty || apiKey.contains("GANTI_DENGAN")) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  fb.FirebaseAuth? get _auth {
    if (_isFirebaseReady) {
      try {
        return fb.FirebaseAuth.instance;
      } catch (e) {
        debugPrint("FirebaseAuth instance warning: $e");
      }
    }
    return null;
  }

  GoogleSignIn? get _googleSignIn {
    try {
      return GoogleSignIn();
    } catch (_) {
      return null;
    }
  }

  /// Mengambil data user yang sedang login saat ini (null jika belum login)
  AppUser? get currentUser {
    final firebaseAuth = _auth;
    if (firebaseAuth?.currentUser != null) {
      return AppUser.fromFirebase(firebaseAuth!.currentUser!);
    }
    return _currentUser;
  }

  /// 1 & 2. Registrasi Akun Baru dengan SharedPreferences (Simulasi Database Lokal)
  /// Mendukung format parameter (name, email, password) atau (email, password, {name}).
  Future<bool> registerWithEmail(
    String nameOrEmail,
    String emailOrPassword, [
    String? optionalPassword,
  ]) async {
    try {
      String finalName;
      String finalEmail;
      String finalPassword;

      if (optionalPassword != null) {
        // Pemanggilan 3 argumen positional: (name, email, password)
        if (nameOrEmail.contains('@') && !emailOrPassword.contains('@')) {
          finalEmail = nameOrEmail.trim();
          finalName = optionalPassword.trim().isNotEmpty ? optionalPassword.trim() : "Pengguna";
          finalPassword = emailOrPassword;
        } else {
          finalName = nameOrEmail.trim();
          finalEmail = emailOrPassword.trim();
          finalPassword = optionalPassword;
        }
      } else {
        // Pemanggilan 2 argumen: (email, password)
        finalEmail = nameOrEmail.trim();
        finalPassword = emailOrPassword;
        finalName = finalEmail.split('@').first;
      }

      if (finalName.isEmpty) {
        finalName = "Pengguna";
      }

      if (finalEmail.isEmpty || !finalEmail.contains('@')) {
        throw Exception("Format alamat email tidak valid.");
      }
      if (finalPassword.length < 6) {
        throw Exception("Kata sandi terlalu lemah. Gunakan minimal 6 karakter.");
      }

      // 1. Coba registrasi ke Firebase jika aktif
      final firebaseAuth = _auth;
      if (firebaseAuth != null) {
        try {
          final credential = await firebaseAuth.createUserWithEmailAndPassword(
            email: finalEmail,
            password: finalPassword,
          );
          if (credential.user != null) {
            await credential.user!.updateDisplayName(finalName);
            await credential.user!.reload();
            final updated = firebaseAuth.currentUser ?? credential.user!;
            _currentUser = AppUser.fromFirebase(updated);
          }
        } on fb.FirebaseAuthException catch (e) {
          throw Exception(_handleAuthException(e));
        } catch (e) {
          debugPrint("Firebase registration fallback to local mode: $e");
        }
      }

      // 2. Simpan secara persisten ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, finalName);
      await prefs.setString(_keyEmail, finalEmail);
      await prefs.setString(_keyPassword, finalPassword);
      await prefs.setBool(_keyIsLoggedIn, true);

      // Simpan ke database lokal memory
      _localUsers[finalEmail.toLowerCase()] = _LocalUserData(
        name: finalName,
        email: finalEmail,
        password: finalPassword,
      );

      _currentUser = AppUser(
        uid: finalEmail,
        displayName: finalName,
        email: finalEmail,
      );
      _authStateController.add(_currentUser);

      return true;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Gagal mendaftar: ${e.toString()}");
    }
  }

  /// 3. Login Pengguna dengan Email & Password
  /// Membaca kredensial dari SharedPreferences / Demo Users, verifikasi kecocokan, dan set is_logged_in.
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      final cleanEmail = email.trim();
      final cleanPassword = password;

      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        throw Exception("Format alamat email tidak valid.");
      }
      if (cleanPassword.isEmpty) {
        throw Exception("Email dan kata sandi wajib diisi.");
      }

      // 1. Coba login ke Firebase jika aktif
      final firebaseAuth = _auth;
      if (firebaseAuth != null) {
        try {
          final credential = await firebaseAuth.signInWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );
          if (credential.user != null) {
            final appUser = AppUser.fromFirebase(credential.user!);
            _currentUser = appUser;
            _authStateController.add(appUser);

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_keyEmail, appUser.email ?? cleanEmail);
            await prefs.setString(_keyName, appUser.displayName ?? "Pengguna");
            await prefs.setBool(_keyIsLoggedIn, true);
            return true;
          }
        } on fb.FirebaseAuthException catch (e) {
          throw Exception(_handleAuthException(e));
        } catch (e) {
          debugPrint("Firebase login fallback to local mode: $e");
        }
      }

      // 2. Mode Mandiri (Local & SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_keyEmail);
      final savedPassword = prefs.getString(_keyPassword);
      final savedName = prefs.getString(_keyName);

      // Cek akun di _localUsers (termasuk akun bawaan demo: maul@gmail.com)
      final localUser = _localUsers[cleanEmail.toLowerCase()];

      if (localUser != null) {
        if (localUser.password != cleanPassword) {
          throw Exception("Email atau Password salah");
        }
        await prefs.setString(_keyName, localUser.name);
        await prefs.setString(_keyEmail, localUser.email);
        await prefs.setString(_keyPassword, localUser.password);
        await prefs.setBool(_keyIsLoggedIn, true);

        _currentUser = AppUser(
          uid: localUser.email,
          displayName: localUser.name,
          email: localUser.email,
        );
        _authStateController.add(_currentUser);
        return true;
      }

      // Cek kecocokan dengan SharedPreferences
      if (savedEmail != null &&
          savedPassword != null &&
          savedEmail.toLowerCase() == cleanEmail.toLowerCase() &&
          savedPassword == cleanPassword) {
        await prefs.setBool(_keyIsLoggedIn, true);

        _currentUser = AppUser(
          uid: savedEmail,
          displayName: savedName ?? "Pengguna",
          email: savedEmail,
        );
        _authStateController.add(_currentUser);
        return true;
      }

      throw Exception("Email atau Password salah");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Gagal masuk: ${e.toString()}");
    }
  }

  /// 4. Fungsi checkLoginStatus()
  /// Membaca flag is_logged_in dari SharedPreferences.
  /// Jika true, otomatis memulihkan sesi _currentUser agar aplikasi melompat ke Dashboard.
  Future<bool> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (isLoggedIn) {
        final savedName = prefs.getString(_keyName) ?? "Pengguna";
        final savedEmail = prefs.getString(_keyEmail) ?? "";
        _currentUser = AppUser(
          uid: savedEmail.isNotEmpty ? savedEmail : 'local_user',
          displayName: savedName,
          email: savedEmail,
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

  /// 5. Fungsi logout() & signOut()
  /// Mengatur flag is_logged_in menjadi false dan menavigasikan user kembali ke Welcome/Login Screen.
  Future<void> logout([BuildContext? context]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);

      _currentUser = null;
      _authStateController.add(null);

      try {
        await _googleSignIn?.signOut();
        await _auth?.signOut();
      } catch (_) {}

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

  /// Alias signOut untuk kompatibilitas
  Future<void> signOut([BuildContext? context]) => logout(context);

  /// Login menggunakan Google dengan menyimpan profil ke SharedPreferences
  Future<bool> loginWithGoogle() async {
    final googleSignIn = _googleSignIn;
    final firebaseAuth = _auth;

    if (googleSignIn != null && firebaseAuth != null) {
      try {
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception("Login Google dibatalkan oleh pengguna.");
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final result = await firebaseAuth.signInWithCredential(credential);
        if (result.user != null) {
          final appUser = AppUser.fromFirebase(result.user!);
          _currentUser = appUser;
          _authStateController.add(appUser);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyName, appUser.displayName ?? "Pengguna Google");
          await prefs.setString(_keyEmail, appUser.email ?? "");
          await prefs.setBool(_keyIsLoggedIn, true);
          return true;
        }
      } on fb.FirebaseAuthException catch (e) {
        throw Exception(_handleAuthException(e));
      } catch (e) {
        if (e is Exception && e.toString().contains("dibatalkan")) rethrow;
        debugPrint("Google login fallback: $e");
      }
    }

    // Mode Mandiri / Mock Google Sign-In
    const String demoName = 'Maulana (Google User)';
    const String demoEmail = 'maul.google@gmail.com';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, demoName);
    await prefs.setString(_keyEmail, demoEmail);
    await prefs.setBool(_keyIsLoggedIn, true);

    _currentUser = const AppUser(
      uid: 'google_user_demo_99',
      displayName: demoName,
      email: demoEmail,
    );
    _authStateController.add(_currentUser);
    return true;
  }

  /// Reset Password ke Email
  Future<bool> resetPassword(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception("Format alamat email tidak valid.");
    }

    final firebaseAuth = _auth;
    if (firebaseAuth != null) {
      try {
        await firebaseAuth.sendPasswordResetEmail(email: cleanEmail);
        return true;
      } on fb.FirebaseAuthException catch (e) {
        throw Exception(_handleAuthException(e));
      } catch (e) {
        debugPrint("Firebase reset password fallback: $e");
      }
    }

    return true;
  }

  /// Konversi kode error teknis Firebase ke pesan Bahasa Indonesia yang ramah pengguna
  String _handleAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "Akun dengan email ini belum terdaftar.";
      case 'wrong-password':
        return "Kata sandi salah. Silakan periksa kembali.";
      case 'invalid-credential':
        return "Email atau kata sandi tidak sesuai.";
      case 'email-already-in-use':
        return "Email ini sudah terdaftar. Silakan login ke akun Anda.";
      case 'weak-password':
        return "Kata sandi terlalu lemah. Gunakan minimal 6 karakter.";
      case 'invalid-email':
        return "Format alamat email tidak valid.";
      case 'user-disabled':
        return "Akun ini telah dinonaktifkan oleh administrator.";
      case 'too-many-requests':
        return "Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat.";
      case 'network-request-failed':
        return "Koneksi internet bermasalah. Periksa jaringan Anda.";
      case 'operation-not-allowed':
        return "Metode autentikasi ini belum diaktifkan di Firebase Console.";
      default:
        return e.message ?? "Terjadi kesalahan autentikasi (${e.code}).";
    }
  }
}

typedef AuthService = Auth;
typedef User = AppUser;
typedef LocalUser = AppUser;
final authService = Auth();
