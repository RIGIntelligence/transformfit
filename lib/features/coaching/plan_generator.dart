/// M4: Coach-generated workout plan model and generator.
///
/// Generates structured workout plans based on user goals, experience level,
/// and training preferences. Includes 5 pre-built plans covering common
/// training archetypes.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

import 'package:transformfit/features/exercise_library/exercise_model.dart';

// ── Training Focus ───────────────────────────────────────────────────────

/// Primary training focus for a workout plan.
enum TrainingFocus {
  /// Low reps, heavy loads, long rest. Neural adaptation priority.
  strength,

  /// Moderate reps, moderate loads, moderate rest. Muscle growth priority.
  hypertrophy,

  /// High reps, lighter loads, short rest. Work capacity priority.
  endurance,

  /// Low intensity, range of motion, flexibility. Recovery priority.
  mobility,
}

// ── WorkoutPlan ──────────────────────────────────────────────────────────

/// A single exercise prescription within a plan.
class PlanExercise {
  const PlanExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.targetRpe,
    required this.restSeconds,
    this.notes,
    this.isSuperset = false,
    this.supersetGroupId,
    this.primaryMuscles = const [],
  });

  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int targetRpe;
  final int restSeconds;
  final String? notes;
  final bool isSuperset;
  final String? supersetGroupId;
  final List<MuscleGroup> primaryMuscles;

  Map<String, Object?> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetRpe': targetRpe,
        'restSeconds': restSeconds,
        'notes': notes,
        'isSuperset': isSuperset,
        'supersetGroupId': supersetGroupId,
        'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
      };

  factory PlanExercise.fromJson(Map<String, Object?> json) {
    return PlanExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      targetSets: json['targetSets'] as int,
      targetReps: json['targetReps'] as int,
      targetRpe: json['targetRpe'] as int,
      restSeconds: json['restSeconds'] as int,
      notes: json['notes'] as String?,
      isSuperset: json['isSuperset'] as bool? ?? false,
      supersetGroupId: json['supersetGroupId'] as String?,
      primaryMuscles: (json['primaryMuscles'] as List?)
              ?.map((m) => MuscleGroup.values.byName(m as String))
              .toList() ??
          const [],
    );
  }
}

/// A single day within a workout plan.
class PlanDay {
  const PlanDay({
    required this.dayNumber,
    required this.name,
    required this.exercises,
    this.focus,
    this.notes,
  });

  final int dayNumber;
  final String name;
  final List<PlanExercise> exercises;
  final TrainingFocus? focus;
  final String? notes;

  /// Total working sets for this day.
  int get totalSets =>
      exercises.fold<int>(0, (total, e) => total + e.targetSets);

  /// Estimated duration in minutes.
  int get estimatedDurationMinutes {
    const perSetMinutes = 2.5; // work + rest
    return (totalSets * perSetMinutes).round();
  }

  Map<String, Object?> toJson() => {
        'dayNumber': dayNumber,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'focus': focus?.name,
        'notes': notes,
      };

  factory PlanDay.fromJson(Map<String, Object?> json) {
    return PlanDay(
      dayNumber: json['dayNumber'] as int,
      name: json['name'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => PlanExercise.fromJson(e as Map<String, Object?>))
          .toList(),
      focus: json['focus'] != null
          ? TrainingFocus.values.byName(json['focus'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

/// A complete workout plan.
class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.durationWeeks,
    required this.daysPerWeek,
    required this.days,
    required this.difficulty,
    required this.focus,
    this.targetAudience,
    this.prerequisites = const [],
    this.deloadFrequency = 4,
    this.notes,
  });

  final String id;
  final String name;
  final String description;
  final int durationWeeks;
  final int daysPerWeek;
  final List<PlanDay> days;
  final DifficultyLevel difficulty;
  final TrainingFocus focus;
  final String? targetAudience;
  final List<String> prerequisites;
  final int deloadFrequency;
  final String? notes;

  /// Total working sets per week.
  int get weeklySets =>
      days.fold<int>(0, (total, d) => total + d.totalSets);

  /// Total exercises in the plan.
  int get totalExercises => days.fold<int>(
      0, (total, d) => total + d.exercises.length);

  /// Whether this plan includes superset work.
  bool get hasSupersets =>
      days.any((d) => d.exercises.any((e) => e.isSuperset));

  // ── Serialization ────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'durationWeeks': durationWeeks,
        'daysPerWeek': daysPerWeek,
        'days': days.map((d) => d.toJson()).toList(),
        'difficulty': difficulty.name,
        'focus': focus.name,
        'targetAudience': targetAudience,
        'prerequisites': prerequisites,
        'deloadFrequency': deloadFrequency,
        'notes': notes,
      };

  factory WorkoutPlan.fromJson(Map<String, Object?> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      durationWeeks: json['durationWeeks'] as int,
      daysPerWeek: json['daysPerWeek'] as int,
      days: (json['days'] as List)
          .map((d) => PlanDay.fromJson(d as Map<String, Object?>))
          .toList(),
      difficulty:
          DifficultyLevel.values.byName(json['difficulty'] as String),
      focus: TrainingFocus.values.byName(json['focus'] as String),
      targetAudience: json['targetAudience'] as String?,
      prerequisites: (json['prerequisites'] as List?)
              ?.map((p) => p as String)
              .toList() ??
          const [],
      deloadFrequency: json['deloadFrequency'] as int? ?? 4,
      notes: json['notes'] as String?,
    );
  }

