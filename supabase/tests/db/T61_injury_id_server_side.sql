-- DB-T61 injury_id_server_side (Plan 12.2, 6.3, MINOR-4, MINOR-D): Client-Wert fuer injury_id wird
-- immer ueberschrieben; training_sessions aus plan_id (fremder Plan -> 42501); Session des alten
-- Tags mit altem plan_id nach Verletzungswechsel -> alte Verletzung; exercise_results = Verletzung
-- ihrer Session; Session eines anderen Patienten -> 42501, nichts geschrieben.
-- (session_checkups ab L4, daily_checkups/patient_questions ab L5; Verletzungswechsel per Admin
-- nachgebildet, start_new_injury folgt in L7.)
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT pl.id AS plan_old, pl.injury_id AS injury_old FROM public.plans pl WHERE pl.patient_id = t.id('pat_a1') \gset
SELECT pl.id AS plan_a3, pl.injury_id AS injury_a3 FROM public.plans pl WHERE pl.patient_id = t.id('pat_a3') \gset
\o /dev/null
SELECT t.as_user(t.id('anon_a1'), true);
-- gefaelschte injury_id (von Clara) wird ueberschrieben
INSERT INTO public.training_sessions (id, patient_id, injury_id, plan_id, local_day, mode)
VALUES (t.id('ts_f'), t.id('pat_a1'), :'injury_a3', :'plan_old', t.today(), 'checklist');
INSERT INTO public.exercise_results (id, patient_id, injury_id, training_session_id, local_day, status)
VALUES (t.id('er_f'), t.id('pat_a1'), :'injury_a3', t.id('ts_f'), t.today(), 'done');
SELECT t.is((SELECT injury_id FROM public.training_sessions WHERE id = t.id('ts_f')), :'injury_old'::uuid, 'Session: injury_id aus plan_id, Client-Wert ueberschrieben');
SELECT t.is((SELECT injury_id FROM public.exercise_results WHERE id = t.id('er_f')), :'injury_old'::uuid, 'Ergebnis: injury_id der Session, Client-Wert ueberschrieben');
-- fremder Plan
SELECT t.throws(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (gen_random_uuid(), %L, %L, current_date, ''checklist'')',
                t.id('pat_a1'), :'plan_a3'), '42501', 'fremder plan_id -> 42501');
SELECT t.throws(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (gen_random_uuid(), %L, gen_random_uuid(), current_date, ''checklist'')',
                t.id('pat_a1')), '42501', 'unbekannter plan_id -> 42501');
-- Session einer anderen Patientin (MINOR-D)
SELECT t.throws(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (%L, %L, %L, current_date, ''done'')',
                t.id('er_minor_d'), t.id('pat_a1'), t.id('ts_pat_a3')), '42501', 'exercise_results mit Session einer anderen Patientin -> 42501');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM public.exercise_results WHERE id = t.id('er_minor_d')), 0::bigint, 'nichts geschrieben');
-- Verletzungswechsel (Nachbildung start_new_injury)
UPDATE public.injuries SET closed_on = t.today() WHERE id = :'injury_old';
UPDATE public.plans SET closed = true WHERE id = :'plan_old';
INSERT INTO public.injuries (id, patient_id, label, reference_date, started_on) VALUES (t.id('inj_new'), t.id('pat_a1'), 'Neu', t.today(), t.today());
INSERT INTO public.plans (id, patient_id, injury_id) VALUES (t.id('plan_new'), t.id('pat_a1'), t.id('inj_new'));
SELECT t.as_user(t.id('anon_a1'), true);
-- offline gespeicherte Session des alten Tags mit altem plan_id, nach dem Wechsel gesendet
INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode)
VALUES (t.id('ts_offline'), t.id('pat_a1'), :'plan_old', t.today() - 1, 'guided');
INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status)
VALUES (t.id('er_offline'), t.id('pat_a1'), t.id('ts_offline'), t.today() - 1, 'done');
SELECT t.is((SELECT injury_id FROM public.training_sessions WHERE id = t.id('ts_offline')), :'injury_old'::uuid, 'alte Session nach dem Wechsel -> alte Verletzung');
SELECT t.is((SELECT injury_id FROM public.exercise_results WHERE id = t.id('er_offline')), :'injury_old'::uuid, 'Ergebnis der alten Session -> alte Verletzung');
INSERT INTO public.training_sessions (id, patient_id, injury_id, plan_id, local_day, mode)
VALUES (t.id('ts_new'), t.id('pat_a1'), :'injury_old', t.id('plan_new'), t.today(), 'guided');
SELECT t.is((SELECT injury_id FROM public.training_sessions WHERE id = t.id('ts_new')), t.id('inj_new'), 'neue Session mit neuem Plan -> neue Verletzung');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM pg_trigger WHERE tgname = 't20_set_injury_id'
              AND tgrelid IN ('public.training_sessions'::regclass, 'public.exercise_results'::regclass)), 2::bigint,
            'Trigger t20_set_injury_id an allen Tabellen mit injury_id (L2)');
SELECT t.is((SELECT string_agg(c.relname, ', ') FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname = 'public' AND a.attname = 'injury_id' AND c.relkind = 'r' AND c.relname NOT IN ('plans')
                AND NOT EXISTS (SELECT 1 FROM pg_trigger tg WHERE tg.tgrelid = c.oid AND tg.tgname = 't20_set_injury_id')), NULL,
            'Pflichtliste 6.14: jede Patienten-Tabelle mit injury_id hat den Trigger (plans: per RPC)');
