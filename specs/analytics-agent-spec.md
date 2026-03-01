# Analytics Agent Spec
**Project:** Word/Logic Puzzle Game (codename TBD)  
**Agent Role:** Analytics specialist — owns all Mixpanel event tracking implementation, session management, event schema enforcement, and analytics utility layer used by the Flutter agent.  
**Document Version:** 0.1  
**Last Updated:** February 2026


---

## Agent Convention — TODO MAS

Any time you need human input, a decision, a credential, a review, or anything uncertain — leave a comment formatted exactly as:

```
// TODO MAS: [clear description of what is needed and why]
```

Use `//` in Dart/Flutter, `--` in SQL, `> TODO MAS:` in markdown. Never stall silently — leave a TODO MAS and keep working on everything else. At the end of your session, print a consolidated list of every TODO MAS you left so Adam can action them in one pass.

---

## Agent Context

You are an analytics implementation expert. You own the analytics layer that sits on top of the Flutter app. Your responsibilities are:

- Mixpanel Flutter SDK initialization and configuration
- Analytics service class consumed by the Flutter agent
- Every event definition with exact property schemas
- Session ID management
- User identity management (anonymous → identified)
- Analytics event firing to both Mixpanel AND Supabase analytics_events table
- Ensuring no PII is sent to Mixpanel

You do not build UI. You do not modify the Supabase schema. You do not write game logic. You provide a clean `AnalyticsService` class that the Flutter agent calls at the right moments — those call sites are defined in this spec.

---

## Tech Stack

| Tool | Purpose |
|---|---|
| Mixpanel Flutter SDK | Dashboard, funnels, retention, cohorts |
| Supabase analytics_events table | Raw event ownership, custom SQL reporting |
| flutter_riverpod | AnalyticsService as a provider |

---

## Initialization

```dart
// Called in main.dart before runApp()

Future<void> initializeAnalytics() async {
  await MixpanelAnalytics.instance.init(
    token: const String.fromEnvironment('MIXPANEL_TOKEN'),
    optOutTrackingDefault: false,
    trackAutomaticEvents: false, // manual control only
  );
  
  // Disable Mixpanel's automatic geolocation — privacy best practice
  MixpanelAnalytics.instance.setLoggingEnabled(kDebugMode);
}
```

---

## Analytics Service

```dart
// lib/data/services/analytics_service.dart

class AnalyticsService {
  final MixpanelAnalytics _mixpanel = MixpanelAnalytics.instance;
  final SupabaseService _supabase;
  
  late String _sessionId;
  
  AnalyticsService(this._supabase) {
    _sessionId = _generateSessionId();
  }
  
  String _generateSessionId() => const Uuid().v4();
  
  // Called when app comes to foreground — new session
  void onAppForegrounded() {
    _sessionId = _generateSessionId();
  }
  
  // ── Identity management ────────────────────────────────────────
  
  // Called after anonymous session created
  void identifyAnonymous(String anonymousUserId) {
    _mixpanel.identify(anonymousUserId);
    _mixpanel.getPeople().set('\$name', 'Guest');
  }
  
  // Called after account creation — links anonymous → identified
  void identifyAuthenticated({
    required String userId,
    required String? displayName,
    required DateTime createdAt,
  }) {
    _mixpanel.identify(userId);
    _mixpanel.getPeople().set({
      '\$name': displayName ?? 'Player',
      '\$created': createdAt.toIso8601String(),
      'account_type': 'authenticated',
    });
    // Alias the anonymous ID to the new authenticated ID
    // This merges their event history in Mixpanel
    _mixpanel.alias(userId, _mixpanel.getDistinctId()!);
  }
  
  // ── Core event firing ──────────────────────────────────────────
  
  Future<void> _track(String eventName, Map<String, dynamic> properties) async {
    final enrichedProperties = {
      ...properties,
      'session_id': _sessionId,
      'platform': Platform.operatingSystem,
      'app_version': await _getAppVersion(),
    };
    
    // Fire to Mixpanel
    _mixpanel.track(eventName, properties: enrichedProperties);
    
    // Fire to Supabase (raw ownership)
    // Non-blocking — don't await, don't fail the game if this fails
    _supabase.trackEvent(eventName, enrichedProperties).catchError((e) {
      Sentry.captureException(e);
    });
  }
}
```

---

## Event Definitions

Every event the Flutter agent must fire, with exact call signatures and property schemas.

---

### `app_open`
**When:** Every time the app comes to foreground  
**Call site:** `AppLifecycleObserver.onResume()`

