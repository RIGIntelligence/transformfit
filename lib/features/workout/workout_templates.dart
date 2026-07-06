/// M5: Pre-built workout template models.
///
/// 10 templates covering strength, hypertrophy, endurance, and recovery.
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

/// Workout category classification.
enum WorkoutCategory {
  strength,
  hypertrophy,
  endurance,
  fullBody,
  mobility,
  recovery;

  String get displayName => switch (this) {
        WorkoutCategory.strength => 'Strength',
        WorkoutCategory.hypertrophy => 'Hypertrophy',
        WorkoutCategory.endurance => 'Endurance',
        WorkoutCategory.fullBody => 'Full Body',
        WorkoutCategory.mobility => 'Mobility',
        WorkoutCategory.recovery => 'Recovery',
      };
}

/// Difficulty level for workout templates.
enum WorkoutDifficulty {
  beginner,
  intermediate,
  advanced;
}

/// An exercise within a workout template.
class TemplateExercise {
  const TemplateExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.restSeconds = 90,
    this.notes,
    this.isTimed = false,
    this.durationSeconds,
  });

  final String name;
  final int sets;
  final String reps; // e.g., "8-10", "12", "30s"
  final int restSeconds;
  final String? notes;
  final bool isTimed;
  final int? durationSeconds;

  Map<String, Object?> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
        'notes': notes,
        'isTimed': isTimed,
        'durationSeconds': durationSeconds,
      };

  factory TemplateExercise.fromJson(Map<String, Object?> json) =>
      TemplateExercise(
        name: json['name'] as String,
        sets: json['sets'] as int,
        reps: json['reps'] as String,
        restSeconds: json['restSeconds'] as int? ?? 90,
        notes: json['notes'] as String?,
        isTimed: json['isTimed'] as bool? ?? false,
        durationSeconds: json['durationSeconds'] as int?,
      );
}

/// A complete workout template.
class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
    required this.difficulty,
    required this.durationMinutes,
    required this.category,
    this.equipment = const [],
    this.tags = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<TemplateExercise> exercises;
  final WorkoutDifficulty difficulty;
  final int durationMinutes;
  final WorkoutCategory category;
  final List<String> equipment;
  final List<String> tags;

  /// Total working sets across all exercises.
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  /// Total exercises.
  int get exerciseCount => exercises.length;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'difficulty': difficulty.name,
        'durationMinutes': durationMinutes,
        'category': category.name,
        'equipment': equipment,
        'tags': tags,
      };

  factory WorkoutTemplate.fromJson(Map<String, Object?> json) =>
      WorkoutTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        exercises: (json['exercises'] as List)
            .map((e) => TemplateExercise.fromJson(e as Map<String, Object?>))
            .toList(),
        difficulty: WorkoutDifficulty.values.byName(
          json['difficulty'] as String,
        ),
        durationMinutes: json['durationMinutes'] as int,
        category: WorkoutCategory.values.byName(
          json['category'] as String,
        ),
        equipment: (json['equipment'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        tags: (json['tags'] as List?)?.map((t) => t as String).toList() ??
            const [],
      );

  @override
  String toString() =>
      'WorkoutTemplate($name, ${exercises.length} exercises, ${durationMinutes}min)';
}

// ── Built-in Templates ──────────────────────────────────────────────────

