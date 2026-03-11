// lib/features/game/providers/valid_words_provider.dart
// Phase 4 — Core Game
// Spec: flutter-agent-spec.md
//
// Loads answer words + valid-guess words and exposes the union as a Set<String>
// for O(1) lookup during word submission validation.
// Answer words must be included so correct puzzle solutions pass the dict check.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final validWordSetProvider = FutureProvider<Set<String>>((ref) async {
  final answers = await rootBundle.loadString('assets/word_lists/answer_words.txt');
  final guesses = await rootBundle.loadString('assets/word_lists/valid_guess_words.txt');

  Set<String> parse(String raw) => raw
      .split('\n')
      .map((w) => w.trim().toLowerCase())
      .where((w) => w.isNotEmpty)
      .toSet();

  return {...parse(answers), ...parse(guesses)};
});
