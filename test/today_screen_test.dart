import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/screens/today_screen.dart';

void main() {
  testWidgets('Today screen displays coach voice text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TodayScreen(),
        ),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('Coach note:'), findsOneWidget);
  });
}
