import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/hero_background.dart';

// ---------------------------------------------------------------------------
// Gamification dashboard — level, XP, streaks, achievements, milestones.
// ---------------------------------------------------------------------------

class GamificationDashboardScreen extends ConsumerStatefulWidget {
  const GamificationDashboardScreen({super.key});

  @override
  ConsumerState<GamificationDashboardScreen> createState() =>
      _GamificationDashboardScreenState();
}

class _GamificationDashboardScreenState
    extends ConsumerState<GamificationDashboardScreen> {
  // Demo state — in production these come from XpTracker, StreakTracker, etc.
  final int _currentLevel = 7;
  final String _levelTitle = 'Committed';
  final int _totalXp = 2850;
  final int _xpToNext = 150;
  final int _xpForLevel = 800;

  final List<_StreakData> _streaks = const [
    _StreakData(type: 'Workout', days: 12, icon: Icons.fitness_center, color: Color(0xFFF97316)),
    _StreakData(type: 'Mood', days: 7, icon: Icons.emoji_emotions_outlined, color: Color(0xFF22C55E)),
    _StreakData(type: 'Nutrition', days: 5, icon: Icons.restaurant_outlined, color: Color(0xFF3B82F6)),
    _StreakData(type: 'Sleep', days: 9, icon: Icons.bedtime_outlined, color: Color(0xFF8B5CF6)),
    _StreakData(type: 'Readiness', days: 14, icon: Icons.bolt_outlined, color: Color(0xFFF59E0B)),
    _StreakData(type: 'Mindfulness', days: 3, icon: Icons.spa_outlined, color: Color(0xFF6366F1)),
  ];

  final List<_AchievementData> _recentAchievements = const [
    _AchievementData(
      icon: '🔥',
      name: 'Week Warrior',
      description: 'Complete workouts 7 days in a row.',
      tier: 'Bronze',
    ),
    _AchievementData(
      icon: '😊',
      name: 'Mood Week',
      description: 'Log mood 7 days in a row.',
      tier: 'Bronze',
    ),
    _AchievementData(
      icon: '⚡',
      name: 'Ready Week',
      description: 'Check readiness 7 days in a row.',
      tier: 'Bronze',
    ),
  ];

  final _NextMilestone _nextMilestone = const _NextMilestone(
    icon: '🏅',
    name: 'PR Collector',
    description: 'Achieve 10 personal records.',
    progress: 7,
    target: 10,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpProgress = _xpForLevel > 0
        ? ((_xpForLevel - _xpToNext) / _xpForLevel).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      label: 'Gamification dashboard screen',
      child: Scaffold(
        backgroundColor: DigitalAtelierTokens.background,
        appBar: AppBar(
          backgroundColor: DigitalAtelierTokens.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: Semantics(
            label: 'Back',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: DigitalAtelierTokens.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            ),
          ),
          title: Text(
            'Achievements',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
              color: DigitalAtelierTokens.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Hero gamification background with dark overlay.
            const HeroBackground(
              assetPath: 'assets/imagery/hero_gamification.png',
              overlayOpacity: 0.85,
              cacheWidth: 800,
              cacheHeight: 600,
            ),
            SafeArea(
              child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 40 : 20,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Level + XP header.
                        _LevelHeader(
                          level: _currentLevel,
                          title: _levelTitle,
                          totalXp: _totalXp,
                          xpToNext: _xpToNext,
                          progress: xpProgress,
                        ),
                        const SizedBox(height: 24),

                        // Streaks grid.
                        Text(
                          'Active Streaks',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: DigitalAtelierTokens.textPrimary,
                            fontFamily:
                                DigitalAtelierTokens.coachVoiceFontFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: wide ? 3 : 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: _streaks.length,
                          itemBuilder: (context, index) {
                            return _StreakCard(streak: _streaks[index]);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Recent achievements.
                        Text(
                          'Recent Achievements',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: DigitalAtelierTokens.textPrimary,
                            fontFamily:
                                DigitalAtelierTokens.coachVoiceFontFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._recentAchievements.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AchievementCard(achievement: a),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Next milestone.
                        Text(
                          'Next Milestone',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: DigitalAtelierTokens.textPrimary,
                            fontFamily:
                                DigitalAtelierTokens.coachVoiceFontFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _NextMilestoneCard(milestone: _nextMilestone),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level header with XP bar
// ---------------------------------------------------------------------------

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.level,
    required this.title,
    required this.totalXp,
    required this.xpToNext,
    required this.progress,
  });

  final int level;
  final String title;
  final int totalXp;
  final int xpToNext;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Level $level, $title. $totalXp total XP. $xpToNext XP to next level.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DigitalAtelierTokens2.surface,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
          border: Border.all(
            color: DigitalAtelierTokens2.surfaceBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Level badge.
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF97316),
                    Color(0xFF8B5CF6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DigitalAtelierTokens.accentOrange
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: TextStyle(
                    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: DigitalAtelierTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$totalXp total XP',
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 14,
                color:
                    DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            // XP progress bar.
            Semantics(
              label: 'XP progress to next level: ${(progress * 100).toStringAsFixed(0)}%',
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: DigitalAtelierTokens.textPrimary
                          .withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation(
                          DigitalAtelierTokens.accentOrange),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$xpToNext XP to next level',
                    style: TextStyle(
                      fontFamily: DigitalAtelierTokens.dataFontFamily,
                      fontSize: 12,
                      color: DigitalAtelierTokens.accentOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak data model and card
// ---------------------------------------------------------------------------

class _StreakData {
  const _StreakData({
    required this.type,
    required this.days,
    required this.icon,
    required this.color,
  });

  final String type;
  final int days;
  final IconData icon;
  final Color color;
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final _StreakData streak;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${streak.type} streak: ${streak.days} days',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DigitalAtelierTokens2.surface,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
          border: Border.all(
            color: DigitalAtelierTokens2.surfaceBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(streak.icon, color: streak.color, size: 22),
            const Spacer(),
            Text(
              '${streak.days}',
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: DigitalAtelierTokens.textPrimary,
              ),
            ),
            Text(
              streak.type,
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 12,
                color:
                    DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Achievement data model and card
// ---------------------------------------------------------------------------

class _AchievementData {
  const _AchievementData({
    required this.icon,
    required this.name,
    required this.description,
    required this.tier,
  });

  final String icon;
  final String name;
  final String description;
  final String tier;
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final _AchievementData achievement;

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Bronze':
        return const Color(0xFFCD7F32);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Platinum':
        return const Color(0xFFE5E4E2);
      default:
        return DigitalAtelierTokens.accentOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _tierColor(achievement.tier);

    return Semantics(
      label: 'Achievement: ${achievement.name}. ${achievement.description}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DigitalAtelierTokens2.surface,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
          border: Border.all(
            color: tierColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.name,
                    style: TextStyle(
                      color: DigitalAtelierTokens.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: DigitalAtelierTokens.textPrimary
                          .withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                achievement.tier,
                style: TextStyle(
                  color: tierColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: DigitalAtelierTokens.dataFontFamily,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next milestone data model and card
// ---------------------------------------------------------------------------

class _NextMilestone {
  const _NextMilestone({
    required this.icon,
    required this.name,
    required this.description,
    required this.progress,
    required this.target,
  });

  final String icon;
  final String name;
  final String description;
  final int progress;
  final int target;
}

class _NextMilestoneCard extends StatelessWidget {
  const _NextMilestoneCard({required this.milestone});

  final _NextMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final ratio =
        milestone.target > 0 ? (milestone.progress / milestone.target) : 0.0;

    return Semantics(
      label:
          'Next milestone: ${milestone.name}. ${milestone.progress} of ${milestone.target}. ${milestone.description}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DigitalAtelierTokens2.surface,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
          border: Border.all(
            color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(milestone.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    milestone.name,
                    style: TextStyle(
                      color: DigitalAtelierTokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${milestone.progress}/${milestone.target}',
                  style: TextStyle(
                    color: DigitalAtelierTokens.accentOrange,
                    fontFamily: DigitalAtelierTokens.dataFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              milestone.description,
              style: TextStyle(
                color:
                    DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: DigitalAtelierTokens.textPrimary
                    .withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(
                    DigitalAtelierTokens.accentOrange),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
