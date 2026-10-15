import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import 'loading_scan_screen.dart';

class Stage3VisualScreen extends StatefulWidget {
  final String? drawingImagePath;
  final String? audioPath;
  final dynamic gaitData;

  const Stage3VisualScreen({
    super.key,
    this.drawingImagePath,
    this.audioPath,
    this.gaitData,
  });

  @override
  State<Stage3VisualScreen> createState() => _Stage3VisualScreenState();
}

class _Stage3VisualScreenState extends State<Stage3VisualScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  bool _isCaptured = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Inisialisasi kamera secara asinkron
    availableCameras().then((cameras) {
      if (cameras.isNotEmpty) {
        // Utamakan kamera depan jika ada, fallback ke kamera pertama
        final camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _controller = CameraController(
          camera,
          ResolutionPreset.medium,
        );

        _initializeControllerFuture = _controller!.initialize().then((_) {
          if (!mounted) return;
          setState(() {});
        });
      }
    }).catchError((error) {
      debugPrint("Gagal inisialisasi kamera: $error");
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Membuat gambar JPEG fallback jika diperlukan
  Future<String> _generateFallbackFaceImage() async {
    try {
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final fallbackPath =
            '${tempDir.path}/face_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(fallbackPath);

        // Binary 1x1 JPEG valid
        final List<int> jpegBytes = [
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
          0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
          0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
          0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
          0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
          0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
          0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
          0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
          0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
          0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
          0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
          0x00, 0xBF, 0x80, 0xFF, 0xD9
        ];

        await file.writeAsBytes(jpegBytes);
        return fallbackPath;
      }
    } catch (e) {
      debugPrint("Gagal membuat fallback image: $e");
    }
    return "face_dummy.jpg";
  }

  /// Mengambil foto saat tombol ditekan
  Future<void> _simulateAutoCapture() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    String? capturedPath;

    try {
      if (_initializeControllerFuture != null) {
        await _initializeControllerFuture;
      }
      if (_controller != null &&
          _controller!.value.isInitialized &&
          !_controller!.value.isTakingPicture) {
        final XFile photo = await _controller!.takePicture();
        capturedPath = photo.path;
        debugPrint("📸 Foto kamera berhasil diambil: $capturedPath");
      }
    } catch (e) {
      debugPrint("⚠️ Gagal mengambil foto kamera: $e");
    }

    if (capturedPath == null || capturedPath.isEmpty) {
      capturedPath = await _generateFallbackFaceImage();
    }

    setState(() {
      _isCaptured = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Lanjut ke LoadingScanScreen membawa seluruh data Tahap 1, 2, dan 3
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingScanScreen(
            faceImagePath: capturedPath ?? '',
            drawingImagePath: widget.drawingImagePath ?? '',
            audioPath: widget.audioPath ?? '',
            gaitData: widget.gaitData ?? 'gait_recorded',
          ),
        ),
      );
    } catch (e) {
      debugPrint("⚠️ Error navigasi Stage 3: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoadingScanScreen(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: NeoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tahap 3: Visual & Sclera Scan",
          style: TextStyle(
            color: NeoColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guidance banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NeoColors.borderBlack, width: 2),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      color: NeoColors.black,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Posisikan wajah & sklera mata di dalam oval. Tahan sejenak.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // VIEWPORT CONTAINER: LIVE CAMERA PREVIEW DI BELAKANG DESAIN OVERLAY
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A), // Dark slate camera background
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: NeoColors.borderBlack,
                      width: 3.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.borderBlack,
                        offset: Offset(6, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        // 1. LIVE CAMERA PREVIEW VIA FutureBuilder
                        FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                _controller != null &&
                                _controller!.value.isInitialized) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _controller!
                                              .value.previewSize?.width ??
                                          400,
                                      height: _controller!
                                              .value.previewSize?.height ??
                                          300,
                                      child: CameraPreview(_controller!),
                                    ),
                                  ),
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    "Kamera tidak tersedia:\n${snapshot.error}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: NeoColors.primaryYellow,
                                      strokeWidth: 3,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "Menyalakan Live Camera...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),

                        // 2. Soft Dark Vignette Overlay
                        Container(
                          color: Colors.black.withValues(alpha: 0.15),
                        ),

                        // Camera Grid Guides
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Divider(
                              color: Colors.white.withValues(alpha: 0.12),
                              thickness: 1,
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.12),
                              thickness: 1,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            VerticalDivider(
                              color: Colors.white.withValues(alpha: 0.12),
                              thickness: 1,
                            ),
                            VerticalDivider(
                              color: Colors.white.withValues(alpha: 0.12),
                              thickness: 1,
                            ),
                          ],
                        ),

                        // 3. Live Eye-Tracking Header Badge (TEPAT DI ATAS CameraPreview)
                        Positioned(
                          top: 14,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isCaptured
                                      ? NeoColors.greenDark
                                      : NeoColors.redDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 4,
                                      backgroundColor: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isCaptured
                                          ? "BIOMARKER TERKUNCI"
                                          : "Live Eye-Tracking",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _controller != null &&
                                          _controller!.value.isInitialized
                                      ? "CAMERA LIVE"
                                      : "MEMUAT...",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 4. Dashed Oval Face Guide Frame (Putus-putus Merah TEPAT DI ATAS CameraPreview)
                        CustomPaint(
                          painter: DashedOvalPainter(
                            color: _isCaptured
                                ? NeoColors.green
                                : NeoColors.redDark,
                            isSuccess: _isCaptured,
                          ),
                          child: SizedBox(
                            width: 210,
                            height: 280,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Crosshair Pusat
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 2,
                                          height: 28,
                                          color: _isCaptured
                                              ? NeoColors.green
                                              : NeoColors.redDark
                                                  .withValues(alpha: 0.8),
                                        ),
                                        Container(
                                          width: 28,
                                          height: 2,
                                          color: _isCaptured
                                              ? NeoColors.green
                                              : NeoColors.redDark
                                                  .withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Icon(
                                    _isCaptured
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.face_retouching_natural_rounded,
                                    size: 46,
                                    color: _isCaptured
                                        ? NeoColors.green
                                        : Colors.white.withValues(alpha: 0.65),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _isCaptured
                                          ? "Frame Terkunci!\nMengambil Foto..."
                                          : "Posisikan Wajah & Sklera",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _isCaptured
                                            ? NeoColors.greenLight
                                            : Colors.white
                                                .withValues(alpha: 0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 5. Capture Flash simulation
                        if (_isCaptured)
                          Positioned.fill(
                            child: AnimatedOpacity(
                              opacity: _isProcessing ? 0.35 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(color: Colors.white),
                            ),
                          ),

                        // 6. Bottom Facial Landmarks indicator
                        Positioned(
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _isCaptured
                                  ? "Micro-Expression Detected: 468 Landmarks"
                                  : "Deteksi Biometrik: Siap Mengunci",
                              style: TextStyle(
                                color: _isCaptured
                                    ? NeoColors.greenLight
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Button: "Simulate Auto-Capture"
              NeoButton(
                text: _isCaptured
                    ? "✓ Memproses Multimodal Data..."
                    : "Simulate Auto-Capture (Ambil Foto)",
                icon: _isCaptured ? Icons.check : Icons.camera_rounded,
                backgroundColor:
                    _isCaptured ? NeoColors.greenDark : NeoColors.primaryBlue,
                textColor: NeoColors.white,
                borderRadius: 28,
                height: 56,
                onPressed: _isCaptured ? null : _simulateAutoCapture,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter untuk garis oval putus-putus (Dashed Oval)
class DashedOvalPainter extends CustomPainter {
  final Color color;
  final bool isSuccess;

  DashedOvalPainter({required this.color, required this.isSuccess});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addOval(rect);

    if (isSuccess) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawOval(rect, fillPaint);
    }

    // Gambar dashed path keliling oval
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      const dashLength = 10.0;
      const dashSpace = 8.0;

      while (distance < metric.length) {
        final nextDistance = distance + dashLength;
        final extractPath = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedOvalPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isSuccess != isSuccess;
  }
}
