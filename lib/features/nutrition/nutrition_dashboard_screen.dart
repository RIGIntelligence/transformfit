import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Nutrition dashboard screen — macro tracking, hydration, supplements.
// ---------------------------------------------------------------------------

class NutritionDashboardScreen extends ConsumerStatefulWidget {
  const NutritionDashboardScreen({super.key});

  @override
  ConsumerState<NutritionDashboardScreen> createState() =>
      _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState
    extends ConsumerState<NutritionDashboardScreen> {
  // Demo state — in production these come from providers.
  int _waterGlasses = 3;
  final int _waterTarget = 8;
  int _mealsLogged = 2;
  final int _mealsTarget = 4;
  final int _supplementsTaken = 1;
  final int _supplementsTarget = 3;

  // Macro demo data.
  final double _targetCalories = 2400;
  final double _actualCalories = 1650;
  final double _targetProtein = 160;
  final double _actualProtein = 112;
  final double _targetCarbs = 280;
  final double _actualCarbs = 190;
  final double _targetFat = 67;
  final double _actualFat = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Nutrition dashboard screen',
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
            'Nutrition',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
              color: DigitalAtelierTokens.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
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
                        _MacroTargetsCard(
                          targetCalories: _targetCalories,
                          actualCalories: _actualCalories,
                          targetProtein: _targetProtein,
                          actualProtein: _actualProtein,
                          targetCarbs: _targetCarbs,
                          actualCarbs: _actualCarbs,
                          targetFat: _targetFat,
                          actualFat: _actualFat,
                        ),
                        const SizedBox(height: 16),
                        _NutritionStatusCard(
                          icon: Icons.restaurant_outlined,
                          title: 'Meals Logged',
                          current: _mealsLogged,
                          target: _mealsTarget,
                          color: DigitalAtelierTokens.accentOrange,
                          subtitle: '$_mealsLogged of $_mealsTarget meals today',
                        ),
                        const SizedBox(height: 12),
                        _NutritionStatusCard(
                          icon: Icons.water_drop_outlined,
                          title: 'Water Intake',
                          current: _waterGlasses,
                          target: _waterTarget,
                          color: const Color(0xFF3B82F6),
                          subtitle: '$_waterGlasses of $_waterTarget glasses',
                          trailing: Semantics(
                            label: 'Add water glass',
                            button: true,
                            child: IconButton(
                              icon: Icon(Icons.add_circle_outline,
                                  color: DigitalAtelierTokens.accentOrange,
                                  size: 28),
                              onPressed: () {
                                setState(() {
                                  if (_waterGlasses < _waterTarget + 4) {
                                    _waterGlasses++;
                                  }
                                });
                              },
                              tooltip: 'Add water glass',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _NutritionStatusCard(
                          icon: Icons.medication_outlined,
                          title: 'Supplements',
                          current: _supplementsTaken,
                          target: _supplementsTarget,
                          color: const Color(0xFF8B5CF6),
                          subtitle: '$_supplementsTaken of $_supplementsTarget taken',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Quick Add',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: DigitalAtelierTokens.textPrimary,
                            fontFamily:
                                DigitalAtelierTokens.coachVoiceFontFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _QuickAddButtons(
                          onAddWater: () {
                            setState(() {
                              if (_waterGlasses < _waterTarget + 4) {
                                _waterGlasses++;
                              }
                            });
                          },
                          onAddMeal: () {
                            setState(() {
                              if (_mealsLogged < _mealsTarget + 2) {
                                _mealsLogged++;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Macro targets card
// ---------------------------------------------------------------------------

class _MacroTargetsCard extends StatelessWidget {
  const _MacroTargetsCard({
    required this.targetCalories,
    required this.actualCalories,
    required this.targetProtein,
    required this.actualProtein,
    required this.targetCarbs,
    required this.actualCarbs,
    required this.targetFat,
    required this.actualFat,
  });

  final double targetCalories;
  final double actualCalories;
  final double targetProtein;
  final double actualProtein;
  final double targetCarbs;
  final double actualCarbs;
  final double targetFat;
  final double actualFat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calorieProgress =
        targetCalories > 0 ? (actualCalories / targetCalories).clamp(0, 1) : 0.0;

    return Semantics(
      label:
          'Macro targets: ${actualCalories.toStringAsFixed(0)} of ${targetCalories.toStringAsFixed(0)} calories',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
          children: [
            Text(
              'Daily Macros',
              style: theme.textTheme.titleSmall?.copyWith(
                color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Calories ring.
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Semantics(
                      label:
                          'Calories: ${actualCalories.toStringAsFixed(0)} of ${targetCalories.toStringAsFixed(0)}',
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: calorieProgress.toDouble(),
                          strokeWidth: 10,
                          backgroundColor: DigitalAtelierTokens.textPrimary
                              .withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation(
                              DigitalAtelierTokens.accentOrange),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actualCalories.toStringAsFixed(0),
                          style: TextStyle(
                            fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: DigitalAtelierTokens.textPrimary,
                          ),
                        ),
                        Text(
                          '/ ${targetCalories.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            fontFamily: DigitalAtelierTokens.dataFontFamily,
                            fontSize: 12,
                            color: DigitalAtelierTokens.textPrimary
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Macro bars.
            _MacroBar(
              label: 'Protein',
              actual: actualProtein,
              target: targetProtein,
              unit: 'g',
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 10),
            _MacroBar(
              label: 'Carbs',
              actual: actualCarbs,
              target: targetCarbs,
              unit: 'g',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 10),
            _MacroBar(
              label: 'Fat',
              actual: actualFat,
              target: targetFat,
              unit: 'g',
              color: const Color(0xFFF59E0B),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.actual,
    required this.target,
    required this.unit,
    required this.color,
  });

  final String label;
  final double actual;
  final double target;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      label: '$label: ${actual.toStringAsFixed(0)} of ${target.toStringAsFixed(0)} $unit',
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color:
                    DigitalAtelierTokens.textPrimary.withValues(alpha: 0.7),
                fontSize: 13,
                fontFamily: DigitalAtelierTokens.dataFontFamily,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    DigitalAtelierTokens.textPrimary.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              '${actual.toStringAsFixed(0)}/${target.toStringAsFixed(0)}$unit',
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                fontSize: 12,
                fontFamily: DigitalAtelierTokens.dataFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nutrition status card (meals, water, supplements)
// ---------------------------------------------------------------------------

class _NutritionStatusCard extends StatelessWidget {
  const _NutritionStatusCard({
    required this.icon,
    required this.title,
    required this.current,
    required this.target,
    required this.color,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final int current;
  final int target;
  final Color color;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      label: '$title: $subtitle',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DigitalAtelierTokens2.surface,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
          border: Border.all(
            color: DigitalAtelierTokens2.surfaceBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: DigitalAtelierTokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: DigitalAtelierTokens.textPrimary
                          .withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: DigitalAtelierTokens.textPrimary
                          .withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick add buttons
// ---------------------------------------------------------------------------

class _QuickAddButtons extends StatelessWidget {
  const _QuickAddButtons({required this.onAddWater, required this.onAddMeal});

  final VoidCallback onAddWater;
  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Quick add water glass',
            button: true,
            child: ElevatedButton.icon(
              onPressed: onAddWater,
              icon: const Icon(Icons.water_drop_outlined, size: 20),
              label: const Text('Add Water'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                foregroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      DigitalAtelierTokens.cornerRadius * 2),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            label: 'Quick add meal',
            button: true,
            child: ElevatedButton.icon(
              onPressed: onAddMeal,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Add Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    DigitalAtelierTokens.accentOrange.withValues(alpha: 0.2),
                foregroundColor: DigitalAtelierTokens.accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      DigitalAtelierTokens.cornerRadius * 2),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
