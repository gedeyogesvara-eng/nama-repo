import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool _isRecordingVoice = false;
  int _voiceSeconds = 10;
  Timer? _voiceTimer;
  Color _selectedColor = NeoColors.white;

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
        }
      });
    } else {
      _voiceTimer?.cancel();
      setState(() {
        _isRecordingVoice = false;
      });
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

              // THE EXACT OFFSET CANVAS FOR DRAWING
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
                    // Interactive Drawing Surface
                    ClipRRect(
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

                    // Top Toolbar (Pen & Eraser icons as required)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Row(
                        children: [
                          // Pen Toggle
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
                          : "Ketuk mikrofon untuk mulai bicara",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isRecordingVoice
                            ? NeoColors.redDark
                            : NeoColors.slateLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Button: "Selesai Corat-coret" -> Stage 2
              NeoButton(
                text: "Selesai Corat-coret & Bicara →",
                icon: Icons.arrow_forward_rounded,
                backgroundColor: NeoColors.primaryBlue,
                textColor: NeoColors.white,
                borderRadius: 28,
                height: 54,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Stage2PhysicalScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
