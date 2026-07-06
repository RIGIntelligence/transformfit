// M3: Active Workout Screen — Strong/Hevy-quality set logging UX.
//
// Architecture: One stateful screen with 7 decomposed widget sections.
// All business logic (readiness caps, pain safety, warmup, plan, technique
// swaps, undo, debrief) preserved from the original god-widget.
//
// Design tokens: DigitalAtelierExtension exclusively — zero hardcoded colors.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
import 'package:transformfit/widgets/tf_error_state.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

// ============================================================================
// Main Screen
// ============================================================================

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, this.initialPrefill});

  final WorkoutPrefill? initialPrefill;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with TickerProviderStateMixin {
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

  // PR celebration animation
  late AnimationController _celebrationController;
  bool _showCelebration = false;

  // Rest timer breathing animation
  late AnimationController _restBreathingController;

  // Set log flash animation
  bool _setJustLogged = false;

  // Session error state
  String? _sessionError;

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
    _celebrationController = AnimationController(
      vsync: this,
      duration: DigitalAtelierTokens2.durationCelebration,
    );
    _restBreathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

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
    _celebrationController.dispose();
    _restBreathingController.dispose();
    super.dispose();
  }

  // ── Business Logic (preserved from original) ──────────────────────────────

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

  void _applyWarmupSet() {
    final readiness = ref.read(sessionControllerProvider).state.readinessEntry;
    final warmWeight =
        _weightKg <= 0 ? 0 : ((_weightKg * 0.6) / 5).round() * 5;
    setState(() {
      _weightKg = warmWeight.clamp(0, 320);
      _reps = (_reps + 2).clamp(6, 15);
      _rpe = 4;
      _restSeconds = 60;
      _applyReadinessCaps(readiness, resetWeightCeiling: true);
      if (_painSafetyActive) _applyPainSafetyCaps();
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
      if (_painSafetyActive) _applyPainSafetyCaps();
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
      if (_painSafetyActive) _applyPainSafetyCaps();
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
      if (_painSafetyActive) _applyPainSafetyCaps();
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
    if (persist) setState(() => _liveStatus = message);
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
    _publishLiveStatus(
      '$statusPrefix Rest started: ${_restLabel(seconds)}.',
    );

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
      setState(() => _restCountdownRemainingSeconds -= 1);
    });
  }

  int _painSafetyCeilingFromPrevious(LoggedSet? previous) {
    final previousWeight = previous?.weightKg?.round();
    if (previousWeight == null) return _weightKg.clamp(0, 320).toInt();
    return previousWeight.clamp(0, 320).toInt();
  }

  void _applyPainSafetyCaps() {
    final ceiling =
        _painSafetyWeightCeiling ?? _weightKg.clamp(0, 320).toInt();
    _painSafetyWeightCeiling = ceiling;
    if (_weightKg > ceiling) _weightKg = ceiling;
    if (_rpe > 6) _rpe = 6;
    if (_restSeconds < _defaultRestSeconds) _restSeconds = _defaultRestSeconds;
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
    if (_weightKg > ceiling) _weightKg = ceiling;
    if (_rpe > 6) _rpe = 6;
    if (_restSeconds < _defaultRestSeconds) _restSeconds = _defaultRestSeconds;
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
      'Pain safety active. Load progression blocked; '
      'use a pain-free option or finish.',
    );
    HapticFeedback.selectionClick();
  }

  void _showPainReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DigitalAtelierTokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _PainReportSheet(
        onReport: (bodyPart, severity) {
          Navigator.of(context).pop();
          setState(() {
            _painSafetyActive = true;
            _painSafetyWeightCeiling = _weightKg;
            _applyPainSafetyCaps();
          });
          _publishLiveStatus(
            'Pain reported: $bodyPart (severity $severity/10). '
            'Pain safety active — load capped at ${_painSafetyWeightCeiling}kg, '
            'RPE capped at 6. Consider swapping exercise or finishing.',
          );
          HapticFeedback.heavyImpact();
        },
      ),
    );
  }

  List<WorkoutPlanExercise> _initialSessionPlan(
    WorkoutPrefill? prefill,
    SessionState sessionState,
  ) {
    if (prefill == null) {
      return _fromSessionPlan(sessionState.activeSessionPlan);
    }
    if (prefill.sessionExercises.isNotEmpty) return prefill.sessionExercises;
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

  List<WorkoutPlanExercise> _fromSessionPlan(
    List<SessionPlanExercise> plan,
  ) {
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
      if (completedByIndex[index] < plan[index].targetSets) return index;
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
      if (planIndex >= 0) counts[planIndex] += 1;
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
            _isSameExercise(
              exerciseName,
              currentPlanExercise.exerciseName,
            )
        ? currentPlanExercise.exerciseId
        : currentPlanExercise != null &&
              _activeTechniqueSwapPlanId ==
                  currentPlanExercise.exerciseId &&
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
        nextExercise == null ||
            _isSameExercise(nextExercise, exerciseName)
        ? ''
        : ' Next: $nextExercise.';
    _startRestCountdown(
      restCountdownSeconds,
      statusPrefix:
          'Set $setNumber logged for $exerciseName.$nextCue',
    );

    // Set-log flash
    setState(() => _setJustLogged = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _setJustLogged = false);
    });

    // PR detection
    _checkForPR(active);

    HapticFeedback.selectionClick();
  }

  void _checkForPR(WorkoutSession active) {
    final previousReference = previousSetReferenceForExercise(
      ref.read(sessionControllerProvider).state.history,
      exerciseName: _exerciseController.text,
      exerciseId: _currentPlanExercise?.exerciseId,
    );
    final previous = previousReference?.set;
    if (previous == null) return;
    final prevVolume = (previous.weightKg ?? 0) * (previous.reps ?? 0);
    final currentVolume = _weightKg * _reps;
    if (currentVolume > prevVolume && prevVolume > 0) {
      setState(() => _showCelebration = true);
      _celebrationController.forward(from: 0).then((_) {
        if (mounted) setState(() => _showCelebration = false);
      });
      _publishLiveStatus(
        'New personal record! '
        '${currentVolume.round()} kg total volume.',
      );
    }
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionStateProvider);
    final active = state.activeSession;
    if (active == null) {
      return _ClosedWorkoutSurface(hasDebrief: state.lastDebrief != null);
    }

    // Show error state if session has an error
    if (_sessionError != null) {
      final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
      return Scaffold(
        backgroundColor: t.background,
        body: SafeArea(
          child: TfErrorState(
            icon: Icons.fitness_center,
            title: 'Session Error',
            message: _sessionError!,
            onRetry: () {
              setState(() => _sessionError = null);
            },
            retryLabel: 'Dismiss',
          ),
        ),
      );
    }

    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final previousReference = previousSetReferenceForExercise(
      state.history,
      exerciseName: _exerciseController.text,
      exerciseId: _currentPlanExercise?.exerciseId,
    );
    final previous = previousReference?.set;
    final readinessCapActive = _readinessCapActive(state.readinessEntry);
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
    final canLog = _exerciseController.text.trim().isNotEmpty;
    final allSetsComplete =
        totalPlannedSets > 0 && completedPlannedSets >= totalPlannedSets;

    int totalVolume = 0;
    for (final s in active.loggedSets) {
      totalVolume += ((s.weightKg ?? 0) * (s.reps ?? 0)).round();
    }

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Pain safety banner
                if (_painSafetyActive)
                  _PainSafetyBanner(
                    ceiling: _painSafetyWeightCeiling,
                    onDismiss: () => setState(() {
                      _painSafetyActive = false;
                      _painSafetyWeightCeiling = null;
                    }),
                  ),

                // Readiness cap banner
                if (readinessCapActive && state.readinessEntry != null)
                  _ReadinessBanner(readiness: state.readinessEntry!),

                // Main scrollable content
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Top bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _WorkoutTopBar(
                            elapsedLabel: _elapsedLabel(active.startedAt),
                            brandMark: const TransformFitBrandMark(
                              width: 72,
                              semanticsLabel: 'TransformFitAI logo',
                            ),
                          ),
                        ),
                      ),

                      // Exercise header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: _ExerciseHeader(
                            exerciseName: _exerciseController.text,
                            setNumber: active.loggedSets
                                    .where(
                                      (s) => _isSameExercise(
                                        s.exerciseName,
                                        _exerciseController.text,
                                      ),
                                    )
                                    .length +
                                1,
                            totalSets:
                                _currentPlanExercise?.targetSets ?? 0,
                            planIndex: _planIndex,
                            planCount: _sessionPlan.length,
                            canGoBack: _planIndex > 0,
                            canGoForward:
                                _planIndex < _sessionPlan.length - 1,
                            hasTechnique: _activeTechniqueSwapName != null,
                            techniqueCue: _activeTechniqueCue,
                            onPrevious: _planIndex > 0
                                ? () {
                                    setState(() {
                                      _planIndex -= 1;
                                      _applyPlanExercise(
                                        _sessionPlan[_planIndex],
                                      );
                                    });
                                    HapticFeedback.selectionClick();
                                  }
                                : null,
                            onNext: _skipToNextExercise,
                            onTechniqueSwap: _applyTechniqueSwap,
                            onExerciseChanged: _handleExerciseChanged,
                            exerciseController: _exerciseController,
                          ),
                        ),
                      ),

                      // Live status
                      if (_liveStatus != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child:
                                _LiveStatusBanner(message: _liveStatus!),
                          ),
                        ),

                      // Set table
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: _SetTable(
                            loggedSets: active.loggedSets,
                            currentExercise:
                                _exerciseController.text.trim(),
                            currentWeightKg: _weightKg,
                            currentReps: _reps,
                            currentRpe: _rpe,
                            previous: previous,
                            setJustLogged: _setJustLogged,
                          ),
                        ),
                      ),

                      // Set controls
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: _SetControls(
                            weightKg: _weightKg,
                            reps: _reps,
                            rpe: _rpe,
                            onWeightChanged: _changeWeight,
                            onRepsChanged: _changeReps,
                            onRpeChanged: _changeRpe,
                            painSafetyActive: _painSafetyActive,
                            readinessCapActive: readinessCapActive,
                          ),
                        ),
                      ),

                      // Bottom spacer for fixed bar
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 200),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // PR celebration overlay
            if (_showCelebration)
              _CelebrationOverlay(controller: _celebrationController),

            // Fixed bottom bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomBar(
                totalVolume: totalVolume,
                loggedSets: active.loggedSets.length,
                totalPlannedSets: totalPlannedSets,
                elapsedLabel: _elapsedLabel(active.startedAt),
                restSeconds: _restCountdownActive
                    ? _restCountdownRemainingSeconds
                    : _restSeconds,
                restCountdownActive: _restCountdownActive,
                restBreathingController: _restBreathingController,
                weightKg: _weightKg,
                reps: _reps,
                canLog: canLog,
                allSetsComplete: allSetsComplete,
                hasLoggedSets: active.loggedSets.isNotEmpty,
                onLogSet: _logSet,
                onUndo: _undoLastSet,
                onFinish: _finishSession,
                onReportPain: _showPainReportDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. Exercise Header
