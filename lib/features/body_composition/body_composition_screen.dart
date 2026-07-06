import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/features/body_composition/body_composition_trust.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

class BodyCompositionScreen extends ConsumerWidget {
  const BodyCompositionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionStateProvider);
    final summary = buildBodyCompositionTrustSummary(state);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: wide ? 32 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const TransformFitBrandMark(
                            width: 132,
                            semanticsLabel:
                                'TransformFitAI composition trust logo',
                          ),
                          const Spacer(),
                          Semantics(
                            button: true,
                            label: 'Return to Progress',
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/progress'),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Progress'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.28,
                                  ),
                                ),
                                minimumSize: const Size(136, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Semantics(
                        header: true,
                        label: 'Composition trust heading',
                        child: Text(
                          'Composition trust',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary.subhead,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _TrustFramePanel(summary: summary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _CoachCuePanel(summary: summary),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _TrustFramePanel(summary: summary),
                            const SizedBox(height: 16),
                            _CoachCuePanel(summary: summary),
                          ],
                        ),
                      const SizedBox(height: 16),
                      _SignalGrid(summary: summary),
                      const SizedBox(height: 16),
                      _PrivacyAndSourcePanel(summary: summary),
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

class _CompositionPanel extends StatelessWidget {
  const _CompositionPanel({
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

class _TrustFramePanel extends StatelessWidget {
  const _TrustFramePanel({required this.summary});

  final BodyCompositionTrustSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: summary.semanticLabel,
      child: _CompositionPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.insights_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.headline,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _TrustPill(label: summary.trustFrame),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'This screen does not diagnose, prescribe, or rank appearance. It explains whether a measurement has enough context to be useful.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.42),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CoachCuePanel extends StatelessWidget {
  const _CoachCuePanel({required this.summary});

  final BodyCompositionTrustSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CompositionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coach cue', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(summary.coachCue, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              border: Border(
                left: BorderSide(color: theme.colorScheme.primary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next best action',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.nextBestAction,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalGrid extends StatelessWidget {
  const _SignalGrid({required this.summary});

  final BodyCompositionTrustSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        final spacing = 16.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final signal in summary.signals)
              SizedBox(
                width: itemWidth,
                child: _SignalPanel(signal: signal),
              ),
          ],
        );
      },
    );
  }
}

class _SignalPanel extends StatelessWidget {
  const _SignalPanel({required this.signal});

  final BodyCompositionTrustSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '${signal.semanticLabel} ${signal.status}. ${signal.context}',
      child: _CompositionPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              signal.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              signal.value,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            _TrustPill(label: signal.status),
            const SizedBox(height: 12),
            Text(
              signal.context,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyAndSourcePanel extends StatelessWidget {
  const _PrivacyAndSourcePanel({required this.summary});

  final BodyCompositionTrustSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CompositionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.privacyLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.privacyDetail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Source trace', style: theme.textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sourceId in summary.sourceIds)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.12,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      sourceId,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: DigitalAtelierTokens.dataFontFamily,
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
}
