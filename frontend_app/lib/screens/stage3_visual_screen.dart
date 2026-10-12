import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';

class Stage3VisualScreen extends StatefulWidget {
  const Stage3VisualScreen({super.key});

  @override
  State<Stage3VisualScreen> createState() => _Stage3VisualScreenState();
}

class _Stage3VisualScreenState extends State<Stage3VisualScreen> {
  bool _isCaptured = false;
  bool _isProcessing = false;

  void _simulateAutoCapture() {
    setState(() {
      _isCaptured = true;
      _isProcessing = true;
    });

    // Simulasi jeda 1 detik lalu pindah ke LoadingScreen
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/loading');
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
                    Icon(Icons.remove_red_eye_outlined,
                        color: NeoColors.black, size: 20),
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

              // SIMULATED CAMERA VIEWPORT
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF0F172A), // Dark slate camera background
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

                      // Camera Live Header
                      Positioned(
                        top: 14,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: ChangeHorizontalAxisAlignment(
                              MainAxisAlignment.spaceBetween),
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: NeoColors.redDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "LIVE FRONT CAM",
                                    style: TextStyle(
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

                      // Oval Face Guide Frame (Turns from Red to Green on capture)
                      Container(
                        width: 200,
                        height: 270,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.elliptical(200, 270),
                          ),
                          border: Border.all(
                            color: _isCaptured
                                ? NeoColors.green
                                : NeoColors.redDark,
                            width: 3.5,
                            style: BorderStyle.solid,
                          ),
                          color: _isCaptured
                              ? NeoColors.green.withValues(alpha: 0.12)
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isCaptured
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.face_retouching_natural_rounded,
                                size: 52,
                                color: _isCaptured
                                    ? NeoColors.green
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isCaptured
                                    ? "Wajah Terkunci!\nMengambil Frame..."
                                    : "Posisikan Wajah",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isCaptured
                                      ? NeoColors.greenLight
                                      : Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
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
                    : "📸 Simulate Auto-Capture Wajah",
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

  MainAxisAlignment ChangeHorizontalAxisAlignment(
          MainAxisAlignment alignment) =>
      alignment;
}
