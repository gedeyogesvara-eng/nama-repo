// ignore_for_file: unused_element
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'services/api_config.dart';
import 'theme/theme_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/loading_scan_screen.dart';
import 'screens/stage1_mental_screen.dart';
import 'screens/stage2_physical_screen.dart';
import 'screens/stage3_visual_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'screens/anti_zombie_recipe_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi konfigurasi API & SharedPreferences
  await ApiConfig.init();

  // Inisialisasi Tema Aplikasi (Light / Dark Mode)
  await themeController.init();

  // Autentikasi memakai Backend Go + MySQL (tanpa Firebase).
  // Pulihkan sesi login terakhir (user_id & full_name) jika ada.
  try {
    await authService.restoreSession();
  } catch (e) {
    debugPrint("Gagal memulihkan sesi login: $e");
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const DepressionDetectionApp());
}

// ==========================================
// PALET WARNA (100% IDENTIK DENGAN GOOGLE STITCH)
// ==========================================
class AppColors {
  // Base Palette
  static const Color appBg = Color(0xFFF1F0EA);
  static const Color desktopBg = Color(0xFFE5E4DE);
  static const Color primaryBlue = Color(0xFF3046B4);
  static const Color primaryYellow = Color(0xFFFFC436);
  static const Color secondaryGray = Color(0xFF5C5C5C);
  static const Color borderBlack = Color(0xFF000000);

  // Status & Cabang Hasil
  static const Color green = Color(0xFF10B981);
  static const Color greenDark = Color(0xFF059669);
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color greenText = Color(0xFF065F46);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberBg = Color(0xFFFFFBEB);
  static const Color amberText = Color(0xFF92400E);

  static const Color red = Color(0xFFEF4444);
  static const Color redDark = Color(0xFFDC2626);
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color redText = Color(0xFFB91C1C);
}

// ==========================================
// ROOT APLIKASI
// ==========================================
class DepressionDetectionApp extends StatelessWidget {
  const DepressionDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          navigatorKey: authService.navigatorKey,
          title: 'RESTGUARD - Mental Health & Fatigue Detection',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF2F1EB),
            fontFamily: 'sans-serif',
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF314BB5),
              onPrimary: Colors.white,
              secondary: Color(0xFFFFC436),
              onSecondary: Colors.black,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
              error: Color(0xFFEF4444),
              onError: Colors.white,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
              displayMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
              displaySmall: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
              headlineLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
              headlineMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
              headlineSmall: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
              titleMedium: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
              titleSmall: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(color: Color(0xFF1E293B)),
              bodyMedium: TextStyle(color: Color(0xFF334155)),
              bodySmall: TextStyle(color: Color(0xFF64748B)),
              labelLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
              labelMedium: TextStyle(color: Color(0xFF334155)),
              labelSmall: TextStyle(color: Color(0xFF64748B)),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
              modalBackgroundColor: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            fontFamily: 'sans-serif',
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF314BB5), // Deep Blue utama dipertahankan
              onPrimary: Colors.white,
              secondary: Color(0xFFFFC436),
              onSecondary: Colors.black,
              surface: Color(0xFF1E1E1E), // Latar kartu/wadah gelap
              onSurface: Colors.white, // Teks putih untuk kontras tinggi
              error: Color(0xFFEF4444),
              onError: Colors.white,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              titleSmall: TextStyle(color: Color(0xFFE4E4E7), fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Color(0xFFE4E4E7)),
              bodySmall: TextStyle(color: Color(0xFFA1A1AA)),
              labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              labelMedium: TextStyle(color: Color(0xFFE4E4E7)),
              labelSmall: TextStyle(color: Color(0xFFA1A1AA)),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              modalBackgroundColor: Color(0xFF1E1E1E),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E1E1E),
            ),
          ),
          home: authService.currentUser != null
              ? const DashboardScreen()
              : const WelcomeScreen(),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/auth': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot_password': (context) => const ForgotPasswordScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/home': (context) => const DashboardScreen(),
            '/recipes': (context) => const AntiZombieRecipeScreen(),
            '/stage1': (context) => const Stage1MentalScreen(),
            '/stage2': (context) => const Stage2PhysicalScreen(),
            '/stage3': (context) => const Stage3VisualScreen(),
            '/loading_scan': (context) => const LoadingScanScreen(),
            '/result': (context) => const ResultScreen(),
            '/history': (context) => const HistoryScreen(),
            '/prototype': (context) => const PrototypeRootScreen(),
          },
        );
      },
    );
  }
}

// ==========================================
// PROTOTYPE ROOT CONTROLLER
// (Mengatur Alur 10 Screen, State, & Frame HP)
// ==========================================
class PrototypeRootScreen extends StatefulWidget {
  const PrototypeRootScreen({super.key});

  @override
  State<PrototypeRootScreen> createState() => _PrototypeRootScreenState();
}

