library;

import 'dart:math' as math;

/// Difficulty tiers for weekly challenges.
enum ChallengeDifficulty {
  easy,
  medium,
  hard,
}

/// Categories that challenges can belong to.
enum ChallengeCategory {
  workout,
  nutrition,
  wellness,
  consistency,
  performance,
}

/// A single weekly challenge with tracking.
class WeeklyChallenge {
  const WeeklyChallenge({
    required this.title,
    required this.description,
    required this.target,
    required this.progress,
    required this.reward,
    required this.difficulty,
    required this.category,
  });

  final String title;
  final String description;
  final int target;
  final int progress;
  final int reward; // XP reward
  final ChallengeDifficulty difficulty;
  final ChallengeCategory category;

  /// Whether the challenge has been completed.
  bool get isCompleted => progress >= target;

  /// Progress as a fraction 0.0–1.0.
  double get progressPercent =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  /// Returns a copy with updated [progress].
  WeeklyChallenge withProgress(int newProgress) => WeeklyChallenge(
        title: title,
        description: description,
        target: target,
        progress: newProgress,
        reward: reward,
        difficulty: difficulty,
        category: category,
      );
}

// ---------------------------------------------------------------------------
// Challenge templates — 15 hand-crafted challenge definitions
// ---------------------------------------------------------------------------

class _ChallengeTemplate {
  const _ChallengeTemplate({
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
    required this.difficulty,
    required this.category,
  });

  final String title;
  final String description;
  final int target;
  final int reward;
  final ChallengeDifficulty difficulty;
  final ChallengeCategory category;
}

const List<_ChallengeTemplate> _templates = [
  // Workout challenges
  _ChallengeTemplate(
    title: 'Log 4 workouts',
    description: 'Complete and log at least 4 workouts this week.',
    target: 4,
    reward: 200,
    difficulty: ChallengeDifficulty.medium,
    category: ChallengeCategory.workout,
  ),
  _ChallengeTemplate(
    title: 'Try a new exercise',
    description: 'Log at least one exercise you haven\'t done before.',
    target: 1,
    reward: 100,
    difficulty: ChallengeDifficulty.easy,
    category: ChallengeCategory.workout,
  ),
  _ChallengeTemplate(
    title: 'Achieve a new PR',
    description: 'Set a personal record on any lift or exercise.',
    target: 1,
    reward: 300,
    difficulty: ChallengeDifficulty.hard,
    category: ChallengeCategory.performance,
  ),
  _ChallengeTemplate(
    title: 'Complete 6 workouts',
    description: 'Push yourself — 6 logged sessions in one week.',
    target: 6,
    reward: 350,
    difficulty: ChallengeDifficulty.hard,
    category: ChallengeCategory.workout,
  ),
  _ChallengeTemplate(
    title: 'Log 150 total sets',
    description: 'Accumulate 150 sets across all workouts this week.',
    target: 150,
    reward: 250,
    difficulty: ChallengeDifficulty.hard,
    category: ChallengeCategory.workout,
  ),

  // Nutrition challenges
  _ChallengeTemplate(
    title: 'Hit your protein target 5 days',
    description: 'Meet your daily protein goal on at least 5 days.',
    target: 5,
    reward: 200,
    difficulty: ChallengeDifficulty.medium,
    category: ChallengeCategory.nutrition,
  ),
  _ChallengeTemplate(
    title: 'Log every meal for 7 days',
    description: 'Track all meals — breakfast, lunch, dinner — every day.',
    target: 7,
    reward: 250,
    difficulty: ChallengeDifficulty.medium,
    category: ChallengeCategory.nutrition,
  ),
  _ChallengeTemplate(
    title: 'Drink 8 glasses of water daily',
    description: 'Stay hydrated all week — log water intake every day.',
    target: 7,
    reward: 150,
    difficulty: ChallengeDifficulty.easy,
    category: ChallengeCategory.nutrition,
  ),
  _ChallengeTemplate(
    title: 'Hit calorie target 6 days',
    description: 'Stay within 10% of your calorie goal for 6 days.',
    target: 6,
    reward: 250,
    difficulty: ChallengeDifficulty.medium,
    category: ChallengeCategory.nutrition,
  ),

  // Wellness challenges
  _ChallengeTemplate(
    title: 'Complete a mindfulness session every day',
    description: 'Do at least one meditation or breathing exercise daily.',
    target: 7,
    reward: 200,
    difficulty: ChallengeDifficulty.medium,
    category: ChallengeCategory.wellness,
  ),
  _ChallengeTemplate(
    title: 'Log mood for 7 days straight',
    description: 'Check in with your mood every single day this week.',
    target: 7,
    reward: 150,
    difficulty: ChallengeDifficulty.easy,
    category: ChallengeCategory.wellness,
  ),
  _ChallengeTemplate(
    title: 'Sleep 7+ hours every night',
    description: 'Log at least 7 hours of sleep for 7 consecutive nights.',
    target: 7,
    reward: 200,
    difficulty: ChallengeDifficulty.medium,
    category: ChallengeCategory.wellness,
  ),

  // Consistency challenges
  _ChallengeTemplate(
    title: 'Perfect week',
    description: 'Log a workout, a meal, and a mood check-in every day.',
    target: 7,
    reward: 400,
    difficulty: ChallengeDifficulty.hard,
    category: ChallengeCategory.consistency,
  ),
  _ChallengeTemplate(
    title: 'Maintain your streak',
    description: 'Keep your daily activity streak alive all week.',
    target: 7,
    reward: 175,
    difficulty: ChallengeDifficulty.easy,
    category: ChallengeCategory.consistency,
  ),
  _ChallengeTemplate(
    title: 'Log 3 progressive overload sessions',
    description: 'Increase weight or reps vs. your last session, 3 times.',
    target: 3,
    reward: 300,
    difficulty: ChallengeDifficulty.hard,
    category: ChallengeCategory.performance,
  ),
];

