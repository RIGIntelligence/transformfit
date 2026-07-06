/// M4: Training volume tracking per muscle group.
///
/// Tracks weekly sets and volume per muscle group, computes muscle balance,
/// and generates recommendations based on evidence-based training guidelines.
///
/// Volume landmarks based on:
/// - Schoenfeld et al. (2017): 10+ sets/week/muscle for hypertrophy.
/// - Israetel & Hoffmann (2019): MV/MEV/MAV/MRV framework.
/// - Krieger (2010): 2-3x frequency per muscle per week is optimal.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

import 'package:transformfit/features/exercise_library/exercise_model.dart';

// ── Volume Status ────────────────────────────────────────────────────────

/// Volume status relative to evidence-based targets.
enum VolumeStatus {
  /// Below minimum effective volume. Muscle may atrophy.
  under,

  /// Within the productive range. Hypertrophy/strength is progressing.
  balanced,

  /// Above maximum recoverable volume. Risk of overtraining.
  over,
}

// ── MuscleVolume ─────────────────────────────────────────────────────────

/// Volume data for a single muscle group over one week.
class MuscleVolume {
  const MuscleVolume({
    required this.muscleGroup,
    required this.weeklySets,
    required this.weeklyVolumeKg,
    required this.targetMinSets,
    required this.targetMaxSets,
    required this.status,
    this.frequency = 0,
  });

  /// The muscle group being tracked.
  final MuscleGroup muscleGroup;

  /// Total sets performed this week targeting this muscle.
  final int weeklySets;

  /// Total volume (sets × reps × weight) in kg.
  final double weeklyVolumeKg;

  /// Minimum effective volume (sets/week) for this muscle.
  final int targetMinSets;

  /// Maximum recoverable volume (sets/week) for this muscle.
  final int targetMaxSets;

  /// Current volume status.
  final VolumeStatus status;

  /// How many distinct sessions hit this muscle this week.
  final int frequency;

  /// Percentage of the way from minimum to maximum target.
  double get fillPercent {
    if (targetMaxSets <= targetMinSets) return 1.0;
    return ((weeklySets - targetMinSets) / (targetMaxSets - targetMinSets))
        .clamp(0.0, 1.0);
  }

  /// Whether this muscle needs more volume.
  bool get needsMore => status == VolumeStatus.under;

  /// Whether this muscle is in the sweet spot.
  bool get isBalanced => status == VolumeStatus.balanced;

  /// Whether this muscle is being overtrained.
  bool get isOver => status == VolumeStatus.over;

  // ── Serialization ────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
        'muscleGroup': muscleGroup.name,
        'weeklySets': weeklySets,
        'weeklyVolumeKg': weeklyVolumeKg,
        'targetMinSets': targetMinSets,
        'targetMaxSets': targetMaxSets,
        'status': status.name,
        'frequency': frequency,
      };

  factory MuscleVolume.fromJson(Map<String, Object?> json) {
    return MuscleVolume(
      muscleGroup:
          MuscleGroup.values.byName(json['muscleGroup'] as String),
      weeklySets: json['weeklySets'] as int,
      weeklyVolumeKg: (json['weeklyVolumeKg'] as num).toDouble(),
      targetMinSets: json['targetMinSets'] as int,
      targetMaxSets: json['targetMaxSets'] as int,
      status: VolumeStatus.values.byName(json['status'] as String),
      frequency: json['frequency'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'MuscleVolume(${muscleGroup.name}, $weeklySets sets/week, '
      '${status.name})';
}

// ── Exercise Volume Record ───────────────────────────────────────────────

/// A single exercise set record used to compute muscle volume.
class ExerciseVolumeRecord {
  const ExerciseVolumeRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.date,
  });

  final String exerciseId;
  final String exerciseName;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final int sets;
  final int reps;
  final double weightKg;
  final DateTime date;

  /// Volume contribution (sets × reps × weight).
  double get volumeKg => sets * reps * weightKg;
}

// ── Volume Targets ───────────────────────────────────────────────────────

/// Evidence-based volume targets per muscle group (sets/week).
///
/// Source: Israetel & Hoffmann (2019) RP Hypertrophy Volume Guidelines.
/// Min = Maintenance Volume (MV), Max = Maximum Recoverable Volume (MRV).
class VolumeTargets {
  VolumeTargets._();

