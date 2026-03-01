// lib/features/auth/screens/splash_screen.dart
// Phase 2 — Foundation
// Spec: master-development-plan.md § 2.3 Anonymous Session Flow
//
// Creates an anonymous session on first launch, then routes to home.
// If Supabase is not configured (no credentials) the session step is skipped
// and the app runs without auth — safe for development without .env.task.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    // Only attempt auth if Supabase was initialized
    try {
      Supabase.instance.client;
      await SupabaseService().ensureAnonymousSession();
    } catch (_) {
      // Supabase not initialized or sign-in failed — continue without auth
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
