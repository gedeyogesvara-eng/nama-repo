import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../theme/theme_controller.dart';

/// Layar Resep Anti-Zombi (Modern Clean)
/// Menampilkan daftar intervensi & resep pemulihan harian dari MySQL (via Go backend)
/// dengan kartu melengkung 24-32, shadow transparan halus, Deep Blue (#314BB5),
/// dan kompatibilitas penuh dengan Dark Mode.
class AntiZombieRecipeScreen extends StatefulWidget {
  const AntiZombieRecipeScreen({super.key});

  @override
  State<AntiZombieRecipeScreen> createState() => _AntiZombieRecipeScreenState();
}

class _AntiZombieRecipeScreenState extends State<AntiZombieRecipeScreen> {
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color greenDone = Color(0xFF10B981);

  bool _isLoading = true;
  bool _isToggling = false;
  List<Map<String, dynamic>> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await authService.refreshProfile();
    List<Map<String, dynamic>> active = [];
    if (data != null && data['active_recipes'] is List) {
      active = (data['active_recipes'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (mounted) {
      setState(() {
        _recipes = active;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRecipe(Map<String, dynamic> recipe) async {
    if (_isToggling) return;
    final int? recipeId = recipe['id'] is num
        ? (recipe['id'] as num).toInt()
        : int.tryParse('${recipe['id']}');
    if (recipeId == null) return;

    final bool currentStatus = recipe['is_completed'] == true;
    final bool newStatus = !currentStatus;

    // Optimistic UI update
    setState(() {
      recipe['is_completed'] = newStatus;
      _isToggling = true;
    });

    try {
      final res = await BackendService.setRecipeCompleted(recipeId, newStatus);
      if (res != null) {
        await _loadData();
      }
    } catch (e) {
      debugPrint('Error toggling recipe: $e');
      if (mounted) {
        setState(() {
          recipe['is_completed'] = currentStatus;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  void _showAddCustomRecipeDialog() {
    final textController = TextEditingController();
    String selectedCategory = 'Fisik';
    final categories = ['Fisik', 'Mental', 'Istirahat', 'Nutrisi', 'Mandiri'];
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = themeController.isDarkMode;
        final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
        final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 12,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medication_liquid_rounded, color: primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tambah Resep Mandiri',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textCol,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tulis aktivitas pemulihan kustom yang ingin Anda selesaikan hari ini:',
                      style: TextStyle(fontSize: 12, color: subCol, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      maxLines: 2,
                      style: TextStyle(color: textCol, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Misal: Istirahat mata 15 menit, jalan santai 1000 langkah...',
                        hintStyle: TextStyle(color: subCol.withValues(alpha: 0.7), fontSize: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryBlue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kategori Pemulihan:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: categories.map((cat) {
                        final isSel = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                            ),
                          ),
                          selected: isSel,
                          selectedColor: primaryBlue,
                          backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: isSel ? primaryBlue : Colors.transparent,
                            ),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() => selectedCategory = cat);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Batal', style: TextStyle(color: subCol, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final text = textController.text.trim();
                          if (text.isEmpty) return;

                          final userId = authService.currentUserId;
                          if (userId == null) return;

                          setDialogState(() => isSubmitting = true);
                          final res = await BackendService.addCustomRecipe(
                            userId: userId,
                            deskripsi: text,
                            jenis: selectedCategory,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!mounted) return;

                          if (res != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Resep mandiri berhasil ditambahkan ke daftar tugas harian!',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                backgroundColor: greenDone,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            await _loadData();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Resep', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final completedCount = _recipes.where((r) => r['is_completed'] == true).length;
    final totalCount = _recipes.length;
    final double progress = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: cardBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : primaryBlue, size: 18),
              ),
            ),
          ),
        ),
        title: Text(
          'Resep Anti-Zombi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : primaryBlue,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBlue)))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. BANNER STATUS PEMULIHAN (MODERN CLEAN CARD)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.healing_rounded, color: primaryBlue, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Target Pemulihan Harian',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: textCol,
                                            ),
                                          ),
                                          Text(
                                            'Tiap resep selesai memberi +15 skor pemulihan',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: subCol,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: greenDone.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '$completedCount / $totalCount Selesai',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                          color: greenDone,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 10,
                                    backgroundColor: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9),
                                    valueColor: const AlwaysStoppedAnimation<Color>(greenDone),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // 2. HEADER DAFTAR RESEP & TOMBOL TAMBAH
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Daftar Resep Aktif',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textCol,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showAddCustomRecipeDialog,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Resep Mandiri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // 3. DAFTAR KARTU RESEP (RESPONSIF, MODERN CLEAN)
                          if (_recipes.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.task_alt_rounded, size: 48, color: primaryBlue),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum Ada Resep Aktif',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: textCol,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Jalankan skrining AI di Beranda atau tekan tombol "+ Resep Mandiri" di atas untuk menambahkan resep pemulihan pertama Anda.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: subCol, height: 1.4),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recipes.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final recipe = _recipes[index];
                                final isDone = recipe['is_completed'] == true;
                                final String jenis = recipe['jenis_intervensi']?.toString() ?? 'Mandiri';
                                final String deskripsi = recipe['deskripsi_tugas']?.toString() ?? '-';

                                return InkWell(
                                  onTap: () => _toggleRecipe(recipe),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? (isDark ? const Color(0xFF161616) : const Color(0xFFF8FAFC))
                                          : cardBg,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Modern Checkbox
                                        Container(
                                          width: 26,
                                          height: 26,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: isDone ? greenDone : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isDone
                                                  ? greenDone
                                                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                              width: 2,
                                            ),
                                          ),
                                          child: isDone
                                              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 14),
                                        // Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                spacing: 8,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isDone
                                                          ? greenDone.withValues(alpha: 0.15)
                                                          : primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      jenis,
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDone ? greenDone : primaryBlue,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isDone)
                                                    const Text(
                                                      '+15 Poin Pemulihan',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: greenDone,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                deskripsi,
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDone ? subCol : textCol,
                                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 24),

                          // Tombol Tambah Resep Mandiri Bawah (Modern Clean BorderRadius 32)
                          SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                              label: const Text(
                                "+ Tambah Resep Mandiri Baru",
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
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
                                shadowColor: primaryBlue.withValues(alpha: 0.35),
                              ),
                              onPressed: _showAddCustomRecipeDialog,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
