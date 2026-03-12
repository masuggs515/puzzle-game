// lib/features/achievements/screens/achievements_screen.dart
// Phase 5 — Economy & Progression
// Spec: flutter-agent-spec.md § Achievements Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/achievements_provider.dart';

// ---------------------------------------------------------------------------
// Achievement definitions (static, matches Supabase achievement_id values)
// ---------------------------------------------------------------------------

class _AchievementDef {
  final String id;
  final String name;
  final String description;
  final int coinReward;

  const _AchievementDef(this.id, this.name, this.description, this.coinReward);
}

const _allAchievements = [
  // Progression
  _AchievementDef('first_word', 'First Word', 'Complete your first puzzle', 10),
  _AchievementDef(
      'getting_warmed_up', 'Getting Warmed Up', 'Complete 10 levels', 20),
  _AchievementDef(
      'puzzle_apprentice', 'Puzzle Apprentice', 'Complete 50 levels', 50),
  _AchievementDef('century', 'Century', 'Complete 100 levels', 100),
  _AchievementDef('vault_dweller', 'Vault Dweller',
      'Enter The Vault for the first time', 150),
  _AchievementDef(
      'boss_slayer', 'Boss Slayer', 'Complete your first boss level', 30),
  _AchievementDef(
      'unstoppable', 'Unstoppable', 'Complete 10 boss levels', 100),
  // Word Count
  _AchievementDef(
      'word_collector', 'Word Collector', 'Find 100 total words', 20),
  _AchievementDef('lexicon', 'Lexicon', 'Find 500 total words', 50),
  _AchievementDef('wordsmith', 'Wordsmith', 'Find 1,000 total words', 100),
  _AchievementDef(
      'grand_lexicon', 'Grand Lexicon', 'Find 5,000 total words', 250),
  // Skill
  _AchievementDef('no_hints_needed', 'No Hints Needed',
      'Complete 10 levels in a row without hints', 50),
  _AchievementDef('first_try', 'First Try',
      'Submit correct word on first attempt 50 times', 75),
  _AchievementDef('perfectionist', 'Perfectionist',
      'Complete a boss level without hints', 100),
  // Streaks
  _AchievementDef(
      'consistent', 'Consistent', 'Maintain a 7-day streak', 50),
  _AchievementDef(
      'dedicated', 'Dedicated', 'Maintain a 30-day streak', 150),
  _AchievementDef('obsessed', 'Obsessed', 'Maintain a 100-day streak', 500),
  // Economy
  _AchievementDef(
      'saver', 'Saver', 'Accumulate 500 coins without spending', 50),
  _AchievementDef(
      'high_roller', 'High Roller', 'Spend 1,000 coins total', 75),
  // Mastery
  _AchievementDef(
      'master_of_words',
      'Master of Words',
      'Complete all 200 hand-crafted levels without skipping',
      500),
];

// ---------------------------------------------------------------------------
// AchievementsScreen
// ---------------------------------------------------------------------------

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Achievements',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: unlockedAsync.when(
        data: (unlocked) {
          final unlockedMap = <String, DateTime>{
            for (final u in unlocked) u.achievementId: u.unlockedAt,
          };
          final unlockedCount =
              _allAchievements.where((a) => unlockedMap.containsKey(a.id)).length;

          return Column(
            children: [
              // Progress summary
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: AppColors.accent, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '$unlockedCount / ${_allAchievements.length} unlocked',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Achievement list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _allAchievements.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final def = _allAchievements[index];
                    final unlockedAt = unlockedMap[def.id];
                    final isUnlocked = unlockedAt != null;
                    return _AchievementTile(
                      def: def,
                      isUnlocked: isUnlocked,
                      unlockedAt: unlockedAt,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading achievements: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AchievementTile
// ---------------------------------------------------------------------------

class _AchievementTile extends StatelessWidget {
  final _AchievementDef def;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _AchievementTile({
    required this.def,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.accent.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isUnlocked ? AppColors.accent : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.emoji_events,
          color: isUnlocked ? AppColors.accent : Colors.grey.shade400,
          size: 22,
        ),
      ),
      title: Text(
        def.name,
        style: TextStyle(
          color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight:
              isUnlocked ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            def.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (isUnlocked && unlockedAt != null)
            Text(
              'Unlocked ${_formatDate(unlockedAt!)}',
              style: TextStyle(
                color: AppColors.accent.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on,
              color: AppColors.accent, size: 14),
          const SizedBox(width: 3),
          Text(
            '+${def.coinReward}',
            style: TextStyle(
              color: isUnlocked ? AppColors.accent : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
