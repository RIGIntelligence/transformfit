// Unit tests for the M4 progression engine.
//
// Doctrine L6-2: the engine computes ALL numbers. Deterministic, no
// randomness. Identical inputs → identical outputs.

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/progression.dart';

void main() {
  group('computeProgression: baseline (no prior anchor)', () {
    test('returns baseline prescription with repsMin and zero weight', () {
      const inputs = ProgressionInputs(
        exerciseId: 'goblet_squat',
        params: ProgressionParams(
          repsMin: 8,
          repsMax: 12,
          rpeTarget: 7,
          restSeconds: 90,
        ),
      );
      final result = computeProgression(inputs);

      expect(result.progressionType, 'baseline');
      expect(result.prescribedWeightKg, 0.0);
      expect(result.prescribedReps, 8);
      expect(result.prescribedRpe, 7);
      expect(result.prescribedSets, 3);
      expect(result.prescribedRestSeconds, 90);
      expect(result.isDeload, isFalse);
    });

    test('baseline is deterministic across repeated calls', () {
      const inputs = ProgressionInputs(
        exerciseId: 'pushup',
        params: ProgressionParams(
          repsMin: 10,
          repsMax: 15,
          rpeTarget: 7,
          restSeconds: 60,
        ),
      );
      final a = computeProgression(inputs);
      final b = computeProgression(inputs);
      expect(a.toJson(), equals(b.toJson()));
    });
  });

  group('computeProgression: rep progression (within corridor)', () {
    test('adds one rep when below repsMax and RPE is controlled', () {
      final lastAnchor = ProgressionAnchor(
        weightKg: 40.0,
        reps: 8,
        rpe: 7,
        completedAt: DateTime(2026, 7, 1),
      );
      final inputs = ProgressionInputs(
        exerciseId: 'goblet_squat',
        params: const ProgressionParams(
          repsMin: 8,
          repsMax: 12,
          rpeTarget: 8,
          restSeconds: 90,
        ),
        lastAnchor: lastAnchor,
      );
      final result = computeProgression(inputs);

      expect(result.progressionType, 'rep_progression');
      expect(result.prescribedReps, 9);
      expect(result.prescribedWeightKg, 40.0);
      expect(result.prescribedRpe, 8);
    });

    test('does not exceed repsMax', () {
      final lastAnchor = ProgressionAnchor(
        weightKg: 40.0,
        reps: 12,
        rpe: 9,
        completedAt: DateTime(2026, 7, 1),
      );
      final inputs = ProgressionInputs(
        exerciseId: 'goblet_squat',
        params: const ProgressionParams(
          repsMin: 8,
          repsMax: 12,
          rpeTarget: 8,
          restSeconds: 90,
        ),
        lastAnchor: lastAnchor,
      );
      final result = computeProgression(inputs);

      // At max reps with high RPE → hold.
      expect(result.progressionType, 'hold');
      expect(result.prescribedReps, 12);
    });
  });

  group('computeProgression: load progression', () {
    test('increases load by 2.5kg when repsMax hit at controlled RPE', () {
      final lastAnchor = ProgressionAnchor(
        weightKg: 40.0,
        reps: 12,
        rpe: 6,
        completedAt: DateTime(2026, 7, 1),
      );
      final inputs = ProgressionInputs(
        exerciseId: 'dumbbell_curl',
        params: const ProgressionParams(
          repsMin: 10,
          repsMax: 12,
          rpeTarget: 8,
          restSeconds: 60,
        ),
        lastAnchor: lastAnchor,
      );
      final result = computeProgression(inputs);

      expect(result.progressionType, 'load_progression');
      expect(result.prescribedWeightKg, 42.5);
      expect(result.prescribedReps, 10); // reset to min
    });

    test('rounds load to nearest 2.5kg increment', () {
      final lastAnchor = ProgressionAnchor(
        weightKg: 41.0,
        reps: 12,
        rpe: 6,
        completedAt: DateTime(2026, 7, 1),
      );
      final inputs = ProgressionInputs(
        exerciseId: 'dumbbell_curl',
        params: const ProgressionParams(
          repsMin: 10,
          repsMax: 12,
          rpeTarget: 8,
          restSeconds: 60,
        ),
        lastAnchor: lastAnchor,
      );
      final result = computeProgression(inputs);

      expect(result.prescribedWeightKg, 42.5);
    });
  });

  group('computeProgression: rebuild', () {
    test('reduces load 10% when reps fall below corridor min', () {
      final lastAnchor = ProgressionAnchor(
        weightKg: 50.0,
        reps: 5,
        rpe: 9,
        completedAt: DateTime(2026, 7, 1),
      );
      final inputs = ProgressionInputs(
        exerciseId: 'barbell_bench_press',
        params: const ProgressionParams(
          repsMin: 8,
          repsMax: 12,
          rpeTarget: 8,
          restSeconds: 120,
        ),
        lastAnchor: lastAnchor,
      );
      final result = computeProgression(inputs);

      expect(result.progressionType, 'rebuild');
      expect(result.prescribedWeightKg, 45.0); // 50 * 0.9 = 45
    });
  });

  group('computeProgression: deload', () {
    test('triggers deload when flag is set', () {
      final lastAnchor = ProgressionAnchor(
        weightKg: 60.0,
        reps: 10,
        rpe: 8,
        completedAt: DateTime(2026, 7, 1),
      );
      final inputs = ProgressionInputs(
        exerciseId: 'barbell_back_squat',
        params: const ProgressionParams(
          repsMin: 8,
          repsMax: 12,
          rpeTarget: 8,
          restSeconds: 120,
        ),
        lastAnchor: lastAnchor,
        deloadRecommended: true,
      );
      final result = computeProgression(inputs);

      expect(result.isDeload, isTrue);
      expect(result.progressionType, 'deload');
      expect(result.prescribedSets, lessThan(4));
      expect(result.volumeMultiplier, lessThan(1.0));
    });
  });

  group('computeProgression: readiness modulation', () {
    test('push zone increases sets', () {
      final lastAnchor = ProgressionAnchor(
        weightKg: 40.0,
        reps: 10,
        rpe: 7,
        completedAt: DateTime(2026, 7, 1),
      );
      final inputs = ProgressionInputs(
        exerciseId: 'goblet_squat',
        params: const ProgressionParams(
          repsMin: 8,
          repsMax: 12,
          rpeTarget: 8,
          restSeconds: 90,
        ),
        lastAnchor: lastAnchor,
        readinessScore: 85,
      );
      final result = computeProgression(inputs);

      expect(result.prescribedSets, 4); // 3 + 1
    });

    test('low readiness decreases sets (floor 2)', () {
      final lastAnchor = ProgressionAnchor(
        weightKg: 40.0,
        reps: 10,
        rpe: 7,
        completedAt: DateTime(2026, 7, 1),
      );
      final inputs = ProgressionInputs(
        exerciseId: 'goblet_squat',
        params: const ProgressionParams(
          repsMin: 8,
          repsMax: 12,
          rpeTarget: 8,
          restSeconds: 90,
        ),
        lastAnchor: lastAnchor,
        readinessScore: 35,
      );
      final result = computeProgression(inputs);

      expect(result.prescribedSets, 2);
    });
  });

  group('computeProgression: validation', () {
    test('rejects empty exerciseId', () {
      const inputs = ProgressionInputs(
        exerciseId: '',
        params: ProgressionParams(
          repsMin: 8,
          repsMax: 12,
          rpeTarget: 8,
          restSeconds: 90,
        ),
      );
      expect(() => computeProgression(inputs), throwsArgumentError);
    });
  });

  group('roundLoad', () {
    test('rounds to nearest 2.5kg', () {
      expect(roundLoad(0.0), 0.0);
      expect(roundLoad(1.0), 0.0);
      expect(roundLoad(2.0), 2.5);
      expect(roundLoad(3.0), 2.5);
      expect(roundLoad(4.0), 5.0);
      expect(roundLoad(42.5), 42.5);
      expect(roundLoad(43.0), 42.5);
      expect(roundLoad(44.0), 45.0);
    });
  });

  group('classifyFatigue', () {
    test('classifies ACWR correctly', () {
      expect(classifyFatigue(0.0), 'safe');
      expect(classifyFatigue(1.0), 'safe');
      expect(classifyFatigue(1.2), 'safe');
      expect(classifyFatigue(1.3), 'caution');
      expect(classifyFatigue(1.4), 'caution');
      expect(classifyFatigue(1.5), 'high');
      expect(classifyFatigue(2.0), 'high');
    });
  });
}
