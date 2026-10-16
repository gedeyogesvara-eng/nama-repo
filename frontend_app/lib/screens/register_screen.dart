import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/google_icon.dart';
import '../widgets/google_auth_dialog.dart';
import '../theme/theme_controller.dart';
import 'login_screen.dart';

/// Layar Registrasi (Register)
/// Didesain dengan gaya 'Modern Clean':
/// - Bebas dari garis pinggir hitam tebal (Neubrutalism) & bayangan kaku
/// - Sudut melengkung halus (BorderRadius.circular(32)) pada seluruh input & tombol
/// - Tombol utama Deep Blue (#314BB5) dengan bayangan halus & transparan
/// - Ikon outline minimalis pada setiap kolom input
/// - Kompatibel penuh dengan Mode Terang & Gelap
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color primaryBlue = Color(0xFF314BB5);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        name: _nameController.text.trim(),
        autoLogin: false,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          message:
              "Registrasi berhasil! Silakan masuk menggunakan akun yang baru Anda daftarkan.",
          isSuccess: true,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceFirst("Exception: ", "").trim();
        if (msg == "Error" || msg.isEmpty) {
          msg = "Gagal mendaftar. Silakan periksa kembali data Anda.";
        }
        _showSnackBar(
          message: msg,
          isError: true,
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

  Future<void> _handleGoogleRegister() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final googleUser = await triggerGoogleSignInFlow(
        context,
        title: "Daftar dengan Google",
        subtitle: "Pilih atau masukkan akun Google untuk mendaftar",
      );

      if (googleUser == null) {
        return;
      }

      final success = await authService.loginWithGoogleAccount(
        email: googleUser.email,
        name: googleUser.displayName,
        googleId: googleUser.googleId,
        setSession: false,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          message:
              "Akun Google ${googleUser.email} berhasil terdaftar dan masuk!",
          isSuccess: true,
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceFirst("Exception: ", "").trim();
        if (msg == "Error" || msg.isEmpty) {
          msg = "Gagal mendaftar dengan Google. Silakan coba kembali.";
        }
        _showSnackBar(
          message: msg,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _showSnackBar(
      {required String message, bool isError = false, bool isSuccess = false}) {
    Color bg = primaryBlue;
    if (isError) bg = const Color(0xFFEF4444);
    if (isSuccess) bg = const Color(0xFF10B981);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor: bg,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark || themeController.isDarkMode;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tombol Back Melingkar Modern Clean
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildBackButton(context, isDark),
                    ),
                    const SizedBox(height: 24),

                    // Tag Registrasi Modern Clean
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(
                              alpha: isDark ? 0.25 : 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_outlined,
                                size: 14, color: primaryBlue),
                            SizedBox(width: 6),
                            Text(
                              "REGISTRASI AKUN",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header Judul
                    Text(
                      "Buat Akun Baru",
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Daftar sekarang untuk memulai proteksi dini terhadap kelelahan dan stres kerja.",
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Input 1: Nama Lengkap
                    _buildFieldLabel("Nama Lengkap", isDark),
                    const SizedBox(height: 8),
                    _buildModernTextField(
                      controller: _nameController,
                      hintText: "Contoh: Budi Santoso",
                      prefixIcon: Icons.person_outline_rounded,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Nama lengkap tidak boleh kosong";
                        }
                        if (value.trim().length < 2) {
                          return "Nama terlalu pendek";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Input 2: Email
                    _buildFieldLabel("Alamat Email", isDark),
                    const SizedBox(height: 8),
                    _buildModernTextField(
                      controller: _emailController,
                      hintText: "nama@contoh.com",
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Email tidak boleh kosong";
                        }
                        if (!value.contains("@") || !value.contains(".")) {
                          return "Format email tidak valid";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Input 3: Kata Sandi
                    _buildFieldLabel("Kata Sandi", isDark),
                    const SizedBox(height: 8),
                    _buildModernTextField(
                      controller: _passwordController,
                      hintText: "Minimal 6 karakter",
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      isDark: isDark,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Kata sandi tidak boleh kosong";
                        }
                        if (value.length < 6) {
                          return "Kata sandi minimal 6 karakter";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Input 4: Konfirmasi Kata Sandi
                    _buildFieldLabel("Konfirmasi Kata Sandi", isDark),
                    const SizedBox(height: 8),
                    _buildModernTextField(
                      controller: _confirmPasswordController,
                      hintText: "Ulangi kata sandi",
                      prefixIcon: Icons.verified_user_outlined,
                      obscureText: _obscureConfirmPassword,
                      isDark: isDark,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Konfirmasi kata sandi diperlukan";
                        }
                        if (value != _passwordController.text) {
                          return "Kata sandi tidak cocok";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Tombol Utama "Daftar Sekarang" (Deep Blue, Radius 32, Soft Shadow)
                    _buildModernActionButton(
                      text: "Daftar Sekarang",
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // Divider "ATAU"
                    _buildModernOrDivider(isDark),
                    const SizedBox(height: 24),

                    // Tombol "Daftar dengan Google"
                    _buildGoogleButton(isDark),
                    const SizedBox(height: 32),

                    // Link Menuju Layar Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Sudah memiliki akun? ",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Masuk di Sini",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Label Form
  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
      ),
    );
  }

  // Tombol Back Modern Clean Melingkar
  Widget _buildBackButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : primaryBlue,
          size: 18,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
    );
  }

  // Kolom Input Modern Clean dengan Radius 32 & Ikon Outline
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Icon(
              prefixIcon,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: suffixIcon,
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF2C2C35) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: primaryBlue,
              width: 1.8,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: Color(0xFFEF4444),
              width: 1.4,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: Color(0xFFDC2626),
              width: 1.8,
            ),
          ),
        ),
      ),
    );
  }

  // Tombol Utama Modern Clean
  Widget _buildModernActionButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
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
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  // Divider "ATAU"
  Widget _buildModernOrDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? const Color(0xFF2C2C35) : const Color(0xFFE2E8F0),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E26) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              "ATAU",
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? const Color(0xFF2C2C35) : const Color(0xFFE2E8F0),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // Tombol "Daftar dengan Google"
  Widget _buildGoogleButton(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C35) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: _isGoogleLoading ? null : _handleGoogleRegister,
          child: Center(
            child: _isGoogleLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleIcon(size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "Daftar dengan Google",
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
