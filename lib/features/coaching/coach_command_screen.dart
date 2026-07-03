import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/app_providers.dart';
import 'package:transformfit/features/behavior/behavioral_repair_loop.dart';
import 'package:transformfit/features/coaching/coach_command_center.dart';
import 'package:transformfit/features/emotion/emotional_experience_map.dart';
import 'package:transformfit/features/rig_systems/rig_systems_engineering.dart';
import 'package:transformfit/features/reviews/five_star_experience.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

class CoachCommandScreen extends ConsumerWidget {
  const CoachCommandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.watch(coachCommandCenterProvider);
    final repair = ref.watch(behavioralRepairLoopProvider);
    final emotion = ref.watch(emotionalExperienceMapProvider);
    final systems = ref.watch(rigSystemsEngineeringProvider);
    final reviewMoment = ref.watch(fiveStarExperienceMomentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: wide ? 32 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const TransformFitBrandMark(
                            width: 132,
                            semanticsLabel: 'TransformFitAI coach logo',
                          ),
                          const Spacer(),
                          Semantics(
                            button: true,
                            label: 'Return to Today',
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/'),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Today'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.28,
                                  ),
                                ),
                                minimumSize: const Size(120, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Coach command',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        center.headline,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ActionRail(center: center),
                      const SizedBox(height: 24),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _CommandPanel(center: center),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _HandoffPanel(center: center),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _CommandPanel(center: center),
                            const SizedBox(height: 16),
                            _HandoffPanel(center: center),
                          ],
                        ),
                      const SizedBox(height: 16),
                      _BehaviorRepairPanel(repair: repair),
                      const SizedBox(height: 16),
                      _EmotionalMapPanel(emotion: emotion),
                      const SizedBox(height: 16),
                      _FiveStarExperiencePanel(moment: reviewMoment),
                      const SizedBox(height: 16),
                      _RigSystemsPanel(systems: systems),
                      const SizedBox(height: 16),
                      _LaneGrid(center: center),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FiveStarExperiencePanel extends StatelessWidget {
  const _FiveStarExperiencePanel({required this.moment});

  final FiveStarExperienceMoment moment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: moment.semanticLabel,
      child: _CoachPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  moment.isStoreReviewEligible
                      ? Icons.rate_review_outlined
                      : Icons.verified_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trust milestone',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(moment.headline, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                _TracePill(
                  icon: Icons.source_outlined,
                  label: moment.sourceTraceLabel,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TracePill(
                  icon: Icons.fact_check_outlined,
                  label: moment.statusLabel,
                ),
                _TracePill(
                  icon: Icons.fitness_center,
                  label: moment.metricLabel,
                ),
                if (moment.lastSatisfaction != null)
                  _TracePill(
                    icon: Icons.star_border,
                    label: 'Session ${moment.lastSatisfaction}/5',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SignalLine(label: 'Why', value: moment.rationale),
            const SizedBox(height: 10),
            _SignalLine(label: 'Next', value: moment.nextAction),
            const SizedBox(height: 10),
            _SignalLine(label: 'Boundary', value: moment.safetyBoundary),
          ],
        ),
      ),
    );
  }
}

class _EmotionalMapPanel extends StatelessWidget {
  const _EmotionalMapPanel({required this.emotion});

