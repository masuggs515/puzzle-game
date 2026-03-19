// lib/data/services/analytics_service.dart
// Phase 6 — Analytics
// Spec: analytics-agent-spec.md
//
// Dual-writes every event to Mixpanel (dashboard/funnels) and the Supabase
// analytics_events table (raw ownership). The Supabase write is non-blocking —
// never awaited, never fails the game.
//
// Privacy rules (non-negotiable):
//   1. Never send actual word strings to Mixpanel — word_length only.
//   2. Never send email addresses to Mixpanel.
//   3. No device identifiers — use Supabase auth.uid() as distinct ID.
//   4. No location data — trackAutomaticEvents: false in init.
//   5. No word list content ever appears in event properties.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_service.dart';

class AnalyticsService {
  final Mixpanel? _mixpanel;
  final SupabaseService _supabase;

  String _sessionId = const Uuid().v4();

  static const _sessionTimeout = Duration(minutes: 30);
  DateTime? _lastActivity;

  AnalyticsService(this._mixpanel, this._supabase) {
    if (_mixpanel != null && kDebugMode) {
      _mixpanel.setLoggingEnabled(true);
    }
  }

  // ── Session management ────────────────────────────────────────────────────

  /// Regenerates session ID on every foreground. Called from trackAppOpen().
  void _resetSession() {
    _sessionId = const Uuid().v4();
    _lastActivity = DateTime.now();
  }

  /// Updates last activity timestamp. Session ID rotates after 30 min idle.
  void _touchActivity() {
    final now = DateTime.now();
    if (_lastActivity != null &&
        now.difference(_lastActivity!) > _sessionTimeout) {
      _sessionId = const Uuid().v4();
    }
    _lastActivity = now;
  }

  // ── Core event dual-write ─────────────────────────────────────────────────

  /// Enriches [properties] with session/platform/version, fires to Mixpanel
  /// and non-blockingly writes to Supabase analytics_events.
  Future<void> _track(String eventName, Map<String, dynamic> properties) async {
    _touchActivity();

    final enriched = <String, dynamic>{
      ...properties,
      'session_id': _sessionId,
      'platform': _platformString(),
      'app_version': const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0',
      ),
    };

    // Mixpanel — dashboard and funnels
    _mixpanel?.track(eventName, properties: enriched);