class _PrototypeRootScreenState extends State<PrototypeRootScreen> {
  String _currentScreen = 'history';

  // State untuk Filter Layar Riwayat
  String _historyFilter = 'all';

  // State untuk Stage 2: Gait Tracker
  Timer? _walkingTimer;
  int _walkingSeconds = 0;

  // State untuk Stage 3: Visual Scan
  bool _captureSuccess = false;

  // State untuk Stage 9: Resep Anti-Zombi Checklist
  final Map<String, bool> _checkedInterventions = {
    'stretch': false,
    'coffee': false,
    'rest': false,
  };

  // State untuk Stage 1: Coretan Mental (Freehand drawing)
  final List<Offset?> _drawingPoints = [];

  final List<Map<String, String>> _screensList = const [
    {'id': 'welcome', 'name': '0. Welcome (RESTGUARD)'},
    {'id': 'login', 'name': '0a. Login Screen'},
    {'id': 'register', 'name': '0b. Register Screen'},
    {'id': 'forgot_password', 'name': '0c. Reset Password'},
    {'id': 'splash', 'name': '1. Splash / Auth'},
    {'id': 'permissions', 'name': '2. Izin Sensor'},
    {'id': 'dashboard', 'name': '3. Dashboard'},
    {'id': 'stage1', 'name': '4. Stage 1: Skrining'},
    {'id': 'stage2', 'name': '5. Stage 2: Gait'},
    {'id': 'stage3', 'name': '6. Stage 3: Scan Mata'},
    {'id': 'loading', 'name': '7. Loading AI'},
    {'id': 'result_healthy', 'name': '8. Hasil: Prima'},
    {'id': 'result_moderate', 'name': '9. Hasil: Burnout'},
    {'id': 'result_extreme', 'name': '10. Hasil: Ekstrem'},
    {'id': 'history', 'name': '11. Riwayat Skrining'},
    {'id': 'loading_scan', 'name': '12. AI Scan & Resep'},
  ];

  void _setScreen(String screenName) {
    setState(() {
      _currentScreen = screenName;
      if (screenName == 'stage2') {
        _walkingTimer?.cancel();
        _walkingSeconds = 0;
      }
      if (screenName == 'stage3') {
        _captureSuccess = false;
      }
    });
  }

