/// M5: Drop set and rest-pause training models.
///
/// Data models for advanced intensity techniques: drop sets (progressive
/// weight reduction) and rest-pause (intra-set rest). Pure Dart, deterministic.
library;

// ── Drop Set ─────────────────────────────────────────────────────────────

/// A single step in a drop set.
class DropSetStep {
  const DropSetStep({
    required this.weightKg,
    required this.reps,
    this.rpe,
  });

  /// Weight for this drop (kg).
  final double weightKg;

  /// Reps to perform at this weight.
  final int reps;

  /// Rate of perceived exertion (optional).
  final double? rpe;

  Map<String, Object?> toJson() => {
        'weightKg': weightKg,
        'reps': reps,
        'rpe': rpe,
      };

  factory DropSetStep.fromJson(Map<String, Object?> json) => DropSetStep(
        weightKg: (json['weightKg'] as num).toDouble(),
        reps: json['reps'] as int,
        rpe: (json['rpe'] as num?)?.toDouble(),
      );

  @override
  String toString() =>
      '${weightKg.toStringAsFixed(1)}kg × $reps${rpe != null ? ' @RPE$rpe' : ''}';
}

/// A drop set: consecutive sets with decreasing weight and no rest.
///
/// Classic drop set protocol: hit failure, reduce weight 20-30%, repeat.
/// Effective for hypertrophy via extended time under tension
/// (Schoenfeld, 2011).
class DropSet {
  const DropSet({
    required this.sets,
    this.restBetweenDrops = 0,
    this.dropPercent = 0.2,
    this.notes,
  });

  /// Steps in the drop set (weight decreasing).
  final List<DropSetStep> sets;

  /// Rest between drops in seconds (0 = no rest, typical for drop sets).
  final int restBetweenDrops;

  /// Percentage to drop weight each step (0.2 = 20%).
  final double dropPercent;

  /// Optional coaching notes.
  final String? notes;

  /// Number of drops (total steps minus the initial set).
  int get dropCount => sets.length - 1;

  /// Total reps across all drops.
  int get totalReps => sets.fold(0, (sum, s) => sum + s.reps);

  /// Starting weight (first step).
  double get startWeightKg => sets.isNotEmpty ? sets.first.weightKg : 0;

  /// Ending weight (last step).
  double get endWeightKg => sets.isNotEmpty ? sets.last.weightKg : 0;

  /// Total weight reduction percentage.
  double get totalReductionPercent {
    if (sets.length < 2) return 0;
    final start = sets.first.weightKg;
    final end = sets.last.weightKg;
    if (start == 0) return 0;
    return ((start - end) / start * 100).clamp(0, 100);
  }

  /// Generate a standard drop set from a starting weight.
  ///
  /// Creates [dropCount] drops, each reducing weight by [dropPercent].
  factory DropSet.generate({
    required double startWeightKg,
    required int repsPerDrop,
    int dropCount = 3,
    double dropPercent = 0.2,
    int restBetweenDrops = 0,
    double? startRpe,
  }) {
    final steps = <DropSetStep>[];
    var weight = startWeightKg;

    for (var i = 0; i <= dropCount; i++) {
      // RPE decreases slightly with each drop
      final rpe = startRpe != null ? (startRpe - i * 0.5).clamp(6.0, 10.0) : null;
      steps.add(DropSetStep(
        weightKg: double.parse(weight.toStringAsFixed(1)),
        reps: repsPerDrop,
        rpe: rpe,
      ));
      weight *= (1 - dropPercent);
    }

    return DropSet(
      sets: steps,
      restBetweenDrops: restBetweenDrops,
      dropPercent: dropPercent,
    );
  }

  Map<String, Object?> toJson() => {
        'sets': sets.map((s) => s.toJson()).toList(),
        'restBetweenDrops': restBetweenDrops,
        'dropPercent': dropPercent,
        'notes': notes,
      };

  factory DropSet.fromJson(Map<String, Object?> json) => DropSet(
        sets: (json['sets'] as List)
            .map((s) => DropSetStep.fromJson(s as Map<String, Object?>))
            .toList(),
        restBetweenDrops: json['restBetweenDrops'] as int? ?? 0,
        dropPercent: (json['dropPercent'] as num?)?.toDouble() ?? 0.2,
        notes: json['notes'] as String?,
      );

