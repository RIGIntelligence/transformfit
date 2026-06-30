import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/engine/plan_generation.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
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
  const FirstSessionHandoffScreen({
    super.key,
    required this.intake,
  });

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
                    onPressed: () async {
                      final userId =
                          ref.read(authFacadeProvider).currentUserId();
                      if (userId != null) {
                        await ref
                            .read(profileFacadeProvider)
                            .completeOnboarding(userId);
                        await ref.read(authControllerProvider).refresh();
                      }
                      if (!context.mounted) return;
                      context.go('/');
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
