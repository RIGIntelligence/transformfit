import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Reusable empty state with icon, title, subtitle, and optional action button.
///
/// Use when a screen has no data to display (no results, no achievements, etc.).
///
/// Usage:
///   TfEmptyState(
///     icon: Icons.search_off,
///     title: 'No results found',
///     subtitle: 'Try a different search term.',
///     actionLabel: 'Clear Search',
///     onAction: () => controller.clear(),
///   )
class TfEmptyState extends StatelessWidget {
  const TfEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Icon displayed at the top.
  final IconData icon;

  /// Primary empty state title.
  final String title;

  /// Descriptive subtitle explaining the empty state.
  final String subtitle;

  /// Label for the optional action button. If null, no button is shown.
  final String? actionLabel;

  /// Callback for the action button. If null, no button is shown.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceLg,
          vertical: t.spaceXxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.surfaceElevated,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: t.textMuted,
                ),
              ),
              SizedBox(height: t.spaceLg),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: t.spaceSm),

              // Subtitle
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: t.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),

              // Action button
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: t.spaceLg),
                Semantics(
                  button: true,
                  label: actionLabel,
                  child: OutlinedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
