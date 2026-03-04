// lib/features/game/screens/level_complete_screen.dart
// Phase 4 — Core Game
// Spec: flutter-agent-spec.md § Navigation Routes
//
// Shown after a level is completed or skipped.
// In Phase 4 coins are always 0 — full economy lands in Phase 5.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/game/models/level_complete_args.dart';

class LevelCompleteScreen extends StatelessWidget {
  final LevelCompleteArgs args;

  const LevelCompleteScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  args.wasSkipped
                      ? 'Level Skipped'
                      : 'Level ${args.levelNumber} Complete!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Star rating
                if (!args.wasSkipped) _StarRating(stars: args.stars),

                const SizedBox(height: 32),

                // Coins earned (hidden when zero)
                if (args.coinsEarned > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: AppColors.accent,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${args.coinsEarned}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],

                // Achievements
                if (args.achievementsUnlocked.isNotEmpty) ...[
                  _AchievementsList(achievements: args.achievementsUnlocked),
                  const SizedBox(height: 32),
                ],

                const SizedBox(height: 16),

                // Continue to next level
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        context.go('/game/${args.levelNumber + 1}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Return to home
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      child: Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int stars;

  const _StarRating({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            i < stars ? Icons.star : Icons.star_outline,
            color: AppColors.accent,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _AchievementsList extends StatelessWidget {
  final List<String> achievements;

  const _AchievementsList({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Achievement Unlocked!',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...achievements.map(
          (a) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Text(a, style: const TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
