import 'package:flutter/material.dart';

/// Reusable hero image background with a dark overlay.
///
/// Used across dashboard screens to add atmospheric depth behind content
/// while preserving readability.
class HeroBackground extends StatelessWidget {
  const HeroBackground({
    super.key,
    required this.assetPath,
    this.overlayOpacity = 0.85,
    this.cacheWidth = 800,
    this.cacheHeight = 600,
  });

  /// Asset path, e.g. 'assets/imagery/hero_workout.png'.
  final String assetPath;

  /// Dark overlay opacity (0 = fully visible image, 1 = fully black).
  final double overlayOpacity;

  /// Downscaled pixel width for memory efficiency.
  final int cacheWidth;

  /// Downscaled pixel height for memory efficiency.
  final int cacheHeight;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
          ),
          // ignore: deprecated_member_use
          Container(
            color: Colors.black.withValues(alpha: overlayOpacity),
          ),
        ],
      ),
    );
  }
}

/// Maps exercise IDs to their Higgsfield imagery asset paths.
///
/// Returns null when no specific image exists — the caller should
/// fall back to a muscle-group placeholder.
String? exerciseImageAsset(String exerciseId) {
  return _exerciseImageMap[exerciseId];
}

/// Returns a placeholder image path based on the primary muscle group.
///
/// Falls back to the kettlebell image for unmatched groups.
String muscleGroupPlaceholder(String muscleGroupName) {
  return _muscleGroupPlaceholders[muscleGroupName] ??
      'assets/imagery/exercise_kettlebell.png';
}

const Map<String, String> _exerciseImageMap = {
  // Chest
  'barbell-bench-press': 'assets/imagery/exercise_bench_press.png',
  'incline-bench-press': 'assets/imagery/exercise_bench_press.png',
  'dumbbell-bench-press': 'assets/imagery/exercise_bench_press.png',
  'incline-dumbbell-press': 'assets/imagery/exercise_bench_press.png',
  'dumbbell-fly': 'assets/imagery/exercise_bench_press.png',
  'cable-fly': 'assets/imagery/exercise_bench_press.png',
  'pec-deck': 'assets/imagery/exercise_bench_press.png',
  'push-up': 'assets/imagery/exercise_plank.png',
  'incline-push-up': 'assets/imagery/exercise_plank.png',
  'decline-push-up': 'assets/imagery/exercise_plank.png',
  'dip': 'assets/imagery/exercise_plank.png',

  // Back
  'barbell-deadlift': 'assets/imagery/exercise_deadlift.png',
  'romanian-deadlift': 'assets/imagery/exercise_deadlift.png',
  'sumo-deadlift': 'assets/imagery/exercise_deadlift.png',
  'trap-bar-deadlift': 'assets/imagery/exercise_deadlift.png',
  'barbell-row': 'assets/imagery/exercise_deadlift.png',
  'pendlay-row': 'assets/imagery/exercise_deadlift.png',
  't-bar-row': 'assets/imagery/exercise_deadlift.png',
  'dumbbell-row': 'assets/imagery/exercise_deadlift.png',
  'pull-up': 'assets/imagery/exercise_pullup.png',
  'chin-up': 'assets/imagery/exercise_pullup.png',
  'lat-pulldown': 'assets/imagery/exercise_pullup.png',

  // Legs
  'barbell-back-squat': 'assets/imagery/exercise_squat.png',
  'front-squat': 'assets/imagery/exercise_squat.png',
  'goblet-squat': 'assets/imagery/exercise_squat.png',
  'leg-press': 'assets/imagery/exercise_squat.png',
  'walking-lunge': 'assets/imagery/exercise_squat.png',
  'bulgarian-split-squat': 'assets/imagery/exercise_squat.png',
  'leg-extension': 'assets/imagery/exercise_squat.png',
  'leg-curl': 'assets/imagery/exercise_squat.png',
  'calf-raise': 'assets/imagery/exercise_squat.png',
  'hip-thrust': 'assets/imagery/exercise_squat.png',

  // Shoulders
  'overhead-press': 'assets/imagery/exercise_overhead_press.png',
  'dumbbell-shoulder-press': 'assets/imagery/exercise_overhead_press.png',
  'lateral-raise': 'assets/imagery/exercise_overhead_press.png',
  'front-raise': 'assets/imagery/exercise_overhead_press.png',
  'face-pull': 'assets/imagery/exercise_overhead_press.png',
  'arnold-press': 'assets/imagery/exercise_overhead_press.png',

  // Arms
  'barbell-curl': 'assets/imagery/exercise_kettlebell.png',
  'dumbbell-curl': 'assets/imagery/exercise_kettlebell.png',
  'hammer-curl': 'assets/imagery/exercise_kettlebell.png',
  'tricep-pushdown': 'assets/imagery/exercise_kettlebell.png',
  'overhead-tricep-extension': 'assets/imagery/exercise_kettlebell.png',
  'skull-crusher': 'assets/imagery/exercise_kettlebell.png',

  // Core
  'plank': 'assets/imagery/exercise_plank.png',
  'side-plank': 'assets/imagery/exercise_plank.png',
  'cable-crunch': 'assets/imagery/exercise_plank.png',
  'hanging-leg-raise': 'assets/imagery/exercise_plank.png',
  'ab-wheel-rollout': 'assets/imagery/exercise_plank.png',
  'russian-twist': 'assets/imagery/exercise_plank.png',

  // Kettlebell
  'kettlebell-swing': 'assets/imagery/exercise_kettlebell.png',
  'kettlebell-goblet-squat': 'assets/imagery/exercise_kettlebell.png',
  'kettlebell-turkish-get-up': 'assets/imagery/exercise_kettlebell.png',

  // Mobility/Yoga
  'downward-dog': 'assets/imagery/exercise_yoga.png',
  'pigeon-pose': 'assets/imagery/exercise_yoga.png',
  'cat-cow': 'assets/imagery/exercise_yoga.png',
  'worlds-greatest-stretch': 'assets/imagery/exercise_yoga.png',
  'hip-90-90': 'assets/imagery/exercise_yoga.png',
};

const Map<String, String> _muscleGroupPlaceholders = {
  'chest': 'assets/imagery/exercise_bench_press.png',
  'back': 'assets/imagery/exercise_deadlift.png',
  'lats': 'assets/imagery/exercise_pullup.png',
  'shoulders': 'assets/imagery/exercise_overhead_press.png',
  'rearDelts': 'assets/imagery/exercise_overhead_press.png',
  'biceps': 'assets/imagery/exercise_kettlebell.png',
  'triceps': 'assets/imagery/exercise_kettlebell.png',
  'forearms': 'assets/imagery/exercise_kettlebell.png',
  'core': 'assets/imagery/exercise_plank.png',
  'obliques': 'assets/imagery/exercise_plank.png',
  'quads': 'assets/imagery/exercise_squat.png',
  'hamstrings': 'assets/imagery/exercise_squat.png',
  'glutes': 'assets/imagery/exercise_squat.png',
  'calves': 'assets/imagery/exercise_squat.png',
  'traps': 'assets/imagery/exercise_deadlift.png',
  'hipFlexors': 'assets/imagery/exercise_yoga.png',
};
