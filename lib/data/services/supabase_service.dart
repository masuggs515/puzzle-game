// lib/data/services/supabase_service.dart
// Phase 2 — Foundation
// Spec: supabase-agent-spec.md § Authentication Configuration
//       master-development-plan.md § 2.3 Anonymous Session Flow

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_profile.dart';

class SupabaseService {
  // Returns null when Supabase is not initialized (missing credentials, failed
  // init, or running without .env.task). All methods below check for null so
  // callers never see an AssertionError from Supabase.instance.
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } on AssertionError catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────
  // Auth
  // ──────────────────────────────────────

  /// Ensures an anonymous session exists on app launch.
  /// If a session is already persisted (e.g. from a previous launch) this is a no-op.
  Future<void> ensureAnonymousSession() async {
    final client = _client;
    if (client == null) return;
    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }
  }

  /// Converts the current anonymous session to an email/password account.
  /// Uses auth.updateUser() which upgrades the existing anonymous user in-place —
  /// no new auth user is created, so auth_id and all associated data are preserved.
  ///
  // TODO MAS: Cloud Supabase (dev/prod) may require email confirmation after signUp.
  // If enabled in the Auth dashboard, the user will receive a confirmation email
  // before the session is fully authenticated. Disable "Enable email confirmations"
  // in Supabase Dashboard → Authentication → Providers → Email for development.
  Future<void> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) return;
    await client.auth.updateUser(
      UserAttributes(email: email, password: password),
    );
    // Mark the profile as no longer a guest
    final user = client.auth.currentUser;
    if (user != null) {
      await client
          .from('player_profiles')
          .update({'is_guest': false})
          .eq('auth_id', user.id);
    }
  }

  /// Signs in an existing email/password account.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) return;
    await client.auth.signInWithPassword(email: email, password: password);
  }

  /// Signs out. Anonymous session data is NOT preserved after sign-out.
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  // ──────────────────────────────────────
  // Profile
  // ──────────────────────────────────────

  /// Fetches the player profile for the currently authenticated user.
  /// Returns null if not authenticated, profile does not exist, or Supabase
  /// is not initialized.
  Future<PlayerProfile?> getProfile() async {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final data = await client
        .from('player_profiles')
        .select()
        .eq('auth_id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return PlayerProfile.fromJson(data);
  }

  /// Updates the player's display name.
  Future<void> updateDisplayName(String name) async {
    final client = _client;
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) return;
    await client
        .from('player_profiles')
        .update({'display_name': name})
        .eq('auth_id', user.id);
  }

  // ──────────────────────────────────────
  // Economy
  // ──────────────────────────────────────

  /// Returns the current coin balance for a player.
  /// Calls the compute_coin_balance stored procedure (server-side SUM).
  Future<int> getCoinBalance(String profileId) async {
    final client = _client;
    if (client == null) return 0;
    final result = await client.rpc(
      'compute_coin_balance',
      params: {'p_user_id': profileId},
    );
    return (result as int?) ?? 0;
  }
}
