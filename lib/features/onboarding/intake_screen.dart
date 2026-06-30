import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Placeholder conversational intake entry (MoT3 identity capture).
///
/// The full multi-step intake quiz is a later M2 feature. This is the route
/// the MoT2 welcome action lands on; it must be a coherent, reachable surface
/// that lets the user advance to completing onboarding so the landing ->
/// welcome -> intake -> done corridor stays unblocked and paywall-free
/// (L3-3, L5-5).
class IntakeScreen extends ConsumerStatefulWidget {
  const IntakeScreen({super.key});

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                label: 'Intake heading',
                child: Text(
                  'Tell me about you',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The full intake quiz is coming next. For now, you can finish '
                'onboarding and jump into your plan.',
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Semantics(
                  label: 'Intake error',
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
                excludeSemantics: true,
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
