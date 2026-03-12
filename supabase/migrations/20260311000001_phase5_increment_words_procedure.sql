-- Phase 5 — Economy & Progression
-- Adds increment_total_words_found stored procedure used by on-level-complete Edge Function.
--
-- Spec: supabase-agent-spec.md § Stored Procedures
-- Phase: 5 — Economy & Progression

-- Atomically increments total_words_found on a player_profiles row.
-- Used by the on-level-complete Edge Function (service role context).
CREATE OR REPLACE FUNCTION public.increment_total_words_found(
  p_profile_id uuid,
  p_words integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.player_profiles
  SET total_words_found = total_words_found + p_words,
      updated_at = now()
  WHERE id = p_profile_id;
END;
$$;
