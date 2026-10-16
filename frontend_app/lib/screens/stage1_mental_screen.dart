import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../services/media_utils.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import 'stage2_physical_screen.dart';

/// Layar Skrining Tahap 1: Perekaman Suara (Talk / Voice)
/// Berfokus murni pada curhat suara pengguna dengan suasana yang hangat dan ramah,
/// tanpa instruksi teknis yang berbelit.
class Stage1MentalScreen extends StatefulWidget {
  const Stage1MentalScreen({super.key});

  @override
  State<Stage1MentalScreen> createState() => _Stage1MentalScreenState();
}

class _Stage1MentalScreenState extends State<Stage1MentalScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecordingVoice = false;
  bool _voiceSaved = false;
  int _voiceSeconds = 15;
  Timer? _voiceTimer;
  bool _isSavingData = false;

  // Perekam mikrofon dibuat lazy (hanya saat tombol mikrofon ditekan)
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _pcmSubscription;
  final List<int> _pcmBytes = [];
  bool _realRecordingActive = false;

  /// Audio WAV hasil rekaman (null jika belum merekam)
  Uint8List? _audioBytes;

  static const int _sampleRate = 16000;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceTimer?.cancel();
    _pcmSubscription?.cancel();
    final recorder = _recorder;
    if (recorder != null) {
      unawaited(recorder.dispose().catchError((_) {}));
    }
    super.dispose();
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

  Future<void> _handleProceedToStage2() async {
    if (_isSavingData) return;

    setState(() {
      _isSavingData = true;
    });

    // Jika masih merekam saat tombol ditekan, hentikan & simpan dulu
    if (_isRecordingVoice) {
      await _finishRecording();
    }

    if (!mounted) return;

    // Navigasikan ke Tahap 2 dengan membawa data Stage 1 (audio bytes)
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Stage2PhysicalScreen(
          drawingBytes: null,
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
              backgroundColor: NeoColors.primaryBlue,
              child: Icon(Icons.mic_rounded, size: 18, color: Colors.white),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Tahap 1: Curhat Suara",
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // KARTU CURHAT & TEKS RAMAH TO THE POINT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: NeoColors.primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NeoColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.record_voice_over_rounded,
                        color: NeoColors.primaryBlue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Curhatlah kepada kami...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Teks ramah satu kalimat sesuai permintaan user
                    const Text(
                      "Apa yang membebanimu hari ini? Bicaralah dengan santai, kami mendengarkan.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.darkGray,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // TOMBOL MIKROFON BESAR INTERAKTIF
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lingkaran animasi pulse saat sedang merekam
                    if (_isRecordingVoice)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 140 + (_pulseController.value * 28),
                            height: 140 + (_pulseController.value * 28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEF4444).withValues(
                                alpha: 0.25 - (_pulseController.value * 0.15),
                              ),
                            ),
                          );
                        },
                      ),

                    // Tombol Mikrofon Utama
                    GestureDetector(
                      onTap: _toggleVoiceRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: _isRecordingVoice
                              ? const Color(0xFFEF4444)
                              : (_voiceSaved ? const Color(0xFF10B981) : NeoColors.primaryBlue),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecordingVoice
                                      ? const Color(0xFFEF4444)
                                      : (_voiceSaved ? const Color(0xFF10B981) : NeoColors.primaryBlue))
                                  .withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isRecordingVoice
                                ? Icons.stop_rounded
                                : (_voiceSaved ? Icons.check_rounded : Icons.mic_rounded),
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // STATUS & HITUNG MUNDUR REKAMAN
              Column(
                children: [
                  if (_isRecordingVoice)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Merekam... Sisa $_voiceSeconds detik",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_voiceSaved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            "Suara tersimpan dengan baik",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      "Ketuk mikrofon untuk mulai bicara",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NeoColors.slateLight,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _isRecordingVoice
                        ? "Ketuk tombol untuk berhenti lebih awal"
                        : (_voiceSaved ? "Ketuk lagi jika ingin merekam ulang" : "Batas waktu maksimal 15 detik"),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // TOMBOL LANJUT KE TAHAP 2
              NeoButton(
                text: _isSavingData ? "Menyimpan Suara..." : "Lanjut ke Tahap 2 →",
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
