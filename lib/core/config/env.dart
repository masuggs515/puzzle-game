// lib/core/config/env.dart
// Environment configuration — all values injected via --dart-define at build time.
// Never hardcode credentials here. See scripts/run_dev.sh for usage.

class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const revenueCatKey = String.fromEnvironment('REVENUECAT_KEY');
  static const oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');
  static const admobInterstitialIos =
      String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');
  static const admobInterstitialAndroid =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');
  static const admobRewardedIos = String.fromEnvironment('ADMOB_REWARDED_IOS');
  static const admobRewardedAndroid =
      String.fromEnvironment('ADMOB_REWARDED_ANDROID');
}
