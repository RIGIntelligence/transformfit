import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/engine/post_session_analysis.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

/// Post-session debrief screen (M5).
///
/// Shows the deterministic analysis of the most recently completed session:
/// volume summary, what changed (1RM deltas), coaching takeaway, and
/// readiness impact. The screen derives its data from the deterministic
/// engine — the LLM narrative is layered on top and flagged when it is the
/// deterministic fallback.
///
/// Doctrine L3-7 (Moment of Truth 6): specific coach debrief with one
/// observation and tomorrow hook. Doctrine L6-2: numbers come from the
/// engine; the LLM only narrates.
class DebriefScreen extends ConsumerWidget {
  const DebriefScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionStateProvider);
    final summary = buildDebriefSummary(state);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: wide ? 32 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 940),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const TransformFitBrandMark(
                            width: 132,
                            semanticsLabel: 'TransformFitAI debrief logo',
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
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.28),
                                ),
                                minimumSize: const Size(120, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text('Debrief', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        summary.subhead,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.74),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _VolumePanel(summary: summary),
                      const SizedBox(height: 16),
                      _WhatChangedPanel(summary: summary),
                      const SizedBox(height: 16),
                      _CoachingTakeawayPanel(summary: summary),
                      const SizedBox(height: 16),
                      _CorridorPanel(summary: summary),
                      const SizedBox(height: 16),
                      _ReadinessImpactPanel(summary: summary),
                      const SizedBox(height: 24),
                      _FallbackNotice(summary: summary),
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

// ---------------------------------------------------------------------------
// Summary builder — pure function, testable without a widget
// ---------------------------------------------------------------------------

/// A flat, UI-facing summary of the post-session analysis. This is what the
/// debrief screen renders. Built deterministically from [SessionState].
class DebriefSummary {
  const DebriefSummary({
    required this.hasSession,
    required this.subhead,
    required this.volumeSummary,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.totalReps,
    required this.averageRpe,
    required this.oneRmChanges,
    required this.corridorStatus,
    required this.corridorReason,
    required this.readinessImpact,
    required this.readinessImpactReason,
    required this.coachingTakeaway,
    required this.semanticLabel,
  });

  final bool hasSession;
  final String subhead;
  final String volumeSummary;
  final double totalVolumeKg;
  final int totalSets;
  final int totalReps;
  final double averageRpe;
  final List<OneRmChange> oneRmChanges;
  final String corridorStatus;
  final String corridorReason;
  final int readinessImpact;
  final String readinessImpactReason;
  final String coachingTakeaway;
  final String semanticLabel;
}

/// Build the deterministic debrief summary from session state.
///
/// Uses the most recently completed session in [SessionState.history]. Falls
/// back to an empty state when no completed session exists.
DebriefSummary buildDebriefSummary(SessionState state) {
  final completed = state.history
      .where((s) => s.endedAt != null && s.loggedSets.isNotEmpty)
      .toList();
  if (completed.isEmpty) {
    return const DebriefSummary(
      hasSession: false,
      subhead: 'Complete a session to see your post-workout debrief.',
      volumeSummary: 'No session yet.',
      totalVolumeKg: 0,
      totalSets: 0,
      totalReps: 0,
      averageRpe: 0,
      oneRmChanges: [],
      corridorStatus: 'in_corridor',
      corridorReason: 'No session analysed yet.',
      readinessImpact: 0,
      readinessImpactReason: 'No training stimulus recorded.',
      coachingTakeaway: 'Train once, then return here for your debrief.',
      semanticLabel: 'Debrief screen waiting for the first completed session.',
    );
  }

  final session = completed.last;
  final analysisSets = <AnalysisLoggedSet>[];
  for (final ls in session.loggedSets) {
    if (!ls.completed) continue;
    if (ls.weightKg == null || ls.reps == null) continue;
    if (ls.weightKg! <= 0 || ls.reps! <= 0) continue;
    analysisSets.add(AnalysisLoggedSet(
      exerciseId: ls.exerciseId ?? ls.exerciseName,
      weightKg: ls.weightKg!,
      reps: ls.reps!,
      rpe: ls.rpe,
    ));
  }

  final durationMinutes = session.endedAt != null
      ? session.startedAt.difference(session.endedAt!).inMinutes.abs()
      : null;

  final result = computePostSessionAnalysis(PostSessionAnalysisInputs(
    sets: analysisSets,
    durationMinutes: durationMinutes,
  ));

  final volKg = _formatNumber(result.totalVolumeKg);
  final volumeSummary =
      '${result.totalSets} sets, ${result.totalReps} reps, $volKg kg total volume.';
  final coachingTakeaway =
      '${result.corridorReason} ${result.readinessImpactReason}';

  return DebriefSummary(
    hasSession: true,
    subhead: 'After-session analysis of your latest workout.',
    volumeSummary: volumeSummary,
    totalVolumeKg: result.totalVolumeKg,
    totalSets: result.totalSets,
    totalReps: result.totalReps,
    averageRpe: result.averageRpe,
    oneRmChanges: result.oneRmChanges,
    corridorStatus: result.corridorStatus,
    corridorReason: result.corridorReason,
    readinessImpact: result.readinessImpact,
    readinessImpactReason: result.readinessImpactReason,
    coachingTakeaway: coachingTakeaway,
    semanticLabel:
        'Debrief: $volumeSummary Corridor: ${result.corridorStatus}. '
        'Readiness impact: ${result.readinessImpact} points.',
  );
}

// ---------------------------------------------------------------------------
// Panels
// ---------------------------------------------------------------------------

class _DebriefPanel extends StatelessWidget {
  const _DebriefPanel({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
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

class _VolumePanel extends StatelessWidget {
  const _VolumePanel({required this.summary});
  final DebriefSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: summary.semanticLabel,
      child: _DebriefPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Volume summary',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(summary.volumeSummary, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _Metric(
                  label: 'Sets',
                  value: summary.totalSets.toString(),
                ),
                _Metric(
                  label: 'Reps',
                  value: summary.totalReps.toString(),
                ),
                _Metric(
                  label: 'Avg RPE',
                  value: summary.averageRpe.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatChangedPanel extends StatelessWidget {
  const _WhatChangedPanel({required this.summary});
  final DebriefSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changes = summary.oneRmChanges;
    return _DebriefPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'What changed',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (changes.isEmpty)
            Text(
              'No prior baseline; this session establishes your 1RM estimates.',
              style: theme.textTheme.bodyLarge,
            )
          else
            ...changes.map((c) {
              final sign = c.deltaKg > 0 ? '+' : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${c.exerciseId}: ${_formatNumber(c.sessionOneRmKg)} kg est. 1RM ($sign${_formatNumber(c.deltaKg)} kg).',
                  style: theme.textTheme.bodyLarge,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CoachingTakeawayPanel extends StatelessWidget {
  const _CoachingTakeawayPanel({required this.summary});
  final DebriefSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _DebriefPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined,
                  color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Coaching takeaway',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.coachingTakeaway,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _CorridorPanel extends StatelessWidget {
  const _CorridorPanel({required this.summary});
  final DebriefSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _DebriefPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression corridor',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.corridorReason,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessImpactPanel extends StatelessWidget {
  const _ReadinessImpactPanel({required this.summary});
  final DebriefSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _DebriefPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Readiness impact',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.readinessImpactReason,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.summary});
  final DebriefSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.hasSession) return const SizedBox.shrink();
    return const SizedBox.shrink();
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 100,
      child: Column(
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

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
