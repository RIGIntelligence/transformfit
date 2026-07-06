/// M5: Meal planning models and sample plans.
///
/// Pre-built meal plans for different goals (high protein, balanced, cut,
/// bulk, vegetarian). Pure Dart, deterministic.
library;

import 'package:transformfit/features/nutrition/macro_model.dart';

// ── Meal Model ───────────────────────────────────────────────────────────

/// Meal type classification.
/// Reuses MealType from macro_model.dart for consistency.

/// A single ingredient in a meal.
class Ingredient {
  const Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  final String name;
  final double amount;
  final String unit;

  @override
  String toString() => '$amount $unit $name';
}

/// A single meal within a meal plan.
class Meal {
  const Meal({
    required this.name,
    required this.type,
    required this.ingredients,
    required this.macros,
    required this.prepTimeMinutes,
    this.instructions,
  });

  final String name;
  final MealType type;
  final List<Ingredient> ingredients;
  final Macros macros;
  final int prepTimeMinutes;
  final String? instructions;

  Map<String, Object?> toJson() => {
        'name': name,
        'type': type.toJson(),
        'ingredients': ingredients
            .map((i) => {
                  'name': i.name,
                  'amount': i.amount,
                  'unit': i.unit,
                })
            .toList(),
        'macros': macros.toJson(),
        'prepTimeMinutes': prepTimeMinutes,
        'instructions': instructions,
      };

  factory Meal.fromJson(Map<String, Object?> json) => Meal(
        name: json['name'] as String,
        type: MealType.fromJson(json['type'] as String),
        ingredients: (json['ingredients'] as List)
            .map((i) => Ingredient(
                  name: (i as Map<String, Object?>)['name'] as String,
                  amount: (i['amount'] as num).toDouble(),
                  unit: i['unit'] as String,
                ))
            .toList(),
        macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
        prepTimeMinutes: json['prepTimeMinutes'] as int,
        instructions: json['instructions'] as String?,
      );

  @override
  String toString() => 'Meal($name, ${type.name}, ${macros.calories.toStringAsFixed(0)}kcal)';
}

// ── Meal Plan ────────────────────────────────────────────────────────────

