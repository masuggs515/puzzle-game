// lib/features/game/screens/level_complete_screen.dart
// Phase 4 — Core Game
// Phase 7 — Rewarded video ad button ("Watch Ad for 15 Coins")
// Phase 9 — MERIDIAN design polish
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

    final showAdButton = !isPayingUser && !widget.args.wasSkipped;

    return Scaffold(
      backgroundColor: AppColors.desk,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // ── Stamp ──────────────────────────────────────────────────
                if (!widget.args.wasSkipped) ...[
                  Transform.rotate(
                    angle: -0.0524, // -3 degrees in radians
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.signal,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.signal.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Center(
                          child: Text(
                            'TRANS-\nMITTED',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.signal,
                              letterSpacing: 1.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Title for skipped levels ───────────────────────────────
                if (widget.args.wasSkipped) ...[
                  const Text(
                    'SIGNAL SKIPPED',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: AppColors.dmInkFaded,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Level label ───────────────────────────────────────────
                Text(
                  widget.args.isVault
                      ? 'VAULT V${widget.args.vaultLevel ?? widget.args.levelNumber}'
                      : 'SIGNAL #${widget.args.levelNumber}',
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.dmInkFaded,
                    letterSpacing: 1.8,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Star rating ────────────────────────────────────────────
                if (!widget.args.wasSkipped)
                  _MeridianStarRating(stars: widget.args.stars),

                const SizedBox(height: 24),

                // ── Stats row ─────────────────────────────────────────────
                if (!widget.args.wasSkipped)
                  _StatsRow(
                    coinsEarned: widget.args.coinsEarned,
                    stars: widget.args.stars,
                  ),

                const SizedBox(height: 24),

                // ── Watch Ad button ────────────────────────────────────────
                if (showAdButton) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_adLoading || !rewardedAdService.isReady)
                          ? null
                          : _watchAdForCoins,
                      icon: _adLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.signal,
                              ),
                            )
                          : const Text(
                              '\u25ba',
                              style: TextStyle(
                                color: AppColors.signal,
                                fontSize: 14,
                              ),
                            ),
                      label: Text(
                        _adLoading
                            ? 'Loading\u2026'
                            : rewardedAdService.isReady
                                ? 'Watch for 15 \u25c8'
                                : 'Ad not available',
                        style: const TextStyle(
                          fontFamily: 'SpecialElite',
                          fontSize: 11,
                          color: AppColors.signal,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.signal),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Achievements ───────────────────────────────────────────
                if (widget.args.achievementsUnlocked.isNotEmpty) ...[
                  _AchievementsList(
                    achievements: widget.args.achievementsUnlocked,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Next Signal button ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (widget.args.isVault) {
                        final nextVault =
                            (widget.args.vaultLevel ?? widget.args.levelNumber) + 1;
                        context.go('/vault/$nextVault');
                      } else {
                        context.go('/game/${widget.args.levelNumber + 1}');
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.signal,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'NEXT SIGNAL \u2192',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.ink,
                          letterSpacing: 2.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Return to Base button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.go(widget.args.isVault ? '/vault' : '/home'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.parchment.withValues(alpha: 0.2),
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '\u2190 RETURN TO BASE',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.dmInkFaded,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeridianStarRating extends StatelessWidget {
  final int stars;

  const _MeridianStarRating({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            i < stars ? '\u2605' : '\u2606',
            style: TextStyle(
              color: i < stars ? AppColors.tungsten : AppColors.dmSurface,
              fontSize: 36,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int coinsEarned;
  final int stars;

  const _StatsRow({required this.coinsEarned, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (coinsEarned > 0)
          _StatItem(
            label: 'EARNED',
            value: '+$coinsEarned \u25c8',
            valueColor: AppColors.signal,
          ),
        _StatItem(
          label: 'STARS',
          value: '$stars / 3',
          valueColor: AppColors.tungsten,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: valueColor,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'CourierPrime',
            fontSize: 9,
            color: AppColors.dmInkFaded,
            letterSpacing: 1.0,
          ),
        ),
      ],
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
          '\u25c8 ACHIEVEMENT UNLOCKED',
          style: TextStyle(
            fontFamily: 'SpecialElite',
            fontSize: 10,
            color: AppColors.tungsten,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        ...achievements.map(
          (a) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              a,
              style: const TextStyle(
                fontFamily: 'SpecialElite',
                fontSize: 11,
                color: AppColors.dmInk,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
