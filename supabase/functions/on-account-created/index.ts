// Edge Function: on-account-created
// Spec: supabase-agent-spec.md § Function: on-account-created
// Phase: 2 — Foundation
//
// Called by Flutter client after successful account creation (email / Apple / Google).
// Migrates anonymous session data to the new authenticated account atomically.
// Uses the migrate_anonymous_to_authenticated stored procedure (migration 010).

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface MigrateRequest {
  anonymous_user_id: string; // old auth.uid() from anonymous session
  new_auth_id: string;       // new auth.uid() after account creation
}

serve(async (req: Request) => {
  // Only allow POST
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    // Validate the caller is authenticated — extract JWT from Authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const body: MigrateRequest = await req.json();
    const { anonymous_user_id, new_auth_id } = body;

    if (!anonymous_user_id || !new_auth_id) {
      return new Response(
        JSON.stringify({ error: 'Missing anonymous_user_id or new_auth_id' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // Verify the caller's JWT matches new_auth_id (prevents one user migrating another's data)
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', ''),
    );

    if (authError || user?.id !== new_auth_id) {
      return new Response(JSON.stringify({ error: 'Forbidden' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Atomic migration via stored procedure (migration 010)
    const { error } = await supabase.rpc('migrate_anonymous_to_authenticated', {
      p_anon_auth_id: anonymous_user_id,
      p_new_auth_id: new_auth_id,
    });

    if (error) {
      console.error('on-account-created migration error:', error);
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // Fetch the migrated profile to return its id
    const { data: profile, error: fetchError } = await supabase
      .from('player_profiles')
      .select('id')
      .eq('auth_id', new_auth_id)
      .single();

    if (fetchError) {
      console.error('on-account-created profile fetch error:', fetchError);
      return new Response(
        JSON.stringify({ error: 'Migration succeeded but profile fetch failed' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    return new Response(
      JSON.stringify({ success: true, profile_id: profile.id }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('on-account-created unhandled error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
