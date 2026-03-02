// Edge Function: create-player-profile
// Spec: supabase-agent-spec.md § Function: create-player-profile
// Phase: 2 — Foundation
//
// Triggered by Supabase Auth hook_after_user_created.
// A database trigger (migration 011) also handles this for safety — the upsert
// with ignoreDuplicates ensures both can fire without conflict.
//
// Deployed with --no-verify-jwt because auth hooks are called by Supabase's auth
// service using HMAC-signed requests, not standard Supabase JWTs.
// Security: the upsert is constrained by the auth_id FK → auth.users(id), so a
// forged payload with a non-existent UUID will fail at the DB level.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req: Request) => {
  try {
    const payload = await req.json();

    // Auth hook format: payload.user
    // Database webhook format (fallback): payload.record
    const user = payload?.user ?? payload?.record;

    if (!user?.id) {
      return new Response(
        JSON.stringify({ error: 'Invalid payload: missing user id' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const isGuest = user.raw_app_meta_data?.is_anonymous === true;

    const { error } = await supabase
      .from('player_profiles')
      .upsert(
        { auth_id: user.id, is_guest: isGuest },
        { onConflict: 'auth_id', ignoreDuplicates: true },
      );

    if (error) {
      console.error('create-player-profile error:', error);
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('create-player-profile unhandled error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
