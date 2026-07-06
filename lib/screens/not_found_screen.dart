import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 40 : 20,
                  vertical: wide ? 32 : 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TransformFitBrandMark(
                        width: 132,
                        semanticsLabel: 'TransformFitAI not found logo',
                      ),
                      const SizedBox(height: 28),
                      Semantics(
                        header: true,
                        label: 'Not found heading',
                        child: Text(
                          'Not found',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'That route is outside the current training flow.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.12,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(
                            DigitalAtelierTokens.cornerRadius,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.route_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Recover the session path',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use a known route to keep the app in a protected, testable state.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _RouteAction(
                                  label: 'Today',
                                  semanticLabel: 'Go to today',
                                  icon: Icons.today_outlined,
                                  onPressed: () => context.go('/'),
                                ),
                                _RouteAction(
                                  label: 'Workout',
                                  semanticLabel: 'Go to workout',
                                  icon: Icons.fitness_center,
                                  onPressed: () => context.go('/workout'),
                                ),
                                _RouteAction(
                                  label: 'Auth',
                                  semanticLabel: 'Go to auth',
                                  icon: Icons.login,
                                  onPressed: () => context.go('/auth'),
                                ),
                              ],
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

class _RouteAction extends StatelessWidget {
  const _RouteAction({
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
    return Semantics(
      button: true,
      label: semanticLabel,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(minimumSize: const Size(112, 44)),
      ),
    );
  }
}
