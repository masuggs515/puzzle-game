// lib/features/vault/screens/vault_screen.dart
// Phase 8 — The Vault
// Spec: flutter-agent-spec.md § The Vault
//
// World map screen for vault levels. Shows an infinite series of procedurally
// generated puzzles. Vault boss levels are every 10th vault level.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_game/features/auth/providers/auth_provider.dart';
import 'package:puzzle_game/features/vault/providers/vault_provider.dart';

// ---------------------------------------------------------------------------
// Vault visual constants
// ---------------------------------------------------------------------------

const _kVaultBackground = Color(0xFF0D0D1A);
const _kVaultPurple = Color(0xFF6B21A8);
const _kVaultPurpleLight = Color(0xFF9333EA);
const _kVaultLocked = Color(0xFF1F1B2E);
const _kVaultLockedBorder = Color(0xFF3D2D5A);

// Vault boss levels — every 10th vault level.
bool _isVaultBoss(int vaultLevel) => vaultLevel % 10 == 0;

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  @override
  void initState() {
    super.initState();
    // Fire vault_entered analytics after first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentVaultLevel = ref.read(currentVaultLevelProvider);
      final coinBalance = ref.read(coinBalanceProvider).value ?? 0;
      ref.read(analyticsServiceProvider).trackVaultEntered(
            isFirstTime: currentVaultLevel == 0,
            levelsCompleted: currentVaultLevel,
            coinBalance: coinBalance,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentVaultLevel = ref.watch(currentVaultLevelProvider);
    final coinAsync = ref.watch(coinBalanceProvider);

    // Display levels from 1 up to currentVaultLevel + 5
    // (always show 5 unlocked levels ahead so there is always progress to make).
    final displayCount = currentVaultLevel + 5;

    return Scaffold(
      backgroundColor: _kVaultBackground,
      appBar: AppBar(
        backgroundColor: _kVaultBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'The Vault',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          // Coin balance display
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD166), size: 18),
                const SizedBox(width: 4),
                Text(
                  '${coinAsync.value ?? 0}',
                  style: const TextStyle(
                    color: Color(0xFFFFD166),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Welcome banner
          SliverToBoxAdapter(
            child: _WelcomeBanner(currentVaultLevel: currentVaultLevel),
          ),

          // Progress label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                currentVaultLevel == 0
                    ? 'Your Vault Journey Begins'
                    : 'Vault Level $currentVaultLevel Reached',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Level grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final vaultLevel = index + 1;
                  final isCompleted = vaultLevel <= currentVaultLevel;
                  // Available = completed + 1 ahead (next unlocked level)
                  final isAvailable = vaultLevel <= currentVaultLevel + 1;
                  final isBoss = _isVaultBoss(vaultLevel);

                  return _VaultLevelNode(
                    vaultLevel: vaultLevel,
                    isBoss: isBoss,
                    isCompleted: isCompleted,
                    isAvailable: isAvailable,
                    onTap: isAvailable
                        ? () => context.go('/vault/$vaultLevel')
                        : null,
                  );
                },
                childCount: displayCount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _WelcomeBanner
// ---------------------------------------------------------------------------

class _WelcomeBanner extends StatelessWidget {
  final int currentVaultLevel;

  const _WelcomeBanner({required this.currentVaultLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF6B21A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kVaultPurple.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'ve conquered the main game.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Welcome to The Vault.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VaultLevelNode
// ---------------------------------------------------------------------------

class _VaultLevelNode extends StatelessWidget {
  final int vaultLevel;
  final bool isBoss;
  final bool isCompleted;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _VaultLevelNode({
    required this.vaultLevel,
    required this.isBoss,
    required this.isCompleted,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (!isAvailable) {
      bgColor = _kVaultLocked;
      borderColor = _kVaultLockedBorder;
      textColor = Colors.white30;
    } else if (isBoss) {
      bgColor = isCompleted
          ? const Color(0xFFFFD166).withValues(alpha: 0.25)
          : const Color(0xFFFFD166).withValues(alpha: 0.10);
      borderColor = const Color(0xFFFFD166);
      textColor = Colors.white;
    } else if (isCompleted) {
      bgColor = _kVaultPurple.withValues(alpha: 0.5);
      borderColor = _kVaultPurpleLight;
      textColor = Colors.white;
    } else {
      bgColor = const Color(0xFF1E1030);
      borderColor = _kVaultPurple;
      textColor = Colors.white;
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
            // Level label — centred
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isAvailable)
                    Icon(Icons.lock, size: 12, color: Colors.white.withValues(alpha: 0.3)),
                  Text(
                    'V$vaultLevel',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: vaultLevel >= 100 ? 11 : 13,
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
                child: Icon(Icons.star, color: Color(0xFFFFD166), size: 10),
              ),

            // Completed indicator (bottom — star icon)
            if (isCompleted)
              const Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Center(
                  child: Icon(Icons.star, color: Color(0xFFFFD166), size: 9),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