  static const Map<MuscleGroup, (int min, int max)> _targets = {
    MuscleGroup.chest: (8, 22),
    MuscleGroup.back: (8, 25),
    MuscleGroup.shoulders: (8, 22),
    MuscleGroup.biceps: (6, 20),
    MuscleGroup.triceps: (6, 18),
    MuscleGroup.forearms: (4, 16),
    MuscleGroup.core: (6, 20),
    MuscleGroup.quads: (8, 20),
    MuscleGroup.hamstrings: (6, 18),
    MuscleGroup.glutes: (6, 20),
    MuscleGroup.calves: (6, 16),
    MuscleGroup.traps: (4, 14),
    MuscleGroup.lats: (8, 22),
    MuscleGroup.rearDelts: (6, 18),
    MuscleGroup.hipFlexors: (4, 12),
    MuscleGroup.obliques: (4, 16),
  };

  /// Get (minSets, maxSets) for a muscle group.
  static (int, int) getTarget(MuscleGroup muscle) {
    return _targets[muscle] ?? (6, 18);
  }

  /// Minimum effective volume for a muscle group.
  static int getMinSets(MuscleGroup muscle) => getTarget(muscle).$1;

  /// Maximum recoverable volume for a muscle group.
  static int getMaxSets(MuscleGroup muscle) => getTarget(muscle).$2;
}

// ── Volume Tracker ───────────────────────────────────────────────────────

/// Computes weekly volume per muscle group from exercise records.
///
/// Stateless engine — pass in the exercise records for the week and get
/// back a complete muscle volume analysis.
class VolumeTracker {
  const VolumeTracker();

  /// Compute weekly volume for all muscle groups from a week's exercise log.
  ///
  /// [records] should contain all completed sets for the target week.
  /// Primary muscles get full set credit; secondary muscles get 0.5 credit.
  List<MuscleVolume> getWeeklyVolume(List<ExerciseVolumeRecord> records) {
    // Accumulate sets and volume per muscle group.
    final setsPerMuscle = <MuscleGroup, int>{};
    final volumePerMuscle = <MuscleGroup, double>{};
    final sessionsPerMuscle = <MuscleGroup, Set<String>>{};

    for (final record in records) {
      // Deduplicate by date + exercise for frequency counting.
      final sessionKey =
          '${record.date.toIso8601String().substring(0, 10)}_'
          '${record.exerciseId}';

      for (final muscle in record.primaryMuscles) {
        setsPerMuscle[muscle] =
            (setsPerMuscle[muscle] ?? 0) + record.sets;
        volumePerMuscle[muscle] =
            (volumePerMuscle[muscle] ?? 0) + record.volumeKg;
        sessionsPerMuscle
            .putIfAbsent(muscle, () => {})
            .add(sessionKey);
      }
      for (final muscle in record.secondaryMuscles) {
        // Secondary muscles get half credit.
        setsPerMuscle[muscle] =
            (setsPerMuscle[muscle] ?? 0) + (record.sets / 2).round();
        volumePerMuscle[muscle] =
            (volumePerMuscle[muscle] ?? 0) + (record.volumeKg / 2);
        sessionsPerMuscle
            .putIfAbsent(muscle, () => {})
            .add(sessionKey);
      }
    }

    // Build MuscleVolume for each muscle group that was trained.
    final results = <MuscleVolume>[];
    final allMuscles = <MuscleGroup>{
      ...setsPerMuscle.keys,
      // Include all muscle groups so we can report zeros too.
      ...MuscleGroup.values,
    };

    for (final muscle in allMuscles) {
      final sets = setsPerMuscle[muscle] ?? 0;
      final volume = volumePerMuscle[muscle] ?? 0.0;
      final minSets = VolumeTargets.getMinSets(muscle);
      final maxSets = VolumeTargets.getMaxSets(muscle);
      final frequency = sessionsPerMuscle[muscle]?.length ?? 0;

      final status = _classifyVolume(sets, minSets, maxSets);
      results.add(MuscleVolume(
        muscleGroup: muscle,
        weeklySets: sets,
        weeklyVolumeKg: volume,
        targetMinSets: minSets,
        targetMaxSets: maxSets,
        status: status,
        frequency: frequency,
      ));
    }

    // Sort: under first, then balanced, then over.
    results.sort((a, b) {
      final statusOrder = {
        VolumeStatus.under: 0,
        VolumeStatus.balanced: 1,
        VolumeStatus.over: 2,
      };
      return (statusOrder[a.status] ?? 1)
          .compareTo(statusOrder[b.status] ?? 1);
    });

    return results;
  }

