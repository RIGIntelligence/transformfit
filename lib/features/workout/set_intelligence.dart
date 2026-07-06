import 'package:transformfit/features/session/models.dart';

const workoutLoggerIntelligenceSourceIds = [
  'src_macrofactor_workouts_product',
  'src_macrofactor_workouts_google_play',
  'src_hevy_app_store_preview',
  'src_hevy_rest_timer',
  'src_strong_app_store_preview',
  'src_fitbod_ai_why_2026',
];

class PreviousSetReference {
  const PreviousSetReference({required this.set, required this.session});

  final LoggedSet set;
  final WorkoutSession session;
}

class SetIntelligence {
  const SetIntelligence({
    required this.progressionIntent,
    required this.progressionReason,
    required this.restPace,
    required this.restDetail,
    required this.postSetCountdown,
    required this.previousReference,
    required this.readinessContext,
    required this.sourceIds,
  });

  final String progressionIntent;
  final String progressionReason;
  final String restPace;
  final String restDetail;
  final String postSetCountdown;
  final String previousReference;
  final String readinessContext;
  final List<String> sourceIds;

  String get semanticLabel =>
      'Set intelligence. Progression intent: $progressionIntent. '
      'Rest pace: $restPace. Previous reference: $previousReference. '
      'Readiness context: $readinessContext.';
}

PreviousSetReference? previousSetReferenceForExercise(
  List<WorkoutSession> history, {
  required String exerciseName,
  String? exerciseId,
}) {
  final normalizedId = exerciseId?.trim();
  final normalized = exerciseName.trim().toLowerCase();
  if (normalized.isEmpty) return null;

  if (normalizedId != null && normalizedId.isNotEmpty) {
    for (final session in history.reversed) {
      for (final set in session.loggedSets.reversed) {
        if (!set.completed) continue;
        if (set.exerciseId?.trim() == normalizedId) {
          return PreviousSetReference(set: set, session: session);
        }
      }
    }
  }

  for (final session in history.reversed) {
    for (final set in session.loggedSets.reversed) {
      if (!set.completed) continue;
      final setExerciseId = set.exerciseId?.trim();
      if (normalizedId != null &&
          normalizedId.isNotEmpty &&
          setExerciseId != null &&
          setExerciseId.isNotEmpty) {
        continue;
      }
      if (set.exerciseName.trim().toLowerCase() == normalized) {
        return PreviousSetReference(set: set, session: session);
      }
    }
  }
  return null;
}

SetIntelligence buildSetIntelligence({
  required PreviousSetReference? previousReference,
  required ReadinessEntry? readiness,
  required int currentWeightKg,
  required int currentReps,
  required int currentRpe,
  required int selectedRestSeconds,
  required int prescribedRestSeconds,
  bool painSafetyActive = false,
}) {
  final intent = _progressionIntent(
    previousReference: previousReference,
    readiness: readiness,
    currentWeightKg: currentWeightKg,
    currentReps: currentReps,
    currentRpe: currentRpe,
    painSafetyActive: painSafetyActive,
  );
  final rest = _restPace(
    selectedRestSeconds: selectedRestSeconds,
    prescribedRestSeconds: prescribedRestSeconds,
  );

  return SetIntelligence(
    progressionIntent: intent.$1,
    progressionReason: intent.$2,
    restPace: rest.$1,
    restDetail: rest.$2,
    postSetCountdown:
        'Post-set countdown: selected ${durationLabel(selectedRestSeconds)} / '
        'prescribed ${durationLabel(prescribedRestSeconds)}.',
    previousReference: previousSetReferenceLabel(previousReference),
    readinessContext: readinessContextLabel(readiness),
    sourceIds: workoutLoggerIntelligenceSourceIds,
  );
}

String previousSetReferenceLabel(PreviousSetReference? reference) {
  if (reference == null) return 'No completed set yet';
  return '${dateLabel(reference.session.startedAt)} · '
      '${setSummary(reference.set)} · '
      'readiness check-in ${reference.session.readinessEntryId}';
}

