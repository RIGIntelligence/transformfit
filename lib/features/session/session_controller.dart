/// M3: Session controller — orchestrates readiness entry -> workout logging -> debrief.
///
/// Uses a small snapshot-friendly state controller for local development.
/// Drift/Supabase persistence can hydrate it through the same JSON contract.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/engine/readiness.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';

typedef SessionSnapshotWriter = Future<void> Function(SessionState state);

// --- State ---

class SessionState {
  const SessionState({
    this.readinessEntry,
    this.activeSession,
    this.activeSessionPlan = const [],
    this.lastDebrief,
    this.nutritionTarget,
    this.wearableSignal,
    this.history = const [],
  });

  final ReadinessEntry? readinessEntry;
  final WorkoutSession? activeSession;
  final List<SessionPlanExercise> activeSessionPlan;
  final SessionDebrief? lastDebrief;
  final NutritionTarget? nutritionTarget;
  final WearableSignal? wearableSignal;
  final List<WorkoutSession> history;

  Map<String, Object?> toJson() => {
    'readinessEntry': readinessEntry?.toJson(),
    'activeSession': activeSession?.toJson(),
    'activeSessionPlan': activeSessionPlan
        .map((exercise) => exercise.toJson())
        .toList(),
    'lastDebrief': lastDebrief?.toJson(),
    'nutritionTarget': nutritionTarget?.toJson(),
    'wearableSignal': wearableSignal?.toJson(),
    'history': history.map((session) => session.toJson()).toList(),
  };

  factory SessionState.fromJson(Map<String, Object?> json) {
    final rawReadinessEntry = json['readinessEntry'];
    final rawActiveSession = json['activeSession'];
    final rawActiveSessionPlan = json['activeSessionPlan'];
    final rawLastDebrief = json['lastDebrief'];
    final rawNutritionTarget = json['nutritionTarget'];
    final rawWearableSignal = json['wearableSignal'];
    final rawHistory = json['history'];

    final readinessEntry = rawReadinessEntry == null
        ? null
        : ReadinessEntry.fromJson(_objectMapValue(rawReadinessEntry));
    final activeSession = rawActiveSession == null
        ? null
        : WorkoutSession.fromJson(_objectMapValue(rawActiveSession));
    final activeSessionPlan = rawActiveSessionPlan == null
        ? const <SessionPlanExercise>[]
        : List<Object?>.from(rawActiveSessionPlan as List)
              .map(
                (exercise) =>
                    SessionPlanExercise.fromJson(_objectMapValue(exercise)),
              )
              .toList();
    final lastDebrief = rawLastDebrief == null
        ? null
        : SessionDebrief.fromJson(_objectMapValue(rawLastDebrief));
    final nutritionTarget = rawNutritionTarget == null
        ? null
        : NutritionTarget.fromJson(_objectMapValue(rawNutritionTarget));
    final wearableSignal = rawWearableSignal == null
        ? null
        : WearableSignal.fromJson(_objectMapValue(rawWearableSignal));
    final history = rawHistory == null
        ? const <WorkoutSession>[]
        : List<Object?>.from(rawHistory as List)
              .map(
                (session) => WorkoutSession.fromJson(_objectMapValue(session)),
              )
              .toList();

    if (!_validSessionStateSnapshot(
      readinessEntry: readinessEntry,
      activeSession: activeSession,
      activeSessionPlan: activeSessionPlan,
      lastDebrief: lastDebrief,
      nutritionTarget: nutritionTarget,
      wearableSignal: wearableSignal,
      history: history,
    )) {
      throw const FormatException('invalid session state snapshot');
    }

    return SessionState(
      readinessEntry: readinessEntry,
      activeSession: activeSession,
      activeSessionPlan: activeSessionPlan,
      lastDebrief: lastDebrief,
      nutritionTarget: nutritionTarget,
      wearableSignal: wearableSignal,
      history: history,
    );
  }

