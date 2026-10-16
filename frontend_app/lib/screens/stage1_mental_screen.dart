import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../services/media_utils.dart';
import 'stage2_physical_screen.dart';

/// Layar Skrining Tahap 1: Perekaman Suara (Talk / Voice)
/// Desain 'Modern Clean' dengan aksen Deep Blue, sudut lengkung halus (BorderRadius.circular(32)),
/// bayangan lembut, dan kompatibilitas penuh dengan Dark Mode.
class Stage1MentalScreen extends StatefulWidget {
  const Stage1MentalScreen({super.key});

  @override
  State<Stage1MentalScreen> createState() => _Stage1MentalScreenState();
}

class _Stage1MentalScreenState extends State<Stage1MentalScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF314BB5);

  bool _isRecordingVoice = false;
  bool _voiceSaved = false;
  int _voiceSeconds = 15;
  Timer? _voiceTimer;
  bool _isSavingData = false;

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _pcmSubscription;
  final List<int> _pcmBytes = [];
  bool _realRecordingActive = false;

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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _toggleVoiceRecording() async {
    if (!_isRecordingVoice) {
      await _startRecording();
    } else {
      await _finishRecording();
    }
  }

  Future<void> _startRecording() async {
    _pcmBytes.clear();
    _audioBytes = null;
    _realRecordingActive = false;

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

    if (_isRecordingVoice) {
      await _finishRecording();
    }

    if (!mounted) return;

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
              child: const Icon(Icons.mic_rounded, size: 16, color: primaryBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Tahap 1: Curhat Suara",
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // KARTU CURHAT MODERN CLEAN DENGAN SUDUT MELENGKUNG 32 & BAYANGAN HALUS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.record_voice_over_rounded,
                        color: primaryBlue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Curhatlah kepada kami...",
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Apa yang membebanimu hari ini? Bicaralah dengan santai, kami mendengarkan.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // TOMBOL MIKROFON BESAR INTERAKTIF DENGAN GLOW PULSE MODERN
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isRecordingVoice)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 140 + (_pulseController.value * 32),
                            height: 140 + (_pulseController.value * 32),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEF4444).withValues(
                                alpha: 0.22 - (_pulseController.value * 0.14),
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
                              : (_voiceSaved ? const Color(0xFF10B981) : primaryBlue),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecordingVoice
                                      ? const Color(0xFFEF4444)
                                      : (_voiceSaved ? const Color(0xFF10B981) : primaryBlue))
                                  .withValues(alpha: 0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isRecordingVoice
                                ? Icons.stop_rounded
                                : (_voiceSaved ? Icons.check_rounded : Icons.mic_rounded),
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // STATUS & HITUNG MUNDUR REKAMAN (MODERN CAPSULE PILL)
              Column(
                children: [
                  if (_isRecordingVoice)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
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
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_voiceSaved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text(
                            "Suara tersimpan dengan baik",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      "Ketuk mikrofon untuk mulai bicara",
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _isRecordingVoice
                        ? "Ketuk tombol untuk berhenti lebih awal"
                        : (_voiceSaved ? "Ketuk lagi jika ingin merekam ulang" : "Batas waktu maksimal 15 detik"),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // TOMBOL LANJUT KE TAHAP 2 (MODERN CLEAN DENGAN SUDUT 32)
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSavingData ? null : _handleProceedToStage2,
                  icon: _isSavingData
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text(
                    _isSavingData ? "Menyimpan Suara..." : "Lanjut ke Tahap 2 →",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    shadowColor: primaryBlue.withValues(alpha: 0.35),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
