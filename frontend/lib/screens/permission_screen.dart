import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _cameraPermission = false;
  bool _microphonePermission = false;
  bool _motionPermission = false;

  bool get _allPermissionsGranted =>
      _cameraPermission && _microphonePermission && _motionPermission;

  void _grantAllPermissions() {
    setState(() {
      _cameraPermission = true;
      _microphonePermission = true;
      _motionPermission = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: NeoColors.greenLight),
            SizedBox(width: 8),
            Text(
              "Semua izin sensor telah diaktifkan!",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: NeoColors.slateDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.borderBlack, width: 2),
        ),
      ),
    );
  }

  void _handleContinue() {
    if (!_allPermissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: NeoColors.primaryYellow),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Wajib mencentang ketiga izin sensor untuk analisis multimodal yang akurat!",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: NeoColors.redDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: NeoColors.borderBlack, width: 2),
          ),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/dashboard');
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required IconData icon,
    required Color iconBg,
    required bool isGranted,
    required ValueChanged<bool?> onChanged,
  }) {
    return NeoCard(
      backgroundColor: isGranted ? const Color(0xFFF0FDF4) : NeoColors.white,
      borderColor: isGranted ? NeoColors.greenDark : NeoColors.borderBlack,
      borderRadius: 18,
      shadowOffset: 4,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.borderBlack, width: 2),
            ),
            child: Icon(icon, color: NeoColors.black, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.darkGray,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: isGranted,
            activeColor: NeoColors.primaryBlue,
            checkColor: NeoColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: NeoColors.borderBlack, width: 2),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: NeoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Izin Sensor Dibutuhkan",
          style: TextStyle(
            color: NeoColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NeoColors.primaryYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NeoColors.borderBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.borderBlack,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: NeoColors.black, size: 26),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Skrining depresi memanfaatkan kombinasi 3 sensor ponsel. Semua wajib diizinkan untuk lanjut.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.black,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Permission Checkbox 1: Kamera
              _buildPermissionItem(
                title: "Kamera Depan",
                description:
                    "Untuk deteksi micro-expression wajah dan dilatasi pupil (Tahap 3).",
                icon: Icons.camera_alt_outlined,
                iconBg: const Color(0xFF93C5FD),
                isGranted: _cameraPermission,
                onChanged: (val) {
                  setState(() => _cameraPermission = val ?? false);
                },
              ),

              // Permission Checkbox 2: Mikrofon
              _buildPermissionItem(
                title: "Mikrofon (Audio)",
                description:
                    "Menganalisis jeda bicara, desahan, dan intonasi prosodi vokal (Tahap 1).",
                icon: Icons.mic_none_rounded,
                iconBg: const Color(0xFFFDE047),
                isGranted: _microphonePermission,
                onChanged: (val) {
                  setState(() => _microphonePermission = val ?? false);
                },
              ),

              // Permission Checkbox 3: Sensor Gerak
              _buildPermissionItem(
                title: "Akselerometer & Sensor Gerak",
                description:
                    "Mengukur stabilitas langkah dan kelambatan motorik gait (Tahap 2).",
                icon: Icons.directions_walk_rounded,
                iconBg: const Color(0xFF86EFAC),
                isGranted: _motionPermission,
                onChanged: (val) {
                  setState(() => _motionPermission = val ?? false);
                },
              ),

              const Spacer(),

              // Quick Action: Izinkan Semua
              NeoButton(
                text: "Izinkan Semua Sensor Sekaligus",
                icon: Icons.done_all_rounded,
                backgroundColor: NeoColors.white,
                textColor: NeoColors.black,
                borderRadius: 25,
                height: 50,
                onPressed: _grantAllPermissions,
              ),
              const SizedBox(height: 12),

              // Proceed Button
              NeoButton(
                text: _allPermissionsGranted
                    ? "Lanjut ke Dashboard Skrining →"
                    : "Centang 3 Izin Di Atas",
                backgroundColor: _allPermissionsGranted
                    ? NeoColors.primaryBlue
                    : NeoColors.darkGray,
                textColor: NeoColors.white,
                borderRadius: 25,
                height: 54,
                onPressed: _allPermissionsGranted ? _handleContinue : null,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