  DropSet copyWith({
    List<DropSetStep>? sets,
    int? restBetweenDrops,
    double? dropPercent,
    String? notes,
  }) {
    return DropSet(
      sets: sets ?? this.sets,
      restBetweenDrops: restBetweenDrops ?? this.restBetweenDrops,
      dropPercent: dropPercent ?? this.dropPercent,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'DropSet(${sets.length} drops, ${startWeightKg}kg → ${endWeightKg}kg, '
      '$totalReps total reps)';
}

// ── Rest-Pause Set ───────────────────────────────────────────────────────

/// A rest-pause set: hit failure, rest briefly, continue with same weight.
///
/// Rest-pause training allows more volume at a given intensity by
/// breaking a set into mini-sets with short intra-set pauses.
/// Effective for strength and hypertrophy (Prestes et al., 2017).
class RestPauseSet {
  const RestPauseSet({
    required this.initialWeightKg,
    required this.initialReps,
    required this.pauseSeconds,
    required this.backoffReps,
    this.backoffSets = 2,
    this.rpe,
    this.notes,
  });

  /// Weight for the set (kg).
  final double initialWeightKg;

  /// Reps in the initial effort.
  final int initialReps;

  /// Pause duration in seconds (typically 10-20s).
  final int pauseSeconds;

  /// Reps achieved in each backoff mini-set.
  final int backoffReps;

  /// Number of backoff mini-sets after the initial effort.
  final int backoffSets;

  /// RPE for the initial effort.
  final double? rpe;

  /// Optional coaching notes.
  final String? notes;

  /// Total reps across all mini-sets.
  int get totalReps => initialReps + (backoffReps * backoffSets);

  /// Number of pauses (same as backoffSets).
  int get pauseCount => backoffSets;

  /// Total time under load estimate (seconds).
  /// Assumes ~3s per rep (2s concentric + 1s eccentric).
  int get estimatedTimeSeconds {
    const secondsPerRep = 3;
    return (totalReps * secondsPerRep) + (pauseSeconds * pauseCount);
  }

  /// Rep breakdown description: "8 + 4 + 3 @80kg".
  String get repBreakdown {
    final parts = <String>['$initialReps'];
    for (var i = 0; i < backoffSets; i++) {
      parts.add('$backoffReps');
    }
    return '${parts.join(' + ')} @${initialWeightKg.toStringAsFixed(0)}kg';
  }

  /// Generate a rest-pause set from target reps.
  ///
  /// [targetReps] is the total desired reps. The initial set goes to near
  /// failure (~80% of target), then backoff sets of ~40% of target reps.
  factory RestPauseSet.generate({
    required double weightKg,
    required int targetReps,
    int pauseSeconds = 15,
    int backoffSets = 2,
    double? rpe,
  }) {
    final initialReps = (targetReps * 0.8).round();
    final backoffReps = ((targetReps - initialReps) / backoffSets).round().clamp(1, 10);

    return RestPauseSet(
      initialWeightKg: weightKg,
      initialReps: initialReps,
      pauseSeconds: pauseSeconds,
      backoffReps: backoffReps,
      backoffSets: backoffSets,
      rpe: rpe,
    );
  }

  Map<String, Object?> toJson() => {
        'initialWeightKg': initialWeightKg,
        'initialReps': initialReps,
        'pauseSeconds': pauseSeconds,
        'backoffReps': backoffReps,
        'backoffSets': backoffSets,
        'rpe': rpe,
        'notes': notes,
      };

  factory RestPauseSet.fromJson(Map<String, Object?> json) => RestPauseSet(
        initialWeightKg: (json['initialWeightKg'] as num).toDouble(),
        initialReps: json['initialReps'] as int,
        pauseSeconds: json['pauseSeconds'] as int,
        backoffReps: json['backoffReps'] as int,
        backoffSets: json['backoffSets'] as int? ?? 2,
        rpe: (json['rpe'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );

  RestPauseSet copyWith({
    double? initialWeightKg,
    int? initialReps,
    int? pauseSeconds,
    int? backoffReps,
    int? backoffSets,
    double? rpe,
    String? notes,
  }) {
    return RestPauseSet(
      initialWeightKg: initialWeightKg ?? this.initialWeightKg,
      initialReps: initialReps ?? this.initialReps,
      pauseSeconds: pauseSeconds ?? this.pauseSeconds,
      backoffReps: backoffReps ?? this.backoffReps,
      backoffSets: backoffSets ?? this.backoffSets,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'RestPause($repBreakdown, ${pauseSeconds}s pauses, '
      '$totalReps total reps)';
}
