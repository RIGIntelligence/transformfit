library;

/// Achievement tiers in ascending rarity.
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
}

/// Achievement categories.
enum AchievementCategory {
  consistency,
  strength,
  wellness,
  social,
  mastery,
}

/// A single achievement definition and its progress.
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.tier,
    required this.requirement,
    required this.progress,
    required this.isUnlocked,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementTier tier;

  /// Target value to unlock (e.g. 7 for "7-day streak").
  final int requirement;

  /// Current progress toward the requirement.
  final int progress;

  final bool isUnlocked;
  final DateTime? unlockedAt;

  /// Progress as a 0.0–1.0 ratio, clamped.
  double get progressRatio =>
      requirement > 0 ? (progress / requirement).clamp(0.0, 1.0) : 0.0;

  Achievement copyWith({
    int? progress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      icon: icon,
      category: category,
      tier: tier,
      requirement: requirement,
      progress: progress ?? this.progress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// Canonical list of all 52 achievements.
List<Achievement> _defaultAchievements() {
  return [
    // ── Consistency (12) ──
    const Achievement(id: 'consistency_7', name: 'Week Warrior', description: 'Complete workouts 7 days in a row.', icon: '🔥', category: AchievementCategory.consistency, tier: AchievementTier.bronze, requirement: 7, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_30', name: 'Monthly Machine', description: 'Complete workouts 30 days in a row.', icon: '🔥', category: AchievementCategory.consistency, tier: AchievementTier.silver, requirement: 30, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_100', name: 'Century Club', description: 'Log 100 total workouts.', icon: '💯', category: AchievementCategory.consistency, tier: AchievementTier.gold, requirement: 100, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_365', name: 'Year of Iron', description: 'Log 365 total workouts.', icon: '📅', category: AchievementCategory.consistency, tier: AchievementTier.platinum, requirement: 365, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_early_bird', name: 'Early Bird', description: 'Complete 10 workouts before 7 AM.', icon: '🌅', category: AchievementCategory.consistency, tier: AchievementTier.bronze, requirement: 10, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_weekend', name: 'Weekend Warrior', description: 'Complete 20 weekend workouts.', icon: '🏋️', category: AchievementCategory.consistency, tier: AchievementTier.silver, requirement: 20, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_perfect_week', name: 'Perfect Week', description: 'Hit all daily goals for 7 straight days.', icon: '⭐', category: AchievementCategory.consistency, tier: AchievementTier.gold, requirement: 7, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_perfect_month', name: 'Perfect Month', description: 'Hit all daily goals for 30 straight days.', icon: '🌟', category: AchievementCategory.consistency, tier: AchievementTier.platinum, requirement: 30, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_50_workouts', name: 'Half Century', description: 'Log 50 total workouts.', icon: '5️⃣0️⃣', category: AchievementCategory.consistency, tier: AchievementTier.silver, requirement: 50, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_200_workouts', name: 'Double Century', description: 'Log 200 total workouts.', icon: '2️⃣0️⃣0️⃣', category: AchievementCategory.consistency, tier: AchievementTier.gold, requirement: 200, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_500_workouts', name: 'Five Hundred Club', description: 'Log 500 total workouts.', icon: '🏋️', category: AchievementCategory.consistency, tier: AchievementTier.platinum, requirement: 500, progress: 0, isUnlocked: false),
    const Achievement(id: 'consistency_14_day', name: 'Fortnight Fighter', description: 'Complete workouts 14 days in a row.', icon: '⚔️', category: AchievementCategory.consistency, tier: AchievementTier.silver, requirement: 14, progress: 0, isUnlocked: false),

    // ── Strength (12) ──
    const Achievement(id: 'strength_first_pr', name: 'First PR', description: 'Achieve your first personal record.', icon: '🏅', category: AchievementCategory.strength, tier: AchievementTier.bronze, requirement: 1, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_10_prs', name: 'PR Collector', description: 'Achieve 10 personal records.', icon: '🏅', category: AchievementCategory.strength, tier: AchievementTier.silver, requirement: 10, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_50_prs', name: 'PR Machine', description: 'Achieve 50 personal records.', icon: '🏅', category: AchievementCategory.strength, tier: AchievementTier.gold, requirement: 50, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_100kg_bench', name: '100kg Bench', description: 'Bench press 100 kg.', icon: '🏋️', category: AchievementCategory.strength, tier: AchievementTier.gold, requirement: 100, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_2x_squat', name: '2x Bodyweight Squat', description: 'Squat twice your bodyweight.', icon: '🦵', category: AchievementCategory.strength, tier: AchievementTier.platinum, requirement: 200, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_140kg_deadlift', name: 'Deadlift Beast', description: 'Deadlift 140 kg.', icon: '💀', category: AchievementCategory.strength, tier: AchievementTier.gold, requirement: 140, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_5_prs_month', name: 'Monthly Gains', description: 'Hit 5 PRs in a single month.', icon: '📈', category: AchievementCategory.strength, tier: AchievementTier.silver, requirement: 5, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_1000lb_club', name: '1000 lb Club', description: 'Combined bench+squat+deadlift ≥ 1000 lbs.', icon: '🏆', category: AchievementCategory.strength, tier: AchievementTier.platinum, requirement: 1000, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_volume_10k', name: '10 Ton Day', description: 'Lift 10,000 kg total volume in one session.', icon: '📦', category: AchievementCategory.strength, tier: AchievementTier.gold, requirement: 10000, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_first_dip', name: 'Dip Initiate', description: 'Complete your first bodyweight dip.', icon: '💪', category: AchievementCategory.strength, tier: AchievementTier.bronze, requirement: 1, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_pullup_10', name: 'Pull-Up Pro', description: 'Do 10 consecutive pull-ups.', icon: '🧗', category: AchievementCategory.strength, tier: AchievementTier.silver, requirement: 10, progress: 0, isUnlocked: false),
    const Achievement(id: 'strength_plank_5min', name: 'Iron Core', description: 'Hold a plank for 5 minutes.', icon: '🧱', category: AchievementCategory.strength, tier: AchievementTier.silver, requirement: 300, progress: 0, isUnlocked: false),

    // ── Wellness (12) ──
    const Achievement(id: 'wellness_mood_7', name: 'Mood Week', description: 'Log your mood 7 days in a row.', icon: '😊', category: AchievementCategory.wellness, tier: AchievementTier.bronze, requirement: 7, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_mood_30', name: 'Mood Month', description: 'Log your mood 30 days in a row.', icon: '😊', category: AchievementCategory.wellness, tier: AchievementTier.silver, requirement: 30, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_first_meditation', name: 'Inner Peace', description: 'Complete your first meditation session.', icon: '🧘', category: AchievementCategory.wellness, tier: AchievementTier.bronze, requirement: 1, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_meditation_30', name: 'Mindful Month', description: 'Complete 30 meditation sessions.', icon: '🧘', category: AchievementCategory.wellness, tier: AchievementTier.gold, requirement: 30, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_sleep_goal', name: 'Well Rested', description: 'Hit your sleep goal 7 nights in a row.', icon: '😴', category: AchievementCategory.wellness, tier: AchievementTier.bronze, requirement: 7, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_sleep_30', name: 'Sleep Champion', description: 'Hit your sleep goal 30 nights.', icon: '🌙', category: AchievementCategory.wellness, tier: AchievementTier.silver, requirement: 30, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_nutrition_7', name: 'Clean Eater', description: 'Log nutrition 7 days in a row.', icon: '🥗', category: AchievementCategory.wellness, tier: AchievementTier.bronze, requirement: 7, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_nutrition_30', name: 'Nutrition Pro', description: 'Log nutrition 30 days in a row.', icon: '🍎', category: AchievementCategory.wellness, tier: AchievementTier.silver, requirement: 30, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_readiness_7', name: 'Ready Week', description: 'Check readiness 7 days in a row.', icon: '⚡', category: AchievementCategory.wellness, tier: AchievementTier.bronze, requirement: 7, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_readiness_30', name: 'Always Ready', description: 'Check readiness 30 days in a row.', icon: '⚡', category: AchievementCategory.wellness, tier: AchievementTier.silver, requirement: 30, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_perfect_week_all', name: 'Holistic Week', description: 'Log mood, nutrition, sleep, and readiness for 7 days.', icon: '🌈', category: AchievementCategory.wellness, tier: AchievementTier.gold, requirement: 7, progress: 0, isUnlocked: false),
    const Achievement(id: 'wellness_meditation_100', name: 'Zen Master', description: 'Complete 100 meditation sessions.', icon: '🕉️', category: AchievementCategory.wellness, tier: AchievementTier.platinum, requirement: 100, progress: 0, isUnlocked: false),

    // ── Social (8) ──
    const Achievement(id: 'social_first_share', name: 'First Share', description: 'Share your first workout.', icon: '📤', category: AchievementCategory.social, tier: AchievementTier.bronze, requirement: 1, progress: 0, isUnlocked: false),
    const Achievement(id: 'social_first_challenge', name: 'Challenger', description: 'Join your first challenge.', icon: '🎯', category: AchievementCategory.social, tier: AchievementTier.bronze, requirement: 1, progress: 0, isUnlocked: false),
    const Achievement(id: 'social_accountability', name: 'Accountability Partner', description: 'Connect with an accountability partner.', icon: '🤝', category: AchievementCategory.social, tier: AchievementTier.bronze, requirement: 1, progress: 0, isUnlocked: false),
    const Achievement(id: 'social_5_challenges', name: 'Challenge Veteran', description: 'Complete 5 challenges.', icon: '🎯', category: AchievementCategory.social, tier: AchievementTier.silver, requirement: 5, progress: 0, isUnlocked: false),
    const Achievement(id: 'social_10_shares', name: 'Influencer', description: 'Share 10 workouts.', icon: '📢', category: AchievementCategory.social, tier: AchievementTier.silver, requirement: 10, progress: 0, isUnlocked: false),
    const Achievement(id: 'social_win_challenge', name: 'Victor', description: 'Win a challenge.', icon: '🏆', category: AchievementCategory.social, tier: AchievementTier.gold, requirement: 1, progress: 0, isUnlocked: false),
    const Achievement(id: 'social_10_challenges', name: 'Challenge Addict', description: 'Complete 10 challenges.', icon: '🎯', category: AchievementCategory.social, tier: AchievementTier.gold, requirement: 10, progress: 0, isUnlocked: false),
    const Achievement(id: 'social_mentor', name: 'Mentor', description: 'Help 5 newcomers complete their first week.', icon: '🎓', category: AchievementCategory.social, tier: AchievementTier.platinum, requirement: 5, progress: 0, isUnlocked: false),

    // ── Mastery (8) ──
    const Achievement(id: 'mastery_10_exercises', name: 'Explorer', description: 'Try 10 different exercises.', icon: '🗺️', category: AchievementCategory.mastery, tier: AchievementTier.bronze, requirement: 10, progress: 0, isUnlocked: false),
    const Achievement(id: 'mastery_25_exercises', name: 'Versatile', description: 'Try 25 different exercises.', icon: '🗺️', category: AchievementCategory.mastery, tier: AchievementTier.silver, requirement: 25, progress: 0, isUnlocked: false),
    const Achievement(id: 'mastery_50_exercises', name: 'Exercise Encyclopedia', description: 'Try 50 different exercises.', icon: '📚', category: AchievementCategory.mastery, tier: AchievementTier.gold, requirement: 50, progress: 0, isUnlocked: false),
    const Achievement(id: 'mastery_perfect_form_week', name: 'Perfect Form', description: 'Complete a week with no form corrections needed.', icon: '✅', category: AchievementCategory.mastery, tier: AchievementTier.silver, requirement: 7, progress: 0, isUnlocked: false),
    const Achievement(id: 'mastery_all_equipment', name: 'Full Arsenal', description: 'Use every equipment type at least once.', icon: '🧰', category: AchievementCategory.mastery, tier: AchievementTier.gold, requirement: 12, progress: 0, isUnlocked: false),
    const Achievement(id: 'mastery_level_10', name: 'Decade', description: 'Reach level 10.', icon: '🔟', category: AchievementCategory.mastery, tier: AchievementTier.silver, requirement: 10, progress: 0, isUnlocked: false),
    const Achievement(id: 'mastery_level_25', name: 'Quarter Century', description: 'Reach level 25.', icon: '2️⃣5️⃣', category: AchievementCategory.mastery, tier: AchievementTier.gold, requirement: 25, progress: 0, isUnlocked: false),
    const Achievement(id: 'mastery_level_50', name: 'Half Century Level', description: 'Reach level 50.', icon: '5️⃣0️⃣', category: AchievementCategory.mastery, tier: AchievementTier.platinum, requirement: 50, progress: 0, isUnlocked: false),
  ];
}

/// The achievement engine — checks, updates, and queries achievements.
class AchievementEngine {
  AchievementEngine([List<Achievement>? achievements])
      : _achievements = List.from(achievements ?? _defaultAchievements());

  final List<Achievement> _achievements;

  /// Immutable view of all achievements.
  List<Achievement> get achievements => List.unmodifiable(_achievements);

  /// Check all achievements against the provided [stats] map and unlock any
  /// that have met their requirement.
  ///
  /// [stats] keys should match achievement IDs (e.g. 'consistency_7' → 7).
  /// Returns the list of newly unlocked achievements.
  List<Achievement> checkAchievements(Map<String, int> stats, {DateTime? now}) {
    final newlyUnlocked = <Achievement>[];
    final timestamp = now ?? DateTime.now();

    for (int i = 0; i < _achievements.length; i++) {
      final a = _achievements[i];
      if (a.isUnlocked) continue;

      final currentProgress = stats[a.id] ?? a.progress;
      if (currentProgress >= a.requirement) {
        final unlocked = a.copyWith(
          progress: currentProgress,
          isUnlocked: true,
          unlockedAt: timestamp,
        );
        _achievements[i] = unlocked;
        newlyUnlocked.add(unlocked);
      } else if (currentProgress != a.progress) {
        _achievements[i] = a.copyWith(progress: currentProgress);
      }
    }

    return newlyUnlocked;
  }

  /// Get progress for a specific achievement by [id].
  double getProgress(String id) {
    final a = _achievements.firstWhere(
      (a) => a.id == id,
      orElse: () => Achievement(
        id: id, name: '', description: '', icon: '', category: AchievementCategory.mastery,
        tier: AchievementTier.bronze, requirement: 1, progress: 0, isUnlocked: false,
      ),
    );
    return a.progressRatio;
  }

  /// All unlocked achievements.
  List<Achievement> getUnlocked() {
    return _achievements.where((a) => a.isUnlocked).toList();
  }

  /// All locked achievements.
  List<Achievement> getLocked() {
    return _achievements.where((a) => !a.isUnlocked).toList();
  }

  /// The next achievement closest to being unlocked (highest progress ratio
  /// among locked achievements).
  Achievement? getNextMilestone() {
    final locked = getLocked();
    if (locked.isEmpty) return null;
    locked.sort((a, b) => b.progressRatio.compareTo(a.progressRatio));
    return locked.first;
  }

  /// Get achievements filtered by [category].
  List<Achievement> getByCategory(AchievementCategory category) {
    return _achievements.where((a) => a.category == category).toList();
  }

  /// Get achievements filtered by [tier].
  List<Achievement> getByTier(AchievementTier tier) {
    return _achievements.where((a) => a.tier == tier).toList();
  }
}
