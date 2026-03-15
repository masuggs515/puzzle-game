// lib/features/game/models/level_complete_args.dart
// Phase 4 — Core Game
// Data passed to the level-complete screen via GoRouter extra.

class LevelCompleteArgs {
  final int levelNumber;
  final int stars;
  final int coinsEarned; // always 0 in Phase 4
  final bool wasSkipped;
  final List<String> achievementsUnlocked;
  final bool isVault;
  final int? vaultLevel; // the vault level number when isVault is true

  const LevelCompleteArgs({
    required this.levelNumber,
    required this.stars,
    this.coinsEarned = 0,
    this.wasSkipped = false,
    this.achievementsUnlocked = const [],
    this.isVault = false,
    this.vaultLevel,
  });
}
