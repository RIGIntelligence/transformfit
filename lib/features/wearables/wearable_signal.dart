library;

import 'package:transformfit/features/session/models.dart';

const wearableIntegrationSourceIds = [
  'src_apple_healthkit_data_types',
  'src_android_health_connect_overview',
  'src_android_health_connect_sleep',
  'src_flutter_health_package',
];

const _allowedWearableSources = {
  'apple_healthkit',
  'android_health_connect',
  'health_package',
  'local_sample',
};

const _allowedSyncStates = {
  'synced',
  'pending_permission',
  'unavailable',
  'sample',
};

const _allowedWearableSourceIds = {
  'src_apple_healthkit_data_types',
  'src_android_health_connect_overview',
  'src_android_health_connect_sleep',
  'src_flutter_health_package',
};

class WearableSignal {
  const WearableSignal({
    required this.id,
    required this.capturedAt,
    required this.source,
    required this.syncState,
    this.stepsToday,
    this.restingHeartRateBpm,
    this.heartRateVariabilityMs,
    this.sleepMinutes,
    this.activeEnergyKcal,
    this.workoutMinutes,
    this.sourceIds = wearableIntegrationSourceIds,
  });

  factory WearableSignal.localSample({DateTime? capturedAt}) {
    final now = capturedAt ?? DateTime.now();
    return WearableSignal(
      id: 'wearable-sample-${now.microsecondsSinceEpoch}',
      capturedAt: now,
      source: 'local_sample',
      syncState: 'sample',
      stepsToday: 6420,
      restingHeartRateBpm: 59,
      heartRateVariabilityMs: 68,
      sleepMinutes: 443,
      activeEnergyKcal: 410,
      workoutMinutes: 38,
    );
  }

  final String id;
  final DateTime capturedAt;
  final String source;
  final String syncState;
  final int? stepsToday;
  final int? restingHeartRateBpm;
  final int? heartRateVariabilityMs;
  final int? sleepMinutes;
  final int? activeEnergyKcal;
  final int? workoutMinutes;
  final List<String> sourceIds;

  bool get isValid => _validWearableSignalSnapshot(
    id: id,
    source: source,
    syncState: syncState,
    stepsToday: stepsToday,
    restingHeartRateBpm: restingHeartRateBpm,
    heartRateVariabilityMs: heartRateVariabilityMs,
    sleepMinutes: sleepMinutes,
    activeEnergyKcal: activeEnergyKcal,
    workoutMinutes: workoutMinutes,
    sourceIds: sourceIds,
  );

  String get sourceLabel => switch (source) {
    'apple_healthkit' => 'Apple HealthKit',
    'android_health_connect' => 'Android Health Connect',
    'local_sample' => 'Local wearable sample',
    _ => 'Health package bridge',
  };

  String get syncLabel => switch (syncState) {
    'synced' => 'Synced',
    'sample' => 'Sample synced',
    'pending_permission' => 'Permission needed',
    _ => 'Unavailable',
  };

  String get sourceTraceLabel =>
      '${sourceIds.length} ${sourceIds.length == 1 ? 'source' : 'sources'}';

  bool get hasUsableSync => syncState == 'synced' || syncState == 'sample';

  bool get needsPermission => syncState == 'pending_permission';

  String get sleepLabel => sleepMinutes == null
      ? 'Sleep not available'
      : '${(sleepMinutes! / 60).toStringAsFixed(1)}h sleep';

  String get hrvLabel => heartRateVariabilityMs == null
      ? 'HRV not available'
      : '${heartRateVariabilityMs!} ms HRV';

  String get restingHeartRateLabel => restingHeartRateBpm == null
      ? 'Resting heart rate not available'
      : '${restingHeartRateBpm!} bpm resting HR';

  String get stepsLabel =>
      stepsToday == null ? 'Steps not available' : '${stepsToday!} steps';

  Map<String, Object?> toJson() => {
    'id': id,
    'capturedAt': capturedAt.toIso8601String(),
    'source': source,
    'syncState': syncState,
    'stepsToday': stepsToday,
    'restingHeartRateBpm': restingHeartRateBpm,
    'heartRateVariabilityMs': heartRateVariabilityMs,
    'sleepMinutes': sleepMinutes,
    'activeEnergyKcal': activeEnergyKcal,
    'workoutMinutes': workoutMinutes,
    'sourceIds': sourceIds,
  };

