import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color scaffoldBg = Color(0xFFF2F1EB);
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color accentYellow = Color(0xFFFFC436);
  static const Color darkBorder = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status / Version Tag Pill
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentYellow,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: darkBorder, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: darkBorder,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 16,
                                color: darkBorder,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "AI HEALTH MONITORING",
                                style: TextStyle(
                                  color: darkBorder,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Logo / Icon Besar dengan Offset Canvas & Neo-Brutalist Card
                      Center(
                        child: SizedBox(
                          width: 170,
                          height: 170,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Solid offset shadow backing layer
                              Positioned(
                                top: 8,
                                left: 8,
                                right: -8,
                                bottom: -8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: darkBorder,
                                    borderRadius: BorderRadius.circular(36),
                                  ),
                                ),
                              ),
                              // Front main card
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(36),
                                  border: Border.all(
                                    color: darkBorder,
                                    width: 3.0,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: darkBorder,
                                        width: 2.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: accentYellow,
                                          offset: Offset(4, 4),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.shield_rounded,
                                        size: 56,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Floating decorative micro-badge
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: accentYellow,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: darkBorder, width: 2),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: darkBorder,
                                        offset: Offset(2, 2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    size: 18,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Teks Judul RESTGUARD
                      const Text(
                        "RESTGUARD",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: darkBorder,
                          letterSpacing: 1.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Deskripsi Singkat yang Ramah
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Teman setia menjaga pola istirahat, mendeteksi kelelahan mental, dan merawat kesehatan harian Anda dengan presisi AI multimodal.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Tombol Besar "Masuk" (Login)
                      _buildNeoButton(
                        context: context,
                        text: "Masuk",
                        backgroundColor: primaryBlue,
                        textColor: Colors.white,
                        icon: Icons.login_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tombol Besar "Daftar Akun Baru" (Register)
                      _buildNeoButton(
                        context: context,
                        text: "Daftar Akun Baru",
                        backgroundColor: Colors.white,
                        textColor: darkBorder,
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Footer Subtext
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Privasi & Data Biometrik Anda 100% Terenkripsi",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildNeoButton({
    required BuildContext context,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: darkBorder,
                width: 2.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 10),
                ],
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
    );
  }
}
