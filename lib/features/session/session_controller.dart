/// M3: Session controller — orchestrates readiness entry -> workout logging -> debrief.
///
/// Uses Riverpod 3.x Notifier pattern with in-memory state for local development.
/// Drift persistence can be wired by replacing the state backend.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/engine/readiness.dart';
import 'package:transformfit/features/session/models.dart';

// --- State ---

class SessionState {
  const SessionState({
    this.readinessEntry,
    this.activeSession,
    this.lastDebrief,
    this.history = const [],
  });

  final ReadinessEntry? readinessEntry;
  final WorkoutSession? activeSession;
  final SessionDebrief? lastDebrief;
  final List<WorkoutSession> history;

  SessionState copyWith({
    ReadinessEntry? readinessEntry,
    WorkoutSession? activeSession,
    bool clearActiveSession = false,
    SessionDebrief? lastDebrief,
    List<WorkoutSession>? history,
  }) {
    return SessionState(
      readinessEntry: readinessEntry ?? this.readinessEntry,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      lastDebrief: lastDebrief ?? this.lastDebrief,
      history: history ?? this.history,
    );
  }
}

// --- Controller ---

class SessionController {
  SessionState _state = const SessionState();
  SessionState get state => _state;

  /// Record today's readiness check-in from user inputs.
  void submitReadiness({
    required int energyLevel,
    required int sleepQuality,
    required List<String> sorenessMap,
    int? hrv,
  }) {
    final result = computeReadinessScore(ReadinessInputs(
      energyLevel: energyLevel,
      sleepQuality: sleepQuality,
      sorenessMap: sorenessMap,
      hrv: hrv,
    ));

    final entry = ReadinessEntry.fromResult(
      id: _uuid(),
      date: DateTime.now(),
      result: result,
    );

    _state = _state.copyWith(readinessEntry: entry);
  }

  /// Start a new workout session linked to today's readiness entry.
  void startSession() {
    final readiness = _state.readinessEntry;
    if (readiness == null) return;

    final session = WorkoutSession(
      id: _uuid(),
      startedAt: DateTime.now(),
      readinessEntryId: readiness.id,
      volumeMultiplier: volumeMultiplierForZone(readiness.zone),
    );

    _state = _state.copyWith(activeSession: session);
  }

  /// Log a set during the active session.
  void logSet({
    required String exerciseName,
    required int setNumber,
    double? weightKg,
    int? reps,
    int? durationSeconds,
    int? rpe,
  }) {
    final session = _state.activeSession;
    if (session == null) return;

    final newSet = LoggedSet(
      id: _uuid(),
      exerciseName: exerciseName,
      setNumber: setNumber,
      weightKg: weightKg,
      reps: reps,
      durationSeconds: durationSeconds,
      rpe: rpe,
    );

    _state = _state.copyWith(
      activeSession: WorkoutSession(
        id: session.id,
        startedAt: session.startedAt,
        readinessEntryId: session.readinessEntryId,
        loggedSets: [...session.loggedSets, newSet],
        volumeMultiplier: session.volumeMultiplier,
      ),
    );
  }

  /// End the active session and move it to history.
  void endSession({String? notes}) {
    final session = _state.activeSession;
    if (session == null) return;

    final ended = WorkoutSession(
      id: session.id,
      startedAt: session.startedAt,
      endedAt: DateTime.now(),
      readinessEntryId: session.readinessEntryId,
      loggedSets: session.loggedSets,
      sessionNotes: notes,
      volumeMultiplier: session.volumeMultiplier,
    );

    _state = _state.copyWith(
      clearActiveSession: true,
      history: [..._state.history, ended],
    );
  }

  /// Submit a post-session debrief.
  void submitDebrief({
    required int perceivedExertion,
    required int satisfaction,
    String? painNotes,
    String? whatWorked,
    String? whatToChange,
    String? nextSessionFocus,
  }) {
    final sessionId = _state.history.isNotEmpty
        ? _state.history.last.id
        : _state.activeSession?.id;
    if (sessionId == null) return;

    final debrief = SessionDebrief(
      id: _uuid(),
      sessionId: sessionId,
      createdAt: DateTime.now(),
      perceivedExertion: perceivedExertion,
      satisfaction: satisfaction,
      painNotes: painNotes,
      whatWorked: whatWorked,
      whatToChange: whatToChange,
      nextSessionFocus: nextSessionFocus,
    );

    _state = _state.copyWith(lastDebrief: debrief);
  }

  /// Reset for a new day (clears current readiness but keeps history).
  void resetDay() {
    _state = SessionState(history: _state.history);
  }
}

final sessionControllerProvider = Provider<SessionController>((ref) {
  return SessionController();
});

String _uuid() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return 'tf-$now';
}
