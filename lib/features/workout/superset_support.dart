/// M4: Superset and circuit training support.
///
/// Data models for grouped exercises (supersets, circuits, giant sets).
/// Integrates with the workout logger to cycle between exercises with
/// prescribed rest intervals.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

// ── Enums ────────────────────────────────────────────────────────────────

/// Grouping strategy for multi-exercise sets.
enum GroupingType {
  /// Two antagonist exercises back-to-back (e.g., bench press + rows).
  superset,

  /// Three exercises performed in sequence (e.g., push/pull/legs circuit).
  circuit,

  /// Four or more exercises in a loop (e.g., full-body giant set).
  giantSet,

  /// Pre-exhaust: isolation before compound on the same muscle.
  preExhaust,

  /// Post-exhaust: compound before isolation on the same muscle.
  postExhaust,
}

/// How rest is prescribed between exercises in a group.
enum RestStrategy {
  /// No rest between exercises; rest only between rounds.
  noRestBetween,

  /// Fixed rest between each exercise transition.
  fixedRest,

  /// Self-paced — athlete decides when to start the next exercise.
  selfPaced,
}

// ── SupersetGroup ────────────────────────────────────────────────────────

/// A superset: two exercises performed back-to-back with minimal rest.
///
/// Classic antagonist supersets (bench/row, curl/tricep extension) save time
/// and may enhance performance via reciprocal inhibition (Robbins et al.,
/// 2010).
class SupersetGroup {
  const SupersetGroup({
    required this.id,
    required this.exercises,
    required this.restBetweenExercises,
    required this.restBetweenRounds,
    required this.rounds,
    this.restStrategy = RestStrategy.fixedRest,
    this.targetReps = const [],
    this.targetWeightKg = const [],
    this.notes,
  });

  /// Stable identifier.
  final String id;

  /// Exercise IDs in execution order (typically 2 for a superset).
  final List<String> exercises;

  /// Rest between the two exercises (seconds). Often 0–15s for supersets.
  final int restBetweenExercises;

  /// Rest after completing both exercises before the next round (seconds).
  final int restBetweenRounds;

  /// Number of rounds to complete.
  final int rounds;

  /// How rest is prescribed between exercises.
  final RestStrategy restStrategy;

  /// Target reps per exercise per round. Empty = use individual prescriptions.
  final List<int> targetReps;

  /// Target weight (kg) per exercise per round. Empty = use individual.
  final List<double> targetWeightKg;

  /// Optional coaching notes for the group.
  final String? notes;

  /// Total working exercises across all rounds.
  int get totalSets => exercises.length * rounds;

  /// Estimated total duration (seconds) including all rest periods.
  int get estimatedDurationSeconds {
    const perSetWorkSeconds = 45; // average working set duration
    final workTime = exercises.length * rounds * perSetWorkSeconds;
    final interExerciseRest =
        restBetweenExercises * (exercises.length - 1) * rounds;
    final interRoundRest = restBetweenRounds * (rounds - 1);
    return workTime + interExerciseRest + interRoundRest;
  }

  /// Whether this superset targets antagonist muscle pairs.
  bool get isAntagonist {
    // Heuristic: if exercises list is exactly 2, assume antagonist pairing.
    // Actual muscle check requires the exercise database lookup.
    return exercises.length == 2;
  }

