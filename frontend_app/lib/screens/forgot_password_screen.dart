import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color scaffoldBg = Color(0xFFF2F1EB);
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color accentYellow = Color(0xFFFFC436);
  static const Color darkBorder = Color(0xFF111827);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authService.resetPassword(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        // Tampilkan SnackBar sukses sesuai spesifikasi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Tautan terkirim ke email Anda!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669), // Green Neo
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: darkBorder, width: 2),
            ),
          ),
        );

        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Gagal mengirim tautan reset. Periksa kembali email Anda.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: darkBorder, width: 2),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceFirst("Exception: ", "").trim();
        if (msg == "Error" || msg.isEmpty) {
          msg = "Gagal mengirim tautan reset. Silakan coba kembali.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: darkBorder, width: 2),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tombol Back di Pojok Kiri Atas
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildBackButton(context),
                        ),
                        const SizedBox(height: 24),

                        // Card Mini Icon Ilustrasi Kunci / Email
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: accentYellow,
                              shape: BoxShape.circle,
                              border: Border.all(color: darkBorder, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: darkBorder,
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lock_reset_rounded,
                                size: 40,
                                color: darkBorder,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Judul "Reset Kata Sandi"
                        const Text(
                          "Reset Kata Sandi",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: darkBorder,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Deskripsi
                        const Text(
                          "Masukkan email Anda untuk menerima tautan reset password.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Label Email
                        const Text(
                          "Alamat Email Terdaftar",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: darkBorder,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Input Email (Clean, rounded, white fill, thin border, NO thick black border)
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkBorder,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Email tidak boleh kosong";
                            }
                            if (!value.contains("@") || !value.contains(".")) {
                              return "Format email tidak valid";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "nama@contoh.com",
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: primaryBlue,
                                width: 1.8,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFEF4444),
                                width: 1.4,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFDC2626),
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Tombol Utama "Kirim Tautan Reset"
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: darkBorder,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              onTap: _isLoading ? null : _handleResetPassword,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: darkBorder,
                                    width: 2.2,
                                  ),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.send_rounded,
                                              color: Colors.white,
                                              size: 19,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Kirim Tautan Reset",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tombol Batal / Kembali ke Login
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            label: const Text(
                              "Kembali ke Halaman Masuk",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: darkBorder, width: 2),
        boxShadow: const [
          BoxShadow(
            color: darkBorder,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Icon(
              Icons.arrow_back_rounded,
              color: darkBorder,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
