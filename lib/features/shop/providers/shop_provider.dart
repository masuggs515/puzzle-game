// lib/features/shop/providers/shop_provider.dart
// Phase 7 — Ads & Monetization
// Spec: master-development-plan.md § IAP / RevenueCat Integration
//
// Provides RevenueCatService and derived state for the shop screen.
// revenueCatServiceProvider is overridden in main.dart with the singleton
// initialised before runApp so purchases work immediately on launch.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../data/services/revenue_cat_service.dart';

// ── RevenueCat singleton ──────────────────────────────────────────────────

/// Single RevenueCatService instance, overridden in main.dart ProviderScope.
final revenueCatServiceProvider = Provider<RevenueCatService>(
  (ref) => RevenueCatService(),
);

// ── Derived async state ───────────────────────────────────────────────────

/// Refreshes and returns whether the user has made any IAP purchase.
/// Invalidate after a successful purchase to update the UI.
final isPayingUserProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(revenueCatServiceProvider);
  await service.refreshCustomerInfo();
  return service.isPayingUser;
});

/// Loads and returns the list of available coin bundle packages.
final availablePackagesProvider = FutureProvider<List<Package>>((ref) async {
  final service = ref.read(revenueCatServiceProvider);
  await service.loadOfferings();
  return service.availablePackages;
});

// ── Purchase state ────────────────────────────────────────────────────────

enum PurchaseState { idle, purchasing, success, error, cancelled }

/// Tracks the lifecycle of an in-progress purchase in the shop screen.
final shopPurchaseStateProvider =
    StateProvider<PurchaseState>((ref) => PurchaseState.idle);
