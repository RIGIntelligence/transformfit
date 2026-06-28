import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/navigation/auth_state.dart';
import 'package:transformfit/screens/auth_screen.dart';
import 'package:transformfit/screens/loading_screen.dart';
import 'package:transformfit/screens/not_found_screen.dart';
import 'package:transformfit/screens/onboarding_screen.dart';
import 'package:transformfit/screens/profile_screen.dart';
import 'package:transformfit/screens/today_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authGuardStateProvider);

  return GoRouter(
    refreshListenable: authState,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'today',
        builder: (context, state) => const TodayScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    redirect: (context, state) {
      final status = authState.status;
      final location = state.matchedLocation;

      if (status == AuthGuardStatus.loading) {
        return location == '/loading' ? null : '/loading';
      }

      if (status == AuthGuardStatus.unauthenticated) {
        return location == '/auth' ? null : '/auth';
      }

      if (status == AuthGuardStatus.authenticatedNoProfile) {
        return location == '/onboarding' ? null : '/onboarding';
      }

      if (location == '/auth' || location == '/onboarding' || location == '/loading') {
        return '/';
      }

      return null;
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
