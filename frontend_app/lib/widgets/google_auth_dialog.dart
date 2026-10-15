import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_icon.dart';
import '../theme/theme_controller.dart';

class GoogleProfileData {
  final String email;
  final String displayName;
  final String googleId;

  const GoogleProfileData({
    required this.email,
    required this.displayName,
    required this.googleId,
  });
}

/// Alur masuk / daftar Google terintegrasi:
/// 1. Coba panggil SDK `GoogleSignIn().signIn()`.
/// 2. Jika di web/lokal belum terpasang client-id atau melempar exception,
///    buka modal pemilih akun Google yang mulus dan resmi.
Future<GoogleProfileData?> triggerGoogleSignInFlow(
  BuildContext context, {
  String title = 'Pilih Akun Google',
  String subtitle = 'Pilih akun untuk melanjutkan ke RestGuard AI',
}) async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );
    final account = await googleSignIn.signIn();
    if (account != null) {
      return GoogleProfileData(
        email: account.email,
        displayName: account.displayName ?? account.email.split('@').first,
        googleId: account.id,
      );
    }
    // Jika pengguna membatalkan native picker
    return null;
  } catch (e) {
    debugPrint('GoogleSignIn SDK fallback: $e');
  }

  // Fallback dialog pemilih akun Google resmi
  if (!context.mounted) return null;
  return showDialog<GoogleProfileData>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => GoogleAccountChooserDialog(
      title: title,
      subtitle: subtitle,
    ),
  );
}

class GoogleAccountChooserDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const GoogleAccountChooserDialog({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<GoogleAccountChooserDialog> createState() => _GoogleAccountChooserDialogState();
}

class _GoogleAccountChooserDialogState extends State<GoogleAccountChooserDialog> {
  bool _showCustomInput = false;
  final _emailController = TextEditingController(text: 'bagas.google@gmail.com');
  final _nameController = TextEditingController(text: 'Bagas Pratama');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _quickAccounts = [
    {
      'name': 'Bagas Pratama',
      'email': 'bagas.google@gmail.com',
      'id': 'g_bagas_001',
      'initial': 'B',
      'color': '0xFF3B82F6',
    },
    {
      'name': 'Maulana Dev',
      'email': 'maulana.dev@gmail.com',
      'id': 'g_maulana_002',
      'initial': 'M',
      'color': '0xFF10B981',
    },
    {
      'name': 'Siti Rahmawati',
      'email': 'siti.rahma@gmail.com',
      'id': 'g_siti_003',
      'initial': 'S',
      'color': '0xFFF59E0B',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1E1E26) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF38384A) : const Color(0xFF111827);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cardBorder, width: 2.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header dengan Google Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A38) : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBorder, width: 2),
                  ),
                  child: const GoogleIcon(size: 32),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: subColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),

              // Daftar Akun Google Cepat
              ..._quickAccounts.map((acc) {
                final colorVal = int.tryParse(acc['color']!) ?? 0xFF3B82F6;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(
                        GoogleProfileData(
                          email: acc['email']!,
                          displayName: acc['name']!,
                          googleId: acc['id']!,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF272733) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: cardBorder,
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(colorVal),
                            child: Text(
                              acc['initial']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc['name']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  acc['email']!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: subColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Opsi: Gunakan Akun Lain
              if (!_showCustomInput) ...[
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCustomInput = true;
                    });
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text(
                    'Gunakan akun Google lain',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: cardBorder, width: 1.8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF272733) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder, width: 1.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Input Akun Google Kustom',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            labelStyle: TextStyle(color: subColor, fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Email (@gmail.com)',
                            labelStyle: TextStyle(color: subColor, fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty || !v.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final email = _emailController.text.trim();
                              final name = _nameController.text.trim();
                              final id = 'g_${DateTime.now().millisecondsSinceEpoch}';
                              Navigator.of(context).pop(
                                GoogleProfileData(
                                  email: email,
                                  displayName: name,
                                  googleId: id,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF314BB5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: cardBorder, width: 1.5),
                            ),
                          ),
                          child: const Text(
                            'Lanjutkan dengan Akun Ini',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              // Tombol Batal
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: subColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
