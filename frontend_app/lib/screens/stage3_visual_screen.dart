import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import 'loading_scan_screen.dart';

class Stage3VisualScreen extends StatefulWidget {
  const Stage3VisualScreen({super.key});

  @override
  State<Stage3VisualScreen> createState() => _Stage3VisualScreenState();
}

class _Stage3VisualScreenState extends State<Stage3VisualScreen> {
  bool _isCaptured = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    if (!kIsWeb) {
      await Permission.camera.request();
    }
  }

  void _simulateAutoCapture() {
    setState(() {
      _isCaptured = true;
      _isProcessing = true;
    });

    Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoadingScanScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: NeoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tahap 3: Visual Scan",
          style: TextStyle(
            color: NeoColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guidance banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NeoColors.borderBlack, width: 2),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      color: NeoColors.black,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Posisikan wajah di dalam oval. Jangan bergerak selama pemindaian.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SIMULATED CAMERA VIEWPORT (KOTAK HITAM DENGAN LIVE EYE-TRACKING)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A), // Dark slate camera background
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: NeoColors.borderBlack,
                      width: 3.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.borderBlack,
                        offset: Offset(6, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Grid Guides
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                            thickness: 1,
                          ),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                            thickness: 1,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          VerticalDivider(
                            color: Colors.white.withValues(alpha: 0.08),
                            thickness: 1,
                          ),
                          VerticalDivider(
                            color: Colors.white.withValues(alpha: 0.08),
                            thickness: 1,
                          ),
                        ],
                      ),

                      // Live Eye-Tracking Header Badge
                      Positioned(
                        top: 14,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isCaptured
                                    ? NeoColors.greenDark
                                    : NeoColors.redDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isCaptured
                                        ? "BIOMARKER TERKUNCI"
                                        : "Live Eye-Tracking",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "FPS: 60 • 1080p",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dashed Oval Face Guide Frame (Putus-putus Merah -> Hijau saat tertangkap)
                      CustomPaint(
                        painter: DashedOvalPainter(
                          color: _isCaptured ? NeoColors.green : NeoColors.redDark,
                          isSuccess: _isCaptured,
                        ),
                        child: SizedBox(
                          width: 200,
                          height: 270,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Crosshair Pusat
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 2,
                                        height: 28,
                                        color: _isCaptured
                                            ? NeoColors.green
                                            : NeoColors.redDark.withValues(alpha: 0.8),
                                      ),
                                      Container(
                                        width: 28,
                                        height: 2,
                                        color: _isCaptured
                                            ? NeoColors.green
                                            : NeoColors.redDark.withValues(alpha: 0.8),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Icon(
                                  _isCaptured
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.face_retouching_natural_rounded,
                                  size: 46,
                                  color: _isCaptured
                                      ? NeoColors.green
                                      : Colors.white.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 8),
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
                                    _isCaptured
                                        ? "Wajah Terkunci!\nMengambil Frame..."
                                        : "Posisikan Wajah",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isCaptured
                                          ? NeoColors.greenLight
                                          : Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Capture Flash simulation
                      if (_isCaptured)
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: _isProcessing ? 0.3 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(color: Colors.white),
                          ),
                        ),

                      // Bottom Facial Landmarks indicator
                      Positioned(
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _isCaptured
                                ? "Micro-Expression Detected: 468 Landmarks"
                                : "Deteksi Biometrik: Siap Mengunci",
                            style: TextStyle(
                              color: _isCaptured
                                  ? NeoColors.greenLight
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Button: "Simulate Auto-Capture"
              NeoButton(
                text: _isCaptured
                    ? "✓ Memproses Multimodal Data..."
                    : "Simulate Auto-Capture",
                icon: _isCaptured ? Icons.check : Icons.camera_rounded,
                backgroundColor:
                    _isCaptured ? NeoColors.greenDark : NeoColors.primaryBlue,
                textColor: NeoColors.white,
                borderRadius: 28,
                height: 56,
                onPressed: _isCaptured ? null : _simulateAutoCapture,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter untuk garis oval putus-putus (Dashed Oval)
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
