-- DB-T19 exercise_cross_practice (Plan 12.2, 6.6 Nr. 4): Physio nutzt keine Uebung einer fremden
-- Praxis in save_plan; fremde Vorlagen und Vorlagen mit fremden Uebungen in create_patient
-- verweigert; keine Uebungen fuer fremde Praxen anlegen/aendern. (assign_exercise: L8.)
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT version AS v2 FROM public.plans WHERE patient_id = t.id('pat_a2') \gset
\o /dev/null
-- Vorlage der Praxis A mit Uebung der Praxis B (nur per Admin moeglich)
INSERT INTO public.plan_templates (id, practice_id, name, injury_label, payload) VALUES
  (t.id('tpl_bad'), t.id('practice_a'), 'kaputt', 'X', jsonb_build_object('phases', jsonb_build_array(
     jsonb_build_object('title', 'P', 'planned_weeks', 1, 'items', jsonb_build_array(
       jsonb_build_object('exercise_id', t.id('ex_b1'), 'sets', 1))))));
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT public.save_plan(%L, %s, %L::jsonb)', t.id('pat_a2'), :v2,
  jsonb_build_object('current_phase_id', t.id('ph1'),
    'phases', jsonb_build_array(jsonb_build_object('id', t.id('ph1'), 'position', 0, 'title', 'P', 'planned_weeks', 1)),
    'items', jsonb_build_array(jsonb_build_object('id', t.id('it1'), 'phase_id', t.id('ph1'), 'exercise_id', t.id('ex_b1'), 'position', 0)))),
  'P0001', 'save_plan mit Uebung der Praxis B -> foreign_id', 'foreign_id');
SELECT t.lives(format('SELECT public.save_plan(%L, %s, %L::jsonb)', t.id('pat_a2'), :v2,
  jsonb_build_object('current_phase_id', t.id('ph1'),
    'phases', jsonb_build_array(jsonb_build_object('id', t.id('ph1'), 'position', 0, 'title', 'P', 'planned_weeks', 1)),
    'items', jsonb_build_array(jsonb_build_object('id', t.id('it1'), 'phase_id', t.id('ph1'), 'exercise_id', t.id('ex_a1'), 'position', 0),
                               jsonb_build_object('id', t.id('it2'), 'phase_id', t.id('ph1'), 'exercise_id', t.id('ex_cat1'), 'position', 1)))),
  'save_plan mit Uebung der eigenen Praxis und Katalog -> ok');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''X'', NULL, %L, %L)', gen_random_uuid(), t.id('tpl_b'), t.today()),
                '42501', 'create_patient mit Vorlage der Praxis B -> 42501');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''X'', NULL, %L, %L)', t.id('pat_bad'), t.id('tpl_bad'), t.today()),
                'P0001', 'create_patient mit Vorlage, die fremde Uebung enthaelt -> foreign_id', 'foreign_id');
SELECT t.is(t.count(format('SELECT 1 FROM public.patients WHERE id = %L', t.id('pat_bad'))), 0::bigint, 'dabei kein Patient angelegt');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description) VALUES (%L, ''X'', ''Y'')', t.id('practice_b')), '42501', 'Uebung fuer Praxis B anlegen verweigert');
SELECT t.throws('INSERT INTO public.exercises (practice_id, name, description) VALUES (NULL, ''X'', ''Y'')', '42501', 'Katalog-Uebung anlegen verweigert');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.exercises SET name = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('ex_b1'))), '0', 'Uebung der Praxis B aendern: 0 Zeilen');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.exercises SET name = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('ex_cat1'))), '0', 'Katalog-Uebung aendern: 0 Zeilen');
SELECT t.throws(format('UPDATE public.exercises SET practice_id = %L WHERE id = %L', t.id('practice_b'), t.id('ex_a1')), '42501', 'practice_id einer Uebung aendern verweigert');
SELECT t.throws(format('INSERT INTO public.plan_templates (practice_id, name) VALUES (%L, ''X'')', t.id('practice_b')), '42501', 'Vorlage fuer Praxis B anlegen verweigert');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM public.plan_items pi JOIN public.plans pl ON pl.id = pi.plan_id WHERE pl.patient_id = t.id('pat_a2')), 2::bigint, 'nur der gueltige Plan wurde gespeichert');
