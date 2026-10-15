import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../services/history_service.dart';
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

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    HistoryService.historyNotifier.addListener(_onHistoryUpdated);
  }

  @override
  void dispose() {
    HistoryService.historyNotifier.removeListener(_onHistoryUpdated);
    super.dispose();
  }

  void _onHistoryUpdated() {
    if (mounted) {
      final updated = HistoryService.historyNotifier.value;
      if (updated.isNotEmpty || authService.currentUserId == null) {
        setState(() {
          _history = updated;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    final userId = authService.currentUserId;
    if (userId != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final rows = await BackendService.fetchHistory(userId);
        if (rows.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _history = rows.map(_mapSession).toList();
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Gagal memuat riwayat dari server: $e');
      }
    }

    // Fallback ke penyimpanan lokal HistoryService (SharedPreferences)
    try {
      final list = await HistoryService.getHistoryList();
      if (!mounted) return;
      setState(() {
        _history = list;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Tidak dapat memuat riwayat skrining.';
      });
    }
  }

  Color _resolveColor(dynamic val, Color fallback) {
    if (val is Color) return val;
    if (val is int) return Color(val);
    return fallback;
  }

  IconData _resolveIcon(dynamic iconVal, dynamic category) {
    if (iconVal is IconData) return iconVal;
    if (category == 'extreme') return Icons.error_outline_rounded;
    if (category == 'healthy') return Icons.sentiment_very_satisfied_rounded;
    return Icons.warning_amber_rounded;
  }

  /// Mengubah satu baris `screening_sessions` dari backend menjadi struktur kartu riwayat
  Map<String, dynamic> _mapSession(Map<String, dynamic> s) {
    int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

    final int voiceScore = asInt(s['voice_score']) > 0 ? asInt(s['voice_score']) : asInt(s['skor_akustik']);
    final int visualScore = asInt(s['visual_score']) > 0 ? asInt(s['visual_score']) : asInt(s['skor_sklera']);
    final int sketchScore = asInt(s['sketch_score']) > 0 ? asInt(s['sketch_score']) : asInt(s['skor_motorik']);
    final int gaitScore = asInt(s['gait_score']) > 0 ? asInt(s['gait_score']) : asInt(s['skor_motorik']);

    final int avg = ((voiceScore + visualScore + sketchScore + gaitScore) / 4).round().clamp(0, 100);

    final String kategori = (s['kategori_burnout'] ?? 'Kelelahan Terdeteksi').toString();
    final String lower = kategori.toLowerCase();
    final bool emergency = s['is_emergency'] == true;

    late final String category;
    late final String label;
    late final Color accent;
    late final Color tint;
    late final Color text;
    late final IconData icon;
    if (emergency || lower.contains('zombi akut')) {
      category = 'extreme';
      label = 'Kritis';
      accent = NeoColors.redDark;
      tint = NeoColors.redLight;
      text = NeoColors.darkRedZombie;
      icon = Icons.error_outline_rounded;
    } else if (lower.contains('stabil') || lower.contains('sehat') || lower.contains('prima')) {
      category = 'healthy';
      label = 'Prima';
      accent = NeoColors.greenDark;
      tint = NeoColors.greenLight;
      text = NeoColors.greenDark;
      icon = Icons.sentiment_very_satisfied_rounded;
    } else {
      category = 'moderate';
      label = 'Burnout';
      accent = NeoColors.amber;
      tint = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
      icon = Icons.warning_amber_rounded;
    }

    final DateTime? created = DateTime.tryParse('${s['created_at']}')?.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final String date = created == null
        ? '-'
        : '${two(created.day)} ${_months[created.month - 1]} ${created.year}';
    final String time = created == null ? '-' : '${two(created.hour)}:${two(created.minute)}';

    final String eyeLabel = (s['eye_label'] ?? 'Normal (Sehat)').toString();
    final String audioLabel = (s['audio_label'] ?? 'Vokal Normal (Stabil)').toString();
    final String sketchLabel = (s['sketch_label'] ?? 'Pola Coretan Rileks & Kontinu').toString();
    final String gaitLabel = (s['gait_label'] ?? 'Langkah Stabil & Terkoordinasi').toString();

    String diagSummary = (s['diagnosis_summary'] ?? '').toString();
    if (diagSummary.isEmpty) {
      diagSummary = 'Mata: $eyeLabel ($visualScore%) • Suara: $audioLabel ($voiceScore%) • Sketsa: $sketchLabel ($sketchScore%) • Gait: $gaitLabel ($gaitScore%)';
    }

    String tips = 'Pertahankan ritme istirahat dan hidrasi yang teratur.';
    final recipes = s['ai_recipes'];
    if (recipes is List && recipes.isNotEmpty && recipes.first is Map) {
      tips = ((recipes.first as Map)['deskripsi_tugas'] ?? tips).toString();
    }

    return {
      'id': (s['id_skrining'] ?? '-').toString(),
      'date': date,
      'time': time,
      'category': category,
      'title': kategori,
      'score': avg,
      'badgeText': '$label • $avg/100',
      'accentColor': accent,
      'bgTint': tint,
      'textColor': text,
      'icon': icon,
      'summary': diagSummary,
      'details': {
        'suara': {'score': '$voiceScore%', 'desc': audioLabel},
        'gait': {'score': '$gaitScore%', 'desc': gaitLabel},
        'visual': {'score': '$visualScore%', 'desc': eyeLabel},
        'sketsa': {'score': '$sketchScore%', 'desc': sketchLabel},
      },
      'tips': tips,
    };
  }

  String get _averageScoreLabel {
    if (_history.isEmpty) return '-';
    final total = _history.fold<int>(0, (sum, item) => sum + (item['score'] as int));
    return '${(total / _history.length).round()} / 100';
  }

  String get _latestConditionLabel {
    if (_history.isEmpty) return '-';
    switch (_history.first['category']) {
      case 'healthy':
        return 'Prima ✓';
      case 'extreme':
        return 'Kritis';
      default:
        return 'Burnout';
    }
  }

  int _countCategory(String category) =>
      _history.where((item) => item['category'] == category).length;

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(child: CircularProgressIndicator(color: NeoColors.primaryBlue)),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: NeoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeoColors.borderBlack, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: NeoColors.redDark),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: NeoColors.darkGray,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          NeoButton(
            text: 'Coba Lagi',
            icon: Icons.refresh_rounded,
            backgroundColor: NeoColors.primaryBlue,
            textColor: NeoColors.white,
            onPressed: _loadHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildNoHistoryState() {
    return Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: NeoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeoColors.borderBlack, width: 2),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 40, color: NeoColors.darkGray),
          SizedBox(height: 8),
          Text(
            'Belum ada riwayat diagnosis. Lakukan tes pertama Anda hari ini!',
            textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final filtered = _history.where((item) {
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
              child: RefreshIndicator(
                onRefresh: _loadHistory,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  children: [
                    if (_isLoading)
                      _buildLoadingState()
                    else if (_error != null)
                      _buildErrorState()
                    else if (_history.isEmpty)
                      _buildNoHistoryState()
                    else ...[
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
                    ],

                    const SizedBox(height: 18),

                    // Bottom Button to trigger new screening
                    NeoButton(
                      text: "+ Skrining Baru Sekarang",
                      icon: Icons.add_chart_rounded,
                      backgroundColor: NeoColors.primaryBlue,
                      textColor: NeoColors.white,
                      onPressed: widget.onStartNewScreening ??
                          () => Navigator.pushNamed(context, '/stage1'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Riwayat Skrining',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.primaryBlue,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Rekapitulasi Multimodal AI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NeoColors.primaryBlue.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
                '${_history.length} Sesi',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.borderBlack,
                ),
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
          _buildStatColumn('Total Sesi', '${_history.length}', Icons.history_edu_rounded),
          Container(width: 1.5, height: 38, color: NeoColors.borderBlack.withValues(alpha: 0.15)),
          _buildStatColumn('Rata-rata Skor', _averageScoreLabel, Icons.analytics_outlined),
          Container(width: 1.5, height: 38, color: NeoColors.borderBlack.withValues(alpha: 0.15)),
          _buildStatColumn('Kondisi Terkini', _latestConditionLabel, Icons.verified_user_outlined),
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
      {'key': 'all', 'label': 'Semua (${_history.length})'},
      {'key': 'healthy', 'label': 'Prima (${_countCategory('healthy')})'},
      {'key': 'moderate', 'label': 'Burnout (${_countCategory('moderate')})'},
      {'key': 'extreme', 'label': 'Kritis (${_countCategory('extreme')})'},
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
    final Color accentColor = _resolveColor(item['accentColor'], NeoColors.primaryBlue);
    final Color bgTint = _resolveColor(item['bgTint'], NeoColors.lightGray);
    final Color textColor = _resolveColor(item['textColor'], NeoColors.black);
    final IconData icon = _resolveIcon(item['icon'], item['category']);

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
                  item['id'] ?? 'SCR-ID',
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
                child: Icon(icon, color: accentColor, size: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: NeoColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NeoColors.borderBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: NeoColors.borderBlack,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: NeoColors.borderBlack, width: 2),
            ),
            child: const Icon(
              Icons.assignment_late_outlined,
              size: 40,
              color: NeoColors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Belum ada riwayat diagnosis. Lakukan tes pertama Anda hari ini!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: NeoColors.black,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Hasil tes skrining multimodal AI Anda akan tercatat secara otomatis di sini.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: NeoColors.darkGray,
              fontSize: 12,
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
                            item['id'] ?? 'SCR-ID',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: NeoColors.darkGray,
                            ),
                          ),
                          Text(
                            item['title'] ?? 'Diagnosis AI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _resolveColor(item['textColor'], NeoColors.black),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _resolveColor(item['bgTint'], NeoColors.lightGray),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _resolveColor(item['accentColor'], NeoColors.primaryBlue), width: 1.5),
                        ),
                        child: Text(
                          'Skor ${item['score']}/100',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: _resolveColor(item['textColor'], NeoColors.black),
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
