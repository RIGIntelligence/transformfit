import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/engine/danger_zone.dart';
import 'package:transformfit/engine/plan_generation.dart';
import 'package:transformfit/features/body_composition/body_composition_screen.dart';
import 'package:transformfit/features/coaching/coach_command_screen.dart';
import 'package:transformfit/features/coaching/coach_consistency_screen.dart';
import 'package:transformfit/features/danger_zones/danger_zone_screen.dart';
import 'package:transformfit/features/debrief/debrief_screen.dart';
import 'package:transformfit/features/trends/recommit_screen.dart';
import 'package:transformfit/features/trends/trends_screen.dart';
import 'package:transformfit/features/onboarding/first_session_handoff_screen.dart';
import 'package:transformfit/features/onboarding/intake_screen.dart';
import 'package:transformfit/features/onboarding/landing_screen.dart';
import 'package:transformfit/features/onboarding/plan_reveal_screen.dart';
import 'package:transformfit/features/onboarding/welcome_screen.dart';
import 'package:transformfit/features/progress/progress_screen.dart';
import 'package:transformfit/features/proof/proof_card_screen.dart';
import 'package:transformfit/features/workout/active_workout_screen.dart';
import 'package:transformfit/features/workout/workout_prefill.dart';
import 'package:transformfit/navigation/auth_state.dart';
import 'package:transformfit/screens/auth_screen.dart';
import 'package:transformfit/screens/loading_screen.dart';
import 'package:transformfit/screens/not_found_screen.dart';
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
        path: '/workout',
        name: 'workout',
        builder: (context, state) {
          final extra = state.extra;
          return ActiveWorkoutScreen(
            initialPrefill: extra is WorkoutPrefill ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/proof',
        name: 'proof',
        builder: (context, state) => const ProofCardScreen(),
      ),
      GoRoute(
        path: '/progress',
        name: 'progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/composition',
        name: 'composition',
        builder: (context, state) => const BodyCompositionScreen(),
      ),
      GoRoute(
        path: '/coach',
        name: 'coach-command',
        builder: (context, state) => const CoachCommandScreen(),
      ),
      GoRoute(
        path: '/coach-consistency',
        name: 'coach-consistency',
        builder: (context, state) => const CoachConsistencyScreen(),
      ),
      GoRoute(
        path: '/debrief',
        name: 'debrief',
        builder: (context, state) => const DebriefScreen(),
      ),
      GoRoute(
        path: '/trends',
        name: 'trends',
        builder: (context, state) => const TrendsScreen(),
      ),
      GoRoute(
        path: '/recommit',
        name: 'recommit',
        builder: (context, state) => const RecommitScreen(),
      ),
      GoRoute(
        path: '/safety',
        name: 'safety',
        builder: (context, state) => const DangerZoneScreen(
          result: DangerZoneResult(signals: [], overallSeverity: 'clear'),
        ),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        redirect: (context, state) {
          // The M2 onboarding flow starts at the landing surface; the bare
          // /onboarding path always forwards there so deep links and the
          // auth guard resolve to a coherent first screen. Only redirect the
          // exact /onboarding path, not its sub-routes.
          if (state.uri.path == '/onboarding') {
            return '/onboarding/landing';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'landing',
            name: 'onboarding-landing',
            builder: (context, state) => const LandingScreen(),
          ),
          GoRoute(
            path: 'welcome',
            name: 'onboarding-welcome',
            builder: (context, state) => const WelcomeScreen(),
          ),
          GoRoute(
            path: 'intake',
            name: 'onboarding-intake',
            builder: (context, state) => const IntakeScreen(),
          ),
          GoRoute(
            path: 'plan-reveal',
            name: 'onboarding-plan-reveal',
            builder: (context, state) => const PlanRevealScreen(),
          ),
          GoRoute(
            path: 'handoff',
            name: 'onboarding-handoff',
            builder: (context, state) {
              // The intake is passed from the plan reveal CTA via
              // `extra`. Fall back to a deterministic default so deep links
              // and tests still render a coherent first session.
              final extra = state.extra;
              final intake = extra is PlanIntake
                  ? extra
                  : const PlanIntake(
                      goal: 'get_fitter',
                      trainingDaysPerWeek: 3,
                      equipment: ['bodyweight'],
                      experienceLevel: 'intermediate',
                    );
              return FirstSessionHandoffScreen(intake: intake);
            },
          ),
        ],
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
      final inOnboarding =
          location == '/onboarding' || location.startsWith('/onboarding/');
      final isPublicFirstValueRoute = location == '/auth' || inOnboarding;

      if (status == AuthGuardStatus.loading) {
        return location == '/loading' ? null : '/loading';
      }

      if (status == AuthGuardStatus.unauthenticated) {
        if (isPublicFirstValueRoute) {
          return null;
        }
        if (location == '/' || location == '/loading') {
          return '/onboarding';
        }
        return '/auth';
      }

      if (status == AuthGuardStatus.authenticatedNoProfile) {
        return inOnboarding ? null : '/onboarding';
      }

      if (location == '/auth' || inOnboarding || location == '/loading') {
        return '/';
      }

      return null;
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
