import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Circular progress ring with animated fill and color that changes
/// based on value (red → yellow → green).
///
/// Used for readiness scores, completion rates.
class TfProgressRing extends StatefulWidget {
  const TfProgressRing({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeOutCubic,
    this.showLabel = true,
    this.label,
    this.textStyle,
    this.semanticLabel,
  });

  /// Progress value between 0.0 and 1.0.
  final double value;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Duration duration;
  final Curve curve;
  final bool showLabel;
  final String? label;
  final TextStyle? textStyle;
  final String? semanticLabel;

  @override
  State<TfProgressRing> createState() => _TfProgressRingState();
}

class _TfProgressRingState extends State<TfProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _previousValue = widget.value;
    _controller.forward();
  }

  @override
  void didUpdateWidget(TfProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _previousValue, end: widget.value)
          .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _previousValue = widget.value;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns a color on the red → yellow → green gradient based on [t].
  static Color _valueColor(double t) {
    if (t < 0.5) {
      // Red to yellow
      return Color.lerp(
        const Color(0xFFE5484D),
        const Color(0xFFFBBF24),
        t * 2,
      )!;
    } else {
      // Yellow to green
      return Color.lerp(
        const Color(0xFFFBBF24),
        const Color(0xFF30A46C),
        (t - 0.5) * 2,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? const Color(0xFF1A1A1A);

    return Semantics(
      label: widget.semanticLabel ??
          '${(widget.value * 100).round()} percent complete',
      value: '${(widget.value * 100).round()}%',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final progress = _animation.value.clamp(0.0, 1.0);
          final color = _valueColor(progress);
          final percent = (progress * 100).round();

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: progress,
                color: color,
                backgroundColor: bg,
                strokeWidth: widget.strokeWidth,
              ),
              child: widget.showLabel
                  ? Center(
                      child: Text(
                        widget.label ?? '$percent%',
                        style: widget.textStyle ??
                            TextStyle(
                              fontFamily:
                                  DigitalAtelierTokens.dataFontFamily,
                              fontSize: widget.size * 0.2,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = backgroundColor;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.color != color;
}
