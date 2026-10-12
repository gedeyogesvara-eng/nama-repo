import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class HealthyResultScreen extends StatelessWidget {
  const HealthyResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Fresh green tint background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Hasil Skrining Multimodal",
          style: TextStyle(
            color: NeoColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badge status
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeoColors.green,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NeoColors.borderBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.borderBlack,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "STATUS: 100% BUGAR & PRIMA",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Avatar of happy/fit person inside NeoCard
              Center(
                child: NeoCard(
                  backgroundColor: NeoColors.white,
                  borderRadius: 28,
                  shadowOffset: 6,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBBF7D0),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NeoColors.borderBlack,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.sentiment_very_satisfied_rounded,
                          size: 68,
                          color: NeoColors.greenDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Kondisi Anda Prima!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Skor Depresi: 12 / 100 (Resiko Rendah)",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.greenDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Analisis grafomotor, modulasi suara, dan ritme langkah kaki menunjukkan energi mental optimal tanpa kelelahan signifikan.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NeoColors.darkGray,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tips Hidrasi & Kebugaran Card
              NeoCard(
                backgroundColor: NeoColors.white,
                borderRadius: 20,
                shadowOffset: 5,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop_rounded,
                            color: NeoColors.primaryBlue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Tips Hidrasi & Performa Harian",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTipRow(
                      icon: Icons.local_drink_rounded,
                      title: "Konsumsi Air 2.5 Liter",
                      desc: "Jaga hidrasi sel otak untuk konsentrasi tinggi.",
                    ),
                    const SizedBox(height: 10),
                    _buildTipRow(
                      icon: Icons.nightlight_round,
                      title: "Jaga Ritme Tidur Konsisten",
                      desc: "Tidur 7-8 jam untuk pemulihan kognitif penuh.",
                    ),
                    const SizedBox(height: 10),
                    _buildTipRow(
                      icon: Icons.self_improvement_rounded,
                      title: "Pertahankan Aktivitas Positif",
                      desc: "Lakukan jalan santai atau peregangan tiap 2 jam.",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Button: "Selesai" -> Dashboard
              NeoButton(
                text: "Selesai & Kembali ke Beranda",
                icon: Icons.home_rounded,
                backgroundColor: NeoColors.primaryBlue,
                textColor: NeoColors.white,
                borderRadius: 28,
                height: 56,
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NeoColors.borderBlack, width: 1.5),
          ),
          child: Icon(icon, color: NeoColors.greenDark, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: NeoColors.black,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: NeoColors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
