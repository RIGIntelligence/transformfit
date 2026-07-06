library;

import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

const behavioralRepairSourceIds = [
  'src_transformfit_behavioral_sidecar',
  'src_transformfit_coaching_harness',
  'src_transformfit_ux_ui_research_ingestion',
];

enum BehavioralRepairMode {
  dayZeroActivation,
  staleCheckIn,
  recoveryKeptPromise,
  painSafety,
  missedDayComeback,
  activeSessionClosure,
  nutritionBridge,
  proofRecommitment,
}

extension BehavioralRepairModeLabel on BehavioralRepairMode {
  String get label => switch (this) {
    BehavioralRepairMode.dayZeroActivation => 'Day-zero activation',
    BehavioralRepairMode.staleCheckIn => 'Checked-in comeback',
    BehavioralRepairMode.recoveryKeptPromise => 'Recovery kept promise',
    BehavioralRepairMode.painSafety => 'Pain safety repair',
    BehavioralRepairMode.missedDayComeback => 'Missed-day comeback',
    BehavioralRepairMode.activeSessionClosure => 'Live-session closure',
    BehavioralRepairMode.nutritionBridge => 'Nutrition bridge',
    BehavioralRepairMode.proofRecommitment => 'Proof recommitment',
  };
}

class BehavioralRepairLoop {
  const BehavioralRepairLoop({
    required this.mode,
    required this.headline,
    required this.emotionalNeed,
    required this.friction,
    required this.repairAction,
    required this.microCommitment,
    required this.proof,
    required this.safetyBoundary,
    required this.confidence,
    required this.sourceIds,
    required this.uxPrincipleIds,
  });

  final BehavioralRepairMode mode;
  final String headline;
  final String emotionalNeed;
  final String friction;
  final String repairAction;
  final String microCommitment;
  final String proof;
  final String safetyBoundary;
  final double confidence;
  final List<String> sourceIds;
  final List<String> uxPrincipleIds;

  String get confidenceLabel => '${(confidence * 100).round()}% confidence';

  String get sourceTraceLabel =>
      '${sourceIds.length} ${sourceIds.length == 1 ? 'source' : 'sources'}';

  String get semanticLabel =>
      'Behavior repair ${mode.label}, $headline, $confidenceLabel. '
      'Need: $emotionalNeed. Repair: $repairAction. Safety: $safetyBoundary';
}

BehavioralRepairLoop buildBehavioralRepairLoop(
  SessionState state, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final painDebrief = state.lastDebrief;
  if (painDebrief != null && hasReportedPain(painDebrief.painNotes)) {
    return _painSafety(painDebrief);
  }

  if (state.activeSession != null) {
    return _activeSessionClosure(state.activeSession!);
  }

  final readiness = state.readinessEntry;
  if (readiness != null && _isLowReadiness(readiness)) {
    return _recoveryKeptPromise(readiness);
  }

  if (_isStaleDayZeroCheckIn(state, currentTime)) {
    return _staleCheckIn();
  }

  final latestCompleted = _latestCompletedSession(state.history);
  if (latestCompleted != null &&
      currentTime.difference(latestCompleted.endedAt!).inHours >= 36) {
    return _missedDayComeback(latestCompleted, currentTime);
  }

  if (readiness == null) {
    return _dayZeroActivation();
  }

  if (state.nutritionTarget == null) {
    return _nutritionBridge(readiness);
  }

  return _proofRecommitment(state);
}

bool behavioralRepairCopyIsGateSafe(BehavioralRepairLoop loop) {
  final copy = [
    loop.mode.label,
    loop.headline,
    loop.emotionalNeed,
    loop.friction,
    loop.repairAction,
    loop.microCommitment,
    loop.proof,
    loop.safetyBoundary,
  ].join(' ').toLowerCase();
  const blocked = [
    'beast mode',
    'burn fat',
    'cheat day',
    'diagnose',
    'failure',
    'guilt',
    'lazy',
    'no excuses',
    'punish',
    'shame',
    'weight loss',
  ];
  final emoji = RegExp('[\u{1F300}-\u{1F9FF}]', unicode: true);
  return blocked.every((term) => !copy.contains(term)) && !emoji.hasMatch(copy);
}