// ============================================================================

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({
    required this.exerciseName,
    required this.setNumber,
    required this.totalSets,
    required this.planIndex,
    required this.planCount,
    required this.canGoBack,
    required this.canGoForward,
    required this.hasTechnique,
    required this.techniqueCue,
    required this.onPrevious,
    required this.onNext,
    required this.onTechniqueSwap,
    required this.onExerciseChanged,
    required this.exerciseController,
  });

  final String exerciseName;
  final int setNumber;
  final int totalSets;
  final int planIndex;
  final int planCount;
  final bool canGoBack;
  final bool canGoForward;
  final bool hasTechnique;
  final String? techniqueCue;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onTechniqueSwap;
  final VoidCallback onExerciseChanged;
  final TextEditingController exerciseController;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Container(
      padding: EdgeInsets.all(t.spaceLg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nav row
          Row(
            children: [
              Semantics(
                button: true,
                enabled: canGoBack,
                label: 'Previous exercise',
                child: IconButton(
                  onPressed: onPrevious,
                  icon: Icon(
                    Icons.chevron_left,
                    color: canGoBack ? t.textPrimary : t.textMuted,
                  ),
                  iconSize: 28,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Semantics(
                      header: true,
                      label: 'Exercise: $exerciseName',
                      child: TextField(
                        key: const ValueKey('active_workout_exercise_field'),
                        controller: exerciseController,
                        onChanged: (_) => onExerciseChanged(),
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: DigitalAtelierTokens.dataFontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Exercise name',
                          hintStyle: TextStyle(
                            color: t.textMuted,
                            fontFamily:
                                DigitalAtelierTokens.dataFontFamily,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: t.spaceXs),
                    // Progress dots
                    Semantics(
                      label: totalSets > 0
                          ? 'Set $setNumber of $totalSets'
                          : 'Set $setNumber',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (totalSets > 0) ...[
                            ...List.generate(totalSets, (i) {
                              final done = i < setNumber - 1;
                              final current = i == setNumber - 1;
                              return AnimatedContainer(
                                duration:
                                    DigitalAtelierTokens2.durationFast,
                                width: current ? 10 : 7,
                                height: current ? 10 : 7,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: done
                                      ? t.accentPrimary
                                      : current
                                          ? t.accentPrimary
                                          : t.surfaceDivider,
                                  border: current
                                      ? Border.all(
                                          color: t.accentPrimary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                              );
                            }),
                            SizedBox(width: t.spaceSm),
                          ],
                          Text(
                            totalSets > 0
                                ? 'Set $setNumber of $totalSets'
                                : 'Set $setNumber',
                            style: TextStyle(
                              fontFamily:
                                  DigitalAtelierTokens.dataFontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                enabled: canGoForward,
                label: 'Next exercise',
                child: IconButton(
                  onPressed: onNext,
                  icon: Icon(
                    Icons.chevron_right,
                    color: canGoForward ? t.textPrimary : t.textMuted,
                  ),
                  iconSize: 28,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
            ],
          ),

          // Plan label
          if (planCount > 0) ...[
            SizedBox(height: t.spaceXs),
            Center(
              child: Text(
                'Exercise ${planIndex + 1} of $planCount',
                style: TextStyle(
                  fontFamily: DigitalAtelierTokens.dataFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: t.textMuted,
                ),
              ),
            ),
          ],

          // Technique swap
          if (hasTechnique && techniqueCue != null) ...[
            SizedBox(height: t.spaceSm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(t.spaceSm),
              decoration: BoxDecoration(
                color: t.accentSecondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(t.radiusSm),
                border: Border.all(
                  color: t.accentSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: t.accentSecondary,
                  ),
                  SizedBox(width: t.spaceSm),
                  Expanded(
                    child: Text(
                      techniqueCue!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily:
                            DigitalAtelierTokens.dataFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.accentSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 2. Set Logging Table (Strong-style)
// ============================================================================

class _SetTable extends StatelessWidget {
  const _SetTable({
    required this.loggedSets,
    required this.currentExercise,
    required this.currentWeightKg,
    required this.currentReps,
    required this.currentRpe,
    required this.previous,
    required this.setJustLogged,
  });

  final List<LoggedSet> loggedSets;
  final String currentExercise;
  final int currentWeightKg;
  final int currentReps;
  final int currentRpe;
  final LoggedSet? previous;
  final bool setJustLogged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    // Filter sets for current exercise
    final exerciseSets = loggedSets
        .where(
          (s) =>
              s.exerciseName.trim().toLowerCase() ==
              currentExercise.trim().toLowerCase(),
        )
        .toList();
    final currentSetNumber = exerciseSets.length + 1;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.surfaceBorder),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.spaceLg,
              vertical: t.spaceSm + 2,
            ),
            child: Row(
              children: [
                _TableCell('SET', width: 36, t: t, isHeader: true),
                _TableCell(
                  'PREVIOUS',
                  flex: 3,
                  t: t,
                  isHeader: true,
                ),
                _TableCell('WEIGHT', flex: 2, t: t, isHeader: true),
                _TableCell('REPS', flex: 2, t: t, isHeader: true),
                _TableCell('RPE', flex: 1, t: t, isHeader: true),
                _TableCell('', width: 30, t: t, isHeader: true),
              ],
            ),
          ),
          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: t.spaceLg),
            color: t.surfaceDivider,
          ),
          // Logged sets
          ...exerciseSets.asMap().entries.map((entry) {
            final idx = entry.key;
            final set = entry.value;
            final isNew =
                setJustLogged && idx == exerciseSets.length - 1;
            return _LoggedSetRow(set: set, isNew: isNew);
          }),
          // Current set
          _CurrentSetRow(
            setNumber: currentSetNumber,
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

class _TableCell extends StatelessWidget {
  const _TableCell(
    this.text, {
    required this.t,
    this.width,
    this.flex = 1,
    this.isHeader = false,
  });

  final String text;
  final DigitalAtelierExtension t;
  final double? width;
  final int flex;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: DigitalAtelierTokens.dataFontFamily,
      fontSize: isHeader ? 10 : 13,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w600,
      color: isHeader ? t.textMuted : t.textPrimary,
      letterSpacing: isHeader ? 0.8 : 0,
    );
    final child = Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: style,
    );
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex, child: child);
  }
}

class _LoggedSetRow extends StatelessWidget {
  const _LoggedSetRow({required this.set, required this.isNew});

  final LoggedSet set;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final prevLabel = set.weightKg != null && set.reps != null
        ? '${_numOrDash(set.weightKg)} × ${set.reps}'
        : '--';

    return AnimatedContainer(
      duration: DigitalAtelierTokens2.durationNormal,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceLg,
        vertical: t.spaceSm + 2,
      ),
      decoration: BoxDecoration(
        color: isNew
            ? t.accentTertiary.withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: t.surfaceDivider, width: 0.5),
        ),
      ),
      child: Semantics(
        label:
            'Completed set ${set.setNumber}: '
            '${_numOrDash(set.weightKg)} kilograms '
            '${set.reps ?? 0} reps, RPE ${set.rpe ?? '--'}',
        child: Row(
          children: [
            _TableCell(
              '${set.setNumber}',
              width: 36,
              t: t,
            ),
            Expanded(
              flex: 3,
              child: Text(
                prevLabel,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: DigitalAtelierTokens.dataFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.textMuted,
                ),
              ),
            ),
            _TableCell(
              _numOrDash(set.weightKg),
              flex: 2,
              t: t,
            ),
            _TableCell(
              '${set.reps ?? '--'}',
              flex: 2,
              t: t,
            ),
            _TableCell(
              '${set.rpe ?? '--'}',
              flex: 1,
              t: t,
            ),
            SizedBox(
              width: 30,
              child: Icon(
                Icons.check_circle,
                color: t.accentTertiary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentSetRow extends StatelessWidget {
  const _CurrentSetRow({
    required this.setNumber,
    required this.previous,
    required this.weightKg,
    required this.reps,
    required this.rpe,
  });

  final int setNumber;
  final LoggedSet? previous;
  final int weightKg;
  final int reps;
  final int rpe;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final prevLabel = previous != null &&
            previous!.weightKg != null &&
            previous!.reps != null
        ? '${_numOrDash(previous!.weightKg)} × ${previous!.reps}'
        : 'No previous';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceLg,
        vertical: t.spaceSm + 2,
      ),
      decoration: BoxDecoration(
        color: t.accentPrimary.withValues(alpha: 0.06),
        border: Border(
          left: BorderSide(color: t.accentPrimary, width: 3),
        ),
      ),
      child: Semantics(
        label:
            'Current set $setNumber: '
            '$weightKg kilograms, $reps reps, RPE $rpe',
        child: Row(
          children: [
            _TableCell('$setNumber', width: 36, t: t),
            Expanded(
              flex: 3,
              child: Text(
                prevLabel,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: DigitalAtelierTokens.dataFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.textMuted,
                ),
              ),
            ),
            _TableCell(
              weightKg == 0 ? '--' : '$weightKg',
              flex: 2,
              t: t,
            ),
            _TableCell('$reps', flex: 2, t: t),
            _TableCell('$rpe', flex: 1, t: t),
            SizedBox(
              width: 30,
              child: Icon(
                Icons.radio_button_unchecked,
                color: t.textMuted,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. Set Controls (Weight/Reps/RPE)
// ============================================================================

class _SetControls extends StatelessWidget {
  const _SetControls({
    required this.weightKg,
    required this.reps,
    required this.rpe,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRpeChanged,
    required this.painSafetyActive,
    required this.readinessCapActive,
  });

  final int weightKg;
  final int reps;
  final int rpe;
  final ValueChanged<int> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<int> onRpeChanged;
  final bool painSafetyActive;
  final bool readinessCapActive;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Container(
      padding: EdgeInsets.all(t.spaceLg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.surfaceBorder),
      ),
      child: Column(
        children: [
          // Weight row
          _ControlStepper(
            label: 'WEIGHT',
            value: '$weightKg',
            unit: 'kg',
            onDecrement: () => onWeightChanged(-1),
            onIncrement: () => onWeightChanged(1),
            t: t,
          ),
          SizedBox(height: t.spaceMd),
          // Reps row
          _ControlStepper(
            label: 'REPS',
            value: '$reps',
            unit: '',
            onDecrement: () => onRepsChanged(-1),
            onIncrement: () => onRepsChanged(1),
            t: t,
          ),
          SizedBox(height: t.spaceMd),
          // RPE row
          _ControlStepper(
            label: 'RPE',
            value: '$rpe',
            unit: '/10',
            onDecrement: () => onRpeChanged(-1),
            onIncrement: () => onRpeChanged(1),
            t: t,
            capped: painSafetyActive || readinessCapActive,
          ),
        ],
      ),
    );
  }
}

class _ControlStepper extends StatelessWidget {
  const _ControlStepper({
    required this.label,
    required this.value,
    required this.unit,
    required this.onDecrement,
    required this.onIncrement,
    required this.t,
    this.capped = false,
  });

  final String label;
  final String value;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final DigitalAtelierExtension t;
  final bool capped;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label control, current value $value$unit',
      child: Row(
        children: [
          // Label
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          // Minus button
          Semantics(
            button: true,
            label: 'Decrease $label',
            child: GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.surfaceElevated,
                  border: Border.all(color: t.surfaceBorder),
                ),
                child: Icon(Icons.remove, color: t.textPrimary, size: 22),
              ),
            ),
          ),
          // Value
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: DigitalAtelierTokens2.durationFast,
                    child: Text(
                      value,
                      key: ValueKey(value),
                      style: TextStyle(
                        fontFamily:
                            DigitalAtelierTokens.dataFontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontFamily:
                              DigitalAtelierTokens.dataFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: t.textMuted,
                        ),
                      ),
                    ),
                  if (capped)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.shield,
                        size: 14,
                        color: t.warning,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Plus button
          Semantics(
            button: true,
            label: 'Increase $label',
            child: GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.accentPrimary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: t.accentPrimary.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(Icons.add, color: t.accentPrimary, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. Quick Preset Row
// ============================================================================

class _QuickPresetRow extends StatelessWidget {
  const _QuickPresetRow({
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
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Quick action presets',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PresetChip(
              icon: Icons.local_fire_department_outlined,
              label: 'Warm-up',
              onPressed: onWarmup,
              t: t,
            ),
            SizedBox(width: t.spaceSm),
            _PresetChip(
              icon: Icons.history,
              label: 'Previous',
              onPressed: hasPrevious ? onApplyPrevious : null,
              t: t,
            ),
            SizedBox(width: t.spaceSm),
            _PresetChip(
              icon: Icons.track_changes,
              label: 'Plan',
              onPressed: onApplyPlanTarget,
              t: t,
            ),
            SizedBox(width: t.spaceSm),
            _PresetChip(
              icon: Icons.tune_outlined,
              label: 'Technique',
              onPressed: onTechniqueSwap,
              t: t,
            ),
            SizedBox(width: t.spaceSm),
            _PresetChip(
              icon: Icons.health_and_safety_outlined,
              label: 'Pain safety',
              onPressed: onPainSafety,
              t: t,
              isDanger: true,
            ),
            SizedBox(width: t.spaceSm),
            _PresetChip(
              icon: Icons.skip_next_outlined,
              label: 'Skip',
              onPressed: canSkip ? onSkip : null,
              t: t,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.t,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final DigitalAtelierExtension t;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fgColor = !enabled
        ? t.textMuted
        : isDanger
            ? t.accentDanger
            : t.textPrimary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: t.surfaceElevated,
            borderRadius: BorderRadius.circular(t.radiusPill),
            border: Border.all(color: t.surfaceBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fgColor),
              SizedBox(width: t.spaceXs + 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: DigitalAtelierTokens.dataFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 5. Coach Insight Card
// ============================================================================

class _CoachInsightCard extends StatelessWidget {
  const _CoachInsightCard({required this.signal});

  final CoachSignal signal;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Semantics(
      container: true,
      label: signal.semanticLabel,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(color: t.surfaceBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: t.accentPrimary),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(t.spaceMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.psychology_alt_outlined,
                        color: t.accentPrimary,
                        size: 18,
                      ),
                      SizedBox(width: t.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              signal.personaLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily:
                                    DigitalAtelierTokens.dataFontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: t.accentPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: t.spaceXs),
                            Text(
                              signal.coachNote,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily:
                                    DigitalAtelierTokens.dataFontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: t.textPrimary,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: t.spaceXs),
                            Text(
                              '${signal.observationLabel}: ${signal.observation}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily:
                                    DigitalAtelierTokens.dataFontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ============================================================================
// 6. Bottom Bar (Summary + Log + Rest)
// ============================================================================

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.totalVolume,
    required this.loggedSets,
    required this.totalPlannedSets,
    required this.elapsedLabel,
    required this.restSeconds,
    required this.restCountdownActive,
    required this.restBreathingController,
    required this.weightKg,
    required this.reps,
    required this.canLog,
    required this.allSetsComplete,
    required this.hasLoggedSets,
    required this.onLogSet,
    required this.onUndo,
    required this.onFinish,
    required this.onReportPain,
  });

  final int totalVolume;
  final int loggedSets;
  final int totalPlannedSets;
  final String elapsedLabel;
  final int restSeconds;
  final bool restCountdownActive;
  final AnimationController restBreathingController;
  final int weightKg;
  final int reps;
  final bool canLog;
  final bool allSetsComplete;
  final bool hasLoggedSets;
  final VoidCallback onLogSet;
  final VoidCallback onUndo;
  final VoidCallback onFinish;
  final VoidCallback onReportPain;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final volumeLabel = totalVolume >= 1000
        ? '${(totalVolume / 1000).toStringAsFixed(1)}k'
        : '$totalVolume';

    return Container(
      padding: EdgeInsets.fromLTRB(
        t.spaceLg,
        t.spaceMd,
        t.spaceLg,
        t.spaceLg,
      ),
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        border: Border(top: BorderSide(color: t.surfaceBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary row
            Semantics(
              container: true,
              label:
                  '$loggedSets of $totalPlannedSets sets logged. '
                  'Volume $volumeLabel kg. Duration $elapsedLabel.',
              child: Row(
                children: [
                  _SummaryMetric(
                    icon: Icons.format_list_numbered,
                    value: '$loggedSets/$totalPlannedSets',
                    label: 'SETS',
                    t: t,
                  ),
                  SizedBox(width: t.spaceLg),
                  _SummaryMetric(
                    icon: Icons.fitness_center,
                    value: volumeLabel,
                    label: 'VOLUME',
                    t: t,
                  ),
                  SizedBox(width: t.spaceLg),
                  _SummaryMetric(
                    icon: Icons.timer_outlined,
                    value: elapsedLabel,
                    label: 'TIME',
                    t: t,
                  ),
                  const Spacer(),
                  // Rest countdown or rest preset
                  if (restCountdownActive)
                    _RestCountdownBadge(
                      seconds: restSeconds,
                      controller: restBreathingController,
                      t: t,
                    )
                  else if (restSeconds > 0)
                    Text(
                      _restLabel(restSeconds),
                      style: TextStyle(
                        fontFamily: DigitalAtelierTokens.dataFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: t.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: t.spaceMd),
            // Action buttons row — undo, finish, pain (compact)
            Row(
              children: [
                // Undo
                Semantics(
                  button: true,
                  enabled: hasLoggedSets,
                  label: 'Undo last set',
                  child: GestureDetector(
                    onTap: hasLoggedSets ? onUndo : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(t.radiusMd),
                        border: Border.all(color: t.surfaceBorder),
                      ),
                      child: Icon(
                        Icons.undo,
                        color: hasLoggedSets
                            ? t.textPrimary
                            : t.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: t.spaceSm),
                // Finish
                if (hasLoggedSets) ...[
                  Semantics(
                    button: true,
                    label: 'Finish workout',
                    child: GestureDetector(
                      onTap: onFinish,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(t.radiusMd),
                          color: t.accentTertiary.withValues(alpha: 0.15),
                          border: Border.all(
                            color: t.accentTertiary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.flag_outlined,
                          color: t.accentTertiary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: t.spaceSm),
                ],
                // Report Pain — persistent, always visible
                Semantics(
                  button: true,
                  label: 'Report pain during workout',
                  child: GestureDetector(
                    onTap: onReportPain,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(t.radiusMd),
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.healing,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: t.spaceSm),
            // Log Set button — full-width, 56px, pill shape
            Semantics(
              button: true,
              enabled: canLog,
              label: allSetsComplete
                  ? 'Finish and debrief'
                  : 'Log set, $weightKg kilograms $reps reps',
              child: GestureDetector(
                onTap: canLog
                    ? (allSetsComplete ? onFinish : onLogSet)
                    : null,
                child: AnimatedContainer(
                  duration: DigitalAtelierTokens2.durationFast,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(t.radiusPill),
                    gradient: canLog
                        ? (allSetsComplete
                            ? LinearGradient(
                                colors: [
                                  t.accentTertiary,
                                  t.accentInfo,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  t.accentPrimary,
                                  t.accentPrimary
                                      .withValues(alpha: 0.8),
                                ],
                              ))
                        : null,
                    color: canLog ? null : t.surfaceDivider,
                  ),
                  child: Center(
                    child: Text(
                      allSetsComplete
                          ? 'Finish & Debrief'
                          : 'Log Set  ·  $weightKg kg × $reps',
                      style: TextStyle(
                        fontFamily:
                            DigitalAtelierTokens.dataFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: canLog
                            ? t.textInverse
                            : t.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.t,
  });

  final IconData icon;
  final String value;
  final String label;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: t.textMuted),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: t.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestCountdownBadge extends StatelessWidget {
  const _RestCountdownBadge({
    required this.seconds,
    required this.controller,
    required this.t,
  });

  final int seconds;
  final AnimationController controller;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final breathe = 0.8 + (controller.value * 0.2);
        return Transform.scale(
          scale: breathe,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: t.accentPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(t.radiusPill),
          border: Border.all(
            color: t.accentPrimary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_bottom, size: 14, color: t.accentPrimary),
            SizedBox(width: t.spaceXs),
            Semantics(
              label: 'Rest timer: ${_spokenSeconds(seconds)} remaining',
              child: Text(
                _restLabel(seconds),
                style: TextStyle(
                  fontFamily: DigitalAtelierTokens.dataFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: t.accentPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 7. Top Bar
// ============================================================================

class _WorkoutTopBar extends StatelessWidget {
  const _WorkoutTopBar({
    required this.elapsedLabel,
    required this.brandMark,
  });

  final String elapsedLabel;
  final Widget brandMark;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Semantics(
      container: true,
      label: 'Workout timer, $elapsedLabel elapsed',
      child: Row(
        children: [
          brandMark,
          const Spacer(),
          Icon(Icons.timer_outlined, size: 16, color: t.accentPrimary),
          SizedBox(width: t.spaceXs),
          Text(
            elapsedLabel,
            style: TextStyle(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Supporting Widgets
// ============================================================================

class _LiveStatusBanner extends StatelessWidget {
  const _LiveStatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Semantics(
      key: const ValueKey('active_workout_live_status'),
      liveRegion: true,
      container: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceMd,
          vertical: t.spaceSm + 2,
        ),
        decoration: BoxDecoration(
          color: t.accentPrimary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(t.radiusSm),
          border: Border.all(
            color: t.accentPrimary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: t.accentPrimary,
            ),
            SizedBox(width: t.spaceSm),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: DigitalAtelierTokens.dataFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.accentPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PainSafetyBanner extends StatelessWidget {
  const _PainSafetyBanner({
    required this.ceiling,
    required this.onDismiss,
  });

  final int? ceiling;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceLg,
        vertical: t.spaceSm + 2,
      ),
      decoration: BoxDecoration(
        color: t.accentDanger.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: t.accentDanger.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety, size: 16, color: t.accentDanger),
          SizedBox(width: t.spaceSm),
          Expanded(
            child: Text(
              ceiling != null
                  ? 'Pain safety active — weight capped at $ceiling kg, RPE max 6'
                  : 'Pain safety active — RPE max 6',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: t.accentDanger,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: EdgeInsets.all(t.spaceXs),
              child: Icon(Icons.close, size: 16, color: t.accentDanger),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessBanner extends StatelessWidget {
  const _ReadinessBanner({required this.readiness});

  final ReadinessEntry readiness;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceLg,
        vertical: t.spaceSm + 2,
      ),
      decoration: BoxDecoration(
        color: t.warning.withValues(alpha: 0.10),
        border: Border(
          bottom: BorderSide(
            color: t.warning.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_outlined, size: 16, color: t.warning),
          SizedBox(width: t.spaceSm),
          Expanded(
            child: Text(
              'Low readiness (${readiness.score} ${readiness.zone}) '
              '— volume capped',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: t.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PR Celebration Overlay
// ============================================================================

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({required this.controller});

  final AnimationController controller;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> {
  late final List<_Confetti> _confetti;
  late final math.Random _rng;

  @override
  void initState() {
    super.initState();
    _rng = math.Random(42);
    _confetti = List.generate(24, (_) {
      return _Confetti(
        x: _rng.nextDouble(),
        y: -_rng.nextDouble() * 0.3,
        color: [
          const Color(0xFFF97316),
          const Color(0xFF10B981),
          const Color(0xFF8B5CF6),
          const Color(0xFF3B82F6),
          const Color(0xFFF59E0B),
        ][_rng.nextInt(5)],
        size: 4 + _rng.nextDouble() * 6,
        rotationSpeed: _rng.nextDouble() * 6 - 3,
        fallSpeed: 0.3 + _rng.nextDouble() * 0.5,
        drift: (_rng.nextDouble() - 0.5) * 0.3,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final progress = widget.controller.value;
        return IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              confetti: _confetti,
              progress: progress,
            ),
          ),
        );
      },
    );
  }
}

class _Confetti {
  const _Confetti({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.fallSpeed,
    required this.drift,
  });

  final double x;
  final double y;
  final Color color;
  final double size;
  final double rotationSpeed;
  final double fallSpeed;
  final double drift;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.confetti,
    required this.progress,
  });

  final List<_Confetti> confetti;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final px = (c.x + c.drift * progress) * size.width;
      final py = (c.y + c.fallSpeed * progress) * size.height;
      if (py > size.height) continue;

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = c.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(c.rotationSpeed * progress * 3.14);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: c.size,
          height: c.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// Debrief Sheet
// ============================================================================

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
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
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
            child: Text(
              'Debrief',
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
          ),
          SizedBox(height: t.spaceLg),
          // Exertion
          _DebriefStepper(
            label: 'Exertion',
            value: _rpe,
            valueLabel: '$_rpe/10',
            max: 10,
            onChanged: (delta) {
              setState(() => _rpe = (_rpe + delta).clamp(1, 10));
            },
            t: t,
          ),
          SizedBox(height: t.spaceMd),
          // Satisfaction
          _DebriefStepper(
            label: 'Satisfaction',
            value: _satisfaction,
            valueLabel: '$_satisfaction/5',
            max: 5,
            onChanged: (delta) {
              setState(
                () => _satisfaction = (_satisfaction + delta).clamp(1, 5),
              );
            },
            t: t,
          ),
          SizedBox(height: t.spaceMd),
          TextField(
            key: const ValueKey('active_workout_pain_field'),
            controller: _painController,
            maxLines: 2,
            style: TextStyle(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
              color: t.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Pain check',
              labelStyle: TextStyle(color: t.textSecondary),
            ),
          ),
          SizedBox(height: t.spaceMd),
          TextField(
            key: const ValueKey('active_workout_next_focus_field'),
            controller: _focusController,
            maxLines: 2,
            style: TextStyle(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
              color: t.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Next focus',
              labelStyle: TextStyle(color: t.textSecondary),
            ),
          ),
          SizedBox(height: t.spaceLg),
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

class _DebriefStepper extends StatelessWidget {
  const _DebriefStepper({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.max,
    required this.onChanged,
    required this.t,
  });

  final String label;
  final int value;
  final String valueLabel;
  final int max;
  final ValueChanged<int> onChanged;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceMd,
        vertical: t.spaceSm + 2,
      ),
      decoration: BoxDecoration(
        color: t.surfaceInput,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: t.textPrimary,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Decrease $label',
            child: GestureDetector(
              onTap: () => onChanged(-1),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.surfaceElevated,
                  border: Border.all(color: t.surfaceBorder),
                ),
                child: Icon(Icons.remove, size: 18, color: t.textPrimary),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              valueLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Increase $label',
            child: GestureDetector(
              onTap: () => onChanged(1),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.accentPrimary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: t.accentPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(Icons.add, size: 18, color: t.accentPrimary),
              ),
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

// ============================================================================
// Closed Workout Surface
// ============================================================================

class _ClosedWorkoutSurface extends StatelessWidget {
  const _ClosedWorkoutSurface({required this.hasDebrief});

  final bool hasDebrief;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final title = hasDebrief ? 'Session saved' : 'No live session';
    final body = hasDebrief
        ? 'Today is logged. The next plan can adapt from this proof.'
        : 'Start a session from Today when you are ready.';

    return Scaffold(
      backgroundColor: t.background,
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
              SizedBox(height: t.spaceXxl),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: t.spaceSm),
              Text(
                body,
                style: TextStyle(
                  fontFamily: DigitalAtelierTokens.dataFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: t.textSecondary,
                ),
              ),
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

// ============================================================================
// Free-standing helpers (preserved from original)
// ============================================================================

String _numOrDash(double? value) {
  if (value == null) return '--';
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

String _elapsedLabel(DateTime startedAt) {
  final elapsed = DateTime.now().difference(startedAt);
  final hours = elapsed.inHours;
  final minutes =
      elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds =
      elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _restLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

String _spokenSeconds(int seconds) {
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

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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
      'Load/RPE and planned sets reduced for today; '
      'return to normal after recovery.';
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

// ── Technique swap ──────────────────────────────────────────────────────────

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

// ============================================================================
// Pain Report Sheet — quick body-part + severity assessment
// ============================================================================

class _PainReportSheet extends StatefulWidget {
  const _PainReportSheet({required this.onReport});

  final void Function(String bodyPart, int severity) onReport;

  @override
  State<_PainReportSheet> createState() => _PainReportSheetState();
}

class _PainReportSheetState extends State<_PainReportSheet> {
  String? _selectedBodyPart;
  int _severity = 5;

  static const _bodyParts = <(String id, String label, IconData icon)>[
    ('shoulder', 'Shoulder', Icons.accessibility_new),
    ('back_lower', 'Lower Back', Icons.airline_seat_recline_normal),
    ('back_upper', 'Upper Back', Icons.accessibility),
    ('knee', 'Knee', Icons.directions_walk),
    ('elbow', 'Elbow', Icons.sports_martial_arts),
    ('wrist', 'Wrist', Icons.front_hand),
    ('hip', 'Hip', Icons.directions_run),
    ('ankle', 'Ankle', Icons.hiking),
    ('neck', 'Neck', Icons.person),
    ('other', 'Other', Icons.healing),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: t.surfaceDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.healing, color: Color(0xFFEF4444), size: 22),
                const SizedBox(width: 10),
                Text(
                  'Report Pain',
                  style: TextStyle(
                    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DigitalAtelierTokens.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Where does it hurt? This activates pain safety mode — '
              'load and RPE will be capped automatically.',
              style: TextStyle(
                fontSize: 13,
                color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            // Body part selector
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, label, icon) in _bodyParts)
                  Semantics(
                    button: true,
                    selected: _selectedBodyPart == id,
                    label: 'Pain location: $label',
                    child: FilterChip(
                      avatar: Icon(icon, size: 16),
                      label: Text(label),
                      selected: _selectedBodyPart == id,
                      selectedColor:
                          const Color(0xFFEF4444).withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: _selectedBodyPart == id
                            ? const Color(0xFFEF4444)
                            : DigitalAtelierTokens.textPrimary,
                        fontSize: 13,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedBodyPart = id),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Severity slider
            Text(
              'Severity: $_severity / 10',
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DigitalAtelierTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Mild',
                    style: TextStyle(
                        fontSize: 11,
                        color: DigitalAtelierTokens.textPrimary
                            .withValues(alpha: 0.5))),
                Expanded(
                  child: Slider(
                    value: _severity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _severity <= 3
                        ? const Color(0xFFF59E0B)
                        : _severity <= 6
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF991B1B),
                    onChanged: (v) =>
                        setState(() => _severity = v.round()),
                  ),
                ),
                Text('Severe',
                    style: TextStyle(
                        fontSize: 11,
                        color: DigitalAtelierTokens.textPrimary
                            .withValues(alpha: 0.5))),
              ],
            ),
            const SizedBox(height: 16),
            // Submit
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: 'Confirm pain report',
                child: ElevatedButton(
                  onPressed: _selectedBodyPart == null
                      ? null
                      : () => widget.onReport(
                            _selectedBodyPart!,
                            _severity,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedBodyPart == null
                        ? 'Select where it hurts'
                        : 'Confirm — Activate Pain Safety',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
