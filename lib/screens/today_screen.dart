import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/app_providers.dart';
import 'package:transformfit/theme/digital_atelier.dart';

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
              Text(
                'Today',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                coachNote,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
