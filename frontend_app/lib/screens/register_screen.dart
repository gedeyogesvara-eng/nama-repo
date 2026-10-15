import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/google_icon.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color scaffoldBg = Color(0xFFF2F1EB);
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color accentYellow = Color(0xFFFFC436);
  static const Color darkBorder = Color(0xFF111827);

  final _formKey = GlobalKey<FormState>();

  // Form input kosong secara default sesuai spesifikasi
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
        _nameController.text.trim().isEmpty ? "Pengguna" : _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          message: e.toString().replaceFirst("Exception: ", ""),
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
      final success = await authService.loginWithGoogle();

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          message: e.toString().replaceFirst("Exception: ", ""),
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
                        // Header: Tombol Back
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
                            "REGISTRASI AKUN",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: darkBorder,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Judul "Buat Akun Baru"
                        const Text(
                          "Buat Akun Baru",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: darkBorder,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Daftar sekarang untuk memulai proteksi dini terhadap kelelahan dan stres kerja.",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Form 1: Nama Lengkap
                        const Text(
                          "Nama Lengkap",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: darkBorder,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCleanTextField(
                          controller: _nameController,
                          hintText: "Contoh: Budi Santoso",
                          prefixIcon: Icons.badge_outlined,
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

                        // Form 2: Email
                        const Text(
                          "Alamat Email",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: darkBorder,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 18),

                        // Form 3: Password
                        const Text(
                          "Kata Sandi",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: darkBorder,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCleanTextField(
                          controller: _passwordController,
                          hintText: "Minimal 6 karakter",
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
                        const SizedBox(height: 18),

                        // Form 4: Konfirmasi Password
                        const Text(
                          "Konfirmasi Kata Sandi",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: darkBorder,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCleanTextField(
                          controller: _confirmPasswordController,
                          hintText: "Ulangi kata sandi",
                          prefixIcon: Icons.lock_reset_rounded,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF6B7280),
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

                        // Tombol Utama "Daftar Sekarang"
                        _buildNeoActionButton(
                          text: "Daftar Sekarang",
                          backgroundColor: primaryBlue,
                          textColor: Colors.white,
                          isLoading: _isLoading,
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: 28),

                        // Divider Pemisah bertuliskan "ATAU"
                        _buildOrDivider(),
                        const SizedBox(height: 24),

                        // Tombol "Daftar dengan Google"
                        _buildGoogleButton(),
                        const SizedBox(height: 28),

                        // Link Menuju Layar Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Sudah memiliki akun? ",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
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
                                  fontWeight: FontWeight.w900,
                                  color: primaryBlue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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

  // Tombol Back
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

  // Input Field Bersih & Membulat (Tanpa Border Hitam Tebal)
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

  // Tombol Utama "Daftar Sekarang"
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
                          Icons.person_add_alt_1_rounded,
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

  // Divider "ATAU"
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

  // Tombol "Daftar dengan Google"
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
          onTap: _isGoogleLoading ? null : _handleGoogleRegister,
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
                          "Daftar dengan Google",
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
