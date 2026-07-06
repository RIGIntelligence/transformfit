/// M5: Basic food database with 100+ common foods.
///
/// Searchable, filterable food database with macro data per serving.
/// Categories: protein, dairy, grains, fruits, vegetables, fats, beverages.
/// Pure Dart, deterministic.
library;

import 'package:transformfit/features/nutrition/macro_model.dart';

// ── Food Category ────────────────────────────────────────────────────────

/// Food classification for filtering.
enum FoodCategory {
  protein,
  dairy,
  grains,
  fruits,
  vegetables,
  fats,
  beverages;

  String get displayName => switch (this) {
        FoodCategory.protein => 'Protein',
        FoodCategory.dairy => 'Dairy',
        FoodCategory.grains => 'Grains',
        FoodCategory.fruits => 'Fruits',
        FoodCategory.vegetables => 'Vegetables',
        FoodCategory.fats => 'Fats & Oils',
        FoodCategory.beverages => 'Beverages',
      };
}

// ── Food Model ───────────────────────────────────────────────────────────

/// A single food item with nutritional data per serving.
class Food {
  const Food({
    required this.name,
    required this.category,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.fiberGrams = 0,
    this.commonPortions = const [],
  });

  final String name;
  final FoodCategory category;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double fiberGrams;

  /// Common alternative portions (e.g., "1 cup = 240ml").
  final List<String> commonPortions;

  /// Convert to Macros object.
  Macros toMacros() => Macros(
        calories: calories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
        fiberGrams: fiberGrams,
      );

  /// Scale macros for a different serving size.
  Macros macrosForServing(double grams) {
    final factor = grams / servingSize;
    return Macros(
      calories: calories * factor,
      proteinGrams: proteinGrams * factor,
      carbsGrams: carbsGrams * factor,
      fatGrams: fatGrams * factor,
      fiberGrams: fiberGrams * factor,
    );
  }

  @override
  String toString() =>
      '$name ($servingSize$servingUnit, ${calories.toStringAsFixed(0)}kcal)';
}

// ── Food Database ────────────────────────────────────────────────────────

/// Searchable food database.
class FoodDatabase {
  const FoodDatabase._();

