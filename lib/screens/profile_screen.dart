import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                label: 'Profile heading',
                child: Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              const Text('This is a URL-addressable protected profile route.'),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Back to today',
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to today'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
