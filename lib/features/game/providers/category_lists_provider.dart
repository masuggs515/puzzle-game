// lib/features/game/providers/category_lists_provider.dart
// Phase 4 — Core Game
//
// Loads all category word lists from assets and preloads them into
// CategoryListLoader so CategoryConstraint.validate() works at runtime.
// Returns true once all categories are loaded.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';

// All category names that have a corresponding file in
// assets/word_lists/category_lists/
const _categoryNames = [
  'animals',
  'body_parts',
  'clothing',
  'colors',
  'countries',
  'foods',
  'fruits',
  'kitchen_items',
  'sports',
  'vegetables',
  'vehicles',
  'water_bodies',
  'weather',
];

final categoryListsProvider = FutureProvider<bool>((ref) async {
  for (final name in _categoryNames) {
    final raw = await rootBundle
        .loadString('assets/word_lists/category_lists/$name.txt');
    final words = raw
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toSet();
    CategoryListLoader.preload(name, words);
  }
  return true;
});
