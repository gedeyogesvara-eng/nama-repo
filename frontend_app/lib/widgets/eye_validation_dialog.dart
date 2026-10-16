import 'package:flutter/material.dart';
import '../services/eye_analysis_service.dart';

/// Komponen UI interaktif untuk menampilkan pesan feedback saat foto mata tidak memenuhi syarat
/// (terlalu gelap, hitam total, atau mata tidak terdeteksi oleh AI).
class EyeValidationDialog extends StatelessWidget {
  final EyeAnalysisResult result;
  final VoidCallback onRetake;
  final VoidCallback? onCancel;

  const EyeValidationDialog({
    super.key,
    required this.result,
    required this.onRetake,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryBlue = theme.colorScheme.primary;

    // Tentukan ikon dan warna aksen sesuai jenis kegagalan
    final IconData iconData;
    final Color accentColor;
    if (result.isTooDark) {
      iconData = Icons.lightbulb_outline_rounded;
      accentColor = const Color(0xFFFF9F1C); // Amber/Oranye untuk pencahayaan
    } else if (result.isEyeNotDetected) {
      iconData = Icons.visibility_off_rounded;
      accentColor = const Color(0xFFE63946); // Merah untuk mata tidak terdeteksi
    } else {
      iconData = Icons.warning_amber_rounded;
      accentColor = const Color(0xFFF4A261);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Ikon dengan Glow Lembut
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.28),
                  width: 2,
                ),
              ),
              child: Icon(
                iconData,
                size: 38,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 18),

            // Judul Masalah
            Text(
              result.feedbackTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Deskripsi & Instruksi Perbaikan
            Text(
              result.feedbackInstruction,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.45,
                color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 20),

            // Tips Praktis Checklist Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E4F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Tips Foto yang Optimal:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTipItem(
                    isDark,
                    result.isTooDark
                        ? 'Hadapkan wajah ke lampu atau cahaya matahari langsung.'
                        : 'Posisikan lensa tepat sejajar dengan pandangan mata.',
                  ),
                  _buildTipItem(
                    isDark,
                    'Buka mata dengan rileks dan lepas kacamata jika memantul.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Aksi: Ambil Ulang Foto (Utama) & Batal
            Row(
              children: [
                if (onCancel != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF3E3E3E) : const Color(0xFFD0D0D0),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onRetake,
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text(
                      'Ambil Ulang',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: isDark ? const Color(0xFF718096) : const Color(0xFF4A5568),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF4A5568),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function untuk memunculkan Dialog Validasi Mata secara elegan
Future<void> showEyeValidationErrorDialog(
  BuildContext context,
  EyeAnalysisResult result, {
  required VoidCallback onRetake,
  VoidCallback? onCancel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return EyeValidationDialog(
        result: result,
        onRetake: () {
          Navigator.of(dialogContext).pop();
          onRetake();
        },
        onCancel: () {
          Navigator.of(dialogContext).pop();
          onCancel?.call();
        },
      );
    },
  );
}

/// Helper function untuk menampilkan SnackBar Peringatan Foto Mata
void showEyeValidationErrorSnackBar(
  BuildContext context,
  EyeAnalysisResult result,
) {
  final isTooDark = result.isTooDark;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: isTooDark ? const Color(0xFFD97706) : const Color(0xFFDC2626),
      content: Row(
        children: [
          Icon(
            isTooDark ? Icons.lightbulb_outline_rounded : Icons.visibility_off_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.feedbackInstruction,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}
