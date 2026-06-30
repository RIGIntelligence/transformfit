/// Deterministic training-plan generator.
///
/// Single spec (architecture.md "deterministic engine duality", M2
/// plan-generation engine, VAL-ONB-056/057):
///   * Identical intake inputs ALWAYS produce an identical plan structure
///     (no randomness, no time, no hidden state). The LLM later narrates
///     over the plan and is the only thing free to vary.
///   * The plan is filtered by the user's selected equipment. "bodyweight"
///     is always in the effective equipment set (base human equipment), so
///     a no-equipment intake still yields a valid non-empty plan with NO
///     fallback to a hardcoded ["full_gym"] default (VAL-ONB-057).
///   * The same spec is ported to Deno at
///     `supabase/functions/_shared/engines/plan_generation.ts`. The two
///     MUST agree for identical inputs; see the parity-test run.
///
/// This file is PURE: no imports beyond the dart: core. It must be testable
/// under `flutter test` with no widget binding and portable verbatim to Deno.
library;

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

/// Canonical intake inputs that fully determine a generated plan.
class PlanIntake {
  const PlanIntake({
    required this.goal,
    required this.trainingDaysPerWeek,
    required this.equipment,
    this.experienceLevel,
    this.limitations = const [],
  });

  /// Goal id, e.g. "build_muscle".
  final String goal;

  /// 2 .. 6.
  final int trainingDaysPerWeek;

  /// User-selected equipment ids, e.g. {"dumbbells", "barbell"}.
  /// "bodyweight" is added automatically by the engine (base human equipment).
  final List<String> equipment;

  /// "beginner" | "intermediate" | "advanced".
  final String? experienceLevel;

  /// Limitation ids excluding "none". E.g. {"knee", "shoulder"}.
  final List<String> limitations;
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

/// A generated first-training plan. Deterministic for a given [PlanIntake].
class GeneratedPlan {
  GeneratedPlan({
    required this.goal,
    required this.experienceLevel,
    required this.effectiveEquipment,
    required this.daysPerWeek,
    required this.contraindications,
    required this.days,
  });

  final String goal;
  final String? experienceLevel;
  final List<String> effectiveEquipment;
  final int daysPerWeek;
  final List<String> contraindications;
  final List<PlanDay> days;

  /// Total number of plan exercises across all days.
  int get totalExercises => days.fold(0, (s, d) => s + d.exercises.length);

  Map<String, Object?> toJson() => {
        'goal': goal,
        'experienceLevel': experienceLevel,
        'effectiveEquipment': effectiveEquipment,
        'daysPerWeek': daysPerWeek,
        'contraindications': contraindications,
        'days': days.map((d) => d.toJson()).toList(),
      };
}

class PlanDay {
  PlanDay({
    required this.dayNumber,
    required this.focus,
    required this.split,
    required this.exercises,
  });

  final int dayNumber;
  final String focus;
  final String split;
  final List<PlanExercise> exercises;

