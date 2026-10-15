import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// ============================================================================
/// PANDUAN INTEGRASI FIREBASE:
/// Agar autentikasi Firebase ini dapat terhubung ke project backend Firebase Anda:
/// 1. Pastikan Firebase CLI terinstall di terminal: `npm install -g firebase-tools`
/// 2. Jalankan perintah: `flutterfire configure`
/// 3. Pastikan `google-services.json` (untuk Android) telah terdaftar di `android/app/`.
/// 4. Aktifkan provider Email/Password dan Google Sign-In di Firebase Console.
/// ============================================================================

class Auth {
  static final Auth _instance = Auth._internal();
  factory Auth() => _instance;
  Auth._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Mengambil data user yang sedang login saat ini (null jika belum login)
  User? get currentUser => _auth.currentUser;

  /// Stream untuk memantau perubahan status login pengguna secara realtime
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// a. Registrasi Akun Baru dengan Email & Password asli ke Firebase
  Future<bool> registerWithEmail(String email, String password, {String? name}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Simpan Nama Lengkap Pengguna jika diberikan
      if (name != null && name.trim().isNotEmpty && credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
      }

      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception("Gagal mendaftar: ${e.toString()}");
    }
  }

  /// b. Login Pengguna dengan Email & Password asli ke Firebase
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception("Gagal masuk: ${e.toString()}");
    }
  }

  /// c. Login menggunakan Akun Google asli via GoogleSignIn & FirebaseAuth
  Future<bool> loginWithGoogle() async {
    try {
      // 1. Tampilkan dialog pemilihan akun Google di perangkat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Pengguna membatalkan proses sign-in
        throw Exception("Login Google dibatalkan oleh pengguna.");
      }

      // 2. Dapatkan token otentikasi dari akun Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Buat kredensial Firebase dari token Google
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase dengan kredensial tersebut
      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Gagal login dengan Google: ${e.toString()}");
    }
  }

  /// d. Kirim Tautan Reset Password asli ke Email pengguna
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception("Gagal mengirim tautan reset: ${e.toString()}");
    }
  }

  /// Logout dari Firebase dan Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error saat logout: $e");
    }
  }

  /// Konversi kode error teknis Firebase ke pesan Bahasa Indonesia yang ramah pengguna
  String _handleAuthException(FirebaseAuthException e) {
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
final authService = Auth();
