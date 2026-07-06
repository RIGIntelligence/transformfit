import 'package:flutter/material.dart';

/// Compact metric display card for home screen and wellness dashboard.
///
/// Shows an icon (left), label + value (center), and trend arrow (right)
/// in a 44px-tall surface card with rounded corners.
///
/// Usage:
///   TfMetricCard(
///     icon: Icons.local_fire_department,
///     label: 'Calories',
///     value: '1,842',
///     trend: TrendDirection.up,
///     onTap: () => context.push('/nutrition'),
///   )
class TfMetricCard extends StatelessWidget {
  const TfMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
    this.onTap,
  });

  /// Leading icon.
  final IconData icon;

  /// Metric label (e.g. "Calories", "Steps").
  final String label;

  /// Metric value (e.g. "1,842", "8.2k").
  final String value;

  /// Optional trend indicator. Null hides the arrow.
  final TrendDirection? trend;

  /// Optional tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon
            Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 10),
            // Label + Value
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            // Trend arrow
            if (trend != null) _TrendArrow(direction: trend!),
          ],
        ),
      ),
    );
  }
}

/// Trend direction enum.
enum TrendDirection { up, down, neutral }

class _TrendArrow extends StatelessWidget {
  const _TrendArrow({required this.direction});

  final TrendDirection direction;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (direction) {
      TrendDirection.up => (Icons.arrow_upward, const Color(0xFF10B981)),
      TrendDirection.down => (Icons.arrow_downward, const Color(0xFFEF4444)),
      TrendDirection.neutral => (Icons.remove, const Color(0xFF9CA3AF)),
    };

    return Icon(icon, size: 16, color: color);
  }
}
