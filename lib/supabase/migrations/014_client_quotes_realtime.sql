-- WorkBridge / permit_plans: enable live updates for the Client quote inbox.
-- Requires migrations 007 and 008 to be applied first.
-- Client visibility remains governed by the existing quotes RLS policies.

DO $migration$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_publication
    WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'quotes'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.quotes';
  END IF;
END;
$migration$;

COMMENT ON TABLE public.quotes IS
  'Engineer quotes. Published to Supabase Realtime for immediate Client quote inbox updates; row visibility is controlled by RLS.';
