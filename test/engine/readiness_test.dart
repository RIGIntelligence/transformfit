import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/readiness.dart';

ReadinessResult _score(ReadinessInputs inputs) => computeReadinessScore(inputs);

void main() {
  group('input validation', () {
    test('VAL-RDY-007: rejects out-of-range energy and sleep', () {
      expect(
        () => _score(
          const ReadinessInputs(
            energyLevel: 0,
            sleepQuality: 8,
            sorenessMap: [],
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => _score(
          const ReadinessInputs(
            energyLevel: 8,
            sleepQuality: 11,
            sorenessMap: [],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-positive HRV and out-of-range strain when supplied', () {
      expect(
        () => _score(
          const ReadinessInputs(
            energyLevel: 8,
            sleepQuality: 8,
            sorenessMap: [],
            hrv: 0,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => _score(
          const ReadinessInputs(
            energyLevel: 8,
            sleepQuality: 8,
            sorenessMap: [],
            hrv: -10,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => _score(
          const ReadinessInputs(
            energyLevel: 8,
            sleepQuality: 8,
            sorenessMap: [],
            strain: 12,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('deterministic scoring', () {
    test('VAL-RDY-009: identical inputs always produce identical JSON', () {
      const inputs = ReadinessInputs(
        energyLevel: 6,
        sleepQuality: 8,
        sorenessMap: ['legs'],
        hrv: 60,
      );
      final a = _score(inputs).toJson();
      final b = _score(inputs).toJson();
      final c = _score(inputs).toJson();
      expect(b, equals(a));
      expect(c, equals(a));
    });

    test('VAL-RDY-011: with-HRV worked example scores 71', () {
      final result = _score(
        const ReadinessInputs(
          energyLevel: 10,
          sleepQuality: 10,
          sorenessMap: [],
          hrv: 120,
        ),
      );
      expect(result.score, equals(71));
      expect(result.readinessVariant, equals('with_hrv'));
      expect(result.readinessZone, equals('maintain'));
    });

    test('VAL-RDY-012: with-HRV ceiling is 71 before soreness penalty', () {
      final result = _score(
        const ReadinessInputs(
          energyLevel: 10,
          sleepQuality: 10,
          sorenessMap: [],
          hrv: 300,
        ),
      );
      expect(result.score, equals(71));
      expect(result.hrvScore, equals(100));
    });

    test('VAL-RDY-013: with-HRV mid-range worked example scores 38', () {
      final result = _score(
        const ReadinessInputs(
          energyLevel: 6,
          sleepQuality: 8,
          sorenessMap: ['legs'],
          hrv: 60,
        ),
      );
      expect(result.score, equals(38));
      expect(result.sorenessPenalty, equals(5));
    });

    test('VAL-RDY-014: without-HRV ceiling reaches 100', () {
      final result = _score(
        const ReadinessInputs(
          energyLevel: 10,
          sleepQuality: 10,
          sorenessMap: [],
        ),
      );
      expect(result.score, equals(100));
      expect(result.readinessVariant, equals('no_hrv'));
    });

    test('VAL-RDY-015: without-HRV mid-range worked example scores 61', () {
      final result = _score(
        const ReadinessInputs(
          energyLevel: 6,
          sleepQuality: 8,
          sorenessMap: ['legs', 'back'],
        ),
      );
      expect(result.score, equals(61));
      expect(result.sorenessPenalty, equals(10));
    });

    test('VAL-RDY-016: score floor clamps at 0', () {
      final result = _score(
        const ReadinessInputs(
          energyLevel: 1,
          sleepQuality: 1,
          sorenessMap: ['legs', 'back', 'shoulders', 'wrist'],
        ),
      );
      expect(result.score, equals(0));
    });

    test('VAL-RDY-017: soreness penalty caps at 20', () {
      final four = _score(
        const ReadinessInputs(
          energyLevel: 8,
          sleepQuality: 8,
          sorenessMap: ['a', 'b', 'c', 'd'],
        ),
      );
      final eight = _score(
        const ReadinessInputs(
          energyLevel: 8,
          sleepQuality: 8,
          sorenessMap: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
        ),
      );
      expect(eight.score, equals(four.score));
      expect(eight.sorenessPenalty, equals(20));
    });

    test('VAL-RDY-018/019: soreness penalty scales 5 per area to cap', () {
      final scores = [
        for (var count = 0; count <= 4; count++)
          _score(
            ReadinessInputs(
              energyLevel: 8,
              sleepQuality: 8,
              sorenessMap: List.generate(count, (i) => 'area_$i'),
            ),
          ).score,
      ];
      expect(scores[0] - scores[1], equals(5));
      expect(scores[1] - scores[2], equals(5));
      expect(scores[2] - scores[3], equals(5));
      expect(scores[3] - scores[4], equals(5));
    });
  });

  group('readiness zones', () {
    test('VAL-RDY-025/026/027: score bands map to push, maintain, deload', () {
      expect(computeReadinessZone(90), equals('push'));
      expect(computeReadinessZone(61), equals('maintain'));
      expect(computeReadinessZone(38), equals('deload'));
    });

    test('VAL-RDY-028: exactly 75 maps to push', () {
      expect(computeReadinessZone(75), equals('push'));
    });

    test('VAL-RDY-029: exactly 50 maps to maintain', () {
      expect(computeReadinessZone(50), equals('maintain'));
    });

    test('VAL-RDY-030: deload flag overrides score bands', () {
      expect(
        computeReadinessZone(90, deloadRecommended: true),
        equals('deload'),
      );
      expect(
        computeReadinessZone(60, deloadRecommended: true),
        equals('deload'),
      );
    });

    test('VAL-RDY-056: strain is captured without changing the score', () {
      final baseline = _score(
        const ReadinessInputs(
          energyLevel: 10,
          sleepQuality: 10,
          sorenessMap: [],
        ),
      );
      final withStrain = _score(
        const ReadinessInputs(
          energyLevel: 10,
          sleepQuality: 10,
          sorenessMap: [],
          strain: 9,
        ),
      );
      expect(withStrain.score, equals(baseline.score));
      expect(withStrain.readinessZone, equals(baseline.readinessZone));
      expect(withStrain.inputs.strain, equals(9));
      expect(withStrain.toJson()['readinessInputs'], containsPair('strain', 9));
    });

    test('VAL-RDY-057: half-value boundary rounds identically to 86', () {
      final result = _score(
        const ReadinessInputs(energyLevel: 8, sleepQuality: 9, sorenessMap: []),
      );
      expect(result.score, equals(86));
    });
  });
}
