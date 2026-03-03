-- Migration: Restrict migrate_anonymous_to_authenticated to service role only
-- Spec: master-development-plan.md § 2.3 Anonymous Session Flow
-- Phase: 2 — Foundation
--
-- Security fix: any authenticated client could call this SECURITY DEFINER function
-- via REST RPC (/rest/v1/rpc/migrate_anonymous_to_authenticated) and manipulate
-- auth_id values on player_profiles rows belonging to other users.
--
-- Fix: Supabase grants EXECUTE to `anon` and `authenticated` individually when a
-- function is created (not via PUBLIC), so REVOKE FROM PUBLIC is a no-op here.
-- Revoke from each client-facing role directly; `service_role` and `postgres`
-- retain their grants so Edge Functions can still call it.

REVOKE EXECUTE ON FUNCTION migrate_anonymous_to_authenticated(uuid, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION migrate_anonymous_to_authenticated(uuid, uuid) FROM authenticated;
