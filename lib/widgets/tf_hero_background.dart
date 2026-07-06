import 'package:flutter/material.dart';

/// Reusable widget for image backgrounds with dark gradient overlay.
///
/// Renders [imagePath] with [BoxFit.cover], applies a dark gradient overlay
/// from top to bottom at [overlayOpacity], and layers [child] on top.
///
/// Usage:
///   TfHeroBackground(
///     imagePath: 'assets/images/home_hero.jpg',
///     child: Column(...),
///   )
class TfHeroBackground extends StatelessWidget {
  const TfHeroBackground({
    super.key,
    required this.imagePath,
    required this.child,
    this.overlayOpacity = 0.85,
    this.fit = BoxFit.cover,
  });

  /// Asset path for the background image.
  final String imagePath;

  /// Widget layered on top of the image + overlay.
  final Widget child;

  /// Opacity of the dark gradient overlay (0.0–1.0). Default 0.85.
  final double overlayOpacity;

  /// How the image fills the container. Default [BoxFit.cover].
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          imagePath,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // Fallback solid background if image not found
            return const ColoredBox(color: Color(0xFF0A0A0A));
          },
        ),
        // Dark gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: overlayOpacity),
                Colors.black.withValues(alpha: overlayOpacity * 0.7),
                Colors.black.withValues(alpha: overlayOpacity),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}
