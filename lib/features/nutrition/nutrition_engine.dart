library;

/// Evidence-based nutrition calculation engine for TransformFit.
///
/// Pure Dart, deterministic — no side effects, no I/O.
/// Uses Mifflin-St Jeor for TDEE and peer-reviewed macro splits.

import 'macro_model.dart';

class NutritionEngine {
  // ---------------------------------------------------------------------------
  // TDEE — Mifflin-St Jeor equation
  // ---------------------------------------------------------------------------

  /// Calculate Total Daily Energy Expenditure using Mifflin-St Jeor.
  ///
  /// Formula:
  ///   Male:   10 × weight(kg) + 6.25 × height(cm) − 5 × age − 5   + activity
  ///   Female: 10 × weight(kg) + 6.25 × height(cm) − 5 × age − 161 + activity
  ///
  /// Most accurate for normal-weight adults; ±10% for obese individuals.
  static double calculateTDEE({
    required double weightKg,
    required double heightCm,
    required int age,
    required Sex sex,
    required ActivityLevel activityLevel,
  }) {
    final bmr = _calculateBMR(weightKg, heightCm, age, sex);
    return bmr * activityLevel.multiplier;
  }

  static double _calculateBMR(
    double weightKg,
    double heightCm,
    int age,
    Sex sex,
  ) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    switch (sex) {
      case Sex.male:
        return base + 5;
      case Sex.female:
        return base - 161;
    }
  }

  // ---------------------------------------------------------------------------
  // Macro calculation — evidence-based splits
  // ---------------------------------------------------------------------------

  /// Calculate daily macro targets from TDEE and goal.
  ///
  /// Evidence-based splits (ISSN / NSCA position stands):
  ///   - Cut:      25% deficit, high protein (2.0g/kg @ 80kg ref), moderate fat
  ///   - Maintain: 0% adjustment, balanced
  ///   - Bulk:     15% surplus, high protein, high carb
  ///
  /// [weightKg] defaults to 80kg for percentage-to-gram conversion if not given.
  static NutritionTarget calculateMacros({
    required double tdee,
    required FitnessGoal goal,
    double weightKg = 80,
  }) {
    final adjustedCalories = _adjustCaloriesForGoal(tdee, goal);
    final proteinG = calculateProteinTarget(weightKg, _defaultIntensity(goal));
    final fatG = _calculateFat(adjustedCalories, goal);
    final carbsG = _remainingCarbs(adjustedCalories, proteinG, fatG);

    return NutritionTarget(
      calories: adjustedCalories,
      proteinGrams: proteinG,
      carbsGrams: carbsG > 0 ? carbsG : 0,
      fatGrams: fatG,
      waterGlasses: 8,
    );
  }

  static double _adjustCaloriesForGoal(double tdee, FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.cut:
        return tdee * 0.75; // 25% deficit — sustainable, LBM-preserving
      case FitnessGoal.maintain:
        return tdee;
      case FitnessGoal.bulk:
        return tdee * 1.15; // 15% surplus — lean bulk
    }
  }

  static TrainingIntensity _defaultIntensity(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.cut:
        return TrainingIntensity.moderate;
      case FitnessGoal.maintain:
        return TrainingIntensity.moderate;
      case FitnessGoal.bulk:
        return TrainingIntensity.intense;
    }
  }

  /// Fat: 25-35% of calories depending on goal.
  static double _calculateFat(double calories, FitnessGoal goal) {
    final fatPercent = switch (goal) {
      FitnessGoal.cut => 0.25, // lower fat to allow more protein+carbs
      FitnessGoal.maintain => 0.30,
      FitnessGoal.bulk => 0.25, // lower fat, more carbs for performance
    };
    return (calories * fatPercent) / 9; // 9 kcal per gram of fat
  }

  /// Remaining calories go to carbs.
  static double _remainingCarbs(
    double calories,
    double proteinG,
    double fatG,
  ) {
    final usedCalories = (proteinG * 4) + (fatG * 9);
    final remaining = calories - usedCalories;
    return remaining / 4; // 4 kcal per gram of carbs
  }

  // ---------------------------------------------------------------------------
  // Protein target — 1.6–2.2 g/kg (ISSN position stand)
  // ---------------------------------------------------------------------------

  /// Calculate protein target in grams based on body weight and training intensity.
  ///
  /// Evidence (Morton et al., 2018 meta-analysis; ISSN 2017):
  ///   - Light:    1.6 g/kg
  ///   - Moderate: 1.8 g/kg
  ///   - Intense:  2.0 g/kg
  ///   - Very intense / caloric deficit: 2.2 g/kg (preserve LBM)
  static double calculateProteinTarget(
    double weightKg,
    TrainingIntensity intensity,
  ) {
    final gPerKg = switch (intensity) {
      TrainingIntensity.light => 1.6,
      TrainingIntensity.moderate => 1.8,
      TrainingIntensity.intense => 2.0,
      TrainingIntensity.veryIntense => 2.2,
    };
    return weightKg * gPerKg;
  }

  // ---------------------------------------------------------------------------
  // Pre-workout nutrition
  // ---------------------------------------------------------------------------

  /// Calculate pre-workout meal macros based on training time and meal timing.
  ///
  /// Guidelines (ISSN):
  ///   - 2-3h before: full meal (complex carbs + moderate protein + low fat)
  ///   - 1-2h before: moderate meal (easily digestible)
  ///   - <1h before: small snack (simple carbs + minimal protein)
  static Macros calculatePreWorkoutNutrition({
    required DateTime trainingTime,
    Duration? mealTiming,
    double bodyWeightKg = 80,
  }) {
    final now = DateTime.now();
    final timeUntilTraining = trainingTime.difference(now);
    final timingMinutes = timeUntilTraining.inMinutes;

    if (timingMinutes >= 120) {
      // 2+ hours before — full meal
      return Macros(
        calories: bodyWeightKg * 4, // ~4 kcal/kg
        proteinGrams: bodyWeightKg * 0.3, // ~0.3g/kg protein
        carbsGrams: bodyWeightKg * 0.7, // ~0.7g/kg carbs (complex)
        fatGrams: bodyWeightKg * 0.1, // low fat for digestion
        fiberGrams: 5,
      );
    } else if (timingMinutes >= 60) {
      // 1-2 hours before — moderate meal
      return Macros(
        calories: bodyWeightKg * 2.5,
        proteinGrams: bodyWeightKg * 0.2,
        carbsGrams: bodyWeightKg * 0.5, // easily digestible
        fatGrams: bodyWeightKg * 0.05,
        fiberGrams: 3,
      );
    } else {
      // <1 hour — small snack
      return Macros(
        calories: bodyWeightKg * 1.5,
        proteinGrams: bodyWeightKg * 0.1,
        carbsGrams: bodyWeightKg * 0.3, // simple carbs
        fatGrams: bodyWeightKg * 0.02,
        fiberGrams: 1,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Post-workout nutrition
  // ---------------------------------------------------------------------------

  /// Calculate post-workout recovery nutrition.
  ///
  /// Evidence (ISSN, Schoenfeld et al.):
  ///   - Protein: 0.3-0.5g/kg within 2h post-exercise
  ///   - Carbs: 0.8-1.2g/kg for glycogen replenishment
  ///     (higher for longer/intense sessions)
  ///   - Minimal fat (slows absorption when fast recovery needed)
  static Macros calculatePostWorkoutNutrition({
    required double weightKg,
    required int workoutDurationMinutes,
    required TrainingIntensity intensity,
  }) {
    // Scale carbs by duration and intensity
    final durationMultiplier =
        (workoutDurationMinutes / 60).clamp(0.5, 2.0);
    final intensityMultiplier = switch (intensity) {
      TrainingIntensity.light => 0.8,
      TrainingIntensity.moderate => 1.0,
      TrainingIntensity.intense => 1.2,
      TrainingIntensity.veryIntense => 1.4,
    };

    final proteinG = weightKg * 0.4; // mid-range 0.3-0.5g/kg
    final carbsG =
        weightKg * 1.0 * durationMultiplier * intensityMultiplier;
    final fatG = weightKg * 0.05; // minimal

    return Macros(
      calories: proteinG * 4 + carbsG * 4 + fatG * 9,
      proteinGrams: proteinG,
      carbsGrams: carbsG,
      fatGrams: fatG,
      fiberGrams: 2,
    );
  }

  // ---------------------------------------------------------------------------
  // Adherence scoring
  // ---------------------------------------------------------------------------

  /// Calculate how closely daily intake matches targets.
  ///
  /// Returns a score 0.0–1.0 where:
  ///   - 1.0 = within 5% of all targets
  ///   - 0.8 = within 15% of all targets
  ///   - 0.5 = within 30% of all targets
  ///   - <0.5 = significantly off target
  ///
  /// Weights: calories 40%, protein 30%, carbs 15%, fat 15%
  static double getAdherenceScore({
    required DailyNutrition dailyNutrition,
    required NutritionTarget target,
  }) {
    final total = dailyNutrition.totalMacros;

    final calorieScore = _scoreRatio(total.calories, target.calories);
    final proteinScore = _scoreRatio(total.proteinGrams, target.proteinGrams);
    final carbsScore = _scoreRatio(total.carbsGrams, target.carbsGrams);
    final fatScore = _scoreRatio(total.fatGrams, target.fatGrams);

    // Weighted composite
    return calorieScore * 0.4 +
        proteinScore * 0.3 +
        carbsScore * 0.15 +
        fatScore * 0.15;
  }

  /// Score a single ratio: 1.0 at perfect, decaying with deviation.
  static double _scoreRatio(double actual, double target) {
    if (target <= 0) return actual <= 0 ? 1.0 : 0.5;
    final ratio = actual / target;
    final deviation = (ratio - 1.0).abs();

    if (deviation <= 0.05) return 1.0; // within 5%
    if (deviation <= 0.10) return 0.9;
    if (deviation <= 0.15) return 0.8;
    if (deviation <= 0.20) return 0.7;
    if (deviation <= 0.30) return 0.5;
    if (deviation <= 0.50) return 0.3;
    return 0.1;
  }

  // ---------------------------------------------------------------------------
  // Water recommendation
  // ---------------------------------------------------------------------------

  /// Calculate daily water recommendation in glasses (250ml each).
  ///
  /// Base: 35ml per kg body weight (European Food Safety Authority).
  /// Adjustments:
  ///   - Activity: +500ml per hour of exercise
  ///   - Hot/humid climate: +500-1000ml
  static int getWaterRecommendation({
    required double weightKg,
    required ActivityLevel activityLevel,
    Climate climate = Climate.temperate,
  }) {
    // Base: 35ml/kg
    double ml = weightKg * 35;

    // Activity adjustment (approximate exercise duration from activity level)
    final exerciseMl = switch (activityLevel) {
      ActivityLevel.sedentary => 0,
      ActivityLevel.light => 250,
      ActivityLevel.moderate => 500,
      ActivityLevel.active => 750,
      ActivityLevel.veryActive => 1000,
    };
    ml += exerciseMl;

    // Climate adjustment
    final climateMl = switch (climate) {
      Climate.cold => 0,
      Climate.temperate => 0,
      Climate.hot => 500,
      Climate.humid => 750,
    };
    ml += climateMl;

    // Convert to 250ml glasses, round up
    return (ml / 250).ceil();
  }
}
