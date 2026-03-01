// lib/data/services/supabase_service.dart
// Phase 2 — Foundation
// Spec: supabase-agent-spec.md § Authentication Configuration
//       master-development-plan.md § 2.3 Anonymous Session Flow

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_profile.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  // ──────────────────────────────────────
  // Auth
  // ──────────────────────────────────────

  /// Ensures an anonymous session exists on app launch.
  /// If a session is already persisted (e.g. from a previous launch) this is a no-op.
  Future<void> ensureAnonymousSession() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
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
    await _client.auth.updateUser(
      UserAttributes(email: email, password: password),
    );
    // Mark the profile as no longer a guest
    final user = _client.auth.currentUser;
    if (user != null) {
      await _client
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
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Signs out. Anonymous session data is NOT preserved after sign-out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ──────────────────────────────────────
  // Profile
  // ──────────────────────────────────────

  /// Fetches the player profile for the currently authenticated user.
  /// Returns null if not authenticated or profile does not exist.
  Future<PlayerProfile?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('player_profiles')
        .select()
        .eq('auth_id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return PlayerProfile.fromJson(data);
  }

  /// Updates the player's display name.
  Future<void> updateDisplayName(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
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
    final result = await _client.rpc(
      'compute_coin_balance',
      params: {'p_user_id': profileId},
    );
    return (result as int?) ?? 0;
  }
}
