// lib/features/shop/screens/shop_screen.dart
// Phase 7 — Ads & Monetization
// Spec: master-development-plan.md § Shop Screen, IAP, Rewarded Video
//
// Coin shop — lets players:
//   1. Watch a rewarded video for 30 coins (free; shown to all users).
//   2. Purchase coin bundles via RevenueCat (IAP).
//
// Rules:
//   - Coins are NEVER awarded client-side. All awards go through Edge Functions.
//   - Non-paying users see a banner about ad removal.
//   - "Best Value" badge on coins_6000.
//   - Idempotency key passed to on-rewarded-ad to prevent double-award.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/ad_service.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/shop_provider.dart';

// Coin amounts matched to RevenueCat product identifiers.
const Map<String, int> _productCoins = {
  'coins_500': 500,
  'coins_1200': 1200,
  'coins_2500': 2500,
  'coins_6000': 6000,
};
const String _bestValueProductId = 'coins_6000';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _adLoading = false;

  @override
  void initState() {
    super.initState();
    // Track shop_viewed on entry — fire-and-forget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coinBalance = ref.read(coinBalanceProvider).value ?? 0;
      final isPayingUser =
          ref.read(revenueCatServiceProvider).isPayingUser;
      ref.read(analyticsServiceProvider).trackShopViewed(
            coinBalance: coinBalance,
            isPayingUser: isPayingUser,
          );
    });
  }

  // ── Rewarded ad ─────────────────────────────────────────────────────────

  Future<void> _watchAdForCoins() async {
    final rewardedAdService = ref.read(rewardedAdServiceProvider);
    if (!rewardedAdService.isReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not available right now. Try again in a moment.'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    setState(() => _adLoading = true);

    await rewardedAdService.showAd(
      coinsToAward: 30,
      onRewarded: (coins) async {
        // Award via Edge Function — never client-side.
        try {
          final supabaseService = ref.read(supabaseServiceProvider);
          await supabaseService.callEdgeFunction(
            'on-rewarded-ad',
            body: {
              'ad_unit_id': RewardedAdService.adUnitId,
              'coins_to_award': coins,
              'idempotency_key': const Uuid().v4(),
            },
          );
          ref.invalidate(coinBalanceProvider);
          final newBalance = ref.read(coinBalanceProvider).value ?? 0;
          ref.read(analyticsServiceProvider).trackRewardedAdCompleted(
                placement: 'shop',
                coinsAwarded: coins,
                coinBalanceAfter: newBalance,
              );
        } catch (e) {
          debugPrint('[ShopScreen] on-rewarded-ad edge function error: $e');
        }
      },
      onDismissed: () {
        if (!mounted) return;
        setState(() => _adLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('30 coins added!'),
            backgroundColor: AppColors.feedbackCorrect,
          ),
        );
      },
    );
  }

  // ── IAP purchase ─────────────────────────────────────────────────────────

  Future<void> _purchasePackage(Package package) async {
    ref.read(shopPurchaseStateProvider.notifier).state =
        PurchaseState.purchasing;

    final revenueCat = ref.read(revenueCatServiceProvider);
    final result = await revenueCat.purchasePackage(package);

    if (result == null) {
      // User cancelled or error — PurchasesErrorCode already logged.
      ref.read(shopPurchaseStateProvider.notifier).state =
          PurchaseState.cancelled;
      if (!mounted) return;
      ref.read(shopPurchaseStateProvider.notifier).state = PurchaseState.idle;
      return;
    }

    // Successful purchase — invalidate UI, fire analytics.
    ref.invalidate(coinBalanceProvider);
    ref.invalidate(isPayingUserProvider);
    ref.read(shopPurchaseStateProvider.notifier).state = PurchaseState.success;

    final productId = package.storeProduct.identifier;
    final coinsAwarded = _productCoins[productId] ?? 0;
    final revenueUsd = package.storeProduct.price;
    final newBalance = ref.read(coinBalanceProvider).value ?? 0;

    ref.read(analyticsServiceProvider).trackIapPurchase(
          productId: productId,
          revenueUsd: revenueUsd,
          coinsAwarded: coinsAwarded,
          coinBalanceAfter: newBalance,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$coinsAwarded coins added!'),
        backgroundColor: AppColors.feedbackCorrect,
      ),
    );
    ref.read(shopPurchaseStateProvider.notifier).state = PurchaseState.idle;
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  Future<void> _restorePurchases() async {
    final revenueCat = ref.read(revenueCatServiceProvider);
    await revenueCat.restorePurchases();
    ref.invalidate(isPayingUserProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Purchases restored.'),
        backgroundColor: AppColors.surface,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final coinBalanceAsync = ref.watch(coinBalanceProvider);
    final packagesAsync = ref.watch(availablePackagesProvider);
    final purchaseState = ref.watch(shopPurchaseStateProvider);
    final rewardedAdService = ref.watch(rewardedAdServiceProvider);
    final isPayingUser =
        ref.watch(revenueCatServiceProvider).isPayingUser;

    final isPurchasing = purchaseState == PurchaseState.purchasing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Coin Shop',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Coin balance display ──────────────────────────────────────
            _CoinBalanceCard(coinBalanceAsync: coinBalanceAsync),
            const SizedBox(height: 16),

            // ── Ad removal banner for non-paying users ────────────────────
            if (!isPayingUser) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.block,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Buy any bundle to remove ads forever',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Free Coins section ────────────────────────────────────────
            const Text(
              'Free Coins',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: (_adLoading || !rewardedAdService.isReady)
                  ? null
                  : _watchAdForCoins,
              icon: _adLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_circle_outline),
              label: Text(
                _adLoading
                    ? 'Loading…'
                    : rewardedAdService.isReady
                        ? 'Watch Ad for 30 Coins'
                        : 'Ad not available',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Coin Bundles section ──────────────────────────────────────
            const Text(
              'Coin Bundles',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            packagesAsync.when(
              data: (packages) {
                if (packages.isEmpty) {
                  return const _BundlesUnavailablePlaceholder();
                }
                return Column(
                  children: packages.map((pkg) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CoinBundleCard(
                        package: pkg,
                        coinsForProduct: _productCoins[
                                pkg.storeProduct.identifier] ??
                            0,
                        isBestValue:
                            pkg.storeProduct.identifier == _bestValueProductId,
                        isPurchasing: isPurchasing,
                        onTap: isPurchasing
                            ? null
                            : () => _purchasePackage(pkg),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, err) => const _BundlesUnavailablePlaceholder(),
            ),
            const SizedBox(height: 24),

            // ── Restore Purchases ─────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: isPurchasing ? null : _restorePurchases,
                child: const Text(
                  'Restore Purchases',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subwidgets
// ---------------------------------------------------------------------------

class _CoinBalanceCard extends StatelessWidget {
  final AsyncValue<int> coinBalanceAsync;

  const _CoinBalanceCard({required this.coinBalanceAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.accent, size: 32),
          const SizedBox(width: 10),
          coinBalanceAsync.when(
            data: (balance) => Text(
              '$balance',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, err) => const Text(
              '--',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'coins',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _CoinBundleCard extends StatelessWidget {
  final Package package;
  final int coinsForProduct;
  final bool isBestValue;
  final bool isPurchasing;
  final VoidCallback? onTap;

  const _CoinBundleCard({
    required this.package,
    required this.coinsForProduct,
    required this.isBestValue,
    required this.isPurchasing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: isBestValue
                  ? Border.all(color: AppColors.accent, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: AppColors.accent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$coinsForProduct coins',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.title.isNotEmpty
                            ? product.title
                            : product.identifier,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                isPurchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        product.priceString,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
          ),
        ),

        // "Best Value" badge
        if (isBestValue)
          Positioned(
            top: 0,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Best Value',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BundlesUnavailablePlaceholder extends StatelessWidget {
  const _BundlesUnavailablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.store_outlined, color: AppColors.textSecondary, size: 40),
          SizedBox(height: 12),
          Text(
            'Coin bundles coming soon',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
