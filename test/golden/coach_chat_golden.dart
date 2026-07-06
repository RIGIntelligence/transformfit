// M4: Golden tests for CoachChatScreen — snapshot regression testing.
//
// Run with: flutter test test/golden/coach_chat_golden.dart --update-goldens
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/coaching/coach_chat_screen.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// iPhone 11 Pro viewport (414×896 @2x).
const _iphoneSize = Size(414, 896);

/// Helper: build CoachChatScreen wrapped in production theme + Riverpod.
Widget _buildCoachChat() {
  return ProviderScope(
    child: MaterialApp(
      theme: buildDigitalAtelierTheme(),
      home: const CoachChatScreen(),
    ),
  );
}

void main() {
  group('CoachChatScreen Golden Tests', () {
    testWidgets('coach chat — initial welcome message', (tester) async {
      tester.view.physicalSize = _iphoneSize;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildCoachChat());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CoachChatScreen),
        matchesGoldenFile('goldens/coach_chat_initial.png'),
      );
    });

    testWidgets('coach chat — with user message', (tester) async {
      tester.view.physicalSize = _iphoneSize;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildCoachChat());
      await tester.pumpAndSettle();

      // Type a message in the input field.
      final inputField = find.byType(TextField);
      if (inputField.evaluate().isNotEmpty) {
        await tester.enterText(inputField, 'Feeling great today!');
        await tester.pump(const Duration(milliseconds: 300));

        // Send the message.
        final sendButton = find.byIcon(Icons.send);
        if (sendButton.evaluate().isNotEmpty) {
          await tester.tap(sendButton);
          await tester.pumpAndSettle();
        }
      }

      await expectLater(
        find.byType(CoachChatScreen),
        matchesGoldenFile('goldens/coach_chat_with_message.png'),
      );
    });

    testWidgets('coach chat — wide viewport (tablet)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildCoachChat());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CoachChatScreen),
        matchesGoldenFile('goldens/coach_chat_tablet.png'),
      );
    });
  });
}
