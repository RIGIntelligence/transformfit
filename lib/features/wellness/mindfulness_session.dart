/// Guided breathing and meditation session engine.
///
/// Mindfulness-based interventions have robust evidence for improving
/// both mental and physical health outcomes in athletic and general
/// populations.
///
/// Evidence base:
/// - Box breathing (4-4-4-4): Used by US Navy SEALs for stress regulation.
///   Equal-ratio breathing at 5-6 breaths/min maximizes respiratory sinus
///   arrhythmia (RSA), promoting vagal tone (Lehrer & Gevirtz, 2014).
/// - 4-7-8 breathing (Dr. Andrew Weil): Extended exhale ratio activates
///   parasympathetic nervous system. The 4:7:8 ratio produces a
///   respiratory rate of ~3.2 breaths/min, well below the 6-breath/min
///   threshold for maximal HRV enhancement (Bernardi et al., 2002).
/// - Body scan meditation: Systematic attention to body regions reduces
///   somatic anxiety and improves interoceptive awareness (Mehling et
///   al., 2012, "The multidimensional assessment of interoceptive
///   awareness").
/// - Gratitude practice: Emmons & McCullough (2003) — weekly gratitude
///   journaling improves well-being, sleep quality, and reduces
///   inflammation markers.
/// - Visualization: Mental imagery activates similar neural pathways as
///   physical execution (Jeannerod, 1995). Athletic performance
///   visualization improves motor skill acquisition by 13-35%.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

/// Mindfulness practice types with their characteristic parameters.
enum MindfulnessType {
  /// Box breathing: equal-ratio 4-4-4-4 pattern.
  ///
  /// Inhale 4s → Hold 4s → Exhale 4s → Hold 4s.
  /// Produces ~3.75 breaths/min. The equal ratio promotes balance
  /// between sympathetic activation (inhale) and parasympathetic
  /// recovery (exhale).
  boxBreathing,

  /// 4-7-8 calming breath: extended exhale ratio.
  ///
  /// Inhale 4s → Hold 7s → Exhale 8s.
  /// Produces ~3.2 breaths/min. The longer exhale-to-inhale ratio
  /// maximizes parasympathetic activation. The breath hold allows
  /// full oxygen saturation before the extended release.
  calmBreathing,

  /// Progressive body scan meditation.
  ///
  /// Systematic attention from head to toes (or reverse), noticing
  /// sensations without judgment. Improves interoceptive accuracy
  /// and reduces somatic anxiety.
  bodyScan,

  /// Gratitude reflection practice.
  ///
  /// Structured reflection on things to be grateful for, from broad
  /// (health, relationships) to specific (today's small wins).
  /// Regular practice increases baseline positive affect by ~25%
  /// (Emmons & McCullough, 2003).
  gratitude,

  /// Performance visualization.
  ///
  /// Guided mental imagery of successful task completion. Activates
  /// premotor and parietal cortex regions similar to actual execution
  /// (Jeannerod, 1995). Especially effective for athletes pre-competition.
  visualization,
}

/// Breathing phase within a breathing pattern.
enum BreathingPhase {
  inhale,
  holdAfterInhale,
  exhale,
  holdAfterExhale,
}

/// A single step in a mindfulness session script.
class MindfulnessStep {
  const MindfulnessStep({
    required this.instruction,
    required this.durationSeconds,
    this.phase,
  });

  /// What the user should do during this step.
  final String instruction;

  /// How long this step lasts in seconds.
  final int durationSeconds;

  /// Breathing phase (only applicable for breathing exercises).
  final BreathingPhase? phase;
}

/// A completed mindfulness session record.
class MindfulnessSession {
  const MindfulnessSession({
    required this.type,
    required this.durationMinutes,
    required this.completedAt,
    required this.quality,
    this.notes,
  });

  /// The type of mindfulness practice performed.
  final MindfulnessType type;

  /// Duration of the session in minutes.
  final int durationMinutes;

  /// When the session was completed.
  final DateTime completedAt;

  /// Self-reported quality of the session (1-10).
  ///
  /// Captures depth of engagement and perceived benefit. Consistent with
  /// the "practice quality" dimension in mindfulness research (Del Re
  /// et al., 2013).
  final int quality;

