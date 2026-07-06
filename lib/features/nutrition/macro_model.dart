library;

/// Nutrition data models for TransformFit.
///
/// All models are pure Dart with JSON serialization.

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  preWorkout,
  postWorkout;

  String toJson() => name;

  static MealType fromJson(String json) {
    return MealType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => MealType.snack,
    );
  }
}

enum FitnessGoal { cut, maintain, bulk }

enum Sex { male, female }

enum ActivityLevel {
  sedentary, // 1.2 — desk job, no exercise
  light, // 1.375 — light exercise 1-3 days/week
  moderate, // 1.55 — moderate exercise 3-5 days/week
  active, // 1.725 — hard exercise 6-7 days/week
  veryActive; // 1.9 — athlete / physical job + training

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }
}

enum TrainingIntensity { light, moderate, intense, veryIntense }

enum Climate { cold, temperate, hot, humid }

/// Core macronutrient breakdown.
class Macros {
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double fiberGrams;

  const Macros({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.fiberGrams = 0,
  });

  const Macros.zero()
      : calories = 0,
        proteinGrams = 0,
        carbsGrams = 0,
        fatGrams = 0,
        fiberGrams = 0;

  Macros operator +(Macros other) {
    return Macros(
      calories: calories + other.calories,
      proteinGrams: proteinGrams + other.proteinGrams,
      carbsGrams: carbsGrams + other.carbsGrams,
      fatGrams: fatGrams + other.fatGrams,
      fiberGrams: fiberGrams + other.fiberGrams,
    );
  }

  Macros operator -(Macros other) {
    return Macros(
      calories: calories - other.calories,
      proteinGrams: proteinGrams - other.proteinGrams,
      carbsGrams: carbsGrams - other.carbsGrams,
      fatGrams: fatGrams - other.fatGrams,
      fiberGrams: fiberGrams - other.fiberGrams,
    );
  }

  Macros operator *(double factor) {
    return Macros(
      calories: calories * factor,
      proteinGrams: proteinGrams * factor,
      carbsGrams: carbsGrams * factor,
      fatGrams: fatGrams * factor,
      fiberGrams: fiberGrams * factor,
    );
  }

  double get proteinCalories => proteinGrams * 4;
  double get carbsCalories => carbsGrams * 4;
  double get fatCalories => fatGrams * 9;
  double get fiberCalories => fiberGrams * 2;

  double get proteinPercent =>
      calories > 0 ? (proteinCalories / calories) * 100 : 0;
  double get carbsPercent =>
      calories > 0 ? (carbsCalories / calories) * 100 : 0;
  double get fatPercent => calories > 0 ? (fatCalories / calories) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'fiberGrams': fiberGrams,
      };

  factory Macros.fromJson(Map<String, dynamic> json) => Macros(
        calories: (json['calories'] as num).toDouble(),
        proteinGrams: (json['proteinGrams'] as num).toDouble(),
        carbsGrams: (json['carbsGrams'] as num).toDouble(),
        fatGrams: (json['fatGrams'] as num).toDouble(),
        fiberGrams: (json['fiberGrams'] as num?)?.toDouble() ?? 0,
      );

  @override
  String toString() =>
      'Macros(${calories.toStringAsFixed(0)}kcal, P:${proteinGrams.toStringAsFixed(1)}g, C:${carbsGrams.toStringAsFixed(1)}g, F:${fatGrams.toStringAsFixed(1)}g)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Macros &&
          calories == other.calories &&
          proteinGrams == other.proteinGrams &&
          carbsGrams == other.carbsGrams &&
          fatGrams == other.fatGrams &&
          fiberGrams == other.fiberGrams;

  @override
  int get hashCode => Object.hash(
        calories,
        proteinGrams,
        carbsGrams,
        fatGrams,
        fiberGrams,
      );
}

/// A single food entry / meal log.
class MealEntry {
  final String id;
  final String name;
  final MealType type;
  final Macros macros;
  final DateTime timestamp;
  final String? photoPath;
  final String? notes;

