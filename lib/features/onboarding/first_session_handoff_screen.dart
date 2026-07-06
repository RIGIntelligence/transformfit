import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/engine/plan_generation.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/auth/auth_service.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/onboarding/plan_reveal_controller.dart';
import 'package:transformfit/features/workout/workout_prefill.dart';
import 'package:transformfit/navigation/auth_state.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// The first-session-ready handoff (MoT4).
///
/// Renders after the plan reveal CTA. Shows the constructed first session
/// (Day 1 of the generated plan) with its exercises, all filtered by the
/// user's selected equipment (end-to-end consistency: the same equipment set
/// that shaped the plan shapes the session). A single CTA leads into the
/// session loop (the Today/home surface) with no dead-end and no paywall
/// (L5-5 corridor-is-free).
///
/// VAL-ONB-060: the onboarding-complete flag flips ONLY when the handoff CTA
/// is pressed (the final step of onboarding), so the guard keeps the user in
/// /onboarding until the full flow finishes and a half-built profile never
/// leaks into the main app.
class FirstSessionHandoffScreen extends ConsumerWidget {
  const FirstSessionHandoffScreen({super.key, required this.intake});

  /// The intake that generated the plan. Passed from the plan reveal so the
  /// handoff can deterministically reconstruct the first session without a
  /// network round-trip (offline-first, deterministic-before-agentic).
  final PlanIntake intake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Deterministic: same intake always yields the same first session. No
    // network call, no LLM, no randomness.
    final plan = generatePlan(intake);
    final session1 = plan.days.first;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading
              Semantics(
                header: true,
                label: 'Ready to train',
                excludeSemantics: true,
                child: Text(
                  'Ready to train',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: 'Handoff subheading',
                excludeSemantics: true,
                child: Text(
                  'Session 1 is built around the equipment you selected. '
                  'No guesswork, no dead-ends.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),

              // Session 1 card
              Semantics(
                label: 'Session 1 card',
                container: true,
                explicitChildNodes: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(
                      DigitalAtelierTokens.cornerRadius,
                    ),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'Session 1 heading',
                        excludeSemantics: true,
                        child: Text(
                          'Session 1 — ${session1.focus}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        label: 'Session 1 split',
                        excludeSemantics: true,
                        child: Text(
                          '${session1.exercises.length} exercises · '
                          '${plan.daysPerWeek} days/week · '
                          '${plan.goal.replaceAll('_', ' ')}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final ex in session1.exercises)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Semantics(
                            label: 'Exercise: ${ex.name}',
                            excludeSemantics: true,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: DigitalAtelierTokens.accentOrange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${ex.name} — ${ex.sets}×${ex.repsMin}-${ex.repsMax}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Equipment consistency note
              Semantics(
                label: 'Equipment consistency note',
                excludeSemantics: true,
                child: Text(
                  'Equipment: ${plan.effectiveEquipment.join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 24),

              // CTA — leads into the session loop (no dead-end, no paywall).
              // VAL-ONB-060: flip onboarding-complete HERE, at the final step
              // of onboarding, then enter the app proper.
              Semantics(
                button: true,
                label: 'Start session',
                excludeSemantics: true,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final workoutPrefill = WorkoutPrefill.fromPlanDay(
                        session1,
                      );
                      final sessionPlan = workoutPrefill.sessionExercises
                          .map(
                            (exercise) => SessionPlanExercise(
                              exerciseId: exercise.exerciseId,
                              exerciseName: exercise.exerciseName,
                              targetSets: exercise.targetSets,
                              targetReps: exercise.targetReps,
                              targetRpe: exercise.targetRpe,
                              targetRestSeconds: exercise.targetRestSeconds,
                              suggestedWeightKg: exercise.suggestedWeightKg,
                            ),
                          )
                          .toList(growable: false);
                      final sessionController = ref.read(
                        sessionControllerProvider,
                      );
                      if (sessionController.state.readinessEntry == null) {
                        sessionController.submitReadiness(
                          energyLevel: 7,
                          sleepQuality: 7,
                          // Limitations shape exercise selection; they are not
                          // evidence of today's soreness.
                          sorenessMap: const [],
                        );
                      }
                      if (sessionController.state.activeSession == null) {
                        sessionController.startSession(plan: sessionPlan);
                      } else if (sessionController
                          .state
                          .activeSessionPlan
                          .isEmpty) {
                        sessionController.attachActiveSessionPlan(sessionPlan);
                      }
                      _clearPendingOnboardingProviders(ref);
                      final userId = ref
                          .read(authFacadeProvider)
                          .currentUserId();
                      if (userId != null) {
                        final authController = ref.read(authControllerProvider);
                        final profileFacade = ref.read(profileFacadeProvider);
                        ref
                            .read(authGuardStateProvider)
                            .setStatus(
                              AuthGuardStatus.authenticatedWithProfile,
                            );
                        context.go('/workout', extra: workoutPrefill);
                        unawaited(
                          _completeRemoteOnboarding(
                            profileFacade: profileFacade,
                            authController: authController,
                            userId: userId,
                          ),
                        );
                        return;
                      }
                      context.go('/workout', extra: workoutPrefill);
                    },
                    child: const Text('Start session'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _clearPendingOnboardingProviders(WidgetRef ref) {
  ref.read(pendingIntakeProvider.notifier).clear();
  ref.read(userWhyNowProvider.notifier).clear();
}

Future<void> _completeRemoteOnboarding({
  required ProfileFacade profileFacade,
  required AuthController authController,
  required String userId,
}) async {
  try {
    await profileFacade.completeOnboarding(userId);
    await authController.refresh();
  } catch (error) {
    debugPrint(
      'first-session handoff completion sync failed: ${error.runtimeType}',
    );
  }
}
