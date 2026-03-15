// lib/features/auth/providers/auth_provider.dart
// Phase 2 — Foundation (extended Phase 6: analytics providers; Phase 7: ad providers)
// Spec: master-development-plan.md § 2.3 Anonymous Session Flow
//       analytics-agent-spec.md
//       master-development-plan.md § Ad Strategy

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/player_profile.dart';
import '../../../data/services/ad_service.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/supabase_service.dart';

// Singleton service — shared across providers
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(),
);

// Stream of Supabase auth state changes.
// Returns an empty stream when Supabase is not initialized for any reason
// (missing credentials, failed init, stale web build, etc.).
// Supabase.instance asserts initialization so we guard with try-catch rather
// than an Env check — the Env check only catches missing credentials, not a
// failed or skipped Supabase.initialize() call.
final authStateProvider = StreamProvider<AuthState>((ref) {
  try {
    return Supabase.instance.client.auth.onAuthStateChange;
  } on AssertionError catch (_) {
    return const Stream.empty();
  }
});

// Current Supabase User — null when signed out
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).whenData((s) => s.session?.user).value;
});

// Player profile — re-fetched on every auth state change.
// SupabaseService.getProfile() returns null safely when Supabase is not
// initialized, so no guard is needed here.
final profileProvider = FutureProvider<PlayerProfile?>((ref) async {
  // Watch auth state so this re-runs on sign-in / sign-out
  ref.watch(authStateProvider);
  final service = ref.read(supabaseServiceProvider);
  return service.getProfile();
});

// Coin balance — derived from profile id
final coinBalanceProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return 0;
  final service = ref.read(supabaseServiceProvider);
  return service.getCoinBalance(profile.id);
});

/// Current vault level — loaded from player profile. Updates when profile refreshes.
final vaultLevelProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  return profile?.currentVaultLevel ?? 0;
});

// ── Analytics providers (Phase 6) ─────────────────────────────────────────

// Holds the Mixpanel instance. Null until initialized in main.dart.
// Overridden via ProviderScope.overrides before runApp().
final mixpanelProvider = StateProvider<Mixpanel?>((ref) => null);

// AnalyticsService derived from the Mixpanel instance.
// No-op when Mixpanel is null (e.g. token missing in dev without .env.task).
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final mixpanel = ref.watch(mixpanelProvider);
  final supabase = ref.read(supabaseServiceProvider);
  return AnalyticsService(mixpanel, supabase);
});

// ── Ad providers (Phase 7) ────────────────────────────────────────────────
// Spec: master-development-plan.md § Ad Strategy

/// Tracks when interstitial ads are due. Single instance for the app lifetime.
final adFrequencyManagerProvider = Provider<AdFrequencyManager>((ref) {
  return AdFrequencyManager();
});

/// Loads and shows interstitial ads. Pre-loaded on app start.
final interstitialAdServiceProvider = Provider<InterstitialAdService>((ref) {
  final service = InterstitialAdService();
  service.loadAd(); // Pre-load on app start
  ref.onDispose(service.dispose);
  return service;
});

/// Loads and shows rewarded video ads. Pre-loaded on app start.
final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  final service = RewardedAdService();
  service.loadAd(); // Pre-load on app start
  ref.onDispose(service.dispose);
  return service;
});
