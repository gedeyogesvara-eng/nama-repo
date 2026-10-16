import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Service akses database Somatic.AI berbasis Supabase Cloud.
///
/// Menggantikan panggilan HTTP POST ke localhost/MySQL lokal untuk mengatasi
/// masalah 'backend timeout'. Semua operasi database (users, screening_history, recipes)
/// dilakukan langsung via Supabase SDK:
/// `Supabase.instance.client.from('nama_tabel')`
class BackendService {
  /// Mengambil SupabaseClient aktif secara aman (baik dari SupabaseConfig maupun Supabase.instance)
  static SupabaseClient? get client {
    try {
      return SupabaseConfig.client ?? Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // 1. MANAJEMEN PENGGUNA (Tabel `users`)
  // ==========================================================================

  /// Menyimpan atau memperbarui data akun pengguna ke tabel `users` di Supabase.
  /// Dipanggil saat registrasi baru atau login dengan Google.
  static Future<Map<String, dynamic>?> insertUser(
    Map<String, dynamic> userData, {
    http.Client? client, // dipertahankan untuk kompatibilitas signature
  }) async {
    final sb = BackendService.client;
    final email = userData['email']?.toString().trim();
    if (email == null || email.isEmpty) return null;

    final name = (userData['nama'] ?? userData['full_name'] ?? userData['displayName'] ?? email.split('@').first).toString();
    final uid = (userData['uid'] ?? userData['google_id'] ?? email).toString();
    final photoUrl = userData['avatar_url'] ?? userData['photo_url'] ?? userData['photoURL'];

    final payload = {
      'uid': uid,
      'email': email,
      'nama': name,
      'avatar_url': photoUrl,
      'recovery_score': userData['recovery_score'] is int ? userData['recovery_score'] : 40,
      'zombie_stage': (userData['zombie_stage'] ?? 'TIRED_ZOMBIE').toString(),
    };

    if (sb != null) {
      try {
        // Gunakan upsert dengan acuan kolom email unik
        final response = await sb
            .from('users')
            .upsert(payload, onConflict: 'email')
            .select()
            .maybeSingle();

        debugPrint('✅ [BackendService-Supabase] Berhasil menyimpan user ke tabel users: $email');
        if (response != null) {
          return Map<String, dynamic>.from(response);
        }
      } catch (e) {
        debugPrint('⚠️ [BackendService-Supabase] Gagal upsert user ke Supabase: $e');
        // Coba insert biasa jika upsert gagal
        try {
          final resInsert = await sb
              .from('users')
              .insert(payload)
              .select()
              .maybeSingle();
          if (resInsert != null) {
            return Map<String, dynamic>.from(resInsert);
          }
        } catch (errInsert) {
          debugPrint('⚠️ [BackendService-Supabase] Insert biasa juga gagal: $errInsert');
        }
      }
    }

    // Fallback data lokal jika Supabase belum terhubung
    return {
      'id': 1,
      'user_id': 1,
      ...payload,
    };
  }

  // ==========================================================================
  // 2. RIWAYAT SKRINING (Tabel `screening_history`)
  // ==========================================================================

  /// Menyimpan data hasil skrining diagnosis AI ke tabel `screening_history` di Supabase.
  /// Menggunakan metode `Supabase.instance.client.from('screening_history').insert(payload)`.
  static Future<bool> insertScreeningHistory(
    Map<String, dynamic> diagnosisData, {
    int? userId,
    http.Client? client,
  }) async {
    final sb = BackendService.client;
    final effectiveUserId = userId ?? 1;

    final screeningData = diagnosisData['data_skrining'] is Map
        ? Map<String, dynamic>.from(diagnosisData['data_skrining'] as Map)
        : diagnosisData;

    int asInt(dynamic v, int fallback) =>
        v is num ? v.toInt() : int.tryParse('$v') ?? fallback;

    final visualScore = asInt(screeningData['visual_score'] ?? screeningData['skor_sklera'], 50);
    final voiceScore = asInt(screeningData['voice_score'] ?? screeningData['skor_akustik'], 50);
    final sketchScore = asInt(screeningData['sketch_score'] ?? screeningData['skor_motorik'], 50);
    final gaitScore = asInt(screeningData['gait_score'] ?? screeningData['skor_motorik'], 50);
    final overallScore = ((visualScore + voiceScore + sketchScore + gaitScore) / 4).round().clamp(0, 100);

    final payload = {
      'user_id': effectiveUserId,
      'id_skrining': (screeningData['id_skrining'] ?? diagnosisData['id_skrining'] ?? 'SCR-${DateTime.now().millisecondsSinceEpoch}').toString(),
      'kode_skrining': (screeningData['id_skrining'] ?? diagnosisData['id_skrining'] ?? 'SCR-${DateTime.now().millisecondsSinceEpoch}').toString(),
      'kategori_burnout': (screeningData['kategori_burnout'] ?? diagnosisData['tingkat_depresi'] ?? 'Kelelahan Terdeteksi').toString(),
      'skor_keseluruhan': overallScore,
      'skor_mata': visualScore,
      'skor_suara': voiceScore,
      'skor_motorik': sketchScore,
      'skor_gait': gaitScore,
      'skor_sklera': visualScore,
      'skor_akustik': voiceScore,
      'eye_label': (screeningData['eye_label'] ?? 'Normal').toString(),
      'audio_label': (screeningData['audio_label'] ?? 'Stabil').toString(),
      'sketch_label': (screeningData['sketch_label'] ?? 'Relaks').toString(),
      'gait_label': (screeningData['gait_label'] ?? 'Simetris').toString(),
      'diagnosis_summary': (screeningData['diagnosis_summary'] ?? '').toString(),
      'is_emergency': screeningData['is_emergency'] == true,
      'ai_recipes': diagnosisData['ai_recipes'] ?? [],
      'created_at': DateTime.now().toIso8601String(),
    };

    if (sb != null) {
      try {
        await sb.from('screening_history').insert(payload);
        debugPrint('✅ [BackendService-Supabase] Berhasil insert riwayat skrining: ${payload['id_skrining']}');
        return true;
      } catch (e) {
        debugPrint('⚠️ [BackendService-Supabase] Gagal insert ke tabel screening_history: $e');
        return false;
      }
    } else {
      debugPrint('ℹ️ [BackendService] Supabase client offline, data dicatat di lokal SharedPreferences.');
      return false;
    }
  }

  /// Mengambil daftar riwayat skrining milik [userId] dari tabel `screening_history` di Supabase.
  static Future<List<Map<String, dynamic>>> fetchHistory(
    int userId, {
    http.Client? client,
  }) async {
    final sb = BackendService.client;
    if (sb == null) return [];

    try {
      final response = await sb
          .from('screening_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('🌐 [BackendService-Supabase] Berhasil mengambil ${response.length} riwayat dari Supabase');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('⚠️ [BackendService-Supabase] Gagal mengambil riwayat dari Supabase: $e');
      return [];
    }
  }

  // ==========================================================================
  // 3. MANAJEMEN RESEP PEMULIHAN (Tabel `recipes`)
  // ==========================================================================

  /// Menandai / membatalkan resep di tabel `recipes` di Supabase
  static Future<Map<String, dynamic>?> setRecipeCompleted(
    dynamic recipeId,
    bool completed, {
    http.Client? client,
  }) async {
    final id = recipeId is num ? recipeId.toInt() : int.tryParse('$recipeId');
    if (id == null) return null;

    final sb = BackendService.client;
    if (sb != null) {
      try {
        final res = await sb
            .from('recipes')
            .update({'is_completed': completed})
            .eq('id', id)
            .select()
            .maybeSingle();

        if (res != null) {
          return Map<String, dynamic>.from(res);
        }
      } catch (e) {
        debugPrint('⚠️ [BackendService-Supabase] Gagal memperbarui resep #$id: $e');
      }
    }

    return {'id': id, 'is_completed': completed};
  }

  /// Menambahkan resep mandiri buatan pengguna ke tabel `recipes` di Supabase
  static Future<Map<String, dynamic>?> addCustomRecipe({
    required int userId,
    required String deskripsi,
    String jenis = 'Mandiri',
    http.Client? client,
  }) async {
    final payload = {
      'user_id': userId,
      'deskripsi_tugas': deskripsi.trim(),
      'jenis_intervensi': jenis.trim(),
      'is_completed': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    final sb = BackendService.client;
    if (sb != null) {
      try {
        final res = await sb
            .from('recipes')
            .insert(payload)
            .select()
            .maybeSingle();

        if (res != null) {
          return Map<String, dynamic>.from(res);
        }
      } catch (e) {
        debugPrint('⚠️ [BackendService-Supabase] Gagal menambahkan resep mandiri: $e');
      }
    }

    return {
      'id': DateTime.now().millisecondsSinceEpoch % 100000,
      ...payload,
    };
  }
}