  @override
  String toString() =>
      'WorkoutPlan($name, $daysPerWeek days/week, $durationWeeks weeks, '
      '${difficulty.name}, ${focus.name})';
}

// ── Plan Generator ───────────────────────────────────────────────────────

/// User goals for plan generation.
enum UserGoal {
  /// Lose body fat while preserving muscle.
  fatLoss,

  /// Build muscle mass.
  muscleGain,

  /// Increase maximal strength.
  strengthGain,

  /// Improve general fitness and endurance.
  generalFitness,

  /// Improve flexibility, mobility, and recovery.
  mobilityRecovery,
}

/// Deterministic workout plan generator.
class PlanGenerator {
  const PlanGenerator();

  /// Generate a plan from user goals.
  ///
  /// Maps goals to the most appropriate pre-built plan.
  WorkoutPlan generateFromGoals({
    required UserGoal goal,
    required DifficultyLevel level,
    int daysPerWeek = 4,
  }) {
    switch (goal) {
      case UserGoal.fatLoss:
        // Hypertrophy focus with higher volume for calorie burn.
        return _buildFatLossPlan(level: level, daysPerWeek: daysPerWeek);
      case UserGoal.muscleGain:
        return _buildHypertrophyPlan(level: level, daysPerWeek: daysPerWeek);
      case UserGoal.strengthGain:
        return _buildStrengthPlan(level: level, daysPerWeek: daysPerWeek);
      case UserGoal.generalFitness:
        return _buildGeneralFitnessPlan(
            level: level, daysPerWeek: daysPerWeek);
      case UserGoal.mobilityRecovery:
        return PreBuiltPlans.mobilityRecovery;
    }
  }

  /// Generate a plan from experience level.
  ///
  /// Selects the appropriate pre-built plan based on training age.
  WorkoutPlan generateFromLevel({
    required DifficultyLevel level,
    int daysPerWeek = 3,
  }) {
    switch (level) {
      case DifficultyLevel.beginner:
        return PreBuiltPlans.beginnerFullBody;
      case DifficultyLevel.intermediate:
        return daysPerWeek >= 4
            ? PreBuiltPlans.intermediateUpperLower
            : PreBuiltPlans.beginnerFullBody;
      case DifficultyLevel.advanced:
        return daysPerWeek >= 5
            ? PreBuiltPlans.advancedPPL
            : PreBuiltPlans.intermediateUpperLower;
    }
  }

  /// Get the recommended plan based on level and available days.
  WorkoutPlan getRecommendedPlan({
    required DifficultyLevel level,
    required int daysPerWeek,
    required UserGoal goal,
  }) {
    if (level == DifficultyLevel.beginner || daysPerWeek <= 3) {
      return PreBuiltPlans.beginnerFullBody;
    }
    if (level == DifficultyLevel.advanced && daysPerWeek >= 5) {
      return goal == UserGoal.strengthGain
          ? PreBuiltPlans.strengthFocus
          : PreBuiltPlans.advancedPPL;
    }
    return PreBuiltPlans.intermediateUpperLower;
  }

  // ── Internal Builders ─────────────────────────────────────────────────

