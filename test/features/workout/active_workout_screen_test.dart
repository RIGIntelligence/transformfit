import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/workout/active_workout_screen.dart';
import 'package:transformfit/features/workout/workout_prefill.dart';

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

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ActiveWorkoutScreen(initialPrefill: initialPrefill),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void _setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets(
    'active workout renders timers, tools, prescription, and set log',
    (tester) async {
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

      expect(find.text('Live workout'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Rest'), findsOneWidget);
      expect(find.text('Workout command center'), findsOneWidget);
      expect(find.textContaining('Live set target:'), findsOneWidget);
      expect(find.text('Log the first working set'), findsOneWidget);
      expect(find.textContaining('Ready: Goblet squat'), findsOneWidget);
      expect(find.textContaining('0 sets'), findsWidgets);
      expect(find.text('Warm-up'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Plan target'), findsOneWidget);
      expect(find.textContaining('Previous: Jul 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Set intelligence'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Set intelligence'), findsOneWidget);
      expect(find.text('Progression intent'), findsOneWidget);
      expect(find.text('Rest pace'), findsOneWidget);
      expect(find.text('Previous reference'), findsOneWidget);
      expect(find.text('Readiness context'), findsOneWidget);
      expect(find.textContaining('Post-set countdown'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Current prescription'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Current prescription'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Set log'), findsOneWidget);
      expect(find.bySemanticsLabel('Log set'), findsOneWidget);
      expect(find.byTooltip('Finish workout'), findsOneWidget);
    },
  );

  testWidgets('active workout quick actions load warm-up and plan target', (
    tester,
  ) async {
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

    expect(find.text('100 kg'), findsWidgets);

    await tester.tap(find.text('Warm-up'));
    await tester.pumpAndSettle();

    expect(find.text('60 kg'), findsWidgets);
    expect(find.text('10 reps'), findsWidgets);
    expect(find.text('4/10'), findsWidgets);
    expect(
      find.text('Warm-up set loaded. Keep it crisp and easy.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Plan target'));
    await tester.pumpAndSettle();

    expect(find.text('100 kg'), findsWidgets);
    expect(find.text('8 reps'), findsWidgets);
    expect(find.text('8/10'), findsWidgets);
    expect(
      find.text('Plan target restored for Barbell Squat.'),
      findsOneWidget,
    );
  });

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
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Pain safety active. Load progression blocked; use a pain-free option or finish.',
      ),
      findsOneWidget,
    );
    expect(find.text('80 kg'), findsWidgets);
    expect(find.text('6/10'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byTooltip('Increase weight'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase weight'));
    await tester.pumpAndSettle();

    expect(find.text('85 kg'), findsNothing);
    expect(find.text('80 kg'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Set intelligence'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Pain safety'), findsWidgets);
    expect(find.textContaining('block load progression'), findsOneWidget);
  });

  testWidgets('active workout turns low readiness into capped active targets', (
    tester,
  ) async {
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
    final container = await _pump(tester, controller, initialPrefill: prefill);

    expect(find.text('Readiness cap'), findsOneWidget);
    expect(
      find.text(
        'Readiness cap active (38 deload). Load/RPE and planned sets reduced for today; return to normal after recovery.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Readiness cap active: load/RPE and planned sets are reduced for this session. Return to normal after recovery.',
      ),
      findsOneWidget,
    );
    expect(find.text('80 kg'), findsWidgets);
    expect(find.text('6/10'), findsWidgets);
    expect(find.text('2:30'), findsWidgets);
    expect(find.text('2 planned sets'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byTooltip('Increase weight'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase weight'));
    await tester.pumpAndSettle();

    expect(find.text('85 kg'), findsNothing);
    expect(find.text('80 kg'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Plan target'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan target'));
    await tester.pumpAndSettle();

    expect(find.text('80 kg'), findsWidgets);
    expect(find.text('6/10'), findsWidgets);
    expect(find.text('2 planned sets'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Next: Dumbbell Row'), findsOneWidget);
    expect(find.text('Dumbbell Row'), findsWidgets);
    expect(find.text('1 planned set'), findsOneWidget);
    expect(
      container.read(sessionControllerProvider).state.activeSession!.loggedSets,
      hasLength(2),
    );
  });

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
      final container = await _pump(
        tester,
        controller,
        initialPrefill: prefill,
      );

      await tester.tap(find.text('Technique'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Technique swap loaded: Tempo Goblet Squat. Three-second lowering, one-second pause, quiet knees.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tempo Goblet Squat'), findsWidgets);
      expect(find.text('Technique swap'), findsOneWidget);
      expect(
        find.text('Three-second lowering, one-second pause, quiet knees.'),
        findsOneWidget,
      );
      expect(find.text('60 kg'), findsWidgets);
      expect(find.text('6/10'), findsWidgets);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
      await tester.pumpAndSettle();

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

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pumpAndSettle();

    expect(
      container.read(sessionControllerProvider).state.activeSession!.totalSets,
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

    await tester.tap(find.byTooltip('Undo last set'));
    await tester.pumpAndSettle();

    expect(
      container.read(sessionControllerProvider).state.activeSession!.totalSets,
      0,
    );
  });

  testWidgets('active workout exposes live status after log and undo', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = _liveController();
    await _pump(tester, controller);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('active_workout_live_status')),
      findsOneWidget,
    );
    expect(
      find.text('Set 1 logged for Goblet squat. Rest started: 1:30.'),
      findsOneWidget,
    );
    expect(
      find.semantics.byLabel(
        'Set 1 logged for Goblet squat. Rest started: 1:30.',
      ),
      findsOne,
    );

    await tester.tap(find.byTooltip('Undo last set'));
    await tester.pumpAndSettle();

    expect(
      find.text('Last set undone for Goblet squat. 0 sets remain.'),
      findsOneWidget,
    );
    expect(
      find.semantics.byLabel(
        'Last set undone for Goblet squat. 0 sets remain.',
      ),
      findsOne,
    );
    semantics.dispose();
  });

  testWidgets('active workout auto-starts rest countdown after logging a set', (
    tester,
  ) async {
    final controller = _liveController();
    await _pump(tester, controller);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pump();

    expect(
      find.text('Set 1 logged for Goblet squat. Rest started: 1:30.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Rest timer, 1 minute 30 seconds'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('1:29'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Rest timer, 1 minute 29 seconds'),
      findsOneWidget,
    );
  });

  testWidgets('active workout records actual rest pace between logged sets', (
    tester,
  ) async {
    final controller = _liveController();
    final container = await _pump(tester, controller);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 45));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pump();

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

    await tester.scrollUntilVisible(
      find.textContaining('Rest before:'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Rest before: 0:45 early vs 1:30'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'Rest before 45 seconds early versus 1 minute 30 seconds'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('active workout top bar fits a compact iPhone viewport', (
    tester,
  ) async {
    _setTestViewport(tester, const Size(320, 568));

    await _pump(tester, _liveController());

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('TransformFitAI logo'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Workout timer, .+')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Rest timer, 1 minute 30 seconds'),
      findsOneWidget,
    );
  });

  testWidgets('active workout quick actions wrap inside mobile viewport', (
    tester,
  ) async {
    _setTestViewport(tester, const Size(390, 844));

    await _pump(tester, _liveController());

    for (final label in ['Warm-up', 'Previous', 'Plan target', 'Skip']) {
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(20));
      expect(rect.right, lessThanOrEqualTo(370));
    }
  });

  testWidgets('active workout hydrates generated first-session prescription', (
    tester,
  ) async {
    const prefill = WorkoutPrefill(
      exerciseId: 'dumbbell_bench_press',
      exerciseName: 'Dumbbell Bench Press',
      targetReps: 8,
      targetRpe: 8,
      targetRestSeconds: 120,
      source: 'onboarding_session_1',
    );
    final controller = _liveController();
    final container = await _pump(tester, controller, initialPrefill: prefill);

    expect(find.text('Dumbbell Bench Press'), findsWidgets);
    expect(find.text('0 kg'), findsOneWidget);
    expect(find.text('8 reps'), findsOneWidget);
    expect(find.text('8/10'), findsWidgets);
    expect(find.text('2:00'), findsWidgets);
    expect(
      find.text('0 kg x 8 reps. Keep two reps in reserve.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pumpAndSettle();

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
  });

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
      final container = await _pump(
        tester,
        controller,
        initialPrefill: prefill,
      );
      final exerciseField = find.byKey(
        const ValueKey('active_workout_exercise_field'),
      );

      expect(find.text('Plan exercise 1 of 2'), findsOneWidget);
      expect(find.text('2 planned sets'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Bench Press',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
      await tester.pumpAndSettle();

      expect(find.text('Plan exercise 1 of 2'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Bench Press',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
      await tester.pumpAndSettle();

      expect(find.text('Plan exercise 2 of 2'), findsOneWidget);
      expect(find.text('3 planned sets'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Row',
      );
      expect(find.text('10 reps'), findsOneWidget);
      expect(find.text('7/10'), findsWidgets);
      expect(find.text('1:30'), findsWidgets);
      expect(
        container
            .read(sessionControllerProvider)
            .state
            .activeSession!
            .loggedSets,
        hasLength(2),
      );

      await tester.tap(find.byTooltip('Undo last set'));
      await tester.pumpAndSettle();

      expect(
        container
            .read(sessionControllerProvider)
            .state
            .activeSession!
            .loggedSets,
        hasLength(1),
      );
      expect(find.text('Plan exercise 1 of 2'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Bench Press',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
      await tester.pumpAndSettle();

      expect(find.text('Plan exercise 2 of 2'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Row',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
      await tester.pumpAndSettle();

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

      expect(find.text('Plan exercise 2 of 2'), findsOneWidget);
      expect(find.text('3 planned sets'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Dumbbell Row',
      );
      expect(find.text('10 reps'), findsOneWidget);
      expect(find.text('7/10'), findsWidgets);
      expect(find.text('1:30'), findsWidgets);
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
      final container = await _pump(
        tester,
        controller,
        initialPrefill: prefill,
      );
      final exerciseField = find.byKey(
        const ValueKey('active_workout_exercise_field'),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
      await tester.pumpAndSettle();

      expect(find.text('Plan exercise 2 of 3'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Split Squat',
      );
      expect(find.text('10 reps'), findsOneWidget);
      expect(find.text('8/10'), findsWidgets);
      expect(find.text('2:00'), findsWidgets);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
      await tester.pumpAndSettle();

      final loggedSetsAfterFirstRight = container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets;
      expect(loggedSetsAfterFirstRight, hasLength(2));
      expect(loggedSetsAfterFirstRight.first.exerciseId, 'split_squat_left');
      expect(loggedSetsAfterFirstRight.last.exerciseId, 'split_squat_right');
      expect(find.text('Plan exercise 2 of 3'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Split Squat',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
      await tester.pumpAndSettle();

      final loggedSets = container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets;
      expect(loggedSets, hasLength(3));
      expect(loggedSets.last.exerciseId, 'split_squat_right');
      expect(find.text('Plan exercise 3 of 3'), findsOneWidget);
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

    expect(find.text('Plan exercise 2 of 2'), findsOneWidget);
    expect(find.text('10 reps'), findsOneWidget);
    expect(find.text('8/10'), findsWidgets);
    expect(find.text('2:00'), findsWidgets);
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

      expect(find.text('Plan exercise 2 of 3'), findsOneWidget);
      expect(
        tester.widget<TextField>(exerciseField).controller!.text,
        'Split Squat',
      );
      expect(find.text('10 reps'), findsOneWidget);
      expect(find.text('8/10'), findsWidgets);
      expect(find.text('2:00'), findsWidgets);
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
    final container = await _pump(tester, controller, initialPrefill: prefill);
    final exerciseField = find.byKey(
      const ValueKey('active_workout_exercise_field'),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
    await tester.pumpAndSettle();

    expect(find.text('Plan exercise 3 of 3'), findsOneWidget);
    expect(
      tester.widget<TextField>(exerciseField).controller!.text,
      'Dumbbell Row',
    );

    await tester.tap(find.byTooltip('Undo last set'));
    await tester.pumpAndSettle();

    final loggedSets = container
        .read(sessionControllerProvider)
        .state
        .activeSession!
        .loggedSets;
    expect(loggedSets, hasLength(1));
    expect(loggedSets.single.exerciseId, 'split_squat_left');
    expect(find.text('Plan exercise 2 of 3'), findsOneWidget);
    expect(
      tester.widget<TextField>(exerciseField).controller!.text,
      'Split Squat',
    );
    expect(find.text('10 reps'), findsOneWidget);
    expect(find.text('8/10'), findsWidgets);
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

    expect(
      find.textContaining('Previous: Jul 1 · Split Squat, 40 kg x 10 reps'),
      findsOneWidget,
    );
  });

  testWidgets('active workout steppers expose spoken semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _liveController());

    await tester.scrollUntilVisible(
      find.byTooltip('Increase weight'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final weightStepper = find.semantics.byLabel('Working weight');
    expect(weightStepper, findsOne);
    expect(
      weightStepper.evaluate().single,
      isSemantics(
        label: 'Working weight',
        value: '40 kilograms',
        increasedValue: '45 kilograms',
        decreasedValue: '35 kilograms',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    tester.semantics.increase(weightStepper);
    await tester.pump();

    expect(find.text('45 kg'), findsWidgets);
    expect(
      weightStepper.evaluate().single,
      isSemantics(
        label: 'Working weight',
        value: '45 kilograms',
        increasedValue: '50 kilograms',
        decreasedValue: '40 kilograms',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    final rpeStepper = find.semantics.byLabel('Working RPE');
    expect(rpeStepper, findsOne);
    expect(
      rpeStepper.evaluate().single,
      isSemantics(
        label: 'Working RPE',
        value: '7 out of 10',
        increasedValue: '8 out of 10',
        decreasedValue: '6 out of 10',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('active workout rest timer exposes spoken boundaries', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _liveController());

    await tester.scrollUntilVisible(
      find.byTooltip('Increase rest timer'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final restTimer = find.semantics.byLabel('Rest timer');
    expect(restTimer, findsOne);
    expect(
      restTimer.evaluate().single,
      isSemantics(
        label: 'Rest timer',
        value: '1 minute 30 seconds',
        increasedValue: '1 minute 45 seconds',
        decreasedValue: '1 minute 15 seconds',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    for (var i = 0; i < 6; i += 1) {
      tester.semantics.decrease(restTimer);
      await tester.pump();
    }

    expect(find.text('0:00'), findsOneWidget);
    expect(
      restTimer.evaluate().single,
      isSemantics(
        label: 'Rest timer',
        value: '0 seconds',
        increasedValue: '15 seconds',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets(
    'active workout debrief persists only entered fields and ratings',
    (tester) async {
      final controller = _liveController();
      final container = await _pump(tester, controller);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log set'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Finish workout'));
      await tester.pumpAndSettle();

      expect(find.text('Debrief'), findsOneWidget);
      await tester.tap(find.byTooltip('Increase satisfaction'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('active_workout_pain_field')),
        'Left knee stayed quiet.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('active_workout_next_focus_field')),
        'Keep the squat crisp.',
      );
      await tester.tap(find.text('Save debrief'));
      await tester.pumpAndSettle();

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
