import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Breathing circle for rest timer / mindfulness.
///
/// Expands on inhale (4 s), holds (4 s), contracts on exhale (4 s).
/// Total cycle: 12 s. Uses [CustomPainter] with gradient fill.
class TfBreathingCircle extends StatefulWidget {
  const TfBreathingCircle({
    super.key,
    this.size = 200,
    this.inhaleDuration = const Duration(seconds: 4),
    this.holdDuration = const Duration(seconds: 4),
    this.exhaleDuration = const Duration(seconds: 4),
    this.color,
    this.showLabel = true,
    this.autoplay = true,
    this.semanticLabel = 'Breathing guide',
  });

  final double size;
  final Duration inhaleDuration;
  final Duration holdDuration;
  final Duration exhaleDuration;
  final Color? color;
  final bool showLabel;
  final bool autoplay;
  final String semanticLabel;

  @override
  State<TfBreathingCircle> createState() => _TfBreathingCircleState();
}

class _TfBreathingCircleState extends State<TfBreathingCircle>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _breathAnimation;
  String _phase = 'Inhale';

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.inhaleDuration +
        widget.holdDuration +
        widget.exhaleDuration;
    _controller = AnimationController(vsync: this, duration: totalDuration);

    final inhaleEnd = widget.inhaleDuration.inMilliseconds /
        totalDuration.inMilliseconds;
    final holdEnd = (widget.inhaleDuration.inMilliseconds +
            widget.holdDuration.inMilliseconds) /
        totalDuration.inMilliseconds;

    // Build a TweenSequence: 0→1 during inhale, hold at 1, 1→0 during exhale.
    _breathAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: inhaleEnd * 100,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: holdEnd * 100 - inhaleEnd * 100,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: (1 - holdEnd) * 100,
      ),
    ]).animate(_controller)
      ..addListener(() {
        final t = _controller.value;
        final newPhase =
            t < inhaleEnd ? 'Inhale' : t < holdEnd ? 'Hold' : 'Exhale';
        if (newPhase != _phase) setState(() => _phase = newPhase);
      });

    if (widget.autoplay) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? DigitalAtelierTokens.accentOrange;

    return Semantics(
      label: widget.semanticLabel,
      child: AnimatedBuilder(
        animation: _breathAnimation,
        builder: (context, child) {
          final t = _breathAnimation.value;
          final currentSize = widget.size * (0.5 + 0.5 * t);

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: CustomPaint(
                size: Size(currentSize, currentSize),
                painter: _BreathingCirclePainter(
                  progress: t,
                  accent: accent,
                  background: DigitalAtelierTokens.background,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BreathingCirclePainter extends CustomPainter {
  _BreathingCirclePainter({
    required this.progress,
    required this.accent,
    required this.background,
  });

  final double progress;
  final Color accent;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Outer glow
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..color = accent.withValues(alpha: 0.3 * progress);
    canvas.drawCircle(center, radius + 10, glowPaint);

    // Gradient fill
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.6 * progress),
          accent.withValues(alpha: 0.2 * progress),
          background.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, gradientPaint);

    // Border ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = accent.withValues(alpha: 0.5 + 0.5 * progress);
    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(_BreathingCirclePainter old) =>
      old.progress != progress || old.accent != accent;
}
