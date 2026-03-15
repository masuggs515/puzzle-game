// lib/data/services/ad_service.dart
// Phase 7 — Ads & Monetization
// Spec: master-development-plan.md § Ad Strategy
//
// Three classes:
//   AdFrequencyManager — tracks when interstitial ads are due.
//   InterstitialAdService — loads and shows interstitial ads.
//   RewardedAdService — loads and shows rewarded video ads.
//
// All ad failures are silent — never throw, never crash the game.
// Ads are pre-loaded immediately after being shown so there is always
// a ready ad for the next opportunity.

import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/config/env.dart';

// ---------------------------------------------------------------------------
// AdFrequencyManager
// Spec: master-development-plan.md § Interstitial Ad Policy
// ---------------------------------------------------------------------------

/// Tracks how many levels have passed since the last interstitial ad.
/// Threshold is randomised between [minLevelsBetweenAds] and
/// [maxLevelsBetweenAds] inclusive to avoid a mechanical feel.
class AdFrequencyManager {
  static const int minLevelsBetweenAds = 4;
  static const int maxLevelsBetweenAds = 5;

  int _levelsSinceLastAd = 0;
  late int _nextAdThreshold;

  AdFrequencyManager() {
    _nextAdThreshold = _randomThreshold();
  }

  int _randomThreshold() =>
      minLevelsBetweenAds +
      Random().nextInt(maxLevelsBetweenAds - minLevelsBetweenAds + 1);

  /// Returns true when an interstitial ad should be shown.
  ///
  /// Always increments the level counter. Paying users and boss levels
  /// NEVER trigger an ad — the counter still advances so the cadence is
  /// maintained (we do not penalise players for completing boss levels).
  bool shouldShowAd({
    required bool isBossLevel,
    required bool isPayingUser,
  }) {
    _levelsSinceLastAd++;

    if (isPayingUser) return false;
    if (isBossLevel) return false;

    if (_levelsSinceLastAd >= _nextAdThreshold) {
      _levelsSinceLastAd = 0;
      _nextAdThreshold = _randomThreshold();
      return true;
    }
    return false;
  }

  /// Levels completed since the last interstitial ad was shown.
  int get levelsSinceLastAd => _levelsSinceLastAd;

  /// Resets the counter — used in tests and after a fresh install.
  void reset() {
    _levelsSinceLastAd = 0;
    _nextAdThreshold = _randomThreshold();
  }
}

// ---------------------------------------------------------------------------
// InterstitialAdService
// Spec: master-development-plan.md § Interstitial Ad Policy
// ---------------------------------------------------------------------------

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  static String get adUnitId => Platform.isIOS
      ? Env.admobInterstitialIos
      : Env.admobInterstitialAndroid;

  /// Loads the next interstitial ad. No-op when the unit ID is empty
  /// (dev builds without AdMob credentials).
  Future<void> loadAd() async {
    if (adUnitId.isEmpty) {
      debugPrint('[InterstitialAdService] Skipped — ad unit ID is empty');
      return;
    }
    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdReady = true;
            debugPrint('[InterstitialAdService] Ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isAdReady = false;
            debugPrint('[InterstitialAdService] Failed to load: $error');
          },
        ),
      );
    } catch (e) {
      _isAdReady = false;
      debugPrint('[InterstitialAdService] loadAd error: $e');
    }
  }

  /// Shows the interstitial ad. Always calls [onAdDismissed] — even if the
  /// ad is not ready or fails to show — so callers never get stuck.
  Future<void> showAd({required void Function() onAdDismissed}) async {
    if (!_isAdReady || _interstitialAd == null) {
      debugPrint('[InterstitialAdService] Not ready — skipping');
      onAdDismissed();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isAdReady = false;
        loadAd(); // Pre-load the next ad
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[InterstitialAdService] Failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _isAdReady = false;
        loadAd(); // Pre-load the next ad
        onAdDismissed();
      },
    );

    try {
      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('[InterstitialAdService] show() error: $e');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isAdReady = false;
      loadAd();
      onAdDismissed();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdReady = false;
  }
}

// ---------------------------------------------------------------------------
// RewardedAdService
// Spec: master-development-plan.md § Rewarded Video Ad Policy
// ---------------------------------------------------------------------------

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isAdReady = false;

  static String get adUnitId => Platform.isIOS
      ? Env.admobRewardedIos
      : Env.admobRewardedAndroid;

  bool get isReady => _isAdReady;

  /// Loads the next rewarded ad. No-op when the unit ID is empty.
  Future<void> loadAd() async {
    if (adUnitId.isEmpty) {
      debugPrint('[RewardedAdService] Skipped — ad unit ID is empty');
      return;
    }
    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isAdReady = true;
            debugPrint('[RewardedAdService] Ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isAdReady = false;
            debugPrint('[RewardedAdService] Failed to load: $error');
          },
        ),
      );
    } catch (e) {
      _isAdReady = false;
      debugPrint('[RewardedAdService] loadAd error: $e');
    }
  }

  /// Shows the rewarded ad.
  ///
  /// [coinsToAward] is passed through to [onRewarded] — the CALLER is
  /// responsible for calling the edge function. Coins are NEVER awarded
  /// client-side here.
  ///
  /// Always calls [onDismissed] — even if the ad fails to show.
  Future<void> showAd({
    required int coinsToAward,
    required void Function(int coins) onRewarded,
    required void Function() onDismissed,
  }) async {
    if (!_isAdReady || _rewardedAd == null) {
      debugPrint('[RewardedAdService] Not ready — skipping');
      onDismissed();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        loadAd(); // Pre-load the next ad
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[RewardedAdService] Failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        loadAd(); // Pre-load the next ad
        onDismissed();
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // Caller handles the edge function call — never award coins here.
          onRewarded(coinsToAward);
        },
      );
    } catch (e) {
      debugPrint('[RewardedAdService] show() error: $e');
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _isAdReady = false;
      loadAd();
      onDismissed();
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdReady = false;
  }
}
