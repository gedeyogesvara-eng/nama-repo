import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/api_config.dart';
import '../services/history_service.dart';
import '../theme/theme_controller.dart';
import 'stage1_mental_screen.dart';
import 'relaxation_drawing_screen.dart';
import 'history_screen.dart';
import 'anti_zombie_recipe_screen.dart';

// --- PANDUAN GAYA DARI DESAIN MINIMAL ANDROID UI (HTML & SCREENSHOT) ---
const Color _kAppBg = Color(0xFFF2F1EB);
const Color _kAppPrimary = Color(0xFF314BB5);
const Color _kAppPrimaryDark = Color(0xFF23378D);
const Color _kAppPrimaryLight = Color(0xFFE8ECFA);
const Color _kAppGray = Color(0xFF5C5C5C);
const Color _kAppGrayLight = Color(0xFF8E8E93);
const Color _kAppGrayBorder = Color(0xFFD5D3CB);
const Color _kAppCard = Color(0xFFFFFFFF);
const Color _kShadowSolid = Color(0x12000000);
const Color _kShadowPrimary = Color(0x28314BB5);
const Color _kShadowButton = Color(0x30314BB5);
const Color _kShadowGray = Color(0x18000000);
const Color _kShadowCard = Color(0x0F000000);

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

  /// Memuat skor pemulihan & status skrining terbaru dari MySQL (via backend Go)
  Future<void> _loadProfile() async {
    final data = await authService.refreshProfile();
    // Ambil (GET) riwayat diagnosis terbaru dari backend Go MySQL
    try {
      await HistoryService.getHistoryList();
    } catch (_) {}
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

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : _kAppPrimary.withValues(alpha: 0.08),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
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
                    color: isDark ? Colors.white : _kAppPrimary,
                  ),
                ),
              ),
              Text(
                connected ? '$displayScore/100' : '-/100',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: _kAppPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: connected ? displayScore / 100 : 0,
              minHeight: 10,
              backgroundColor: isDark ? const Color(0xFF2E2E3E) : _kAppPrimaryLight,
              valueColor: const AlwaysStoppedAnimation<Color>(_kAppPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            connected
                ? (total == 0
                    ? 'Belum ada data. Mulai skrining pertamamu!'
                    : '$stageName • $done/$allRecipes resep selesai')
                : 'Sambungkan server untuk cek skor pemulihan.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? const Color(0xFFA1A1AA) : _kAppGray,
            ),
          ),
        ],
      ),
    );
  }

  // --- MODAL: PROFIL & AKUN LENGKAP DENGAN EDIT NAMA & PENGATURAN BASE URL (MODERN CLEAN) ---
  void _showProfileModal(BuildContext context) {
    final user = authService.currentUser;
    final int total = (_profile?['total_screenings'] as num?)?.toInt() ?? 0;
    final int done = (_profile?['recipes_completed'] as num?)?.toInt() ?? 0;
    final int score = (user?.recoveryScore ?? 50).clamp(0, 100);

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
                color: isDarkModal ? const Color(0xFF181822) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                          color: _kAppGrayLight.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header Modal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profil & Akun Pengguna',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _kAppPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDarkModal ? const Color(0xFF262636) : _kAppPrimaryLight.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDarkModal ? Colors.white : _kAppPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. KARTU INFORMASI AKUN (Modern Clean, No black border)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDarkModal ? const Color(0xFF222230) : _kAppPrimaryLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _kAppPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _kAppPrimary.withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.person_outline_rounded, size: 28, color: Colors.white),
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
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDarkModal ? Colors.white : _kAppPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _showEditNameDialog(context, setModalState),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _kAppPrimary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.edit_rounded, size: 14, color: _kAppPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user?.email ?? 'Akun Lokal / Demo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkModal ? const Color(0xFFA1A1AA) : _kAppGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _kAppPrimary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'ID #${(user?.userId ?? 1).toString().padLeft(3, '0')}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: _kAppPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _stageLabel(user?.zombieStage ?? ''),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF047857),
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
                    const SizedBox(height: 16),

                    // 2. RINGKASAN STATISTIK
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatCard('Sesi Skrining', '$total Sesi', Icons.history_rounded, _kAppPrimary, isDarkModal),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMiniStatCard('Skor Pemulihan', '$score/100', Icons.battery_charging_full_rounded, const Color(0xFF059669), isDarkModal),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMiniStatCard('Resep Selesai', '$done Selesai', Icons.task_alt_rounded, const Color(0xFFD97706), isDarkModal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. PENGATURAN TAMPILAN / TEMA APLIKASI
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDarkModal ? const Color(0xFF222230) : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _kAppPrimary.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDarkModal ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                size: 18,
                                color: _kAppPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tampilan / Tema Aplikasi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDarkModal ? Colors.white : _kAppPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pilih mode tampilan terang (Light Mode) atau gelap (Dark Mode).',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkModal ? const Color(0xFFA1A1AA) : _kAppGray,
                            ),
                          ),
                          const SizedBox(height: 14),
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
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: !isDarkModal ? _kAppPrimary : (isDarkModal ? const Color(0xFF2B2B3C) : _kAppBg),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: !isDarkModal
                                          ? [
                                              BoxShadow(
                                                color: _kAppPrimary.withValues(alpha: 0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.wb_sunny_rounded,
                                          color: !isDarkModal ? Colors.white : const Color(0xFFD97706),
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tema Terang',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: !isDarkModal ? Colors.white : (isDarkModal ? Colors.white : _kAppPrimary),
                                          ),
                                        ),
                                        Text(
                                          'Light Mode',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: !isDarkModal ? Colors.white.withValues(alpha: 0.8) : _kAppGrayLight,
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
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: isDarkModal ? _kAppPrimary : _kAppBg,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: isDarkModal
                                          ? [
                                              BoxShadow(
                                                color: _kAppPrimary.withValues(alpha: 0.35),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.nightlight_round,
                                          color: isDarkModal ? Colors.white : _kAppGray,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tema Gelap',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: isDarkModal ? Colors.white : _kAppPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Dark Mode',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkModal ? Colors.white.withValues(alpha: 0.8) : _kAppGrayLight,
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
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDarkModal ? const Color(0xFF222230) : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _kAppPrimary.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.dns_rounded, size: 18, color: _kAppPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Koneksi Server Backend (Base URL)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDarkModal ? Colors.white : _kAppPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ubah alamat IP jika berpindah Wi-Fi/Hotspot tanpa perlu build ulang APK.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkModal ? const Color(0xFFA1A1AA) : _kAppGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDarkModal ? const Color(0xFF2B2B3C) : _kAppBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link_rounded, size: 16, color: _kAppPrimary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activeUrl,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: isDarkModal ? Colors.white : _kAppPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showEditBaseUrlDialog(context, setModalState),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      color: _kAppPrimary,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kAppPrimary.withValues(alpha: 0.28),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Ganti Alamat Server',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _testServerConnection(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      color: isDarkModal ? const Color(0xFF2B2B3C) : _kAppPrimaryLight,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kAppPrimary.withValues(alpha: 0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Uji Koneksi (Ping)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: _kAppPrimary,
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
                    const SizedBox(height: 22),

                    // 5. TOMBOL LOGOUT (Clean pill shape, soft shadow)
                    InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                        }
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Keluar dari Akun (Logout)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color, [bool isDark = false]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222230) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kAppPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : _kAppPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _kAppGrayLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Dialog Edit Nama (Modern Clean)
  void _showEditNameDialog(BuildContext context, StateSetter setModalState) {
    final textController = TextEditingController(text: authService.currentUser?.displayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: const Text(
            'Edit Nama Lengkap',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _kAppPrimary),
          ),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Nama lengkap Anda',
              filled: true,
              fillColor: _kAppBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _kAppPrimary, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: _kAppGray, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAppPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                      const SnackBar(
                        content: Text('Nama berhasil diperbarui!'),
                        backgroundColor: Color(0xFF059669),
                      ),
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

  // Dialog Edit Base URL API (Modern Clean)
  void _showEditBaseUrlDialog(BuildContext context, StateSetter setModalState) {
    final textController = TextEditingController(text: ApiConfig.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: const Text(
            'Ubah Base URL API',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _kAppPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan URL Backend Go (misal http://192.168.x.x:8081):',
                style: TextStyle(fontSize: 12, color: _kAppGray),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'http://192.168.18.12:8081',
                  filled: true,
                  fillColor: _kAppBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: _kAppPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Localhost (8081)', style: TextStyle(fontSize: 10, color: _kAppPrimary, fontWeight: FontWeight.bold)),
                    backgroundColor: _kAppPrimaryLight,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () => textController.text = 'http://localhost:8081',
                  ),
                  ActionChip(
                    label: const Text('Wi-Fi Laptop (192.168.18.12)', style: TextStyle(fontSize: 10, color: _kAppPrimary, fontWeight: FontWeight.bold)),
                    backgroundColor: _kAppPrimaryLight,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () => textController.text = 'http://192.168.18.12:8081',
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: _kAppGray, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAppPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                final url = textController.text.trim();
                Navigator.pop(ctx);
                await ApiConfig.setCustomBaseUrl(url);
                setModalState(() {});
                await _loadProfile();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Alamat server diatur ke: ${ApiConfig.baseUrl}'),
                      backgroundColor: _kAppPrimary,
                    ),
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
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Server merespons HTTP ${res.statusCode}'), backgroundColor: const Color(0xFFD97706)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal menghubungi server: $e'), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    required String desc,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    String? extra,
    required bool isCompleted,
    bool isMissed = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline node
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isMissed ? const Color(0xFFE57373) : _kAppPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMissed ? Icons.close_rounded : Icons.check_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _kAppPrimary,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _kAppGrayLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: _kAppGray,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  if (extra != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      extra,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _kAppGrayLight,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = themeController.isDarkMode;
    final Color scaffoldBg = isDark ? const Color(0xFF121217) : _kAppBg;

    final String userName = authService.currentUser?.displayName?.isNotEmpty == true
        ? authService.currentUser!.displayName!
        : "User Lorem Ipsum";

    final user = authService.currentUser;
    final String userSub = user != null
        ? "ID #${user.userId.toString().padLeft(3, '0')}"
        : "ID Lorem Ipsum";


    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: _kAppPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP HEADER BAR: Profile Avatar + User Info + Notification Bell
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Info (Clickable -> Opens Modal)
                    InkWell(
                      onTap: () => _showProfileModal(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _kAppPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _kAppPrimary.withValues(alpha: 0.35),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _kAppPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                userSub,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _kAppPrimary.withValues(alpha: 0.70),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Notification Bell (Clickable -> SnackBar as tested in test 5)
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        color: _kAppPrimary,
                        size: 24,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Pengingat skrining aktif setiap jam 19.00 WIB",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: const Color(0xFF1E293B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. CARD RELAKSASI MENGGAMBAR (Modern Clean with Offset Contour)
                SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      // Layer 1: Background offset outline (Deep Blue Modern Clean)
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(color: _kAppPrimary, width: 2.0),
                          ),
                        ),
                      ),
                      // Layer 2: Main deep blue card
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 8,
                        bottom: 8,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RelaxationDrawingScreen(),
                              ),
                            ).then((_) => _loadProfile());
                          },
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                            decoration: BoxDecoration(
                              color: _kAppPrimary,
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: _kAppPrimary.withValues(alpha: 0.32),
                                  offset: const Offset(0, 12),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // White dot + Title & Tag
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Relaksasi Menggambar",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.palette_outlined, size: 14, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            "Kanvas",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Headline & Brief Description
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Coretan Bebas",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Lepaskan penatmu dengan coretan bebas",
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                // Action Button: Mulai Menggambar
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            offset: const Offset(0, 2),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.brush_rounded, size: 14, color: _kAppPrimary),
                                          SizedBox(width: 6),
                                          Text(
                                            "Mulai Menggambar",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _kAppPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 3. BRANDING & MOTTO ("EMO-SENSE AI", "Destress", "Jaga emosi & fokusmu")
                Center(
                  child: Text(
                    "EMO-SENSE AI",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: _kAppPrimary.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Center(
                  child: Text(
                    "Destress",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kAppPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "Jaga emosi & fokusmu",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kAppPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. PROTOKOL ISTIRAHAT SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Protokol Istirahat",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _kAppPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _kAppPrimary.withValues(alpha: 0.08),
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            "2 Langkah",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kAppPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Aktif Sekarang",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kAppPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Card 1: Detoks Layar (Active - Deep Blue)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kAppPrimary,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _kAppPrimary.withValues(alpha: 0.32),
                        offset: const Offset(0, 12),
                        blurRadius: 28,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: _kAppPrimary.withValues(alpha: 0.12),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: _DetoxPhoneIcon(color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "LANGKAH 01 • AKTIF",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Detoks Layar",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  offset: const Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Text(
                              "15 Menit",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _kAppPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Istirahatkan matamu dari layar sejenak.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Tulis perasaanmu...",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Detoks layar selesai! Hebat."),
                                    backgroundColor: _kAppPrimary,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.10),
                                      offset: const Offset(0, 2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Selesaikan",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _kAppPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Card 2: Minum Air & Mineral (Next State - White)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _kAppPrimary.withValues(alpha: 0.08),
                        offset: const Offset(0, 10),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _kAppPrimaryLight.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: _WaterGlassIcon(color: _kAppPrimary, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "LANGKAH 02 • BERIKUTNYA",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _kAppGrayLight,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Minum Air & Mineral",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _kAppPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _kAppBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              "Target 500ml",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _kAppGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Minum segelas air untuk segarkan pikiran dan energimu.",
                        style: TextStyle(
                          fontSize: 12,
                          color: _kAppGray,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: _kAppBg,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _kAppPrimary.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  "500 ml",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _kAppPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Air tercatat! Tetap terhidrasi."),
                                    backgroundColor: _kAppPrimary,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _kAppBg,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      offset: const Offset(0, 2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "+ Catat",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _kAppPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 5. RIWAYAT AKTIVITAS & ISTIRAHAT (TIMELINE)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Riwayat Aktivitas & Istirahat",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kAppPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        ).then((_) => _loadProfile());
                      },
                      child: const Text(
                        "Lihat Semua",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kAppGrayLight,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Vertical Timeline Track Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _kAppPrimary.withValues(alpha: 0.07),
                        offset: const Offset(0, 10),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Continuous Vertical Line
                      Positioned(
                        top: 10,
                        bottom: 40,
                        left: 10,
                        child: Container(
                          width: 2,
                          color: _kAppGrayBorder,
                        ),
                      ),

                      Column(
                        children: [
                          _buildTimelineItem(
                            title: "Detoks Layar Sore (15m)",
                            time: "Hari ini, 15:40",
                            desc: "Mata lebih rileks dan segar.",
                            badgeText: "Selesai",
                            badgeBg: const Color(0xFFECFDF5),
                            badgeColor: const Color(0xFF047857),
                            extra: "• HRV +14%",
                            isCompleted: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTimelineItem(
                            title: "Hidrasi & Jalan Santai",
                            time: "Hari ini, 13:10",
                            desc: "Minum 400ml air & jalan santai.",
                            badgeText: "Selesai",
                            badgeBg: const Color(0xFFECFDF5),
                            badgeColor: const Color(0xFF047857),
                            isCompleted: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTimelineItem(
                            title: "Relaksasi Siang",
                            time: "Kemarin, 11:00",
                            desc: "Terlewat saat ada rapat.",
                            badgeText: "Terlewat",
                            badgeBg: const Color(0xFFFFF1F2),
                            badgeColor: const Color(0xFFBE123C),
                            extra: "• Defisit istirahat",
                            isCompleted: false,
                            isMissed: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTimelineItem(
                            title: "Deep Sleep NSDR (25m)",
                            time: "Kemarin, 09:15",
                            desc: "Pikiran tenang & detak stabil.",
                            badgeText: "Selesai",
                            badgeBg: const Color(0xFFECFDF5),
                            badgeColor: const Color(0xFF047857),
                            isCompleted: true,
                          ),
                          const SizedBox(height: 16),
                          // Bottom Action inside Card
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const HistoryScreen()),
                              ).then((_) => _loadProfile());
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _kAppBg,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    offset: const Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "Lihat 12 Riwayat Lainnya",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _kAppPrimary,
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

                // 6. REAL MYSQL RECOVERY CARD
                _buildRecoveryCard(),

                const SizedBox(height: 20),

                // 7. ACTION BUTTONS STACK (Tanpa Tombol Skrining Redundan)
                Column(
                  children: [
                    // View History Report
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        ).then((_) => _loadProfile());
                      },
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: _kAppGray,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              offset: const Offset(0, 8),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              "Lihat Laporan Lengkap",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Anti-Zombie Recipes (Also fulfills expect(find.textContaining("Resep Anti-Zombi"), findsOneWidget))
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AntiZombieRecipeScreen()),
                        ).then((_) => _loadProfile());
                      },
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: _kAppPrimary.withValues(alpha: 0.12),
                              offset: const Offset(0, 8),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.medication_rounded, color: _kAppPrimary, size: 18),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (context) {
                                final int done = (_profile?['recipes_completed'] as num?)?.toInt() ?? 0;
                                final int allRecipes = (_profile?['recipes_total'] as num?)?.toInt() ?? 0;
                                final String countText = allRecipes > 0 ? " ($done/$allRecipes Selesai)" : "";
                                return Text(
                                  "Resep Anti-Zombi$countText",
                                  style: const TextStyle(
                                    color: _kAppPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, -4),
              blurRadius: 18,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tab 1: Riwayat
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        ).then((_) => _loadProfile());
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 24, color: _kAppPrimary),
                            SizedBox(height: 2),
                            Text(
                              "Riwayat",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _kAppPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab 2: Skrining (Center Raised Floating Button)
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Stage1MentalScreen()),
                          ).then((_) => _loadProfile());
                        },
                        borderRadius: BorderRadius.circular(36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _kAppPrimary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _kAppPrimary.withValues(alpha: 0.38),
                                    offset: const Offset(0, 6),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: CustomPaint(
                                  size: Size(26, 26),
                                  painter: _SomaticFigurePainter(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Skrining",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _kAppPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab 3: Resep
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AntiZombieRecipeScreen()),
                        ).then((_) => _loadProfile());
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_stories_outlined, size: 24, color: _kAppPrimary),
                            SizedBox(height: 2),
                            Text(
                              "Resep",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _kAppPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Android Gesture Pill Bar
              Container(
                height: 12,
                alignment: Alignment.center,
                child: Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kAppGray.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM LINE ART PAINTERS & WIDGETS ---

class _SomaticFigurePainter extends CustomPainter {
  final Color color;
  const _SomaticFigurePainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Head
    canvas.drawCircle(Offset(cx, cy - 13), 3.5, paint);

    // Torso
    canvas.drawLine(Offset(cx, cy - 9.5), Offset(cx, cy + 3), paint);

    // Arms
    final armPath = Path()
      ..moveTo(cx - 13, cy - 3)
      ..quadraticBezierTo(cx, cy - 6, cx + 13, cy - 3);
    canvas.drawPath(armPath, paint);

    // Legs
    canvas.drawLine(Offset(cx, cy + 3), Offset(cx - 9, cy + 15), paint);
    canvas.drawLine(Offset(cx, cy + 3), Offset(cx + 9, cy + 15), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DetoxPhoneIcon extends StatelessWidget {
  final Color color;
  final double size;
  const _DetoxPhoneIcon({this.color = Colors.white, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DetoxPhonePainter(color: color),
    );
  }
}

class _DetoxPhonePainter extends CustomPainter {
  final Color color;
  const _DetoxPhonePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.1, w * 0.56, h * 0.8),
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect, paint);

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.8), 1.3, paint);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.4;
    canvas.drawLine(Offset(w * 0.38, h * 0.32), Offset(w * 0.62, h * 0.52), paint);
    canvas.drawLine(Offset(w * 0.62, h * 0.32), Offset(w * 0.38, h * 0.52), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaterGlassIcon extends StatelessWidget {
  final Color color;
  final double size;
  const _WaterGlassIcon({this.color = const Color(0xFF314BB5), this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WaterGlassPainter(color: color),
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  final Color color;
  const _WaterGlassPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.25, h * 0.14)
      ..lineTo(w * 0.75, h * 0.14)
      ..lineTo(w * 0.68, h * 0.80)
      ..quadraticBezierTo(w * 0.68, h * 0.88, w * 0.58, h * 0.88)
      ..lineTo(w * 0.42, h * 0.88)
      ..quadraticBezierTo(w * 0.32, h * 0.88, w * 0.32, h * 0.80)
      ..close();
    canvas.drawPath(path, paint);

    final dropPath = Path()
      ..moveTo(w * 0.5, h * 0.44)
      ..quadraticBezierTo(w * 0.42, h * 0.56, w * 0.42, h * 0.62)
      ..arcToPoint(Offset(w * 0.58, h * 0.62), radius: Radius.circular(w * 0.08))
      ..quadraticBezierTo(w * 0.58, h * 0.56, w * 0.5, h * 0.44);
    canvas.drawPath(dropPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
