import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'stage1_mental_screen.dart';
import 'history_screen.dart';

/// Halaman Beranda (Home Screen) Interaktif dengan Fitur Ganti Tema (Dark / Light)
/// Menggunakan transisi lukisan SVG satu layar penuh secara mulus.
class HomeScreen extends StatefulWidget {
  final bool initialDarkMode;

  const HomeScreen({
    super.key,
    this.initialDarkMode = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const String _prefThemeKey = 'app_theme_is_dark';

  // State Tema: true = Dark Mode (lukisan_malam), false = Light Mode (lukisan_siang)
  late bool _isDarkMode;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;

    // Animasi denyut halus untuk tombol interaktif / visual hint
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadThemePreference();
    notificationService.init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Memuat preferensi tema terakhir dari SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDark = prefs.getBool(_prefThemeKey);
      if (savedDark != null && mounted) {
        setState(() {
          _isDarkMode = savedDark;
        });
      }
    } catch (e) {
      debugPrint('Catatan SharedPreferences tema: $e');
    }
  }

  /// Menyimpan preferensi tema ke SharedPreferences
  Future<void> _saveThemePreference(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefThemeKey, isDark);
    } catch (e) {
      debugPrint('Gagal menyimpan tema: $e');
    }
  }

  /// Mengubah tema (Dark <-> Light) ketika user mengetuk gambar lukisan
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveThemePreference(_isDarkMode);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              color: _isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFFF59E0B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _isDarkMode ? "Beralih ke Tema Gelap (Malam)" : "Beralih ke Tema Terang (Siang)",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1100),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF334155),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Menampilkan modal notifikasi sistem
  Future<void> _showNotificationsModal(BuildContext context) async {
    final list = await notificationService.getNotificationHistory();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Header Modal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              color: _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFD97706),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Notifikasi Sistem",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        if (list.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await notificationService.clearNotificationHistory();
                              setModalState(() {
                                list.clear();
                              });
                            },
                            child: const Text(
                              "Hapus Semua",
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),

                  // List Notifikasi
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 48,
                                    color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    "Belum ada notifikasi baru",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Peringatan gejala burnout dan pengingat tes akan tercatat di sini.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final item = list[index];
                              final isWarning = item['type'] == 'warning';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? (isWarning ? const Color(0xFF3B1219) : const Color(0xFF1E293B))
                                      : (isWarning ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isWarning
                                        ? const Color(0xFFDC2626)
                                        : (_isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isWarning ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                                      color: isWarning
                                          ? const Color(0xFFEF4444)
                                          : (_isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFD97706)),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'] ?? 'Notifikasi',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['body'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _isDarkMode
                                                  ? const Color(0xFFCBD5E1)
                                                  : const Color(0xFF475569),
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
  }

  /// Menampilkan dialog konfirmasi Logout
  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Konfirmasi Keluar",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          "Apakah Anda yakin ingin keluar dari akun ini?",
          style: TextStyle(
            color: _isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Batal",
              style: TextStyle(
                color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await authService.signOut(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final String displayName = user?.displayName ?? "Maulana";
    final int userId = user?.userId ?? 1042;
    final String initialLetter = (displayName.isNotEmpty ? displayName[0] : "U").toUpperCase();

    // Palet warna adaptif sesuai tema
    // TEMA GELAP: Midnight Navy (#0B1120 / #0F172A)
    // TEMA TERANG: Warm Golden Ivory (#FFFBEB / #FDFBF7 / #FEF9C3)
    final Color scaffoldBg = _isDarkMode ? const Color(0xFF0B1120) : const Color(0xFFFFFBEB);
    final Color cardBorderColor = _isDarkMode ? const Color(0xFF334155) : const Color(0xFFFDE68A);
    final Color primaryTextColor = _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color secondaryTextColor = _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF92400E);
    final Color headerBadgeBg = _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7);
    final Color headerBadgeBorder = _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF59E0B);
    final Color headerBadgeText = _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFB45309);

    // Tombol Skrining: Biru Tua saat Gelap, Kuning Emas saat Terang
    final Color screeningButtonBg = _isDarkMode ? const Color(0xFF3046B4) : const Color(0xFFFFC436);
    final Color screeningButtonText = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color screeningButtonBorder = _isDarkMode ? const Color(0xFF4338CA) : const Color(0xFF000000);

    // Tombol Riwayat: Konsisten Abu-abu Gelap / Dark Grey
    const Color historyButtonBg = Color(0xFF334155);
    const Color historyButtonText = Colors.white;

    // SVG Asset yang aktif
    final String activeSvgAsset = _isDarkMode ? 'assets/lukisan_malam.svg' : 'assets/lukisan_siang.svg';

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        color: scaffoldBg,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32.0,
                    maxWidth: 480,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ==========================================
                        // 1. HEADER ATAS
                        // Teks "Beranda Utama", Avatar, Nama, ID & Lonceng
                        // ==========================================
                        _buildHeader(
                          displayName: displayName,
                          userId: userId,
                          initialLetter: initialLetter,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          headerBadgeBg: headerBadgeBg,
                          headerBadgeBorder: headerBadgeBorder,
                          headerBadgeText: headerBadgeText,
                        ),

                        const SizedBox(height: 20),

                        // Indikator Interaktif: Tooltip / Badge info tema
                        _buildThemeHintBadge(),

                        const SizedBox(height: 12),

                        // ==========================================
                        // 2. BAGIAN TENGAH: WIDGET SVGPICTURE INTERAKTIF
                        // Dibungkus GestureDetector untuk beralih Tema
                        // ==========================================
                        _buildInteractiveSvgPainting(
                          svgAsset: activeSvgAsset,
                          borderColor: cardBorderColor,
                        ),

                        const SizedBox(height: 24),

                        // ==========================================
                        // 3. BAGIAN BAWAH GAMBAR
                        // Judul: "Nama Aplikasi" & "Maintain your emotions"
                        // Tombol 1: "Skrining"
                        // Tombol 2: "Riwayat"
                        // ==========================================
                        _buildAppTitleAndSubtext(
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                        ),

                        const SizedBox(height: 20),

                        // Tombol Utama 1: "Skrining"
                        _buildScreeningButton(
                          backgroundColor: screeningButtonBg,
                          textColor: screeningButtonText,
                          borderColor: screeningButtonBorder,
                        ),

                        const SizedBox(height: 12),

                        // Tombol Utama 2: "Riwayat" (Abu-abu Gelap Konsisten)
                        _buildHistoryButton(
                          backgroundColor: historyButtonBg,
                          textColor: historyButtonText,
                        ),

                        const Spacer(),

                        const SizedBox(height: 16),

                        // ==========================================
                        // 4. POJOK KANAN BAWAH: IKON TOMBOL LOGOUT KECIL
                        // ==========================================
                        _buildBottomRowWithLogout(
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Komponen Header Atas
  Widget _buildHeader({
    required String displayName,
    required int userId,
    required String initialLetter,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color headerBadgeBg,
    required Color headerBadgeBorder,
    required Color headerBadgeText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sisi Kiri: Avatar & Info Pengguna
        Expanded(
          child: Row(
            children: [
              // Avatar Profil
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isDarkMode ? Colors.black : const Color(0xFFD97706)).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initialLetter,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info: Beranda Utama, Nama & ID Pengguna
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge / Label "Beranda Utama"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: headerBadgeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: headerBadgeBorder, width: 1),
                      ),
                      child: Text(
                        "Beranda Utama",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: headerBadgeText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: primaryTextColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      "ID: #$userId",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Sisi Kanan Atas: Ikon Lonceng Notifikasi
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: "Notifikasi Sistem",
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.notifications_active_outlined,
                  color: _isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFFD97706),
                  size: 22,
                ),
                onPressed: () => _showNotificationsModal(context),
              ),
              // Unread dot indicator
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Badge petunjuk interaktif untuk memberi tahu user bahwa gambar bisa ditekan
  Widget _buildThemeHintBadge() {
    return Center(
      child: GestureDetector(
        onTap: _toggleTheme,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1E293B).withValues(alpha: 0.9) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDarkMode ? const Color(0xFF38BDF8).withValues(alpha: 0.6) : const Color(0xFFF59E0B),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isDarkMode ? Icons.touch_app_rounded : Icons.light_mode_rounded,
                size: 15,
                color: _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFB45309),
              ),
              const SizedBox(width: 6),
              Text(
                _isDarkMode ? "Ketuk lukisan untuk Mode Siang ☀️" : "Ketuk lukisan untuk Mode Malam 🌙",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF78350F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget SvgPicture Interaktif di Tengah Layar
  Widget _buildInteractiveSvgPainting({
    required String svgAsset,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: _toggleTheme,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 550),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<String>(svgAsset),
            width: double.infinity,
            height: 270,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _isDarkMode
                      ? Colors.black.withValues(alpha: 0.55)
                      : const Color(0xFFD97706).withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar SVG
                  SvgPicture.asset(
                    svgAsset,
                    fit: BoxFit.cover,
                    placeholderBuilder: (context) => Container(
                      color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                  // Overlay efek gradient halus di bagian bawah gambar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            (_isDarkMode ? Colors.black87 : Colors.black45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Badge status tema di pojok kiri bawah lukisan
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Row(
                      children: [
                        Icon(
                          _isDarkMode ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                          color: _isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFFFFC436),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isDarkMode ? "Lukisan Malam (Dark)" : "Lukisan Siang (Light)",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1)),
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
        ),
      ),
    );
  }

  /// Judul Aplikasi & Subteks
  Widget _buildAppTitleAndSubtext({
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      children: [
        // Judul Aplikasi: "Nama Aplikasi" (Somatic.AI)
        Text(
          "Nama Aplikasi",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),

        // Subteks: "Maintain your emotions"
        Text(
          "Maintain your emotions",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: secondaryTextColor,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  /// Tombol Utama 1: "Skrining"
  Widget _buildScreeningButton({
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: _isDarkMode ? 6 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: borderColor, width: 2),
          ),
          shadowColor: _isDarkMode
              ? const Color(0xFF3046B4).withValues(alpha: 0.5)
              : const Color(0xFFD97706).withValues(alpha: 0.35),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Stage1MentalScreen()),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled_rounded,
              size: 26,
              color: textColor,
            ),
            const SizedBox(width: 10),
            Text(
              "Skrining",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tombol Utama 2: "Riwayat" (Abu-abu Gelap Konsisten)
  Widget _buildHistoryButton({
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFF1E293B), width: 1.8),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryScreen()),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 24,
              color: textColor,
            ),
            const SizedBox(width: 10),
            Text(
              "Riwayat",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Baris Bawah dengan Ikon Logout Kecil di Pojok Kanan Bawah
  Widget _buildBottomRowWithLogout({
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sisi Kiri: Status Versi / Footer Ringkas
        Text(
          "v1.0 • Multimodal AI Triage",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: secondaryTextColor.withValues(alpha: 0.8),
          ),
        ),

        // Sisi Kanan: Ikon Tombol Logout/Keluar Kecil
        Tooltip(
          message: "Keluar dari Akun",
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFFCA5A5),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