```dart
Future<void> trackAppOpen() async {
  await _track('app_open', {
    'is_first_open': await _isFirstOpen(),
    'days_since_install': await _daysSinceInstall(),
  });
  
  onAppForegrounded(); // reset session ID
}
```

**Properties:**

| Property | Type | Description |
|---|---|---|
| is_first_open | bool | True on very first app launch |
| days_since_install | int | Days since first open |
| session_id | string | New session ID (auto-added) |
| platform | string | ios / android |
| app_version | string | e.g. "1.0.0" |

---

### `level_start`
**When:** Puzzle screen loads and puzzle is ready for interaction  
**Call site:** `GameNotifier.build()` after puzzle loaded

```dart
Future<void> trackLevelStart({
  required int levelNumber,
  required String levelType,    // 'standard', 'bossLevel', 'vault'
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
```

---

### `word_submitted`
**When:** Player taps submit button  
**Call site:** `GameNotifier.onSubmit()` — fire BEFORE validation for wrong attempts, after for correct

```dart
Future<void> trackWordSubmitted({
  required int levelNumber,
  required String levelType,
  required String word,
  required String constraintId,
  required int constraintTier,
  required String result,       // 'correct', 'wrong_word', 'wrong_constraint'
  required int attemptNumber,   // which attempt on this level
  required int wordSlotId,
  required int timeOnLevelMs,   // time since level_start
}) async {
  await _track('word_submitted', {
    'level_number': levelNumber,
    'level_type': levelType,
    'word_length': word.length,   // track length, NOT the word itself (privacy)
    'constraint_id': constraintId,
    'constraint_tier': constraintTier,
    'result': result,
    'attempt_number': attemptNumber,
    'word_slot_id': wordSlotId,
    'time_on_level_ms': timeOnLevelMs,
  });
}
```

**Important:** Do NOT send the actual word string to Mixpanel. Send `word_length` only. The actual word is stored in Supabase analytics_events where it is controlled data. Mixpanel receives no PII or potentially sensitive word content.

---

### `hint_used`
**When:** Edge Function confirms hint deduction successful  
**Call site:** `GameNotifier.onHintRequested()` on success

```dart
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
```

---

### `level_complete`
**When:** Edge Function confirms level completion  
**Call site:** `GameNotifier._onLevelComplete()` on Edge Function success

```dart
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
```

---

### `level_abandoned`
**When:** Player navigates away from puzzle without completing it  
**Call site:** Back button confirm dialog "Leave" → before navigation

```dart
Future<void> trackLevelAbandoned({
  required int levelNumber,
  required String levelType,
  required bool isBoss,
  required int timeSpentMs,
  required int hintsUsed,
  required int attemptsMade,
  required int wordsCompleted,    // how many words solved before abandoning
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
    'completion_fraction': wordsCompleted / totalWords,
    'coin_balance': coinBalance,
  });
}
```

---

### `level_skip`
**When:** Edge Function confirms skip deduction successful  
**Call site:** `GameNotifier.onSkipRequested()` on success

```dart
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
```

---

### `vault_entered`
**When:** Player navigates to theVault for the first time  
**Call site:** `VaultScreen.initState()` — check if first time via SharedPreferences

```dart
Future<void> trackVaultEntered({
  required bool isFirstTime,
  required int levelsCompletedBeforeEntry,
  required int coinBalance,
}) async {
  await _track('vault_entered', {
    'is_first_time': isFirstTime,
    'levels_completed': levelsCompletedBeforeEntry,
    'coin_balance': coinBalance,
  });
  
  // Set Mixpanel super property so all future events include vault status
  if (isFirstTime) {
    _mixpanel.registerSuperProperties({'has_reached_vault': true});
  }
}
```

---

### `achievement_unlocked`
**When:** Edge Function returns achievement in `achievements_unlocked` array  
**Call site:** `LevelCompleteScreen` — for each achievement in the list

```dart
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
  
  // Update Mixpanel People profile
  _mixpanel.getPeople().increment('total_achievements', 1);
}
```

---

### `streak_updated`
**When:** Edge Function returns updated streak on level complete  
**Call site:** `GameNotifier._onLevelComplete()` when streak changes

```dart
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
  
  // Update Mixpanel People profile with current streak
  _mixpanel.getPeople().set('current_streak', newStreak);
  if (newStreak > (await _getProperty('longest_streak') ?? 0)) {
    _mixpanel.getPeople().set('longest_streak', newStreak);
  }
}
```

---

### `coin_transaction`
**When:** Any coin balance change — earn or spend  
**Call site:** After every Edge Function call that changes coin balance