/// Generates deterministic weekly challenges from a seed week.
class ChallengeGenerator {
  const ChallengeGenerator();

  /// Number of challenges to offer per week.
  static const int challengesPerWeek = 5;

  /// Generates a deterministic set of challenges for the week containing [now].
  ///
  /// The seed is derived from the ISO week number so the same week always
  /// produces the same selection — no randomness, fully reproducible.
  List<WeeklyChallenge> generateWeeklyChallenges({DateTime? now}) {
    final date = now ?? DateTime.now();
    final seed = _isoWeekSeed(date);
    final rng = math.Random(seed);

    // Shuffle a copy deterministically and pick [challengesPerWeek].
    final pool = List<_ChallengeTemplate>.of(_templates);
    _shuffleWith(pool, rng);

    return pool.take(challengesPerWeek).map((tpl) {
      return WeeklyChallenge(
        title: tpl.title,
        description: tpl.description,
        target: tpl.target,
        progress: 0,
        reward: tpl.reward,
        difficulty: tpl.difficulty,
        category: tpl.category,
      );
    }).toList();
  }

  /// Returns only challenges that are not yet completed.
  List<WeeklyChallenge> getActiveChallenges(List<WeeklyChallenge> challenges) {
    return challenges.where((c) => !c.isCompleted).toList();
  }

  /// Returns only completed challenges.
  List<WeeklyChallenge> getCompletedChallenges(
    List<WeeklyChallenge> challenges,
  ) {
    return challenges.where((c) => c.isCompleted).toList();
  }

  /// Total XP available from all challenges.
  int totalAvailableXp(List<WeeklyChallenge> challenges) {
    return challenges.fold<int>(0, (sum, c) => sum + c.reward);
  }

  /// Total XP earned from completed challenges.
  int totalEarnedXp(List<WeeklyChallenge> challenges) {
    return getCompletedChallenges(challenges)
        .fold<int>(0, (sum, c) => sum + c.reward);
  }

  // ---------------------------------------------------------------------------
  // Deterministic helpers
  // ---------------------------------------------------------------------------

  /// Produces a deterministic int seed from the ISO week of [date].
  static int _isoWeekSeed(DateTime date) {
    // ISO week: week 1 of a year contains the first Thursday.
    final jan4 = DateTime(date.year, 1, 4);
    final dayOfYear = date.difference(jan4).inDays + 4;
    final weekNumber = ((dayOfYear - 1) / 7).floor();
    return date.year * 100 + weekNumber;
  }

  /// Fisher-Yates shuffle using [rng].
  static void _shuffleWith<T>(List<T> list, math.Random rng) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
