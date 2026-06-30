import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// M1 onboarding surface.
///
/// The full conversational intake is M2; M1 only needs the route guard to land
/// an authenticated-but-onboarding-incomplete user here (VAL-FND-019 /
/// VAL-AUTH-025) and to provide a reachable, E2E-testable way to flip the
/// profile's `onboarding_completed` flag so the guard releases the user to the
/// main app.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _completing = false;
  String? _error;

  Future<void> _finishOnboarding() async {
    if (_completing) return;
    final userId = ref.read(authFacadeProvider).currentUserId();
    if (userId == null) {
      setState(() => _error = 'No signed-in user. Please sign in again.');
      return;
    }
    setState(() {
      _completing = true;
      _error = null;
    });
    try {
      await ref.read(profileFacadeProvider).completeOnboarding(userId);
      // Re-resolve the profile so the guard moves to authenticatedWithProfile.
      await ref.read(authControllerProvider).refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _completing = false;
          _error = 'Could not save onboarding. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Finish onboarding to access your training plan.'),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Semantics(
                  label: 'Onboarding error',
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: DigitalAtelierTokens.errorText,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Semantics(
                button: true,
                label: 'Finish onboarding',
                child: ElevatedButton(
                  onPressed: _completing ? null : _finishOnboarding,
                  child: _completing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Finish onboarding'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
