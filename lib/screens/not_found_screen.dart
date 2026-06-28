import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

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
                label: 'Not found heading',
                child: Text(
                  'Not found',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              const Text('The route you entered does not exist.'),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Go to auth',
                child: ElevatedButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text('Go to auth'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
