-- DB-T42 active_patient_writes_and_undoes (Plan 12.2, NEU-1, B-24): aktiver Patient (Rolle
-- authenticated, ohne UPDATE-Recht auf patients) legt Training, Ergebnis und eigenen Termin an,
-- aendert die erlaubten Session-Spalten und loescht Ergebnis (Rueckgaengig), Training und Termin.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT id AS plan_a1, current_phase_id AS phase_a1 FROM public.plans WHERE patient_id = t.id('pat_a1') \gset
\o /dev/null
SELECT t.ok(NOT has_table_privilege('authenticated', 'public.patients', 'UPDATE'), 'authenticated hat kein Tabellen-UPDATE auf patients');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.lives(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, phase_id, plan_version, items, mode, started_at) VALUES (%L, %L, %L, %L, %L, 1, ''[{"plan_item_id":"x"}]'', ''guided'', now()) ON CONFLICT (id) DO NOTHING',
               t.id('ts2'), t.id('pat_a1'), :'plan_a1', t.today(), :'phase_a1'), 'Session (guided) anlegen');
SELECT t.lives(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (%L, %L, %L, %L, ''guided'') ON CONFLICT (id) DO NOTHING',
               t.id('ts2'), t.id('pat_a1'), :'plan_a1', t.today()), 'Wiederholung derselben Geraete-ID: idempotent');
SELECT t.lives(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (%L, %L, %L, %L, ''guided'') ON CONFLICT (id) DO UPDATE SET ended_at = now(), active_seconds = 600, ended_early = false, streak_after = 3',
               t.id('ts2'), t.id('pat_a1'), :'plan_a1', t.today()), 'Upsert setzt Ende-Spalten (training_session_upsert)');
SELECT t.is((SELECT active_seconds FROM public.training_sessions WHERE id = t.id('ts2')), 600, 'Ende-Spalten gesetzt');
SELECT t.lives(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, plan_item_id, exercise_id, exercise_name, status, sets_done, reps_done) VALUES (%L, %L, %L, %L, gen_random_uuid(), %L, ''Kniebeuge'', ''done'', 3, 30)',
               t.id('er2'), t.id('pat_a1'), t.id('ts2'), t.today(), t.id('ex_cat1')), 'Ergebnis (done) anlegen');
SELECT t.lives(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (%L, %L, %L, %L, ''skipped'')',
               t.id('er3'), t.id('pat_a1'), t.id('ts2'), t.today()), 'Ergebnis (skipped) anlegen');
SELECT t.lives(format('INSERT INTO public.appointments (id, patient_id, starts_at, title) VALUES (%L, %L, now() + interval ''1 day'', ''Arzt'')',
               t.id('apt2'), t.id('pat_a1')), 'eigenen Termin anlegen');
SELECT t.is(t.val(format('WITH d AS (DELETE FROM public.exercise_results WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('er2'))), '1', 'Ergebnis loeschen (Rueckgaengig)');
SELECT t.is(t.val(format('WITH d AS (DELETE FROM public.training_sessions WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('ts2'))), '1', 'Session loeschen');
SELECT t.is((SELECT count(*) FROM public.exercise_results WHERE id = t.id('er3')), 0::bigint, 'Ergebnisse der Session per CASCADE weg');
SELECT t.is(t.val(format('WITH d AS (DELETE FROM public.appointments WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('apt2'))), '1', 'Termin loeschen');
SELECT t.is(public.accept_consent('physio_sharing', 'physio_sharing-2'), (SELECT id FROM public.consents WHERE version = 'physio_sharing-2'), 'accept_consent idempotent (gleiche ID)');
SELECT t.is((SELECT count(*) FROM public.consents), 1::bigint, 'keine doppelte Einwilligung');
