import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/exercise_library/exercise_model.dart';
import 'package:transformfit/features/exercise_library/exercise_database.dart';
import 'package:transformfit/features/exercise_library/exercise_search.dart';
import 'package:transformfit/features/exercise_library/exercise_recommender.dart';

void main() {
  test('exercise count >= 100', () {
    expect(ExerciseDatabase.exercises.length, greaterThanOrEqualTo(100));
  });

  test('exercise count == 114', () {
    expect(ExerciseDatabase.exercises.length, 114);
  });

  test('all muscle groups covered', () {
    final all = ExerciseDatabase.exercises;
    for (final mg in MuscleGroup.values) {
      final covered = all.any((e) =>
          e.primaryMuscles.contains(mg) || e.secondaryMuscles.contains(mg));
      expect(covered, true, reason: '${mg.name} not covered');
    }
  });

  test('all exercise types represented', () {
    final all = ExerciseDatabase.exercises;
    for (final et in ExerciseType.values) {
      final covered = all.any((e) => e.type == et);
      expect(covered, true, reason: '${et.name} not represented');
    }
  });

  test('JSON roundtrip', () {
    final squat = ExerciseSearch.getById('barbell-squat')!;
    expect(squat.name, 'Barbell Back Squat');
    final json = squat.toJson();
    final restored = Exercise.fromJson(json);
    expect(restored.id, squat.id);
    expect(restored.name, squat.name);
    expect(restored.type, squat.type);
    expect(restored.isCompound, squat.isCompound);
    expect(restored.primaryMuscles.length, squat.primaryMuscles.length);
  });

  test('search by name', () {
    final results = ExerciseSearch.searchByName('bench press');
    expect(results, isNotEmpty);
    expect(results.first.id, contains('bench-press'));
  });

  test('fuzzy search', () {
    final results = ExerciseSearch.searchByName('deadlft');
    expect(results.any((e) => e.id.contains('deadlift')), true);
  });

  test('search nonsense returns empty', () {
    final results = ExerciseSearch.searchByName('zzzznonexistent');
    expect(results, isEmpty);
  });

  test('filter by muscle group', () {
    final chest = ExerciseSearch.filterByMuscleGroup(MuscleGroup.chest);
    expect(chest, isNotEmpty);
    expect(chest.every((e) =>
        e.primaryMuscles.contains(MuscleGroup.chest) ||
        e.secondaryMuscles.contains(MuscleGroup.chest)), true);
  });

  test('getCompoundExercises', () {
    final compounds = ExerciseSearch.getCompoundExercises();
    expect(compounds, isNotEmpty);
    expect(compounds.every((e) => e.isCompound), true);
  });

  test('getIsolationExercises', () {
    final isolations = ExerciseSearch.getIsolationExercises();
    expect(isolations, isNotEmpty);
    expect(isolations.every((e) => !e.isCompound), true);
  });

  test('recommendForMuscleGroup compound-first', () {
    final recs = ExerciseRecommender.recommendForMuscleGroup(MuscleGroup.chest);
    expect(recs, isNotEmpty);
    expect(recs.first.isCompound, true);
  });

  test('minimalEquipmentWorkout', () {
    final workout = ExerciseRecommender.minimalEquipmentWorkout();
    expect(workout, isNotEmpty);
  });

  test('injury-aware: shoulder avoids bench press', () {
    final safe = ExerciseRecommender.recommendForInjury(
        InjuryType.shoulderPain, MuscleGroup.chest);
    expect(safe, isNotEmpty);
    expect(safe.every((e) => e.id != 'barbell-bench-press'), true);
  });

  test('exercisesToAvoid knee pain', () {
    final avoid = ExerciseRecommender.exercisesToAvoid(InjuryType.kneePain);
    expect(avoid, isNotEmpty);
  });

  test('progression chain push-up', () {
    final prog = ExerciseRecommender.getProgression('push-up');
    expect(prog?.id, 'decline-push-up');
    final reg = ExerciseRecommender.getRegression('push-up');
    expect(reg?.id, 'incline-push-up');
    final chain = ExerciseRecommender.getProgressionChain('push-up');
    expect(chain.length, greaterThanOrEqualTo(4));
    expect(chain.first.id, 'incline-push-up');
  });

  test('random is deterministic', () {
    final r1 = ExerciseSearch.getRandomExercise(seed: 'test42');
    final r2 = ExerciseSearch.getRandomExercise(seed: 'test42');
    expect(r1.id, r2.id);
  });
}
