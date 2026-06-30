import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/engine/plan_generation.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/onboarding/plan_reveal_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Conversational, multi-step intake quiz (M2).
///
/// Captures goals, training schedule (days/week), equipment (multi-select),
/// experience level, injury/limitation (optional — allows "none"), and a
/// free-text "why now". One focused question group per step with a step
/// progress indicator. Forward advances one step at a time; Back returns to
/// the prior step with answers preserved across the round trip. Required
/// steps block advancing until answered; optional steps advance when empty.
/// No paywall is ever interposed (L3-3, L5-5, L5-7).
///
/// The intake answers are persisted and the onboarding-complete flag is flipped
/// ONLY when the full flow finishes on the last step — never mid-intake, so a
/// half-built profile never leaks into the main app (VAL-ONB-055, VAL-ONB-060).
class IntakeScreen extends ConsumerStatefulWidget {
  const IntakeScreen({super.key});

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

/// The canonical step sequence. Each step declares whether an answer is
/// required to advance.
enum _IntakeStep { goals, schedule, equipment, experience, injury, whyNow }

extension _StepMeta on _IntakeStep {
  /// Number of steps in the flow (1-based ordinaling helper).
  static const count = 6;
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
  int _current = 0;

  // Answers live on the state object (never rebuilt on step change) so they
  // survive back/forward round trips.
  String? _goal;
  int? _daysPerWeek;
  final List<String> _equipment = [];
  final List<String> _experienceLevels = [];
  final List<String> _limitations = [];
  String _whyNow = '';
  late final TextEditingController _whyNowController;

  bool _submitting = false;
  String? _error;

  static const _goals = <(String id, String label)>[
    ('build_strength', 'Build strength'),
    ('get_fitter', 'Get fitter'),
    ('lose_fat', 'Lose fat'),
    ('build_muscle', 'Build muscle'),
    ('improve_mobility', 'Improve mobility'),
    ('train_for_sport', 'Train for a sport'),
  ];

  static const _scheduleDays = [2, 3, 4, 5, 6];

  static const _equipmentOptions = <(String id, String label)>[
    ('bodyweight', 'Bodyweight'),
    ('dumbbells', 'Dumbbells'),
    ('barbell', 'Barbell'),
    ('kettlebells', 'Kettlebells'),
    ('resistance_bands', 'Resistance bands'),
    ('machines', 'Machines'),
    ('cables', 'Cables'),
    ('pull_up_bar', 'Pull-up bar'),
  ];

  static const _experienceOptions = <(String id, String label)>[
    ('beginner', 'Beginner'),
    ('intermediate', 'Intermediate'),
    ('advanced', 'Advanced'),
  ];

  static const _limitationOptions = <(String id, String label)>[
    ('none', 'No limitations'),
    ('knee', 'Knee'),
    ('back', 'Back'),
    ('shoulder', 'Shoulder'),
    ('wrist', 'Wrist'),
    ('hip', 'Hip'),
    ('ankle', 'Ankle'),
  ];

  _IntakeStep get _step => _IntakeStep.values[_current];

  @override
  void initState() {
    super.initState();
    _whyNowController = TextEditingController(text: _whyNow);
  }

  @override
  void dispose() {
    _whyNowController.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    return switch (_step) {
      _IntakeStep.goals => _goal != null,
      _IntakeStep.schedule => _daysPerWeek != null,
      _IntakeStep.equipment => _equipment.isNotEmpty,
      _IntakeStep.experience => _experienceLevels.length == 1,
      _IntakeStep.injury => true,
      _IntakeStep.whyNow => true,
    };
  }

  bool get _isLast => _current == _IntakeStep.values.length - 1;

  void _goForward() {
    if (!_canAdvance || _submitting) return;
    setState(() {
      _error = null;
      _current += 1;
    });
  }

  void _goBack() {
    if (_current == 0 || _submitting) return;
    setState(() {
      _error = null;
      _current -= 1;
    });
  }