BehavioralRepairLoop _dayZeroActivation() {
  return const BehavioralRepairLoop(
    mode: BehavioralRepairMode.dayZeroActivation,
    headline: 'Make starting feel safe',
    emotionalNeed: 'Belong before performance.',
    friction:
        'No workout proof exists yet, so the app should not ask for a big identity leap.',
    repairAction: 'Start with a 30-second readiness check.',
    microCommitment:
        'Answer energy, sleep, and soreness; then log one clean set.',
    proof: 'Activation counts when readiness and one set are stored.',
    safetyBoundary: 'No streak pressure, body ranking, or unsafe progression.',
    confidence: 0.78,
    sourceIds: behavioralRepairSourceIds,
    uxPrincipleIds: [
      'uxp_goal_to_session_continuity',
      'uxp_explain_plan_before_ask',
      'uxp_recovery_as_kept_promise',
    ],
  );
}

BehavioralRepairLoop _staleCheckIn() {
  return const BehavioralRepairLoop(
    mode: BehavioralRepairMode.staleCheckIn,
    headline: 'Save the day without pretending',
    emotionalNeed: 'Keep agency after delay.',
    friction: 'Readiness was submitted, but the first session has not started.',
    repairAction: 'Save today with an 8-minute recovery reset.',
    microCommitment:
        'Four minutes walk, four minutes mobility, then log the reset.',
    proof: 'The day counts as a kept promise when the reset is saved.',
    safetyBoundary: 'Recovery work is valid; loaded work remains optional.',
    confidence: 0.86,
    sourceIds: behavioralRepairSourceIds,
    uxPrincipleIds: [
      'uxp_recovery_as_kept_promise',
      'uxp_readiness_adjusted_next_action',
    ],
  );
}

BehavioralRepairLoop _recoveryKeptPromise(ReadinessEntry readiness) {
  final soreness = readiness.sorenessMap.length;
  return BehavioralRepairLoop(
    mode: BehavioralRepairMode.recoveryKeptPromise,
    headline: 'Turn low readiness into a kept promise',
    emotionalNeed: 'Progress without self-betrayal.',
    friction:
        '${readiness.score} readiness and $soreness sore ${soreness == 1 ? 'area' : 'areas'} make heavy work a poor default.',
    repairAction: 'Choose the 12-minute mobility path or a controlled walk.',
    microCommitment: 'Move, record it, and protect tomorrow.',
    proof: 'Recovery-safe work is stored as training proof.',
    safetyBoundary: 'No loaded pain work; reduce or stop if symptoms escalate.',
    confidence: soreness >= 3 ? 0.9 : 0.84,
    sourceIds: behavioralRepairSourceIds,
    uxPrincipleIds: const [
      'uxp_recovery_as_kept_promise',
      'uxp_safety_boundary_at_action_point',
      'uxp_readiness_adjusted_next_action',
    ],
  );
}

BehavioralRepairLoop _painSafety(SessionDebrief debrief) {
  final note = _shortText(debrief.painNotes, fallback: 'pain was reported');
  return BehavioralRepairLoop(
    mode: BehavioralRepairMode.painSafety,
    headline: 'Protect trust before load',
    emotionalNeed: 'Feel protected, not benched.',
    friction: 'The last debrief recorded $note.',
    repairAction: 'Choose a pain-free variation before any progression.',
    microCommitment: 'Run a light set only if it stays pain-free.',
    proof: 'Pain context stays visible until a pain-free session is logged.',
    safetyBoundary:
        'Stop sharp, worsening, or unusual symptoms and seek qualified care when appropriate.',
    confidence: 0.91,
    sourceIds: behavioralRepairSourceIds,
    uxPrincipleIds: const [
      'uxp_safety_boundary_at_action_point',
      'uxp_recovery_as_kept_promise',
    ],
  );
}

BehavioralRepairLoop _missedDayComeback(
  WorkoutSession latestCompleted,
  DateTime now,
) {
  final days = now.difference(latestCompleted.endedAt!).inDays;
  final dayLabel = days <= 1 ? 'yesterday' : '$days days ago';
  return BehavioralRepairLoop(
    mode: BehavioralRepairMode.missedDayComeback,
    headline: 'Make return smaller than avoidance',
    emotionalNeed: 'Restart without a broken-streak story.',
    friction: 'The last completed session ended $dayLabel.',
    repairAction: 'Begin with readiness, then one warm-up set.',
    microCommitment: 'No catch-up workout; just restart the loop.',
    proof: 'Comeback proof is a fresh check-in plus one logged action.',
    safetyBoundary: 'Do not add missed volume back into today.',
    confidence: 0.82,
    sourceIds: behavioralRepairSourceIds,
    uxPrincipleIds: const [
      'uxp_recovery_as_kept_promise',
      'uxp_goal_to_session_continuity',
    ],
  );
}

