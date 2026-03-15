// lib/features/vault/providers/vault_provider.dart
// Phase 8 — The Vault
// Spec: flutter-agent-spec.md § The Vault

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_game/features/auth/providers/auth_provider.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/generation/pre_generator.dart';
import 'package:puzzle_game/puzzle_engine/generation/runtime_generator.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/solver/csp_solver.dart';
import 'package:puzzle_game/puzzle_engine/validation/puzzle_validator.dart';

// ---------------------------------------------------------------------------
// currentVaultLevelProvider
// Tracks the player's highest reached vault level (0 = vault not yet entered).
// Loaded from Supabase on auth; updated locally in GameScreen on completion.
// ---------------------------------------------------------------------------

final currentVaultLevelProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Internal: vault answer word list — loaded once from assets.
// ---------------------------------------------------------------------------

final _vaultAnswerWordsProvider = FutureProvider<List<String>>((ref) async {
  final raw = await rootBundle.loadString('assets/word_lists/answer_words.txt');
  return raw
      .split('\n')
      .map((w) => w.trim().toLowerCase())
      .where((w) => w.isNotEmpty)
      .toList();
});

// ---------------------------------------------------------------------------
// Internal: RuntimeGenerator — built once per session, shared across all
// vault puzzle requests.
// ---------------------------------------------------------------------------

final _runtimeGeneratorProvider = FutureProvider<RuntimeGenerator>((ref) async {
  final answerWords = await ref.watch(_vaultAnswerWordsProvider.future);
  final library = ConstraintLibrary.build();
  final solver = CspSolver(
    answerWords: answerWords,
    constraintLibrary: library,
  );
  final validator = PuzzleValidator(
    answerWordSet: answerWords.toSet(),
    allValidWords: answerWords.toSet(),
  );
  final preGenerator = PreGenerator(
    solver: solver,
    validator: validator,
    constraintLibrary: library,
  );
  return RuntimeGenerator(preGenerator: preGenerator);
});

// ---------------------------------------------------------------------------
// vaultGamePuzzleProvider
// Generates a vault puzzle for a given vault level number.
// Deterministic: same userId + vaultLevel always yields the same puzzle.
// Throws if generation fails so callers see an error state.
// ---------------------------------------------------------------------------

final vaultGamePuzzleProvider = FutureProvider.family<Puzzle, int>(
  (ref, vaultLevel) async {
    final generator = await ref.watch(_runtimeGeneratorProvider.future);
    final supabase = ref.read(supabaseServiceProvider);

    // Resolve the userId for seed derivation. Fall back to empty string so
    // generation still succeeds offline / before profile is created — the same
    // puzzle is produced consistently for a given vaultLevel.
    String userId = '';
    try {
      final profileId = await supabase.getProfileId();
      if (profileId != null && profileId.isNotEmpty) {
        userId = profileId;
      }
    } catch (_) {
      // Silently swallow — offline or Supabase not yet initialised.
    }

    final puzzle = generator.generateVaultPuzzle(
      userId: userId,
      vaultLevel: vaultLevel,
    );

    if (puzzle == null) {
      throw Exception(
        'Vault puzzle generation failed for vault level $vaultLevel. '
        'The constraint library may have too few words for this difficulty.',
      );
    }

    return puzzle;
  },
);
