// lib/core/constants/game_constants.dart
// Single source of truth for all game economy and mechanic values.
// Do not hardcode these anywhere else — always reference this class.

class GameConstants {
  // Coin economy
  static const int hintCostCoins = 10;
  static const int skipCostCoins = 25;
  static const int coinsPerLevelComplete = 5;
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
  static const int vaultStartLevel = 201;
}
