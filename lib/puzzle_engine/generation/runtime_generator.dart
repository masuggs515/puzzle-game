import 'package:puzzle_game/puzzle_engine/generation/difficulty_profile.dart';
import 'package:puzzle_game/puzzle_engine/generation/pre_generator.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

/// Generates puzzles at runtime for theVault (levels 201+).
/// Uses a deterministic seed derived from userId + vaultLevel to ensure
/// the same user always gets the same puzzle for a given vault level.
class RuntimeGenerator {
  final PreGenerator preGenerator;

  RuntimeGenerator({required this.preGenerator});

  /// Generate the Vault puzzle for a given [userId] and [vaultLevel].
  ///
  /// The seed is deterministic: same userId + vaultLevel → same puzzle.
  /// Returns null if no valid puzzle can be generated.
  Puzzle? generateVaultPuzzle({
    required String userId,
    required int vaultLevel,
  }) {
    final seed = _deriveSeed(userId, vaultLevel);
    final difficulty = DifficultyProfile.forLevel(vaultLevel + 200);
    return preGenerator.generate(difficulty, seed: seed);
  }

  /// Derive a deterministic integer seed from [userId] and [vaultLevel].
  int _deriveSeed(String userId, int vaultLevel) {
    // Combine userId hash with vaultLevel for uniqueness
    int hash = 0;
    for (final codeUnit in userId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
    }
    return (hash ^ (vaultLevel * 1000003)) & 0x7FFFFFFF;
  }
}
