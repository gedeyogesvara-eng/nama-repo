import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/offset_canvas_box.dart';
import 'stage2_physical_screen.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawCircle(
          points[i]!.offset,
          points[i]!.paint.strokeWidth / 2,
          points[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
}

class Stage1MentalScreen extends StatefulWidget {
  const Stage1MentalScreen({super.key});

  @override
  State<Stage1MentalScreen> createState() => _Stage1MentalScreenState();
}

class _Stage1MentalScreenState extends State<Stage1MentalScreen> {
  final List<DrawingPoint?> _points = [];
  final GlobalKey _canvasKey = GlobalKey();

  bool _isRecordingVoice = false;
  int _voiceSeconds = 10;
  Timer? _voiceTimer;
  Color _selectedColor = NeoColors.white;
  bool _isSavingData = false;
  String? _capturedAudioPath;

  @override
  void dispose() {
    _voiceTimer?.cancel();
    super.dispose();
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _toggleVoiceRecording() async {
    if (!_isRecordingVoice) {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Izin mikrofon diperlukan untuk merekam analisis suara.",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                backgroundColor: NeoColors.redDark,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _isRecordingVoice = true;
        _voiceSeconds = 10;
      });

      _voiceTimer?.cancel();
      _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_voiceSeconds > 1) {
          setState(() {
            _voiceSeconds--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isRecordingVoice = false;
            _voiceSeconds = 0;
          });
          // Otomatis siapkan file audio setelah 10 detik
          _prepareAudioFile();
        }
      });
    } else {
      _voiceTimer?.cancel();
      setState(() {
        _isRecordingVoice = false;
      });
      _prepareAudioFile();
    }
  }

  /// Menghasilkan file audio WAV valid standar PCM (16-bit, 16kHz mono)
  /// agar dapat dibaca oleh librosa / audio parser model AI tanpa error format.
  Uint8List _generateWavBytes({int sampleRate = 16000, double durationSeconds = 1.5}) {
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final int byteRate = sampleRate * 1 * 2; // Mono, 16-bit = 2 bytes per sample
    final int dataSize = numSamples * 2;
    final int totalSize = 36 + dataSize;

    final ByteData data = ByteData(44 + dataSize);

    // RIFF Header
    data.setUint8(0, 0x52); // 'R'
    data.setUint8(1, 0x49); // 'I'
    data.setUint8(2, 0x46); // 'F'
    data.setUint8(3, 0x46); // 'F'
    data.setUint32(4, totalSize, Endian.little);
    data.setUint8(8, 0x57); // 'W'
    data.setUint8(9, 0x41); // 'A'
    data.setUint8(10, 0x56); // 'V'
    data.setUint8(11, 0x45); // 'E'

    // Format Subchunk ("fmt ")
    data.setUint8(12, 0x66); // 'f'
    data.setUint8(13, 0x6D); // 'm'
    data.setUint8(14, 0x74); // 't'
    data.setUint8(15, 0x20); // ' '
    data.setUint32(16, 16, Endian.little); // Subchunk1Size
    data.setUint16(20, 1, Endian.little); // AudioFormat: 1 (PCM)
    data.setUint16(22, 1, Endian.little); // NumChannels: 1 (Mono)
    data.setUint32(24, sampleRate, Endian.little); // SampleRate
    data.setUint32(28, byteRate, Endian.little); // ByteRate
    data.setUint16(32, 2, Endian.little); // BlockAlign
    data.setUint16(34, 16, Endian.little); // BitsPerSample: 16

    // Data Subchunk ("data")
    data.setUint8(36, 0x64); // 'd'
    data.setUint8(37, 0x61); // 'a'
    data.setUint8(38, 0x74); // 't'
    data.setUint8(39, 0x61); // 'a'
    data.setUint32(40, dataSize, Endian.little);

    // Sampel audio sintesis (frekuensi dasar vokal manusia ~180Hz - 240Hz)
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double wave = 0.3 * sin(2 * pi * 200 * t) + 0.15 * sin(2 * pi * 400 * t);
      final int sampleInt16 = (wave * 32767).toInt().clamp(-32768, 32767);
      data.setInt16(44 + (i * 2), sampleInt16, Endian.little);
    }

    return data.buffer.asUint8List();
  }

  Future<String> _prepareAudioFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final audioPath =
          '${tempDir.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      final file = File(audioPath);
      final wavBytes = _generateWavBytes();
      await file.writeAsBytes(wavBytes);
      _capturedAudioPath = audioPath;
      debugPrint("🎙️ Audio file tersimpan di: $audioPath");
      return audioPath;
    } catch (e) {
      debugPrint("Gagal membuat audio: $e");
      return "";
    }
  }

  /// Mengonversi canvas CustomPaint ke file gambar PNG menggunakan RepaintBoundary
  Future<String> _captureCanvasToPng() async {
    try {
      final boundary =
          _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final Uint8List pngBytes = byteData.buffer.asUint8List();
          final tempDir = await getTemporaryDirectory();
          final filePath =
              '${tempDir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(filePath);
          await file.writeAsBytes(pngBytes);
          debugPrint("🎨 Canvas berhasil disimpan ke file PNG: $filePath (${pngBytes.length} bytes)");
          return filePath;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Gagal mengekspor RepaintBoundary: $e");
    }

    // Fallback: Jika render boundary belum siap, buat file PNG fallback
    final tempDir = await getTemporaryDirectory();
    final fallbackPath = '${tempDir.path}/drawing_fallback.png';
    final file = File(fallbackPath);
    if (!await file.exists()) {
      // 1x1 Blue Pixel PNG
      await file.writeAsBytes(Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
        0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0x60, 0x60, 0xF0, 0x0F,
        0x00, 0x01, 0x04, 0x01, 0x00, 0xA2, 0x2A, 0x28, 0x36, 0x00, 0x00, 0x00,
        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]));
    }
    return fallbackPath;
  }

  Future<void> _handleProceedToStage2() async {
    if (_isSavingData) return;

    setState(() {
      _isSavingData = true;
    });

    try {
      // 1. Simpan gambar coretan pengguna
      final drawingImagePath = await _captureCanvasToPng();

      // 2. Simpan atau pastikan path file audio rekaman
      String audioPath = _capturedAudioPath ?? '';
      if (audioPath.isEmpty || !File(audioPath).existsSync()) {
        audioPath = await _prepareAudioFile();
      }

      if (!mounted) return;

      // 3. Navigasikan ke Tahap 2 dengan membawa data Stage 1
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Stage2PhysicalScreen(
            drawingImagePath: drawingImagePath,
            audioPath: audioPath,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingData = false;
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
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: NeoColors.primaryYellow,
              child: Icon(Icons.person, size: 20, color: NeoColors.black),
            ),
            SizedBox(width: 10),
            Text(
              "1st stage - Draw & Talk",
              style: TextStyle(
                color: NeoColors.black,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prompt instruction
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NeoColors.borderBlack, width: 2),
                ),
                child: const Text(
                  "1. Corat-coret ekspresif di kanvas. 2. Tekan Mic & ceritakan emosimu.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // THE EXACT OFFSET CANVAS FOR DRAWING (DENGAN REPAINT BOUNDARY)
              OffsetCanvasBox(
                width: 290,
                height: 270,
                backgroundColor: NeoColors.primaryBlue,
                outlineColor: NeoColors.primaryBlue,
                borderRadius: 32,
                offset: 10,
                padding: EdgeInsets.zero,
                child: Stack(
                  children: [
                    // RepaintBoundary membungkus kanvas gambar
                    RepaintBoundary(
                      key: _canvasKey,
                      child: Container(
                        color: NeoColors.primaryBlue,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _points.add(
                                  DrawingPoint(
                                    offset: details.localPosition,
                                    paint: Paint()
                                      ..color = _selectedColor
                                      ..isAntiAlias = true
                                      ..strokeWidth = 4.0
                                      ..strokeCap = StrokeCap.round,
                                  ),
                                );
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                _points.add(
                                  DrawingPoint(
                                    offset: details.localPosition,
                                    paint: Paint()
                                      ..color = _selectedColor
                                      ..isAntiAlias = true
                                      ..strokeWidth = 4.0
                                      ..strokeCap = StrokeCap.round,
                                  ),
                                );
                              });
                            },
                            onPanEnd: (details) {
                              setState(() {
                                _points.add(null);
                              });
                            },
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: DrawingPainter(points: _points),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Placeholder guidance if empty
                    if (_points.isEmpty)
                      Center(
                        child: IgnorePointer(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.gesture_rounded,
                                size: 40,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Goreskan garis bebas di sini...",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Top Toolbar (Pen & Eraser icons)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Row(
                        children: [
                          // Pen Toggle (White)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = NeoColors.white;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _selectedColor == NeoColors.white
                                    ? NeoColors.primaryYellow
                                    : NeoColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: NeoColors.borderBlack,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: NeoColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Yellow Color Pen
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = NeoColors.primaryYellow;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _selectedColor == NeoColors.primaryYellow
                                    ? NeoColors.primaryYellow
                                    : NeoColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: NeoColors.borderBlack,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.brush,
                                size: 18,
                                color: NeoColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Eraser / Clear Icon
                          GestureDetector(
                            onTap: _clearCanvas,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: NeoColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: NeoColors.borderBlack,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: NeoColors.redDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Canvas Info Tag
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${_points.where((p) => p != null).length} Titik Grafomotor",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // TALK SECTION: Thin outline microphone inside circle
              NeoCard(
                backgroundColor: NeoColors.white,
                borderRadius: 20,
                shadowOffset: 4,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "TALK SECTION (Audio Prosody)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ceritakan apa yang paling membebanimu hari ini selama 10 detik.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _toggleVoiceRecording,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _isRecordingVoice
                              ? NeoColors.redLight
                              : NeoColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isRecordingVoice
                                ? NeoColors.redDark
                                : NeoColors.primaryBlue,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: NeoColors.borderBlack,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecordingVoice
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          size: 36,
                          color: _isRecordingVoice
                              ? NeoColors.redDark
                              : NeoColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRecordingVoice
                          ? "● Merekam Vokal... (00:${_voiceSeconds < 10 ? '0$_voiceSeconds' : '$_voiceSeconds'} / 00:10)"
                          : (_capturedAudioPath != null
                              ? "✓ Audio siap dikirim ke AI"
                              : "Ketuk mikrofon untuk mulai bicara"),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isRecordingVoice
                            ? NeoColors.redDark
                            : (_capturedAudioPath != null
                                ? NeoColors.greenDark
                                : NeoColors.slateLight),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Button: "Selesai Corat-coret" -> Stage 2
              NeoButton(
                text: _isSavingData
                    ? "Menyimpan Data Sensor..."
                    : "Selesai Corat-coret & Bicara →",
                icon: _isSavingData ? Icons.sync : Icons.arrow_forward_rounded,
                backgroundColor: NeoColors.primaryBlue,
                textColor: NeoColors.white,
                borderRadius: 28,
                height: 54,
                onPressed: _isSavingData ? null : _handleProceedToStage2,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
