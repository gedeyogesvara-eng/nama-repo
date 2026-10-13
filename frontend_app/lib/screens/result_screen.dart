import 'package:flutter/material.dart';

/// Halaman Hasil Deteksi AI
/// Menampilkan ringkasan diagnosis, 3 indikator metrik sensor,
/// dan checklist interaktif Resep Anti-Zombi.
class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> detectionData;

  const ResultScreen({
    super.key,
    required this.detectionData,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Palet Warna Neo-Brutalism
  static const Color appBg = Color(0xFFF2F1EB);
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color primaryDark = Color(0xFF1E2D75);
  static const Color grayText = Color(0xFF5C5C5C);
  static const Color grayLight = Color(0xFF8E8E93);
  static const Color cardShadowGray = Color(0xFFDBD8CF);
  static const Color borderBlack = Color(0xFF000000);

  // Status & Aksen
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberBg = Color(0xFFFFFBEB);
  static const Color greenDark = Color(0xFF059669);
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color redDark = Color(0xFFDC2626);
  static const Color redBg = Color(0xFFFEF2F2);

  late Map<String, dynamic> _screeningData;
  late List<Map<String, dynamic>> _recipes;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    final rawData = widget.detectionData['data_skrining'] as Map<String, dynamic>? ?? {};
    _screeningData = Map<String, dynamic>.from(rawData);

    final rawRecipes = widget.detectionData['ai_recipes'] as List<dynamic>? ?? [];
    _recipes = rawRecipes.map((r) => Map<String, dynamic>.from(r as Map<String, dynamic>)).toList();
  }

  void _toggleRecipeCompletion(int index) {
    setState(() {
      final current = _recipes[index]['is_completed'] as bool? ?? false;
      _recipes[index]['is_completed'] = !current;
    });

    final taskDesc = _recipes[index]['deskripsi_tugas'] ?? '';
    final isDone = _recipes[index]['is_completed'] as bool;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isDone ? 'Bagus! "$taskDesc" terselesaikan.' : 'Tugas dikembalikan ke belum selesai.',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: isDone ? greenDark : primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idSkrining = _screeningData['id_skrining'] ?? 'SCR-UNKNOWN';
    final kategoriBurnout = _screeningData['kategori_burnout'] ?? 'Kelelahan Terdeteksi';
    final skorAkustik = _screeningData['skor_akustik'] ?? 0;
    final skorMotorik = _screeningData['skor_motorik'] ?? 0;
    final skorSklera = _screeningData['skor_sklera'] ?? 0;

    final completedCount = _recipes.where((r) => r['is_completed'] == true).length;
    final totalCount = _recipes.length;

    return Scaffold(
      backgroundColor: appBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(idSkrining),

            // Content Scroll
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  // 1. Header Card Biru Tua (#314BB5)
                  _buildPrimaryHeaderCard(kategoriBurnout),
                  const SizedBox(height: 24),

                  // 2. Section 3 Metrik Sensor
                  _buildMetricsSection(
                    skorAkustik: skorAkustik,
                    skorMotorik: skorMotorik,
                    skorSklera: skorSklera,
                  ),
                  const SizedBox(height: 28),

                  // 3. Section Resep Anti-Zombi
                  _buildRecipesSection(completedCount, totalCount),
                  const SizedBox(height: 28),

                  // 4. Tombol Selesai / Navigasi Beranda
                  _buildBottomActionButton(),
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
  Widget _buildTopBar(String idSkrining) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: borderBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil Skrining',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: primaryBlue,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Analisis Multimodal Selesai',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderBlack, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: borderBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              idSkrining,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: primaryBlue,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER CARD BIRU TUA ---
  Widget _buildPrimaryHeaderCard(String kategoriBurnout) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: primaryDark,
            offset: Offset(4, 4),
            blurRadius: 0,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
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
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC436),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderBlack, width: 1.5),
                ),
                child: const Text(
                  'Perlu Perhatian',
                  style: TextStyle(
                    color: borderBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Korelasi penurunan frekuensi langkah motorik dan mikrosleep sklera menunjukkan kelelahan kognitif tinggi.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      height: 1.4,
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

  // --- SECTION METRIK (3 KARTU KECIL) ---
  Widget _buildMetricsSection({
    required dynamic skorAkustik,
    required dynamic skorMotorik,
    required dynamic skorSklera,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.speed_rounded, size: 16, color: primaryBlue),
            SizedBox(width: 6),
            Text(
              'INDIKATOR MULTIMODAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: primaryBlue,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Akustik',
                score: skorAkustik.toString(),
                icon: Icons.graphic_eq_rounded,
                statusText: 'Monoton',
                accentColor: amberDark,
                bgTint: amberBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Motorik',
                score: skorMotorik.toString(),
                icon: Icons.directions_walk_rounded,
                statusText: 'Melambat',
                accentColor: redDark,
                bgTint: redBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Sklera',
                score: skorSklera.toString(),
                icon: Icons.remove_red_eye_outlined,
                statusText: 'Tegang',
                accentColor: amberDark,
                bgTint: amberBg,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String score,
    required IconData icon,
    required String statusText,
    required Color accentColor,
    required Color bgTint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: cardShadowGray,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: grayText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            score,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: borderBlack,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION RESEP ANTI-ZOMBI ---
  Widget _buildRecipesSection(int completedCount, int totalCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.checklist_rounded, size: 18, color: primaryBlue),
                SizedBox(width: 6),
                Text(
                  'Resep Anti-Zombi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: completedCount == totalCount ? greenBg : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: completedCount == totalCount ? greenDark : borderBlack,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: borderBlack,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                '$completedCount / $totalCount Selesai',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: completedCount == totalCount ? greenDark : borderBlack,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Tugas mikro-intervensi terpandu untuk memulihkan fungsi sistem saraf Anda.',
          style: TextStyle(
            fontSize: 12,
            color: grayText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // List Kartu Resep
        ..._recipes.asMap().entries.map((entry) {
          final index = entry.key;
          final recipe = entry.value;
          final isCompleted = recipe['is_completed'] as bool? ?? false;
          final jenis = recipe['jenis_intervensi'] ?? 'Fisik';
          final desc = recipe['deskripsi_tugas'] ?? '';

          return _buildRecipeCardItem(
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
    required int index,
    required String jenis,
    required String description,
    required bool isCompleted,
  }) {
    final isFisik = jenis.toLowerCase() == 'fisik';
    final badgeBg = isFisik ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF);
    final badgeColor = isFisik ? primaryBlue : const Color(0xFF7C3AED);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFFAFAF7) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? grayLight : borderBlack,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted ? cardShadowGray : borderBlack,
            offset: const Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox Custom
          InkWell(
            onTap: () => _toggleRecipeCompletion(index),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isCompleted ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderBlack, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: borderBlack,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Intervensi $jenis',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    if (isCompleted)
                      const Text(
                        'Selesai ✓',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: greenDark,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? grayLight : borderBlack,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TOMBOL AKSI BAWAH ---
  Widget _buildBottomActionButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: borderBlack,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_filled, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Simpan & Kembali ke Beranda',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
