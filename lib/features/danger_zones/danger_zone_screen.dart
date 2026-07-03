import 'package:flutter/material.dart';
import 'package:transformfit/engine/danger_zone.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

/// Danger-zone screen (M8).
///
/// Shows active danger-zone warnings with severity badges and recommended
/// actions. Routes the user to the appropriate response (deload, rest, etc).
class DangerZoneScreen extends StatelessWidget {
  final DangerZoneResult result;
  final VoidCallback? onDeload;
  final VoidCallback? onRest;
  final VoidCallback? onAcknowledge;

  const DangerZoneScreen({
    super.key,
    required this.result,
    this.onDeload,
    this.onRest,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClear = result.overallSeverity == 'clear';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TransformFitBrandMark(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Safety Check', style: theme.textTheme.headlineMedium),
                      ),
                      _SeverityBadge(severity: result.overallSeverity),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isClear
                        ? 'All clear. Train on.'
                        : '${result.signals.length} signal${result.signals.length == 1 ? '' : 's'} detected.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 28),

                  if (isClear) ...[
                    const _ClearState(),
                  ] else ...[
                    // Signals
                    for (final signal in result.signals) ...[
                      _DangerSignalCard(signal: signal),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 24),

                    // Action buttons based on severity
                    if (result.overallSeverity == 'critical') ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onRest ?? onAcknowledge,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                          icon: const Icon(Icons.pause_circle),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text('Stop & Rest'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (result.signals.any((s) => s.code.contains('ACWR'))) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: onDeload ?? onAcknowledge,
                          icon: const Icon(Icons.trending_down),
                          label: const Text('Start Deload Week'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onAcknowledge,
                        child: const Text('Acknowledge & Continue'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (severity) {
      'critical' => (Colors.red.shade400, 'CRITICAL'),
      'warning' => (Colors.orange.shade400, 'WARNING'),
      'watch' => (Colors.yellow.shade700, 'WATCH'),
      'clear' => (Colors.green.shade400, 'CLEAR'),
      _ => (Colors.grey, severity.toUpperCase()),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DangerSignalCard extends StatelessWidget {
  final DangerSignal signal;

  const _DangerSignalCard({required this.signal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = switch (signal.severity) {
      'critical' => Colors.red.shade400,
      'warning' => Colors.orange.shade400,
      'watch' => Colors.yellow.shade700,
      _ => Colors.grey,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DigitalAtelierTokens.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        border: Border(
          left: BorderSide(color: severityColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: severityColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  signal.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            signal.detail,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: severityColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    signal.recommendedAction,
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.w500,
                        ),
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

class _ClearState extends StatelessWidget {
  const _ClearState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(
              Icons.shield,
              size: 56,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 16),
            Text('No danger signals', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Your workload, intensity, and consistency are\nall within safe ranges. Keep it up.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                    color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