String readinessContextLabel(ReadinessEntry? readiness) {
  if (readiness == null) return 'No readiness check-in';
  return '${readiness.zone} ${readiness.score}/100';
}

String setSummary(LoggedSet set) {
  final metrics = <String>[];
  if (set.weightKg != null && set.reps != null) {
    metrics.add('${numberLabel(set.weightKg)} kg x ${set.reps} reps');
  } else if (set.reps != null) {
    metrics.add('${set.reps} reps');
  } else if (set.durationSeconds != null) {
    metrics.add('${(set.durationSeconds! / 60).round()} min');
  }
  if (set.rpe != null) metrics.add('RPE ${set.rpe}');
  return metrics.isEmpty
      ? set.exerciseName
      : '${set.exerciseName}, ${metrics.join(', ')}';
}

String numberLabel(double? value) {
  if (value == null) return '--';
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

String durationLabel(int seconds) {
  final safeSeconds = seconds.clamp(0, 600).toInt();
  final minutes = safeSeconds ~/ 60;
  final remainder = safeSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

String dateLabel(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}';
}

(String, String) _progressionIntent({
  required PreviousSetReference? previousReference,
  required ReadinessEntry? readiness,
  required int currentWeightKg,
  required int currentReps,
  required int currentRpe,
  required bool painSafetyActive,
}) {
  if (painSafetyActive) {
    return (
      'Pain safety',
      'Pain safety is active; block load progression, cap effort, and use a pain-free option or finish.',
    );
  }
  final zone = readiness?.zone.trim().toLowerCase() ?? '';
  final readinessScore = readiness?.score ?? 100;
  if (readinessScore < 45 ||
      zone.contains('recover') ||
      zone.contains('rest')) {
    return (
      'Reduce target',
      'Readiness is low; protect the habit and cap effort before chasing overload.',
    );
  }
  if (currentRpe >= 9) {
    return (
      'Hold load',
      'Effort is high; repeat clean reps before adding stress.',
    );
  }
  if (previousReference == null) {
    return (
      'Baseline set',
      'No completed reference yet; log one honest set to anchor the plan.',
    );
  }

  final previous = previousReference.set;
  final previousWeight = previous.weightKg;
  final previousReps = previous.reps;
  if (previousWeight == null || previousReps == null) {
    return (
      'Repeat clean',
      'The previous reference is incomplete; capture full weight, reps, and RPE.',
    );
  }

  if (currentWeightKg > previousWeight) {
    return (
      'Load progression',
      'Load is above the last reference; keep RPE controlled before adding more.',
    );
  }
  if (currentWeightKg < previousWeight || currentReps < previousReps) {
    return (
      'Rebuild confidence',
      'This set is below the last reference; keep quality and finish the session.',
    );
  }
  if (currentReps > previousReps) {
    return (
      'Rep progression',
      'Reps are above the last reference; finish with clean technique.',
    );
  }
  if ((previous.rpe ?? currentRpe) <= 7 && currentRpe <= 7) {
    return (
      'Add one rep next',
      'The last reference was controlled; one rep is the smallest useful overload.',
    );
  }
  return ('Hold target', 'Stay at this load until the set feels repeatable.');
}

(String, String) _restPace({
  required int selectedRestSeconds,
  required int prescribedRestSeconds,
}) {
  final selected = selectedRestSeconds.clamp(0, 600).toInt();
  final prescribed = prescribedRestSeconds.clamp(0, 600).toInt();
  if (selected == 0) {
    return (
      'Rest skipped',
      'Selected 0:00 vs prescribed ${durationLabel(prescribed)}; skip only when the next set stays crisp.',
    );
  }
  if (selected < prescribed - 15) {
    return (
      'Short rest',
      'Selected ${durationLabel(selected)} vs prescribed ${durationLabel(prescribed)}; expect fewer reps.',
    );
  }
  if (selected > prescribed + 30) {
    return (
      'Long rest',
      'Selected ${durationLabel(selected)} vs prescribed ${durationLabel(prescribed)}; useful after hard sets.',
    );
  }
  return (
    'On pace',
    'Selected ${durationLabel(selected)} matches prescribed ${durationLabel(prescribed)}.',
  );
}
