-- DB-T03 anon_role_sees_nothing (Plan 12.2, 6.1 Nr. 2): Rolle anon (ohne Anmeldung): jede
-- Tabelle und Sicht in public/app und jede Funktion verweigert.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_anon();

DO $$
DECLARE r record; v_args text;
BEGIN
  FOR r IN SELECT n.nspname, c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname IN ('public', 'app') AND c.relkind IN ('r', 'v', 'm', 'p')
            ORDER BY 1, 2 LOOP
    PERFORM t.throws(format('SELECT 1 FROM %I.%I', r.nspname, r.relname), '42501',
                     format('anon: SELECT %s.%s verweigert', r.nspname, r.relname));
  END LOOP;
  FOR r IN SELECT n.nspname, p.proname, p.pronargs FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname IN ('public', 'app') AND p.prokind = 'f' AND p.prorettype <> 'trigger'::regtype
            ORDER BY 1, 2 LOOP
    v_args := (SELECT string_agg('NULL', ',') FROM generate_series(1, r.pronargs));
    PERFORM t.throws(format('SELECT %I.%I(%s)', r.nspname, r.proname, coalesce(v_args, '')), '42501',
                     format('anon: %s.%s() verweigert', r.nspname, r.proname));
  END LOOP;
END $$;
SELECT t.throws('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), current_date, ''checklist'')',
                '42501', 'anon: INSERT verweigert');
