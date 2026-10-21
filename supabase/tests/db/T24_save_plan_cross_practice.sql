-- DB-T24 save_plan_cross_practice (Plan 12.2): Physio der Praxis B speichert Plan der Praxis A -> 42501
\set ON_ERROR_STOP 1
\o /dev/null
\ir _plan_base.psql
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_b1'));
SELECT t.throws(format('SELECT public.save_plan(%L, 1, %L::jsonb)', t.id('pat_a2'), t.j(:'base')), '42501', 'Physio B speichert Plan von Ben (Praxis A) -> 42501');
SELECT t.throws(format('SELECT public.set_current_phase(%L, %L)', t.id('pat_a1'), gen_random_uuid()), '42501', 'Physio B setzt Phase bei Anna -> 42501');
SELECT t.as_admin();
SELECT t.is((SELECT version FROM public.plans WHERE patient_id = t.id('pat_a2')), 1, 'Plan unveraendert');