  /// Optional session notes or reflections.
  final String? notes;
}

/// Deterministic mindfulness engine.
///
/// Generates session scripts, tracks practice history, and provides
/// personalized recommendations. All computation is pure — no I/O.
class MindfulnessEngine {
  MindfulnessEngine({List<MindfulnessSession>? sessions})
      : _sessions = sessions ?? [];

  final List<MindfulnessSession> _sessions;

  /// All completed sessions (unmodifiable view).
  List<MindfulnessSession> get sessions => List.unmodifiable(_sessions);

  /// Generate a step-by-step session script.
  ///
  /// Returns a list of [MindfulnessStep] objects that form the complete
  /// session. Each step has an instruction, duration, and optional
  /// breathing phase marker.
  List<MindfulnessStep> getSessionScript({
    required MindfulnessType type,
    required int durationMinutes,
  }) {
    return switch (type) {
      MindfulnessType.boxBreathing =>
        _boxBreathingScript(durationMinutes),
      MindfulnessType.calmBreathing =>
        _calmBreathingScript(durationMinutes),
      MindfulnessType.bodyScan =>
        _bodyScanScript(durationMinutes),
      MindfulnessType.gratitude =>
        _gratitudeScript(durationMinutes),
      MindfulnessType.visualization =>
        _visualizationScript(durationMinutes),
    };
  }

  /// Get a daily recommendation based on recent practice and time of day.
  ///
  /// Strategy:
  /// - Morning: energizing practices (box breathing, visualization)
  /// - Afternoon: reset practices (calm breathing, body scan)
  /// - Evening: reflective practices (gratitude, calm breathing)
  /// - If user has been doing the same type repeatedly, suggest variety
  /// - If user is new, start with box breathing (simplest, most evidence)
  MindfulnessType getDailyRecommendation(DateTime now) {
    final hour = now.hour;

    // Check for monotony in recent sessions (last 7 days).
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = _sessions
        .where((s) => s.completedAt.isAfter(weekAgo))
        .toList();

    // If no recent sessions, recommend by time of day.
    if (recent.isEmpty) {
      if (hour >= 5 && hour < 12) return MindfulnessType.boxBreathing;
      if (hour >= 12 && hour < 17) return MindfulnessType.bodyScan;
      return MindfulnessType.gratitude;
    }

    // Count occurrences of each type.
    final counts = <MindfulnessType, int>{};
    for (final session in recent) {
      counts[session.type] = (counts[session.type] ?? 0) + 1;
    }

    // Find the least-practiced type for variety.
    final allTypes = MindfulnessType.values;
    var leastPracticed = allTypes.first;
    var leastCount = counts[allTypes.first] ?? 0;
    for (final type in allTypes.skip(1)) {
      final count = counts[type] ?? 0;
      if (count < leastCount) {
        leastCount = count;
        leastPracticed = type;
      }
    }

    return leastPracticed;
  }

  /// Total minutes of mindfulness practice in the last 7 days.
  int getWeeklyMinutes(DateTime now) {
    final weekAgo = now.subtract(const Duration(days: 7));
    return _sessions
        .where((s) => s.completedAt.isAfter(weekAgo))
        .fold<int>(0, (acc, s) => acc + s.durationMinutes);
  }

