import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Avatar + User Info (Expanded) + Notification Bell
              // BEBAS OVERFLOW DI SELURUH TIPE HP ANDROID
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
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: NeoColors.black,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info Pengguna (Dibungkus Expanded agar fleksibel dan tidak overflow)
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
                          _conditionText,
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

                  // Lonceng Notifikasi
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
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        color: NeoColors.black,
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
                      padding: EdgeInsets.zero,
                      tooltip: "Keluar Akun",
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      onPressed: () async {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/welcome',
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // THE SIGNATURE "OFFSET CANVAS" (RESPONSIF UNTUK ANDROID)
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

              // Text below canvas as required
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

              const SizedBox(height: 28),

              // GIANT NEO BUTTON: "Mulai Skrining"
              NeoButton(
                text: "🚀 Mulai Skrining Mandiri",
                icon: Icons.play_arrow_rounded,
                backgroundColor: NeoColors.primaryBlue,
                textColor: NeoColors.white,
                height: 58,
                borderRadius: 29, // Pill button
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

              const SizedBox(height: 14),

              // SECONDARY BUTTON: "Riwayat" (#5C5C5C)
              NeoButton(
                text: "📋 Riwayat & Tren Emosi",
                icon: Icons.history_rounded,
                backgroundColor: NeoColors.darkGray,
                textColor: NeoColors.white,
                height: 52,
                borderRadius: 26, // Pill button
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
            ],
          ),
        ),
      ),
    );
  }
}