```dart
Future<void> trackCoinTransaction({
  required String transactionType,  // matches Supabase transaction_type enum
  required int amount,              // positive = earn, negative = spend
  required int balanceBefore,
  required int balanceAfter,
  required String? referenceId,     // level number, achievement ID, etc.
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
  
  // Update Mixpanel People
  _mixpanel.getPeople().set('coin_balance', balanceAfter);
  if (amount < 0) {
    _mixpanel.getPeople().increment('total_coins_spent', amount.abs());
  } else {
    _mixpanel.getPeople().increment('total_coins_earned', amount);
  }
}
```

---

### `iap_purchase`
**When:** RevenueCat purchase completes successfully  
**Call site:** `RevenueCatService.onPurchaseComplete()`

```dart
Future<void> trackIapPurchase({
  required String productId,
  required int coinsAwarded,
  required double price,
  required String currency,
}) async {
  await _track('iap_purchase', {
    'product_id': productId,
    'coins_awarded': coinsAwarded,
    'price': price,
    'currency': currency,
  });
  
  // Track revenue in Mixpanel
  _mixpanel.getPeople().trackCharge(price, properties: {
    'product_id': productId,
    'currency': currency,
  });
  
  _mixpanel.getPeople().set('is_paying_user', true);
  _mixpanel.getPeople().increment('total_iap_purchases', 1);
}
```

---

### `account_created`
**When:** Player creates an account (email/Apple/Google)  
**Call site:** `SignUpScreen` on successful account creation

```dart
Future<void> trackAccountCreated({
  required String method,   // 'email', 'apple', 'google'
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
  
  _mixpanel.getPeople().set('account_method', method);
  _mixpanel.getPeople().set('converted_from_guest', wasGuest);
}
```

---

### `sign_in`
**When:** Returning player signs in  
**Call site:** `SignInScreen` on successful sign-in

```dart
Future<void> trackSignIn({required String method}) async {
  await _track('sign_in', {'method': method});
}
```

---

### `shop_viewed`
**When:** Player opens the shop screen  
**Call site:** `ShopScreen.initState()`

```dart
Future<void> trackShopViewed({required int coinBalance}) async {
  await _track('shop_viewed', {'coin_balance': coinBalance});
}
```

---

### `settings_changed`
**When:** Player changes a setting  
**Call site:** `SettingsProvider` on any setting change

```dart
Future<void> trackSettingChanged({
  required String settingName,   // 'sound', 'notifications'
  required dynamic newValue,
}) async {
  await _track('settings_changed', {
    'setting_name': settingName,
    'new_value': newValue,
  });
}
```

---

## Super Properties

Super properties are set once and automatically appended to every subsequent event.

```dart
void setSuperProperties({
  required String platform,
  required String appVersion,
  required bool isGuest,
}) {
  _mixpanel.registerSuperProperties({
    'platform': platform,
    'app_version': appVersion,
    'is_guest': isGuest,
  });
}

// Called when auth state changes
void onAuthStateChanged(bool isGuest) {
  _mixpanel.registerSuperPropertiesOnce({'first_seen': DateTime.now().toIso8601String()});
  _mixpanel.registerSuperProperties({'is_guest': isGuest});
}
```

---

## Mixpanel People Profile Properties

The following People properties are maintained on the Mixpanel profile for each user. These enable cohort analysis and segmentation.

| Property | Type | Set When |
|---|---|---|
| `$name` | string | Account creation or anonymous session |
| `$created` | datetime | First seen |
| `account_type` | string | 'guest' or 'authenticated' |
| `account_method` | string | 'email', 'apple', 'google' |
| `coin_balance` | int | Every coin transaction |
| `total_coins_earned` | int | Incremented on earn |
| `total_coins_spent` | int | Incremented on spend |
| `current_streak` | int | Every streak update |
| `longest_streak` | int | When new longest streak set |
| `total_achievements` | int | Every achievement unlock |
| `is_paying_user` | bool | First IAP purchase |
| `total_iap_purchases` | int | Every IAP purchase |
| `has_reached_vault` | bool | First vault entry |
| `converted_from_guest` | bool | Account creation if was guest |

---

## Privacy Rules

These are non-negotiable:

1. **Never send actual word strings to Mixpanel** — send `word_length` only
2. **Never send email addresses to Mixpanel** — Supabase handles identity
3. **No device identifiers** — use Supabase `auth.uid()` as the Mixpanel distinct ID
4. **No location data** — disable Mixpanel geolocation
5. **All Supabase analytics_events writes** are the controlled raw data — Mixpanel is for dashboards only
6. The `valid_guess_words.txt` and any word-related data are never sent as event properties

