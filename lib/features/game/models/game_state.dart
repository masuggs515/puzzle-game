// lib/features/game/models/game_state.dart
// Phase 4 — Core Game
// Spec: flutter-agent-spec.md § Game State Machine

import 'package:puzzle_game/core/constants/game_constants.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

enum GamePhase {
  loading,
  idle,
  dragging,
  submitted,
  feedbackCorrect,
  feedbackWrongWord,
  feedbackWrongConstraint,
  hintActive,
  levelComplete,
  paused,
}

enum FeedbackType { correct, wrongWord, wrongConstraint }

class FeedbackMessage {
  final FeedbackType type;
  final String message;
  final String? constraintText;

  const FeedbackMessage({
    required this.type,
    required this.message,
    this.constraintText,
  });
}

class GameState {
  final GamePhase phase;
  final Puzzle puzzle;
  final Map<int, String> solvedWords;       // slotId → word
  final List<int> currentPath;              // tile indices in current drag path
  final String currentWord;
  final int hintsUsedThisLevel;
  final int attemptsThisLevel;
  final int? activeHintSlotId;
  final Set<int> hintedTileIndices;
  final FeedbackMessage? feedbackMessage;
  final DateTime levelStartTime;
  final int coinBalance;

  const GameState({
    required this.phase,
    required this.puzzle,
    required this.solvedWords,
    required this.currentPath,
    required this.currentWord,
    required this.hintsUsedThisLevel,
    required this.attemptsThisLevel,
    required this.activeHintSlotId,
    required this.hintedTileIndices,
    required this.feedbackMessage,
    required this.levelStartTime,
    required this.coinBalance,
  });

  GameState copyWith({
    GamePhase? phase,
    Puzzle? puzzle,
    Map<int, String>? solvedWords,
    List<int>? currentPath,
    String? currentWord,
    int? hintsUsedThisLevel,
    int? attemptsThisLevel,
    int? activeHintSlotId,
    bool clearActiveHintSlotId = false,
    Set<int>? hintedTileIndices,
    FeedbackMessage? feedbackMessage,
    bool clearFeedbackMessage = false,
    DateTime? levelStartTime,
    int? coinBalance,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      puzzle: puzzle ?? this.puzzle,
      solvedWords: solvedWords ?? this.solvedWords,
      currentPath: currentPath ?? this.currentPath,
      currentWord: currentWord ?? this.currentWord,
      hintsUsedThisLevel: hintsUsedThisLevel ?? this.hintsUsedThisLevel,
      attemptsThisLevel: attemptsThisLevel ?? this.attemptsThisLevel,
      activeHintSlotId: clearActiveHintSlotId
          ? null
          : (activeHintSlotId ?? this.activeHintSlotId),
      hintedTileIndices: hintedTileIndices ?? this.hintedTileIndices,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      levelStartTime: levelStartTime ?? this.levelStartTime,
      coinBalance: coinBalance ?? this.coinBalance,
    );
  }

  /// True when all word slots are solved.
  bool get isComplete => solvedWords.length == puzzle.wordSlots.length;

  /// Star rating: 3 = no hints, 2 = 1-2 hints, 1 = more hints used.
  int get stars {
    if (hintsUsedThisLevel <= GameConstants.threeStarMaxHints) return 3;
    if (hintsUsedThisLevel <= GameConstants.twoStarMaxHints) return 2;
    return 1;
  }
}
