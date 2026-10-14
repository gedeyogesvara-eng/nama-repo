import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'result_screen.dart';

/// Halaman Loading Scan AI
/// Menampilkan animasi visual scanner multimodal (Sklera, Suara, Gait),
/// mengirimkan berkas data multimodal ke AI Service lokal (http://10.0.2.2:5000/api/detect),
/// lalu berpindah ke ResultScreen setelah respons diterima.
class LoadingScanScreen extends StatefulWidget {
  final String faceImagePath;
  final String drawingImagePath;
  final String audioPath;
  final dynamic gaitData;

  const LoadingScanScreen({
    super.key,
    this.faceImagePath = '',
    this.drawingImagePath = '',
    this.audioPath = '',
    this.gaitData = 'gait_recorded',
  });

  @override
  State<LoadingScanScreen> createState() => _LoadingScanScreenState();
}

class _LoadingScanScreenState extends State<LoadingScanScreen>
    with SingleTickerProviderStateMixin {
  // Palet Warna Neo-Brutalism
  static const Color appBg = Color(0xFFF2F1EB);
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color primaryDark = Color(0xFF1E2D75);
  static const Color grayText = Color(0xFF5C5C5C);
  static const Color borderBlack = Color(0xFF000000);
  static const Color accentYellow = Color(0xFFFFC436);

  late AnimationController _animController;
  int _currentStepIndex = 0;
  Timer? _stepTimer;
  bool _isConnecting = true;

  final List<String> _analysisSteps = const [
    'Mengunggah berkas sensor multimodal ke backend...',
    'Memindai vaskularisasi & mikrosleep sklera optik...',
    'Mengekstrak prosodi nada vokal & tremor akustik...',
    'Menganalisis simetri akselerometer gait berjalan...',
    'Mengagregasi skor AI Multimodal & menyusun resep...',
  ];

  @override
  void initState() {
    super.initState();

    // Controller untuk animasi pulse rotasi & gelombang
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Timer untuk memutar teks tahapan analisis
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _analysisSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
      }
    });

    // Jalankan pemrosesan inferensi AI
    _processDetection();
  }

  Future<void> _processDetection() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // Panggil AI Service nyata via Multipart POST Request
      final resultData = await AIService.sendDataToAI(
        faceImagePath: widget.faceImagePath,
        drawingImagePath: widget.drawingImagePath,
        audioPath: widget.audioPath,
        gaitData: widget.gaitData,
      );

      if (!mounted) return;

      // Navigasi pushReplacement ke ResultScreen dengan data JSON nyata
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(detectionData: resultData),
        ),
      );
    } catch (e) {
      debugPrint("❌ Gagal terhubung ke AI Model: $e");
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
      });
      _showConnectionErrorDialog(e.toString());
    }
  }

  void _showConnectionErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderBlack, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: borderBlack,
                  offset: Offset(5, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderBlack, width: 2),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Koneksi AI Terputus",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: borderBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  "Gagal menghubungi endpoint AI lokal:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: borderBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderBlack, width: 1.5),
                  ),
                  child: Text(
                    AIService.defaultEndpoint,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Detail: $errorMessage",
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: grayText,
                  ),
                ),
                const SizedBox(height: 20),
                // Tombol Coba Lagi
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _processDetection();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderBlack, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: borderBlack,
                          offset: Offset(2.5, 2.5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Coba Lagi",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tombol Fallback / Demo Result
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final fallbackData = AIService.normalizeResponse({
                      "status": "success",
                      "tingkat_depresi": "Burnout Sedang (Acoustic & Motoric)",
                      "skor_sensor": {
                        "audio": 78,
                        "motorik": 65,
                        "sklera": 84,
                      },
                      "rekomendasi_tindakan": [
                        "Istirahatkan mata dari layar monitor setiap 20 menit.",
                        "Lakukan latihan peregangan fisik ringan 5 menit.",
                        "Dengarkan audio relaksasi pernapasan ritmik.",
                      ],
                    });
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResultScreen(detectionData: fallbackData),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderBlack, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        "Buka dengan Data Simulasi (Testing UI)",
                        style: TextStyle(
                          color: borderBlack,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar Status
              _buildTopStatus(),

              // Central Scanning Radar Visual
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPulseScanningIndicator(),
                      const SizedBox(height: 36),

                      // Teks Utama Sesuai Prompt
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'AI sedang menganalisis Sklera, Suara, dan Gait Anda...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: primaryBlue,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Teks Sub-tahapan Dinamis
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          key: ValueKey<int>(_currentStepIndex),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderBlack, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: borderBlack,
                                offset: Offset(2.5, 2.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            _analysisSteps[_currentStepIndex],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: borderBlack,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Sensor Active Nodes (Sklera, Suara, Gait)
                      _buildSensorNodesRow(),
                    ],
                  ),
                ),
              ),

              // Bottom Info Box
              _buildBottomNotice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: accentYellow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: borderBlack,
                    offset: Offset(1.5, 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isConnecting ? 'HTTP REQUEST AKTIF' : 'MENUNGGU RESPONS',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: primaryBlue,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderBlack, width: 2),
          ),
          child: const Text(
            'Local AI :5000',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulseScanningIndicator() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final scale = 1.0 + (_animController.value * 0.12);
        final rotation = _animController.value * 2 * 3.14159;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Gelombang Luar
            Transform.scale(
              scale: scale,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryBlue.withValues(
                    alpha: 0.08 * (1.0 - _animController.value),
                  ),
                  border: Border.all(
                    color: primaryBlue.withValues(
                      alpha: 0.3 * (1.0 - _animController.value),
                    ),
                    width: 2,
                  ),
                ),
              ),
            ),

            // Lingkaran Border Putar
            Transform.rotate(
              angle: rotation,
              child: Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryBlue,
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: accentYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: borderBlack,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Kotak Inti Neo-Brutalism (Offset Solid Shadow)
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderBlack, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: primaryDark,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.sensors_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensorNodesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSensorNodeChip(
          Icons.remove_red_eye_outlined,
          'Sklera',
          _currentStepIndex >= 1,
        ),
        const SizedBox(width: 8),
        _buildSensorNodeChip(
          Icons.graphic_eq_rounded,
          'Suara',
          _currentStepIndex >= 2,
        ),
        const SizedBox(width: 8),
        _buildSensorNodeChip(
          Icons.directions_walk_rounded,
          'Gait',
          _currentStepIndex >= 3,
        ),
      ],
    );
  }

  Widget _buildSensorNodeChip(IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderBlack, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: borderBlack,
            offset: Offset(1.5, 1.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isActive ? Colors.white : grayText,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : grayText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderBlack, width: 1.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryBlue,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Mengirim data ke model AI lokal...',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: grayText,
            ),
          ),
        ],
      ),
    );
  }
}
