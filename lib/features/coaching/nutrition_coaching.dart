library;

/// Categories of nutrition coaching advice.
enum NutritionAdviceCategory {
  protein,
  timing,
  hydration,
  supplement,
}

/// A single piece of nutrition coaching advice.
class NutritionCoachAdvice {
  const NutritionCoachAdvice({
    required this.message,
    required this.category,
    required this.confidence,
    required this.actionable,
  });

  /// Human-readable advice message.
  final String message;

  /// What area of nutrition this advice addresses.
  final NutritionAdviceCategory category;

  /// Confidence level from 0.0 to 1.0 that this advice is relevant.
  final double confidence;

  /// Whether the user can act on this right now.
  final bool actionable;
}

/// Simplified snapshot of a user's recent nutrition data.
///
/// Used by [NutritionCoach] to generate context-aware advice.
class NutritionSnapshot {
  const NutritionSnapshot({
    required this.dailyProteinG,
    required this.proteinTargetG,
    required this.dailyCalories,
    required this.calorieTarget,
    required this.dailyWaterMl,
    required this.waterTargetMl,
    required this.lastMealHour,
    required this.wakeHour,
    required this.sleepHour,
    required this.loggedDaysThisWeek,
    required this.supplementsTaken,
  });

  final double dailyProteinG;
  final double proteinTargetG;
  final double dailyCalories;
  final double calorieTarget;
  final double dailyWaterMl;
  final double waterTargetMl;
  final int lastMealHour; // 0–23
  final int wakeHour;
  final int sleepHour;
  final int loggedDaysThisWeek;
  final List<String> supplementsTaken;
}

/// Deterministic nutrition coach that generates advice from logged data.
class NutritionCoach {
  const NutritionCoach();

  /// Returns a prioritized list of advice based on the user's current data.
  ///
  /// Advice is sorted by confidence (descending) — most relevant first.
  List<NutritionCoachAdvice> getAdvice(NutritionSnapshot data) {
    final advice = <NutritionCoachAdvice>[];

    // Protein advice
    advice.addAll(_proteinAdvice(data));
    // Hydration advice
    advice.addAll(_hydrationAdvice(data));
    // Timing advice
    advice.addAll(_timingAdvice(data));
    // Supplement advice
    advice.addAll(_supplementAdvice(data));

    // Sort by confidence descending.
    advice.sort((a, b) => b.confidence.compareTo(a.confidence));
    return advice;
  }

  /// Protein-specific advice.
  List<NutritionCoachAdvice> getProteinAdvice(NutritionSnapshot data) =>
      _proteinAdvice(data);

  /// Hydration-specific advice.
  List<NutritionCoachAdvice> getHydrationAdvice(NutritionSnapshot data) =>
      _hydrationAdvice(data);

  /// Meal timing advice.
  List<NutritionCoachAdvice> getTimingAdvice(NutritionSnapshot data) =>
      _timingAdvice(data);

  /// Generates a protein reminder based on current intake vs target.
  NutritionCoachAdvice? getProteinReminder(NutritionSnapshot data) {
    final remaining = data.proteinTargetG - data.dailyProteinG;
    if (remaining <= 0) {
      return const NutritionCoachAdvice(
        message: 'You\'ve hit your protein target — great work today!',
        category: NutritionAdviceCategory.protein,
        confidence: 0.95,
        actionable: false,
      );
    }

    final percent = data.proteinTargetG > 0
        ? (data.dailyProteinG / data.proteinTargetG * 100).round()
        : 0;

    if (percent < 50) {
      return NutritionCoachAdvice(
        message:
            'You\'re at ${percent}% of your protein target. '
            'Consider a protein-rich snack — ${remaining.round()}g remaining.',
        category: NutritionAdviceCategory.protein,
        confidence: 0.9,
        actionable: true,
      );
    }

    return NutritionCoachAdvice(
      message:
          'Almost there — ${remaining.round()}g of protein left for today.',
      category: NutritionAdviceCategory.protein,
      confidence: 0.8,
      actionable: true,
    );
  }