  /// All foods in the database.
  static const List<Food> foods = [
    // ── PROTEIN ────────────────────────────────────────────────────────
    Food(name: 'Chicken Breast (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 165, proteinGrams: 31, carbsGrams: 0, fatGrams: 3.6),
    Food(name: 'Chicken Thigh (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 209, proteinGrams: 26, carbsGrams: 0, fatGrams: 10.9),
    Food(name: 'Turkey Breast (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 135, proteinGrams: 30, carbsGrams: 0, fatGrams: 1),
    Food(name: 'Beef Sirloin (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 271, proteinGrams: 26, carbsGrams: 0, fatGrams: 18),
    Food(name: 'Ground Beef 90/10 (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 176, proteinGrams: 20, carbsGrams: 0, fatGrams: 10),
    Food(name: 'Salmon Fillet (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 208, proteinGrams: 20, carbsGrams: 0, fatGrams: 13),
    Food(name: 'Tuna (canned in water)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 116, proteinGrams: 26, carbsGrams: 0, fatGrams: 1),
    Food(name: 'Shrimp (cooked)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 99, proteinGrams: 24, carbsGrams: 0.2, fatGrams: 0.3),
    Food(name: 'Cod Fillet (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 82, proteinGrams: 18, carbsGrams: 0, fatGrams: 0.7),
    Food(name: 'Tilapia (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 96, proteinGrams: 20, carbsGrams: 0, fatGrams: 1.7),
    Food(name: 'Eggs (whole)', category: FoodCategory.protein, servingSize: 50, servingUnit: 'g', calories: 72, proteinGrams: 6, carbsGrams: 0.4, fatGrams: 5),
    Food(name: 'Egg Whites', category: FoodCategory.protein, servingSize: 33, servingUnit: 'g', calories: 17, proteinGrams: 4, carbsGrams: 0.2, fatGrams: 0.1),
    Food(name: 'Pork Loin (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 143, proteinGrams: 26, carbsGrams: 0, fatGrams: 3.5),
    Food(name: 'Bison (raw)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 146, proteinGrams: 28, carbsGrams: 0, fatGrams: 2.4),
    Food(name: 'Tofu (firm)', category: FoodCategory.protein, servingSize: 100, servingUnit: 'g', calories: 144, proteinGrams: 17, carbsGrams: 3, fatGrams: 8),

    // ── DAIRY ──────────────────────────────────────────────────────────
    Food(name: 'Greek Yogurt (0% fat)', category: FoodCategory.dairy, servingSize: 150, servingUnit: 'g', calories: 90, proteinGrams: 15, carbsGrams: 6, fatGrams: 0),
    Food(name: 'Greek Yogurt (2% fat)', category: FoodCategory.dairy, servingSize: 150, servingUnit: 'g', calories: 130, proteinGrams: 14, carbsGrams: 7, fatGrams: 3.5),
    Food(name: 'Cottage Cheese (2% fat)', category: FoodCategory.dairy, servingSize: 100, servingUnit: 'g', calories: 84, proteinGrams: 12, carbsGrams: 4, fatGrams: 2.3),
    Food(name: 'Whole Milk', category: FoodCategory.dairy, servingSize: 240, servingUnit: 'ml', calories: 149, proteinGrams: 8, carbsGrams: 12, fatGrams: 8),
    Food(name: 'Skim Milk', category: FoodCategory.dairy, servingSize: 240, servingUnit: 'ml', calories: 83, proteinGrams: 8, carbsGrams: 12, fatGrams: 0.2),
    Food(name: 'Cheddar Cheese', category: FoodCategory.dairy, servingSize: 28, servingUnit: 'g', calories: 113, proteinGrams: 7, carbsGrams: 0.4, fatGrams: 9),
    Food(name: 'Mozzarella (part-skim)', category: FoodCategory.dairy, servingSize: 28, servingUnit: 'g', calories: 72, proteinGrams: 7, carbsGrams: 1, fatGrams: 4.5),
    Food(name: 'Parmesan Cheese', category: FoodCategory.dairy, servingSize: 10, servingUnit: 'g', calories: 43, proteinGrams: 4, carbsGrams: 0.4, fatGrams: 2.9),
    Food(name: 'Whey Protein Powder', category: FoodCategory.dairy, servingSize: 30, servingUnit: 'g', calories: 120, proteinGrams: 24, carbsGrams: 3, fatGrams: 1),

    // ── GRAINS ─────────────────────────────────────────────────────────
    Food(name: 'White Rice (cooked)', category: FoodCategory.grains, servingSize: 150, servingUnit: 'g', calories: 195, proteinGrams: 4, carbsGrams: 43, fatGrams: 0.4),
    Food(name: 'Brown Rice (cooked)', category: FoodCategory.grains, servingSize: 150, servingUnit: 'g', calories: 173, proteinGrams: 4, carbsGrams: 36, fatGrams: 1.4),
    Food(name: 'Oats (dry)', category: FoodCategory.grains, servingSize: 40, servingUnit: 'g', calories: 152, proteinGrams: 5, carbsGrams: 27, fatGrams: 2.6),
    Food(name: 'Whole Wheat Bread', category: FoodCategory.grains, servingSize: 30, servingUnit: 'g', calories: 75, proteinGrams: 4, carbsGrams: 12, fatGrams: 1.2),
    Food(name: 'White Bread', category: FoodCategory.grains, servingSize: 25, servingUnit: 'g', calories: 66, proteinGrams: 2, carbsGrams: 13, fatGrams: 0.8),
    Food(name: 'Quinoa (cooked)', category: FoodCategory.grains, servingSize: 150, servingUnit: 'g', calories: 180, proteinGrams: 7, carbsGrams: 32, fatGrams: 2.6),
    Food(name: 'Sweet Potato (baked)', category: FoodCategory.grains, servingSize: 150, servingUnit: 'g', calories: 135, proteinGrams: 2.5, carbsGrams: 31, fatGrams: 0.2),
    Food(name: 'White Potato (baked)', category: FoodCategory.grains, servingSize: 150, servingUnit: 'g', calories: 130, proteinGrams: 3, carbsGrams: 30, fatGrams: 0.2),
    Food(name: 'Pasta (cooked)', category: FoodCategory.grains, servingSize: 140, servingUnit: 'g', calories: 220, proteinGrams: 8, carbsGrams: 43, fatGrams: 1.3),
    Food(name: 'Tortilla (flour, large)', category: FoodCategory.grains, servingSize: 60, servingUnit: 'g', calories: 180, proteinGrams: 5, carbsGrams: 30, fatGrams: 4.5),
    Food(name: 'Granola', category: FoodCategory.grains, servingSize: 40, servingUnit: 'g', calories: 190, proteinGrams: 5, carbsGrams: 28, fatGrams: 7),

    // ── FRUITS ─────────────────────────────────────────────────────────
    Food(name: 'Banana', category: FoodCategory.fruits, servingSize: 118, servingUnit: 'g', calories: 105, proteinGrams: 1.3, carbsGrams: 27, fatGrams: 0.4, fiberGrams: 3.1),
    Food(name: 'Apple', category: FoodCategory.fruits, servingSize: 182, servingUnit: 'g', calories: 95, proteinGrams: 0.5, carbsGrams: 25, fatGrams: 0.3, fiberGrams: 4.4),
    Food(name: 'Orange', category: FoodCategory.fruits, servingSize: 131, servingUnit: 'g', calories: 62, proteinGrams: 1.2, carbsGrams: 15, fatGrams: 0.2, fiberGrams: 3.1),
    Food(name: 'Blueberries', category: FoodCategory.fruits, servingSize: 100, servingUnit: 'g', calories: 57, proteinGrams: 0.7, carbsGrams: 14, fatGrams: 0.3, fiberGrams: 2.4),
    Food(name: 'Strawberries', category: FoodCategory.fruits, servingSize: 100, servingUnit: 'g', calories: 32, proteinGrams: 0.7, carbsGrams: 7.7, fatGrams: 0.3, fiberGrams: 2),
    Food(name: 'Avocado', category: FoodCategory.fruits, servingSize: 100, servingUnit: 'g', calories: 160, proteinGrams: 2, carbsGrams: 8.5, fatGrams: 15, fiberGrams: 6.7),
    Food(name: 'Grapes', category: FoodCategory.fruits, servingSize: 100, servingUnit: 'g', calories: 69, proteinGrams: 0.7, carbsGrams: 18, fatGrams: 0.2, fiberGrams: 0.9),
    Food(name: 'Mango', category: FoodCategory.fruits, servingSize: 100, servingUnit: 'g', calories: 60, proteinGrams: 0.8, carbsGrams: 15, fatGrams: 0.4, fiberGrams: 1.6),
    Food(name: 'Pineapple', category: FoodCategory.fruits, servingSize: 100, servingUnit: 'g', calories: 50, proteinGrams: 0.5, carbsGrams: 13, fatGrams: 0.1, fiberGrams: 1.4),
    Food(name: 'Watermelon', category: FoodCategory.fruits, servingSize: 100, servingUnit: 'g', calories: 30, proteinGrams: 0.6, carbsGrams: 7.6, fatGrams: 0.2, fiberGrams: 0.4),

    // ── VEGETABLES ─────────────────────────────────────────────────────
    Food(name: 'Broccoli (cooked)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 35, proteinGrams: 2.4, carbsGrams: 7, fatGrams: 0.4, fiberGrams: 3.3),
    Food(name: 'Spinach (raw)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 23, proteinGrams: 2.9, carbsGrams: 3.6, fatGrams: 0.4, fiberGrams: 2.2),
    Food(name: 'Kale (raw)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 49, proteinGrams: 4.3, carbsGrams: 8.8, fatGrams: 0.9, fiberGrams: 3.6),
    Food(name: 'Bell Pepper (red)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 31, proteinGrams: 1, carbsGrams: 6, fatGrams: 0.3, fiberGrams: 2.1),
    Food(name: 'Carrots (raw)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 41, proteinGrams: 0.9, carbsGrams: 10, fatGrams: 0.2, fiberGrams: 2.8),
    Food(name: 'Cucumber', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 16, proteinGrams: 0.7, carbsGrams: 3.6, fatGrams: 0.1, fiberGrams: 0.5),
    Food(name: 'Tomato', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 18, proteinGrams: 0.9, carbsGrams: 3.9, fatGrams: 0.2, fiberGrams: 1.2),
    Food(name: 'Onion', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 40, proteinGrams: 1.1, carbsGrams: 9.3, fatGrams: 0.1, fiberGrams: 1.7),
    Food(name: 'Zucchini', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 17, proteinGrams: 1.2, carbsGrams: 3.1, fatGrams: 0.3, fiberGrams: 1),
    Food(name: 'Asparagus (cooked)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 22, proteinGrams: 2.4, carbsGrams: 4.1, fatGrams: 0.2, fiberGrams: 2),
    Food(name: 'Green Beans (cooked)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 35, proteinGrams: 1.8, carbsGrams: 7, fatGrams: 0.1, fiberGrams: 3.2),
    Food(name: 'Mushrooms (white)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 22, proteinGrams: 3.1, carbsGrams: 3.3, fatGrams: 0.3, fiberGrams: 1),
    Food(name: 'Cauliflower (cooked)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 23, proteinGrams: 1.8, carbsGrams: 4.1, fatGrams: 0.5, fiberGrams: 2),
    Food(name: 'Brussels Sprouts (cooked)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 43, proteinGrams: 3.4, carbsGrams: 9, fatGrams: 0.3, fiberGrams: 3.8),
    Food(name: 'Edamame (shelled)', category: FoodCategory.vegetables, servingSize: 100, servingUnit: 'g', calories: 121, proteinGrams: 12, carbsGrams: 9, fatGrams: 5, fiberGrams: 5),

    // ── FATS & OILS ────────────────────────────────────────────────────
    Food(name: 'Olive Oil', category: FoodCategory.fats, servingSize: 15, servingUnit: 'ml', calories: 119, proteinGrams: 0, carbsGrams: 0, fatGrams: 14),
    Food(name: 'Coconut Oil', category: FoodCategory.fats, servingSize: 15, servingUnit: 'ml', calories: 121, proteinGrams: 0, carbsGrams: 0, fatGrams: 14),
    Food(name: 'Butter', category: FoodCategory.fats, servingSize: 14, servingUnit: 'g', calories: 102, proteinGrams: 0.1, carbsGrams: 0, fatGrams: 12),
    Food(name: 'Peanut Butter', category: FoodCategory.fats, servingSize: 32, servingUnit: 'g', calories: 190, proteinGrams: 7, carbsGrams: 7, fatGrams: 16),
    Food(name: 'Almond Butter', category: FoodCategory.fats, servingSize: 32, servingUnit: 'g', calories: 196, proteinGrams: 7, carbsGrams: 6, fatGrams: 18),
    Food(name: 'Almonds', category: FoodCategory.fats, servingSize: 28, servingUnit: 'g', calories: 164, proteinGrams: 6, carbsGrams: 6, fatGrams: 14, fiberGrams: 3.5),
    Food(name: 'Walnuts', category: FoodCategory.fats, servingSize: 28, servingUnit: 'g', calories: 185, proteinGrams: 4.3, carbsGrams: 3.9, fatGrams: 18.5, fiberGrams: 1.9),
    Food(name: 'Cashews', category: FoodCategory.fats, servingSize: 28, servingUnit: 'g', calories: 157, proteinGrams: 5.2, carbsGrams: 8.6, fatGrams: 12.4, fiberGrams: 0.9),
    Food(name: 'Chia Seeds', category: FoodCategory.fats, servingSize: 15, servingUnit: 'g', calories: 73, proteinGrams: 2.5, carbsGrams: 6, fatGrams: 4.7, fiberGrams: 5),
    Food(name: 'Flax Seeds (ground)', category: FoodCategory.fats, servingSize: 10, servingUnit: 'g', calories: 53, proteinGrams: 1.8, carbsGrams: 2.9, fatGrams: 4.2, fiberGrams: 2.7),
    Food(name: 'Hemp Seeds', category: FoodCategory.fats, servingSize: 15, servingUnit: 'g', calories: 83, proteinGrams: 5, carbsGrams: 1.2, fatGrams: 7.3, fiberGrams: 0.6),

    // ── BEVERAGES ──────────────────────────────────────────────────────
    Food(name: 'Water', category: FoodCategory.beverages, servingSize: 240, servingUnit: 'ml', calories: 0, proteinGrams: 0, carbsGrams: 0, fatGrams: 0),
    Food(name: 'Black Coffee', category: FoodCategory.beverages, servingSize: 240, servingUnit: 'ml', calories: 2, proteinGrams: 0.3, carbsGrams: 0, fatGrams: 0),
    Food(name: 'Green Tea', category: FoodCategory.beverages, servingSize: 240, servingUnit: 'ml', calories: 2, proteinGrams: 0, carbsGrams: 0, fatGrams: 0),
    Food(name: 'Orange Juice', category: FoodCategory.beverages, servingSize: 240, servingUnit: 'ml', calories: 112, proteinGrams: 2, carbsGrams: 26, fatGrams: 0.5),
    Food(name: 'Apple Juice', category: FoodCategory.beverages, servingSize: 240, servingUnit: 'ml', calories: 114, proteinGrams: 0.2, carbsGrams: 28, fatGrams: 0.3),
    Food(name: 'Protein Shake (milk)', category: FoodCategory.beverages, servingSize: 300, servingUnit: 'ml', calories: 250, proteinGrams: 30, carbsGrams: 16, fatGrams: 6),
    Food(name: 'Almond Milk (unsweetened)', category: FoodCategory.beverages, servingSize: 240, servingUnit: 'ml', calories: 30, proteinGrams: 1, carbsGrams: 1, fatGrams: 2.5),
    Food(name: 'Soy Milk', category: FoodCategory.beverages, servingSize: 240, servingUnit: 'ml', calories: 80, proteinGrams: 7, carbsGrams: 4, fatGrams: 4),
    Food(name: 'Coconut Water', category: FoodCategory.beverages, servingSize: 240, servingUnit: 'ml', calories: 46, proteinGrams: 0.5, carbsGrams: 11, fatGrams: 0.5),
    Food(name: 'Sports Drink', category: FoodCategory.beverages, servingSize: 240, servingUnit: 'ml', calories: 50, proteinGrams: 0, carbsGrams: 14, fatGrams: 0),
  ];

  /// Search foods by name (case-insensitive substring match).
  static List<Food> search(String query) {
    if (query.isEmpty) return foods;
    final lower = query.toLowerCase();
    return foods.where((f) => f.name.toLowerCase().contains(lower)).toList();
  }

  /// Filter foods by category.
  static List<Food> filterByCategory(FoodCategory category) {
    return foods.where((f) => f.category == category).toList();
  }

  /// Search within a specific category.
  static List<Food> searchInCategory(String query, FoodCategory category) {
    final lower = query.toLowerCase();
    return foods
        .where((f) =>
            f.category == category && f.name.toLowerCase().contains(lower))
        .toList();
  }

  /// Get foods sorted by protein density (protein per calorie).
  static List<Food> sortByProteinDensity({int limit = 20}) {
    final sorted = List<Food>.from(foods)
      ..sort((a, b) {
        final aDensity = a.calories > 0 ? a.proteinGrams / a.calories : 0.0;
        final bDensity = b.calories > 0 ? b.proteinGrams / b.calories : 0.0;
        return bDensity.compareTo(aDensity);
      });
    return sorted.take(limit).toList();
  }

  /// Get a food by exact name (case-insensitive).
  static Food? findByName(String name) {
    final lower = name.toLowerCase();
    try {
      return foods.firstWhere((f) => f.name.toLowerCase() == lower);
    } catch (_) {
      return null;
    }
  }

  /// Total count of foods in the database.
  static int get count => foods.length;
}
