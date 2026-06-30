import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/main.dart';
import 'package:transformfit/navigation/app_router.dart';
import 'package:transformfit/navigation/auth_state.dart';

void main() {
  testWidgets('Unauthenticated users are redirected to /auth', (tester) async {
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
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('Authenticated users without profile are redirected to onboarding', (
    tester,
  ) async {
    final authState = AuthGuardState(
      initialStatus: AuthGuardStatus.authenticatedNoProfile,
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
    await tester.pumpAndSettle();

    expect(find.text('Onboarding'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('Unknown route resolves to controlled fallback', (tester) async {
    final authState = AuthGuardState(
      initialStatus: AuthGuardStatus.authenticatedWithProfile,
    );
    final container = ProviderContainer(
      overrides: [
        authGuardStateProvider.overrideWithValue(authState),
        authControllerProvider.overrideWithValue(AuthController.noop()),
      ],
    );
    final router = container.read(appRouterProvider);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TransformFitApp(),
      ),
    );
    router.go('/unknown-route');
    await tester.pumpAndSettle();

    expect(find.text('Not found'), findsOneWidget);
  });

  testWidgets('Authenticated users can access protected non-root routes', (
    tester,
  ) async {
    final authState = AuthGuardState(
      initialStatus: AuthGuardStatus.authenticatedWithProfile,
    );
    final container = ProviderContainer(
      overrides: [
        authGuardStateProvider.overrideWithValue(authState),
        authControllerProvider.overrideWithValue(AuthController.noop()),
      ],
    );
    final router = container.read(appRouterProvider);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TransformFitApp(),
      ),
    );
    router.go('/profile');
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Guard resolves before protected content paints for no session', (
    tester,
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

    expect(find.text('Today'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });
}
