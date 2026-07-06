/// M3: Session models for daily readiness entry, workout logging, and debrief.
///
/// These are pure data models that persist locally through Drift and can be
/// synced to Supabase when hosted. The models are designed to work offline-first.
library;

import 'package:transformfit/engine/readiness.dart';

/// A completed daily readiness check-in.
class ReadinessEntry {
  const ReadinessEntry({
    required this.id,
    required this.date,
    required this.score,
    required this.zone,
    required this.energyLevel,
    required this.sleepQuality,
    required this.sorenessMap,
    this.hrv,
    this.createdAt,
  });

  final String id;
  final DateTime date;
  final int score;
  final String zone;
  final int energyLevel;
  final int sleepQuality;
  final List<String> sorenessMap;
  final int? hrv;
  final DateTime? createdAt;

  factory ReadinessEntry.fromResult({
    required String id,
    required DateTime date,
    required ReadinessResult result,
  }) {
    return ReadinessEntry(
      id: id,
      date: date,
      score: result.score,
      zone: result.readinessZone,
      energyLevel: result.inputs.energyLevel,
      sleepQuality: result.inputs.sleepQuality,
      sorenessMap: result.inputs.sorenessMap,
      hrv: result.inputs.hrv,
      createdAt: DateTime.now(),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'score': score,
    'zone': zone,
    'energyLevel': energyLevel,
    'sleepQuality': sleepQuality,
    'sorenessMap': sorenessMap,
    'hrv': hrv,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory ReadinessEntry.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json, 'id').trim();
    final score = _intValue(json, 'score');
    final zone = _stringValue(json, 'zone').trim();
    final energyLevel = _intValue(json, 'energyLevel');
    final sleepQuality = _intValue(json, 'sleepQuality');
    final sorenessMap = _stringListValue(json, 'sorenessMap');
    final hrv = _nullableIntValue(json, 'hrv');
    if (!_validReadinessSnapshot(
      id: id,
      score: score,
      zone: zone,
      energyLevel: energyLevel,
      sleepQuality: sleepQuality,
      sorenessMap: sorenessMap,
      hrv: hrv,
    )) {
      throw const FormatException('invalid readiness snapshot');
    }
    return ReadinessEntry(
      id: id,
      date: _dateTimeValue(json, 'date'),
      score: score,
      zone: zone,
      energyLevel: energyLevel,
      sleepQuality: sleepQuality,
      sorenessMap: sorenessMap,
      hrv: hrv,
      createdAt: _nullableDateTimeValue(json, 'createdAt'),
    );
  }
}

/// A single exercise set logged during a session.
class LoggedSet {
  const LoggedSet({
    required this.id,
    this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    this.loggedAt,
    this.weightKg,
    this.reps,
    this.durationSeconds,
    this.rpe,
    this.prescribedRestSeconds,
    this.actualRestSeconds,
    this.completed = true,
  });

  final String id;
  final String? exerciseId;
  final String exerciseName;
  final int setNumber;
  final DateTime? loggedAt;
  final double? weightKg;
  final int? reps;
  final int? durationSeconds;
  final int? rpe;
  final int? prescribedRestSeconds;
  final int? actualRestSeconds;
  final bool completed;

  Map<String, Object?> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'setNumber': setNumber,
    'loggedAt': loggedAt?.toIso8601String(),
    'weightKg': weightKg,
    'reps': reps,
    'durationSeconds': durationSeconds,
    'rpe': rpe,
    'prescribedRestSeconds': prescribedRestSeconds,
    'actualRestSeconds': actualRestSeconds,
    'completed': completed,
  };

  factory LoggedSet.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json, 'id').trim();
    final exerciseId = _nullableStringValue(json, 'exerciseId')?.trim();
    final exerciseName = _stringValue(json, 'exerciseName').trim();
    final setNumber = _intValue(json, 'setNumber');
    final loggedAt = _nullableDateTimeValue(json, 'loggedAt');
    final weightKg = _nullableDoubleValue(json, 'weightKg');
    final reps = _nullableIntValue(json, 'reps');
    final durationSeconds = _nullableIntValue(json, 'durationSeconds');
    final rpe = _nullableIntValue(json, 'rpe');
    final prescribedRestSeconds = _nullableIntValue(
      json,
      'prescribedRestSeconds',
    );
    final actualRestSeconds = _nullableIntValue(json, 'actualRestSeconds');
    if (!_validLoggedSetSnapshot(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      loggedAt: loggedAt,
      weightKg: weightKg,
      reps: reps,
      durationSeconds: durationSeconds,
      rpe: rpe,
      prescribedRestSeconds: prescribedRestSeconds,
      actualRestSeconds: actualRestSeconds,
    )) {
      throw const FormatException('invalid logged set snapshot');
    }
    return LoggedSet(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      loggedAt: loggedAt,
      weightKg: weightKg,
      reps: reps,
      durationSeconds: durationSeconds,
      rpe: rpe,
      prescribedRestSeconds: prescribedRestSeconds,
      actualRestSeconds: actualRestSeconds,
      completed: _nullableBoolValue(json, 'completed') ?? true,
    );
  }
}

