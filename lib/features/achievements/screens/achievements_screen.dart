// lib/features/achievements/screens/achievements_screen.dart
// Phase 5 — Economy & Progression
// Phase 9 — MERIDIAN design polish
// Spec: flutter-agent-spec.md § Achievements Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/graph_paper_background.dart';
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
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.desk,
        title: const Text(
          '\u25c8 DOSSIER',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.parchment,
            letterSpacing: 2.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.parchment),
          onPressed: () => context.go('/home'),
        ),
        elevation: 0,
      ),
      body: GraphPaperBackground(
        child: unlockedAsync.when(
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
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        '$unlockedCount / ${_allAchievements.length} CLEARED',
                        style: const TextStyle(
                          fontFamily: 'CourierPrime',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.signal,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: const Color(0x1A1C1410)),
                // Achievement list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allAchievements.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final def = _allAchievements[index];
                      final unlockedAt = unlockedMap[def.id];
                      final isUnlocked = unlockedAt != null;
                      return _AchievementCard(
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Error loading achievements: $e',
              style: const TextStyle(color: AppColors.inkFaded),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AchievementCard
// ---------------------------------------------------------------------------

class _AchievementCard extends StatelessWidget {
  final _AchievementDef def;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _AchievementCard({
    required this.def,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0A1C1410),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: isUnlocked ? AppColors.verdigris : Colors.transparent,
              width: 3,
            ),
            top: const BorderSide(color: Color(0x1A1C1410)),
            right: const BorderSide(color: Color(0x1A1C1410)),
            bottom: const BorderSide(color: Color(0x1A1C1410)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.name,
                    style: const TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    def.description,
                    style: const TextStyle(
                      fontFamily: 'CourierPrime',
                      fontSize: 10,
                      color: AppColors.inkFaded,
                    ),
                  ),
                  if (isUnlocked && unlockedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Cleared ${_formatDate(unlockedAt!)}',
                      style: TextStyle(
                        fontFamily: 'CourierPrime',
                        fontSize: 9,
                        color: AppColors.verdigris.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '+${def.coinReward} \u25c8',
              style: TextStyle(
                fontFamily: 'CourierPrime',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isUnlocked ? AppColors.signal : AppColors.inkFaded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
