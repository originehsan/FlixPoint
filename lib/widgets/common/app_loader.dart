import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';

class AppLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoader({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 3,
  });

  // Small variant for buttons
  const AppLoader.small({
    super.key,
    this.color,
  })  : size = 20,
        strokeWidth = 2;

  // Large variant for full screen
  const AppLoader.large({
    super.key,
    this.color,
  })  : size = 56,
        strokeWidth = 4;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? appthemecolor;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _HotstarPainter(
            progress: _controller.value,
            color: color,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _HotstarPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _HotstarPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Spinning gradient arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * 3.14 * 2,
      3.14 * 1.5,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [
            color.withValues(alpha: 0.0),
            color,
          ],
          startAngle: 0,
          endAngle: 3.14 * 1.5,
          transform: GradientRotation(
            progress * 3.14 * 2,
          ),
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: radius,
          ),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HotstarPainter old) =>
      old.progress != progress;
}