  /// Generates a hydration reminder based on current intake.
  NutritionCoachAdvice? getHydrationReminder(NutritionSnapshot data) {
    final remaining = data.waterTargetMl - data.dailyWaterMl;
    if (remaining <= 0) {
      return const NutritionCoachAdvice(
        message: 'Hydration goal met — you\'re well-hydrated today.',
        category: NutritionAdviceCategory.hydration,
        confidence: 0.9,
        actionable: false,
      );
    }

    final glasses = (remaining / 250).ceil();
    return NutritionCoachAdvice(
      message:
          'Drink about $glasses more glasses of water today '
          '(${remaining.round()}ml remaining).',
      category: NutritionAdviceCategory.hydration,
      confidence: 0.85,
      actionable: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal advice generators
  // ---------------------------------------------------------------------------

  List<NutritionCoachAdvice> _proteinAdvice(NutritionSnapshot data) {
    final advice = <NutritionCoachAdvice>[];
    final ratio = data.proteinTargetG > 0
        ? data.dailyProteinG / data.proteinTargetG
        : 1.0;

    if (ratio < 0.3) {
      advice.add(const NutritionCoachAdvice(
        message:
            'Your protein intake is significantly below target. '
            'Aim for a protein source at every meal today.',
        category: NutritionAdviceCategory.protein,
        confidence: 0.95,
        actionable: true,
      ));
    } else if (ratio < 0.7) {
      advice.add(NutritionCoachAdvice(
        message:
            'You\'re ${(ratio * 100).round()}% toward your protein goal. '
            'A high-protein snack could help close the gap.',
        category: NutritionAdviceCategory.protein,
        confidence: 0.85,
        actionable: true,
      ));
    } else if (ratio >= 1.0) {
      advice.add(const NutritionCoachAdvice(
        message: 'Protein target hit for today — consistency pays off.',
        category: NutritionAdviceCategory.protein,
        confidence: 0.9,
        actionable: false,
      ));
    }

    return advice;
  }

  List<NutritionCoachAdvice> _hydrationAdvice(NutritionSnapshot data) {
    final advice = <NutritionCoachAdvice>[];
    final ratio = data.waterTargetMl > 0
        ? data.dailyWaterMl / data.waterTargetMl
        : 1.0;

    if (ratio < 0.4) {
      advice.add(const NutritionCoachAdvice(
        message:
            'You\'re well behind on water intake. Drink a glass now and '
            'set a reminder for every 2 hours.',
        category: NutritionAdviceCategory.hydration,
        confidence: 0.9,
        actionable: true,
      ));
    } else if (ratio < 0.8) {
      advice.add(NutritionCoachAdvice(
        message:
            'Hydration is at ${(ratio * 100).round()}% — keep sipping '
            'throughout the afternoon.',
        category: NutritionAdviceCategory.hydration,
        confidence: 0.75,
        actionable: true,
      ));
    }

    return advice;
  }

  List<NutritionCoachAdvice> _timingAdvice(NutritionSnapshot data) {
    final advice = <NutritionCoachAdvice>[];

    // If it's late and no recent meal logged.
    if (data.lastMealHour >= 0 && data.lastMealHour < data.wakeHour) {
      advice.add(const NutritionCoachAdvice(
        message:
            'No meals logged yet today. Starting with breakfast helps '
            'stabilize energy and appetite.',
        category: NutritionAdviceCategory.timing,
        confidence: 0.8,
        actionable: true,
      ));
    }

    // Long gap since last meal (>5 hours assumed from data).
    final gapHours = data.lastMealHour > 0 ? data.lastMealHour : 0;
    if (gapHours > 0) {
      advice.add(const NutritionCoachAdvice(
        message:
            'It\'s been a while since your last logged meal. '
            'Regular meal timing supports recovery and energy.',
        category: NutritionAdviceCategory.timing,
        confidence: 0.65,
        actionable: true,
      ));
    }

    // Consistency bonus.
    if (data.loggedDaysThisWeek >= 5) {
      advice.add(NutritionCoachAdvice(
        message:
            'You\'ve logged nutrition ${data.loggedDaysThisWeek} days '
            'this week — excellent consistency.',
        category: NutritionAdviceCategory.timing,
        confidence: 0.7,
        actionable: false,
      ));
    }

    return advice;
  }

  List<NutritionCoachAdvice> _supplementAdvice(NutritionSnapshot data) {
    final advice = <NutritionCoachAdvice>[];
    final taken = data.supplementsTaken.map((s) => s.toLowerCase()).toList();

    // Creatine reminder if not taken.
    if (!taken.any((s) => s.contains('creatine'))) {
      advice.add(const NutritionCoachAdvice(
        message:
            'Don\'t forget your creatine — 5g daily is the evidence-based '
            'dose for strength and recovery.',
        category: NutritionAdviceCategory.supplement,
        confidence: 0.6,
        actionable: true,
      ));
    }

    // Vitamin D reminder (generic).
    if (!taken.any((s) => s.contains('vitamin d') || s.contains('vitd'))) {
      advice.add(const NutritionCoachAdvice(
        message:
            'Consider Vitamin D3 if you have limited sun exposure — '
            'it supports bone health and recovery.',
        category: NutritionAdviceCategory.supplement,
        confidence: 0.4,
        actionable: true,
      ));
    }

    return advice;
  }
}
