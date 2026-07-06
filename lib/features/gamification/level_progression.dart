library;

/// A reward granted at a specific level.
class LevelReward {
  const LevelReward({
    required this.level,
    required this.title,
    required this.description,
    this.unlockFeature,
    this.badge,
  });

  final int level;
  final String title;
  final String description;

  /// Feature unlocked at this level (if any).
  final String? unlockFeature;

  /// Badge icon identifier (if any).
  final String? badge;
}

/// 50-level progression system with titles, rewards, and unlockable features.
class LevelProgression {
  static const List<LevelReward> _rewards = [
    // Levels 1–10: Foundation
    LevelReward(level: 1, title: 'The Beginner', description: 'Your journey starts here.', badge: 'badge_beginner'),
    LevelReward(level: 2, title: 'First Steps', description: 'You showed up. That matters.', badge: 'badge_first_steps'),
    LevelReward(level: 3, title: 'Getting Warmed Up', description: 'The body remembers.', badge: 'badge_warm_up'),
    LevelReward(level: 4, title: 'Habit Former', description: 'Three days in a row.', badge: 'badge_habit'),
    LevelReward(level: 5, title: 'Regular', description: 'You belong here now.', unlockFeature: 'custom_workout_templates', badge: 'badge_regular'),
    LevelReward(level: 6, title: 'Dedicated', description: 'Consistency is your superpower.', badge: 'badge_dedicated'),
    LevelReward(level: 7, title: 'Committed', description: 'A week of effort.', badge: 'badge_committed'),
    LevelReward(level: 8, title: 'Persistent', description: 'You don\'t quit.', badge: 'badge_persistent'),
    LevelReward(level: 9, title: 'Focused', description: 'Your aim is true.', badge: 'badge_focused'),
    LevelReward(level: 10, title: 'Iron Apprentice', description: 'The iron teaches patience.', unlockFeature: 'advanced_analytics', badge: 'badge_iron_apprentice'),

    // Levels 11–20: Growth
    LevelReward(level: 11, title: 'Grinder', description: 'Day in, day out.', badge: 'badge_grinder'),
    LevelReward(level: 12, title: 'Resilient', description: 'You bounce back.', badge: 'badge_resilient'),
    LevelReward(level: 13, title: 'Unlucky But Unbroken', description: 'Superstition can\'t stop you.', badge: 'badge_13'),
    LevelReward(level: 14, title: 'Steady Hand', description: 'Precision in every rep.', badge: 'badge_steady'),
    LevelReward(level: 15, title: 'Iron Will', description: 'Nothing breaks your resolve.', unlockFeature: 'workout_sharing', badge: 'badge_iron_will'),
    LevelReward(level: 16, title: 'Ascending', description: 'Only up from here.', badge: 'badge_ascending'),
    LevelReward(level: 17, title: 'Relentless', description: 'You show up no matter what.', badge: 'badge_relentless'),
    LevelReward(level: 18, title: 'Forged', description: 'Pressure made you stronger.', badge: 'badge_forged'),
    LevelReward(level: 19, title: 'Veteran', description: 'You\'ve seen the grind.', badge: 'badge_veteran'),
    LevelReward(level: 20, title: 'Steel Warrior', description: 'You are the weight.', unlockFeature: 'custom_challenges', badge: 'badge_steel_warrior'),

    // Levels 21–30: Mastery
    LevelReward(level: 21, title: 'Unyielding', description: 'Bend but never break.', badge: 'badge_unyielding'),
    LevelReward(level: 22, title: 'Powerhouse', description: 'Your strength speaks.', badge: 'badge_powerhouse'),
    LevelReward(level: 23, title: 'Titan', description: 'Mountains move for you.', badge: 'badge_titan'),
    LevelReward(level: 24, title: 'Champion', description: 'Victory is habitual.', badge: 'badge_champion'),
    LevelReward(level: 25, title: 'Iron Elite', description: 'Top of the food chain.', unlockFeature: 'elite_programs', badge: 'badge_iron_elite'),
    LevelReward(level: 26, title: 'Indomitable', description: 'No challenge is enough.', badge: 'badge_indomitable'),
    LevelReward(level: 27, title: 'Phenom', description: 'Others watch and learn.', badge: 'badge_phenom'),
    LevelReward(level: 28, title: 'Apex', description: 'Peak performance personified.', badge: 'badge_apex'),
    LevelReward(level: 29, title: 'Monolith', description: 'Immovable. Unstoppable.', badge: 'badge_monolith'),
    LevelReward(level: 30, title: 'Grandmaster', description: 'Mastery in motion.', unlockFeature: 'mentor_mode', badge: 'badge_grandmaster'),

    // Levels 31–40: Transcendence
    LevelReward(level: 31, title: 'Transcendent', description: 'Beyond mortal limits.', badge: 'badge_transcendent'),
    LevelReward(level: 32, title: 'Mythic', description: 'Legends speak your name.', badge: 'badge_mythic'),
    LevelReward(level: 33, title: 'Eternal', description: 'Time bows to your will.', badge: 'badge_eternal'),
    LevelReward(level: 34, title: 'Ascendant', description: 'You\'ve left gravity behind.', badge: 'badge_ascendant'),
    LevelReward(level: 35, title: 'Demi-God', description: 'Half divine, all determined.', unlockFeature: 'custom_program_builder', badge: 'badge_demigod'),
    LevelReward(level: 36, title: 'Celestial', description: 'Written in the stars.', badge: 'badge_celestial'),
    LevelReward(level: 37, title: 'Olympian', description: 'The gods train beside you.', badge: 'badge_olympian'),
    LevelReward(level: 38, title: 'Immortal', description: 'Your legacy endures.', badge: 'badge_immortal'),
    LevelReward(level: 39, title: 'Cosmic', description: 'Universal force of nature.', badge: 'badge_cosmic'),
    LevelReward(level: 40, title: 'Omega', description: 'The endgame begins.', unlockFeature: 'all_features', badge: 'badge_omega'),

    // Levels 41–50: Legend
    LevelReward(level: 41, title: 'Primordial', description: 'You existed before the game.', badge: 'badge_primordial'),
    LevelReward(level: 42, title: 'The Answer', description: 'To life, the universe, and gains.', badge: 'badge_answer'),
    LevelReward(level: 43, title: 'Singularity', description: 'Infinite density of will.', badge: 'badge_singularity'),
    LevelReward(level: 44, title: 'Conqueror', description: 'Nothing remains undefeated.', badge: 'badge_conqueror'),
    LevelReward(level: 45, title: 'Absolute', description: 'No compromise. No limit.', badge: 'badge_absolute'),
    LevelReward(level: 46, title: 'Zenith', description: 'The highest point achievable.', badge: 'badge_zenith'),
    LevelReward(level: 47, title: 'Paragon', description: 'A model of perfection.', badge: 'badge_paragon'),
    LevelReward(level: 48, title: 'Apex Predator', description: 'Top of every chain.', badge: 'badge_apex_predator'),
    LevelReward(level: 49, title: 'One Below', description: 'Almost there. Almost.', badge: 'badge_one_below'),
    LevelReward(level: 50, title: 'Legendary', description: 'You did it. Now maintain it.', unlockFeature: 'legendary_status', badge: 'badge_legendary'),
  ];

