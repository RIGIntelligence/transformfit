/// M5: Experience level selection with specific examples.
///
/// Three levels (Beginner, Intermediate, Advanced) each with concrete
/// examples of what the user can do. Uses DigitalAtelier tokens.
library;

import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ── Experience Level Model ───────────────────────────────────────────────

/// User training experience level.
enum ExperienceLevel {
  beginner,
  intermediate,
  advanced;

  String get title => switch (this) {
        ExperienceLevel.beginner => 'Beginner',
        ExperienceLevel.intermediate => 'Intermediate',
        ExperienceLevel.advanced => 'Advanced',
      };

  String get subtitle => switch (this) {
        ExperienceLevel.beginner => 'I\'m new to lifting',
        ExperienceLevel.intermediate => 'I\'ve been training 6–12 months',
        ExperienceLevel.advanced => 'I\'ve been training 2+ years',
      };

  List<String> get examples => switch (this) {
        ExperienceLevel.beginner => [
            'Learning basic movement patterns',
            'Focus on form over weight',
            'Building a consistent habit',
            'Bodyweight or light weights',
          ],
        ExperienceLevel.intermediate => [
            'Comfortable with compound lifts',
            'Following a structured program',
            'Tracking weights and reps',
            'Can bench/squat bodyweight',
          ],
        ExperienceLevel.advanced => [
            'Customizing programs',
            'Periodization and deloads',
            'Advanced techniques (drop sets, pauses)',
            'Multiple training blocks completed',
          ],
      };

  IconData get icon => switch (this) {
        ExperienceLevel.beginner => Icons.eco,
        ExperienceLevel.intermediate => Icons.trending_up,
        ExperienceLevel.advanced => Icons.military_tech,
      };

  Color get accentColor => switch (this) {
        ExperienceLevel.beginner => const Color(0xFF10B981), // green
        ExperienceLevel.intermediate => const Color(0xFFF97316), // orange
        ExperienceLevel.advanced => const Color(0xFF8B5CF6), // purple
      };
}

// ── Experience Level Picker Widget ───────────────────────────────────────

/// Experience level selection with specific examples.
///
/// Each level shows a title, subtitle, and concrete examples
/// of what the user can do at that level.
class ExperienceLevelPicker extends StatefulWidget {
  const ExperienceLevelPicker({
    super.key,
    this.initialLevel,
    this.onSelected,
  });

  final ExperienceLevel? initialLevel;
  final ValueChanged<ExperienceLevel>? onSelected;

  @override
  State<ExperienceLevelPicker> createState() => _ExperienceLevelPickerState();
}

class _ExperienceLevelPickerState extends State<ExperienceLevelPicker> {
  ExperienceLevel? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLevel;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What\'s your experience level?', style: t.textTheme.h3),
        SizedBox(height: t.spaceXs),
        Text(
          'This helps us calibrate your starting weights and volume.',
          style: t.textTheme.bodySmall,
        ),
        SizedBox(height: t.spaceXl),

        // Level cards
        ...ExperienceLevel.values.map((level) {
          final isSelected = _selected == level;
          return Padding(
            padding: EdgeInsets.only(bottom: t.spaceMd),
            child: _ExperienceLevelCard(
              level: level,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selected = level);
                widget.onSelected?.call(level);
              },
            ),
          );
        }),
      ],
    );
  }
}

// ── Experience Level Card ────────────────────────────────────────────────

class _ExperienceLevelCard extends StatelessWidget {
  const _ExperienceLevelCard({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  final ExperienceLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final accent = level.accentColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: t.durationFast,
        curve: t.curveDefault,
        padding: EdgeInsets.all(t.spaceLg),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.08)
              : t.surface,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(
            color: isSelected ? accent : t.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(t.radiusSm),
                  ),
                  child: Icon(level.icon, color: accent, size: 22),
                ),
                SizedBox(width: t.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.title,
                        style: t.textTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? accent : t.textPrimary,
                        ),
                      ),
                      Text(level.subtitle, style: t.textTheme.caption),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: accent, size: 20),
              ],
            ),

            // Examples (shown when selected)
            AnimatedCrossFade(
              duration: t.durationNormal,
              crossFadeState: isSelected
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(top: t.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: t.surfaceBorder,
                    ),
                    SizedBox(height: t.spaceMd),
                    ...level.examples.map((example) => Padding(
                      padding: EdgeInsets.only(bottom: t.spaceXs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check,
                            size: 14,
                            color: accent,
                          ),
                          SizedBox(width: t.spaceSm),
                          Expanded(
                            child: Text(
                              example,
                              style: t.textTheme.bodySmall.copyWith(
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
