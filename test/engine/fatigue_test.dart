// Unit tests for the M4 fatigue/ACWR engine.

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/fatigue.dart';

void main() {
  group('computeFatigue: empty history', () {
    test('returns safe state with zero loads', () {
      final result = computeFatigue([]);

      expect(result.acwr, 0.0);
      expect(result.state, 'safe');
      expect(result.acuteLoad, 0.0);
      expect(result.chronicLoad, 0.0);
      expect(result.volumeMultiplier, 1.0);
    });
  });

  group('computeFatigue: steady state (ACWR ~1.0)', () {
    test('classifies as safe when acute matches chronic', () {
      // 28 days of equal daily volume.
      final history = [
        for (int i = 27; i >= 0; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 1000.0,
          ),
      ];
      final result = computeFatigue(history);

      expect(result.state, 'safe');
      expect(result.acwr, closeTo(1.0, 0.15));
    });
  });

  group('computeFatigue: spike (high ACWR)', () {
    test('classifies as high when acute >> chronic', () {
      // 21 days of low volume, then 7 days of high volume.
      final history = [
        for (int i = 27; i >= 7; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 500.0,
          ),
        for (int i = 6; i >= 0; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 3000.0,
          ),
      ];
      final result = computeFatigue(history);

      expect(result.state, 'high');
      expect(result.acwr, greaterThan(1.5));
      expect(result.volumeMultiplier, 0.70);
    });
  });

  group('computeFatigue: caution zone', () {
    test('classifies as caution for moderate spike', () {
      // 21 days moderate, 7 days elevated.
      final history = [
        for (int i = 27; i >= 7; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 1000.0,
          ),
        for (int i = 6; i >= 0; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 1600.0,
          ),
      ];
      final result = computeFatigue(history);

      expect(result.state, anyOf('caution', 'high'));
      expect(result.acwr, greaterThanOrEqualTo(1.3));
    });
  });

  group('computeFatigue: volume multiplier', () {
    test('safe zone gives 1.0', () {
      final history = [
        for (int i = 27; i >= 0; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 1000.0,
          ),
      ];
      final result = computeFatigue(history);
      expect(result.volumeMultiplier, 1.0);
    });

    test('high zone gives 0.70', () {
      final history = [
        for (int i = 27; i >= 7; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 100.0,
          ),
        for (int i = 6; i >= 0; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 5000.0,
          ),
      ];
      final result = computeFatigue(history);
      expect(result.volumeMultiplier, 0.70);
    });
  });

  group('computeFatigue: determinism', () {
    test('identical history produces identical result', () {
      final history = [
        for (int i = 27; i >= 0; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 800.0 + (i % 3) * 200,
          ),
      ];
      final a = computeFatigue(history);
      final b = computeFatigue(history);
      expect(a.toJson(), equals(b.toJson()));
    });
  });

  group('roundAcwr', () {
    test('rounds to 2 decimal places', () {
      expect(roundAcwr(1.23456), 1.23);
      expect(roundAcwr(1.555), 1.56);
      expect(roundAcwr(0.0), 0.0);
    });
  });
}