/// A complete meal plan for one day.
class MealPlan {
  const MealPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.meals,
    required this.targetGoal,
    this.adherenceScore = 1.0,
  });

  final String id;
  final String name;
  final String description;
  final List<Meal> meals;
  final String targetGoal;
  final double adherenceScore;

  /// Total macros across all meals.
  Macros get totalMacros {
    if (meals.isEmpty) return const Macros.zero();
    return meals.fold(const Macros.zero(), (sum, m) => sum + m.macros);
  }

  /// Total prep time in minutes.
  int get totalPrepTime => meals.fold(0, (sum, m) => sum + m.prepTimeMinutes);

  /// Number of meals.
  int get mealCount => meals.length;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'meals': meals.map((m) => m.toJson()).toList(),
        'targetGoal': targetGoal,
        'adherenceScore': adherenceScore,
      };

  factory MealPlan.fromJson(Map<String, Object?> json) => MealPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        meals: (json['meals'] as List)
            .map((m) => Meal.fromJson(m as Map<String, Object?>))
            .toList(),
        targetGoal: json['targetGoal'] as String,
        adherenceScore: (json['adherenceScore'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  String toString() =>
      'MealPlan($name, ${meals.length} meals, ${totalMacros.calories.toStringAsFixed(0)}kcal)';
}

// ── Default Meal Plans ───────────────────────────────────────────────────

const List<MealPlan> defaultMealPlans = [
  // ── 1. High Protein ──
  MealPlan(
    id: 'plan_high_protein',
    name: 'High Protein',
    description: '200g+ protein for muscle building. Prioritizes complete proteins at every meal.',
    targetGoal: 'muscle_gain',
    meals: [
      Meal(
        name: 'Protein Oats',
        type: MealType.breakfast,
        prepTimeMinutes: 10,
        ingredients: [
          Ingredient(name: 'Oats', amount: 80, unit: 'g'),
          Ingredient(name: 'Whey protein', amount: 30, unit: 'g'),
          Ingredient(name: 'Banana', amount: 1, unit: 'whole'),
          Ingredient(name: 'Peanut butter', amount: 15, unit: 'g'),
        ],
        macros: Macros(calories: 520, proteinGrams: 42, carbsGrams: 62, fatGrams: 14),
      ),
      Meal(
        name: 'Chicken & Rice Bowl',
        type: MealType.lunch,
        prepTimeMinutes: 25,
        ingredients: [
          Ingredient(name: 'Chicken breast', amount: 200, unit: 'g'),
          Ingredient(name: 'Brown rice', amount: 150, unit: 'g'),
          Ingredient(name: 'Broccoli', amount: 100, unit: 'g'),
          Ingredient(name: 'Olive oil', amount: 10, unit: 'ml'),
        ],
        macros: Macros(calories: 620, proteinGrams: 52, carbsGrams: 58, fatGrams: 16),
      ),
      Meal(
        name: 'Greek Yogurt Parfait',
        type: MealType.snack,
        prepTimeMinutes: 5,
        ingredients: [
          Ingredient(name: 'Greek yogurt', amount: 200, unit: 'g'),
          Ingredient(name: 'Mixed berries', amount: 80, unit: 'g'),
          Ingredient(name: 'Granola', amount: 30, unit: 'g'),
        ],
        macros: Macros(calories: 280, proteinGrams: 24, carbsGrams: 32, fatGrams: 6),
      ),
      Meal(
        name: 'Salmon & Sweet Potato',
        type: MealType.dinner,
        prepTimeMinutes: 30,
        ingredients: [
          Ingredient(name: 'Salmon fillet', amount: 180, unit: 'g'),
          Ingredient(name: 'Sweet potato', amount: 200, unit: 'g'),
          Ingredient(name: 'Asparagus', amount: 100, unit: 'g'),
          Ingredient(name: 'Olive oil', amount: 10, unit: 'ml'),
        ],
        macros: Macros(calories: 580, proteinGrams: 44, carbsGrams: 48, fatGrams: 22),
      ),
    ],
  ),

  // ── 2. Balanced ──
  MealPlan(
    id: 'plan_balanced',
    name: 'Balanced',
    description: 'Even macro split for general fitness. ~30% protein, 40% carbs, 30% fat.',
    targetGoal: 'maintenance',
    meals: [
      Meal(
        name: 'Avocado Toast & Eggs',
        type: MealType.breakfast,
        prepTimeMinutes: 10,
        ingredients: [
          Ingredient(name: 'Whole grain bread', amount: 2, unit: 'slices'),
          Ingredient(name: 'Avocado', amount: 0.5, unit: 'whole'),
          Ingredient(name: 'Eggs', amount: 2, unit: 'whole'),
        ],
        macros: Macros(calories: 450, proteinGrams: 22, carbsGrams: 38, fatGrams: 24),
      ),
      Meal(
        name: 'Turkey Wrap',
        type: MealType.lunch,
        prepTimeMinutes: 10,
        ingredients: [
          Ingredient(name: 'Whole wheat tortilla', amount: 1, unit: 'large'),
          Ingredient(name: 'Turkey breast', amount: 120, unit: 'g'),
          Ingredient(name: 'Mixed greens', amount: 50, unit: 'g'),
          Ingredient(name: 'Hummus', amount: 30, unit: 'g'),
        ],
        macros: Macros(calories: 420, proteinGrams: 32, carbsGrams: 40, fatGrams: 14),
      ),
      Meal(
        name: 'Apple & Almonds',
        type: MealType.snack,
        prepTimeMinutes: 2,
        ingredients: [
          Ingredient(name: 'Apple', amount: 1, unit: 'medium'),
          Ingredient(name: 'Almonds', amount: 25, unit: 'g'),
        ],
        macros: Macros(calories: 220, proteinGrams: 6, carbsGrams: 28, fatGrams: 12),
      ),
      Meal(
        name: 'Stir-Fry Tofu & Vegetables',
        type: MealType.dinner,
        prepTimeMinutes: 20,
        ingredients: [
          Ingredient(name: 'Firm tofu', amount: 200, unit: 'g'),
          Ingredient(name: 'Mixed vegetables', amount: 200, unit: 'g'),
          Ingredient(name: 'Brown rice', amount: 120, unit: 'g'),
          Ingredient(name: 'Soy sauce', amount: 15, unit: 'ml'),
        ],
        macros: Macros(calories: 480, proteinGrams: 28, carbsGrams: 52, fatGrams: 16),
      ),
    ],
  ),

  // ── 3. Cut ──
  MealPlan(
    id: 'plan_cut',
    name: 'Cut',
    description: 'High protein, moderate fat, lower carbs for fat loss. ~500kcal deficit.',
    targetGoal: 'fat_loss',
    meals: [
      Meal(
        name: 'Egg White Omelette',
        type: MealType.breakfast,
        prepTimeMinutes: 10,
        ingredients: [
          Ingredient(name: 'Egg whites', amount: 150, unit: 'g'),
          Ingredient(name: 'Spinach', amount: 50, unit: 'g'),
          Ingredient(name: 'Whole egg', amount: 1, unit: 'whole'),
          Ingredient(name: 'Whole grain toast', amount: 1, unit: 'slice'),
        ],
        macros: Macros(calories: 250, proteinGrams: 32, carbsGrams: 16, fatGrams: 8),
      ),
      Meal(
        name: 'Tuna Salad',
        type: MealType.lunch,
        prepTimeMinutes: 10,
        ingredients: [
          Ingredient(name: 'Tuna (canned in water)', amount: 150, unit: 'g'),
          Ingredient(name: 'Mixed greens', amount: 100, unit: 'g'),
          Ingredient(name: 'Cherry tomatoes', amount: 80, unit: 'g'),
          Ingredient(name: 'Balsamic vinegar', amount: 10, unit: 'ml'),
        ],
        macros: Macros(calories: 220, proteinGrams: 38, carbsGrams: 10, fatGrams: 4),
      ),
      Meal(
        name: 'Cottage Cheese & Cucumber',
        type: MealType.snack,
        prepTimeMinutes: 3,
        ingredients: [
          Ingredient(name: 'Low-fat cottage cheese', amount: 150, unit: 'g'),
          Ingredient(name: 'Cucumber', amount: 100, unit: 'g'),
        ],
        macros: Macros(calories: 120, proteinGrams: 18, carbsGrams: 6, fatGrams: 2),
      ),
      Meal(
        name: 'Grilled Chicken & Vegetables',
        type: MealType.dinner,
        prepTimeMinutes: 25,
        ingredients: [
          Ingredient(name: 'Chicken breast', amount: 180, unit: 'g'),
          Ingredient(name: 'Zucchini', amount: 150, unit: 'g'),
          Ingredient(name: 'Bell pepper', amount: 100, unit: 'g'),
          Ingredient(name: 'Olive oil', amount: 5, unit: 'ml'),
        ],
        macros: Macros(calories: 340, proteinGrams: 46, carbsGrams: 14, fatGrams: 12),
      ),
    ],
  ),

  // ── 4. Bulk ──
  MealPlan(
    id: 'plan_bulk',
    name: 'Bulk',
    description: 'Calorie surplus for muscle gain. ~400kcal above maintenance.',
    targetGoal: 'muscle_gain',
    meals: [
      Meal(
        name: 'Mass Gainer Shake',
        type: MealType.breakfast,
        prepTimeMinutes: 5,
        ingredients: [
          Ingredient(name: 'Whole milk', amount: 300, unit: 'ml'),
          Ingredient(name: 'Whey protein', amount: 40, unit: 'g'),
          Ingredient(name: 'Oats', amount: 60, unit: 'g'),
          Ingredient(name: 'Banana', amount: 1, unit: 'whole'),
          Ingredient(name: 'Peanut butter', amount: 30, unit: 'g'),
        ],
        macros: Macros(calories: 780, proteinGrams: 58, carbsGrams: 82, fatGrams: 26),
      ),
      Meal(
        name: 'Double Chicken Burrito',
        type: MealType.lunch,
        prepTimeMinutes: 15,
        ingredients: [
          Ingredient(name: 'Chicken thigh', amount: 250, unit: 'g'),
          Ingredient(name: 'Flour tortilla', amount: 2, unit: 'large'),
          Ingredient(name: 'Black beans', amount: 100, unit: 'g'),
          Ingredient(name: 'Rice', amount: 150, unit: 'g'),
          Ingredient(name: 'Cheese', amount: 40, unit: 'g'),
        ],
        macros: Macros(calories: 920, proteinGrams: 68, carbsGrams: 94, fatGrams: 28),
      ),
      Meal(
        name: 'Trail Mix',
        type: MealType.snack,
        prepTimeMinutes: 1,
        ingredients: [
          Ingredient(name: 'Mixed nuts', amount: 50, unit: 'g'),
          Ingredient(name: 'Dried fruit', amount: 30, unit: 'g'),
          Ingredient(name: 'Dark chocolate chips', amount: 20, unit: 'g'),
        ],
        macros: Macros(calories: 420, proteinGrams: 12, carbsGrams: 42, fatGrams: 24),
      ),
      Meal(
        name: 'Steak & Potato',
        type: MealType.dinner,
        prepTimeMinutes: 30,
        ingredients: [
          Ingredient(name: 'Sirloin steak', amount: 250, unit: 'g'),
          Ingredient(name: 'Baked potato', amount: 250, unit: 'g'),
          Ingredient(name: 'Butter', amount: 15, unit: 'g'),
          Ingredient(name: 'Green beans', amount: 100, unit: 'g'),
        ],
        macros: Macros(calories: 780, proteinGrams: 62, carbsGrams: 56, fatGrams: 32),
      ),
    ],
  ),

  // ── 5. Vegetarian ──
  MealPlan(
    id: 'plan_vegetarian',
    name: 'Vegetarian',
    description: 'Plant-forward with dairy and eggs. Complete proteins from complementary sources.',
    targetGoal: 'maintenance',
    meals: [
      Meal(
        name: 'Tofu Scramble',
        type: MealType.breakfast,
        prepTimeMinutes: 12,
        ingredients: [
          Ingredient(name: 'Firm tofu', amount: 200, unit: 'g'),
          Ingredient(name: 'Bell pepper', amount: 80, unit: 'g'),
          Ingredient(name: 'Spinach', amount: 50, unit: 'g'),
          Ingredient(name: 'Whole grain toast', amount: 2, unit: 'slices'),
          Ingredient(name: 'Nutritional yeast', amount: 10, unit: 'g'),
        ],
        macros: Macros(calories: 420, proteinGrams: 32, carbsGrams: 40, fatGrams: 14),
      ),
      Meal(
        name: 'Lentil Soup & Bread',
        type: MealType.lunch,
        prepTimeMinutes: 25,
        ingredients: [
          Ingredient(name: 'Red lentils', amount: 100, unit: 'g'),
          Ingredient(name: 'Carrots', amount: 80, unit: 'g'),
          Ingredient(name: 'Onion', amount: 50, unit: 'g'),
          Ingredient(name: 'Whole grain bread', amount: 2, unit: 'slices'),
        ],
        macros: Macros(calories: 480, proteinGrams: 28, carbsGrams: 68, fatGrams: 8),
      ),
      Meal(
        name: 'Edamame & Hummus',
        type: MealType.snack,
        prepTimeMinutes: 5,
        ingredients: [
          Ingredient(name: 'Edamame', amount: 100, unit: 'g'),
          Ingredient(name: 'Hummus', amount: 50, unit: 'g'),
          Ingredient(name: 'Carrot sticks', amount: 80, unit: 'g'),
        ],
        macros: Macros(calories: 260, proteinGrams: 18, carbsGrams: 22, fatGrams: 12),
      ),
      Meal(
        name: 'Chickpea Curry & Rice',
        type: MealType.dinner,
        prepTimeMinutes: 25,
        ingredients: [
          Ingredient(name: 'Chickpeas', amount: 200, unit: 'g'),
          Ingredient(name: 'Coconut milk', amount: 100, unit: 'ml'),
          Ingredient(name: 'Brown rice', amount: 120, unit: 'g'),
          Ingredient(name: 'Spinach', amount: 80, unit: 'g'),
        ],
        macros: Macros(calories: 540, proteinGrams: 22, carbsGrams: 72, fatGrams: 16),
      ),
    ],
  ),
];