  WorkoutPlan _buildFatLossPlan({
    required DifficultyLevel level,
    required int daysPerWeek,
  }) {
    // Fat loss: moderate volume, superset-heavy for time efficiency.
    final base = level == DifficultyLevel.beginner
        ? PreBuiltPlans.beginnerFullBody
        : PreBuiltPlans.intermediateUpperLower;
    return WorkoutPlan(
      id: 'generated-fat-loss-${level.name}',
      name: 'Fat Loss Focus',
      description: 'Moderate volume with superset emphasis for metabolic '
          'demand. Pair antagonist movements to maximize calorie burn '
          'while preserving muscle.',
      durationWeeks: 8,
      daysPerWeek: daysPerWeek,
      days: base.days,
      difficulty: level,
      focus: TrainingFocus.hypertrophy,
      targetAudience: 'Users in a caloric deficit looking to preserve muscle.',
      deloadFrequency: 4,
    );
  }

  WorkoutPlan _buildHypertrophyPlan({
    required DifficultyLevel level,
    required int daysPerWeek,
  }) {
    final base = level == DifficultyLevel.advanced
        ? PreBuiltPlans.advancedPPL
        : PreBuiltPlans.intermediateUpperLower;
    return WorkoutPlan(
      id: 'generated-hypertrophy-${level.name}',
      name: 'Hypertrophy Focus',
      description: 'Moderate reps (8-12), controlled tempo, progressive '
          'overload. Designed for maximum muscle growth stimulus.',
      durationWeeks: 10,
      daysPerWeek: daysPerWeek,
      days: base.days,
      difficulty: level,
      focus: TrainingFocus.hypertrophy,
      targetAudience: 'Users focused on building muscle mass.',
      deloadFrequency: 4,
    );
  }

  WorkoutPlan _buildStrengthPlan({
    required DifficultyLevel level,
    required int daysPerWeek,
  }) {
    return PreBuiltPlans.strengthFocus;
  }

  WorkoutPlan _buildGeneralFitnessPlan({
    required DifficultyLevel level,
    required int daysPerWeek,
  }) {
    return PreBuiltPlans.beginnerFullBody;
  }
}

// ── Pre-Built Plans ──────────────────────────────────────────────────────

/// 5 pre-built workout plans covering common training archetypes.
class PreBuiltPlans {
  PreBuiltPlans._();

  // ── 1. Beginner Full Body ──────────────────────────────────────────────

