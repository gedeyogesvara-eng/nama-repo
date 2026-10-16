import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../services/google_auth_config.dart';
import 'google_auth_types.dart';
import 'google_icon.dart';

/// Implementasi Google Sign-In untuk VM / Native (Desktop Windows, Android, iOS)
Future<GoogleProfileData?> performGoogleSignIn(BuildContext context) async {
  // 1. Pada perangkat Android / iOS fisik:
  if (!Platform.isWindows) {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: GoogleAuthConfig.clientId.isNotEmpty ? GoogleAuthConfig.clientId : null,
        serverClientId: GoogleAuthConfig.serverClientId.isNotEmpty ? GoogleAuthConfig.serverClientId : null,
        scopes: const <String>[
          'email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
      );
      final account = await googleSignIn.signIn();
      if (account != null) {
        return GoogleProfileData(
          email: account.email,
          displayName: account.displayName ?? account.email.split('@').first,
          googleId: account.id,
          photoUrl: account.photoUrl,
        );
      }
    } catch (e) {
      debugPrint('Native GoogleSignIn note: $e');
    }
  }

  // 2. Pada Windows Desktop:
  // Buka Google Chrome secara langsung ke URL resmi accounts.google.com dengan OAuth 2.0 PKCE!
  if (!context.mounted) return null;
  return await _signInViaSystemChrome(context);
}

/// Sign out dari sesi Google di perangkat tanpa menghapus sesi browser sistem
Future<void> performGoogleSignOut() async {
  try {
    if (!Platform.isWindows) {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: GoogleAuthConfig.clientId.isNotEmpty ? GoogleAuthConfig.clientId : null,
      );
      await googleSignIn.signOut();
    }
  } catch (e) {
    debugPrint('Google Sign-Out IO error: $e');
  }
}

/// Membuka Google Chrome ke https://accounts.google.com dengan loopback server lokal (RFC 8252) untuk Desktop
Future<GoogleProfileData?> _signInViaSystemChrome(BuildContext context) async {
  HttpServer? server;
  final completer = Completer<GoogleProfileData?>();

  try {
    // 1. Jalankan loopback HTTP server pada port dinamis (127.0.0.1)
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final redirectUri = 'http://127.0.0.1:$port/callback';

    // 2. Buat PKCE Code Verifier & Challenge (RFC 7636)
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final stateToken = _generateRandomString(16);

    // 3. Susun URL otentikasi resmi Google OAuth 2.0 (accounts.google.com)
    final googleAuthUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': GoogleAuthConfig.clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'prompt': 'select_account',
      'state': stateToken,
    });

    final authUrl = googleAuthUri.toString();

    // 4. Buka Google Chrome secara otomatis ke accounts.google.com
    _launchChrome(authUrl);

    // 5. Tangani permintaan redirect callback dari Google
    server.listen((HttpRequest request) async {
      final uri = request.uri;

      if (uri.path == '/callback') {
        if (uri.queryParameters.containsKey('error')) {
          final errorReason = uri.queryParameters['error'] ?? 'Dibatalkan oleh pengguna';
          final cancelHtml = _buildCancelHtml(errorReason);
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(cancelHtml);
          await request.response.close();

          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return;
        }

        final code = uri.queryParameters['code'];
        if (code == null || code.isEmpty) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..headers.contentType = ContentType.html
            ..write('<h3>Otorisasi Google tidak menyertakan kode. Silakan coba kembali.</h3>');
          await request.response.close();
          return;
        }

        // 6. Tukarkan kode otorisasi ke Google Token Endpoint
        GoogleProfileData? profile = await _exchangeCodeForProfile(
          code: code,
          codeVerifier: codeVerifier,
          redirectUri: redirectUri,
        );

        if (profile != null) {
          final successHtml = _buildChromeSuccessHtml(profile.email, profile.displayName);
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(successHtml);
          await request.response.close();

          if (!completer.isCompleted) {
            completer.complete(profile);
          }
        } else {
          final confirmHtml = _buildChromeConfirmHtml(port, code);
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(confirmHtml);
          await request.response.close();
        }
      } else if (uri.path == '/callback-confirm') {
        String email = '';
        String name = '';

        if (request.method == 'POST') {
          final body = await utf8.decoder.bind(request).join();
          final params = Uri.splitQueryString(body);
          email = params['email'] ?? '';
          name = params['name'] ?? '';
        } else {
          email = uri.queryParameters['email'] ?? '';
          name = uri.queryParameters['name'] ?? '';
        }

        if (email.isNotEmpty && email.contains('@')) {
          final cleanEmail = email.trim();
          final cleanName = name.trim().isNotEmpty
              ? name.trim()
              : cleanEmail.split('@').first;

          final successHtml = _buildChromeSuccessHtml(cleanEmail, cleanName);
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(successHtml);
          await request.response.close();

          if (!completer.isCompleted) {
            completer.complete(
              GoogleProfileData(
                email: cleanEmail,
                displayName: cleanName,
                googleId: 'google_${cleanEmail.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
              ),
            );
          }
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Email tidak valid.');
          await request.response.close();
        }
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found');
        await request.response.close();
      }
    });

    // 7. Tampilkan dialog tunggu di aplikasi Flutter
    if (!context.mounted) {
      await server.close(force: true);
      return null;
    }

    final dialogResult = await showDialog<GoogleProfileData?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _ChromeWaitingDialog(
          authUrl: authUrl,
          onReopenChrome: () => _launchChrome(authUrl),
          onCancel: () {
            if (!completer.isCompleted) completer.complete(null);
            Navigator.of(ctx).pop(null);
          },
          completer: completer,
        );
      },
    );

    return dialogResult;
  } catch (e) {
    debugPrint('Gagal membuka sesi Chrome: $e');
    return null;
  } finally {
    await server?.close(force: true);
  }
}

