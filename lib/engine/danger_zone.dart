/// Danger-zone engine — M8 safety milestone.
///
/// Detects dangerous training patterns and returns severity + recommended
/// action. Pure and deterministic; the Deno mirror must agree.
///
/// Doctrine L6-2: this engine owns the danger assessment. The LLM may only
/// narrate. A surfaced deterministic fallback is used on LLM failure.
library;

import 'package:meta/meta.dart';

/// Input snapshot for danger-zone evaluation.
@immutable
class DangerZoneInput {
  final double acwr; // acute:chronic workload ratio
  final double monotony; // weekly volume / daily std dev
  final List<SetRpe> recentHardSets; // last session's hard sets
  final int missedSessionsInLast14Days;
  final double? bodyWeightChangePercent; // week-over-week, optional

  const DangerZoneInput({
    required this.acwr,
    required this.monotony,
    this.recentHardSets = const [],
    this.missedSessionsInLast14Days = 0,
    this.bodyWeightChangePercent,
  });
}

@immutable
class SetRpe {
  final String exerciseId;
  final double rpe;

  const SetRpe({required this.exerciseId, required this.rpe});
}

/// A single danger-zone signal.
@immutable
class DangerSignal {
  final String code; // e.g. 'ACWR_HIGH', 'RPE_SPIKE'
  final String severity; // 'watch' | 'warning' | 'critical'
  final String title;
  final String detail;
  final String recommendedAction;

  const DangerSignal({
    required this.code,
    required this.severity,
    required this.title,
    required this.detail,
    required this.recommendedAction,
  });

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity,
        'title': title,
        'detail': detail,
        'recommendedAction': recommendedAction,
      };
}

/// Result of a danger-zone evaluation.
@immutable
class DangerZoneResult {
  final List<DangerSignal> signals;
  final String overallSeverity; // highest severity among signals, or 'clear'

  const DangerZoneResult({
    required this.signals,
    required this.overallSeverity,
  });

  Map<String, Object?> toJson() => {
        'signals': signals.map((s) => s.toJson()).toList(),
        'overallSeverity': overallSeverity,
      };
}

/// Evaluate danger-zone signals from training data.
///
/// Detection rules:
/// 1. ACWR > 1.5 → critical (injury risk)
/// 2. ACWR 1.3–1.5 → warning
/// 3. Monotony > 2.0 → warning (repetitive stress)
/// 4. 3+ consecutive sets with RPE ≥ 9.5 → critical (CNS overload)
/// 5. 3+ consecutive sets with RPE 9.0–9.4 → warning
/// 6. Body weight change > 3% in a week → warning (water/glycogen/health)
/// 7. Body weight change > 5% in a week → critical
/// 8. 3+ missed sessions in 14 days → watch (consistency risk)
DangerZoneResult evaluateDangerZones(DangerZoneInput input) {
  final signals = <DangerSignal>[];

  // 1-2: ACWR checks
  if (input.acwr > 1.5) {
    signals.add(const DangerSignal(
      code: 'ACWR_HIGH',
      severity: 'critical',
      title: 'Acute:chronic workload too high',
      detail:
          'Your ACWR is above 1.5, the strongest predictor of injury in '
          'workload research. Volume spiked too fast relative to your base.',
      recommendedAction: 'Deload by 40% next session and reassess.',
    ));
  } else if (input.acwr >= 1.3) {
    signals.add(const DangerSignal(
      code: 'ACWR_ELEVATED',
      severity: 'warning',
      title: 'Workload ratio elevated',
      detail:
          'ACWR between 1.3–1.5 is a caution zone. Monitor closely and '
          'avoid adding volume.',
      recommendedAction: 'Hold volume steady; do not increase next session.',
    ));
  }

  // 3: Monotony
  if (input.monotony > 2.0) {
    signals.add(const DangerSignal(
      code: 'MONOTONY_HIGH',
      severity: 'warning',
      title: 'Training monotony high',
      detail:
          'Monotony index >2.0 means day-to-day variation is too low relative '
          'to total volume. Repetitive stress accumulates.',
      recommendedAction: 'Add variety: different exercises, intensities, or a rest day.',
    ));
  }

  // Count the max consecutive streak
  int maxStreak = 0;
  int currentStreak = 0;
  for (final s in input.recentHardSets) {
    if (s.rpe >= 9.0) {
      currentStreak++;
      maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
    } else {
      currentStreak = 0;
    }
  }

  if (maxStreak >= 3) {
    final anyCritical = input.recentHardSets.any((s) => s.rpe >= 9.5);
    if (anyCritical) {
      signals.add(const DangerSignal(
        code: 'RPE_SPIKE_CRITICAL',
        severity: 'critical',
        title: 'CNS overload detected',
        detail: '3+ consecutive sets at RPE ≥9.5. Central nervous system '
            'fatigue is accumulating rapidly.',
        recommendedAction: 'Stop the session. Take 2 rest days before next training.',
      ));
    } else {
      signals.add(const DangerSignal(
        code: 'RPE_SPIKE',
        severity: 'warning',
        title: 'Sustained high intensity',
        detail: '3+ consecutive sets at RPE ≥9.0. Recovery demand is high.',
        recommendedAction: 'Reduce working sets next session to 2 per exercise.',
      ));
    }
  }

  // 6-7: Body composition rapid change
  if (input.bodyWeightChangePercent != null) {
    final change = input.bodyWeightChangePercent!.abs();
    if (change > 5.0) {
      signals.add(DangerSignal(
        code: 'BODY_WEIGHT_RAPID',
        severity: 'critical',
        title: 'Rapid body weight change',
        detail: 'Body weight changed ${input.bodyWeightChangePercent!.toStringAsFixed(1)}% '
            'in one week. This can indicate dehydration, glycogen depletion, '
            'or a health concern.',
        recommendedAction: 'Consult a healthcare provider if this was unplanned.',
      ));
    } else if (change > 3.0) {
      signals.add(DangerSignal(
        code: 'BODY_WEIGHT_NOTABLE',
        severity: 'warning',
        title: 'Notable body weight shift',
        detail: 'Body weight changed ${input.bodyWeightChangePercent!.toStringAsFixed(1)}% '
            'in one week. Monitor hydration and nutrition.',
        recommendedAction: 'Ensure adequate hydration and caloric intake.',
      ));
    }
  }

  // 8: Missed sessions
  if (input.missedSessionsInLast14Days >= 3) {
    signals.add(const DangerSignal(
      code: 'CONSISTENCY_RISK',
      severity: 'watch',
      title: 'Consistency dropping',
      detail: '3+ planned sessions missed in the last 14 days. '
          'Adherence is the #1 driver of results.',
      recommendedAction: 'Recommit to a minimum viable schedule (2 sessions/week).',
    ));
  }

  // Overall severity
  String overall = 'clear';
  if (signals.any((s) => s.severity == 'critical')) {
    overall = 'critical';
  } else if (signals.any((s) => s.severity == 'warning')) {
    overall = 'warning';
  } else if (signals.any((s) => s.severity == 'watch')) {
    overall = 'watch';
  }

  return DangerZoneResult(signals: signals, overallSeverity: overall);
}