  // ── Serialization ────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
        'id': id,
        'exercises': exercises,
        'restBetweenExercises': restBetweenExercises,
        'restBetweenRounds': restBetweenRounds,
        'rounds': rounds,
        'restStrategy': restStrategy.name,
        'targetReps': targetReps,
        'targetWeightKg': targetWeightKg,
        'notes': notes,
      };

  factory SupersetGroup.fromJson(Map<String, Object?> json) {
    return SupersetGroup(
      id: json['id'] as String,
      exercises:
          (json['exercises'] as List).map((e) => e as String).toList(),
      restBetweenExercises: json['restBetweenExercises'] as int,
      restBetweenRounds: json['restBetweenRounds'] as int,
      rounds: json['rounds'] as int,
      restStrategy: RestStrategy.values.byName(
        json['restStrategy'] as String? ?? RestStrategy.fixedRest.name,
      ),
      targetReps:
          (json['targetReps'] as List?)?.map((r) => r as int).toList() ??
              const [],
      targetWeightKg: (json['targetWeightKg'] as List?)
              ?.map((w) => (w as num).toDouble())
              .toList() ??
          const [],
      notes: json['notes'] as String?,
    );
  }

  SupersetGroup copyWith({
    String? id,
    List<String>? exercises,
    int? restBetweenExercises,
    int? restBetweenRounds,
    int? rounds,
    RestStrategy? restStrategy,
    List<int>? targetReps,
    List<double>? targetWeightKg,
    String? notes,
  }) {
    return SupersetGroup(
      id: id ?? this.id,
      exercises: exercises ?? this.exercises,
      restBetweenExercises:
          restBetweenExercises ?? this.restBetweenExercises,
      restBetweenRounds: restBetweenRounds ?? this.restBetweenRounds,
      rounds: rounds ?? this.rounds,
      restStrategy: restStrategy ?? this.restStrategy,
      targetReps: targetReps ?? this.targetReps,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'SupersetGroup($id, ${exercises.length} exercises, $rounds rounds)';
}

// ── CircuitGroup ─────────────────────────────────────────────────────────

/// A circuit: 3+ exercises performed in sequence, repeated for N rounds.
///
/// Circuits are time-efficient and provide a cardiovascular stimulus alongside
/// resistance training. Effective for general fitness and conditioning
/// (Alcaraz et al., 2011).
class CircuitGroup {
  const CircuitGroup({
    required this.id,
    required this.name,
    required this.exercises,
    required this.restBetweenExercises,
    required this.restBetweenRounds,
    required this.rounds,
    this.groupingType = GroupingType.circuit,
    this.restStrategy = RestStrategy.fixedRest,
    this.targetRepsPerExercise = const [],
    this.targetDurationSeconds = const [],
    this.targetRpe = 7,
    this.notes,
  });

  /// Stable identifier.
  final String id;

  /// Human-readable circuit name (e.g., "Upper Body Push Circuit").
  final String name;

  /// Exercise IDs in execution order.
  final List<String> exercises;

  /// Rest between each exercise in the circuit (seconds).
  final int restBetweenExercises;

  /// Rest after completing one full round (seconds).
  final int restBetweenRounds;

  /// Number of full rounds.
  final int rounds;

  /// What kind of grouping this is.
  final GroupingType groupingType;

  /// How rest is prescribed.
  final RestStrategy restStrategy;

  /// Target reps per exercise. Empty = bodyweight/timed.
  final List<int> targetRepsPerExercise;

  /// Target duration per exercise in seconds (for timed exercises).
  /// Empty = rep-based.
  final List<int> targetDurationSeconds;

  /// Target RPE for the entire circuit.
  final int targetRpe;

  /// Optional coaching notes.
  final String? notes;

  /// Number of exercises in the circuit.
  int get exerciseCount => exercises.length;

  /// Total working sets across all rounds.
  int get totalSets => exercises.length * rounds;

  /// Estimated total duration (seconds).
  int get estimatedDurationSeconds {
    final isTimed = targetDurationSeconds.isNotEmpty;
    final perExerciseWork = isTimed
        ? (targetDurationSeconds.isEmpty
            ? 45
            : targetDurationSeconds.reduce((a, b) => a + b) ~/
                targetDurationSeconds.length)
        : 45;
    final workTime = exercises.length * rounds * perExerciseWork;
    final interExerciseRest =
        restBetweenExercises * (exercises.length - 1) * rounds;
    final interRoundRest = restBetweenRounds * (rounds - 1);
    return workTime + interExerciseRest + interRoundRest;
  }

  // ── Serialization ────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises,
        'restBetweenExercises': restBetweenExercises,
        'restBetweenRounds': restBetweenRounds,
        'rounds': rounds,
        'groupingType': groupingType.name,
        'restStrategy': restStrategy.name,
        'targetRepsPerExercise': targetRepsPerExercise,
        'targetDurationSeconds': targetDurationSeconds,
        'targetRpe': targetRpe,
        'notes': notes,
      };

  factory CircuitGroup.fromJson(Map<String, Object?> json) {
    return CircuitGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises:
          (json['exercises'] as List).map((e) => e as String).toList(),
      restBetweenExercises: json['restBetweenExercises'] as int,
      restBetweenRounds: json['restBetweenRounds'] as int,
      rounds: json['rounds'] as int,
      groupingType: GroupingType.values.byName(
        json['groupingType'] as String? ?? GroupingType.circuit.name,
      ),
      restStrategy: RestStrategy.values.byName(
        json['restStrategy'] as String? ?? RestStrategy.fixedRest.name,
      ),
      targetRepsPerExercise: (json['targetRepsPerExercise'] as List?)
              ?.map((r) => r as int)
              .toList() ??
          const [],
      targetDurationSeconds: (json['targetDurationSeconds'] as List?)
              ?.map((d) => d as int)
              .toList() ??
          const [],
      targetRpe: json['targetRpe'] as int? ?? 7,
      notes: json['notes'] as String?,
    );
  }

  CircuitGroup copyWith({
    String? id,
    String? name,
    List<String>? exercises,
    int? restBetweenExercises,
    int? restBetweenRounds,
    int? rounds,
    GroupingType? groupingType,
    RestStrategy? restStrategy,
    List<int>? targetRepsPerExercise,
    List<int>? targetDurationSeconds,
    int? targetRpe,
    String? notes,
  }) {
    return CircuitGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      restBetweenExercises:
          restBetweenExercises ?? this.restBetweenExercises,
      restBetweenRounds: restBetweenRounds ?? this.restBetweenRounds,
      rounds: rounds ?? this.rounds,
      groupingType: groupingType ?? this.groupingType,
      restStrategy: restStrategy ?? this.restStrategy,
      targetRepsPerExercise:
          targetRepsPerExercise ?? this.targetRepsPerExercise,
      targetDurationSeconds:
          targetDurationSeconds ?? this.targetDurationSeconds,
      targetRpe: targetRpe ?? this.targetRpe,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'CircuitGroup($name, ${exercises.length} exercises, $rounds rounds)';
}

