import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// MoT1 — Acquisition to first belief.
///
/// The landing / acquisition surface. Per L3-2 it must convey a coach-specific
/// value claim ("a coach who already noticed me") BEFORE any feature stack,
/// and show a readiness preview that demonstrates personalization intent at
/// first touch. There is no payment gate anywhere near this surface
/// (L3-3 / L5-5 / L5-7 — corridor-is-free).
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _valueClaim =
      'A coach who already noticed you — and adjusted the plan before your '
      'first rep.';
  static const _readinessPreviewBody =
      'Tomorrow it checks how you slept, how your body feels, and what you '
      'have available — then reshapes today so you can actually do it.';
  static const _featureReadiness = 'Readiness-adjusted daily plan';
  static const _featureCoachVoice = 'Coach-voice narration, not notifications';
  static const _featureProgression = 'Progression that reacts to your body';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                label: 'Coach value claim',
                excludeSemantics: true,
                child: Text(
                  _valueClaim,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                label: 'Readiness preview',
                excludeSemantics: true,
                child: _PreviewCard(
                  body: _readinessPreviewBody,
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                label: 'Feature stack heading',
                excludeSemantics: true,
                child: Text(
                  'What you get',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Feature stack',
                excludeSemantics: true,
                container: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FeatureItem(text: _featureReadiness),
                    const SizedBox(height: 8),
                    _FeatureItem(text: _featureCoachVoice),
                    const SizedBox(height: 8),
                    _FeatureItem(text: _featureProgression),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Semantics(
                button: true,
                label: 'Begin onboarding',
                excludeSemantics: true,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/onboarding/welcome'),
                    child: const Text('Begin'),
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        border: Border.all(
          color: DigitalAtelierTokens.accentOrange,
          width: 1,
        ),
      ),
      child: Text(
        body,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle,
            size: 18,
            color: DigitalAtelierTokens.accentOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
