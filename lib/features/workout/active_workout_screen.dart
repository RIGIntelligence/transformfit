import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/workout/set_intelligence.dart';
import 'package:transformfit/features/workout/workout_prefill.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, this.initialPrefill});

  final WorkoutPrefill? initialPrefill;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late final TextEditingController _exerciseController;
  late int _weightKg;
  late int _reps;
  late int _rpe;
  late int _restSeconds;
  int _restCountdownRemainingSeconds = 0;
  bool _restCountdownActive = false;
  Timer? _restCountdownTimer;
  bool _painSafetyActive = false;
  int? _painSafetyWeightCeiling;
  int? _readinessWeightCeiling;
  String? _activeTechniqueSwapPlanId;
  String? _activeTechniqueSwapName;
  String? _activeTechniqueCue;
  late final List<WorkoutPlanExercise> _sessionPlan;
  late int _planIndex;
  String? _liveStatus;

  WorkoutPlanExercise? get _currentPlanExercise {
    if (_sessionPlan.isEmpty) return null;
    return _sessionPlan[_planIndex.clamp(0, _sessionPlan.length - 1).toInt()];
  }

  int get _defaultRestSeconds =>
      _currentPlanExercise?.targetRestSeconds ??
      widget.initialPrefill?.targetRestSeconds ??
      90;

  @override
  void initState() {
    super.initState();
    final initialPrefill = widget.initialPrefill;
    final sessionState = ref.read(sessionControllerProvider).state;
    _sessionPlan = _readinessAdjustedSessionPlan(
      _initialSessionPlan(initialPrefill, sessionState),
      sessionState.readinessEntry,
    );
    if (initialPrefill != null && _sessionPlan.isNotEmpty) {
      ref
          .read(sessionControllerProvider)
          .attachActiveSessionPlan(_toSessionPlan(_sessionPlan));
    }
    _planIndex = _resolvedPlanIndex(
      plan: _sessionPlan,
      loggedSets: sessionState.activeSession?.loggedSets ?? const [],
      requestedIndex: initialPrefill?.exerciseIndex ?? 0,
    );
    final initialExercise = _currentPlanExercise;
    _exerciseController = TextEditingController(
      text:
          initialExercise?.exerciseName ??
          initialPrefill?.exerciseName ??
          'Goblet squat',
    );
    _weightKg =
        initialExercise?.suggestedWeightKg ??
        initialPrefill?.suggestedWeightKg ??
        40;
    if ((initialExercise != null &&
            initialExercise.suggestedWeightKg == null) ||
        (initialExercise == null &&
            initialPrefill != null &&
            initialPrefill.suggestedWeightKg == null)) {
      _weightKg = 0;
    }
    _reps = initialExercise?.targetReps ?? initialPrefill?.targetReps ?? 8;
    _rpe = initialExercise?.targetRpe ?? initialPrefill?.targetRpe ?? 7;
    _restSeconds = _defaultRestSeconds;
    _applyReadinessCaps(sessionState.readinessEntry, resetWeightCeiling: true);
    if (_readinessCapActive(sessionState.readinessEntry)) {
      _liveStatus = _readinessCapStatus(sessionState.readinessEntry!);
    }
  }

  @override
  void dispose() {
    _restCountdownTimer?.cancel();
    _exerciseController.dispose();
    super.dispose();
  }

  void _changeWeight(int delta) {
    final readiness = ref.read(sessionControllerProvider).state.readinessEntry;
    setState(() {
      final maxWeight = _activeWeightCeiling(readiness);
      _weightKg = (_weightKg + (delta * 5)).clamp(0, maxWeight).toInt();
    });
  }

  void _changeReps(int delta) {
    setState(() => _reps = (_reps + delta).clamp(1, 60));
  }

  void _changeRpe(int delta) {
    final readiness = ref.read(sessionControllerProvider).state.readinessEntry;
    setState(() {
      final maxRpe = _painSafetyActive || _readinessCapActive(readiness)
          ? 6
          : 10;
      _rpe = (_rpe + delta).clamp(1, maxRpe).toInt();
    });
  }

  void _changeRest(int delta) {
    final currentValue = _restCountdownActive
        ? _restCountdownRemainingSeconds
        : _restSeconds;
    final nextValue = (currentValue + (delta * 15)).clamp(0, 300).toInt();
    setState(() {
      _restSeconds = nextValue;
      if (_restCountdownActive) {
        _restCountdownRemainingSeconds = nextValue;
      }
    });
    if (_restCountdownActive && nextValue == 0) {
      _restCountdownTimer?.cancel();
      _restCountdownTimer = null;
      setState(() => _restCountdownActive = false);
      _publishLiveStatus('Rest complete. Next set is ready.');
    }
  }

  void _applyWarmupSet() {
    final readiness = ref.read(sessionControllerProvider).state.readinessEntry;
    final warmWeight = _weightKg <= 0 ? 0 : ((_weightKg * 0.6) / 5).round() * 5;
    setState(() {
      _weightKg = warmWeight.clamp(0, 320);
      _reps = (_reps + 2).clamp(6, 15);
      _rpe = 4;
      _restSeconds = 60;
      _applyReadinessCaps(readiness, resetWeightCeiling: true);
      if (_painSafetyActive) {
        _applyPainSafetyCaps();
      }
    });
    _publishLiveStatus('Warm-up set loaded. Keep it crisp and easy.');
    HapticFeedback.selectionClick();
  }

  void _applyPreviousSet() {
    final readiness = ref.read(sessionControllerProvider).state.readinessEntry;
    final previousReference = previousSetReferenceForExercise(
      ref.read(sessionControllerProvider).state.history,
      exerciseName: _exerciseController.text,
      exerciseId: _currentPlanExercise?.exerciseId,
    );
    final previous = previousReference?.set;
    if (previous == null) return;

    setState(() {
      _weightKg = previous.weightKg?.round() ?? _weightKg;
      _reps = previous.reps ?? _reps;
      _rpe = previous.rpe ?? _rpe;
      _restSeconds = _defaultRestSeconds;
      _applyReadinessCaps(readiness, resetWeightCeiling: true);
      if (_painSafetyActive) {
        _applyPainSafetyCaps();
      }
    });
    _publishLiveStatus('Previous set applied for ${previous.exerciseName}.');
    HapticFeedback.selectionClick();
  }

  void _applyPlanTarget() {
    final currentPlanExercise = _currentPlanExercise;
    if (currentPlanExercise == null) return;
    final readiness = ref.read(sessionControllerProvider).state.readinessEntry;

    setState(() {
      _applyPlanExercise(currentPlanExercise);
      _applyReadinessCaps(readiness, resetWeightCeiling: true);
      if (_painSafetyActive) {
        _applyPainSafetyCaps();
      }
    });
    _publishLiveStatus(
      'Plan target restored for ${currentPlanExercise.exerciseName}.',
    );
    HapticFeedback.selectionClick();
  }

  void _applyTechniqueSwap() {
    final readiness = ref.read(sessionControllerProvider).state.readinessEntry;
    final currentPlanExercise = _currentPlanExercise;
    final sourceName =
        currentPlanExercise?.exerciseName ?? _exerciseController.text.trim();
    if (sourceName.isEmpty) return;
    final swap = _techniqueSwapForExercise(
      exerciseName: sourceName,
      currentWeightKg: _weightKg,
      currentReps: _reps,
      currentRpe: _rpe,
      currentRestSeconds: _restSeconds,
      prescribedRestSeconds: _defaultRestSeconds,
    );

    setState(() {
      _activeTechniqueSwapPlanId = currentPlanExercise?.exerciseId;
      _activeTechniqueSwapName = swap.exerciseName;
      _activeTechniqueCue = swap.cue;
      _exerciseController.text = swap.exerciseName;
      _weightKg = swap.weightKg;
      _reps = swap.reps;
      _rpe = swap.rpe;
      _restSeconds = swap.restSeconds;
      _applyReadinessCaps(readiness, resetWeightCeiling: true);
      if (_painSafetyActive) {
        _applyPainSafetyCaps();
      }
    });
    _publishLiveStatus(
      'Technique swap loaded: ${swap.exerciseName}. ${swap.cue}',
    );
    HapticFeedback.selectionClick();
  }

  void _skipToNextExercise() {
    if (_planIndex >= _sessionPlan.length - 1) return;
    final readiness = ref.read(sessionControllerProvider).state.readinessEntry;
    setState(() {
      _planIndex += 1;
      _applyPlanExercise(_sessionPlan[_planIndex]);
      _applyReadinessCaps(readiness, resetWeightCeiling: true);
      if (_painSafetyActive) {
        _painSafetyWeightCeiling = _weightKg;
        _applyPainSafetyCaps();
      }
    });
    _publishLiveStatus('Skipped to ${_sessionPlan[_planIndex].exerciseName}.');
    HapticFeedback.selectionClick();
  }

  void _handleExerciseChanged() {
    setState(() {
      if (_activeTechniqueSwapName != null &&
          !_isSameExercise(
            _exerciseController.text,
            _activeTechniqueSwapName!,
          )) {
        _activeTechniqueSwapPlanId = null;
        _activeTechniqueSwapName = null;
        _activeTechniqueCue = null;
      }
    });
  }

  void _publishLiveStatus(String message, {bool persist = true}) {
    if (!mounted) return;
    if (persist) {
      setState(() => _liveStatus = message);
    }
    if (MediaQuery.supportsAnnounceOf(context)) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    }
  }

  void _cancelRestCountdown() {
    _restCountdownTimer?.cancel();
    _restCountdownTimer = null;
    _restCountdownActive = false;
    _restCountdownRemainingSeconds = 0;
  }

  void _startRestCountdown(int seconds, {required String statusPrefix}) {
    _restCountdownTimer?.cancel();
    _restCountdownTimer = null;
    if (seconds <= 0) {
      setState(() {
        _restCountdownActive = false;
        _restCountdownRemainingSeconds = 0;
      });
      _publishLiveStatus('$statusPrefix Rest skipped.');
      return;
    }

    setState(() {
      _restCountdownActive = true;
      _restCountdownRemainingSeconds = seconds;
    });
    _publishLiveStatus('$statusPrefix Rest started: ${_restLabel(seconds)}.');

    _restCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_restCountdownRemainingSeconds <= 1) {
        timer.cancel();
        _restCountdownTimer = null;
        setState(() {
          _restCountdownActive = false;
          _restCountdownRemainingSeconds = 0;
        });
        _publishLiveStatus('Rest complete. Next set is ready.');
        return;
      }
      setState(() {
        _restCountdownRemainingSeconds -= 1;
      });
    });
  }

  int _painSafetyCeilingFromPrevious(LoggedSet? previous) {
    final previousWeight = previous?.weightKg?.round();
    if (previousWeight == null) return _weightKg.clamp(0, 320).toInt();
    return previousWeight.clamp(0, 320).toInt();
  }

  void _applyPainSafetyCaps() {
    final ceiling = _painSafetyWeightCeiling ?? _weightKg.clamp(0, 320).toInt();
    _painSafetyWeightCeiling = ceiling;
    if (_weightKg > ceiling) {
      _weightKg = ceiling;
    }
    if (_rpe > 6) {
      _rpe = 6;
    }
    if (_restSeconds < _defaultRestSeconds) {
      _restSeconds = _defaultRestSeconds;
    }
  }

  int _activeWeightCeiling(ReadinessEntry? readiness) {
    final ceilings = <int>[320];
    if (_painSafetyActive) {
      ceilings.add(_painSafetyWeightCeiling ?? _weightKg);
    }
    if (_readinessCapActive(readiness)) {
      ceilings.add(_readinessWeightCeiling ?? _weightKg);
    }
    return ceilings
        .reduce((value, element) => value < element ? value : element)
        .clamp(0, 320)
        .toInt();
  }

  void _applyReadinessCaps(
    ReadinessEntry? readiness, {
    bool resetWeightCeiling = false,
  }) {
    if (!_readinessCapActive(readiness)) {
      _readinessWeightCeiling = null;
      return;
    }
    if (resetWeightCeiling || _readinessWeightCeiling == null) {
      _readinessWeightCeiling = _readinessCappedWeightKg(_weightKg);
    }
    final ceiling = _readinessWeightCeiling ?? _weightKg.clamp(0, 320).toInt();
    if (_weightKg > ceiling) {
      _weightKg = ceiling;
    }
    if (_rpe > 6) {
      _rpe = 6;
    }
    if (_restSeconds < _defaultRestSeconds) {
      _restSeconds = _defaultRestSeconds;
    }
  }

  void _activatePainSafety() {
    final previousReference = previousSetReferenceForExercise(
      ref.read(sessionControllerProvider).state.history,
      exerciseName: _exerciseController.text,
      exerciseId: _currentPlanExercise?.exerciseId,
    );
    final previous = previousReference?.set;
    setState(() {
      _painSafetyActive = true;
      _painSafetyWeightCeiling = _painSafetyCeilingFromPrevious(previous);
      _applyPainSafetyCaps();
    });
    _publishLiveStatus(
      'Pain safety active. Load progression blocked; use a pain-free option or finish.',
    );
    HapticFeedback.selectionClick();
  }

  List<WorkoutPlanExercise> _initialSessionPlan(
    WorkoutPrefill? prefill,
    SessionState sessionState,
  ) {
    if (prefill == null) {
      return _fromSessionPlan(sessionState.activeSessionPlan);
    }
    if (prefill.sessionExercises.isNotEmpty) {
      return prefill.sessionExercises;
    }
    return [prefill.selectedExercise];
  }

  List<WorkoutPlanExercise> _readinessAdjustedSessionPlan(
    List<WorkoutPlanExercise> plan,
    ReadinessEntry? readiness,
  ) {
    if (!_readinessCapActive(readiness)) return plan;
    return [
      for (final exercise in plan)
        WorkoutPlanExercise(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          targetSets: _readinessCappedTargetSets(exercise.targetSets),
          targetReps: exercise.targetReps,
          targetRpe: exercise.targetRpe.clamp(1, 6).toInt(),
          targetRestSeconds: _readinessCappedRestSeconds(
            exercise.targetRestSeconds,
          ),
          suggestedWeightKg: exercise.suggestedWeightKg,
        ),
    ];
  }

  List<SessionPlanExercise> _toSessionPlan(List<WorkoutPlanExercise> plan) {
    return [
      for (final exercise in plan)
        SessionPlanExercise(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          targetSets: exercise.targetSets,
          targetReps: exercise.targetReps,
          targetRpe: exercise.targetRpe,
          targetRestSeconds: exercise.targetRestSeconds,
          suggestedWeightKg: exercise.suggestedWeightKg,
        ),
    ];
  }

  List<WorkoutPlanExercise> _fromSessionPlan(List<SessionPlanExercise> plan) {
    return [
      for (final exercise in plan)
        WorkoutPlanExercise(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          targetSets: exercise.targetSets,
          targetReps: exercise.targetReps,
          targetRpe: exercise.targetRpe,
          targetRestSeconds: exercise.targetRestSeconds,
          suggestedWeightKg: exercise.suggestedWeightKg,
        ),
    ];
  }

  int _resolvedPlanIndex({
    required List<WorkoutPlanExercise> plan,
    required List<LoggedSet> loggedSets,
    required int requestedIndex,
  }) {
    if (plan.isEmpty) return 0;
    if (loggedSets.isEmpty) {
      return requestedIndex.clamp(0, plan.length - 1).toInt();
    }
    final completedByIndex = _completedPlanSetCounts(
      plan: plan,
      loggedSets: loggedSets,
    );
    for (var index = 0; index < plan.length; index += 1) {
      if (completedByIndex[index] < plan[index].targetSets) {
        return index;
      }
    }
    return plan.length - 1;
  }

  void _applyPlanExercise(WorkoutPlanExercise exercise) {
    _activeTechniqueSwapPlanId = null;
    _activeTechniqueSwapName = null;
    _activeTechniqueCue = null;
    _readinessWeightCeiling = null;
    _exerciseController.text = exercise.exerciseName;
    _weightKg = exercise.suggestedWeightKg ?? 0;
    _reps = exercise.targetReps;
    _rpe = exercise.targetRpe;
    _restSeconds = exercise.targetRestSeconds;
  }

  bool _isSameExercise(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }

  bool _isTechniqueSwapForPlan({
    required String? loggedExerciseId,
    required WorkoutPlanExercise exercise,
  }) {
    return loggedExerciseId == _techniqueSwapExerciseId(exercise.exerciseId);
  }

  List<int> _completedPlanSetCounts({
    required List<WorkoutPlanExercise> plan,
    required List<LoggedSet> loggedSets,
  }) {
    final counts = List<int>.filled(plan.length, 0);
    for (final set in loggedSets) {
      final exerciseId = set.exerciseId?.trim();
      var planIndex = -1;
      if (exerciseId != null && exerciseId.isNotEmpty) {
        planIndex = plan.indexWhere(
          (exercise) =>
              exercise.exerciseId == exerciseId ||
              _isTechniqueSwapForPlan(
                loggedExerciseId: exerciseId,
                exercise: exercise,
              ),
        );
      } else {
        for (var index = 0; index < plan.length; index += 1) {
          final exercise = plan[index];
          if (_isSameExercise(set.exerciseName, exercise.exerciseName) &&
              counts[index] < exercise.targetSets) {
            planIndex = index;
            break;
          }
        }
      }
      if (planIndex >= 0) {
        counts[planIndex] += 1;
      }
    }
    return counts;
  }

  bool _isLoggedPlanExercise({
    required String loggedExerciseName,
    required String? loggedExerciseId,
    required WorkoutPlanExercise exercise,
  }) {
    if (loggedExerciseId != null && loggedExerciseId.isNotEmpty) {
      return loggedExerciseId == exercise.exerciseId ||
          _isTechniqueSwapForPlan(
            loggedExerciseId: loggedExerciseId,
            exercise: exercise,
          );
    }
    return _isSameExercise(loggedExerciseName, exercise.exerciseName);
  }

  void _advancePlanIfComplete({
    required String loggedExerciseName,
    required String? loggedExerciseId,
  }) {
    final currentPlanExercise = _currentPlanExercise;
    if (currentPlanExercise == null) {
      setState(() => _restSeconds = _defaultRestSeconds);
      return;
    }
    final session = ref.read(sessionControllerProvider).state.activeSession;
    final completedByIndex = session == null
        ? List<int>.filled(_sessionPlan.length, 0)
        : _completedPlanSetCounts(
            plan: _sessionPlan,
            loggedSets: session.loggedSets,
          );
    final completedForExercise = completedByIndex[_planIndex];
    final shouldAdvance =
        _isLoggedPlanExercise(
          loggedExerciseName: loggedExerciseName,
          loggedExerciseId: loggedExerciseId,
          exercise: currentPlanExercise,
        ) &&
        completedForExercise >= currentPlanExercise.targetSets &&
        _planIndex < _sessionPlan.length - 1;

    setState(() {
      if (shouldAdvance) {
        _planIndex += 1;
        _applyPlanExercise(_sessionPlan[_planIndex]);
        _applyReadinessCaps(
          ref.read(sessionControllerProvider).state.readinessEntry,
          resetWeightCeiling: true,
        );
      } else {
        _restSeconds = _defaultRestSeconds;
      }
    });
  }

  int? _actualRestSecondsBeforeSet(WorkoutSession active, DateTime now) {
    if (active.loggedSets.isEmpty) return null;
    final prescribedRestSeconds = active.loggedSets.last.prescribedRestSeconds;
    if (_restCountdownActive && prescribedRestSeconds != null) {
      return (prescribedRestSeconds - _restCountdownRemainingSeconds)
          .clamp(0, 7200)
          .toInt();
    }
    final previousLoggedAt = active.loggedSets.last.loggedAt;
    if (previousLoggedAt == null) return null;
    return now.difference(previousLoggedAt).inSeconds.clamp(0, 7200).toInt();
  }

  void _logSet() {
    final controller = ref.read(sessionControllerProvider);
    final active = controller.state.activeSession;
    final exerciseName = _exerciseController.text.trim();
    if (active == null || exerciseName.isEmpty) return;
    final setNumber = active.loggedSets.length + 1;
    final currentPlanExercise = _currentPlanExercise;
    final restCountdownSeconds = _restSeconds;
    final loggedAt = DateTime.now();
    final actualRestSeconds = _actualRestSecondsBeforeSet(active, loggedAt);
    final exerciseId =
        currentPlanExercise != null &&
            _isSameExercise(exerciseName, currentPlanExercise.exerciseName)
        ? currentPlanExercise.exerciseId
        : currentPlanExercise != null &&
              _activeTechniqueSwapPlanId == currentPlanExercise.exerciseId &&
              _activeTechniqueSwapName != null &&
              _isSameExercise(exerciseName, _activeTechniqueSwapName!)
        ? _techniqueSwapExerciseId(currentPlanExercise.exerciseId)
        : null;

    controller.logSet(
      exerciseName: exerciseName,
      setNumber: setNumber,
      exerciseId: exerciseId,
      loggedAt: loggedAt,
      weightKg: _weightKg == 0 ? null : _weightKg.toDouble(),
      reps: _reps,
      rpe: _rpe,
      prescribedRestSeconds: restCountdownSeconds,
      actualRestSeconds: actualRestSeconds,
    );
    _advancePlanIfComplete(
      loggedExerciseName: exerciseName,
      loggedExerciseId: exerciseId,
    );
    final nextExercise = _currentPlanExercise?.exerciseName;
    final nextCue =
        nextExercise == null || _isSameExercise(nextExercise, exerciseName)
        ? ''
        : ' Next: $nextExercise.';
    _startRestCountdown(
      restCountdownSeconds,
      statusPrefix: 'Set $setNumber logged for $exerciseName.$nextCue',
    );
    HapticFeedback.selectionClick();
  }

  void _undoLastSet() {
    final controller = ref.read(sessionControllerProvider);
    final active = controller.state.activeSession;
    if (active == null || active.loggedSets.isEmpty) return;
    final removedSet = active.loggedSets.last;

    _cancelRestCountdown();
    controller.removeLastSet();
    final session = controller.state.activeSession;
    if (_sessionPlan.isNotEmpty && session != null) {
      setState(() {
        _planIndex = _resolvedPlanIndex(
          plan: _sessionPlan,
          loggedSets: session.loggedSets,
          requestedIndex: _planIndex,
        );
        _applyPlanExercise(_sessionPlan[_planIndex]);
        _applyReadinessCaps(
          ref.read(sessionControllerProvider).state.readinessEntry,
          resetWeightCeiling: true,
        );
      });
    }
    final remainingSets = session?.loggedSets.length ?? 0;
    final setWord = remainingSets == 1 ? 'set' : 'sets';
    final verb = remainingSets == 1 ? 'remains' : 'remain';
    _publishLiveStatus(
      'Last set undone for ${removedSet.exerciseName}. '
      '$remainingSets $setWord $verb.',
    );
    HapticFeedback.selectionClick();
  }

  Future<void> _finishSession() async {
    final controller = ref.read(sessionControllerProvider);
    final active = controller.state.activeSession;
    if (active == null || active.loggedSets.isEmpty) return;

    final result = await showModalBottomSheet<_DebriefResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DigitalAtelierTokens.background,
      builder: (context) => const _DebriefSheet(),
    );
    if (result == null) return;

    _cancelRestCountdown();
    controller.endSession(notes: 'Live workout completed.');
    controller.submitDebrief(
      perceivedExertion: result.rpe,
      satisfaction: result.satisfaction,
      painNotes: result.painNotes,
      nextSessionFocus: result.nextFocus,
    );
    _publishLiveStatus('Workout finished. Debrief saved.', persist: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionStateProvider);
    final active = state.activeSession;

    if (active == null) {
      return _ClosedWorkoutSurface(hasDebrief: state.lastDebrief != null);
    }

    final previousReference = previousSetReferenceForExercise(
      state.history,
      exerciseName: _exerciseController.text,
      exerciseId: _currentPlanExercise?.exerciseId,
    );
    final previous = previousReference?.set;
    final setIntelligence = buildSetIntelligence(
      previousReference: previousReference,
      readiness: state.readinessEntry,
      currentWeightKg: _weightKg,
      currentReps: _reps,
      currentRpe: _rpe,
      selectedRestSeconds: _restSeconds,
      prescribedRestSeconds: _defaultRestSeconds,
      painSafetyActive: _painSafetyActive,
    );
    final theme = Theme.of(context);
    final canLog = _exerciseController.text.trim().isNotEmpty;
    final completedByIndex = _completedPlanSetCounts(
      plan: _sessionPlan,
      loggedSets: active.loggedSets,
    );
    final totalPlannedSets = _sessionPlan.fold<int>(
      0,
      (sum, exercise) => sum + exercise.targetSets,
    );
    final completedPlannedSets = _completedPlannedSetCount(
      plan: _sessionPlan,
      completedByIndex: completedByIndex,
      fallbackCompletedSets: active.completedSets,
    );
    final coachSignal = buildCoachSignal(state);
    final readinessCapActive = _readinessCapActive(state.readinessEntry);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(3000),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _WorkoutTopBar(
                  elapsedLabel: _elapsedLabel(active.startedAt),
                  restLabel: _restLabel(
                    _restCountdownActive
                        ? _restCountdownRemainingSeconds
                        : _restSeconds,
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ExerciseHeaderDelegate(
                minExtent: 194,
                maxExtent: 220,
                child: _ExerciseHeader(
                  exerciseController: _exerciseController,
                  previousReference: previousReference,
                  onChanged: _handleExerciseChanged,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              sliver: SliverList.list(
                children: [
                  if (_liveStatus != null) ...[
                    _LiveStatusBanner(message: _liveStatus!),
                    const SizedBox(height: 18),
                  ],
                  _QuickActionRail(
                    hasPrevious: previous != null,
                    canSkip:
                        _sessionPlan.length > 1 &&
                        _planIndex < _sessionPlan.length - 1,
                    onWarmup: _applyWarmupSet,
                    onApplyPrevious: _applyPreviousSet,
                    onApplyPlanTarget: _currentPlanExercise == null
                        ? null
                        : _applyPlanTarget,
                    onTechniqueSwap: _applyTechniqueSwap,
                    onPainSafety: _activatePainSafety,
                    onSkip: _skipToNextExercise,
                  ),
                  const SizedBox(height: 18),
                  _WorkoutCockpit(
                    session: active,
                    readiness: state.readinessEntry,
                    currentExercise: _currentPlanExercise,
                    coachSignal: coachSignal,
                    planIndex: _planIndex,
                    planCount: _sessionPlan.length,
                    completedPlannedSets: completedPlannedSets,
                    totalPlannedSets: totalPlannedSets,
                    targetCue: _targetFromPrevious(previous, _weightKg, _reps),
                    weightKg: _weightKg,
                    reps: _reps,
                    rpe: _rpe,
                    restSeconds: _restSeconds,
                    techniqueCue: _activeTechniqueCue,
                    painSafetyActive: _painSafetyActive,
                    readinessCapActive: readinessCapActive,
                  ),
                  const SizedBox(height: 18),
                  _SetIntelligencePanel(intelligence: setIntelligence),
                  const SizedBox(height: 18),
                  _PrescriptionSection(
                    planExercise: _currentPlanExercise,
                    planIndex: _planIndex,
                    planCount: _sessionPlan.length,
                    previous: previous,
                    weightKg: _weightKg,
                    reps: _reps,
                    rpe: _rpe,
                    onWeightChanged: _changeWeight,
                    onRepsChanged: _changeReps,
                    onRpeChanged: _changeRpe,
                  ),
                  const SizedBox(height: 18),
                  _SetLedgerSection(
                    session: active,
                    currentExercise: _exerciseController.text.trim(),
                    currentWeightKg: _weightKg,
                    currentReps: _reps,
                    currentRpe: _rpe,
                    previous: previous,
                  ),
                  const SizedBox(height: 18),
                  _RestControl(
                    restSeconds: _restSeconds,
                    onChanged: _changeRest,
                  ),
                  const SizedBox(height: 132),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BottomSetSummary(
                exerciseName: _exerciseController.text.trim(),
                weightKg: _weightKg,
                reps: _reps,
                rpe: _rpe,
                loggedSets: active.loggedSets.length,
                restLabel: _restLabel(
                  _restCountdownActive
                      ? _restCountdownRemainingSeconds
                      : _restSeconds,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      enabled: canLog,
                      label: 'Log set',
                      excludeSemantics: true,
                      child: ElevatedButton.icon(
                        onPressed: canLog ? _logSet : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Log set'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Semantics(
                    button: true,
                    enabled: active.loggedSets.isNotEmpty,
                    label: 'Undo last set',
                    excludeSemantics: true,
                    child: IconButton.outlined(
                      tooltip: 'Undo last set',
                      onPressed: active.loggedSets.isEmpty
                          ? null
                          : _undoLastSet,
                      icon: const Icon(Icons.undo),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Semantics(
                    button: true,
                    enabled: active.loggedSets.isNotEmpty,
                    label: 'Finish workout',
                    excludeSemantics: true,
                    child: IconButton.filled(
                      tooltip: 'Finish workout',
                      onPressed: active.loggedSets.isEmpty
                          ? null
                          : _finishSession,
                      icon: const Icon(Icons.flag_outlined),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSetSummary extends StatelessWidget {
  const _BottomSetSummary({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.rpe,
    required this.loggedSets,
    required this.restLabel,
  });

  final String exerciseName;
  final int weightKg;
  final int reps;
  final int rpe;
  final int loggedSets;
  final String restLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightLabel = weightKg == 0 ? 'bodyweight' : '$weightKg kg';
    final summary =
        'Ready: ${exerciseName.isEmpty ? 'choose exercise' : exerciseName} · '
        '$weightLabel x $reps · RPE $rpe';
    final setLabel = loggedSets == 1 ? '1 set' : '$loggedSets sets';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$summary. $setLabel logged. Rest $restLabel.',
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '$setLabel · $restLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutTopBar extends StatelessWidget {
  const _WorkoutTopBar({required this.elapsedLabel, required this.restLabel});

  final String elapsedLabel;
  final String restLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Live workout timer strip',
          child: compact
              ? Row(
                  children: [
                    const TransformFitBrandMark(
                      width: 72,
                      semanticsLabel: 'TransformFitAI logo',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _TimerPill(
                              icon: Icons.timer_outlined,
                              label: 'Workout',
                              value: elapsedLabel,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _TimerPill(
                              icon: Icons.hourglass_bottom,
                              label: 'Rest',
                              value: restLabel,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const TransformFitBrandMark(
                      width: 124,
                      semanticsLabel: 'TransformFitAI logo',
                    ),
                    const Spacer(),
                    _TimerPill(
                      icon: Icons.timer_outlined,
                      label: 'Workout',
                      value: elapsedLabel,
                    ),
                    const SizedBox(width: 8),
                    _TimerPill(
                      icon: Icons.hourglass_bottom,
                      label: 'Rest',
                      value: restLabel,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleLabel = compact && label == 'Workout' ? 'Work' : label;

    return Semantics(
      label: '$label timer, ${_timerSemanticValue(value)}',
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minWidth: compact ? 70 : 86),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            ),
            borderRadius: BorderRadius.circular(
              DigitalAtelierTokens.cornerRadius,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              SizedBox(width: compact ? 4 : 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visibleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.62,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveStatusBanner extends StatelessWidget {
  const _LiveStatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      key: const ValueKey('active_workout_live_status'),
      liveRegion: true,
      container: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            border: Border.all(color: theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(
              DigitalAtelierTokens.cornerRadius,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutCockpit extends StatelessWidget {
  const _WorkoutCockpit({
    required this.session,
    required this.readiness,
    required this.currentExercise,
    required this.coachSignal,
    required this.planIndex,
    required this.planCount,
    required this.completedPlannedSets,
    required this.totalPlannedSets,
    required this.targetCue,
    required this.weightKg,
    required this.reps,
    required this.rpe,
    required this.restSeconds,
    required this.techniqueCue,
    required this.painSafetyActive,
    required this.readinessCapActive,
  });

  final WorkoutSession session;
  final ReadinessEntry? readiness;
  final WorkoutPlanExercise? currentExercise;
  final CoachSignal coachSignal;
  final int planIndex;
  final int planCount;
  final int completedPlannedSets;
  final int totalPlannedSets;
  final String targetCue;
  final int weightKg;
  final int reps;
  final int rpe;
  final int restSeconds;
  final String? techniqueCue;
  final bool painSafetyActive;
  final bool readinessCapActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPlan = totalPlannedSets > 0;
    final progress = hasPlan
        ? (completedPlannedSets / totalPlannedSets).clamp(0.0, 1.0)
        : (session.completedSets > 0 ? 0.18 : 0.04);
    final currentName = currentExercise?.exerciseName ?? 'Free log';
    final currentTarget = targetCue;
    final planLabel = planCount == 0
        ? 'Open session'
        : 'Plan exercise ${planIndex + 1} of $planCount';
    final plannedSetLabel = currentExercise == null
        ? 'Free sets'
        : _plannedSetLabel(currentExercise!.targetSets);
    final setLabel = hasPlan
        ? '$completedPlannedSets / $totalPlannedSets sets'
        : '${session.completedSets} logged';
    final readinessLabel = readiness == null
        ? 'No check-in'
        : '${readiness!.score} ${readiness!.zone}';

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label:
          'Workout command center. $currentName. $setLabel complete. '
          'Readiness $readinessLabel. ${coachSignal.semanticLabel}',
      child: _LiveSection(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout command center',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFamily: DigitalAtelierTokens.dataFontFamily,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currentTarget,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _SmallMetric(label: 'Sets', value: setLabel),
              ],
            ),
            const SizedBox(height: 14),
            _WorkoutCoachCue(signal: coachSignal),
            const SizedBox(height: 14),
            Semantics(
              label: hasPlan
                  ? 'Workout progress, $completedPlannedSets of $totalPlannedSets planned sets complete'
                  : 'Workout progress, ${session.completedSets} sets logged',
              child: ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    DigitalAtelierTokens.cornerRadius,
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF252525),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CockpitChip(icon: Icons.route_outlined, label: planLabel),
                _CockpitChip(
                  icon: Icons.format_list_numbered,
                  label: plannedSetLabel,
                ),
                _CockpitChip(icon: Icons.bolt_outlined, label: readinessLabel),
                _CockpitChip(
                  icon: Icons.scale_outlined,
                  label: weightKg == 0 ? '0 kg' : '$weightKg kg',
                ),
                _CockpitChip(icon: Icons.repeat, label: '$reps reps'),
                _CockpitChip(icon: Icons.speed_outlined, label: '$rpe/10'),
                _CockpitChip(
                  icon: Icons.hourglass_bottom,
                  label: _restLabel(restSeconds),
                ),
                if (techniqueCue != null)
                  const _CockpitChip(
                    icon: Icons.tune_outlined,
                    label: 'Technique swap',
                  ),
                if (painSafetyActive)
                  const _CockpitChip(
                    icon: Icons.health_and_safety_outlined,
                    label: 'Pain safety',
                  ),
                if (readinessCapActive)
                  const _CockpitChip(
                    icon: Icons.shield_outlined,
                    label: 'Readiness cap',
                  ),
                _CockpitChip(
                  icon: Icons.history,
                  label: _elapsedLabel(session.startedAt),
                ),
              ],
            ),
            if (techniqueCue != null) ...[
              const SizedBox(height: 10),
              Text(
                techniqueCue!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (readinessCapActive) ...[
              const SizedBox(height: 10),
              Text(
                'Readiness cap active: load/RPE and planned sets are reduced for this session. Return to normal after recovery.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkoutCoachCue extends StatelessWidget {
  const _WorkoutCoachCue({required this.signal});

  final CoachSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: signal.semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.psychology_alt_outlined,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.personaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signal.coachNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${signal.observationLabel}: ${signal.observation}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.74,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            signal.nextAction,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CockpitChip extends StatelessWidget {
  const _CockpitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 34, maxWidth: 216),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(
            DigitalAtelierTokens.cornerRadius,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ExerciseHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: DigitalAtelierTokens.background,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_ExerciseHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        child != oldDelegate.child;
  }
}

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({
    required this.exerciseController,
    required this.previousReference,
    required this.onChanged,
  });

  final TextEditingController exerciseController;
  final PreviousSetReference? previousReference;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _LiveSection(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: 'Live workout',
            excludeSemantics: true,
            child: Text('Live workout', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('active_workout_exercise_field'),
            controller: exerciseController,
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Exercise',
              prefixIcon: Icon(Icons.fitness_center),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Previous: ${previousSetReferenceLabel(previousReference)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetIntelligencePanel extends StatelessWidget {
  const _SetIntelligencePanel({required this.intelligence});

  final SetIntelligence intelligence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: intelligence.semanticLabel,
      child: ExcludeSemantics(
        child: _LiveSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Set intelligence',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  _SetIntentBadge(value: intelligence.progressionIntent),
                ],
              ),
              const SizedBox(height: 12),
              _IntelligenceRow(
                icon: Icons.trending_up,
                label: 'Progression intent',
                value: intelligence.progressionIntent,
              ),
              _IntelligenceRow(
                icon: Icons.hourglass_bottom,
                label: 'Rest pace',
                value: intelligence.restPace,
              ),
              _IntelligenceRow(
                icon: Icons.history,
                label: 'Previous reference',
                value: intelligence.previousReference,
              ),
              _IntelligenceRow(
                icon: Icons.bolt_outlined,
                label: 'Readiness context',
                value: intelligence.readinessContext,
              ),
              _IntelligenceRow(
                icon: Icons.timer_outlined,
                label: 'Post-set countdown',
                value: intelligence.postSetCountdown,
              ),
              const SizedBox(height: 10),
              Text(
                intelligence.progressionReason,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                intelligence.restDetail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetIntentBadge extends StatelessWidget {
  const _SetIntentBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 138,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Column(
        children: [
          Text(
            'Intent',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntelligenceRow extends StatelessWidget {
  const _IntelligenceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionRail extends StatelessWidget {
  const _QuickActionRail({
    required this.hasPrevious,
    required this.canSkip,
    required this.onWarmup,
    required this.onApplyPrevious,
    required this.onApplyPlanTarget,
    required this.onTechniqueSwap,
    required this.onPainSafety,
    required this.onSkip,
  });

  final bool hasPrevious;
  final bool canSkip;
  final VoidCallback onWarmup;
  final VoidCallback onApplyPrevious;
  final VoidCallback? onApplyPlanTarget;
  final VoidCallback onTechniqueSwap;
  final VoidCallback onPainSafety;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 720
            ? 6
            : constraints.maxWidth >= 620
            ? 5
            : constraints.maxWidth >= 360
            ? 3
            : 2;
        final itemWidth =
            (constraints.maxWidth - (8 * (columnCount - 1))) / columnCount;

        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Workout quick actions',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickActionButton(
                width: itemWidth,
                icon: Icons.local_fire_department_outlined,
                label: 'Warm-up',
                tooltip: 'Load warm-up set',
                onPressed: onWarmup,
                theme: theme,
              ),
              _QuickActionButton(
                width: itemWidth,
                icon: Icons.history,
                label: 'Previous',
                tooltip: 'Apply previous set',
                onPressed: hasPrevious ? onApplyPrevious : null,
                theme: theme,
              ),
              _QuickActionButton(
                width: itemWidth,
                icon: Icons.track_changes,
                label: 'Plan target',
                tooltip: 'Restore plan target',
                onPressed: onApplyPlanTarget,
                theme: theme,
              ),
              _QuickActionButton(
                width: itemWidth,
                icon: Icons.tune_outlined,
                label: 'Technique',
                tooltip: 'Load technique swap',
                onPressed: onTechniqueSwap,
                theme: theme,
              ),
              _QuickActionButton(
                width: itemWidth,
                icon: Icons.health_and_safety_outlined,
                label: 'Pain safety',
                tooltip: 'Activate pain safety',
                onPressed: onPainSafety,
                theme: theme,
              ),
              _QuickActionButton(
                width: itemWidth,
                icon: Icons.skip_next_outlined,
                label: 'Skip',
                tooltip: 'Skip to next exercise',
                onPressed: canSkip ? onSkip : null,
                theme: theme,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    required this.theme,
  });

  final double width;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            disabledForegroundColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.38,
            ),
            side: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
            ),
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionSection extends StatelessWidget {
  const _PrescriptionSection({
    required this.planExercise,
    required this.planIndex,
    required this.planCount,
    required this.previous,
    required this.weightKg,
    required this.reps,
    required this.rpe,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRpeChanged,
  });

  final WorkoutPlanExercise? planExercise;
  final int planIndex;
  final int planCount;
  final LoggedSet? previous;
  final int weightKg;
  final int reps;
  final int rpe;
  final ValueChanged<int> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<int> onRpeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = _targetFromPrevious(previous, weightKg, reps);

    return _LiveSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (planExercise != null) ...[
            Semantics(
              container: true,
              label:
                  'Plan exercise ${planIndex + 1} of $planCount, '
                  '${planExercise!.exerciseName}, '
                  '${_plannedSetLabel(planExercise!.targetSets)}.',
              child: Row(
                children: [
                  Icon(
                    Icons.route_outlined,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Plan exercise ${planIndex + 1} of $planCount',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _plannedSetLabel(planExercise!.targetSets),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current prescription',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(target, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SmallMetric(label: 'RPE', value: '$rpe/10'),
            ],
          ),
          const SizedBox(height: 14),
          _LiveStepper(
            label: 'Weight',
            semanticLabel: 'Working weight',
            value: weightKg,
            valueLabel: '$weightKg kg',
            minValue: 0,
            maxValue: 320,
            step: 5,
            decreaseTooltip: 'Decrease weight',
            increaseTooltip: 'Increase weight',
            onChanged: onWeightChanged,
          ),
          const SizedBox(height: 10),
          _LiveStepper(
            label: 'Reps',
            semanticLabel: 'Working reps',
            value: reps,
            valueLabel: '$reps reps',
            maxValue: 60,
            decreaseTooltip: 'Decrease reps',
            increaseTooltip: 'Increase reps',
            onChanged: onRepsChanged,
          ),
          const SizedBox(height: 10),
          _LiveStepper(
            label: 'RPE',
            semanticLabel: 'Working RPE',
            value: rpe,
            valueLabel: '$rpe/10',
            decreaseTooltip: 'Decrease RPE',
            increaseTooltip: 'Increase RPE',
            onChanged: onRpeChanged,
          ),
        ],
      ),
    );
  }
}

class _SetLedgerSection extends StatelessWidget {
  const _SetLedgerSection({
    required this.session,
    required this.currentExercise,
    required this.currentWeightKg,
    required this.currentReps,
    required this.currentRpe,
    required this.previous,
  });

  final WorkoutSession session;
  final String currentExercise;
  final int currentWeightKg;
  final int currentReps;
  final int currentRpe;
  final LoggedSet? previous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = session.loggedSets;

    return _LiveSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Set log', style: theme.textTheme.titleMedium),
              ),
              Text(
                '${session.completedSets} done',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LedgerHeader(theme: theme),
          for (var index = 0; index < rows.length; index += 1)
            _LedgerRow(
              set: rows[index],
              previousSet: index == 0 ? null : rows[index - 1],
            ),
          _CurrentLedgerRow(
            setNumber: rows.length + 1,
            exercise: currentExercise.isEmpty ? 'Exercise' : currentExercise,
            previous: previous,
            weightKg: currentWeightKg,
            reps: currentReps,
            rpe: currentRpe,
          ),
        ],
      ),
    );
  }
}

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          _LedgerCell('Set', width: 44, theme: theme),
          _LedgerCell('Previous', flex: 2, theme: theme),
          _LedgerCell('Kg', theme: theme),
          _LedgerCell('Reps', theme: theme),
          _LedgerCell('RPE', theme: theme),
          _LedgerCell('', width: 32, theme: theme),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.set, required this.previousSet});

  final LoggedSet set;
  final LoggedSet? previousSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restPace = _restPaceLabel(set: set, previousSet: previousSet);

    return Semantics(
      label:
          'Completed set ${set.setNumber}: ${_setSummary(set)}'
          '${restPace == null ? '' : '. ${_restPaceSemanticLabel(restPace)}'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            _LedgerCell('#${set.setNumber}', width: 44, theme: theme),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.exerciseName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (restPace != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      restPace,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.66,
                        ),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _LedgerCell(_numberOrDash(set.weightKg), theme: theme),
            _LedgerCell(set.reps?.toString() ?? '--', theme: theme),
            _LedgerCell(set.rpe?.toString() ?? '--', theme: theme),
            SizedBox(
              width: 32,
              child: Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLedgerRow extends StatelessWidget {
  const _CurrentLedgerRow({
    required this.setNumber,
    required this.exercise,
    required this.previous,
    required this.weightKg,
    required this.reps,
    required this.rpe,
  });

  final int setNumber;
  final String exercise;
  final LoggedSet? previous;
  final int weightKg;
  final int reps;
  final int rpe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          'Current set $setNumber: $exercise, $weightKg kilograms, $reps reps, RPE $rpe',
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: Row(
          children: [
            _LedgerCell('#$setNumber', width: 44, theme: theme),
            _LedgerCell(
              previous == null ? 'No previous' : _setSummary(previous!),
              flex: 2,
              theme: theme,
            ),
            _LedgerCell(weightKg == 0 ? '--' : '$weightKg', theme: theme),
            _LedgerCell('$reps', theme: theme),
            _LedgerCell('$rpe', theme: theme),
            SizedBox(
              width: 32,
              child: Icon(
                Icons.radio_button_unchecked,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerCell extends StatelessWidget {
  const _LedgerCell(
    this.text, {
    required this.theme,
    this.flex = 1,
    this.width,
  });

  final String text;
  final int flex;
  final double? width;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
    );
    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex, child: child);
  }
}

class _RestControl extends StatelessWidget {
  const _RestControl({required this.restSeconds, required this.onChanged});

  final int restSeconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _LiveSection(
      child: _LiveStepper(
        label: 'Rest timer',
        semanticLabel: 'Rest timer',
        value: restSeconds,
        valueLabel: _restLabel(restSeconds),
        minValue: 0,
        maxValue: 300,
        step: 15,
        decreaseTooltip: 'Decrease rest timer',
        increaseTooltip: 'Increase rest timer',
        onChanged: onChanged,
      ),
    );
  }
}

class _LiveStepper extends StatelessWidget {
  const _LiveStepper({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onChanged,
    this.semanticLabel,
    this.minValue = 1,
    this.maxValue = 10,
    this.step = 1,
  });

  final String label;
  final String? semanticLabel;
  final int value;
  final String valueLabel;
  final String decreaseTooltip;
  final String increaseTooltip;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int maxValue;
  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrease = value > minValue;
    final canIncrease = value < maxValue;
    final nextValue = (value + step).clamp(minValue, maxValue);
    final previousValue = (value - step).clamp(minValue, maxValue);

    return Semantics(
      container: true,
      excludeSemantics: true,
      enabled: true,
      label: semanticLabel ?? label,
      value: _semanticValue(value),
      increasedValue: canIncrease ? _semanticValue(nextValue) : null,
      decreasedValue: canDecrease ? _semanticValue(previousValue) : null,
      onIncrease: canIncrease ? () => onChanged(1) : null,
      onDecrease: canDecrease ? () => onChanged(-1) : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(
            DigitalAtelierTokens.cornerRadius,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Text(label, style: theme.textTheme.bodyMedium),
              ),
            ),
            IconButton(
              tooltip: decreaseTooltip,
              onPressed: canDecrease ? () => onChanged(-1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 78,
              child: ExcludeSemantics(
                child: Text(
                  valueLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: increaseTooltip,
              onPressed: canIncrease ? () => onChanged(1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  String _semanticValue(int nextValue) {
    if (valueLabel.contains(':')) return _spokenDuration(nextValue);
    if (valueLabel.endsWith('kg')) return '$nextValue kilograms';
    if (valueLabel.endsWith('reps')) return '$nextValue reps';
    if (valueLabel.contains('/')) return '$nextValue out of $maxValue';
    return nextValue.toString();
  }

  String _spokenDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds.remainder(60);
    final parts = <String>[];
    if (minutes > 0) {
      parts.add(minutes == 1 ? '1 minute' : '$minutes minutes');
    }
    if (remainingSeconds > 0 || parts.isEmpty) {
      parts.add(
        remainingSeconds == 1 ? '1 second' : '$remainingSeconds seconds',
      );
    }
    return parts.join(' ');
  }
}

class _LiveSection extends StatelessWidget {
  const _LiveSection({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: child,
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 74),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebriefSheet extends StatefulWidget {
  const _DebriefSheet();

  @override
  State<_DebriefSheet> createState() => _DebriefSheetState();
}

class _DebriefSheetState extends State<_DebriefSheet> {
  final TextEditingController _painController = TextEditingController(
    text: 'No sharp pain.',
  );
  final TextEditingController _focusController = TextEditingController(
    text: 'Repeat clean reps before adding load.',
  );
  int _rpe = 7;
  int _satisfaction = 4;

  @override
  void dispose() {
    _painController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: 'Debrief',
            excludeSemantics: true,
            child: Text('Debrief', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 14),
          _LiveStepper(
            label: 'Exertion',
            semanticLabel: 'Debrief exertion',
            value: _rpe,
            valueLabel: '$_rpe/10',
            decreaseTooltip: 'Decrease exertion',
            increaseTooltip: 'Increase exertion',
            onChanged: (delta) {
              setState(() => _rpe = (_rpe + delta).clamp(1, 10));
            },
          ),
          const SizedBox(height: 10),
          _LiveStepper(
            label: 'Satisfaction',
            semanticLabel: 'Debrief satisfaction',
            value: _satisfaction,
            valueLabel: '$_satisfaction/5',
            maxValue: 5,
            decreaseTooltip: 'Decrease satisfaction',
            increaseTooltip: 'Increase satisfaction',
            onChanged: (delta) {
              setState(() {
                _satisfaction = (_satisfaction + delta).clamp(1, 5);
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('active_workout_pain_field'),
            controller: _painController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Pain check'),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('active_workout_next_focus_field'),
            controller: _focusController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Next focus'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(
                  _DebriefResult(
                    rpe: _rpe,
                    satisfaction: _satisfaction,
                    painNotes: _trimmedOrNull(_painController.text),
                    nextFocus:
                        _trimmedOrNull(_focusController.text) ??
                        'Repeat clean reps before adding load.',
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Save debrief'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebriefResult {
  const _DebriefResult({
    required this.rpe,
    required this.satisfaction,
    required this.nextFocus,
    this.painNotes,
  });

  final int rpe;
  final int satisfaction;
  final String nextFocus;
  final String? painNotes;
}

class _ClosedWorkoutSurface extends StatelessWidget {
  const _ClosedWorkoutSurface({required this.hasDebrief});

  final bool hasDebrief;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = hasDebrief ? 'Session saved' : 'No live session';
    final body = hasDebrief
        ? 'Today is logged. The next plan can adapt from this proof.'
        : 'Start a session from Today when you are ready.';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TransformFitBrandMark(
                width: 160,
                semanticsLabel: 'TransformFitAI logo',
              ),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 10),
              Text(body, style: theme.textTheme.bodyLarge),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.today_outlined),
                  label: const Text('Today'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _targetFromPrevious(LoggedSet? previous, int fallbackWeight, int reps) {
  if (previous == null || previous.weightKg == null || previous.reps == null) {
    return '$fallbackWeight kg x $reps reps. Keep two reps in reserve.';
  }
  final canAddRep = previous.rpe == null || previous.rpe! <= 7;
  final nextReps = canAddRep ? previous.reps! + 1 : previous.reps!;
  final cue = canAddRep
      ? 'Add one rep before load.'
      : 'Repeat clean before load.';
  return '${_numberOrDash(previous.weightKg)} kg x $nextReps reps. $cue';
}

String _plannedSetLabel(int sets) {
  return sets == 1 ? '1 planned set' : '$sets planned sets';
}

bool _readinessCapActive(ReadinessEntry? readiness) {
  if (readiness == null) return false;
  final zone = readiness.zone.trim().toLowerCase();
  return readiness.score < 45 ||
      zone.contains('deload') ||
      zone.contains('recover') ||
      zone.contains('rest');
}

int _readinessCappedWeightKg(int weightKg) {
  if (weightKg <= 0) return 0;
  return (((weightKg * 0.8) / 5).floor() * 5).clamp(0, weightKg).toInt();
}

int _readinessCappedTargetSets(int targetSets) {
  if (targetSets <= 1) return 1;
  if (targetSets <= 3) return targetSets - 1;
  return (targetSets * 0.75).floor().clamp(1, targetSets - 1).toInt();
}

int _readinessCappedRestSeconds(int restSeconds) {
  return (restSeconds + 30).clamp(60, 300).toInt();
}

String _readinessCapStatus(ReadinessEntry readiness) {
  return 'Readiness cap active (${readiness.score} ${readiness.zone}). '
      'Load/RPE and planned sets reduced for today; return to normal after recovery.';
}

int _completedPlannedSetCount({
  required List<WorkoutPlanExercise> plan,
  required List<int> completedByIndex,
  required int fallbackCompletedSets,
}) {
  if (plan.isEmpty || completedByIndex.length != plan.length) {
    return fallbackCompletedSets;
  }
  var count = 0;
  for (var index = 0; index < plan.length; index += 1) {
    final capped = completedByIndex[index].clamp(0, plan[index].targetSets);
    count += capped.toInt();
  }
  return count;
}

class _TechniqueSwap {
  const _TechniqueSwap({
    required this.exerciseName,
    required this.cue,
    required this.weightKg,
    required this.reps,
    required this.rpe,
    required this.restSeconds,
  });

  final String exerciseName;
  final String cue;
  final int weightKg;
  final int reps;
  final int rpe;
  final int restSeconds;
}

String _techniqueSwapExerciseId(String exerciseId) {
  return '${exerciseId.trim()}.technique_swap';
}

_TechniqueSwap _techniqueSwapForExercise({
  required String exerciseName,
  required int currentWeightKg,
  required int currentReps,
  required int currentRpe,
  required int currentRestSeconds,
  required int prescribedRestSeconds,
}) {
  final lower = exerciseName.trim().toLowerCase();
  final reps = currentReps.clamp(6, 12).toInt();
  final rpe = currentRpe.clamp(4, 6).toInt();
  final restSeconds = currentRestSeconds < prescribedRestSeconds
      ? prescribedRestSeconds
      : currentRestSeconds;

  if (lower.contains('squat')) {
    return _TechniqueSwap(
      exerciseName: 'Tempo Goblet Squat',
      cue: 'Three-second lowering, one-second pause, quiet knees.',
      weightKg: _reducedTechniqueWeight(currentWeightKg, 0.60),
      reps: reps,
      rpe: rpe,
      restSeconds: restSeconds,
    );
  }
  if (lower.contains('bench') || lower.contains('press')) {
    return _TechniqueSwap(
      exerciseName: 'Tempo Dumbbell Press',
      cue: 'Three-second lowering, elbows stacked, stop when path changes.',
      weightKg: _reducedTechniqueWeight(currentWeightKg, 0.55),
      reps: reps,
      rpe: rpe,
      restSeconds: restSeconds,
    );
  }
  if (lower.contains('deadlift') || lower.contains('hinge')) {
    return _TechniqueSwap(
      exerciseName: 'Hip Hinge Patterning',
      cue: 'Use bodyweight or a dowel; keep ribs stacked and hips moving back.',
      weightKg: 0,
      reps: reps,
      rpe: 4,
      restSeconds: restSeconds,
    );
  }
  if (lower.contains('row') || lower.contains('pull')) {
    return _TechniqueSwap(
      exerciseName: 'Chest-supported Row',
      cue: 'Brace against the bench and finish each rep without momentum.',
      weightKg: _reducedTechniqueWeight(currentWeightKg, 0.60),
      reps: reps,
      rpe: rpe,
      restSeconds: restSeconds,
    );
  }
  if (lower.contains('lunge') || lower.contains('split')) {
    return _TechniqueSwap(
      exerciseName: 'Supported Split Squat',
      cue: 'Use support, own the bottom position, and keep reps smooth.',
      weightKg: 0,
      reps: reps,
      rpe: rpe,
      restSeconds: restSeconds,
    );
  }
  return _TechniqueSwap(
    exerciseName: 'Tempo $exerciseName',
    cue: 'Slow the lowering phase and stop the set when form changes.',
    weightKg: _reducedTechniqueWeight(currentWeightKg, 0.60),
    reps: reps,
    rpe: rpe,
    restSeconds: restSeconds,
  );
}

int _reducedTechniqueWeight(int currentWeightKg, double multiplier) {
  if (currentWeightKg <= 0) return 0;
  return (((currentWeightKg * multiplier) / 5).round() * 5)
      .clamp(0, currentWeightKg)
      .toInt();
}

String _setSummary(LoggedSet set) {
  final metrics = <String>[];
  if (set.weightKg != null && set.reps != null) {
    metrics.add('${_numberOrDash(set.weightKg)} kg x ${set.reps} reps');
  } else if (set.reps != null) {
    metrics.add('${set.reps} reps');
  } else if (set.durationSeconds != null) {
    metrics.add('${(set.durationSeconds! / 60).round()} min');
  }
  if (set.rpe != null) metrics.add('RPE ${set.rpe}');
  return '${set.exerciseName}, ${metrics.join(', ')}';
}

String _elapsedLabel(DateTime startedAt) {
  final elapsed = DateTime.now().difference(startedAt);
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _restLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

String? _restPaceLabel({
  required LoggedSet set,
  required LoggedSet? previousSet,
}) {
  final actualRestSeconds = set.actualRestSeconds;
  final prescribedRestSeconds = previousSet?.prescribedRestSeconds;
  if (actualRestSeconds == null || prescribedRestSeconds == null) return null;
  return 'Rest before: ${_restLabel(actualRestSeconds)} '
      '${_restPaceStatus(actualRestSeconds, prescribedRestSeconds)} '
      'vs ${_restLabel(prescribedRestSeconds)}';
}

String _restPaceStatus(int actualRestSeconds, int prescribedRestSeconds) {
  if (actualRestSeconds < prescribedRestSeconds - 15) return 'early';
  if (actualRestSeconds > prescribedRestSeconds + 30) return 'late';
  return 'on target';
}

String _restPaceSemanticLabel(String label) {
  return label
      .replaceFirst('Rest before:', 'Rest before')
      .replaceAll(' vs ', ' versus ')
      .replaceAllMapped(
        RegExp(r'\d+:\d{2}'),
        (match) => _timerSemanticValue(match.group(0)!),
      );
}

String _timerSemanticValue(String value) {
  final parts = value.split(':').map(int.tryParse).toList();
  if (parts.any((part) => part == null)) return value;
  final totalSeconds = switch (parts.length) {
    2 => (parts[0]! * 60) + parts[1]!,
    3 => (parts[0]! * 3600) + (parts[1]! * 60) + parts[2]!,
    _ => null,
  };
  if (totalSeconds == null) return value;
  return _spokenSeconds(totalSeconds);
}

String _spokenSeconds(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = seconds.remainder(3600) ~/ 60;
  final remainingSeconds = seconds.remainder(60);
  final parts = <String>[];
  if (hours > 0) parts.add(hours == 1 ? '1 hour' : '$hours hours');
  if (minutes > 0) parts.add(minutes == 1 ? '1 minute' : '$minutes minutes');
  if (remainingSeconds > 0 || parts.isEmpty) {
    parts.add(remainingSeconds == 1 ? '1 second' : '$remainingSeconds seconds');
  }
  return parts.join(' ');
}

String _numberOrDash(double? value) {
  if (value == null) return '--';
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
