/// M5: Audio coaching messages during rest periods.
///
/// Provides context-aware messages for rest, motivation, and readiness.
/// Messages vary by persona and set context. Pure Dart, deterministic.
library;

/// Coach persona for message style.
enum CoachPersona {
  /// Supportive, encouraging, warm.
  supportive,

  /// Direct, technical, data-driven.
  technical,

  /// High-energy, competitive, aggressive.
  intense,

  /// Calm, mindful, breath-focused.
  zen;
}

/// Context about the set that was just completed.
class SetContext {
  const SetContext({
    required this.exerciseName,
    required this.setNumber,
    required this.totalSets,
    required this.repsCompleted,
    required this.weightKg,
    this.rpe,
    this.isPersonalRecord = false,
    this.isLastSet = false,
  });

  final String exerciseName;
  final int setNumber;
  final int totalSets;
  final int repsCompleted;
  final double weightKg;
  final double? rpe;
  final bool isPersonalRecord;
  final bool isLastSet;

  /// Progress through the exercise (0.0 to 1.0).
  double get progress => totalSets > 0 ? setNumber / totalSets : 0;
}

/// Timer configuration for rest periods.
class RestTimerConfig {
  const RestTimerConfig({
    required this.totalSeconds,
    this.warningAtSeconds = 10,
    this.countdownFrom = 5,
  });

  final int totalSeconds;
  final int warningAtSeconds;
  final int countdownFrom;

  static const strength = RestTimerConfig(totalSeconds: 180, warningAtSeconds: 15);
  static const hypertrophy = RestTimerConfig(totalSeconds: 90, warningAtSeconds: 10);
  static const endurance = RestTimerConfig(totalSeconds: 45, warningAtSeconds: 5);
  static const warmup = RestTimerConfig(totalSeconds: 60, warningAtSeconds: 10);
}

/// Audio coaching during rest periods.
///
/// Provides context-aware messages based on persona, set performance,
/// and rest timer state. All methods are pure and deterministic.
class RestAudioCoach {
  const RestAudioCoach({this.persona = CoachPersona.supportive});

  final CoachPersona persona;

  /// Message displayed at the start of a rest period.
  String getRestMessage(SetContext ctx) {
    if (ctx.isPersonalRecord) {
      return _prRestMessage(ctx);
    }
    if (ctx.isLastSet) {
      return _lastSetRestMessage(ctx);
    }

    switch (persona) {
      case CoachPersona.supportive:
        return _supportiveRest(ctx);
      case CoachPersona.technical:
        return _technicalRest(ctx);
      case CoachPersona.intense:
        return _intenseRest(ctx);
      case CoachPersona.zen:
        return _zenRest(ctx);
    }
  }

  /// Motivational message mid-rest (typically at 50% of rest time).
  String getMotivationMessage(SetContext ctx) {
    switch (persona) {
      case CoachPersona.supportive:
        return _supportiveMotivation(ctx);
      case CoachPersona.technical:
        return _technicalMotivation(ctx);
      case CoachPersona.intense:
        return _intenseMotivation(ctx);
      case CoachPersona.zen:
        return _zenMotivation(ctx);
    }
  }

  /// "Get ready" message when rest timer is about to end.
  String getReadyMessage(SetContext ctx) {
    switch (persona) {
      case CoachPersona.supportive:
        return 'Take a deep breath. You\'ve got set ${ctx.setNumber + 1}.';
      case CoachPersona.technical:
        return 'Set ${ctx.setNumber + 1} incoming. Brace, breathe, execute.';
      case CoachPersona.intense:
        return 'Time\'s up. Next set. No hesitation.';
      case CoachPersona.zen:
        return 'Inhale confidence. Exhale doubt. Ready when you are.';
    }
  }

  /// Message for the final set of an exercise.
  String getExerciseCompleteMessage(SetContext ctx) {
    switch (persona) {
      case CoachPersona.supportive:
        return '${ctx.exerciseName} done. You showed up for every set — that matters.';
      case CoachPersona.technical:
        return '${ctx.exerciseName} complete. ${ctx.totalSets} sets logged.';
      case CoachPersona.intense:
        return '${ctx.exerciseName} — destroyed. On to the next one.';
      case CoachPersona.zen:
        return '${ctx.exerciseName} complete. Notice how that felt. Carry it forward.';
    }
  }

