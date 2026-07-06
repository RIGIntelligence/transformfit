library;

import 'package:health/health.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';

// The health package treats these methods as excluded. Keep automatic watch and
// sensor data in the recovery signal; only user-entered manual points are filtered.
const wearableRecoveryRecordingMethodsToFilter = <RecordingMethod>[
  RecordingMethod.manual,
];

abstract interface class WearableSyncAdapter {
  Future<WearableSignal> readDailySignal({DateTime? now});
}

class HealthWearableAdapter implements WearableSyncAdapter {
  HealthWearableAdapter({Health? health}) : _health = health ?? Health();

  static const readTypes = [
    HealthDataType.STEPS,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  static const readPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  final Health _health;

  @override
  Future<WearableSignal> readDailySignal({DateTime? now}) async {
    final end = now ?? DateTime.now();
    final start = DateTime(end.year, end.month, end.day);

    try {
      await _health.configure();
      final authorized = await _health.requestAuthorization(
        readTypes,
        permissions: readPermissions,
      );
      if (!authorized) {
        return _emptySignal(
          capturedAt: end,
          source: 'health_package',
          syncState: 'pending_permission',
        );
      }

      final points = await _health.getHealthDataFromTypes(
        types: readTypes,
        startTime: start,
        endTime: end,
        recordingMethodsToFilter: wearableRecoveryRecordingMethodsToFilter,
      );
      final steps = await _health.getTotalStepsInInterval(
        start,
        end,
        includeManualEntry: false,
      );

      return wearableSignalFromHealthData(
        capturedAt: end,
        points: points,
        totalSteps: steps,
      );
    } catch (_) {
      return _emptySignal(
        capturedAt: end,
        source: 'health_package',
        syncState: 'unavailable',
      );
    }
  }
}

WearableSignal wearableSignalFromHealthData({
  required DateTime capturedAt,
  required List<HealthDataPoint> points,
  int? totalSteps,
}) {
  final source = _sourceFrom(points);
  final sleepMinutes = _sumNumeric(points, HealthDataType.SLEEP_ASLEEP);
  final activeEnergy = _sumNumeric(points, HealthDataType.ACTIVE_ENERGY_BURNED);
  final workoutMinutes = _sumWorkoutMinutes(points);
  final restingHeartRate = _latestNumeric(
    points,
    HealthDataType.RESTING_HEART_RATE,
  );
  final hrv =
      _latestNumeric(points, HealthDataType.HEART_RATE_VARIABILITY_SDNN) ??
      _latestNumeric(points, HealthDataType.HEART_RATE_VARIABILITY_RMSSD);
  final hasUsableMetric =
      totalSteps != null ||
      sleepMinutes != null ||
      activeEnergy != null ||
      restingHeartRate != null ||
      hrv != null ||
      workoutMinutes > 0;

  if (!hasUsableMetric) {
    return _emptySignal(
      capturedAt: capturedAt,
      source: source,
      syncState: 'unavailable',
    );
  }

  return WearableSignal(
    id: 'wearable-${capturedAt.microsecondsSinceEpoch}',
    capturedAt: capturedAt,
    source: source,
    syncState: 'synced',
    stepsToday: totalSteps,
    restingHeartRateBpm: restingHeartRate?.round(),
    heartRateVariabilityMs: hrv?.round(),
    sleepMinutes: sleepMinutes?.round(),
    activeEnergyKcal: activeEnergy?.round(),
    workoutMinutes: workoutMinutes == 0 ? null : workoutMinutes,
  );
}

WearableSignal _emptySignal({
  required DateTime capturedAt,
  required String source,
  required String syncState,
}) {
  return WearableSignal(
    id: 'wearable-${capturedAt.microsecondsSinceEpoch}',
    capturedAt: capturedAt,
    source: source,
    syncState: syncState,
  );
}

String _sourceFrom(List<HealthDataPoint> points) {
  if (points.any(
    (point) => point.sourcePlatform == HealthPlatformType.appleHealth,
  )) {
    return 'apple_healthkit';
  }
  if (points.any(
    (point) => point.sourcePlatform == HealthPlatformType.googleHealthConnect,
  )) {
    return 'android_health_connect';
  }
  return 'health_package';
}

num? _latestNumeric(List<HealthDataPoint> points, HealthDataType type) {
  final matches =
      points
          .where(
            (point) => point.type == type && point.value is NumericHealthValue,
          )
          .toList()
        ..sort((a, b) => b.dateTo.compareTo(a.dateTo));
  if (matches.isEmpty) return null;
  return (matches.first.value as NumericHealthValue).numericValue;
}

num? _sumNumeric(List<HealthDataPoint> points, HealthDataType type) {
  num total = 0;
  var found = false;
  for (final point in points) {
    if (point.type != type || point.value is! NumericHealthValue) continue;
    total += (point.value as NumericHealthValue).numericValue;
    found = true;
  }
  return found ? total : null;
}

int _sumWorkoutMinutes(List<HealthDataPoint> points) {
  var total = 0;
  for (final point in points.where(
    (point) => point.type == HealthDataType.WORKOUT,
  )) {
    total += point.dateTo.difference(point.dateFrom).inMinutes;
  }
  return total;
}
