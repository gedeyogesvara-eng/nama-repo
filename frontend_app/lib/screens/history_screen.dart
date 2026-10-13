import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  final VoidCallback? onStartNewScreening;

  const HistoryScreen({
    super.key,
    this.onBackToDashboard,
    this.onStartNewScreening,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all'; // 'all', 'healthy', 'moderate', 'extreme'

  // Data dummy riwayat skrining statis (hardcoded)
  final List<Map<String, dynamic>> _dummyHistory = const [
    {
      'id': 'SCR-2026-1012',
      'date': '12 Okt 2026',
      'time': '14:30 WIB',
      'category': 'healthy',
      'title': 'Kondisi Prima (Sehat)',
      'score': 92,
      'badgeText': 'Prima • 92/100',
      'accentColor': NeoColors.greenDark,
      'bgTint': NeoColors.greenLight,
      'textColor': NeoColors.greenDark,
      'icon': Icons.sentiment_very_satisfied_rounded,
      'summary':
          'Respon saraf otonom prima. Irama gait stabil simetris dan mikrosleep visual nihil.',
      'details': {
        'suara': {'score': '94%', 'desc': 'Prosodi vokal dinamis & ekspresif'},
        'gait': {'score': '91%', 'desc': 'Simetri irama langkah optimal'},
        'visual': {'score': '18%', 'desc': 'Tegangan optik kornea sangat rendah'},
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
      'accentColor': NeoColors.amber,
      'bgTint': Color(0xFFFEF3C7),
      'textColor': Color(0xFF92400E),
      'icon': Icons.warning_amber_rounded,
      'summary':
          'Deselerasi frekuensi langkah dan tegangan optik tinggi pasca jam kerja panjang.',
      'details': {
        'suara': {'score': '62%', 'desc': 'Pitch vokal cenderung monoton'},
        'gait': {'score': '58%', 'desc': 'Langkah melambat & variatif'},
        'visual': {'score': '74%', 'desc': 'Frekuensi kedip mata turun signifikan'},
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
      'accentColor': NeoColors.greenDark,
      'bgTint': NeoColors.greenLight,
      'textColor': NeoColors.greenDark,
      'icon': Icons.sentiment_satisfied_alt_rounded,
      'summary':
          'Kondisi mental dan motorik bugar setelah jeda istirahat akhir pekan teratur.',
      'details': {
        'suara': {'score': '89%', 'desc': 'Variasi frekuensi suara normal'},
        'gait': {'score': '87%', 'desc': 'Kecepatan jalan konstan & mantap'},
        'visual': {'score': '24%', 'desc': 'Fokus refraksi mata stabil'},
        'sketsa': {'score': '30%', 'desc': 'Garis luwes tanpa penekanan tegang'},
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
      'accentColor': NeoColors.redDark,
      'bgTint': NeoColors.redLight,
      'textColor': NeoColors.darkRedZombie,
      'icon': Icons.error_outline_rounded,
      'summary':
          'Terdeteksi deselerasi motorik berat, tremor mikro, serta mikrosleep berulang.',
      'details': {
        'suara': {'score': '38%', 'desc': 'Intonasi lemah & tempo sangat lambat'},
        'gait': {'score': '44%', 'desc': 'Ketidakstabilan akselerasi langkah'},
        'visual': {'score': '89%', 'desc': 'Kelelahan saraf penglihatan akut'},
        'sketsa': {'score': '85%', 'desc': 'Pola garis kaku & bertekanan tajam'},
      },
      'tips':
          'Hentikan aktivitas segera, matikan notifikasi, dan prioritaskan istirahat tidur.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _dummyHistory.where((item) {
      if (_selectedFilter == 'all') return true;
      return item['category'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildHeaderBar(context),

            // Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                children: [
                  // Stat Overview Banner
                  _buildStatBanner(),
                  const SizedBox(height: 18),

                  // Filter Chips
                  _buildFilterChips(),
                  const SizedBox(height: 16),

                  // History Cards
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ...filtered.map((item) => _buildHistoryCard(context, item)),

                  const SizedBox(height: 18),

                  // Bottom Button to trigger new screening
                  NeoButton(
                    text: "+ Skrining Baru Sekarang",
                    icon: Icons.add_chart_rounded,
                    backgroundColor: NeoColors.primaryBlue,
                    textColor: NeoColors.white,
                    onPressed: widget.onStartNewScreening ?? () {},
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HEADER BAR ---
  Widget _buildHeaderBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: widget.onBackToDashboard ?? () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NeoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoColors.borderBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.borderBlack,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: NeoColors.primaryBlue,
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
                      color: NeoColors.primaryBlue,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Rekapitulasi Multimodal AI (Statis)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: NeoColors.primaryBlue.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: NeoColors.primaryYellow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NeoColors.borderBlack, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: NeoColors.borderBlack,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              '${_dummyHistory.length} Sesi',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STAT OVERVIEW BANNER ---
  Widget _buildStatBanner() {
    return NeoCard(
      backgroundColor: NeoColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shadowOffset: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Total Sesi', '${_dummyHistory.length}', Icons.history_edu_rounded),
          Container(width: 1.5, height: 38, color: NeoColors.borderBlack.withValues(alpha: 0.15)),
          _buildStatColumn('Rata-rata Skor', '71 / 100', Icons.analytics_outlined),
          Container(width: 1.5, height: 38, color: NeoColors.borderBlack.withValues(alpha: 0.15)),
          _buildStatColumn('Kondisi Terkini', 'Prima ✓', Icons.verified_user_outlined),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: NeoColors.primaryBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: NeoColors.darkGray,
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
            color: NeoColors.black,
          ),
        ),
      ],
    );
  }

  // --- FILTER CHIPS ---
  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Semua (${_dummyHistory.length})'},
      {'key': 'healthy', 'label': 'Prima (2)'},
      {'key': 'moderate', 'label': 'Burnout (1)'},
      {'key': 'extreme', 'label': 'Kritis (1)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = f['key']!;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? NeoColors.primaryBlue : NeoColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: NeoColors.borderBlack, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: NeoColors.borderBlack,
                      offset: isSelected ? const Offset(1, 1) : const Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? NeoColors.white : NeoColors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- HISTORY CARD ITEM ---
  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item) {
    final Color accentColor = item['accentColor'];
    final Color bgTint = item['bgTint'];
    final Color textColor = item['textColor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeoColors.borderBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: NeoColors.borderBlack,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Tanggal, Waktu & ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: NeoColors.darkGray),
                  const SizedBox(width: 5),
                  Text(
                    '${item['date']} • ${item['time']}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: NeoColors.darkGray,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F0EA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeoColors.borderBlack.withValues(alpha: 0.3)),
                ),
                child: Text(
                  item['id'],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: NeoColors.darkGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Row: Icon + Title + Score Badge
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

          // Ringkasan Teks
          Text(
            item['summary'],
            style: const TextStyle(
              fontSize: 12,
              color: NeoColors.darkGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // 4 Micro Metrics Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMicroMetricPill('🎙️ Suara', item['details']['suara']['score']),
              _buildMicroMetricPill('🚶 Gait', item['details']['gait']['score']),
              _buildMicroMetricPill('👁️ Visual', item['details']['visual']['score']),
              _buildMicroMetricPill('✏️ Sketsa', item['details']['sketsa']['score']),
            ],
          ),
          const SizedBox(height: 14),

          // Action Button: Lihat Rincian
          InkWell(
            onTap: () => _showDetailBottomSheet(context, item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: NeoColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeoColors.borderBlack, width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Analisis Lengkap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: NeoColors.black,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: NeoColors.black),
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
        border: Border.all(color: NeoColors.borderBlack.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: NeoColors.black,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: NeoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeoColors.borderBlack, width: 2),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: NeoColors.darkGray),
          SizedBox(height: 8),
          Text(
            'Tidak ada riwayat pada kategori ini.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: NeoColors.darkGray,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- MODAL BOTTOM SHEET DETAIL ANALISIS ---
  void _showDetailBottomSheet(BuildContext context, Map<String, dynamic> item) {
    final details = item['details'] as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: NeoColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: NeoColors.borderBlack, width: 3),
              left: BorderSide(color: NeoColors.borderBlack, width: 3),
              right: BorderSide(color: NeoColors.borderBlack, width: 3),
            ),
          ),
          padding: const EdgeInsets.all(22.0),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: NeoColors.borderBlack.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Modal
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
                              color: NeoColors.darkGray,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item['bgTint'],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: item['accentColor'], width: 1.5),
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
                      color: NeoColors.primaryBlue,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4 Sensor Breakdown List
                  _buildSensorDetailRow('1. Prosodi Vokal (Suara)', details['suara']['score'], details['suara']['desc'], Icons.mic_rounded),
                  _buildSensorDetailRow('2. Gait Tracker (Sensor Gerak)', details['gait']['score'], details['gait']['desc'], Icons.directions_walk_rounded),
                  _buildSensorDetailRow('3. Tegangan Visual (Kamera)', details['visual']['score'], details['visual']['desc'], Icons.remove_red_eye_rounded),
                  _buildSensorDetailRow('4. Coretan Mental (Canvas Doodle)', details['sketsa']['score'], details['sketsa']['desc'], Icons.draw_rounded),

                  const SizedBox(height: 16),

                  // Rekomendasi Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F0EA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 16, color: NeoColors.primaryBlue),
                            SizedBox(width: 6),
                            Text(
                              'REKOMENDASI AI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['tips'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: NeoColors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Close button
                  NeoButton(
                    text: 'Tutup Rincian',
                    backgroundColor: NeoColors.slate,
                    textColor: NeoColors.white,
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

  Widget _buildSensorDetailRow(String title, String score, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeoColors.borderBlack.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: NeoColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NeoColors.borderBlack, width: 1.5),
              ),
              child: Icon(icon, size: 18, color: NeoColors.primaryBlue),
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
                      color: NeoColors.black,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 10,
                      color: NeoColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: NeoColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                score,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
