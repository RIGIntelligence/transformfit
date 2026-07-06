library;

import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

const emotionalExperienceSourceIds = [
  'src_transformfit_behavioral_sidecar',
  'src_transformfit_ux_ui_research_ingestion',
  'src_transformfit_progress_and_proof',
];

enum EmotionalExperienceStage {
  orientation,
  agency,
  safety,
  comeback,
  momentum,
  proofIdentity,
}

extension EmotionalExperienceStageLabel on EmotionalExperienceStage {
  String get label => switch (this) {
    EmotionalExperienceStage.orientation => 'Orientation',
    EmotionalExperienceStage.agency => 'Agency',
    EmotionalExperienceStage.safety => 'Safety',
    EmotionalExperienceStage.comeback => 'Comeback',
    EmotionalExperienceStage.momentum => 'Momentum',
    EmotionalExperienceStage.proofIdentity => 'Proof identity',
  };
}

class EmotionalExperienceVector {
  const EmotionalExperienceVector({
    required this.id,
    required this.label,
    required this.state,
    required this.signal,
    required this.designResponse,
  });

  final String id;
  final String label;
  final String state;
  final String signal;
  final String designResponse;

  String get semanticLabel => '$label: $state. $signal $designResponse';
}

class EmotionalExperienceMap {
  const EmotionalExperienceMap({
    required this.stage,
    required this.headline,
    required this.emotionalPromise,
    required this.primaryFeeling,
    required this.riskToAvoid,
    required this.nextExperience,
    required this.confidence,
    required this.vectors,
    required this.sourceIds,
    required this.uxPrincipleIds,
  });

  final EmotionalExperienceStage stage;
  final String headline;
  final String emotionalPromise;
  final String primaryFeeling;
  final String riskToAvoid;
  final String nextExperience;
  final double confidence;
  final List<EmotionalExperienceVector> vectors;
  final List<String> sourceIds;
  final List<String> uxPrincipleIds;

  String get confidenceLabel => '${(confidence * 100).round()}% confidence';

  String get sourceTraceLabel =>
      '${sourceIds.length} ${sourceIds.length == 1 ? 'source' : 'sources'}';

  String get semanticLabel =>
      'Emotional experience ${stage.label}, $headline, $confidenceLabel. '
      '$emotionalPromise Next: $nextExperience';
}

EmotionalExperienceMap buildEmotionalExperienceMap(
  SessionState state, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final painDebrief = state.lastDebrief;
  if (painDebrief != null && hasReportedPain(painDebrief.painNotes)) {
    return _safetyMap(painDebrief);
  }

  if (state.activeSession != null) {
    return _agencyMap(state);
  }

  final readiness = state.readinessEntry;
  if (readiness != null && _isLowReadiness(readiness)) {
    return _recoverySafetyMap(readiness);
  }

  final latestCompleted = _latestCompletedSession(state.history);
  if (latestCompleted != null &&
      currentTime.difference(latestCompleted.endedAt!).inHours >= 36) {
    return _comebackMap(latestCompleted, currentTime);
  }

  if (state.history.length >= 3) {
    return _proofIdentityMap(state);
  }

  if (state.history.isNotEmpty || state.lastDebrief != null) {
    return _momentumMap(state);
  }

  return _orientationMap(state);
}

bool emotionalExperienceCopyIsGateSafe(EmotionalExperienceMap map) {
  final copy = [
    map.stage.label,
    map.headline,
    map.emotionalPromise,
    map.primaryFeeling,
    map.riskToAvoid,
    map.nextExperience,
    for (final vector in map.vectors)
      '${vector.label} ${vector.state} ${vector.signal} ${vector.designResponse}',
  ].join(' ').toLowerCase();
  const blocked = [
    'beast mode',
    'burn fat',
    'diagnose',
    'guilt',
    'lazy',
    'no excuses',
    'punish',
    'shame',
    'skinny',
    'weight loss',
  ];
  final emoji = RegExp('[\u{1F300}-\u{1F9FF}]', unicode: true);
  return blocked.every((term) => !copy.contains(term)) && !emoji.hasMatch(copy);
}

