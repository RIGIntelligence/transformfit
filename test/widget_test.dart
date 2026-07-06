import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/main.dart';
import 'package:transformfit/navigation/auth_state.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

void main() {
  testWidgets('App mounts value-before-auth landing when unauthenticated', (
    WidgetTester tester,
  ) async {
    final authState = AuthGuardState(
      initialStatus: AuthGuardStatus.unauthenticated,
    );
    final container = ProviderContainer(
      overrides: [
        authGuardStateProvider.overrideWithValue(authState),
        authControllerProvider.overrideWithValue(AuthController.noop()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TransformFitApp(),
      ),
    );
    // Landing screen has looping animations — use explicit pumps.
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(
      find.bySemanticsLabel(TransformFitBrandMark.defaultSemanticsLabel),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Coach value claim'), findsOneWidget);
    expect(find.bySemanticsLabel('Begin onboarding'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Sign in to existing account'),
      findsOneWidget,
    );
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Today'), findsNothing);
  });
}