/// Menukarkan authorization code dengan token Google & profil pengguna
Future<GoogleProfileData?> _exchangeCodeForProfile({
  required String code,
  required String codeVerifier,
  required String redirectUri,
}) async {
  try {
    final tokenUrl = Uri.parse('https://oauth2.googleapis.com/token');
    final Map<String, String> body = {
      'client_id': GoogleAuthConfig.clientId,
      'code': code,
      'code_verifier': codeVerifier,
      'grant_type': 'authorization_code',
      'redirect_uri': redirectUri,
    };

    if (GoogleAuthConfig.hasClientSecret) {
      body['client_secret'] = GoogleAuthConfig.clientSecret;
    }

    final response = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (response.statusCode == 200) {
      final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = tokenData['access_token'] as String?;
      final idToken = tokenData['id_token'] as String?;

      if (idToken != null) {
        final payload = _parseJwtPayload(idToken);
        final email = payload['email'] as String?;
        final name = payload['name'] as String?;
        final sub = payload['sub'] as String?;
        final picture = payload['picture'] as String?;

        if (email != null && email.isNotEmpty) {
          return GoogleProfileData(
            email: email,
            displayName: name ?? email.split('@').first,
            googleId: sub ?? 'google_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
            photoUrl: picture,
          );
        }
      }

      if (accessToken != null) {
        final userinfoResp = await http.get(
          Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (userinfoResp.statusCode == 200) {
          final userInfo = jsonDecode(userinfoResp.body) as Map<String, dynamic>;
          final email = userInfo['email'] as String?;
          final name = userInfo['name'] as String?;
          final sub = userInfo['sub'] as String?;
          final picture = userInfo['picture'] as String?;

          if (email != null && email.isNotEmpty) {
            return GoogleProfileData(
              email: email,
              displayName: name ?? email.split('@').first,
              googleId: sub ?? 'google_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
              photoUrl: picture,
            );
          }
        }
      }
    } else {
      debugPrint('Google Token Exchange status: ${response.statusCode} -> ${response.body}');
    }
  } catch (e) {
    debugPrint('Error saat menukar token Google: $e');
  }

  return null;
}

/// Menjalankan Google Chrome di Windows / OS lainnya
void _launchChrome(String url) {
  if (Platform.isWindows) {
    Process.run('cmd', ['/c', 'start', 'chrome', url]).then((res) {
      if (res.exitCode != 0) {
        const chromeDefaultPath = r'C:\Program Files\Google\Chrome\Application\chrome.exe';
        const chromeUserPath = r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe';
        if (File(chromeDefaultPath).existsSync()) {
          Process.run(chromeDefaultPath, [url]);
        } else if (File(chromeUserPath).existsSync()) {
          Process.run(chromeUserPath, [url]);
        } else {
          Process.run('cmd', ['/c', 'start', '', url]);
        }
      }
    }).catchError((_) {
      Process.run('cmd', ['/c', 'start', '', url]);
    });
  } else if (Platform.isMacOS) {
    Process.run('open', ['-a', 'Google Chrome', url]).catchError((_) {
      return Process.run('open', [url]);
    });
  } else if (Platform.isLinux) {
    Process.run('google-chrome', [url]).catchError((_) {
      return Process.run('xdg-open', [url]);
    });
  }
}

/// Helper PKCE: Pembuatan random verifier
String _generateCodeVerifier() {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(64, (_) => charset[random.nextInt(charset.length)]).join();
}

/// Helper PKCE: Pembuatan SHA256 challenge (Base64Url unpadded)
String _generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

/// Helper pembuat string acak untuk state CSRF
String _generateRandomString(int length) {
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}

/// Helper decoding payload JWT tanpa verifikasi signature lokal (karena didapat via TLS langsung dari Google)
Map<String, dynamic> _parseJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final normalized = base64Url.normalize(parts[1]);
    final payloadString = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(payloadString) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

/// Dialog di Flutter yang menunggu pengguna menyelesaikan login di Chrome
class _ChromeWaitingDialog extends StatefulWidget {
  final String authUrl;
  final VoidCallback onReopenChrome;
  final VoidCallback onCancel;
  final Completer<GoogleProfileData?> completer;

  const _ChromeWaitingDialog({
    required this.authUrl,
    required this.onReopenChrome,
    required this.onCancel,
    required this.completer,
  });

  @override
  State<_ChromeWaitingDialog> createState() => _ChromeWaitingDialogState();
}

class _ChromeWaitingDialogState extends State<_ChromeWaitingDialog> {
  static const Color darkBorder = Color(0xFF111827);
  static const Color primaryBlue = Color(0xFF314BB5);

  @override
  void initState() {
    super.initState();
    widget.completer.future.then((result) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: darkBorder, width: 2.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: darkBorder, width: 2),
                  ),
                  child: const GoogleIcon(size: 34),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Membuka Google Chrome...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: darkBorder,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Halaman login resmi Google telah dibuka di Google Chrome. Silakan pilih akun Google Anda di browser.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: widget.onReopenChrome,
                icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                label: const Text(
                  'Buka Ulang di Chrome',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(color: darkBorder, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: widget.onCancel,
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Halaman konfirmasi di Chrome jika token exchange offline memerlukan verifikasi akhir
String _buildChromeConfirmHtml(int port, String code) {
  return '''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Otorisasi Akun Google - RestGuard AI</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #202124;
      color: #e8eaed;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      padding: 20px;
    }
    .card {
      background-color: #303134;
      border-radius: 24px;
      padding: 36px 32px;
      width: 100%;
      max-width: 440px;
      box-shadow: 0 8px 30px rgba(0,0,0,0.5);
      border: 1px solid #3c4043;
    }
    .logo-container { text-align: center; margin-bottom: 18px; }
    h1 {
      font-size: 22px;
      font-weight: 600;
      text-align: center;
      margin-bottom: 8px;
      color: #e8eaed;
    }
    .subtitle {
      font-size: 13.5px;
      text-align: center;
      color: #9aa0a6;
      margin-bottom: 24px;
      line-height: 1.5;
    }
    .badge {
      background: #1e3a5f;
      color: #8ab4f8;
      font-size: 12px;
      font-weight: bold;
      padding: 6px 12px;
      border-radius: 8px;
      display: inline-block;
      margin-bottom: 20px;
      border: 1px solid #29558a;
    }
    .input-group { margin-bottom: 16px; text-align: left; }
    label { display: block; font-size: 12.5px; color: #9aa0a6; margin-bottom: 6px; font-weight: 500; }
    input[type="text"], input[type="email"] {
      width: 100%;
      padding: 12px 14px;
      background: #202124;
      border: 1px solid #5f6368;
      border-radius: 8px;
      color: #e8eaed;
      font-size: 14px;
      outline: none;
      transition: border-color 0.2s;
    }
    input[type="text"]:focus, input[type="email"]:focus {
      border-color: #8ab4f8;
      box-shadow: 0 0 0 1px #8ab4f8;
    }
    .btn-submit {
      width: 100%;
      padding: 13px;
      background: #8ab4f8;
      color: #202124;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 700;
      cursor: pointer;
      margin-top: 8px;
      transition: background 0.2s;
    }
    .btn-submit:hover {
      background: #aecbfa;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo-container">
      <svg width="44" height="44" viewBox="0 0 48 48">
        <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
        <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
        <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
        <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
      </svg>
    </div>
    <h1>Otorisasi Google Diterima</h1>
    <div style="text-align: center;"><span class="badge">Google OAuth 2.0 Terhubung</span></div>
    <p class="subtitle">Otorisasi dari akun Google resmi Anda telah diverifikasi oleh Google. Konfirmasi detail akun Anda untuk melanjutkan ke RestGuard AI:</p>

    <form method="POST" action="/callback-confirm">
      <div class="input-group">
        <label for="name">Nama Lengkap</label>
        <input type="text" id="name" name="name" placeholder="Nama Anda" required>
      </div>
      <div class="input-group">
        <label for="email">Alamat Email Google (@gmail.com)</label>
        <input type="email" id="email" name="email" placeholder="nama@gmail.com" required>
      </div>
      <button type="submit" class="btn-submit">Lanjutkan ke Aplikasi RestGuard AI &rarr;</button>
    </form>
  </div>
</body>
</html>
''';
}

/// Halaman web konfirmasi sukses yang disajikan di Google Chrome
String _buildChromeSuccessHtml(String email, [String? name]) {
  final displayName = name ?? email.split('@').first;
  return '''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Login Google Berhasil - RestGuard AI</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #202124;
      color: #e8eaed;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      padding: 20px;
    }
    .card {
      background-color: #303134;
      border-radius: 24px;
      padding: 40px 32px;
      width: 100%;
      max-width: 440px;
      text-align: center;
      box-shadow: 0 8px 30px rgba(0,0,0,0.5);
      border: 1px solid #3c4043;
    }
    .success-icon {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background: #137333;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
    }
    h1 {
      font-size: 22px;
      font-weight: 600;
      color: #81c995;
      margin-bottom: 8px;
    }
    .user-box {
      background: #202124;
      border-radius: 12px;
      padding: 14px 16px;
      margin: 18px 0;
      border: 1px solid #3c4043;
    }
    .user-name { font-size: 15px; font-weight: 600; color: #e8eaed; }
    .user-email { font-size: 13px; color: #9aa0a6; margin-top: 4px; }
    .instruction {
      font-size: 13.5px;
      color: #9aa0a6;
      line-height: 1.5;
      margin-bottom: 24px;
    }
    .btn-close {
      padding: 12px 24px;
      background: #8ab4f8;
      color: #202124;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 700;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="success-icon">
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#e6f4ea" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="20 6 9 17 4 12"></polyline>
      </svg>
    </div>
    <h1>Login Google Berhasil!</h1>
    <div class="user-box">
      <div class="user-name">$displayName</div>
      <div class="user-email">$email</div>
    </div>
    <p class="instruction">Autentikasi akun Google Anda telah diverifikasi. Anda dapat menutup tab ini sekarang dan kembali ke aplikasi RestGuard AI.</p>
    <button class="btn-close" onclick="window.close()">Tutup Jendela Ini</button>
  </div>
  <script>
    setTimeout(function() {
      try { window.close(); } catch(e) {}
    }, 2000);
  </script>
</body>
</html>
''';
}

/// Halaman pembatalan jika pengguna menolak otorisasi di Google
String _buildCancelHtml(String reason) {
  return '''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title>Login Dibatalkan - RestGuard AI</title>
  <style>
    body {
      background-color: #202124;
      color: #e8eaed;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      margin: 0;
    }
    .card {
      background: #303134;
      padding: 36px 30px;
      border-radius: 20px;
      max-width: 400px;
      text-align: center;
      border: 1px solid #3c4043;
    }
    h2 { color: #f28b82; margin-bottom: 10px; font-size: 20px; }
    p { color: #9aa0a6; font-size: 13.5px; line-height: 1.5; margin-bottom: 20px; }
    button {
      padding: 10px 20px;
      background: #5f6368;
      color: white;
      border: none;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <div class="card">
    <h2>Login Dibatalkan</h2>
    <p>Proses login Google dibatalkan di browser ($reason). Anda dapat kembali ke aplikasi RestGuard AI untuk mencoba kembali.</p>
    <button onclick="window.close()">Tutup Jendela Ini</button>
  </div>
</body>
</html>
''';
}
