import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import 'relaxation_drawing_screen.dart';

/// Halaman Hasil Deteksi AI
/// Menampilkan ringkasan diagnosis, 3 indikator metrik sensor multimodal (Suara, Visual, Gait),
/// checklist interaktif Goals Pemulihan, dan tombol relaksasi menggambar.
///
/// Didesain dengan gaya 'Modern Clean':
/// - Dominan Deep Blue (#314BB5) & Putih/Surface Elegan
/// - Sudut lengkung halus (BorderRadius.circular(32))
/// - Shadow halus & transparan (tanpa solid black atau outline tebal)
/// - Kompatibel penuh dengan Mode Terang & Mode Gelap
class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> detectionData;

  const ResultScreen({
    super.key,
    this.detectionData = const {},
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const Color primaryBlue = Color(0xFF314BB5);

  // Status & Aksen
  static const Color amberDark = Color(0xFFD97706);
  static const Color greenDark = Color(0xFF10B981);
  static const Color redDark = Color(0xFFEF4444);

  late Map<String, dynamic> _screeningData;
  late List<Map<String, dynamic>> _recipes;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    final Map<String, dynamic> source = widget.detectionData.isNotEmpty
        ? widget.detectionData
        : AIService.getFallbackDetectionData();

    Map<String, dynamic> rawData;
    if (source.containsKey('data_skrining') && source['data_skrining'] is Map) {
      rawData = Map<String, dynamic>.from(source['data_skrining'] as Map);
    } else if (source.containsKey('data') && source['data'] is Map) {
      rawData = Map<String, dynamic>.from(source['data'] as Map);
    } else {
      rawData = Map<String, dynamic>.from(source);
    }

    if (!rawData.containsKey('kategori_burnout') || rawData['kategori_burnout'] == null) {
      rawData['kategori_burnout'] = source['tingkat_depresi'] ??
          source['depression_level'] ??
          rawData['tingkat_depresi'] ??
          rawData['status'] ??
          'Kelelahan Terdeteksi';
    }

    _screeningData = rawData;

    final rawRecipes = (source['ai_recipes'] ??
            source['resep'] ??
            source['rekomendasi_tindakan'] ??
            source['recommendations'] ??
            rawData['ai_recipes'] ??
            rawData['resep']) as List<dynamic>? ??
        [];

    _recipes = rawRecipes.map((r) {
      if (r is Map) {
        return <String, dynamic>{
          'id': r['id'],
          'id_resep': r['id_resep'] ?? 'REC-01',
          'jenis_intervensi': r['jenis_intervensi'] ?? r['kategori'] ?? 'Fisik',
          'deskripsi_tugas': r['deskripsi_tugas'] ?? r['deskripsi'] ?? r.toString(),
          'is_completed': r['is_completed'] ?? false,
        };
      } else {
        return <String, dynamic>{
          'id': null,
          'id_resep': 'REC-01',
          'jenis_intervensi': 'Fisik',
          'deskripsi_tugas': r.toString(),
          'is_completed': false,
        };
      }
    }).toList();
  }

  void _toggleRecipeCompletion(int index) {
    setState(() {
      final current = _recipes[index]['is_completed'] as bool? ?? false;
      _recipes[index]['is_completed'] = !current;
    });

    final taskDesc = _recipes[index]['deskripsi_tugas'] ?? '';
    final isDone = _recipes[index]['is_completed'] as bool;

    final recipeId = _recipes[index]['id'];
    if (recipeId != null) {
      BackendService.setRecipeCompleted(recipeId, isDone).then((res) {
        if (res != null) {
          authService.refreshProfile();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Gagal menyinkronkan ke server. Perubahan hanya tersimpan di layar ini.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              backgroundColor: redDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      });
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isDone ? 'Bagus! "$taskDesc" terselesaikan.' : 'Tugas dikembalikan ke belum selesai.',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: isDone ? greenDark : primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    int asInt(dynamic v, int fallback) => v is num ? v.toInt() : (int.tryParse('$v') ?? fallback);

    final idSkrining = _screeningData['id_skrining'] ?? 'SCR-UNKNOWN';
    final kategoriBurnout = _screeningData['kategori_burnout'] ?? 'Kelelahan Terdeteksi';

    final int skorSuara = asInt(_screeningData['voice_score'] ?? _screeningData['skor_akustik'], 34);
    final int skorVisual = asInt(_screeningData['visual_score'] ?? _screeningData['skor_sklera'], 32);
    final int skorGait = asInt(_screeningData['gait_score'] ?? _screeningData['skor_motorik'], 38);

    final String labelVisual = (_screeningData['eye_label'] ?? _screeningData['eye_diagnosis'] ?? 'Normal (Sehat)').toString();
    final String labelSuara = (_screeningData['audio_label'] ?? _screeningData['audio_diagnosis'] ?? 'Vokal Normal (Stabil)').toString();
    final String labelGait = (_screeningData['gait_label'] ?? 'Langkah Terkoordinasi').toString();

    final String diagSummary = (_screeningData['diagnosis_summary'] ?? '').toString();

    final completedCount = _recipes.where((r) => r['is_completed'] == true).length;
    final totalCount = _recipes.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, idSkrining, isDark, textTheme),

            // Content Scroll
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  // 1. Header Card Biru Tua (#314BB5) Modern Clean
                  _buildPrimaryHeaderCard(kategoriBurnout, diagSummary, isDark, textTheme),
                  const SizedBox(height: 24),

                  // 2. Section 3 Metrik Sensor Multimodal (Suara, Visual, Gait)
                  _buildMetricsSection(
                    isDark: isDark,
                    textTheme: textTheme,
                    skorSuara: skorSuara,
                    skorVisual: skorVisual,
                    skorGait: skorGait,
                    labelSuara: labelSuara,
                    labelVisual: labelVisual,
                    labelGait: labelGait,
                  ),
                  const SizedBox(height: 28),

                  // 3. Section Resep Anti-Zombi
                  _buildRecipesSection(completedCount, totalCount, isDark, textTheme),
                  const SizedBox(height: 28),

                  // 4. Saran Relaksasi Menggambar (Tombol Besar "Mari Rileks Sejenak")
                  _buildRelaxationSuggestionCard(context, isDark, textTheme),
                  const SizedBox(height: 18),

                  // 5. Tombol Selesai / Navigasi Beranda
                  _buildBottomActionButton(context, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TOP BAR ---
  Widget _buildTopBar(BuildContext context, String idSkrining, bool isDark, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: isDark ? Colors.white : primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil Skrining',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : primaryBlue,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Analisis Multimodal Selesai',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              idSkrining,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: primaryBlue,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER CARD BIRU TUA (DEEP BLUE #314BB5) ELEGAN ---
  Widget _buildPrimaryHeaderCard(String kategoriBurnout, String diagSummary, bool isDark, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF314BB5), Color(0xFF253B99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: isDark ? 0.4 : 0.28),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'AI TRIAGE RESULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Perlu Perhatian',
                  style: TextStyle(
                    color: Color(0xFF78350F),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'KATEGORI STATUS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kategoriBurnout,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    diagSummary.isNotEmpty
                        ? diagSummary
                        : 'Hasil analisis multimodal 3 sensor Somatic.AI: integrasi respons mata (visual), suara (akustik vokal), dan dinamika langkah (gait motorik).',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION METRIK (3 KARTU MULTIMODAL: SUARA, VISUAL, GAIT) ---
  Widget _buildMetricsSection({
    required bool isDark,
    required TextTheme textTheme,
    required int skorSuara,
    required int skorVisual,
    required int skorGait,
    required String labelSuara,
    required String labelVisual,
    required String labelGait,
  }) {
    Color getAccent(int score) => score >= 70 ? redDark : (score >= 45 ? amberDark : greenDark);
    Color getBg(int score) => getAccent(score).withValues(alpha: isDark ? 0.2 : 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.speed_rounded, size: 16, color: primaryBlue),
            const SizedBox(width: 6),
            Text(
              'INDIKATOR 3 MODALITAS AI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : primaryBlue,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Baris 1: 2 Kartu Berdampingan (Suara & Visual)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                isDark: isDark,
                textTheme: textTheme,
                title: 'Suara (Audio)',
                score: '$skorSuara%',
                icon: Icons.graphic_eq_rounded,
                statusText: labelSuara,
                accentColor: getAccent(skorSuara),
                bgTint: getBg(skorSuara),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                isDark: isDark,
                textTheme: textTheme,
                title: 'Visual (Mata)',
                score: '$skorVisual%',
                icon: Icons.remove_red_eye_outlined,
                statusText: labelVisual,
                accentColor: getAccent(skorVisual),
                bgTint: getBg(skorVisual),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Baris 2: Kartu Horizontal Penuh (Gait / Sensor Langkah)
        _buildHorizontalMetricCard(
          isDark: isDark,
          textTheme: textTheme,
          title: 'Gait (Sensor Gerak)',
          subtitle: 'Akselerasi & Koordinasi Langkah Kaki',
          score: '$skorGait%',
          icon: Icons.directions_walk_rounded,
          statusText: labelGait,
          accentColor: getAccent(skorGait),
          bgTint: getBg(skorGait),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required bool isDark,
    required TextTheme textTheme,
    required String title,
    required String score,
    required IconData icon,
    required String statusText,
    required Color accentColor,
    required Color bgTint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            score,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalMetricCard({
    required bool isDark,
    required TextTheme textTheme,
    required String title,
    required String subtitle,
    required String score,
    required IconData icon,
    required String statusText,
    required Color accentColor,
    required Color bgTint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Motorik',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SECTION RESEP ANTI-ZOMBI ---
  Widget _buildRecipesSection(int completedCount, int totalCount, bool isDark, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 18, color: primaryBlue),
                const SizedBox(width: 6),
                Text(
                  'Goals Pemulihan',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : primaryBlue,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: completedCount == totalCount
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$completedCount / $totalCount Selesai',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: completedCount == totalCount ? const Color(0xFF10B981) : primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tugas mikro-intervensi terpandu untuk memulihkan fungsi sistem saraf Anda.',
          style: textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // List Kartu Resep Modern Clean
        ..._recipes.asMap().entries.map((entry) {
          final index = entry.key;
          final recipe = entry.value;
          final isCompleted = recipe['is_completed'] as bool? ?? false;
          final jenis = recipe['jenis_intervensi'] ?? 'Fisik';
          final desc = recipe['deskripsi_tugas'] ?? '';

          return _buildRecipeCardItem(
            isDark: isDark,
            textTheme: textTheme,
            index: index,
            jenis: jenis,
            description: desc,
            isCompleted: isCompleted,
          );
        }),
      ],
    );
  }

  Widget _buildRecipeCardItem({
    required bool isDark,
    required TextTheme textTheme,
    required int index,
    required String jenis,
    required String description,
    required bool isCompleted,
  }) {
    final isFisik = jenis.toLowerCase() == 'fisik';
    final badgeBg = isFisik
        ? primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1)
        : const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.1);
    final badgeColor = isFisik ? primaryBlue : const Color(0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCompleted
            ? (isDark ? const Color(0xFF161616) : const Color(0xFFF8FAFC))
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox Custom Modern
          InkWell(
            onTap: () => _toggleRecipeCompletion(index),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isCompleted ? primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted
                      ? primaryBlue
                      : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // Deskripsi & Jenis Intervensi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Intervensi $jenis',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    if (isCompleted)
                      const Text(
                        'Selesai ✓',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SARAN RELAKSASI MENGGAMBAR (TOMBOL BESAR "MARI RILEKS SEJENAK") ---
  Widget _buildRelaxationSuggestionCard(BuildContext context, bool isDark, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF314BB5), Color(0xFF253B99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SARAN PEMULIHAN CEPAT",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFDE68A),
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      "Lepaskan Beban Pikiran",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Coretan bebas terbukti membantu menenangkan sistem saraf dan meredakan ketegangan mental setelah skrining.",
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          // Tombol Berukuran Besar "Mari Rileks Sejenak"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RelaxationDrawingScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.brush_rounded, color: primaryBlue, size: 20),
              label: const Text(
                "Mari Rileks Sejenak",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TOMBOL AKSI BAWAH ---
  Widget _buildBottomActionButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
        },
        icon: const Icon(Icons.home_filled, color: Colors.white, size: 18),
        label: const Text(
          'Simpan & Kembali ke Beranda',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          shadowColor: primaryBlue.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