// ── Grouped Exercise State ───────────────────────────────────────────────

/// Tracks the current position within a superset/circuit during a workout.
///
/// The workout logger uses this to determine which exercise is next and
/// how much rest to prescribe between transitions.
class GroupedExerciseState {
  const GroupedExerciseState({
    required this.groupId,
    required this.groupingType,
    required this.exercises,
    required this.rounds,
    required this.currentRound,
    required this.currentExerciseIndex,
    required this.completedSetsPerExercise,
  });

  /// ID of the superset/circuit group.
  final String groupId;

  /// Type of grouping.
  final GroupingType groupingType;

  /// Exercise IDs in order.
  final List<String> exercises;

  /// Total rounds prescribed.
  final int rounds;

  /// Current round (1-indexed).
  final int currentRound;

  /// Index into [exercises] for the current exercise (0-indexed).
  final int currentExerciseIndex;

  /// Number of completed sets per exercise across all rounds.
  final List<int> completedSetsPerExercise;

  /// The exercise ID currently active.
  String get currentExerciseId => exercises[currentExerciseIndex];

  /// Whether all rounds and exercises are complete.
  bool get isComplete =>
      currentRound > rounds ||
      (currentRound == rounds && currentExerciseIndex >= exercises.length);

  /// Progress as a fraction (0.0 to 1.0).
  double get progress {
    if (isComplete) return 1.0;
    final totalSets = exercises.length * rounds;
    final completedSets =
        completedSetsPerExercise.fold<int>(0, (a, b) => a + b);
    if (totalSets == 0) return 0.0;
    return (completedSets / totalSets).clamp(0.0, 1.0);
  }

  /// Advance to the next exercise or round. Returns the new state.
  GroupedExerciseState advance() {
    final newCompleted = List<int>.from(completedSetsPerExercise);
    if (currentExerciseIndex < exercises.length) {
      newCompleted[currentExerciseIndex]++;
    }

    final nextExerciseIndex = currentExerciseIndex + 1;
    if (nextExerciseIndex < exercises.length) {
      // Next exercise in the same round.
      return GroupedExerciseState(
        groupId: groupId,
        groupingType: groupingType,
        exercises: exercises,
        rounds: rounds,
        currentRound: currentRound,
        currentExerciseIndex: nextExerciseIndex,
        completedSetsPerExercise: newCompleted,
      );
    }

    // All exercises in this round done — advance to next round.
    return GroupedExerciseState(
      groupId: groupId,
      groupingType: groupingType,
      exercises: exercises,
      rounds: rounds,
      currentRound: currentRound + 1,
      currentExerciseIndex: 0,
      completedSetsPerExercise: newCompleted,
    );
  }

