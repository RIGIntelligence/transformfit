import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/body_composition/body_composition_screen.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';

void main() {
  testWidgets('composition screen renders trust-first empty state', (
    tester,
  ) async {
    await _pump(tester, const SessionState());

    expect(find.text('Composition trust'), findsOneWidget);
    expect(find.text('No composition signal yet'), findsOneWidget);
    expect(find.textContaining('Signals, not verdicts'), findsOneWidget);
    expect(find.text('Imperfect signal'), findsOneWidget);
    expect(find.text('Private by default'), findsOneWidget);
    expect(find.text('Source trace'), findsOneWidget);
    expect(
      find.bySemanticsLabel('TransformFitAI composition trust logo'),
      findsOneWidget,
    );
    expect(find.textContaining('weight loss'), findsNothing);
    expect(find.textContaining('before and after'), findsNothing);
  });

  testWidgets(
    'composition screen renders training nutrition and privacy context',
    (tester) async {
      final state = SessionState(
        nutritionTarget: NutritionTarget(
          id: 'screen-nutrition-composition-1',
          createdAt: DateTime(2026, 7, 2, 7),
          targetType: 'protein',
          label: 'Protein target',
          dailyTarget: 150,
          unit: 'g/day',
        ),
        history: [
          WorkoutSession(
            id: 'screen-composition-session-1',
            startedAt: DateTime(2026, 7, 1, 8),
            endedAt: DateTime(2026, 7, 1, 8, 45),
            readinessEntryId: 'screen-readiness-1',
            loggedSets: const [
              LoggedSet(
                id: 'screen-composition-set-1',
                exerciseName: 'Trap bar deadlift',
                setNumber: 1,
                weightKg: 100,
                reps: 5,
                rpe: 7,
              ),
            ],
          ),
          WorkoutSession(
            id: 'screen-composition-session-2',
            startedAt: DateTime(2026, 7, 2, 8),
            endedAt: DateTime(2026, 7, 2, 8, 20),
            readinessEntryId: 'screen-readiness-2',
            loggedSets: const [
              LoggedSet(
                id: 'screen-composition-set-2',
                exerciseName: 'Mobility reset',
                setNumber: 1,
                durationSeconds: 600,
                rpe: 3,
              ),
            ],
            sessionNotes: 'Recovery mobility session.',
          ),
        ],
      );

      await _pump(tester, state);

      expect(find.text('Context before change'), findsOneWidget);
      expect(find.text('Strength context'), findsOneWidget);
      expect(find.text('1 weighted set'), findsOneWidget);
      expect(find.text('Recovery context'), findsOneWidget);
      expect(find.text('1 recovery win'), findsOneWidget);
      expect(find.text('Nutrition context'), findsOneWidget);
      expect(find.text('150 g/day'), findsOneWidget);
      expect(find.text('Review after repeated readings'), findsOneWidget);
      expect(find.textContaining('appearance score'), findsOneWidget);
      expect(find.textContaining('weight loss'), findsNothing);
      expect(find.textContaining('shred'), findsNothing);
    },
  );
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
        home: const BodyCompositionScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