/// The ordered workout prescription attached to an active session.
class SessionPlanExercise {
  const SessionPlanExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.targetRpe,
    required this.targetRestSeconds,
    this.suggestedWeightKg,
  });

  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int targetRpe;
  final int targetRestSeconds;
  final int? suggestedWeightKg;

  Map<String, Object?> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'targetSets': targetSets,
    'targetReps': targetReps,
    'targetRpe': targetRpe,
    'targetRestSeconds': targetRestSeconds,
    'suggestedWeightKg': suggestedWeightKg,
  };

  factory SessionPlanExercise.fromJson(Map<String, Object?> json) {
    final exerciseId = _stringValue(json, 'exerciseId').trim();
    final exerciseName = _stringValue(json, 'exerciseName').trim();
    final targetSets = _intValue(json, 'targetSets');
    final targetReps = _intValue(json, 'targetReps');
    final targetRpe = _intValue(json, 'targetRpe');
    final targetRestSeconds = _intValue(json, 'targetRestSeconds');
    final suggestedWeightKg = _nullableIntValue(json, 'suggestedWeightKg');

    if (!_validSessionPlanExerciseSnapshot(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      targetSets: targetSets,
      targetReps: targetReps,
      targetRpe: targetRpe,
      targetRestSeconds: targetRestSeconds,
      suggestedWeightKg: suggestedWeightKg,
    )) {
      throw const FormatException('invalid session plan exercise snapshot');
    }

    return SessionPlanExercise(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      targetSets: targetSets,
      targetReps: targetReps,
      targetRpe: targetRpe,
      targetRestSeconds: targetRestSeconds,
      suggestedWeightKg: suggestedWeightKg,
    );
  }
}

/// A user-selected daily nutrition target used by activation and coach context.
class NutritionTarget {
  const NutritionTarget({
    required this.id,
    required this.createdAt,
    required this.targetType,
    required this.label,
    required this.dailyTarget,
    required this.unit,
    this.sourceIds = defaultSourceIds,
    this.safetyNote = defaultSafetyNote,
  });

  static const defaultSafetyNote =
      'Not medical nutrition advice; adjust with a qualified professional for medical needs.';

  static const defaultSourceIds = [
    'src_odphp_dietary_guidelines_2025_2030',
    'src_odphp_physical_activity_guidelines',
    'src_nutrition_target_safety_protocol',
  ];

  final String id;
  final DateTime createdAt;
  final String targetType;
  final String label;
  final double dailyTarget;
  final String unit;
  final List<String> sourceIds;
  final String safetyNote;

  bool get isValid => _validNutritionTargetSnapshot(
    id: id,
    targetType: targetType,
    label: label,
    dailyTarget: dailyTarget,
    unit: unit,
    sourceIds: sourceIds,
    safetyNote: safetyNote,
  );

  String get targetDisplay {
    final number = dailyTarget == dailyTarget.roundToDouble()
        ? dailyTarget.toInt().toString()
        : dailyTarget.toStringAsFixed(1);
    return '$number $unit';
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'targetType': targetType,
    'label': label,
    'dailyTarget': dailyTarget,
    'unit': unit,
    'sourceIds': sourceIds,
    'safetyNote': safetyNote,
  };

