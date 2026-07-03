import 'package:flutter/material.dart';
import 'package:transformfit/engine/fatigue.dart';
import 'package:transformfit/engine/recalibration.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

/// Trends screen (M6).
///
/// Shows weekly/monthly volume trends, ACWR status, readiness trend,
/// and recalibration results. All numbers come from deterministic engines.
class TrendsScreen extends StatelessWidget {
  final List<DailyVolume> volumeHistory;
  final List<RecalibrationResult> recalibrationResults;
  final List<int> recentReadinessScores;

  const TrendsScreen({
    super.key,
    this.volumeHistory = const [],
    this.recalibrationResults = const [],
    this.recentReadinessScores = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fatigue = volumeHistory.isNotEmpty ? computeFatigue(volumeHistory) : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TransformFitBrandMark(),
                  const SizedBox(height: 24),
                  Text('Trends', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Your training data, decoded.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ACWR / Fatigue section
                  if (fatigue != null) ...[
                    _SectionCard(
                      title: 'Workload Ratio',
                      child: _FatigueDisplay(result: fatigue),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Volume trend
                  if (volumeHistory.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Volume History',
                      child: _VolumeChart(history: volumeHistory),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Readiness trend
                  if (recentReadinessScores.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Readiness Trend',
                      child: _ReadinessTrend(scores: recentReadinessScores),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Recalibration results
                  if (recalibrationResults.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Training Max Recalibration',
                      child: _RecalibrationList(results: recalibrationResults),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Empty state
                  if (volumeHistory.isEmpty &&
                      recalibrationResults.isEmpty &&
                      recentReadinessScores.isEmpty)
                    const _EmptyState(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DigitalAtelierTokens.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        border: Border.all(
          color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FatigueDisplay extends StatelessWidget {
  final FatigueResult result;

  const _FatigueDisplay({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateColor = switch (result.state) {
      'safe' => Colors.green.shade400,
      'caution' => Colors.orange.shade400,
      'high' => Colors.red.shade400,
      _ => Colors.grey,
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACWR',
                style: theme.textTheme.labelSmall?.copyWith(
                      color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                    ),
              ),
              Text(
                result.acwr.toStringAsFixed(2),
                style: theme.textTheme.headlineSmall?.copyWith(color: stateColor),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acute Load',
                style: theme.textTheme.labelSmall?.copyWith(
                      color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                    ),
              ),
              Text(
                '${result.acuteLoad.toStringAsFixed(0)} kg/day',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chronic Load',
                style: theme.textTheme.labelSmall?.copyWith(
                      color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                    ),
              ),
              Text(
                '${result.chronicLoad.toStringAsFixed(0)} kg/day',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
            ),
            child: Text(
              result.state.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                    color: stateColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VolumeChart extends StatelessWidget {
  final List<DailyVolume> history;

  const _VolumeChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (history.length < 2) {
      return Text('Not enough data yet.', style: theme.textTheme.bodySmall);
    }

    final maxVolume = history.fold<double>(
      0,
      (prev, e) => e.volumeKg > prev ? e.volumeKg : prev,
    );
    if (maxVolume <= 0) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < history.length; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                child: FractionallySizedBox(
                  heightFactor: (history[i].volumeKg / maxVolume).clamp(0.02, 1.0),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadinessTrend extends StatelessWidget {
  final List<int> scores;

  const _ReadinessTrend({required this.scores});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (scores.isEmpty) return const SizedBox.shrink();

    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final last = scores.last;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Average',
                style: theme.textTheme.labelSmall?.copyWith(
                      color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                    ),
              ),
              Text(avg.toStringAsFixed(0), style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest',
                style: theme.textTheme.labelSmall?.copyWith(
                      color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                    ),
              ),
              Text('$last', style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trend',
                style: theme.textTheme.labelSmall?.copyWith(
                      color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                    ),
              ),
              Row(
                children: [
                  Icon(
                    last > avg ? Icons.trending_up : Icons.trending_down,
                    color: last > avg ? Colors.green.shade400 : Colors.orange.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    last > avg ? 'Improving' : 'Dipping',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecalibrationList extends StatelessWidget {
  final List<RecalibrationResult> results;

  const _RecalibrationList({required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: results.map((r) {
        final dirColor = switch (r.direction) {
          'up' => Colors.green.shade400,
          'down' => Colors.red.shade400,
          _ => Colors.grey,
        };
        final dirIcon = switch (r.direction) {
          'up' => Icons.arrow_upward,
          'down' => Icons.arrow_downward,
          _ => Icons.horizontal_rule,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(dirIcon, color: dirColor, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.exerciseId,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.oldTrainingMaxKg.toStringAsFixed(1)} → ${r.newTrainingMaxKg.toStringAsFixed(1)} kg',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '1RM: ${r.estimatedOneRmKg.toStringAsFixed(1)} kg',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No trends yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Log a few sessions to see your volume,\nreadiness, and training max trends.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
