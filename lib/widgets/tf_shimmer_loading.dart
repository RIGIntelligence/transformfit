import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Shimmer loading placeholder for cards, text lines, and avatars.
///
/// Dark-theme compatible — uses subtle brightness shifts on the
/// [DigitalAtelierTokens.background] base.
class TfShimmerLoading extends StatefulWidget {
  const TfShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  State<TfShimmerLoading> createState() => _TfShimmerLoadingState();
}

class _TfShimmerLoadingState extends State<TfShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? const Color(0xFF1A1A1A);
    final highlight = widget.highlightColor ?? const Color(0xFF2A2A2A);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
        (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
        (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// Pre-built shimmer shapes for common loading patterns.
class TfShimmerBox extends StatelessWidget {
  const TfShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius:
            borderRadius ?? BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
    );
  }
}

/// Shimmer placeholder for avatar circles.
class TfShimmerAvatar extends StatelessWidget {
  const TfShimmerAvatar({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF222222),
      ),
    );
  }
}

/// Full card-level shimmer skeleton.
class TfShimmerCard extends StatelessWidget {
  const TfShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const TfShimmerLoading(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TfShimmerAvatar(size: 36),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TfShimmerBox(width: 120, height: 12),
                      SizedBox(height: 6),
                      TfShimmerBox(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TfShimmerBox(height: 14),
            SizedBox(height: 8),
            TfShimmerBox(height: 14),
            SizedBox(height: 8),
            TfShimmerBox(width: 200, height: 14),
          ],
        ),
      ),
    );
  }
}
