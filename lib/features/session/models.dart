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
}

/// A single exercise set logged during a session.
class LoggedSet {
  const LoggedSet({
    required this.id,
    required this.exerciseName,
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.durationSeconds,
    this.rpe,
    this.completed = true,
  });

  final String id;
  final String exerciseName;
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final int? durationSeconds;
  final int? rpe;
  final bool completed;

  Map<String, Object?> toJson() => {
        'id': id,
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'weightKg': weightKg,
        'reps': reps,
        'durationSeconds': durationSeconds,
        'rpe': rpe,
        'completed': completed,
      };
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
      };
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
}
