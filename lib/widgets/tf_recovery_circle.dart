import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Whoop-style recovery circle widget.
///
/// Displays a gradient ring (red → yellow → green) with the recovery
/// score number in the center and zone label below.
///
/// Usage:
///   TfRecoveryCircle(score: 78, size: 120)
class TfRecoveryCircle extends StatefulWidget {
  const TfRecoveryCircle({
    super.key,
    required this.score,
    this.size = 120,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  /// Recovery score 0–100.
  final int score;

  /// Diameter of the circle in logical pixels.
  final double size;

  /// Duration of the fill animation on first appearance.
  final Duration animationDuration;

  @override
  State<TfRecoveryCircle> createState() => _TfRecoveryCircleState();
}

class _TfRecoveryCircleState extends State<TfRecoveryCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RecoveryCirclePainter(
            score: widget.score,
            progress: _animation.value,
          ),
        );
      },
    );
  }
}

/// Returns the zone label for a given score.
String _zoneLabel(int score) {
  if (score >= 67) return 'Push';
  if (score >= 34) return 'Maintain';
  return 'Deload';
}

/// Returns the color for a given score on the red→yellow→green gradient.
Color _zoneColor(double t) {
  // t is 0.0–1.0 where 0 = red, 0.5 = yellow, 1 = green.
  if (t < 0.5) {
    return Color.lerp(
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      t * 2,
    )!;
  }
  return Color.lerp(
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    (t - 0.5) * 2,
  )!;
}

class _RecoveryCirclePainter extends CustomPainter {
  _RecoveryCirclePainter({
    required this.score,
    required this.progress,
  });

  final int score;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.08;
    final innerRadius = radius - strokeWidth;

    // Background ring (dark track)
    final trackPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, innerRadius, trackPaint);

    // Gradient ring (red → yellow → green) — animated fill
    final sweepAngle = 2 * math.pi * (score / 100) * progress;
    final scoreNorm = score / 100.0;

    // Build gradient shader
    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Create a sweep gradient
    final rect = Rect.fromCircle(center: center, radius: innerRadius);
    gradientPaint.shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [
        _zoneColor(0),
        _zoneColor(0.33),
        _zoneColor(0.5),
        _zoneColor(0.67),
        _zoneColor(1.0),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    ).createShader(rect);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -math.pi / 2,
      sweepAngle,
      false,
      gradientPaint,
    );

    // Score number in center
    final scorePainter = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size.width * 0.35,
          fontWeight: FontWeight.w700,
          height: 1.0,
          color: _zoneColor(scoreNorm),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scorePainter.paint(
      canvas,
      Offset(
        center.dx - scorePainter.width / 2,
        center.dy - scorePainter.height / 2 - size.height * 0.04,
      ),
    );

    // Zone label below score
    final zonePainter = TextPainter(
      text: TextSpan(
        text: _zoneLabel(score),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size.width * 0.1,
          fontWeight: FontWeight.w500,
          height: 1.0,
          color: const Color(0xFF9CA3AF),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    zonePainter.paint(
      canvas,
      Offset(
        center.dx - zonePainter.width / 2,
        center.dy + scorePainter.height / 2 + size.height * 0.02,
      ),
    );
  }

  @override
  bool shouldRepaint(_RecoveryCirclePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.progress != progress;
  }
}
