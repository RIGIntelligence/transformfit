import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Apple-style concentric activity rings showing workout, mindfulness,
/// and nutrition progress.
///
/// Usage:
///   ActivityRings(
///     workoutProgress: 0.75,
///     mindfulnessProgress: 0.50,
///     nutritionProgress: 0.90,
///   )
class ActivityRings extends StatefulWidget {
  const ActivityRings({
    super.key,
    required this.workoutProgress,
    required this.mindfulnessProgress,
    required this.nutritionProgress,
    this.size = 160,
    this.ringWidth = 12,
    this.gap = 6,
    this.animate = true,
    this.showLabels = true,
  });

  /// Progress from 0.0 to 1.0+ for each ring.
  final double workoutProgress;
  final double mindfulnessProgress;
  final double nutritionProgress;

  /// Outer diameter of the ring group.
  final double size;

  /// Stroke width of each ring.
  final double ringWidth;

  /// Gap between rings.
  final double gap;

  /// Animate fill on first appearance.
  final bool animate;

  /// Show labels around the rings.
  final bool showLabels;

  @override
  State<ActivityRings> createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<ActivityRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ActivityRingsPainter(
              workoutProgress: widget.workoutProgress,
              mindfulnessProgress: widget.mindfulnessProgress,
              nutritionProgress: widget.nutritionProgress,
              progress: _animation.value,
              ringWidth: widget.ringWidth,
              gap: widget.gap,
              workoutColor: t.accentPrimary, // orange
              mindfulnessColor: t.accentSecondary, // purple
              nutritionColor: t.accentTertiary, // green
              trackColor: t.surfaceBorder,
            ),
            child: widget.showLabels
                ? _buildLabels(t)
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildLabels(DigitalAtelierExtension t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RingLabel(
            icon: Icons.fitness_center,
            color: t.accentPrimary,
            percent: (widget.workoutProgress * 100).round(),
            style: t.textTheme.caption,
          ),
          const SizedBox(height: 4),
          _RingLabel(
            icon: Icons.self_improvement,
            color: t.accentSecondary,
            percent: (widget.mindfulnessProgress * 100).round(),
            style: t.textTheme.caption,
          ),
          const SizedBox(height: 4),
          _RingLabel(
            icon: Icons.restaurant,
            color: t.accentTertiary,
            percent: (widget.nutritionProgress * 100).round(),
            style: t.textTheme.caption,
          ),
        ],
      ),
    );
  }
}

class _RingLabel extends StatelessWidget {
  const _RingLabel({
    required this.icon,
    required this.color,
    required this.percent,
    required this.style,
  });

  final IconData icon;
  final Color color;
  final int percent;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text('$percent%', style: style.copyWith(color: color, fontSize: 10)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter — concentric arc rings
// ---------------------------------------------------------------------------

class _ActivityRingsPainter extends CustomPainter {
  _ActivityRingsPainter({
    required this.workoutProgress,
    required this.mindfulnessProgress,
    required this.nutritionProgress,
    required this.progress,
    required this.ringWidth,
    required this.gap,
    required this.workoutColor,
    required this.mindfulnessColor,
    required this.nutritionColor,
    required this.trackColor,
  });

  final double workoutProgress;
  final double mindfulnessProgress;
  final double nutritionProgress;
  final double progress;
  final double ringWidth;
  final double gap;
  final Color workoutColor;
  final Color mindfulnessColor;
  final Color nutritionColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Draw 3 rings: outermost = workout, middle = mindfulness, inner = nutrition
    final rings = <_RingData>[
      _RingData(
        progress: workoutProgress,
        color: workoutColor,
        radius: maxRadius - ringWidth / 2,
      ),
      _RingData(
        progress: mindfulnessProgress,
        color: mindfulnessColor,
        radius: maxRadius - ringWidth - gap - ringWidth / 2,
      ),
      _RingData(
        progress: nutritionProgress,
        color: nutritionColor,
        radius: maxRadius - (ringWidth + gap) * 2 - ringWidth / 2,
      ),
    ];

    const startAngle = -math.pi / 2;

    for (final ring in rings) {
      final rect = Rect.fromCircle(center: center, radius: ring.radius);

      // Track
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..color = trackColor;
      canvas.drawCircle(center, ring.radius, trackPaint);

      // Progress arc
      final sweepAngle =
          2 * math.pi * ring.progress.clamp(0.0, 1.0) * progress;
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round
        ..color = ring.color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_ActivityRingsPainter old) =>
      workoutProgress != old.workoutProgress ||
      mindfulnessProgress != old.mindfulnessProgress ||
      nutritionProgress != old.nutritionProgress ||
      progress != old.progress;
}

class _RingData {
  const _RingData({
    required this.progress,
    required this.color,
    required this.radius,
  });

  final double progress;
  final Color color;
  final double radius;
}
