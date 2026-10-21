-- DB-T06 physio_practice_isolation (Plan 12.2, 6.14, P-1 AK 1): Physio der Praxis A sieht
-- 0 Zeilen der Praxis B in jeder Tabelle (und umgekehrt). Die fremden Zeilen werden als Admin
-- bestimmt; jede Tabelle in public muss hier eingeordnet sein.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();

CREATE TABLE t.practice_rows (practice text, tbl text, id uuid);
INSERT INTO t.practice_rows
SELECT pr.k, x.tbl, x.id FROM (VALUES ('A', t.id('practice_a')), ('B', t.id('practice_b'))) pr(k, pid),
LATERAL (
  SELECT 'practices' tbl, id FROM public.practices WHERE id = pr.pid
  UNION ALL SELECT 'physios', id FROM public.physios WHERE practice_id = pr.pid
  UNION ALL SELECT 'patients', id FROM public.patients WHERE practice_id = pr.pid
  UNION ALL SELECT 'exercises', id FROM public.exercises WHERE practice_id = pr.pid
  UNION ALL SELECT 'plan_templates', id FROM public.plan_templates WHERE practice_id = pr.pid
  UNION ALL SELECT 'injuries', x.id FROM public.injuries x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'invitations', x.id FROM public.invitations x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'plans', x.id FROM public.plans x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'phases', x.id FROM public.phases x JOIN public.plans pl ON pl.id = x.plan_id JOIN public.patients p ON p.id = pl.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'plan_items', x.id FROM public.plan_items x JOIN public.plans pl ON pl.id = x.plan_id JOIN public.patients p ON p.id = pl.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'treaters', x.id FROM public.treaters x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'appointments', x.id FROM public.appointments x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'history_entries', x.id FROM public.history_entries x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'consents', x.id FROM public.consents x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'account_events', x.id FROM public.account_events x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'training_sessions', x.id FROM public.training_sessions x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
  UNION ALL SELECT 'exercise_results', x.id FROM public.exercise_results x JOIN public.patients p ON p.id = x.patient_id WHERE p.practice_id = pr.pid
) x;
GRANT SELECT ON t.practice_rows TO PUBLIC;

-- Vollstaendigkeit: jede Tabelle in public ist eingeordnet (redeem_attempts: ohne Praxisbezug, kein Recht)
SELECT t.is((SELECT string_agg(c.relname, ', ') FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname = 'public' AND c.relkind IN ('r', 'v', 'p')
                AND c.relname NOT IN (SELECT DISTINCT tbl FROM t.practice_rows)
                AND c.relname <> 'redeem_attempts'), NULL, 'jede Tabelle in public ist eingeordnet und hat Testzeilen beider Praxen');
SELECT t.is((SELECT count(DISTINCT tbl) FROM t.practice_rows WHERE practice = 'B'),
            (SELECT count(DISTINCT tbl) FROM t.practice_rows WHERE practice = 'A'), 'beide Praxen haben Zeilen in denselben Tabellen');

DO $$
DECLARE r record; v_me text; v_other text; v_physio text;
BEGIN
  FOR v_physio, v_me, v_other IN VALUES ('phys_a1', 'A', 'B'), ('phys_a2', 'A', 'B'), ('phys_b1', 'B', 'A') LOOP
    PERFORM t.as_user(t.id(v_physio));
    FOR r IN SELECT DISTINCT tbl FROM t.practice_rows ORDER BY 1 LOOP
      PERFORM t.is(t.count(format('SELECT 1 FROM public.%I x WHERE x.id IN (SELECT id FROM t.practice_rows WHERE practice = %L AND tbl = %L)',
                                  r.tbl, v_other, r.tbl)), 0::bigint,
                   format('%s sieht 0 Zeilen der Praxis %s in %s', v_physio, v_other, r.tbl));
    END LOOP;
    -- Gegenprobe: eigene Praxis sichtbar
    PERFORM t.ok(t.count(format('SELECT 1 FROM public.patients x WHERE x.id IN (SELECT id FROM t.practice_rows WHERE practice = %L AND tbl = ''patients'')', v_me)) > 0,
                 format('%s sieht Patienten der eigenen Praxis', v_physio));
  END LOOP;
END $$;
-- Hilfsfunktionen fuer fremde Patienten
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(app.physio_can_see_patient(t.id('pat_b1')), false, 'physio_can_see_patient(fremd) = false');
SELECT t.is(app.current_plan_id(t.id('pat_b1')), NULL::uuid, 'current_plan_id(fremd) = null');
-- Schreiben fuer fremde Praxis
SELECT t.throws(format('INSERT INTO public.treaters (patient_id, role, name) VALUES (%L, ''Arzt'', ''X'')', t.id('pat_b1')), '42501', 'kein INSERT treaters fuer Patient der Praxis B');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.patients SET first_name = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('pat_b1'))), '0', 'kein UPDATE patients der Praxis B');
