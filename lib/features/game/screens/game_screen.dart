// lib/features/game/screens/game_screen.dart
// Phase 5 — Economy & Progression (extended from Phase 4)
// Spec: flutter-agent-spec.md § Navigation Routes
//
// Main game screen. Shows the crossword grid and letter pool.
// Game state is managed by a GameNotifier created as local state — this
// keeps the notifier scoped to a single level play-through.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_game/core/constants/game_constants.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/auth/providers/auth_provider.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/models/level_complete_args.dart';
import 'package:puzzle_game/features/game/providers/game_provider.dart';
import 'package:puzzle_game/features/game/providers/category_lists_provider.dart';
import 'package:puzzle_game/features/game/providers/valid_words_provider.dart';
import 'package:puzzle_game/features/game/widgets/crossword_grid_widget.dart';
import 'package:puzzle_game/features/game/widgets/letter_pool_widget.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

// ---------------------------------------------------------------------------
// GameScreen
// ---------------------------------------------------------------------------

class GameScreen extends ConsumerStatefulWidget {
  final int levelNumber;

  const GameScreen({super.key, required this.levelNumber});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  GameNotifier? _notifier;
  GameState? _gameState;
  bool _levelCompleteNavigated = false;

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
    _notifier = GameNotifier(
      puzzle: puzzle,
      wordValidator: wordValidator,
      callEdgeFunction: (name, body) =>
          supabase.callEdgeFunction(name, body: body),
      getProfileId: () => supabase.getProfileId(),
    );
    _notifier!.addListener((newState) {
      if (mounted) setState(() => _gameState = newState);
    });
    _gameState = _notifier!.currentState;
  }

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Hint and Skip
  // ---------------------------------------------------------------------------

  Future<void> _requestHint() async {
    final balance = ref.read(coinBalanceProvider).value ?? 0;
    if (balance < GameConstants.hintCost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough coins. Hints cost ${GameConstants.hintCost} coins.',
          ),
          backgroundColor: AppColors.feedbackWrongWord,
        ),
      );
      return;
    }
    final granted =
        await _notifier?.onHintRequested(coinBalance: balance) ?? false;
    if (granted) {
      // Invalidate coin balance so the HUD updates.
      ref.invalidate(coinBalanceProvider);
    }
  }

  Future<void> _requestSkip(Puzzle puzzle) async {
    final balance = ref.read(coinBalanceProvider).value ?? 0;
    if (balance < GameConstants.skipCost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough coins. Skipping costs ${GameConstants.skipCost} coins.',
          ),
          backgroundColor: AppColors.feedbackWrongWord,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Skip this level?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'This costs ${GameConstants.skipCost} coins.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Skip',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result =
        await _notifier?.onSkipRequested(coinBalance: balance);
    if (result == null || !result.success) return;

    ref.invalidate(coinBalanceProvider);
    if (!mounted) return;
    context.go(
      '/level-complete',
      extra: LevelCompleteArgs(
        levelNumber: puzzle.levelNumber ?? widget.levelNumber,
        stars: 0,
        coinsEarned: 0,
        wasSkipped: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzleAsync = ref.watch(gamePuzzleProvider(widget.levelNumber));
    // categoryListsProvider preloads CategoryListLoader so constraint
    // validation works. Both must be ready before showing the game.
    final categoriesAsync = ref.watch(categoryListsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave(context);
        if (shouldLeave && context.mounted) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
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
        // Capture router before the async gap to satisfy the linter.
        final router = GoRouter.of(context);
        final result = await _notifier!.onLevelCompletedBackend(
          levelNumber: puzzle.levelNumber ?? widget.levelNumber,
          isBoss: puzzle.isBoss,
        );
        if (!mounted) return;
        // Invalidate coin balance so home screen shows updated value.
        ref.invalidate(coinBalanceProvider);
        router.go(
          '/level-complete',
          extra: LevelCompleteArgs(
            levelNumber: puzzle.levelNumber ?? widget.levelNumber,
            stars: gameState.stars,
            coinsEarned: result.coinsEarned,
            achievementsUnlocked: result.achievementsUnlocked,
          ),
        );
      });
    }

    return SafeArea(
      child: Column(
        children: [
          // HUD bar
          _GameHud(
            levelNumber: puzzle.levelNumber ?? widget.levelNumber,
            isBoss: puzzle.isBoss,
            coinBalance: coinBalance,
            onBack: () async {
              final shouldLeave = await _confirmLeave(context);
              if (shouldLeave && context.mounted) context.go('/home');
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
                  // Crossword grid — centerpiece of the screen
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
                  // Letter pool — tile bank below the grid
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

          // Feedback banner (shown when there is an active feedback message)
          if (gameState.feedbackMessage != null)
            _FeedbackBanner(message: gameState.feedbackMessage!),
        ],
      ),
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Leave puzzle?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Your progress on this puzzle will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Playing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.feedbackWrongWord),
            ),
          ),
        ],
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
  final int coinBalance;
  final VoidCallback onBack;
  final VoidCallback onHintPressed;
  final VoidCallback onSkipPressed;

  const _GameHud({
    required this.levelNumber,
    required this.isBoss,
    required this.coinBalance,
    required this.onBack,
    required this.onHintPressed,
    required this.onSkipPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: AppColors.surface.withValues(alpha: 0.1),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: onBack,
          ),
          // Level title
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isBoss) ...[
                  const Icon(Icons.star, color: AppColors.accent, size: 18),
                  const SizedBox(width: 4),
                ],
                Text(
                  'Level $levelNumber',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isBoss) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: AppColors.accent, size: 18),
                ],
              ],
            ),
          ),
          // Hint button
          _HudActionButton(
            icon: Icons.lightbulb_outline,
            cost: GameConstants.hintCost,
            label: 'Hint',
            onPressed: onHintPressed,
          ),
          const SizedBox(width: 4),
          // Skip button
          _HudActionButton(
            icon: Icons.skip_next,
            cost: GameConstants.skipCost,
            label: 'Skip',
            onPressed: onSkipPressed,
          ),
          const SizedBox(width: 4),
          // Coin balance
          Row(
            children: [
              const Icon(
                Icons.monetization_on,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 2),
              Text(
                '$coinBalance',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact HUD button showing an icon, coin cost, and a label.
class _HudActionButton extends StatelessWidget {
  final IconData icon;
  final int cost;
  final String label;
  final VoidCallback onPressed;

  const _HudActionButton({
    required this.icon,
    required this.cost,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: AppColors.accent,
                  size: 10,
                ),
                const SizedBox(width: 1),
                Text(
                  '$cost',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
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

  const _SubmitBar({
    required this.onSubmit,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppColors.surface.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onClearAll,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
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
    const Color textColor = Colors.white;

    switch (message.type) {
      case FeedbackType.correct:
        bannerColor = AppColors.feedbackCorrect;
      case FeedbackType.wrongWord:
        bannerColor = AppColors.feedbackWrongWord;
      case FeedbackType.wrongConstraint:
        bannerColor = AppColors.feedbackWrongConstraint;
      case FeedbackType.hint:
        bannerColor = AppColors.primary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      color: bannerColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (message.constraintText != null) ...[
            const SizedBox(height: 2),
            Text(
              message.constraintText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
