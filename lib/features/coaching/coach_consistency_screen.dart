/// Coach-consistency screen — M7 Coaching milestone.
///
/// Shows coaching history, persona distribution, and a consistency score
/// that measures how well coaching messages adhere to doctrine rules.
///
/// Pure widget + deterministic model; the data comes from a list of
/// [CoachLogEntry] items (produced by the coaching system during use).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/features/coaching/persona_system.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

/// A single logged coaching entry — persona, message, timestamp, lint result.
class CoachLogEntry {
  const CoachLogEntry({
    required this.id,
    required this.persona,
    required this.message,
    required this.timestamp,
    required this.passed,
    required this.findingsCount,
    this.modelUsed = 'deterministic',
    this.isFallback = true,
  });

  final String id;
  final CoachingPersona persona;
  final String message;
  final DateTime timestamp;
  final bool passed;
  final int findingsCount;
  final String modelUsed;
  final bool isFallback;
}

/// Aggregated coaching consistency report.
class CoachConsistencyReport {
  const CoachConsistencyReport({
    required this.totalMessages,
    required this.passedMessages,
    required this.consistencyScore,
    required this.personaDistribution,
    required this.fallbackRate,
    required this.recentEntries,
  });

  final int totalMessages;
  final int passedMessages;
  final int consistencyScore; // 0–100
  final Map<CoachingPersona, int> personaDistribution;
  final double fallbackRate;
  final List<CoachLogEntry> recentEntries;
}

