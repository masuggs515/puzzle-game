// lib/features/game/screens/level_complete_screen.dart
// Phase 4 — Core Game
// Phase 7 — Rewarded video ad button ("Watch Ad for 15 Coins")
// Spec: flutter-agent-spec.md § Navigation Routes
//       master-development-plan.md § Rewarded Video Ad Policy
//
// Shown after a level is completed or skipped.
// Non-paying users can watch a rewarded video for 15 coins.
// Coins are awarded via the on-rewarded-ad Edge Function — never client-side.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/data/services/ad_service.dart';
import 'package:puzzle_game/features/auth/providers/auth_provider.dart';
import 'package:puzzle_game/features/game/models/level_complete_args.dart';
import 'package:puzzle_game/features/shop/providers/shop_provider.dart';
import 'package:uuid/uuid.dart';

class LevelCompleteScreen extends ConsumerStatefulWidget {
  final LevelCompleteArgs args;

  const LevelCompleteScreen({super.key, required this.args});

  @override
  ConsumerState<LevelCompleteScreen> createState() =>
      _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends ConsumerState<LevelCompleteScreen> {
  bool _adLoading = false;

  // ── Rewarded ad ──────────────────────────────────────────────────────────

  Future<void> _watchAdForCoins() async {
    final rewardedAdService = ref.read(rewardedAdServiceProvider);
    if (!rewardedAdService.isReady) return;

    setState(() => _adLoading = true);

    await rewardedAdService.showAd(
      coinsToAward: 15,
      onRewarded: (coins) async {
        // Award via Edge Function — never client-side.
        try {
          final supabaseService = ref.read(supabaseServiceProvider);
          await supabaseService.callEdgeFunction(
            'on-rewarded-ad',
            body: {
              'ad_unit_id': RewardedAdService.adUnitId,
              'coins_to_award': coins,
              'idempotency_key': const Uuid().v4(),
            },
          );
          ref.invalidate(coinBalanceProvider);
          final newBalance = ref.read(coinBalanceProvider).value ?? 0;
          ref.read(analyticsServiceProvider).trackRewardedAdCompleted(
                placement: 'level_complete',
                coinsAwarded: coins,
                coinBalanceAfter: newBalance,
              );
        } catch (e) {
          debugPrint('[LevelCompleteScreen] on-rewarded-ad error: $e');
        }
      },
      onDismissed: () {
        if (!mounted) return;
        setState(() => _adLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('15 coins added!'),
            backgroundColor: AppColors.feedbackCorrect,
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rewardedAdService = ref.watch(rewardedAdServiceProvider);
    final isPayingUser = ref.read(revenueCatServiceProvider).isPayingUser;

    // Show the rewarded ad button only for non-paying users.
    final showAdButton = !isPayingUser && !widget.args.wasSkipped;

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
                  widget.args.wasSkipped
                      ? 'Level Skipped'
                      : 'Level ${widget.args.levelNumber} Complete!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Star rating
                if (!widget.args.wasSkipped)
                  _StarRating(stars: widget.args.stars),

                const SizedBox(height: 32),

                // Coins earned (hidden when zero)
                if (widget.args.coinsEarned > 0) ...[
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
                        '+${widget.args.coinsEarned}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Phase 7: Watch Ad for 15 Coins button.
                // Shown between coins earned and achievements.
                // Only for non-paying users on completed (not skipped) levels.
                if (showAdButton) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_adLoading || !rewardedAdService.isReady)
                          ? null
                          : _watchAdForCoins,
                      icon: _adLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.play_circle_outline,
                              color: AppColors.accent,
                            ),
                      label: Text(
                        _adLoading
                            ? 'Loading…'
                            : rewardedAdService.isReady
                                ? 'Watch Ad for 15 Coins'
                                : 'Ad not available',
                        style: const TextStyle(color: AppColors.accent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Achievements
                if (widget.args.achievementsUnlocked.isNotEmpty) ...[
                  _AchievementsList(
                    achievements: widget.args.achievementsUnlocked,
                  ),
                  const SizedBox(height: 32),
                ],

                const SizedBox(height: 16),

                // Continue to next level
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        context.go('/game/${widget.args.levelNumber + 1}'),
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
