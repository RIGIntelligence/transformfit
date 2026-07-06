/// M4: Exercise search and filter — fuzzy matching, muscle/type/difficulty filters.
///
/// Pure Dart, deterministic. Consumed by the exercise library screen and
/// workout builder.
library;

import 'exercise_database.dart';
import 'exercise_model.dart';

/// Search, filter, and query the exercise database.
class ExerciseSearch {
  ExerciseSearch._();

  static final List<Exercise> _all = ExerciseDatabase.exercises;

  // ── Text search ──────────────────────────────────────────────────────

  /// Fuzzy name search — matches substrings, handles typos via edit distance.
  static List<Exercise> searchByName(String query) {
    if (query.trim().isEmpty) return List.unmodifiable(_all);
    final q = query.trim().toLowerCase();
    final scored = <_ScoredExercise>[];
    for (final e in _all) {
      final name = e.name.toLowerCase();
      final id = e.id.toLowerCase();
      // Exact substring match — highest priority.
      if (name.contains(q) || id.contains(q)) {
        scored.add(_ScoredExercise(e, 3));
        continue;
      }
      // Word-level prefix match.
      if (_wordPrefixMatch(name, q)) {
        scored.add(_ScoredExercise(e, 2));
        continue;
      }
      // Fuzzy — Levenshtein distance on each word.
      if (_fuzzyMatch(name, q)) {
        scored.add(_ScoredExercise(e, 1));
        continue;
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.exercise).toList(growable: false);
  }

  // ── Filters ──────────────────────────────────────────────────────────

  /// Exercises whose primary or secondary muscles include [muscle].
  static List<Exercise> filterByMuscleGroup(MuscleGroup muscle) {
    return _all
        .where((e) =>
            e.primaryMuscles.contains(muscle) ||
            e.secondaryMuscles.contains(muscle))
        .toList(growable: false);
  }

  /// Exercises matching the given equipment type.
  static List<Exercise> filterByType(ExerciseType type) {
    return _all.where((e) => e.type == type).toList(growable: false);
  }

  /// Exercises at the given difficulty level.
  static List<Exercise> filterByDifficulty(DifficultyLevel difficulty) {
    return _all.where((e) => e.difficulty == difficulty).toList(growable: false);
  }

  /// All compound (multi-joint) exercises.
  static List<Exercise> getCompoundExercises() {
    return _all.where((e) => e.isCompound).toList(growable: false);
  }

  /// All isolation (single-joint) exercises.
  static List<Exercise> getIsolationExercises() {
    return _all.where((e) => !e.isCompound).toList(growable: false);
  }

  /// Pseudo-random exercise using a deterministic hash of [seed].
  static Exercise getRandomExercise({String seed = 'default'}) {
    final index = _hashCode(seed) % _all.length;
    return _all[index];
  }

  /// Get a specific exercise by its stable id, or null.
  static Exercise? getById(String id) {
    for (final e in _all) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Combined filter — all criteria must match.
  static List<Exercise> filter({
    MuscleGroup? muscle,
    ExerciseType? type,
    DifficultyLevel? difficulty,
    bool? compound,
  }) {
    return _all.where((e) {
      if (muscle != null &&
          !e.primaryMuscles.contains(muscle) &&
          !e.secondaryMuscles.contains(muscle)) {
        return false;
      }
      if (type != null && e.type != type) return false;
      if (difficulty != null && e.difficulty != difficulty) return false;
      if (compound != null && e.isCompound != compound) return false;
      return true;
    }).toList(growable: false);
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static bool _wordPrefixMatch(String name, String query) {
    final words = name.split(RegExp(r'\s+'));
    for (final w in words) {
      if (w.startsWith(query)) return true;
    }
    return false;
  }

  static bool _fuzzyMatch(String name, String query) {
    final words = name.split(RegExp(r'\s+'));
    for (final w in words) {
      if (_levenshtein(w, query) <= 2) return true;
    }
    return false;
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final m = a.length;
    final n = b.length;
    // Use two-row DP for memory efficiency.
    var prev = List<int>.generate(n + 1, (j) => j);
    var curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1, // deletion
          curr[j - 1] + 1, // insertion
          prev[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }

  static int _hashCode(String s) {
    var hash = 0;
    for (var i = 0; i < s.length; i++) {
      hash = (hash * 31 + s.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }
}

class _ScoredExercise {
  const _ScoredExercise(this.exercise, this.score);
  final Exercise exercise;
  final int score;
}
