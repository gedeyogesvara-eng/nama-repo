import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/api_config.dart';
import '../theme/neo_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/offset_canvas_box.dart';
import 'stage1_mental_screen.dart';
import 'history_screen.dart';
import 'anti_zombie_recipe_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;
<<<<<<< HEAD
=======
  List<Map<String, dynamic>> _historyList = [];
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadHistory();
    HistoryService.historyNotifier.addListener(_onHistoryChanged);
    notificationService.init();
  }

  @override
  void dispose() {
    HistoryService.historyNotifier.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    if (mounted) {
      setState(() {
        _historyList = HistoryService.historyNotifier.value;
      });
    }
  }

  Future<void> _loadHistory() async {
    final list = await HistoryService.getHistoryList();
    if (mounted) {
      setState(() {
        _historyList = list;
      });
    }
  }

  /// Memuat skor pemulihan & status skrining terbaru dari MySQL (via backend Go)
  Future<void> _loadProfile() async {
    final data = await authService.refreshProfile();
    if (!mounted) return;

    setState(() {
      _profile = data;
      _isLoadingProfile = false;
    });
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'CRITICAL_ZOMBIE':
        return 'Zombi Kritis';
      case 'TIRED_ZOMBIE':
        return 'Zombi Lelah';
      case 'RECOVERING_HUMAN':
        return 'Manusia Pulih';
      case 'HEALTHY_HUMAN':
        return 'Manusia Sehat';
      default:
        return 'Kondisi Prima';
    }
  }

  String get _conditionText {
    if (_isLoadingProfile) return 'Memuat kondisi terbaru...';
    final int total = (_profile?['total_screenings'] as num?)?.toInt() ?? 0;
    if (total == 0) return 'Kondisi: Belum Ada Skrining';

    final latest = _profile?['latest_screening'];
    if (latest is Map && latest['kategori_burnout'] != null) {
      return 'Terakhir: ${latest['kategori_burnout']}';
    }
    return _profile == null
        ? 'Kondisi: Server belum terhubung'
        : 'Kondisi: Siap Skrining';
  }

  // --- KARTU SKOR PEMULIHAN (DINAMIS DARI MYSQL) ---
  Widget _buildRecoveryCard() {
    final isDark = themeController.isDarkMode;
    final user = authService.currentUser;
    final int total = (_profile?['total_screenings'] as num?)?.toInt() ?? 0;
    final int done = (_profile?['recipes_completed'] as num?)?.toInt() ?? 0;
    final int allRecipes = (_profile?['recipes_total'] as num?)?.toInt() ?? 0;
    final bool connected = _profile != null;

    final int displayScore = total == 0 ? 50 : (user?.recoveryScore ?? 50).clamp(0, 100);
    final String stageName = total == 0 ? 'Belum Ada Skrining' : _stageLabel(user?.zombieStage ?? '');

    return NeoCard(
      backgroundColor: isDark ? const Color(0xFF1E1E26) : NeoColors.white,
      borderRadius: 20,
      shadowOffset: 4,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Skor Pemulihan',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? Colors.white : NeoColors.black,
                  ),
                ),
              ),
              Text(
                connected ? '$displayScore/100' : '-/100',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: NeoColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: connected ? displayScore / 100 : 0,
              minHeight: 12,
              backgroundColor: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(NeoColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            connected
                ? (total == 0
                    ? '0 skrining • 0/0 resep selesai • Jalankan skrining pertama Anda'
                    : '$stageName • $total skrining • $done/$allRecipes resep selesai')
                : 'Hubungkan backend (port 8081) untuk memuat skor pemulihan Anda.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? const Color(0xFFA1A1AA) : NeoColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  // --- MODAL: PROFIL & AKUN LENGKAP DENGAN EDIT NAMA & PENGATURAN BASE URL ---
  void _showProfileModal(BuildContext context) {
    final user = authService.currentUser;
    final int total = (_profile?['total_screenings'] as num?)?.toInt() ?? 0;
    final int done = (_profile?['recipes_completed'] as num?)?.toInt() ?? 0;
    final int score = (user?.recoveryScore ?? 50).clamp(0, 100);

=======
  @override
  Widget build(BuildContext context) {
    final String userName = authService.currentUser?.displayName?.isNotEmpty == true
        ? authService.currentUser!.displayName!
        : "Budi Santoso";

    final String statusText = _historyList.isNotEmpty
        ? "Kondisi: ${_historyList.first['title']} (${_historyList.first['score']}/100)"
        : "Kondisi: Belum Skrining Hari Ini";

    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Avatar + User Info (Expanded) + Notification Bell + Logout
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Foto Profil / Avatar
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: NeoColors.primaryYellow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NeoColors.borderBlack,
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.borderBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: authService.currentUser?.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                authService.currentUser!.photoUrl!,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: NeoColors.black,
                                  size: 28,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              color: NeoColors.black,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info Pengguna
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Halo, $userName",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _historyList.isNotEmpty ? statusText : _conditionText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NeoColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 4. Lonceng Notifikasi (Membuka daftar notifikasi dari state)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: NeoColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NeoColors.borderBlack,
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.borderBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: "Daftar Notifikasi",
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        color: NeoColors.black,
                        size: 20,
                      ),
                      onPressed: () => _showNotificationsModal(context),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Logout / Keluar Akun
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NeoColors.borderBlack,
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.borderBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: "Keluar dari Akun",
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      onPressed: () => _showLogoutDialog(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // THE SIGNATURE "OFFSET CANVAS"
              LayoutBuilder(
                builder: (context, constraints) {
                  final double canvasWidth = (constraints.maxWidth - 12).clamp(240.0, 360.0);
                  final double canvasHeight = (canvasWidth * 0.85).clamp(200.0, 260.0);

                  return OffsetCanvasBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    backgroundColor: NeoColors.primaryBlue,
                    outlineColor: NeoColors.primaryBlue,
                    borderRadius: 32,
                    offset: 10,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Stars / Moon shapes decoration inside
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: NeoColors.primaryYellow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: NeoColors.borderBlack,
                                  width: 2,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: NeoColors.black,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "AI AGENT",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: NeoColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.star,
                                    color: NeoColors.primaryYellow, size: 20),
                                SizedBox(width: 4),
                                Icon(Icons.dark_mode,
                                    color: Colors.white, size: 18),
                              ],
                            ),
                          ],
                        ),

                        // Central Graphic Icon
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            size: 54,
                            color: NeoColors.white,
                          ),
                        ),

                        // Canvas Bottom Caption
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: NeoColors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "3 Tahap: Coretan • Gerak • Wajah",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: NeoColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Title Branding
              const Center(
                child: Text(
                  "EMO-SENSE AI",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.primaryBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  "Maintain your emotions and detect fatigue early",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.darkGray,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // GIANT NEO BUTTON: "Mulai Skrining"
              NeoButton(
                text: "🚀 Mulai Skrining Mandiri",
                icon: Icons.play_arrow_rounded,
                backgroundColor: NeoColors.primaryBlue,
                textColor: NeoColors.white,
                height: 58,
                borderRadius: 29,
                shadowOffset: 6,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Stage1MentalScreen(),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),

              const SizedBox(height: 12),

              // SECONDARY BUTTON: "Riwayat & Tren Emosi"
              NeoButton(
                text: "📋 Riwayat & Tren Emosi",
                icon: Icons.history_rounded,
                backgroundColor: NeoColors.darkGray,
                textColor: NeoColors.white,
                height: 52,
                borderRadius: 26,
                shadowOffset: 5,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),

              const SizedBox(height: 24),

              // SEKSI RIWAYAT DIAGNOSIS (BAGIAN 1 & 2 DARI PROMPT)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Riwayat Diagnosis",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: NeoColors.black,
                    ),
                  ),
                  if (_historyList.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Lihat Semua →",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.primaryBlue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // JIKA KOSONG: TAMPILKAN UI "Belum ada riwayat diagnosis. Lakukan tes pertama Anda hari ini!"
              if (_historyList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  decoration: BoxDecoration(
                    color: NeoColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: NeoColors.borderBlack, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.borderBlack,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                          border: Border.all(color: NeoColors.borderBlack, width: 2),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          size: 34,
                          color: NeoColors.black,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Belum ada riwayat diagnosis. Lakukan tes pertama Anda hari ini!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: NeoColors.black,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Hasil tes skrining multimodal AI Anda akan tersimpan secara otomatis.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: NeoColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // JIKA ADA DATA: TAMPILKAN DIAGNOSIS TERBARU
                _buildLatestHistoryCard(_historyList.first),

              const SizedBox(height: 20),

              // Skor Pemulihan (data nyata dari MySQL)
              _buildRecoveryCard(),
              const SizedBox(height: 16),

              // Status Summary Info NeoCard
              NeoCard(
                backgroundColor: NeoColors.white,
                borderRadius: 20,
                shadowOffset: 4,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: NeoColors.borderBlack, width: 2),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: NeoColors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Estimasi Waktu Skrining",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: NeoColors.black,
                            ),
                          ),
                          Text(
                            "Cukup 1-2 menit untuk hasil komprehensif.",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: NeoColors.darkGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestHistoryCard(Map<String, dynamic> item) {
    Color resolveColor(dynamic val, Color fallback) {
      if (val is Color) return val;
      if (val is int) return Color(val);
      return fallback;
    }

    final Color accentColor = resolveColor(item['accentColor'], NeoColors.primaryBlue);
    final Color bgTint = resolveColor(item['bgTint'], NeoColors.lightGray);
    final Color textColor = resolveColor(item['textColor'], NeoColors.black);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeoColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NeoColors.borderBlack, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: NeoColors.borderBlack,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: NeoColors.darkGray),
                    const SizedBox(width: 5),
                    Text(
                      '${item['date']} • ${item['time']}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: NeoColors.darkGray,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor, width: 1.5),
                  ),
                  child: Text(
                    'Skor ${item['score']}/100',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item['title'] ?? 'Diagnosis AI',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item['summary'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NeoColors.slateDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODAL DAFTAR NOTIFIKASI NYATA (DARI STATE, BUKAN DATA DUMMY)
  void _showNotificationsModal(BuildContext context) {
>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final activeUrl = ApiConfig.baseUrl;
            final isDarkModal = themeController.isDarkMode;

            return Container(
              decoration: BoxDecoration(
                color: isDarkModal ? const Color(0xFF16161E) : NeoColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: const Border(
                  top: BorderSide(color: NeoColors.borderBlack, width: 3),
                  left: BorderSide(color: NeoColors.borderBlack, width: 3),
                  right: BorderSide(color: NeoColors.borderBlack, width: 3),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: NeoColors.borderBlack.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Modal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profil & Akun Pengguna',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.primaryBlue,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: NeoColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                            ),
                            child: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 1. KARTU INFORMASI AKUN
                    NeoCard(
                      backgroundColor: NeoColors.white,
                      borderRadius: 18,
                      shadowOffset: 3,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: NeoColors.primaryYellow,
                              shape: BoxShape.circle,
                              border: Border.all(color: NeoColors.borderBlack, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: NeoColors.borderBlack, offset: Offset(2, 2)),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.person_rounded, size: 34, color: NeoColors.black),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user?.displayName ?? 'Pengguna Somatic',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: NeoColors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _showEditNameDialog(context, setModalState),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: NeoColors.borderBlack, width: 1),
                                        ),
                                        child: const Icon(Icons.edit_rounded, size: 14, color: NeoColors.black),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.email ?? 'Akun Lokal / Demo',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: NeoColors.darkGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: NeoColors.primaryBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ID #${(user?.userId ?? 1).toString().padLeft(3, '0')}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: NeoColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: NeoColors.greenLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _stageLabel(user?.zombieStage ?? ''),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: NeoColors.greenDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. RINGKASAN STATISTIK
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatCard('Sesi Skrining', '$total Sesi', Icons.history_rounded, NeoColors.primaryBlue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniStatCard('Skor Pemulihan', '$score/100', Icons.battery_charging_full_rounded, NeoColors.greenDark),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniStatCard('Resep Selesai', '$done Selesai', Icons.task_alt_rounded, NeoColors.amber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 3. PENGATURAN TAMPILAN / TEMA APLIKASI
                    NeoCard(
                      backgroundColor: isDarkModal ? const Color(0xFF242432) : NeoColors.white,
                      borderRadius: 18,
                      shadowOffset: 3,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDarkModal ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                size: 18,
                                color: NeoColors.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tampilan / Tema Aplikasi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isDarkModal ? Colors.white : NeoColors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pilih mode tampilan terang (Light Mode) atau gelap (Dark Mode).',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkModal ? const Color(0xFFA1A1AA) : NeoColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Tombol Mode Terang
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    await themeController.setThemeMode(ThemeMode.light);
                                    setModalState(() {});
                                    setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: !isDarkModal ? const Color(0xFFFEF3C7) : const Color(0xFF1E1E28),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !isDarkModal ? NeoColors.borderBlack : const Color(0xFF3F3F50),
                                        width: !isDarkModal ? 2.5 : 1.5,
                                      ),
                                      boxShadow: !isDarkModal
                                          ? const [
                                              BoxShadow(color: NeoColors.borderBlack, offset: Offset(2, 2)),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.wb_sunny_rounded, color: Color(0xFFD97706), size: 22),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tema Terang',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: isDarkModal ? Colors.white : NeoColors.black,
                                          ),
                                        ),
                                        Text(
                                          'Light Mode',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkModal ? const Color(0xFFA1A1AA) : NeoColors.darkGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Tombol Mode Gelap
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    await themeController.setThemeMode(ThemeMode.dark);
                                    setModalState(() {});
                                    setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: isDarkModal ? const Color(0xFF314BB5) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDarkModal ? Colors.white : NeoColors.borderBlack.withValues(alpha: 0.2),
                                        width: isDarkModal ? 2.5 : 1.5,
                                      ),
                                      boxShadow: isDarkModal
                                          ? const [
                                              BoxShadow(color: NeoColors.borderBlack, offset: Offset(2, 2)),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.nightlight_round,
                                          color: isDarkModal ? Colors.white : NeoColors.darkGray,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tema Gelap',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: isDarkModal ? Colors.white : NeoColors.black,
                                          ),
                                        ),
                                        Text(
                                          'Dark Mode',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkModal ? const Color(0xFFE0E7FF) : NeoColors.darkGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. PENGATURAN KONEKSI SERVER (BASE URL API)
                    NeoCard(
                      backgroundColor: isDarkModal ? const Color(0xFF242432) : NeoColors.white,
                      borderRadius: 18,
                      shadowOffset: 3,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.dns_rounded, size: 18, color: NeoColors.primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                'Koneksi Server Backend (Base URL)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: NeoColors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ubah alamat IP jika berpindah Wi-Fi/Hotspot tanpa perlu build ulang APK.',
                            style: TextStyle(fontSize: 11, color: NeoColors.darkGray),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NeoColors.borderBlack.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link_rounded, size: 16, color: NeoColors.darkGray),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activeUrl,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: NeoColors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showEditBaseUrlDialog(context, setModalState),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: NeoColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(color: NeoColors.borderBlack, offset: Offset(1.5, 1.5)),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Ganti Alamat Server',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: NeoColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _testServerConnection(context),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: NeoColors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(color: NeoColors.borderBlack, offset: Offset(1.5, 1.5)),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Uji Koneksi (Ping)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: NeoColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. TOMBOL LOGOUT
                    NeoButton(
                      text: 'Keluar dari Akun (Logout)',
                      icon: Icons.logout_rounded,
                      backgroundColor: const Color(0xFFEF4444),
                      textColor: NeoColors.white,
                      height: 48,
                      borderRadius: 16,
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: NeoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NeoColors.borderBlack, width: 1.5),
        boxShadow: const [
          BoxShadow(color: NeoColors.borderBlack, offset: Offset(1.5, 1.5)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: NeoColors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: NeoColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Dialog Edit Nama
  void _showEditNameDialog(BuildContext context, StateSetter setModalState) {
    final textController = TextEditingController(text: authService.currentUser?.displayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: NeoColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: NeoColors.borderBlack, width: 2),
          ),
          title: const Text('Edit Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Nama lengkap Anda',
              filled: true,
              fillColor: NeoColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: NeoColors.darkGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.primaryBlue,
                foregroundColor: NeoColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final newName = textController.text.trim();
                if (newName.isEmpty) return;
                Navigator.pop(ctx);
                final ok = await authService.updateProfileName(newName);
                if (ok) {
                  setModalState(() {});
                  setState(() {});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama berhasil diperbarui!'), backgroundColor: NeoColors.greenDark),
                    );
                  }
                }
              },
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Dialog Edit Base URL API
  void _showEditBaseUrlDialog(BuildContext context, StateSetter setModalState) {
    final textController = TextEditingController(text: ApiConfig.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: NeoColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: NeoColors.borderBlack, width: 2),
          ),
          title: const Text('Ubah Base URL API', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Masukkan URL Backend Go (misal http://192.168.x.x:8081):', style: TextStyle(fontSize: 12, color: NeoColors.darkGray)),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'http://192.168.18.12:8081',
                  filled: true,
                  fillColor: NeoColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Localhost (8081)', style: TextStyle(fontSize: 10)),
                    onPressed: () => textController.text = 'http://localhost:8081',
                  ),
                  ActionChip(
                    label: const Text('Wi-Fi Laptop (192.168.18.12)', style: TextStyle(fontSize: 10)),
                    onPressed: () => textController.text = 'http://192.168.18.12:8081',
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: NeoColors.darkGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.primaryBlue,
                foregroundColor: NeoColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final url = textController.text.trim();
                Navigator.pop(ctx);
                await ApiConfig.setCustomBaseUrl(url);
                setModalState(() {});
                await _loadProfile();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Alamat server diatur ke: ${ApiConfig.baseUrl}')),
                  );
                }
              },
              child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Uji koneksi ke /api/health
  Future<void> _testServerConnection(BuildContext context) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/health')).timeout(const Duration(seconds: 4));
      if (!context.mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final String dbStatus = decoded['mysql_status'] ?? 'ok';
        final bool pyStatus = decoded['python_ai_online'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Terhubung! MySQL: $dbStatus • Python AI: ${pyStatus ? "Online" : "Offline"}'),
            backgroundColor: NeoColors.greenDark,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Server merespons HTTP ${res.statusCode}'), backgroundColor: NeoColors.amber),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal menghubungi server: $e'), backgroundColor: NeoColors.redDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = themeController.isDarkMode;
    final Color scaffoldBg = isDark ? const Color(0xFF121217) : NeoColors.background;
    final Color cardBg = isDark ? const Color(0xFF1E1E26) : NeoColors.white;
    final Color textMain = isDark ? Colors.white : NeoColors.black;
    final Color textSub = isDark ? const Color(0xFFA1A1AA) : NeoColors.darkGray;
    final Color borderCol = isDark ? const Color(0xFF38384A) : NeoColors.borderBlack;

    final String userName = authService.currentUser?.displayName?.isNotEmpty == true
        ? authService.currentUser!.displayName!
        : "Budi Santoso";

    final int done = (_profile?['recipes_completed'] as num?)?.toInt() ?? 0;
    final int allRecipes = (_profile?['recipes_total'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: NeoColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Avatar (Klik untuk Buka Profil & Akun) + User Info + Notification Bell + Logout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Foto Profil / Avatar (DAPAT DIKLIK)
                    InkWell(
                      onTap: () => _showProfileModal(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: NeoColors.primaryYellow,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderCol,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: borderCol,
                              offset: const Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: NeoColors.black,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info Pengguna
                    Expanded(
                      child: InkWell(
                        onTap: () => _showProfileModal(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Halo, $userName",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _conditionText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Lonceng Notifikasi
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: borderCol,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: borderCol,
                            offset: const Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.notifications_active_outlined,
                          color: textMain,
                          size: 20,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                "Pengingat skrining aktif setiap jam 19.00 WIB",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              backgroundColor: NeoColors.slateDark,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: NeoColors.borderBlack,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Tombol Buka Profil / Pengaturan
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: borderCol,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: borderCol,
                            offset: const Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: "Pengaturan & Akun",
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: NeoColors.black,
                          size: 20,
                        ),
                        onPressed: () => _showProfileModal(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // THE SIGNATURE "OFFSET CANVAS"
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double canvasWidth = (constraints.maxWidth - 12).clamp(240.0, 360.0);
                    final double canvasHeight = (canvasWidth * 0.82).clamp(190.0, 250.0);

                    return OffsetCanvasBox(
                      width: canvasWidth,
                      height: canvasHeight,
                      backgroundColor: NeoColors.primaryBlue,
                      outlineColor: NeoColors.primaryBlue,
                      borderRadius: 32,
                      offset: 10,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: NeoColors.primaryYellow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: NeoColors.borderBlack,
                                    width: 2,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: NeoColors.black,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "AI AGENT",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: NeoColors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: NeoColors.primaryYellow, size: 20),
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: isDark ? "Beralih ke Tema Terang" : "Beralih ke Tema Gelap",
                                    child: InkWell(
                                      onTap: () async {
                                        await themeController.toggleTheme();
                                        setState(() {});
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isDark ? Icons.wb_sunny_rounded : Icons.dark_mode,
                                          color: isDark ? NeoColors.primaryYellow : Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              size: 50,
                              color: NeoColors.white,
                            ),
                          ),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 7,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: NeoColors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "3 Tahap: Coretan • Gerak • Wajah",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: NeoColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                Center(
                  child: Text(
                    "EMO-SENSE AI",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? const Color(0xFF60A5FA) : NeoColors.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "Deteksi dini kelelahan & pulihkan energi somatik Anda",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textSub,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // GIANT NEO BUTTON 1: "Mulai Skrining"
                NeoButton(
                  text: "🚀 Mulai Skrining Mandiri",
                  icon: Icons.play_arrow_rounded,
                  backgroundColor: NeoColors.primaryBlue,
                  textColor: NeoColors.white,
                  height: 56,
                  borderRadius: 28,
                  shadowOffset: 6,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Stage1MentalScreen(),
                      ),
                    ).then((_) => _loadProfile());
                  },
                ),

                const SizedBox(height: 12),

                // SECONDARY BUTTON 2: "Riwayat & Tren Emosi"
                NeoButton(
                  text: "📋 Riwayat & Tren Emosi",
                  icon: Icons.history_rounded,
                  backgroundColor: isDark ? const Color(0xFF282836) : NeoColors.darkGray,
                  textColor: NeoColors.white,
                  height: 50,
                  borderRadius: 25,
                  shadowOffset: 5,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    ).then((_) => _loadProfile());
                  },
                ),

                const SizedBox(height: 12),

                // TERTIARY BUTTON 3: "Resep Anti-Zombi" (SETARA DENGAN 2 TOMBOL DI ATASNYA)
                NeoButton(
                  text: "💊 Resep Anti-Zombi ($done/$allRecipes)",
                  icon: Icons.medication_rounded,
                  backgroundColor: NeoColors.primaryYellow,
                  textColor: NeoColors.borderBlack,
                  height: 50,
                  borderRadius: 25,
                  shadowOffset: 5,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AntiZombieRecipeScreen(),
                      ),
                    ).then((_) => _loadProfile());
                  },
                ),

                const SizedBox(height: 20),

                // SKOR PEMULIHAN (DATA NYATA MYSQL)
                _buildRecoveryCard(),

                const SizedBox(height: 18),

                // Status Info Box
                NeoCard(
                  backgroundColor: cardBg,
                  borderRadius: 18,
                  shadowOffset: 3,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderCol, width: 1.8),
                        ),
                        child: const Icon(
                          Icons.timer_outlined,
                          color: NeoColors.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Estimasi Waktu Skrining",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: textMain,
                              ),
                            ),
                            Text(
                              "Cukup 1-2 menit untuk 4 sensor multimodal lengkap.",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
