library;

/// Types of meditation practice.
enum MeditationType {
  bodyScan,
  breathing,
  visualization,
  lovingKindness,
  walking,
}

/// Difficulty level for meditation sessions.
enum MeditationDifficulty {
  beginner,
  intermediate,
  advanced,
}

/// A guided meditation session with a script.
class MeditationSession {
  const MeditationSession({
    required this.title,
    required this.description,
    required this.duration,
    required this.type,
    required this.difficulty,
    required this.script,
  });

  final String title;
  final String description;
  final Duration duration;
  final MeditationType type;
  final MeditationDifficulty difficulty;

  /// Ordered list of script segments (one per step/cue).
  final List<String> script;

  /// Duration formatted as human-readable string.
  String get durationLabel {
    if (duration.inMinutes < 1) return '${duration.inSeconds}s';
    return '${duration.inMinutes} min';
  }

  /// Number of script steps.
  int get stepCount => script.length;

  /// Average seconds per script step.
  double get secondsPerStep =>
      stepCount > 0 ? duration.inSeconds / stepCount : 0;
}

/// Pre-built library of 10 guided meditation sessions.
class MeditationLibrary {
  const MeditationLibrary();

  /// All available sessions.
  List<MeditationSession> get sessions => _sessions;

  /// Filter sessions by type.
  List<MeditationSession> byType(MeditationType type) {
    return _sessions.where((s) => s.type == type).toList();
  }

  /// Filter sessions by difficulty.
  List<MeditationSession> byDifficulty(MeditationDifficulty difficulty) {
    return _sessions.where((s) => s.difficulty == difficulty).toList();
  }

  /// Filter sessions that fit within [maxMinutes].
  List<MeditationSession> byMaxDuration(int maxMinutes) {
    return _sessions
        .where((s) => s.duration.inMinutes <= maxMinutes)
        .toList();
  }