  factory NutritionTarget.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json, 'id').trim();
    final targetType = _stringValue(json, 'targetType').trim();
    final label = _stringValue(json, 'label').trim();
    final dailyTarget = _doubleValue(json, 'dailyTarget');
    final unit = _stringValue(json, 'unit').trim();
    final sourceIds = _stringListValue(json, 'sourceIds');
    final safetyNote = _stringValue(json, 'safetyNote').trim();

    if (!_validNutritionTargetSnapshot(
      id: id,
      targetType: targetType,
      label: label,
      dailyTarget: dailyTarget,
      unit: unit,
      sourceIds: sourceIds,
      safetyNote: safetyNote,
    )) {
      throw const FormatException('invalid nutrition target snapshot');
    }

    return NutritionTarget(
      id: id,
      createdAt: _dateTimeValue(json, 'createdAt'),
      targetType: targetType,
      label: label,
      dailyTarget: dailyTarget,
      unit: unit,
      sourceIds: List.unmodifiable(sourceIds),
      safetyNote: safetyNote,
    );
  }
}

/// A workout session with its logged sets.
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.startedAt,
    required this.readinessEntryId,
    this.endedAt,
    this.loggedSets = const [],
    this.sessionNotes,
    this.volumeMultiplier,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String readinessEntryId;
  final List<LoggedSet> loggedSets;
  final String? sessionNotes;
  final double? volumeMultiplier;

  int get totalSets => loggedSets.length;
  int get completedSets => loggedSets.where((s) => s.completed).length;
  double? get totalVolume => loggedSets
      .where((s) => s.completed && s.weightKg != null && s.reps != null)
      .fold(0.0, (sum, s) => sum! + (s.weightKg! * s.reps!));
  double get totalEffortUnits => loggedSets
      .where((s) => s.completed)
      .fold(
        0.0,
        (sum, s) =>
            sum +
            (s.reps?.toDouble() ?? 0) +
            (s.durationSeconds == null ? 0.0 : s.durationSeconds! / 30.0),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'readinessEntryId': readinessEntryId,
    'loggedSets': loggedSets.map((s) => s.toJson()).toList(),
    'sessionNotes': sessionNotes,
    'volumeMultiplier': volumeMultiplier,
    'totalSets': totalSets,
    'completedSets': completedSets,
    'totalVolume': totalVolume,
    'totalEffortUnits': totalEffortUnits,
  };

  factory WorkoutSession.fromJson(Map<String, Object?> json) {
    final rawSets = _listValue(json, 'loggedSets');
    final id = _stringValue(json, 'id').trim();
    final startedAt = _dateTimeValue(json, 'startedAt');
    final endedAt = _nullableDateTimeValue(json, 'endedAt');
    final readinessEntryId = _stringValue(json, 'readinessEntryId').trim();
    final loggedSets = rawSets
        .map((set) => LoggedSet.fromJson(_objectMapValue(set)))
        .toList();
    final volumeMultiplier = _nullableDoubleValue(json, 'volumeMultiplier');

    if (!_validWorkoutSessionSnapshot(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      readinessEntryId: readinessEntryId,
      loggedSets: loggedSets,
      volumeMultiplier: volumeMultiplier,
    )) {
      throw const FormatException('invalid workout session snapshot');
    }

    return WorkoutSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      readinessEntryId: readinessEntryId,
      loggedSets: loggedSets,
      sessionNotes: _nullableStringValue(json, 'sessionNotes'),
      volumeMultiplier: volumeMultiplier,
    );
  }
}

/// Post-session debrief — how the user felt after the workout.
class SessionDebrief {
  const SessionDebrief({
    required this.id,
    required this.sessionId,
    required this.createdAt,
    required this.perceivedExertion,
    required this.satisfaction,
    this.painNotes,
    this.whatWorked,
    this.whatToChange,
    this.nextSessionFocus,
  });

  final String id;
  final String sessionId;
  final DateTime createdAt;
  final int perceivedExertion; // 1-10 RPE
  final int satisfaction; // 1-5 stars
  final String? painNotes;
  final String? whatWorked;
  final String? whatToChange;
  final String? nextSessionFocus;

