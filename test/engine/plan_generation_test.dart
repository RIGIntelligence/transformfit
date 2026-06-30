// RED-then-GREEN unit tests for the Dart plan-generation engine.
// Run: flutter test test/engine/plan_generation_test.dart
//
// Spec under test: lib/engine/plan_generation.dart (single source of truth,
// deterministic training-plan generator, VAL-ONB-056/057).
//
// Determinism contract: identical [PlanIntake] always produces an identical
// [GeneratedPlan] (same exercises, sets, reps, rpe_target, rest, sort order).
// Bodyweight / no-equipment intake yields a non-empty plan with NO ["full_gym"]
// fallback. Contraindicated exercises are excluded.

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/plan_generation.dart';

GeneratedPlan _gen(PlanIntake i) => generatePlan(i);

/// Serialize to a stable JSON shape for equality checks.
Map<String, Object?> _json(GeneratedPlan p) => p.toJson();

void main() {
  group('generatePlan: determinism (VAL-ONB-056)', () {
    test('identical intake -> identical plan (byte-equal JSON)', () {
      const intake = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells', 'pull_up_bar'],
        experienceLevel: 'intermediate',
      );
      final a = _gen(intake);
      final b = _gen(intake);
      expect(_json(b), equals(_json(a)));
    });

    test('three repeated runs agree (invariant over run count, red-then-green)', () {
      const intake = PlanIntake(
        goal: 'lose_fat',
        trainingDaysPerWeek: 4,
        equipment: ['kettlebells'],
        experienceLevel: 'beginner',
        limitations: ['knee'],
      );
      final r1 = _json(_gen(intake));
      final r2 = _json(_gen(intake));
      final r3 = _json(_gen(intake));
      expect(r2, equals(r1));
      expect(r3, equals(r1));
    });

    test('deterministic sort order of exercises within a day', () {
      const intake = PlanIntake(
        goal: 'get_fitter',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells', 'pull_up_bar'],
      );
      final p = _gen(intake);
      expect(p.days, hasLength(3));
      for (final d in p.days) {
        // sortOrder must be 0-based and strictly increasing per day.
        for (int i = 0; i < d.exercises.length; i++) {
          expect(d.exercises[i].sortOrder, equals(i));
        }
        // Exercise ids are unique within a day (round-robin dedup).
        final ids = d.exercises.map((e) => e.id).toList();
        expect(ids.toSet().length, equals(ids.length));
      }
    });
  });

  group('equipment filter (VAL-ONB-026, VAL-ONB-057)', () {
    test('plan uses ONLY selected-equipment + bodyweight movements; never full_gym', () {
      const intake = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
      );
      final p = _gen(intake);
      final eq = <String>{'bodyweight', ...intake.equipment};
      for (final d in p.days) {
        for (final e in d.exercises) {
          expect(eq.contains(e.equipment), isTrue,
              reason: '${e.id} needs ${e.equipment}, not in $eq');
        }
      }
    });

    test('no-equipment intake -> non-empty plan of bodyweight-only exercises (no full_gym fallback)', () {
      const intake = PlanIntake(
        goal: 'get_fitter',
        trainingDaysPerWeek: 3,
        equipment: <String>[],
        experienceLevel: 'beginner',
      );
      final p = _gen(intake);
      expect(p.days, hasLength(3));
      int total = 0;
      for (final d in p.days) {
        expect(d.exercises, isNotEmpty);
        total += d.exercises.length;
        for (final e in d.exercises) {
          expect(e.equipment, equals('bodyweight'),
              reason:
                  'bodyweight-only intake must NOT fall back to equipment-dependent "${e.id}"');
        }
      }
      expect(total, greaterThan(0));
    });

    test('effectiveEquipment always includes bodyweight (sorted, unique)', () {
      const intake = PlanIntake(
        goal: 'build_strength',
        trainingDaysPerWeek: 4,
        equipment: ['kettlebells', 'dumbbells'],
      );
      final p = _gen(intake);
      expect(p.effectiveEquipment, contains('bodyweight'));
      expect(p.effectiveEquipment, containsAll(<String>['kettlebells', 'dumbbells']));
      // sorted
      final sorted = [...p.effectiveEquipment]..sort();
      expect(p.effectiveEquipment, equals(sorted));
    });
  });

  group('contraindication / injury filter (VAL-ONB-029)', () {
    test('knee limitation excludes squatting/landing movements', () {
      const intake = PlanIntake(
        goal: 'get_fitter',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
        limitations: ['knee'],
      );
      final p = _gen(intake);
      final ids = <String>{
        for (final d in p.days) ...d.exercises.map((e) => e.id),
      };
      // Contraindicated for knee: air_squat, bodyweight_lunge, goblet_squat, etc.
      expect(ids.contains('bodyweight_squat'), isFalse);
      expect(ids.contains('bodyweight_lunge'), isFalse);
      expect(ids.contains('goblet_squat'), isFalse);
      // plan should still be non-empty (substitution, not dead-end).
      expect(p.totalExercises, greaterThan(0));
    });

    test('shoulder + wrist limitations remove push-up & OH press family', () {
      const intake = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells', 'barbell', 'bodyweight'],
        experienceLevel: 'intermediate',
        limitations: ['shoulder', 'wrist'],
      );
      final p = _gen(intake);
      final ids = <String>{
        for (final d in p.days) ...d.exercises.map((e) => e.id),
      };
      expect(ids.contains('pushup'), isFalse);
      expect(ids.contains('overhead_press_dumbbell'), isFalse);
      expect(ids.contains('barbell_bench_press'), isFalse);
      expect(ids.contains('dumbbell_bench_press'), isFalse);
      expect(ids.contains('pike_pushup'), isFalse);
      expect(ids.contains('close_grip_pushup'), isFalse);
      expect(ids.contains('tricep_dip'), isFalse);
      expect(p.totalExercises, greaterThan(0));
    });

    test('"none" limitation means no exclusions', () {
      const withNone = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
        limitations: ['none'],
      );
      const without = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
      );
      expect(_json(_gen(withNone)), equals(_json(_gen(without))));
    });
  });

  group('volume grid (sets/reps/rpe by goal x experience)', () {
    test('build_muscle / intermediate -> sets=3, reps 8-12, rpe=8', () {
      const intake = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
      );
      final p = _gen(intake);
      for (final d in p.days) {
        for (final e in d.exercises) {
          expect(e.sets, equals(3));
          expect(e.repsMin, equals(8));
          expect(e.repsMax, equals(12));
          expect(e.rpeTarget, equals(8));
        }
      }
    });

    test('build_strength / advanced -> sets=5, reps 3-5, rpe=9', () {
      const intake = PlanIntake(
        goal: 'build_strength',
        trainingDaysPerWeek: 4,
        equipment: ['barbell'],
        experienceLevel: 'advanced',
      );
      final p = _gen(intake);
      for (final d in p.days) {
        for (final e in d.exercises) {
          expect(e.sets, equals(5));
          expect(e.repsMin, equals(3));
          expect(e.repsMax, equals(5));
          expect(e.rpeTarget, equals(9));
        }
      }
    });

    test('improve_mobility / beginner -> sets=2, reps 8-12', () {
      const intake = PlanIntake(
        goal: 'improve_mobility',
        trainingDaysPerWeek: 3,
        equipment: <String>[],
        experienceLevel: 'beginner',
      );
      final p = _gen(intake);
      for (final d in p.days) {
        for (final e in d.exercises) {
          expect(e.sets, equals(2));
          expect(e.repsMin, equals(8));
          expect(e.repsMax, equals(12));
          expect(e.rpeTarget, equals(6));
        }
      }
    });

    test('null experienceLevel falls back to intermediate row', () {
      const intakeNull = PlanIntake(
        goal: 'lose_fat',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: null,
      );
      const intakeInter = PlanIntake(
        goal: 'lose_fat',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
      );
      expect(_json(_gen(intakeNull)), equals(_json(_gen(intakeInter))));
    });

    test('rest seconds: compound=120, isolation=60 (non-beginner)', () {
      const intake = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
      );
      final p = _gen(intake);
      for (final d in p.days) {
        for (final e in d.exercises) {
          if (e.isCompound) {
            expect(e.restSeconds, equals(120));
          } else {
            expect(e.restSeconds, equals(60));
          }
        }
      }
    });
  });

  group('split by training days per week (cadence, VAL-ONB-027)', () {
    test('3 days -> 3 plan days, full body split codes', () {
      final p = _gen(const PlanIntake(
        goal: 'get_fitter',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
      ));
      expect(p.days, hasLength(3));
      expect(p.days.map((d) => d.split).toSet(), equals(<String>{'full'}));
    });

    test('4 days -> 4 plan days, upper/lower', () {
      final p = _gen(const PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 4,
        equipment: ['dumbbells'],
      ));
      expect(p.days, hasLength(4));
      expect(p.days[0].split, equals('upper'));
      expect(p.days[1].split, equals('lower'));
      expect(p.days[2].split, equals('upper'));
      expect(p.days[3].split, equals('lower'));
    });

    test('5 days -> 5 plan days, push/pull/legs/upper/lower', () {
      final p = _gen(const PlanIntake(
        goal: 'get_fitter',
        trainingDaysPerWeek: 5,
        equipment: ['dumbbells', 'barbell'],
      ));
      expect(p.days, hasLength(5));
      expect(p.days[0].split, equals('push'));
      expect(p.days[1].split, equals('pull'));
      expect(p.days[2].split, equals('legs'));
      expect(p.days[3].split, equals('upper'));
      expect(p.days[4].split, equals('lower'));
      // target exercises/day == 4 for 5 days
      for (final d in p.days) {
        expect(d.exercises.length, lessThanOrEqualTo(4));
      }
    });

    test('2 days -> 2 full-body days', () {
      final p = _gen(const PlanIntake(
        goal: 'build_strength',
        trainingDaysPerWeek: 2,
        equipment: ['barbell'],
      ));
      expect(p.days, hasLength(2));
      // target exercises/day == 6 for 2 days
      for (final d in p.days) {
        expect(d.exercises.length, lessThanOrEqualTo(6));
      }
    });
  });

  group('consequential behavior (VAL-ONB-050): changing an answer changes the plan', () {
    test('changing equipment changes the exercise set', () {
      const a = PlanIntake(
        goal: 'get_fitter',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
      );
      const b = PlanIntake(
        goal: 'get_fitter',
        trainingDaysPerWeek: 3,
        equipment: ['barbell'],
      );
      expect(_json(_gen(b)) == _json(_gen(a)), isFalse);
    });

    test('changing goal changes sets/reps/rpe', () {
      const a = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
      );
      const b = PlanIntake(
        goal: 'build_strength',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
      );
      expect(_json(_gen(b)) == _json(_gen(a)), isFalse);
    });

    test('adding a limitation reduces or changes the exercise set, never errors', () {
      const a = PlanIntake(
        goal: 'get_fitter',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
      );
      final b = PlanIntake(
        goal: 'get_fitter',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        limitations: ['back', 'knee', 'shoulder'],
      );
      final pa = _gen(a);
      final pb = _gen(b);
      // With many limitations the bodyweight-only plan body gets smaller
      // but is NEVER empty.
      expect(pb.totalExercises, greaterThan(0));
      expect(pb.totalExercises, lessThanOrEqualTo(pa.totalExercises));
    });
  });

  group('output contract', () {
    test('every exercise has non-empty name, positive sets/reps', () {
      const intake = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 5,
        equipment: ['dumbbells', 'pull_up_bar'],
        experienceLevel: 'advanced',
      );
      final p = _gen(intake);
      for (final d in p.days) {
        for (final e in d.exercises) {
          expect(e.name, isNotEmpty);
          expect(e.muscleGroup, isNotEmpty);
          expect(e.equipment, isNotEmpty);
          expect(e.sets, greaterThan(0));
          expect(e.repsMax, greaterThanOrEqualTo(e.repsMin));
          expect(e.rpeTarget, inInclusiveRange(1, 10));
          expect(e.restSeconds, greaterThan(0));
        }
      }
    });
  });
}
