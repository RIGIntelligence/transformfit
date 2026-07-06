import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/proof/proof_card_screen.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('proof card screen renders the empty local preview state', (
    tester,
  ) async {
    await _pump(tester, const SessionState());

    expect(find.text('Proof card'), findsOneWidget);
    expect(find.text('Proof begins after session 1'), findsOneWidget);
    expect(find.text('Share preview'), findsOneWidget);
    expect(find.text('Private by default'), findsOneWidget);
    expect(find.text('Copy proof text'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Copy proof text'),
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('first completed session'), findsOneWidget);
    expect(find.bySemanticsLabel('TransformFitAI proof logo'), findsOneWidget);
    expect(find.bySemanticsLabel('Proof card share preview'), findsOneWidget);
  });

  testWidgets(
    'proof card sharing controls survive narrow large-text viewport',
    (tester) async {
      final state = SessionState(
        history: [
          WorkoutSession(
            id: 'session-proof-a11y',
            startedAt: DateTime(2026, 7, 3, 8),
            endedAt: DateTime(2026, 7, 3, 8, 35),
            readinessEntryId: 'readiness-proof-a11y',
            loggedSets: const [
              LoggedSet(
                id: 'set-proof-a11y',
                exerciseName: 'Bench press',
                setNumber: 1,
                weightKg: 80,
                reps: 6,
                rpe: 7,
              ),
            ],
          ),
        ],
        lastDebrief: SessionDebrief(
          id: 'debrief-proof-a11y',
          sessionId: 'session-proof-a11y',
          createdAt: DateTime(2026, 7, 3, 8, 40),
          perceivedExertion: 7,
          satisfaction: 4,
          nextSessionFocus: 'Repeat clean reps before adding load',
        ),
      );

      await _pump(
        tester,
        state,
        viewportSize: const Size(390, 720),
        textScale: 1.35,
      );

      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel('TransformFitAI proof logo'),
        findsOneWidget,
      );
      await _expectMinTouchTarget(
        tester,
        find.bySemanticsLabel('Return to Today'),
        'return to Today',
      );
      await tester.ensureVisible(
        find.bySemanticsLabel('Proof card share preview'),
      );
      await tester.ensureVisible(
        find.text('I reviewed this redacted proof text'),
      );
      await tester.pump();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      final copyButton = find.bySemanticsLabel('Copy redacted proof text');
      await _expectMinTouchTarget(
        tester,
        copyButton,
        'copy redacted proof text',
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Copy proof text'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'proof card screen renders completed-session proof without pain notes',
    (tester) async {
      final state = SessionState(
        history: [
          WorkoutSession(
            id: 'session-proof-1',
            startedAt: DateTime(2026, 7, 1, 8),
            endedAt: DateTime(2026, 7, 1, 8, 45),
            readinessEntryId: 'readiness-proof-1',
            loggedSets: const [
              LoggedSet(
                id: 'set-proof-1',
                exerciseName: 'Trap bar deadlift',
                setNumber: 1,
                weightKg: 100,
                reps: 5,
                rpe: 7,
              ),
            ],
          ),
        ],
        lastDebrief: SessionDebrief(
          id: 'debrief-proof-1',
          sessionId: 'session-proof-1',
          createdAt: DateTime(2026, 7, 1, 8, 50),
          perceivedExertion: 7,
          satisfaction: 4,
          painNotes: 'Private left knee note',
          nextSessionFocus: 'Hinge clean before adding load',
        ),
      );

      await _pump(tester, state);

      expect(find.text('1 kept promise'), findsOneWidget);
      expect(find.text('Trap bar deadlift: 100 kg x 5'), findsOneWidget);
      expect(find.text('Hinge clean before adding load'), findsOneWidget);
      expect(find.textContaining('TransformFitAI proof:'), findsOneWidget);
      expect(find.textContaining('Shared by choice'), findsOneWidget);
      expect(find.text('No measurements'), findsOneWidget);
      expect(find.text('No injury details'), findsOneWidget);
      expect(find.textContaining('100 kg'), findsOneWidget);
      expect(find.textContaining('100 kg volume'), findsNothing);
      expect(find.textContaining('Private left knee note'), findsNothing);
      expect(find.textContaining('left knee'), findsNothing);
      expect(find.textContaining('weight loss'), findsNothing);
      expect(find.textContaining('before and after'), findsNothing);
      expect(find.textContaining('No body rankings'), findsNothing);
    },
  );

  testWidgets('proof card copy is disabled until explicit opt-in', (
    tester,
  ) async {
    var clipboardText = 'old clipboard';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final args = Map<String, Object?>.from(call.arguments as Map);
          clipboardText = args['text']! as String;
          return null;
        case 'Clipboard.getData':
          return {'text': clipboardText};
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final state = SessionState(
      history: [
        WorkoutSession(
          id: 'session-proof-copy',
          startedAt: DateTime(2026, 7, 3, 8),
          endedAt: DateTime(2026, 7, 3, 8, 35),
          readinessEntryId: 'readiness-proof-copy',
          loggedSets: const [
            LoggedSet(
              id: 'set-proof-copy',
              exerciseName: 'Front squat',
              setNumber: 1,
              weightKg: 90,
              reps: 5,
              rpe: 7,
            ),
          ],
        ),
      ],
      lastDebrief: SessionDebrief(
        id: 'debrief-proof-copy',
        sessionId: 'session-proof-copy',
        createdAt: DateTime(2026, 7, 3, 8, 40),
        perceivedExertion: 7,
        satisfaction: 4,
        painNotes: 'Private hip note',
        nextSessionFocus: 'Protect the hip and repeat clean singles',
      ),
    );

    await _pump(tester, state);

    final copyButton = find.widgetWithText(ElevatedButton, 'Copy proof text');
    expect(tester.widget<ElevatedButton>(copyButton).onPressed, isNull);

    await tester.ensureVisible(
      find.text('I reviewed this redacted proof text'),
    );
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.widget<ElevatedButton>(copyButton).onPressed, isNotNull);
    await tester.ensureVisible(copyButton);
    await tester.pump();
    await tester.tap(copyButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.text('Proof text copied. You choose where it goes.'),
      findsOneWidget,
    );
    final data = await Clipboard.getData('text/plain');
    expect(data?.text, contains('TransformFitAI proof: 1 kept promise'));
    expect(data?.text, contains('Shared by choice'));
    expect(data?.text, isNot(contains('90 kg')));
    expect(data?.text, isNot(contains('Front squat')));
    expect(data?.text, isNot(contains('hip')));
  });
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

Future<void> _pump(
  WidgetTester tester,
  SessionState state, {
  Size? viewportSize,
  double textScale = 1,
}) async {
  if (viewportSize != null) {
    _setTestViewport(tester, viewportSize);
  }

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
        builder: (context, child) {
          final mediaQuery = MediaQuery.maybeOf(context);
          final mediaData = mediaQuery ?? const MediaQueryData();
          return MediaQuery(
            data: mediaData.copyWith(textScaler: TextScaler.linear(textScale)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const ProofCardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
