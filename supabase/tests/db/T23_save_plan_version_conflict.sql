-- DB-T23 save_plan_version_conflict (Plan 12.2, M-5): alte Version -> conflict, nichts geaendert.
\set ON_ERROR_STOP 1
\o /dev/null
\ir _plan_base.psql
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(public.save_plan(t.id('pat_a2'), 1, t.j(:'base')), 2, 'Version 1 -> 2');
SELECT t.throws(format('SELECT public.save_plan(%L, 1, %L::jsonb)', t.id('pat_a2'), t.j('{"current_phase_id":null,"phases":[],"items":[]}')),
                'P0001', 'erneut mit Version 1 -> conflict', 'conflict');
SELECT t.throws(format('SELECT public.save_plan(%L, 7, %L::jsonb)', t.id('pat_a2'), t.j('{"current_phase_id":null,"phases":[],"items":[]}')),
                'P0001', 'zukuenftige Version -> conflict', 'conflict');
SELECT t.is((SELECT count(*) FROM public.phases WHERE plan_id = app.current_plan_id(t.id('pat_a2'))), 2::bigint, 'Plan unveraendert');
SELECT t.is((SELECT version FROM public.plans WHERE patient_id = t.id('pat_a2')), 2, 'Version unveraendert');
-- set_current_phase erhoeht die Version -> alter Stand des Editors bekommt conflict
SELECT t.is(public.set_current_phase(t.id('pat_a2'), t.id('ph2')), 3, 'set_current_phase -> Version 3');
SELECT t.throws(format('SELECT public.save_plan(%L, 2, %L::jsonb)', t.id('pat_a2'), t.j(:'base')), 'P0001', 'Editor mit Version 2 nach Phasenwechsel -> conflict', 'conflict');
