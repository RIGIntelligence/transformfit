/// M4: Exercise recommender — injury-aware, equipment-aware, progression chains.
///
/// Pure Dart, deterministic. Used by the AI coach, plan generator, and
/// exercise library screen.
library;

import 'exercise_database.dart';
import 'exercise_model.dart';
import 'exercise_search.dart';

/// Injury type for injury-aware recommendations.
enum InjuryType {
  shoulderPain,
  lowerBackPain,
  kneePain,
  elbowPain,
  wristPain,
  anklePain,
  neckPain,
  hipPain,
}

/// AI-powered exercise recommendations.
class ExerciseRecommender {
  ExerciseRecommender._();

  static final List<Exercise> _all = ExerciseDatabase.exercises;

  // ── Muscle group recommendations ─────────────────────────────────────

  /// Top exercises for a muscle group, sorted by compound-first.
  static List<Exercise> recommendForMuscleGroup(
    MuscleGroup muscle, {
    int limit = 10,
  }) {
    final candidates = ExerciseSearch.filterByMuscleGroup(muscle);
    // Sort: compound first, then by difficulty (beginner → advanced).
    candidates.sort((a, b) {
      if (a.isCompound != b.isCompound) return a.isCompound ? -1 : 1;
      return a.difficulty.index.compareTo(b.difficulty.index);
    });
    return candidates.take(limit).toList(growable: false);
  }

  /// Full workout plan for a muscle group — compounds + isolations.
  static List<Exercise> fullWorkoutForMuscleGroup(
    MuscleGroup muscle, {
    int compoundLimit = 3,
    int isolationLimit = 3,
  }) {
    final compounds = ExerciseSearch.filterByMuscleGroup(muscle)
        .where((e) => e.isCompound)
        .take(compoundLimit)
        .toList();
    final isolations = ExerciseSearch.filterByMuscleGroup(muscle)
        .where((e) => !e.isCompound)
        .take(isolationLimit)
        .toList();
    return [...compounds, ...isolations];
  }

  // ── Equipment-based recommendations ──────────────────────────────────

  /// Exercises available with the given equipment types.
  static List<Exercise> recommendForEquipment(
    List<ExerciseType> availableEquipment, {
    MuscleGroup? targetMuscle,
    int limit = 20,
  }) {
    var candidates = _all
        .where((e) => availableEquipment.contains(e.type))
        .toList();
    if (targetMuscle != null) {
      candidates = candidates
          .where((e) =>
              e.primaryMuscles.contains(targetMuscle) ||
              e.secondaryMuscles.contains(targetMuscle))
          .toList();
    }
    candidates.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
    return candidates.take(limit).toList(growable: false);
  }

  /// Minimal-equipment workout — bodyweight + band only.
  static List<Exercise> minimalEquipmentWorkout({
    MuscleGroup? targetMuscle,
    int limit = 10,
  }) {
    return recommendForEquipment(
      [ExerciseType.bodyweight, ExerciseType.band],
      targetMuscle: targetMuscle,
      limit: limit,
    );
  }

  // ── Injury-aware recommendations ─────────────────────────────────────

  /// Exercises to AVOID for a given injury.
  static List<Exercise> exercisesToAvoid(InjuryType injury) {
    final avoidIds = _injuryAvoidanceMap[injury] ?? [];
    return _all.where((e) => avoidIds.contains(e.id)).toList(growable: false);
  }

  /// Safe exercise alternatives for a given injury + target muscle.
  static List<Exercise> recommendForInjury(
    InjuryType injury,
    MuscleGroup targetMuscle, {
    int limit = 8,
  }) {
    final avoidIds = _injuryAvoidanceMap[injury]?.toSet() ?? {};
    final candidates = ExerciseSearch.filterByMuscleGroup(targetMuscle)
        .where((e) => !avoidIds.contains(e.id))
        .toList();
    // Prefer safer modalities — machines and cables over free weights.
    candidates.sort((a, b) {
      final aSafety = _safetyPriority(a.type, injury);
      final bSafety = _safetyPriority(b.type, injury);
      if (aSafety != bSafety) return aSafety.compareTo(bSafety);
      return a.difficulty.index.compareTo(b.difficulty.index);
    });
    return candidates.take(limit).toList(growable: false);
  }

  /// General safe alternatives for any injury — returns full-body safe list.
  static List<Exercise> safeExercisesForInjury(InjuryType injury) {
    final avoidIds = _injuryAvoidanceMap[injury]?.toSet() ?? {};
    return _all.where((e) => !avoidIds.contains(e.id)).toList(growable: false);
  }

  // ── Progression / Regression chains ──────────────────────────────────

  /// Get the progression (harder version) of an exercise.
  static Exercise? getProgression(String exerciseId) {
    final nextId = _progressionChains[exerciseId];
    if (nextId == null) return null;
    return ExerciseSearch.getById(nextId);
  }

  /// Get the regression (easier version) of an exercise.
  static Exercise? getRegression(String exerciseId) {
    final prevId = _regressionChains[exerciseId];
    if (prevId == null) return null;
    return ExerciseSearch.getById(prevId);
  }

  /// Full progression chain from easiest to hardest for an exercise.
  static List<Exercise> getProgressionChain(String exerciseId) {
    final chain = <Exercise>[];
    // Walk backward to find the root.
    var root = exerciseId;
    while (_regressionChains.containsKey(root)) {
      root = _regressionChains[root]!;
    }
    // Walk forward collecting the chain.
    String? current = root;
    while (current != null) {
      final ex = ExerciseSearch.getById(current);
      if (ex != null) chain.add(ex);
      current = _progressionChains[current];
    }
    return chain;
  }