  /// Find a session by title (case-insensitive).
  MeditationSession? find(String title) {
    try {
      return _sessions.firstWhere(
        (s) => s.title.toLowerCase() == title.toLowerCase(),
      );
    } on StateError {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// 10 pre-built meditation sessions
// ---------------------------------------------------------------------------

const List<MeditationSession> _sessions = [
  // 1. Morning Energy — 5 min breathing
  MeditationSession(
    title: 'Morning Energy',
    description:
        'An energizing breath practice to start your day with clarity and focus.',
    duration: Duration(minutes: 5),
    type: MeditationType.breathing,
    difficulty: MeditationDifficulty.beginner,
    script: [
      'Find a comfortable seated position. Close your eyes gently.',
      'Take three deep breaths — in through the nose, out through the mouth.',
      'Begin rhythmic breathing: inhale for 4 counts, exhale for 4 counts.',
      'Gradually increase to inhale for 4, hold for 2, exhale for 6.',
      'Visualize energy filling your body with each inhale.',
      'Set an intention for your day. What do you want to accomplish?',
      'Carry this clarity with you. Open your eyes when ready.',
    ],
  ),

  // 2. Stress Relief — 10 min breathing
  MeditationSession(
    title: 'Stress Relief',
    description:
        'A calming practice to release tension and restore inner peace.',
    duration: Duration(minutes: 10),
    type: MeditationType.breathing,
    difficulty: MeditationDifficulty.beginner,
    script: [
      'Settle into a comfortable position. Let your hands rest naturally.',
      'Close your eyes. Take a slow, deep breath in… and release.',
      'Scan your body from head to toe. Notice any areas of tension.',
      'Breathe into those areas. With each exhale, let the tension dissolve.',
      'Inhale for 4 counts. Hold for 4. Exhale for 6. Repeat.',
      'If thoughts arise, acknowledge them and let them drift away.',
      'You are safe. You are calm. You are exactly where you need to be.',
      'Continue this rhythm for a few more minutes.',
      'Slowly deepen your breath. Wiggle your fingers and toes.',
      'Open your eyes gently. Carry this calm into your next moment.',
    ],
  ),

  // 3. Body Scan — 15 min body scan
  MeditationSession(
    title: 'Body Scan',
    description:
        'A systematic practice of bringing awareness to every part of your body.',
    duration: Duration(minutes: 15),
    type: MeditationType.bodyScan,
    difficulty: MeditationDifficulty.intermediate,
    script: [
      'Lie down or sit comfortably. Close your eyes.',
      'Bring attention to the top of your head. Notice any sensations.',
      'Move your awareness down to your forehead, jaw, and neck.',
      'Notice your shoulders. Let them drop away from your ears.',
      'Scan down your arms to your fingertips. Feel the subtle energy.',
      'Bring awareness to your chest. Notice the rise and fall of breath.',
      'Move to your stomach. Observe without judgment.',
      'Scan your lower back, hips, and pelvis.',
      'Move down your thighs, knees, calves.',
      'Bring awareness to your ankles, feet, and toes.',
      'Now feel your body as a whole — one unified field of awareness.',
      'Breathe into any areas that need attention.',
      'Rest in this wholeness for a few moments.',
      'Slowly begin to reawaken movement. Wiggle your fingers.',
      'Open your eyes. Return to the room, refreshed and aware.',
    ],
  ),

  // 4. Sleep Preparation — 10 min visualization
  MeditationSession(
    title: 'Sleep Preparation',
    description:
        'A gentle visualization to quiet the mind and prepare for restful sleep.',
    duration: Duration(minutes: 10),
    type: MeditationType.visualization,
    difficulty: MeditationDifficulty.beginner,
    script: [
      'Lie in your bed. Get comfortable. Close your eyes.',
      'Take three slow, deep breaths. Let gravity pull you into the mattress.',
      'Imagine a warm, golden light above you, gently descending.',
      'It touches the top of your head, filling you with calm.',
      'The light flows down through your body — face, neck, shoulders.',
      'With each breath, the light dissolves any remaining tension.',
      'You are floating on a still, warm ocean. Safe and supported.',
      'The waves lull you deeper into relaxation.',
      'There is nothing to do. Nowhere to be. Just rest.',
      'Let sleep come naturally. Goodnight.',
    ],
  ),

  // 5. Focus Enhancement — 5 min breathing
  MeditationSession(
    title: 'Focus Enhancement',
    description:
        'Sharpen your concentration before a workout, meeting, or deep work session.',
    duration: Duration(minutes: 5),
    type: MeditationType.breathing,
    difficulty: MeditationDifficulty.beginner,
    script: [
      'Sit upright. Feet flat on the floor. Hands on your knees.',
      'Close your eyes. Take a sharp, quick inhale through the nose.',
      'Exhale forcefully through the mouth. Repeat 3 times.',
      'Now settle into a steady rhythm: inhale 4, exhale 4.',
      'Focus your attention on a single point — the tip of your nose.',
      'When your mind wanders, gently return to that point.',
      'You are training your attention like a muscle.',
      'Open your eyes. Your focus is sharp. You are ready.',
    ],
  ),

  // 6. Gratitude Practice — 10 min loving kindness
  MeditationSession(
    title: 'Gratitude Practice',
    description:
        'Cultivate appreciation for the people and experiences in your life.',
    duration: Duration(minutes: 10),
    type: MeditationType.lovingKindness,
    difficulty: MeditationDifficulty.beginner,
    script: [
      'Sit comfortably. Close your eyes. Breathe naturally.',
      'Bring to mind someone you love. See their face clearly.',
      'Silently say: "May you be happy. May you be healthy. May you be safe."',
      'Feel the warmth of this wish in your heart.',
      'Now think of yourself. Offer the same wish: "May I be happy…"',
      'Expand your circle. Think of a friend, then a stranger.',
      'Offer each the same loving wishes.',
      'Now think of someone you find difficult. Offer them compassion too.',
      'Feel gratitude for this moment, this breath, this life.',
      'Open your eyes. Carry this gratitude into your day.',
    ],
  ),

  // 7. Anxiety Relief — 10 min breathing
  MeditationSession(
    title: 'Anxiety Relief',
    description:
        'A grounding practice to calm anxious thoughts and restore balance.',
    duration: Duration(minutes: 10),
    type: MeditationType.breathing,
    difficulty: MeditationDifficulty.intermediate,
    script: [
      'Sit or lie down. Place one hand on your chest, one on your belly.',
      'Breathe so that only the belly hand moves. Slow, diaphragmatic breaths.',
      'Inhale for 4 counts. Hold for 7 counts. Exhale for 8 counts.',
      'Repeat this 4-7-8 pattern three times.',
      'Now name 5 things you can see. 4 you can touch. 3 you can hear.',
      'You are here. You are grounded. This moment is safe.',
      'Return to natural breathing. Notice the calm that has settled in.',
      'Anxiety is a wave — it rises, and it passes. You are the ocean.',
      'Take one more deep breath. You\'ve got this.',
      'Open your eyes when you\'re ready.',
    ],
  ),

  // 8. Walking Meditation — 15 min walking
  MeditationSession(
    title: 'Walking Meditation',
    description:
        'A mindful walking practice — bring awareness to each step.',
    duration: Duration(minutes: 15),
    type: MeditationType.walking,
    difficulty: MeditationDifficulty.intermediate,
    script: [
      'Find a quiet path — indoors or outdoors. Stand still for a moment.',
      'Feel your feet on the ground. Notice the weight distribution.',
      'Begin walking slowly. Much slower than normal.',
      'As you lift your foot, notice the sensation of weight shifting.',
      'As you place it down, feel the contact — heel, ball, toes.',
      'Coordinate breath with steps. Inhale for 2 steps, exhale for 2.',
      'If your mind wanders, gently return attention to your feet.',
      'Notice the sounds around you without labeling them.',
      'Feel the air on your skin. The temperature. The breeze.',
      'Walk with gratitude — each step is a gift of movement.',
      'Gradually increase your pace to a normal walk.',
      'Continue for a few more minutes in mindful awareness.',
      'Come to a stop. Stand still. Take a deep breath.',
      'You have walked with purpose and presence.',
      'Carry this mindfulness into the rest of your day.',
    ],
  ),

  // 9. Loving Kindness — 10 min loving kindness
  MeditationSession(
    title: 'Loving Kindness',
    description:
        'Extend compassion to yourself and others through metta meditation.',
    duration: Duration(minutes: 10),
    type: MeditationType.lovingKindness,
    difficulty: MeditationDifficulty.intermediate,
    script: [
      'Sit comfortably. Close your eyes. Breathe softly.',
      'Place your attention on your heart center.',
      'Silently repeat: "May I be filled with loving kindness."',
      '"May I be well. May I be peaceful. May I be happy."',
      'Let these words resonate in your body. Feel their truth.',
      'Now extend this wish to someone you love.',
      '"May you be filled with loving kindness…"',
      'Expand further — to your community, your country, the world.',
      '"May all beings everywhere be filled with loving kindness."',
      'Rest in this boundless compassion. Open your eyes gently.',
    ],
  ),

  // 10. Quick Reset — 3 min breathing
  MeditationSession(
    title: 'Quick Reset',
    description:
        'A rapid mindfulness hit for busy moments — just 3 minutes.',
    duration: Duration(minutes: 3),
    type: MeditationType.breathing,
    difficulty: MeditationDifficulty.beginner,
    script: [
      'Pause whatever you\'re doing. Close your eyes if you can.',
      'Take one deep breath in. Hold for 3 seconds. Release slowly.',
      'Repeat two more times. Each exhale, let go of one thought.',
      'Open your eyes. You\'re reset. Carry on with clarity.',
    ],
  ),
];
