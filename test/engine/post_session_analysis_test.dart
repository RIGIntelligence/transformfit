// Unit tests for the M5 post-session analysis engine.

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/post_session_analysis.dart';

void main() {
  group('computePostSessionAnalysis: empty sets', () {
    test('returns zero-volume result', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(sets: []),
      );

      expect(result.totalVolumeKg, 0.0);
      expect(result.totalSets, 0);
      expect(result.totalReps, 0);
      expect(result.averageRpe, 0.0);
      expect(result.oneRmChanges, isEmpty);
      expect(result.corridorStatus, 'in_corridor');
      expect(result.readinessImpact, 0);
    });
  });

  group('computePostSessionAnalysis: volume', () {
    test('sums weight x reps across sets', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(
          sets: [
            AnalysisLoggedSet(
              exerciseId: 'squat',
              weightKg: 100,
              reps: 5,
              rpe: 7,
            ),
            AnalysisLoggedSet(
              exerciseId: 'squat',
              weightKg: 100,
              reps: 5,
              rpe: 8,
            ),
          ],
        ),
      );

      expect(result.totalVolumeKg, 1000.0);
      expect(result.totalSets, 2);
      expect(result.totalReps, 10);
      expect(result.averageRpe, 7.5);
    });

    test('skips sets with zero weight or reps', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(
          sets: [
            AnalysisLoggedSet(
              exerciseId: 'squat',
              weightKg: 100,
              reps: 5,
              rpe: 7,
            ),
            AnalysisLoggedSet(
              exerciseId: 'squat',
              weightKg: 0,
              reps: 5,
            ),
          ],
        ),
      );

      expect(result.totalVolumeKg, 500.0);
      expect(result.totalSets, 2); // both counted, but volume only from valid
    });
  });

  group('computePostSessionAnalysis: 1RM (Epley)', () {
    test('computes session-best 1RM per exercise', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(
          sets: [
            AnalysisLoggedSet(
              exerciseId: 'press',
              weightKg: 60,
              reps: 8,
            ),
            AnalysisLoggedSet(
              exerciseId: 'press',
              weightKg: 70,
              reps: 3,
            ),
          ],
        ),
      );

      expect(result.oneRmChanges, hasLength(1));
      // Epley for 70x3 = 70 * (1 + 3/30) = 70 * 1.1 = 77
      // Epley for 60x8 = 60 * (1 + 8/30) = 60 * 1.267 = 76
      // Session best = 77
      expect(result.oneRmChanges.first.exerciseId, 'press');
      expect(result.oneRmChanges.first.sessionOneRmKg, closeTo(77.0, 0.1));
    });

    test('computes delta against previous best', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(
          sets: [
            AnalysisLoggedSet(
              exerciseId: 'squat',
              weightKg: 100,
              reps: 5,
            ),
          ],
          previousBests: [
            AnalysisPreviousBest(
              exerciseId: 'squat',
              estimatedOneRmKg: 100.0,
            ),
          ],
        ),
      );

      // Epley 100x5 = 100 * (1 + 5/30) = 116.67
      expect(result.oneRmChanges.first.sessionOneRmKg, closeTo(116.67, 0.1));
      expect(result.oneRmChanges.first.previousOneRmKg, 100.0);
      expect(result.oneRmChanges.first.deltaKg, closeTo(16.67, 0.1));
    });

    test('uses session 1RM as previous when no prior best exists', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(
          sets: [
            AnalysisLoggedSet(
              exerciseId: 'row',
              weightKg: 50,
              reps: 10,
            ),
          ],
        ),
      );

      expect(result.oneRmChanges.first.deltaKg, 0.0);
    });
  });

  group('computePostSessionAnalysis: corridor', () {
    test('in_corridor when reps and rpe are within band', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(
          sets: [
            AnalysisLoggedSet(
              exerciseId: 'squat',
              weightKg: 100,
              reps: 8,
              rpe: 7,
            ),
          ],
          corridorRepsMin: 5,
          corridorRepsMax: 12,
          corridorRpeTarget: 7,
        ),
      );

      expect(result.corridorStatus, 'in_corridor');
    });

    test('above_corridor when reps exceed max at low rpe', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(
          sets: [
            AnalysisLoggedSet(
              exerciseId: 'squat',
              weightKg: 60,
              reps: 15,
              rpe: 5,
            ),
          ],
          corridorRepsMin: 5,
          corridorRepsMax: 12,
          corridorRpeTarget: 7,
        ),
      );

      expect(result.corridorStatus, 'above_corridor');
    });

    test('below_corridor when rpe is too high', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(
          sets: [
            AnalysisLoggedSet(
              exerciseId: 'squat',
              weightKg: 120,
              reps: 5,
              rpe: 10,
            ),
          ],
          corridorRepsMin: 5,
          corridorRepsMax: 12,
          corridorRpeTarget: 7,
        ),
      );

      expect(result.corridorStatus, 'below_corridor');
    });
  });

  group('computePostSessionAnalysis: readiness impact', () {
    test('zero impact for minimal volume', () {
      final result = computePostSessionAnalysis(
        const PostSessionAnalysisInputs(
          sets: [
            AnalysisLoggedSet(
              exerciseId: 'squat',
              weightKg: 20,
              reps: 5,
              rpe: 5,
            ),
          ],
        ),
      );

      expect(result.readinessImpact, lessThanOrEqualTo(5));
    });

    test('higher impact for heavy volume and duration', () {
      final result = computePostSessionAnalysis(
        PostSessionAnalysisInputs(
          sets: [
            for (int i = 0; i < 10; i++)
              const AnalysisLoggedSet(
                exerciseId: 'squat',
                weightKg: 120,
                reps: 5,
                rpe: 9,
              ),
          ],
          durationMinutes: 90,
        ),
      );

      expect(result.readinessImpact, greaterThan(10));
    });

    test('readiness impact is clamped at 20', () {
      final result = computePostSessionAnalysis(
        PostSessionAnalysisInputs(
          sets: [
            for (int i = 0; i < 20; i++)
              const AnalysisLoggedSet(
                exerciseId: 'squat',
                weightKg: 200,
                reps: 10,
                rpe: 10,
              ),
          ],
          durationMinutes: 120,
        ),
      );

      expect(result.readinessImpact, lessThanOrEqualTo(20));
    });
  });

  group('computePostSessionAnalysis: determinism', () {
    test('identical inputs produce identical outputs', () {
      final inputs = const PostSessionAnalysisInputs(
        sets: [
          AnalysisLoggedSet(
            exerciseId: 'squat',
            weightKg: 100,
            reps: 5,
            rpe: 7,
          ),
          AnalysisLoggedSet(
            exerciseId: 'press',
            weightKg: 60,
            reps: 8,
            rpe: 6,
          ),
        ],
        previousBests: [
          AnalysisPreviousBest(
            exerciseId: 'squat',
            estimatedOneRmKg: 110.0,
          ),
        ],
        durationMinutes: 45,
      );

      final a = computePostSessionAnalysis(inputs);
      final b = computePostSessionAnalysis(inputs);
      expect(a.toJson(), equals(b.toJson()));
    });
  });

  group('epleyOneRm', () {
    test('returns weight for 1 rep', () {
      expect(epleyOneRm(100, 1), 100.0);
    });

    test('computes Epley formula correctly', () {
      // 100 * (1 + 5/30) = 116.67
      expect(epleyOneRm(100, 5), closeTo(116.67, 0.01));
      // 60 * (1 + 10/30) = 80
      expect(epleyOneRm(60, 10), closeTo(80.0, 0.01));
    });

    test('returns 0 for non-positive reps', () {
      expect(epleyOneRm(100, 0), 0.0);
    });
  });
}
