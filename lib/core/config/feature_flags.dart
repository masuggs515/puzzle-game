// lib/core/config/feature_flags.dart
// Feature flags injected via --dart-define at build time.
// Production builds only enable flags for fully reviewed features.

class FeatureFlags {
  static const bool theVaultEnabled = bool.fromEnvironment(
    'FEATURE_VAULT_ENABLED',
    defaultValue: false,
  );
  static const bool rewardedAdsEnabled = bool.fromEnvironment(
    'FEATURE_REWARDED_ADS_ENABLED',
    defaultValue: false,
  );
  static const bool dailyBonusEnabled = bool.fromEnvironment(
    'FEATURE_DAILY_BONUS_ENABLED',
    defaultValue: false,
  );
}
