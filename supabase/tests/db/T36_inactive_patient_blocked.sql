-- DB-T36 inactive_patient_blocked (Plan 12.2): Patient mit Status deleting bzw. access_deleted
-- kann nicht schreiben (alle Patienten-Tabellen und RPCs der Lieferung 2) und sieht nichts.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT id AS plan_a1 FROM public.plans WHERE patient_id = t.id('pat_a1') \gset
\o /dev/null
-- Status deleting bei bestehender Bindung (Ausschnitt 3: lange Loeschung)
UPDATE public.patients SET status = 'deleting' WHERE id = t.id('pat_a1');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.throws(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (gen_random_uuid(), %L, %L, current_date, ''checklist'')', t.id('pat_a1'), :'plan_a1'), '42501', 'deleting: INSERT training_sessions -> 42501');
SELECT t.throws(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (gen_random_uuid(), %L, %L, current_date, ''done'')', t.id('pat_a1'), t.id('ts_pat_a1')), '42501', 'deleting: INSERT exercise_results -> 42501');
SELECT t.throws(format('INSERT INTO public.appointments (patient_id, starts_at, title) VALUES (%L, now(), ''x'')', t.id('pat_a1')), '42501', 'deleting: INSERT appointments -> 42501');
SELECT t.throws('SELECT public.accept_consent(''physio_sharing'', ''physio_sharing-3'')', '42501', 'deleting: accept_consent -> 42501');
SELECT t.throws('SELECT public.set_manny_look(''ohne'')', '42501', 'deleting: set_manny_look -> 42501');
SELECT t.throws('SELECT public.get_my_manny_look()', '42501', 'deleting: get_my_manny_look -> 42501');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.training_sessions SET ended_at = now() WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('ts_pat_a1'))), '0', 'deleting: UPDATE training_sessions 0 Zeilen');
SELECT t.ok(t.sees_nothing('SELECT 1 FROM public.training_sessions'), 'deleting: sieht kein Training');
-- Schreibsperre direkt: Trigger verweigert auch Schreibvorgaenge, die RLS passieren wuerden
SELECT t.as_admin();
UPDATE public.patients SET status = 'active' WHERE id = t.id('pat_a1');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.lives(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (%L, %L, %L, current_date, ''checklist'')', t.id('ts_new'), t.id('pat_a1'), :'plan_a1'), 'active: INSERT moeglich');
-- access_deleted nach delete_my_data: alte Sitzung ohne Bindung
SELECT t.is(public.delete_my_data(), 'ok', 'Loeschen');
SELECT t.throws(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (gen_random_uuid(), %L, %L, current_date, ''checklist'')', t.id('pat_a1'), :'plan_a1'), '42501', 'access_deleted: INSERT training_sessions -> 42501');
SELECT t.throws('SELECT public.set_manny_look(''ohne'')', '42501', 'access_deleted: set_manny_look -> 42501');
-- Schreibsperre ist an der Tabelle aktiv (Katalog, Pflichtliste 6.14; vollstaendig in DB-T70)
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM pg_trigger WHERE tgname = 't10_lock_patient_for_write' AND tgrelid = 'public.training_sessions'::regclass), 1::bigint, 'Schreibsperre an training_sessions');
