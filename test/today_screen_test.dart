import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/app_providers.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/auth/auth_service.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/session/session_snapshot_store.dart';
import 'package:transformfit/features/wearables/health_wearable_adapter.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';
import 'package:transformfit/navigation/auth_state.dart';
import 'package:transformfit/screens/today_screen.dart';

class _ThrowingSignOutAuthFacade implements AuthFacade {
  var signOutCalls = 0;

  @override
  Stream<AuthStateChanged> authStateChanges() {
    return const Stream<AuthStateChanged>.empty();
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    return const AuthResult.success();
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    throw StateError('offline sign-out');
  }

  @override
  String? currentUserId() => 'u-signout';
}

class _FakeSessionSnapshotStore extends SessionSnapshotStore {
  var hasSnapshot = true;
  var clearCalls = 0;

  @override
  Future<SessionState?> load() async {
    return hasSnapshot ? const SessionState() : null;
  }

  @override
  Future<void> save(SessionState state) async {
    hasSnapshot = true;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
    hasSnapshot = false;
  }
}

class _FakeWearableSyncAdapter implements WearableSyncAdapter {
  _FakeWearableSyncAdapter(this.signal);

  final WearableSignal signal;
  var readCalls = 0;

  @override
  Future<WearableSignal> readDailySignal({DateTime? now}) async {
    readCalls += 1;
    return signal;
  }
}

void _setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _expectMinTouchTarget(
  WidgetTester tester,
  Finder finder,
  String label,
) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(44), reason: '$label width');
  expect(size.height, greaterThanOrEqualTo(44), reason: '$label height');
}

