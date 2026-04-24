import 'dart:math';
import 'package:flutter/material.dart';

class WavyProgressIndicator extends StatefulWidget {
  final double progress; // 0 → 1
  final Color color;
  final double height;

  const WavyProgressIndicator({
    super.key,
    required this.progress,
    this.color = Colors.blue,
    this.height = 6,
  });

  @override
  State<WavyProgressIndicator> createState() => _WavyProgressIndicatorState();
}

class _WavyProgressIndicatorState extends State<WavyProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    // Fill the parent constraints instead of having a fixed 0 width
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _WavyPainter(
              progress: widget.progress,
              phase: _controller.value * 2 * pi,
              color: widget.color,
              height: widget.height,
            ),
          );
        },
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color color;
  final double height;

  _WavyPainter({
    required this.progress,
    required this.phase,
    required this.color,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The total angle for progress (0.4 means 40% of the circle)
    // To make it indeterminate-like, we can use a fixed arc (like progress)
    // but rotate the starting position with phase.

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    final center = Offset(size.width / 2, size.height / 2);
    // Base radius fits inside the container minus wave amplitude (height)
    final baseRadius =
        (size.width < size.height ? size.width : size.height) / 2 - height + 5;
    final waveAmplitude = height * 0.2;
    final wavesCount = 10; // Number of ripples around the circle

    // If progress is greater than 1, clamp it
    final clampedProgress = progress.clamp(0.0, 1.0);
    final arcAngle = 2 * pi * clampedProgress;

    if (arcAngle <= 0) return;

    // We animate the start angle so the entire arc rotates (loading on and on).
    // The phase also affects the ripple for an extra wavy effect.
    final startAngle = phase;
    final endAngle = startAngle + arcAngle;

    for (double angle = startAngle; angle <= endAngle; angle += 0.05) {
      // The wave travels along the arc
      double r =
          baseRadius + sin(angle * wavesCount - phase * 3) * waveAmplitude;
      double x = center.dx + r * cos(angle);
      double y = center.dy + r * sin(angle);

      if (angle == startAngle) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
