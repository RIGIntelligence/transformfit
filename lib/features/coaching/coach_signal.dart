import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

class CoachSignal {
  const CoachSignal({
    required this.workflowId,
    required this.persona,
    required this.coachNote,
    required this.observationLabel,
    required this.observation,
    required this.nextAction,
    required this.confidence,
    required this.sourceIds,
    required this.uxPrincipleIds,
  });

  final String workflowId;
  final String persona;
  final String coachNote;
  final String observationLabel;
  final String observation;
  final String nextAction;
  final double confidence;
  final List<String> sourceIds;
  final List<String> uxPrincipleIds;

  String get personaLabel => _titleCase(persona);

  String get confidenceLabel => '${(confidence * 100).round()}% confidence';

  String get sourceTraceLabel =>
      '${sourceIds.length} ${sourceIds.length == 1 ? 'source' : 'sources'}';

  String get semanticLabel =>
      'Coach workflow $workflowId, $personaLabel mode, '
      '$confidenceLabel, $sourceTraceLabel. $coachNote $observation';
}

CoachSignal buildCoachSignal(SessionState state) {
  final readiness = state.readinessEntry;
  final painDebrief = state.lastDebrief;
  if (painDebrief != null && hasReportedPain(painDebrief.painNotes)) {
    return _painOrInjuryGuardrail(painDebrief);
  }

  final riskSignal = _coastingOrOverreachingSignal(state);
  if (riskSignal != null) return riskSignal;

  if (readiness != null && _isLowReadiness(readiness)) {
    return _domsOrLowReadiness(readiness);
  }

  if (state.activeSession != null) {
    return _liveSessionGuidance(state);
  }

  if (state.history.isNotEmpty || state.lastDebrief != null) {
    return _progressInterpretation(state);
  }

  return _dayZeroActivation(readiness, state.activeSession);
}

bool hasReportedPain(String? note) {
  final text = note?.trim().toLowerCase();
  if (text == null || text.isEmpty) return false;

  final cleanNoPainSignal =
      (text.contains('no pain') ||
          text.contains('no sharp pain') ||
          text.contains('pain-free') ||
          text.contains('pain free')) &&
      !text.contains('but') &&
      !text.contains('however') &&
      !text.contains('ache') &&
      !text.contains('hurt') &&
      !text.contains('worse');
  if (cleanNoPainSignal) return false;

  const riskTokens = [
    'ache',
    'aching',
    'aggravated',
    'flare',
    'hurt',
    'hurts',
    'pain',
    'pinch',
    'sharp',
    'twinge',
    'worse',
  ];
  return riskTokens.any(text.contains);
}

bool coachSignalCopyIsGateSafe(CoachSignal signal) {
  if (signal.coachNote.split(RegExp(r'\s+')).length > 60) return false;
  final copy = [
    signal.workflowId,
    signal.persona,
    signal.coachNote,
    signal.observationLabel,
    signal.observation,
    signal.nextAction,
  ].join(' ').toLowerCase();
  const blocked = [
    'beast mode',
    'burn fat',
    'cheat',
    'crush your goals',
    'excuses',
    'guilt',
    'no excuses',
    'punish',
    'shame',
    'skinny',
    'summer body',
    'unlock your potential',
    'weight loss',
  ];
  final emoji = RegExp('[\u{1F300}-\u{1F9FF}]', unicode: true);
  return blocked.every((term) => !copy.contains(term)) && !emoji.hasMatch(copy);
}

CoachSignal _dayZeroActivation(
  ReadinessEntry? readiness,
  WorkoutSession? active,
) {
  final hasActiveSession = active != null;
  final note = hasActiveSession
      ? 'Coach note: First session is live. Log one clean working set, then let the plan earn the next step.'
      : readiness == null
      ? 'Coach note: Start with a 30-second readiness check so today can match energy, sleep, and soreness.'
      : 'Coach note: Readiness is set. Start the first session and keep the target small enough to finish.';

  return CoachSignal(
    workflowId: 'day_0_activation',
    persona: 'motivator',
    coachNote: note,
    observationLabel: hasActiveSession ? 'First set target' : 'First action',
    observation: hasActiveSession
        ? 'The activation path starts with one logged set, not a perfect workout.'
        : 'No completed session is in the ledger yet, so the lowest-friction next action wins.',
    nextAction: hasActiveSession ? 'Log set 1' : 'Submit readiness',
    confidence: readiness == null ? 0.74 : 0.78,
    sourceIds: const [
      'src_cal_ai_app_store_preview',
      'src_ladder_app_store_preview',
      'src_nike_run_club_app_store_preview',
    ],
    uxPrincipleIds: const [
      'uxp_goal_to_session_continuity',
      'uxp_explain_plan_before_ask',
      'uxp_coach_voice_with_data_token',
    ],
  );
}

