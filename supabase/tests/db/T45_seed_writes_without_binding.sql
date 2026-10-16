-- DB-T45 seed_writes_without_binding (Plan 12.2, NEU-2, MINOR-C): service_role schreibt Verlauf
-- (training_sessions, exercise_results) und Termine fuer ungebundene Patienten ohne Patienten-JWT;
-- injury_id wird ueber die interne Variante korrekt gesetzt. (daily_checkups: ab L5.)
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT pl.id AS plan_a2, pl.injury_id AS injury_a2 FROM public.plans pl WHERE pl.patient_id = t.id('pat_a2') \gset
\o /dev/null
SELECT t.as_service();
SELECT t.lives(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode, streak_after) VALUES (%L, %L, %L, %L, ''checklist'', 2)',
               t.id('ts_seed'), t.id('pat_a2'), :'plan_a2', t.today() - 1), 'service_role: Session fuer eingeladenen Patienten');
SELECT t.lives(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (%L, %L, %L, %L, ''done'')',
               t.id('er_seed'), t.id('pat_a2'), t.id('ts_seed'), t.today() - 1), 'service_role: Ergebnis');
SELECT t.lives(format('INSERT INTO public.appointments (id, patient_id, starts_at, title, created_by, created_by_role) VALUES (%L, %L, now(), ''Seed'', %L, ''physio'')',
               t.id('apt_seed'), t.id('pat_a2'), t.id('phys_a1')), 'service_role: Termin mit Physio-Rolle');
SELECT t.as_admin();
SELECT t.is((SELECT injury_id FROM public.training_sessions WHERE id = t.id('ts_seed')), :'injury_a2'::uuid, 'injury_id der Session gesetzt');
SELECT t.is((SELECT injury_id FROM public.exercise_results WHERE id = t.id('er_seed')), :'injury_a2'::uuid, 'injury_id des Ergebnisses gesetzt');
SELECT t.is((SELECT created_by_role FROM public.appointments WHERE id = t.id('apt_seed')), 'physio', 'Seed behaelt die gelieferte Rolle');
SELECT t.is(app.injury_for_patient_day(t.id('pat_a2'), t.today()), :'injury_a2'::uuid, 'interne Herleitung liefert die aktive Verletzung');
SELECT t.ok(NOT has_function_privilege('authenticated', 'app.active_injury_id_internal(uuid)', 'EXECUTE')
            AND NOT has_function_privilege('anon', 'app.active_injury_id_internal(uuid)', 'EXECUTE')
            AND NOT has_function_privilege('authenticated', 'app.injury_for_patient_day(uuid, date)', 'EXECUTE'),
            'interne Varianten nicht fuer API-Rollen ausfuehrbar');
