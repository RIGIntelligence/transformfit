import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/nutrition/macro_model.dart';
import 'package:transformfit/features/nutrition/nutrition_state.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/hero_background.dart';

// ---------------------------------------------------------------------------
// Nutrition dashboard screen — macro tracking, hydration, supplements.
// Wired to NutritionEngine, HydrationTracker, SupplementTracker via providers.
// ---------------------------------------------------------------------------

class NutritionDashboardScreen extends ConsumerWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nutrition = ref.watch(nutritionProvider);

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
        body: Stack(
          children: [
            // Hero nutrition background with dark overlay.
            const HeroBackground(
              assetPath: 'assets/imagery/hero_nutrition.png',
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
                        _MacroTargetsCard(
                          targetCalories: nutrition.target.calories,
                          actualCalories: nutrition.actualMacros.calories,
                          targetProtein: nutrition.target.proteinGrams,
                          actualProtein: nutrition.actualMacros.proteinGrams,
                          targetCarbs: nutrition.target.carbsGrams,
                          actualCarbs: nutrition.actualMacros.carbsGrams,
                          targetFat: nutrition.target.fatGrams,
                          actualFat: nutrition.actualMacros.fatGrams,
                          adherence: nutrition.adherence,
                        ),
                        const SizedBox(height: 16),
                        _NutritionStatusCard(
                          icon: Icons.restaurant_outlined,
                          title: 'Meals Logged',
                          current: nutrition.mealsLogged,
                          target: 4,
                          color: DigitalAtelierTokens.accentOrange,
                          subtitle:
                              '${nutrition.mealsLogged} of 4 meals today',
                        ),
                        const SizedBox(height: 12),
                        _NutritionStatusCard(
                          icon: Icons.water_drop_outlined,
                          title: 'Water Intake',
                          current: nutrition.waterGlasses,
                          target: nutrition.waterTarget,
                          color: const Color(0xFF3B82F6),
                          subtitle:
                              '${nutrition.waterGlasses} of ${nutrition.waterTarget} glasses',
                          trailing: Semantics(
                            label: 'Add water glass',
                            button: true,
                            child: IconButton(
                              icon: Icon(Icons.add_circle_outline,
                                  color: DigitalAtelierTokens.accentOrange,
                                  size: 28),
                              onPressed: () =>
                                  ref.read(nutritionProvider.notifier).logWater(),
                              tooltip: 'Add water glass',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _NutritionStatusCard(
                          icon: Icons.medication_outlined,
                          title: 'Supplements',
                          current: nutrition.supplementsTaken,
                          target: nutrition.supplementsTarget,
                          color: const Color(0xFF8B5CF6),
                          subtitle:
                              '${nutrition.supplementsTaken} of ${nutrition.supplementsTarget} taken',
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
                          onAddWater: () =>
                              ref.read(nutritionProvider.notifier).logWater(),
                          onAddMeal: () => _showQuickMealDialog(context, ref),
                          onAddSupplement: () =>
                              _showQuickSupplementDialog(context, ref),
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
          ],
        ),
      ),
    );
  }

  static void _showQuickMealDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DigitalAtelierTokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _QuickMealSheet(
        onLog: (name, type, macros) {
          ref.read(nutritionProvider.notifier).quickAddMeal(
                name: name,
                type: type,
                macros: macros,
              );
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  static void _showQuickSupplementDialog(
      BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DigitalAtelierTokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _QuickSupplementSheet(
        onLog: (name) {
          ref.read(nutritionProvider.notifier).logSupplement(name);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick meal bottom sheet
// ---------------------------------------------------------------------------

class _QuickMealSheet extends StatelessWidget {
  const _QuickMealSheet({required this.onLog});

  final void Function(String name, MealType type, Macros macros) onLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quickMeals = <(String, MealType, Macros)>[
      (
        'Protein shake',
        MealType.snack,
        const Macros(calories: 200, proteinGrams: 40, carbsGrams: 8, fatGrams: 2)
      ),
      (
        'Chicken & rice',
        MealType.lunch,
        const Macros(calories: 550, proteinGrams: 45, carbsGrams: 60, fatGrams: 12)
      ),
      (
        'Greek yogurt + fruit',
        MealType.snack,
        const Macros(calories: 250, proteinGrams: 20, carbsGrams: 30, fatGrams: 5)
      ),
      (
        'Oatmeal + eggs',
        MealType.breakfast,
        const Macros(calories: 450, proteinGrams: 25, carbsGrams: 55, fatGrams: 14)
      ),
      (
        'Salmon + veggies',
        MealType.dinner,
        const Macros(calories: 500, proteinGrams: 40, carbsGrams: 25, fatGrams: 22)
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Add Meal',
              style: theme.textTheme.titleMedium?.copyWith(
                color: DigitalAtelierTokens.textPrimary,
                fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
              ),
            ),
            const SizedBox(height: 16),
            for (final (name, type, macros) in quickMeals)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  button: true,
                  label: 'Quick add $name',
                  child: InkWell(
                    onTap: () => onLog(name, type, macros),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DigitalAtelierTokens2.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: DigitalAtelierTokens2.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: DigitalAtelierTokens.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${macros.calories.toStringAsFixed(0)} kcal · '
                                  'P${macros.proteinGrams.toStringAsFixed(0)}g '
                                  'C${macros.carbsGrams.toStringAsFixed(0)}g '
                                  'F${macros.fatGrams.toStringAsFixed(0)}g',
                                  style: TextStyle(
                                    color: DigitalAtelierTokens.textPrimary
                                        .withValues(alpha: 0.5),
                                    fontSize: 12,
                                    fontFamily:
                                        DigitalAtelierTokens.dataFontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.add_circle_outline,
                              color: DigitalAtelierTokens.accentOrange),
                        ],
                      ),
                    ),
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
// Quick supplement bottom sheet
// ---------------------------------------------------------------------------

class _QuickSupplementSheet extends StatelessWidget {
  const _QuickSupplementSheet({required this.onLog});

  final void Function(String name) onLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supplements = [
      'Creatine Monohydrate',
      'Whey Protein',
      'Vitamin D3',
      'Omega-3 (EPA/DHA)',
      'Magnesium (Glycinate/Citrate)',
      'Caffeine',
      'Zinc',
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Supplement',
              style: theme.textTheme.titleMedium?.copyWith(
                color: DigitalAtelierTokens.textPrimary,
                fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
              ),
            ),
            const SizedBox(height: 16),
            for (final name in supplements)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  button: true,
                  label: 'Log $name',
                  child: InkWell(
                    onTap: () => onLog(name),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DigitalAtelierTokens2.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: DigitalAtelierTokens2.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: DigitalAtelierTokens.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.add_circle_outline,
                              color: DigitalAtelierTokens.accentOrange),
                        ],
                      ),
                    ),
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
// Macro targets card — now with adherence score
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
    required this.adherence,
  });

  final double targetCalories;
  final double actualCalories;
  final double targetProtein;
  final double actualProtein;
  final double targetCarbs;
  final double actualCarbs;
  final double targetFat;
  final double actualFat;
  final double adherence;

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
            Row(
              children: [
                Text(
                  'Daily Macros',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                    fontFamily: DigitalAtelierTokens.dataFontFamily,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                // Adherence badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _adherenceColor(adherence).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(adherence * 100).toStringAsFixed(0)}% match',
                    style: TextStyle(
                      color: _adherenceColor(adherence),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: DigitalAtelierTokens.dataFontFamily,
                    ),
                  ),
                ),
              ],
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

  static Color _adherenceColor(double score) {
    if (score >= 0.8) return const Color(0xFF22C55E);
    if (score >= 0.5) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
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
// Quick add buttons — now with supplement logging
// ---------------------------------------------------------------------------

class _QuickAddButtons extends StatelessWidget {
  const _QuickAddButtons({
    required this.onAddWater,
    required this.onAddMeal,
    required this.onAddSupplement,
  });

  final VoidCallback onAddWater;
  final VoidCallback onAddMeal;
  final VoidCallback onAddSupplement;

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
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            label: 'Quick add supplement',
            button: true,
            child: ElevatedButton.icon(
              onPressed: onAddSupplement,
              icon: const Icon(Icons.medication_outlined, size: 20),
              label: const Text('Add Supp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                foregroundColor: const Color(0xFF8B5CF6),
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
