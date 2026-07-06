/// M5: Animated goal visualization for onboarding.
///
/// Shows what the user will achieve in 4 weeks with animated counters
/// and sample week preview cards. Uses DigitalAtelier tokens.
library;

import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ── Goal Metric Model ────────────────────────────────────────────────────

/// A single metric the user will hit in 4 weeks.
class GoalMetric {
  const GoalMetric({
    required this.label,
    required this.targetValue,
    required this.unit,
    required this.icon,
  });

  final String label;
  final double targetValue;
  final String unit;
  final IconData icon;
}

/// Sample goal metrics generated from the plan generator.
class GoalPreview {
  const GoalPreview({
    required this.metrics,
    required this.sampleWeek,
    required this.weeksToGoal,
  });

  final List<GoalMetric> metrics;
  final List<SampleDay> sampleWeek;
  final int weeksToGoal;
}

/// A single day in the sample week preview.
class SampleDay {
  const SampleDay({
    required this.dayName,
    required this.focus,
    required this.exerciseCount,
    required this.durationMinutes,
    this.isRestDay = false,
  });

  final String dayName;
  final String focus;
  final int exerciseCount;
  final int durationMinutes;
  final bool isRestDay;
}

// ── Default Goal Data ────────────────────────────────────────────────────

/// Generates a default goal preview based on user profile.
GoalPreview generateDefaultGoalPreview({
  required int trainingDaysPerWeek,
  required String experienceLevel,
}) {
  // Scale targets by experience level
  final strengthMultiplier = switch (experienceLevel) {
    'beginner' => 1.0,
    'intermediate' => 1.3,
    'advanced' => 1.5,
    _ => 1.0,
  };

  final metrics = <GoalMetric>[
    GoalMetric(
      label: 'Bench Press',
      targetValue: (60 * strengthMultiplier).roundToDouble(),
      unit: 'kg',
      icon: Icons.fitness_center,
    ),
    GoalMetric(
      label: 'Squat',
      targetValue: (80 * strengthMultiplier).roundToDouble(),
      unit: 'kg',
      icon: Icons.directions_run,
    ),
    GoalMetric(
      label: 'Weekly Volume',
      targetValue: (trainingDaysPerWeek * 18 * strengthMultiplier).roundToDouble(),
      unit: 'sets',
      icon: Icons.bar_chart,
    ),
    GoalMetric(
      label: 'Body Fat Drop',
      targetValue: 2.5,
      unit: '%',
      icon: Icons.trending_down,
    ),
  ];

  final sampleWeek = _generateSampleWeek(trainingDaysPerWeek);

  return GoalPreview(
    metrics: metrics,
    sampleWeek: sampleWeek,
    weeksToGoal: 4,
  );
}

List<SampleDay> _generateSampleWeek(int trainingDays) {
  const allDays = [
    SampleDay(dayName: 'Mon', focus: 'Push', exerciseCount: 6, durationMinutes: 55),
    SampleDay(dayName: 'Tue', focus: 'Pull', exerciseCount: 6, durationMinutes: 50),
    SampleDay(dayName: 'Wed', focus: 'Legs', exerciseCount: 7, durationMinutes: 60),
    SampleDay(dayName: 'Thu', focus: 'Upper', exerciseCount: 6, durationMinutes: 50),
    SampleDay(dayName: 'Fri', focus: 'Lower', exerciseCount: 6, durationMinutes: 55),
    SampleDay(dayName: 'Sat', focus: 'Full Body', exerciseCount: 8, durationMinutes: 45),
    SampleDay(dayName: 'Sun', focus: 'Rest', exerciseCount: 0, durationMinutes: 0, isRestDay: true),
  ];

  // Distribute training days evenly across the week
  final restDays = 7 - trainingDays;
  final restIndices = <int>[];
  if (restDays >= 1) restIndices.add(6); // Sunday always rest first
  if (restDays >= 2) restIndices.add(2); // Wednesday
  if (restDays >= 3) restIndices.add(4); // Friday
  if (restDays >= 4) restIndices.add(0); // Monday
  if (restDays >= 5) restIndices.add(3); // Thursday

  return List.generate(7, (i) {
    if (restIndices.contains(i)) {
      return SampleDay(
        dayName: allDays[i].dayName,
        focus: 'Rest',
        exerciseCount: 0,
        durationMinutes: 0,
        isRestDay: true,
      );
    }
    return allDays[i];
  });
}

// ── Goal Visualization Widget ────────────────────────────────────────────

/// Animated goal preview showing what the user will achieve.
///
/// Displays animated counters for each goal metric and a sample week
/// calendar with colored training day blocks.
class GoalVisualization extends StatefulWidget {
  const GoalVisualization({
    super.key,
    required this.preview,
    this.onContinue,
  });

