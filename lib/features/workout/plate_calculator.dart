/// M5: Barbell plate calculator.
///
/// Calculates which plates to load on each side of a barbell to reach
/// a target weight. Includes warmup plate suggestions. Pure Dart, deterministic.
library;

/// A plate with its weight in kg.
class Plate {
  const Plate(this.weightKg);

  final double weightKg;

  /// Standard Olympic plates.
  static const Plate red = Plate(25); // competition red
  static const Plate blue = Plate(20);
  static const Plate yellow = Plate(15);
  static const Plate green = Plate(10);
  static const Plate white = Plate(5);
  static const Plate redSmall = Plate(2.5);
  static const Plate blueSmall = Plate(1.25);

  /// Default available plates (one pair of each).
  static const List<Plate> standardSet = [
    Plate(20),
    Plate(15),
    Plate(10),
    Plate(5),
    Plate(2.5),
    Plate(1.25),
  ];

  @override
  String toString() => '${weightKg.toStringAsFixed(weightKg == weightKg.roundToDouble() ? 0 : 1)}kg';
}

/// Result of a plate calculation.
class PlateCalculationResult {
  const PlateCalculationResult({
    required this.targetWeightKg,
    required this.barWeightKg,
    required this.platesPerSide,
    required this.actualWeightKg,
    required this.difference,
    this.isExact = true,
  });

  /// The weight the user requested.
  final double targetWeightKg;

  /// Weight of the barbell.
  final double barWeightKg;

  /// Plates to load on EACH side, in order (largest first).
  final List<Plate> platesPerSide;

  /// Actual total weight (bar + all plates).
  final double actualWeightKg;

  /// Difference between target and actual (0 if exact).
  final double difference;

  /// Whether the target was achievable exactly.
  final bool isExact;

  /// Total plate weight (both sides combined).
  double get totalPlateWeight => actualWeightKg - barWeightKg;

  Map<String, Object?> toJson() => {
        'targetWeightKg': targetWeightKg,
        'barWeightKg': barWeightKg,
        'platesPerSide': platesPerSide.map((p) => p.weightKg).toList(),
        'actualWeightKg': actualWeightKg,
        'difference': difference,
        'isExact': isExact,
      };
}

/// Warmup set specification.
class WarmupSet {
  const WarmupSet({
    required this.weightKg,
    required this.reps,
    required this.platesPerSide,
  });

  final double weightKg;
  final int reps;
  final List<Plate> platesPerSide;
}

/// Barbell plate calculator.
///
/// Calculates which plates to load on each side of a barbell to reach
/// a target weight. Uses a greedy algorithm (largest plates first).
class PlateCalculator {
  const PlateCalculator({
    this.availablePlates = Plate.standardSet,
    this.barWeightKg = 20,
    this.minPlateKg = 1.25,
  });

  /// Available plate sizes, sorted largest first.
  final List<Plate> availablePlates;

  /// Barbell weight in kg (standard = 20kg Olympic).
  final double barWeightKg;

  /// Smallest available plate weight.
  final double minPlateKg;

  /// Calculate plates needed for a target weight.
  ///
  /// Returns a [PlateCalculationResult] with the plates per side
  /// and the actual achievable weight.
  PlateCalculationResult calculatePlates(double targetWeightKg) {
    // Weight to distribute across plates (both sides)
    final plateWeight = targetWeightKg - barWeightKg;

    if (plateWeight <= 0) {
      return PlateCalculationResult(
        targetWeightKg: targetWeightKg,
        barWeightKg: barWeightKg,
        platesPerSide: const [],
        actualWeightKg: barWeightKg,
        difference: targetWeightKg - barWeightKg,
        isExact: targetWeightKg == barWeightKg,
      );
    }

    // Weight per side
    final perSide = plateWeight / 2;

    // Greedy: largest plates first
    final sortedPlates = List<Plate>.from(availablePlates)
      ..sort((a, b) => b.weightKg.compareTo(a.weightKg));

    final result = <Plate>[];
    var remaining = perSide;

    for (final plate in sortedPlates) {
      while (remaining >= plate.weightKg - 0.001) {
        // epsilon for floating point
        result.add(plate);
        remaining -= plate.weightKg;
      }
    }

    // Round remaining to nearest min plate
    final actualPerSide = result.fold<double>(0, (sum, p) => sum + p.weightKg);
    final actualTotal = barWeightKg + actualPerSide * 2;
    final diff = (targetWeightKg - actualTotal).abs();

    return PlateCalculationResult(
      targetWeightKg: targetWeightKg,
      barWeightKg: barWeightKg,
      platesPerSide: result,
      actualWeightKg: actualTotal,
      difference: diff,
      isExact: diff < 0.01,
    );
  }

  /// Get a display string like "20 + 10 + 5 per side".
  String getDisplayString(PlateCalculationResult result) {
    if (result.platesPerSide.isEmpty) {
      return 'Bar only (${result.barWeightKg.toStringAsFixed(0)}kg)';
    }

    final plateStr = result.platesPerSide
        .map((p) => p.weightKg.toStringAsFixed(
            p.weightKg == p.weightKg.roundToDouble() ? 0 : 1))
        .join(' + ');

    final suffix = result.isExact
        ? ''
        : ' (≈${result.actualWeightKg.toStringAsFixed(1)}kg)';

    return '$plateStr per side$suffix';
  }

  /// Generate warmup plate suggestions for a working weight.
  ///
  /// Returns 3–5 warmup sets ramping from empty bar to working weight.
  List<WarmupSet> getWarmupPlates(double workingWeightKg) {
    final sets = <WarmupSet>[];

    // Set 1: Empty bar
    sets.add(WarmupSet(
      weightKg: barWeightKg,
      reps: 10,
      platesPerSide: const [],
    ));

    if (workingWeightKg <= barWeightKg) return sets;

    // Calculate warmup increments
    final range = workingWeightKg - barWeightKg;
    final warmupSteps = _warmupIncrements(range);

    for (final increment in warmupSteps) {
      final weight = barWeightKg + increment;
      if (weight >= workingWeightKg) break;

      final calc = calculatePlates(weight);
      final reps = _warmupReps(weight, workingWeightKg);
      sets.add(WarmupSet(
        weightKg: calc.actualWeightKg,
        reps: reps,
        platesPerSide: calc.platesPerSide,
      ));
    }

    // Final warmup: ~80% of working weight
    final eightyPct = (workingWeightKg * 0.8);
    final finalWarmup = calculatePlates(eightyPct);
    if (finalWarmup.actualWeightKg < workingWeightKg) {
      sets.add(WarmupSet(
        weightKg: finalWarmup.actualWeightKg,
        reps: 3,
        platesPerSide: finalWarmup.platesPerSide,
      ));
    }

    return sets;
  }

  /// Warmup weight increments based on range to working weight.
  List<double> _warmupIncrements(double range) {
    if (range <= 20) return [5, 10, 15];
    if (range <= 40) return [10, 20, 30];
    if (range <= 60) return [10, 20, 40, 50];
    if (range <= 80) return [20, 40, 60, 70];
    return [20, 40, 60, 80, 100];
  }

  /// Warmup reps based on proximity to working weight.
  int _warmupReps(double warmupWeight, double workingWeight) {
    final pct = warmupWeight / workingWeight;
    if (pct <= 0.4) return 8;
    if (pct <= 0.6) return 5;
    if (pct <= 0.8) return 3;
    return 2;
  }
}