  const MealEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.macros,
    required this.timestamp,
    this.photoPath,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toJson(),
        'macros': macros.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'photoPath': photoPath,
        'notes': notes,
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        type: MealType.fromJson(json['type'] as String),
        macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
        timestamp: DateTime.parse(json['timestamp'] as String),
        photoPath: json['photoPath'] as String?,
        notes: json['notes'] as String?,
      );

  MealEntry copyWith({
    String? id,
    String? name,
    MealType? type,
    Macros? macros,
    DateTime? timestamp,
    String? photoPath,
    String? notes,
  }) {
    return MealEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      macros: macros ?? this.macros,
      timestamp: timestamp ?? this.timestamp,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'MealEntry($name, ${type.name}, ${macros.calories.toStringAsFixed(0)}kcal)';
}

/// Daily nutrition summary.
class DailyNutrition {
  final DateTime date;
  final List<MealEntry> meals;
  final int waterGlasses;
  final List<String> supplements;
  final NutritionTarget? targetMacros;
  final double? adherenceScore;

  const DailyNutrition({
    required this.date,
    required this.meals,
    this.waterGlasses = 0,
    this.supplements = const [],
    this.targetMacros,
    this.adherenceScore,
  });

  /// Auto-calculated total from all logged meals.
  Macros get totalMacros {
    if (meals.isEmpty) return const Macros.zero();
    return meals.fold(
      const Macros.zero(),
      (total, meal) => total + meal.macros,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'meals': meals.map((m) => m.toJson()).toList(),
        'waterGlasses': waterGlasses,
        'supplements': supplements,
        'targetMacros': targetMacros?.toJson(),
        'adherenceScore': adherenceScore,
      };

  factory DailyNutrition.fromJson(Map<String, dynamic> json) =>
      DailyNutrition(
        date: DateTime.parse(json['date'] as String),
        meals: (json['meals'] as List)
            .map((m) => MealEntry.fromJson(m as Map<String, dynamic>))
            .toList(),
        waterGlasses: (json['waterGlasses'] as num?)?.toInt() ?? 0,
        supplements: (json['supplements'] as List?)
                ?.map((s) => s as String)
                .toList() ??
            [],
        targetMacros: json['targetMacros'] != null
            ? NutritionTarget.fromJson(
                json['targetMacros'] as Map<String, dynamic>)
            : null,
        adherenceScore: (json['adherenceScore'] as num?)?.toDouble(),
      );

  DailyNutrition copyWith({
    DateTime? date,
    List<MealEntry>? meals,
    int? waterGlasses,
    List<String>? supplements,
    NutritionTarget? targetMacros,
    double? adherenceScore,
  }) {
    return DailyNutrition(
      date: date ?? this.date,
      meals: meals ?? this.meals,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      supplements: supplements ?? this.supplements,
      targetMacros: targetMacros ?? this.targetMacros,
      adherenceScore: adherenceScore ?? this.adherenceScore,
    );
  }

  @override
  String toString() =>
      'DailyNutrition(${date.toIso8601String().substring(0, 10)}, '
      '${meals.length} meals, ${totalMacros.calories.toStringAsFixed(0)}kcal)';
}

/// User's daily nutrition targets.
class NutritionTarget {
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final int waterGlasses;

  const NutritionTarget({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.waterGlasses = 8,
  });

  Macros toMacros() => Macros(
        calories: calories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'waterGlasses': waterGlasses,
      };

  factory NutritionTarget.fromJson(Map<String, dynamic> json) =>
      NutritionTarget(
        calories: (json['calories'] as num).toDouble(),
        proteinGrams: (json['proteinGrams'] as num).toDouble(),
        carbsGrams: (json['carbsGrams'] as num).toDouble(),
        fatGrams: (json['fatGrams'] as num).toDouble(),
        waterGlasses: (json['waterGlasses'] as num?)?.toInt() ?? 8,
      );

  @override
  String toString() =>
      'NutritionTarget(${calories.toStringAsFixed(0)}kcal, '
      'P:${proteinGrams.toStringAsFixed(0)}g, '
      'C:${carbsGrams.toStringAsFixed(0)}g, '
      'F:${fatGrams.toStringAsFixed(0)}g, '
      '$waterGlasses glasses)';
}
