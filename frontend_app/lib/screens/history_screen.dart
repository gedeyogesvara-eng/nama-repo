import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';

/// Layar Riwayat Skrining (Modern Clean)
/// Menampilkan rekapitulasi riwayat skrining dengan parsing warna & data aman,
/// kartu berlekuk halus (BorderRadius.circular(32)), shadow pudar lembut (blurRadius: 10-15),
/// aksen Deep Blue (#314BB5), dan kompatibilitas penuh dengan Dark Mode.
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
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color redCrit = Color(0xFFEF4444);

  String _selectedFilter = 'all'; // 'all', 'healthy', 'moderate', 'extreme'

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await HistoryService.getHistoryList(userId: userId);
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
        _error = 'Tidak dapat memuat riwayat skrining. Pastikan backend Go (port 8081) dan database menyala.';
      });
    }
  }

  /// Parser warna aman: Mencegah error "type 'int' is not a subtype of type 'Color'"
  Color _parseColor(dynamic value, {Color fallback = const Color(0xFF1E3A8A)}) {
    if (value == null) return fallback;
    if (value is Color) return value;
    if (value is int) return Color(value);
    final str = value.toString().replaceAll('#', '').trim();
    if (str.isEmpty) return fallback;
    final parsed = int.tryParse(str.startsWith('0x') ? str : '0xFF$str') ?? int.tryParse(str);
    return parsed != null ? Color(parsed) : fallback;
  }

  /// Parser ikon aman: Menghindari null icon atau type mismatch
  IconData _parseIcon(dynamic icon, dynamic codePoint, String? category) {
    if (icon is IconData) return icon;
    final int? cp = codePoint is int ? codePoint : int.tryParse('$codePoint');
    if (cp != null) {
      if (cp == Icons.sentiment_very_satisfied_rounded.codePoint) {
        return Icons.sentiment_very_satisfied_rounded;
      }
      if (cp == Icons.sentiment_satisfied_alt_rounded.codePoint) {
        return Icons.sentiment_satisfied_alt_rounded;
      }
      if (cp == Icons.error_outline_rounded.codePoint) {
        return Icons.error_outline_rounded;
      }
      if (cp == Icons.warning_amber_rounded.codePoint) {
        return Icons.warning_amber_rounded;
      }
      // ignore: non_const_argument_for_const_parameter
      return IconData(cp, fontFamily: 'MaterialIcons');
    }
    switch (category) {
      case 'healthy':
        return Icons.sentiment_very_satisfied_rounded;
      case 'extreme':
        return Icons.error_outline_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String get _averageScoreLabel {
    if (_history.isEmpty) return '-';
    final total = _history.fold<int>(0, (sum, item) {
      final s = item['score'];
      final scoreVal = s is num ? s.toInt() : (int.tryParse('$s') ?? 50);
      return sum + scoreVal;
    });
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
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: redCrit),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 0,
              ),
              onPressed: _loadHistory,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoHistoryState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 48,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat diagnosis. Lakukan tes pertama Anda hari ini!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    final filtered = _history.where((item) {
      if (_selectedFilter == 'all') return true;
      return item['category'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildHeaderBar(context, isDark, textTheme),

            // Content List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadHistory,
                color: primaryBlue,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  children: [
                    if (_isLoading)
                      _buildLoadingState()
                    else if (_error != null)
                      _buildErrorState(isDark)
                    else if (_history.isEmpty)
                      _buildNoHistoryState(isDark)
                    else ...[
                      // Stat Overview Banner (Modern Clean BorderRadius 32)
                      _buildStatBanner(isDark, textTheme),
                      const SizedBox(height: 18),

                      // Filter Chips
                      _buildFilterChips(isDark),
                      const SizedBox(height: 16),

                      // History Cards
                      if (filtered.isEmpty)
                        _buildEmptyState(isDark)
                      else
                        ...filtered.map((item) => _buildHistoryCard(context, item, isDark, textTheme)),
                    ],

                    const SizedBox(height: 20),

                    // Bottom Button: Skrining Baru
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: isDark ? 0.35 : 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_chart_rounded, size: 20),
                        label: const Text(
                          "+ Skrining Baru Sekarang",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        onPressed: widget.onStartNewScreening ??
                            () => Navigator.pushNamed(context, '/stage1'),
                      ),
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
  Widget _buildHeaderBar(BuildContext context, bool isDark, TextTheme textTheme) {
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: isDark ? Colors.white : primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Riwayat Skrining',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : primaryBlue,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Rekapitulasi Multimodal AI',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_history.length} Sesi',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: primaryBlue,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STAT OVERVIEW BANNER (MODERN CLEAN CARD BORDER-RADIUS 32) ---
  Widget _buildStatBanner(bool isDark, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Total Sesi', '${_history.length}', Icons.history_edu_rounded, isDark, textTheme),
          Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          _buildStatColumn('Rata-rata', _averageScoreLabel, Icons.analytics_outlined, isDark, textTheme),
          Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          _buildStatColumn('Terkini', _latestConditionLabel, Icons.verified_user_outlined, isDark, textTheme),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, bool isDark, TextTheme textTheme) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: primaryBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // --- FILTER CHIPS ---
  Widget _buildFilterChips(bool isDark) {
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
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryBlue
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- HISTORY CARD ITEM (MODERN CLEAN CARD BORDER-RADIUS 32) ---
  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item, bool isDark, TextTheme textTheme) {
    // Parsing warna secara aman menggunakan fallback Deep Blue
    final Color accentColor = _parseColor(item['accentColor'], fallback: primaryBlue);
    final Color bgTint = _parseColor(item['bgTint'], fallback: accentColor.withValues(alpha: isDark ? 0.22 : 0.1));
    final IconData statusIcon = _parseIcon(item['icon'], item['iconCodePoint'], item['category']?.toString());

    // Parsing data transaksi & string secara aman
    final String dateStr = (item['date'] ?? '-').toString();
    final String timeStr = (item['time'] ?? '').toString();
    final String dateTimeDisplay = timeStr.isNotEmpty ? '$dateStr • $timeStr' : dateStr;
    final String idStr = (item['id'] ?? 'SCR-00').toString();
    final String titleStr = (item['title'] ?? 'Skrining Selesai').toString();
    final String badgeStr = (item['badgeText'] ?? '${item['score'] ?? 0}/100').toString();
    final String summaryStr = (item['summary'] ?? '-').toString();

    final Map<String, dynamic> details = item['details'] is Map
        ? Map<String, dynamic>.from(item['details'] as Map)
        : {};

    String getMetric(String key) {
      final m = details[key];
      if (m is Map) return '${m['score'] ?? '-'}';
      return '-';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateTimeDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  idStr,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Row: Icon + Title + Score Badge
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleStr,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: bgTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeStr,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ringkasan Teks
          Text(
            summaryStr,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // 4 Micro Metrics Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMicroMetricPill('🎙️ Suara', getMetric('suara'), isDark),
              _buildMicroMetricPill('🚶 Gait', getMetric('gait'), isDark),
              _buildMicroMetricPill('👁️ Visual', getMetric('visual'), isDark),
              _buildMicroMetricPill('✏️ Sketsa', getMetric('sketsa'), isDark),
            ],
          ),
          const SizedBox(height: 16),

          // Action Button: Lihat Rincian
          InkWell(
            onTap: () => _showDetailBottomSheet(context, item, isDark, textTheme),
            borderRadius: BorderRadius.circular(32),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: isDark ? 0.22 : 0.08),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Analisis Lengkap',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: primaryBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroMetricPill(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada riwayat pada kategori ini.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- MODAL BOTTOM SHEET DETAIL ANALISIS (MODERN CLEAN) ---
  void _showDetailBottomSheet(BuildContext context, Map<String, dynamic> item, bool isDark, TextTheme textTheme) {
    final Map<String, dynamic> details = item['details'] is Map
        ? Map<String, dynamic>.from(item['details'] as Map)
        : {};

    final String dateStr = (item['date'] ?? '-').toString();
    final String timeStr = (item['time'] ?? '').toString();
    final String dateTimeDisplay = timeStr.isNotEmpty ? '$dateStr • $timeStr' : dateStr;
    final String idStr = (item['id'] ?? 'SCR-00').toString();
    final String titleStr = (item['title'] ?? 'Skrining Selesai').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(26.0),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header Modal
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleStr,
                              style: textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dateTimeDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          idStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Detail Metrik 4 Sensor
                  _buildDetailRow('🎙️ Nada Vokal (Audio)', details['suara'], isDark, textTheme),
                  _buildDetailRow('🚶 Dinamika Gait (Langkah)', details['gait'], isDark, textTheme),
                  _buildDetailRow('👁️ Mikrosleep & Sklera', details['visual'], isDark, textTheme),
                  _buildDetailRow('✏️ Ritme Motorik (Sketsa)', details['sketsa'], isDark, textTheme),

                  const SizedBox(height: 22),

                  // Tombol Tutup
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: isDark ? 0.35 : 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup Analisis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, dynamic dataRaw, bool isDark, TextTheme textTheme) {
    final Map<String, dynamic> data = dataRaw is Map ? Map<String, dynamic>.from(dataRaw) : {};
    final String scoreStr = (data['score'] ?? '-').toString();
    final String descStr = (data['desc'] ?? data['diagnosis'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  scoreStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            descStr,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
