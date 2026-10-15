import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_card.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Otomatis pindah ke AuthScreen setelah delay 2 detik sesuai ketentuan
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: NeoCard(
                    backgroundColor: NeoColors.primaryYellow,
                    borderRadius: 28,
                    shadowOffset: 8,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NeoColors.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NeoColors.borderBlack,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.psychology_alt_rounded,
                            size: 64,
                            color: NeoColors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "EMO-SENSE AI",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: NeoColors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NeoColors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "MULTIMODAL DEPRESSION DETECTION",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: NeoColors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  "Memeriksa Integritas Sensor...",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.darkGray,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      minHeight: 8,
                      backgroundColor: NeoColors.lightGray,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        NeoColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  "Prototipe Native Flutter • Neo-Brutalism Edition",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.slateLight,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
