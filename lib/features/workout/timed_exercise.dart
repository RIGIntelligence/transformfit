/// M4: Timed exercise model — planks, holds, stretches, isometric work.
///
/// Provides data models for exercises performed for a target duration rather
/// than a target rep count. Includes a pure-Dart timer state machine for
/// tracking elapsed time without Flutter's Timer dependency.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

/// Source of a timed exercise entry.
enum TimedExerciseSource {
  /// Logged during an active workout.
  active,

  /// Retroactively logged after the fact.
  manual,

  /// Auto-estimated from heart rate or accelerometer data.
  estimated,
}

/// Quality rating for a timed exercise set (1–10).
///
/// Captures subjective execution quality: was the hold stable, was form
/// clean, was breathing controlled. Useful for progressive overload on
/// isometric exercises where the only variable is hold quality.
enum TimedExerciseQuality {
  poor(1),
  belowAverage(2),
  fair(3),
  average(4),
  decent(5),
  good(6),
  aboveAverage(7),
  strong(8),
  excellent(9),
  perfect(10);

  const TimedExerciseQuality(this.value);
  final int value;

  /// Get quality from integer value (1–10), clamping to valid range.
  static TimedExerciseQuality fromValue(int value) {
    final clamped = value.clamp(1, 10);
    return TimedExerciseQuality.values.firstWhere(
      (q) => q.value == clamped,
      orElse: () => TimedExerciseQuality.average,
    );
  }

  /// Human-readable label.
  String get label => switch (this) {
        TimedExerciseQuality.poor => 'Poor',
        TimedExerciseQuality.belowAverage => 'Below Average',
        TimedExerciseQuality.fair => 'Fair',
        TimedExerciseQuality.average => 'Average',
        TimedExerciseQuality.decent => 'Decent',
        TimedExerciseQuality.good => 'Good',
        TimedExerciseQuality.aboveAverage => 'Above Average',
        TimedExerciseQuality.strong => 'Strong',
        TimedExerciseQuality.excellent => 'Excellent',
        TimedExerciseQuality.perfect => 'Perfect',
      };
}

// ── TimedExercise ────────────────────────────────────────────────────────

/// A single timed exercise log entry.
///
/// Records the exercise name, target duration, actual duration achieved,
/// and subjective quality rating. Used for planks, wall sits, dead hangs,
/// stretching, and other isometric or sustained-effort exercises.
class TimedExercise {
  const TimedExercise({
    required this.id,
    required this.exerciseName,
    required this.targetDurationSeconds,
    required this.actualDurationSeconds,
    required this.quality,
    this.source = TimedExerciseSource.active,
    this.setNumber = 1,
    this.notes,
    this.loggedAt,
  });

  /// Stable identifier.
  final String id;

  /// Exercise name (e.g., "Front Plank", "Dead Hang").
  final String exerciseName;

  /// Target hold duration in seconds.
  final int targetDurationSeconds;

  /// Actual hold duration in seconds.
  final int actualDurationSeconds;

  /// Subjective quality rating (1–10).
  final TimedExerciseQuality quality;

  /// How this entry was logged.
  final TimedExerciseSource source;

  /// Set number within the exercise block.
  final int setNumber;

  /// Optional coaching notes.
  final String? notes;

  /// When the set was logged.
  final DateTime? loggedAt;

  /// Target duration formatted as mm:ss.
  String get targetLabel => _formatDuration(targetDurationSeconds);

  /// Actual duration formatted as mm:ss.
  String get actualLabel => _formatDuration(actualDurationSeconds);

  /// Whether the actual duration met or exceeded the target.
  bool get hitTarget => actualDurationSeconds >= targetDurationSeconds;

  /// Completion percentage (capped at 100%).
  double get completionPercent {
    if (targetDurationSeconds == 0) return 1.0;
    return (actualDurationSeconds / targetDurationSeconds).clamp(0.0, 1.0);
  }

  /// Remaining seconds if the target was not met.
  int get remainingSeconds =>
      hitTarget ? 0 : targetDurationSeconds - actualDurationSeconds;

  /// Format seconds as mm:ss.
  static String _formatDuration(int totalSeconds) {
    final safe = totalSeconds.clamp(0, 5999); // cap at 99:59
    final minutes = safe ~/ 60;
    final seconds = safe.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── Serialization ────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
        'id': id,
        'exerciseName': exerciseName,
        'targetDurationSeconds': targetDurationSeconds,
        'actualDurationSeconds': actualDurationSeconds,
        'quality': quality.value,
        'source': source.name,
        'setNumber': setNumber,
        'notes': notes,
        'loggedAt': loggedAt?.toIso8601String(),
      };