  factory WearableSignal.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json, 'id').trim();
    final source = _stringValue(json, 'source').trim();
    final syncState = _stringValue(json, 'syncState').trim();
    final stepsToday = _nullableIntValue(json, 'stepsToday');
    final restingHeartRateBpm = _nullableIntValue(json, 'restingHeartRateBpm');
    final heartRateVariabilityMs = _nullableIntValue(
      json,
      'heartRateVariabilityMs',
    );
    final sleepMinutes = _nullableIntValue(json, 'sleepMinutes');
    final activeEnergyKcal = _nullableIntValue(json, 'activeEnergyKcal');
    final workoutMinutes = _nullableIntValue(json, 'workoutMinutes');
    final sourceIds = _stringListValue(json, 'sourceIds');

    if (!_validWearableSignalSnapshot(
      id: id,
      source: source,
      syncState: syncState,
      stepsToday: stepsToday,
      restingHeartRateBpm: restingHeartRateBpm,
      heartRateVariabilityMs: heartRateVariabilityMs,
      sleepMinutes: sleepMinutes,
      activeEnergyKcal: activeEnergyKcal,
      workoutMinutes: workoutMinutes,
      sourceIds: sourceIds,
    )) {
      throw const FormatException('invalid wearable signal snapshot');
    }

    return WearableSignal(
      id: id,
      capturedAt: _dateTimeValue(json, 'capturedAt'),
      source: source,
      syncState: syncState,
      stepsToday: stepsToday,
      restingHeartRateBpm: restingHeartRateBpm,
      heartRateVariabilityMs: heartRateVariabilityMs,
      sleepMinutes: sleepMinutes,
      activeEnergyKcal: activeEnergyKcal,
      workoutMinutes: workoutMinutes,
      sourceIds: List.unmodifiable(sourceIds),
    );
  }
}

class WearableReadinessInsight {
  const WearableReadinessInsight({
    required this.status,
    required this.statusLabel,
    required this.detail,
    required this.primaryAdjustment,
    required this.readinessModifier,
    required this.confidence,
    required this.sourceIds,
    required this.connected,
  });

  final String status;
  final String statusLabel;
  final String detail;
  final String primaryAdjustment;
  final int readinessModifier;
  final double confidence;
  final List<String> sourceIds;
  final bool connected;

  String get modifierLabel {
    if (readinessModifier == 0) return '0 readiness points';
    final sign = readinessModifier > 0 ? '+' : '';
    return '$sign$readinessModifier readiness points';
  }

  String get confidenceLabel => '${(confidence * 100).round()}% confidence';

  String get sourceTraceLabel =>
      '${sourceIds.length} ${sourceIds.length == 1 ? 'source' : 'sources'}';

  String get semanticLabel =>
      'Wearable status $statusLabel, modifier $modifierLabel, '
      '$confidenceLabel. $detail';
}

WearableReadinessInsight buildWearableReadinessInsight(
  WearableSignal? signal, {
  ReadinessEntry? readiness,
}) {
  if (signal == null) {
    return const WearableReadinessInsight(
      status: 'not_connected',
      statusLabel: 'HealthKit / Health Connect ready',
      detail:
          'Connect wearable data to add sleep, HRV, resting heart rate, steps, and training minutes to coach context.',
      primaryAdjustment: 'Run on readiness until wearable sync is connected',
      readinessModifier: 0,
      confidence: 0.62,
      sourceIds: wearableIntegrationSourceIds,
      connected: false,
    );
  }

  if (!signal.hasUsableSync) {
    final needsPermission = signal.needsPermission;
    return WearableReadinessInsight(
      status: needsPermission ? 'permission_needed' : 'sync_unavailable',
      statusLabel: needsPermission
          ? 'Wearable permission needed'
          : 'Wearable sync unavailable',
      detail: needsPermission
          ? '${signal.sourceLabel} is not authorized yet. DAI will use readiness and logged training until the user opts in.'
          : '${signal.sourceLabel} is unavailable. DAI will not infer recovery from missing wearable data.',
      primaryAdjustment: needsPermission
          ? 'Keep readiness primary until wearable permission is granted'
          : 'Use manual readiness while wearable sync is unavailable',
      readinessModifier: 0,
      confidence: needsPermission ? 0.66 : 0.64,
      sourceIds: signal.sourceIds,
      connected: false,
    );
  }

  final readinessScore = readiness?.score;
  final lowSleep = signal.sleepMinutes != null && signal.sleepMinutes! < 360;
  final lowHrv =
      signal.heartRateVariabilityMs != null &&
      signal.heartRateVariabilityMs! < 38;
  final elevatedRestingHeart =
      signal.restingHeartRateBpm != null && signal.restingHeartRateBpm! >= 74;
  final strongRecovery =
      signal.sleepMinutes != null &&
      signal.sleepMinutes! >= 420 &&
      signal.heartRateVariabilityMs != null &&
      signal.heartRateVariabilityMs! >= 58 &&
      (signal.restingHeartRateBpm == null || signal.restingHeartRateBpm! <= 64);

  if (lowSleep || (lowHrv && elevatedRestingHeart)) {
    final driver = lowSleep
        ? signal.sleepLabel
        : '${signal.hrvLabel}, ${signal.restingHeartRateLabel}';
    return WearableReadinessInsight(
      status: 'recovery_bias',
      statusLabel: 'Recovery-biased wearable signal',
      detail:
          '$driver is weighting the plan toward lower load, more rest, and cleaner form.',
      primaryAdjustment: 'Bias toward recovery-safe training',
      readinessModifier: readinessScore != null && readinessScore < 45
          ? -10
          : -7,
      confidence: lowSleep && lowHrv ? 0.86 : 0.78,
      sourceIds: signal.sourceIds,
      connected: true,
    );
  }

  if (strongRecovery) {
    return WearableReadinessInsight(
      status: 'ready_bias',
      statusLabel: 'Ready-biased wearable signal',
      detail:
          '${signal.sleepLabel}, ${signal.hrvLabel}, and ${signal.restingHeartRateLabel} support normal progression if sets stay clean.',
      primaryAdjustment: 'Allow normal progression with set-by-set checks',
      readinessModifier: 4,
      confidence: 0.8,
      sourceIds: signal.sourceIds,
      connected: true,
    );
  }

  return WearableReadinessInsight(
    status: 'neutral',
    statusLabel: signal.syncLabel,
    detail:
        '${signal.sourceLabel} is connected; wearable data stays context, not an override.',
    primaryAdjustment: 'Keep readiness and logged sets as the primary signal',
    readinessModifier: 0,
    confidence: 0.72,
    sourceIds: signal.sourceIds,
    connected: true,
  );
}

