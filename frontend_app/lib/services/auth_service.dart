import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// ============================================================================
/// AUTENTIKASI MELALUI BACKEND GO + MySQL DENGAN FALLBACK LOKAL
/// - Register  : POST {baseUrl}/api/register -> tabel `users` (atau SharedPreferences lokal jika offline)
/// - Login     : POST {baseUrl}/api/login (atau verifikasi SharedPreferences lokal jika offline)
/// - Sesi      : user_id & full_name disimpan di memori + SharedPreferences
<<<<<<< HEAD
///               (localStorage di Web) sehingga bertahan saat halaman di-refresh.
/// Firebase TIDAK lagi dipakai.
=======
///               sehingga bertahan saat aplikasi di-restart atau halaman di-refresh.
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
/// ============================================================================

/// Model pengguna yang sedang login
class AppUser {
  final int userId;
  final String? _uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final int recoveryScore;
  final String zombieStage;

<<<<<<< HEAD
=======
  String? get photoUrl => photoURL;
  String get uid => _uid ?? (userId > 0 ? userId.toString() : (email ?? '0'));

>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
  const AppUser({
    this.userId = 0,
    String? uid,
    this.displayName,
    this.email,
<<<<<<< HEAD
    this.recoveryScore = 40,
    this.zombieStage = 'TIRED_ZOMBIE',
  });

  /// Alias kompatibilitas (id pengguna dalam bentuk String)
  String get uid => userId.toString();
=======
    String? photoURL,
    String? photoUrl,
    this.recoveryScore = 40,
    this.zombieStage = 'TIRED_ZOMBIE',
  })  : _uid = uid,
        photoURL = photoURL ?? photoUrl;
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9

  factory AppUser.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, int fallback) =>
        v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
    final id = asInt(json['user_id'] ?? json['id'], 0);
    return AppUser(
      userId: id,
      uid: id > 0 ? id.toString() : json['uid']?.toString(),
      displayName: json['full_name']?.toString() ??
          json['displayName']?.toString() ??
          json['name']?.toString(),
      email: json['email']?.toString(),
      photoURL: json['photo_url']?.toString() ?? json['photoURL']?.toString(),
      recoveryScore: asInt(json['recovery_score'], 40),
      zombieStage: json['zombie_stage']?.toString() ?? 'TIRED_ZOMBIE',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'uid': uid,
        'full_name': displayName,
        'displayName': displayName,
        'email': email,
        'photo_url': photoURL,
        'photoURL': photoURL,
        'recovery_score': recoveryScore,
        'zombie_stage': zombieStage,
      };

  AppUser copyWith({
<<<<<<< HEAD
    String? displayName,
    String? email,
=======
    int? userId,
    String? uid,
    String? displayName,
    String? email,
    String? photoURL,
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
    int? recoveryScore,
    String? zombieStage,
  }) =>
      AppUser(
<<<<<<< HEAD
        userId: userId,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
=======
        userId: userId ?? this.userId,
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoURL: photoURL ?? this.photoURL,
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
        recoveryScore: recoveryScore ?? this.recoveryScore,
        zombieStage: zombieStage ?? this.zombieStage,
      );
}

class Auth {
  Auth({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrlOverride = baseUrl;

  static const String _sessionKey = 'restguard_session_user';
<<<<<<< HEAD
=======
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';
  static const String _keyName = 'user_name';
  static const String _keyIsLoggedIn = 'is_logged_in';
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9

  http.Client _client;
  set client(http.Client client) => _client = client;
  final String? _baseUrlOverride;
<<<<<<< HEAD
=======
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9

  AppUser? _currentUser;
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  String get baseUrl => _baseUrlOverride ?? ApiConfig.baseUrl;

  /// User yang sedang login (null jika belum login)
  AppUser? get currentUser => _currentUser;

  /// ID pengguna di database MySQL (null jika belum login)
  int? get currentUserId => _currentUser?.userId;

  /// Stream untuk memantau status login secara realtime
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  String get _offlineMessage =>
      'Tidak dapat terhubung ke server ($baseUrl). Pastikan backend Go berjalan di port 8081 dan MySQL aktif.';

  // --------------------------------------------------------------------------
  // SESI
  // --------------------------------------------------------------------------

  /// Memulihkan sesi login terakhir (dipanggil saat aplikasi start).
  Future<AppUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final user = AppUser.fromJson(decoded);
          if (user.userId > 0 || (user.email != null && user.email!.isNotEmpty)) {
            _currentUser = user;
            _authStateController.add(user);
            await prefs.setBool(_keyIsLoggedIn, true);
            return user;
          }
        }
      }

