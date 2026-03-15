// lib/features/home/screens/home_screen.dart
// Phase 5 — Economy & Progression (extended from Phase 2)
// Spec: flutter-agent-spec.md § World Map
//
// Shows player stats and a scrollable world-map level grid.
// Levels unlock sequentially — level N requires level N-1 to be completed.
// Boss levels (8, 15, 24, 32, 42, 50) have a gold visual treatment.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/home/providers/home_provider.dart';
import '../../../features/puzzle_engine/screens/puzzle_debug_screen.dart';

// Boss level numbers for the hand-crafted set (1–50).
const _bossLevels = {8, 15, 24, 32, 42, 50};
const _totalHandcraftedLevels = 50;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final coinAsync = ref.watch(coinBalanceProvider);
    final user = ref.watch(currentUserProvider);
    final progressAsync = ref.watch(levelProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Game'),
        actions: [
          // Achievements button
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Achievements',
            onPressed: () => context.go('/achievements'),
          ),
          if (user != null && !(user.isAnonymous))
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () async {
                await ref.read(supabaseServiceProvider).signOut();
              },
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _HomeBody(
          profile: profile,
          coinAsync: coinAsync,
          progressAsync: progressAsync,
          isGuest: profile?.isGuest ?? true,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final dynamic profile; // PlayerProfile?
  final AsyncValue<int> coinAsync;
  final AsyncValue<List<LevelProgress>> progressAsync;
  final bool isGuest;

  const _HomeBody({
    required this.profile,
    required this.coinAsync,
    required this.progressAsync,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    // Build a fast lookup: levelNumber → LevelProgress
    final progressMap = <int, LevelProgress>{};
    progressAsync.whenData((list) {
      for (final p in list) {
        progressMap[p.levelNumber] = p;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Text(
            'Welcome, ${profile?.welcomeName ?? 'Guest'}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          if (isGuest)
            Text(
              'Playing as guest — create an account to save your progress across devices.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          const SizedBox(height: 24),

          // Stats
          _StatsRow(
            coins: coinAsync.whenData((v) => v).value ?? 0,
            streak: profile?.currentStreak ?? 0,
            wordsFound: profile?.totalWordsFound ?? 0,
            loading: profile == null,
          ),
          const SizedBox(height: 32),

          // World map label
          Text(
            'Levels',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Level grid
          _LevelGrid(progressMap: progressMap),

          // The Vault entry banner
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: GestureDetector(
              onTap: () => context.go('/vault'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C1D95), Color(0xFF6B21A8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_open, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Vault',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Infinite procedurally generated puzzles',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Create Account / already signed in
          if (isGuest)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/signup'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Create Account'),
                ),
              ),
            ),

          if (isGuest) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.push('/signin'),
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],

          // Debug-only: puzzle inspector — never shown in release builds
          if (kDebugMode) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PuzzleDebugScreen(),
                  ),
                ),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Debug Puzzles'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple.shade300,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level grid — 5 columns x 10 rows = 50 levels
// ---------------------------------------------------------------------------

class _LevelGrid extends StatelessWidget {
  final Map<int, LevelProgress> progressMap;

  const _LevelGrid({required this.progressMap});

  /// Level N is available if it is level 1 or level N-1 is completed.
  bool _isAvailable(int n) {
    if (n == 1) return true;
    final prev = progressMap[n - 1];
    return prev != null && prev.completed;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: _totalHandcraftedLevels,
      itemBuilder: (context, index) {
        final levelNumber = index + 1;
        final progress = progressMap[levelNumber];
        final completed = progress?.completed ?? false;
        final stars = progress?.stars;
        final isBoss = _bossLevels.contains(levelNumber);
        final available = _isAvailable(levelNumber);

        return _LevelNode(
          levelNumber: levelNumber,
          isBoss: isBoss,
          isCompleted: completed,
          isAvailable: available,
          stars: stars,
          onTap: available
              ? () => context.go('/game/$levelNumber')
              : () => _showLockedMessage(context, levelNumber),
        );
      },
    );
  }

  void _showLockedMessage(BuildContext context, int levelNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complete level ${levelNumber - 1} first.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LevelNode
// ---------------------------------------------------------------------------

class _LevelNode extends StatelessWidget {
  final int levelNumber;
  final bool isBoss;
  final bool isCompleted;
  final bool isAvailable;
  final int? stars; // null = not yet completed
  final VoidCallback onTap;

  const _LevelNode({
    required this.levelNumber,
    required this.isBoss,
    required this.isCompleted,
    required this.isAvailable,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (!isAvailable) {
      bgColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade400;
      textColor = Colors.grey.shade600;
    } else if (isBoss) {
      bgColor = isCompleted
          ? AppColors.accent.withValues(alpha: 0.3)
          : AppColors.accent.withValues(alpha: 0.15);
      borderColor = AppColors.accent;
      textColor = AppColors.textPrimary;
    } else if (isCompleted) {
      bgColor = AppColors.feedbackCorrect.withValues(alpha: 0.2);
      borderColor = AppColors.feedbackCorrect;
      textColor = AppColors.textPrimary;
    } else {
      bgColor = AppColors.primary.withValues(alpha: 0.15);
      borderColor = AppColors.primary;
      textColor = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isBoss ? 2 : 1.5),
        ),
        child: Stack(
          children: [
            // Level number — centred
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBoss && !isAvailable)
                    const Icon(Icons.lock, size: 12, color: Colors.grey)
                  else if (!isAvailable)
                    const Icon(Icons.lock, size: 12, color: Colors.grey),
                  Text(
                    '$levelNumber',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Boss star badge (top-right corner)
            if (isBoss)
              const Positioned(
                top: 3,
                right: 3,
                child: Icon(Icons.star, color: AppColors.accent, size: 10),
              ),

            // Star rating (bottom — only when completed)
            if (isCompleted && stars != null)
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Icon(
                      i < stars! ? Icons.star : Icons.star_outline,
                      color: AppColors.accent,
                      size: 8,
                    ),
                  ),
                ),
              ),

            // Skipped indicator (completed but no stars)
            if (isCompleted && stars == null)
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Center(
                  child: Icon(
                    Icons.skip_next,
                    color: Colors.grey.shade500,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatsRow
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final int coins;
  final int streak;
  final int wordsFound;
  final bool loading;

  const _StatsRow({
    required this.coins,
    required this.streak,
    required this.wordsFound,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCard(label: 'Coins', value: loading ? '—' : '$coins'),
        _StatCard(label: 'Streak', value: loading ? '—' : '$streak days'),
        _StatCard(label: 'Words', value: loading ? '—' : '$wordsFound'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