  /// All level rewards.
  static List<LevelReward> get allRewards => List.unmodifiable(_rewards);

  /// Get the current level from total XP.
  ///
  /// Same formula as [XpTracker.getLevel]: level N needs N×100 cumulative XP.
  static int getCurrentLevel(int totalXp) {
    int level = 0;
    int cumulative = 0;
    while (true) {
      final needed = (level + 1) * 100;
      if (cumulative + needed > totalXp) break;
      cumulative += needed;
      level++;
    }
    return level;
  }

  /// Get the title for a given level.
  static String getLevelTitle(int level) {
    if (level <= 0) return 'Newcomer';
    if (level > 50) return _rewards.last.title;
    return _rewards[level - 1].title;
  }

  /// Get the [LevelReward] for a specific level, or null if out of range.
  static LevelReward? getReward(int level) {
    if (level <= 0 || level > _rewards.length) return null;
    return _rewards[level - 1];
  }

  /// All rewards up to and including [level].
  static List<LevelReward> getRewards(int level) {
    return _rewards.where((r) => r.level <= level).toList();
  }

  /// All features unlocked up to and including [level].
  static List<String> getUnlockableFeatures(int level) {
    return _rewards
        .where((r) => r.level <= level && r.unlockFeature != null)
        .map((r) => r.unlockFeature!)
        .toList();
  }

  /// The next reward coming after [currentLevel].
  static LevelReward? getNextReward(int currentLevel) {
    if (currentLevel >= _rewards.length) return null;
    return _rewards[currentLevel]; // 0-indexed, so [currentLevel] is next
  }
}
