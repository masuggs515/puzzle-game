// lib/features/home/screens/home_screen.dart
// Phase 5 — Economy & Progression (extended from Phase 2)
// Phase 9 — MERIDIAN design polish
// Spec: flutter-agent-spec.md § World Map
//
// Shows player stats and a scrollable world-map level grid.
// Levels unlock sequentially — level N requires level N-1 to be completed.
// Boss levels (8, 15, 24, 32, 42, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100) have a gold visual treatment.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/graph_paper_background.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/home/providers/home_provider.dart';
import '../../../features/puzzle_engine/screens/puzzle_debug_screen.dart';

// Boss level numbers for the hand-crafted set (1–100).
const _bossLevels = {8, 15, 24, 32, 42, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100};

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final coinAsync = ref.watch(coinBalanceProvider);
    final user = ref.watch(currentUserProvider);
    final progressAsync = ref.watch(levelProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: GraphPaperBackground(
        child: profileAsync.when(
          data: (profile) => _HomeBody(
            profile: profile,
            coinAsync: coinAsync,
            progressAsync: progressAsync,
            isGuest: profile?.isGuest ?? true,
            user: user,
            ref: ref,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading profile: $err')),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final dynamic profile;
  final AsyncValue<int> coinAsync;
  final AsyncValue<List<LevelProgress>> progressAsync;
  final bool isGuest;
  final dynamic user;
  final WidgetRef ref;

  const _HomeBody({
    required this.profile,
    required this.coinAsync,
    required this.progressAsync,
    required this.isGuest,
    required this.user,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final progressMap = <int, LevelProgress>{};
    progressAsync.whenData((list) {
      for (final p in list) {
        progressMap[p.levelNumber] = p;
      }
    });

    final coinBalance = coinAsync.whenData((v) => v).value ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INTERCEPT',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          letterSpacing: 3.96,
                        ),
                      ),
                      const Text(
                        'Field Transmission Decoder',
                        style: TextStyle(
                          fontFamily: 'SpecialElite',
                          fontSize: 9,
                          color: AppColors.inkFaded,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Coin balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$coinBalance \u25c8',
                      style: const TextStyle(
                        fontFamily: 'CourierPrime',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.signal,
                      ),
                    ),
                    if (user != null && !(user.isAnonymous))
                      GestureDetector(
                        onTap: () async {
                          await ref.read(supabaseServiceProvider).signOut();
                        },
                        child: const Text(
                          'Sign out',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 8,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Level grid with sector headers ────────────────────────────
            _SectoredLevelGrid(progressMap: progressMap),

            const SizedBox(height: 16),

            // ── Coming Soon banner ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.aged,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: AppColors.inkFaded.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MORE SIGNALS COMING SOON',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: AppColors.inkFaded,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          'New signal packs and modes in development',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 9,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Guest CTAs ────────────────────────────────────────────────
            if (isGuest) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x0A1C1410),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0x1A1C1410)),
                ),
                child: const Text(
                  'Playing as guest \u2014 create an account to save progress across devices.',
                  style: TextStyle(
                    fontFamily: 'SpecialElite',
                    fontSize: 9,
                    color: AppColors.inkFaded,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/signup'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.signal),
                    foregroundColor: AppColors.signal,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontFamily: 'Oswald', letterSpacing: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/signin'),
                  child: const Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 10,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
              ),
            ],

            // ── Debug-only ────────────────────────────────────────────────
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              const Divider(color: Color(0x1A1C1410)),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PuzzleDebugScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.search, size: 16, color: AppColors.inkFaded),
                  label: const Text(
                    'Debug Puzzles',
                    style: TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 10,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectoredLevelGrid — groups levels into sectors of 10 with headers
// ---------------------------------------------------------------------------

class _SectoredLevelGrid extends StatelessWidget {
  final Map<int, LevelProgress> progressMap;

  const _SectoredLevelGrid({required this.progressMap});

  bool _isAvailable(int n) {
    if (n == 1) return true;
    final prev = progressMap[n - 1];
    return prev != null && prev.completed;
  }

  @override
  Widget build(BuildContext context) {
    final sectors = <Widget>[];

    for (int sector = 0; sector < 10; sector++) {
      final startLevel = sector * 10 + 1;
      final endLevel = sector * 10 + 10;
      final sectorNum = (sector + 1).toString().padLeft(2, '0');

      // Sector header
      sectors.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              const Text(
                '\u25c6',
                style: TextStyle(color: AppColors.deepAged, fontSize: 8),
              ),
              const SizedBox(width: 6),
              Text(
                'SECTOR $sectorNum',
                style: const TextStyle(
                  fontFamily: 'SpecialElite',
                  fontSize: 8,
                  color: AppColors.inkFaded,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0x1A1C1410),
                ),
              ),
            ],
          ),
        ),
      );

      // 5-column grid for this sector
      final levelWidgets = <Widget>[];
      for (int level = startLevel; level <= endLevel; level++) {
        final progress = progressMap[level];
        final completed = progress?.completed ?? false;
        final stars = progress?.stars;
        final isBoss = _bossLevels.contains(level);
        final available = _isAvailable(level);

        levelWidgets.add(_LevelNode(
          levelNumber: level,
          isBoss: isBoss,
          isCompleted: completed,
          isAvailable: available,
          stars: stars,
          onTap: available
              ? () => context.go('/game/$level')
              : () => _showLockedMessage(context, level),
        ));
      }

      sectors.add(
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
          children: levelWidgets,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectors,
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
  final int? stars;
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
    final Border border;

    if (!isAvailable) {
      bgColor = AppColors.aged;
      border = Border.all(color: const Color(0x401C1410));
    } else if (isCompleted) {
      bgColor = AppColors.verdigris.withValues(alpha: 0.22);
      border = Border.all(
        color: isBoss ? AppColors.signal : AppColors.verdigris,
        width: isBoss ? 2 : 1.5,
      );
    } else {
      bgColor = AppColors.aged;
      border = Border.all(
        color: isBoss ? AppColors.signal : AppColors.signal.withValues(alpha: 0.7),
        width: isBoss ? 2 : 1.5,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
          border: border,
        ),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: Stack(
            children: [
              // Boss indicator (top-right)
              if (isBoss)
                const Positioned(
                  top: 2,
                  right: 3,
                  child: Text(
                    '\u2316',
                    style: TextStyle(color: AppColors.signal, fontSize: 9),
                  ),
                ),

              // Level number — centered
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isAvailable)
                      const Icon(Icons.lock,
                          size: 10, color: AppColors.inkFaded),
                    Text(
                      '$levelNumber',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: isAvailable ? AppColors.ink : AppColors.inkFaded,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Star rating (bottom — only when completed)
              if (isCompleted && stars != null)
                Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Text(
                        i < stars! ? '\u2605' : '\u2606',
                        style: TextStyle(
                          color: i < stars!
                              ? AppColors.tungsten
                              : AppColors.deepAged,
                          fontSize: 7,
                        ),
                      ),
                    ),
                  ),
                ),

              // Skipped indicator
              if (isCompleted && stars == null)
                Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      Icons.skip_next,
                      color: AppColors.inkFaded.withValues(alpha: 0.5),
                      size: 9,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
