// lib/features/game/providers/valid_words_provider.dart
// Phase 4 — Core Game
// Spec: flutter-agent-spec.md
//
// Loads the valid-guess word list once and exposes it as a Set<String>
// for O(1) lookup during word submission validation.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final validWordSetProvider = FutureProvider<Set<String>>((ref) async {
  final raw = await rootBundle.loadString('assets/word_lists/valid_guess_words.txt');
  final words = raw
      .split('\n')
      .map((w) => w.trim().toLowerCase())
      .where((w) => w.isNotEmpty)
      .toSet();
  return words;
});