/// Compute a consistency report from a list of coach log entries.
/// Deterministic — same entries produce the same report.
CoachConsistencyReport computeConsistencyReport(List<CoachLogEntry> entries) {
  if (entries.isEmpty) {
    return const CoachConsistencyReport(
      totalMessages: 0,
      passedMessages: 0,
      consistencyScore: 100,
      personaDistribution: {},
      fallbackRate: 0.0,
      recentEntries: [],
    );
  }

  final total = entries.length;
  final passed = entries.where((e) => e.passed).length;
  final fallbacks = entries.where((e) => e.isFallback).length;
  final score = ((passed / total) * 100).round();

  // Persona distribution.
  final dist = <CoachingPersona, int>{};
  for (final entry in entries) {
    dist[entry.persona] = (dist[entry.persona] ?? 0) + 1;
  }

  // Recent entries (last 20, newest first).
  final sorted = List<CoachLogEntry>.from(entries)
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  final recent = sorted.take(20).toList(growable: false);

  return CoachConsistencyReport(
    totalMessages: total,
    passedMessages: passed,
    consistencyScore: score,
    personaDistribution: dist,
    fallbackRate: fallbacks / total,
    recentEntries: recent,
  );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// In-memory coach log provider. In production this would be backed by
/// a drift table or Supabase; for now it's seeded with sample entries
/// demonstrating the system.
class CoachLog extends Notifier<List<CoachLogEntry>> {
  @override
  List<CoachLogEntry> build() => _seedEntries();

  void add(CoachLogEntry entry) {
    state = [...state, entry];
  }
}

final coachLogProvider =
    NotifierProvider<CoachLog, List<CoachLogEntry>>(CoachLog.new);

/// Derived consistency report provider.
final coachConsistencyProvider = Provider<CoachConsistencyReport>((ref) {
  final entries = ref.watch(coachLogProvider);
  return computeConsistencyReport(entries);
});

List<CoachLogEntry> _seedEntries() {
  final now = DateTime(2026, 7, 3, 8, 0);
  return [
    CoachLogEntry(
      id: 'c1',
      persona: CoachingPersona.motivator,
      message: 'Readiness 72 and 2 sessions logged. Momentum is building.',
      timestamp: now.subtract(const Duration(hours: 2)),
      passed: true,
      findingsCount: 0,
      modelUsed: 'ollama:ornith:35b',
      isFallback: false,
    ),
    CoachLogEntry(
      id: 'c2',
      persona: CoachingPersona.analyst,
      message:
          'Volume: 3200 kg across 3 sessions. The data shows a clean upward path.',
      timestamp: now.subtract(const Duration(hours: 26)),
      passed: true,
      findingsCount: 0,
      modelUsed: 'ollama:ornith:35b',
      isFallback: false,
    ),
    CoachLogEntry(
      id: 'c3',
      persona: CoachingPersona.zen,
      message: '2 sore areas, readiness 48. Recovery is within normal range.',
      timestamp: now.subtract(const Duration(days: 2)),
      passed: true,
      findingsCount: 0,
      modelUsed: 'deterministic',
      isFallback: true,
    ),
    CoachLogEntry(
      id: 'c4',
      persona: CoachingPersona.challenger,
      message: '3 sessions done. Next week the bar moves.',
      timestamp: now.subtract(const Duration(days: 3)),
      passed: true,
      findingsCount: 0,
      modelUsed: 'ollama:ornith:35b',
      isFallback: false,
    ),
    CoachLogEntry(
      id: 'c5',
      persona: CoachingPersona.motivator,
      message: 'Session done. 4 promises kept. That consistency is the game.',
      timestamp: now.subtract(const Duration(days: 4)),
      passed: true,
      findingsCount: 0,
      modelUsed: 'ollama:ornith:35b',
      isFallback: false,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CoachConsistencyScreen extends ConsumerWidget {
  const CoachConsistencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(coachConsistencyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
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
                      _buildHeader(context, theme),
                      const SizedBox(height: 28),
                      _buildConsistencyScoreCard(context, theme, report),
                      const SizedBox(height: 20),
                      _buildPersonaDistribution(context, theme, report),
                      const SizedBox(height: 20),
                      _buildHistorySection(context, theme, report),
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

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        const TransformFitBrandMark(
          width: 132,
          semanticsLabel: 'TransformFitAI coach consistency logo',
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
              ),
              minimumSize: const Size(120, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsistencyScoreCard(
    BuildContext context,
    ThemeData theme,
    CoachConsistencyReport report,
  ) {
    final score = report.consistencyScore;
    final scoreColor = score >= 90
        ? DigitalAtelierTokens.accentOrange
        : score >= 70
            ? DigitalAtelierTokens.textPrimary.withValues(alpha: 0.8)
            : DigitalAtelierTokens.errorText;

    return Semantics(
      label: 'Coach consistency score: $score out of 100. '
          '${report.passedMessages} of ${report.totalMessages} messages passed.',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consistency score',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 56,
                    color: scoreColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    '/ 100',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const Spacer(),
                _buildScoreBadge(theme, score),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildStatChip(
                  theme,
                  label: 'Messages',
                  value: '${report.totalMessages}',
                ),
                _buildStatChip(
                  theme,
                  label: 'Passed',
                  value: '${report.passedMessages}',
                ),
                _buildStatChip(
                  theme,
                  label: 'Fallback rate',
                  value: '${(report.fallbackRate * 100).round()}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(ThemeData theme, int score) {
    final label = score >= 90 ? 'Excellent' : score >= 70 ? 'Good' : 'Needs work';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: DigitalAtelierTokens.accentOrange,
        ),
      ),
    );
  }

  Widget _buildStatChip(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: DigitalAtelierTokens.dataFontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonaDistribution(
    BuildContext context,
    ThemeData theme,
    CoachConsistencyReport report,
  ) {
    final dist = report.personaDistribution;
    final total = report.totalMessages;

    return Semantics(
      label: 'Persona distribution across coaching messages',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Persona distribution', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final persona in CoachingPersona.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPersonaBar(
                  theme,
                  persona: persona,
                  count: dist[persona] ?? 0,
                  total: total,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaBar(
    ThemeData theme, {
    required CoachingPersona persona,
    required int count,
    required int total,
  }) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            persona.label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: DigitalAtelierTokens.accentOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          child: Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    ThemeData theme,
    CoachConsistencyReport report,
  ) {
    final entries = report.recentEntries;

    return Semantics(
      label: 'Coaching message history, ${entries.length} recent entries',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent coaching', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Text(
                'No coaching messages yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHistoryItem(theme, entry),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ThemeData theme, CoachLogEntry entry) {
    final statusColor = entry.passed
        ? DigitalAtelierTokens.accentOrange.withValues(alpha: 0.6)
        : DigitalAtelierTokens.errorText;
    final timeStr =
        '${entry.timestamp.month}/${entry.timestamp.day} '
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.persona.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  if (entry.isFallback)
                    Text(
                      'fallback',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                entry.message,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
