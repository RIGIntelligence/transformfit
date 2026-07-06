import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// TransformFit standardized button component.
///
/// Four variants: primary (orange), secondary (surface), danger (red), ghost.
/// All use DigitalAtelier tokens — radiusSm, 44px min height, Inter font.
///
/// Usage:
///   TfButton(
///     label: 'Log Set',
///     variant: TfButtonVariant.primary,
///     onPressed: () => _logSet(),
///   )
enum TfButtonVariant {
  /// Orange accent background, dark text.
  primary,

  /// Surface background, light text.
  secondary,

  /// Red accent background, light text.
  danger,

  /// Transparent background, light text.
  ghost,
}

class TfButton extends StatelessWidget {
  const TfButton({
    super.key,
    required this.label,
    this.variant = TfButtonVariant.primary,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.semanticLabel,
  });

  /// Button text.
  final String label;

  /// Visual variant.
  final TfButtonVariant variant;

  /// Callback. When null, the button is disabled.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether to stretch to full width.
  final bool expanded;

  /// Semantic label for screen readers (defaults to label).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    final colors = _resolveColors(variant, t, onPressed == null);
    final textStyle = TextStyle(
      fontFamily: DigitalAtelierExtension.dataFontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: colors.foreground,
    );

    Widget child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: colors.foreground),
          SizedBox(width: t.spaceSm),
        ],
        Text(label, style: textStyle),
      ],
    );

    if (expanded) {
      child = SizedBox(width: double.infinity, child: child);
    }

    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        height: 44,
        child: Material(
          color: colors.background,
          borderRadius: BorderRadius.circular(t.radiusSm),
          child: InkWell(
            onTap: onPressed != null
                ? () {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  }
                : null,
            borderRadius: BorderRadius.circular(t.radiusSm),
            splashColor: colors.foreground.withValues(alpha: 0.1),
            highlightColor: colors.foreground.withValues(alpha: 0.05),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: t.spaceLg),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(t.radiusSm),
                border: variant == TfButtonVariant.ghost
                    ? Border.all(color: t.surfaceBorder, width: 1)
                    : null,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Color resolution
// ---------------------------------------------------------------------------

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

_ButtonColors _resolveColors(
  TfButtonVariant variant,
  DigitalAtelierExtension t,
  bool disabled,
) {
  final muted = disabled ? 0.4 : 1.0;

  return switch (variant) {
    TfButtonVariant.primary => _ButtonColors(
        background: t.accentPrimary.withValues(alpha: muted),
        foreground: t.textInverse.withValues(alpha: muted),
      ),
    TfButtonVariant.secondary => _ButtonColors(
        background: t.surface.withValues(alpha: muted),
        foreground: t.textPrimary.withValues(alpha: muted),
      ),
    TfButtonVariant.danger => _ButtonColors(
        background: t.accentDanger.withValues(alpha: muted),
        foreground: t.textPrimary.withValues(alpha: muted),
      ),
    TfButtonVariant.ghost => _ButtonColors(
        background: Colors.transparent,
        foreground: t.textPrimary.withValues(alpha: muted),
      ),
  };
}
