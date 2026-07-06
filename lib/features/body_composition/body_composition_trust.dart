import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

const bodyCompositionTrustSourceIds = [
  'src_cdc_bmi_individual_context_2025',
  'src_cdc_physical_activity_strength_2025',
  'src_fda_bia_home_device_estimate_k130311',
  'src_nap_weight_context_complexity',
  'src_transformfit_composition_trust_protocol',
];

class BodyCompositionTrustSignal {
  const BodyCompositionTrustSignal({
    required this.label,
    required this.value,
    required this.status,
    required this.context,
    required this.semanticLabel,
  });

  final String label;
  final String value;
  final String status;
  final String context;
  final String semanticLabel;
}

class BodyCompositionTrustSummary {
  const BodyCompositionTrustSummary({
    required this.hasTrainingContext,
    required this.headline,
    required this.subhead,
    required this.trustFrame,
    required this.coachCue,
    required this.nextBestAction,
    required this.privacyLabel,
    required this.privacyDetail,
    required this.signals,
    required this.sourceIds,
    required this.semanticLabel,
  });

  final bool hasTrainingContext;
  final String headline;
  final String subhead;
  final String trustFrame;
  final String coachCue;
  final String nextBestAction;
  final String privacyLabel;
  final String privacyDetail;
  final List<BodyCompositionTrustSignal> signals;
  final List<String> sourceIds;
  final String semanticLabel;
}

BodyCompositionTrustSummary buildBodyCompositionTrustSummary(
  SessionState state, {
  DateTime? now,
}) {
  final completed = [...state.history]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final completedSessions = completed
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .toList(growable: false);
  final anchorDay = _dateOnly(now ?? DateTime.now());
  final currentWeekStart = anchorDay.subtract(const Duration(days: 6));
  final currentWeekSessions = completedSessions
      .where(
        (session) => _inRange(session.startedAt, currentWeekStart, anchorDay),
      )
      .length;
  final weightedSets = completedSessions.fold<int>(
    0,
    (count, session) => count + session.loggedSets.where(_isWeightedSet).length,
  );
  final recoveryWins = completedSessions.where(_isRecoverySession).length;
  final target = state.nutritionTarget;
  final hasTrainingContext = completedSessions.isNotEmpty;

  final strengthValue = weightedSets == 0
      ? 'No weighted sets'
      : '$weightedSets weighted ${_plural(weightedSets, 'set', 'sets')}';
  final recoveryValue = recoveryWins == 0
      ? 'No recovery checks'
      : '$recoveryWins recovery ${_plural(recoveryWins, 'win', 'wins')}';
  final adherenceValue =
      '${completedSessions.length} ${_plural(completedSessions.length, 'session', 'sessions')}';
  final nutritionValue = target?.targetDisplay ?? 'Not set';

  final signals = [
    BodyCompositionTrustSignal(
      label: 'Strength context',
      value: strengthValue,
      status: weightedSets >= 6
          ? 'Trend context'
          : weightedSets > 0
          ? 'Baseline context'
          : 'Missing',
      context:
          'Use load, reps, and effort to explain a trend before changing targets.',
      semanticLabel: 'Strength context: $strengthValue.',
    ),
    BodyCompositionTrustSignal(
      label: 'Recovery context',
      value: recoveryValue,
      status: recoveryWins > 0 ? 'Recovery linked' : 'Needs context',
      context:
          'Sleep, soreness, and easy work can explain noisy readings and plan changes.',
      semanticLabel: 'Recovery context: $recoveryValue.',
    ),
    BodyCompositionTrustSignal(
      label: 'Adherence context',
      value: adherenceValue,
      status: currentWeekSessions >= 2 ? 'Pattern evidence' : 'Baseline',
      context:
          'A repeated training pattern matters more than a single measurement.',
      semanticLabel: 'Adherence context: $adherenceValue.',
    ),
    BodyCompositionTrustSignal(
      label: 'Nutrition context',
      value: nutritionValue,
      status: target == null ? 'Optional' : 'Scoped target',
      context: target == null
          ? 'Add a simple target only when it helps recovery and consistency.'
          : 'Nutrition is used as context, not as a diagnosis or appearance score.',
      semanticLabel: 'Nutrition context: $nutritionValue.',
    ),
  ];

  final headline = hasTrainingContext
      ? 'Context before change'
      : 'No composition signal yet';
  final nextBestAction = _nextBestAction(
    hasTrainingContext: hasTrainingContext,
    weightedSets: weightedSets,
    recoveryWins: recoveryWins,
    nutritionTarget: target,
  );
  final coachCue = _coachCue(
    hasTrainingContext: hasTrainingContext,
    weightedSets: weightedSets,
    recoveryWins: recoveryWins,
    nutritionTarget: target,
  );

  return BodyCompositionTrustSummary(
    hasTrainingContext: hasTrainingContext,
    headline: headline,
    subhead:
        'Signals, not verdicts. Trends only become useful beside strength, recovery, and adherence.',
    trustFrame: 'Imperfect signal',
    coachCue: coachCue,
    nextBestAction: nextBestAction,
    privacyLabel: 'Private by default',
    privacyDetail:
        'No share surface exists here; this view is for interpretation and plan context.',
    signals: signals,
    sourceIds: bodyCompositionTrustSourceIds,
    semanticLabel:
        '$headline. Signals, not verdicts. ${signals.map((signal) => signal.semanticLabel).join(' ')} Next action: $nextBestAction.',
  );
}

