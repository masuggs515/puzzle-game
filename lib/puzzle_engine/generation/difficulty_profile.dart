import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

/// Describes the generation parameters for a given level.
class DifficultyProfile {
  final int levelNumber;
  final LevelType levelType;
  final bool isBoss;
  final int intersectionCount;
  final List<int> allowedConstraintTiers;
  final int decoyLetterCount;

  const DifficultyProfile({
    required this.levelNumber,
    required this.levelType,
    required this.isBoss,
    required this.intersectionCount,
    required this.allowedConstraintTiers,
    required this.decoyLetterCount,
  });

  /// Create a [DifficultyProfile] for the given [level] number.
  factory DifficultyProfile.forLevel(int level) {
    final isBoss = _isBossLevel(level);
    final levelType = _levelType(level);

    if (level <= 10) {
      return DifficultyProfile(
        levelNumber: level,
        levelType: levelType,
        isBoss: isBoss,
        intersectionCount: 1,
        allowedConstraintTiers: [1],
        decoyLetterCount: 0,
      );
    } else if (level <= 24) {
      return DifficultyProfile(
        levelNumber: level,
        levelType: levelType,
        isBoss: isBoss,
        intersectionCount: level <= 17 ? 1 : 2,
        allowedConstraintTiers: [1, 2],
        decoyLetterCount: 0,
      );
    } else if (level <= 50) {
      return DifficultyProfile(
        levelNumber: level,
        levelType: levelType,
        isBoss: isBoss,
        intersectionCount: 2,
        allowedConstraintTiers: isBoss ? [3, 4] : [1, 2, 3],
        decoyLetterCount: 2,
      );
    } else if (level <= 99) {
      return DifficultyProfile(
        levelNumber: level,
        levelType: levelType,
        isBoss: isBoss,
        intersectionCount: level <= 74 ? 2 : 3,
        allowedConstraintTiers: [1, 2, 3, 4],
        decoyLetterCount: 4,
      );
    } else if (level <= 190) {
      return DifficultyProfile(
        levelNumber: level,
        levelType: levelType,
        isBoss: isBoss,
        intersectionCount: level <= 150 ? 3 : 4,
        allowedConstraintTiers: [1, 2, 3, 4],
        decoyLetterCount: 26, // Full keyboard
      );
    } else {
      // Boss levels 191–200
      return DifficultyProfile(
        levelNumber: level,
        levelType: levelType,
        isBoss: true,
        intersectionCount: level <= 195 ? 4 : 5,
        allowedConstraintTiers: [4, 5],
        decoyLetterCount: 26, // Full keyboard
      );
    }
  }

  static bool _isBossLevel(int level) {
    // Boss levels: every 10th level (10, 20, 30, ...) and all 191–200
    if (level >= 191 && level <= 200) return true;
    return level % 10 == 0;
  }

  static LevelType _levelType(int level) {
    if (level > 200) return LevelType.vault;
    return LevelType.puzzle;
  }
}
