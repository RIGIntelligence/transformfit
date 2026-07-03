import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/trends/recommit_screen.dart';

void main() {
  group('RecommitScreen', () {
    testWidgets('renders welcome back header', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RecommitScreen()));
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('shows missed days', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: RecommitScreen(missedDays: 10),
      ));
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows adjusted target', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: RecommitScreen(newWeeklyTarget: 2),
      ));
      expect(find.textContaining('2 sessions this week'), findsOneWidget);
    });

    testWidgets('recommit button calls callback', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: RecommitScreen(onRecommit: () => pressed = true),
      ));
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('shows not ready yet option', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RecommitScreen()));
      expect(find.text('Not ready yet'), findsOneWidget);
    });
  });
}
