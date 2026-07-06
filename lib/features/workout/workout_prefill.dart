import 'package:transformfit/engine/plan_generation.dart';

class WorkoutPlanExercise {
  const WorkoutPlanExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.targetRpe,
    required this.targetRestSeconds,
    this.suggestedWeightKg,
  });

  factory WorkoutPlanExercise.fromPlanExercise(
    PlanExercise exercise, {
    int? suggestedWeightKg,
  }) {
    return WorkoutPlanExercise(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      targetSets: exercise.sets,
      targetReps: exercise.repsMin,
      targetRpe: exercise.rpeTarget,
      targetRestSeconds: exercise.restSeconds,
      suggestedWeightKg: suggestedWeightKg,
    );
  }

  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int targetRpe;
  final int targetRestSeconds;
  final int? suggestedWeightKg;
}

class WorkoutPrefill {
  const WorkoutPrefill({
    required this.exerciseId,
    required this.exerciseName,
    this.targetSets = 1,
    required this.targetReps,
    required this.targetRpe,
    required this.targetRestSeconds,
    this.suggestedWeightKg,
    this.source = 'manual',
    this.sessionExercises = const [],
    this.exerciseIndex = 0,
  });

  factory WorkoutPrefill.fromPlanExercise(
    PlanExercise exercise, {
    int? suggestedWeightKg,
    String source = 'onboarding_session_1',
  }) {
    return WorkoutPrefill(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      targetSets: exercise.sets,
      targetReps: exercise.repsMin,
      targetRpe: exercise.rpeTarget,
      targetRestSeconds: exercise.restSeconds,
      suggestedWeightKg: suggestedWeightKg,
      source: source,
      sessionExercises: [
        WorkoutPlanExercise.fromPlanExercise(
          exercise,
          suggestedWeightKg: suggestedWeightKg,
        ),
      ],
    );
  }

  factory WorkoutPrefill.fromPlanDay(
    PlanDay day, {
    int exerciseIndex = 0,
    String source = 'onboarding_session_1',
  }) {
    final exercises = day.exercises
        .map(WorkoutPlanExercise.fromPlanExercise)
        .toList(growable: false);
    final selectedIndex = exercises.isEmpty
        ? 0
        : exerciseIndex.clamp(0, exercises.length - 1);
    final selected = exercises.isEmpty ? null : exercises[selectedIndex];

    return WorkoutPrefill(
      exerciseId: selected?.exerciseId ?? '',
      exerciseName: selected?.exerciseName ?? '',
      targetSets: selected?.targetSets ?? 1,
      targetReps: selected?.targetReps ?? 1,
      targetRpe: selected?.targetRpe ?? 7,
      targetRestSeconds: selected?.targetRestSeconds ?? 90,
      suggestedWeightKg: selected?.suggestedWeightKg,
      source: source,
      sessionExercises: exercises,
      exerciseIndex: selectedIndex,
    );
  }

  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int targetRpe;
  final int targetRestSeconds;
  final int? suggestedWeightKg;
  final String source;
  final List<WorkoutPlanExercise> sessionExercises;
  final int exerciseIndex;

  WorkoutPlanExercise get selectedExercise {
    if (sessionExercises.isEmpty) {
      return WorkoutPlanExercise(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        targetSets: targetSets,
        targetReps: targetReps,
        targetRpe: targetRpe,
        targetRestSeconds: targetRestSeconds,
        suggestedWeightKg: suggestedWeightKg,
      );
    }
    return sessionExercises[exerciseIndex.clamp(
      0,
      sessionExercises.length - 1,
    )];
  }
}
