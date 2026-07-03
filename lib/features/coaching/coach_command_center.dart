library;

import 'package:transformfit/features/behavior/behavioral_repair_loop.dart';
import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/coaching/dai_interface.dart';
import 'package:transformfit/features/reviews/five_star_experience.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

const coachCommandCenterSourceIds = [
  'src_transformfit_coaching_harness',
  'src_transformfit_wearable_dai_interface',
  'src_transformfit_workout_logger_intelligence',
  'src_transformfit_nutrition_target',
  'src_transformfit_body_composition_trust',
  'src_transformfit_behavioral_repair_loop',
  'src_transformfit_five_star_experience_bar',
];

class CoachCommandLane {
  const CoachCommandLane({
    required this.id,
    required this.label,
    required this.status,
    required this.detail,
    required this.nextAction,
    required this.sourceIds,
  });

  final String id;
  final String label;
  final String status;
  final String detail;
  final String nextAction;
  final List<String> sourceIds;

  String get sourceTraceLabel =>
      '${sourceIds.length} ${sourceIds.length == 1 ? 'source' : 'sources'}';

  String get semanticLabel => '$label, $status. $detail Next: $nextAction.';
}

class CoachCommandCenter {
  const CoachCommandCenter({
    required this.headline,
    required this.primaryAction,
    required this.commandReason,
    required this.safetyBoundary,
    required this.riskLabel,
    required this.confidence,
    required this.dai,
    required this.lanes,
    required this.next24Hours,
    required this.handoffSummary,
    required this.sourceIds,
  });

  final String headline;
  final String primaryAction;
  final String commandReason;
  final String safetyBoundary;
  final String riskLabel;
  final double confidence;
  final DaiInterface dai;
  final List<CoachCommandLane> lanes;
  final List<String> next24Hours;
  final String handoffSummary;
  final List<String> sourceIds;

  String get confidenceLabel => '${(confidence * 100).round()}% confidence';

  String get sourceTraceLabel =>
      '${sourceIds.length} ${sourceIds.length == 1 ? 'source' : 'sources'}';

  String get semanticLabel =>
      'Coach command center, $headline, $primaryAction, $riskLabel, '
      '$confidenceLabel. $commandReason $safetyBoundary';
}

CoachCommandCenter buildCoachCommandCenter(SessionState state) {
  final dai = buildDaiInterface(state);
  final coach = dai.coachSignal;
  final sourceIds = _uniqueSourceIds([
    ...coachCommandCenterSourceIds,
    ...dai.sourceIds,
  ]);
  final riskLabel = _riskLabel(state, dai);
  final headline = _headline(state, dai);
  final lanes = _buildLanes(state, dai, coach);

  return CoachCommandCenter(
    headline: headline,
    primaryAction: dai.primaryCommand,
    commandReason: dai.rationale,
    safetyBoundary: dai.boundary,
    riskLabel: riskLabel,
    confidence: dai.confidence,
    dai: dai,
    lanes: lanes,
    next24Hours: _next24Hours(state, dai),
    handoffSummary: _handoffSummary(state, dai),
    sourceIds: sourceIds,
  );
}

bool coachCommandCenterCopyIsGateSafe(CoachCommandCenter center) {
  final copy = [
    center.headline,
    center.primaryAction,
    center.commandReason,
    center.safetyBoundary,
    center.riskLabel,
    center.handoffSummary,
    ...center.next24Hours,
    for (final lane in center.lanes)
      '${lane.label} ${lane.status} ${lane.detail} ${lane.nextAction}',
  ].join(' ').toLowerCase();
  const blocked = [
    'beast mode',
    'burn fat',
    'diagnose',
    'no excuses',
    'punish',
    'shame',
    'weight loss',
  ];
  final emoji = RegExp('[\u{1F300}-\u{1F9FF}]', unicode: true);
  return blocked.every((term) => !copy.contains(term)) && !emoji.hasMatch(copy);
}

String _headline(SessionState state, DaiInterface dai) {
  if (dai.workflowId == 'dai_pain_override') {
    return 'Safety leads today';
  }
  if (state.activeSession != null) {
    return 'Session is live';
  }
  if (state.history.isNotEmpty) {
    return 'Review then progress';
  }
  return 'First command is ready';
}

String _riskLabel(SessionState state, DaiInterface dai) {
  if (dai.workflowId == 'dai_pain_override') return 'Safety review';
  if (dai.wearableInsight.status == 'recovery_bias') return 'Recovery bias';
  if (state.readinessEntry != null && state.readinessEntry!.score < 45) {
    return 'Low readiness';
  }
  return 'Normal guardrails';
}