  /// Get muscle balance analysis — identifies weak points and imbalances.
  MuscleBalanceReport getMuscleBalance(List<MuscleVolume> volumes) {
    final underTrained = <MuscleGroup>[];
    final balanced = <MuscleGroup>[];
    final overTrained = <MuscleGroup>[];
    final imbalances = <MuscleImbalance>[];

    for (final vol in volumes) {
      switch (vol.status) {
        case VolumeStatus.under:
          underTrained.add(vol.muscleGroup);
        case VolumeStatus.balanced:
          balanced.add(vol.muscleGroup);
        case VolumeStatus.over:
          overTrained.add(vol.muscleGroup);
      }
    }

    // Check for push/pull imbalance.
    final pushSets = _totalSetsFor(
      volumes,
      [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps],
    );
    final pullSets = _totalSetsFor(
      volumes,
      [MuscleGroup.back, MuscleGroup.biceps, MuscleGroup.lats],
    );
    if (pushSets > 0 && pullSets > 0) {
      final ratio = pushSets / pullSets;
      if (ratio > 1.5) {
        imbalances.add(const MuscleImbalance(
          description: 'Push/Pull imbalance: pushing volume is significantly '
              'higher than pulling. Add more rows, pull-ups, and face pulls.',
          severity: ImbalanceSeverity.moderate,
          affectedMuscles: [
            MuscleGroup.back,
            MuscleGroup.biceps,
            MuscleGroup.rearDelts,
          ],
        ));
      } else if (ratio < 0.6) {
        imbalances.add(const MuscleImbalance(
          description: 'Pull/Push imbalance: pulling volume is significantly '
              'higher than pushing. Add more pressing movements.',
          severity: ImbalanceSeverity.moderate,
          affectedMuscles: [
            MuscleGroup.chest,
            MuscleGroup.shoulders,
            MuscleGroup.triceps,
          ],
        ));
      }
    }

    // Check quad/hamstring ratio.
    final quadSets = _setsForMuscle(volumes, MuscleGroup.quads);
    final hamSets = _setsForMuscle(volumes, MuscleGroup.hamstrings);
    if (quadSets > 0 && hamSets > 0) {
      final ratio = quadSets / hamSets;
      if (ratio > 2.0) {
        imbalances.add(const MuscleImbalance(
          description: 'Quad-dominant: hamstrings are undertrained relative '
              'to quads. Add Romanian deadlifts or leg curls.',
          severity: ImbalanceSeverity.moderate,
          affectedMuscles: [MuscleGroup.hamstrings],
        ));
      }
    }

    return MuscleBalanceReport(
      underTrained: underTrained,
      balanced: balanced,
      overTrained: overTrained,
      imbalances: imbalances,
    );
  }

  /// Generate actionable training recommendations.
  List<String> getRecommendations(List<MuscleVolume> volumes) {
    final recommendations = <String>[];
    final balance = getMuscleBalance(volumes);

    if (balance.underTrained.isNotEmpty) {
      final names =
          balance.underTrained.map((m) => m.name).join(', ');
      recommendations.add(
        'Undertrained muscles ($names). Add 2-4 sets per muscle per week '
        'to reach minimum effective volume.',
      );
    }

    if (balance.overTrained.isNotEmpty) {
      final names =
          balance.overTrained.map((m) => m.name).join(', ');
      recommendations.add(
        'Overtrained muscles ($names). Reduce volume by 2-4 sets per week '
        'or add a deload week to allow recovery.',
      );
    }

    for (final imbalance in balance.imbalances) {
      recommendations.add(imbalance.description);
    }

    // Check frequency recommendations.
    for (final vol in volumes) {
      if (vol.weeklySets >= VolumeTargets.getMinSets(vol.muscleGroup) &&
          vol.frequency < 2) {
        recommendations.add(
          '${vol.muscleGroup.name}: all sets in ${vol.frequency} session. '
          'Split across 2+ sessions for better hypertrophy stimulus.',
        );
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Volume is balanced across all muscle groups. Maintain current '
        'training load and focus on progressive overload.',
      );
    }

    return recommendations;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  VolumeStatus _classifyVolume(int sets, int minSets, int maxSets) {
    if (sets < minSets) return VolumeStatus.under;
    if (sets > maxSets) return VolumeStatus.over;
    return VolumeStatus.balanced;
  }

  int _totalSetsFor(
    List<MuscleVolume> volumes,
    List<MuscleGroup> muscles,
  ) {
    return volumes
        .where((v) => muscles.contains(v.muscleGroup))
        .fold<int>(0, (total, v) => total + v.weeklySets);
  }

  int _setsForMuscle(List<MuscleVolume> volumes, MuscleGroup muscle) {
    return volumes
        .where((v) => v.muscleGroup == muscle)
        .fold<int>(0, (total, v) => total + v.weeklySets);
  }
}

// ── Balance Report ───────────────────────────────────────────────────────

/// Severity of a muscle imbalance.
enum ImbalanceSeverity {
  /// Minor deviation; informational.
  minor,

