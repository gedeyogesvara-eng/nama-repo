import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  int _secondsRemaining = 10;
  bool _isTracking = false;
  bool _isFinished = false;
  int _stepCount = 0;
  Timer? _timer;

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
    _timer?.cancel();
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
                            "Sensor Akselerometer Aktif",
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Taruh HP di saku atau genggam santai, lalu berjalanlah selama 10 detik.",
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
                        color: primaryBlue.withValues(alpha: isDark ? 0.3 : 0.14),
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
                          value: _isFinished ? 1.0 : progress,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : primaryBlue.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isFinished ? const Color(0xFF10B981) : primaryBlue,
                          ),
                        ),
                      ),

                      // Content inside circle
                      if (_isFinished)
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
                              "14 Langkah Terbaca",
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
                    onPressed: _isTracking ? null : _startTracking,
                    icon: Icon(
                      _isTracking ? Icons.sync : Icons.play_arrow_rounded,
                      size: 22,
                    ),
                    label: Text(
                      _isTracking ? "Sedang Merekam Langkah..." : "Mulai Berjalan (10 Detik)",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking ? const Color(0xFFF59E0B) : primaryBlue,
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
                    onPressed: _startTracking,
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