  /// Count consecutive days with at least one session, ending at [now].
  ///
  /// Consistency is more important than session length for mindfulness
  /// benefits. Even 5 minutes daily produces measurable improvements in
  /// attention and emotional regulation after 8 weeks (Zeidan et al., 2010).
  int getStreak(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final sessionDates = <DateTime>{};
    for (final session in _sessions) {
      sessionDates.add(DateTime(
        session.completedAt.year,
        session.completedAt.month,
        session.completedAt.day,
      ));
    }

    if (!sessionDates.contains(today)) return 0;

    int streak = 0;
    var checkDate = today;
    while (sessionDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // --- Breathing script generators ---

  List<MindfulnessStep> _boxBreathingScript(int durationMinutes) {
    // Box breathing cycle: 4s inhale, 4s hold, 4s exhale, 4s hold = 16s/cycle.
    const cycleSeconds = 16;
    final totalCycles = (durationMinutes * 60 / cycleSeconds).floor();

    final steps = <MindfulnessStep>[
      const MindfulnessStep(
        instruction: 'Find a comfortable position. Close your eyes or '
            'soften your gaze. We\'ll begin box breathing — a technique '
            'used by Navy SEALs to regulate stress under pressure.',
        durationSeconds: 10,
      ),
    ];

    for (var i = 0; i < totalCycles; i++) {
      final cycleLabel = 'Cycle ${i + 1} of $totalCycles. ';

      steps.add(MindfulnessStep(
        instruction: '${cycleLabel}Breathe in slowly through your nose...',
        durationSeconds: 4,
        phase: BreathingPhase.inhale,
      ));
      steps.add(MindfulnessStep(
        instruction: '${cycleLabel}Hold your breath gently...',
        durationSeconds: 4,
        phase: BreathingPhase.holdAfterInhale,
      ));
      steps.add(MindfulnessStep(
        instruction: '${cycleLabel}Exhale slowly through your mouth...',
        durationSeconds: 4,
        phase: BreathingPhase.exhale,
      ));
      steps.add(MindfulnessStep(
        instruction: '${cycleLabel}Hold with empty lungs...',
        durationSeconds: 4,
        phase: BreathingPhase.holdAfterExhale,
      ));
    }

    steps.add(const MindfulnessStep(
      instruction: 'Release the pattern. Breathe naturally. Notice the '
          'calm stillness in your body. Take a moment before opening '
          'your eyes.',
      durationSeconds: 15,
    ));

    return steps;
  }

  List<MindfulnessStep> _calmBreathingScript(int durationMinutes) {
    // 4-7-8 cycle: 4s inhale, 7s hold, 8s exhale = 19s/cycle.
    const cycleSeconds = 19;
    final totalCycles = (durationMinutes * 60 / cycleSeconds).floor();

    final steps = <MindfulnessStep>[
      const MindfulnessStep(
        instruction: 'Sit comfortably with your back straight. Place the '
            'tip of your tongue against the ridge behind your upper front '
            'teeth. We\'ll practice the 4-7-8 breath, a natural '
            'tranquilizer for the nervous system.',
        durationSeconds: 10,
      ),
    ];

    for (var i = 0; i < totalCycles; i++) {
      final cycleLabel = 'Cycle ${i + 1} of $totalCycles. ';

      steps.add(MindfulnessStep(
        instruction: '${cycleLabel}Exhale completely through your mouth, '
            'making a whoosh sound. Then close your mouth and inhale '
            'quietly through your nose...',
        durationSeconds: 4,
        phase: BreathingPhase.inhale,
      ));
      steps.add(MindfulnessStep(
        instruction: '${cycleLabel}Hold your breath...',
        durationSeconds: 7,
        phase: BreathingPhase.holdAfterInhale,
      ));
      steps.add(MindfulnessStep(
        instruction: '${cycleLabel}Exhale completely through your mouth, '
            'whoosh sound...',
        durationSeconds: 8,
        phase: BreathingPhase.exhale,
      ));
    }

    steps.add(const MindfulnessStep(
      instruction: 'Return to natural breathing. Your nervous system is '
          'now shifted toward parasympathetic dominance. Rest here '
          'for a moment.',
      durationSeconds: 15,
    ));

    return steps;
  }

  List<MindfulnessStep> _bodyScanScript(int durationMinutes) {
    // Body scan progresses through 8 major body regions.
    const regions = [
      'feet and toes',
      'lower legs and calves',
      'knees and thighs',
      'hips and pelvis',
      'abdomen and lower back',
      'chest and upper back',
      'shoulders, arms, and hands',
      'neck, face, and head',
    ];

    final secondsPerRegion = ((durationMinutes * 60 - 25) / regions.length)
        .floor()
        .clamp(20, 120);

    final steps = <MindfulnessStep>[
      const MindfulnessStep(
        instruction: 'Lie down or sit comfortably. Close your eyes. Take '
            'three deep breaths. We\'ll move through your body from toes '
            'to crown, noticing sensations without trying to change them.',
        durationSeconds: 15,
      ),
    ];

    for (final region in regions) {
      steps.add(MindfulnessStep(
        instruction: 'Bring your attention to your $region. Notice any '
            'sensation — warmth, coolness, tension, tingling, numbness, '
            'or nothing at all. All observations are valid. Simply notice '
            'and breathe into this area.',
        durationSeconds: secondsPerRegion,
      ));
    }

    steps.add(const MindfulnessStep(
      instruction: 'Expand your awareness to encompass your entire body '
          'at once. Feel the body breathing as a whole. Rest in this '
          'full-body awareness.',
      durationSeconds: 10,
    ));

    return steps;
  }

  List<MindfulnessStep> _gratitudeScript(int durationMinutes) {
    // Gratitude practice: 3 broad categories, each ~1/3 of time.
    final sectionSeconds = ((durationMinutes * 60 - 20) / 3).floor()
        .clamp(30, 180);

    return [
      const MindfulnessStep(
        instruction: 'Settle into a comfortable position. Close your eyes '
            'and take three slow breaths. We\'ll practice gratitude — '
            'research shows this rewires your brain for positivity over time.',
        durationSeconds: 10,
      ),
      MindfulnessStep(
        instruction: 'Think about your relationships — people who care '
            'about you, who you care about. Bring specific faces to mind. '
            'What have they done recently that you appreciate? '
            'Let the warmth of gratitude fill your chest.',
        durationSeconds: sectionSeconds,
      ),
      MindfulnessStep(
        instruction: 'Think about your body and health — the ability to '
            'move, to breathe, to experience the world through your senses. '
            'What did your body do for you today? Thank it silently.',
        durationSeconds: sectionSeconds,
      ),
      MindfulnessStep(
        instruction: 'Think about today — small moments of beauty, '
            'convenience, or kindness. A good meal, a kind word, a moment '
            'of quiet. What tiny wins did today bring?',
        durationSeconds: sectionSeconds,
      ),
      const MindfulnessStep(
        instruction: 'Hold all three threads of gratitude together. '
            'You are connected, capable, and surrounded by good. '
            'Carry this awareness with you as you open your eyes.',
        durationSeconds: 10,
      ),
    ];
  }

  List<MindfulnessStep> _visualizationScript(int durationMinutes) {
    // Visualization: setup → scene construction → kinesthetic rehearsal → integration.
    final phaseSeconds = ((durationMinutes * 60 - 20) / 4).floor()
        .clamp(20, 120);

    return [
      const MindfulnessStep(
        instruction: 'Close your eyes and take several deep breaths. '
            'We\'ll use visualization to mentally rehearse success. '
            'Your brain cannot fully distinguish between vividly imagined '
            'and real experiences — we\'ll use this to your advantage.',
        durationSeconds: 10,
      ),
      MindfulnessStep(
        instruction: 'Imagine yourself in your training environment — '
            'the gym, the track, the field. See the details: the lighting, '
            'the equipment, the sounds around you. Make it vivid and '
            'specific to your real environment.',
        durationSeconds: phaseSeconds,
      ),
      MindfulnessStep(
        instruction: 'Now see yourself performing at your best. Imagine '
            'the movement perfectly — the weight lifting smoothly, the '
            'stride opening effortlessly, the form pristine. Feel the '
            'muscles activating correctly. See the confidence in yourself.',
        durationSeconds: phaseSeconds,
      ),
      MindfulnessStep(
        instruction: 'Add the kinesthetic layer — feel the effort, the '
            'power, the rhythm of your best performance. Notice the '
            'sensation of mastery. Your body is learning this pattern '
            'even now, at the neural level.',
        durationSeconds: phaseSeconds,
      ),
      MindfulnessStep(
        instruction: 'Now see yourself completing the task successfully. '
            'Feel the satisfaction, the pride. Know that this outcome '
            'is available to you. Open your eyes when ready, carrying '
            'this confidence forward.',
        durationSeconds: phaseSeconds,
      ),
      const MindfulnessStep(
        instruction: 'Take a final deep breath. Open your eyes slowly. '
            'You\'ve just completed a powerful neural rehearsal.',
        durationSeconds: 10,
      ),
    ];
  }
}
