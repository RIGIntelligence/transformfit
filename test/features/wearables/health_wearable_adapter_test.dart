import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:transformfit/features/wearables/health_wearable_adapter.dart';

void main() {
  group('HealthWearableAdapter conversion', () {
    test(
      'adapter filter excludes manual entries without filtering automatic recovery data',
      () {
        expect(
          wearableRecoveryRecordingMethodsToFilter,
          contains(RecordingMethod.manual),
        );
        expect(
          wearableRecoveryRecordingMethodsToFilter,
          isNot(contains(RecordingMethod.automatic)),
        );
        expect(
          wearableRecoveryRecordingMethodsToFilter,
          isNot(contains(RecordingMethod.active)),
        );
        expect(
          wearableRecoveryRecordingMethodsToFilter,
          isNot(contains(RecordingMethod.unknown)),
        );
      },
    );

    test(
      'automatic HealthKit points convert into a synced wearable signal',
      () {
        final capturedAt = DateTime(2026, 7, 3, 8);
        final signal = wearableSignalFromHealthData(
          capturedAt: capturedAt,
          totalSteps: 6420,
          points: [
            _numericPoint(
              capturedAt,
              type: HealthDataType.RESTING_HEART_RATE,
              unit: HealthDataUnit.BEATS_PER_MINUTE,
              value: 58,
            ),
            _numericPoint(
              capturedAt.add(const Duration(minutes: 1)),
              type: HealthDataType.HEART_RATE_VARIABILITY_SDNN,
              unit: HealthDataUnit.MILLISECOND,
              value: 66,
            ),
            _numericPoint(
              capturedAt,
              type: HealthDataType.ACTIVE_ENERGY_BURNED,
              unit: HealthDataUnit.KILOCALORIE,
              value: 410,
            ),
            _sleepPoint(
              from: capturedAt.subtract(const Duration(hours: 7)),
              to: capturedAt,
            ),
            _workoutPoint(
              from: capturedAt.subtract(const Duration(minutes: 38)),
              to: capturedAt,
            ),
          ],
        );

        expect(signal.source, 'apple_healthkit');
        expect(signal.syncState, 'synced');
        expect(signal.stepsToday, 6420);
        expect(signal.restingHeartRateBpm, 58);
        expect(signal.heartRateVariabilityMs, 66);
        expect(signal.activeEnergyKcal, 410);
        expect(signal.sleepMinutes, 420);
        expect(signal.workoutMinutes, 38);
      },
    );

    test('empty Health data fails closed as unavailable, not synced', () {
      final signal = wearableSignalFromHealthData(
        capturedAt: DateTime(2026, 7, 3, 8),
        points: const [],
      );

      expect(signal.source, 'health_package');
      expect(signal.syncState, 'unavailable');
      expect(signal.hasUsableSync, isFalse);
    });
  });
}

HealthDataPoint _numericPoint(
  DateTime at, {
  required HealthDataType type,
  required HealthDataUnit unit,
  required num value,
}) {
  return HealthDataPoint(
    uuid: 'auto-${type.name}-${at.microsecondsSinceEpoch}',
    value: NumericHealthValue(numericValue: value),
    type: type,
    unit: unit,
    dateFrom: at,
    dateTo: at.add(const Duration(seconds: 30)),
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'apple-watch-test',
    sourceId: 'com.apple.health',
    sourceName: 'Apple Watch',
    recordingMethod: RecordingMethod.automatic,
  );
}

HealthDataPoint _sleepPoint({required DateTime from, required DateTime to}) {
  return HealthDataPoint(
    uuid: 'auto-sleep-${to.microsecondsSinceEpoch}',
    value: NumericHealthValue(numericValue: 1),
    type: HealthDataType.SLEEP_ASLEEP,
    unit: HealthDataUnit.MINUTE,
    dateFrom: from,
    dateTo: to,
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'apple-watch-test',
    sourceId: 'com.apple.health',
    sourceName: 'Apple Watch',
    recordingMethod: RecordingMethod.automatic,
  );
}

HealthDataPoint _workoutPoint({required DateTime from, required DateTime to}) {
  return HealthDataPoint(
    uuid: 'auto-workout-${to.microsecondsSinceEpoch}',
    value: WorkoutHealthValue(
      workoutActivityType:
          HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING,
    ),
    type: HealthDataType.WORKOUT,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: from,
    dateTo: to,
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'apple-watch-test',
    sourceId: 'com.apple.health',
    sourceName: 'Apple Watch',
    recordingMethod: RecordingMethod.automatic,
  );
}