  factory TimedExercise.fromJson(Map<String, Object?> json) {
    return TimedExercise(
      id: json['id'] as String,
      exerciseName: json['exerciseName'] as String,
      targetDurationSeconds: json['targetDurationSeconds'] as int,
      actualDurationSeconds: json['actualDurationSeconds'] as int,
      quality: TimedExerciseQuality.fromValue(json['quality'] as int),
      source: TimedExerciseSource.values.byName(
        json['source'] as String? ?? TimedExerciseSource.active.name,
      ),
      setNumber: json['setNumber'] as int? ?? 1,
      notes: json['notes'] as String?,
      loggedAt: json['loggedAt'] != null
          ? DateTime.parse(json['loggedAt'] as String)
          : null,
    );
  }

  TimedExercise copyWith({
    String? id,
    String? exerciseName,
    int? targetDurationSeconds,
    int? actualDurationSeconds,
    TimedExerciseQuality? quality,
    TimedExerciseSource? source,
    int? setNumber,
    String? notes,
    DateTime? loggedAt,
  }) {
    return TimedExercise(
      id: id ?? this.id,
      exerciseName: exerciseName ?? this.exerciseName,
      targetDurationSeconds:
          targetDurationSeconds ?? this.targetDurationSeconds,
      actualDurationSeconds:
          actualDurationSeconds ?? this.actualDurationSeconds,
      quality: quality ?? this.quality,
      source: source ?? this.source,
      setNumber: setNumber ?? this.setNumber,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  String toString() =>
      'TimedExercise($exerciseName, $actualLabel/$targetLabel, '
      'quality ${quality.value}/10)';
}

// ── Timer State ──────────────────────────────────────────────────────────

/// Timer states for the isometric hold tracker.
enum TimerState {
  /// Timer has not started.
  idle,

  /// Timer is actively counting.
  running,

  /// Timer is paused.
  paused,

  /// Timer has been stopped (hold ended).
  stopped,
}

// ── TimedExerciseTimer ───────────────────────────────────────────────────

/// Pure state machine for tracking timed exercise duration.
///
/// Does not use dart:async Timer — this is a deterministic model that
/// stores timestamps and computes elapsed time from them. The UI layer
/// is responsible for calling [tick] on each frame or timer interval.
///
/// Usage:
/// ```dart
/// var timer = TimedExerciseTimer(targetSeconds: 60);
/// timer = timer.start();
/// // ... time passes ...
/// timer = timer.tick(now: DateTime.now());
/// // User pauses
/// timer = timer.pause(now: DateTime.now());
/// // User resumes
/// timer = timer.resume(now: DateTime.now());
/// // Hold ends
/// final result = timer.stop(now: DateTime.now());
/// ```
class TimedExerciseTimer {
  /// Creates a timer targeting [targetSeconds].
  const TimedExerciseTimer({
    required this.targetSeconds,
    this.state = TimerState.idle,
    this.startTime,
    this.pauseTime,
    this.totalPausedMs = 0,
  });

  /// Target duration in seconds.
  final int targetSeconds;

  /// Current state of the timer.
  final TimerState state;

  /// When the timer was last started (or resumed).
  final DateTime? startTime;

  /// When the timer was last paused.
  final DateTime? pauseTime;

  /// Total accumulated paused milliseconds (across all pause/resume cycles).
  final int totalPausedMs;

  /// Start the timer. Returns a new timer in the running state.
  TimedExerciseTimer start({DateTime? now}) {
    assert(state == TimerState.idle, 'Can only start from idle state');
    return TimedExerciseTimer(
      targetSeconds: targetSeconds,
      state: TimerState.running,
      startTime: now ?? DateTime.now(),
      totalPausedMs: 0,
    );
  }

  /// Pause the timer. Returns a new timer in the paused state.
  TimedExerciseTimer pause({DateTime? now}) {
    assert(state == TimerState.running, 'Can only pause from running state');
    return TimedExerciseTimer(
      targetSeconds: targetSeconds,
      state: TimerState.paused,
      startTime: startTime,
      pauseTime: now ?? DateTime.now(),
      totalPausedMs: totalPausedMs,
    );
  }

  /// Resume from pause. Returns a new timer in the running state.
  TimedExerciseTimer resume({DateTime? now}) {
    assert(state == TimerState.paused, 'Can only resume from paused state');
    final resumeTime = now ?? DateTime.now();
    final pausedMs =
        pauseTime != null ? resumeTime.difference(pauseTime!).inMilliseconds : 0;
    return TimedExerciseTimer(
      targetSeconds: targetSeconds,
      state: TimerState.running,
      startTime: startTime,
      totalPausedMs: totalPausedMs + pausedMs,
    );
  }

  /// Stop the timer. Returns the final elapsed seconds.
  int stop({DateTime? now}) {
    return getElapsedSeconds(now: now);
  }

  /// Get the elapsed seconds, excluding paused time.
  ///
  /// If the timer is idle, returns 0. If paused, returns elapsed up to
  /// the pause point. If running, returns elapsed up to [now].
  int getElapsedSeconds({DateTime? now}) {
    if (startTime == null) return 0;
    if (state == TimerState.idle) return 0;

    final referenceTime = switch (state) {
      TimerState.paused => pauseTime ?? now ?? DateTime.now(),
      TimerState.stopped => now ?? DateTime.now(),
      _ => now ?? DateTime.now(),
    };

    final totalMs = referenceTime.difference(startTime!).inMilliseconds;
    final activeMs = totalMs - totalPausedMs;
    return (activeMs / 1000).floor().clamp(0, 5999);
  }

  /// Elapsed time formatted as mm:ss.
  String getElapsedLabel({DateTime? now}) {
    return _formatDuration(getElapsedSeconds(now: now));
  }

  /// Remaining seconds (0 if target met or exceeded).
  int getRemainingSeconds({DateTime? now}) {
    final elapsed = getElapsedSeconds(now: now);
    return (targetSeconds - elapsed).clamp(0, targetSeconds);
  }

  /// Remaining time formatted as mm:ss.
  String getRemainingLabel({DateTime? now}) {
    return _formatDuration(getRemainingSeconds(now: now));
  }

  /// Whether the target duration has been met.
  bool get isTargetMet => getElapsedSeconds() >= targetSeconds;

  /// Progress toward target (0.0–1.0, can exceed 1.0 if holding past target).
  double getProgress({DateTime? now}) {
    if (targetSeconds == 0) return 1.0;
    return getElapsedSeconds(now: now) / targetSeconds;
  }

  /// Create a [TimedExercise] log entry from the current timer state.
  TimedExercise toLogEntry({
    required String id,
    required String exerciseName,
    required TimedExerciseQuality quality,
    int setNumber = 1,
    String? notes,
  }) {
    final elapsed = getElapsedSeconds();
    return TimedExercise(
      id: id,
      exerciseName: exerciseName,
      targetDurationSeconds: targetSeconds,
      actualDurationSeconds: elapsed,
      quality: quality,
      setNumber: setNumber,
      notes: notes,
      loggedAt: DateTime.now(),
    );
  }

  static String _formatDuration(int totalSeconds) {
    final safe = totalSeconds.clamp(0, 5999);
    final minutes = safe ~/ 60;
    final seconds = safe.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  String toString() =>
      'TimedExerciseTimer(${getElapsedLabel()}/${_formatDuration(targetSeconds)}, '
      '${state.name})';
}

// ── Pre-built Timed Exercise Templates ───────────────────────────────────

/// Common timed exercise prescriptions.
class TimedExerciseTemplates {
  TimedExerciseTemplates._();

  static const frontPlank = _TimedExerciseTemplate(
    name: 'Front Plank',
    targetSeconds: 60,
    notes: 'Maintain neutral spine. Brace core, squeeze glutes. '
        'Do not let hips sag or pike.',
  );

  static const sidePlank = _TimedExerciseTemplate(
    name: 'Side Plank',
    targetSeconds: 45,
    notes: 'Stack feet or stagger. Keep hips high and shoulders stacked.',
  );

  static const deadHang = _TimedExerciseTemplate(
    name: 'Dead Hang',
    targetSeconds: 45,
    notes: 'Full grip, shoulders packed down. Breathe steadily.',
  );

  static const wallSit = _TimedExerciseTemplate(
    name: 'Wall Sit',
    targetSeconds: 60,
    notes: 'Thighs parallel to floor. Back flat against wall. '
        'Knees over ankles.',
  );

  static const lSit = _TimedExerciseTemplate(
    name: 'L-Sit',
    targetSeconds: 20,
    notes: 'Hands under hips, legs straight and parallel to floor. '
        'Shoulders depressed.',
  );

  static const all = [frontPlank, sidePlank, deadHang, wallSit, lSit];
}

class _TimedExerciseTemplate {
  const _TimedExerciseTemplate({
    required this.name,
    required this.targetSeconds,
    this.notes,
  });

  final String name;
  final int targetSeconds;
  final String? notes;
}
