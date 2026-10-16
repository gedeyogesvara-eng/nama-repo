import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'backend_service.dart';

/// ============================================================================
/// AUTENTIKASI MELALUI BACKEND GO + MySQL DENGAN FALLBACK LOKAL
/// - Register  : POST {baseUrl}/api/register -> tabel `users` (atau SharedPreferences lokal jika offline)
/// - Login     : POST {baseUrl}/api/login (atau verifikasi SharedPreferences lokal jika offline)
/// - Sesi      : user_id & full_name disimpan di memori + SharedPreferences
///               sehingga bertahan saat aplikasi di-restart atau halaman di-refresh (localStorage di Web).
/// Firebase TIDAK lagi dipakai.
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

  String? get photoUrl => photoURL;
  String get uid => _uid ?? (userId > 0 ? userId.toString() : (email ?? '0'));

  const AppUser({
    this.userId = 0,
    String? uid,
    this.displayName,
    this.email,
    String? photoURL,
    String? photoUrl,
    this.recoveryScore = 40,
    this.zombieStage = 'TIRED_ZOMBIE',
  })  : _uid = uid,
        photoURL = photoURL ?? photoUrl;

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
    int? userId,
    String? uid,
    String? displayName,
    String? email,
    String? photoURL,
    int? recoveryScore,
    String? zombieStage,
  }) =>
      AppUser(
        userId: userId ?? this.userId,
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoURL: photoURL ?? this.photoURL,
        recoveryScore: recoveryScore ?? this.recoveryScore,
        zombieStage: zombieStage ?? this.zombieStage,
      );
}

