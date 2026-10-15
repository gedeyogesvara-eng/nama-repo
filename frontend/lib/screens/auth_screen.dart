import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: "user@emosense.ai");
  final TextEditingController _passwordController =
      TextEditingController(text: "password123");
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    Navigator.pushNamed(context, '/permissions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Tag
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: NeoColors.primaryYellow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.borderBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Text(
                      "MASUK SISTEM SKRINING",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Selamat Datang di\nMindPulse AI",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Masuk untuk memulai skrining kondisi emosi dan kelelahan mental harian.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.darkGray,
                  ),
                ),
                const SizedBox(height: 28),

                // Form Container NeoCard
                NeoCard(
                  backgroundColor: NeoColors.white,
                  borderRadius: 24,
                  shadowOffset: 6,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Alamat Email",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.slate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: NeoColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: NeoColors.borderBlack,
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            hintText: "nama@email.com",
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              color: NeoColors.slateMedium,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Kata Sandi",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.slate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: NeoColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: NeoColors.borderBlack,
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: "••••••••",
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: NeoColors.slateMedium,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: NeoColors.slateMedium,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      NeoButton(
                        text: "Masuk / Register",
                        icon: Icons.login_rounded,
                        backgroundColor: NeoColors.primaryBlue,
                        textColor: NeoColors.white,
                        borderRadius: 30, // Blue pill shape
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                NeoButton(
                  text: "Masuk Sebagai Tamu (Demo)",
                  icon: Icons.person_outline_rounded,
                  backgroundColor: NeoColors.white,
                  textColor: NeoColors.slate,
                  borderRadius: 30,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Data Anda diproses lokal untuk menjaga privasi medis.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.slateLight,
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
