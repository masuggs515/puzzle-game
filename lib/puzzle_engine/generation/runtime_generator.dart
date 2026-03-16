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
    // Map vault level to a working difficulty band (1–185).
    // DifficultyProfile.forLevel(191+) mandates tiers [4,5] only — the solver
    // cannot reliably satisfy those against a finite word list, so we cap at 185.
    // Vault 1–10  → levels  1–20  (tier 1, easy)
    // Vault 11–40 → levels 21–80  (tiers 1–3, medium)
    // Vault 41+   → levels 81–185 (tiers 1–4, hard, capped)
    final mappedLevel = (vaultLevel * 2).clamp(1, 185);
    final difficulty = DifficultyProfile.forLevel(mappedLevel);
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
