library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/nutrition/hydration_tracker.dart';
import 'package:transformfit/features/nutrition/macro_model.dart';
import 'package:transformfit/features/nutrition/nutrition_engine.dart';
import 'package:transformfit/features/nutrition/supplement_tracker.dart';

// ---------------------------------------------------------------------------
// Nutrition state — single source of truth for the dashboard.
// ---------------------------------------------------------------------------

/// Holds today's actual nutrition intake alongside the engine-calculated targets.
class NutritionState {
  const NutritionState({
    required this.target,
    required this.dailyNutrition,
    required this.hydrationTracker,
    required this.supplementTracker,
  });

  final NutritionTarget target;
  final DailyNutrition dailyNutrition;
  final HydrationTracker hydrationTracker;
  final SupplementTracker supplementTracker;

  Macros get actualMacros => dailyNutrition.totalMacros;
  int get mealsLogged => dailyNutrition.meals.length;
  int get waterGlasses => hydrationTracker.getGlassesConsumed().ceil();
  int get waterTarget => target.waterGlasses;
  int get supplementsTaken => supplementTracker.getDailyStack().length;
  int get supplementsTarget => 3; // common daily stack size
  double get adherence => NutritionEngine.getAdherenceScore(
        dailyNutrition: dailyNutrition,
        target: target,
      );
}

/// Riverpod notifier that manages the live nutrition state.
class NutritionNotifier extends Notifier<NutritionState> {
  final HydrationTracker _hydration = HydrationTracker();
  final SupplementTracker _supplements = SupplementTracker();
  final List<MealEntry> _meals = [];

  @override
  NutritionState build() {
    // Default targets — in production these come from the user profile.
    // These are reasonable defaults for a moderate-activity 80kg male.
    const defaultTarget = NutritionTarget(
      calories: 2400,
      proteinGrams: 160,
      carbsGrams: 280,
      fatGrams: 67,
      waterGlasses: 8,
    );

    return NutritionState(
      target: defaultTarget,
      dailyNutrition: DailyNutrition(
        date: DateTime.now(),
        meals: const [],
        waterGlasses: 0,
      ),
      hydrationTracker: _hydration,
      supplementTracker: _supplements,
    );
  }

  /// Recalculate targets from user profile data.
  void setTargets(NutritionTarget target) {
    _hydration.setGoal(target.waterGlasses * 250);
    _refresh(target: target);
  }

  /// Log a meal entry.
  void logMeal(MealEntry meal) {
    _meals.add(meal);
    _refresh();
  }

  /// Quick-add a predefined meal.
  void quickAddMeal({
    required String name,
    required MealType type,
    required Macros macros,
  }) {
    _meals.add(MealEntry(
      id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      macros: macros,
      timestamp: DateTime.now(),
    ));
    _refresh();
  }

  /// Log a water glass (250ml).
  void logWater() {
    _hydration.logWater(amountMl: 250);
    _refresh();
  }

  /// Log water by amount.
  void logWaterAmount(double ml, {HydrationType type = HydrationType.water}) {
    _hydration.logWater(amountMl: ml, type: type);
    _refresh();
  }

  /// Log a supplement.
  void logSupplement(String name, {String? dosage}) {
    _supplements.logSupplement(
      supplementName: name,
      dosageOverride: dosage,
    );
    _refresh();
  }

  void _refresh({NutritionTarget? target}) {
    final t = target ?? state.target;
    state = NutritionState(
      target: t,
      dailyNutrition: DailyNutrition(
        date: DateTime.now(),
        meals: List.unmodifiable(_meals),
        waterGlasses: _hydration.getGlassesConsumed().ceil(),
      ),
      hydrationTracker: _hydration,
      supplementTracker: _supplements,
    );
  }
}

/// The global nutrition state provider.
final nutritionProvider =
    NotifierProvider<NutritionNotifier, NutritionState>(NutritionNotifier.new);