List<CoachCommandLane> _buildLanes(
  SessionState state,
  DaiInterface dai,
  CoachSignal coach,
) {
  final readiness = state.readinessEntry;
  final nutrition = state.nutritionTarget;
  final wearable = state.wearableSignal;
  final behavior = buildBehavioralRepairLoop(state);
  final reviewMoment = buildFiveStarExperienceMoment(state);
  final completed = state.history
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .toList(growable: false);
  final painReported = hasReportedPain(state.lastDebrief?.painNotes);

  return [
    CoachCommandLane(
      id: 'lane-dai-command',
      label: 'DAI command',
      status: dai.workflowId,
      detail: dai.rationale,
      nextAction: dai.primaryCommand,
      sourceIds: dai.sourceIds,
    ),
    CoachCommandLane(
      id: 'lane-wearable-readiness',
      label: 'Wearable readiness',
      status: dai.wearableInsight.statusLabel,
      detail: dai.wearableInsight.detail,
      nextAction: dai.wearableInsight.primaryAdjustment,
      sourceIds: dai.wearableInsight.sourceIds,
    ),
    CoachCommandLane(
      id: 'lane-behavior-repair',
      label: 'Behavior repair',
      status: behavior.mode.label,
      detail: '${behavior.emotionalNeed} ${behavior.friction}',
      nextAction: behavior.repairAction,
      sourceIds: behavior.sourceIds,
    ),
    CoachCommandLane(
      id: 'lane-readiness-entry',
      label: 'Readiness',
      status: readiness == null
          ? 'No check-in'
          : '${readiness.score} ${readiness.zone}',
      detail: readiness == null
          ? 'No readiness entry is stored for today.'
          : '${readiness.energyLevel}/10 energy, ${readiness.sleepQuality}/10 sleep, ${readiness.sorenessMap.length} sore ${readiness.sorenessMap.length == 1 ? 'area' : 'areas'}.',
      nextAction: readiness == null ? 'Submit readiness' : coach.nextAction,
      sourceIds: coach.sourceIds,
    ),
    CoachCommandLane(
      id: 'lane-training-ledger',
      label: 'Training ledger',
      status:
          '${completed.length} ${completed.length == 1 ? 'session' : 'sessions'}',
      detail:
          '${_totalSets(completed)} sets logged. ${_topSetLabel(completed)}',
      nextAction: state.activeSession == null
          ? 'Start today session'
          : 'Finish live session',
      sourceIds: const [
        'src_transformfit_workout_logger_intelligence',
        'src_transformfit_coaching_harness',
      ],
    ),
    CoachCommandLane(
      id: 'lane-nutrition',
      label: 'Nutrition',
      status: nutrition == null ? 'Needed for activation' : nutrition.label,
      detail: nutrition == null
          ? 'No nutrition target is stored yet.'
          : '${nutrition.targetDisplay}. ${nutrition.safetyNote}',
      nextAction: nutrition == null
          ? 'Create nutrition target'
          : 'Review target after today session',
      sourceIds:
          nutrition?.sourceIds ??
          const [
            'src_transformfit_nutrition_target',
            'src_transformfit_coaching_harness',
          ],
    ),
    CoachCommandLane(
      id: 'lane-safety',
      label: 'Safety',
      status: painReported ? 'Pain reported' : 'Clear guardrail',
      detail: painReported
          ? 'Pain context is present; loaded progression requires review before increasing.'
          : wearable == null
          ? 'No pain flag and no wearable override are stored.'
          : 'No pain flag; wearable context stays secondary to set quality.',
      nextAction: painReported
          ? 'Choose pain-free variation'
          : coach.nextAction,
      sourceIds: const [
        'src_transformfit_coaching_harness',
        'src_transformfit_body_composition_trust',
      ],
    ),
    CoachCommandLane(
      id: 'lane-review-readiness',
      label: 'Review readiness',
      status: reviewMoment.statusLabel,
      detail: '${reviewMoment.headline} ${reviewMoment.rationale}',
      nextAction: reviewMoment.nextAction,
      sourceIds: reviewMoment.sourceIds,
    ),
  ];
}

List<String> _next24Hours(SessionState state, DaiInterface dai) {
  final steps = <String>[dai.primaryCommand];
  if (state.readinessEntry == null) {
    steps.add('Submit readiness with wearable HRV when available');
  }
  if (state.activeSession == null) {
    steps.add('Start today session and log one clean set');
  } else {
    steps.add('Finish live session and save debrief');
  }
  if (state.nutritionTarget == null) {
    steps.add('Create one safe nutrition target');
  }
  steps.add('Review proof after the session');
  return steps.take(4).toList(growable: false);
}

String _handoffSummary(SessionState state, DaiInterface dai) {
  final readiness = state.readinessEntry;
  final completed = state.history
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .length;
  final pain = hasReportedPain(state.lastDebrief?.painNotes)
      ? 'Pain review needed.'
      : 'No pain escalation stored.';
  final readinessText = readiness == null
      ? 'readiness pending'
      : 'readiness ${readiness.score} ${readiness.zone}';
  return 'Coach handoff: ${dai.primaryCommand}; $readinessText; $completed completed ${completed == 1 ? 'session' : 'sessions'}; $pain';
}

int _totalSets(List<WorkoutSession> sessions) {
  return sessions.fold<int>(0, (total, session) => total + session.totalSets);
}

String _topSetLabel(List<WorkoutSession> sessions) {
  LoggedSet? top;
  for (final session in sessions) {
    for (final set in session.loggedSets) {
      if (set.weightKg == null || set.reps == null) continue;
      if (top == null ||
          set.weightKg! * set.reps! > top.weightKg! * top.reps!) {
        top = set;
      }
    }
  }
  if (top == null) return 'No weighted top set yet.';
  final weight = top.weightKg == top.weightKg!.roundToDouble()
      ? top.weightKg!.round().toString()
      : top.weightKg!.toStringAsFixed(1);
  return 'Top set: ${top.exerciseName} $weight kg x ${top.reps}.';
}

List<String> _uniqueSourceIds(List<String> sourceIds) {
  final seen = <String>{};
  return sourceIds.where(seen.add).toList(growable: false);
}
