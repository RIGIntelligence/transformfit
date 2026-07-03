import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

/// Recommit flow (M6).
///
/// Shown after a missed training week. Displays the gap, a adjusted plan
/// for getting back on track, and a single CTA to recommit.
class RecommitScreen extends StatelessWidget {
  final int missedDays;
  final int previousWeeklyTarget;
  final int newWeeklyTarget;
  final VoidCallback? onRecommit;

  const RecommitScreen({
    super.key,
    this.missedDays = 7,
    this.previousWeeklyTarget = 3,
    this.newWeeklyTarget = 2,
    this.onRecommit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TransformFitBrandMark(),
                  const SizedBox(height: 24),
                  Text('Welcome Back', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'No judgment. Let\'s get you moving again.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 28),

                  // Missed gap
                  _RecommitStat(
                    icon: Icons.event_busy,
                    label: 'Days away',
                    value: '$missedDays',
                  ),
                  const SizedBox(height: 12),

                  // Previous target
                  _RecommitStat(
                    icon: Icons.fitness_center,
                    label: 'Your previous target',
                    value: '$previousWeeklyTarget sessions/week',
                  ),
                  const SizedBox(height: 12),

                  // New adjusted target
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
                      border: Border.all(
                        color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.adjust,
                          color: DigitalAtelierTokens.accentOrange,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adjusted target',
                                style: theme.textTheme.labelSmall?.copyWith(
                                      color: DigitalAtelierTokens.accentOrange,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$newWeeklyTarget sessions this week',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'We scaled back to rebuild the habit. '
                                'You\'ll ramp back up as consistency returns.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRecommit,
                      icon: const Icon(Icons.play_arrow),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Recommit to training'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Secondary
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        'Not ready yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  DigitalAtelierTokens.textPrimary.withValues(alpha: 0.4),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommitStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RecommitStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DigitalAtelierTokens.background.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                        color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                      ),
                ),
                Text(value, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
