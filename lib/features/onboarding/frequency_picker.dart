/// M5: Training frequency selector with calendar preview.
///
/// Options for 2–6 days per week, each showing a sample calendar week
/// with colored blocks for training days. Uses DigitalAtelier tokens.
library;

import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ── Frequency Option Model ───────────────────────────────────────────────

/// A training frequency option with preview data.
class FrequencyOption {
  const FrequencyOption({
    required this.daysPerWeek,
    required this.label,
    required this.description,
    required this.trainingDays,
  });

  final int daysPerWeek;
  final String label;
  final String description;

  /// Indices of training days (0 = Mon, 6 = Sun).
  final List<int> trainingDays;

  /// Predefined frequency options.
  static const List<FrequencyOption> presets = [
    FrequencyOption(
      daysPerWeek: 2,
      label: '2 days/week',
      description: 'Full Body × 2. Ideal for busy schedules.',
      trainingDays: [0, 3], // Mon, Thu
    ),
    FrequencyOption(
      daysPerWeek: 3,
      label: '3 days/week',
      description: 'Push/Pull/Legs. The classic split.',
      trainingDays: [0, 2, 4], // Mon, Wed, Fri
    ),
    FrequencyOption(
      daysPerWeek: 4,
      label: '4 days/week',
      description: 'Upper/Lower × 2. Balanced volume.',
      trainingDays: [0, 1, 3, 4], // Mon, Tue, Thu, Fri
    ),
    FrequencyOption(
      daysPerWeek: 5,
      label: '5 days/week',
      description: 'Bro split or PPL+Upper/Lower.',
      trainingDays: [0, 1, 2, 3, 4], // Mon–Fri
    ),
    FrequencyOption(
      daysPerWeek: 6,
      label: '6 days/week',
      description: 'PPL × 2. High frequency for advanced.',
      trainingDays: [0, 1, 2, 3, 4, 5], // Mon–Sat
    ),
  ];
}

// ── Frequency Picker Widget ──────────────────────────────────────────────

/// Training frequency selector with calendar preview.
///
/// Each option shows a sample calendar week with colored blocks.
/// Selected option highlights with the orange accent.
class FrequencyPicker extends StatefulWidget {
  const FrequencyPicker({
    super.key,
    this.initialDays = 3,
    this.onSelected,
  });

  final int initialDays;
  final ValueChanged<FrequencyOption>? onSelected;

  @override
  State<FrequencyPicker> createState() => _FrequencyPickerState();
}

class _FrequencyPickerState extends State<FrequencyPicker> {
  late int _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDays;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How often can you train?', style: t.textTheme.h3),
        SizedBox(height: t.spaceXs),
        Text(
          'Pick the schedule that fits your life — we\'ll build around it.',
          style: t.textTheme.bodySmall,
        ),
        SizedBox(height: t.spaceXl),

        // Frequency options
        ...FrequencyOption.presets.map((option) {
          final isSelected = option.daysPerWeek == _selectedDays;
          return Padding(
            padding: EdgeInsets.only(bottom: t.spaceMd),
            child: _FrequencyCard(
              option: option,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedDays = option.daysPerWeek);
                widget.onSelected?.call(option);
              },
            ),
          );
        }),
      ],
    );
  }
}

// ── Frequency Card ───────────────────────────────────────────────────────

class _FrequencyCard extends StatelessWidget {
  const _FrequencyCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final FrequencyOption option;
  final bool isSelected;
  final VoidCallback onTap;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: t.durationFast,
        curve: t.curveDefault,
        padding: EdgeInsets.all(t.spaceLg),
        decoration: BoxDecoration(
          color: isSelected
              ? t.accentPrimary.withValues(alpha: 0.08)
              : t.surface,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(
            color: isSelected ? t.accentPrimary : t.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: t.accentPrimary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Days badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.spaceMd,
                    vertical: t.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? t.accentPrimary
                        : t.surfaceElevated,
                    borderRadius: BorderRadius.circular(t.radiusPill),
                  ),
                  child: Text(
                    '${option.daysPerWeek}×',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? t.textInverse : t.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: t.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: t.textTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? t.accentPrimary : t.textPrimary,
                        ),
                      ),
                      Text(option.description, style: t.textTheme.caption),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: t.accentPrimary, size: 20),
              ],
            ),

            SizedBox(height: t.spaceMd),

            // Calendar preview row
            Row(
              children: List.generate(7, (i) {
                final isTrainingDay = option.trainingDays.contains(i);
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text(
                          _dayLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            color: isTrainingDay ? t.textPrimary : t.textMuted,
                            fontWeight: isTrainingDay ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: isTrainingDay
                                ? t.accentPrimary.withValues(alpha: 0.85)
                                : t.surfaceBorder.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(t.radiusSm),
                          ),
                          child: isTrainingDay
                              ? Center(
                                  child: Icon(
                                    Icons.fitness_center,
                                    size: 12,
                                    color: t.textInverse,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
