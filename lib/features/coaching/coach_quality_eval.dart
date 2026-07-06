import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

class CoachQualityIssue {
  const CoachQualityIssue({required this.id, required this.message});

  final String id;
  final String message;
}

class CoachQualityVerdict {
  const CoachQualityVerdict({required this.issues});

  final List<CoachQualityIssue> issues;

  bool get passed => issues.isEmpty;

  List<String> get issueIds => issues.map((issue) => issue.id).toList();
}

CoachQualityVerdict buildCoachQualityVerdict(SessionState state) {
  return evaluateCoachSignal(state: state, signal: buildCoachSignal(state));
}

CoachQualityVerdict evaluateCoachSignal({
  required SessionState state,
  required CoachSignal signal,
}) {
  final issues = <CoachQualityIssue>[];

  void add(String id, String message) {
    issues.add(CoachQualityIssue(id: id, message: message));
  }

  if (!coachSignalCopyIsGateSafe(signal)) {
    add('copy_safety', 'Coach copy failed the banned-term or emoji guardrail.');
  }
  if (!signal.coachNote.startsWith('Coach note:')) {
    add('coach_note_prefix', 'Coach note must use the source-trace prefix.');
  }
  if (signal.coachNote.split(RegExp(r'\s+')).length > 60) {
    add('coach_note_length', 'Coach note must stay within 60 words.');
  }
  if (signal.observation.trim().isEmpty || signal.nextAction.trim().isEmpty) {
    add(
      'action_point_shape',
      'Coach signal needs observation and next action.',
    );
  }
  if (signal.sourceIds.length < 3) {
    add('source_trace', 'Coach signal needs at least three source IDs.');
  }
  if (signal.uxPrincipleIds.length < 2) {
    add('ux_trace', 'Coach signal needs at least two UX principle IDs.');
  }
  if (!_hasDataToken(signal)) {
    add('data_token', 'Coach signal needs a data token or explicit context.');
  }

  final painNotes = state.lastDebrief?.painNotes;
  if (hasReportedPain(painNotes)) {
    if (signal.workflowId != 'pain_or_injury_guardrail') {
      add('pain_workflow', 'Reported pain must route to pain guardrail.');
    }
    if (!_containsAny(signal.nextAction, const [
      'pain-free',
      'modify',
      'stop',
    ])) {
      add('pain_next_action', 'Pain guardrail must offer a safe action.');
    }
    if (_containsAny(
      '${signal.coachNote} ${signal.observation} ${signal.nextAction}',
      const ['increase load', 'raise the next set', 'pr ', 'push through'],
    )) {
      add('pain_progression_block', 'Pain guardrail must block progression.');
    }
  }

  final readiness = state.readinessEntry;
  if (readiness != null && _isLowReadiness(readiness)) {
    if (signal.workflowId != 'doms_or_low_readiness' &&
        signal.workflowId != 'pain_or_injury_guardrail') {
      add('low_readiness_workflow', 'Low readiness must alter the coach path.');
    }
    if (_containsAny(signal.nextAction, const ['raise', 'increase', 'pr'])) {
      add('low_readiness_progression', 'Low readiness cannot push load.');
    }
  }

  final activeSets = state.activeSession?.loggedSets ?? const <LoggedSet>[];
  if (activeSets.length >= 3 && _averageRpe(activeSets) <= 5) {
    if (signal.workflowId != 'coasting_or_overreaching') {
      add('coasting_workflow', 'Soft live effort must route to challenge.');
    }
  } else if (state.activeSession != null &&
      signal.workflowId != 'live_session_guidance' &&
      signal.workflowId != 'doms_or_low_readiness' &&
      signal.workflowId != 'pain_or_injury_guardrail' &&
      signal.workflowId != 'coasting_or_overreaching') {
    add(
      'live_session_workflow',
      'A normal active session must stay focused on live set guidance.',
    );
  }

  if (state.activeSession == null &&
      _hasRapidVolumeJump(state.history) &&
      signal.workflowId != 'coasting_or_overreaching' &&
      signal.workflowId != 'pain_or_injury_guardrail') {
    add('overreach_workflow', 'Rapid volume jump must route to a hold signal.');
  }

  if (state.readinessEntry == null &&
      state.activeSession == null &&
      state.history.isEmpty &&
      signal.workflowId != 'day_0_activation') {
    add('day_zero_workflow', 'Day zero must route to activation.');
  }

  return CoachQualityVerdict(issues: List.unmodifiable(issues));
}

bool _hasDataToken(CoachSignal signal) {
  final text = '${signal.coachNote} ${signal.observation} ${signal.nextAction}'
      .toLowerCase();
  if (RegExp(r'\d').hasMatch(text)) return true;
  return _containsAny(text, const [
    'readiness',
    'rpe',
    'sets',
    'session',
    'pain',
    'recovery',
    'load',
  ]);
}

bool _containsAny(String value, List<String> tokens) {
  final text = value.toLowerCase();
  return tokens.any(text.contains);
}

bool _isLowReadiness(ReadinessEntry readiness) {
  return readiness.zone == 'deload' ||
      readiness.score <= 45 ||
      readiness.sleepQuality <= 4 ||
      readiness.sorenessMap.length >= 3;
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

bool _hasRapidVolumeJump(List<WorkoutSession> history) {
  final completed = history
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .toList(growable: false);
  if (completed.length < 2) return false;
  final latestVolume = completed.last.totalVolume ?? 0;
  final previousVolume = completed[completed.length - 2].totalVolume ?? 0;
  return previousVolume > 0 && latestVolume > previousVolume * 1.6;
}
