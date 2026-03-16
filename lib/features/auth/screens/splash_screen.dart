// lib/features/auth/screens/splash_screen.dart
// Phase 2 — Foundation
// Phase 9 — MERIDIAN design polish
// Spec: master-development-plan.md § 2.3 Anonymous Session Flow
//
// Creates an anonymous session on first launch, then routes to home.
// If Supabase is not configured (no credentials) the session step is skipped
// and the app runs without auth — safe for development without .env.task.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
    final startTime = DateTime.now();
    try {
      await SupabaseService().ensureAnonymousSession();
    } catch (e) {
      debugPrint('SplashScreen: anonymous sign-in failed: $e');
      // Continue to home — app degrades gracefully without auth
    }
    // Minimum 2.5s display time for the splash
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(milliseconds: 2500) - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.desk,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ◆ rule ◆
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '\u25c6',
                  style: TextStyle(color: AppColors.signal, fontSize: 14),
                ),
                Container(
                  width: 40,
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.signal.withValues(alpha: 0.5),
                ),
                const Text(
                  '\u25c6',
                  style: TextStyle(color: AppColors.signal, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // INTERCEPT ●
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'INTERCEPT',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppColors.parchment,
                    letterSpacing: 5.76,
                  ),
                ),
                const SizedBox(width: 8),
                _BlinkingDot(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Field Transmission Decoder \u00b7 Est. 1978',
              style: TextStyle(
                fontFamily: 'SpecialElite',
                fontSize: 10,
                color: AppColors.dmInkFaded,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.15).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Text(
        '\u25cf',
        style: TextStyle(color: AppColors.signal, fontSize: 12),
      ),
    );
  }
}
