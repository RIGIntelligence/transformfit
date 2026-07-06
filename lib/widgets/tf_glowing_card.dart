import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Card with subtle glow on the accent-colored border.
///
/// Supports gradient background, shimmer loading state, and tap animation.
class TfGlowingCard extends StatefulWidget {
  const TfGlowingCard({
    super.key,
    required this.child,
    this.onTap,
    this.glowColor,
    this.gradientColors,
    this.isLoading = false,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.borderRadius,
    this.glowIntensity = 0.4,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? glowColor;
  final List<Color>? gradientColors;
  final bool isLoading;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BorderRadius? borderRadius;
  final double glowIntensity;
  final String? semanticLabel;

  @override
  State<TfGlowingCard> createState() => _TfGlowingCardState();
}

class _TfGlowingCardState extends State<TfGlowingCard>
    with TickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isLoading) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(TfGlowingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!widget.isLoading && _shimmerController.isAnimating) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _tapController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _tapController.forward();
  void _onTapUp(TapUpDetails _) => _tapController.reverse();
  void _onTapCancel() => _tapController.reverse();

  @override
  Widget build(BuildContext context) {
    final accent = widget.glowColor ?? DigitalAtelierTokens.accentOrange;
    final radius =
        widget.borderRadius ??
            BorderRadius.circular(DigitalAtelierTokens.cornerRadius);

    Widget card = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: widget.gradientColors != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradientColors!,
                )
              : null,
          color: widget.gradientColors == null
              ? const Color(0xFF141414)
              : null,
          border: Border.all(
            color: accent.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: widget.glowIntensity * 0.3),
              blurRadius: 16,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: accent.withValues(alpha: widget.glowIntensity * 0.15),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: widget.isLoading
              ? _ShimmerContent(
                  controller: _shimmerController,
                  padding: widget.padding,
                )
              : Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
        ),
      ),
    );

    if (widget.onTap != null) {
      card = GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: card,
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      child: card,
    );
  }
}

class _ShimmerContent extends StatelessWidget {
  const _ShimmerContent({
    required this.controller,
    required this.padding,
  });

  final AnimationController controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFF1A1A1A),
                Color(0xFF2A2A2A),
                Color(0xFF1A1A1A),
              ],
              stops: [
                (controller.value - 0.3).clamp(0.0, 1.0),
                controller.value,
        (controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 14,
                  width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
