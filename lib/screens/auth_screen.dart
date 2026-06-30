import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/auth/auth_service.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Email/password authentication surface wired to Supabase GoTrue.
///
/// Surfaces explicit errors for wrong password, unregistered email, duplicate
/// email, invalid email domain, and sub-minimum password. Every interactive or
/// asserted element carries a meaningful [Semantics] label per the convention.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSignIn = _mode == _AuthMode.signIn;
    final submitLabel = isSignIn ? 'Sign in' : 'Sign up';
    final switchLabel = isSignIn
        ? 'Switch to sign up'
        : 'Switch to sign in';
    final switchPrompt = isSignIn
        ? "Don't have an account? Sign up"
        : 'Already have an account? Sign in';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      isSignIn ? 'Welcome back' : 'Create your account',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSignIn
                        ? 'Sign in to continue your training.'
                        : 'Sign up to start your training plan.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
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
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    autofillHints: const ['password'],
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: DigitalAtelierTokens.errorText,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Semantics(
                    button: true,
                    label: submitLabel,
                    excludeSemantics: true,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
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
                    label: switchLabel,
                    excludeSemantics: true,
                    child: TextButton(
                      onPressed: _submitting
                          ? null
                          : () => _switchMode(
                                isSignIn ? _AuthMode.signUp : _AuthMode.signIn,
                              ),
                      child: Text(switchPrompt),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
