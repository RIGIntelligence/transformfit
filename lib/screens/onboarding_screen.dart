import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/navigation/auth_state.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                label: 'Onboarding heading',
                child: Text(
                  'Onboarding',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Finish onboarding to access your training plan.'),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Finish onboarding',
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(authGuardStateProvider)
                        .setStatus(AuthGuardStatus.authenticatedWithProfile);
                  },
                  child: const Text('Finish onboarding'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