  /// Noticeable ratio; should be addressed within 2-4 weeks.
  moderate,

  /// Significant imbalance; injury risk if not corrected.
  severe,
}

/// A detected muscle imbalance.
class MuscleImbalance {
  const MuscleImbalance({
    required this.description,
    required this.severity,
    required this.affectedMuscles,
  });

  final String description;
  final ImbalanceSeverity severity;
  final List<MuscleGroup> affectedMuscles;
}

/// Report on muscle group balance.
class MuscleBalanceReport {
  const MuscleBalanceReport({
    required this.underTrained,
    required this.balanced,
    required this.overTrained,
    required this.imbalances,
  });

  /// Muscles below minimum effective volume.
  final List<MuscleGroup> underTrained;

  /// Muscles within the productive range.
  final List<MuscleGroup> balanced;

  /// Muscles above maximum recoverable volume.
  final List<MuscleGroup> overTrained;

  /// Detected imbalances between muscle groups.
  final List<MuscleImbalance> imbalances;

  /// Whether all muscles are within their target range.
  bool get isFullyBalanced =>
      underTrained.isEmpty && overTrained.isEmpty && imbalances.isEmpty;
}

/// Exercise-to-muscle mapping for volume tracking.
///
/// Maps common exercise IDs to their muscle group targets. This supplements
/// the exercise database for quick lookups during volume calculation.
class ExerciseMuscleMapping {
  ExerciseMuscleMapping._();

  /// Map exercise ID to primary muscles. Used when the full Exercise object
  /// is not available.
  static const Map<String, List<MuscleGroup>> primaryByExerciseId = {
    'barbell-bench-press': [MuscleGroup.chest],
    'incline-bench-press': [MuscleGroup.chest, MuscleGroup.shoulders],
    'decline-bench-press': [MuscleGroup.chest],
    'dumbbell-bench-press': [MuscleGroup.chest],
    'barbell-row': [MuscleGroup.back, MuscleGroup.lats],
    'pull-up': [MuscleGroup.back, MuscleGroup.lats],
    'lat-pulldown': [MuscleGroup.lats, MuscleGroup.back],
    'overhead-press': [MuscleGroup.shoulders],
    'lateral-raise': [MuscleGroup.shoulders],
    'barbell-curl': [MuscleGroup.biceps],
    'tricep-pushdown': [MuscleGroup.triceps],
    'skull-crusher': [MuscleGroup.triceps],
    'squat': [MuscleGroup.quads, MuscleGroup.glutes],
    'front-squat': [MuscleGroup.quads],
    'leg-press': [MuscleGroup.quads, MuscleGroup.glutes],
    'romanian-deadlift': [MuscleGroup.hamstrings, MuscleGroup.glutes],
    'leg-curl': [MuscleGroup.hamstrings],
    'calf-raise': [MuscleGroup.calves],
    'plank': [MuscleGroup.core],
    'cable-crunch': [MuscleGroup.core],
    'face-pull': [MuscleGroup.rearDelts, MuscleGroup.traps],
    'shrug': [MuscleGroup.traps],
    'deadlift': [
      MuscleGroup.back,
      MuscleGroup.hamstrings,
      MuscleGroup.glutes,
      MuscleGroup.traps,
    ],
  };

  /// Map exercise ID to secondary muscles.
  static const Map<String, List<MuscleGroup>> secondaryByExerciseId = {
    'barbell-bench-press': [MuscleGroup.triceps, MuscleGroup.shoulders],
    'pull-up': [MuscleGroup.biceps, MuscleGroup.core],
    'overhead-press': [MuscleGroup.triceps, MuscleGroup.core],
    'squat': [MuscleGroup.hamstrings, MuscleGroup.core],
    'deadlift': [MuscleGroup.quads, MuscleGroup.core],
    'romanian-deadlift': [MuscleGroup.back],
    'barbell-row': [MuscleGroup.biceps, MuscleGroup.rearDelts],
  };
}
