-- DB-T04 unbound_anonymous_sees_nothing (Plan 12.2, 6.14): anonyme, ungebundene Sitzung
-- (Rolle authenticated, is_anonymous = true, keine Bindung): alle Tabellen 0 Zeilen bzw. kein Recht.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_unbound'), true);
\o
SELECT id AS plan_a1 FROM public.plans WHERE patient_id = t.id('pat_a1') \gset
\o /dev/null
SELECT t.as_user(t.id('anon_unbound'), true);

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT n.nspname, c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname IN ('public', 'app') AND c.relkind IN ('r', 'v', 'm', 'p')
            ORDER BY 1, 2 LOOP
    PERFORM t.ok(t.sees_nothing(format('SELECT 1 FROM %I.%I', r.nspname, r.relname)),
                 format('ungebunden: %s.%s 0 Zeilen oder kein Recht', r.nspname, r.relname));
  END LOOP;
END $$;
-- Hilfsfunktionen liefern nichts
SELECT t.is(app.current_patient_id(), NULL::uuid, 'current_patient_id() = null');
SELECT t.is(app.current_physio_practice(), NULL::uuid, 'current_physio_practice() = null');
SELECT t.is(app.patient_can_see_exercise(t.id('ex_cat1')), false, 'patient_can_see_exercise = false');
-- Schreiben scheitert
SELECT t.throws(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (%L, %L, %L, current_date, ''checklist'')',
                gen_random_uuid(), t.id('pat_a1'), :'plan_a1'), '42501', 'ungebunden: INSERT training_sessions (fremder Patient, echter Plan) verweigert');
SELECT t.throws(format('INSERT INTO public.appointments (patient_id, starts_at, title) VALUES (%L, now(), ''x'')', t.id('pat_a1')),
                '42501', 'ungebunden: INSERT appointments verweigert');