---

## Mixpanel Dashboards to Build Post-Launch

These are the dashboards the developer needs. Build them in Mixpanel using the events defined above.

### 1. Level Funnel (most important)
- Funnel: `level_start` → `level_complete`
- Break down by `level_number` — shows exact drop-off at each level
- Filter by `level_type` to compare sprint vs puzzle vs bossLevel

### 2. Constraint Failure Breakdown
- Event: `word_submitted` where `result = wrong_constraint`
- Group by `constraint_id` and `constraint_tier`
- Shows which constraints confuse players most

### 3. Retention Curves
- Day 1, Day 7, Day 30 retention cohorts
- Based on `app_open` events
- Segment by `is_paying_user` to compare paid vs free retention

### 4. Coin Economy Health
- Event: `coin_transaction`
- Chart: `total_coins_earned` vs `total_coins_spent` over time
- Funnel: `shop_viewed` → `iap_purchase` (shop conversion rate)

### 5. Hint Usage Heatmap
- Event: `hint_used`, grouped by `level_number`
- Identifies which levels have abnormally high hint usage
- Cross-reference with `level_abandoned` to find problem levels

### 6. Vault Conversion
- Funnel: `level_start (level=200)` → `level_complete (level=200)` → `vault_entered`
- Shows how many players make it to and enter theVault

### 7. Guest → Account Conversion
- Event: `account_created` where `was_guest = true`
- Trend over time — shows if the optional sign-up prompts are working

---

## Session Management

```dart
class SessionManager {
  static const _sessionTimeout = Duration(minutes: 30);
  DateTime? _lastActivity;
  String _currentSessionId = '';
  
  String get sessionId => _currentSessionId;
  
  void onActivity() {
    final now = DateTime.now();
    if (_lastActivity == null || 
        now.difference(_lastActivity!) > _sessionTimeout) {
      _currentSessionId = const Uuid().v4();
    }
    _lastActivity = now;
  }
}
```

Sessions reset after 30 minutes of inactivity. This aligns with Mixpanel's default session definition for consistent funnel analysis.

---

## Deliverable Checklist

Before this agent's work is considered complete:

- [ ] Mixpanel initialized with correct token from environment
- [ ] AnalyticsService implemented as Riverpod provider
- [ ] All 15 event tracking methods implemented with correct property schemas
- [ ] Super properties set correctly on app start and auth change
- [ ] Mixpanel People profile properties maintained
- [ ] Anonymous identity set on guest session creation
- [ ] Identity aliased correctly on account creation
- [ ] Dual-write to Mixpanel AND Supabase analytics_events on every event
- [ ] No word strings sent to Mixpanel (word_length only)
- [ ] No email or PII sent to Mixpanel
- [ ] Session management implemented with 30-minute timeout
- [ ] All call sites documented and verified with Flutter agent
- [ ] Sentry captures analytics_events write failures silently
- [ ] Tested: events appearing in Mixpanel Live View on dev build
- [ ] Tested: events appearing in Supabase analytics_events table on dev build

---

## Call Site Reference for Flutter Agent

Quick reference of where each event fires in the Flutter codebase:

| Event | Flutter Call Site |
|---|---|
| `app_open` | `AppLifecycleObserver.didChangeAppLifecycleState` on resumed |
| `level_start` | `GameNotifier.build()` after puzzle loaded |
| `word_submitted` | `GameNotifier.onSubmit()` |
| `hint_used` | `GameNotifier.onHintRequested()` on success |
| `level_complete` | `GameNotifier._onLevelComplete()` on Edge Function success |
| `level_abandoned` | Back button confirm dialog on "Leave" |
| `level_skip` | `GameNotifier.onSkipRequested()` on success |
| `vault_entered` | `VaultScreen.initState()` |
| `achievement_unlocked` | `LevelCompleteScreen` for each achievement in response |
| `streak_updated` | `GameNotifier._onLevelComplete()` when streak changes |
| `coin_transaction` | After every Edge Function call that returns new_balance |
| `iap_purchase` | `RevenueCatService.onPurchaseComplete()` |
| `account_created` | `SignUpScreen` on success |
| `sign_in` | `SignInScreen` on success |
| `shop_viewed` | `ShopScreen.initState()` |
| `settings_changed` | `SettingsProvider` on any setting mutation |

---

*This spec is the single source of truth for the Analytics agent. All event names, property names, and types defined here are canonical — the Flutter agent must match them exactly.*
