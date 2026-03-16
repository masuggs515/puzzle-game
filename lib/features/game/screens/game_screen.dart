// lib/features/game/screens/game_screen.dart
// Phase 5 — Economy & Progression (extended from Phase 4)
// Phase 6 — Analytics call sites
// Phase 7 — Interstitial ad before level-complete navigation
// Phase 8 — Vault mode support
// Phase 9 — MERIDIAN design polish
// Spec: flutter-agent-spec.md § Navigation Routes
//       analytics-agent-spec.md
//       master-development-plan.md § Ad Strategy
//
// Main game screen. Shows the crossword grid and letter pool.
// Game state is managed by a GameNotifier created as local state — this
// keeps the notifier scoped to a single level play-through.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_game/core/constants/game_constants.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/auth/providers/auth_provider.dart';
import 'package:puzzle_game/features/shop/providers/shop_provider.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/models/level_complete_args.dart';
import 'package:puzzle_game/features/game/providers/game_provider.dart';
import 'package:puzzle_game/features/game/providers/category_lists_provider.dart';
import 'package:puzzle_game/features/game/providers/valid_words_provider.dart';
import 'package:puzzle_game/features/game/services/puzzle_state_persistence.dart';
import 'package:puzzle_game/features/game/widgets/crossword_grid_widget.dart';
import 'package:puzzle_game/features/game/widgets/letter_pool_widget.dart';
import 'package:puzzle_game/features/vault/providers/vault_provider.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

// ---------------------------------------------------------------------------
// GameScreen
// ---------------------------------------------------------------------------

class GameScreen extends ConsumerStatefulWidget {
  final int? levelNumber;
  final int? vaultLevel;

  const GameScreen({super.key, this.levelNumber, this.vaultLevel})
      : assert(levelNumber != null || vaultLevel != null,
            'GameScreen requires either levelNumber or vaultLevel');

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  GameNotifier? _notifier;
  GameState? _gameState;
  bool _levelCompleteNavigated = false;
  Timer? _saveDebounceTimer;
  bool _stateRestored = false;

  bool get _isVault => widget.vaultLevel != null;
  int get _effectiveLevelNumber =>
      _isVault ? widget.vaultLevel! : (widget.levelNumber ?? 0);
  bool get _isVaultBoss => _isVault && widget.vaultLevel! % 10 == 0;

