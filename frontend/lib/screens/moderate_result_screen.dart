import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class ModerateResultScreen extends StatefulWidget {
  const ModerateResultScreen({super.key});

  @override
  State<ModerateResultScreen> createState() => _ModerateResultScreenState();
}

class _ModerateResultScreenState extends State<ModerateResultScreen> {
  int _selectedTab = 0; // 0: Resep Fisik, 1: Resep Mental

  final Map<String, bool> _physicalRecipes = {
    "Peregangan otot leher & pundak (5 menit)": false,
    "Seduh teh herbal / air hangat (hindari kafein berlebih)": false,
    "Jalan santai tanpa menatap layar ponsel (10 menit)": false,
    "Istirahat taktil (kompres mata dengan kain hangat)": false,
  };

  final Map<String, bool> _mentalRecipes = {
    "Latihan pernapasan 4-7-8 untuk menenangkan saraf": false,
    "Catat 3 hal yang membuatmu cemas lalu tutup buku": false,
    "Matikan notifikasi pekerjaan setelah jam kerja": false,
    "Dengarkan audio gelombang alfa / binaural beats": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF3C7), // Amber/Yellow soft background
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
                    color: NeoColors.amber,
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
                      Icon(Icons.warning_amber_rounded,
                          color: NeoColors.black, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "STATUS: GEJALA KELELAHAN (BURNOUT SEDANG)",
                        style: TextStyle(
                          color: NeoColors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Title and Summary NeoCard
              NeoCard(
                backgroundColor: NeoColors.white,
                borderRadius: 24,
                shadowOffset: 6,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE68A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: NeoColors.borderBlack,
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.sentiment_neutral_rounded,
                        size: 56,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Gejala Kelelahan Terdeteksi",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Skor Depresi / Fatigue: 54 / 100",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ditemukan penurunan ritme gait dan jeda vokal lebih lambat. Lakukan resep pemulihan anti-zombie berikut:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // TAB SWITCHER: RESEP FISIK VS RESEP MENTAL
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? NeoColors.primaryBlue
                              : NeoColors.white,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(16),
                          ),
                          border: Border.all(
                            color: NeoColors.borderBlack,
                            width: 2.5,
                          ),
                          boxShadow: _selectedTab == 0
                              ? const [
                                  BoxShadow(
                                    color: NeoColors.borderBlack,
                                    offset: Offset(3, 3),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            "🏃 RESEP FISIK",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _selectedTab == 0
                                  ? NeoColors.white
                                  : NeoColors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? NeoColors.primaryBlue
                              : NeoColors.white,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(16),
                          ),
                          border: Border.all(
                            color: NeoColors.borderBlack,
                            width: 2.5,
                          ),
                          boxShadow: _selectedTab == 1
                              ? const [
                                  BoxShadow(
                                    color: NeoColors.borderBlack,
                                    offset: Offset(3, 3),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            "🧠 RESEP MENTAL",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _selectedTab == 1
                                  ? NeoColors.white
                                  : NeoColors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // THE WHITE "RECIPE CARD" (Checklist format)
              NeoCard(
                backgroundColor: NeoColors.white,
                borderRadius: 20,
                shadowOffset: 5,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedTab == 0
                              ? Icons.fitness_center_rounded
                              : Icons.spa_rounded,
                          color: NeoColors.primaryBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTab == 0
                              ? "Daftar Checklist Fisik Harian"
                              : "Daftar Checklist Relaksasi Mental",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.black,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: NeoColors.borderBlack, thickness: 1.5),
                    const SizedBox(height: 6),

                    // Render Checklist Items
                    ...(_selectedTab == 0 ? _physicalRecipes : _mentalRecipes)
                        .entries
                        .map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: entry.value,
                              activeColor: NeoColors.primaryBlue,
                              checkColor: NeoColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: const BorderSide(
                                  color: NeoColors.borderBlack,
                                  width: 2,
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (_selectedTab == 0) {
                                    _physicalRecipes[entry.key] = val ?? false;
                                  } else {
                                    _mentalRecipes[entry.key] = val ?? false;
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: entry.value
                                        ? NeoColors.slateLight
                                        : NeoColors.black,
                                    decoration: entry.value
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Button: "Selesaikan Resep" -> Dashboard
              NeoButton(
                text: "Selesaikan Resep & Kembali",
                icon: Icons.check_circle_outline_rounded,
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
}
