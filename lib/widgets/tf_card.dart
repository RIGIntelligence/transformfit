import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// TransformFit standardized card component.
///
/// Uses DigitalAtelier tokens exclusively — zero hardcoded values.
/// Supports optional accent left border, tap interaction with haptic feedback,
/// and elevated state.
///
/// Usage:
///   TfCard(
///     child: Text('Hello'),
///     onTap: () => print('tapped'),
///     accentColor: t.accentPrimary,
///   )
class TfCard extends StatelessWidget {
  const TfCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.accentColor,
    this.elevated = false,
    this.semanticLabel,
  });

  /// The card content.
  final Widget child;

  /// Inner padding. Defaults to DigitalAtelier spaceLg (16).
  final EdgeInsetsGeometry? padding;

  /// Tap callback. When non-null, the card becomes tappable with haptic feedback.
  final VoidCallback? onTap;

  /// Optional accent color for a left border stripe.
  final Color? accentColor;

  /// Whether to use elevated surface (surfaceElevated) instead of surface.
  final bool elevated;

  /// Semantic label for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    final decoration = BoxDecoration(
      color: elevated ? t.surfaceElevated : t.surface,
      borderRadius: BorderRadius.circular(t.radiusMd),
      border: Border.all(color: t.surfaceBorder, width: 1),
    );

    final cardContent = Container(
      decoration: accentColor != null
          ? decoration.copyWith(
              border: Border(
                left: BorderSide(color: accentColor!, width: 3),
                top: BorderSide(color: t.surfaceBorder, width: 1),
                right: BorderSide(color: t.surfaceBorder, width: 1),
                bottom: BorderSide(color: t.surfaceBorder, width: 1),
              ),
            )
          : decoration,
      padding: padding ?? EdgeInsets.all(t.spaceLg),
      child: child,
    );

    if (onTap != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(t.radiusMd),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap!();
            },
            borderRadius: BorderRadius.circular(t.radiusMd),
            child: cardContent,
          ),
        ),
      );
    }

    if (semanticLabel != null) {
      return Semantics(label: semanticLabel, child: cardContent);
    }

    return cardContent;
  }
}