CoachSignal _domsOrLowReadiness(ReadinessEntry readiness) {
  final sorenessText = readiness.sorenessMap.isEmpty
      ? 'low readiness'
      : '${readiness.sorenessMap.length} sore ${readiness.sorenessMap.length == 1 ? 'area' : 'areas'}';
  return CoachSignal(
    workflowId: 'doms_or_low_readiness',
    persona: 'zen',
    coachNote:
        'Coach note: Today counts if the work fits recovery. Keep effort at ${_zoneEffort(readiness.zone)} and protect tomorrow.',
    observationLabel: 'Recovery promise',
    observation:
        '$sorenessText and a ${readiness.score} readiness score point to completion without grinding.',
    nextAction: 'Choose recovery-safe session',
    confidence: readiness.sorenessMap.length >= 3 ? 0.9 : 0.84,
    sourceIds: const [
      'src_calm_health_app_store_preview',
      'src_garmin_app_store_preview',
      'src_macrofactor_workouts_google_play',
    ],
    uxPrincipleIds: const [
      'uxp_recovery_as_kept_promise',
      'uxp_readiness_adjusted_next_action',
    ],
  );
}

CoachSignal _painOrInjuryGuardrail(SessionDebrief debrief) {
  final painNote = _safePainNote(debrief.painNotes);
  return CoachSignal(
    workflowId: 'pain_or_injury_guardrail',
    persona: 'zen',
    coachNote:
        'Coach note: Pain was reported last session. Keep today conservative: stop sharp pain, reduce load, and use a pain-free variation.',
    observationLabel: 'Safety boundary',
    observation:
        'Pain note: $painNote. No load increase is approved until the next set is pain-free.',
    nextAction: 'Choose pain-free variation',
    confidence: 0.91,
    sourceIds: const [
      'src_calm_health_app_store_preview',
      'src_garmin_app_store_preview',
      'src_macrofactor_workouts_google_play',
    ],
    uxPrincipleIds: const [
      'uxp_safety_boundary_at_action_point',
      'uxp_recovery_as_kept_promise',
      'uxp_readiness_adjusted_next_action',
    ],
  );
}

CoachSignal _liveSessionGuidance(SessionState state) {
  final active = state.activeSession!;
  final loggedSets = active.completedSets;
  final plannedSets = state.activeSessionPlan.fold<int>(
    0,
    (total, exercise) => total + exercise.targetSets,
  );
  final hasPlan = plannedSets > 0;
  final completionLabel = hasPlan
      ? '$loggedSets of $plannedSets planned sets'
      : '$loggedSets live ${loggedSets == 1 ? 'set' : 'sets'}';
  final readiness = state.readinessEntry;
  final readinessLabel = readiness == null
      ? 'no readiness check-in'
      : '${readiness.score} ${readiness.zone} readiness';
  final action = loggedSets == 0
      ? 'Log the first working set'
      : hasPlan && loggedSets >= plannedSets
      ? 'Finish and debrief'
      : 'Log the next clean set';

  return CoachSignal(
    workflowId: 'live_session_guidance',
    persona: 'analyst',
    coachNote:
        'Coach note: Session is live. Keep the logger fast: use the target, take the rest, and record only the next clean set.',
    observationLabel: 'Live set target',
    observation:
        '$completionLabel complete with $readinessLabel. The next decision belongs inside the workout, not the progress ledger.',
    nextAction: action,
    confidence: hasPlan ? 0.88 : 0.82,
    sourceIds: const [
      'src_macrofactor_workouts_product',
      'src_hevy_app_store_preview',
      'src_fitbod_app_store_preview',
    ],
    uxPrincipleIds: const [
      'uxp_fast_active_logging',
      'uxp_readiness_adjusted_next_action',
      'uxp_coach_voice_with_data_token',
    ],
  );
}

CoachSignal _progressInterpretation(SessionState state) {
  final completed = state.history
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .toList(growable: false);
  final setCount = completed.fold<int>(
    0,
    (total, session) => total + session.totalSets,
  );
  final recoveryWins = completed.where(_isRecoverySession).length;
  final nextFocus = _safeNextFocus(state.lastDebrief?.nextSessionFocus);

  return CoachSignal(
    workflowId: 'progress_interpretation',
    persona: 'analyst',
    coachNote:
        'Coach note: The ledger shows ${completed.length} kept ${completed.length == 1 ? 'promise' : 'promises'} and $setCount sets. Use that proof for the next session.',
    observationLabel: 'Progress proof',
    observation:
        '$recoveryWins recovery ${recoveryWins == 1 ? 'win' : 'wins'} logged. Suggested next move is $nextFocus.',
    nextAction: nextFocus,
    confidence: completed.isEmpty ? 0.72 : 0.86,
    sourceIds: const [
      'src_hevy_app_store_preview',
      'src_strava_app_store_preview',
      'src_garmin_app_store_preview',
    ],
    uxPrincipleIds: const [
      'uxp_progress_without_body_shame',
      'uxp_coach_voice_with_data_token',
    ],
  );
}

