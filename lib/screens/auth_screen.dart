import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/config/runtime_flags.dart';
import 'package:transformfit/dev/visual_smoke_state.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/auth/auth_service.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/navigation/auth_state.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

/// Email/password authentication surface wired to Supabase GoTrue.
///
/// Surfaces explicit errors for wrong password, unregistered email, duplicate
/// email, invalid email domain, and sub-minimum password. Every interactive or
/// asserted element carries a meaningful [Semantics] label per the convention.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.localDemoEntryEnabled = transformfitAuthScreenDemoEntryEnabled,
  });

  final bool localDemoEntryEnabled;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthMode { signIn, signUp }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;
  bool _submitting = false;
  String? _error;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode next) {
    if (_mode == next) return;
    setState(() {
      _mode = next;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final facade = ref.read(authFacadeProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final AuthResult result;
    if (_mode == _AuthMode.signUp) {
      result = await facade.signUp(email: email, password: password);
    } else {
      result = await facade.signIn(email: email, password: password);
    }

    if (!mounted) return;

    if (result.isSuccess) {
      // The auth state stream drives the route guard; routing is handled by
      // the guard redirect (to /onboarding or /). No manual navigation here.
      setState(() => _submitting = false);
      return;
    }

    setState(() {
      _submitting = false;
      _error = result.userMessage ?? 'Something went wrong. Please try again.';
    });
  }

  void _openLocalDemoSession() {
    if (!widget.localDemoEntryEnabled) return;
    ref.read(sessionControllerProvider).restore(buildVisualSmokeSessionState());
    ref
        .read(authGuardStateProvider)
        .setStatus(AuthGuardStatus.authenticatedWithProfile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSignIn = _mode == _AuthMode.signIn;
    final submitLabel = isSignIn ? 'Sign in' : 'Sign up';
    final switchLabel = isSignIn ? 'Switch to sign up' : 'Switch to sign in';
    final switchPrompt = isSignIn
        ? "Don't have an account? Sign up"
        : 'Already have an account? Sign in';

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final short = constraints.maxHeight < 680;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 32,
                vertical: short ? 16 : (compact ? 28 : 40),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      (short ? 32 : (compact ? 56 : 80)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: TransformFitBrandMark(
                                width: short ? 112 : (compact ? 164 : 192),
                                semanticsLabel: 'TransformFitAI logo',
                              ),
                            ),
                            SizedBox(height: short ? 10 : 18),
                            Text(
                              'TransformFitAI',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: short ? 8 : 14),
                            Semantics(
                              header: true,
                              child: Text(
                                isSignIn
                                    ? 'Welcome back'
                                    : 'Create your account',
                                style: theme.textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: short ? 6 : 8),
                            Text(
                              isSignIn
                                  ? 'Sign in to continue your readiness-adjusted training.'
                                  : 'Create the account that keeps your plan, debriefs, and coaching memory together.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: short ? 14 : 20),
                            if (!short) ...[
                              const _AuthSignalStrip(),
                              const SizedBox(height: 24),
                            ],
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.com',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const ['email'],
                              textInputAction: TextInputAction.next,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                              ),
                              obscureText: true,
                              autofillHints: const ['password'],
                              textInputAction: TextInputAction.done,
                              validator: _validatePassword,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 16),
                            if (_error != null) ...[
                              Semantics(
                                container: true,
                                liveRegion: true,
                                child: Text(
                                  _error!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: DigitalAtelierTokens.errorText,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Semantics(
                              button: true,
                              label: submitLabel,
                              excludeSemantics: true,
                              child: ElevatedButton(
                                onPressed: _submitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(submitLabel),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Semantics(
                              button: true,
                              label: switchPrompt,
                              hint: switchLabel,
                              excludeSemantics: true,
                              child: TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () => _switchMode(
                                        isSignIn
                                            ? _AuthMode.signUp
                                            : _AuthMode.signIn,
                                      ),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: Text(switchPrompt),
                              ),
                            ),
                            if (widget.localDemoEntryEnabled) ...[
                              const SizedBox(height: 10),
                              Semantics(
                                button: true,
                                label: 'Open sample workout',
                                hint:
                                    'Open a deterministic local demo session.',
                                excludeSemantics: true,
                                child: OutlinedButton.icon(
                                  onPressed: _submitting
                                      ? null
                                      : _openLocalDemoSession,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  icon: const Icon(Icons.play_arrow_outlined),
                                  label: const Text('Open sample workout'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password.';
    // GoTrue minimum_password_length = 6 (config.toml). Mirror it client-side
    // for instant feedback; the server still rejects sub-minimum passwords
    // (VAL-AUTH-029).
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }
}

class _AuthSignalStrip extends StatelessWidget {
  const _AuthSignalStrip();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _AuthSignalChip(icon: Icons.bolt_outlined, label: 'Readiness plan'),
        _AuthSignalChip(icon: Icons.fitness_center, label: 'Live logging'),
        _AuthSignalChip(icon: Icons.verified_outlined, label: 'Private proof'),
      ],
    );
  }
}

class _AuthSignalChip extends StatelessWidget {
  const _AuthSignalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
