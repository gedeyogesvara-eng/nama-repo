import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'loading_scan_screen.dart';

/// Layar Skrining Tahap 3: Foto Mata (Visual / Sklera)
/// Desain 'Modern Clean' dengan Deep Blue, sudut lengkung 32, bayangan halus,
/// dan kompatibilitas penuh dengan Dark Mode.
class Stage3VisualScreen extends StatefulWidget {
  /// Gambar coretan (PNG) dari Tahap 1
  final Uint8List? drawingBytes;

  /// Rekaman suara (WAV) dari Tahap 1
  final Uint8List? audioBytes;

  /// Data sensor gait dari Tahap 2
  final dynamic gaitData;

  const Stage3VisualScreen({
    super.key,
    this.drawingBytes,
    this.audioBytes,
    this.gaitData,
  });

  @override
  State<Stage3VisualScreen> createState() => _Stage3VisualScreenState();
}

class _Stage3VisualScreenState extends State<Stage3VisualScreen> {
  static const Color primaryBlue = Color(0xFF314BB5);

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  bool _isCaptured = false;
  bool _isProcessing = false;
  Uint8List? _capturedFaceBytes;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    availableCameras().then((cameras) {
      if (cameras.isNotEmpty) {
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

  Future<void> _simulateAutoCapture() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    Uint8List? faceBytes;

    try {
      if (_initializeControllerFuture != null) {
        await _initializeControllerFuture!.timeout(const Duration(seconds: 5));
      }
      if (_controller != null &&
          _controller!.value.isInitialized &&
          !_controller!.value.isTakingPicture) {
        final XFile photo = await _controller!.takePicture();
        faceBytes = await photo.readAsBytes();
        debugPrint("📸 Foto kamera berhasil diambil: ${faceBytes.length} bytes");
      }
    } catch (e) {
      debugPrint("⚠️ Gagal mengambil foto kamera: $e");
    }

    if (!mounted) return;
    setState(() {
      _isCaptured = true;
      _capturedFaceBytes = faceBytes;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingScanScreen(
            faceBytes: faceBytes,
            drawingBytes: widget.drawingBytes,
            audioBytes: widget.audioBytes,
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

  Future<void> pickImageFromGallery() async {
    if (_isProcessing) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );

      if (pickedFile == null) {
        return;
      }

      final faceBytes = await pickedFile.readAsBytes();
      debugPrint("🖼️ [Stage3] Foto mata berhasil dipilih dari galeri: ${faceBytes.length} bytes");

      setState(() {
        _isCaptured = true;
        _isProcessing = true;
        _capturedFaceBytes = faceBytes;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Foto dari galeri berhasil dipilih! Melanjutkan...",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingScanScreen(
            faceBytes: faceBytes,
            drawingBytes: widget.drawingBytes,
            audioBytes: widget.audioBytes,
            gaitData: widget.gaitData ?? 'gait_recorded',
          ),
        ),
      );
    } catch (e) {
      debugPrint("⚠️ Gagal memilih foto dari galeri: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal memilih foto: $e",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : primaryBlue,
                size: 18,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove_red_eye_rounded, size: 16, color: primaryBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Tahap 3: Foto Mata",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white : primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guidance banner - Modern Clean Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.remove_red_eye_outlined,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Tatap layar dan ambil foto matamu",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // VIEWPORT CONTAINER: LIVE CAMERA PREVIEW DENGAN SUDUT 32 DAN SHADOW HALUS
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        // 1. LIVE CAMERA PREVIEW VIA FutureBuilder
                        FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done &&
                                _controller != null &&
                                _controller!.value.isInitialized) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _controller!.value.previewSize?.width ?? 400,
                                      height: _controller!.value.previewSize?.height ?? 300,
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
                                      color: primaryBlue,
                                      strokeWidth: 3,
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      "Menyalakan Live Camera...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),

                        // Preview foto yang tertangkap
                        if (_capturedFaceBytes != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.memory(
                                _capturedFaceBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                        // Soft Dark Vignette Overlay
                        Container(
                          color: Colors.black.withValues(alpha: 0.12),
                        ),

                        // Camera Grid Guides
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Divider(
                              color: Colors.white.withValues(alpha: 0.08),
                              thickness: 1,
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.08),
                              thickness: 1,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            VerticalDivider(
                              color: Colors.white.withValues(alpha: 0.08),
                              thickness: 1,
                            ),
                            VerticalDivider(
                              color: Colors.white.withValues(alpha: 0.08),
                              thickness: 1,
                            ),
                          ],
                        ),

                        // Header Live Badge
                        Positioned(
                          top: 16,
                          left: 18,
                          right: 18,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _isCaptured
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 4,
                                      backgroundColor: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isCaptured ? "FOTO DIAMBIL" : "Kamera Aktif",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _controller != null && _controller!.value.isInitialized
                                      ? "LIVE VIEW"
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

                        // Dashed Oval Face Guide Frame
                        CustomPaint(
                          painter: DashedOvalPainter(
                            color: _isCaptured ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.8),
                            isSuccess: _isCaptured,
                          ),
                          child: SizedBox(
                            width: 210,
                            height: 280,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isCaptured
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.face_retouching_natural_rounded,
                                    size: 46,
                                    color: _isCaptured
                                        ? const Color(0xFF10B981)
                                        : Colors.white.withValues(alpha: 0.75),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _isCaptured ? "Foto Berhasil Diambil!" : "Arahkan Matamu ke Sini",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _isCaptured
                                            ? const Color(0xFF34D399)
                                            : Colors.white.withValues(alpha: 0.95),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Capture Flash animation
                        if (_isCaptured)
                          Positioned.fill(
                            child: AnimatedOpacity(
                              opacity: _isProcessing ? 0.35 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol Utama: Ambil Foto Mata (Modern Clean BorderRadius 32)
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isCaptured || _isProcessing ? null : _simulateAutoCapture,
                  icon: Icon(
                    _isCaptured ? Icons.check_rounded : Icons.camera_alt_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _isCaptured ? "Menyimpan Foto..." : "Ambil Foto Mata",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCaptured ? const Color(0xFF10B981) : primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    shadowColor: primaryBlue.withValues(alpha: 0.35),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tombol Sekunder: Pilih dari Galeri (Modern Clean)
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isCaptured || _isProcessing ? null : pickImageFromGallery,
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: const Text(
                    "📁 Pilih dari Galeri",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedOvalPainter extends CustomPainter {
  final Color color;
  final bool isSuccess;

  DashedOvalPainter({required this.color, required this.isSuccess});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addOval(rect);

    if (isSuccess) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawOval(rect, fillPaint);
    }

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      const dashLength = 8.0;
      const dashSpace = 6.0;

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
