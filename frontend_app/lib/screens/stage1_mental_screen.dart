import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:record/record.dart';
import '../services/media_utils.dart';
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
  bool _voiceSaved = false;
  int _voiceSeconds = 15;
  Timer? _voiceTimer;
  Color _selectedColor = NeoColors.white;
  bool _isSavingData = false;

  // Perekam mikrofon dibuat lazy (hanya saat tombol mikrofon ditekan)
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _pcmSubscription;
  final List<int> _pcmBytes = [];
  bool _realRecordingActive = false;

  /// Audio WAV hasil rekaman (null jika belum merekam)
  Uint8List? _audioBytes;

  static const int _sampleRate = 16000;

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _pcmSubscription?.cancel();
    final recorder = _recorder;
    if (recorder != null) {
      unawaited(recorder.dispose().catchError((_) {}));
    }
    super.dispose();
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  void _showInfo(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: isError ? NeoColors.redDark : NeoColors.slateDark,
      ),
    );
  }

  Future<void> _toggleVoiceRecording() async {
    if (!_isRecordingVoice) {
      await _startRecording();
    } else {
      // Tombol ditekan kedua kali: berhenti merekam & simpan suara
      await _finishRecording();
    }
  }

  Future<void> _startRecording() async {
    _pcmBytes.clear();
    _audioBytes = null;
    _realRecordingActive = false;

    // Coba mikrofon nyata (Web: izin browser, Android/iOS: izin sistem).
    // Jika gagal, rekaman disimulasikan agar alur tidak macet.
    try {
      final recorder = _recorder ??= AudioRecorder();
      if (await recorder.hasPermission()) {
        final stream = await recorder.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ));
        _pcmSubscription = stream.listen(
          _pcmBytes.addAll,
          onError: (Object e) => debugPrint('Stream mikrofon error: $e'),
        );
        _realRecordingActive = true;
      } else {
        _showInfo(
          'Izin mikrofon ditolak. Rekaman disimulasikan agar skrining tetap berjalan.',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Mikrofon tidak tersedia: $e');
      _showInfo('Mikrofon tidak tersedia. Rekaman disimulasikan agar skrining tetap berjalan.');
    }

    if (!mounted) return;
    setState(() {
      _isRecordingVoice = true;
      _voiceSaved = false;
      _voiceSeconds = 15;
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
        _finishRecording();
      }
    });
  }

  Future<void> _finishRecording() async {
    _voiceTimer?.cancel();
    if (!_isRecordingVoice) return;

    if (_realRecordingActive) {
      try {
        await _recorder?.stop();
      } catch (e) {
        debugPrint('Gagal menghentikan perekam: $e');
      }
      await _pcmSubscription?.cancel();
      _pcmSubscription = null;
      _realRecordingActive = false;
    }

    // PCM16 mono 16 kHz -> WAV. Kurang dari ~0,1 detik dianggap gagal -> sintetis.
    if (_pcmBytes.length >= _sampleRate ~/ 5) {
      _audioBytes = MediaUtils.pcm16ToWav(Uint8List.fromList(_pcmBytes), sampleRate: _sampleRate);
    } else {
      _audioBytes = MediaUtils.generateSyntheticWav(sampleRate: _sampleRate);
    }

    if (!mounted) return;
    setState(() {
      _isRecordingVoice = false;
      _voiceSaved = true;
    });
  }

  /// Mengekspor kanvas coretan menjadi bytes PNG (aman di Web & mobile).
  /// Mengembalikan null bila gagal/timeout -> AIService memakai PNG placeholder.
  Future<Uint8List?> _captureCanvasPng() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) {
        return null;
      }
      final ui.Image image = await boundary
          .toImage(pixelRatio: 1.0)
          .timeout(const Duration(milliseconds: 300));
      final ByteData? data = await image
          .toByteData(format: ui.ImageByteFormat.png)
          .timeout(const Duration(milliseconds: 300));
      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('⚠️ Gagal mengekspor kanvas: $e');
      return null;
    }
  }

  Future<void> _handleProceedToStage2() async {
    if (_isSavingData) return;

    setState(() {
      _isSavingData = true;
    });

    // Jika masih merekam saat tombol ditekan, hentikan & simpan dulu
    if (_isRecordingVoice) {
      await _finishRecording();
    }

    final Uint8List? drawingBytes = await _captureCanvasPng();

    if (!mounted) return;

    // Navigasikan ke Tahap 2 dengan membawa data Stage 1 (bytes)
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Stage2PhysicalScreen(
          drawingBytes: drawingBytes,
          audioBytes: _audioBytes,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isSavingData = false;
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
            Expanded(
              child: Text(
                "Tahap 1: Draw & Talk",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: NeoColors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
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
              // ==========================================
              // BAGIAN DRAW (Super Sederhana & To The Point)
              // ==========================================
              const Text(
                "Draw",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Gambarlah apapun yang ada di kepala Anda.",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NeoColors.darkGray,
                ),
              ),
              const SizedBox(height: 14),

              // Kanvas Menggambar Responsif untuk Semua HP Android
              LayoutBuilder(
                builder: (context, constraints) {
                  final double canvasWidth = (constraints.maxWidth - 12).clamp(240.0, 360.0);
                  final double canvasHeight = (canvasWidth * 0.85).clamp(200.0, 260.0);

                  return OffsetCanvasBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    backgroundColor: NeoColors.primaryBlue,
                    outlineColor: NeoColors.primaryBlue,
                    borderRadius: 28,
                    offset: 8,
                    padding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        // RepaintBoundary membungkus kanvas gambar
                        RepaintBoundary(
                          key: _canvasKey,
                          child: Container(
                            color: NeoColors.primaryBlue,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
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

                        // Placeholder sederhana jika kanvas masih kosong
                        if (_points.isEmpty)
                          Center(
                            child: IgnorePointer(
                              child: Text(
                                "Goreskan garis bebas di sini...",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                        // Toolbar Sederhana: Ganti Warna & Hapus
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _selectedColor = NeoColors.white),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _selectedColor == NeoColors.white
                                        ? NeoColors.primaryYellow
                                        : NeoColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: NeoColors.borderBlack, width: 2),
                                  ),
                                  child: const Icon(Icons.edit, size: 18, color: NeoColors.black),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _selectedColor = NeoColors.primaryYellow),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _selectedColor == NeoColors.primaryYellow
                                        ? NeoColors.primaryYellow
                                        : NeoColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: NeoColors.borderBlack, width: 2),
                                  ),
                                  child: const Icon(Icons.brush, size: 18, color: NeoColors.black),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _clearCanvas,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: NeoColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: NeoColors.borderBlack, width: 2),
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
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ==========================================
              // BAGIAN TALK (Suara Dinamis & To The Point)
              // ==========================================
              NeoCard(
                backgroundColor: NeoColors.white,
                borderRadius: 20,
                shadowOffset: 4,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    const Text(
                      "Talk",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ceritakan apa yang membebanimu hari ini...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tombol Mikrofon Dinamis
                    // Saat ditekan pertama: Berubah merah (sedang merekam)
                    // Saat ditekan lagi: Berhenti dan keterangan "Suara tersimpan"
                    GestureDetector(
                      onTap: _toggleVoiceRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: _isRecordingVoice
                              ? const Color(0xFFEF4444)
                              : (_voiceSaved ? const Color(0xFF10B981) : const Color(0xFFF1F0EA)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NeoColors.borderBlack,
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
                        child: Center(
                          child: Icon(
                            _isRecordingVoice
                                ? Icons.stop_rounded
                                : (_voiceSaved ? Icons.check_rounded : Icons.mic_rounded),
                            size: 38,
                            color: (_isRecordingVoice || _voiceSaved)
                                ? Colors.white
                                : NeoColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Keterangan Status Suara Dinamis
                    Text(
                      _isRecordingVoice
                          ? "● Sedang Merekam... (Ketuk untuk berhenti)"
                          : (_voiceSaved ? "Suara tersimpan" : "Ketuk mikrofon untuk mulai bicara"),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _isRecordingVoice
                            ? const Color(0xFFEF4444)
                            : (_voiceSaved ? const Color(0xFF059669) : NeoColors.slateLight),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              NeoButton(
                text: _isSavingData ? "Menyimpan Data..." : "Lanjut ke Tahap 2 →",
                icon: _isSavingData ? Icons.sync : Icons.arrow_forward_rounded,
                backgroundColor: NeoColors.primaryBlue,
                textColor: NeoColors.white,
                borderRadius: 28,
                height: 54,
                onPressed: _isSavingData ? null : _handleProceedToStage2,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