void main() {
  testWidgets('Today screen displays coach voice text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TodayScreen())),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('Coach note:'), findsOneWidget);
    expect(find.bySemanticsLabel('TransformFitAI logo'), findsOneWidget);
    expect(find.text('Motivator'), findsOneWidget);
    expect(find.text('74% confidence'), findsOneWidget);
    expect(find.text('3 sources'), findsWidgets);
    expect(find.text('Activation corridor'), findsOneWidget);
    expect(find.text('Start the first set'), findsWidgets);
    expect(find.text('What to do now'), findsOneWidget);
    expect(find.text('Why it changed'), findsOneWidget);
    expect(find.text('Next after that'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('activation_corridor_primary_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('activation_corridor_coach_action')),
      findsOneWidget,
    );
    expect(find.text('First action'), findsWidgets);
    expect(find.text('DAI interface'), findsOneWidget);
    expect(find.text('Daily Adaptive Intelligence'), findsOneWidget);
    expect(find.text('DAI command'), findsOneWidget);
    expect(find.text('Connect wearable context'), findsOneWidget);
    expect(find.text('Behavior repair'), findsOneWidget);
    expect(find.text('Make starting feel safe'), findsOneWidget);
    expect(find.text('Belong before performance.'), findsOneWidget);
    expect(
      find.text('Start with a 30-second readiness check.'),
      findsOneWidget,
    );
    expect(find.text('Wearable status'), findsOneWidget);
    expect(find.text('HealthKit / Health Connect ready'), findsWidgets);
    expect(find.text('Readiness modifier'), findsOneWidget);
    expect(find.text('0 readiness points'), findsWidgets);
    expect(
      find.widgetWithText(FilledButton, 'Connect wearable'),
      findsOneWidget,
    );
    expect(find.text('Session plan'), findsOneWidget);
    expect(find.text('Readiness'), findsWidgets);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Soreness map'), findsOneWidget);
    expect(find.text('No check-in'), findsOneWidget);
    expect(find.text('Load target'), findsOneWidget);
    expect(find.text('Activation proof'), findsOneWidget);
    expect(find.text('Nutrition target'), findsWidgets);
    expect(find.text('Needed for activation'), findsOneWidget);
    expect(find.text('Protein target'), findsOneWidget);
    expect(find.text('Daily protein'), findsOneWidget);
    expect(find.text('Not created'), findsOneWidget);
    expect(find.text('Not started'), findsOneWidget);
    expect(find.text('Training pulse'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('0 sessions'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('0 sets'), findsOneWidget);
    expect(find.text('Top set'), findsNothing);
    expect(find.text('Next target'), findsNothing);
    expect(find.text('Warm-up ramp'), findsNothing);
    expect(find.text('Recent sessions'), findsOneWidget);
    expect(find.text('No sessions yet'), findsOneWidget);
    expect(find.bySemanticsLabel('Open proof card'), findsOneWidget);
    expect(find.text('Proof card'), findsOneWidget);
    expect(find.bySemanticsLabel('Open coach command'), findsOneWidget);
    expect(find.text('Coach'), findsWidgets);
    expect(find.bySemanticsLabel('Open progress'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.bySemanticsLabel('Open composition trust'), findsOneWidget);
    expect(find.text('Composition'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Training pulse: 0 sessions, 0 sets, volume not recorded.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Today screen syncs HealthWearableAdapter output into DAI', (
    WidgetTester tester,
  ) async {
    final adapter = _FakeWearableSyncAdapter(
      WearableSignal(
        id: 'wearable-healthkit-test',
        capturedAt: DateTime(2026, 7, 3, 7),
        source: 'apple_healthkit',
        syncState: 'synced',
        stepsToday: 7200,
        restingHeartRateBpm: 58,
        heartRateVariabilityMs: 72,
        sleepMinutes: 480,
        activeEnergyKcal: 420,
        workoutMinutes: 36,
      ),
    );
    final container = ProviderContainer(
      overrides: [wearableSyncAdapterProvider.overrideWithValue(adapter)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(
      container.read(sessionControllerProvider).state.wearableSignal,
      isNull,
    );

    final sync = find.widgetWithText(FilledButton, 'Connect wearable');
    await tester.ensureVisible(sync);
    await tester.tap(sync);
    await tester.pumpAndSettle();

    expect(adapter.readCalls, 1);
    final signal = container
        .read(sessionControllerProvider)
        .state
        .wearableSignal;
    expect(signal, isNotNull);
    expect(signal!.source, 'apple_healthkit');
    expect(signal.heartRateVariabilityMs, 72);
    expect(find.text('Ready-biased wearable signal'), findsOneWidget);
    expect(find.text('+4 readiness points'), findsWidgets);
    expect(find.text('Refresh wearable'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Clear wearable'),
      findsOneWidget,
    );
  });

  testWidgets('Today screen keeps unavailable adapter output fail-closed', (
    WidgetTester tester,
  ) async {
    final adapter = _FakeWearableSyncAdapter(
      WearableSignal(
        id: 'wearable-unavailable-test',
        capturedAt: DateTime(2026, 7, 3, 7),
        source: 'health_package',
        syncState: 'unavailable',
      ),
    );
    final container = ProviderContainer(
      overrides: [wearableSyncAdapterProvider.overrideWithValue(adapter)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final sync = find.widgetWithText(FilledButton, 'Connect wearable');
    await tester.ensureVisible(sync);
    await tester.tap(sync);
    await tester.pumpAndSettle();

    final signal = container
        .read(sessionControllerProvider)
        .state
        .wearableSignal;
    expect(adapter.readCalls, 1);
    expect(signal, isNotNull);
    expect(signal!.syncState, 'unavailable');
    expect(find.text('Wearable sync unavailable'), findsWidgets);
    expect(find.text('0 readiness points'), findsWidgets);
    expect(find.textContaining('will not infer recovery'), findsOneWidget);
    expect(find.text('Ready-biased wearable signal'), findsNothing);
  });

  testWidgets('Today screen treats pending wearable permission as manual DAI', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(sessionControllerProvider)
        .setWearableSignal(
          WearableSignal(
            id: 'wearable-pending-permission',
            capturedAt: DateTime(2026, 7, 2, 7),
            source: 'health_package',
            syncState: 'pending_permission',
            sleepMinutes: 500,
            restingHeartRateBpm: 55,
            heartRateVariabilityMs: 80,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(find.text('Grant wearable permission'), findsOneWidget);
    expect(find.text('Wearable permission needed'), findsWidgets);
    expect(find.text('0 readiness points'), findsWidgets);
    expect(find.textContaining('not authorized yet'), findsOneWidget);
    expect(
      find.textContaining('No wearable metric changes training'),
      findsOneWidget,
    );
    expect(find.text('Ready-biased wearable signal'), findsNothing);
    expect(
      find.widgetWithText(FilledButton, 'Connect wearable'),
      findsOneWidget,
    );
  });

  testWidgets('Today screen creates a safe nutrition target for activation', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(
      container.read(sessionControllerProvider).state.nutritionTarget,
      isNull,
    );
    expect(find.bySemanticsLabel('Create nutrition target'), findsOneWidget);

    final create = find.bySemanticsLabel('Create nutrition target');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();

    final target = container
        .read(sessionControllerProvider)
        .state
        .nutritionTarget;
    expect(target, isNotNull);
    expect(target!.label, 'Protein target');
    expect(target.targetDisplay, '120 g/day');
    expect(
      target.safetyNote.toLowerCase(),
      contains('not medical nutrition advice'),
    );
    expect(find.text('Target saved'), findsOneWidget);
    expect(find.text('Update target'), findsOneWidget);
    expect(find.textContaining('120 g/day'), findsWidgets);
    expect(find.text('3 source trace'), findsOneWidget);
    expect(find.bySemanticsLabel('Update nutrition target'), findsOneWidget);
  });

  testWidgets('Start session opens the real session loop', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(
      container.read(sessionControllerProvider).state.activeSession,
      isNull,
    );
    expect(find.text('Ready to start'), findsOneWidget);

    final start = find.bySemanticsLabel('Start today session');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    final state = container.read(sessionControllerProvider).state;
    expect(state.readinessEntry, isNotNull);
    expect(state.activeSession, isNotNull);
    expect(find.text('Session live'), findsWidgets);
    expect(find.bySemanticsLabel('Session already live'), findsOneWidget);
    expect(find.bySemanticsLabel('Start today session'), findsNothing);
    final startButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Session live').last,
    );
    expect(startButton.onPressed, isNull);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('Maintain'), findsOneWidget);
    expect(find.text('2 areas'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.bySemanticsLabel('Apply next set'), findsNothing);
    expect(find.bySemanticsLabel('Log workout set'), findsOneWidget);
    final logButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Log workout set'),
    );
    expect(logButton.onPressed, isNull);
    expect(find.bySemanticsLabel('Undo last set'), findsOneWidget);
    final undoButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Undo last set'),
    );
    expect(undoButton.onPressed, isNull);
    expect(find.bySemanticsLabel('Finish and debrief'), findsOneWidget);
    final finishButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Finish and debrief'),
    );
    expect(finishButton.onPressed, isNull);
    expect(find.text('Logged sets'), findsOneWidget);
    expect(find.text('No sets logged yet'), findsOneWidget);
  });

  testWidgets('Today iPhone controls keep app-grade touch targets', (
    WidgetTester tester,
  ) async {
    _setTestViewport(tester, const Size(390, 720));
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    await _expectMinTouchTarget(
      tester,
      find.bySemanticsLabel('Toggle hips soreness'),
      'hips soreness chip',
    );
    await _expectMinTouchTarget(
      tester,
      find.bySemanticsLabel('Save check-in'),
      'save check-in',
    );
    await _expectMinTouchTarget(
      tester,
      find.bySemanticsLabel('Start today session'),
      'start session',
    );
    await _expectMinTouchTarget(
      tester,
      find.widgetWithText(OutlinedButton, 'Open profile'),
      'open profile',
    );
    await _expectMinTouchTarget(
      tester,
      find.bySemanticsLabel('Create nutrition target'),
      'create nutrition target',
    );

    final start = find.bySemanticsLabel('Start today session');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    const exerciseName = 'Goblet squat';
    final exerciseField = find.byKey(const ValueKey('today_exercise_field'));
    await tester.ensureVisible(exerciseField);
    await tester.enterText(exerciseField, exerciseName);
    await tester.pump();

    final increaseWeight = find.byTooltip('Increase set weight');
    await tester.ensureVisible(increaseWeight);
    await tester.tap(increaseWeight);
    await tester.pump();

    await _expectMinTouchTarget(
      tester,
      find.bySemanticsLabel('Log workout set'),
      'log workout set',
    );
    await _expectMinTouchTarget(
      tester,
      find.bySemanticsLabel('Undo last set'),
      'undo last set',
    );
    await _expectMinTouchTarget(
      tester,
      find.bySemanticsLabel('Finish and debrief'),
      'finish and debrief',
    );

    final logSet = find.bySemanticsLabel('Log workout set');
    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    await _expectMinTouchTarget(
      tester,
      find.bySemanticsLabel('Apply next set'),
      'apply next set',
    );
  });

  testWidgets('Start session preserves a restored readiness check-in', (
    WidgetTester tester,
  ) async {
    final restoredReadiness = ReadinessEntry(
      id: 'readiness-restored',
      date: DateTime(2026, 7, 2),
      score: 30,
      zone: 'deload',
      energyLevel: 5,
      sleepQuality: 5,
      sorenessMap: const ['quads', 'hamstrings', 'chest', 'back'],
      createdAt: DateTime(2026, 7, 2, 7),
    );
    final controller = SessionController(
      initialState: SessionState(readinessEntry: restoredReadiness),
    );
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(find.text('30'), findsOneWidget);
    expect(find.text('Deload'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);

    final start = find.bySemanticsLabel('Start today session');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    final state = container.read(sessionControllerProvider).state;
    expect(state.readinessEntry!.id, 'readiness-restored');
    expect(state.readinessEntry!.zone, 'deload');
    expect(state.activeSession, isNotNull);
    expect(state.activeSession!.readinessEntryId, 'readiness-restored');
    expect(state.activeSession!.volumeMultiplier, 0.65);
    expect(find.text('Session live'), findsWidgets);
    expect(find.text('Deload'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
  });

  testWidgets('Restored readiness hydrates check-in controls before resave', (
    WidgetTester tester,
  ) async {
    final restoredReadiness = ReadinessEntry(
      id: 'readiness-hydrated',
      date: DateTime(2026, 7, 2),
      score: 75,
      zone: 'push',
      energyLevel: 9,
      sleepQuality: 8,
      sorenessMap: const ['hips', 'back'],
      createdAt: DateTime(2026, 7, 2, 7),
    );
    final controller = SessionController(
      initialState: SessionState(readinessEntry: restoredReadiness),
    );
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(find.text('75'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('9/10'), findsOneWidget);
    expect(find.text('8/10'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'hips'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'back'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'ankles'))
          .selected,
      isFalse,
    );

    final save = find.bySemanticsLabel('Save check-in');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final entry = controller.state.readinessEntry!;
    expect(entry.energyLevel, 9);
    expect(entry.sleepQuality, 8);
    expect(entry.sorenessMap, ['hips', 'back']);
  });

  testWidgets('Restored readiness controls save intentional edits', (
    WidgetTester tester,
  ) async {
    final restoredReadiness = ReadinessEntry(
      id: 'readiness-hydrated-edited',
      date: DateTime(2026, 7, 2),
      score: 62,
      zone: 'maintain',
      energyLevel: 4,
      sleepQuality: 9,
      sorenessMap: const ['shoulders', 'back'],
      createdAt: DateTime(2026, 7, 2, 7),
    );
    final controller = SessionController(
      initialState: SessionState(readinessEntry: restoredReadiness),
    );
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final increaseEnergy = find.byTooltip('Increase energy');
    await tester.ensureVisible(increaseEnergy);
    await tester.tap(increaseEnergy);
    await tester.pump();
    final decreaseSleep = find.byTooltip('Decrease sleep');
    await tester.ensureVisible(decreaseSleep);
    await tester.tap(decreaseSleep);
    await tester.pump();
    final hipsChip = find.widgetWithText(FilterChip, 'hips');
    await tester.ensureVisible(hipsChip);
    await tester.tap(hipsChip);
    await tester.pump();
    final backChip = find.widgetWithText(FilterChip, 'back');
    await tester.ensureVisible(backChip);
    await tester.tap(backChip);
    await tester.pump();

    final save = find.bySemanticsLabel('Save check-in');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final entry = controller.state.readinessEntry!;
    expect(entry.energyLevel, 5);
    expect(entry.sleepQuality, 8);
    expect(entry.sorenessMap, ['hips', 'shoulders']);
  });

  testWidgets(
    'Restored readiness preserves hidden HRV and soreness on resave',
    (WidgetTester tester) async {
      final restoredReadiness = ReadinessEntry(
        id: 'readiness-hydrated-hidden',
        date: DateTime(2026, 7, 2),
        score: 33,
        zone: 'deload',
        energyLevel: 6,
        sleepQuality: 8,
        sorenessMap: const ['quads', 'back'],
        hrv: 60,
        createdAt: DateTime(2026, 7, 2, 7),
      );
      final controller = SessionController(
        initialState: SessionState(readinessEntry: restoredReadiness),
      );
      final container = ProviderContainer(
        overrides: [sessionControllerProvider.overrideWithValue(controller)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TodayScreen()),
        ),
      );

      expect(find.text('33'), findsOneWidget);
      expect(find.text('Deload'), findsOneWidget);
      expect(find.text('6/10'), findsOneWidget);
      expect(find.text('8/10'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'back'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'hips'))
            .selected,
        isFalse,
      );

      final save = find.bySemanticsLabel('Save check-in');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final entry = controller.state.readinessEntry!;
      expect(entry.hrv, 60);
      expect(entry.sorenessMap, ['back', 'quads']);
      expect(entry.score, 33);
      expect(entry.zone, 'deload');
    },
  );

  testWidgets('Readiness controls hydrate when restore arrives after mount', (
    WidgetTester tester,
  ) async {
    final controller = SessionController();
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    controller.restore(
      SessionState(
        readinessEntry: ReadinessEntry(
          id: 'readiness-late-restore',
          date: DateTime(2026, 7, 2),
          score: 58,
          zone: 'maintain',
          energyLevel: 3,
          sleepQuality: 9,
          sorenessMap: const ['shoulders'],
          createdAt: DateTime(2026, 7, 2, 7),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('58'), findsOneWidget);
    expect(find.text('Maintain'), findsOneWidget);
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text('9/10'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'shoulders'))
          .selected,
      isTrue,
    );

    final save = find.bySemanticsLabel('Save check-in');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final entry = controller.state.readinessEntry!;
    expect(entry.energyLevel, 3);
    expect(entry.sleepQuality, 9);
    expect(entry.sorenessMap, ['shoulders']);
    expect(entry.score, 58);
    expect(entry.zone, 'maintain');
  });

  testWidgets('High soreness shows a recovery-safe DOMS intervention', (
    WidgetTester tester,
  ) async {
    final restoredReadiness = ReadinessEntry(
      id: 'readiness-doms',
      date: DateTime(2026, 7, 2),
      score: 30,
      zone: 'deload',
      energyLevel: 5,
      sleepQuality: 5,
      sorenessMap: const ['hips', 'ankles', 'shoulders', 'back'],
      createdAt: DateTime(2026, 7, 2, 7),
    );
    final controller = SessionController(
      initialState: SessionState(readinessEntry: restoredReadiness),
    );
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(find.text('DOMS wall'), findsOneWidget);
    expect(
      find.textContaining('hips, ankles, shoulders, and back are sore'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Recovery-safe alternative: 12 min mobility, 20 min walk',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'DOMS wall: hips, ankles, shoulders, and back are sore'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Stale readiness shows a day-zero bail recovery cue', (
    WidgetTester tester,
  ) async {
    final staleReadiness = ReadinessEntry(
      id: 'readiness-stale',
      date: DateTime(2000),
      score: 86,
      zone: 'push',
      energyLevel: 8,
      sleepQuality: 9,
      sorenessMap: const [],
      createdAt: DateTime(2000),
    );
    final controller = SessionController(
      initialState: SessionState(readinessEntry: staleReadiness),
    );
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(find.text('Bail recovery'), findsOneWidget);
    expect(find.text('Save the day without pretending'), findsOneWidget);
    expect(
      find.text('Save today with an 8-minute recovery reset.'),
      findsOneWidget,
    );
    expect(find.textContaining('You already checked in'), findsOneWidget);
    expect(find.textContaining('8-minute reset'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Bail recovery: You already checked in')),
      findsOneWidget,
    );
  });

  testWidgets('Stale readiness recovery action logs an 8-minute reset', (
    WidgetTester tester,
  ) async {
    final staleReadiness = ReadinessEntry(
      id: 'readiness-stale-action',
      date: DateTime(2000),
      score: 86,
      zone: 'push',
      energyLevel: 8,
      sleepQuality: 9,
      sorenessMap: const [],
      createdAt: DateTime(2000),
    );
    final controller = SessionController(
      initialState: SessionState(readinessEntry: staleReadiness),
    );
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final action = find.bySemanticsLabel(
      'Save today with 8-minute recovery reset',
    );
    expect(action, findsOneWidget);

    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    final state = controller.state;
    expect(state.activeSession, isNull);
    expect(state.history, hasLength(1));
    expect(state.lastDebrief, isNotNull);
    final resetSet = state.history.single.loggedSets.single;
    expect(resetSet.exerciseName, 'Recovery reset');
    expect(resetSet.durationSeconds, 480);
    expect(resetSet.rpe, 3);
    expect(find.text('Recovery reset'), findsWidgets);
    expect(find.text('8 min'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Save today with 8-minute recovery reset'),
      findsNothing,
    );
  });

  testWidgets('DOMS recovery action logs a 12-minute mobility reset', (
    WidgetTester tester,
  ) async {
    final restoredReadiness = ReadinessEntry(
      id: 'readiness-doms-action',
      date: DateTime(2026, 7, 2),
      score: 30,
      zone: 'deload',
      energyLevel: 5,
      sleepQuality: 5,
      sorenessMap: const ['hips', 'ankles', 'shoulders', 'back'],
      createdAt: DateTime(2026, 7, 2, 7),
    );
    final controller = SessionController(
      initialState: SessionState(readinessEntry: restoredReadiness),
    );
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(find.text('DOMS wall'), findsOneWidget);
    final action = find.bySemanticsLabel('Log 12-minute mobility reset');
    expect(action, findsOneWidget);

    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    final state = controller.state;
    expect(state.activeSession, isNull);
    expect(state.history, hasLength(1));
    expect(state.lastDebrief, isNotNull);
    final resetSet = state.history.single.loggedSets.single;
    expect(resetSet.exerciseName, 'Mobility reset');
    expect(resetSet.durationSeconds, 720);
    expect(resetSet.rpe, 3);
    expect(find.text('Mobility reset'), findsWidgets);
    expect(find.text('12 min'), findsOneWidget);
    expect(find.bySemanticsLabel('Log 12-minute mobility reset'), findsNothing);
  });

  testWidgets('Sign out clears local session when remote sign-out fails', (
    WidgetTester tester,
  ) async {
    final authFacade = _ThrowingSignOutAuthFacade();
    final snapshotStore = _FakeSessionSnapshotStore();
    final authGuard = AuthGuardState(
      initialStatus: AuthGuardStatus.authenticatedWithProfile,
    );
    final controller = SessionController();
    controller.submitReadiness(
      energyLevel: 8,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    controller.logSet(
      exerciseName: 'Split squat',
      setNumber: 1,
      weightKg: 24,
      reps: 10,
    );

    final container = ProviderContainer(
      overrides: [
        authFacadeProvider.overrideWithValue(authFacade),
        authGuardStateProvider.overrideWithValue(authGuard),
        sessionControllerProvider.overrideWithValue(controller),
        sessionSnapshotStoreProvider.overrideWithValue(snapshotStore),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    expect(controller.state.activeSession, isNotNull);
    expect(authGuard.status, AuthGuardStatus.authenticatedWithProfile);
    expect(snapshotStore.hasSnapshot, isTrue);

    final signOut = find.widgetWithText(TextButton, 'Sign out');
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pumpAndSettle();

    expect(authFacade.signOutCalls, equals(1));
    expect(snapshotStore.clearCalls, equals(1));
    expect(snapshotStore.hasSnapshot, isFalse);
    expect(controller.state.readinessEntry, isNull);
    expect(controller.state.activeSession, isNull);
    expect(controller.state.lastDebrief, isNull);
    expect(controller.state.history, isEmpty);
    expect(authGuard.status, AuthGuardStatus.unauthenticated);
  });

  testWidgets('Score steppers expose semantic values and actions', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final energyStepper = find.semantics.byLabel('Energy');
    expect(energyStepper, findsOne);
    expect(
      energyStepper.evaluate().single,
      isSemantics(
        label: 'Energy',
        value: '7 out of 10',
        increasedValue: '8 out of 10',
        decreasedValue: '6 out of 10',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    tester.semantics.increase(energyStepper);
    await tester.pump();

    expect(find.text('8/10'), findsOneWidget);
    expect(
      energyStepper.evaluate().single,
      isSemantics(
        label: 'Energy',
        value: '8 out of 10',
        increasedValue: '9 out of 10',
        decreasedValue: '7 out of 10',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('Readiness steppers announce disabled during live session', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final start = find.bySemanticsLabel('Start today session');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    final energyStepper = find.semantics.byLabel('Energy');
    expect(energyStepper, findsOne);
    expect(
      energyStepper.evaluate().single,
      isSemantics(
        label: 'Energy',
        value: '7 out of 10',
        hasEnabledState: true,
        isEnabled: false,
        hasIncreaseAction: false,
        hasDecreaseAction: false,
      ),
    );

    final save = find.bySemanticsLabel('Save check-in');
    expect(save, findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Save check-in'),
          )
          .onPressed,
      isNull,
    );
    semantics.dispose();
  });

  testWidgets('Workout steppers expose spoken values and boundaries', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final start = find.bySemanticsLabel('Start today session');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    final weightStepper = find.semantics.byLabel('Set weight');
    expect(weightStepper, findsOne);
    expect(
      weightStepper.evaluate().single,
      isSemantics(
        label: 'Set weight',
        value: '0 kilograms',
        increasedValue: '5 kilograms',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: false,
      ),
    );

    tester.semantics.increase(weightStepper);
    await tester.pump();

    expect(find.text('5 kg'), findsOneWidget);
    expect(
      weightStepper.evaluate().single,
      isSemantics(
        label: 'Set weight',
        value: '5 kilograms',
        increasedValue: '10 kilograms',
        decreasedValue: '0 kilograms',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    final setRpeStepper = find.semantics.byLabel('Set RPE');
    expect(setRpeStepper, findsOne);
    expect(
      setRpeStepper.evaluate().single,
      isSemantics(
        label: 'Set RPE',
        value: '6 out of 10',
        increasedValue: '7 out of 10',
        decreasedValue: '5 out of 10',
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('Readiness controls save a custom check-in before start', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final increaseEnergy = find.byTooltip('Increase energy');
    await tester.ensureVisible(increaseEnergy);
    await tester.tap(increaseEnergy);
    await tester.pump();
    await tester.tap(increaseEnergy);
    await tester.pump();

    final increaseSleep = find.byTooltip('Increase sleep');
    await tester.ensureVisible(increaseSleep);
    await tester.tap(increaseSleep);
    await tester.pump();

    await tester.tap(find.text('hips'));
    await tester.pump();
    await tester.tap(find.text('ankles'));
    await tester.pump();

    final save = find.text('Save check-in');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final checkedIn = container.read(sessionControllerProvider).state;
    expect(checkedIn.readinessEntry!.energyLevel, 9);
    expect(checkedIn.readinessEntry!.sleepQuality, 8);
    expect(checkedIn.readinessEntry!.sorenessMap, isEmpty);
    expect(checkedIn.readinessEntry!.score, 85);
    expect(checkedIn.readinessEntry!.zone, 'push');
    expect(find.text('85'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('110%'), findsOneWidget);

    final start = find.bySemanticsLabel('Start today session');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    final live = container.read(sessionControllerProvider).state;
    expect(live.activeSession, isNotNull);
    expect(live.activeSession!.volumeMultiplier, 1.10);
    expect(live.readinessEntry!.score, 85);
    expect(find.bySemanticsLabel('Save check-in'), findsOneWidget);
    final saveButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Save check-in'),
    );
    expect(saveButton.onPressed, isNull);
    final hipsChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'hips'),
    );
    expect(hipsChip.onSelected, isNull);
    final shouldersChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'shoulders'),
    );
    expect(shouldersChip.onSelected, isNull);
  });

  testWidgets('Session loop logs a set and saves a debrief', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final start = find.bySemanticsLabel('Start today session');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    const exerciseName = 'Goblet squat';
    final exerciseField = find.byKey(const ValueKey('today_exercise_field'));
    await tester.ensureVisible(exerciseField);
    await tester.enterText(exerciseField, exerciseName);
    await tester.pump();
    final readyLogButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Log workout set'),
    );
    expect(readyLogButton.onPressed, isNotNull);

    final increaseWeight = find.byTooltip('Increase set weight');
    await tester.ensureVisible(increaseWeight);
    for (var i = 0; i < 4; i += 1) {
      await tester.tap(increaseWeight);
      await tester.pump();
    }

    final increaseReps = find.byTooltip('Increase set reps');
    await tester.ensureVisible(increaseReps);
    await tester.tap(increaseReps);
    await tester.pump();
    await tester.tap(increaseReps);
    await tester.pump();

    final increaseSetRpe = find.byTooltip('Increase set RPE');
    await tester.ensureVisible(increaseSetRpe);
    await tester.tap(increaseSetRpe);
    await tester.pump();

    final logSet = find.bySemanticsLabel('Log workout set');
    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    final loggedSet = container
        .read(sessionControllerProvider)
        .state
        .activeSession!
        .loggedSets
        .single;
    expect(loggedSet.exerciseName, exerciseName);
    expect(loggedSet.weightKg, 20);
    expect(loggedSet.reps, 12);
    expect(loggedSet.rpe, 7);
    expect(
      container.read(sessionControllerProvider).state.activeSession!.totalSets,
      1,
    );
    expect(find.text('1 set'), findsOneWidget);
    expect(find.text('Logged sets'), findsOneWidget);
    expect(find.text(exerciseName), findsWidgets);
    expect(find.text('20 kg x 12 reps'), findsOneWidget);
    expect(find.text('RPE 7'), findsOneWidget);
    expect(find.text('240 kg'), findsOneWidget);
    final finishButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Finish and debrief'),
    );
    expect(finishButton.onPressed, isNotNull);

    final increaseRpe = find.byTooltip('Increase debrief RPE');
    await tester.ensureVisible(increaseRpe);
    await tester.tap(increaseRpe);
    await tester.pump();
    await tester.tap(increaseRpe);
    await tester.pump();

    final increaseSatisfaction = find.byTooltip(
      'Increase debrief satisfaction',
    );
    await tester.ensureVisible(increaseSatisfaction);
    await tester.tap(increaseSatisfaction);
    await tester.pump();

    const nextFocus = 'Protect the back squat groove';
    final nextFocusField = find.byKey(const ValueKey('today_next_focus_field'));
    await tester.ensureVisible(nextFocusField);
    await tester.enterText(nextFocusField, nextFocus);
    await tester.pump();

    const painCheck = 'Left knee quiet, no sharp pain.';
    final painCheckField = find.byKey(const ValueKey('today_pain_notes_field'));
    await tester.ensureVisible(painCheckField);
    await tester.enterText(painCheckField, painCheck);
    await tester.pump();

    final finish = find.bySemanticsLabel('Finish and debrief');
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pumpAndSettle();

    final state = container.read(sessionControllerProvider).state;
    expect(state.activeSession, isNull);
    expect(state.history.length, 1);
    expect(state.lastDebrief, isNotNull);
    expect(state.lastDebrief!.perceivedExertion, 8);
    expect(state.lastDebrief!.satisfaction, 5);
    expect(state.lastDebrief!.painNotes, painCheck);
    expect(state.lastDebrief!.nextSessionFocus, nextFocus);
    expect(find.text('Debrief saved'), findsWidgets);
    expect(find.textContaining('Next focus:'), findsOneWidget);
    expect(find.text('Pain check'), findsWidgets);
    expect(find.text(painCheck), findsWidgets);
    expect(find.text('Last session'), findsOneWidget);
    expect(find.text('Top set'), findsOneWidget);
    expect(find.text('From session 1'), findsOneWidget);
    expect(find.text('Next target'), findsOneWidget);
    expect(find.text('Warm-up ramp'), findsOneWidget);
    expect(find.text('1 set'), findsNWidgets(2));
    expect(find.text('Volume'), findsNWidgets(2));
    expect(find.text('240 kg'), findsNWidgets(2));
    expect(find.text(exerciseName), findsNWidgets(3));
    expect(find.text('20 kg x 12 reps'), findsOneWidget);
    expect(find.text('20 kg x 12 reps · RPE 7'), findsOneWidget);
    expect(
      find.text('20 kg x 13 reps · Add 1 rep before load'),
      findsOneWidget,
    );
    expect(find.text('10 kg x 8 reps · 15 kg x 5 reps'), findsOneWidget);
    expect(find.text('RPE 7'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Top set: Goblet squat, 20 kilograms for 12 reps, RPE 7, session 1.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Next target: Goblet squat, 20 kilograms for 13 reps. '
        'Add one rep before adding load.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Warm-up ramp: Goblet squat, 10 kilograms for 8 reps, '
        'then 15 kilograms for 5 reps.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Last session: 1 set, 240 kilograms, Goblet squat, '
        '20 kilograms for 12 reps, RPE 7.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Pain check: $painCheck'), findsOneWidget);
  });

  testWidgets('Session loop can undo the last logged set', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final start = find.bySemanticsLabel('Start today session');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    const exerciseName = 'Bad rep';
    final exerciseField = find.byKey(const ValueKey('today_exercise_field'));
    await tester.ensureVisible(exerciseField);
    await tester.enterText(exerciseField, exerciseName);
    await tester.pump();

    final logSet = find.bySemanticsLabel('Log workout set');
    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    expect(
      container.read(sessionControllerProvider).state.activeSession!.totalSets,
      1,
    );
    expect(find.text('1 set'), findsOneWidget);
    expect(find.text('RPE 6'), findsOneWidget);
    var undoButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Undo last set'),
    );
    expect(undoButton.onPressed, isNotNull);
    var finishButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Finish and debrief'),
    );
    expect(finishButton.onPressed, isNotNull);

    final undo = find.bySemanticsLabel('Undo last set');
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pumpAndSettle();

    expect(
      container.read(sessionControllerProvider).state.activeSession!.totalSets,
      0,
    );
    expect(find.text('0 sets'), findsNWidgets(2));
    expect(find.text('No sets logged yet'), findsOneWidget);
    expect(find.text('RPE 6'), findsNothing);
    undoButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Undo last set'),
    );
    expect(undoButton.onPressed, isNull);
    finishButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Finish and debrief'),
    );
    expect(finishButton.onPressed, isNull);
  });

  testWidgets(
    'Session loop can apply a target from active sets without history',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TodayScreen()),
        ),
      );

      final start = find.bySemanticsLabel('Start today session');
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Apply next set'), findsNothing);

      const exerciseName = 'Goblet squat';
      final exerciseField = find.byKey(const ValueKey('today_exercise_field'));
      await tester.ensureVisible(exerciseField);
      await tester.enterText(exerciseField, exerciseName);
      await tester.pump();

      final increaseWeight = find.byTooltip('Increase set weight');
      await tester.ensureVisible(increaseWeight);
      for (var i = 0; i < 4; i += 1) {
        await tester.tap(increaseWeight);
        await tester.pump();
      }

      final increaseReps = find.byTooltip('Increase set reps');
      await tester.ensureVisible(increaseReps);
      await tester.tap(increaseReps);
      await tester.pump();
      await tester.tap(increaseReps);
      await tester.pump();

      final increaseSetRpe = find.byTooltip('Increase set RPE');
      await tester.ensureVisible(increaseSetRpe);
      await tester.tap(increaseSetRpe);
      await tester.pump();

      final logSet = find.bySemanticsLabel('Log workout set');
      await tester.ensureVisible(logSet);
      await tester.tap(logSet);
      await tester.pumpAndSettle();

      final loggedSet = container
          .read(sessionControllerProvider)
          .state
          .activeSession!
          .loggedSets
          .single;
      expect(loggedSet.exerciseName, exerciseName);
      expect(loggedSet.weightKg, 20);
      expect(loggedSet.reps, 12);
      expect(loggedSet.rpe, 7);
      expect(find.text('Next working set'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Next working set: Goblet squat, 20 kilograms for 13 reps. '
          'Add one rep before adding load.',
        ),
        findsOneWidget,
      );

      final applyNextSet = find.bySemanticsLabel('Apply next set');
      expect(applyNextSet, findsOneWidget);
      await tester.ensureVisible(applyNextSet);
      await tester.tap(applyNextSet);
      await tester.pump();

      final updatedExerciseField = tester.widget<TextField>(exerciseField);
      expect(updatedExerciseField.controller!.text, exerciseName);
      expect(find.text('20 kg'), findsOneWidget);
      expect(find.text('13 reps'), findsOneWidget);
      expect(find.text('7/10'), findsWidgets);
    },
  );

  testWidgets('Activation proof shows recent completed sessions newest first', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final controller = container.read(sessionControllerProvider);

    controller.submitReadiness(
      energyLevel: 8,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    controller.logSet(
      exerciseName: 'Row',
      setNumber: 1,
      weightKg: 30,
      reps: 10,
      rpe: 6,
    );
    controller.endSession(notes: 'First session');
    controller.resetDay();

    controller.submitReadiness(
      energyLevel: 9,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    controller.logSet(
      exerciseName: 'Deadlift',
      setNumber: 1,
      weightKg: 40,
      reps: 12,
      rpe: 8,
    );
    controller.endSession(notes: 'Second session');
    controller.submitDebrief(
      perceivedExertion: 8,
      satisfaction: 5,
      nextSessionFocus: 'Keep hinge crisp',
    );
    await tester.pump();

    expect(controller.state.history, hasLength(2));
    expect(find.text('Completed sessions'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Training pulse'), findsOneWidget);
    expect(find.text('2 sessions'), findsOneWidget);
    expect(find.text('2 sets'), findsOneWidget);
    expect(find.text('780 kg'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Training pulse: 2 sessions, 2 sets, 780 kilograms.',
      ),
      findsOneWidget,
    );
    expect(find.text('Top set'), findsOneWidget);
    expect(find.text('From session 2'), findsOneWidget);
    expect(find.text('Next target'), findsOneWidget);
    expect(find.text('Warm-up ramp'), findsOneWidget);
    expect(find.text('40 kg x 12 reps · RPE 8'), findsOneWidget);
    expect(
      find.text('40 kg x 12 reps · Repeat clean before load'),
      findsOneWidget,
    );
    expect(find.text('20 kg x 8 reps · 30 kg x 5 reps'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Top set: Deadlift, 40 kilograms for 12 reps, RPE 8, session 2.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Next target: Deadlift, 40 kilograms for 12 reps. '
        'Repeat it cleanly before adding load.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Warm-up ramp: Deadlift, 20 kilograms for 8 reps, '
        'then 30 kilograms for 5 reps.',
      ),
      findsOneWidget,
    );
    expect(find.text('Recent sessions'), findsOneWidget);
    expect(find.text('Session 2'), findsOneWidget);
    expect(find.text('Deadlift'), findsWidgets);
    expect(find.text('1 set | 480 kg'), findsOneWidget);
    expect(find.text('Session 1'), findsOneWidget);
    expect(find.text('Row'), findsOneWidget);
    expect(find.text('1 set | 300 kg'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Session 2')).dy,
      lessThan(tester.getTopLeft(find.text('Session 1')).dy),
    );
    expect(
      find.bySemanticsLabel(
        'Session 2: 1 set, 480 kilograms, Deadlift, '
        '40 kilograms for 12 reps, RPE 8.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Session loop can apply the working set after warm-ups', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final controller = container.read(sessionControllerProvider);
    controller.submitReadiness(
      energyLevel: 8,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    controller.logSet(
      exerciseName: 'Row',
      setNumber: 1,
      weightKg: 30,
      reps: 10,
      rpe: 6,
    );
    controller.endSession(notes: 'First session');
    controller.resetDay();

    controller.submitReadiness(
      energyLevel: 9,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    controller.logSet(
      exerciseName: 'Deadlift',
      setNumber: 1,
      weightKg: 40,
      reps: 12,
      rpe: 8,
    );
    controller.endSession(notes: 'Second session');
    controller.resetDay();

    controller.submitReadiness(
      energyLevel: 8,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    controller.logSet(
      exerciseName: 'Deadlift',
      setNumber: 1,
      weightKg: 20,
      reps: 8,
      rpe: 4,
    );
    controller.logSet(
      exerciseName: 'Deadlift',
      setNumber: 2,
      weightKg: 30,
      reps: 5,
      rpe: 5,
    );
    await tester.pump();

    expect(find.text('Session live'), findsWidgets);
    expect(find.text('Next working set'), findsOneWidget);
    final applyTarget = find.bySemanticsLabel('Apply next set');
    expect(applyTarget, findsOneWidget);

    await tester.ensureVisible(applyTarget);
    await tester.tap(applyTarget);
    await tester.pump();

    final exerciseField = tester.widget<TextField>(
      find.byKey(const ValueKey('today_exercise_field')),
    );
    expect(exerciseField.controller!.text, 'Deadlift');
    expect(find.text('40 kg'), findsOneWidget);
    expect(find.text('12 reps'), findsOneWidget);
    expect(find.text('8/10'), findsOneWidget);

    final logSet = find.bySemanticsLabel('Log workout set');
    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    final loggedSet = controller.state.activeSession!.loggedSets.last;
    expect(controller.state.activeSession!.loggedSets, hasLength(3));
    expect(loggedSet.setNumber, 3);
    expect(loggedSet.exerciseName, 'Deadlift');
    expect(loggedSet.weightKg, 40);
    expect(loggedSet.reps, 12);
    expect(loggedSet.rpe, 8);
    expect(find.text('#3'), findsOneWidget);
    expect(find.text('Deadlift'), findsWidgets);
    expect(find.text('40 kg x 12 reps'), findsWidgets);
    expect(find.text('RPE 8'), findsWidgets);
  });

  testWidgets('Session loop can apply the warm-up ramp into set controls', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final controller = container.read(sessionControllerProvider);
    controller.submitReadiness(
      energyLevel: 9,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    controller.logSet(
      exerciseName: 'Deadlift',
      setNumber: 1,
      weightKg: 40,
      reps: 12,
      rpe: 8,
    );
    controller.endSession(notes: 'Baseline hinge');
    controller.resetDay();

    controller.submitReadiness(
      energyLevel: 8,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    await tester.pump();

    expect(find.text('Session live'), findsWidgets);
    expect(find.text('Next warm-up 1'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Next warm-up 1: Deadlift, 20 kilograms for 8 reps, RPE 4.',
      ),
      findsOneWidget,
    );
    final applyNextSet = find.bySemanticsLabel('Apply next set');
    expect(applyNextSet, findsOneWidget);

    await tester.ensureVisible(applyNextSet);
    await tester.tap(applyNextSet);
    await tester.pump();

    final exerciseField = tester.widget<TextField>(
      find.byKey(const ValueKey('today_exercise_field')),
    );
    expect(exerciseField.controller!.text, 'Deadlift');
    expect(find.text('20 kg'), findsOneWidget);
    expect(find.text('8 reps'), findsOneWidget);
    expect(find.text('4/10'), findsOneWidget);

    final logSet = find.bySemanticsLabel('Log workout set');
    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    final loggedSet = controller.state.activeSession!.loggedSets.single;
    expect(loggedSet.setNumber, 1);
    expect(loggedSet.exerciseName, 'Deadlift');
    expect(loggedSet.weightKg, 20);
    expect(loggedSet.reps, 8);
    expect(loggedSet.rpe, 4);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('Deadlift'), findsWidgets);
    expect(find.text('20 kg x 8 reps'), findsOneWidget);
    expect(find.text('RPE 4'), findsOneWidget);
    expect(find.text('Next warm-up 2'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Next warm-up 2: Deadlift, 30 kilograms for 5 reps, RPE 5.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(applyNextSet);
    await tester.tap(applyNextSet);
    await tester.pump();

    expect(exerciseField.controller!.text, 'Deadlift');
    expect(find.text('30 kg'), findsOneWidget);
    expect(find.text('5 reps'), findsOneWidget);
    expect(find.text('5/10'), findsOneWidget);

    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    final loggedSets = controller.state.activeSession!.loggedSets;
    expect(loggedSets, hasLength(2));
    expect(loggedSets.last.setNumber, 2);
    expect(loggedSets.last.exerciseName, 'Deadlift');
    expect(loggedSets.last.weightKg, 30);
    expect(loggedSets.last.reps, 5);
    expect(loggedSets.last.rpe, 5);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('30 kg x 5 reps'), findsOneWidget);
    expect(find.text('RPE 5'), findsOneWidget);
    expect(find.text('Next working set'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Next working set: Deadlift, 40 kilograms for 12 reps. '
        'Repeat it cleanly before adding load.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(applyNextSet);
    await tester.tap(applyNextSet);
    await tester.pump();

    expect(exerciseField.controller!.text, 'Deadlift');
    expect(find.text('40 kg'), findsOneWidget);
    expect(find.text('12 reps'), findsOneWidget);
    expect(find.text('8/10'), findsOneWidget);

    final decreaseSetRpe = find.byTooltip('Decrease set RPE');
    await tester.ensureVisible(decreaseSetRpe);
    await tester.tap(decreaseSetRpe);
    await tester.pump();
    expect(find.text('7/10'), findsWidgets);

    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    final adaptedSets = controller.state.activeSession!.loggedSets;
    expect(adaptedSets, hasLength(3));
    expect(adaptedSets.last.setNumber, 3);
    expect(adaptedSets.last.exerciseName, 'Deadlift');
    expect(adaptedSets.last.weightKg, 40);
    expect(adaptedSets.last.reps, 12);
    expect(adaptedSets.last.rpe, 7);
    expect(find.text('#3'), findsOneWidget);
    expect(find.text('40 kg x 12 reps'), findsOneWidget);
    expect(find.text('RPE 7'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Next working set: Deadlift, 40 kilograms for 13 reps. '
        'Add one rep before adding load.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(applyNextSet);
    await tester.tap(applyNextSet);
    await tester.pump();

    expect(exerciseField.controller!.text, 'Deadlift');
    expect(find.text('40 kg'), findsOneWidget);
    expect(find.text('13 reps'), findsOneWidget);
    expect(find.text('7/10'), findsWidgets);
  });

  testWidgets('Session loop scales next set on deload days', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TodayScreen()),
      ),
    );

    final controller = container.read(sessionControllerProvider);
    controller.submitReadiness(
      energyLevel: 9,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    controller.logSet(
      exerciseName: 'Deadlift',
      setNumber: 1,
      weightKg: 40,
      reps: 12,
      rpe: 8,
    );
    controller.endSession(notes: 'Baseline hinge');
    controller.resetDay();

    controller.submitReadiness(
      energyLevel: 5,
      sleepQuality: 5,
      sorenessMap: const ['hips', 'ankles', 'shoulders', 'back'],
    );
    controller.startSession();
    await tester.pump();

    expect(controller.state.readinessEntry!.zone, 'deload');
    expect(controller.state.activeSession!.volumeMultiplier, 0.65);
    expect(find.text('Deload'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('Next warm-up 1'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Next warm-up 1: Deadlift, 15 kilograms for 8 reps, RPE 4.',
      ),
      findsOneWidget,
    );

    final applyNextSet = find.bySemanticsLabel('Apply next set');
    await tester.ensureVisible(applyNextSet);
    await tester.tap(applyNextSet);
    await tester.pump();

    final exerciseField = tester.widget<TextField>(
      find.byKey(const ValueKey('today_exercise_field')),
    );
    expect(exerciseField.controller!.text, 'Deadlift');
    expect(find.text('15 kg'), findsOneWidget);
    expect(find.text('8 reps'), findsOneWidget);
    expect(find.text('4/10'), findsOneWidget);

    final logSet = find.bySemanticsLabel('Log workout set');
    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    expect(controller.state.activeSession!.loggedSets.single.weightKg, 15);
    expect(controller.state.activeSession!.loggedSets.single.reps, 8);
    expect(controller.state.activeSession!.loggedSets.single.rpe, 4);
    expect(find.text('Next warm-up 2'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Next warm-up 2: Deadlift, 20 kilograms for 5 reps, RPE 5.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(applyNextSet);
    await tester.tap(applyNextSet);
    await tester.pump();

    expect(exerciseField.controller!.text, 'Deadlift');
    expect(find.text('20 kg'), findsOneWidget);
    expect(find.text('5 reps'), findsOneWidget);
    expect(find.text('5/10'), findsOneWidget);

    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    expect(controller.state.activeSession!.loggedSets, hasLength(2));
    expect(controller.state.activeSession!.loggedSets.last.weightKg, 20);
    expect(controller.state.activeSession!.loggedSets.last.reps, 5);
    expect(controller.state.activeSession!.loggedSets.last.rpe, 5);
    expect(find.text('Next working set'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Next working set: Deadlift, 25 kilograms for 12 reps. '
        'Deload to 65 percent today before adding load.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(applyNextSet);
    await tester.tap(applyNextSet);
    await tester.pump();

    expect(exerciseField.controller!.text, 'Deadlift');
    expect(find.text('25 kg'), findsOneWidget);
    expect(find.text('12 reps'), findsOneWidget);
    expect(find.text('8/10'), findsOneWidget);

    await tester.ensureVisible(logSet);
    await tester.tap(logSet);
    await tester.pumpAndSettle();

    final deloadSet = controller.state.activeSession!.loggedSets.last;
    expect(controller.state.activeSession!.loggedSets, hasLength(3));
    expect(deloadSet.exerciseName, 'Deadlift');
    expect(deloadSet.weightKg, 25);
    expect(deloadSet.reps, 12);
    expect(deloadSet.rpe, 8);
  });

  testWidgets(
    'Today screen reacts to session changes made outside the screen',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TodayScreen()),
        ),
      );

      expect(find.text('Ready to start'), findsOneWidget);

      final controller = container.read(sessionControllerProvider);
      controller.submitReadiness(
        energyLevel: 9,
        sleepQuality: 8,
        sorenessMap: const [],
      );
      controller.startSession();
      await tester.pump();

      expect(find.text('Session live'), findsWidgets);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('Push'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('110%'), findsOneWidget);

      controller.logSet(
        exerciseName: 'External warm-up',
        setNumber: 1,
        durationSeconds: 300,
        rpe: 3,
      );
      await tester.pump();

      expect(find.text('1 set'), findsOneWidget);
      expect(find.text('External warm-up'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
      expect(find.text('RPE 3'), findsOneWidget);
    },
  );
}