  Map<String, Object?> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'createdAt': createdAt.toIso8601String(),
    'perceivedExertion': perceivedExertion,
    'satisfaction': satisfaction,
    'painNotes': painNotes,
    'whatWorked': whatWorked,
    'whatToChange': whatToChange,
    'nextSessionFocus': nextSessionFocus,
  };

  factory SessionDebrief.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json, 'id').trim();
    final sessionId = _stringValue(json, 'sessionId').trim();
    final perceivedExertion = _intValue(json, 'perceivedExertion');
    final satisfaction = _intValue(json, 'satisfaction');

    if (!_validDebriefSnapshot(
      id: id,
      sessionId: sessionId,
      perceivedExertion: perceivedExertion,
      satisfaction: satisfaction,
    )) {
      throw const FormatException('invalid debrief snapshot');
    }

    return SessionDebrief(
      id: id,
      sessionId: sessionId,
      createdAt: _dateTimeValue(json, 'createdAt'),
      perceivedExertion: perceivedExertion,
      satisfaction: satisfaction,
      painNotes: _nullableStringValue(json, 'painNotes'),
      whatWorked: _nullableStringValue(json, 'whatWorked'),
      whatToChange: _nullableStringValue(json, 'whatToChange'),
      nextSessionFocus: _nullableStringValue(json, 'nextSessionFocus'),
    );
  }
}

Map<String, Object?> _objectMapValue(Object? value) {
  return Map<String, Object?>.from(value! as Map);
}

List<Object?> _listValue(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return const [];
  }
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

String? _nullableStringValue(Map<String, Object?> json, String key) {
  return json[key] as String?;
}

int _intValue(Map<String, Object?> json, String key) {
  return (json[key]! as num).toInt();
}

double _doubleValue(Map<String, Object?> json, String key) {
  return (json[key]! as num).toDouble();
}

int? _nullableIntValue(Map<String, Object?> json, String key) {
  return (json[key] as num?)?.toInt();
}

double? _nullableDoubleValue(Map<String, Object?> json, String key) {
  return (json[key] as num?)?.toDouble();
}

bool? _nullableBoolValue(Map<String, Object?> json, String key) {
  return json[key] as bool?;
}

bool _validWorkoutSessionSnapshot({
  required String id,
  required DateTime startedAt,
  DateTime? endedAt,
  required String readinessEntryId,
  required List<LoggedSet> loggedSets,
  double? volumeMultiplier,
}) {
  if (id.isEmpty || readinessEntryId.isEmpty) {
    return false;
  }
  if (endedAt != null && endedAt.isBefore(startedAt)) {
    return false;
  }
  if (endedAt != null && loggedSets.isEmpty) {
    return false;
  }
  final loggedSetIds = <String>{};
  for (var index = 0; index < loggedSets.length; index += 1) {
    final set = loggedSets[index];
    if (!loggedSetIds.add(set.id)) {
      return false;
    }
    if (set.setNumber != index + 1) {
      return false;
    }
  }
  if (volumeMultiplier != null &&
      (!volumeMultiplier.isFinite || volumeMultiplier < 0)) {
    return false;
  }
  return true;
}

bool _validReadinessSnapshot({
  required String id,
  required int score,
  required String zone,
  required int energyLevel,
  required int sleepQuality,
  required List<String> sorenessMap,
  int? hrv,
}) {
  if (id.isEmpty) {
    return false;
  }
  if (score < 0 || score > 100) {
    return false;
  }
  if (zone != computeReadinessZone(score) && zone != 'rest') {
    return false;
  }
  if (energyLevel < 1 || energyLevel > 10) {
    return false;
  }
  if (sleepQuality < 1 || sleepQuality > 10) {
    return false;
  }
  final sorenessEntries = <String>{};
  for (final entry in sorenessMap) {
    if (entry.isEmpty || !sorenessEntries.add(entry)) {
      return false;
    }
  }
  if (hrv != null && hrv <= 0) {
    return false;
  }
  return true;
}

bool _validDebriefSnapshot({
  required String id,
  required String sessionId,
  required int perceivedExertion,
  required int satisfaction,
}) {
  if (id.isEmpty || sessionId.isEmpty) {
    return false;
  }
  return perceivedExertion >= 1 &&
      perceivedExertion <= 10 &&
      satisfaction >= 1 &&
      satisfaction <= 5;
}