bool wearableSignalCopyIsGateSafe(WearableReadinessInsight insight) {
  final copy = [
    insight.status,
    insight.statusLabel,
    insight.detail,
    insight.primaryAdjustment,
  ].join(' ').toLowerCase();
  const blocked = [
    'burn fat',
    'diagnose',
    'medical advice',
    'no excuses',
    'punish',
    'shame',
    'weight loss',
  ];
  final emoji = RegExp('[\u{1F300}-\u{1F9FF}]', unicode: true);
  return blocked.every((term) => !copy.contains(term)) && !emoji.hasMatch(copy);
}

bool _validWearableSignalSnapshot({
  required String id,
  required String source,
  required String syncState,
  int? stepsToday,
  int? restingHeartRateBpm,
  int? heartRateVariabilityMs,
  int? sleepMinutes,
  int? activeEnergyKcal,
  int? workoutMinutes,
  required List<String> sourceIds,
}) {
  if (id.isEmpty ||
      !_allowedWearableSources.contains(source) ||
      !_allowedSyncStates.contains(syncState)) {
    return false;
  }
  if (stepsToday != null && (stepsToday < 0 || stepsToday > 100000)) {
    return false;
  }
  if (restingHeartRateBpm != null &&
      (restingHeartRateBpm < 30 || restingHeartRateBpm > 220)) {
    return false;
  }
  if (heartRateVariabilityMs != null &&
      (heartRateVariabilityMs <= 0 || heartRateVariabilityMs > 300)) {
    return false;
  }
  if (sleepMinutes != null && (sleepMinutes < 0 || sleepMinutes > 1440)) {
    return false;
  }
  if (activeEnergyKcal != null &&
      (activeEnergyKcal < 0 || activeEnergyKcal > 10000)) {
    return false;
  }
  if (workoutMinutes != null && (workoutMinutes < 0 || workoutMinutes > 1440)) {
    return false;
  }
  if (sourceIds.isEmpty ||
      sourceIds.length > _allowedWearableSourceIds.length) {
    return false;
  }
  final seenSources = <String>{};
  for (final sourceId in sourceIds) {
    if (sourceId.isEmpty ||
        !_allowedWearableSourceIds.contains(sourceId) ||
        !seenSources.add(sourceId)) {
      return false;
    }
  }
  return true;
}

List<Object?> _listValue(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return const [];
  return List<Object?>.from(value as List);
}

List<String> _stringListValue(Map<String, Object?> json, String key) {
  return _listValue(
    json,
    key,
  ).map((value) => (value as String).trim()).toList();
}

String _stringValue(Map<String, Object?> json, String key) {
  return json[key]! as String;
}

int? _nullableIntValue(Map<String, Object?> json, String key) {
  return (json[key] as num?)?.toInt();
}

DateTime _dateTimeValue(Map<String, Object?> json, String key) {
  return DateTime.parse(json[key]! as String);
}
