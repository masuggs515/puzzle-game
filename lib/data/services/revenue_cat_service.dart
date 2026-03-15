// lib/data/services/revenue_cat_service.dart
// Phase 7 — Ads & Monetization
// Spec: master-development-plan.md § IAP / RevenueCat Integration
//
// Wraps the RevenueCat SDK. All calls are guarded against an empty
// REVENUECAT_KEY so dev builds without credentials work without crashing.
//
// Coin awards from IAP go through the on-rewarded-ad / on-iap-purchase
// Edge Functions — NEVER awarded client-side here.

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config/env.dart';

class RevenueCatService {
  // Cached synchronously — read in the interstitial-ad decision path where
  // async calls would add latency. Refreshed after every purchase and on init.
  bool _isPayingUser = false;
  List<Package> _availablePackages = [];

  // ── Initialization ──────────────────────────────────────────────────────

  /// Initializes RevenueCat. No-op when [Env.revenueCatKey] is empty.
  ///
  /// [appUserId] should be the Supabase auth UID so purchase history is
  /// linked to the player's account. Pass null on first launch — RevenueCat
  /// will use an anonymous ID until we have one.
  Future<void> initialize({String? appUserId}) async {
    if (Env.revenueCatKey.isEmpty) {
      debugPrint('[RevenueCat] NOT initialized — REVENUECAT_KEY is empty');
      return;
    }
    try {
      final configuration = PurchasesConfiguration(Env.revenueCatKey);
      if (appUserId != null) {
        configuration.appUserID = appUserId;
      }
      await Purchases.configure(configuration);
      await refreshCustomerInfo();
      await loadOfferings();
      debugPrint('[RevenueCat] initialized');
    } catch (e) {
      debugPrint('[RevenueCat] initialize error: $e');
    }
  }

  // ── Paying user status ──────────────────────────────────────────────────

  /// Returns the cached paying-user status synchronously.
  /// Call [refreshCustomerInfo] to update after a purchase.
  bool get isPayingUser => _isPayingUser;

  /// Refreshes paying-user status from RevenueCat.
  /// No-op when key is empty.
  Future<void> refreshCustomerInfo() async {
    if (Env.revenueCatKey.isEmpty) return;
    try {
      final info = await Purchases.getCustomerInfo();
      _isPayingUser = info.allPurchasedProductIdentifiers.isNotEmpty;
      debugPrint('[RevenueCat] isPayingUser=$_isPayingUser');
    } catch (e) {
      debugPrint('[RevenueCat] refreshCustomerInfo error: $e');
    }
  }

  // ── Offerings ──────────────────────────────────────────────────────────

  List<Package> get availablePackages => _availablePackages;

  /// Loads available offerings (coin bundles) from RevenueCat.
  Future<void> loadOfferings() async {
    if (Env.revenueCatKey.isEmpty) return;
    try {
      final offerings = await Purchases.getOfferings();
      _availablePackages = offerings.current?.availablePackages ?? [];
      debugPrint(
        '[RevenueCat] ${_availablePackages.length} package(s) loaded',
      );
    } catch (e) {
      debugPrint('[RevenueCat] loadOfferings error: $e');
      _availablePackages = [];
    }
  }

  // ── Purchase ──────────────────────────────────────────────────────────

  /// Purchases a package. Returns [CustomerInfo] on success, null on
  /// cancellation or error.
  ///
  /// The caller is responsible for calling the on-iap-purchase Edge Function
  /// to award coins — never award coins here.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      _isPayingUser = info.allPurchasedProductIdentifiers.isNotEmpty;
      debugPrint('[RevenueCat] Purchase complete — isPayingUser=$_isPayingUser');
      return info;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[RevenueCat] Purchase cancelled by user');
        return null;
      }
      debugPrint('[RevenueCat] purchase error (PurchasesErrorCode): $e');
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] purchase error: $e');
      return null;
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────

  /// Restores previous purchases (required by App Store / Google Play).
  Future<void> restorePurchases() async {
    if (Env.revenueCatKey.isEmpty) return;
    try {
      final info = await Purchases.restorePurchases();
      _isPayingUser = info.allPurchasedProductIdentifiers.isNotEmpty;
      debugPrint('[RevenueCat] Restore complete — isPayingUser=$_isPayingUser');
    } catch (e) {
      debugPrint('[RevenueCat] restorePurchases error: $e');
    }
  }
}
