// lib/features/auth/screens/sign_up_screen.dart
// Phase 2 — Foundation
// Spec: master-development-plan.md § 2.5 Sign Up / Sign In Screens
//
// Converts anonymous session to email/password account via auth.updateUser().
// This preserves all guest data (same auth_id, same player_profiles row).
//
// TODO MAS: Sign in with Apple — requires Apple Developer account + Supabase OAuth
// configuration (Authentication → Providers → Apple). Add in Phase 8/9 before launch.
//
// TODO MAS: Sign in with Google — requires Google Cloud project + OAuth credentials
// configured in Supabase. Add in Phase 8/9 before launch.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(supabaseServiceProvider).createAccountWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('already registered') || raw.contains('already exists')) {
      return 'That email is already in use. Try signing in instead.';
    }
    if (raw.contains('network') || raw.contains('SocketException')) {
      return 'No internet connection. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Create your account to save progress across devices.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  helperText: 'At least 8 characters',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a password';
                  if (v.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Error
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),

              // Submit
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),
              const SizedBox(height: 16),

              // Sign in link
              TextButton(
                onPressed: () => context.pushReplacement('/signin'),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