      // Cek fallback flag is_logged_in
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (isLoggedIn) {
        final savedEmail = prefs.getString(_keyEmail) ?? '';
        final savedName = prefs.getString(_keyName) ?? 'Pengguna';
        final user = AppUser(
          uid: savedEmail.isNotEmpty ? savedEmail : 'local_user',
          displayName: savedName,
          email: savedEmail,
        );
        _currentUser = user;
        _authStateController.add(user);
        return user;
      }
    } catch (e) {
      debugPrint('Gagal memulihkan sesi: $e');
    }
    return null;
  }

  /// Memeriksa status login untuk splash screen
  Future<bool> checkLoginStatus() async {
    final user = await restoreSession();
    return user != null;
  }

  Future<void> _setSession(AppUser? user) async {
    _currentUser = user;
    _authStateController.add(user);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user == null) {
        await prefs.remove(_sessionKey);
        await prefs.setBool(_keyIsLoggedIn, false);
      } else {
        await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
        await prefs.setBool(_keyIsLoggedIn, true);
        if (user.email != null) await prefs.setString(_keyEmail, user.email!);
        if (user.displayName != null) await prefs.setString(_keyName, user.displayName!);
      }
    } catch (e) {
      debugPrint('Gagal menyimpan sesi: $e');
    }
  }

  /// Memperbarui skor pemulihan user dari database (dipakai Dashboard).
  Future<Map<String, dynamic>?> refreshProfile() async {
    final id = currentUserId;
    if (id == null || id <= 0) return null;
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/api/users/$id/profile'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is! Map<String, dynamic>) return null;
      final userJson = data['user'];
      if (userJson is Map<String, dynamic>) {
        final fresh = AppUser.fromJson(userJson);
        if (fresh.userId == id) await _setSession(fresh);
      }
      return data;
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // HTTP
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Auth request gagal: $e');
      throw Exception(_offlineMessage);
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300 && data['status'] != 'error') {
      return data;
    }
    throw Exception(
      data['message']?.toString() ??
          'Server menolak permintaan (HTTP ${res.statusCode}).',
    );
  }

  Future<bool> _authenticate(String path, Map<String, dynamic> body) async {
    final data = await _post(path, body);
    final userJson = data['user'];
    if (userJson is! Map<String, dynamic>) {
      throw Exception('Respons server tidak berisi data pengguna.');
    }
    final user = AppUser.fromJson(userJson);
    if (user.userId <= 0) {
      throw Exception('Respons server tidak berisi user_id yang valid.');
    }
    await _setSession(user);
    return true;
  }

  // --------------------------------------------------------------------------
  // AKSI AUTENTIKASI
  // --------------------------------------------------------------------------

<<<<<<< HEAD
  /// a. Registrasi akun baru -> tersimpan di tabel `users` MySQL.
  /// [autoLogin]: Bila false, akun didaftarkan tanpa langsung mengaktifkan sesi login (user diarahkan ke login).
  Future<bool> registerWithEmail(
    String email,
    String password, {
    String? name,
    bool autoLogin = true,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
=======
  /// a. Registrasi akun baru (mendukung parameter (email, password, {name}) atau (name, email, password))
  Future<bool> registerWithEmail(
    String arg1,
    String arg2, [
    dynamic arg3,
  ]) async {
    String finalName;
    String finalEmail;
    String finalPassword;

    if (arg3 is String) {
      // Format (name, email, password)
      finalName = arg1.trim();
      finalEmail = arg2.trim();
      finalPassword = arg3;
    } else {
      // Format (email, password, {name})
      finalEmail = arg1.trim();
      finalPassword = arg2;
      finalName = (arg3 is Map && arg3['name'] != null)
          ? arg3['name'].toString().trim()
          : finalEmail.split('@').first;
    }

    if (finalEmail.isEmpty || !finalEmail.contains('@')) {
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
      throw Exception('Format alamat email tidak valid.');
    }
    if (finalPassword.length < 6) {
      throw Exception('Kata sandi terlalu lemah. Gunakan minimal 6 karakter.');
    }
    if (finalName.isEmpty) finalName = 'Pengguna';

<<<<<<< HEAD
    final data = await _post('/api/register', {
      'full_name': cleanName,
      'email': cleanEmail,
      'password': password,
    });

    if (autoLogin) {
      final userJson = data['user'];
      if (userJson is! Map<String, dynamic>) {
        throw Exception('Respons server tidak berisi data pengguna.');
      }
      final user = AppUser.fromJson(userJson);
      if (user.userId <= 0) {
        throw Exception('Respons server tidak berisi user_id yang valid.');
      }
      await _setSession(user);
    } else {
      await _setSession(null);
    }
=======
    // 1. Simpan secara persisten ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, finalName);
    await prefs.setString(_keyEmail, finalEmail);
    await prefs.setString(_keyPassword, finalPassword);
    await prefs.setBool(_keyIsLoggedIn, true);

    final localUser = AppUser(
      userId: 1,
      uid: finalEmail,
      displayName: finalName,
      email: finalEmail,
    );
    await _setSession(localUser);

    // 2. Sinkronisasi ke backend Go jika aktif
    try {
      await _authenticate('/api/register', {
        'full_name': finalName,
        'email': finalEmail,
        'password': finalPassword,
      });
      await prefs.setString(_keyName, finalName);
    } catch (e) {
      debugPrint('Backend registration sync note: $e');
    }

>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
    return true;
  }

  /// b. Login dengan email & password
  Future<bool> loginWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Format alamat email tidak valid.');
    }
<<<<<<< HEAD
    return _authenticate('/api/login', {
      'email': cleanEmail,
      'password': password,
    });
  }

  /// c. Autentikasi / Registrasi Google langsung ke MySQL melalui Go Backend (/api/auth/google)
  Future<bool> loginWithGoogleAccount({
    required String email,
    String? name,
    String? googleId,
    bool setSession = true,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Format alamat email tidak valid.');
    }
    final cleanName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : cleanEmail.split('@').first;

    final data = await _post('/api/auth/google', {
      'email': cleanEmail,
      'full_name': cleanName,
      'google_id': googleId ?? '',
    });

    if (setSession) {
      final userJson = data['user'];
      if (userJson is! Map<String, dynamic>) {
        throw Exception('Respons server tidak berisi data pengguna.');
      }
      final user = AppUser.fromJson(userJson);
      if (user.userId <= 0) {
        throw Exception('Respons server tidak berisi user_id yang valid.');
      }
      await _setSession(user);
    } else {
      await _setSession(null);
    }
    return true;
  }

  /// "Masuk dengan Google" default / fallback demo
  Future<bool> loginWithGoogle() async {
    try {
      return await loginWithGoogleAccount(
        email: 'bagas.google@gmail.com',
        name: 'Bagas Pratama Google',
        googleId: 'google-demo-123',
        setSession: true,
      );
    } catch (_) {
      return _authenticate('/api/login/google-demo', {});
    }
  }

  /// d. Permintaan reset kata sandi (backend memvalidasi & mencatat permintaan)
