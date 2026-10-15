import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/offset_canvas_box.dart';
import 'stage1_mental_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;
  List<Map<String, dynamic>> _historyList = [];

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

  /// Memuat skor pemulihan & skrining terbaru dari MySQL (via backend Go)
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
        return stage;
    }
  }

  String get _conditionText {
    if (_isLoadingProfile) return 'Memuat kondisi terbaru...';
    final latest = _profile?['latest_screening'];
    if (latest is Map && latest['kategori_burnout'] != null) {
      return 'Terakhir: ${latest['kategori_burnout']}';
    }
    return _profile == null
        ? 'Kondisi: Server belum terhubung'
        : 'Kondisi: Belum Ada Skrining';
  }

  Widget _buildRecoveryCard() {
    final user = authService.currentUser;
    final int score = (user?.recoveryScore ?? 0).clamp(0, 100);
    final int total = (_profile?['total_screenings'] as num?)?.toInt() ?? 0;
    final int done = (_profile?['recipes_completed'] as num?)?.toInt() ?? 0;
    final int allRecipes = (_profile?['recipes_total'] as num?)?.toInt() ?? 0;
    final bool connected = _profile != null;

    return NeoCard(
      backgroundColor: NeoColors.white,
      borderRadius: 20,
      shadowOffset: 4,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Skor Pemulihan',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: NeoColors.black,
                  ),
                ),
              ),
              Text(
                connected ? '$score/100' : '-/100',
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
              value: connected ? score / 100 : 0,
              minHeight: 12,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(NeoColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            connected
                ? '${_stageLabel(user?.zombieStage ?? '')} • $total skrining • $done/$allRecipes resep selesai'
                : 'Hubungkan backend (port 8081) untuk memuat skor pemulihan Anda.',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: NeoColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: notificationService.getNotificationHistory(),
              builder: (context, snapshot) {
                final notifList = snapshot.data ?? [];
                final isLoading = snapshot.connectionState == ConnectionState.waiting;

                return Container(
                  height: MediaQuery.of(context).size.height * 0.72,
                  decoration: const BoxDecoration(
                    color: NeoColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(
                      top: BorderSide(color: NeoColors.borderBlack, width: 3.5),
                      left: BorderSide(color: NeoColors.borderBlack, width: 3.5),
                      right: BorderSide(color: NeoColors.borderBlack, width: 3.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: NeoColors.borderBlack.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: NeoColors.primaryYellow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: NeoColors.borderBlack, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    size: 20,
                                    color: NeoColors.black,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Notifikasi Sistem",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: NeoColors.black,
                                  ),
                                ),
                              ],
                            ),
                            if (notifList.isNotEmpty)
                              TextButton(
                                onPressed: () async {
                                  await notificationService.clearNotificationHistory();
                                  setModalState(() {});
                                },
                                child: const Text(
                                  "Bersihkan",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: NeoColors.redDark,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const Divider(color: NeoColors.borderBlack, thickness: 1.5, height: 1),

                      // Konten Notifikasi
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : notifList.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(28.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: NeoColors.lightGray,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: NeoColors.borderBlack,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.notifications_off_outlined,
                                              size: 38,
                                              color: NeoColors.darkGray,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          const Text(
                                            "Belum ada notifikasi baru",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: NeoColors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            "Peringatan gejala zombie dan pengingat skrining 24 jam akan tercatat di sini secara otomatis.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: NeoColors.darkGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: notifList.length,
                                    itemBuilder: (context, index) {
                                      final item = notifList[index];
                                      final bool isWarning = item['type'] == 'warning';

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isWarning ? const Color(0xFFFEF2F2) : NeoColors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isWarning ? NeoColors.redDark : NeoColors.borderBlack,
                                            width: 2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: NeoColors.borderBlack,
                                              offset: Offset(3, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isWarning ? NeoColors.redLight : NeoColors.primaryYellow,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isWarning ? NeoColors.redDark : NeoColors.borderBlack,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Icon(
                                                isWarning ? Icons.warning_rounded : Icons.schedule_rounded,
                                                size: 20,
                                                color: isWarning ? NeoColors.redDark : NeoColors.black,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item['title'] ?? 'Notifikasi',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w900,
                                                            fontSize: 13,
                                                            color: isWarning ? NeoColors.darkRedZombie : NeoColors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        item['time'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w700,
                                                          color: NeoColors.darkGray,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item['body'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: NeoColors.slateDark,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: NeoColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: NeoColors.borderBlack, width: 2.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text(
              "Konfirmasi Keluar",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari akun RESTGUARD?",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              "Batal",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: NeoColors.slateDark,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: NeoColors.borderBlack, width: 2),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await authService.logout(context);
            },
            child: const Text(
              "Keluar",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
