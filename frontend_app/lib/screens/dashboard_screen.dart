import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../theme/theme_controller.dart';
import 'stage1_mental_screen.dart';
import 'history_screen.dart';
import 'anti_zombie_recipe_screen.dart';

// --- PANDUAN GAYA DARI DESAIN MINIMAL ANDROID UI (HTML & SCREENSHOT) ---
const Color _kAppBg = Color(0xFFF2F1EB);
const Color _kAppPrimaryLight = Color(0xFFE8ECFA);
const Color _kAppGray = Color(0xFF5C5C5C);
const Color _kAppGrayLight = Color(0xFF8E8E93);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  DateTime _scheduledScreeningTime = DateTime(
    DateTime.now().year,
    10, // Oktober
    21,
    13, // 1 PM
    0,
  );

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
    await _loadScreeningSchedule();
    if (!mounted) return;

    setState(() {
      _profile = data;
    });
  }

  Future<void> _loadScreeningSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('next_screening_datetime');
      if (saved != null) {
        final dt = DateTime.tryParse(saved);
        if (dt != null && mounted) {
          setState(() {
            _scheduledScreeningTime = dt;
          });
        }
      }
    } catch (_) {}
  }

  String _formatHour(DateTime dt) {
    int h = dt.hour;
    if (h == 0) return "12";
    if (h > 12) return "${h - 12}";
    return "$h";
  }

  String _formatAmPm(DateTime dt) {
    return dt.hour >= 12 ? "Pm." : "Am.";
  }

  String _monthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Future<void> _pickNewScreeningSchedule() async {
    final now = DateTime.now();
    final DateTime initialDate = _scheduledScreeningTime.isAfter(now)
        ? _scheduledScreeningTime
        : now.add(const Duration(hours: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'PILIH TANGGAL SKRINING',
      confirmText: 'LANJUT',
      cancelText: 'BATAL',
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledScreeningTime),
      helpText: 'PILIH JAM SKRINING',
      confirmText: 'SIMPAN & AKTIFKAN PENGINGAT',
      cancelText: 'BATAL',
    );

    if (pickedTime == null || !mounted) return;

    final newSchedule = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _scheduledScreeningTime = newSchedule;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('next_screening_datetime', newSchedule.toIso8601String());
    } catch (_) {}

    // Panggil fungsi untuk menjadwalkan notifikasi peringatan (15 menit sebelum waktu skrining tiba)
    await notificationService.scheduleScreeningReminder(
      screeningDateTime: newSchedule,
      minutesBefore: 15,
    );

    if (!mounted) return;

    final timeStr = "${newSchedule.hour.toString().padLeft(2, '0')}:${newSchedule.minute.toString().padLeft(2, '0')}";
    final dateStr = "${newSchedule.day} ${_monthName(newSchedule.month)}";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Yuk, luangkan waktu sejenak untuk skrining! Pengingat aktif 15 menit sebelum $dateStr pukul $timeStr WIB.",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF314BB5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 4),
      ),
    );
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
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController.themeModeNotifier,
          builder: (modalCtx, currentThemeMode, _) {
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                final theme = Theme.of(ctx);
                final colorScheme = theme.colorScheme;
                final textTheme = theme.textTheme;
                final activeUrl = ApiConfig.baseUrl;
                final isDarkModal = currentThemeMode == ThemeMode.dark;

                return Container(
                  decoration: BoxDecoration(
                    color: isDarkModal ? colorScheme.surface : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDarkModal ? 0.35 : 0.15),
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
                              color: isDarkModal
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : _kAppGrayLight.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Header Modal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profil & Akun Pengguna',
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDarkModal ? Colors.white : colorScheme.primary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDarkModal ? const Color(0xFF2E2E2E) : _kAppPrimaryLight.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: isDarkModal ? Colors.white : colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 1. KARTU INFORMASI AKUN (Modern Clean)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDarkModal ? const Color(0xFF262626) : _kAppPrimaryLight.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.3),
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
                                            style: textTheme.titleMedium?.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: isDarkModal ? Colors.white : colorScheme.primary,
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
                                              color: colorScheme.primary.withValues(alpha: isDarkModal ? 0.25 : 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(Icons.edit_rounded, size: 14, color: isDarkModal ? Colors.white : colorScheme.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      user?.email ?? 'Akun Lokal / Demo',
                                      style: textTheme.bodySmall?.copyWith(
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
                                            color: isDarkModal ? const Color(0xFF1E1E1E) : colorScheme.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'ID #${(user?.userId ?? 1).toString().padLeft(3, '0')}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isDarkModal ? Colors.white : colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDarkModal ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _stageLabel(user?.zombieStage ?? ''),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isDarkModal ? const Color(0xFF34D399) : const Color(0xFF047857),
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
                              child: _buildMiniStatCard(ctx, 'Sesi Skrining', '$total Sesi', Icons.history_rounded, colorScheme.primary, isDarkModal),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMiniStatCard(ctx, 'Skor Pemulihan', '$score/100', Icons.battery_charging_full_rounded, const Color(0xFF059669), isDarkModal),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMiniStatCard(ctx, 'Goals Selesai', '$done Selesai', Icons.flag_outlined, const Color(0xFFD97706), isDarkModal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 3. PENGATURAN TAMPILAN / TEMA APLIKASI
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDarkModal ? const Color(0xFF262626) : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkModal
                                    ? Colors.black.withValues(alpha: 0.25)
                                    : colorScheme.primary.withValues(alpha: 0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
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
                                      Icon(
                                        isDarkModal ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Mode Gelap (Dark Mode)',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: isDarkModal ? Colors.white : colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Switch Mode Gelap Terhubung Langsung ke State
                                  Switch.adaptive(
                                    value: isDarkModal,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: const Color(0xFFD1D5DB),
                                    onChanged: (bool value) async {
                                      await themeController.setThemeMode(
                                        value ? ThemeMode.dark : ThemeMode.light,
                                      );
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pilih mode tampilan terang (Light Mode) atau gelap (Dark Mode).',
                                style: textTheme.bodySmall?.copyWith(
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
                                          color: !isDarkModal ? colorScheme.primary : (isDarkModal ? const Color(0xFF1E1E1E) : _kAppBg),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: !isDarkModal
                                              ? [
                                                  BoxShadow(
                                                    color: colorScheme.primary.withValues(alpha: 0.3),
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
                                              style: textTheme.bodyMedium?.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: !isDarkModal ? Colors.white : (isDarkModal ? Colors.white : colorScheme.primary),
                                              ),
                                            ),
                                            Text(
                                              'Light Mode',
                                              style: textTheme.bodySmall?.copyWith(
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
                                          color: isDarkModal ? colorScheme.primary : _kAppBg,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: isDarkModal
                                              ? [
                                                  BoxShadow(
                                                    color: colorScheme.primary.withValues(alpha: 0.35),
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
                                              style: textTheme.bodyMedium?.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: isDarkModal ? Colors.white : colorScheme.primary,
                                              ),
                                            ),
                                            Text(
                                              'Dark Mode',
                                              style: textTheme.bodySmall?.copyWith(
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
                            color: isDarkModal ? const Color(0xFF262626) : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkModal
                                    ? Colors.black.withValues(alpha: 0.25)
                                    : colorScheme.primary.withValues(alpha: 0.06),
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
                                  Icon(Icons.dns_rounded, size: 18, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Koneksi Server Backend (Base URL)',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDarkModal ? Colors.white : colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ubah alamat IP jika berpindah Wi-Fi/Hotspot tanpa perlu build ulang APK.',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: isDarkModal ? const Color(0xFFA1A1AA) : _kAppGray,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDarkModal ? const Color(0xFF1E1E1E) : _kAppBg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.link_rounded, size: 16, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        activeUrl,
                                        style: textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          color: isDarkModal ? Colors.white : colorScheme.primary,
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
                                          color: colorScheme.primary,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary.withValues(alpha: 0.28),
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
                                          color: isDarkModal ? const Color(0xFF1E1E1E) : _kAppPrimaryLight,
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary.withValues(alpha: isDarkModal ? 0.2 : 0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Uji Koneksi (Ping)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: isDarkModal ? Colors.white : colorScheme.primary,
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
      },
    );
  }

  Widget _buildMiniStatCard(BuildContext context, String label, String value, IconData icon, Color color, [bool isDark = false]) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : colorScheme.primary.withValues(alpha: 0.05),
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
            style: textTheme.titleSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFA1A1AA) : _kAppGrayLight,
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
    final isDark = themeController.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: Text(
            'Edit Nama Lengkap',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: isDark ? Colors.white : colorScheme.primary,
            ),
          ),
          content: TextField(
            controller: textController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Nama lengkap Anda',
              hintStyle: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : _kAppGrayLight),
              filled: true,
              fillColor: isDark ? const Color(0xFF121212) : _kAppBg,
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
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : _kAppGray, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
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
    final isDark = themeController.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: Text(
            'Ubah Base URL API',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: isDark ? Colors.white : colorScheme.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan URL Backend Go (misal http://192.168.x.x:8081):',
                style: textTheme.bodySmall?.copyWith(fontSize: 12, color: isDark ? const Color(0xFFA1A1AA) : _kAppGray),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'http://192.168.18.12:8081',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : _kAppGrayLight),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF121212) : _kAppBg,
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
                    borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: Text(
                      'Localhost (8081)',
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white : colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : _kAppPrimaryLight,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () => textController.text = 'http://localhost:8081',
                  ),
                  ActionChip(
                    label: Text(
                      'Wi-Fi Laptop (192.168.18.12)',
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white : colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : _kAppPrimaryLight,
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
              child: Text(
                'Batal',
                style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : _kAppGray, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
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
                      backgroundColor: colorScheme.primary,
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        final bool isDark = themeMode == ThemeMode.dark;
        final Color scaffoldBg = theme.scaffoldBackgroundColor;

        final String userName = authService.currentUser?.displayName?.isNotEmpty == true
            ? authService.currentUser!.displayName!
            : "User Lorem Ipsum";

        final user = authService.currentUser;
        final String userSub = user != null
            ? "ID #${user.userId.toString().padLeft(3, '0')}"
            : "ID Lorem Ipsum";

        final int recoveryScore = (user?.recoveryScore ?? 65).clamp(0, 100);

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadProfile,
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. TOP HEADER BAR: Profile Avatar + User Info (Clickable) + Notification Bell (Outline)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Info (Clickable -> Opens Modal)
                        InkWell(
                          onTap: () => _showProfileModal(context),
                          borderRadius: BorderRadius.circular(24),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.28),
                                      offset: const Offset(0, 4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white,
                                    size: 24,
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
                                    style: textTheme.titleMedium?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : colorScheme.primary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userSub,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFFA1A1AA)
                                          : colorScheme.primary.withValues(alpha: 0.70),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Notification Bell (Outline - Clickable -> SnackBar as tested in test 5)
                        IconButton(
                          icon: Icon(
                            Icons.notifications_active_outlined,
                            color: isDark ? Colors.white : colorScheme.primary,
                            size: 26,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "Pengingat skrining aktif setiap jam 19.00 WIB",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFF1E293B),
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

                    const SizedBox(height: 20),

                    // 2. CARD UTAMA: SKRINING SELANJUTNYA (Modern Clean Layered Contour)
                    SizedBox(
                      height: 330,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Layer 1: Background offset contour frame (Deep Blue Modern Clean)
                          Positioned(
                            top: 8,
                            left: 8,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(38),
                                border: Border.all(color: colorScheme.primary, width: 2.2),
                              ),
                            ),
                          ),

                          // Layer 2: Main deep blue card
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(38),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.28),
                                    offset: const Offset(0, 12),
                                    blurRadius: 26,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Top: White Dot + "Skrining Selanjutnya"
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
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          "Skrining Selanjutnya",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _pickNewScreeningSchedule,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.22),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit_calendar_outlined, color: Colors.white, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                "Atur",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Center: Giant Time "1 Pm." and Date
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            _formatHour(_scheduledScreeningTime),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 72,
                                              fontWeight: FontWeight.w900,
                                              height: 0.95,
                                              letterSpacing: -2.0,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatAmPm(_scheduledScreeningTime),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 34,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "${_scheduledScreeningTime.day}, ${_monthName(_scheduledScreeningTime.month)}",
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.92),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Bottom: Progress Bar inside card only
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Progress Goals Pemulihan",
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 8,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: (recoveryScore / 100).clamp(0.20, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // 3. BAGIAN DESTRESS ("EMO-SENSE AI", "Destress", "Maintain your emotions")
                    Center(
                      child: Text(
                        "EMO-SENSE AI",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: isDark ? const Color(0xFFA1A1AA) : colorScheme.primary.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        "Destress",
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : colorScheme.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        "Maintain your emotions",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFE4E4E7) : colorScheme.primary.withValues(alpha: 0.75),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 4. PROTOKOL ISTIRAHAT HEADER
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Protokol Istirahat",
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : colorScheme.primary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                    offset: const Offset(0, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                "2 Langkah",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : colorScheme.primary,
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
                            color: isDark ? const Color(0xFFE4E4E7) : colorScheme.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 5. CARD PROTOKOL ISTIRAHAT: DETOKS LAYAR
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.28),
                            offset: const Offset(0, 10),
                            blurRadius: 24,
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
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      offset: const Offset(0, 2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "15 Menit",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Letakkan perangkat atau aktifkan mode monokrom.\nIstirahatkan korteks visual dari stimulasi cahaya biru berlebih.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.only(top: 10),
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
                                    padding: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Catatan perasaan (opsional)...",
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
                                      SnackBar(
                                        content: const Text("Detoks layar selesai! Hebat."),
                                        backgroundColor: colorScheme.primary,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.10),
                                          offset: const Offset(0, 2),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "Selesaikan",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : colorScheme.primary,
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

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 72,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Left & Right Navigation Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tab 1: Riwayat
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const HistoryScreen()),
                              ).then((_) => _loadProfile());
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.menu_book_outlined, size: 24, color: isDark ? Colors.white : colorScheme.primary),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Riwayat",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Tab 2: Goals
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AntiZombieRecipeScreen()),
                              ).then((_) => _loadProfile());
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flag_outlined, size: 24, color: isDark ? Colors.white : colorScheme.primary),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Goals",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center: Floating Button Melayang
                    Positioned(
                      top: -24,
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
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.35),
                                    offset: const Offset(0, 6),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: CustomPaint(
                                  size: Size(30, 30),
                                  painter: _SomaticFigurePainter(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Skrining",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
