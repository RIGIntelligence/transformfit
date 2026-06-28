import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/main.dart';

void main() {
  testWidgets('App mounts auth screen by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TransformFitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auth'), findsOneWidget);
    expect(find.text('Sign in or create an account to continue.'), findsOneWidget);
  });
}
