// Edge Function: on-iap-purchase
// Spec: master-development-plan.md § 9.6 Rewarded Ad Edge Function
// Phase: 7 — Ads & Monetization
//
// Receives a RevenueCat webhook after a successful IAP purchase.
// Awards coins to the player based on the product ID.
// Idempotent via transaction_id — prevents double-award on webhook retry.
// Client NEVER writes directly to coin_transactions.
//
// TODO MAS: configure REVENUECAT_WEBHOOK_SECRET in Supabase Edge Function secrets
// TODO MAS: configure RevenueCat webhook URL to point to this function

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Server-authoritative coin bundle definitions.
// These must match the products configured in RevenueCat and the App Store / Play Store.
const COIN_BUNDLES: Record<string, number> = {
  coins_500:  500,
  coins_1200: 1200,
  coins_2500: 2500,
  coins_6000: 6000,
}

interface IapPurchaseRequest {
  app_user_id: string    // RevenueCat user ID — we configure RevenueCat to use Supabase auth UID
  product_id: string     // e.g. 'coins_500', 'coins_1200', etc.
  transaction_id: string // RevenueCat transaction ID — used as idempotency_key
  revenue_usd: number    // purchase price in USD (for logging)
}

interface IapPurchaseResponse {
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
    // --- Webhook secret authentication ---
    // This endpoint is called by RevenueCat server, not by a user JWT.
    // RevenueCat sends the shared secret in the Authorization header as: Bearer <secret>
    const authHeader = req.headers.get('Authorization') ?? ''
    const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET') ?? ''

    if (!webhookSecret) {
      // Secret not configured — log a warning and proceed for development convenience.
      // In production this must always be set.
      console.warn(
        'on-iap-purchase: REVENUECAT_WEBHOOK_SECRET is not set — skipping auth check. ' +
        'This must be configured before going to production.',
      )
    } else if (authHeader !== `Bearer ${webhookSecret}`) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // --- Validate body ---
    let body: IapPurchaseRequest
    try {
      body = await req.json()
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { app_user_id, product_id, transaction_id, revenue_usd } = body

    if (
      typeof app_user_id !== 'string' || !app_user_id ||
      typeof product_id !== 'string' || !product_id ||
      typeof transaction_id !== 'string' || !transaction_id ||
      typeof revenue_usd !== 'number'
    ) {
      return new Response(JSON.stringify({ error: 'Missing or invalid required fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // --- Validate product ID against server-side bundle config ---
    const coinsForProduct = COIN_BUNDLES[product_id]
    if (coinsForProduct === undefined) {
      console.warn(`on-iap-purchase: unknown product_id '${product_id}'`)
      return new Response(JSON.stringify({ error: `Unknown product_id: ${product_id}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // --- Idempotency check ---
    // RevenueCat may retry webhooks on failure. If this transaction_id is already
    // recorded, return success immediately without writing again.
    const { data: existingTx } = await supabase
      .from('coin_transactions')
      .select('amount, user_id')
      .eq('idempotency_key', transaction_id)
      .maybeSingle()

    if (existingTx) {
      const { data: balanceRows } = await supabase
        .from('coin_transactions')
        .select('amount')
        .eq('user_id', existingTx.user_id)

      const new_balance = (balanceRows ?? []).reduce(
        (sum: number, row: { amount: number }) => sum + row.amount,
        0,
      )

      return new Response(
        JSON.stringify({
          success: true,
          idempotent: true,
          coins_awarded: existingTx.amount,
          new_balance,
        } satisfies IapPurchaseResponse),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // --- Look up player profile ---
    // RevenueCat is configured to use the Supabase auth user ID as the app_user_id,
    // so we can look up the profile directly by auth_id.
    const { data: profile, error: profileError } = await supabase
      .from('player_profiles')
      .select('id')
      .eq('auth_id', app_user_id)
      .single()

    if (profileError || !profile) {
      console.error(
        `on-iap-purchase: profile not found for app_user_id=${app_user_id}`,
        profileError,
      )
      return new Response(JSON.stringify({ error: 'Player profile not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const profile_id: string = profile.id

    // --- Insert coin transaction ---
    const { error: coinError } = await supabase
      .from('coin_transactions')
      .insert({
        user_id: profile_id,
        amount: coinsForProduct,
        transaction_type: 'iap',
        reference_id: product_id,
        idempotency_key: transaction_id,
      })

    if (coinError) {
      // Unique violation on idempotency_key — concurrent webhook delivery, treat as success.
      if (coinError.code === '23505') {
        console.warn('on-iap-purchase: idempotency_key race — treating as success')
      } else {
        console.error('on-iap-purchase coin insert error:', coinError)
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

    console.log(
      `on-iap-purchase: awarded ${coinsForProduct} coins to profile=${profile_id} ` +
      `for product=${product_id} revenue_usd=${revenue_usd}`,
    )

    // --- Return ---
    return new Response(
      JSON.stringify({
        success: true,
        coins_awarded: coinsForProduct,
        new_balance,
      } satisfies IapPurchaseResponse),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    console.error('on-iap-purchase unhandled error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
