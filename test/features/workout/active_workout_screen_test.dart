import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/workout/active_workout_screen.dart';
import 'package:transformfit/features/workout/workout_prefill.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

SessionController _liveController({List<WorkoutSession> history = const []}) {
  final readiness = ReadinessEntry(
    id: 'readiness-live',
    date: DateTime(2026, 7, 2),
    score: 78,
    zone: 'push',
    energyLevel: 8,
    sleepQuality: 8,
    sorenessMap: const ['hips'],
  );
  final controller = SessionController(
    initialState: SessionState(readinessEntry: readiness, history: history),
  );
  controller.startSession();
  return controller;
}

SessionController _lowReadinessController({
  List<WorkoutSession> history = const [],
}) {
  final readiness = ReadinessEntry(
    id: 'readiness-low',
    date: DateTime(2026, 7, 2),
    score: 38,
    zone: 'deload',
    energyLevel: 3,
    sleepQuality: 4,
    sorenessMap: const ['quads', 'low back'],
  );
  final controller = SessionController(
    initialState: SessionState(readinessEntry: readiness, history: history),
  );
  controller.startSession();
  return controller;
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  SessionController controller, {
  WorkoutPrefill? initialPrefill,
}) async {
  final container = ProviderContainer(
    overrides: [sessionControllerProvider.overrideWithValue(controller)],
  );
  addTearDown(container.dispose);
  // Drain any pending timers (rest countdown, set-log flash Future.delayed).
  addTearDown(() => tester.pump(const Duration(seconds: 200)));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDigitalAtelierTheme(),
        home: ActiveWorkoutScreen(initialPrefill: initialPrefill),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

/// Log a set and pump enough time for the 800ms set-flash timer to expire.
Future<void> _logAndPump(WidgetTester tester) async {
  await tester.tap(find.textContaining('Log Set'));
  await tester.pump(const Duration(seconds: 1));
}

void _setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Find the log set button by text containing 'Log Set'.
Finder _findLogButton() => find.textContaining('Log Set');

/// Find undo by semantics label.
Finder _findUndoButton() => find.bySemanticsLabel('Undo last set');

/// Find finish by semantics label.
Finder _findFinishButton() => find.bySemanticsLabel('Finish workout');

void main() {
  testWidgets(
    'active workout renders exercise header, controls, set table, and bottom bar',
    skip: true, (tester) async {
      final history = [
        WorkoutSession(
          id: 'session-1',
          startedAt: DateTime(2026, 7, 1, 8),
          endedAt: DateTime(2026, 7, 1, 8, 40),
          readinessEntryId: 'readiness-old',
          loggedSets: const [
            LoggedSet(
              id: 'set-1',
              exerciseName: 'Goblet squat',
              setNumber: 1,
              weightKg: 40,
              reps: 8,
              rpe: 7,
            ),
          ],
        ),
      ];
      await _pump(tester, _liveController(history: history));

      // Exercise header
      expect(find.text('Goblet squat'), findsWidgets);
      expect(find.textContaining('Set '), findsWidgets);

      // Quick presets
      expect(find.text('Warm-up'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);

      // Set table headers + control steppers both show WEIGHT/REPS/RPE
      expect(find.text('SET'), findsOneWidget);
      expect(find.text('PREVIOUS'), findsOneWidget);
      expect(find.text('WEIGHT'), findsNWidgets(2));
      expect(find.text('REPS'), findsNWidgets(2));
      expect(find.text('RPE'), findsNWidgets(2));

      // Bottom bar summary
      expect(find.text('SETS'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('TIME'), findsOneWidget);

      // Log button
      expect(_findLogButton(), findsOneWidget);
    },
  );

  testWidgets(
    'active workout quick actions load warm-up and plan target',
    (tester) async {
      const prefill = WorkoutPrefill(
        exerciseId: 'barbell_squat',
        exerciseName: 'Barbell Squat',
        targetSets: 3,
        targetReps: 8,
        targetRpe: 8,
        targetRestSeconds: 120,
        suggestedWeightKg: 100,
        source: 'onboarding_session_1',
      );
      final controller = _liveController();
      await _pump(tester, controller, initialPrefill: prefill);

      expect(find.text('100'), findsWidgets);

      await tester.tap(find.text('Warm-up'));
      await tester.pump();

      expect(find.text('60'), findsWidgets);
      expect(find.text('10'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      expect(
        find.text('Warm-up set loaded. Keep it crisp and easy.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Plan'));
      await tester.pump();

      expect(find.text('100'), findsWidgets);
      expect(find.text('8'), findsWidgets);
      expect(
        find.text('Plan target restored for Barbell Squat.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('active workout pain safety blocks load progression', (
    tester,
  ) async {
    final history = [
      WorkoutSession(
        id: 'history-pain-safety',
        startedAt: DateTime(2026, 7, 1, 8),
        readinessEntryId: 'readiness-history',
        loggedSets: const [
          LoggedSet(
            id: 'set-history',
            exerciseId: 'barbell_squat',
            exerciseName: 'Barbell Squat',
            setNumber: 1,
            weightKg: 80,
            reps: 8,
            rpe: 7,
          ),
        ],
      ),
    ];
    const prefill = WorkoutPrefill(
      exerciseId: 'barbell_squat',
      exerciseName: 'Barbell Squat',
      targetSets: 3,
      targetReps: 8,
      targetRpe: 8,
      targetRestSeconds: 120,
      suggestedWeightKg: 100,
      source: 'onboarding_session_1',
    );
    await _pump(
      tester,
      _liveController(history: history),
      initialPrefill: prefill,
    );

    await tester.tap(find.text('Pain safety'));
    await tester.pump();

    expect(
      find.textContaining('Pain safety active'),
      findsWidgets,
    );
    expect(find.text('80'), findsWidgets);
    expect(find.text('6'), findsWidgets);

    // Try to increase weight — should be capped
    final increaseWeight = find.bySemanticsLabel('Increase WEIGHT');
    await tester.scrollUntilVisible(
      increaseWeight,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(increaseWeight);
    await tester.pump();

    // Weight should still be 80 (capped by pain safety)
    expect(find.text('80'), findsWidgets);
  });

  testWidgets(
    'active workout turns low readiness into capped active targets',
    (tester) async {
      const prefill = WorkoutPrefill(
        exerciseId: 'barbell_squat',
        exerciseName: 'Barbell Squat',
        targetSets: 3,
        targetReps: 8,
        targetRpe: 8,
        targetRestSeconds: 120,
        suggestedWeightKg: 100,
        source: 'onboarding_session_1',
        sessionExercises: [
          WorkoutPlanExercise(
            exerciseId: 'barbell_squat',
            exerciseName: 'Barbell Squat',
            targetSets: 3,
            targetReps: 8,
            targetRpe: 8,
            targetRestSeconds: 120,
            suggestedWeightKg: 100,
          ),
          WorkoutPlanExercise(
            exerciseId: 'dumbbell_row',
            exerciseName: 'Dumbbell Row',
            targetSets: 2,
            targetReps: 10,
            targetRpe: 7,
            targetRestSeconds: 90,
            suggestedWeightKg: 35,
          ),
        ],
      );
      final controller = _lowReadinessController();
      final container =
          await _pump(tester, controller, initialPrefill: prefill);

      // Readiness banner
      expect(find.textContaining('Low readiness'), findsOneWidget);
      expect(find.textContaining('volume capped'), findsOneWidget);

      // Capped values (100 * 0.8 = 80, RPE capped at 6)
      expect(find.text('80'), findsWidgets);
      expect(find.text('6'), findsWidgets);

      // Try to increase weight — should be capped
      final increaseWeight = find.bySemanticsLabel('Increase WEIGHT');
      await tester.scrollUntilVisible(
        increaseWeight,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(increaseWeight);
      await tester.pump();

      expect(find.text('80'), findsWidgets);

      // Plan target should also be capped
      await tester.scrollUntilVisible(
        find.text('Plan'),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Plan'));
      await tester.pump();

      expect(find.text('80'), findsWidgets);
      expect(find.text('6'), findsWidgets);

      // Log two sets to complete exercise 1
      await _logAndPump(tester);
      await _logAndPump(tester);

      // Exercise header scrolled off — verify via textContaining and state
      expect(find.textContaining('Dumbbell Row'), findsWidgets);
      expect(
        container
            .read(sessionControllerProvider)
            .state
            .activeSession!
            .loggedSets,
        hasLength(2),
      );
    },
  );

  testWidgets(
    'active workout technique swap loads a safer variation and counts the plan set',
    (tester) async {
      const prefill = WorkoutPrefill(
        exerciseId: 'barbell_squat',
        exerciseName: 'Barbell Squat',
        targetSets: 1,
        targetReps: 8,
        targetRpe: 8,
        targetRestSeconds: 120,
        suggestedWeightKg: 100,
        source: 'onboarding_session_1',
        sessionExercises: [
          WorkoutPlanExercise(
            exerciseId: 'barbell_squat',
            exerciseName: 'Barbell Squat',
            targetSets: 1,
            targetReps: 8,
            targetRpe: 8,
            targetRestSeconds: 120,
            suggestedWeightKg: 100,
          ),
          WorkoutPlanExercise(
            exerciseId: 'dumbbell_press',
            exerciseName: 'Dumbbell Press',
            targetSets: 2,
            targetReps: 10,
            targetRpe: 7,
            targetRestSeconds: 90,
            suggestedWeightKg: 30,
          ),
        ],
      );
      final controller = _liveController();
      final container =
          await _pump(tester, controller, initialPrefill: prefill);

      await tester.tap(find.text('Technique'));
      await tester.pump();

      expect(
        find.textContaining('Technique swap loaded: Tempo Goblet Squat'),
        findsOneWidget,
      );
      expect(find.text('Tempo Goblet Squat'), findsWidgets);
      // Technique cue appears in both the header card and the live status
      expect(
        find.textContaining(
          'Three-second lowering, one-second pause, quiet knees',
        ),
        findsWidgets,
      );
      expect(find.text('60'), findsWidgets);
      expect(find.text('6'), findsWidgets);

      await _logAndPump(tester);

      final loggedSet = container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets
          .single;
      expect(loggedSet.exerciseName, 'Tempo Goblet Squat');
      expect(loggedSet.exerciseId, 'barbell_squat.technique_swap');
      expect(loggedSet.weightKg, 60);
      expect(loggedSet.rpe, 6);
      expect(find.textContaining('Next: Dumbbell Press'), findsOneWidget);
      expect(find.text('Dumbbell Press'), findsWidgets);
    },
  );

  testWidgets('active workout logs and undoes a set', (tester) async {
    final controller = _liveController();
    final container = await _pump(tester, controller);

    await _logAndPump(tester);

    expect(
      container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .totalSets,
      1,
    );
    expect(
      container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets
          .single
          .exerciseName,
      'Goblet squat',
    );

    await tester.tap(_findUndoButton());
    await tester.pump();

    expect(
      container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .totalSets,
      0,
    );
  });

  testWidgets('active workout exposes live status after log and undo', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = _liveController();
    await _pump(tester, controller);

    await _logAndPump(tester);

    expect(
      find.byKey(const ValueKey('active_workout_live_status')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Set 1 logged for Goblet squat'),
      findsOneWidget,
    );

    await tester.tap(_findUndoButton());
    await tester.pump();

    expect(
      find.textContaining('Last set undone for Goblet squat'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'active workout auto-starts rest countdown after logging a set',
    (tester) async {
      final controller = _liveController();
      await _pump(tester, controller);

      await tester.tap(_findLogButton());
      await tester.pump();

      expect(
        find.textContaining('Set 1 logged for Goblet squat'),
        findsOneWidget,
      );
      // Rest countdown badge should appear
      expect(find.textContaining('1:30'), findsWidgets);

      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('1:29'), findsWidgets);
    },
  );

  testWidgets(
    'active workout records actual rest pace between logged sets',
    (tester) async {
      final controller = _liveController();
      final container = await _pump(tester, controller);

      await tester.tap(_findLogButton());
      await tester.pump();
      await tester.pump(const Duration(seconds: 45));
      await tester.tap(_findLogButton());
      await tester.pump(const Duration(seconds: 1));

      final loggedSets = container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets;
      expect(loggedSets, hasLength(2));
      expect(loggedSets.first.loggedAt, isNotNull);
      expect(loggedSets.first.prescribedRestSeconds, 90);
      expect(loggedSets.first.actualRestSeconds, isNull);
      expect(loggedSets.last.loggedAt, isNotNull);
      expect(loggedSets.last.prescribedRestSeconds, 90);
      expect(loggedSets.last.actualRestSeconds, 45);
    },
  );

  testWidgets(
    'active workout top bar fits a compact iPhone viewport',
    (tester) async {
      _setTestViewport(tester, const Size(320, 568));

      await _pump(tester, _liveController());

      expect(tester.takeException(), isNull);
      expect(find.byType(TransformFitBrandMark), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'Workout timer, .+')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'active workout quick actions wrap inside mobile viewport',
    (tester) async {
      _setTestViewport(tester, const Size(390, 844));

      await _pump(tester, _liveController());

      for (final label in ['Warm-up', 'Previous', 'Plan', 'Skip']) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets(
    'active workout hydrates generated first-session prescription',
    (tester) async {
      const prefill = WorkoutPrefill(
        exerciseId: 'dumbbell_bench_press',
        exerciseName: 'Dumbbell Bench Press',
        targetReps: 8,
        targetRpe: 8,
        targetRestSeconds: 120,
        suggestedWeightKg: 0,
        source: 'onboarding_session_1',
      );
      final controller = _liveController();
      final container =
          await _pump(tester, controller, initialPrefill: prefill);

      expect(find.text('Dumbbell Bench Press'), findsWidgets);
      expect(find.text('0'), findsWidgets);
      expect(find.text('8'), findsWidgets);

      await _logAndPump(tester);

      final loggedSet = container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets
          .single;
      expect(loggedSet.exerciseName, 'Dumbbell Bench Press');
      expect(loggedSet.exerciseId, 'dumbbell_bench_press');
      expect(loggedSet.weightKg, isNull);
      expect(loggedSet.reps, 8);
      expect(loggedSet.rpe, 8);
    },
  );

  testWidgets(
    'active workout advances generated session queue after planned sets',
    (tester) async {
      const prefill = WorkoutPrefill(
        exerciseId: 'dumbbell_bench_press',
        exerciseName: 'Dumbbell Bench Press',
        targetSets: 2,
        targetReps: 8,
        targetRpe: 8,
        targetRestSeconds: 120,
        source: 'onboarding_session_1',
        sessionExercises: [
          WorkoutPlanExercise(
            exerciseId: 'dumbbell_bench_press',
            exerciseName: 'Dumbbell Bench Press',
            targetSets: 2,
            targetReps: 8,
            targetRpe: 8,
            targetRestSeconds: 120,
          ),
          WorkoutPlanExercise(
            exerciseId: 'dumbbell_row',
            exerciseName: 'Dumbbell Row',
            targetSets: 3,
            targetReps: 10,
            targetRpe: 7,
            targetRestSeconds: 90,
          ),
        ],
      );
      final controller = _liveController();
      final container =
          await _pump(tester, controller, initialPrefill: prefill);
      final exerciseField = find.byKey(
        const ValueKey('active_workout_exercise_field'),
      );

      expect(find.textContaining('Exercise 1 of 2'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Bench Press',
      );

      await _logAndPump(tester);

      expect(find.textContaining('Exercise 1 of 2'), findsOneWidget);

      await _logAndPump(tester);

      expect(find.textContaining('Exercise 2 of 2'), findsOneWidget);
      expect(find.text('Dumbbell Row'), findsWidgets);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Row',
      );
      expect(find.text('10'), findsWidgets);
      expect(find.text('7'), findsWidgets);
      expect(
        container
            .read(sessionControllerProvider)
            .state
            .activeSession!
            .loggedSets,
        hasLength(2),
      );

      await tester.tap(_findUndoButton());
      await tester.pump();

      expect(
        container
            .read(sessionControllerProvider)
            .state
            .activeSession!
            .loggedSets,
        hasLength(1),
      );
      expect(find.textContaining('Exercise 1 of 2'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Bench Press',
      );

      await _logAndPump(tester);

      expect(find.textContaining('Exercise 2 of 2'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Row',
      );

      await _logAndPump(tester);

      final loggedSets = container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets;
      expect(loggedSets, hasLength(3));
      expect(loggedSets.last.exerciseName, 'Dumbbell Row');
      expect(loggedSets.last.reps, 10);
      expect(loggedSets.last.rpe, 7);
    },
  );

  testWidgets(
    'active workout restores queued exercise from active session state',
    (tester) async {
      final readiness = ReadinessEntry(
        id: 'readiness-live',
        date: DateTime(2026, 7, 2),
        score: 78,
        zone: 'push',
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: const ['hips'],
      );
      final controller = SessionController(
        initialState: SessionState(
          readinessEntry: readiness,
          activeSession: WorkoutSession(
            id: 'session-live',
            startedAt: DateTime(2026, 7, 2, 9),
            readinessEntryId: 'readiness-live',
            loggedSets: const [
              LoggedSet(
                id: 'set-1',
                exerciseName: 'Dumbbell Bench Press',
                setNumber: 1,
                reps: 8,
                rpe: 8,
              ),
              LoggedSet(
                id: 'set-2',
                exerciseName: 'Dumbbell Bench Press',
                setNumber: 2,
                reps: 8,
                rpe: 8,
              ),
            ],
          ),
          activeSessionPlan: const [
            SessionPlanExercise(
              exerciseId: 'dumbbell_bench_press',
              exerciseName: 'Dumbbell Bench Press',
              targetSets: 2,
              targetReps: 8,
              targetRpe: 8,
              targetRestSeconds: 120,
            ),
            SessionPlanExercise(
              exerciseId: 'dumbbell_row',
              exerciseName: 'Dumbbell Row',
              targetSets: 3,
              targetReps: 10,
              targetRpe: 7,
              targetRestSeconds: 90,
            ),
          ],
        ),
      );

      await _pump(tester, controller);
      final exerciseField = find.byKey(
        const ValueKey('active_workout_exercise_field'),
      );

      expect(find.textContaining('Exercise 2 of 2'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Row',
      );
      expect(find.text('10'), findsWidgets);
      expect(find.text('7'), findsWidgets);
    },
  );

  testWidgets(
    'active workout advances duplicate-name exercises by stable plan id',
    (tester) async {
      const prefill = WorkoutPrefill(
        exerciseId: 'split_squat_left',
        exerciseName: 'Split Squat',
        targetSets: 1,
        targetReps: 8,
        targetRpe: 7,
        targetRestSeconds: 90,
        source: 'onboarding_session_1',
        sessionExercises: [
          WorkoutPlanExercise(
            exerciseId: 'split_squat_left',
            exerciseName: 'Split Squat',
            targetSets: 1,
            targetReps: 8,
            targetRpe: 7,
            targetRestSeconds: 90,
          ),
          WorkoutPlanExercise(
            exerciseId: 'split_squat_right',
            exerciseName: 'Split Squat',
            targetSets: 2,
            targetReps: 10,
            targetRpe: 8,
            targetRestSeconds: 120,
          ),
          WorkoutPlanExercise(
            exerciseId: 'dumbbell_row',
            exerciseName: 'Dumbbell Row',
            targetSets: 1,
            targetReps: 12,
            targetRpe: 7,
            targetRestSeconds: 90,
          ),
        ],
      );
      final controller = _liveController();
      final container =
          await _pump(tester, controller, initialPrefill: prefill);
      final exerciseField = find.byKey(
        const ValueKey('active_workout_exercise_field'),
      );

      await _logAndPump(tester);

      expect(find.textContaining('Exercise 2 of 3'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Split Squat',
      );
      expect(find.text('10'), findsWidgets);
      expect(find.text('8'), findsWidgets);

      await _logAndPump(tester);

      final loggedSetsAfterFirstRight = container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets;
      expect(loggedSetsAfterFirstRight, hasLength(2));
      expect(loggedSetsAfterFirstRight.first.exerciseId, 'split_squat_left');
      expect(loggedSetsAfterFirstRight.last.exerciseId, 'split_squat_right');
      expect(find.textContaining('Exercise 2 of 3'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Split Squat',
      );

      await _logAndPump(tester);

      final loggedSets = container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets;
      expect(loggedSets, hasLength(3));
      expect(loggedSets.last.exerciseId, 'split_squat_right');
      expect(find.textContaining('Exercise 3 of 3'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Row',
      );
    },
  );

  testWidgets('active workout honors requested exercise index before logs', (
    tester,
  ) async {
    const prefill = WorkoutPrefill(
      exerciseId: 'split_squat_right',
      exerciseName: 'Split Squat',
      targetSets: 1,
      targetReps: 10,
      targetRpe: 8,
      targetRestSeconds: 120,
      source: 'onboarding_session_1',
      exerciseIndex: 1,
      sessionExercises: [
        WorkoutPlanExercise(
          exerciseId: 'split_squat_left',
          exerciseName: 'Split Squat',
          targetSets: 1,
          targetReps: 8,
          targetRpe: 7,
          targetRestSeconds: 90,
        ),
        WorkoutPlanExercise(
          exerciseId: 'split_squat_right',
          exerciseName: 'Split Squat',
          targetSets: 1,
          targetReps: 10,
          targetRpe: 8,
          targetRestSeconds: 120,
        ),
      ],
    );
    await _pump(tester, _liveController(), initialPrefill: prefill);

    expect(find.textContaining('Exercise 2 of 2'), findsOneWidget);
    expect(find.text('10'), findsWidgets);
    expect(find.text('8'), findsWidgets);
  });

  testWidgets(
    'active workout restores duplicate-name legacy set to the next matching slot',
    (tester) async {
      final readiness = ReadinessEntry(
        id: 'readiness-live',
        date: DateTime(2026, 7, 2),
        score: 78,
        zone: 'push',
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: const ['hips'],
      );
      final controller = SessionController(
        initialState: SessionState(
          readinessEntry: readiness,
          activeSession: WorkoutSession(
            id: 'session-live',
            startedAt: DateTime(2026, 7, 2, 9),
            readinessEntryId: 'readiness-live',
            loggedSets: const [
              LoggedSet(
                id: 'set-legacy',
                exerciseName: 'Split Squat',
                setNumber: 1,
                reps: 8,
                rpe: 7,
              ),
            ],
          ),
          activeSessionPlan: const [
            SessionPlanExercise(
              exerciseId: 'split_squat_left',
              exerciseName: 'Split Squat',
              targetSets: 1,
              targetReps: 8,
              targetRpe: 7,
              targetRestSeconds: 90,
            ),
            SessionPlanExercise(
              exerciseId: 'split_squat_right',
              exerciseName: 'Split Squat',
              targetSets: 1,
              targetReps: 10,
              targetRpe: 8,
              targetRestSeconds: 120,
            ),
            SessionPlanExercise(
              exerciseId: 'dumbbell_row',
              exerciseName: 'Dumbbell Row',
              targetSets: 1,
              targetReps: 12,
              targetRpe: 7,
              targetRestSeconds: 90,
            ),
          ],
        ),
      );
      final exerciseField = find.byKey(
        const ValueKey('active_workout_exercise_field'),
      );

      await _pump(tester, controller);

      expect(find.textContaining('Exercise 2 of 3'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Split Squat',
      );
      expect(find.text('10'), findsWidgets);
      expect(find.text('8'), findsWidgets);
    },
  );

  testWidgets('active workout undo rewinds duplicate-name queue by id', (
    tester,
  ) async {
    const prefill = WorkoutPrefill(
      exerciseId: 'split_squat_left',
      exerciseName: 'Split Squat',
      targetSets: 1,
      targetReps: 8,
      targetRpe: 7,
      targetRestSeconds: 90,
      source: 'onboarding_session_1',
      sessionExercises: [
        WorkoutPlanExercise(
          exerciseId: 'split_squat_left',
          exerciseName: 'Split Squat',
          targetSets: 1,
          targetReps: 8,
          targetRpe: 7,
          targetRestSeconds: 90,
        ),
        WorkoutPlanExercise(
          exerciseId: 'split_squat_right',
          exerciseName: 'Split Squat',
          targetSets: 1,
          targetReps: 10,
          targetRpe: 8,
          targetRestSeconds: 120,
        ),
        WorkoutPlanExercise(
          exerciseId: 'dumbbell_row',
          exerciseName: 'Dumbbell Row',
          targetSets: 1,
          targetReps: 12,
          targetRpe: 7,
          targetRestSeconds: 90,
        ),
      ],
    );
    final controller = _liveController();
    final container =
        await _pump(tester, controller, initialPrefill: prefill);
    final exerciseField = find.byKey(
      const ValueKey('active_workout_exercise_field'),
    );

    await _logAndPump(tester);
    await _logAndPump(tester);

    expect(find.textContaining('Exercise 3 of 3'), findsOneWidget);
    expect(
      tester.widget<TextField>(exerciseField).controller!.text,
      'Dumbbell Row',
    );

    await tester.tap(_findUndoButton());
    await tester.pump();

    final loggedSets = container
        .read(sessionControllerProvider)
        .state
        .activeSession!
        .loggedSets;
    expect(loggedSets, hasLength(1));
    expect(loggedSets.single.exerciseId, 'split_squat_left');
    expect(find.textContaining('Exercise 2 of 3'), findsOneWidget);
    expect(
      tester.widget<TextField>(exerciseField).controller!.text,
      'Split Squat',
    );
    expect(find.text('10'), findsWidgets);
    expect(find.text('8'), findsWidgets);
  });

  testWidgets('active workout previous performance prefers stable ids', (
    tester,
  ) async {
    final history = [
      WorkoutSession(
        id: 'session-history',
        startedAt: DateTime(2026, 7, 1, 8),
        endedAt: DateTime(2026, 7, 1, 8, 40),
        readinessEntryId: 'readiness-old',
        loggedSets: const [
          LoggedSet(
            id: 'set-right',
            exerciseId: 'split_squat_right',
            exerciseName: 'Split Squat',
            setNumber: 1,
            weightKg: 40,
            reps: 10,
            rpe: 8,
          ),
          LoggedSet(
            id: 'set-left',
            exerciseId: 'split_squat_left',
            exerciseName: 'Split Squat',
            setNumber: 2,
            weightKg: 30,
            reps: 8,
            rpe: 7,
          ),
        ],
      ),
    ];
    const prefill = WorkoutPrefill(
      exerciseId: 'split_squat_right',
      exerciseName: 'Split Squat',
      targetSets: 1,
      targetReps: 10,
      targetRpe: 8,
      targetRestSeconds: 120,
      source: 'onboarding_session_1',
      exerciseIndex: 1,
      sessionExercises: [
        WorkoutPlanExercise(
          exerciseId: 'split_squat_left',
          exerciseName: 'Split Squat',
          targetSets: 1,
          targetReps: 8,
          targetRpe: 7,
          targetRestSeconds: 90,
        ),
        WorkoutPlanExercise(
          exerciseId: 'split_squat_right',
          exerciseName: 'Split Squat',
          targetSets: 1,
          targetReps: 10,
          targetRpe: 8,
          targetRestSeconds: 120,
        ),
      ],
    );

    await _pump(
      tester,
      _liveController(history: history),
      initialPrefill: prefill,
    );

    // Previous reference should show in the set table's PREVIOUS column
    expect(find.text('40 × 10'), findsOneWidget);
  });

  testWidgets(
    'active workout steppers expose spoken semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _liveController());

      final weightControl = find.bySemanticsLabel(
        RegExp(r'WEIGHT control'),
      );
      expect(weightControl, findsOne);

      final rpeControl = find.bySemanticsLabel(RegExp(r'RPE control'));
      expect(rpeControl, findsOne);

      semantics.dispose();
    },
  );

  testWidgets(
    'active workout debrief persists only entered fields and ratings', skip: true,
    (tester) async {
      final controller = _liveController();
      final container = await _pump(tester, controller);

      await _logAndPump(tester);
      await tester.tap(_findFinishButton());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Debrief'), findsOneWidget);
      // The bottom sheet content is in a scrollable overlay.
      // Scroll the debrief sheet to make each element visible.
      final sheetScrollable = find.byType(SingleChildScrollView).last;
      final satisfactionUp = find.bySemanticsLabel('Increase Satisfaction');
      await tester.scrollUntilVisible(
        satisfactionUp,
        200,
        scrollable: sheetScrollable,
      );
      await tester.tap(satisfactionUp);
      await tester.pump();
      final painField = find.byKey(const ValueKey('active_workout_pain_field'));
      await tester.scrollUntilVisible(painField, 200, scrollable: sheetScrollable);
      await tester.enterText(painField, 'Left knee stayed quiet.');
      final focusField =
          find.byKey(const ValueKey('active_workout_next_focus_field'));
      await tester.scrollUntilVisible(focusField, 200, scrollable: sheetScrollable);
      await tester.enterText(focusField, 'Keep the squat crisp.');
      final saveButton = find.text('Save debrief');
      await tester.scrollUntilVisible(saveButton, 200, scrollable: sheetScrollable);
      await tester.tap(saveButton);
      await tester.pump(const Duration(milliseconds: 500));

      final state = container.read(sessionControllerProvider).state;
      expect(state.activeSession, isNull);
      expect(state.history, hasLength(1));
      final debrief = state.lastDebrief;
      expect(debrief?.satisfaction, 5);
      expect(debrief?.painNotes, 'Left knee stayed quiet.');
      expect(debrief?.whatWorked, isNull);
      expect(debrief?.whatToChange, isNull);
      expect(debrief?.nextSessionFocus, 'Keep the squat crisp.');
      expect(find.text('Session saved'), findsOneWidget);
    },
  );
}
