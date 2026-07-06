import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/features/proof/proof_card.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

class ProofCardScreen extends ConsumerStatefulWidget {
  const ProofCardScreen({super.key});

  @override
  ConsumerState<ProofCardScreen> createState() => _ProofCardScreenState();
}

class _ProofCardScreenState extends ConsumerState<ProofCardScreen> {
  bool _copyApproved = false;

  Future<void> _copyProofText(ProofCardSummary summary) async {
    await Clipboard.setData(ClipboardData(text: summary.shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proof text copied. You choose where it goes.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionStateProvider);
    final summary = buildProofCardSummary(state);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: wide ? 32 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 940),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const TransformFitBrandMark(
                            width: 132,
                            semanticsLabel: 'TransformFitAI proof logo',
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
                      Text('Proof card', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Body-neutral proof for the work that actually happened.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ProofShareCard(summary: summary),
                      const SizedBox(height: 20),
                      _SharePreview(summary: summary),
                      const SizedBox(height: 20),
                      _ProofPrivacyControls(
                        summary: summary,
                        approved: _copyApproved,
                        onApprovedChanged: summary.readyToShare
                            ? (value) => setState(() => _copyApproved = value)
                            : null,
                        onCopy: summary.readyToShare && _copyApproved
                            ? () => _copyProofText(summary)
                            : null,
                      ),
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

class _ProofShareCard extends StatelessWidget {
  const _ProofShareCard({required this.summary});

  final ProofCardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: summary.semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(
            DigitalAtelierTokens.cornerRadius,
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.42),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    summary.readyToShare
                        ? Icons.verified_outlined
                        : Icons.hourglass_empty,
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
                        const SizedBox(height: 6),
                        Text(
                          summary.subhead,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _MetricGrid(metrics: summary.metrics),
              const SizedBox(height: 20),
              _ProofLine(label: 'Top set', value: summary.topSet),
              const SizedBox(height: 10),
              _ProofLine(label: 'Next focus', value: summary.nextFocus),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Body-neutral. Readiness-aware. Built from completed work.',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.74,
                        ),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<ProofMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        for (final metric in metrics)
          SizedBox(width: 128, child: _MetricColumn(metric: metric)),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.metric});

  final ProofMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '${metric.label}: ${metric.spokenValue}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofLine extends StatelessWidget {
  const _ProofLine({required this.label, required this.value});

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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SharePreview extends StatelessWidget {
  const _SharePreview({required this.summary});

  final ProofCardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Proof card share preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share preview',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            summary.shareText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofPrivacyControls extends StatelessWidget {
  const _ProofPrivacyControls({
    required this.summary,
    required this.approved,
    required this.onApprovedChanged,
    required this.onCopy,
  });

  final ProofCardSummary summary;
  final bool approved;
  final ValueChanged<bool>? onApprovedChanged;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label:
          'Proof sharing controls. ${summary.sharePrivacySummary} Copy requires opt-in.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(
            DigitalAtelierTokens.cornerRadius,
          ),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Private by default',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.sharePrivacySummary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.76,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final redaction in summary.shareRedactions)
                    _PrivacyChip(label: redaction),
                ],
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  value: approved,
                  onChanged: onApprovedChanged == null
                      ? null
                      : (value) => onApprovedChanged!(value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    summary.shareConsentLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  enabled: onCopy != null,
                  label: 'Copy redacted proof text',
                  child: ElevatedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.content_copy_outlined),
                    label: const Text('Copy proof text'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
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

class _PrivacyChip extends StatelessWidget {
  const _PrivacyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