  Future<void> _finish() async {
    if (!_canAdvance || _submitting) return;
    final userId = ref.read(authFacadeProvider).currentUserId();
    if (userId == null) {
      setState(() => _error = 'No signed-in user. Please sign in again.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // Persist intake answers. The onboarding-complete flag is NOT
      // flipped here — the plan reveal screen is the next step in the
      // flow, and the user must see their plan before being released
      // into the main app (VAL-ONB-060).
      await ref.read(profileFacadeProvider).persistIntake(
            userId: userId,
            goal: _goal,
            trainingDaysPerWeek: _daysPerWeek,
            equipment: _equipment,
            experienceLevel:
                _experienceLevels.isEmpty ? null : _experienceLevels.first,
            limitations: _limitations.isEmpty ? null : _limitations,
            whyNow: _whyNow.trim().isEmpty ? null : _whyNow.trim(),
          );
      // The user has finished intake; advance them to the plan reveal so
      // they see their generated plan before being released into the main
      // app. This is the next step in the onboarding E2E flow — without it
      // the intake screen is a dead-end.
      //
      // Seed the REAL intake the user entered (goal / schedule / equipment /
      // experience / limitations) plus their "why now" phrase into the
      // pending-intake providers so the plan-reveal controller reads the
      // actual user inputs rather than a hardcoded default
      // (onboarding-data-flow.md, Controller & Test Authenticity).
      ref.read(pendingIntakeProvider.notifier).setIntake(PlanIntake(
        goal: _goal ?? 'get_fitter',
        trainingDaysPerWeek: _daysPerWeek ?? 3,
        equipment: _equipment,
        experienceLevel:
            _experienceLevels.isEmpty ? null : _experienceLevels.first,
        limitations:
            _limitations.isEmpty ? const [] : _limitations,
      ));
      ref
          .read(userWhyNowProvider.notifier)
          .setPhrase(_whyNow.trim().isEmpty ? null : _whyNow.trim());
      if (mounted) {
        context.go('/onboarding/plan-reveal');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Could not save your answers. Please try again.';
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Semantics(
                label: 'Step ${_current + 1} of ${_StepMeta.count}',
                value: '${_current + 1}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens.cornerRadius,
                      ),
                      child: LinearProgressIndicator(
                        value: (_current + 1) / _StepMeta.count,
                        backgroundColor: const Color(0xFF151515),
                        color: DigitalAtelierTokens.accentOrange,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step ${_current + 1} of ${_StepMeta.count}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildStep(theme),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_current > 0)
                    Semantics(
                      button: true,
                      label: 'Back',
                      excludeSemantics: true,
                      child: TextButton(
                        onPressed: _submitting ? null : _goBack,
                        child: const Text('Back'),
                      ),
                    ),
                  const Spacer(),
                  if (!_isLast)
                    Semantics(
                      button: true,
                      enabled: _canAdvance,
                      label: 'Next',
                      excludeSemantics: true,
                      child: ElevatedButton(
                        onPressed: _canAdvance ? _goForward : null,
                        child: const Text('Next'),
                      ),
                    )
                  else
                    Semantics(
                      button: true,
                      label: 'Finish',
                      excludeSemantics: true,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _finish,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Finish'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    return switch (_step) {
      _IntakeStep.goals => _buildSingleSelectStep(
          theme: theme,
          label: 'Goals step',
          question: 'What do you want to achieve?',
          helper: 'Pick the one that matters most right now.',
          options: _goals,
          selected: {_goal ?? ''},
          onSelected: (id) => setState(() => _goal = id),
          semanticPrefix: 'Goal: ',
        ),
      _IntakeStep.schedule => _buildScheduleStep(theme),
      _IntakeStep.equipment => _buildMultiSelectStep(
          theme: theme,
          label: 'Equipment step',
          question: 'What equipment do you have access to?',
          helper: 'Select everything that applies.',
          options: _equipmentOptions,
          selected: _equipment,
          onToggle: (id) => setState(() {
            if (_equipment.contains(id)) {
              _equipment.remove(id);
            } else {
              _equipment.add(id);
            }
          }),
          semanticPrefix: 'Equipment: ',
        ),
      _IntakeStep.experience => _buildSingleSelectStep(
          theme: theme,
          label: 'Experience step',
          question: 'What is your training experience?',
          options: _experienceOptions,
          selected: _experienceLevels.toSet(),
          onSelected: (id) => setState(() {
            _experienceLevels
              ..clear()
              ..add(id);
          }),
          semanticPrefix: 'Experience: ',
        ),
      _IntakeStep.injury => _buildMultiSelectStep(
          theme: theme,
          label: 'Injury step',
          question: 'Any injuries or movement limitations?',
          helper: 'Optional — select any that apply, or none.',
          options: _limitationOptions,
          selected: _limitations,
          onToggle: (id) => setState(() {
            if (id == 'none') {
              _limitations
                ..clear()
                ..add('none');
              return;
            }
            _limitations.remove('none');
            if (_limitations.contains(id)) {
              _limitations.remove(id);
            } else {
              _limitations.add(id);
            }
          }),
          semanticPrefix: 'Injury: ',
        ),
      _IntakeStep.whyNow => _buildWhyNowStep(theme),
    };
  }

  Widget _buildScheduleStep(ThemeData theme) {
    return Semantics(
      label: 'Training schedule step',
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: 'Schedule question',
            child: Text(
              'How many days per week can you train?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final days in _scheduleDays)
                Semantics(
                  button: true,
                  selected: _daysPerWeek == days,
                  label: 'Schedule: $days days',
                  value: '$days',
                  excludeSemantics: true,
                  child: ChoiceChip(
                    label: Text('$days days'),
                    selected: _daysPerWeek == days,
                    selectedColor: DigitalAtelierTokens.accentOrange,
                    labelStyle: TextStyle(
                      color: _daysPerWeek == days
                          ? DigitalAtelierTokens.background
                          : DigitalAtelierTokens.textPrimary,
                    ),
                    onSelected: (_) =>
                        setState(() => _daysPerWeek = days),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSelectStep({
    required ThemeData theme,
    required String label,
    required String question,
    String? helper,
    required List<(String id, String label)> options,
    required Set<String> selected,
    required ValueChanged<String> onSelected,
    required String semanticPrefix,
  }) {
    return Semantics(
      label: label,
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: '$label heading',
            child: Text(
              question,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                height: 1.2,
              ),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 8),
            Text(helper, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 24),
          Column(
            children: [
              for (final (id, text) in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    button: true,
                    selected: selected.contains(id),
                    label: '$semanticPrefix$id',
                    excludeSemantics: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: _SelectCard(
                        text: text,
                        selected: selected.contains(id),
                        onTap: () => onSelected(id),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectStep({
    required ThemeData theme,
    required String label,
    required String question,
    String? helper,
    required List<(String id, String label)> options,
    required List<String> selected,
    required ValueChanged<String> onToggle,
    required String semanticPrefix,
  }) {
    return Semantics(
      label: label,
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: '$label heading',
            child: Text(
              question,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                height: 1.2,
              ),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 8),
            Text(helper, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (id, text) in options)
                Semantics(
                  button: true,
                  selected: selected.contains(id),
                  label: '$semanticPrefix$id',
                  excludeSemantics: true,
                  child: ChoiceChip(
                    label: Text(text),
                    selected: selected.contains(id),
                    selectedColor: DigitalAtelierTokens.accentOrange,
                    labelStyle: TextStyle(
                      color: selected.contains(id)
                          ? DigitalAtelierTokens.background
                          : DigitalAtelierTokens.textPrimary,
                    ),
                    onSelected: (_) => onToggle(id),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhyNowStep(ThemeData theme) {
    return Semantics(
      label: 'Why now step',
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: 'Why now heading',
            child: Text(
              'Why now?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional. A phrase here helps me echo your words back later.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _whyNowController,
            maxLines: 4,
            onChanged: (value) => setState(() => _whyNow = value),
            decoration: const InputDecoration(
              hintText: 'e.g. I am tired of starting over every January.',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              label: 'Intake error',
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DigitalAtelierTokens.errorText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? DigitalAtelierTokens.accentOrange.withValues(alpha: 0.12)
              : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
          border: Border.all(
            color: selected
                ? DigitalAtelierTokens.accentOrange
                : const Color(0xFF2A2A2A),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected
                  ? DigitalAtelierTokens.accentOrange
                  : theme.disabledColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