  Map<String, Object?> toJson() => {
        'dayNumber': dayNumber,
        'focus': focus,
        'split': split,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

class PlanExercise {
  PlanExercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.rpeTarget,
    required this.restSeconds,
    required this.isCompound,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final int sets;
  final int repsMin;
  final int repsMax;
  final int rpeTarget;
  final int restSeconds;
  final bool isCompound;
  final int sortOrder;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'muscleGroup': muscleGroup,
        'equipment': equipment,
        'sets': sets,
        'repsMin': repsMin,
        'repsMax': repsMax,
        'rpeTarget': rpeTarget,
        'restSeconds': restSeconds,
        'isCompound': isCompound,
        'sortOrder': sortOrder,
      };
}

// ---------------------------------------------------------------------------
// Canonical embedded exercise catalog (bodyweight is base human equipment).
// Deterministic: stable id sort, stable selection.
// ---------------------------------------------------------------------------

class _Ex {
  const _Ex({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.isCompound,
    required this.difficulty,
    this.contraindications = const [],
  });

  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final bool isCompound;
  final String difficulty;
  /// Limitation ids that contraindicate this exercise.
  final List<String> contraindications;
}

/// Canonical catalog — stable id order. Single source of truth for the
/// exercise pool (the same catalog is embedded in the Deno engine so the two
/// runtimes agree; the server-side `exercises` table is the long-run source
/// but is unseeded in M2, and embedding keeps the pure/engine-file
/// deterministic-first contract intact).
const List<_Ex> _catalog = [
  // ---------- chest (compound) ----------
  _Ex(id: 'barbell_bench_press', name: 'Barbell Bench Press', muscleGroup: 'chest', equipment: 'barbell', isCompound: true, difficulty: 'intermediate', contraindications: ['shoulder']),
  _Ex(id: 'dumbbell_bench_press', name: 'Dumbbell Bench Press', muscleGroup: 'chest', equipment: 'dumbbells', isCompound: true, difficulty: 'intermediate', contraindications: ['shoulder']),
  _Ex(id: 'pushup', name: 'Push-Up', muscleGroup: 'chest', equipment: 'bodyweight', isCompound: true, difficulty: 'beginner', contraindications: ['shoulder', 'wrist']),
  _Ex(id: 'dumbbell_fly', name: 'Dumbbell Fly', muscleGroup: 'chest', equipment: 'dumbbells', isCompound: false, difficulty: 'intermediate', contraindications: ['shoulder']),
  _Ex(id: 'cable_fly', name: 'Cable Fly', muscleGroup: 'chest', equipment: 'cables', isCompound: false, difficulty: 'intermediate', contraindications: ['shoulder']),
  _Ex(id: 'machine_chest_press', name: 'Machine Chest Press', muscleGroup: 'chest', equipment: 'machines', isCompound: true, difficulty: 'beginner', contraindications: ['shoulder']),
  _Ex(id: 'banded_chest_press', name: 'Banded Chest Press', muscleGroup: 'chest', equipment: 'resistance_bands', isCompound: true, difficulty: 'beginner', contraindications: ['shoulder']),
  // ---------- back (compound) ----------
  _Ex(id: 'pull_up', name: 'Pull-Up', muscleGroup: 'back', equipment: 'pull_up_bar', isCompound: true, difficulty: 'intermediate', contraindications: ['shoulder']),
  _Ex(id: 'barbell_row', name: 'Barbell Row', muscleGroup: 'back', equipment: 'barbell', isCompound: true, difficulty: 'intermediate', contraindications: ['back', 'shoulder']),
  _Ex(id: 'dumbbell_row', name: 'Dumbbell Row', muscleGroup: 'back', equipment: 'dumbbells', isCompound: true, difficulty: 'beginner', contraindications: ['back']),
  _Ex(id: 'cable_row', name: 'Cable Row', muscleGroup: 'back', equipment: 'cables', isCompound: true, difficulty: 'beginner', contraindications: ['back']),
  _Ex(id: 'lat_pulldown', name: 'Lat Pulldown', muscleGroup: 'back', equipment: 'machines', isCompound: true, difficulty: 'beginner', contraindications: ['shoulder']),
  _Ex(id: 'resistance_band_row', name: 'Resistance Band Row', muscleGroup: 'back', equipment: 'resistance_bands', isCompound: true, difficulty: 'beginner', contraindications: ['back']),
  _Ex(id: 'bodyweight_row', name: 'Bodyweight Inverted Row', muscleGroup: 'back', equipment: 'bodyweight', isCompound: true, difficulty: 'beginner', contraindications: ['back', 'shoulder']),
  _Ex(id: 'superman', name: 'Superman Hold', muscleGroup: 'back', equipment: 'bodyweight', isCompound: false, difficulty: 'beginner', contraindications: ['back']),
  // ---------- shoulders ----------
  _Ex(id: 'overhead_press_barbell', name: 'Barbell Overhead Press', muscleGroup: 'shoulders', equipment: 'barbell', isCompound: true, difficulty: 'intermediate', contraindications: ['shoulder', 'wrist']),
  _Ex(id: 'overhead_press_dumbbell', name: 'Dumbbell Overhead Press', muscleGroup: 'shoulders', equipment: 'dumbbells', isCompound: true, difficulty: 'beginner', contraindications: ['shoulder']),
  _Ex(id: 'lateral_raise_dumbbell', name: 'Dumbbell Lateral Raise', muscleGroup: 'shoulders', equipment: 'dumbbells', isCompound: false, difficulty: 'beginner', contraindications: ['shoulder']),
  _Ex(id: 'lateral_raise_band', name: 'Band Lateral Raise', muscleGroup: 'shoulders', equipment: 'resistance_bands', isCompound: false, difficulty: 'beginner', contraindications: ['shoulder']),
  _Ex(id: 'pike_pushup', name: 'Pike Push-Up', muscleGroup: 'shoulders', equipment: 'bodyweight', isCompound: true, difficulty: 'intermediate', contraindications: ['shoulder', 'wrist']),
  _Ex(id: 'face_pull', name: 'Face Pull', muscleGroup: 'shoulders', equipment: 'cables', isCompound: false, difficulty: 'beginner', contraindications: []),
  // ---------- biceps ----------
  _Ex(id: 'barbell_curl', name: 'Barbell Curl', muscleGroup: 'biceps', equipment: 'barbell', isCompound: false, difficulty: 'beginner', contraindications: ['wrist']),
  _Ex(id: 'dumbbell_curl', name: 'Dumbbell Curl', muscleGroup: 'biceps', equipment: 'dumbbells', isCompound: false, difficulty: 'beginner', contraindications: ['wrist']),
  _Ex(id: 'resistance_band_curl', name: 'Band Curl', muscleGroup: 'biceps', equipment: 'resistance_bands', isCompound: false, difficulty: 'beginner', contraindications: ['wrist']),
  _Ex(id: 'bodyweight_curl_iso', name: 'Isometric Arm Curl', muscleGroup: 'biceps', equipment: 'bodyweight', isCompound: false, difficulty: 'beginner', contraindications: []),
  // ---------- triceps ----------
  _Ex(id: 'tricep_dip', name: 'Tricep Dip', muscleGroup: 'triceps', equipment: 'bodyweight', isCompound: true, difficulty: 'intermediate', contraindications: ['shoulder', 'wrist']),
  _Ex(id: 'dumbbell_skull_crusher', name: 'Dumbbell Skull Crusher', muscleGroup: 'triceps', equipment: 'dumbbells', isCompound: false, difficulty: 'intermediate', contraindications: ['wrist']),
  _Ex(id: 'cable_pushdown', name: 'Cable Pushdown', muscleGroup: 'triceps', equipment: 'cables', isCompound: false, difficulty: 'beginner', contraindications: ['wrist']),
  _Ex(id: 'band_pushdown', name: 'Band Pushdown', muscleGroup: 'triceps', equipment: 'resistance_bands', isCompound: false, difficulty: 'beginner', contraindications: []),
  _Ex(id: 'close_grip_pushup', name: 'Close-Grip Push-Up', muscleGroup: 'triceps', equipment: 'bodyweight', isCompound: false, difficulty: 'beginner', contraindications: ['shoulder', 'wrist']),
  // ---------- quads ----------
  _Ex(id: 'barbell_back_squat', name: 'Barbell Back Squat', muscleGroup: 'quads', equipment: 'barbell', isCompound: true, difficulty: 'intermediate', contraindications: ['knee', 'back']),
  _Ex(id: 'goblet_squat', name: 'Goblet Squat', muscleGroup: 'quads', equipment: 'dumbbells', isCompound: true, difficulty: 'beginner', contraindications: ['knee']),
  _Ex(id: 'bodyweight_squat', name: 'Air Squat', muscleGroup: 'quads', equipment: 'bodyweight', isCompound: true, difficulty: 'beginner', contraindications: ['knee']),
  _Ex(id: 'leg_press', name: 'Leg Press', muscleGroup: 'quads', equipment: 'machines', isCompound: true, difficulty: 'beginner', contraindications: ['knee', 'back']),
  _Ex(id: 'lunge_dumbbell', name: 'Dumbbell Lunge', muscleGroup: 'quads', equipment: 'dumbbells', isCompound: true, difficulty: 'beginner', contraindications: ['knee', 'hip']),
  _Ex(id: 'bodyweight_lunge', name: 'Bodyweight Lunge', muscleGroup: 'quads', equipment: 'bodyweight', isCompound: true, difficulty: 'beginner', contraindications: ['knee', 'hip']),
  _Ex(id: 'band_squat', name: 'Band Squat', muscleGroup: 'quads', equipment: 'resistance_bands', isCompound: true, difficulty: 'beginner', contraindications: ['knee']),
  // ---------- hamstrings ----------
  _Ex(id: 'romanian_deadlift', name: 'Romanian Deadlift', muscleGroup: 'hamstrings', equipment: 'barbell', isCompound: true, difficulty: 'intermediate', contraindications: ['back']),
  _Ex(id: 'dumbbell_rdl', name: 'Dumbbell RDL', muscleGroup: 'hamstrings', equipment: 'dumbbells', isCompound: true, difficulty: 'beginner', contraindications: ['back']),
  _Ex(id: 'bodyweight_romanian_deadlift', name: 'Bodyweight Single-Leg RDL', muscleGroup: 'hamstrings', equipment: 'bodyweight', isCompound: true, difficulty: 'beginner', contraindications: ['back']),
  _Ex(id: 'glute_bridge', name: 'Glute Bridge', muscleGroup: 'hamstrings', equipment: 'bodyweight', isCompound: true, difficulty: 'beginner', contraindications: ['back']),
  _Ex(id: 'kettlebell_swing', name: 'Kettlebell Swing', muscleGroup: 'hamstrings', equipment: 'kettlebells', isCompound: true, difficulty: 'intermediate', contraindications: ['back']),
  _Ex(id: 'resistance_band_good_morning', name: 'Band Good Morning', muscleGroup: 'hamstrings', equipment: 'resistance_bands', isCompound: true, difficulty: 'beginner', contraindications: ['back']),
  _Ex(id: 'lying_leg_curl', name: 'Lying Leg Curl', muscleGroup: 'hamstrings', equipment: 'machines', isCompound: false, difficulty: 'beginner', contraindications: []),
  // ---------- glutes ----------
  _Ex(id: 'hip_thrust', name: 'Hip Thrust', muscleGroup: 'glutes', equipment: 'barbell', isCompound: true, difficulty: 'intermediate', contraindications: []),
  _Ex(id: 'dumbbell_hip_thrust', name: 'Dumbbell Hip Thrust', muscleGroup: 'glutes', equipment: 'dumbbells', isCompound: true, difficulty: 'beginner', contraindications: ['back']),
  _Ex(id: 'bodyweight_glute_bridge_walkout', name: 'Glute Bridge Walkout', muscleGroup: 'glutes', equipment: 'bodyweight', isCompound: true, difficulty: 'beginner', contraindications: []),
  _Ex(id: 'band_clamshell', name: 'Band Clamshell', muscleGroup: 'glutes', equipment: 'resistance_bands', isCompound: false, difficulty: 'beginner', contraindications: []),
  // ---------- calves ----------
  _Ex(id: 'standing_calf_raise', name: 'Standing Calf Raise', muscleGroup: 'calves', equipment: 'dumbbells', isCompound: false, difficulty: 'beginner', contraindications: ['ankle']),
  _Ex(id: 'bodyweight_calf_raise', name: 'Bodyweight Calf Raise', muscleGroup: 'calves', equipment: 'bodyweight', isCompound: false, difficulty: 'beginner', contraindications: ['ankle']),
  _Ex(id: 'machine_calf_raise', name: 'Machine Calf Raise', muscleGroup: 'calves', equipment: 'machines', isCompound: false, difficulty: 'beginner', contraindications: ['ankle']),
  // ---------- core ----------
  _Ex(id: 'plank', name: 'Plank', muscleGroup: 'core', equipment: 'bodyweight', isCompound: false, difficulty: 'beginner', contraindications: ['back', 'shoulder', 'wrist']),
  _Ex(id: 'dead_bug', name: 'Dead Bug', muscleGroup: 'core', equipment: 'bodyweight', isCompound: false, difficulty: 'beginner', contraindications: []),
  _Ex(id: 'bird_dog', name: 'Bird Dog', muscleGroup: 'core', equipment: 'bodyweight', isCompound: false, difficulty: 'beginner', contraindications: ['back']),
  _Ex(id: 'bodyweight_crunch', name: 'Crunch', muscleGroup: 'core', equipment: 'bodyweight', isCompound: false, difficulty: 'beginner', contraindications: []),
];

// Canonical sort key for deterministic selection: compounds first, then by id.
int _sortKey(_Ex a, _Ex b) {
  if (a.isCompound != b.isCompound) return a.isCompound ? -1 : 1;
  return a.id.compareTo(b.id);
}

// ---------------------------------------------------------------------------
// Canonical training split splits, by training days per week.
// Deterministic: fixed map. Each day is tagged with a `split` role so the
// muscle-group→day mapping is reproducible.
// ---------------------------------------------------------------------------

class _SplitRole {
  const _SplitRole(this.code, this.focus, this.muscleGroups);
  final String code; // "full" | "upper" | "lower" | "push" | "pull" | "legs"
  final String focus;
  final List<String> muscleGroups;
}

_SplitRole _splitFor(int trainingDaysPerWeek, int dayIndex) {
  switch (trainingDaysPerWeek) {
    case 2:
      return dayIndex == 0
          ? const _SplitRole('full', 'Full Body A', ['chest', 'back', 'quads', 'hamstrings', 'shoulders', 'biceps'])
          : const _SplitRole('full', 'Full Body B', ['quads', 'glutes', 'chest', 'back', 'triceps', 'core']);
    case 3:
      switch (dayIndex) {
        case 0:
          return const _SplitRole('full', 'Full Body A', ['chest', 'back', 'quads', 'hamstrings', 'shoulders', 'biceps']);
        case 1:
          return const _SplitRole('full', 'Full Body B', ['quads', 'glutes', 'chest', 'back', 'triceps', 'core']);
        default:
          return const _SplitRole('full', 'Full Body C', ['hamstrings', 'shoulders', 'back', 'chest', 'calves', 'core']);
      }
    case 4:
      switch (dayIndex % 4) {
        case 0:
          return const _SplitRole('upper', 'Upper A', ['chest', 'back', 'shoulders', 'biceps', 'triceps']);
        case 1:
          return const _SplitRole('lower', 'Lower A', ['quads', 'hamstrings', 'glutes', 'calves', 'core']);
        case 2:
          return const _SplitRole('upper', 'Upper B', ['back', 'chest', 'shoulders', 'triceps', 'biceps']);
        default:
          return const _SplitRole('lower', 'Lower B', ['hamstrings', 'quads', 'glutes', 'core', 'calves']);
      }
    case 5:
      switch (dayIndex % 5) {
        case 0:
          return const _SplitRole('push', 'Push', ['chest', 'shoulders', 'triceps', 'quads']);
        case 1:
          return const _SplitRole('pull', 'Pull', ['back', 'biceps', 'hamstrings']);
        case 2:
          return const _SplitRole('legs', 'Legs', ['quads', 'hamstrings', 'glutes', 'calves']);
        case 3:
          return const _SplitRole('upper', 'Upper', ['chest', 'back', 'shoulders', 'biceps', 'triceps']);
        default:
          return const _SplitRole('lower', 'Lower', ['hamstrings', 'quads', 'glutes', 'core', 'calves']);
      }
    case 6:
    default:
      switch (dayIndex % 6) {
        case 0:
          return const _SplitRole('push', 'Push A', ['chest', 'shoulders', 'triceps', 'quads']);
        case 1:
          return const _SplitRole('pull', 'Pull A', ['back', 'biceps', 'hamstrings']);
        case 2:
          return const _SplitRole('legs', 'Legs A', ['quads', 'hamstrings', 'glutes', 'calves']);
        case 3:
          return const _SplitRole('push', 'Push B', ['shoulders', 'chest', 'triceps', 'core']);
        case 4:
          return const _SplitRole('pull', 'Pull B', ['back', 'biceps', 'rear_shoulders']);
        default:
          return const _SplitRole('legs', 'Legs B', ['hamstrings', 'glutes', 'quads', 'calves']);
      }
  }
}

// ---------------------------------------------------------------------------
// Volume/intensity grid: (sets, repsMin, repsMax, rpeTarget) by [goal][exp].
// Deterministic lookup. Rounded to ints.
// ---------------------------------------------------------------------------

class _Vol {
  const _Vol(this.sets, this.repsMin, this.repsMax, this.rpe);
  final int sets;
  final int repsMin;
  final int repsMax;
  final int rpe;
}

const _Vol _defaultVol = _Vol(3, 8, 12, 8);

const Map<String, Map<String, _Vol>> _volumeGrid = {
  'build_muscle': {
    'beginner': _Vol(3, 10, 12, 7),
    'intermediate': _Vol(3, 8, 12, 8),
    'advanced': _Vol(4, 6, 10, 9),
  },
  'build_strength': {
    'beginner': _Vol(3, 5, 8, 7),
    'intermediate': _Vol(4, 4, 6, 8),
    'advanced': _Vol(5, 3, 5, 9),
  },
  'lose_fat': {
    'beginner': _Vol(3, 10, 15, 7),
    'intermediate': _Vol(3, 10, 12, 8),
    'advanced': _Vol(4, 8, 12, 9),
  },
  'get_fitter': {
    'beginner': _Vol(3, 8, 12, 7),
    'intermediate': _Vol(3, 8, 10, 8),
    'advanced': _Vol(4, 6, 10, 9),
  },
  'improve_mobility': {
    'beginner': _Vol(2, 8, 12, 6),
    'intermediate': _Vol(2, 8, 10, 7),
    'advanced': _Vol(3, 6, 10, 8),
  },
  'train_for_sport': {
    'beginner': _Vol(3, 8, 10, 7),
    'intermediate': _Vol(3, 8, 10, 8),
    'advanced': _Vol(4, 6, 8, 9),
  },
};

_Vol _volumeFor(String goal, String? experienceLevel) {
  final exp = (experienceLevel == null || experienceLevel.isEmpty)
      ? 'intermediate'
      : experienceLevel;
  final byGoal = _volumeGrid[goal];
  if (byGoal != null && byGoal[exp] != null) return byGoal[exp]!;
  return _defaultVol;
}

/// Normalized experience level used as plan provenance. Null/empty -> "intermediate".
String _normalizedExp(String? experienceLevel) =>
    (experienceLevel == null || experienceLevel.isEmpty) ? 'intermediate' : experienceLevel;

/// Target exercises per day, by training-days-per-week bucket.
int _targetExercisesPerDay(int trainingDaysPerWeek) {
  if (trainingDaysPerWeek <= 3) return 6;
  if (trainingDaysPerWeek == 4) return 5;
  return 4;
}

/// Rest seconds. Compound=120, isolation=60. Beginners add 30s.
int _restSeconds(bool isCompound, String? experienceLevel) {
  final base = isCompound ? 120 : 60;
  return (experienceLevel == 'beginner') ? base + 30 : base;
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

/// Generate the first training plan for [intake], deterministically.
///
/// Pure and deterministic: no time, no randomness, no I/O. Same inputs
/// always produce the same plan structure (exercises, sets, reps, rpe_target,
/// rest, stable sort order). Only the narrative LLM text varies downstream.
GeneratedPlan generatePlan(PlanIntake intake) {
  // Canonical effective equipment: user selection + bodyweight (base human equipment).
  final eff = <String>{'bodyweight', ...intake.equipment}..removeWhere((e) => e.isEmpty);

  // Canonical contraindications: strip "none"/empty.
  final contras = <String>[
    for (final l in intake.limitations)
      if (l.isNotEmpty && l != 'none') l,
  ];

  // Filtered, deterministic catalog.
  final usable = _catalog
      .where((e) => eff.contains(e.equipment))
      .where((e) => !e.contraindications.any((c) => contras.contains(c)))
      .toList()
    ..sort(_sortKey);

  // Group usable exercises by muscle group (preserves sort order).
  final byGroup = <String, List<_Ex>>{};
  for (final e in usable) {
    byGroup.putIfAbsent(e.muscleGroup, () => []).add(e);
  }

  final target = _targetExercisesPerDay(intake.trainingDaysPerWeek);
  final vol = _volumeFor(intake.goal, intake.experienceLevel);

  final days = <PlanDay>[];
  for (int d = 0; d < intake.trainingDaysPerWeek; d++) {
    final split = _splitFor(intake.trainingDaysPerWeek, d);

    // Round-robin across the split's listed muscle groups, picking the first
    // usable exercise for each. Stop when target count reached. Stable
    // muscle-group ordering within the split makes this deterministic.
    final exercises = <PlanExercise>[];
    final seen = <String>{};
    final mgOrder = split.muscleGroups;
    // Up to enough round-robin rounds to fill target (cap at mgOrder.length*8
    // for safety).
    for (int round = 0; exercises.length < target && round < mgOrder.length * 8; round++) {
      for (final mg in mgOrder) {
        if (exercises.length >= target) break;
        final candidates = byGroup[mg];
        if (candidates == null) continue;
        for (final c in candidates) {
          if (!seen.contains(c.id)) {
            seen.add(c.id);
            exercises.add(_toPlanExercise(
              c,
              vol,
              intake.experienceLevel,
              exercises.length,
            ));
            break;
          }
        }
      }
    }

    days.add(PlanDay(
      dayNumber: d + 1,
      focus: split.focus,
      split: split.code,
      exercises: exercises,
    ));
  }

  final effList = eff.toList()..sort();

  return GeneratedPlan(
    goal: intake.goal,
    experienceLevel: _normalizedExp(intake.experienceLevel),
    effectiveEquipment: effList,
    daysPerWeek: intake.trainingDaysPerWeek,
    contraindications: contras,
    days: days,
  );
}

PlanExercise _toPlanExercise(
    _Ex e, _Vol vol, String? experienceLevel, int sortOrder) {
  return PlanExercise(
    id: e.id,
    name: e.name,
    muscleGroup: e.muscleGroup,
    equipment: e.equipment,
    sets: vol.sets,
    repsMin: vol.repsMin,
    repsMax: vol.repsMax,
    rpeTarget: vol.rpe,
    restSeconds: _restSeconds(e.isCompound, experienceLevel),
    isCompound: e.isCompound,
    sortOrder: sortOrder,
  );
}