  final GoalPreview preview;
  final VoidCallback? onContinue;

  @override
  State<GoalVisualization> createState() => _GoalVisualizationState();
}

class _GoalVisualizationState extends State<GoalVisualization>
    with TickerProviderStateMixin {
  late final AnimationController _counterCtrl;
  late final AnimationController _staggerCtrl;
  late final Animation<double> _counterAnim;

  @override
  void initState() {
    super.initState();
    _counterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _counterAnim = CurvedAnimation(
      parent: _counterCtrl,
      curve: Curves.easeOutCubic,
    );
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _counterCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'In ${widget.preview.weeksToGoal} weeks, you\'ll be doing:',
          style: t.textTheme.h2,
        ),
        SizedBox(height: t.spaceXl),

        // Animated metric cards
        ...widget.preview.metrics.asMap().entries.map((entry) {
          final index = entry.key;
          final metric = entry.value;
          return _AnimatedMetricCard(
            metric: metric,
            animation: _counterAnim,
            staggerDelay: index * 0.15,
          );
        }),

        SizedBox(height: t.spaceXxl),

        // Sample week section
        Text('Your sample week', style: t.textTheme.h3),
        SizedBox(height: t.spaceLg),
        _SampleWeekCalendar(
          days: widget.preview.sampleWeek,
          animation: _staggerCtrl,
        ),

        if (widget.onContinue != null) ...[
          SizedBox(height: t.spaceXxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accentPrimary,
                foregroundColor: t.textInverse,
                padding: EdgeInsets.symmetric(vertical: t.spaceLg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(t.radiusMd),
                ),
              ),
              child: Text('Let\'s build your plan', style: t.textTheme.body.copyWith(
                color: t.textInverse,
                fontWeight: FontWeight.w600,
              )),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Animated Metric Card ─────────────────────────────────────────────────

class _AnimatedMetricCard extends StatelessWidget {
  const _AnimatedMetricCard({
    required this.metric,
    required this.animation,
    required this.staggerDelay,
  });

  final GoalMetric metric;
  final Animation<double> animation;
  final double staggerDelay;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delayedValue = ((animation.value - staggerDelay) / (1.0 - staggerDelay)).clamp(0.0, 1.0);

        return Opacity(
          opacity: delayedValue.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - delayedValue)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: t.spaceMd),
        padding: EdgeInsets.all(t.spaceLg),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(color: t.surfaceBorder),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.accentPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(t.radiusSm),
              ),
              child: Icon(metric.icon, color: t.accentPrimary, size: 22),
            ),
            SizedBox(width: t.spaceLg),

            // Label and animated value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.label, style: t.textTheme.caption),
                  SizedBox(height: t.spaceXs),
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      final delayedValue = ((animation.value - staggerDelay) / (1.0 - staggerDelay)).clamp(0.0, 1.0);
                      final currentValue = metric.targetValue * delayedValue;
                      return Text(
                        '${currentValue.toStringAsFixed(currentValue == currentValue.roundToDouble() ? 0 : 1)} ${metric.unit}',
                        style: t.textTheme.dataMedium.copyWith(
                          color: t.accentPrimary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Arrow indicator
            Icon(Icons.arrow_forward_ios, color: t.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Sample Week Calendar ─────────────────────────────────────────────────

class _SampleWeekCalendar extends StatelessWidget {
  const _SampleWeekCalendar({
    required this.days,
    required this.animation,
  });

  final List<SampleDay> days;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          children: days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final delay = index * 0.1;
            final opacity = ((animation.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);

            return Expanded(
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - opacity)),
                  child: _DayBlock(day: day),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({required this.day});

  final SampleDay day;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          // Day name
          Text(
            day.dayName,
            style: t.textTheme.caption.copyWith(
              color: day.isRestDay ? t.textMuted : t.textSecondary,
            ),
          ),
          SizedBox(height: t.spaceXs),

          // Color block
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: day.isRestDay
                  ? t.surfaceBorder.withValues(alpha: 0.5)
                  : t.accentPrimary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(t.radiusSm),
              border: day.isRestDay
                  ? Border.all(color: t.surfaceBorder)
                  : null,
            ),
            child: day.isRestDay
                ? Center(
                    child: Text('—', style: TextStyle(color: t.textMuted)),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${day.exerciseCount}',
                          style: t.textTheme.dataSmall.copyWith(
                            color: t.textInverse,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'ex',
                          style: TextStyle(
                            color: t.textInverse.withValues(alpha: 0.7),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: t.spaceXs),

          // Focus label
          Text(
            day.focus,
            style: TextStyle(
              fontSize: 9,
              color: day.isRestDay ? t.textMuted : t.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
