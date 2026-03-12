// lib/app.dart
// Root application widget — sets up MaterialApp, GoRouter, and theme.
// Phase 4: added /game/:levelNumber and /level-complete routes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/achievements/screens/achievements_screen.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/auth/screens/sign_up_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/game/models/level_complete_args.dart';
import 'features/game/screens/game_screen.dart';
import 'features/game/screens/level_complete_screen.dart';
import 'features/home/screens/home_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/game/:levelNumber',
      builder: (context, state) => GameScreen(
        levelNumber: int.parse(state.pathParameters['levelNumber']!),
      ),
    ),
    GoRoute(
      path: '/level-complete',
      builder: (context, state) => LevelCompleteScreen(
        args: state.extra as LevelCompleteArgs,
      ),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    // TODO Phase 9: /shop route
  ],
);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Puzzle Game',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