BehavioralRepairLoop _activeSessionClosure(WorkoutSession active) {
  final loggedSets = active.loggedSets.length;
  return BehavioralRepairLoop(
    mode: BehavioralRepairMode.activeSessionClosure,
    headline: 'Close the loop you opened',
    emotionalNeed: 'Finish with clarity.',
    friction:
        '$loggedSets ${loggedSets == 1 ? 'set is' : 'sets are'} logged and the session is still live.',
    repairAction: loggedSets == 0
        ? 'Log one clean set.'
        : 'Finish and debrief while the memory is fresh.',
    microCommitment: loggedSets == 0
        ? 'One set is enough to create proof.'
        : 'Save RPE, satisfaction, pain check, and next focus.',
    proof: 'The session becomes useful only after the debrief is saved.',
    safetyBoundary: 'Stop any set that changes form or creates sharp pain.',
    confidence: loggedSets == 0 ? 0.8 : 0.88,
    sourceIds: behavioralRepairSourceIds,
    uxPrincipleIds: const [
      'uxp_fast_active_logging',
      'uxp_coach_voice_with_data_token',
    ],
  );
}

BehavioralRepairLoop _nutritionBridge(ReadinessEntry readiness) {
  return BehavioralRepairLoop(
    mode: BehavioralRepairMode.nutritionBridge,
    headline: 'Connect food to training without moralizing',
    emotionalNeed: 'Know the next useful input.',
    friction:
        'Readiness is ${readiness.score} ${readiness.zone}, but no nutrition target is saved.',
    repairAction: 'Create one protein target for the next 24 hours.',
    microCommitment: 'Pick the target and review it after the session.',
    proof:
        'Activation strengthens when readiness, training, and one nutrition target exist together.',
    safetyBoundary:
        'Nutrition targets are practical defaults, not medical nutrition advice.',
    confidence: 0.8,
    sourceIds: behavioralRepairSourceIds,
    uxPrincipleIds: const [
      'uxp_goal_to_session_continuity',
      'uxp_coach_voice_with_data_token',
    ],
  );
}

BehavioralRepairLoop _proofRecommitment(SessionState state) {
  final completed = state.history
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .length;
  return BehavioralRepairLoop(
    mode: BehavioralRepairMode.proofRecommitment,
    headline: 'Use proof to choose the next promise',
    emotionalNeed: 'See progress as evidence, not judgment.',
    friction:
        '$completed completed ${completed == 1 ? 'session' : 'sessions'} can become noise without a next action.',
    repairAction: 'Review proof, then start the smallest useful next session.',
    microCommitment: 'One next action, not a full-life reset.',
    proof: 'The ledger shows what happened and what to do next.',
    safetyBoundary: 'Proof is opt-in and body-neutral.',
    confidence: completed == 0 ? 0.72 : 0.86,
    sourceIds: behavioralRepairSourceIds,
    uxPrincipleIds: const [
      'uxp_progress_without_body_shame',
      'uxp_goal_to_session_continuity',
    ],
  );
}

bool _isStaleDayZeroCheckIn(SessionState state, DateTime now) {
  if (state.activeSession != null ||
      state.history.isNotEmpty ||
      state.lastDebrief != null) {
    return false;
  }
  final readiness = state.readinessEntry;
  if (readiness == null) return false;
  final checkedAt = readiness.createdAt ?? readiness.date;
  return now.difference(checkedAt) >= const Duration(hours: 4);
}

bool _isLowReadiness(ReadinessEntry readiness) {
  return readiness.zone == 'deload' ||
      readiness.zone == 'rest' ||
      readiness.score <= 45 ||
      readiness.sleepQuality <= 4 ||
      readiness.sorenessMap.length >= 3;
}

WorkoutSession? _latestCompletedSession(List<WorkoutSession> history) {
  for (final session in history.reversed) {
    if (session.endedAt != null && session.loggedSets.isNotEmpty) {
      return session;
    }
  }
  return null;
}

String _shortText(String? value, {required String fallback}) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return fallback;
  return trimmed.length <= 72
      ? trimmed
      : '${trimmed.substring(0, 72).trim()}...';
}
