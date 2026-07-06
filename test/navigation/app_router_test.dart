import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/main.dart';
import 'package:transformfit/navigation/app_router.dart';
import 'package:transformfit/navigation/auth_state.dart';

void main() {
  testWidgets('Unauthenticated first open lands on value before auth', (
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
    // Landing screen has looping animations — use explicit pumps.
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.bySemanticsLabel('Coach value claim'), findsOneWidget);
    expect(find.bySemanticsLabel('Begin onboarding'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('Unauthenticated users can continue public onboarding', (
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
    final router = container.read(appRouterProvider);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TransformFitApp(),
      ),
    );
    router.go('/onboarding/welcome');
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Welcome heading'), findsOneWidget);
    expect(find.bySemanticsLabel('Begin intake'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('Unauthenticated protected routes still redirect to auth', (
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

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets(
    'Authenticated users without profile are redirected to onboarding landing',
    (tester) async {
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
      // Landing screen has looping animations — use explicit pumps.
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // The guard routes to /onboarding which redirects to /onboarding/landing.
      expect(find.bySemanticsLabel('Coach value claim'), findsOneWidget);
      expect(find.bySemanticsLabel('Begin onboarding'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
    },
  );

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
    // Shell route has tab animations — use explicit pumps.
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Profile text appears in both the bottom nav tab and the screen content.
    expect(find.text('Profile'), findsAtLeastNWidgets(1));
  });

  testWidgets('Authenticated users can access the live workout route', (
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
    router.go('/workout');
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('No live session'), findsOneWidget);
  });

  testWidgets('Authenticated users can access the proof card route', (
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
    router.go('/proof');
    await tester.pumpAndSettle();

    expect(find.text('Proof card'), findsOneWidget);
    expect(find.text('Proof begins after session 1'), findsOneWidget);
  });

  testWidgets('Authenticated users can access the progress route', (
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
    router.go('/progress');
    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('No proof yet'), findsOneWidget);
  });

  testWidgets('Authenticated users can access the composition route', (
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
    router.go('/composition');
    await tester.pumpAndSettle();

    expect(find.text('Composition trust'), findsOneWidget);
    expect(find.text('No composition signal yet'), findsOneWidget);
  });

  testWidgets('Authenticated users can access the coach command route', (
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
    router.go('/coach');
    await tester.pumpAndSettle();

    expect(find.text('Coach command'), findsOneWidget);
    expect(find.text('First command is ready'), findsOneWidget);
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
    // Landing screen has looping animations — use explicit pumps.
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.bySemanticsLabel('Coach value claim'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Today'), findsNothing);
  });
}
