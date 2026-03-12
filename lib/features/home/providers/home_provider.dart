// lib/features/home/providers/home_provider.dart
// Phase 5 — Economy & Progression
// Spec: flutter-agent-spec.md § World Map

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Progress data for a single level.
class LevelProgress {
  final int levelNumber;
  final bool completed;
  final int? stars; // null = skipped or not completed with stars

  const LevelProgress({
    required this.levelNumber,
    required this.completed,
    this.stars,
  });
}

/// Returns the list of completed/started levels for the current user.
/// An empty list means no progress yet (first time player).
final levelProgressProvider = FutureProvider<List<LevelProgress>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  final rows = await supabase.getLevelProgress();
  return rows
      .map(
        (r) => LevelProgress(
          levelNumber: r['level_number'] as int,
          completed: (r['completed'] as bool?) ?? false,
          stars: r['stars'] as int?,
        ),
      )
      .toList();
});
