import 'package:flutter/material.dart';

/// Widget yang menggambar ikon resmi Google "G" 4-warna secara vector
/// tanpa memerlukan asset eksternal/file gambar tambahan.
class GoogleIcon extends StatelessWidget {
  final double size;

  const GoogleIcon({super.key, this.size = 22.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final innerRadius = radius * 0.58;

    // Google Brand Colors
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw Red Segment (Top)
    paint.color = red;
    final redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 * 0.75,
        3.14159 * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(redPath, paint);

    // Draw Yellow Segment (Left)
    paint.color = yellow;
    final yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 * 1.25,
        3.14159 * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Draw Green Segment (Bottom)
    paint.color = green;
    final greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        3.14159 * 0.25,
        3.14159 * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(greenPath, paint);

    // Draw Blue Segment (Right)
    paint.color = blue;
    final bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 * 0.25,
        3.14159 * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(bluePath, paint);

    // Hollow Center (White donut cutout)
    paint.color = Colors.white;
    canvas.drawCircle(center, innerRadius, paint);

    // Blue horizontal bar for the "G" crossbar
    paint.color = blue;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx,
        center.dy - (radius * 0.18),
        center.dx + radius * 0.95,
        center.dy + (radius * 0.18),
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, paint);

    // Clear the right upper quadrant opening inside inner radius
    paint.color = Colors.white;
    final cutRect = Rect.fromLTRB(
      center.dx,
      center.dy - innerRadius,
      center.dx + radius,
      center.dy - (radius * 0.18),
    );
    canvas.drawRect(cutRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
