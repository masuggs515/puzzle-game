// Edge Function: on-rewarded-ad
// Spec: master-development-plan.md § 9.6 Rewarded Ad Edge Function
// Phase: 7 — Ads & Monetization
//
// Awards coins to a player after they watch a rewarded ad.
// Idempotent via idempotency_key — prevents double-award on retry.
// Client NEVER writes directly to coin_transactions.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Server-authoritative coin amounts for rewarded ad placements.
// level_complete placement = 15 coins, shop placement = 30 coins.
// Client sends the proposed amount; we validate it against this whitelist.
// Any value not in this set falls back to 15 (minimum valid award).
const VALID_COINS_AMOUNTS = new Set([15, 30])

interface RewardedAdRequest {
  ad_unit_id: string       // for logging and reference_id on the transaction
  coins_to_award: number   // client-proposed; validated server-side
  idempotency_key: string  // UUID from client — prevents double-award on retry
}

interface RewardedAdResponse {
  success: boolean
  coins_awarded?: number
  new_balance?: number
  idempotent?: boolean
  error?: string
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
    let body: RewardedAdRequest
    try {
      body = await req.json()
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { ad_unit_id, coins_to_award, idempotency_key } = body

    if (
      typeof ad_unit_id !== 'string' || !ad_unit_id ||
      typeof coins_to_award !== 'number' ||
      typeof idempotency_key !== 'string' || !idempotency_key
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
    // If this exact idempotency_key was already used, return the cached result
    // immediately without any further writes.
    const { data: existingTx } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('idempotency_key', idempotency_key)
      .maybeSingle()

    if (existingTx) {
      const { data: balanceRows } = await supabase
        .from('coin_transactions')
        .select('amount')
        .eq('user_id', profile_id)

      const new_balance = (balanceRows ?? []).reduce(
        (sum: number, row: { amount: number }) => sum + row.amount,
        0,
      )

      return new Response(
        JSON.stringify({
          success: true,
          coins_awarded: existingTx.amount,
          new_balance,
          idempotent: true,
        } satisfies RewardedAdResponse),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // --- Server-side coin validation ---
    // Never trust the client's proposed amount — validate against the server whitelist.
    // Falls back to 15 (minimum valid placement) if an unrecognised value is sent.
    const coinsToAward = VALID_COINS_AMOUNTS.has(coins_to_award) ? coins_to_award : 15

    if (coinsToAward !== coins_to_award) {
      console.warn(
        `on-rewarded-ad: client proposed ${coins_to_award} coins — not in whitelist, awarding ${coinsToAward}`,
      )
    }

    // --- Insert coin transaction ---
    const { error: coinError } = await supabase
      .from('coin_transactions')
      .insert({
        user_id: profile_id,
        amount: coinsToAward,
        transaction_type: 'rewarded_ad',
        reference_id: ad_unit_id,
        idempotency_key,
      })

    if (coinError) {
      // A unique violation on idempotency_key means a concurrent request won the race.
      // Treat as idempotent success rather than an error.
      if (coinError.code === '23505') {
        console.warn('on-rewarded-ad: idempotency_key race — treating as success')
      } else {
        console.error('on-rewarded-ad coin insert error:', coinError)
        return new Response(JSON.stringify({ error: 'Failed to record coin transaction' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // --- Compute balance ---
    const { data: balanceRows } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('user_id', profile_id)

    const new_balance = (balanceRows ?? []).reduce(
      (sum: number, row: { amount: number }) => sum + row.amount,
      0,
    )

    // --- Return ---
    return new Response(
      JSON.stringify({
        success: true,
        coins_awarded: coinsToAward,
        new_balance,
      } satisfies RewardedAdResponse),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    console.error('on-rewarded-ad unhandled error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