  final EmotionalExperienceMap emotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: emotion.semanticLabel,
      child: _CoachPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emotional map',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emotion.headline,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                _TracePill(
                  icon: Icons.verified_outlined,
                  label: emotion.confidenceLabel,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TracePill(
                  icon: Icons.favorite_border,
                  label: emotion.stage.label,
                ),
                _TracePill(
                  icon: Icons.psychology_outlined,
                  label: emotion.primaryFeeling,
                ),
                _TracePill(
                  icon: Icons.source_outlined,
                  label: emotion.sourceTraceLabel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SignalLine(label: 'Promise', value: emotion.emotionalPromise),
            const SizedBox(height: 10),
            _SignalLine(label: 'Next', value: emotion.nextExperience),
            const SizedBox(height: 10),
            _SignalLine(label: 'Avoid', value: emotion.riskToAvoid),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final vector in emotion.vectors)
                      SizedBox(
                        width: wide
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: _EmotionVectorCard(vector: vector),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionVectorCard extends StatelessWidget {
  const _EmotionVectorCard({required this.vector});

  final EmotionalExperienceVector vector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vector.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(vector.state, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(vector.designResponse, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _BehaviorRepairPanel extends StatelessWidget {
  const _BehaviorRepairPanel({required this.repair});

  final BehavioralRepairLoop repair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: repair.semanticLabel,
      child: _CoachPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Behavior repair',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(repair.headline, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                _TracePill(
                  icon: Icons.verified_outlined,
                  label: repair.confidenceLabel,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TracePill(
                  icon: Icons.route_outlined,
                  label: repair.mode.label,
                ),
                _TracePill(
                  icon: Icons.source_outlined,
                  label: repair.sourceTraceLabel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _RepairCell(
                      width: wide
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      label: 'Need',
                      value: repair.emotionalNeed,
                    ),
                    _RepairCell(
                      width: wide
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      label: 'Friction',
                      value: repair.friction,
                    ),
                    _RepairCell(
                      width: wide
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      label: 'Next repair',
                      value: repair.repairAction,
                    ),
                    _RepairCell(
                      width: wide
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      label: 'Proof',
                      value: repair.proof,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _SignalLine(label: 'Boundary', value: repair.safetyBoundary),
          ],
        ),
      ),
    );
  }
}

class _RepairCell extends StatelessWidget {
  const _RepairCell({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(
            DigitalAtelierTokens.cornerRadius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _RigSystemsPanel extends StatelessWidget {
  const _RigSystemsPanel({required this.systems});

  final RigSystemsEngineeringSnapshot systems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: systems.semanticLabel,
      child: _CoachPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RIG systems',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        systems.selectedArchetype.label,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                _TracePill(
                  icon: Icons.speed_outlined,
                  label: 'BMS ${systems.bmsLabel}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TracePill(icon: Icons.hub_outlined, label: systems.coordinate),
                _TracePill(
                  icon: Icons.warning_amber_outlined,
                  label: systems.killSwitch,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Triple Double Diamond', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 840;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final diamond in RigDiamond.values)
                      SizedBox(
                        width: wide
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth,
                        child: _DiamondSummary(
                          diamond: diamond,
                          cells: systems.cellsForDiamond(diamond).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final archetype in systems.archetypes)
                      SizedBox(
                        width: wide
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: _BuildModeCard(archetype: archetype),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DiamondSummary extends StatelessWidget {
  const _DiamondSummary({required this.diamond, required this.cells});

  final RigDiamond diamond;
  final List<RigDiamondCell> cells;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proofCell = cells.firstWhere(
      (cell) => cell.step == RigProcessStep.proof,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diamond.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${cells.length} IQRSQPI cells',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(proofCell.coordinate, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _BuildModeCard extends StatelessWidget {
  const _BuildModeCard({required this.archetype});

  final RigBuildModeArchetype archetype;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            archetype.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(archetype.bmsRange, style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(archetype.decisionPath, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(archetype.guardrail, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({required this.center});

  final CoachCommandCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _CommandButton(
          label: 'Today',
          semanticLabel: 'Open Today',
          icon: Icons.today_outlined,
          route: '/',
          theme: theme,
        ),
        _CommandButton(
          label: 'Live logger',
          semanticLabel: 'Open live workout logger',
          icon: Icons.fitness_center,
          route: '/workout',
          theme: theme,
        ),
        _CommandButton(
          label: 'Progress',
          semanticLabel: 'Open progress',
          icon: Icons.insights_outlined,
          route: '/progress',
          theme: theme,
        ),
        _CommandButton(
          label: 'Composition',
          semanticLabel: 'Open composition trust',
          icon: Icons.verified_user_outlined,
          route: '/composition',
          theme: theme,
        ),
      ],
    );
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.route,
    required this.theme,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final String route;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: OutlinedButton.icon(
        onPressed: () => context.go(route),
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          minimumSize: const Size(144, 48),
        ),
      ),
    );
  }
}

class _CommandPanel extends StatelessWidget {
  const _CommandPanel({required this.center});

  final CoachCommandCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: center.semanticLabel,
      child: _CoachPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.psychology_alt_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily command',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        center.primaryAction,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SignalLine(label: 'Reason', value: center.commandReason),
            const SizedBox(height: 10),
            _SignalLine(label: 'Boundary', value: center.safetyBoundary),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TracePill(
                  icon: Icons.shield_outlined,
                  label: center.riskLabel,
                ),
                _TracePill(
                  icon: Icons.verified_outlined,
                  label: center.confidenceLabel,
                ),
                _TracePill(
                  icon: Icons.source_outlined,
                  label: center.sourceTraceLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HandoffPanel extends StatelessWidget {
  const _HandoffPanel({required this.center});

  final CoachCommandCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CoachPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coach handoff', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(center.handoffSummary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          Text(
            'Next 24 hours',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < center.next24Hours.length; index += 1)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == center.next24Hours.length - 1 ? 0 : 10,
              ),
              child: _NumberedStep(
                number: index + 1,
                text: center.next24Hours[index],
              ),
            ),
        ],
      ),
    );
  }
}

class _LaneGrid extends StatelessWidget {
  const _LaneGrid({required this.center});

  final CoachCommandCenter center;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final lane in center.lanes)
              SizedBox(
                width: wide
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth,
                child: _LaneCard(lane: lane),
              ),
          ],
        );
      },
    );
  }
}

class _LaneCard extends StatelessWidget {
  const _LaneCard({required this.lane});

  final CoachCommandLane lane;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: lane.semanticLabel,
      child: _CoachPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lane.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(lane.status, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(lane.detail, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            _SignalLine(label: 'Next', value: lane.nextAction),
            const SizedBox(height: 10),
            _TracePill(
              icon: Icons.source_outlined,
              label: lane.sourceTraceLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachPanel extends StatelessWidget {
  const _CoachPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: child,
    );
  }
}

class _SignalLine extends StatelessWidget {
  const _SignalLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.72),
            ),
            borderRadius: BorderRadius.circular(
              DigitalAtelierTokens.cornerRadius,
            ),
          ),
          child: Text(
            number.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _TracePill extends StatelessWidget {
  const _TracePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 34, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
