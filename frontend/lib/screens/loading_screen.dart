import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _processingStep = 0;

  final List<String> _steps = [
    "Menganalisis tekanan goresan grafomotor...",
    "Mengekstraksi fitur prosodi frekuensi vokal...",
    "Menghitung variabilitas irama langkah kaki...",
    "Melakukan fusi multimodal transformer...",
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _cycleSteps();
  }

  void _cycleSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _processingStep = (i + 1) % _steps.length;
        });
      }
    }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Animated AI Brain / Neural processing visual
              Center(
                child: RotationTransition(
                  turns: _animController,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: NeoColors.primaryYellow,
                      shape: BoxShape.circle,
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
                    child: const Center(
                      child: Icon(
                        Icons.hub_rounded,
                        size: 52,
                        color: NeoColors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                "Agentic AI Memproses Data...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Menggabungkan data visual, audio, dan sensor gerak ke dalam model klasifikasi depresi.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NeoColors.darkGray,
                ),
              ),

              const SizedBox(height: 24),

              // Processing Step NeoCard
              NeoCard(
                backgroundColor: NeoColors.white,
                borderRadius: 16,
                shadowOffset: 4,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          NeoColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _steps[_processingStep],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.slate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // TESTING & DEBUG BRANCH NAVIGATION (3 TOMBOL RAHASIA)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: NeoColors.borderBlack,
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.borderBlack,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.science_rounded,
                          size: 18,
                          color: NeoColors.black,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: NeoColors.primaryYellow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: NeoColors.borderBlack,
                              width: 1.5,
                            ),
                          ),
                          child: const Text(
                            "MODE SIMULASI PENGUJIAN",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Pilih jalur hasil diagnosa untuk menguji screen prototipe:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: NeoColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rahasia 1: Hasil Sehat
                    NeoButton(
                      text: "1. Simulate Hasil Sehat (100% Bugar)",
                      icon: Icons.sentiment_very_satisfied_rounded,
                      backgroundColor: NeoColors.greenDark,
                      textColor: NeoColors.white,
                      height: 46,
                      borderRadius: 14,
                      shadowOffset: 3,
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/result_healthy');
                      },
                    ),
                    const SizedBox(height: 8),

                    // Rahasia 2: Hasil Sedang
                    NeoButton(
                      text: "2. Simulate Hasil Sedang (Kelelahan)",
                      icon: Icons.sentiment_neutral_rounded,
                      backgroundColor: NeoColors.amber,
                      textColor: NeoColors.black,
                      height: 46,
                      borderRadius: 14,
                      shadowOffset: 3,
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/result_moderate',
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Rahasia 3: Hasil Ekstrem
                    NeoButton(
                      text: "3. Simulate Hasil Ekstrem (Zombi Akut)",
                      icon: Icons.warning_rounded,
                      backgroundColor: NeoColors.redDark,
                      textColor: NeoColors.white,
                      height: 46,
                      borderRadius: 14,
                      shadowOffset: 3,
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/result_extreme',
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
