import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../theme/theme_controller.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';

class AntiZombieRecipeScreen extends StatefulWidget {
  const AntiZombieRecipeScreen({super.key});

  @override
  State<AntiZombieRecipeScreen> createState() => _AntiZombieRecipeScreenState();
}

class _AntiZombieRecipeScreenState extends State<AntiZombieRecipeScreen> {
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color primaryYellow = Color(0xFFFFC436);
  static const Color darkBorder = Color(0xFF111827);
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

    // Optimistic UI
    setState(() {
      recipe['is_completed'] = newStatus;
      _isToggling = true;
    });

    try {
      final res = await BackendService.setRecipeCompleted(recipeId, newStatus);
      if (res != null) {
        // Refresh profile data from MySQL
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
        final dialogBg = isDark ? const Color(0xFF1E1E26) : Colors.white;
        final textCol = isDark ? Colors.white : const Color(0xFF111827);
        final subCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: darkBorder, width: 2.5),
              ),
              title: Row(
                children: [
                  const Icon(Icons.medication_liquid_rounded, color: primaryBlue, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Tambah Resep Mandiri',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: textCol,
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
                      style: TextStyle(fontSize: 12, color: subCol, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      maxLines: 2,
                      style: TextStyle(color: textCol, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Misal: Istirahat mata 15 menit, jalan kaki 1000 langkah...',
                        hintStyle: TextStyle(color: subCol, fontSize: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF282836) : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: darkBorder, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: darkBorder, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryBlue, width: 2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Kategori Pemulihan:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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
                              fontWeight: FontWeight.w800,
                              color: isSel ? darkBorder : textCol,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: primaryYellow,
                          backgroundColor: isDark ? const Color(0xFF282836) : const Color(0xFFE5E7EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSel ? darkBorder : Colors.transparent,
                              width: 1.5,
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
                  child: Text('Batal', style: TextStyle(color: subCol, fontWeight: FontWeight.w700)),
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
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: Color(0xFF10B981),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            await _loadData();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: darkBorder, width: 2),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Resep', style: TextStyle(fontWeight: FontWeight.w800)),
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
    final isDark = themeController.isDarkMode;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF2F1EB);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF111827);
    final subCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563);

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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: darkBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(color: darkBorder, offset: Offset(2, 2)),
                  ],
                ),
                child: Icon(Icons.arrow_back_rounded, color: textCol, size: 20),
              ),
            ),
          ),
        ),
        title: Text(
          'Resep Anti-Zombi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textCol,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryBlue))
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
                          // 1. BANNER STATUS PEMULIHAN
                          NeoCard(
                            backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
                            borderRadius: 20,
                            shadowOffset: 4,
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryYellow,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: darkBorder, width: 2),
                                      ),
                                      child: const Text('💊', style: TextStyle(fontSize: 20)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Target Pemulihan Harian',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                              color: textCol,
                                            ),
                                          ),
                                          Text(
                                            'Tiap resep selesai memberi +15 skor pemulihan MySQL',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
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
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: greenDone, width: 1.5),
                                      ),
                                      child: Text(
                                        '$completedCount / $totalCount Selesai',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: greenDone,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 12,
                                    backgroundColor: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB),
                                    valueColor: const AlwaysStoppedAnimation<Color>(greenDone),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2. HEADER DAFTAR RESEP & TOMBOL TAMBAH
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Daftar Resep Aktif',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: textCol,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showAddCustomRecipeDialog,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Resep Mandiri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryYellow,
                                  foregroundColor: darkBorder,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: darkBorder, width: 1.8),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // 3. DAFTAR KARTU RESEP (RESPONSIF, NO OVERFLOW)
                          if (_recipes.isEmpty)
                            NeoCard(
                              backgroundColor: cardBg,
                              borderRadius: 18,
                              shadowOffset: 3,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.task_alt_rounded, size: 48, color: primaryBlue),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum Ada Resep Aktif',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: textCol,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Jalankan skrining AI di Home atau tekan tombol "+ Resep Mandiri" di atas untuk menambahkan resep pemulihan pertama Anda.',
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
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final recipe = _recipes[index];
                                final isDone = recipe['is_completed'] == true;
                                final String jenis = recipe['jenis_intervensi']?.toString() ?? 'Mandiri';
                                final String deskripsi = recipe['deskripsi_tugas']?.toString() ?? '-';

                                return InkWell(
                                  onTap: () => _toggleRecipe(recipe),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? (isDark ? const Color(0xFF142E20) : const Color(0xFFF0FDF4))
                                          : cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDone ? greenDone : darkBorder,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDone ? greenDone.withValues(alpha: 0.5) : darkBorder,
                                          offset: const Offset(3, 3),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Custom Neobrutalist Checkbox
                                        Container(
                                          width: 26,
                                          height: 26,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: isDone ? greenDone : (isDark ? const Color(0xFF282836) : Colors.white),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isDone ? greenDone : darkBorder,
                                              width: 2,
                                            ),
                                          ),
                                          child: isDone
                                              ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
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
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isDone
                                                          ? greenDone.withValues(alpha: 0.2)
                                                          : primaryBlue.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      jenis,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w800,
                                                        color: isDone ? greenDone : primaryBlue,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isDone)
                                                    const Text(
                                                      '+15 Poin Pemulihan',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
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
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDone
                                                      ? subCol
                                                      : textCol,
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

                          // Tombol Tambah Resep Mandiri Bawah (Pill Neobrutalism)
                          NeoButton(
                            text: "+ Tambah Resep Mandiri Baru",
                            icon: Icons.add_circle_outline_rounded,
                            backgroundColor: primaryBlue,
                            textColor: Colors.white,
                            height: 52,
                            borderRadius: 26,
                            shadowOffset: 4,
                            onPressed: _showAddCustomRecipeDialog,
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