bool _validLoggedSetSnapshot({
  required String id,
  String? exerciseId,
  required String exerciseName,
  required int setNumber,
  DateTime? loggedAt,
  double? weightKg,
  int? reps,
  int? durationSeconds,
  int? rpe,
  int? prescribedRestSeconds,
  int? actualRestSeconds,
}) {
  if (id.isEmpty || exerciseName.isEmpty || setNumber <= 0) {
    return false;
  }
  if (exerciseId != null && exerciseId.isEmpty) {
    return false;
  }
  if (loggedAt != null && loggedAt.isBefore(DateTime.utc(2000))) {
    return false;
  }
  if (reps == null && durationSeconds == null) {
    return false;
  }
  if (weightKg != null && (!weightKg.isFinite || weightKg <= 0)) {
    return false;
  }
  if (reps != null && reps <= 0) {
    return false;
  }
  if (durationSeconds != null && durationSeconds <= 0) {
    return false;
  }
  if (rpe != null && (rpe < 1 || rpe > 10)) {
    return false;
  }
  if (prescribedRestSeconds != null &&
      (prescribedRestSeconds < 0 || prescribedRestSeconds > 600)) {
    return false;
  }
  if (actualRestSeconds != null &&
      (actualRestSeconds < 0 || actualRestSeconds > 7200)) {
    return false;
  }
  return true;
}

bool _validSessionPlanExerciseSnapshot({
  required String exerciseId,
  required String exerciseName,
  required int targetSets,
  required int targetReps,
  required int targetRpe,
  required int targetRestSeconds,
  int? suggestedWeightKg,
}) {
  if (exerciseId.isEmpty || exerciseName.isEmpty) {
    return false;
  }
  if (targetSets <= 0 || targetReps <= 0) {
    return false;
  }
  if (targetRpe < 1 || targetRpe > 10) {
    return false;
  }
  if (targetRestSeconds < 0 || targetRestSeconds > 600) {
    return false;
  }
  if (suggestedWeightKg != null && suggestedWeightKg <= 0) {
    return false;
  }
  return true;
}

bool _validNutritionTargetSnapshot({
  required String id,
  required String targetType,
  required String label,
  required double dailyTarget,
  required String unit,
  required List<String> sourceIds,
  required String safetyNote,
}) {
  const allowedTypes = {'protein', 'hydration', 'recovery_fuel', 'meal_rhythm'};
  const allowedUnits = {'g/day', 'ml/day', 'meals/day', 'times/day'};
  const allowedSources = {
    'src_odphp_dietary_guidelines_2025_2030',
    'src_odphp_physical_activity_guidelines',
    'src_nutrition_target_safety_protocol',
  };

  if (id.isEmpty || targetType.isEmpty || label.isEmpty || unit.isEmpty) {
    return false;
  }
  if (!allowedTypes.contains(targetType) || !allowedUnits.contains(unit)) {
    return false;
  }
  if (!dailyTarget.isFinite || dailyTarget <= 0) {
    return false;
  }
  final maxByUnit = switch (unit) {
    'g/day' => 300.0,
    'ml/day' => 6000.0,
    'meals/day' => 10.0,
    'times/day' => 8.0,
    _ => 0.0,
  };
  if (dailyTarget > maxByUnit) {
    return false;
  }
  if (sourceIds.isEmpty || sourceIds.length > allowedSources.length) {
    return false;
  }
  final seenSources = <String>{};
  for (final sourceId in sourceIds) {
    if (sourceId.isEmpty ||
        !allowedSources.contains(sourceId) ||
        !seenSources.add(sourceId)) {
      return false;
    }
  }
  final lowerSafetyNote = safetyNote.toLowerCase();
  if (!lowerSafetyNote.contains('not medical nutrition advice') ||
      lowerSafetyNote.contains('weight loss') ||
      lowerSafetyNote.contains('detox') ||
      safetyNote.length > 140) {
    return false;
  }
  return true;
}

DateTime _dateTimeValue(Map<String, Object?> json, String key) {
  return DateTime.parse(json[key]! as String);
}

DateTime? _nullableDateTimeValue(Map<String, Object?> json, String key) {
  final value = json[key] as String?;
  return value == null ? null : DateTime.parse(value);
}
