// lib/features/achievements/providers/achievements_provider.dart
// Phase 5 — Economy & Progression
// Spec: flutter-agent-spec.md § Achievements Screen

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// A single achievement row returned from Supabase.
class UnlockedAchievement {
  final String achievementId;
  final DateTime unlockedAt;

  const UnlockedAchievement({
    required this.achievementId,
    required this.unlockedAt,
  });
}

/// Fetches all achievements unlocked by the current user.
final unlockedAchievementsProvider =
    FutureProvider<List<UnlockedAchievement>>((ref) async {
  // Re-run when auth state changes (sign-in / sign-out).
  ref.watch(authStateProvider);
  final supabase = ref.read(supabaseServiceProvider);
  final rows = await supabase.getAchievements();
  return rows
      .map(
        (r) => UnlockedAchievement(
          achievementId: r['achievement_id'] as String,
          unlockedAt: DateTime.parse(r['unlocked_at'] as String),
        ),
      )
      .toList();
});
