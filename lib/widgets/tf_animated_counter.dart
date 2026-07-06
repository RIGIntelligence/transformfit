import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Animated number counter that counts from 0 to [targetValue] with easing.
///
/// Used for readiness scores, rep counts, volume numbers.
class TfAnimatedCounter extends StatefulWidget {
  const TfAnimatedCounter({
    super.key,
    required this.targetValue,
    this.duration = const Duration(milliseconds: 1200),
    this.curve = Curves.easeOutCubic,
    this.textStyle,
    this.suffix = '',
    this.prefix = '',
    this.decimals = 0,
    this.semanticLabel,
  });

  final num targetValue;
  final Duration duration;
  final Curve curve;
  final TextStyle? textStyle;
  final String suffix;
  final String prefix;
  final int decimals;
  final String? semanticLabel;

  @override
  State<TfAnimatedCounter> createState() => _TfAnimatedCounterState();
}

class _TfAnimatedCounterState extends State<TfAnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.targetValue.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _controller.forward();
  }

  @override
  void didUpdateWidget(TfAnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.targetValue.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
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

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontFamily: DigitalAtelierTokens.dataFontFamily,
          fontWeight: FontWeight.w700,
          color: DigitalAtelierTokens.textPrimary,
        );
    final style = widget.textStyle ?? defaultStyle;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value.toStringAsFixed(widget.decimals);
        final display = '${widget.prefix}$value${widget.suffix}';
        return Semantics(
          label: widget.semanticLabel ?? 'Counter: ${widget.targetValue}${widget.suffix}',
          child: Text(display, style: style),
        );
      },
    );
  }
}
