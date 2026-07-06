/// M5: Visual equipment selection grid for onboarding.
///
/// Multi-select grid with icons for each equipment type.
/// Selected items highlight with the orange accent. Uses DigitalAtelier tokens.
library;

import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ── Equipment Model ──────────────────────────────────────────────────────

/// Available gym equipment types.
enum EquipmentType {
  barbell,
  dumbbell,
  kettlebell,
  cableMachine,
  pullUpBar,
  resistanceBands,
  bodyweight,
  machine,
  ezBar,
  bands;

  String get displayName => switch (this) {
        EquipmentType.barbell => 'Barbell',
        EquipmentType.dumbbell => 'Dumbbells',
        EquipmentType.kettlebell => 'Kettlebell',
        EquipmentType.cableMachine => 'Cable Machine',
        EquipmentType.pullUpBar => 'Pull-Up Bar',
        EquipmentType.resistanceBands => 'Resistance Bands',
        EquipmentType.bodyweight => 'Bodyweight',
        EquipmentType.machine => 'Machines',
        EquipmentType.ezBar => 'EZ Bar',
        EquipmentType.bands => 'Bands',
      };

  IconData get icon => switch (this) {
        EquipmentType.barbell => Icons.fitness_center,
        EquipmentType.dumbbell => Icons.sports_gymnastics,
        EquipmentType.kettlebell => Icons.sports_martial_arts,
        EquipmentType.cableMachine => Icons.cable,
        EquipmentType.pullUpBar => Icons.accessibility_new,
        EquipmentType.resistanceBands => Icons.change_history,
        EquipmentType.bodyweight => Icons.self_improvement,
        EquipmentType.machine => Icons.settings_input_component,
        EquipmentType.ezBar => Icons.linear_scale,
        EquipmentType.bands => Icons.waves,
      };

  String get description => switch (this) {
        EquipmentType.barbell => 'Olympic bar, plates, rack',
        EquipmentType.dumbbell => 'Fixed or adjustable',
        EquipmentType.kettlebell => 'Any weight range',
        EquipmentType.cableMachine => 'Crossover or single',
        EquipmentType.pullUpBar => 'Door frame or wall mount',
        EquipmentType.resistanceBands => 'Loop or tube bands',
        EquipmentType.bodyweight => 'No equipment needed',
        EquipmentType.machine => 'Chest press, lat pulldown, etc.',
        EquipmentType.ezBar => 'Curl bar',
        EquipmentType.bands => 'Elastic resistance',
      };
}

// ── Equipment Picker Widget ──────────────────────────────────────────────

/// Visual equipment selection grid.
///
/// Displays a grid of equipment cards with icons. Tapping toggles selection.
/// Selected items are highlighted with the orange accent border and background.
class EquipmentPicker extends StatefulWidget {
  const EquipmentPicker({
    super.key,
    this.initialSelection = const {},
    this.onSelectionChanged,
  });

  final Set<EquipmentType> initialSelection;
  final ValueChanged<Set<EquipmentType>>? onSelectionChanged;

  @override
  State<EquipmentPicker> createState() => _EquipmentPickerState();
}

class _EquipmentPickerState extends State<EquipmentPicker> {
  late Set<EquipmentType> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelection);
  }

  void _toggle(EquipmentType type) {
    setState(() {
      if (_selected.contains(type)) {
        _selected.remove(type);
      } else {
        _selected.add(type);
      }
    });
    widget.onSelectionChanged?.call(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text('What equipment do you have?', style: t.textTheme.h3),
        SizedBox(height: t.spaceXs),
        Text(
          'Select all that apply — your plan adapts to what\'s available.',
          style: t.textTheme.bodySmall,
        ),
        SizedBox(height: t.spaceXl),

        // Equipment grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: t.spaceMd,
            crossAxisSpacing: t.spaceMd,
            childAspectRatio: 2.2,
          ),
          itemCount: EquipmentType.values.length,
          itemBuilder: (context, index) {
            final type = EquipmentType.values[index];
            final isSelected = _selected.contains(type);
            return _EquipmentCard(
              type: type,
              isSelected: isSelected,
              onTap: () => _toggle(type),
            );
          },
        ),

        // Selection count
        if (_selected.isNotEmpty) ...[
          SizedBox(height: t.spaceLg),
          Text(
            '${_selected.length} item${_selected.length == 1 ? '' : 's'} selected',
            style: t.textTheme.bodySmall.copyWith(color: t.accentPrimary),
          ),
        ],
      ],
    );
  }
}

// ── Equipment Card ───────────────────────────────────────────────────────

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final EquipmentType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: t.durationFast,
        curve: t.curveDefault,
        padding: EdgeInsets.all(t.spaceMd),
        decoration: BoxDecoration(
          color: isSelected
              ? t.accentPrimary.withValues(alpha: 0.1)
              : t.surface,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(
            color: isSelected ? t.accentPrimary : t.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: t.accentPrimary.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? t.accentPrimary.withValues(alpha: 0.2)
                    : t.surfaceElevated,
                borderRadius: BorderRadius.circular(t.radiusSm),
              ),
              child: Icon(
                type.icon,
                color: isSelected ? t.accentPrimary : t.textSecondary,
                size: 20,
              ),
            ),
            SizedBox(width: t.spaceSm),

            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    type.displayName,
                    style: t.textTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? t.accentPrimary : t.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: t.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Checkmark
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: t.accentPrimary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
