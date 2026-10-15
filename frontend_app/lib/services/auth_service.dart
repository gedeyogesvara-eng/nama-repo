import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// ============================================================================
/// AUTENTIKASI MELALUI BACKEND GO + MySQL
/// - Register  : POST {baseUrl}/api/register  -> tabel `users` (password di-hash bcrypt)
/// - Login     : POST {baseUrl}/api/login
/// - Sesi      : user_id & full_name disimpan di memori + SharedPreferences
///               (localStorage di Web) sehingga bertahan saat halaman di-refresh.
/// Firebase TIDAK lagi dipakai.
/// ============================================================================

/// Model pengguna yang sedang login
class AppUser {
  final int userId;
  final String? displayName;
  final String? email;
  final int recoveryScore;
  final String zombieStage;

  const AppUser({
    required this.userId,
    this.displayName,
    this.email,
    this.recoveryScore = 40,
    this.zombieStage = 'TIRED_ZOMBIE',
  });

  /// Alias kompatibilitas (id pengguna dalam bentuk String)
  String get uid => userId.toString();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, int fallback) =>
        v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
    return AppUser(
      userId: asInt(json['user_id'] ?? json['id'], 0),
      displayName: json['full_name']?.toString(),
      email: json['email']?.toString(),
      recoveryScore: asInt(json['recovery_score'], 40),
      zombieStage: json['zombie_stage']?.toString() ?? 'TIRED_ZOMBIE',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': displayName,
        'email': email,
        'recovery_score': recoveryScore,
        'zombie_stage': zombieStage,
      };

  AppUser copyWith({int? recoveryScore, String? zombieStage}) => AppUser(
        userId: userId,
        displayName: displayName,
        email: email,
        recoveryScore: recoveryScore ?? this.recoveryScore,
        zombieStage: zombieStage ?? this.zombieStage,
      );
}

class Auth {
  Auth({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrlOverride = baseUrl;

  static const String _sessionKey = 'restguard_session_user';

  http.Client _client;
  set client(http.Client client) => _client = client;
  final String? _baseUrlOverride;

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
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final user = AppUser.fromJson(decoded);
        if (user.userId > 0) {
          _currentUser = user;
          _authStateController.add(user);
          return user;
        }
      }
    } catch (e) {
      debugPrint('Gagal memulihkan sesi: $e');
    }
    return null;
  }

  Future<void> _setSession(AppUser? user) async {
    _currentUser = user;
    _authStateController.add(user);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user == null) {
        await prefs.remove(_sessionKey);
      } else {
        await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
      }
    } catch (e) {
      debugPrint('Gagal menyimpan sesi: $e');
    }
  }

  /// Memperbarui skor pemulihan user dari database (dipakai Dashboard).
  /// Mengembalikan data profil lengkap, atau null jika server tidak terjangkau.
  Future<Map<String, dynamic>?> refreshProfile() async {
    final id = currentUserId;
    if (id == null) return null;
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

  /// a. Registrasi akun baru -> tersimpan di tabel `users` MySQL, lalu otomatis login
  Future<bool> registerWithEmail(
    String email,
    String password, {
    String? name,
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

    return _authenticate('/api/register', {
      'full_name': cleanName,
      'email': cleanEmail,
      'password': password,
    });
  }

  /// b. Login dengan email & password yang divalidasi backend terhadap MySQL
  Future<bool> loginWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Format alamat email tidak valid.');
    }
    return _authenticate('/api/login', {
      'email': cleanEmail,
      'password': password,
    });
  }

  /// c. "Masuk dengan Google" (mode demo): Google OAuth asli membutuhkan konfigurasi
  /// Firebase/Google Cloud, jadi tombol ini memakai akun demo yang tersimpan di MySQL.
  Future<bool> loginWithGoogle() async {
    return _authenticate('/api/login/google-demo', {});
  }

  /// d. Permintaan reset kata sandi (backend memvalidasi & mencatat permintaan)
  Future<bool> resetPassword(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Format alamat email tidak valid.');
    }
    await _post('/api/forgot-password', {'email': cleanEmail});
    return true;
  }

  /// Logout dari sesi saat ini
  Future<void> signOut() async {
    await _setSession(null);
  }
}

typedef AuthService = Auth;
typedef User = AppUser;
final authService = Auth();
