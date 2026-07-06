import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/app_providers.dart';
import 'package:transformfit/features/emotion/emotional_experience_map.dart';
import 'package:transformfit/features/progress/progress_summary.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionStateProvider);
    final summary = buildProgressSummary(state);
    final emotion = ref.watch(emotionalExperienceMapProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: wide ? 32 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const TransformFitBrandMark(
                            width: 132,
                            semanticsLabel: 'TransformFitAI progress logo',
                          ),
                          const Spacer(),
                          Semantics(
                            button: true,
                            label: 'Return to Today',
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/'),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Today'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.28,
                                  ),
                                ),
                                minimumSize: const Size(120, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text('Progress', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'History, volume, and comeback proof without body ranking.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Semantics(
                            button: true,
                            label: 'Open composition trust',
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/composition'),
                              icon: const Icon(Icons.verified_user_outlined),
                              label: const Text('Composition trust'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                minimumSize: const Size(188, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _ProgressSignal(summary: summary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _CoachCue(summary: summary),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _ProgressSignal(summary: summary),
                            const SizedBox(height: 16),
                            _CoachCue(summary: summary),
                          ],
                        ),
                      const SizedBox(height: 16),
                      _EmotionalExperiencePanel(emotion: emotion),
                      const SizedBox(height: 16),
                      _ProgressLedger(summary: summary),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: child,
    );
  }
}

class _EmotionalExperiencePanel extends StatelessWidget {
  const _EmotionalExperiencePanel({required this.emotion});

  final EmotionalExperienceMap emotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: emotion.semanticLabel,
      child: _ProgressPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emotional map',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emotion.headline,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                _MiniPill(label: emotion.confidenceLabel),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(label: emotion.stage.label),
                _MiniPill(label: emotion.primaryFeeling),
                _MiniPill(label: emotion.sourceTraceLabel),
              ],
            ),
            const SizedBox(height: 16),
            _SignalLine(label: 'Promise', value: emotion.emotionalPromise),
            const SizedBox(height: 10),
            _SignalLine(
              label: 'Next experience',
              value: emotion.nextExperience,
            ),
            const SizedBox(height: 10),
            _SignalLine(label: 'Avoid', value: emotion.riskToAvoid),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final vector in emotion.vectors)
                      SizedBox(
                        width: wide
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: _EmotionVectorCard(vector: vector),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionVectorCard extends StatelessWidget {
  const _EmotionVectorCard({required this.vector});

  final EmotionalExperienceVector vector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: vector.semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(
            DigitalAtelierTokens.cornerRadius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vector.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(vector.state, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(vector.designResponse, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 32, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProgressSignal extends StatelessWidget {
  const _ProgressSignal({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: summary.semanticLabel,
      child: _ProgressPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  summary.hasProgress
                      ? Icons.insights_outlined
                      : Icons.hourglass_empty,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.headline,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary.subhead,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _MetricWrap(metrics: summary.metrics),
            const SizedBox(height: 20),
            _SignalLine(
              label: 'Volume signal',
              value: summary.volumeTrendLabel,
            ),
            const SizedBox(height: 10),
            _SignalLine(label: 'Top set', value: summary.topSet),
          ],
        ),
      ),
    );
  }
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.metrics});

  final List<ProgressMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        for (final metric in metrics)
          SizedBox(width: 128, child: _MetricColumn(metric: metric)),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.metric});

  final ProgressMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '${metric.label}: ${metric.spokenValue}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalLine extends StatelessWidget {
  const _SignalLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CoachCue extends StatelessWidget {
  const _CoachCue({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ProgressPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coach cue', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(summary.coachCue, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              border: Border(
                left: BorderSide(color: theme.colorScheme.primary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next best action',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.nextBestAction,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLedger extends StatelessWidget {
  const _ProgressLedger({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ProgressPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress ledger', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (summary.ledger.isEmpty)
            Text(
              'No completed sessions yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < summary.ledger.length; index += 1)
                  _LedgerRow(
                    entry: summary.ledger[index],
                    showDivider: index != summary.ledger.length - 1,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.showDivider});

  final ProgressLedgerEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: entry.semanticLabel,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    entry.dateLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.62,
                      ),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.kind,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.primary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  entry.secondary,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: DigitalAtelierTokens.dataFontFamily,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            ),
        ],
      ),
    );
  }
}
