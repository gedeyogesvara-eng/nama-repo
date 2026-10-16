import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/google_icon.dart';
import '../widgets/google_auth_dialog.dart';
import '../theme/theme_controller.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color scaffoldBg = Color(0xFFF2F1EB);
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color accentYellow = Color(0xFFFFC436);
  static const Color darkBorder = Color(0xFF111827);

  final _formKey = GlobalKey<FormState>();
  // Form input kosong secara default sesuai instruksi
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
        setSession: true, // Masuk langsung ke Home
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
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
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: darkBorder, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode;
    final Color currentBg = isDark ? const Color(0xFF121217) : scaffoldBg;

    return Scaffold(
      backgroundColor: currentBg,
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
                        // Header Bar: Tombol Back di Pojok Kiri Atas
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildBackButton(context),
                        ),
                        const SizedBox(height: 24),

                        // Tag Mini
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: accentYellow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: darkBorder, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: darkBorder,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Text(
                            "MASUK KE AKUN",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: darkBorder,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Judul "Selamat Datang Kembali"
                        const Text(
                          "Selamat Datang Kembali",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: darkBorder,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Masuk untuk melanjutkan pemantauan ritme istirahat dan kesehatan Anda.",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Label Email
                        const Text(
                          "Alamat Email",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: darkBorder,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Input Email (Clean, rounded, white fill, thin border, NO thick black border)
                        _buildCleanTextField(
                          controller: _emailController,
                          hintText: "nama@contoh.com",
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
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

                        // Label Password
                        const Text(
                          "Kata Sandi",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: darkBorder,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Input Password
                        _buildCleanTextField(
                          controller: _passwordController,
                          hintText: "Masukkan kata sandi",
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF6B7280),
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
                        const SizedBox(height: 10),

                        // Tombol "Lupa kata sandi?" di Kanan Bawah Form Password
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
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                "Lupa kata sandi?",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Tombol Utama "Masuk" (Biru Tua, Solid Offset Shadow)
                        _buildNeoActionButton(
                          text: "Masuk",
                          backgroundColor: primaryBlue,
                          textColor: Colors.white,
                          isLoading: _isLoading,
                          onPressed: _handleEmailLogin,
                        ),
                        const SizedBox(height: 28),

                        // Divider Pemisah bertuliskan "ATAU"
                        _buildOrDivider(),
                        const SizedBox(height: 24),

                        // Tombol "Masuk dengan Google" (Putih, Teks Biru Tua, Google Icon)
                        _buildGoogleButton(),
                        const SizedBox(height: 28),

                        // Navigasi ke Daftar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Belum memiliki akun? ",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
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
                                  fontWeight: FontWeight.w900,
                                  color: primaryBlue,
                                  decoration: TextDecoration.underline,
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
            );
          },
        ),
      ),
    );
  }

  // Tombol Back di Pojok Kiri Atas
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

  // Desain TextField Membulat Bersih (Fill Putih, Border Tipis, Tanpa Border Hitam Tebal)
  Widget _buildCleanTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkBorder,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF6B7280),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }

  // Tombol Utama "Masuk" dengan Solid Offset Shadow
  Widget _buildNeoActionButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
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
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
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
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: TextStyle(
                            color: textColor,
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
    );
  }

  // Divider dengan teks "ATAU"
  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0xFFD1D5DB),
            thickness: 1.4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            ),
            child: const Text(
              "ATAU",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Color(0xFFD1D5DB),
            thickness: 1.4,
          ),
        ),
      ],
    );
  }

  // Tombol "Masuk dengan Google" (Putih, Teks Biru Tua, Google Icon)
  Widget _buildGoogleButton() {
    return Container(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _isGoogleLoading ? null : _handleGoogleLogin,
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
              child: _isGoogleLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GoogleIcon(size: 22),
                        SizedBox(width: 12),
                        Text(
                          "Masuk dengan Google",
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
