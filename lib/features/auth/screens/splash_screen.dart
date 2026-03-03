// lib/features/auth/screens/splash_screen.dart
// Phase 2 — Foundation
// Spec: master-development-plan.md § 2.3 Anonymous Session Flow
//
// Creates an anonymous session on first launch, then routes to home.
// If Supabase is not configured (no credentials) the session step is skipped
// and the app runs without auth — safe for development without .env.task.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // SupabaseService._client is null-safe — returns null when Supabase is not
    // initialized so no guard is needed here. Errors are logged rather than
    // swallowed so auth failures are visible during development.
    try {
      await SupabaseService().ensureAnonymousSession();
    } catch (e) {
      debugPrint('SplashScreen: anonymous sign-in failed: $e');
      // Continue to home — app degrades gracefully without auth
    }

    // Defer navigation so the initial splash frame is always visible,
    // and so tests can observe the splash state before routing.
    await Future<void>.delayed(Duration.zero);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Puzzle Game',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
