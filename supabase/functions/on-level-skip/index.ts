// Edge Function: on-level-skip
// Spec: supabase-agent-spec.md § Function: on-level-skip
// Phase: 5 — Economy & Progression
//
// Deducts 50 coins, marks the level as skipped (completed=true, stars=NULL),
// and checks the high_roller achievement (1000+ coins total spent).
// Idempotent via idempotency_key — safe to retry on network failure.
// Client NEVER writes directly to coin_transactions or player_progress.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const SKIP_COST = 50

// Achievement coin rewards for achievements this function can trigger
const HIGH_ROLLER_COINS = 75
const SAVER_COINS = 50

interface LevelSkipRequest {
  level_number: number
  level_type: 'standard' | 'bossLevel' | 'vault'
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
    let body: LevelSkipRequest
    try {
      body = await req.json()
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { level_number, level_type, idempotency_key } = body

    if (
      typeof level_number !== 'number' ||
      !['standard', 'bossLevel', 'vault'].includes(level_type) ||
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
    // If the skip deduction was already recorded, return the current balance
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

    if (balance < SKIP_COST) {
      return new Response(
        JSON.stringify({
          success: false,
          reason: 'insufficient_coins',
          balance,
          skip_cost: SKIP_COST,
        }),
        {
          status: 200, // 200 so Flutter can read the body; not a server error
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      )
    }

    // --- Deduct skip cost ---
    const { error: deductError } = await supabase
      .from('coin_transactions')
      .insert({
        user_id: profile_id,
        amount: -SKIP_COST,
        transaction_type: 'skip_purchase',
        reference_id: String(level_number),
        idempotency_key,
      })

    if (deductError) {
      if (deductError.code === '23505') {
        // Concurrent request already wrote this — idempotent, continue to progress upsert
        console.warn('on-level-skip: idempotency_key race — treating as success')
      } else {
        console.error('on-level-skip coin insert error:', deductError)
        return new Response(JSON.stringify({ error: 'Failed to record skip transaction' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // --- Upsert player_progress (skipped: completed=true, stars=NULL) ---
    // stars=NULL distinguishes a skip from a genuine 1-star completion.
    // Guard: do NOT overwrite a genuine star-earning completion. If the player
    // already completed this level with earned stars, leave that record intact
    // so star ratings and master_of_words eligibility are preserved.
    const { data: existingProgress } = await supabase
      .from('player_progress')
      .select('id, stars')
      .eq('user_id', profile_id)
      .eq('level_number', level_number)
      .eq('level_type', level_type)
      .maybeSingle()

    const alreadyCompletedWithStars = existingProgress !== null && existingProgress.stars !== null

    if (!alreadyCompletedWithStars) {
      const { error: progressError } = await supabase
        .from('player_progress')
        .upsert(
          {
            user_id: profile_id,
            level_number,
            level_type,
            completed: true,
            stars: null,  // null = skipped, not earned
            completed_at: new Date().toISOString(),
          },
          {
            onConflict: 'user_id,level_number,level_type',
            ignoreDuplicates: false,
          },
        )

      if (progressError) {
        console.error('on-level-skip progress upsert error:', progressError)
        // Non-fatal: coin already deducted, log and continue
      }
    }

    // --- Check high_roller achievement ---
    // high_roller: total negative coin transactions (spending) >= 1000 coins spent
    // We re-fetch all transactions to compute total spending post-deduction.
    const achievements_unlocked: string[] = []

    const { data: freshTx } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('user_id', profile_id)

    const txRows: { amount: number }[] = freshTx ?? []
    const totalSpent = txRows
      .filter((r) => r.amount < 0)
      .reduce((sum, r) => sum + Math.abs(r.amount), 0)

    const new_balance = txRows.reduce((sum, r) => sum + r.amount, 0)

    // Fetch already-unlocked achievements to avoid re-awarding
    const { data: unlockedRows } = await supabase
      .from('achievements')
      .select('achievement_id')
      .eq('user_id', profile_id)

    const alreadyUnlocked = new Set(
      (unlockedRows ?? []).map((r: { achievement_id: string }) => r.achievement_id),
    )

    // high_roller: spent 1000+ coins total
    if (!alreadyUnlocked.has('high_roller') && totalSpent >= 1000) {
      const { error: achError } = await supabase
        .from('achievements')
        .insert({
          user_id: profile_id,
          achievement_id: 'high_roller',
          coins_awarded: HIGH_ROLLER_COINS,
        })

      if (!achError || achError.code === '23505') {
        if (!achError) {
          achievements_unlocked.push('high_roller')

          // Award the achievement coins
          const achIdempotencyKey = `${profile_id}:achievement:high_roller`
          const { error: achCoinError } = await supabase
            .from('coin_transactions')
            .insert({
              user_id: profile_id,
              amount: HIGH_ROLLER_COINS,
              transaction_type: 'achievement',
              reference_id: 'high_roller',
              idempotency_key: achIdempotencyKey,
            })

          if (achCoinError && achCoinError.code !== '23505') {
            console.error('on-level-skip: high_roller coin insert error:', achCoinError)
          }
        }
      } else {
        console.error('on-level-skip: high_roller achievement insert error:', achError)
      }
    }

    // saver achievement is awarded by on-level-complete (for positive balance thresholds),
    // but we note it here for completeness — no additional saver check on skip.
    // If the saver achievement needs checking here in future, add it below this comment.

    // Re-fetch balance to include any achievement coins just awarded
    const { data: finalTx } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('user_id', profile_id)

    const final_balance = (finalTx ?? []).reduce(
      (sum: number, row: { amount: number }) => sum + row.amount,
      0,
    )

    return new Response(
      JSON.stringify({
        success: true,
        new_balance: final_balance,
        achievements_unlocked,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    console.error('on-level-skip unhandled error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
