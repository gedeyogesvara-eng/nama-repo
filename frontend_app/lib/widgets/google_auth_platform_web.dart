import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_auth_config.dart';
import 'google_auth_types.dart';

/// Singleton instance GoogleSignIn untuk web agar konfigurasi client ID konsisten
final GoogleSignIn _webGoogleSignIn = GoogleSignIn(
  clientId: GoogleAuthConfig.clientId.isNotEmpty ? GoogleAuthConfig.clientId : null,
  scopes: const <String>[
    'email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ],
);

/// Implementasi Google Sign-In khusus Web (Chrome / Browser).
/// Membuka dialog resmi pemilihan akun Google di Chrome.
/// Karena session Google di Chrome masih aktif, pengguna TIDAK PERLU mengetik password lagi,
/// cukup 1 kali klik pada nama akun Google mereka.
Future<GoogleProfileData?> performGoogleSignIn(BuildContext context) async {
  try {
    final completer = Completer<GoogleSignInAccount?>();

    // 1. Dengarkan event reaktif perubahan akun (Google Identity Services)
    final StreamSubscription<GoogleSignInAccount?> subscription =
        _webGoogleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? acc) {
      if (acc != null && !completer.isCompleted) {
        completer.complete(acc);
      }
    });

    try {
      // 2. Buka popup/window Google di Chrome untuk memilih akun
      final directAccount = await _webGoogleSignIn.signIn();
      if (directAccount != null && !completer.isCompleted) {
        completer.complete(directAccount);
      }
    } catch (signInErr) {
      debugPrint('Google Web signIn caught: $signInErr');
    }

    // Jika proses signIn() selesai (misal user memilih akun atau menutup popup),
    // beri toleransi 500ms agar event stream sempat diterima.
    if (!completer.isCompleted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!completer.isCompleted) {
        final current = _webGoogleSignIn.currentUser;
        completer.complete(current);
      }
    }

    final GoogleSignInAccount? account = await completer.future;
    await subscription.cancel();

    if (account != null) {
      return GoogleProfileData(
        email: account.email,
        displayName: account.displayName ?? account.email.split('@').first,
        googleId: account.id,
        photoUrl: account.photoUrl,
      );
    }
  } catch (e) {
    debugPrint('Google Sign-In Web SDK error: $e');
  }

  return null;
}

/// Sign out dari Google Sign-In di aplikasi Flutter (Web).
/// PENTING: Menggunakan `signOut()` dan BUKAN `disconnect()`.
/// `signOut()` hanya membersihkan sesi di aplikasi tanpa menghapus cookie login Google di browser Chrome.
/// Dengan demikian, saat login berikutnya akun Google tetap tersedia dan TIDAK meminta password ulang!
Future<void> performGoogleSignOut() async {
  try {
    await _webGoogleSignIn.signOut();
    debugPrint('Google Sign-Out Web: Sesi lokal berhasil dibersihkan.');
  } catch (e) {
    debugPrint('Google Sign-Out Web error: $e');
  }
}
