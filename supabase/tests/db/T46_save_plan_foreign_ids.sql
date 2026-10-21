-- DB-T46 save_plan_foreign_ids (Plan 12.2, NEU-5): Payload mit Phasen- bzw. Positions-ID eines
-- anderen Plans -> foreign_id, nichts geaendert.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT (SELECT ph.id FROM public.phases ph JOIN public.plans pl ON pl.id = ph.plan_id WHERE pl.patient_id = t.id('pat_a1') ORDER BY ph.position LIMIT 1) AS foreign_phase,
       (SELECT pi.id FROM public.plan_items pi JOIN public.plans pl ON pl.id = pi.plan_id WHERE pl.patient_id = t.id('pat_a1') ORDER BY pi.position LIMIT 1) AS foreign_item \gset
\o /dev/null
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT public.save_plan(%L, 1, %L::jsonb)', t.id('pat_a2'),
  jsonb_build_object('current_phase_id', :'foreign_phase'::uuid,
    'phases', jsonb_build_array(jsonb_build_object('id', :'foreign_phase'::uuid, 'position', 0, 'title', 'geklaut', 'planned_weeks', 1)),
    'items', '[]'::jsonb)), 'P0001', 'Phasen-ID aus Annas Plan -> foreign_id', 'foreign_id');
SELECT t.throws(format('SELECT public.save_plan(%L, 1, %L::jsonb)', t.id('pat_a2'),
  jsonb_build_object('current_phase_id', t.id('phn'),
    'phases', jsonb_build_array(jsonb_build_object('id', t.id('phn'), 'position', 0, 'title', 'neu', 'planned_weeks', 1)),
    'items', jsonb_build_array(jsonb_build_object('id', :'foreign_item'::uuid, 'phase_id', t.id('phn'), 'exercise_id', t.id('ex_cat1'), 'position', 0)))),
  'P0001', 'Positions-ID aus Annas Plan -> foreign_id', 'foreign_id');
SELECT t.throws(format('SELECT public.save_plan(%L, 1, %L::jsonb)', t.id('pat_a2'),
  jsonb_build_object('current_phase_id', t.id('phn'),
    'phases', jsonb_build_array(jsonb_build_object('id', t.id('phn'), 'position', 0, 'title', 'neu', 'planned_weeks', 1)),
    'items', jsonb_build_array(jsonb_build_object('id', t.id('itn'), 'phase_id', :'foreign_phase'::uuid, 'exercise_id', t.id('ex_cat1'), 'position', 0)))),
  'P0001', 'Position in Phase eines anderen Plans -> foreign_id', 'foreign_id');
SELECT t.throws(format('SELECT public.save_plan(%L, 1, %L::jsonb)', t.id('pat_a2'),
  jsonb_build_object('plan_id', (SELECT id FROM public.plans WHERE patient_id = t.id('pat_a1')), 'current_phase_id', NULL, 'phases', '[]'::jsonb, 'items', '[]'::jsonb)),
  'P0001', 'plan_id eines anderen Patienten im Payload -> foreign_id', 'foreign_id');
SELECT t.as_admin();
SELECT t.is((SELECT version FROM public.plans WHERE patient_id = t.id('pat_a2')), 1, 'Bens Plan unveraendert');
SELECT t.is((SELECT title FROM public.phases WHERE id = :'foreign_phase'::uuid), 'Phase 1', 'Annas Phase unveraendert');
SELECT t.is((SELECT plan_id FROM public.plan_items WHERE id = :'foreign_item'::uuid), (SELECT id FROM public.plans WHERE patient_id = t.id('pat_a1')), 'Annas Position unveraendert');