CoachSignal? _coastingOrOverreachingSignal(SessionState state) {
  final active = state.activeSession;
  final activeSets = active?.loggedSets ?? const <LoggedSet>[];
  if (activeSets.length >= 3 && _averageRpe(activeSets) <= 5) {
    return _coastingSignal(
      setCount: activeSets.length,
      observation:
          '${activeSets.length} live sets average ${_formatRpe(_averageRpe(activeSets))}/10 RPE. Raise intent or close the session cleanly.',
      nextAction: 'Raise the next set by one RPE',
    );
  }

  final completed = state.history
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .toList(growable: false);
  if (completed.length < 2) return null;
  final latest = completed.last;
  final previous = completed[completed.length - 2];
  final latestVolume = latest.totalVolume ?? 0;
  final previousVolume = previous.totalVolume ?? 0;
  if (previousVolume > 0 && latestVolume > previousVolume * 1.6) {
    return _overreachingSignal(
      observation:
          'Volume jumped from ${previousVolume.round()} kg to ${latestVolume.round()} kg. Keep the next increase bounded.',
      nextAction: 'Hold volume steady next time',
    );
  }

  final latestAverageRpe = _averageRpe(latest.loggedSets);
  if (latest.loggedSets.length >= 3 && latestAverageRpe <= 5) {
    return _coastingSignal(
      setCount: latest.loggedSets.length,
      observation:
          'Last session averaged ${_formatRpe(latestAverageRpe)}/10 RPE across ${latest.loggedSets.length} sets.',
      nextAction: 'Make the first working set honest',
    );
  }
  return null;
}

CoachSignal _coastingSignal({
  required int setCount,
  required String observation,
  required String nextAction,
}) {
  return CoachSignal(
    workflowId: 'coasting_or_overreaching',
    persona: 'challenger',
    coachNote:
        'Coach note: $setCount sets are logged, but the effort signal is soft. Make the next set honest without chasing fatigue.',
    observationLabel: 'Quality check',
    observation: observation,
    nextAction: nextAction,
    confidence: 0.84,
    sourceIds: const [
      'src_macrofactor_workouts_product',
      'src_liftoff_app_store_preview',
      'src_fitbod_app_store_preview',
    ],
    uxPrincipleIds: const [
      'uxp_fast_active_logging',
      'uxp_readiness_adjusted_next_action',
      'uxp_recovery_as_kept_promise',
    ],
  );
}

CoachSignal _overreachingSignal({
  required String observation,
  required String nextAction,
}) {
  return CoachSignal(
    workflowId: 'coasting_or_overreaching',
    persona: 'challenger',
    coachNote:
        'Coach note: The work jumped fast. Hold the next session steady so progress compounds without a recovery debt.',
    observationLabel: 'Load jump',
    observation: observation,
    nextAction: nextAction,
    confidence: 0.87,
    sourceIds: const [
      'src_macrofactor_workouts_product',
      'src_liftoff_app_store_preview',
      'src_fitbod_app_store_preview',
    ],
    uxPrincipleIds: const [
      'uxp_fast_active_logging',
      'uxp_readiness_adjusted_next_action',
      'uxp_recovery_as_kept_promise',
    ],
  );
}

bool _isLowReadiness(ReadinessEntry readiness) {
  return readiness.zone == 'deload' ||
      readiness.score <= 45 ||
      readiness.sleepQuality <= 4 ||
      readiness.sorenessMap.length >= 3;
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
    return exercise.contains('mobility') ||
        exercise.contains('walk') ||
        exercise.contains('reset');
  });
}

double _averageRpe(List<LoggedSet> sets) {
  final rpes = sets
      .map((set) => set.rpe)
      .whereType<int>()
      .where((rpe) => rpe > 0)
      .toList(growable: false);
  if (rpes.isEmpty) return 10;
  return rpes.reduce((a, b) => a + b) / rpes.length;
}

String _formatRpe(double value) {
  return value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
}

String _safeNextFocus(String? nextFocus) {
  final trimmed = nextFocus?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'Start from Today';
  return trimmed.length <= 72
      ? trimmed
      : '${trimmed.substring(0, 72).trim()}...';
}

String _safePainNote(String? note) {
  final trimmed = note?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'pain reported';
  return trimmed.length <= 72
      ? trimmed
      : '${trimmed.substring(0, 72).trim()}...';
}

String _zoneEffort(String zone) {
  return switch (zone) {
    'push' => '7/10',
    'maintain' => '6/10',
    'deload' => '4/10',
    _ => '6/10',
  };
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
