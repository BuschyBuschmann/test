-- DB-T08 patient_sees_only_self (Plan 12.2, 6.14): gebundener Patient sieht nur eigene Zeilen,
-- auch nicht die anderer Patienten derselben Praxis. Jede Tabelle in public ist eingeordnet.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('anon_a1'), true);
DO $$
DECLARE tbl text;
BEGIN
  -- Tabellen mit patient_id: nur eigene Zeilen, und eigene sind sichtbar
  FOREACH tbl IN ARRAY ARRAY['injuries', 'plans', 'treaters', 'appointments', 'history_entries', 'consents',
                             'account_events', 'training_sessions', 'exercise_results'] LOOP
    PERFORM t.is(t.count(format('SELECT 1 FROM public.%I WHERE patient_id <> %L', tbl, t.id('pat_a1'))), 0::bigint,
                 format('Patient sieht keine fremden Zeilen in %s', tbl));
    PERFORM t.ok(t.count(format('SELECT 1 FROM public.%I WHERE patient_id = %L', tbl, t.id('pat_a1'))) > 0,
                 format('Patient sieht eigene Zeilen in %s', tbl));
  END LOOP;
  -- ohne Recht bzw. ohne Policy fuer Patienten
  FOREACH tbl IN ARRAY ARRAY['practices', 'physios', 'invitations', 'redeem_attempts', 'plan_templates'] LOOP
    PERFORM t.ok(t.sees_nothing(format('SELECT 1 FROM public.%I', tbl)), format('Patient sieht nichts in %s', tbl));
  END LOOP;
END $$;
SELECT t.is((SELECT string_agg(id::text, ',') FROM public.patients), t.id('pat_a1')::text, 'patients: nur die eigene Zeile');
SELECT t.is((SELECT count(*) FROM public.phases ph WHERE ph.plan_id NOT IN (SELECT id FROM public.plans)), 0::bigint, 'phases: nur eigener Plan');
SELECT t.is((SELECT count(DISTINCT plan_id) FROM public.plan_items), 1::bigint, 'plan_items: nur eigener Plan');
SELECT t.is((SELECT string_agg(name, ',' ORDER BY name) FROM public.exercises), 'Bruecke,Kniebeuge', 'exercises: nur Uebungen des eigenen Plans');
SELECT t.as_admin();
SELECT t.is((SELECT string_agg(c.relname, ', ') FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname = 'public' AND c.relkind IN ('r', 'v', 'p')
                AND c.relname NOT IN ('injuries', 'plans', 'treaters', 'appointments', 'history_entries', 'consents',
                  'account_events', 'training_sessions', 'exercise_results', 'practices', 'physios', 'invitations',
                  'redeem_attempts', 'plan_templates', 'patients', 'phases', 'plan_items', 'exercises')),
            NULL, 'jede Tabelle in public ist in diesem Test eingeordnet');