class Auth {
  Auth({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrlOverride = baseUrl;

  static const String _sessionKey = 'restguard_session_user';
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';
  static const String _keyName = 'user_name';
  static const String _keyIsLoggedIn = 'is_logged_in';

  http.Client _client;
  set client(http.Client client) => _client = client;
  final String? _baseUrlOverride;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppUser? _currentUser;
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  /// Pengguna yang sedang login saat ini (null jika belum login)
  AppUser? get currentUser => _currentUser;

  /// User ID integer (MySQL primary key `users.id`)
  int? get currentUserId => _currentUser?.userId;

  /// Stream perubahan status autentikasi
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  /// URL dasar backend Go
  String get baseUrl => _baseUrlOverride ?? ApiConfig.baseUrl;

  static const String _offlineMessage =
      'Tidak dapat terhubung ke backend Go. Pastikan server lokal berjalan di port 8081 dan MySQL aktif.';

  // --------------------------------------------------------------------------
  // SESI LOKAL
  // --------------------------------------------------------------------------

  /// Pulihkan sesi login terakhir dari SharedPreferences saat aplikasi dibuka.
  Future<AppUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw);
        if (map is Map<String, dynamic>) {
          final user = AppUser.fromJson(map);
          _currentUser = user;
          _authStateController.add(user);
          return user;
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

  /// a. Registrasi akun baru -> tersimpan di tabel `users` MySQL (atau SharedPreferences lokal jika offline)
  /// [autoLogin]: Bila false, akun didaftarkan tanpa langsung mengaktifkan sesi login (user diarahkan ke login).
  Future<bool> registerWithEmail(
    String email,
    String password, {
    String? name,
    bool autoLogin = true,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Format alamat email tidak valid.');
    }
    if (password.length < 6) {
      throw Exception('Kata sandi terlalu lemah. Gunakan minimal 6 karakter.');
    }
    final cleanName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : cleanEmail.split('@').first;

    // 1. Simpan secara persisten ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, cleanName);
    await prefs.setString(_keyEmail, cleanEmail);
    await prefs.setString(_keyPassword, password);
    if (autoLogin) {
      await prefs.setBool(_keyIsLoggedIn, true);
    }

    // 2. Simpan data akun ke Supabase (tabel `users`)
    try {
      final supabaseUser = await BackendService.insertUser({
        'uid': cleanEmail,
        'email': cleanEmail,
        'nama': cleanName,
        'full_name': cleanName,
      });

      if (supabaseUser != null && supabaseUser['id'] != null && supabaseUser['id'] != 1) {
        if (autoLogin) {
          final user = AppUser.fromJson(supabaseUser);
          if (user.userId > 0) {
            await _setSession(user);
            return true;
          }
        } else {
          await _setSession(null);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Supabase register note: $e');
    }

    // Fallback backend HTTP (jika ada server backend aktif)
    try {
      final data = await _post('/api/register', {
        'full_name': cleanName,
        'email': cleanEmail,
        'password': password,
      });

      if (autoLogin) {
        final userJson = data['user'];
        if (userJson is Map<String, dynamic>) {
          final user = AppUser.fromJson(userJson);
          if (user.userId > 0) {
            await _setSession(user);
            return true;
          }
        }
      } else {
        await _setSession(null);
        return true;
      }
    } catch (e) {
      debugPrint('Backend registration note: $e');
    }

    if (autoLogin) {
      final localUser = AppUser(
        userId: 1,
        uid: cleanEmail,
        displayName: cleanName,
        email: cleanEmail,
      );
      await _setSession(localUser);
    } else {
      await _setSession(null);
    }
    return true;
  }

  /// b. Login dengan email & password
  Future<bool> loginWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Format alamat email tidak valid.');
    }
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

    // 2. Coba autentikasi ke backend Go
    try {
      return await _authenticate('/api/login', {
        'email': cleanEmail,
        'password': password,
      });
    } catch (e) {
      debugPrint('Backend login note: $e');
      throw Exception('Email atau Password salah');
    }
  }

  /// c. Autentikasi / Registrasi Google langsung ke MySQL melalui Go Backend (/api/users & /api/auth/google)
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
    final effectiveUid = (googleId != null && googleId.trim().isNotEmpty)
        ? googleId.trim()
        : cleanEmail;

    final payload = {
      'uid': effectiveUid,
      'google_id': effectiveUid,
      'email': cleanEmail,
      'name': cleanName,
      'full_name': cleanName,
    };

    // 1. Simpan data pengguna (UID, Nama, Email) ke Supabase (tabel `users`)
    try {
      final supabaseUser = await BackendService.insertUser(payload);
      if (supabaseUser != null && supabaseUser['id'] != null && supabaseUser['id'] != 1) {
        if (setSession) {
          final user = AppUser.fromJson(supabaseUser);
          if (user.userId > 0) {
            await _setSession(user);
            return true;
          }
        } else {
          await _setSession(null);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Google login via Supabase note: $e');
    }

    // Fallback backend HTTP
    try {
      Map<String, dynamic> data;
      try {
        data = await _post('/api/users', payload);
      } catch (_) {
        data = await _post('/api/auth/google', payload);
      }

      if (setSession) {
        final userJson = data['user'] ?? data['data'];
        if (userJson is Map<String, dynamic>) {
          final user = AppUser.fromJson(userJson);
          if (user.userId > 0) {
            await _setSession(user);
            return true;
          }
        }
      } else {
        await _setSession(null);
        return true;
      }
    } catch (e) {
      debugPrint('Google login via backend note: $e');
    }

    if (setSession) {
      final localUser = AppUser(
        userId: 2,
        uid: effectiveUid,
        displayName: cleanName,
        email: cleanEmail,
      );
      await _setSession(localUser);
    }
    return true;
  }

  /// "Masuk dengan Google" default / fallback demo
  Future<bool> loginWithGoogle() async {
    try {
      return await _authenticate('/api/login/google-demo', {});
    } catch (_) {
      try {
        return await loginWithGoogleAccount(
          email: 'maul.google@gmail.com',
          name: 'Maulana (Google User)',
          googleId: 'google-demo-123',
          setSession: true,
        );
      } catch (e) {
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
  }

  /// d. Permintaan reset kata sandi
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

  /// Logout dari sesi saat ini
  Future<void> signOut([BuildContext? context]) async {
    await _setSession(null);
    final navContext = context ?? navigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      Navigator.of(navContext).pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    }
  }

  /// Alias logout
  Future<void> logout([BuildContext? context]) => signOut(context);
}

typedef AuthService = Auth;
typedef User = AppUser;
final authService = Auth();