  void _initGame(Puzzle puzzle) {
    if (_notifier != null) return; // already initialised for this level

    Future<bool> wordValidator(String word) async {
      try {
        final wordSet = await ref.read(validWordSetProvider.future);
        return wordSet.contains(word.toLowerCase());
      } catch (_) {
        // If the word list fails to load, treat every word as valid
        // so the game remains playable.
        return true;
      }
    }

    final supabase = ref.read(supabaseServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    _notifier = GameNotifier(
      puzzle: puzzle,
      wordValidator: wordValidator,
      callEdgeFunction: (name, body) =>
          supabase.callEdgeFunction(name, body: body),
      getProfileId: () => supabase.getProfileId(),
      analytics: analytics,
    );
    // Analytics: level_start — fire-and-forget.
    final isBossForAnalytics = _isVault ? _isVaultBoss : puzzle.isBoss;
    final levelTypeForAnalytics =
        _isVault ? 'vault' : (puzzle.isBoss ? 'bossLevel' : 'standard');
    analytics.trackLevelStart(
      levelNumber: puzzle.levelNumber ?? _effectiveLevelNumber,
      levelType: levelTypeForAnalytics,
      isBoss: isBossForAnalytics,
      coinBalance: ref.read(coinBalanceProvider).value ?? 0,
      intersectionCount: puzzle.intersections.length,
      constraintTiers: puzzle.wordSlots
          .map((s) => s.constraint.tier)
          .toList(),
    );
    _notifier!.addListener((newState) {
      if (mounted) {
        setState(() => _gameState = newState);
        if (!_isVault) _scheduleSave(newState);
      }
    });
    _gameState = _notifier!.currentState;
    if (!_isVault) _scheduleRestore(_effectiveLevelNumber);
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _notifier?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Persistence helpers
  // ---------------------------------------------------------------------------

  void _scheduleRestore(int levelNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _stateRestored) return;
      _stateRestored = true;
      final saved = await PuzzleStatePersistence.load(levelNumber);
      if (!mounted || saved == null) return;
      for (final entry in saved.placements.entries) {
        _notifier?.placeTile(entry.key, entry.value);
      }
      _notifier?.restoreProgress(
        hintsUsed: saved.hintsUsed,
        attempts: saved.attempts,
      );
      debugPrint(
        '[GameScreen] Restored ${saved.placements.length} tile placements '
        'for level $levelNumber',
      );
    });
  }

  void _scheduleSave(GameState newState) {
    if (_isVault) return;
    if (newState.phase == GamePhase.levelComplete) return;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      PuzzleStatePersistence.save(
        widget.levelNumber!,
        newState.tiles,
        newState.hintsUsedThisLevel,
        newState.attemptsThisLevel,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Hint and Skip
  // ---------------------------------------------------------------------------

  Future<void> _requestHint() async {
    final balance = ref.read(coinBalanceProvider).value ?? 0;
    if (balance < GameConstants.hintCost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins for Field Assist.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.ink,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: const BoxDecoration(
                color: AppColors.signal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REQUEST FIELD ASSIST',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppColors.parchment,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reveal one letter position. Costs 5 \u25c8.',
                    style: TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 13,
                      color: AppColors.dmInkFaded,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current balance: $balance \u25c8',
                    style: const TextStyle(
                      fontFamily: 'CourierPrime',
                      fontSize: 11,
                      color: AppColors.dmInkFaded,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text(
                          'Stand down',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 13,
                            color: AppColors.signal,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Confirm \u2014 spend 5 \u25c8',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 13,
                            color: AppColors.signal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final granted =
        await _notifier?.onHintRequested(coinBalance: balance) ?? false;
    if (granted) {
      ref.invalidate(coinBalanceProvider);
    }
  }

  Future<void> _requestSkip(Puzzle puzzle) async {
    if (_isVault) return;
    final balance = ref.read(coinBalanceProvider).value ?? 0;
    if (balance < GameConstants.skipCost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough coins. Skipping costs ${GameConstants.skipCost} coins.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.ink,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: const BoxDecoration(
                color: AppColors.signal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SKIP THIS SIGNAL?',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppColors.parchment,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Costs ${GameConstants.skipCost} \u25c8. Signal marked as skipped.',
                    style: const TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 13,
                      color: AppColors.dmInkFaded,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text(
                          'Stay on signal',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 13,
                            color: AppColors.signal,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(
                          'Skip \u2014 spend ${GameConstants.skipCost} \u25c8',
                          style: const TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 13,
                            color: AppColors.rust,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final result =
        await _notifier?.onSkipRequested(coinBalance: balance);
    if (result == null || !result.success) return;

    // Analytics: coin_transaction for skip spend — fire-and-forget.
    ref.read(analyticsServiceProvider).trackCoinTransaction(
      transactionType: 'level_skip',
      amount: -GameConstants.skipCost,
      balanceBefore: balance,
      balanceAfter: result.newBalance,
      referenceId: '${puzzle.levelNumber ?? _effectiveLevelNumber}',
    );

    ref.invalidate(coinBalanceProvider);
    // Clear saved mid-puzzle state so a replay starts fresh.
    if (!_isVault) await PuzzleStatePersistence.clear(widget.levelNumber!);
    if (!mounted) return;
    context.go(
      '/level-complete',
      extra: LevelCompleteArgs(
        levelNumber: puzzle.levelNumber ?? _effectiveLevelNumber,
        stars: 0,
        coinsEarned: 0,
        wasSkipped: true,
        isVault: _isVault,
        vaultLevel: _isVault ? widget.vaultLevel : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzleAsync = _isVault
        ? ref.watch(vaultGamePuzzleProvider(widget.vaultLevel!))
        : ref.watch(gamePuzzleProvider(widget.levelNumber!));
    final categoriesAsync = ref.watch(categoryListsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave(context);
        if (shouldLeave && context.mounted) {
          _fireAbandonedAnalytics(_effectiveLevelNumber);
          context.go(_isVault ? '/vault' : '/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.parchment,
        body: puzzleAsync.when(
          data: (puzzle) => categoriesAsync.when(
            data: (_) => _buildGameBody(context, puzzle),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error loading word lists: $e',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error loading puzzle: $e',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameBody(BuildContext context, Puzzle puzzle) {
    _initGame(puzzle);

    final gameState = _gameState ?? _notifier!.currentState;
    final coinBalance = ref.watch(coinBalanceProvider).value ?? 0;

    // Navigate to level-complete exactly once, calling backend first.
    if (gameState.phase == GamePhase.levelComplete && !_levelCompleteNavigated) {
      _levelCompleteNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final router = GoRouter.of(context);
        final coinBalanceBefore = ref.read(coinBalanceProvider).value ?? 0;
        final result = await _notifier!.onLevelCompletedBackend(
          levelNumber: puzzle.levelNumber ?? _effectiveLevelNumber,
          isBoss: _isVault ? _isVaultBoss : puzzle.isBoss,
          isVault: _isVault,
        );
        if (!mounted) return;

        final analytics = ref.read(analyticsServiceProvider);
        final levelNum = puzzle.levelNumber ?? _effectiveLevelNumber;
        final levelType =
            _isVault ? 'vault' : (puzzle.isBoss ? 'bossLevel' : 'standard');
        final isBossForComplete = _isVault ? _isVaultBoss : puzzle.isBoss;

        analytics.trackLevelComplete(
          levelNumber: levelNum,
          levelType: levelType,
          isBoss: isBossForComplete,
          stars: gameState.stars,
          hintsUsed: gameState.hintsUsedThisLevel,
          attemptsTotal: gameState.attemptsThisLevel,
          coinsEarned: result.coinsEarned,
          coinBalanceAfter: result.newBalance,
          timeTakenMs: DateTime.now()
              .difference(gameState.levelStartTime)
              .inMilliseconds,
          achievementsUnlocked: result.achievementsUnlocked,
        );

        analytics.trackCoinTransaction(
          transactionType: 'level_complete',
          amount: result.coinsEarned,
          balanceBefore: coinBalanceBefore,
          balanceAfter: result.newBalance,
          referenceId: '$levelNum',
        );

        if (result.newStreak > 0) {
          analytics.trackStreakUpdated(
            newStreak: result.newStreak,
            previousStreak:
                result.newStreak > 1 ? result.newStreak - 1 : 0,
            streakIncreased: true,
          );
        }

        for (var i = 0; i < result.achievementsUnlocked.length; i++) {
          analytics.trackAchievementUnlocked(
            achievementId: result.achievementsUnlocked[i],
            coinsAwarded: 0,
            levelNumber: levelNum,
            totalAchievementsUnlocked: i + 1,
          );
        }

        ref.invalidate(coinBalanceProvider);

        if (_isVault) {
          final vl = widget.vaultLevel!;
          final current = ref.read(currentVaultLevelProvider);
          if (vl > current) {
            ref.read(currentVaultLevelProvider.notifier).state = vl;
          }
          ref.invalidate(vaultLevelProvider);
          ref.invalidate(profileProvider);
        }

        if (!_isVault) {
          await PuzzleStatePersistence.clear(
            puzzle.levelNumber ?? widget.levelNumber!,
          );
        }
        if (!mounted) return;

        final adFreqManager = ref.read(adFrequencyManagerProvider);
        final revenueCat = ref.read(revenueCatServiceProvider);
        final levelsSinceLastAd = adFreqManager.levelsSinceLastAd;
        final shouldShowAd = adFreqManager.shouldShowAd(
          isBossLevel: _isVault ? _isVaultBoss : puzzle.isBoss,
          isPayingUser: revenueCat.isPayingUser,
        );

        void navigateToLevelComplete() {
          if (!mounted) return;
          router.go(
            '/level-complete',
            extra: LevelCompleteArgs(
              levelNumber: puzzle.levelNumber ?? _effectiveLevelNumber,
              stars: gameState.stars,
              coinsEarned: result.coinsEarned,
              achievementsUnlocked: result.achievementsUnlocked,
              isVault: _isVault,
              vaultLevel: _isVault ? widget.vaultLevel : null,
            ),
          );
        }

        if (shouldShowAd) {
          ref.read(analyticsServiceProvider).trackInterstitialAdShown(
            levelNumber: levelNum,
            levelsSinceLastAd: levelsSinceLastAd,
          );
          final interstitialService = ref.read(interstitialAdServiceProvider);
          await interstitialService.showAd(
            onAdDismissed: navigateToLevelComplete,
          );
        } else {
          navigateToLevelComplete();
        }
      });
    }

    return SafeArea(
      child: Column(
        children: [
          // HUD bar
          _GameHud(
            levelNumber: puzzle.levelNumber ?? _effectiveLevelNumber,
            isBoss: _isVault ? _isVaultBoss : puzzle.isBoss,
            isVault: _isVault,
            coinBalance: coinBalance,
            onBack: () async {
              final shouldLeave = await _confirmLeave(context);
              if (shouldLeave && context.mounted) {
                _fireAbandonedAnalytics(
                  _gameState?.puzzle.levelNumber ?? _effectiveLevelNumber,
                );
                context.go(_isVault ? '/vault' : '/home');
              }
            },
            onHintPressed: _requestHint,
            onSkipPressed: () => _requestSkip(puzzle),
          ),

          // Scrollable puzzle area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  CrosswordGridWidget(
                    puzzle: puzzle,
                    tiles: gameState.tiles,
                    slotResults: gameState.slotResults,
                    onTileDropped: (tile, targetCell) =>
                        _notifier?.placeTile(tile.id, targetCell),
                    onTileReturned: (tileId) =>
                        _notifier?.returnTile(tileId),
                  ),
                  const SizedBox(height: 16),
                  LetterPoolWidget(
                    tiles: gameState.tiles,
                    hintTileIds: gameState.hintTileIds,
                    onTileReturned: (tileId) =>
                        _notifier?.returnTile(tileId),
                  ),
                ],
              ),
            ),
          ),

          // Submit + Clear All bar
          _SubmitBar(
            onSubmit: () => _notifier?.onSubmit(),
            onClearAll: () => _notifier?.clearAll(),
          ),

          // Feedback banner
          if (gameState.feedbackMessage != null)
            _FeedbackBanner(message: gameState.feedbackMessage!),
        ],
      ),
    );
  }

  void _fireAbandonedAnalytics(int levelNumber) {
    final gameState = _gameState ?? _notifier?.currentState;
    if (gameState == null) return;
    final puzzle = gameState.puzzle;
    final levelType =
        _isVault ? 'vault' : (puzzle.isBoss ? 'bossLevel' : 'standard');
    final isBossForAbandoned = _isVault ? _isVaultBoss : puzzle.isBoss;
    ref.read(analyticsServiceProvider).trackLevelAbandoned(
      levelNumber: levelNumber,
      levelType: levelType,
      isBoss: isBossForAbandoned,
      timeSpentMs: DateTime.now()
          .difference(gameState.levelStartTime)
          .inMilliseconds,
      hintsUsed: gameState.hintsUsedThisLevel,
      attemptsMade: gameState.attemptsThisLevel,
      wordsCompleted: gameState.solvedWords.length,
      totalWords: puzzle.wordSlots.length,
      coinBalance: ref.read(coinBalanceProvider).value ?? 0,
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.ink,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: const BoxDecoration(
                color: AppColors.signal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ABANDON SIGNAL?',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppColors.parchment,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your tile placements are saved.',
                    style: TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 13,
                      color: AppColors.dmInkFaded,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text(
                          'Stay on signal',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 13,
                            color: AppColors.signal,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Leave',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 13,
                            color: AppColors.rust,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }
}

// ---------------------------------------------------------------------------
// _GameHud
// ---------------------------------------------------------------------------

class _GameHud extends StatelessWidget {
  final int levelNumber;
  final bool isBoss;
  final bool isVault;
  final int coinBalance;
  final VoidCallback onBack;
  final VoidCallback onHintPressed;
  final VoidCallback onSkipPressed;

  const _GameHud({
    required this.levelNumber,
    required this.isBoss,
    required this.isVault,
    required this.coinBalance,
    required this.onBack,
    required this.onHintPressed,
    required this.onSkipPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String levelLabel;
    final String levelTypeBadge;
    if (isVault) {
      levelLabel = 'VAULT V$levelNumber';
      levelTypeBadge = isBoss ? 'BOSS VAULT' : 'VAULT';
    } else {
      levelLabel = 'SIGNAL #$levelNumber';
      levelTypeBadge = isBoss ? 'BOSS' : 'STANDARD';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: AppColors.desk,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.parchment, size: 20),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Level title + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  levelLabel,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.parchment,
                    letterSpacing: 1.8,
                  ),
                ),
                Text(
                  levelTypeBadge,
                  style: const TextStyle(
                    fontFamily: 'CourierPrime',
                    fontSize: 7,
                    color: AppColors.dmInkFaded,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Hint button
          _MeridianHudButton(
            label: 'Field Assist',
            cost: GameConstants.hintCost,
            onPressed: onHintPressed,
            color: AppColors.signal,
          ),
          const SizedBox(width: 4),
          // Skip button (hidden for vault)
          if (!isVault)
            _MeridianHudButton(
              label: 'Skip',
              cost: GameConstants.skipCost,
              onPressed: onSkipPressed,
              color: AppColors.rust,
            ),
          const SizedBox(width: 8),
          // Coin balance
          Text(
            '$coinBalance \u25c8',
            style: const TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.signal,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _MeridianHudButton extends StatelessWidget {
  final String label;
  final int cost;
  final VoidCallback onPressed;
  final Color color;

  const _MeridianHudButton({
    required this.label,
    required this.cost,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: const BorderRadius.all(Radius.circular(3)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.all(Radius.circular(3)),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          '$label  $cost \u25c8',
          style: TextStyle(
            fontFamily: 'SpecialElite',
            fontSize: 9,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SubmitBar
// ---------------------------------------------------------------------------

class _SubmitBar extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onClearAll;

  const _SubmitBar({required this.onSubmit, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppColors.desk,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.signal,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'TRANSMIT \u2192',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.4,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onClearAll,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0x331C1410)),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
              child: const Text(
                'CLEAR',
                style: TextStyle(
                  fontFamily: 'CourierPrime',
                  fontSize: 10,
                  color: Color(0x731C1410),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FeedbackBanner
// ---------------------------------------------------------------------------

class _FeedbackBanner extends StatelessWidget {
  final FeedbackMessage message;
  const _FeedbackBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final Color bannerColor;
    final String bannerText;

    switch (message.type) {
      case FeedbackType.correct:
        bannerColor = AppColors.verdigris;
        bannerText = 'DECODED \u2713';
      case FeedbackType.wrongWord:
        bannerColor = AppColors.rust;
        bannerText = message.message;
      case FeedbackType.wrongConstraint:
        bannerColor = AppColors.rust;
        bannerText = message.message;
      case FeedbackType.hint:
        bannerColor = AppColors.signal;
        bannerText = message.message;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      color: bannerColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bannerText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'SpecialElite',
              fontSize: 11,
              letterSpacing: 1.32,
              color: AppColors.parchment,
            ),
          ),
          if (message.constraintText != null) ...[
            const SizedBox(height: 2),
            Text(
              message.constraintText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpecialElite',
                fontSize: 10,
                color: AppColors.parchment.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.3, duration: 200.ms, curve: Curves.easeOut)
        .fadeIn(duration: 200.ms);
  }
}
