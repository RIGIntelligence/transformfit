import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/debrief/debrief_screen.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';

void main() {
  group('DebriefSummary', () {
    test('empty state when no completed sessions', () {
      final summary = buildDebriefSummary(const SessionState());
      expect(summary.hasSession, isFalse);
      expect(summary.totalVolumeKg, 0.0);
      expect(summary.totalSets, 0);
      expect(summary.coachingTakeaway, contains('Train once'));
    });

    test('populates from a completed session with weight sets', () {
      final session = WorkoutSession(
        id: 'debrief-1',
        startedAt: DateTime(2099, 7, 1, 8),
        endedAt: DateTime(2099, 7, 1, 8, 45),
        readinessEntryId: 'readiness-1',
        loggedSets: const [
          LoggedSet(
            id: 'set-1',
            exerciseId: 'squat',
            exerciseName: 'Back squat',
            setNumber: 1,
            weightKg: 100,
            reps: 5,
            rpe: 7,
          ),
          LoggedSet(
            id: 'set-2',
            exerciseId: 'squat',
            exerciseName: 'Back squat',
            setNumber: 2,
            weightKg: 100,
            reps: 5,
            rpe: 8,
          ),
        ],
      );
      final summary = buildDebriefSummary(
        SessionState(history: [session]),
      );

      expect(summary.hasSession, isTrue);
      expect(summary.totalSets, 2);
      expect(summary.totalReps, 10);
      // Volume = 100*5 + 100*5 = 1000
      expect(summary.totalVolumeKg, 1000.0);
      expect(summary.volumeSummary, contains('1000 kg'));
      expect(summary.oneRmChanges, hasLength(1));
      expect(summary.oneRmChanges.first.exerciseId, 'squat');
      expect(summary.coachingTakeaway, isNotEmpty);
      expect(summary.semanticLabel, contains('Debrief'));
    });

    test('skips incomplete sets', () {
      final session = WorkoutSession(
        id: 'debrief-2',
        startedAt: DateTime(2099, 7, 2, 8),
        endedAt: DateTime(2099, 7, 2, 8, 30),
        readinessEntryId: 'readiness-2',
        loggedSets: const [
          LoggedSet(
            id: 'set-1',
            exerciseId: 'press',
            exerciseName: 'Bench press',
            setNumber: 1,
            weightKg: 60,
            reps: 8,
            rpe: 7,
            completed: true,
          ),
          LoggedSet(
            id: 'set-2',
            exerciseId: 'press',
            exerciseName: 'Bench press',
            setNumber: 2,
            weightKg: 60,
            reps: 8,
            rpe: 7,
            completed: false,
          ),
        ],
      );
      final summary = buildDebriefSummary(
        SessionState(history: [session]),
      );

      expect(summary.totalSets, 1);
      expect(summary.totalReps, 8);
    });

    test('deterministic — identical input produces identical output', () {
      final session = WorkoutSession(
        id: 'debrief-3',
        startedAt: DateTime(2099, 7, 3, 8),
        endedAt: DateTime(2099, 7, 3, 8, 40),
        readinessEntryId: 'readiness-3',
        loggedSets: const [
          LoggedSet(
            id: 'set-1',
            exerciseId: 'deadlift',
            exerciseName: 'Trap bar deadlift',
            setNumber: 1,
            weightKg: 120,
            reps: 3,
            rpe: 8,
          ),
        ],
      );
      final state = SessionState(history: [session]);
      final a = buildDebriefSummary(state);
      final b = buildDebriefSummary(state);
      expect(a.totalVolumeKg, b.totalVolumeKg);
      expect(a.coachingTakeaway, b.coachingTakeaway);
      expect(a.corridorStatus, b.corridorStatus);
    });
  });

  group('DebriefScreen', () {
    testWidgets('renders empty state without a session', (tester) async {
      await _pump(tester, const SessionState());

      expect(find.text('Debrief'), findsOneWidget);
      expect(find.text('Volume summary'), findsOneWidget);
      expect(find.text('No session yet.'), findsOneWidget);
      expect(find.text('What changed'), findsOneWidget);
      expect(find.text('Coaching takeaway'), findsOneWidget);
      expect(
        find.bySemanticsLabel('TransformFitAI debrief logo'),
        findsOneWidget,
      );
    });

    testWidgets('renders volume and analysis from a completed session', (
      tester,
    ) async {
      final session = WorkoutSession(
        id: 'debrief-ui-1',
        startedAt: DateTime(2099, 7, 1, 8),
        endedAt: DateTime(2099, 7, 1, 8, 45),
        readinessEntryId: 'readiness-ui-1',
        loggedSets: const [
          LoggedSet(
            id: 'set-1',
            exerciseId: 'squat',
            exerciseName: 'Back squat',
            setNumber: 1,
            weightKg: 100,
            reps: 5,
            rpe: 7,
          ),
        ],
      );

      await _pump(tester, SessionState(history: [session]));

      expect(find.text('Debrief'), findsOneWidget);
      expect(find.text('Volume summary'), findsOneWidget);
      expect(find.textContaining('500 kg'), findsWidgets);
      expect(find.text('What changed'), findsOneWidget);
      expect(find.textContaining('squat'), findsWidgets);
      expect(find.text('Coaching takeaway'), findsOneWidget);
      expect(find.text('Progression corridor'), findsOneWidget);
      expect(find.text('Readiness impact'), findsOneWidget);
    });
  });
}

Future<void> _pump(WidgetTester tester, SessionState state) async {
  final container = ProviderContainer(
    overrides: [
      sessionControllerProvider.overrideWithValue(
        SessionController(initialState: state),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDigitalAtelierTheme(),
        home: const DebriefScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
