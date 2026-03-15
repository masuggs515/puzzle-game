// Edge Function: on-level-complete
// Spec: supabase-agent-spec.md § Function: on-level-complete
// Phase: 5 — Economy & Progression
//
// Awards coins, updates streak, increments total_words_found, writes progress,
// and checks all achievement triggers. Idempotent via idempotency_key.
// Client must NEVER write directly to coin_transactions or achievements.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Achievement definitions: id -> coin reward
const ACHIEVEMENT_COINS: Record<string, number> = {
  first_word:         10,
  getting_warmed_up:  20,
  puzzle_apprentice:  50,
  century:            100,
  boss_slayer:        30,
  unstoppable:        100,
  word_collector:     20,
  lexicon:            50,
  wordsmith:          100,
  grand_lexicon:      250,
  no_hints_needed:    50,
  first_try:          75,
  perfectionist:      100,
  consistent:         50,
  dedicated:          150,
  obsessed:           500,
  master_of_words:    500,
  saver:              50,
  high_roller:        75,
  vault_dweller:      100,
}

interface LevelCompleteRequest {
  level_number: number
  level_type: 'standard' | 'bossLevel' | 'vault'
  hints_used: number
  attempts_made: number
  words_found: number
  time_taken_ms: number
  stars: 1 | 2 | 3
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
    let body: LevelCompleteRequest
    try {
      body = await req.json()
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const {
      level_number,
      level_type,
      hints_used,
      attempts_made,
      words_found,
      stars,
      idempotency_key,
    } = body

    if (
      typeof level_number !== 'number' ||
      !['standard', 'bossLevel', 'vault'].includes(level_type) ||
      typeof hints_used !== 'number' ||
      typeof attempts_made !== 'number' ||
      typeof words_found !== 'number' ||
      ![1, 2, 3].includes(stars) ||
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
      .select('id, current_streak, longest_streak, last_played_date, total_words_found, current_vault_level')
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
    // If this exact transaction was already written, return the cached result
    // immediately without performing any further writes.
    const { data: existingTx } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('idempotency_key', idempotency_key)
      .maybeSingle()

    if (existingTx) {
      // Transaction already applied — recompute balance and streak from current DB state
      const { data: balanceRow } = await supabase
        .from('coin_transactions')
        .select('amount')
        .eq('user_id', profile_id)

      const new_balance = (balanceRow ?? []).reduce(
        (sum: number, row: { amount: number }) => sum + row.amount,
        0,
      )

      // Re-fetch updated profile for streak values
      const { data: freshProfile } = await supabase
        .from('player_profiles')
        .select('current_streak, longest_streak')
        .eq('id', profile_id)
        .single()

      return new Response(
        JSON.stringify({
          success: true,
          coins_awarded: existingTx.amount,
          new_balance,
          streak: {
            current: freshProfile?.current_streak ?? profile.current_streak,
            longest: freshProfile?.longest_streak ?? profile.longest_streak,
          },
          achievements_unlocked: [],
          idempotent: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // --- Coin award ---
    const coins_awarded = level_type === 'bossLevel' ? 20 : 10
    const tx_type = level_type === 'bossLevel' ? 'boss_complete' : 'level_complete'

    const { error: coinError } = await supabase
      .from('coin_transactions')
      .insert({
        user_id: profile_id,
        amount: coins_awarded,
        transaction_type: tx_type,
        reference_id: String(level_number),
        idempotency_key,
      })

    if (coinError) {
      // A unique violation on idempotency_key means a concurrent request won the race.
      // Treat as idempotent success rather than an error.
      if (coinError.code === '23505') {
        console.warn('on-level-complete: idempotency_key race — treating as success')
      } else {
        console.error('on-level-complete coin insert error:', coinError)
        return new Response(JSON.stringify({ error: 'Failed to record coin transaction' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // --- Upsert player_progress ---
    // ON CONFLICT: idx_player_progress_unique (user_id, level_number, level_type)
    // Update stars only if the new result is better (higher stars wins).
    const { error: progressError } = await supabase
      .from('player_progress')
      .upsert(
        {
          user_id: profile_id,
          level_number,
          level_type,
          completed: true,
          stars,
          hints_used,
          attempts_made,
          completed_at: new Date().toISOString(),
        },
        {
          onConflict: 'user_id,level_number,level_type',
          ignoreDuplicates: false,
        },
      )

    if (progressError) {
      console.error('on-level-complete progress upsert error:', progressError)
      // Non-fatal: coin already written, log and continue
    }

    // --- Increment total_words_found ---
    // Use raw SQL via rpc to atomically increment rather than read-then-write
    const { error: wordsError } = await supabase.rpc('increment_total_words_found', {
      p_profile_id: profile_id,
      p_words: words_found,
    })

    if (wordsError) {
      // Fallback: manual increment if rpc not yet deployed
      console.error('on-level-complete increment_total_words_found error:', wordsError)
      await supabase
        .from('player_profiles')
        .update({ total_words_found: profile.total_words_found + words_found })
        .eq('id', profile_id)
    }

    // --- Streak update ---
    const todayUTC = new Date().toISOString().slice(0, 10) // YYYY-MM-DD
    const yesterdayUTC = new Date(Date.now() - 86_400_000).toISOString().slice(0, 10)

    let new_streak = profile.current_streak
    let new_longest = profile.longest_streak

    if (profile.last_played_date === todayUTC) {
      // Already played today — streak unchanged
      new_streak = profile.current_streak
    } else if (profile.last_played_date === yesterdayUTC) {
      // Consecutive day — extend streak
      new_streak = profile.current_streak + 1
      if (new_streak > new_longest) {
        new_longest = new_streak
      }
    } else {
      // Gap in play or first play — reset
      new_streak = 1
      if (1 > new_longest) {
        new_longest = 1
      }
    }

    const { error: streakError } = await supabase
      .from('player_profiles')
      .update({
        current_streak: new_streak,
        longest_streak: new_longest,
        last_played_date: todayUTC,
      })
      .eq('id', profile_id)

    if (streakError) {
      console.error('on-level-complete streak update error:', streakError)
    }

    // --- Update current_vault_level for vault levels ---
    if (level_type === 'vault') {
      const newVaultLevel = Math.max((profile.current_vault_level as number) ?? 0, level_number)
      const { error: vaultLevelError } = await supabase
        .from('player_profiles')
        .update({ current_vault_level: newVaultLevel })
        .eq('id', profile_id)
      if (vaultLevelError) {
        console.error('on-level-complete vault level update error:', vaultLevelError)
      }
    }

    // --- Fetch updated totals for achievement checks ---
    // Re-fetch total_words_found after the increment so achievement thresholds
    // are evaluated against the post-increment value.
    const { data: updatedProfile } = await supabase
      .from('player_profiles')
      .select('total_words_found')
      .eq('id', profile_id)
      .single()

    const total_words_found = updatedProfile?.total_words_found ?? (profile.total_words_found + words_found)

    // Fetch all coin transactions now — used for both saver check and final balance.
    // Must come after the coin award insert above so the level reward is included.
    const { data: allTx } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('user_id', profile_id)

    const totalSpentBeforeAchievements = (allTx ?? [])
      .filter((r: { amount: number }) => r.amount < 0)
      .reduce((sum: number, r: { amount: number }) => sum + Math.abs(r.amount), 0)

    const balanceBeforeAchievements = (allTx ?? []).reduce(
      (sum: number, r: { amount: number }) => sum + r.amount,
      0,
    )

    // Fetch completed level counts for achievement checks.
    // ORDER BY completed_at ASC so slice(-10) gives the 10 most-recent completions.
    const { data: progressRows } = await supabase
      .from('player_progress')
      .select('level_type, hints_used, attempts_made, stars')
      .eq('user_id', profile_id)
      .eq('completed', true)
      .order('completed_at', { ascending: true })

    const completedRows = progressRows ?? []
    const completedCount = completedRows.length
    const bossCompletions = completedRows.filter((r: { level_type: string }) => r.level_type === 'bossLevel').length

    // Fetch already-unlocked achievements to avoid duplicate checks
    const { data: unlockedRows } = await supabase
      .from('achievements')
      .select('achievement_id')
      .eq('user_id', profile_id)

    const alreadyUnlocked = new Set((unlockedRows ?? []).map((r: { achievement_id: string }) => r.achievement_id))

    // Build the list of newly triggered achievements
    const triggered: string[] = []

    const maybeUnlock = (id: string, condition: boolean) => {
      if (condition && !alreadyUnlocked.has(id)) {
        triggered.push(id)
      }
    }

    // Progress milestones
    maybeUnlock('first_word', completedCount >= 1)
    maybeUnlock('getting_warmed_up', completedCount >= 10)
    maybeUnlock('puzzle_apprentice', completedCount >= 50)
    maybeUnlock('century', completedCount >= 100)

    // Boss milestones
    maybeUnlock('boss_slayer', bossCompletions >= 1)
    maybeUnlock('unstoppable', bossCompletions >= 10)

    // Word count milestones
    maybeUnlock('word_collector', total_words_found >= 100)
    maybeUnlock('lexicon', total_words_found >= 500)
    maybeUnlock('wordsmith', total_words_found >= 1000)
    maybeUnlock('grand_lexicon', total_words_found >= 5000)

    // Skill-based
    // no_hints_needed: last 10 completed levels all have hints_used = 0
    if (!alreadyUnlocked.has('no_hints_needed') && completedCount >= 10) {
      const last10 = completedRows.slice(-10)
      if (last10.every((r: { hints_used: number }) => r.hints_used === 0)) {
        triggered.push('no_hints_needed')
      }
    }

    // first_try: 50+ completions with attempts_made = 1
    const firstTryCount = completedRows.filter((r: { attempts_made: number }) => r.attempts_made === 1).length
    maybeUnlock('first_try', firstTryCount >= 50)

    // perfectionist: this completion is bossLevel with hints_used = 0
    maybeUnlock('perfectionist', level_type === 'bossLevel' && hints_used === 0)

    // Streak-based
    maybeUnlock('consistent', new_streak >= 7)
    maybeUnlock('dedicated', new_streak >= 30)
    maybeUnlock('obsessed', new_streak >= 100)

    // saver: accumulated 500+ coins without ever spending any
    // totalSpentBeforeAchievements is computed from the coin_transactions snapshot taken
    // right after this level's coin award was inserted (above).
    maybeUnlock('saver', totalSpentBeforeAchievements === 0 && balanceBeforeAchievements >= 500)

    // vault_dweller: complete first vault level
    maybeUnlock('vault_dweller', level_type === 'vault' && completedCount >= 1)

    // master_of_words: all levels 1-200 completed AND none skipped (stars not null)
    // Only check if completedCount is high enough to be feasible
    if (!alreadyUnlocked.has('master_of_words') && completedCount >= 200) {
      const standardAndBoss = completedRows.filter(
        (r: { level_type: string; stars: number | null }) =>
          r.level_type !== 'vault' && r.stars !== null,
      )
      if (standardAndBoss.length >= 200) {
        triggered.push('master_of_words')
      }
    }

    // --- Unlock achievements and award their coins ---
    const achievements_unlocked: string[] = []

    for (const achievement_id of triggered) {
      const achievement_coins = ACHIEVEMENT_COINS[achievement_id] ?? 0

      // Insert into achievements (unique constraint prevents duplicates)
      const { error: achError } = await supabase
        .from('achievements')
        .insert({
          user_id: profile_id,
          achievement_id,
          coins_awarded: achievement_coins,
        })

      if (achError) {
        if (achError.code === '23505') {
          // Race condition — another request already unlocked this, skip
          console.warn(`on-level-complete: achievement ${achievement_id} already unlocked (race)`)
          continue
        }
        console.error(`on-level-complete: achievement insert error for ${achievement_id}:`, achError)
        continue
      }

      achievements_unlocked.push(achievement_id)

      // Award coins for the achievement
      if (achievement_coins > 0) {
        const achIdempotencyKey = `${profile_id}:achievement:${achievement_id}`
        const { error: achCoinError } = await supabase
          .from('coin_transactions')
          .insert({
            user_id: profile_id,
            amount: achievement_coins,
            transaction_type: 'achievement',
            reference_id: achievement_id,
            idempotency_key: achIdempotencyKey,
          })

        if (achCoinError && achCoinError.code !== '23505') {
          console.error(`on-level-complete: achievement coin insert error for ${achievement_id}:`, achCoinError)
        }
      }
    }

    // --- Compute final balance ---
    // Re-fetch after achievement coins have been inserted so the balance is accurate.
    const { data: finalTxRows } = await supabase
      .from('coin_transactions')
      .select('amount')
      .eq('user_id', profile_id)

    const new_balance = (finalTxRows ?? []).reduce(
      (sum: number, row: { amount: number }) => sum + row.amount,
      0,
    )

    // --- Return ---
    return new Response(
      JSON.stringify({
        success: true,
        coins_awarded,
        new_balance,
        streak: {
          current: new_streak,
          longest: new_longest,
        },
        achievements_unlocked,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    console.error('on-level-complete unhandled error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
