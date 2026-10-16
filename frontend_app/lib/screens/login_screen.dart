import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/google_icon.dart';
import '../widgets/google_auth_dialog.dart';
import '../theme/theme_controller.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Layar Masuk (Login)
/// Didesain dengan gaya 'Modern Clean':
/// - Bebas dari garis hitam tebal (Neubrutalism) & bayangan kaku
/// - Sudut membulat halus (BorderRadius.circular(32)) pada kolom input & tombol
/// - Tombol utama Deep Blue (#314BB5) dengan bayangan halus & transparan
/// - Ikon outline minimalis pada input field
/// - Kompatibel penuh dengan Mode Terang & Gelap
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color primaryBlue = Color(0xFF314BB5);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authService.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        _showSnackBar(
          message: "Login gagal. Periksa kembali email dan kata sandi Anda.",
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceFirst("Exception: ", "").trim();
        if (msg == "Error" || msg.isEmpty) {
          msg = "Gagal masuk. Periksa kembali email dan kata sandi Anda.";
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

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final googleUser = await triggerGoogleSignInFlow(
        context,
        title: "Masuk dengan Google",
        subtitle: "Pilih akun Google Anda untuk masuk ke RestGuard",
      );

      if (googleUser == null) {
        return;
      }

      final success = await authService.loginWithGoogleAccount(
        email: googleUser.email,
        name: googleUser.displayName,
        googleId: googleUser.googleId,
        setSession: true,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          message: "Berhasil masuk dengan akun Google: ${googleUser.email}!",
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      } else {
        _showSnackBar(
          message: "Login dengan Google gagal. Silakan coba kembali.",
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceFirst("Exception: ", "").trim();
        if (msg == "Error" || msg.isEmpty) {
          msg = "Gagal login dengan Google. Silakan coba kembali.";
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

  void _showSnackBar({required String message, bool isError = false}) {
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
        backgroundColor: isError ? const Color(0xFFEF4444) : primaryBlue,
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
    final isDark = theme.brightness == Brightness.dark || themeController.isDarkMode;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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

                    // Tag Kategori Modern Clean
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_open_rounded, size: 14, color: primaryBlue),
                            SizedBox(width: 6),
                            Text(
                              "MASUK KE AKUN",
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

                    // Header Teks
                    Text(
                      "Selamat Datang Kembali",
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Masuk untuk melanjutkan pemantauan ritme istirahat dan kesehatan Anda.",
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Input Form Email
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
                    const SizedBox(height: 20),

                    // Input Form Password
                    _buildFieldLabel("Kata Sandi", isDark),
                    const SizedBox(height: 8),
                    _buildModernTextField(
                      controller: _passwordController,
                      hintText: "Masukkan kata sandi",
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      isDark: isDark,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                    const SizedBox(height: 12),

                    // Link Lupa Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            "Lupa kata sandi?",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Tombol Utama "Masuk" (Modern Clean Deep Blue, Radius 32, Soft Shadow)
                    _buildModernActionButton(
                      text: "Masuk",
                      isLoading: _isLoading,
                      onPressed: _handleEmailLogin,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // Divider "ATAU"
                    _buildModernOrDivider(isDark),
                    const SizedBox(height: 24),

                    // Tombol "Masuk dengan Google" (Elegan, Radius 32, Soft Shadow)
                    _buildGoogleButton(isDark),
                    const SizedBox(height: 32),

                    // Link ke Layar Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Belum memiliki akun? ",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Daftar Sekarang",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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

  // Kolom Input (TextField) Modern Clean dengan Radius 32 & Ikon Outline
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

  // Tombol Utama Modern Clean (Deep Blue, Radius 32, Soft Shadow)
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

  // Divider Modern Clean
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
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

  // Tombol "Masuk dengan Google" Modern Clean
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
          onTap: _isGoogleLoading ? null : _handleGoogleLogin,
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
                        "Masuk dengan Google",
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
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