  void _startWalkingSimulation() {
    _walkingTimer?.cancel();
    setState(() {
      _walkingSeconds = 0;
    });

    _walkingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_walkingSeconds < 10) {
        setState(() {
          _walkingSeconds++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _simulateAutoCapture() {
    setState(() {
      _captureSuccess = true;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _setScreen('loading_scan');
      }
    });
  }

  @override
  void dispose() {
    _walkingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: isDesktop ? AppColors.desktopBg : AppColors.appBg,
          body: Stack(
            children: [
              // Frame Mobile Phone (max-w-md, mx-auto, h-full)
              Center(
                child: Container(
                  width: isDesktop ? 420 : double.infinity,
                  height: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 440),
                  decoration: BoxDecoration(
                    color: AppColors.appBg,
                    boxShadow: isDesktop
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: SafeArea(
                    child: _buildCurrentScreenView(),
                  ),
                ),
              ),

              // Floating Debug Navigation Menu (Khusus Desktop side panel)
              if (isDesktop)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildDesktopDebugMenu(),
                ),

              // Tombol Floating Switcher Layar untuk Mobile
              if (!isDesktop)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'mobile_quick_nav',
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    tooltip: 'Quick Navigation (10 Screens)',
                    onPressed: _showMobileDebugModal,
                    child: const Icon(Icons.grid_view_rounded, size: 20),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Debug Panel Navigasi Desktop
  Widget _buildDesktopDebugMenu() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'QUICK NAVIGATION (10 SCREENS)',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _screensList.map((screen) {
              final isSelected = _currentScreen == screen['id'];
              return InkWell(
                onTap: () => _setScreen(screen['id']!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 122,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    screen['name']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Modal Sheet Navigasi Cepat untuk Mobile
  void _showMobileDebugModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Layar Prototipe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _screensList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _screensList[index];
                      final isSelected = _currentScreen == item['id'];
                      return ListTile(
                        dense: true,
                        title: Text(
                          item['name']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                color: AppColors.primaryBlue, size: 18)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _setScreen(item['id']!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Switch Screen Controller
  Widget _buildCurrentScreenView() {
    switch (_currentScreen) {
      case 'welcome':
        return const WelcomeScreen();
      case 'login':
        return const LoginScreen();
      case 'register':
        return const RegisterScreen();
      case 'forgot_password':
        return const ForgotPasswordScreen();
      case 'splash':
        return _buildSplashAuthScreen();
      case 'permissions':
        return _buildPermissionsScreen();
      case 'dashboard':
        return const DashboardScreen();
      case 'stage1':
        return const Stage1MentalScreen();
      case 'stage2':
        return const Stage2PhysicalScreen();
      case 'stage3':
        return const Stage3VisualScreen();
      case 'loading':
        return _buildLoadingScreen();
      case 'result_healthy':
        return _buildResultHealthyScreen();
      case 'result_moderate':
        return _buildResultModerateScreen();
      case 'result_extreme':
        return _buildResultExtremeScreen();
      case 'history':
        return _buildHistoryScreen();
      case 'loading_scan':
        return const LoadingScanScreen();
      default:
        return const DashboardScreen();
    }
  }

  // ==========================================
  // SHARED HEADER COMPONENT
  // ==========================================
  Widget _buildHeader({String? titleText, String? subtitleText}) {
    if (titleText != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                        height: 1.1,
                      ),
                    ),
                    if (subtitleText != null)
                      Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 24),
              color: AppColors.primaryBlue,
              tooltip: 'Ke Dashboard',
              onPressed: () => _setScreen('dashboard'),
            ),
          ],
        ),
      );
    }

    // Default Header untuk Dashboard
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Lorem Ipsum',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    'ID Lorem Ipsum',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 24),
            color: AppColors.primaryBlue,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NEO-BRUTALIST PILL BUTTON HELPER
  // ==========================================
  Widget _buildNeoPillButton({
    required String text,
    required VoidCallback? onPressed,
    Color backgroundColor = AppColors.primaryBlue,
    Color textColor = Colors.white,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : 260,
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey.shade400 : backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderBlack,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: textColor, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. SCREEN: SPLASH / AUTH
  // ==========================================
  Widget _buildSplashAuthScreen() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Brand Header
          Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.borderBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderBlack,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nama Aplikasi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Multimodal AI Depression & Burnout Detection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),

          // Form Login (Bottom-bordered fields)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EMAIL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.primaryBlue,
                  ),
                ),
                TextFormField(
                  initialValue: 'user.lorem@gmail.com',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: AppColors.primaryYellow, width: 2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'PASSWORD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.primaryBlue,
                  ),
                ),
                TextFormField(
                  initialValue: '••••••••',
                  obscureText: true,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: AppColors.primaryYellow, width: 2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: true,
                            activeColor: AppColors.primaryBlue,
                            onChanged: (val) {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ingat saya',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Lupa kata sandi?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tombol CTA
          Column(
            children: [
              _buildNeoPillButton(
                text: 'Masuk / Register',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => _setScreen('permissions'),
              ),
              const SizedBox(height: 10),
              Text(
                'Versi Prototipe Interaktif 1.0',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryBlue.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. SCREEN: IZIN SENSOR
  // ==========================================
  Widget _buildPermissionsScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              titleText: 'Izin Sensor Dibutuhkan',
              subtitleText: 'Multimodal Behavioral Skrining',
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: Text(
                'Untuk mendeteksi biomarker depresi dan fatigue secara akurat, sistem AI membutuhkan akses sensor temporal perangkat Anda:',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.primaryBlue.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildSensorCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'Kamera Depan',
                    desc:
                        'Analisis kedipan sklera mata, mikropupil & mikroekspresi wajah.',
                  ),
                  const SizedBox(height: 14),
                  _buildSensorCard(
                    icon: Icons.mic_none_rounded,
                    title: 'Mikrofon Audio',
                    desc:
                        'Pola intonasi bicara, jeda prosodi, dan resonansi vokal.',
                  ),
                  const SizedBox(height: 14),
                  _buildSensorCard(
                    icon: Icons.directions_walk_rounded,
                    title: 'Akselerometer & Gait Sensor',
                    desc:
                        'Metrik gaya berjalan, kelambanan langkah & tremor motorik halus.',
                  ),
                ],
              ),
            ),
          ],
        ),

        // Bottom Button
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildNeoPillButton(
                text: 'Izinkan Semua',
                icon: Icons.check_rounded,
                onPressed: () => _setScreen('dashboard'),
              ),
              const SizedBox(height: 10),
              Text(
                'Data sensor diproses secara on-device terenkripsi',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primaryBlue.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: AppColors.secondaryGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. SCREEN: DASHBOARD
  // ==========================================
  Widget _buildDashboardScreen() {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),

                // THE SIGNATURE OFFSET CANVAS (BOXDECORATION NEO-BRUTALISM)
                Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.borderBlack,
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.borderBlack,
                        offset: Offset(8, 8),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Daily Mood + Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'DAILY MOOD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryYellow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Center Illustration (Moon + Sparkle Stars)
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.nightlight_round,
                              size: 54,
                              color: AppColors.primaryYellow,
                            ),
                            Positioned(
                              top: 14,
                              right: 20,
                              child: Text(
                                '✦',
                                style: TextStyle(
                                  color: AppColors.primaryYellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 20,
                              child: Text(
                                '★',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Text Inside Canvas
                      const Text(
                        'Siklus Emosi: Tenang & Terjaga',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Text(
                  'Nama Aplikasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Maintain your emotions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),

            // Bottom Stacked Pill Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                children: [
                  _buildNeoPillButton(
                    text: 'Skrining',
                    icon: Icons.chevron_right_rounded,
                    onPressed: () => _setScreen('stage1'),
                  ),
                  const SizedBox(height: 12),
                  _buildNeoPillButton(
                    text: 'Riwayat',
                    backgroundColor: AppColors.secondaryGray,
                    onPressed: () => _setScreen('history'),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Bottom Logout Button
        Positioned(
          bottom: 16,
          right: 20,
          child: IconButton(
            tooltip: 'Keluar',
            icon:
                const Icon(Icons.logout_rounded, color: AppColors.primaryBlue),
            onPressed: () => _setScreen('splash'),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. SCREEN: STAGE 1 (DRAW & TALK)
  // ==========================================
  Widget _buildStage1Screen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              titleText: '1st stage',
              subtitleText: 'Draw & Talk',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.0),
              child: Text(
                'Draw',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Middle: EXACT OFFSET CANVAS DENGAN DRAWING INTERAKTIF
            Center(
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.borderBlack, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderBlack,
                      offset: Offset(8, 8),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top-left Pen & Eraser
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _drawingPoints.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),

                    // Area Menggambar Bebas
                    Expanded(
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _drawingPoints.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _drawingPoints.add(null);
                          });
                        },
                        child: CustomPaint(
                          painter: FreehandPainter(points: _drawingPoints),
                          child: Container(
                            color: Colors.transparent,
                            child: _drawingPoints.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.gesture_rounded,
                                          size: 48,
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Ekspresikan coretan bebas di sini',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Canvas Tag
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        'Biomarker: Pressure & Speed',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Talk Section
            Center(
              child: Column(
                children: [
                  const Text(
                    'Talk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.borderBlack, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.borderBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mic_none_rounded,
                        size: 32,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tekan & ceritakan harimu (30s)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryBlue.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Selesai Corat-coret Button
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Center(
            child: _buildNeoPillButton(
              text: 'Selesai Corat-coret',
              icon: Icons.chevron_right_rounded,
              onPressed: () => _setScreen('stage2'),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. SCREEN: STAGE 2 (GAIT TRACKER)
  // ==========================================
  Widget _buildStage2Screen() {
    final isComplete = _walkingSeconds >= 10;
    final isRunning =
        _walkingTimer != null && _walkingTimer!.isActive && !isComplete;
    final progress = (_walkingSeconds / 10).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            _buildHeader(
              titleText: 'Tahap 2',
              subtitleText: 'Gait Tracker',
            ),
            const Text(
              'Tahap 2: Gait Tracker',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Taruh HP di saku dan berjalanlah selama 10 detik',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // Lingkaran Progress Berjalan
            SizedBox(
              width: 210,
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: const Color(0xFFE0DED6),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? AppColors.green : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isComplete) ...[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.green,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '10s Lengkap!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green,
                          ),
                        ),
                        const Text(
                          'Gait pattern tercatat',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.secondaryGray,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '${_walkingSeconds}s',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const Text(
                          'dari 10 detik',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryGray,
                          ),
                        ),
                        if (isRunning) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Mendeteksi langkah...',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Info Sensor Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderBlack, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderBlack,
                      offset: Offset(2.5, 2.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Text(
                  'Sensor IMU membaca variasi ritme langkah dan kestabilan postural kaki.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Action Button
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: isComplete
              ? _buildNeoPillButton(
                  text: 'Lanjut Scan Mata',
                  icon: Icons.chevron_right_rounded,
                  backgroundColor: AppColors.green,
                  onPressed: () => _setScreen('stage3'),
                )
              : _buildNeoPillButton(
                  text: isRunning
                      ? 'Sedang Berjalan...'
                      : 'Mulai Berjalan (10 Detik)',
                  icon: Icons.play_arrow_rounded,
                  onPressed: isRunning ? null : _startWalkingSimulation,
                ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. SCREEN: STAGE 3 (VISUAL & EYE SCAN)
  // ==========================================
  Widget _buildStage3Screen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            _buildHeader(
              titleText: 'Tahap 3',
              subtitleText: 'Visual & Sclera Scan',
            ),
            const Text(
              'Pindai Visual & Mata',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Arahkan kamera ke wajah dan tatap titik tengah',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryGray,
              ),
            ),
            const SizedBox(height: 14),

            // Viewfinder Simulasi Kamera Depan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827), // gray-900
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.borderBlack, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderBlack,
                      offset: Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid Viewfinder Overlay (3x3)
                    Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: Container()),
                      ],
                    ),

                    // Top Status Indicator
                    Positioned(
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _captureSuccess
                                    ? AppColors.green
                                    : AppColors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _captureSuccess
                                  ? 'Biomarker Terkunci'
                                  : 'Live Eye-Tracking',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Center Dashed Oval Shape
                    CustomPaint(
                      painter: DashedOvalPainter(
                        color:
                            _captureSuccess ? AppColors.green : AppColors.red,
                        isSuccess: _captureSuccess,
                      ),
                      child: Container(
                        width: 190,
                        height: 250,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Crosshair
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 2,
                                    height: 24,
                                    color: _captureSuccess
                                        ? AppColors.green
                                        : AppColors.red,
                                  ),
                                  Container(
                                    width: 24,
                                    height: 2,
                                    color: _captureSuccess
                                        ? AppColors.green
                                        : AppColors.red,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _captureSuccess
                                    ? '✓ Wajah Terdeteksi Pas'
                                    : 'Posisikan Wajah',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ],
        ),

        // Bottom Action Button
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            children: [
              _buildNeoPillButton(
                text: 'Simulate Auto-Capture',
                icon: Icons.camera_alt_rounded,
                onPressed: _simulateAutoCapture,
              ),
              const SizedBox(height: 8),
              const Text(
                'Oval berubah hijau lalu lanjut ke loading',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.secondaryGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 7. SCREEN: LOADING AI
  // ==========================================
  Widget _buildLoadingScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 16),

          // Center Animated Wave / Spinner
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderBlack, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderBlack,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryYellow,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bouncing dots simulator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryYellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Agentic AI sedang memproses...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: const Text(
                  'Mengintegrasikan coretan mental, gait sensor, prosodi suara, dan biomarker sklera mata...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.secondaryGray,
                  ),
                ),
              ),
            ],
          ),

          // Pilihan Simulasi Cabang Hasil Prototype
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderBlack, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.borderBlack,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'PILIH CABANG HASIL (SIMULASI PROTOTYPE):',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildBranchButton(
                        text: 'Simulate Sehat',
                        color: AppColors.green,
                        onTap: () => _setScreen('result_healthy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBranchButton(
                        text: 'Simulate Sedang',
                        color: AppColors.amber,
                        onTap: () => _setScreen('result_moderate'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBranchButton(
                        text: 'Simulate Ekstrem',
                        color: AppColors.red,
                        onTap: () => _setScreen('result_extreme'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderBlack, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderBlack,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 8. SCREEN: RESULT HEALTHY (PRIMA)
  // ==========================================
  Widget _buildResultHealthyScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.appBg,
            AppColors.greenBg,
            AppColors.appBg,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _buildHeader(
                titleText: 'Hasil Skrining',
                subtitleText: 'Kondisi Prima',
              ),
              const SizedBox(height: 12),

              // Avatar Happy 100% Bugar
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.borderBlack, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.borderBlack,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.greenDark,
                        size: 60,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderBlack,
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        '100% Bugar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Kondisi Anda Prima!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.greenText,
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Tidak terdeteksi indikator depresi maupun burnout signifikan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greenText,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kartu Tips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.borderBlack,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: AppColors.greenDark),
                          SizedBox(width: 6),
                          Text(
                            'REKOMENDASI PRESERVASI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '"Jaga ritme kerja dan hidrasi."',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint(
                          'Pertahankan waktu tidur 7-8 jam per malam.'),
                      _buildBulletPoint(
                          'Lakukan peregangan ringan setiap 90 menit bekerja.'),
                      _buildBulletPoint(
                          'Pertahankan interaksi sosial yang sehat.'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Selesai Button
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _buildNeoPillButton(
              text: 'Selesai',
              icon: Icons.check_rounded,
              backgroundColor: AppColors.greenDark,
              onPressed: () => _setScreen('dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryGray)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryGray,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 9. SCREEN: RESULT MODERATE (BURNOUT SEDANG)
  // ==========================================
  Widget _buildResultModerateScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.appBg,
            AppColors.amberBg,
            AppColors.appBg,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _buildHeader(
                titleText: 'Hasil Skrining',
                subtitleText: 'Kelelahan Terdeteksi',
              ),
              const SizedBox(height: 8),

              // Alert Icon Circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderBlack,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.amberDark,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Gejala Kelelahan (Burnout Sedang) Terdeteksi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amberText,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Variabilitas gait dan prosodi suara menunjukkan beban kognitif berlebih.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.amberText,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Recipe Card: Resep Anti-Zombi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: AppColors.borderBlack, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.borderBlack,
                        offset: Offset(5, 5),
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
                          const Text(
                            '📋 Resep Anti-Zombi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Mikro-Intervensi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amberText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Selesaikan 3 langkah pemulihan cepat ini untuk me-reset sistem saraf:',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryGray,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Checklists Interaktif
                      _buildChecklistTile(
                        key: 'stretch',
                        title: 'Peregangan Otot Leher & Bahu (3 Menit)',
                      ),
                      const SizedBox(height: 8),
                      _buildChecklistTile(
                        key: 'coffee',
                        title: 'Seduh Kopi/Teh Hangat Tanpa Gula',
                      ),
                      const SizedBox(height: 8),
                      _buildChecklistTile(
                        key: 'rest',
                        title: 'Istirahat Taktil (Jauhkan Layar 10 Menit)',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Selesaikan Resep Button
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _buildNeoPillButton(
              text: 'Selesaikan Resep',
              icon: Icons.check_rounded,
              backgroundColor: AppColors.primaryYellow,
              textColor: AppColors.primaryBlue,
              onPressed: () => _setScreen('dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistTile({
    required String key,
    required String title,
  }) {
    final isChecked = _checkedInterventions[key] ?? false;

    return InkWell(
      onTap: () {
        setState(() {
          _checkedInterventions[key] = !isChecked;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isChecked ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? Colors.grey.shade300 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: isChecked,
                activeColor: AppColors.primaryBlue,
                onChanged: (val) {
                  setState(() {
                    _checkedInterventions[key] = val ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  decoration: isChecked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: isChecked ? Colors.grey.shade400 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 10. SCREEN: RESULT EXTREME (ZOMBI AKUT)
  // ==========================================
  Widget _buildResultExtremeScreen() {
    return Container(
      color: AppColors.redBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _buildHeader(
                titleText: 'Peringatan Medis',
                subtitleText: 'Kondisi Kritis',
              ),
              const SizedBox(height: 8),

              // Zombie Alert Icon Circle
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderBlack, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderBlack,
                      offset: Offset(5, 5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_rounded,
                    color: AppColors.redDark,
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Peringatan Mode Zombi Akut',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.redDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Indikator depresi berat dan kelelahan saraf akut terdeteksi pada 4 multimodal sensor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.redText,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Warning Alert Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: AppColors.borderBlack, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.borderBlack,
                        offset: Offset(5, 5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TINDAKAN CEPAT DIBUTUHKAN:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.redDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Jangan memaksakan aktivitas fisik maupun pekerjaan komputasi saat ini. Segera hubungi tenaga profesional kesehatan mental atau pendamping terdekat.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Emergency Hotline Badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.redBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          '🚨 Hotline Darurat Sejiwa: 119 ext 8',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.redDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom 2 Bold Triage Buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              children: [
                _buildNeoPillButton(
                  text: 'Konsultasi Telemedicine Segera',
                  icon: Icons.phone_in_talk_rounded,
                  backgroundColor: AppColors.redDark,
                  isFullWidth: true,
                  onPressed: () => _setScreen('dashboard'),
                ),
                const SizedBox(height: 12),
                _buildNeoPillButton(
                  text: 'Protokol Istirahat Penuh',
                  backgroundColor: AppColors.secondaryGray,
                  isFullWidth: true,
                  onPressed: () => _setScreen('dashboard'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 11. SCREEN: RIWAYAT SKRINING (HISTORY)
  // ==========================================
  Widget _buildHistoryScreen() {
    // 4 Data dummy riwayat skrining statis (hardcoded)
    final List<Map<String, dynamic>> dummyHistoryList = [
      {
        'id': 'SCR-2026-1012',
        'date': '12 Okt 2026',
        'time': '14:30 WIB',
        'category': 'healthy',
        'title': 'Kondisi Prima (Sehat)',
        'score': 92,
        'badgeText': 'Prima • 92/100',
        'accentColor': AppColors.greenDark,
        'bgTint': AppColors.greenBg,
        'textColor': AppColors.greenText,
        'icon': Icons.sentiment_very_satisfied_rounded,
        'summary':
            'Respon saraf otonom prima. Irama gait stabil simetris dan mikrosleep visual nihil.',
        'details': {
          'suara': {
            'score': '94%',
            'desc': 'Prosodi vokal dinamis & ekspresif'
          },
          'gait': {'score': '91%', 'desc': 'Simetri irama langkah optimal'},
          'visual': {
            'score': '18%',
            'desc': 'Tegangan optik kornea sangat rendah'
          },
          'sketsa': {'score': '22%', 'desc': 'Pola goresan spontan & rileks'},
        },
        'tips':
            'Pertahankan ritme kerja, hidrasi teratur, dan pola istirahat sirkadian saat ini.',
      },
      {
        'id': 'SCR-2026-1008',
        'date': '08 Okt 2026',
        'time': '19:15 WIB',
        'category': 'moderate',
        'title': 'Kelelahan Kerja (Burnout Sedang)',
        'score': 64,
        'badgeText': 'Burnout • 64/100',
        'accentColor': AppColors.amberDark,
        'bgTint': AppColors.amberBg,
        'textColor': AppColors.amberText,
        'icon': Icons.warning_amber_rounded,
        'summary':
            'Deselerasi frekuensi langkah dan tegangan optik tinggi pasca jam kerja panjang.',
        'details': {
          'suara': {'score': '62%', 'desc': 'Pitch vokal cenderung monoton'},
          'gait': {'score': '58%', 'desc': 'Langkah melambat & variatif'},
          'visual': {
            'score': '74%',
            'desc': 'Frekuensi kedip mata turun signifikan'
          },
          'sketsa': {'score': '65%', 'desc': 'Kerapatan goresan garis padat'},
        },
        'tips':
            'Jalankan Protokol Istirahat: detoks layar 15 menit & rehidrasi 500ml air mineral.',
      },
      {
        'id': 'SCR-2026-0929',
        'date': '29 Sep 2026',
        'time': '09:45 WIB',
        'category': 'healthy',
        'title': 'Kondisi Prima (Sehat)',
        'score': 88,
        'badgeText': 'Prima • 88/100',
        'accentColor': AppColors.greenDark,
        'bgTint': AppColors.greenBg,
        'textColor': AppColors.greenText,
        'icon': Icons.sentiment_satisfied_alt_rounded,
        'summary':
            'Kondisi mental dan motorik bugar setelah jeda istirahat akhir pekan teratur.',
        'details': {
          'suara': {'score': '89%', 'desc': 'Variasi frekuensi vokal normal'},
          'gait': {'score': '87%', 'desc': 'Kecepatan jalan konstan & mantap'},
          'visual': {'score': '24%', 'desc': 'Refleks fokus kornea stabil'},
          'sketsa': {
            'score': '30%',
            'desc': 'Bentuk luwes tanpa penekanan tegang'
          },
        },
        'tips':
            'Fokus kerja terarah. Luangkan peregangan ringan setiap 90 menit bekerja.',
      },
      {
        'id': 'SCR-2026-0915',
        'date': '15 Sep 2026',
        'time': '21:10 WIB',
        'category': 'extreme',
        'title': 'Stres Akut & Beban Kognitif Berat',
        'score': 41,
        'badgeText': 'Kritis • 41/100',
        'accentColor': AppColors.redDark,
        'bgTint': AppColors.redBg,
        'textColor': AppColors.redText,
        'icon': Icons.error_outline_rounded,
        'summary':
            'Terdeteksi deselerasi motorik berat, tremor mikro, serta mikrosleep berulang.',
        'details': {
          'suara': {
            'score': '38%',
            'desc': 'Intonasi lemah & tempo sangat lambat'
          },
          'gait': {
            'score': '44%',
            'desc': 'Ketidakstabilan akselerasi langkah'
          },
          'visual': {
            'score': '89%',
            'desc': 'Kelelahan saraf penglihatan akut'
          },
          'sketsa': {
            'score': '85%',
            'desc': 'Pola garis kaku & bertekanan tajam'
          },
        },
        'tips':
            'Hentikan aktivitas segera, matikan notifikasi kerja, dan prioritaskan istirahat tidur.',
      },
    ];

    final filteredList = dummyHistoryList.where((item) {
      if (_historyFilter == 'all') return true;
      return item['category'] == _historyFilter;
    }).toList();

    return Column(
      children: [
        // Header Bar Riwayat
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _setScreen('dashboard'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.borderBlack, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.borderBlack,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riwayat Skrining',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryBlue,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Arsip Multimodal AI (Statis)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderBlack, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderBlack,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${dummyHistoryList.length} Sesi',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.borderBlack,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Body
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            children: [
              // 1. Stats Overview Banner
              _buildHistoryOverviewStats(dummyHistoryList),
              const SizedBox(height: 18),

              // 2. Filter Chips
              _buildHistoryFilterChips(dummyHistoryList),
              const SizedBox(height: 16),

              // 3. List of History Cards
              if (filteredList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderBlack, width: 2),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 40, color: AppColors.secondaryGray),
                      SizedBox(height: 8),
                      Text(
                        'Tidak ada riwayat pada kategori ini.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryGray,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filteredList.map((item) => _buildHistoryCardItem(item)),

              const SizedBox(height: 16),

              // 4. Tombol Skrining Baru
              _buildNeoPillButton(
                text: '+ Skrining Baru Sekarang',
                icon: Icons.add_chart_rounded,
                backgroundColor: AppColors.primaryBlue,
                isFullWidth: true,
                onPressed: () => _setScreen('stage1'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // Mini Widget: Stat Overview
  Widget _buildHistoryOverviewStats(List<Map<String, dynamic>> list) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderBlack,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColItem(
              'Total Sesi', '${list.length}', Icons.history_edu_rounded),
          Container(
              width: 1.5,
              height: 38,
              color: AppColors.borderBlack.withValues(alpha: 0.15)),
          _buildStatColItem('Rata-rata', '71 / 100', Icons.analytics_outlined),
          Container(
              width: 1.5,
              height: 38,
              color: AppColors.borderBlack.withValues(alpha: 0.15)),
          _buildStatColItem('Terkini', 'Prima ✓', Icons.verified_user_outlined),
        ],
      ),
    );
  }

  Widget _buildStatColItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primaryBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.borderBlack,
          ),
        ),
      ],
    );
  }

  // Mini Widget: Filter Chips
  Widget _buildHistoryFilterChips(List<Map<String, dynamic>> list) {
    final filters = [
      {'key': 'all', 'label': 'Semua (${list.length})'},
      {'key': 'healthy', 'label': 'Prima (2)'},
      {'key': 'moderate', 'label': 'Burnout (1)'},
      {'key': 'extreme', 'label': 'Kritis (1)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _historyFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _historyFilter = f['key']!;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderBlack, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.borderBlack,
                      offset:
                          isSelected ? const Offset(1, 1) : const Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.borderBlack,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Mini Widget: History Card Item
  Widget _buildHistoryCardItem(Map<String, dynamic> item) {
    final Color accentColor = item['accentColor'];
    final Color bgTint = item['bgTint'];
    final Color textColor = item['textColor'];
    final details = item['details'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderBlack,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Tanggal & ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 12, color: AppColors.secondaryGray),
                  const SizedBox(width: 5),
                  Text(
                    '${item['date']} • ${item['time']}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryGray,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F0EA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.borderBlack.withValues(alpha: 0.25)),
                ),
                child: Text(
                  item['id'],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.secondaryGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Status Icon + Title + Score Badge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2),
                ),
                child: Icon(item['icon'], color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item['badgeText'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 3: Ringkasan Deskriptif
          Text(
            item['summary'],
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Row 4: 4 Micro Metrics Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMicroMetricPill('🎙️ Suara', details['suara']['score']),
              _buildMicroMetricPill('🚶 Gait', details['gait']['score']),
              _buildMicroMetricPill('👁️ Visual', details['visual']['score']),
              _buildMicroMetricPill('✏️ Sketsa', details['sketsa']['score']),
            ],
          ),
          const SizedBox(height: 14),

          // Row 5: Action Button (Lihat Rincian Detail Modal)
          InkWell(
            onTap: () => _showHistoryDetailModal(item),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F0EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderBlack, width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Analisis Lengkap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.borderBlack,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 15, color: AppColors.borderBlack),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroMetricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderBlack.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.borderBlack,
        ),
      ),
    );
  }

  // Modal Detail Rincian
  void _showHistoryDetailModal(Map<String, dynamic> item) {
    final details = item['details'] as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.borderBlack, width: 3),
              left: BorderSide(color: AppColors.borderBlack, width: 3),
              right: BorderSide(color: AppColors.borderBlack, width: 3),
            ),
          ),
          padding: const EdgeInsets.all(22.0),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderBlack.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['id'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryGray,
                            ),
                          ),
                          Text(
                            item['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: item['textColor'],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item['bgTint'],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: item['accentColor'], width: 1.5),
                        ),
                        child: Text(
                          'Skor ${item['score']}/100',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: item['textColor'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'RINCIAN 4 SENSOR MULTIMODAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildSensorModalRow(
                      '1. Prosodi Vokal (Suara)',
                      details['suara']['score'],
                      details['suara']['desc'],
                      Icons.mic_rounded),
                  _buildSensorModalRow(
                      '2. Gait Tracker (Sensor Gerak)',
                      details['gait']['score'],
                      details['gait']['desc'],
                      Icons.directions_walk_rounded),
                  _buildSensorModalRow(
                      '3. Tegangan Visual (Kamera)',
                      details['visual']['score'],
                      details['visual']['desc'],
                      Icons.remove_red_eye_rounded),
                  _buildSensorModalRow(
                      '4. Coretan Mental (Canvas Doodle)',
                      details['sketsa']['score'],
                      details['sketsa']['desc'],
                      Icons.draw_rounded),

                  const SizedBox(height: 16),

                  // Rekomendasi AI Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F0EA),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.borderBlack, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 16, color: AppColors.primaryBlue),
                            SizedBox(width: 6),
                            Text(
                              'REKOMENDASI AI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['tips'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildNeoPillButton(
                    text: 'Tutup Rincian',
                    backgroundColor: AppColors.borderBlack,
                    textColor: Colors.white,
                    isFullWidth: true,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorModalRow(
      String title, String score, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F7),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.borderBlack.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderBlack, width: 1.5),
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.borderBlack,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.secondaryGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                score,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTER: FREEHAND DOODLE (STAGE 1)
// ==========================================
class FreehandPainter extends CustomPainter {
  final List<Offset?> points;

  FreehandPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FreehandPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

// ==========================================
// CUSTOM PAINTER: DASHED OVAL SCANNER (STAGE 3)
// ==========================================
class DashedOvalPainter extends CustomPainter {
  final Color color;
  final bool isSuccess;

  DashedOvalPainter({required this.color, required this.isSuccess});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addOval(rect);

    if (isSuccess) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawOval(rect, fillPaint);
    }

    // Gambar dashed path keliling oval
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      const dashLength = 10.0;
      const dashSpace = 8.0;

      while (distance < metric.length) {
        final nextDistance = distance + dashLength;
        final extractPath = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedOvalPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isSuccess != isSuccess;
  }
}
