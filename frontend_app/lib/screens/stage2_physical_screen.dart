import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import 'stage3_visual_screen.dart';

class Stage2PhysicalScreen extends StatefulWidget {
  /// Gambar coretan (PNG) dari Tahap 1
  final Uint8List? drawingBytes;

  /// Rekaman suara (WAV) dari Tahap 1
  final Uint8List? audioBytes;

  const Stage2PhysicalScreen({
    super.key,
    this.drawingBytes,
    this.audioBytes,
  });

  @override
  State<Stage2PhysicalScreen> createState() => _Stage2PhysicalScreenState();
}

class _Stage2PhysicalScreenState extends State<Stage2PhysicalScreen> {
  int _secondsRemaining = 10;
  bool _isTracking = false;
  bool _isFinished = false;
  bool _isCountingDown = false;
  String _countdownText = "Bersiap...";
  int _stepCount = 0;
  Timer? _timer;
  Timer? _countdownTimer;

  // Data sensor gait akselerometer (dummy list JSON & status gait_recorded)
  final Map<String, dynamic> _gaitData = {
    "status": "gait_recorded",
    "step_count": 14,
    "duration_seconds": 10,
    "accelerometer_samples": [
      {"t": 0.0, "x": 0.12, "y": 9.81, "z": 0.35},
      {"t": 2.0, "x": 0.45, "y": 10.12, "z": 0.88},
      {"t": 4.0, "x": 0.28, "y": 9.74, "z": 0.42},
      {"t": 6.0, "x": 0.62, "y": 10.35, "z": 0.95},
      {"t": 8.0, "x": 0.31, "y": 9.80, "z": 0.51},
      {"t": 10.0, "x": 0.15, "y": 9.79, "z": 0.22},
    ],
  };

  /// Memulai hitung mundur 3 detik sebelum sensor merekam (Bersiap... -> 3 -> 2 -> 1 -> Mulai!)
  void _startCountdownSequence() {
    _countdownTimer?.cancel();
    _timer?.cancel();

    setState(() {
      _isCountingDown = true;
      _isTracking = false;
      _isFinished = false;
      _secondsRemaining = 10;
      _stepCount = 0;
      _countdownText = "Bersiap...";
    });

    int step = 0;
    const steps = ["Bersiap...", "3", "2", "1", "Mulai!"];

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      step++;
      if (step < steps.length) {
        setState(() {
          _countdownText = steps[step];
        });
      } else {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
        // Sensor akselerometer/gyroscope mulai merekam tepat setelah 'Mulai!'
        _startTracking();
      }
    });
  }

  void _startTracking() {
    _timer?.cancel();
    setState(() {
      _isTracking = true;
      _isFinished = false;
      _secondsRemaining = 10;
      _stepCount = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
          _stepCount += (_secondsRemaining % 2 == 0) ? 2 : 1;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _stepCount = 14;
          _isTracking = false;
          _isFinished = true;
        });
        if (mounted) {
          _navigateToStage3();
        }
      }
    });
  }

  void _navigateToStage3() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Stage3VisualScreen(
          drawingBytes: widget.drawingBytes,
          audioBytes: widget.audioBytes,
          gaitData: _gaitData,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (10 - _secondsRemaining) / 10.0;

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
          "Tahap 2: Gait Tracker",
          style: TextStyle(
            color: NeoColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instruction Banner
              const NeoCard(
                backgroundColor: NeoColors.primaryYellow,
                borderRadius: 18,
                shadowOffset: 4,
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_walk_rounded,
                      size: 32,
                      color: NeoColors.black,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sensor Akselerometer Aktif",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: NeoColors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Taruh HP di saku atau genggam santai, lalu berjalanlah selama 10 detik.",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: NeoColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Circular Progress Ring & Timer
              Center(
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    color: NeoColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NeoColors.borderBlack,
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.borderBlack,
                        offset: Offset(8, 8),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular indicator ring
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: _isFinished ? 1.0 : (_isCountingDown ? 0.0 : progress),
                          strokeWidth: 14,
                          backgroundColor: NeoColors.lightGray,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isFinished
                                ? NeoColors.green
                                : (_isCountingDown
                                    ? NeoColors.amber
                                    : NeoColors.primaryBlue),
                          ),
                        ),
                      ),

                      // Content inside circle
                      if (_isFinished)
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 72,
                              color: NeoColors.greenDark,
                            ),
                            SizedBox(height: 6),
                            Text(
                              "10s SELESAI!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.greenDark,
                              ),
                            ),
                            Text(
                              "14 Langkah Terbaca",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: NeoColors.darkGray,
                              ),
                            ),
                          ],
                        )
                      else if (_isCountingDown)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(scale: animation, child: child),
                              child: Text(
                                _countdownText,
                                key: ValueKey<String>(_countdownText),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: (_countdownText.length <= 2) ? 68 : 28,
                                  fontWeight: FontWeight.w900,
                                  color: _countdownText == "Mulai!"
                                      ? NeoColors.greenDark
                                      : NeoColors.amber,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: NeoColors.lightGray,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: NeoColors.borderBlack,
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                "Taruh HP di saku",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: NeoColors.black,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (_isTracking)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${_secondsRemaining}s",
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.primaryBlue,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "dari 10 detik",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: NeoColors.slateMedium,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$_stepCount langkah terhitung",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: NeoColors.greenDark,
                              ),
                            ),
                          ],
                        )
                      else
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "0s",
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.primaryBlue,
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "dari 10 detik",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: NeoColors.slateMedium,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Gait Cadence",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: NeoColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Tracking Action Button
              if (!_isFinished) ...[
                NeoButton(
                  text: _isCountingDown
                      ? "Bersiap: $_countdownText"
                      : (_isTracking
                          ? "Sedang Merekam Langkah..."
                          : "Mulai Berjalan (10 Detik)"),
                  icon: (_isCountingDown || _isTracking)
                      ? Icons.sync
                      : Icons.play_arrow_rounded,
                  backgroundColor: (_isCountingDown || _isTracking)
                      ? NeoColors.amber
                      : NeoColors.primaryBlue,
                  textColor: NeoColors.white,
                  borderRadius: 28,
                  height: 54,
                  onPressed: (_isCountingDown || _isTracking)
                      ? null
                      : _startCountdownSequence,
                ),
              ] else ...[
                // Once finished, display "Lanjut Scan Mata" as requested
                NeoButton(
                  text: "Lanjut Scan Mata (Tahap 3) →",
                  icon: Icons.face_rounded,
                  backgroundColor: NeoColors.greenDark,
                  textColor: NeoColors.white,
                  borderRadius: 28,
                  height: 56,
                  onPressed: _navigateToStage3,
                ),
                const SizedBox(height: 10),
                NeoButton(
                  text: "Ulangi Tes Berjalan",
                  backgroundColor: NeoColors.white,
                  textColor: NeoColors.black,
                  borderRadius: 28,
                  height: 46,
                  onPressed: _startCountdownSequence,
                ),
              ],

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
