/// M4: Exercise data model — enums, Exercise class, JSON serialization.
///
/// Pure Dart, no Flutter dependencies. Used by workout logger, coach,
/// plan generator, and exercise library screens.
library;

/// Muscle groups targeted by exercises.
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  core,
  quads,
  hamstrings,
  glutes,
  calves,
  traps,
  lats,
  rearDelts,
  hipFlexors,
  obliques,
}

/// Equipment / modality type.
enum ExerciseType {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  kettlebell,
  band,
  cardio,
  mobility,
}

/// Difficulty level for progressive programming.
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
}

/// A single exercise in the library.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.difficulty,
    required this.instructions,
    required this.formCues,
    required this.commonMistakes,
    this.variations = const [],
    this.equipment,
    this.isCompound = false,
    this.estimatedCaloriesPerSet = 5,
    this.imageAsset,
  });

  /// Stable identifier — lowercase, hyphenated, never changes.
  final String id;

  /// Human-readable name.
  final String name;

  /// Equipment / modality.
  final ExerciseType type;

  /// Primary muscles worked.
  final List<MuscleGroup> primaryMuscles;

  /// Secondary / stabilizer muscles.
  final List<MuscleGroup> secondaryMuscles;

  /// Difficulty tier.
  final DifficultyLevel difficulty;

  /// Step-by-step instructions.
  final List<String> instructions;

  /// Coaching cues for good form.
  final List<String> formCues;

  /// Common errors to avoid.
  final List<String> commonMistakes;

  /// Alternative exercises or progressions.
  final List<String> variations;

  /// Specific equipment needed (e.g. "barbell", "pull-up bar", null for BW).
  final String? equipment;

  /// Whether this is a compound (multi-joint) movement.
  final bool isCompound;

  /// Rough calories burned per working set (kcal).
  final int estimatedCaloriesPerSet;

  /// Asset path for the exercise demonstration image (e.g. 'assets/imagery/exercise_squat.png').
  /// Null when no specific image exists — the UI falls back to a muscle-group placeholder.
  final String? imageAsset;

  // ── Serialization ──────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
        'secondaryMuscles': secondaryMuscles.map((m) => m.name).toList(),
        'difficulty': difficulty.name,
        'instructions': instructions,
        'formCues': formCues,
        'commonMistakes': commonMistakes,
        'variations': variations,
        'equipment': equipment,
        'isCompound': isCompound,
        'estimatedCaloriesPerSet': estimatedCaloriesPerSet,
        'imageAsset': imageAsset,
      };

  factory Exercise.fromJson(Map<String, Object?> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ExerciseType.values.byName(json['type'] as String),
      primaryMuscles: (json['primaryMuscles'] as List)
          .map((m) => MuscleGroup.values.byName(m as String))
          .toList(),
      secondaryMuscles: (json['secondaryMuscles'] as List)
          .map((m) => MuscleGroup.values.byName(m as String))
          .toList(),
      difficulty: DifficultyLevel.values.byName(json['difficulty'] as String),
      instructions:
          (json['instructions'] as List).map((i) => i as String).toList(),
      formCues: (json['formCues'] as List).map((c) => c as String).toList(),
      commonMistakes: (json['commonMistakes'] as List)
          .map((m) => m as String)
          .toList(),
      variations:
          (json['variations'] as List?)?.map((v) => v as String).toList() ??
              const [],
      equipment: json['equipment'] as String?,
      isCompound: json['isCompound'] as bool? ?? false,
      estimatedCaloriesPerSet:
          json['estimatedCaloriesPerSet'] as int? ?? 5,
      imageAsset: json['imageAsset'] as String?,
    );
  }

  @override
  String toString() => 'Exercise($id: $name)';
}
