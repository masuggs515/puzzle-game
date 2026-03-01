// Edge Function: create-player-profile
// Spec: supabase-agent-spec.md § Function: create-player-profile
// Phase: 2 — Foundation
//
// Triggered by Supabase Auth webhook on new user creation.
// A database trigger (migration 011) also handles this locally — this Edge Function
// is the supplemental mechanism for cloud environments.
//
// TODO MAS: Configure the Auth webhook in Supabase dashboard for puzzle-game-dev and
// puzzle-game-prod. Go to Authentication → Webhooks → Add webhook → select the
// "User created" event → point to this function's URL. Without this, profile creation
// in cloud environments relies on the fallback ensureProfile call in SupabaseService.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const user = payload?.record;

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
