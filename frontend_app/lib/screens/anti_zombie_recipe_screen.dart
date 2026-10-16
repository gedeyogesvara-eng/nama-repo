import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../services/notification_service.dart';
import '../theme/theme_controller.dart';

/// Layar Goals Pemulihan (Modern Clean)
/// Menampilkan daftar intervensi & target goals pemulihan harian dari Supabase / backend
/// dengan kartu berlekuk halus (BorderRadius.circular(32)), shadow transparan lembut,
/// aksen Deep Blue (#314BB5), ikon target outline minimalis, dan kompatibilitas penuh Dark Mode.
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
  Map<String, String> _activeReminders = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('goal_reminder_time_'));
      final Map<String, String> reminders = {};
      for (final k in keys) {
        final goalId = k.replaceFirst('goal_reminder_time_', '');
        final timeStr = prefs.getString(k);
        if (timeStr != null) {
          reminders[goalId] = timeStr;
        }
      }
      if (mounted) {
        setState(() {
          _activeReminders = reminders;
        });
      }
    } catch (_) {}
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

  Future<void> _handleToggleGoalReminder(Map<String, dynamic> recipe) async {
    final int goalId = recipe['id'] is num
        ? (recipe['id'] as num).toInt()
        : int.tryParse('${recipe['id']}') ?? 1;
    final String key = '$goalId';
    final String deskripsi = recipe['deskripsi_tugas']?.toString() ?? 'Rutinitas Goal';
    final isReminderActive = _activeReminders.containsKey(key);

    if (isReminderActive) {
      final bool? shouldTurnOff = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final isDark = themeController.isDarkMode;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: primaryBlue, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pengingat Goal Aktif',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: Text(
              "Pengingat untuk '$deskripsi' saat ini aktif pukul ${_activeReminders[key]}.\n\nApakah Anda ingin mematikan pengingat ini atau mengubah jamnya?",
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Ubah Jam', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Matikan Pengingat', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      );

      if (shouldTurnOff == null || !mounted) return;

      if (shouldTurnOff) {
        await notificationService.cancelGoalReminder(goalId);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('goal_reminder_time_$key');
        } catch (_) {}

        setState(() {
          _activeReminders.remove(key);
        });

        if (!mounted) return;
        final isDark = themeController.isDarkMode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Pengingat untuk goal '$deskripsi' dinonaktifkan.",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
        return;
      }
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'ATUR JAM PENGINGAT GOAL',
      confirmText: 'AKTIFKAN',
      cancelText: 'BATAL',
    );

    if (pickedTime == null || !mounted) return;

    await notificationService.scheduleGoalReminder(
      goalId: goalId,
      goalTitle: deskripsi,
      time: pickedTime,
    );

    final timeStr =
        "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')} WIB";
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('goal_reminder_time_$key', timeStr);
    } catch (_) {}

    setState(() {
      _activeReminders[key] = timeStr;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Waktunya menyelesaikan goals pemulihanmu hari ini! Pengingat aktif jam $timeStr.",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 4),
      ),
    );
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
      debugPrint('Error toggling goal status: $e');
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
                borderRadius: BorderRadius.circular(32),
              ),
              elevation: 12,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flag_outlined, color: primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tambah Target Goal',
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
                      'Tulis aktivitas atau target pemulihan yang ingin Anda capai hari ini:',
                      style: TextStyle(fontSize: 12.5, color: subCol, fontWeight: FontWeight.w500, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: textController,
                      maxLines: 2,
                      style: TextStyle(color: textCol, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Misal: Istirahat mata 15 menit, jalan santai 1000 langkah...',
                        hintStyle: TextStyle(color: subCol.withValues(alpha: 0.7), fontSize: 12.5),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: primaryBlue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kategori Target Goal:',
                      style: TextStyle(
                        fontSize: 12.5,
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
                              fontSize: 11.5,
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
                                  'Target goal baru berhasil ditambahkan ke daftar pemulihan!',
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Goal', style: TextStyle(fontWeight: FontWeight.w700)),
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
    final isDark = theme.brightness == Brightness.dark || themeController.isDarkMode;
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
          'Goals Pemulihanmu',
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
                          // 1. BANNER TARGET GOALS PEMULIHAN (MODERN CLEAN CARD BORDER-RADIUS 32)
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.07),
                                  blurRadius: 22,
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
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(Icons.track_changes_outlined, color: primaryBlue, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Target Goals Harian',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15.5,
                                              color: textCol,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tiap goal tercapai memberi +15 skor pemulihan',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: subCol,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: greenDone.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '$completedCount / $totalCount Tercapai',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: greenDone,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
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

                          const SizedBox(height: 24),

                          // 2. HEADER DAFTAR GOALS & TOMBOL TAMBAH
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Daftar Target Goals',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: textCol,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showAddCustomRecipeDialog,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Goal Mandiri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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

                          // 3. DAFTAR KARTU TARGET GOALS (MODERN CLEAN BORDER-RADIUS 32)
                          if (_recipes.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(32),
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
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.track_changes_outlined, size: 44, color: primaryBlue),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum Ada Target Goals',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: textCol,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Jalankan skrining AI di Beranda atau tekan tombol "+ Goal Mandiri" di atas untuk menambahkan target pemulihan pertama Anda.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12.5, color: subCol, height: 1.45),
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
                                final int goalId = recipe['id'] is num
                                    ? (recipe['id'] as num).toInt()
                                    : int.tryParse('${recipe['id']}') ?? (index + 1);
                                final String goalKey = '$goalId';
                                final bool isReminderActive = _activeReminders.containsKey(goalKey);

                                return InkWell(
                                  onTap: () => _toggleRecipe(recipe),
                                  borderRadius: BorderRadius.circular(32),
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? (isDark ? const Color(0xFF161616) : const Color(0xFFF8FAFC))
                                          : cardBg,
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Modern Goal Checkbox
                                        Container(
                                          width: 28,
                                          height: 28,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: isDone ? greenDone : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isDone
                                                  ? greenDone
                                                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                              width: 1.8,
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
                                                    const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.stars_rounded, size: 14, color: greenDone),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          '+15 Poin Pemulihan',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w700,
                                                            color: greenDone,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                deskripsi,
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDone ? subCol : textCol,
                                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              InkWell(
                                                onTap: () => _handleToggleGoalReminder(recipe),
                                                borderRadius: BorderRadius.circular(20),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: isReminderActive
                                                        ? primaryBlue.withValues(alpha: isDark ? 0.3 : 0.12)
                                                        : (isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9)),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: isReminderActive
                                                          ? primaryBlue.withValues(alpha: 0.5)
                                                          : (isDark ? const Color(0xFF383838) : const Color(0xFFE2E8F0)),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isReminderActive
                                                            ? Icons.notifications_active_rounded
                                                            : Icons.notifications_none_rounded,
                                                        size: 14,
                                                        color: isReminderActive ? primaryBlue : subCol,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        isReminderActive
                                                            ? "Pengingat: ${_activeReminders[goalKey]}"
                                                            : "Set Pengingat",
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: isReminderActive ? primaryBlue : subCol,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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

                          const SizedBox(height: 26),

                          // Tombol Tambah Goal Mandiri Bawah (Modern Clean Deep Blue, BorderRadius 32, Soft Shadow)
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: isDark ? 0.4 : 0.28),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_task_rounded, size: 20),
                              label: const Text(
                                "+ Tambah Target Goal Baru",
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
                              onPressed: _showAddCustomRecipeDialog,
                            ),
                          ),
                          const SizedBox(height: 24),
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