  /// Get the prescribed rest seconds before the next exercise.
  int getRestBeforeNext({
    required int restBetweenExercises,
    required int restBetweenRounds,
  }) {
    if (isComplete) return 0;
    // If we're about to start a new round (wrapped back to index 0).
    if (currentExerciseIndex == exercises.length - 1) {
      return restBetweenRounds;
    }
    return restBetweenExercises;
  }

  /// Label for UI display: "Exercise 2 of 3 · Round 1 of 4".
  String get progressLabel {
    if (isComplete) return 'Complete';
    return 'Exercise ${currentExerciseIndex + 1} of ${exercises.length} · '
        'Round $currentRound of $rounds';
  }

  // ── Serialization ────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
        'groupId': groupId,
        'groupingType': groupingType.name,
        'exercises': exercises,
        'rounds': rounds,
        'currentRound': currentRound,
        'currentExerciseIndex': currentExerciseIndex,
        'completedSetsPerExercise': completedSetsPerExercise,
      };

  factory GroupedExerciseState.fromJson(Map<String, Object?> json) {
    return GroupedExerciseState(
      groupId: json['groupId'] as String,
      groupingType: GroupingType.values.byName(
        json['groupingType'] as String,
      ),
      exercises:
          (json['exercises'] as List).map((e) => e as String).toList(),
      rounds: json['rounds'] as int,
      currentRound: json['currentRound'] as int,
      currentExerciseIndex: json['currentExerciseIndex'] as int,
      completedSetsPerExercise:
          (json['completedSetsPerExercise'] as List)
              .map((c) => c as int)
              .toList(),
    );
  }

  /// Create initial state for a new group.
  factory GroupedExerciseState.initial({
    required String groupId,
    required GroupingType groupingType,
    required List<String> exercises,
    required int rounds,
  }) {
    return GroupedExerciseState(
      groupId: groupId,
      groupingType: groupingType,
      exercises: exercises,
      rounds: rounds,
      currentRound: 1,
      currentExerciseIndex: 0,
      completedSetsPerExercise: List.filled(exercises.length, 0),
    );
  }

  @override
  String toString() =>
      'GroupedExerciseState($groupId, $progressLabel, '
      '${(progress * 100).round()}% complete)';
}

// ── Pre-built Superset Templates ─────────────────────────────────────────

/// Common superset templates for quick workout building.
class SupersetTemplates {
  SupersetTemplates._();

  /// Antagonist superset: bench press + barbell row.
  static const pushPullSuperset = SupersetGroup(
    id: 'tpl-push-pull',
    exercises: ['barbell-bench-press', 'barbell-row'],
    restBetweenExercises: 15,
    restBetweenRounds: 90,
    rounds: 3,
    targetReps: [8, 8],
    notes: 'Classic antagonist superset. Reciprocal inhibition helps '
        'performance on both lifts.',
  );

  /// Bicep/tricep superset.
  static const armSuperset = SupersetGroup(
    id: 'tpl-arms',
    exercises: ['barbell-curl', 'tricep-pushdown'],
    restBetweenExercises: 10,
    restBetweenRounds: 60,
    rounds: 3,
    targetReps: [12, 12],
    notes: 'Arm superset. Keep elbows pinned for both exercises.',
  );

  /// Leg superset: quad-dominant + hip-dominant.
  static const legSuperset = SupersetGroup(
    id: 'tpl-legs',
    exercises: ['leg-press', 'romanian-deadlift'],
    restBetweenExercises: 20,
    restBetweenRounds: 120,
    rounds: 3,
    targetReps: [10, 10],
    notes: 'Quad + hamstring superset. Brace core on both movements.',
  );

  /// All pre-built templates.
  static const List<SupersetGroup> all = [
    pushPullSuperset,
    armSuperset,
    legSuperset,
  ];
}
