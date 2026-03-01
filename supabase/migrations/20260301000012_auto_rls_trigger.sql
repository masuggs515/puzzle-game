-- Migration 012: Auto-enable RLS on any new table created in public schema
-- Spec: supabase-agent-spec.md § Auto-enable RLS on new tables
-- Phase: 2 — Foundation
--
-- Safety net: if a new table is added in a future migration without an explicit
-- ALTER TABLE ... ENABLE ROW LEVEL SECURITY, this event trigger catches it.

CREATE OR REPLACE FUNCTION enable_rls_on_new_table()
RETURNS event_trigger AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
  WHERE command_tag = 'CREATE TABLE'
  LOOP
    EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', obj.object_identity);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE EVENT TRIGGER auto_enable_rls
ON ddl_command_end
WHEN TAG IN ('CREATE TABLE')
EXECUTE FUNCTION enable_rls_on_new_table();