  SessionState copyWith({
    ReadinessEntry? readinessEntry,
    WorkoutSession? activeSession,
    bool clearActiveSession = false,
    List<SessionPlanExercise>? activeSessionPlan,
    SessionDebrief? lastDebrief,
    NutritionTarget? nutritionTarget,
    bool clearNutritionTarget = false,
    WearableSignal? wearableSignal,
    bool clearWearableSignal = false,
    List<WorkoutSession>? history,
  }) {
    return SessionState(
      readinessEntry: readinessEntry ?? this.readinessEntry,
      activeSession: clearActiveSession
          ? null
          : (activeSession ?? this.activeSession),
      activeSessionPlan: clearActiveSession
          ? const []
          : (activeSessionPlan ?? this.activeSessionPlan),
      lastDebrief: lastDebrief ?? this.lastDebrief,
      nutritionTarget: clearNutritionTarget
          ? null
          : (nutritionTarget ?? this.nutritionTarget),
      wearableSignal: clearWearableSignal
          ? null
          : (wearableSignal ?? this.wearableSignal),
      history: history ?? this.history,
    );
  }
}

// --- Controller ---

class SessionController extends ChangeNotifier {
  SessionController({
    SessionState initialState = const SessionState(),
    SessionSnapshotWriter? snapshotWriter,
  }) : this._(initialState, snapshotWriter);

  SessionController._(this._state, this._snapshotWriter);

  SessionState _state;
  final SessionSnapshotWriter? _snapshotWriter;
  Future<void> _snapshotWriteQueue = Future<void>.value();

  SessionState get state => _state;

  Map<String, Object?> snapshot() => _state.toJson();

  Future<void> waitForSnapshotWrites() => _snapshotWriteQueue;

  @visibleForTesting
  Future<void> get snapshotWritesIdle => waitForSnapshotWrites();

  void restore(SessionState snapshot, {bool persist = false}) {
    _setState(snapshot, persist: persist);
  }

  /// Record today's readiness check-in from user inputs.
  void submitReadiness({
    required int energyLevel,
    required int sleepQuality,
    required List<String> sorenessMap,
    int? hrv,
  }) {
    if (_state.activeSession != null) return;

    final result = computeReadinessScore(
      ReadinessInputs(
        energyLevel: energyLevel,
        sleepQuality: sleepQuality,
        sorenessMap: sorenessMap,
        hrv: hrv,
      ),
    );

    final entry = ReadinessEntry.fromResult(
      id: _uuid(),
      date: DateTime.now(),
      result: result,
    );

    _setState(_state.copyWith(readinessEntry: entry));
  }

  /// Start a new workout session linked to today's readiness entry.
  void startSession({List<SessionPlanExercise> plan = const []}) {
    if (_state.activeSession != null) return;

    final readiness = _state.readinessEntry;
    if (readiness == null) return;

    final session = WorkoutSession(
      id: _uuid(),
      startedAt: DateTime.now(),
      readinessEntryId: readiness.id,
      volumeMultiplier: volumeMultiplierForZone(readiness.zone),
    );

    _setState(
      _state.copyWith(
        activeSession: session,
        activeSessionPlan: plan.isEmpty ? const [] : List.unmodifiable(plan),
      ),
    );
  }

  /// Attach the ordered plan queue for the current active session.
  void attachActiveSessionPlan(List<SessionPlanExercise> exercises) {
    if (_state.activeSession == null) return;
    _setState(
      _state.copyWith(
        activeSessionPlan: exercises.isEmpty
            ? const []
            : List.unmodifiable(exercises),
      ),
    );
  }

  /// Log a set during the active session.
  void logSet({
    required String exerciseName,
    required int setNumber,
    String? exerciseId,
    DateTime? loggedAt,
    double? weightKg,
    int? reps,
    int? durationSeconds,
    int? rpe,
    int? prescribedRestSeconds,
    int? actualRestSeconds,
  }) {
    final session = _state.activeSession;
    if (session == null) return;
    final normalizedExerciseName = exerciseName.trim();
    final normalizedExerciseId = _trimmedOrNull(exerciseId);
    if (!_validSetInput(
      exerciseName: normalizedExerciseName,
      setNumber: setNumber,
      weightKg: weightKg,
      reps: reps,
      durationSeconds: durationSeconds,
      rpe: rpe,
      prescribedRestSeconds: prescribedRestSeconds,
      actualRestSeconds: actualRestSeconds,
    )) {
      return;
    }

    final newSet = LoggedSet(
      id: _uuid(),
      exerciseId: normalizedExerciseId,
      exerciseName: normalizedExerciseName,
      setNumber: setNumber,
      loggedAt: loggedAt ?? DateTime.now(),
      weightKg: weightKg,
      reps: reps,
      durationSeconds: durationSeconds,
      rpe: rpe,
      prescribedRestSeconds: prescribedRestSeconds,
      actualRestSeconds: actualRestSeconds,
    );

    _setState(
      _state.copyWith(
        activeSession: WorkoutSession(
          id: session.id,
          startedAt: session.startedAt,
          readinessEntryId: session.readinessEntryId,
          loggedSets: [...session.loggedSets, newSet],
          volumeMultiplier: session.volumeMultiplier,
        ),
      ),
    );
  }

