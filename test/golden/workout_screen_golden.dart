// M4: Golden tests for ActiveWorkoutScreen — snapshot regression testing.
//
// Run with: flutter test test/golden/workout_screen_golden.dart --update-goldens
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/workout/active_workout_screen.dart';
import 'package:transformfit/features/workout/workout_prefill.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// iPhone 11 Pro viewport (414×896 @2x).
const _iphoneSize = Size(414, 896);

SessionController _buildController({
  ReadinessEntry? readiness,
  List<WorkoutSession> history = const [],
}) {
  final r = readiness ??
      ReadinessEntry(
        id: 'golden-readiness',
        date: DateTime(2026, 7, 6),
        score: 78,
        zone: 'push',
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: const ['hips'],
      );
  final controller = SessionController(
    initialState: SessionState(readinessEntry: r, history: history),
  );
  controller.startSession();
  return controller;
}

Future<void> _pumpWorkout(
  WidgetTester tester, {
  SessionController? controller,
  WorkoutPrefill? prefill,
}) async {
  final ctrl = controller ?? _buildController();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWithValue(ctrl),
        ],
      ),
      child: MaterialApp(
        theme: buildDigitalAtelierTheme(),
        home: ActiveWorkoutScreen(initialPrefill: prefill),
      ),
    ),
  );
  // Let animations and initial state settle.
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('ActiveWorkoutScreen Golden Tests', () {
    testWidgets('workout screen — fresh session, no logged sets', (
      tester,
    ) async {
      tester.view.physicalSize = _iphoneSize;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await _pumpWorkout(tester);

      await expectLater(
        find.byType(ActiveWorkoutScreen),
        matchesGoldenFile('goldens/workout_screen_fresh.png'),
      );
    });

    testWidgets('workout screen — with prefill exercise', (tester) async {
      tester.view.physicalSize = _iphoneSize;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final prefill = WorkoutPrefill(
        exerciseName: 'Barbell squat',
        exerciseId: 'barbell-squat',
        suggestedWeightKg: 80,
        targetReps: 5,
        targetRpe: 8,
        targetRestSeconds: 120,
        exerciseIndex: 0,
        sessionExercises: [
          WorkoutPlanExercise(
            exerciseId: 'barbell-squat',
            exerciseName: 'Barbell squat',
            targetSets: 3,
            targetReps: 5,
            targetRpe: 8,
            targetRestSeconds: 120,
            suggestedWeightKg: 80,
          ),
        ],
      );

      await _pumpWorkout(tester, prefill: prefill);

      await expectLater(
        find.byType(ActiveWorkoutScreen),
        matchesGoldenFile('goldens/workout_screen_prefill.png'),
      );
    });

    testWidgets('workout screen — low readiness (deload)', (tester) async {
      tester.view.physicalSize = _iphoneSize;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final lowReadiness = ReadinessEntry(
        id: 'golden-low-readiness',
        date: DateTime(2026, 7, 6),
        score: 32,
        zone: 'deload',
        energyLevel: 3,
        sleepQuality: 4,
        sorenessMap: const ['quads', 'low back'],
      );

      await _pumpWorkout(
        tester,
        controller: _buildController(readiness: lowReadiness),
      );

      await expectLater(
        find.byType(ActiveWorkoutScreen),
        matchesGoldenFile('goldens/workout_screen_deload.png'),
      );
    });

    testWidgets('workout screen — wide viewport (tablet)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await _pumpWorkout(tester);

      await expectLater(
        find.byType(ActiveWorkoutScreen),
        matchesGoldenFile('goldens/workout_screen_tablet.png'),
      );
    });
  });
}