  // ── Private: Rest Messages ───────────────────────────────────────────

  String _supportiveRest(SetContext ctx) {
    final pct = (ctx.progress * 100).round();
    if (pct <= 33) {
      return 'Good work. Set ${ctx.setNumber} of ${ctx.totalSets}. Rest and recover.';
    } else if (pct <= 66) {
      return 'Halfway there. Your body is adapting — let it recover.';
    } else {
      return 'Almost done with ${ctx.exerciseName}. Finish strong.';
    }
  }

  String _technicalRest(SetContext ctx) {
    return 'Set ${ctx.setNumber}/${ctx.totalSets} at ${ctx.weightKg.toStringAsFixed(0)}kg × '
        '${ctx.repsCompleted}. Rest ${_formatDuration(RestTimerConfig.hypertrophy.totalSeconds)}.';
  }

  String _intenseRest(SetContext ctx) {
    if (ctx.setNumber <= 1) return 'Good start. Keep that intensity up.';
    if (ctx.setNumber >= ctx.totalSets - 1) return 'Final sets. Dig deep.';
    return 'Stay locked in. ${ctx.totalSets - ctx.setNumber} sets to go.';
  }

  String _zenRest(SetContext ctx) {
    return 'Breathe. Let your muscles absorb the work. Set ${ctx.setNumber} is behind you.';
  }

  // ── Private: Motivation Messages ─────────────────────────────────────

  String _supportiveMotivation(SetContext ctx) {
    if (ctx.rpe != null && ctx.rpe! >= 9) {
      return 'That was hard — and you did it anyway. That\'s progress.';
    }
    return 'You\'re building something. Every rep counts.';
  }

  String _technicalMotivation(SetContext ctx) {
    if (ctx.rpe != null) {
      final rpe = ctx.rpe!;
      if (rpe <= 7) return 'RPE ${rpe.toStringAsFixed(0)} — room to push next set.';
      if (rpe <= 8.5) return 'RPE ${rpe.toStringAsFixed(0)} — target range. Maintain.';
      return 'RPE ${rpe.toStringAsFixed(0)} — near limit. Good effort.';
    }
    return 'Volume accumulating. Trust the process.';
  }

  String _intenseMotivation(SetContext ctx) {
    return 'This is where champions are made. Rest hard, then work harder.';
  }

  String _zenMotivation(SetContext ctx) {
    return 'Feel your heartbeat settling. When it\'s calm, you\'re ready.';
  }

  // ── Private: PR Messages ─────────────────────────────────────────────

  String _prRestMessage(SetContext ctx) {
    switch (persona) {
      case CoachPersona.supportive:
        return 'New personal record! ${ctx.weightKg.toStringAsFixed(0)}kg × ${ctx.repsCompleted}. Take an extra minute to celebrate.';
      case CoachPersona.technical:
        return 'PR logged: ${ctx.exerciseName} ${ctx.weightKg.toStringAsFixed(0)}kg × ${ctx.repsCompleted}. Extended rest recommended.';
      case CoachPersona.intense:
        return 'NEW PR! ${ctx.weightKg.toStringAsFixed(0)}kg! You\'re a different animal today!';
      case CoachPersona.zen:
        return 'A new best. Notice the feeling — you earned this moment.';
    }
  }

  String _lastSetRestMessage(SetContext ctx) {
    switch (persona) {
      case CoachPersona.supportive:
        return 'Last set done. Give yourself credit — you finished every set prescribed.';
      case CoachPersona.technical:
        return 'Final set complete. ${ctx.totalSets} sets logged for ${ctx.exerciseName}.';
      case CoachPersona.intense:
        return 'DONE. Every single set. That\'s the difference.';
      case CoachPersona.zen:
        return 'The last set flows into the first breath of rest. Well done.';
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
