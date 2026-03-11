// lib/features/game/screens/game_screen.dart
// Phase 4 — Core Game (tile-placement redesign)
// Spec: flutter-agent-spec.md § Navigation Routes
//
// Main game screen. Shows the crossword grid and letter pool.
// Game state is managed by a GameNotifier created as local state — this
// keeps the notifier scoped to a single level play-through.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
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

    _notifier = GameNotifier(puzzle: puzzle, wordValidator: wordValidator);
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

    // Navigate to level-complete exactly once
    if (gameState.phase == GamePhase.levelComplete && !_levelCompleteNavigated) {
      _levelCompleteNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(
            '/level-complete',
            extra: LevelCompleteArgs(
              levelNumber: puzzle.levelNumber ?? widget.levelNumber,
              stars: gameState.stars,
              coinsEarned: 0, // Phase 4 — coin economy in Phase 5
            ),
          );
        }
      });
    }

    return SafeArea(
      child: Column(
        children: [
          // HUD bar
          _GameHud(
            levelNumber: puzzle.levelNumber ?? widget.levelNumber,
            isBoss: puzzle.isBoss,
            onBack: () async {
              final shouldLeave = await _confirmLeave(context);
              if (shouldLeave && context.mounted) context.go('/home');
            },
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
  final VoidCallback onBack;

  const _GameHud({
    required this.levelNumber,
    required this.isBoss,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppColors.surface.withValues(alpha: 0.1),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: onBack,
          ),
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
          // Coin balance placeholder — wired to real balance in Phase 5
          const Row(
            children: [
              Icon(Icons.monetization_on, color: AppColors.accent, size: 18),
              SizedBox(width: 4),
              Text(
                '0',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
        ],
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