  static final beginnerFullBody = WorkoutPlan(
    id: 'plan-beginner-full-body',
    name: 'Beginner Full Body',
    description: '3 days/week, full body each session. Compound-focused '
        'with linear progression. Ideal for the first 6-12 months of '
        'training. Each session hits all major muscle groups with '
        '2-3 exercises per pattern.',
    durationWeeks: 8,
    daysPerWeek: 3,
    difficulty: DifficultyLevel.beginner,
    focus: TrainingFocus.strength,
    targetAudience: 'New lifters (< 1 year experience)',
    deloadFrequency: 4,
    days: [
      const PlanDay(
        dayNumber: 1,
        name: 'Full Body A — Squat Focus',
        exercises: [
          PlanExercise(
            exerciseId: 'squat',
            exerciseName: 'Barbell Squat',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
            notes: 'Start with the bar if needed. Add 2.5kg per session.',
          ),
          PlanExercise(
            exerciseId: 'barbell-bench-press',
            exerciseName: 'Barbell Bench Press',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.chest],
          ),
          PlanExercise(
            exerciseId: 'barbell-row',
            exerciseName: 'Barbell Row',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.back, MuscleGroup.lats],
          ),
          PlanExercise(
            exerciseId: 'overhead-press',
            exerciseName: 'Dumbbell Overhead Press',
            targetSets: 2,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'plank',
            exerciseName: 'Front Plank',
            targetSets: 3,
            targetReps: 1,
            targetRpe: 6,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.core],
            notes: 'Hold for 30-60 seconds per set.',
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 2,
        name: 'Full Body B — Hinge Focus',
        exercises: [
          PlanExercise(
            exerciseId: 'deadlift',
            exerciseName: 'Conventional Deadlift',
            targetSets: 3,
            targetReps: 5,
            targetRpe: 7,
            restSeconds: 150,
            primaryMuscles: [
              MuscleGroup.back,
              MuscleGroup.hamstrings,
              MuscleGroup.glutes,
            ],
            notes: 'Focus on hip hinge pattern. Start light.',
          ),
          PlanExercise(
            exerciseId: 'dumbbell-bench-press',
            exerciseName: 'Dumbbell Bench Press',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.chest],
          ),
          PlanExercise(
            exerciseId: 'lat-pulldown',
            exerciseName: 'Lat Pulldown',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.lats, MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'leg-press',
            exerciseName: 'Leg Press',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
          ),
          PlanExercise(
            exerciseId: 'barbell-curl',
            exerciseName: 'Barbell Curl',
            targetSets: 2,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.biceps],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 3,
        name: 'Full Body C — Volume Focus',
        exercises: [
          PlanExercise(
            exerciseId: 'front-squat',
            exerciseName: 'Goblet Squat',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.core],
          ),
          PlanExercise(
            exerciseId: 'overhead-press',
            exerciseName: 'Overhead Press',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'pull-up',
            exerciseName: 'Assisted Pull-Up or Lat Pulldown',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.lats, MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'romanian-deadlift',
            exerciseName: 'Romanian Deadlift',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
          ),
          PlanExercise(
            exerciseId: 'cable-crunch',
            exerciseName: 'Cable Crunch',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.core],
          ),
        ],
      ),
    ],
  );

  // ── 2. Intermediate Upper/Lower ────────────────────────────────────────

  static final intermediateUpperLower = WorkoutPlan(
    id: 'plan-intermediate-upper-lower',
    name: 'Intermediate Upper/Lower',
    description: '4 days/week alternating upper and lower body. Allows '
        'higher volume per muscle group while maintaining 2x frequency. '
        'Uses compound movements with targeted accessories.',
    durationWeeks: 10,
    daysPerWeek: 4,
    difficulty: DifficultyLevel.intermediate,
    focus: TrainingFocus.hypertrophy,
    targetAudience: 'Lifters with 1-2 years of consistent training.',
    deloadFrequency: 4,
    days: [
      const PlanDay(
        dayNumber: 1,
        name: 'Upper A — Horizontal Push/Pull',
        focus: TrainingFocus.hypertrophy,
        exercises: [
          PlanExercise(
            exerciseId: 'barbell-bench-press',
            exerciseName: 'Barbell Bench Press',
            targetSets: 4,
            targetReps: 8,
            targetRpe: 8,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.chest],
          ),
          PlanExercise(
            exerciseId: 'barbell-row',
            exerciseName: 'Barbell Row',
            targetSets: 4,
            targetReps: 8,
            targetRpe: 8,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.back, MuscleGroup.lats],
          ),
          PlanExercise(
            exerciseId: 'incline-bench-press',
            exerciseName: 'Incline Dumbbell Press',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.chest, MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'lat-pulldown',
            exerciseName: 'Cable Row',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'lateral-raise',
            exerciseName: 'Lateral Raise',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'barbell-curl',
            exerciseName: 'Barbell Curl',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.biceps],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 2,
        name: 'Lower A — Quad Focus',
        focus: TrainingFocus.hypertrophy,
        exercises: [
          PlanExercise(
            exerciseId: 'squat',
            exerciseName: 'Barbell Squat',
            targetSets: 4,
            targetReps: 6,
            targetRpe: 8,
            restSeconds: 150,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
          ),
          PlanExercise(
            exerciseId: 'leg-press',
            exerciseName: 'Leg Press',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
          ),
          PlanExercise(
            exerciseId: 'leg-curl',
            exerciseName: 'Leg Curl',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.hamstrings],
          ),
          PlanExercise(
            exerciseId: 'calf-raise',
            exerciseName: 'Calf Raise',
            targetSets: 4,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.calves],
          ),
          PlanExercise(
            exerciseId: 'plank',
            exerciseName: 'Hanging Leg Raise',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.core],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 3,
        name: 'Upper B — Vertical Push/Pull',
        focus: TrainingFocus.hypertrophy,
        exercises: [
          PlanExercise(
            exerciseId: 'overhead-press',
            exerciseName: 'Overhead Press',
            targetSets: 4,
            targetReps: 8,
            targetRpe: 8,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'pull-up',
            exerciseName: 'Pull-Up',
            targetSets: 4,
            targetReps: 8,
            targetRpe: 8,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.lats, MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'dumbbell-bench-press',
            exerciseName: 'Dumbbell Bench Press',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.chest],
          ),
          PlanExercise(
            exerciseId: 'face-pull',
            exerciseName: 'Face Pull',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 6,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.rearDelts, MuscleGroup.traps],
          ),
          PlanExercise(
            exerciseId: 'tricep-pushdown',
            exerciseName: 'Tricep Pushdown',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.triceps],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 4,
        name: 'Lower B — Hinge Focus',
        focus: TrainingFocus.hypertrophy,
        exercises: [
          PlanExercise(
            exerciseId: 'romanian-deadlift',
            exerciseName: 'Romanian Deadlift',
            targetSets: 4,
            targetReps: 8,
            targetRpe: 8,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
          ),
          PlanExercise(
            exerciseId: 'squat',
            exerciseName: 'Front Squat',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.quads],
          ),
          PlanExercise(
            exerciseId: 'leg-curl',
            exerciseName: 'Nordic Hamstring Curl',
            targetSets: 3,
            targetReps: 6,
            targetRpe: 8,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.hamstrings],
            notes: 'Use assistance if needed. Control the eccentric.',
          ),
          PlanExercise(
            exerciseId: 'calf-raise',
            exerciseName: 'Seated Calf Raise',
            targetSets: 4,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.calves],
          ),
          PlanExercise(
            exerciseId: 'cable-crunch',
            exerciseName: 'Ab Wheel Rollout',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.core],
          ),
        ],
      ),
    ],
  );

  // ── 3. Advanced PPL ────────────────────────────────────────────────────

  static final advancedPPL = WorkoutPlan(
    id: 'plan-advanced-ppl',
    name: 'Advanced Push/Pull/Legs',
    description: '6 days/week (PPL repeat). High volume, high frequency. '
        'Each muscle group hit 2x/week with progressive overload. '
        'Requires 2+ years of consistent training.',
    durationWeeks: 12,
    daysPerWeek: 6,
    difficulty: DifficultyLevel.advanced,
    focus: TrainingFocus.hypertrophy,
    targetAudience: 'Advanced lifters with high work capacity.',
    deloadFrequency: 4,
    days: [
      const PlanDay(
        dayNumber: 1,
        name: 'Push A — Heavy',
        focus: TrainingFocus.strength,
        exercises: [
          PlanExercise(
            exerciseId: 'barbell-bench-press',
            exerciseName: 'Barbell Bench Press',
            targetSets: 4,
            targetReps: 5,
            targetRpe: 8,
            restSeconds: 150,
            primaryMuscles: [MuscleGroup.chest],
          ),
          PlanExercise(
            exerciseId: 'overhead-press',
            exerciseName: 'Overhead Press',
            targetSets: 4,
            targetReps: 6,
            targetRpe: 8,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'incline-bench-press',
            exerciseName: 'Incline Dumbbell Press',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.chest, MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'lateral-raise',
            exerciseName: 'Lateral Raise',
            targetSets: 4,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'tricep-pushdown',
            exerciseName: 'Tricep Pushdown',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.triceps],
          ),
          PlanExercise(
            exerciseId: 'skull-crusher',
            exerciseName: 'Overhead Tricep Extension',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.triceps],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 2,
        name: 'Pull A — Heavy',
        focus: TrainingFocus.strength,
        exercises: [
          PlanExercise(
            exerciseId: 'deadlift',
            exerciseName: 'Conventional Deadlift',
            targetSets: 4,
            targetReps: 5,
            targetRpe: 8,
            restSeconds: 180,
            primaryMuscles: [
              MuscleGroup.back,
              MuscleGroup.hamstrings,
              MuscleGroup.glutes,
            ],
          ),
          PlanExercise(
            exerciseId: 'pull-up',
            exerciseName: 'Weighted Pull-Up',
            targetSets: 4,
            targetReps: 6,
            targetRpe: 8,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.lats, MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'barbell-row',
            exerciseName: 'Barbell Row',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'face-pull',
            exerciseName: 'Face Pull',
            targetSets: 4,
            targetReps: 15,
            targetRpe: 6,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.rearDelts, MuscleGroup.traps],
          ),
          PlanExercise(
            exerciseId: 'barbell-curl',
            exerciseName: 'Barbell Curl',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.biceps],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 3,
        name: 'Legs A — Heavy',
        focus: TrainingFocus.strength,
        exercises: [
          PlanExercise(
            exerciseId: 'squat',
            exerciseName: 'Barbell Squat',
            targetSets: 4,
            targetReps: 5,
            targetRpe: 8,
            restSeconds: 180,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
          ),
          PlanExercise(
            exerciseId: 'romanian-deadlift',
            exerciseName: 'Romanian Deadlift',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
          ),
          PlanExercise(
            exerciseId: 'leg-press',
            exerciseName: 'Leg Press',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.quads],
          ),
          PlanExercise(
            exerciseId: 'leg-curl',
            exerciseName: 'Leg Curl',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.hamstrings],
          ),
          PlanExercise(
            exerciseId: 'calf-raise',
            exerciseName: 'Calf Raise',
            targetSets: 4,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.calves],
          ),
          PlanExercise(
            exerciseId: 'plank',
            exerciseName: 'Cable Crunch',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.core],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 4,
        name: 'Push B — Volume',
        focus: TrainingFocus.hypertrophy,
        exercises: [
          PlanExercise(
            exerciseId: 'dumbbell-bench-press',
            exerciseName: 'Dumbbell Bench Press',
            targetSets: 4,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.chest],
          ),
          PlanExercise(
            exerciseId: 'overhead-press',
            exerciseName: 'Seated Dumbbell Press',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'decline-bench-press',
            exerciseName: 'Cable Fly',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.chest],
          ),
          PlanExercise(
            exerciseId: 'lateral-raise',
            exerciseName: 'Lateral Raise',
            targetSets: 4,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'skull-crusher',
            exerciseName: 'Skull Crusher',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.triceps],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 5,
        name: 'Pull B — Volume',
        focus: TrainingFocus.hypertrophy,
        exercises: [
          PlanExercise(
            exerciseId: 'lat-pulldown',
            exerciseName: 'Lat Pulldown',
            targetSets: 4,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.lats],
          ),
          PlanExercise(
            exerciseId: 'barbell-row',
            exerciseName: 'Seated Cable Row',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'face-pull',
            exerciseName: 'Face Pull',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 6,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.rearDelts],
          ),
          PlanExercise(
            exerciseId: 'barbell-curl',
            exerciseName: 'Incline Dumbbell Curl',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.biceps],
          ),
          PlanExercise(
            exerciseId: 'shrug',
            exerciseName: 'Shrug',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.traps],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 6,
        name: 'Legs B — Volume',
        focus: TrainingFocus.hypertrophy,
        exercises: [
          PlanExercise(
            exerciseId: 'front-squat',
            exerciseName: 'Front Squat',
            targetSets: 4,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.quads],
          ),
          PlanExercise(
            exerciseId: 'leg-press',
            exerciseName: 'Leg Press',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
          ),
          PlanExercise(
            exerciseId: 'leg-curl',
            exerciseName: 'Leg Curl',
            targetSets: 4,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.hamstrings],
          ),
          PlanExercise(
            exerciseId: 'calf-raise',
            exerciseName: 'Calf Raise',
            targetSets: 4,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.calves],
          ),
          PlanExercise(
            exerciseId: 'plank',
            exerciseName: 'Hanging Leg Raise',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.core],
          ),
        ],
      ),
    ],
  );

  // ── 4. Strength Focus ──────────────────────────────────────────────────

  static final strengthFocus = WorkoutPlan(
    id: 'plan-strength-focus',
    name: 'Strength Focus',
    description: '4 days/week. Low reps (3-6), heavy loads, long rest. '
        'Built around the squat, bench, deadlift, and overhead press. '
        'Linear periodization with weekly progression targets.',
    durationWeeks: 12,
    daysPerWeek: 4,
    difficulty: DifficultyLevel.intermediate,
    focus: TrainingFocus.strength,
    targetAudience: 'Lifters focused on maximal strength in the big 4.',
    deloadFrequency: 3,
    days: [
      const PlanDay(
        dayNumber: 1,
        name: 'Squat & Bench',
        focus: TrainingFocus.strength,
        exercises: [
          PlanExercise(
            exerciseId: 'squat',
            exerciseName: 'Barbell Squat',
            targetSets: 5,
            targetReps: 5,
            targetRpe: 8,
            restSeconds: 180,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
            notes: 'Add 2.5kg per week if all sets completed.',
          ),
          PlanExercise(
            exerciseId: 'barbell-bench-press',
            exerciseName: 'Barbell Bench Press',
            targetSets: 5,
            targetReps: 5,
            targetRpe: 8,
            restSeconds: 180,
            primaryMuscles: [MuscleGroup.chest],
            notes: 'Add 2.5kg per week if all sets completed.',
          ),
          PlanExercise(
            exerciseId: 'barbell-row',
            exerciseName: 'Barbell Row',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'plank',
            exerciseName: 'Front Plank',
            targetSets: 3,
            targetReps: 1,
            targetRpe: 6,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.core],
            notes: 'Hold 60 seconds per set.',
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 2,
        name: 'Deadlift & Press',
        focus: TrainingFocus.strength,
        exercises: [
          PlanExercise(
            exerciseId: 'deadlift',
            exerciseName: 'Conventional Deadlift',
            targetSets: 5,
            targetReps: 3,
            targetRpe: 8,
            restSeconds: 240,
            primaryMuscles: [
              MuscleGroup.back,
              MuscleGroup.hamstrings,
              MuscleGroup.glutes,
            ],
            notes: 'Add 2.5kg per week. Singles at RPE 9 on week 6+.',
          ),
          PlanExercise(
            exerciseId: 'overhead-press',
            exerciseName: 'Overhead Press',
            targetSets: 5,
            targetReps: 5,
            targetRpe: 8,
            restSeconds: 180,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'pull-up',
            exerciseName: 'Weighted Pull-Up',
            targetSets: 3,
            targetReps: 6,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.lats, MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'barbell-curl',
            exerciseName: 'Barbell Curl',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 6,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.biceps],
            notes: 'Elbow prehab. Light weight, controlled reps.',
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 3,
        name: 'Squat & Bench — Volume',
        focus: TrainingFocus.hypertrophy,
        exercises: [
          PlanExercise(
            exerciseId: 'front-squat',
            exerciseName: 'Front Squat',
            targetSets: 3,
            targetReps: 6,
            targetRpe: 7,
            restSeconds: 150,
            primaryMuscles: [MuscleGroup.quads],
          ),
          PlanExercise(
            exerciseId: 'incline-bench-press',
            exerciseName: 'Incline Bench Press',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.chest, MuscleGroup.shoulders],
          ),
          PlanExercise(
            exerciseId: 'leg-curl',
            exerciseName: 'Leg Curl',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.hamstrings],
          ),
          PlanExercise(
            exerciseId: 'lateral-raise',
            exerciseName: 'Lateral Raise',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.shoulders],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 4,
        name: 'Deadlift & Press — Volume',
        focus: TrainingFocus.hypertrophy,
        exercises: [
          PlanExercise(
            exerciseId: 'romanian-deadlift',
            exerciseName: 'Romanian Deadlift',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
          ),
          PlanExercise(
            exerciseId: 'dumbbell-bench-press',
            exerciseName: 'Dumbbell Bench Press',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            restSeconds: 90,
            primaryMuscles: [MuscleGroup.chest],
          ),
          PlanExercise(
            exerciseId: 'barbell-row',
            exerciseName: 'Pendlay Row',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            restSeconds: 120,
            primaryMuscles: [MuscleGroup.back],
          ),
          PlanExercise(
            exerciseId: 'calf-raise',
            exerciseName: 'Calf Raise',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 7,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.calves],
          ),
        ],
      ),
    ],
  );

  // ── 5. Mobility & Recovery ─────────────────────────────────────────────

  static final mobilityRecovery = WorkoutPlan(
    id: 'plan-mobility-recovery',
    name: 'Mobility & Recovery',
    description: '3 days/week. Low intensity, full range of motion, '
        'flexibility focus. Ideal for active recovery weeks, deload '
        'periods, or as a standalone program for mobility improvement.',
    durationWeeks: 6,
    daysPerWeek: 3,
    difficulty: DifficultyLevel.beginner,
    focus: TrainingFocus.mobility,
    targetAudience: 'Anyone needing recovery work, injury rehab, or '
        'flexibility improvement.',
    deloadFrequency: 0, // This IS the deload.
    notes: 'Keep RPE below 6 at all times. This is recovery, not training.',
    days: [
      const PlanDay(
        dayNumber: 1,
        name: 'Upper Body Mobility',
        focus: TrainingFocus.mobility,
        exercises: [
          PlanExercise(
            exerciseId: 'dead-hang',
            exerciseName: 'Dead Hang',
            targetSets: 3,
            targetReps: 1,
            targetRpe: 5,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.forearms, MuscleGroup.back],
            notes: 'Hold 30-45 seconds. Decompress the spine.',
          ),
          PlanExercise(
            exerciseId: 'face-pull',
            exerciseName: 'Band Pull-Apart',
            targetSets: 3,
            targetReps: 20,
            targetRpe: 4,
            restSeconds: 45,
            primaryMuscles: [MuscleGroup.rearDelts, MuscleGroup.traps],
            notes: 'Light band. Focus on scapular retraction.',
          ),
          PlanExercise(
            exerciseId: 'shoulder-rotation',
            exerciseName: 'Shoulder Dislocations',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 3,
            restSeconds: 45,
            primaryMuscles: [MuscleGroup.shoulders],
            notes: 'Use a PVC pipe or light band. Go slow.',
          ),
          PlanExercise(
            exerciseId: 'thoracic-rotation',
            exerciseName: 'Thoracic Rotation',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 3,
            restSeconds: 45,
            primaryMuscles: [MuscleGroup.core],
          ),
          PlanExercise(
            exerciseId: 'cat-cow',
            exerciseName: 'Cat-Cow Stretch',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 2,
            restSeconds: 30,
            primaryMuscles: [MuscleGroup.core, MuscleGroup.back],
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 2,
        name: 'Lower Body Mobility',
        focus: TrainingFocus.mobility,
        exercises: [
          PlanExercise(
            exerciseId: 'hip-90-90',
            exerciseName: '90/90 Hip Stretch',
            targetSets: 3,
            targetReps: 1,
            targetRpe: 3,
            restSeconds: 30,
            primaryMuscles: [MuscleGroup.hipFlexors, MuscleGroup.glutes],
            notes: 'Hold 45-60 seconds per side.',
          ),
          PlanExercise(
            exerciseId: 'world-greatest-stretch',
            exerciseName: 'World\'s Greatest Stretch',
            targetSets: 3,
            targetReps: 5,
            targetRpe: 3,
            restSeconds: 30,
            primaryMuscles: [
              MuscleGroup.hipFlexors,
              MuscleGroup.quads,
              MuscleGroup.shoulders,
            ],
          ),
          PlanExercise(
            exerciseId: 'deep-squat-hold',
            exerciseName: 'Deep Squat Hold',
            targetSets: 3,
            targetReps: 1,
            targetRpe: 4,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.hipFlexors],
            notes: 'Hold 30-60 seconds. Use support if needed.',
          ),
          PlanExercise(
            exerciseId: 'hip-flexor-stretch',
            exerciseName: 'Half-Kneeling Hip Flexor Stretch',
            targetSets: 3,
            targetReps: 1,
            targetRpe: 3,
            restSeconds: 30,
            primaryMuscles: [MuscleGroup.hipFlexors],
            notes: 'Hold 45 seconds per side. Squeeze glute on stretch side.',
          ),
          PlanExercise(
            exerciseId: 'calf-stretch',
            exerciseName: 'Calf Stretch',
            targetSets: 3,
            targetReps: 1,
            targetRpe: 2,
            restSeconds: 30,
            primaryMuscles: [MuscleGroup.calves],
            notes: 'Hold 30 seconds per side.',
          ),
        ],
      ),
      const PlanDay(
        dayNumber: 3,
        name: 'Full Body Flow',
        focus: TrainingFocus.mobility,
        exercises: [
          PlanExercise(
            exerciseId: 'plank',
            exerciseName: 'Front Plank',
            targetSets: 3,
            targetReps: 1,
            targetRpe: 5,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.core],
            notes: 'Hold 30-45 seconds. Focus on breathing.',
          ),
          PlanExercise(
            exerciseId: 'glute-bridge',
            exerciseName: 'Glute Bridge',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 4,
            restSeconds: 45,
            primaryMuscles: [MuscleGroup.glutes],
            notes: 'Squeeze at top for 2 seconds.',
          ),
          PlanExercise(
            exerciseId: 'bird-dog',
            exerciseName: 'Bird Dog',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 3,
            restSeconds: 30,
            primaryMuscles: [MuscleGroup.core, MuscleGroup.back],
            notes: 'Slow and controlled. No rotation.',
          ),
          PlanExercise(
            exerciseId: 'dead-hang',
            exerciseName: 'Dead Hang',
            targetSets: 2,
            targetReps: 1,
            targetRpe: 5,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.forearms, MuscleGroup.back],
            notes: 'Hold as long as comfortable up to 60 seconds.',
          ),
          PlanExercise(
            exerciseId: 'deep-squat-hold',
            exerciseName: 'Deep Squat Hold',
            targetSets: 2,
            targetReps: 1,
            targetRpe: 3,
            restSeconds: 60,
            primaryMuscles: [MuscleGroup.quads, MuscleGroup.hipFlexors],
            notes: 'Hold 60 seconds. Breathe into the hips.',
          ),
        ],
      ),
    ],
  );

  /// All 5 pre-built plans.
  static final List<WorkoutPlan> all = [
    beginnerFullBody,
    intermediateUpperLower,
    advancedPPL,
    strengthFocus,
    mobilityRecovery,
  ];
}
