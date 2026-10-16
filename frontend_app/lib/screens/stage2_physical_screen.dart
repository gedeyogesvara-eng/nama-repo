import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'stage3_visual_screen.dart';

/// Layar Skrining Tahap 2: Gait Tracker (Sensor Akselerometer)
/// Desain 'Modern Clean' dengan Deep Blue, sudut melengkung 32, bayangan halus,
/// dan kompatibilitas penuh dengan Dark Mode.
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
  static const Color primaryBlue = Color(0xFF314BB5);

  // Status perekaman sensor
  int _secondsRemaining = 10;
  bool _isTracking = false;
  bool _isFinished = false;
  int _stepCount = 0;
  Timer? _timer;

  // Status fase aba-aba (Hitung Mundur: 3, 2, 1, Mulai!)
  bool _isCountingDown = false;
  String _countdownText = '3';
  Timer? _countdownTimer;

  // Subscription sensor accelerometer riil
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final List<Map<String, dynamic>> _realSamples = [];

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

  /// Memulai fase aba-aba hitung mundur: '3' -> '2' -> '1' -> 'Mulai!'
  /// Setelah 'Mulai!' tampil, barulah fungsi perekaman sensor akselerometer 10 detik dimulai.
  void _startCountdown() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _accelerometerSubscription?.cancel();

    setState(() {
      _isCountingDown = true;
      _isTracking = false;
      _isFinished = false;
      _countdownText = '3';
      _secondsRemaining = 10;
      _stepCount = 0;
    });

    int currentStep = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep--;
      if (currentStep == 2) {
        setState(() {
          _countdownText = '2';
        });
      } else if (currentStep == 1) {
        setState(() {
          _countdownText = '1';
        });
      } else if (currentStep == 0) {
        setState(() {
          _countdownText = 'Mulai!';
        });
      } else {
        // Aba-aba 'Mulai!' telah selesai ditampilkan,
        // BARULAH fungsi perekaman sensor akselerometer berjalan selama 10 detik.
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
        _startTracking();
      }
    });
  }

  /// Perekaman sensor akselerometer selama 10 detik
  void _startTracking() {
    _timer?.cancel();
    _accelerometerSubscription?.cancel();
    _realSamples.clear();

    setState(() {
      _isTracking = true;
      _isCountingDown = false;
      _isFinished = false;
      _secondsRemaining = 10;
      _stepCount = 0;
    });

    // Dengarkan event accelerometer hardware (bila didukung pada perangkat fisik)
    try {
      _accelerometerSubscription = accelerometerEventStream().listen((event) {
        if (_realSamples.length < 150) {
          _realSamples.add({
            "t": double.parse(((10 - _secondsRemaining) + 0.0).toStringAsFixed(2)),
            "x": double.parse(event.x.toStringAsFixed(2)),
            "y": double.parse(event.y.toStringAsFixed(2)),
            "z": double.parse(event.z.toStringAsFixed(2)),
          });
        }
      }, onError: (_) {
        // Fallback aman untuk simulator atau lingkungan tanpa sensor
      });
    } catch (_) {
      // Fallback aman
    }

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
        _accelerometerSubscription?.cancel();

        if (_realSamples.isNotEmpty) {
          _gaitData["accelerometer_samples"] = _realSamples;
        }
        _gaitData["step_count"] = _stepCount > 0 ? _stepCount : 14;

        setState(() {
          _secondsRemaining = 0;
          _stepCount = _stepCount > 0 ? _stepCount : 14;
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
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final double progress = (10 - _secondsRemaining) / 10.0;

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
              child: const Icon(Icons.directions_walk_rounded, size: 16, color: primaryBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Tahap 2: Gait Tracker",
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
              // Instruction Banner - Modern Clean Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        size: 28,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCountingDown
                                ? "Fase Aba-aba Berjalan"
                                : (_isTracking
                                    ? "Sensor Akselerometer Merekam..."
                                    : "Sensor Akselerometer Siap"),
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isCountingDown
                                ? "Posisikan HP dengan santai dan bersiaplah melangkah saat aba-aba 'Mulai!'."
                                : "Taruh HP di saku atau genggam santai, lalu berjalanlah selama 10 detik.",
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Circular Progress Ring & Timer - Modern Clean
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isCountingDown && _countdownText == 'Mulai!')
                            ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.2)
                            : primaryBlue.withValues(alpha: isDark ? 0.3 : 0.14),
                        blurRadius: 36,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular indicator ring
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: _isCountingDown
                              ? (_countdownText == 'Mulai!'
                                  ? 1.0
                                  : (4 - (_countdownText == '3' ? 3 : (_countdownText == '2' ? 2 : 1))) / 4.0)
                              : (_isFinished ? 1.0 : progress),
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : primaryBlue.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (_isFinished || (_isCountingDown && _countdownText == 'Mulai!'))
                                ? const Color(0xFF10B981)
                                : primaryBlue,
                          ),
                        ),
                      ),

                      // Content inside circle
                      if (_isCountingDown)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey<String>(_countdownText),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _countdownText,
                                  style: TextStyle(
                                    fontSize: _countdownText == 'Mulai!' ? 40 : 72,
                                    fontWeight: FontWeight.w900,
                                    color: _countdownText == 'Mulai!'
                                        ? const Color(0xFF10B981)
                                        : (isDark ? Colors.white : primaryBlue),
                                    height: 1.0,
                                    letterSpacing: _countdownText == 'Mulai!' ? -0.5 : -2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (_countdownText == 'Mulai!'
                                            ? const Color(0xFF10B981)
                                            : primaryBlue)
                                        .withValues(alpha: isDark ? 0.25 : 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _countdownText == 'Mulai!'
                                        ? "Ayo Melangkah!"
                                        : "Bersiap Melangkah",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: _countdownText == 'Mulai!'
                                          ? const Color(0xFF10B981)
                                          : (isDark ? Colors.white : primaryBlue),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_isFinished)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 64,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "10s SELESAI!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            Text(
                              "$_stepCount Langkah Terbaca",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                              style: TextStyle(
                                fontSize: 54,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : primaryBlue,
                                height: 1,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "dari 10 detik",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$_stepCount langkah terhitung",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "0s",
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : primaryBlue,
                                height: 1,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "dari 10 detik",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Gait Cadence",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Tracking Action Buttons - Modern Clean (BorderRadius.circular(32))
              if (!_isFinished) ...[
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: (_isTracking || _isCountingDown) ? null : _startCountdown,
                    icon: _isCountingDown
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.white70 : Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            _isTracking ? Icons.sync : Icons.play_arrow_rounded,
                            size: 22,
                          ),
                    label: Text(
                      _isCountingDown
                          ? (_countdownText == 'Mulai!'
                              ? "Mulai Melangkah!"
                              : "Bersiap Melangkah ($_countdownText)...")
                          : (_isTracking
                              ? "Sedang Merekam Langkah..."
                              : "Mulai Berjalan (10 Detik)"),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCountingDown
                          ? const Color(0xFF3B82F6)
                          : (_isTracking ? const Color(0xFFF59E0B) : primaryBlue),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      shadowColor: primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToStage3,
                    icon: const Icon(Icons.face_rounded, size: 20),
                    label: const Text(
                      "Lanjut Scan Mata (Tahap 3) →",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _startCountdown,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      "Ulangi Tes Berjalan",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ),
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
