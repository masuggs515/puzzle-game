// Edge Function: on-hint-used
// Spec: supabase-agent-spec.md § Function: on-hint-used
// Phase: 5 — Economy & Progression
//
// Deducts hint_cost coins when a player uses a hint mid-puzzle.
// Idempotent via idempotency_key — safe to retry on network failure.
// Client NEVER writes directly to coin_transactions.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface HintUsedRequest {
  level_number: number
  word_slot_id: number
  idempotency_key: string
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    // --- Auth ---
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    const token = authHeader.replace('Bearer ', '')

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // --- Validate body ---
    let body: HintUsedRequest
    try {
      body = await req.json()
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { level_number, word_slot_id, idempotency_key } = body

    if (
      typeof level_number !== 'number' ||
      typeof word_slot_id !== 'number' ||
      !idempotency_key
    ) {
      return new Response(JSON.stringify({ error: 'Missing or invalid required fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // --- Fetch player profile ---
    const { data: profile, error: profileError } = await supabase
      .from('player_profiles')
      .select('id')
      .eq('auth_id', user.id)
      .single()

    if (profileError || !profile) {
      return new Response(JSON.stringify({ error: 'Profile not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const profile_id: string = profile.id

    // --- Idempotency check ---
    // If this hint deduction was already recorded, return the current balance
    // without deducting again. Safe for network retries.
    const { data: existingTx } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('idempotency_key', idempotency_key)
      .maybeSingle()

    if (existingTx) {
      const { data: allTx } = await supabase
        .from('coin_transactions')
        .select('amount')
        .eq('user_id', profile_id)

      const new_balance = (allTx ?? []).reduce(
        (sum: number, row: { amount: number }) => sum + row.amount,
        0,
      )

      return new Response(
        JSON.stringify({ success: true, new_balance, idempotent: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // --- Compute current balance ---
    const { data: allTx } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('user_id', profile_id)

    const balance = (allTx ?? []).reduce(
      (sum: number, row: { amount: number }) => sum + row.amount,
      0,
    )

    // --- Check hint cost from environment (default 5) ---
    const hint_cost = parseInt(Deno.env.get('HINT_COST_COINS') ?? '5', 10)

    if (balance < hint_cost) {
      return new Response(
        JSON.stringify({
          success: false,
          reason: 'insufficient_coins',
          balance,
          hint_cost,
        }),
        {
          status: 200, // 200 so Flutter can read the body; not a server error
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      )
    }

    // --- Deduct hint cost ---
    const { error: deductError } = await supabase
      .from('coin_transactions')
      .insert({
        user_id: profile_id,
        amount: -hint_cost,
        transaction_type: 'hint_purchase',
        reference_id: `${level_number}:${word_slot_id}`,
        idempotency_key,
      })

    if (deductError) {
      if (deductError.code === '23505') {
        // Concurrent request already wrote this — idempotent, compute balance and return
        console.warn('on-hint-used: idempotency_key race — treating as success')
      } else {
        console.error('on-hint-used coin insert error:', deductError)
        return new Response(JSON.stringify({ error: 'Failed to record hint transaction' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // --- Compute new balance ---
    const { data: updatedTx } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('user_id', profile_id)

    const new_balance = (updatedTx ?? []).reduce(
      (sum: number, row: { amount: number }) => sum + row.amount,
      0,
    )

    return new Response(
      JSON.stringify({ success: true, new_balance }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    console.error('on-hint-used unhandled error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