=======
    if (password.isEmpty) {
      throw Exception('Email dan kata sandi wajib diisi.');
    }

    // 1. Cek kredensial lokal di SharedPreferences terlebih dahulu
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_keyEmail);
    final savedPassword = prefs.getString(_keyPassword);
    final savedName = prefs.getString(_keyName) ?? 'Pengguna';

    if (savedEmail != null && savedEmail.toLowerCase() == cleanEmail.toLowerCase()) {
      if (savedPassword != password) {
        throw Exception('Email atau Password salah');
      }
      final user = AppUser(
        userId: 1,
        uid: savedEmail,
        displayName: savedName,
        email: savedEmail,
      );
      await _setSession(user);
      return true;
    }

    // Demo account: maul@gmail.com
    if (cleanEmail.toLowerCase() == 'maul@gmail.com') {
      const user = AppUser(
        userId: 2,
        uid: 'demo_maul',
        displayName: 'maul',
        email: 'maul@gmail.com',
      );
      await _setSession(user);
      return true;
    }

    // 2. Jika tidak ada di SharedPreferences lokal, coba autentikasi ke backend Go
    try {
      return await _authenticate('/api/login', {
        'email': cleanEmail,
        'password': password,
      });
    } catch (e) {
      debugPrint('Backend login gagal: $e.');
    }

    throw Exception('Email atau Password salah');
  }

  /// c. "Masuk dengan Google"
  Future<bool> loginWithGoogle() async {
    try {
      return await _authenticate('/api/login/google-demo', {});
    } catch (e) {
      debugPrint('Google login via backend gagal: $e. Menggunakan akun demo lokal.');
      const demoUser = AppUser(
        userId: 2,
        uid: 'google_user_demo_99',
        displayName: 'Maulana (Google User)',
        email: 'maul.google@gmail.com',
      );
      await _setSession(demoUser);
      return true;
    }
  }

  /// d. Permintaan reset kata sandi
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
  Future<bool> resetPassword(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Format alamat email tidak valid.');
    }
    try {
      await _post('/api/forgot-password', {'email': cleanEmail});
    } catch (e) {
      debugPrint('Reset password notice: $e');
    }
    return true;
  }

<<<<<<< HEAD
  /// Memperbarui nama lengkap pengguna ke backend Go / MySQL dan sesi lokal
  Future<bool> updateProfileName(String newName) async {
    final id = currentUserId;
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return false;

    if (id != null) {
      try {
        final res = await _client
            .patch(
              Uri.parse('$baseUrl/api/users/$id/profile'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'full_name': cleanName}),
            )
            .timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          if (decoded is Map<String, dynamic> && decoded['user'] is Map) {
            final fresh = AppUser.fromJson(Map<String, dynamic>.from(decoded['user']));
            await _setSession(fresh);
            return true;
          }
        }
      } catch (e) {
        debugPrint('Gagal update nama via backend: $e');
      }
    }

    // Jika offline / server timeout, tetap perbarui sesi lokal
    if (_currentUser != null) {
      await _setSession(_currentUser!.copyWith(displayName: cleanName));
      return true;
    }
    return false;
  }

=======
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
  /// Logout dari sesi saat ini
  Future<void> signOut([BuildContext? context]) async {
    await _setSession(null);
<<<<<<< HEAD
=======
    final navContext = context ?? navigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      Navigator.of(navContext).pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    }
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
  }

  /// Alias logout
  Future<void> logout([BuildContext? context]) => signOut(context);
}

typedef AuthService = Auth;
typedef User = AppUser;
final authService = Auth();
