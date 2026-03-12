// lib/data/services/supabase_service.dart
// Phase 2 — Foundation
// Spec: supabase-agent-spec.md § Authentication Configuration
//       master-development-plan.md § 2.3 Anonymous Session Flow

import 'package:flutter/foundation.dart';
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
    if (client == null) {
      debugPrint('[SupabaseService] ensureAnonymousSession: client is null (Supabase not initialized)');
      return;
    }
    if (client.auth.currentSession != null) {
      debugPrint('[SupabaseService] ensureAnonymousSession: session already exists (uid=${client.auth.currentUser?.id})');
      return;
    }
    debugPrint('[SupabaseService] ensureAnonymousSession: no session found — calling signInAnonymously');
    final response = await client.auth.signInAnonymously();
    debugPrint('[SupabaseService] ensureAnonymousSession: signed in (uid=${response.user?.id})');
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

  /// Returns the player_profiles.id (internal UUID) for the current user.
  /// This is the user_id FK used in all other tables.
  Future<String?> getProfileId() async {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user == null) return null;
    final data = await client
        .from('player_profiles')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();
    return data?['id'] as String?;
  }

  /// Calls a Supabase Edge Function by name with a JSON body.
  /// Returns the decoded response map.
  /// Throws on network errors or non-200 responses.
  Future<Map<String, dynamic>> callEdgeFunction(
    String functionName, {
    required Map<String, dynamic> body,
  }) async {
    final client = _client;
    if (client == null) return {'success': false, 'error': 'not_initialized'};
    final response = await client.functions.invoke(
      functionName,
      body: body,
    );
    if (response.status != 200) {
      debugPrint('[SupabaseService] callEdgeFunction $functionName failed: status=${response.status} body=${response.data}');
      throw Exception(
          'Edge function $functionName failed: ${response.status}');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Returns level progress rows for the current user from player_progress.
  /// Each row contains: level_number (int), completed (bool), stars (int?).
  Future<List<Map<String, dynamic>>> getLevelProgress() async {
    final client = _client;
    if (client == null) return [];
    final user = client.auth.currentUser;
    if (user == null) return [];
    final profileData = await client
        .from('player_profiles')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();
    if (profileData == null) return [];
    final profileId = profileData['id'] as String;
    final rows = await client
        .from('player_progress')
        .select('level_number, completed, stars')
        .eq('user_id', profileId)
        .order('level_number');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Returns all achievement rows for the current user from the achievements table.
  Future<List<Map<String, dynamic>>> getAchievements() async {
    final client = _client;
    if (client == null) return [];
    final user = client.auth.currentUser;
    if (user == null) return [];
    final profileData = await client
        .from('player_profiles')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();
    if (profileData == null) return [];
    final profileId = profileData['id'] as String;
    final rows = await client
        .from('achievements')
        .select('achievement_id, unlocked_at')
        .eq('user_id', profileId);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
