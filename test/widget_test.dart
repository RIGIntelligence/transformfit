import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/main.dart';
import 'package:transformfit/navigation/auth_state.dart';

void main() {
  testWidgets('App mounts the auth screen when unauthenticated', (
    WidgetTester tester,
  ) async {
    final authState = AuthGuardState(
      initialStatus: AuthGuardStatus.unauthenticated,
    );
    final container = ProviderContainer(
      overrides: [authGuardStateProvider.overrideWithValue(authState)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TransformFitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.bySemanticsLabel('Email'), findsOneWidget);
    expect(find.bySemanticsLabel('Password'), findsOneWidget);
    expect(find.bySemanticsLabel('Sign in'), findsOneWidget);
  });
}
