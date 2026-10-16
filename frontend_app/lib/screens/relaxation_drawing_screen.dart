import 'package:flutter/material.dart';

/// Model untuk titik coretan pada kanvas relaksasi
class RelaxationDrawingPoint {
  final Offset offset;
  final Paint paint;

  RelaxationDrawingPoint({required this.offset, required this.paint});
}

/// Custom painter untuk menggambar garis halus pada kanvas
class RelaxationCanvasPainter extends CustomPainter {
  final List<RelaxationDrawingPoint?> points;

  RelaxationCanvasPainter({required this.points});

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
  bool shouldRepaint(covariant RelaxationCanvasPainter oldDelegate) {
    return true;
  }
}

/// Layar Khusus Kanvas Relaksasi Menggambar
/// Memberikan ruang bebas bagi pengguna untuk melepaskan penat dan stres
/// melalui coretan warna-warni yang menenangkan.
class RelaxationDrawingScreen extends StatefulWidget {
  const RelaxationDrawingScreen({super.key});

  @override
  State<RelaxationDrawingScreen> createState() => _RelaxationDrawingScreenState();
}

class _RelaxationDrawingScreenState extends State<RelaxationDrawingScreen> {
  static const Color primaryBlue = Color(0xFF314BB5);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color darkText = Color(0xFF0F172A);

  final List<RelaxationDrawingPoint?> _points = [];
  Color _selectedColor = primaryBlue;
  double _strokeWidth = 5.0;

  final List<Color> _palette = const [
    primaryBlue,
    Color(0xFFF59E0B), // Warm Amber
    Color(0xFF10B981), // Emerald Green
    Color(0xFFEF4444), // Coral Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF0F172A), // Midnight Slate
    Color(0xFF64748B), // Soft Gray
  ];

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Kanvas dibersihkan. Silakan mulai corat-coret kembali!",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Relaksasi Menggambar",
              style: TextStyle(
                color: darkText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              "Lepaskan penatmu dengan coretan bebas",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Bersihkan Kanvas",
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFEF4444)),
            onPressed: _points.isEmpty ? null : _clearCanvas,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          child: Column(
            children: [
              // PALET WARNA & KETEBALAN KUAS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Pilihan Warna
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _palette.map((color) {
                            final isSelected = _selectedColor == color;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isSelected ? 34 : 26,
                                height: isSelected ? 34 : 26,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? primaryBlue : Colors.white,
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const VerticalDivider(width: 16, thickness: 1, color: Color(0xFFE2E8F0)),

                    // Pilihan Ukuran Kuas
                    Row(
                      children: [
                        _buildStrokeButton(3.0, "Kecil"),
                        const SizedBox(width: 4),
                        _buildStrokeButton(6.0, "Sedang"),
                        const SizedBox(width: 4),
                        _buildStrokeButton(12.0, "Tebal"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // AREA KANVAS
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              _points.add(
                                RelaxationDrawingPoint(
                                  offset: details.localPosition,
                                  paint: Paint()
                                    ..color = _selectedColor
                                    ..isAntiAlias = true
                                    ..strokeWidth = _strokeWidth
                                    ..strokeCap = StrokeCap.round,
                                ),
                              );
                            });
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              _points.add(
                                RelaxationDrawingPoint(
                                  offset: details.localPosition,
                                  paint: Paint()
                                    ..color = _selectedColor
                                    ..isAntiAlias = true
                                    ..strokeWidth = _strokeWidth
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
                            painter: RelaxationCanvasPainter(points: _points),
                          ),
                        ),

                        // Placeholder teks saat kanvas masih kosong
                        if (_points.isEmpty)
                          Center(
                            child: IgnorePointer(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.brush_rounded,
                                    size: 42,
                                    color: primaryBlue.withValues(alpha: 0.25),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Sentuh & goreskan jari bebas di sini...",
                                    style: TextStyle(
                                      color: const Color(0xFF64748B).withValues(alpha: 0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tidak ada aturan, nikmati prosesnya.",
                                    style: TextStyle(
                                      color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // TOMBOL KELUAR / SELESAI
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "Relaksasi selesai! Semoga pikiranmu jauh lebih segar.",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    "Selesai & Segarkan Pikiran",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeButton(double size, String label) {
    final isSelected = _strokeWidth == size;
    return GestureDetector(
      onTap: () => setState(() => _strokeWidth = size),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Container(
            width: size + 6,
            height: size + 6,
            decoration: BoxDecoration(
              color: isSelected ? primaryBlue : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
