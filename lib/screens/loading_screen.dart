import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: TransformFitBrandMark(
                      width: 148,
                      semanticsLabel: 'TransformFitAI loading logo',
                    ),
                  ),
                  const SizedBox(height: 22),
                  Semantics(
                    header: true,
                    child: Text(
                      'Syncing coaching state',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 34,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Checking your session, profile, and training memory.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.72,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Auth state loading',
                    child: const LinearProgressIndicator(minHeight: 4),
                  ),
                  const SizedBox(height: 18),
                  const _LoadingStatusRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingStatusRow extends StatelessWidget {
  const _LoadingStatusRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: const [
        _LoadingChip(label: 'Session'),
        _LoadingChip(label: 'Readiness'),
        _LoadingChip(label: 'Plan'),
      ],
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
