import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Whoop-style recovery circle — the iconic 0-100% color-coded ring.
///
/// Usage:
///   RecoveryCircle(score: 72)
///   RecoveryCircle(score: 35, size: 200)
class RecoveryCircle extends StatefulWidget {
  const RecoveryCircle({
    super.key,
    required this.score,
    this.size = 160,
    this.strokeWidth = 14,
    this.animate = true,
  }) : assert(score >= 0 && score <= 100);

  /// Recovery score from 0 to 100.
  final int score;

  /// Diameter of the circle in logical pixels.
  final double size;

  /// Width of the ring stroke.
  final double strokeWidth;

  /// Whether to animate the fill on first appearance.
  final bool animate;

  @override
  State<RecoveryCircle> createState() => _RecoveryCircleState();
}

class _RecoveryCircleState extends State<RecoveryCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final zone = _RecoveryZone.fromScore(widget.score);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _RecoveryCirclePainter(
              score: widget.score,
              progress: _animation.value,
              strokeWidth: widget.strokeWidth,
              accentPrimary: t.accentPrimary,
              accentDanger: t.accentDanger,
              warning: t.warning,
              success: t.success,
              textPrimary: t.textPrimary,
              textMuted: t.textMuted,
              surfaceBorder: t.surfaceBorder,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(widget.score * _animation.value).round()}',
                    style: t.textTheme.dataLarge.copyWith(
                      fontSize: widget.size * 0.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    zone.label,
                    style: t.textTheme.caption.copyWith(
                      color: zone.color,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recovery zone classification
// ---------------------------------------------------------------------------

enum _RecoveryZone {
  needsAttention(label: 'NEEDS ATTENTION', threshold: 0),
  recovering(label: 'RECOVERING', threshold: 34),
  maintaining(label: 'MAINTAINING', threshold: 67),
  thriving(label: 'THRIVING', threshold: 85);

  const _RecoveryZone({required this.label, required this.threshold});

  final String label;
  final int threshold;

  static _RecoveryZone fromScore(int score) {
    if (score >= 85) return _RecoveryZone.thriving;
    if (score >= 67) return _RecoveryZone.maintaining;
    if (score >= 34) return _RecoveryZone.recovering;
    return _RecoveryZone.needsAttention;
  }

  Color get color {
    switch (this) {
      case _RecoveryZone.needsAttention:
        return const Color(0xFFEF4444);
      case _RecoveryZone.recovering:
        return const Color(0xFFF59E0B);
      case _RecoveryZone.maintaining:
        return const Color(0xFF10B981);
      case _RecoveryZone.thriving:
        return const Color(0xFF10B981);
    }
  }
}

// ---------------------------------------------------------------------------
// CustomPainter — the gradient ring
// ---------------------------------------------------------------------------

class _RecoveryCirclePainter extends CustomPainter {
  _RecoveryCirclePainter({
    required this.score,
    required this.progress,
    required this.strokeWidth,
    required this.accentPrimary,
    required this.accentDanger,
    required this.warning,
    required this.success,
    required this.textPrimary,
    required this.textMuted,
    required this.surfaceBorder,
  });

  final int score;
  final double progress;
  final double strokeWidth;
  final Color accentPrimary;
  final Color accentDanger;
  final Color warning;
  final Color success;
  final Color textPrimary;
  final Color textMuted;
  final Color surfaceBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = surfaceBorder;
    canvas.drawCircle(center, radius, bgPaint);

    // Gradient arc
    final sweepAngle = 2 * math.pi * (score / 100) * progress;
    const startAngle = -math.pi / 2;

    // Build gradient from red → yellow → green
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + 2 * math.pi,
      colors: [
        accentDanger, // 0% — red
        warning, // 33% — yellow/orange
        success, // 67% — green
        success, // 100% — green
      ],
      stops: const [0.0, 0.33, 0.67, 1.0],
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(_RecoveryCirclePainter old) =>
      score != old.score || progress != old.progress;
}