EmotionalExperienceMap _orientationMap(SessionState state) {
  final readiness = state.readinessEntry;
  return EmotionalExperienceMap(
    stage: EmotionalExperienceStage.orientation,
    headline: 'Feel safe to begin',
    emotionalPromise: 'The first win is clarity, not intensity.',
    primaryFeeling: readiness == null ? 'uncertain' : 'ready to try',
    riskToAvoid: 'Do not make the first screen feel like a test.',
    nextExperience: readiness == null
        ? 'Answer the readiness check and see one small next action.'
        : 'Start the first session and log one clean set.',
    confidence: readiness == null ? 0.76 : 0.8,
    vectors: _vectors(
      certainty: readiness == null ? 'Needs first signal' : 'Readiness set',
      agency: 'One action available',
      safety: 'Low-pressure start',
      momentum: 'Proof begins after one set',
    ),
    sourceIds: emotionalExperienceSourceIds,
    uxPrincipleIds: const [
      'uxp_explain_plan_before_ask',
      'uxp_goal_to_session_continuity',
    ],
  );
}

EmotionalExperienceMap _agencyMap(SessionState state) {
  final sets = state.activeSession?.loggedSets.length ?? 0;
  return EmotionalExperienceMap(
    stage: EmotionalExperienceStage.agency,
    headline: 'Feel in control while moving',
    emotionalPromise: 'The session stays editable and finishable.',
    primaryFeeling: 'in control',
    riskToAvoid: 'Do not bury undo, finish, or pain-check controls.',
    nextExperience: sets == 0
        ? 'Log one clean set.'
        : 'Finish and debrief while context is fresh.',
    confidence: sets == 0 ? 0.8 : 0.87,
    vectors: _vectors(
      certainty: sets == 0 ? 'Action pending' : 'Action logged',
      agency: 'Edit, undo, and finish stay visible',
      safety: 'Pain check remains explicit',
      momentum: '$sets ${sets == 1 ? 'set' : 'sets'} logged',
    ),
    sourceIds: emotionalExperienceSourceIds,
    uxPrincipleIds: const [
      'uxp_fast_active_logging',
      'uxp_safety_boundary_at_action_point',
    ],
  );
}

EmotionalExperienceMap _safetyMap(SessionDebrief debrief) {
  final pain = _shortText(debrief.painNotes, fallback: 'pain was reported');
  return EmotionalExperienceMap(
    stage: EmotionalExperienceStage.safety,
    headline: 'Feel protected before pushed',
    emotionalPromise: 'Trust comes from conservative choices after pain.',
    primaryFeeling: 'protected',
    riskToAvoid: 'Do not imply load increases are approved.',
    nextExperience: 'Choose a pain-free variation before progression.',
    confidence: 0.91,
    vectors: _vectors(
      certainty: 'Pain context visible',
      agency: 'Variation choice remains open',
      safety: pain,
      momentum: 'Progress waits for a pain-free session',
    ),
    sourceIds: emotionalExperienceSourceIds,
    uxPrincipleIds: const [
      'uxp_safety_boundary_at_action_point',
      'uxp_recovery_as_kept_promise',
    ],
  );
}

EmotionalExperienceMap _recoverySafetyMap(ReadinessEntry readiness) {
  return EmotionalExperienceMap(
    stage: EmotionalExperienceStage.safety,
    headline: 'Feel allowed to protect tomorrow',
    emotionalPromise: 'Recovery-safe work still counts.',
    primaryFeeling: 'permission',
    riskToAvoid: 'Do not turn low readiness into pressure.',
    nextExperience: 'Choose mobility, walking, or reduced-load training.',
    confidence: readiness.sorenessMap.length >= 3 ? 0.9 : 0.84,
    vectors: _vectors(
      certainty: '${readiness.score} readiness',
      agency: 'Recovery options available',
      safety: '${readiness.sorenessMap.length} sore areas',
      momentum: 'Kept promise over intensity',
    ),
    sourceIds: emotionalExperienceSourceIds,
    uxPrincipleIds: const [
      'uxp_recovery_as_kept_promise',
      'uxp_readiness_adjusted_next_action',
    ],
  );
}

