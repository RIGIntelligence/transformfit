import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/app_providers.dart';
import 'package:transformfit/features/auth/auth_controller.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await ref.read(authFacadeProvider).signOut();
      // The auth stream fires `signedOut` -> the guard redirects to /auth.
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _signingOut ? null : _signOut,
                  child: _signingOut
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
