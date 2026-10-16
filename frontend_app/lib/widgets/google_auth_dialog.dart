import 'package:flutter/widgets.dart';
import 'google_auth_types.dart';
import 'google_auth_platform_stub.dart'
    if (dart.library.io) 'google_auth_platform_io.dart'
    if (dart.library.html) 'google_auth_platform_web.dart';

export 'google_auth_types.dart';

/// Alur login / registrasi Google yang adaptif:
/// - Pada Browser Web (Chrome/Edge): Menggunakan Google Identity Services Web SDK (bebas dari error dart:io / Process).
/// - Pada Windows Desktop: Membuka Google Chrome sistem secara otomatis ke accounts.google.com via loopback server.
/// - Pada Android/iOS: Menggunakan native Google Play Services SDK.
Future<GoogleProfileData?> triggerGoogleSignInFlow(
  BuildContext context, {
  String title = 'Masuk dengan Google',
  String subtitle = 'Pilih akun untuk melanjutkan ke RestGuard AI',
}) async {
  return await performGoogleSignIn(context);
}

/// Sign out dari sesi Google di aplikasi.
/// Memastikan browser Chrome tetap mempertahankan sesi Google sehingga pengguna
/// dapat login kembali dengan 1-klik akun tanpa harus mengetik password ulang.
Future<void> triggerGoogleSignOut() async {
  await performGoogleSignOut();
}
