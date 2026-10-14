import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/offset_canvas_box.dart';
import 'stage1_mental_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Avatar + User Info + Notification Bell
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
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
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Halo, Budi Santoso",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.black,
                            ),
                          ),
                          Text(
                            "Kondisi: Belum Skrining Hari Ini",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: NeoColors.darkGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                ],
              ),

              const SizedBox(height: 24),

              // THE SIGNATURE "OFFSET CANVAS" (BLUE BACKGROUND)
              OffsetCanvasBox(
                width: 280,
                height: 250,
                backgroundColor: NeoColors.primaryBlue,
                outlineColor: NeoColors.primaryBlue,
                borderRadius: 32,
                offset: 12,
                padding: const EdgeInsets.all(20),
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
                  );
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
                  );
                },
              ),

              const SizedBox(height: 20),

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
