import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore_for_file: use_build_context_synchronously
import 'package:go_router/go_router.dart';
import 'package:transformfit/engine/plan_generation.dart';
import 'package:transformfit/features/onboarding/plan_reveal_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// The plan/projection reveal screen (M2).
///
/// Renders after intake. The generated plan reflects the user's equipment,
/// schedule, experience, injury, and goal. Coach copy echoes a user phrase
/// (emoji/markup sanitized), obeys the message rules (<=60 words, no emoji,
/// no generic encouragement, >=1 data token, <=1 question), follows
/// Ask->Research->Give, maps the full 7-beat emotional arc, and shows a
/// surfaced deterministic fallback if the narration LLM fails. No paywall
/// appears (Noom anti-pattern guard).
class PlanRevealScreen extends ConsumerStatefulWidget {
  const PlanRevealScreen({super.key});

  @override
  ConsumerState<PlanRevealScreen> createState() => _PlanRevealScreenState();
}

class _PlanRevealScreenState extends ConsumerState<PlanRevealScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planRevealControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _buildError(theme),
          data: (s) => _buildContent(context, theme, s),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Semantics(
      label: 'Plan reveal error',
      excludeSemantics: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong generating your plan. Please try again.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, PlanRevealState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 7-beat arc ---
          // Beat 1: Arrival
          Semantics(
            label: 'Arrival beat',
            excludeSemantics: true,
            child: Text(
              'Your first week',
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),

          // Beat 2: Grounding — restate the user's situation/inputs
          Semantics(
            label: 'Grounding beat',
            excludeSemantics: true,
            child: Text(
              'Based on what you told me — '
              '${state.plan.daysPerWeek} days a week, '
              '${state.plan.goal.replaceAll('_', ' ')} goal'
              '${state.plan.effectiveEquipment.contains('bodyweight') && state.plan.effectiveEquipment.length == 1 ? ', bodyweight only' : ''}.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),

          // Beat 3: Recognition — acknowledge the user's why/constraints
          Semantics(
            label: 'Recognition beat',
            excludeSemantics: true,
            child: Text(
              state.echoedPhrase != null && state.echoedPhrase!.isNotEmpty
                  ? 'You said "${state.echoedPhrase}" — that is the through-line here.'
                  : 'I heard what matters to you. This plan is built around it.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),

          // Beat 4: Highlight — the tailored plan as centerpiece
          Semantics(
            label: 'Highlight beat',
            container: true,
            explicitChildNodes: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your plan', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Plan reveal body',
                  container: true,
                  explicitChildNodes: true,
                  child: Column(
                    children: [
                      for (final day in state.plan.days)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanDayCard(day: day),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Beat 5: Reflection — how the plan fits the user's life
          Semantics(
            label: 'Reflection beat',
            excludeSemantics: true,
            child: Text(
              'This fits your schedule and equipment so you can start without '
              'overthinking it. The numbers come from your inputs — nothing is '
              'hardcoded.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),

          // Beat 6: Forward — point to the first session
          Semantics(
            label: 'Forward beat',
            excludeSemantics: true,
            child: Text(
              'Your first session is ready when you are.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),

          // Beat 7: CTA — explicit "start session 1" action. Leads into the
          // first-session handoff (MoT4) — never a dead-end, never a paywall.
          //
          // VAL-ONB-060: the onboarding-complete flag is NOT flipped here.
          // It flips only after the handoff CTA, so the guard keeps the user
          // in /onboarding for the handoff and the flag is true only after
          // the full flow finishes.
          Semantics(
            label: 'CTA beat',
            container: true,
            explicitChildNodes: true,
            child: _StartSessionButton(
              onPressed: () {
                // Navigate to the handoff, passing the intake so the first
                // session is reconstructed deterministically (offline-first).
                GoRouter.of(context).go(
                  '/onboarding/handoff',
                  extra: state.intake,
                );
              },
            ),
          ),

          // --- Ask -> Research -> Give structure (VAL-ONB-037) ---
          const SizedBox(height: 24),
          Semantics(
            label: 'Ask phase',
            excludeSemantics: true,
            child: Text(
              'What you asked for: ${state.plan.goal.replaceAll('_', ' ')}, '
              '${state.plan.daysPerWeek} days/week.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: 'Research phase',
            excludeSemantics: true,
            child: Text(
              'What I considered: your equipment, experience, and any limitations.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: 'Give phase',
            excludeSemantics: true,
            child: Text(
              'What you get: a ${state.plan.daysPerWeek}-day plan with '
              '${state.plan.totalExercises} exercises tailored to you.',
              style: theme.textTheme.bodySmall,
            ),
          ),

          // --- Coach copy (echo + message rules) ---
          const SizedBox(height: 24),
          Semantics(
            label: 'Plan headline',
            excludeSemantics: true,
            child: Text(
              state.headline,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Plan reasoning',
            excludeSemantics: true,
            child: Text(
              state.reasoning,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.coachingCue,
            style: theme.textTheme.bodyMedium,
          ),

          // --- Fallback indicator (VAL-ONB-058) ---
          if (state.isFallback) ...[
            const SizedBox(height: 16),
            Semantics(
              label: 'Fallback indicator',
              excludeSemantics: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Text(
                  'Narration is a deterministic fallback (model: ${state.modelUsed}). '
                  'The plan above is complete and ready.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "Start session 1" CTA button, extracted so it can use `ref` from the
/// [ConsumerState] without nesting closures inside `_buildContent`.
class _StartSessionButton extends ConsumerWidget {
  const _StartSessionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Start session 1',
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          child: const Text('Start session 1'),
        ),
      ),
    );
  }
}

class _PlanDayCard extends StatelessWidget {
  const _PlanDayCard({required this.day});

  final PlanDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Day ${day.dayNumber} — ${day.focus}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
            ),
          ),
          const SizedBox(height: 6),
          for (final e in day.exercises)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${e.name} — ${e.sets} x ${e.repsMin}-${e.repsMax}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
