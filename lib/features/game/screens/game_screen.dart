// lib/features/game/screens/game_screen.dart
// Phase 4 — Core Game
// Spec: flutter-agent-spec.md § Navigation Routes
//
// Main game screen. Wraps the Flame PuzzleGame with a Flutter overlay
// that shows the HUD, constraint panel, submit bar, and feedback banner.
// Game state is managed by a GameNotifier created as local state — this
// keeps the notifier scoped to a single level play-through.

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/game/game/puzzle_game.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/models/level_complete_args.dart';
import 'package:puzzle_game/features/game/providers/game_provider.dart';
import 'package:puzzle_game/features/game/providers/valid_words_provider.dart';
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
  PuzzleGame? _game;
  GameNotifier? _notifier;
  GameState? _gameState;
  int? _selectedSlotId;
  bool _levelCompleteNavigated = false;

  void _initGame(Puzzle puzzle) {
    if (_notifier != null) return; // already initialized for this level

    // Build a WordValidator callback that reads from the cached provider.
    // This avoids storing WidgetRef in the notifier (which is not allowed).
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
    _game = PuzzleGame(
      puzzle: puzzle,
      notifier: _notifier!,
      getState: () => _notifier!.currentState,
    );
  }

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzleAsync = ref.watch(gamePuzzleProvider(widget.levelNumber));

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
          data: (puzzle) => _buildGameBody(context, puzzle),
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

    // Sync tile visuals after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game?.syncState(gameState);
    });

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

          // Constraint panel (slot selection chips)
          _ConstraintPanel(
            puzzle: puzzle,
            solvedWords: gameState.solvedWords,
            selectedSlotId: _selectedSlotId,
            onSlotSelected: (id) => setState(() => _selectedSlotId = id),
          ),

          // Flame game canvas
          Expanded(
            child: GameWidget(game: _game!),
          ),

          // Word display + submit/clear
          _WordSubmitBar(
            currentWord: gameState.currentWord,
            selectedSlotId: _selectedSlotId,
            onSubmit: () {
              if (_selectedSlotId != null) {
                _notifier?.onSubmit(_selectedSlotId!);
              }
            },
            onClear: () => _notifier?.onPathCleared(),
          ),

          // Feedback banner
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
// _ConstraintPanel
// ---------------------------------------------------------------------------

class _ConstraintPanel extends StatelessWidget {
  final Puzzle puzzle;
  final Map<int, String> solvedWords;
  final int? selectedSlotId;
  final void Function(int slotId) onSlotSelected;

  const _ConstraintPanel({
    required this.puzzle,
    required this.solvedWords,
    required this.selectedSlotId,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemCount: puzzle.wordSlots.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final slot = puzzle.wordSlots[index];
          final isSolved = solvedWords.containsKey(slot.id);
          final isSelected = selectedSlotId == slot.id;

          return GestureDetector(
            onTap: isSolved ? null : () => onSlotSelected(slot.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSolved
                    ? AppColors.feedbackCorrect.withValues(alpha: 0.3)
                    : isSelected
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.surface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSolved
                      ? AppColors.feedbackCorrect
                      : isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSolved) ...[
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.feedbackCorrect,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      isSolved
                          ? solvedWords[slot.id]!.toUpperCase()
                          : slot.constraint.displayText,
                      style: TextStyle(
                        color: isSolved
                            ? AppColors.feedbackCorrect
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _WordSubmitBar
// ---------------------------------------------------------------------------

class _WordSubmitBar extends StatelessWidget {
  final String currentWord;
  final int? selectedSlotId;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const _WordSubmitBar({
    required this.currentWord,
    required this.selectedSlotId,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = currentWord.length >= 3 && selectedSlotId != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppColors.surface.withValues(alpha: 0.1),
      child: Column(
        children: [
          // Current word display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              currentWord.isEmpty
                  ? (selectedSlotId == null
                      ? 'Select a word slot above, then drag tiles'
                      : 'Drag to spell a word...')
                  : currentWord.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: currentWord.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: currentWord.isEmpty ? 13 : 24,
                fontWeight: currentWord.isEmpty
                    ? FontWeight.normal
                    : FontWeight.bold,
                letterSpacing: currentWord.isEmpty ? 0 : 4,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Submit + Clear buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: canSubmit ? onSubmit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: canSubmit
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.3),
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
                  onPressed: currentWord.isNotEmpty ? onClear : null,
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
                      'Clear',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    final Color textColor = Colors.white;

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
            style: TextStyle(
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
