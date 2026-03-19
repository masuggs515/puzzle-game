// lib/core/constants/game_constants.dart
// Single source of truth for all game economy and mechanic values.
// Do not hardcode these anywhere else — always reference this class.

class GameConstants {
  // Coin economy (spec: flutter-agent-spec.md § Game Constants)
  static const int hintCost = 5;            // 5–10 TBD — confirm via Phase 4 playtesting
  static const int skipCost = 50;
  static const int coinsPerStandardLevel = 10;
  static const int coinsPerBossLevel = 20;
  static const int streakBonusCoins = 10;

  // Star rating thresholds (hints used)
  static const int threeStarMaxHints = 0;
  static const int twoStarMaxHints = 2;

  // Feedback duration
  static const int feedbackDurationMs = 2000;

  // Hint behaviour
  static const int maxHintsPerLevel = 3;

  // Ad frequency — free players only
  static const int levelsPerInterstitialAd = 3;

  // Puzzle sizes
  static const int minWordLength = 3;
  static const int maxWordLength = 8;

  // Progression
  static const int levelsPerWorld = 30;
  static const int totalHandcraftedLevels = 200;
}
