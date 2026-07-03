import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/coaching/coach_command_screen.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';
import 'package:transformfit/theme/digital_atelier.dart';

void main() {
  testWidgets('coach command screen renders empty command center', (
    tester,
  ) async {
    await _pump(tester, const SessionState());

    expect(find.text('Coach command'), findsOneWidget);
    expect(find.text('First command is ready'), findsOneWidget);
    expect(find.text('Daily command'), findsOneWidget);
    expect(find.text('Connect wearable context'), findsWidgets);
    expect(find.text('Coach handoff'), findsOneWidget);
    expect(find.text('Next 24 hours'), findsOneWidget);
    expect(find.text('DAI command'), findsOneWidget);
    expect(find.text('Wearable readiness'), findsOneWidget);
    expect(find.text('Behavior repair'), findsWidgets);
    expect(find.text('Make starting feel safe'), findsOneWidget);
    expect(find.text('Day-zero activation'), findsWidgets);
    expect(find.text('Emotional map'), findsOneWidget);
    expect(find.text('Feel safe to begin'), findsOneWidget);
    expect(find.text('Orientation'), findsOneWidget);
    expect(find.text('Trust milestone'), findsOneWidget);
    expect(find.text('Earn two proof-backed sessions'), findsOneWidget);
    expect(find.text('Build value'), findsWidgets);
    expect(find.text('Training ledger'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Safety'), findsWidgets);
    expect(find.text('RIG systems'), findsOneWidget);
    expect(find.text('Triple Double Diamond'), findsOneWidget);
    expect(find.text('A1 deterministic'), findsOneWidget);
    expect(find.text('A2 hybrid typed'), findsOneWidget);
    expect(find.text('A3 agent bounded'), findsOneWidget);
    expect(find.text('A4 LLM agent free'), findsWidgets);
    expect(find.textContaining('BMS'), findsWidgets);
    expect(find.bySemanticsLabel('TransformFitAI coach logo'), findsOneWidget);
  });

  testWidgets('coach command screen renders wearable and training context', (
    tester,
  ) async {
    await _pump(
      tester,
      SessionState(
        readinessEntry: ReadinessEntry(
          id: 'readiness-screen',
          date: DateTime(2026, 7, 2),
          score: 82,
          zone: 'push',
          energyLevel: 8,
          sleepQuality: 8,
          sorenessMap: const ['hips'],
        ),
        wearableSignal: WearableSignal.localSample(
          capturedAt: DateTime(2026, 7, 2, 7),
        ),
        history: [
          WorkoutSession(
            id: 'session-screen',
            startedAt: DateTime(2099, 7, 2, 6),
            endedAt: DateTime(2099, 7, 2, 6, 45),
            readinessEntryId: 'readiness-old',
            loggedSets: const [
              LoggedSet(
                id: 'set-screen',
                exerciseName: 'Trap bar deadlift',
                setNumber: 1,
                weightKg: 120,
                reps: 5,
              ),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Review then progress'), findsOneWidget);
    expect(find.text('Ready-biased wearable signal'), findsOneWidget);
    expect(find.text('Behavior repair'), findsWidgets);
    expect(find.text('Nutrition bridge'), findsWidgets);
    expect(find.text('Emotional map'), findsOneWidget);
    expect(find.text('Feel the loop working'), findsOneWidget);
    expect(find.text('Momentum'), findsWidgets);
    expect(find.text('Trust milestone'), findsOneWidget);
    expect(find.text('Earn two proof-backed sessions'), findsOneWidget);
    expect(find.text('Build value'), findsWidgets);
    expect(find.text('RIG systems'), findsOneWidget);
    expect(find.textContaining('L4-D2'), findsWidgets);
    expect(
      find.textContaining('Top set: Trap bar deadlift 120 kg x 5.'),
      findsOneWidget,
    );
    expect(find.textContaining('weight loss'), findsNothing);
    expect(find.textContaining('no excuses'), findsNothing);
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
        home: const CoachCommandScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
