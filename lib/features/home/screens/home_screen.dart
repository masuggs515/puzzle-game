// lib/features/home/screens/home_screen.dart
// Phase 2 — Foundation
// Spec: master-development-plan.md § 2.4 Player Profile Screen
//
// Replaces the Phase 1 hello-world with a real player profile screen.
// All data is fetched from Supabase — no hardcoded values.
// "Start Game" and navigation to auth screens wired up here.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/puzzle_engine/screens/puzzle_debug_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final coinAsync = ref.watch(coinBalanceProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Game'),
        actions: [
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
        data: (profile) => _ProfileBody(
          profile: profile,
          coinAsync: coinAsync,
          isGuest: profile?.isGuest ?? true,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final dynamic profile; // PlayerProfile?
  final AsyncValue<int> coinAsync;
  final bool isGuest;

  const _ProfileBody({
    required this.profile,
    required this.coinAsync,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 32),

          // Stats
          _StatsRow(
            coins: coinAsync.whenData((v) => v).value ?? 0,
            streak: profile?.currentStreak ?? 0,
            wordsFound: profile?.totalWordsFound ?? 0,
            loading: profile == null,
          ),
          const SizedBox(height: 40),

          // Start Game — navigates to level 1
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/game/1'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Start Game', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
          const SizedBox(height: 16),

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