    // Supabase — raw event ownership, non-blocking
    _supabase
        .trackEvent(eventName, enriched)
        .catchError((_) {/* Sentry capture handled inside SupabaseService */});
  }

  String _platformString() {
    try {
      return Platform.operatingSystem; // 'ios', 'android', 'macos', 'linux', 'windows'
    } catch (_) {
      return 'unknown';
    }
  }

  // ── Identity management ───────────────────────────────────────────────────

  /// Called immediately after an anonymous session is created.
  void identifyAnonymous(String userId) {
    _mixpanel?.identify(userId);
    _mixpanel?.getPeople().set('\$name', 'Guest');
    _mixpanel?.getPeople().set('account_type', 'guest');
  }

  /// Called after account creation — aliases anonymous history to the new ID.
  Future<void> identifyAuthenticated({
    required String userId,
    required String? displayName,
    required DateTime createdAt,
  }) async {
    // Alias first so the anonymous event history merges into the new profile.
    final currentId = await _mixpanel?.getDistinctId() ?? '';
    if (currentId.isNotEmpty && currentId != userId) {
      _mixpanel?.alias(userId, currentId);
    }
    _mixpanel?.identify(userId);

    _mixpanel?.getPeople().set('\$name', displayName ?? 'Player');
    _mixpanel?.getPeople().set('\$created', createdAt.toIso8601String());
    _mixpanel?.getPeople().set('account_type', 'authenticated');
  }

  // ── Super properties ──────────────────────────────────────────────────────

  void setSuperProperties({
    required String platform,
    required String appVersion,
    required bool isGuest,
  }) {
    _mixpanel?.registerSuperProperties({
      'platform': platform,
      'app_version': appVersion,
      'is_guest': isGuest,
    });
  }

  /// Called on every auth state change to keep the is_guest super property current.
  void onAuthStateChanged(bool isGuest) {
    _mixpanel?.registerSuperPropertiesOnce({
      'first_seen': DateTime.now().toIso8601String(),
    });
    _mixpanel?.registerSuperProperties({'is_guest': isGuest});
  }

  // ── Event: app_open ───────────────────────────────────────────────────────

  /// Fire when app comes to foreground. Resets session ID.
  Future<void> trackAppOpen() async {
    _resetSession();
    await _track('app_open', {
      'is_first_open': false, // TODO MAS: implement SharedPreferences-backed first-open tracking
      'days_since_install': 0, // TODO MAS: implement SharedPreferences-backed install date tracking
    });
  }

  // ── Event: level_start ────────────────────────────────────────────────────

  Future<void> trackLevelStart({
    required int levelNumber,
    required String levelType,
    required bool isBoss,
    required int coinBalance,
    required int intersectionCount,
    required List<int> constraintTiers,
  }) async {
    await _track('level_start', {
      'level_number': levelNumber,
      'level_type': levelType,
      'is_boss': isBoss,
      'coin_balance_at_start': coinBalance,
      'intersection_count': intersectionCount,
      'constraint_tiers': constraintTiers,
    });
  }

  // ── Event: word_submitted ─────────────────────────────────────────────────

  /// Privacy: sends word_length only — never the word itself.
  Future<void> trackWordSubmitted({
    required int levelNumber,
    required String levelType,
    required int wordLength,      // NOT the word — length only
    required String constraintId,
    required int constraintTier,
    required String result,       // 'correct' | 'wrong_word' | 'wrong_constraint'
    required int attemptNumber,
    required int wordSlotId,
    required int timeOnLevelMs,
  }) async {
    await _track('word_submitted', {
      'level_number': levelNumber,
      'level_type': levelType,
      'word_length': wordLength,
      'constraint_id': constraintId,
      'constraint_tier': constraintTier,
      'result': result,
      'attempt_number': attemptNumber,
      'word_slot_id': wordSlotId,
      'time_on_level_ms': timeOnLevelMs,
    });
  }

  // ── Event: hint_used ──────────────────────────────────────────────────────

  Future<void> trackHintUsed({
    required int levelNumber,
    required String levelType,
    required int wordSlotId,
    required int constraintTier,
    required int coinsSpent,
    required int coinBalanceAfter,
    required int hintsUsedThisLevel,
    required int timeOnLevelMs,
  }) async {
    await _track('hint_used', {
      'level_number': levelNumber,
      'level_type': levelType,
      'word_slot_id': wordSlotId,
      'constraint_tier': constraintTier,
      'coins_spent': coinsSpent,
      'coin_balance_after': coinBalanceAfter,
      'hints_used_this_level': hintsUsedThisLevel,
      'time_on_level_ms': timeOnLevelMs,
    });
  }

  // ── Event: level_complete ─────────────────────────────────────────────────

  Future<void> trackLevelComplete({
    required int levelNumber,
    required String levelType,
    required bool isBoss,
    required int stars,
    required int hintsUsed,
    required int attemptsTotal,
    required int coinsEarned,
    required int coinBalanceAfter,
    required int timeTakenMs,
    required List<String> achievementsUnlocked,
  }) async {
    await _track('level_complete', {
      'level_number': levelNumber,
      'level_type': levelType,
      'is_boss': isBoss,
      'stars': stars,
      'hints_used': hintsUsed,
      'attempts_total': attemptsTotal,
      'coins_earned': coinsEarned,
      'coin_balance_after': coinBalanceAfter,
      'time_taken_ms': timeTakenMs,
      'achievements_unlocked': achievementsUnlocked,
      'achievements_unlocked_count': achievementsUnlocked.length,
    });
  }

  // ── Event: level_abandoned ────────────────────────────────────────────────

  Future<void> trackLevelAbandoned({
    required int levelNumber,
    required String levelType,
    required bool isBoss,
    required int timeSpentMs,
    required int hintsUsed,
    required int attemptsMade,
    required int wordsCompleted,
    required int totalWords,
    required int coinBalance,
  }) async {
    await _track('level_abandoned', {
      'level_number': levelNumber,
      'level_type': levelType,
      'is_boss': isBoss,
      'time_spent_ms': timeSpentMs,
      'hints_used': hintsUsed,
      'attempts_made': attemptsMade,
      'words_completed': wordsCompleted,
      'total_words': totalWords,
      'completion_fraction':
          totalWords > 0 ? wordsCompleted / totalWords : 0.0,
      'coin_balance': coinBalance,
    });
  }

  // ── Event: level_skip ─────────────────────────────────────────────────────

  Future<void> trackLevelSkip({
    required int levelNumber,
    required String levelType,
    required bool isBoss,
    required int timeSpentBeforeSkipMs,
    required int hintsUsedBeforeSkip,
    required int coinsSpent,
    required int coinBalanceAfter,
  }) async {
    await _track('level_skip', {
      'level_number': levelNumber,
      'level_type': levelType,
      'is_boss': isBoss,
      'time_spent_before_skip_ms': timeSpentBeforeSkipMs,
      'hints_used_before_skip': hintsUsedBeforeSkip,
      'coins_spent': coinsSpent,
      'coin_balance_after': coinBalanceAfter,
    });
  }

  // ── Event: achievement_unlocked ───────────────────────────────────────────

  Future<void> trackAchievementUnlocked({
    required String achievementId,
    required int coinsAwarded,
    required int levelNumber,
    required int totalAchievementsUnlocked,
  }) async {
    await _track('achievement_unlocked', {
      'achievement_id': achievementId,
      'coins_awarded': coinsAwarded,
      'triggered_by_level': levelNumber,
      'total_achievements_unlocked': totalAchievementsUnlocked,
    });

    _mixpanel?.getPeople().increment('total_achievements', 1);
  }

  // ── Event: streak_updated ─────────────────────────────────────────────────

  Future<void> trackStreakUpdated({
    required int newStreak,
    required int previousStreak,
    required bool streakIncreased,
  }) async {
    await _track('streak_updated', {
      'new_streak': newStreak,
      'previous_streak': previousStreak,
      'streak_increased': streakIncreased,
      'streak_reset': previousStreak > 1 && newStreak == 1,
    });

    _mixpanel?.getPeople().set('current_streak', newStreak);
    // Always set longest_streak when streak increased — Mixpanel People
    // properties are idempotent so setting a lower value is harmless here,
    // but we guard with the provided previousStreak for correctness.
    if (newStreak > previousStreak) {
      _mixpanel?.getPeople().set('longest_streak', newStreak);
    }
  }

  // ── Event: coin_transaction ───────────────────────────────────────────────

  Future<void> trackCoinTransaction({
    required String transactionType,
    required int amount,
    required int balanceBefore,
    required int balanceAfter,
    String? referenceId,
  }) async {
    await _track('coin_transaction', {
      'transaction_type': transactionType,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'reference_id': referenceId,
      'is_earn': amount > 0,
      'is_spend': amount < 0,
    });

    _mixpanel?.getPeople().set('coin_balance', balanceAfter);
    if (amount < 0) {
      _mixpanel?.getPeople().increment('total_coins_spent', amount.abs().toDouble());
    } else {
      _mixpanel?.getPeople().increment('total_coins_earned', amount.toDouble());
    }
  }

  // ── Event: iap_purchase ───────────────────────────────────────────────────
  // Phase 7: revenueUsd replaces price/currency for consistency with RevenueCat
  // storeProduct.price which is already normalised to USD-equivalent by the SDK.

  Future<void> trackIapPurchase({
    required String productId,
    required double revenueUsd,
    required int coinsAwarded,
    required int coinBalanceAfter,
  }) async {
    await _track('iap_purchase', {
      'product_id': productId,
      'revenue_usd': revenueUsd,
      'coins_awarded': coinsAwarded,
      'coin_balance_after': coinBalanceAfter,
    });

    _mixpanel?.getPeople().trackCharge(revenueUsd, properties: {
      'product_id': productId,
    });
    _mixpanel?.getPeople().set('is_paying_user', true);
    _mixpanel?.getPeople().increment('total_iap_purchases', 1);
  }

  // ── Event: account_created ────────────────────────────────────────────────

  Future<void> trackAccountCreated({
    required String method, // 'email' | 'apple' | 'google'
    required bool wasGuest,
    required int levelsCompletedAsGuest,
    required int coinBalanceAtConversion,
  }) async {
    await _track('account_created', {
      'method': method,
      'was_guest': wasGuest,
      'levels_completed_as_guest': levelsCompletedAsGuest,
      'coin_balance_at_conversion': coinBalanceAtConversion,
    });

    _mixpanel?.getPeople().set('account_method', method);
    _mixpanel?.getPeople().set('converted_from_guest', wasGuest);
  }

  // ── Event: sign_in ────────────────────────────────────────────────────────

  Future<void> trackSignIn({required String method}) async {
    await _track('sign_in', {'method': method});
  }

  // ── Event: shop_viewed ────────────────────────────────────────────────────
  // Phase 7: is_paying_user added so Mixpanel funnels can segment IAP converts.

  Future<void> trackShopViewed({
    required int coinBalance,
    required bool isPayingUser,
  }) async {
    await _track('shop_viewed', {
      'coin_balance': coinBalance,
      'is_paying_user': isPayingUser,
    });
  }

  // ── Event: settings_changed ───────────────────────────────────────────────

  Future<void> trackSettingChanged({
    required String settingName,
    required dynamic newValue,
  }) async {
    await _track('settings_changed', {
      'setting_name': settingName,
      'new_value': newValue,
    });
  }

  // ── Phase 7: Ad events ────────────────────────────────────────────────────

  /// Fired when an interstitial ad is shown between levels.
  Future<void> trackInterstitialAdShown({
    required int levelNumber,
    required int levelsSinceLastAd,
  }) async {
    await _track('interstitial_ad_shown', {
      'level_number': levelNumber,
      'levels_since_last_ad': levelsSinceLastAd,
    });
  }

  /// Fired when a rewarded video ad completes and coins are awarded.
  /// [placement] is 'level_complete' or 'shop'.
  Future<void> trackRewardedAdCompleted({
    required String placement,
    required int coinsAwarded,
    required int coinBalanceAfter,
  }) async {
    await _track('rewarded_ad_completed', {
      'placement': placement,
      'coins_awarded': coinsAwarded,
      'coin_balance_after': coinBalanceAfter,
    });

    _mixpanel?.getPeople().increment('total_rewarded_ads_watched', 1);
    _mixpanel?.getPeople().set('coin_balance', coinBalanceAfter);
  }
}
