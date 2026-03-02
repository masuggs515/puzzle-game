// lib/features/auth/providers/auth_provider.dart
// Phase 2 — Foundation
// Spec: master-development-plan.md § 2.3 Anonymous Session Flow

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../data/models/player_profile.dart';
import '../../../data/services/supabase_service.dart';

// Singleton service — shared across providers
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(),
);

// Stream of Supabase auth state changes.
// Returns an empty stream when credentials are absent (Supabase not initialized).
// Supabase.instance has its own assert guard so we must check before calling it.
final authStateProvider = StreamProvider<AuthState>((ref) {
  if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
    return const Stream.empty();
  }
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Current Supabase User — null when signed out
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).whenData((s) => s.session?.user).value;
});

// Player profile — re-fetched on every auth state change
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
