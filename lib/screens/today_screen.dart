import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/app_providers.dart';
import 'package:transformfit/navigation/auth_state.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachNote = ref.watch(coachNoteProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                label: 'Today heading',
                child: Text(
                  'Today',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Coach note',
                child: Text(
                  coachNote,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Start today session',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Start session'),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'Open profile',
                child: TextButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text('Open profile'),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'Sign out',
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(authGuardStateProvider)
                        .setStatus(AuthGuardStatus.unauthenticated);
                  },
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
