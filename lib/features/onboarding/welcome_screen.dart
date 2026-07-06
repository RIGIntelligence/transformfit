import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

/// MoT2 — Install to first open.
///
/// A zero-friction welcome surface that offers a single, clear first meaningful
/// action. Per L3-3 the first meaningful action must be reachable with no
/// payment gate. The full conversational intake is wired by a later M2 feature;
/// this screen is the entry point that gets the user from "I just opened the
/// app" to "I'm telling the coach about me".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _body =
      'Tell me how you train, what you have available, and what you want. It '
      'takes a couple of minutes and I will build your first week around it.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TransformFitBrandMark(width: 176),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                label: 'Welcome heading',
                excludeSemantics: true,
                child: Text('Welcome', style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 16),
              Text(_body, style: theme.textTheme.bodyLarge),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Begin intake',
                excludeSemantics: true,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // The intake quiz is wired by the next M2 feature. The
                    // action is real (enabled) and routes to the intake entry
                    // point so this is not a dead-end.
                    onPressed: () => context.go('/onboarding/intake'),
                    child: const Text('Begin intake'),
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
