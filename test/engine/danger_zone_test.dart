// Unit tests for the M8 danger-zone engine.

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/danger_zone.dart';

void main() {
  group('evaluateDangerZones: ACWR', () {
    test('critical when ACWR > 1.5', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.6,
        monotony: 1.0,
      ));
      expect(result.overallSeverity, 'critical');
      expect(result.signals.any((s) => s.code == 'ACWR_HIGH'), isTrue);
    });

    test('warning when ACWR 1.3-1.5', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.4,
        monotony: 1.0,
      ));
      expect(result.overallSeverity, 'warning');
      expect(result.signals.any((s) => s.code == 'ACWR_ELEVATED'), isTrue);
    });

    test('clear when ACWR < 1.3', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.1,
        monotony: 1.0,
      ));
      expect(result.signals.any((s) => s.code.contains('ACWR')), isFalse);
    });
  });

  group('evaluateDangerZones: monotony', () {
    test('warning when monotony > 2.0', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.0,
        monotony: 2.5,
      ));
      expect(result.signals.any((s) => s.code == 'MONOTONY_HIGH'), isTrue);
      expect(result.overallSeverity, 'warning');
    });

    test('clear when monotony < 2.0', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.0,
        monotony: 1.5,
      ));
      expect(result.signals.any((s) => s.code == 'MONOTONY_HIGH'), isFalse);
    });
  });

  group('evaluateDangerZones: RPE streak', () {
    test('critical when 3+ consecutive RPE >= 9.5', () {
      final result = evaluateDangerZones(DangerZoneInput(
        acwr: 1.0,
        monotony: 1.0,
        recentHardSets: [
          SetRpe(exerciseId: 'squat', rpe: 9.5),
          SetRpe(exerciseId: 'squat', rpe: 9.7),
          SetRpe(exerciseId: 'squat', rpe: 9.5),
        ],
      ));
      expect(result.overallSeverity, 'critical');
      expect(result.signals.any((s) => s.code == 'RPE_SPIKE_CRITICAL'), isTrue);
    });

    test('warning when 3+ consecutive RPE 9.0-9.4', () {
      final result = evaluateDangerZones(DangerZoneInput(
        acwr: 1.0,
        monotony: 1.0,
        recentHardSets: [
          SetRpe(exerciseId: 'bench', rpe: 9.0),
          SetRpe(exerciseId: 'bench', rpe: 9.2),
          SetRpe(exerciseId: 'bench', rpe: 9.1),
        ],
      ));
      expect(result.overallSeverity, 'warning');
      expect(result.signals.any((s) => s.code == 'RPE_SPIKE'), isTrue);
    });

    test('no signal when streak broken', () {
      final result = evaluateDangerZones(DangerZoneInput(
        acwr: 1.0,
        monotony: 1.0,
        recentHardSets: [
          SetRpe(exerciseId: 'squat', rpe: 9.0),
          SetRpe(exerciseId: 'squat', rpe: 7.0),
          SetRpe(exerciseId: 'squat', rpe: 9.0),
          SetRpe(exerciseId: 'squat', rpe: 9.0),
        ],
      ));
      expect(result.signals.any((s) => s.code.contains('RPE')), isFalse);
    });
  });

  group('evaluateDangerZones: body weight', () {
    test('critical when weight change > 5%', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.0,
        monotony: 1.0,
        bodyWeightChangePercent: -5.5,
      ));
      expect(result.overallSeverity, 'critical');
      expect(result.signals.any((s) => s.code == 'BODY_WEIGHT_RAPID'), isTrue);
    });

    test('warning when weight change 3-5%', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.0,
        monotony: 1.0,
        bodyWeightChangePercent: 3.5,
      ));
      expect(result.overallSeverity, 'warning');
      expect(result.signals.any((s) => s.code == 'BODY_WEIGHT_NOTABLE'), isTrue);
    });

    test('clear when weight change < 3%', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.0,
        monotony: 1.0,
        bodyWeightChangePercent: 1.5,
      ));
      expect(result.signals.any((s) => s.code.contains('BODY_WEIGHT')), isFalse);
    });
  });

  group('evaluateDangerZones: missed sessions', () {
    test('watch when 3+ missed in 14 days', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.0,
        monotony: 1.0,
        missedSessionsInLast14Days: 4,
      ));
      expect(result.overallSeverity, 'watch');
      expect(result.signals.any((s) => s.code == 'CONSISTENCY_RISK'), isTrue);
    });

    test('clear when < 3 missed', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.0,
        monotony: 1.0,
        missedSessionsInLast14Days: 2,
      ));
      expect(result.signals.any((s) => s.code == 'CONSISTENCY_RISK'), isFalse);
    });
  });

  group('evaluateDangerZones: overall severity', () {
    test('clear when no signals', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.0,
        monotony: 1.0,
      ));
      expect(result.overallSeverity, 'clear');
      expect(result.signals, isEmpty);
    });

    test('critical dominates warning', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.6,
        monotony: 2.5,
      ));
      expect(result.overallSeverity, 'critical');
      expect(result.signals.length, 2);
    });

    test('warning dominates watch', () {
      final result = evaluateDangerZones(const DangerZoneInput(
        acwr: 1.0,
        monotony: 2.5,
        missedSessionsInLast14Days: 4,
      ));
      expect(result.overallSeverity, 'warning');
    });
  });

  group('determinism', () {
    test('identical inputs produce identical outputs', () {
      const input = DangerZoneInput(
        acwr: 1.4,
        monotony: 1.8,
        missedSessionsInLast14Days: 2,
      );
      final r1 = evaluateDangerZones(input);
      final r2 = evaluateDangerZones(input);
      expect(r1.signals.length, r2.signals.length);
      expect(r1.overallSeverity, r2.overallSeverity);
    });
  });
}
