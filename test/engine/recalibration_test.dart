// Unit tests for the M6 recalibration engine.

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/recalibration.dart';

void main() {
  group('epleyOneRm', () {
    test('returns weight for 1 rep', () {
      expect(epleyOneRm(100, 1), 100);
    });

    test('computes Epley formula correctly', () {
      // 100kg x 5 reps = 100 * (1 + 5/30) = 100 * 1.1666... = 116.67
      expect(epleyOneRm(100, 5), closeTo(116.67, 0.1));
    });

    test('returns 0 for non-positive reps', () {
      expect(epleyOneRm(100, 0), 0);
      expect(epleyOneRm(0, 5), 0);
    });
  });

  group('roundLoad', () {
    test('rounds to nearest 2.5kg', () {
      expect(roundLoad(102.3), 102.5);
      expect(roundLoad(101.0), 100.0);
      expect(roundLoad(103.7), 102.5);
    });
  });

  group('recalibrateTrainingMaxes', () {
    test('bumps training max when estimated 1RM exceeds by >2.5%', () {
      final results = recalibrateTrainingMaxes([
        ExercisePerformance(
          exerciseId: 'squat',
          lastTrainingMaxKg: 100.0,
          topWeightThisWeekKg: 100.0,
          topRepsAtTopWeight: 6,
          // est1RM = 100 * (1 + 6/30) = 120. 90% = 108. 108 > 102.5 threshold.
          totalSetsThisWeek: 12,
          averageRpe: 8.0,
        ),
      ]);

      expect(results.first.direction, 'up');
      expect(results.first.newTrainingMaxKg, greaterThan(100.0));
      expect(results.first.newTrainingMaxKg, 107.5); // 108 rounded to 107.5
    });

    test('drops training max when performance drops with high RPE', () {
      final results = recalibrateTrainingMaxes([
        ExercisePerformance(
          exerciseId: 'bench',
          lastTrainingMaxKg: 100.0,
          topWeightThisWeekKg: 80.0,
          topRepsAtTopWeight: 3,
          // est1RM = 80 * (1 + 3/30) = 88. 88 < 95 threshold. RPE > 8.5.
          totalSetsThisWeek: 10,
          averageRpe: 9.0,
        ),
      ]);

      expect(results.first.direction, 'down');
      expect(results.first.newTrainingMaxKg, lessThan(100.0));
    });

    test('holds when lower performance but low RPE (easy week)', () {
      final results = recalibrateTrainingMaxes([
        ExercisePerformance(
          exerciseId: 'deadlift',
          lastTrainingMaxKg: 120.0,
          topWeightThisWeekKg: 90.0,
          topRepsAtTopWeight: 3,
          // est1RM = 90 * 1.1 = 99 < 114. But RPE is low → hold.
          totalSetsThisWeek: 8,
          averageRpe: 6.0,
        ),
      ]);

      expect(results.first.direction, 'hold');
      expect(results.first.newTrainingMaxKg, 120.0);
    });

    test('holds when performance within ±2.5%', () {
      final results = recalibrateTrainingMaxes([
        ExercisePerformance(
          exerciseId: 'squat',
          lastTrainingMaxKg: 100.0,
          topWeightThisWeekKg: 95.0,
          topRepsAtTopWeight: 3,
          // est1RM = 95 * 1.1 = 104.5. 90% = 94.05 < 102.5 threshold → hold.
          // Actually 104.5 > 100 so est is fine. 90% = 94 < gainThreshold.
          // est < lossThreshold? 104.5 > 95 → no. So hold.
          totalSetsThisWeek: 10,
          averageRpe: 7.5,
        ),
      ]);

      expect(results.first.direction, 'hold');
      expect(results.first.newTrainingMaxKg, 100.0);
    });

    test('holds when no sets logged', () {
      final results = recalibrateTrainingMaxes([
        ExercisePerformance(
          exerciseId: 'ohp',
          lastTrainingMaxKg: 60.0,
          topWeightThisWeekKg: 0,
          topRepsAtTopWeight: 0,
          totalSetsThisWeek: 0,
          averageRpe: 0,
        ),
      ]);

      expect(results.first.direction, 'hold');
      expect(results.first.newTrainingMaxKg, 60.0);
    });

    test('determinism — identical inputs produce identical outputs', () {
      final perf = [
        ExercisePerformance(
          exerciseId: 'squat',
          lastTrainingMaxKg: 100.0,
          topWeightThisWeekKg: 100.0,
          topRepsAtTopWeight: 5,
          totalSetsThisWeek: 12,
          averageRpe: 8.0,
        ),
      ];

      final r1 = recalibrateTrainingMaxes(perf);
      final r2 = recalibrateTrainingMaxes(perf);
      expect(r1.first.newTrainingMaxKg, r2.first.newTrainingMaxKg);
      expect(r1.first.direction, r2.first.direction);
    });

    test('handles multiple exercises in one call', () {
      final results = recalibrateTrainingMaxes([
        ExercisePerformance(
          exerciseId: 'squat',
          lastTrainingMaxKg: 100.0,
          topWeightThisWeekKg: 100.0,
          topRepsAtTopWeight: 6,
          totalSetsThisWeek: 12,
          averageRpe: 8.0,
        ),
        ExercisePerformance(
          exerciseId: 'bench',
          lastTrainingMaxKg: 80.0,
          topWeightThisWeekKg: 80.0,
          topRepsAtTopWeight: 5,
          totalSetsThisWeek: 10,
          averageRpe: 7.5,
        ),
        ExercisePerformance(
          exerciseId: 'row',
          lastTrainingMaxKg: 70.0,
          topWeightThisWeekKg: 0,
          topRepsAtTopWeight: 0,
          totalSetsThisWeek: 0,
          averageRpe: 0,
        ),
      ]);

      expect(results.length, 3);
      expect(results[0].direction, 'up');
      expect(results[2].direction, 'hold');
    });

    test('new training max is always snapped to 2.5kg increment', () {
      final results = recalibrateTrainingMaxes([
        ExercisePerformance(
          exerciseId: 'squat',
          lastTrainingMaxKg: 100.0,
          topWeightThisWeekKg: 102.5,
          topRepsAtTopWeight: 8,
          totalSetsThisWeek: 15,
          averageRpe: 8.5,
        ),
      ]);

      final newMax = results.first.newTrainingMaxKg;
      expect((newMax * 10) % 25, 0.0); // divisible by 2.5
    });
  });
}