  /// Remove the most recently logged set from the active session.
  void removeLastSet() {
    final session = _state.activeSession;
    if (session == null || session.loggedSets.isEmpty) return;

    _setState(
      _state.copyWith(
        activeSession: WorkoutSession(
          id: session.id,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          readinessEntryId: session.readinessEntryId,
          loggedSets: session.loggedSets
              .take(session.loggedSets.length - 1)
              .toList(),
          sessionNotes: session.sessionNotes,
          volumeMultiplier: session.volumeMultiplier,
        ),
      ),
    );
  }

  /// End the active session and move it to history.
  void endSession({String? notes}) {
    final session = _state.activeSession;
    if (session == null) return;
    if (session.loggedSets.isEmpty) return;

    final ended = WorkoutSession(
      id: session.id,
      startedAt: session.startedAt,
      endedAt: DateTime.now(),
      readinessEntryId: session.readinessEntryId,
      loggedSets: session.loggedSets,
      sessionNotes: _trimmedOrNull(notes),
      volumeMultiplier: session.volumeMultiplier,
    );

    _setState(
      _state.copyWith(
        clearActiveSession: true,
        history: [..._state.history, ended],
      ),
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
    if (_state.activeSession != null) return;
    final sessionId = _state.history.isNotEmpty ? _state.history.last.id : null;
    if (sessionId == null) return;
    if (!_validDebriefInput(
      perceivedExertion: perceivedExertion,
      satisfaction: satisfaction,
    )) {
      return;
    }

    final debrief = SessionDebrief(
      id: _uuid(),
      sessionId: sessionId,
      createdAt: DateTime.now(),
      perceivedExertion: perceivedExertion,
      satisfaction: satisfaction,
      painNotes: _trimmedOrNull(painNotes),
      whatWorked: _trimmedOrNull(whatWorked),
      whatToChange: _trimmedOrNull(whatToChange),
      nextSessionFocus: _trimmedOrNull(nextSessionFocus),
    );

    _setState(_state.copyWith(lastDebrief: debrief));
  }

  /// Set a user-selected nutrition target for activation and coach context.
  void setNutritionTarget({
    required String targetType,
    required String label,
    required double dailyTarget,
    required String unit,
    List<String>? sourceIds,
    String safetyNote = NutritionTarget.defaultSafetyNote,
  }) {
    final target = NutritionTarget(
      id: _uuid(),
      createdAt: DateTime.now(),
      targetType: targetType.trim(),
      label: label.trim(),
      dailyTarget: dailyTarget,
      unit: unit.trim(),
      sourceIds: List.unmodifiable(
        sourceIds ?? NutritionTarget.defaultSourceIds,
      ),
      safetyNote: safetyNote.trim(),
    );
    if (!target.isValid) return;
    _setState(_state.copyWith(nutritionTarget: target));
  }

  void clearNutritionTarget() {
    _setState(_state.copyWith(clearNutritionTarget: true));
  }

  /// Store the latest wearable context from HealthKit, Health Connect, or a
  /// deterministic local sample used by tests and demos.
  void setWearableSignal(WearableSignal signal) {
    if (!signal.isValid) return;
    _setState(_state.copyWith(wearableSignal: signal));
  }

  void clearWearableSignal() {
    _setState(_state.copyWith(clearWearableSignal: true));
  }

  /// Reset for a new day (clears current readiness but keeps history).
  void resetDay() {
    if (_state.activeSession != null) return;
    _setState(
      SessionState(
        history: _state.history,
        nutritionTarget: _state.nutritionTarget,
        wearableSignal: _state.wearableSignal,
      ),
    );
  }

  /// Clear all local session state, for example after account sign-out.
  void clear({bool persist = false}) {
    _setState(const SessionState(), persist: persist);
  }

  void _setState(SessionState nextState, {bool persist = true}) {
    _state = nextState;
    notifyListeners();
    final snapshotWriter = _snapshotWriter;
    if (persist && snapshotWriter != null) {
      _snapshotWriteQueue = _snapshotWriteQueue
          .then((_) => snapshotWriter(nextState))
          .catchError((Object error, StackTrace stack) {
            debugPrint(
              'Session snapshot persistence failed: ${error.runtimeType}',
            );
          });
      unawaited(_snapshotWriteQueue);
    }
  }
}

bool _validSetInput({
  required String exerciseName,
  required int setNumber,
  double? weightKg,
  int? reps,
  int? durationSeconds,
  int? rpe,
  int? prescribedRestSeconds,
  int? actualRestSeconds,
}) {
  if (exerciseName.isEmpty || setNumber <= 0) {
    return false;
  }
  if (reps == null && durationSeconds == null) {
    return false;
  }
  if (weightKg != null && (!weightKg.isFinite || weightKg <= 0)) {
    return false;
  }
  if (reps != null && reps <= 0) {
    return false;
  }
  if (durationSeconds != null && durationSeconds <= 0) {
    return false;
  }
  if (rpe != null && (rpe < 1 || rpe > 10)) {
    return false;
  }
  if (prescribedRestSeconds != null &&
      (prescribedRestSeconds < 0 || prescribedRestSeconds > 600)) {
    return false;
  }
  if (actualRestSeconds != null &&
      (actualRestSeconds < 0 || actualRestSeconds > 7200)) {
    return false;
  }
  return true;
}

bool _validDebriefInput({
  required int perceivedExertion,
  required int satisfaction,
}) {
  return perceivedExertion >= 1 &&
      perceivedExertion <= 10 &&
      satisfaction >= 1 &&
      satisfaction <= 5;
}

bool _validSessionStateSnapshot({
  required ReadinessEntry? readinessEntry,
  required WorkoutSession? activeSession,
  required List<SessionPlanExercise> activeSessionPlan,
  required SessionDebrief? lastDebrief,
  required NutritionTarget? nutritionTarget,
  required WearableSignal? wearableSignal,
  required List<WorkoutSession> history,
}) {
  if (activeSession == null && activeSessionPlan.isNotEmpty) {
    return false;
  }
  if (activeSession != null) {
    if (activeSession.endedAt != null) {
      return false;
    }
    if (readinessEntry == null ||
        activeSession.readinessEntryId != readinessEntry.id) {
      return false;
    }
  }

  if (history.any((session) => session.endedAt == null)) {
    return false;
  }
  final sessionIds = <String>{};
  for (final session in history) {
    if (!sessionIds.add(session.id)) {
      return false;
    }
  }
  if (activeSession != null && !sessionIds.add(activeSession.id)) {
    return false;
  }
  for (var index = 1; index < history.length; index += 1) {
    final previousEndedAt = history[index - 1].endedAt!;
    if (history[index].startedAt.isBefore(previousEndedAt)) {
      return false;
    }
  }
  if (activeSession != null && history.isNotEmpty) {
    final previousEndedAt = history.last.endedAt!;
    if (activeSession.startedAt.isBefore(previousEndedAt)) {
      return false;
    }
  }

  if (lastDebrief != null) {
    if (history.isEmpty || history.last.id != lastDebrief.sessionId) {
      return false;
    }
    final latestEndedAt = history.last.endedAt!;
    if (lastDebrief.createdAt.isBefore(latestEndedAt)) {
      return false;
    }
  }

  if (nutritionTarget != null && !nutritionTarget.isValid) {
    return false;
  }
  if (wearableSignal != null && !wearableSignal.isValid) {
    return false;
  }

  return true;
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

final sessionControllerProvider = Provider<SessionController>((ref) {
  return SessionController();
});

final sessionStateProvider = Provider<SessionState>((ref) {
  final controller = ref.watch(sessionControllerProvider);
  void onSessionChanged() => ref.invalidateSelf();

  controller.addListener(onSessionChanged);
  ref.onDispose(() => controller.removeListener(onSessionChanged));

  return controller.state;
});

Map<String, Object?> _objectMapValue(Object? value) {
  return Map<String, Object?>.from(value! as Map);
}

String _uuid() {
  _uuidCounter += 1;
  final now = DateTime.now().microsecondsSinceEpoch;
  return 'tf-$now-$_uuidCounter';
}

int _uuidCounter = 0;
