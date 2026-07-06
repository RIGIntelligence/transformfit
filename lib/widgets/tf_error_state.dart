import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Reusable error state with icon, message, and optional retry button.
///
/// Use when a data load fails or a session error occurs.
/// Follows Digital Atelier design system — zero hardcoded colors.
///
/// Usage:
///   TfErrorState(
///     icon: Icons.cloud_off,
///     title: 'Connection lost',
///     message: 'Check your internet and try again.',
///     onRetry: () => ref.invalidate(someProvider),
///   )
class TfErrorState extends StatelessWidget {
  const TfErrorState({
    super.key,
    this.icon = Icons.error_outline,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  /// Icon displayed at the top. Defaults to [Icons.error_outline].
  final IconData icon;

  /// Primary error title (e.g. 'Something went wrong').
  final String title;

  /// Descriptive message explaining the error.
  final String message;

  /// Callback for the retry button. If null, no button is shown.
  final VoidCallback? onRetry;

  /// Label for the retry button. Defaults to 'Try Again'.
  final String retryLabel;

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
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.accentDanger.withValues(alpha: 0.12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: t.accentDanger,
                ),
              ),
              SizedBox(height: t.spaceLg),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: t.spaceSm),

              // Message
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: t.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),

              // Retry button
              if (onRetry != null) ...[
                SizedBox(height: t.spaceLg),
                Semantics(
                  button: true,
                  label: retryLabel,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(retryLabel),
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
