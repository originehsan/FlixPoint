import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';

class CinemaScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Curved screen line
    final screenPaint = Paint()
      ..color = appthemecolor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final glowPaint = Paint()
      ..color = appthemecolor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(size.width * 0.05, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.5,
      0,
      size.width * 0.95,
      size.height * 0.6,
    );

    // Draw glow first
    canvas.drawPath(path, glowPaint);
    // Draw main line
    canvas.drawPath(path, screenPaint);

    // Light rays from screen
    final rayPaint = Paint()
      ..style = PaintingStyle.fill;

    final rayGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        appthemecolor.withValues(alpha: 0.08),
        Colors.transparent,
      ],
    );

    rayPaint.shader = rayGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final rayPath = Path();
    rayPath.moveTo(size.width * 0.05, size.height * 0.6);
    rayPath.quadraticBezierTo(
      size.width * 0.5,
      0,
      size.width * 0.95,
      size.height * 0.6,
    );
    rayPath.lineTo(size.width, size.height);
    rayPath.lineTo(0, size.height);
    rayPath.close();

    canvas.drawPath(rayPath, rayPaint);
  }

  @override
  bool shouldRepaint(CinemaScreenPainter oldDelegate) => false;
}