EmotionalExperienceMap _comebackMap(WorkoutSession session, DateTime now) {
  final days = now.difference(session.endedAt!).inDays;
  final label = days <= 1 ? '1 day' : '$days days';
  return EmotionalExperienceMap(
    stage: EmotionalExperienceStage.comeback,
    headline: 'Feel invited back',
    emotionalPromise: 'A gap becomes a restart path, not a verdict.',
    primaryFeeling: 'welcomed back',
    riskToAvoid: 'Do not add missed volume or frame the gap as broken.',
    nextExperience: 'Run readiness and log one warm-up set.',
    confidence: 0.82,
    vectors: _vectors(
      certainty: 'Last session $label ago',
      agency: 'Restart path is small',
      safety: 'No catch-up volume',
      momentum: 'One warm-up set restarts proof',
    ),
    sourceIds: emotionalExperienceSourceIds,
    uxPrincipleIds: const [
      'uxp_recovery_as_kept_promise',
      'uxp_goal_to_session_continuity',
    ],
  );
}

EmotionalExperienceMap _momentumMap(SessionState state) {
  final completed = _completedSessions(state.history).length;
  return EmotionalExperienceMap(
    stage: EmotionalExperienceStage.momentum,
    headline: 'Feel the loop working',
    emotionalPromise: 'Proof turns the next action into something obvious.',
    primaryFeeling: 'momentum',
    riskToAvoid: 'Do not make progress depend on appearance or comparison.',
    nextExperience: 'Review proof and start the smallest useful next session.',
    confidence: completed == 0 ? 0.74 : 0.84,
    vectors: _vectors(
      certainty:
          '$completed completed ${completed == 1 ? 'session' : 'sessions'}',
      agency: 'Next action is explicit',
      safety: 'Body-neutral progress',
      momentum: 'Proof is building',
    ),
    sourceIds: emotionalExperienceSourceIds,
    uxPrincipleIds: const [
      'uxp_progress_without_body_shame',
      'uxp_goal_to_session_continuity',
    ],
  );
}

EmotionalExperienceMap _proofIdentityMap(SessionState state) {
  final completed = _completedSessions(state.history).length;
  return EmotionalExperienceMap(
    stage: EmotionalExperienceStage.proofIdentity,
    headline: 'Feel like the kind of person who returns',
    emotionalPromise: 'The identity signal is kept promises over time.',
    primaryFeeling: 'self-trust',
    riskToAvoid: 'Do not reduce identity to a score, body, or streak.',
    nextExperience:
        'Use the proof ledger to choose the next right-sized promise.',
    confidence: 0.88,
    vectors: _vectors(
      certainty: '$completed kept promises',
      agency: 'Next promise is adjustable',
      safety: 'Recovery wins still count',
      momentum: 'History supports recommitment',
    ),
    sourceIds: emotionalExperienceSourceIds,
    uxPrincipleIds: const [
      'uxp_progress_without_body_shame',
      'uxp_coach_voice_with_data_token',
    ],
  );
}

List<EmotionalExperienceVector> _vectors({
  required String certainty,
  required String agency,
  required String safety,
  required String momentum,
}) {
  return [
    EmotionalExperienceVector(
      id: 'certainty',
      label: 'Certainty',
      state: certainty,
      signal: 'The user can understand what is true right now.',
      designResponse: 'Show one plain next action.',
    ),
    EmotionalExperienceVector(
      id: 'agency',
      label: 'Agency',
      state: agency,
      signal: 'The user can choose or adjust without losing progress.',
      designResponse: 'Keep the path editable.',
    ),
    EmotionalExperienceVector(
      id: 'safety',
      label: 'Safety',
      state: safety,
      signal: 'The app protects the user when readiness or pain changes.',
      designResponse: 'Make boundaries explicit.',
    ),
    EmotionalExperienceVector(
      id: 'momentum',
      label: 'Momentum',
      state: momentum,
      signal: 'The next action feels smaller than avoidance.',
      designResponse: 'Turn proof into recommitment.',
    ),
  ];
}

bool _isLowReadiness(ReadinessEntry readiness) {
  return readiness.zone == 'deload' ||
      readiness.zone == 'rest' ||
      readiness.score <= 45 ||
      readiness.sleepQuality <= 4 ||
      readiness.sorenessMap.length >= 3;
}

List<WorkoutSession> _completedSessions(List<WorkoutSession> history) {
  return history
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .toList(growable: false);
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