bool bodyCompositionCopyIsTrustSafe(BodyCompositionTrustSummary summary) {
  const blockedTerms = [
    'before and after',
    'bikini',
    'burn fat',
    'cheat meal',
    'clean eating',
    'detox',
    'dream body',
    'fat loss',
    'guilt',
    'no excuses',
    'punish',
    'shame',
    'shred',
    'skinny',
    'summer body',
    'transformation photo',
    'weight loss',
  ];
  final copy = [
    summary.headline,
    summary.subhead,
    summary.trustFrame,
    summary.coachCue,
    summary.nextBestAction,
    summary.privacyLabel,
    summary.privacyDetail,
    summary.semanticLabel,
    ...summary.sourceIds,
    ...summary.signals.expand(
      (signal) => [
        signal.label,
        signal.value,
        signal.status,
        signal.context,
        signal.semanticLabel,
      ],
    ),
  ].join(' ').toLowerCase();
  return blockedTerms.every((term) => !copy.contains(term));
}

String _coachCue({
  required bool hasTrainingContext,
  required int weightedSets,
  required int recoveryWins,
  required NutritionTarget? nutritionTarget,
}) {
  if (!hasTrainingContext) {
    return 'Log one training action before interpreting any measurement.';
  }
  if (weightedSets == 0) {
    return 'Build strength context first; unloaded recovery work is useful but incomplete.';
  }
  if (recoveryWins == 0 && weightedSets >= 6) {
    return 'Strength context exists. Add recovery context before making a bigger change.';
  }
  if (nutritionTarget == null) {
    return 'Training context is visible. Add one scoped nutrition target if it helps recovery.';
  }
  return 'Use repeated trend context before changing training or nutrition.';
}

String _nextBestAction({
  required bool hasTrainingContext,
  required int weightedSets,
  required int recoveryWins,
  required NutritionTarget? nutritionTarget,
}) {
  if (!hasTrainingContext) {
    return 'Log first training action';
  }
  if (weightedSets == 0) {
    return 'Add one strength set';
  }
  if (recoveryWins == 0) {
    return 'Add recovery context';
  }
  if (nutritionTarget == null) {
    return 'Add scoped nutrition target';
  }
  return 'Review after repeated readings';
}

bool _isWeightedSet(LoggedSet set) {
  return set.completed && set.weightKg != null && set.reps != null;
}

bool _isRecoverySession(WorkoutSession session) {
  final note = session.sessionNotes?.toLowerCase() ?? '';
  if (note.contains('recovery') ||
      note.contains('mobility') ||
      note.contains('walk')) {
    return true;
  }
  return session.loggedSets.any((set) {
    final exercise = set.exerciseName.toLowerCase();
    return set.durationSeconds != null &&
        set.weightKg == null &&
        (exercise.contains('mobility') ||
            exercise.contains('reset') ||
            exercise.contains('walk') ||
            exercise.contains('recovery'));
  });
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _inRange(DateTime value, DateTime start, DateTime end) {
  final day = _dateOnly(value);
  return !day.isBefore(start) && !day.isAfter(end);
}

String _plural(int count, String singular, String plural) {
  return count == 1 ? singular : plural;
}