/// The 10 default workout templates.
const List<WorkoutTemplate> defaultWorkoutTemplates = [
  // ── 1. Push Day ──
  WorkoutTemplate(
    id: 'tpl_push_day',
    name: 'Push Day',
    description: 'Chest, shoulders, and triceps. Compound-heavy with isolation finishers.',
    difficulty: WorkoutDifficulty.intermediate,
    durationMinutes: 55,
    category: WorkoutCategory.hypertrophy,
    equipment: ['barbell', 'dumbbell', 'cable'],
    tags: ['push', 'chest', 'shoulders', 'triceps'],
    exercises: [
      TemplateExercise(name: 'Barbell Bench Press', sets: 4, reps: '6-8', restSeconds: 180),
      TemplateExercise(name: 'Overhead Press', sets: 3, reps: '8-10', restSeconds: 120),
      TemplateExercise(name: 'Incline Dumbbell Press', sets: 3, reps: '10-12', restSeconds: 90),
      TemplateExercise(name: 'Lateral Raises', sets: 3, reps: '12-15', restSeconds: 60),
      TemplateExercise(name: 'Cable Flyes', sets: 3, reps: '12-15', restSeconds: 60),
      TemplateExercise(name: 'Tricep Pushdowns', sets: 3, reps: '12-15', restSeconds: 60),
    ],
  ),

  // ── 2. Pull Day ──
  WorkoutTemplate(
    id: 'tpl_pull_day',
    name: 'Pull Day',
    description: 'Back and biceps. Vertical and horizontal pulling patterns.',
    difficulty: WorkoutDifficulty.intermediate,
    durationMinutes: 50,
    category: WorkoutCategory.hypertrophy,
    equipment: ['barbell', 'dumbbell', 'cable', 'pull_up_bar'],
    tags: ['pull', 'back', 'biceps'],
    exercises: [
      TemplateExercise(name: 'Barbell Rows', sets: 4, reps: '6-8', restSeconds: 180),
      TemplateExercise(name: 'Pull-Ups', sets: 3, reps: '8-10', restSeconds: 120),
      TemplateExercise(name: 'Seated Cable Row', sets: 3, reps: '10-12', restSeconds: 90),
      TemplateExercise(name: 'Face Pulls', sets: 3, reps: '15-20', restSeconds: 60),
      TemplateExercise(name: 'Barbell Curls', sets: 3, reps: '10-12', restSeconds: 60),
      TemplateExercise(name: 'Hammer Curls', sets: 2, reps: '12-15', restSeconds: 60),
    ],
  ),

  // ── 3. Leg Day ──
  WorkoutTemplate(
    id: 'tpl_leg_day',
    name: 'Leg Day',
    description: 'Quads, hamstrings, and glutes. Squat-focused with posterior chain work.',
    difficulty: WorkoutDifficulty.intermediate,
    durationMinutes: 60,
    category: WorkoutCategory.strength,
    equipment: ['barbell', 'dumbbell', 'machine'],
    tags: ['legs', 'quads', 'hamstrings', 'glutes'],
    exercises: [
      TemplateExercise(name: 'Barbell Back Squat', sets: 4, reps: '5-8', restSeconds: 180),
      TemplateExercise(name: 'Romanian Deadlift', sets: 3, reps: '8-10', restSeconds: 120),
      TemplateExercise(name: 'Leg Press', sets: 3, reps: '10-12', restSeconds: 90),
      TemplateExercise(name: 'Walking Lunges', sets: 3, reps: '12 each', restSeconds: 90),
      TemplateExercise(name: 'Leg Curls', sets: 3, reps: '12-15', restSeconds: 60),
      TemplateExercise(name: 'Calf Raises', sets: 4, reps: '15-20', restSeconds: 60),
    ],
  ),

  // ── 4. Upper Body ──
  WorkoutTemplate(
    id: 'tpl_upper_body',
    name: 'Upper Body',
    description: 'Balanced push/pull for the entire upper body.',
    difficulty: WorkoutDifficulty.beginner,
    durationMinutes: 50,
    category: WorkoutCategory.fullBody,
    equipment: ['barbell', 'dumbbell', 'cable'],
    tags: ['upper', 'push', 'pull', 'beginner'],
    exercises: [
      TemplateExercise(name: 'Dumbbell Bench Press', sets: 3, reps: '8-10', restSeconds: 120),
      TemplateExercise(name: 'Dumbbell Rows', sets: 3, reps: '8-10', restSeconds: 120),
      TemplateExercise(name: 'Overhead Press', sets: 3, reps: '10-12', restSeconds: 90),
      TemplateExercise(name: 'Lat Pulldown', sets: 3, reps: '10-12', restSeconds: 90),
      TemplateExercise(name: 'Lateral Raises', sets: 2, reps: '15', restSeconds: 60),
      TemplateExercise(name: 'Bicep Curls', sets: 2, reps: '12-15', restSeconds: 60),
    ],
  ),

  // ── 5. Lower Body ──
  WorkoutTemplate(
    id: 'tpl_lower_body',
    name: 'Lower Body',
    description: 'Squat and hinge patterns with unilateral work.',
    difficulty: WorkoutDifficulty.beginner,
    durationMinutes: 45,
    category: WorkoutCategory.strength,
    equipment: ['barbell', 'dumbbell'],
    tags: ['lower', 'legs', 'beginner'],
    exercises: [
      TemplateExercise(name: 'Goblet Squat', sets: 3, reps: '10-12', restSeconds: 90),
      TemplateExercise(name: 'Romanian Deadlift', sets: 3, reps: '10-12', restSeconds: 90),
      TemplateExercise(name: 'Bulgarian Split Squat', sets: 3, reps: '10 each', restSeconds: 90),
      TemplateExercise(name: 'Leg Curl', sets: 3, reps: '12-15', restSeconds: 60),
      TemplateExercise(name: 'Calf Raises', sets: 3, reps: '15-20', restSeconds: 60),
    ],
  ),

  // ── 6. Full Body ──
  WorkoutTemplate(
    id: 'tpl_full_body',
    name: 'Full Body',
    description: 'One compound per pattern: squat, hinge, push, pull, carry.',
    difficulty: WorkoutDifficulty.beginner,
    durationMinutes: 45,
    category: WorkoutCategory.fullBody,
    equipment: ['barbell', 'dumbbell'],
    tags: ['full_body', 'beginner', 'compound'],
    exercises: [
      TemplateExercise(name: 'Barbell Squat', sets: 3, reps: '8', restSeconds: 120),
      TemplateExercise(name: 'Romanian Deadlift', sets: 3, reps: '10', restSeconds: 90),
      TemplateExercise(name: 'Dumbbell Bench Press', sets: 3, reps: '10', restSeconds: 90),
      TemplateExercise(name: 'Dumbbell Row', sets: 3, reps: '10', restSeconds: 90),
      TemplateExercise(name: 'Farmer\'s Walk', sets: 3, reps: '30s', restSeconds: 60, isTimed: true, durationSeconds: 30),
    ],
  ),

  // ── 7. HIIT Circuit ──
  WorkoutTemplate(
    id: 'tpl_hiit_circuit',
    name: 'HIIT Circuit',
    description: 'High-intensity interval training. 40s work, 20s rest, 4 rounds.',
    difficulty: WorkoutDifficulty.intermediate,
    durationMinutes: 30,
    category: WorkoutCategory.endurance,
    equipment: ['bodyweight', 'kettlebell'],
    tags: ['hiit', 'cardio', 'conditioning'],
    exercises: [
      TemplateExercise(name: 'Burpees', sets: 4, reps: '40s', restSeconds: 20, isTimed: true, durationSeconds: 40),
      TemplateExercise(name: 'Kettlebell Swings', sets: 4, reps: '40s', restSeconds: 20, isTimed: true, durationSeconds: 40),
      TemplateExercise(name: 'Mountain Climbers', sets: 4, reps: '40s', restSeconds: 20, isTimed: true, durationSeconds: 40),
      TemplateExercise(name: 'Jump Squats', sets: 4, reps: '40s', restSeconds: 20, isTimed: true, durationSeconds: 40),
      TemplateExercise(name: 'Push-Up to Renegade Row', sets: 4, reps: '40s', restSeconds: 20, isTimed: true, durationSeconds: 40),
    ],
  ),

  // ── 8. Mobility Flow ──
  WorkoutTemplate(
    id: 'tpl_mobility_flow',
    name: 'Mobility Flow',
    description: 'Dynamic stretching and joint mobility. Perfect for warm-up or active recovery.',
    difficulty: WorkoutDifficulty.beginner,
    durationMinutes: 25,
    category: WorkoutCategory.mobility,
    equipment: ['bodyweight'],
    tags: ['mobility', 'stretching', 'warm_up'],
    exercises: [
      TemplateExercise(name: 'Cat-Cow', sets: 2, reps: '10', restSeconds: 30),
      TemplateExercise(name: 'World\'s Greatest Stretch', sets: 2, reps: '5 each side', restSeconds: 30),
      TemplateExercise(name: 'Hip 90/90 Rotations', sets: 2, reps: '8 each', restSeconds: 30),
      TemplateExercise(name: 'Thoracic Rotations', sets: 2, reps: '8 each', restSeconds: 30),
      TemplateExercise(name: 'Ankle Circles', sets: 2, reps: '10 each', restSeconds: 30),
      TemplateExercise(name: 'Shoulder Dislocates', sets: 2, reps: '10', restSeconds: 30),
    ],
  ),

  // ── 9. Core Blast ──
  WorkoutTemplate(
    id: 'tpl_core_blast',
    name: 'Core Blast',
    description: 'Anti-extension, anti-rotation, and anti-lateral flexion work.',
    difficulty: WorkoutDifficulty.intermediate,
    durationMinutes: 20,
    category: WorkoutCategory.hypertrophy,
    equipment: ['bodyweight', 'cable'],
    tags: ['core', 'abs', 'stability'],
    exercises: [
      TemplateExercise(name: 'Plank', sets: 3, reps: '30-45s', restSeconds: 45, isTimed: true, durationSeconds: 45),
      TemplateExercise(name: 'Pallof Press', sets: 3, reps: '10 each', restSeconds: 45),
      TemplateExercise(name: 'Dead Bug', sets: 3, reps: '10 each', restSeconds: 45),
      TemplateExercise(name: 'Hanging Knee Raise', sets: 3, reps: '12', restSeconds: 60),
      TemplateExercise(name: 'Side Plank', sets: 2, reps: '30s each', restSeconds: 45, isTimed: true, durationSeconds: 30),
    ],
  ),

  // ── 10. Active Recovery ──
  WorkoutTemplate(
    id: 'tpl_active_recovery',
    name: 'Active Recovery',
    description: 'Light movement, foam rolling, and gentle stretching. No intensity.',
    difficulty: WorkoutDifficulty.beginner,
    durationMinutes: 30,
    category: WorkoutCategory.recovery,
    equipment: ['bodyweight'],
    tags: ['recovery', 'foam_rolling', 'light'],
    exercises: [
      TemplateExercise(name: 'Foam Rolling — Quads', sets: 1, reps: '60s', restSeconds: 0, isTimed: true, durationSeconds: 60),
      TemplateExercise(name: 'Foam Rolling — Upper Back', sets: 1, reps: '60s', restSeconds: 0, isTimed: true, durationSeconds: 60),
      TemplateExercise(name: 'Light Walking', sets: 1, reps: '10 min', restSeconds: 0, isTimed: true, durationSeconds: 600),
      TemplateExercise(name: 'Pigeon Stretch', sets: 1, reps: '60s each', restSeconds: 0, isTimed: true, durationSeconds: 60),
      TemplateExercise(name: 'Child\'s Pose', sets: 1, reps: '60s', restSeconds: 0, isTimed: true, durationSeconds: 60),
    ],
  ),
];
