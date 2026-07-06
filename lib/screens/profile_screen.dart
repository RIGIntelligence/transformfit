import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const TransformFitBrandMark(
                            width: 132,
                            semanticsLabel: 'TransformFitAI profile logo',
                          ),
                          const Spacer(),
                          _RouteButton(
                            label: 'Today',
                            semanticLabel: 'Back to today',
                            icon: Icons.arrow_back,
                            onPressed: () => context.go('/'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Semantics(
                        header: true,
                        label: 'Profile heading',
                        child: Text(
                          'Profile',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Training memory, privacy posture, and account controls in one place.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (wide)
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ProfilePanel(
                                icon: Icons.memory_outlined,
                                title: 'Training memory',
                                value: 'Local-first session history',
                                detail:
                                    'Readiness, sets, debriefs, and proof cards stay tied to your authenticated profile.',
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _ProfilePanel(
                                icon: Icons.verified_user_outlined,
                                title: 'Privacy posture',
                                value: 'No public sharing by default',
                                detail:
                                    'Proof stays private until an explicit share flow exists and is approved.',
                              ),
                            ),
                          ],
                        )
                      else ...[
                        const _ProfilePanel(
                          icon: Icons.memory_outlined,
                          title: 'Training memory',
                          value: 'Local-first session history',
                          detail:
                              'Readiness, sets, debriefs, and proof cards stay tied to your authenticated profile.',
                        ),
                        const SizedBox(height: 16),
                        const _ProfilePanel(
                          icon: Icons.verified_user_outlined,
                          title: 'Privacy posture',
                          value: 'No public sharing by default',
                          detail:
                              'Proof stays private until an explicit share flow exists and is approved.',
                        ),
                      ],
                      const SizedBox(height: 16),
                      _ProfilePanel(
                        icon: Icons.route_outlined,
                        title: 'App routes',
                        value: 'Today, workout, progress, composition, proof',
                        detail:
                            'Jump to the core surfaces used after onboarding.',
                        trailing: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MiniRouteButton(
                              label: 'Workout',
                              icon: Icons.fitness_center,
                              onPressed: () => context.go('/workout'),
                            ),
                            _MiniRouteButton(
                              label: 'Progress',
                              icon: Icons.insights_outlined,
                              onPressed: () => context.go('/progress'),
                            ),
                            _MiniRouteButton(
                              label: 'Composition',
                              icon: Icons.verified_user_outlined,
                              onPressed: () => context.go('/composition'),
                            ),
                            _MiniRouteButton(
                              label: 'Proof',
                              icon: Icons.verified_outlined,
                              onPressed: () => context.go('/proof'),
                            ),
                          ],
                        ),
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

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          if (trailing != null) ...[const SizedBox(height: 16), trailing!],
        ],
      ),
    );
  }
}

class _RouteButton extends StatelessWidget {
  const _RouteButton({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
          ),
          minimumSize: const Size(120, 48),
        ),
      ),
    );
  }
}

class _MiniRouteButton extends StatelessWidget {
  const _MiniRouteButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size(112, 44)),
    );
  }
}
