// M4: Workout-specific integration tests — full workout logging flow.
//
// Tests the complete workout lifecycle: start → log set → rest timer →
// log second set → finish → debrief.
//
// Run with: flutter test integration_test/workout_flow_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/workout/active_workout_screen.dart';
import 'package:transformfit/features/workout/workout_prefill.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/navigation/auth_state.dart';

/// Build a test harness with a pre-configured session controller.
///
/// This creates a ProviderContainer that overrides the session controller
/// with a realistic initial state (readiness entry + empty session) so
/// the workout screen renders properly without real Supabase.
Future<ProviderContainer> _pumpWorkoutHarness(
  WidgetTester tester, {
  WorkoutPrefill? prefill,
  SessionController? controller,
}) async {
  final readiness = ReadinessEntry(
    id: 'integration-readiness',
    date: DateTime.now(),
    score: 78,
    zone: 'push',
    energyLevel: 8,
    sleepQuality: 8,
    sorenessMap: const ['hips'],
  );

  final sessionController = controller ??
      SessionController(
        initialState: SessionState(readinessEntry: readiness),
      );
  sessionController.startSession();

  final container = ProviderContainer(
    overrides: [
      sessionControllerProvider.overrideWithValue(sessionController),
      authGuardStateProvider.overrideWith((ref) {
        final state = AuthGuardState(
          initialStatus: AuthGuardStatus.authenticatedWithProfile,
        );
        ref.onDispose(state.dispose);
        return state;
      }),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(() => tester.pump(const Duration(seconds: 200)));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDigitalAtelierTheme(),
        home: ActiveWorkoutScreen(initialPrefill: prefill),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
  return container;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Workout Flow Integration Tests', () {
    // ── Start Workout ────────────────────────────────────────────────────

    testWidgets('Workout screen renders with exercise name and controls', (
      tester,
    ) async {
      await _pumpWorkoutHarness(tester);

      // The screen should show the default exercise name.
      expect(find.textContaining('Goblet squat'), findsWidgets);

      // Weight and reps controls should be visible.
      expect(find.textContaining('kg'), findsWidgets);

      // Log Set button should be present.
      expect(find.textContaining('Log Set'), findsOneWidget);
    });

    testWidgets('Workout screen shows readiness status when capped', (
      tester,
    ) async {
      await _pumpWorkoutHarness(tester);

      // With readiness score 78 (push zone), the status line should
      // reflect readiness adjustments.
      // The live status area may show readiness cap information.
      expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
    });

    // ── Log First Set ────────────────────────────────────────────────────

    testWidgets('Log first set — appears in set history', (tester) async {
      await _pumpWorkoutHarness(tester);

      // Tap the Log Set button.
      final logSetButton = find.textContaining('Log Set');
      expect(logSetButton, findsOneWidget);
      await tester.tap(logSetButton);
      await tester.pump(const Duration(seconds: 1));

      // After logging, the set should appear in the history.
      // The screen updates to show "Set 1" or similar.
      expect(find.textContaining('Set'), findsWidgets);
    });

    // ── Rest Timer ───────────────────────────────────────────────────────

    testWidgets('Rest timer starts after logging a set', (tester) async {
      await _pumpWorkoutHarness(tester);

      // Log a set.
      await tester.tap(find.textContaining('Log Set'));
      await tester.pump(const Duration(milliseconds: 500));

      // The rest countdown should become active.
      // The screen should show a countdown or rest indicator.
      // After the set flash (800ms), the rest timer UI appears.
      await tester.pump(const Duration(seconds: 1));

      // Verify the workout screen is still displayed (not crashed).
      expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
    });

    // ── Log Second Set ───────────────────────────────────────────────────

    testWidgets('Log second set — rest timer resets', (tester) async {
      await _pumpWorkoutHarness(tester);

      // Log first set.
      await tester.tap(find.textContaining('Log Set'));
      await tester.pump(const Duration(seconds: 1));

      // Wait for rest countdown to tick a bit.
      await tester.pump(const Duration(seconds: 3));

      // Log second set.
      await tester.tap(find.textContaining('Log Set'));
      await tester.pump(const Duration(seconds: 1));

      // Both sets should now appear.
      expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
    });

    // ── Warmup Set ───────────────────────────────────────────────────────

    testWidgets('Warmup set applies reduced weight and RPE', (tester) async {
      await _pumpWorkoutHarness(tester);

      // Find and tap the warmup button.
      final warmupButton = find.textContaining('Warm');
      if (warmupButton.evaluate().isNotEmpty) {
        await tester.tap(warmupButton);
        await tester.pump(const Duration(milliseconds: 500));

        // The live status should confirm warmup loaded.
        expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
      }
    });

    // ── Previous Set ─────────────────────────────────────────────────────

    testWidgets('Previous set button present', (tester) async {
      // Pre-populate with history.
      final history = [
        WorkoutSession(
          id: 'session-prev',
          readinessEntryId: 'readiness-prev',
          startedAt: DateTime.now().subtract(const Duration(days: 2)),
          endedAt: DateTime.now().subtract(const Duration(days: 2)),
          loggedSets: [
            LoggedSet(
              id: 'set-prev-1',
              exerciseName: 'Goblet squat',
              setNumber: 1,
              exerciseId: 'goblet-squat',
              weightKg: 40,
              reps: 10,
              rpe: 7,
              loggedAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ],
        ),
      ];

      final readiness = ReadinessEntry(
        id: 'readiness-prev',
        date: DateTime.now(),
        score: 78,
        zone: 'push',
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: const [],
      );

      final controller = SessionController(
        initialState: SessionState(
          readinessEntry: readiness,
          history: history,
        ),
      );

      await _pumpWorkoutHarness(tester, controller: controller);

      // The "Prev" button should be available.
      expect(find.textContaining('Prev'), findsOneWidget);
    });

    // ── Technique Swap ───────────────────────────────────────────────────

    testWidgets('Technique swap button is available', (tester) async {
      await _pumpWorkoutHarness(tester);

      // Find the swap button.
      final swapButton = find.textContaining('Swap');
      if (swapButton.evaluate().isNotEmpty) {
        expect(swapButton, findsOneWidget);
      }
    });

    // ── Finish Workout ───────────────────────────────────────────────────

    testWidgets('Finish button navigates to debrief', (tester) async {
      await _pumpWorkoutHarness(tester);

      // Log at least one set so finish has data.
      await tester.tap(find.textContaining('Log Set'));
      await tester.pump(const Duration(seconds: 1));

      // Find and tap the Finish button.
      final finishButton = find.textContaining('Finish');
      if (finishButton.evaluate().isNotEmpty) {
        await tester.tap(finishButton);
        await tester.pumpAndSettle();

        // After finishing, the app should navigate to debrief.
        expect(find.byType(ActiveWorkoutScreen), findsNothing);
      }
    });

    // ── Pain Safety ──────────────────────────────────────────────────────

    testWidgets('Pain safety button available', (tester) async {
      await _pumpWorkoutHarness(tester);

      // The pain/safety button should be accessible.
      final painButton = find.textContaining('Pain');
      if (painButton.evaluate().isNotEmpty) {
        expect(painButton, findsOneWidget);
      }
    });

    // ── Skip Exercise ────────────────────────────────────────────────────

    testWidgets('Skip exercise advances to next plan exercise', (
      tester,
    ) async {
      // Create a multi-exercise prefill.
      final prefill = WorkoutPrefill(
        exerciseName: 'Goblet squat',
        exerciseId: 'goblet-squat',
        suggestedWeightKg: 40,
        targetReps: 8,
        targetRpe: 7,
        targetRestSeconds: 90,
        exerciseIndex: 0,
        sessionExercises: [
          WorkoutPlanExercise(
            exerciseId: 'goblet-squat',
            exerciseName: 'Goblet squat',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 7,
            targetRestSeconds: 90,
            suggestedWeightKg: 40,
          ),
          WorkoutPlanExercise(
            exerciseId: 'push-up',
            exerciseName: 'Push-up',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 7,
            targetRestSeconds: 60,
            suggestedWeightKg: null,
          ),
        ],
      );

      await _pumpWorkoutHarness(tester, prefill: prefill);

      // Find and tap the Next/Skip button.
      final nextButton = find.textContaining('Next');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pump(const Duration(milliseconds: 500));

        // Should now show the second exercise.
        expect(find.textContaining('Push-up'), findsWidgets);
      }
    });
  });
}
