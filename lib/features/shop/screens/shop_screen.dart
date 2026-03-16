// lib/features/shop/screens/shop_screen.dart
// Phase 7 — Ads & Monetization
// Phase 9 — MERIDIAN design polish
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
import '../../../core/widgets/graph_paper_background.dart';
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
        ),
      );
      return;
    }

    setState(() => _adLoading = true);

    await rewardedAdService.showAd(
      coinsToAward: 30,
      onRewarded: (coins) async {
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
          const SnackBar(content: Text('30 coins added!')),
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
      ref.read(shopPurchaseStateProvider.notifier).state =
          PurchaseState.cancelled;
      if (!mounted) return;
      ref.read(shopPurchaseStateProvider.notifier).state = PurchaseState.idle;
      return;
    }

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
      SnackBar(content: Text('$coinsAwarded coins added!')),
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
      const SnackBar(content: Text('Purchases restored.')),
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
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.desk,
        leading: BackButton(
          color: AppColors.parchment,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '\u25c6 FIELD SUPPLY',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.parchment,
            letterSpacing: 2.0,
          ),
        ),
        elevation: 0,
      ),
      body: GraphPaperBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Coin balance ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  coinBalanceAsync.when(
                    data: (balance) => Text(
                      '$balance \u25c8',
                      style: const TextStyle(
                        fontFamily: 'CourierPrime',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.signal,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, err) => const Text(
                      '-- \u25c8',
                      style: TextStyle(
                        fontFamily: 'CourierPrime',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.signal,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Remove ads banner for non-paying users ────────────────────
              if (!isPayingUser) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.signal.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        '\u25c6',
                        style: TextStyle(color: AppColors.signal, fontSize: 12),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Buy any bundle to remove ads forever',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 11,
                            color: AppColors.parchment,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Free Fragments section ────────────────────────────────────
              const Text(
                '\u2592 FREE FRAGMENTS',
                style: TextStyle(
                  fontFamily: 'SpecialElite',
                  fontSize: 10,
                  color: AppColors.inkFaded,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x14C8651A),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppColors.signal.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Watch for 30 \u25c8',
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.ink,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const Text(
                            'Watch a short video to earn 30 coins',
                            style: TextStyle(
                              fontFamily: 'SpecialElite',
                              fontSize: 9,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: (_adLoading || !rewardedAdService.isReady)
                            ? null
                            : _watchAdForCoins,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.signal,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: _adLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.ink,
                                ),
                              )
                            : Text(
                                rewardedAdService.isReady
                                    ? 'Watch'
                                    : 'Unavailable',
                                style: const TextStyle(
                                  fontFamily: 'Oswald',
                                  fontSize: 11,
                                  color: AppColors.ink,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Coin Bundles section ──────────────────────────────────────
              const Text(
                '\u2592 COIN BUNDLES',
                style: TextStyle(
                  fontFamily: 'SpecialElite',
                  fontSize: 10,
                  color: AppColors.inkFaded,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              packagesAsync.when(
                data: (packages) {
                  if (packages.isEmpty) {
                    return const _BundlesUnavailablePlaceholder();
                  }
                  // 2-column grid using Wrap
                  final cards = packages.map((pkg) {
                    return _CoinBundleCard(
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
                    );
                  }).toList();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth =
                          (constraints.maxWidth - 8) / 2;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cards
                            .map((c) => SizedBox(width: itemWidth, child: c))
                            .toList(),
                      );
                    },
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

              const SizedBox(height: 20),

              // ── Restore Purchases ─────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: isPurchasing ? null : _restorePurchases,
                  child: const Text(
                    'Restore Purchases',
                    style: TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 10,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subwidgets
// ---------------------------------------------------------------------------

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
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.aged,
              borderRadius: BorderRadius.circular(5),
              border: isBestValue
                  ? Border.all(color: AppColors.signal, width: 2)
                  : Border.all(color: const Color(0x1A1C1410)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$coinsForProduct \u25c8',
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.signal,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.title.isNotEmpty
                      ? product.title
                      : product.identifier,
                  style: const TextStyle(
                    fontFamily: 'SpecialElite',
                    fontSize: 9,
                    color: AppColors.inkFaded,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                isPurchasing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.signal,
                        ),
                      )
                    : Text(
                        product.priceString,
                        style: const TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.ink,
                        ),
                      ),
              ],
            ),
          ),
        ),

        // "BEST VALUE" badge
        if (isBestValue)
          Positioned(
            top: 0,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.signal,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(2),
                ),
              ),
              child: const Text(
                'BEST VALUE',
                style: TextStyle(
                  fontFamily: 'CourierPrime',
                  color: AppColors.ink,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
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
        color: const Color(0x0A1C1410),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0x1A1C1410)),
      ),
      child: const Column(
        children: [
          Text(
            '\u25c6',
            style: TextStyle(color: AppColors.deepAged, fontSize: 28),
          ),
          SizedBox(height: 8),
          Text(
            'Coin bundles coming soon',
            style: TextStyle(
              fontFamily: 'SpecialElite',
              fontSize: 11,
              color: AppColors.inkFaded,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
