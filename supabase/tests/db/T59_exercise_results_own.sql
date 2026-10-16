-- DB-T59 exercise_results_own (Plan 12.2, 6.2): Patient legt nur eigene Ergebnisse an und loescht
-- nur eigene; Physio liest, schreibt aber nicht.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.lives(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (%L, %L, %L, current_date, ''done'')',
               t.id('er_x'), t.id('pat_a1'), t.id('ts_pat_a1')), 'eigenes Ergebnis anlegen');
SELECT t.throws(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (gen_random_uuid(), %L, %L, current_date, ''done'')',
                t.id('pat_a3'), t.id('ts_pat_a3')), '42501', 'Ergebnis fuer andere Patientin (deren Session) -> 42501');
SELECT t.throws(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (gen_random_uuid(), %L, %L, current_date, ''unknown'')',
                t.id('pat_a1'), t.id('ts_pat_a1')), '23514', 'unbekannter Status -> 23514');
SELECT t.is(t.val(format('WITH d AS (DELETE FROM public.exercise_results WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('er_pat_a3'))), '0', 'fremdes Ergebnis loeschen: 0 Zeilen');
SELECT t.throws(format('UPDATE public.exercise_results SET status = ''skipped'' WHERE id = %L', t.id('er_x')), '42501', 'Ergebnis aendern verweigert (kein UPDATE)');
SELECT t.is(t.val(format('WITH d AS (DELETE FROM public.exercise_results WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('er_x'))), '1', 'eigenes Ergebnis loeschen');
SELECT t.as_user(t.id('phys_a2'));
SELECT t.is((SELECT count(*) FROM public.exercise_results WHERE patient_id = t.id('pat_a1')), 1::bigint, 'Physio der Praxis liest Ergebnisse');
SELECT t.throws(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (gen_random_uuid(), %L, %L, current_date, ''done'')',
                t.id('pat_a1'), t.id('ts_pat_a1')), '42501', 'Physio legt keine Ergebnisse an');
SELECT t.is(t.val(format('WITH d AS (DELETE FROM public.exercise_results WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('er_pat_a1'))), '0', 'Physio loescht keine Ergebnisse');
SELECT t.throws(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) SELECT gen_random_uuid(), %L, id, current_date, ''checklist'' FROM public.plans WHERE patient_id = %L',
                t.id('pat_a1'), t.id('pat_a1')), '42501', 'Physio legt keine Sessions an');
