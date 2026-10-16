import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class ExtremeResultScreen extends StatelessWidget {
  const ExtremeResultScreen({super.key});

  void _showTriageDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: NeoColors.borderBlack, width: 3),
        ),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: NeoColors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: NeoColors.slate,
            height: 1.4,
          ),
        ),
        actions: [
          NeoButton(
            text: "Kembali ke Dashboard",
            backgroundColor: NeoColors.black,
            textColor: NeoColors.white,
            height: 44,
            borderRadius: 14,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/dashboard',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF2F2), // Light red alert background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Peringatan Triage Darurat",
          style: TextStyle(
            color: NeoColors.redDark,
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
                    color: NeoColors.redDark,
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
                      Icon(Icons.warning_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "PERINGATAN: MODE ZOMBI AKUT TERDETEKSI",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Zombie Avatar Card
              Center(
                child: NeoCard(
                  backgroundColor: NeoColors.white,
                  borderColor: NeoColors.redDark,
                  borderRadius: 26,
                  shadowOffset: 6,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: NeoColors.redLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NeoColors.redDark,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.battery_alert_rounded,
                          size: 58,
                          color: NeoColors.redDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Zombi Akut / Severe Exhaustion",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.redDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Skor Kelelahan Ekstrem: 89 / 100",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.slate,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Kombinasi kelambatan grafomotor, jeda suara terputus-putus, serta mikro-ekspresi menunjukkan keletihan sistem saraf akut. Hentikan seluruh beban kerja sekarang.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NeoColors.slateMedium,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Hotline Bantuan Medis
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NeoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NeoColors.borderBlack, width: 2),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      color: NeoColors.redDark,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hotline Dukungan Psikologis 24 Jam",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: NeoColors.black,
                            ),
                          ),
                          Text(
                            "Layanan Sejiwa: 119 (ext 8) • Bebas Pulsa",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: NeoColors.redDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2 BOLD TRIAGE BUTTONS AS REQUIRED:
              // 1. Red Button: "Konsultasi Telemedicine Segera"
              NeoButton(
                text: "📞 Konsultasi Telemedicine Segera",
                icon: Icons.video_call_rounded,
                backgroundColor: NeoColors.redDark,
                textColor: NeoColors.white,
                borderRadius: 28,
                height: 56,
                onPressed: () {
                  _showTriageDialog(
                    context,
                    title: "Rujukan Telemedicine Terhubung",
                    message:
                        "Sistem telah meneruskan ringkasan triase multimodal ke konselor klinis on-duty. Panggilan video konsultasi akan dimulai dalam 3 menit.",
                    color: NeoColors.redDark,
                    icon: Icons.medical_services_rounded,
                  );
                },
              ),

              const SizedBox(height: 12),

              // 2. Gray Button: "Protokol Istirahat Penuh"
              NeoButton(
                text: "🛑 Protokol Istirahat Penuh (DND Mode)",
                icon: Icons.do_not_disturb_on_rounded,
                backgroundColor: NeoColors.darkGray,
                textColor: NeoColors.white,
                borderRadius: 28,
                height: 54,
                onPressed: () {
                  _showTriageDialog(
                    context,
                    title: "Protokol Istirahat Aktif",
                    message:
                        "Mode istirahat total diaktifkan. Matikan seluruh layar digital selama minimal 4 jam dan konsumsi air minum hangat.",
                    color: NeoColors.darkGray,
                    icon: Icons.bed_rounded,
                  );
                },
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/dashboard',
                      (route) => false,
                    );
                  },
                  child: const Text(
                    "Kembali ke Menu Utama",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: NeoColors.slate,
                      fontSize: 13,
                    ),
                  ),
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
