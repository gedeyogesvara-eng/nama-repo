import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Akses data skrining nyata dari backend Go (MySQL): riwayat & penyelesaian resep.
class BackendService {
  /// Mengambil riwayat skrining milik [userId] dari MySQL.
  /// Melempar [Exception] bila server tidak terjangkau agar UI bisa menampilkan status.
  static Future<List<Map<String, dynamic>>> fetchHistory(
    int userId, {
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/history?user_id=$userId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        throw Exception('Server mengembalikan HTTP ${res.statusCode}.');
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on TimeoutException {
      throw Exception('Server tidak merespons. Pastikan backend Go menyala.');
    } finally {
      if (client == null) c.close();
    }
  }

  /// Menandai / membatalkan resep di MySQL dan mengembalikan skor pemulihan terbaru.
  /// Mengembalikan null bila gagal (mis. hasil offline tanpa id resep / server mati).
  static Future<Map<String, dynamic>?> setRecipeCompleted(
    dynamic recipeId,
    bool completed, {
    http.Client? client,
  }) async {
    final id = recipeId is num ? recipeId.toInt() : int.tryParse('$recipeId');
    if (id == null) return null;

    final c = client ?? http.Client();
    try {
      final res = await c
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/api/recipes/$id/complete'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'is_completed': completed}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint('Gagal memperbarui resep #$id: $e');
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  /// Menambahkan resep mandiri buatan pengguna ke backend MySQL.
  static Future<Map<String, dynamic>?> addCustomRecipe({
    required int userId,
    required String deskripsi,
    String jenis = 'Mandiri',
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/recipes/custom'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'user_id': userId,
              'deskripsi_tugas': deskripsi.trim(),
              'jenis_intervensi': jenis.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['recipe'] is Map) {
        return Map<String, dynamic>.from(decoded['recipe']);
      }
      return null;
    } catch (e) {
      debugPrint('Gagal menambahkan resep mandiri: $e');
      return null;
    } finally {
      if (client == null) c.close();
    }
  }
}
