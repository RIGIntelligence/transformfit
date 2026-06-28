import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/navigation/auth_state.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

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
                label: 'Auth heading',
                child: Text(
                  'Auth',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Sign in or create an account to continue.'),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Complete sign in',
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(authGuardStateProvider)
                        .setStatus(AuthGuardStatus.authenticatedNoProfile);
                  },
                  child: const Text('Complete sign in'),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'Go to onboarding',
                child: TextButton(
                  onPressed: () => context.go('/onboarding'),
                  child: const Text('Go to onboarding'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