  /// Get a progression chain for a muscle group pattern (e.g., squat chain).
  static List<Exercise> getProgressionChainForPattern(
    String pattern,
  ) {
    final chainId = _patternChains[pattern];
    if (chainId == null) return [];
    return getProgressionChain(chainId);
  }

  // ── Injury avoidance map ─────────────────────────────────────────────

  static const Map<InjuryType, List<String>> _injuryAvoidanceMap = {
    InjuryType.shoulderPain: [
      'overhead-press',
      'arnold-press',
      'push-press',
      'dip',
      'upright-row',
      'barbell-bench-press',
      'incline-bench-press',
      'dumbbell-fly',
    ],
    InjuryType.lowerBackPain: [
      'barbell-deadlift',
      'barbell-squat',
      'sumo-deadlift',
      'barbell-row',
      'pendlay-row',
      'good-morning',
      'jefferson-curl',
      'zercher-squat',
    ],
    InjuryType.kneePain: [
      'barbell-squat',
      'front-squat',
      'leg-press',
      'hack-squat',
      'sissy-squat',
      'lunge',
      'bulgarian-split-squat',
      'box-jump',
      'squat-jump',
      'pistol-squat',
      'shrimp-squat',
    ],
    InjuryType.elbowPain: [
      'skull-crusher',
      'close-grip-bench-press',
      'preacher-curl',
      'barbell-curl',
      'tricep-pushdown',
      'overhead-tricep-extension',
    ],
    InjuryType.wristPain: [
      'barbell-curl',
      'barbell-bench-press',
      'push-up',
      'front-squat',
      'zercher-squat',
      'turkish-get-up',
    ],
    InjuryType.anklePain: [
      'box-jump',
      'squat-jump',
      'burpee',
      'lunge',
      'bulgarian-split-squat',
      'standing-calf-raise',
      'mountain-climber',
    ],
    InjuryType.neckPain: [
      'overhead-press',
      'push-press',
      'barbell-shrug',
      'upright-row',
      'arnold-press',
    ],
    InjuryType.hipPain: [
      'barbell-squat',
      'front-squat',
      'hip-thrust',
      'pistol-squat',
      'turkish-get-up',
      'lunge',
      'bulgarian-split-squat',
    ],
  };

  /// Lower number = safer for that injury.
  static int _safetyPriority(ExerciseType type, InjuryType injury) {
    // Machines and cables are generally safer — controlled ROM.
    switch (type) {
      case ExerciseType.machine:
        return 0;
      case ExerciseType.cable:
        return 1;
      case ExerciseType.band:
        return 2;
      case ExerciseType.bodyweight:
        return 3;
      case ExerciseType.dumbbell:
        return 4;
      case ExerciseType.kettlebell:
        return 5;
      case ExerciseType.barbell:
        return 6;
      case ExerciseType.cardio:
        return 7;
      case ExerciseType.mobility:
        return 8;
    }
  }

  // ── Progression chains ───────────────────────────────────────────────

  /// Maps exercise id → next harder exercise id.
  static const Map<String, String> _progressionChains = {
    // Push-up chain
    'incline-push-up': 'push-up',
    'push-up': 'decline-push-up',
    'decline-push-up': 'dip',
    'dip': 'weighted-dip',

    // Pull-up chain
    'lat-pulldown': 'chin-up',
    'chin-up': 'pull-up',
    'pull-up': 'weighted-pull-up',
    'weighted-pull-up': 'muscle-up',

    // Squat chain
    'goblet-squat': 'barbell-squat',
    'barbell-squat': 'front-squat',
    'front-squat': 'zercher-squat',
    'pistol-box-squat': 'pistol-squat',
    'pistol-squat': 'shrimp-squat',

    // Hinge chain
    'glute-bridge': 'hip-thrust',
    'hip-thrust': 'romanian-deadlift',
    'romanian-deadlift': 'barbell-deadlift',
    'barbell-deadlift': 'sumo-deadlift',

    // Overhead press chain
    'dumbbell-shoulder-press': 'overhead-press',
    'overhead-press': 'push-press',

    // Lunge chain
    'reverse-lunge': 'lunge',
    'lunge': 'bulgarian-split-squat',

    // Core chain
    'crunch': 'cable-crunch',
    'plank': 'ab-rollout',
    'dead-bug': 'hanging-knee-raise',
    'hanging-knee-raise': 'hanging-leg-raise',
    'hanging-leg-raise': 'toes-to-bar',

    // Lateral raise chain
    'lateral-raise': 'cable-lateral-raise',

    // Bicep chain
    'dumbbell-curl': 'barbell-curl',
    'barbell-curl': 'preacher-curl',

    // Row chain
    'chest-supported-row': 'dumbbell-row',
    'dumbbell-row': 'barbell-row',
    'barbell-row': 'pendlay-row',

    // Calf chain
    'seated-calf-raise': 'standing-calf-raise',

    // Nordic chain
    'leg-curl': 'nordic-hamstring-curl',
  };

  /// Maps exercise id → next easier exercise id (reverse of progression).
  static final Map<String, String> _regressionChains =
      _buildRegressionMap();

  static Map<String, String> _buildRegressionMap() {
    final map = <String, String>{};
    for (final entry in _progressionChains.entries) {
      map[entry.value] = entry.key;
    }
    return map;
  }

  /// Named patterns → root exercise id for getting full chains.
  static const Map<String, String> _patternChains = {
    'push-up': 'incline-push-up',
    'pull-up': 'lat-pulldown',
    'squat': 'goblet-squat',
    'hinge': 'glute-bridge',
    'overhead-press': 'dumbbell-shoulder-press',
    'lunge': 'reverse-lunge',
    'core': 'crunch',
    'row': 'chest-supported-row',
  };
}
