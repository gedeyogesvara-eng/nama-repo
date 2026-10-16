import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import 'result_screen.dart';

/// Halaman Loading Scan AI (Layar Loading Hasil Diagnosis)
/// Menampilkan animasi visual scanner multimodal (Sklera, Suara, Gait),
/// mengirimkan data multimodal (bytes) ke backend Go (POST /api/detect) yang
/// meneruskannya ke server AI Python dan menyimpannya ke MySQL,
/// lalu berpindah ke ResultScreen setelah respons diterima.
///
/// Didesain dengan gaya 'Modern Clean':
/// - Background putih/abu-abu terang (adaptif ke Dark Mode)
/// - Elemen dominan Deep Blue (#314BB5)
/// - Card tengah melengkung elegan (BorderRadius.circular(32))
/// - Indikator loading CircularProgressIndicator halus dan lembut
/// - Shadow sangat halus dan transparan (tanpa border hitam/shadow kaku)
class LoadingScanScreen extends StatefulWidget {
  final Uint8List? faceBytes;
  final Uint8List? drawingBytes;
  final Uint8List? audioBytes;
  final dynamic gaitData;

  const LoadingScanScreen({
    super.key,
    this.faceBytes,
    this.drawingBytes,
    this.audioBytes,
    this.gaitData = 'gait_recorded',
  });

  @override
  State<LoadingScanScreen> createState() => _LoadingScanScreenState();
}

class _LoadingScanScreenState extends State<LoadingScanScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);

  late AnimationController _animController;
  int _currentStepIndex = 0;
  Timer? _stepTimer;
  bool _isConnecting = true;

  final List<String> _analysisSteps = const [
    'Mengunggah berkas sensor multimodal ke backend...',
    'Memindai vaskularisasi & mikrosleep sklera optik...',
    'Mengekstrak prosodi nada vokal & tremor akustik...',
    'Menganalisis simetri akselerometer gait berjalan...',
    'Mengagregasi skor AI Multimodal & menyusun resep...',
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _analysisSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
      }
    });

    _processDetection();
  }

  Future<void> _processDetection() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      final resultData = await AIService.sendDataToAI(
        faceImageBytes: widget.faceBytes,
        drawingImageBytes: widget.drawingBytes,
        audioBytes: widget.audioBytes,
        gaitData: widget.gaitData,
        userId: authService.currentUserId,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(detectionData: resultData),
        ),
      );
    } catch (e) {
      debugPrint("❌ Gagal terhubung ke AI Model: $e. Menggunakan fallback diagnosis otomatis.");
      if (!mounted) return;
      final fallbackData = AIService.getFallbackDetectionData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(detectionData: fallbackData),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar Status - Sleek Modern Pill
              _buildTopStatus(isDark),

              // Central Scanning Card Elegan
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
                            blurRadius: 36,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Indikator Loading Elegan dengan CircularProgressIndicator & Pulse Glow
                          _buildElegantLoadingIndicator(isDark),
                          const SizedBox(height: 30),

                          // Teks Utama
                          Text(
                            'AI Sedang Menganalisis Sensor...',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : primaryBlue,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mengintegrasikan respons sklera, vokal, ritme motorik, dan akselerometer gait.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Teks Sub-tahapan Dinamis (Modern Pill Badge)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              key: ValueKey<int>(_currentStepIndex),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      _analysisSteps[_currentStepIndex],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sensor Active Nodes (Sklera, Suara, Gait) - Modern Clean Pills
                          _buildSensorNodesRow(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Info Box
              _buildBottomNotice(isDark, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatus(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isConnecting ? accentAmber : accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isConnecting ? accentAmber : accentGreen).withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isConnecting ? 'HTTP REQUEST AKTIF' : 'MENUNGGU RESPONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : primaryBlue,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Somatic.AI Core',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  /// Indikator loading halus: CircularProgressIndicator Deep Blue dibalut dalam Stack animasi
  Widget _buildElegantLoadingIndicator(bool isDark) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final pulseScale = 1.0 + (_animController.value * 0.14);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Gelombang Pulse Luar Sangat Halus
            Transform.scale(
              scale: pulseScale,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryBlue.withValues(
                    alpha: 0.08 * (1.0 - _animController.value),
                  ),
                ),
              ),
            ),

            // Lingkaran Circular Progress Halus
            SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            ),

            // Ikon Inti Melayang
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FC),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.sensors_rounded,
                  color: primaryBlue,
                  size: 34,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensorNodesRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSensorNodeChip(
          Icons.remove_red_eye_outlined,
          'Sklera',
          _currentStepIndex >= 1,
          isDark,
        ),
        const SizedBox(width: 8),
        _buildSensorNodeChip(
          Icons.graphic_eq_rounded,
          'Suara',
          _currentStepIndex >= 2,
          isDark,
        ),
        const SizedBox(width: 8),
        _buildSensorNodeChip(
          Icons.directions_walk_rounded,
          'Gait',
          _currentStepIndex >= 3,
          isDark,
        ),
      ],
    );
  }

  Widget _buildSensorNodeChip(IconData icon, String label, bool isActive, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? primaryBlue
            : (isDark ? const Color(0xFF141414) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(999),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : icon,
            size: 13,
            color: isActive
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNotice(bool isDark, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Mengirim data ke model AI lokal...',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
