import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/progress/progress_screen.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';

void main() {
  testWidgets('progress screen renders the empty state', (tester) async {
    await _pump(tester, const SessionState());

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('No proof yet'), findsOneWidget);
    expect(find.text('Start from Today'), findsOneWidget);
    expect(find.text('Composition trust'), findsOneWidget);
    expect(find.text('Emotional map'), findsOneWidget);
    expect(find.text('Feel safe to begin'), findsOneWidget);
    expect(find.text('Orientation'), findsOneWidget);
    expect(find.text('Certainty'), findsOneWidget);
    expect(find.text('Progress ledger'), findsOneWidget);
    expect(find.text('No completed sessions yet'), findsOneWidget);
    expect(
      find.bySemanticsLabel('TransformFitAI progress logo'),
      findsOneWidget,
    );
  });

  testWidgets('progress screen renders volume and ledger without pain notes', (
    tester,
  ) async {
    final state = SessionState(
      history: [
        WorkoutSession(
          id: 'progress-session-1',
          startedAt: DateTime(2099, 7, 1, 8),
          endedAt: DateTime(2099, 7, 1, 8, 45),
          readinessEntryId: 'readiness-progress-1',
          loggedSets: const [
            LoggedSet(
              id: 'progress-set-1',
              exerciseName: 'Trap bar deadlift',
              setNumber: 1,
              weightKg: 100,
              reps: 5,
              rpe: 7,
            ),
          ],
        ),
        WorkoutSession(
          id: 'progress-session-2',
          startedAt: DateTime(2099, 7, 2, 8),
          endedAt: DateTime(2099, 7, 2, 8, 20),
          readinessEntryId: 'readiness-progress-2',
          loggedSets: const [
            LoggedSet(
              id: 'progress-set-2',
              exerciseName: 'Mobility reset',
              setNumber: 1,
              durationSeconds: 600,
              rpe: 3,
            ),
          ],
          sessionNotes: 'Recovery mobility work.',
        ),
      ],
      lastDebrief: SessionDebrief(
        id: 'progress-debrief-1',
        sessionId: 'progress-session-2',
        createdAt: DateTime(2099, 7, 2, 8, 25),
        perceivedExertion: 3,
        satisfaction: 4,
        painNotes: 'Private hip note',
      ),
    );

    await _pump(tester, state);

    expect(find.text('2 kept promises'), findsOneWidget);
    expect(find.text('Baseline week'), findsOneWidget);
    expect(find.text('Trap bar deadlift: 100 kg x 5'), findsOneWidget);
    expect(find.text('Recovery'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Emotional map'), findsOneWidget);
    expect(find.text('Feel the loop working'), findsOneWidget);
    expect(find.text('Momentum'), findsWidgets);
    expect(find.text('Private hip note'), findsNothing);
    expect(find.textContaining('weight loss'), findsNothing);
    expect(find.textContaining('before and after'), findsNothing);
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
        home: const ProgressScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
