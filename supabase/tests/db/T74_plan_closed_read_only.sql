-- DB-T74 plan_closed_read_only (Plan 12.2, 6.7): abgeschlossener Plan: Patient liest ihn, niemand
-- schreibt ueber save_plan/set_current_phase (assign_exercise: L8). Verletzungswechsel per Admin
-- nachgebildet (start_new_injury: L7).
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT pl.id AS plan_old, pl.version AS v_old, pl.current_phase_id AS phase_old FROM public.plans pl WHERE pl.patient_id = t.id('pat_a1') \gset
\o /dev/null
UPDATE public.injuries SET closed_on = t.today() WHERE patient_id = t.id('pat_a1');
UPDATE public.plans SET closed = true WHERE id = :'plan_old';
-- ohne aktive Verletzung: kein Plan zum Speichern
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT public.save_plan(%L, %s, ''{"phases":[],"items":[]}'')', t.id('pat_a1'), :v_old), 'P0001', 'ohne aktiven Plan -> plan_closed', 'plan_closed');
SELECT t.throws(format('SELECT public.set_current_phase(%L, %L)', t.id('pat_a1'), :'phase_old'), 'P0001', 'set_current_phase ohne aktiven Plan -> plan_closed', 'plan_closed');
SELECT t.as_admin();
INSERT INTO public.injuries (id, patient_id, label, reference_date, started_on) VALUES (t.id('inj_new'), t.id('pat_a1'), 'Neu', t.today(), t.today());
INSERT INTO public.plans (id, patient_id, injury_id) VALUES (t.id('plan_new'), t.id('pat_a1'), t.id('inj_new'));
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT public.save_plan(%L, %s, %L::jsonb)', t.id('pat_a1'), :v_old, jsonb_build_object('plan_id', :'plan_old'::uuid, 'phases', '[]'::jsonb, 'items', '[]'::jsonb)),
                'P0001', 'save_plan auf den alten Plan -> plan_closed', 'plan_closed');
SELECT t.throws(format('SELECT public.set_current_phase(%L, %L)', t.id('pat_a1'), :'phase_old'), 'P0001', 'Phase des alten Plans setzen -> foreign_id', 'foreign_id');
SELECT t.is(public.save_plan(t.id('pat_a1'), 1, '{"phases":[],"items":[]}'::jsonb), 2, 'save_plan ohne plan_id arbeitet auf dem neuen Plan');
SELECT t.as_admin();
SELECT t.is((SELECT version FROM public.plans WHERE id = :'plan_old'), :v_old, 'alter Plan unveraendert');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(t.count(format('SELECT 1 FROM public.plans WHERE id = %L AND closed', :'plan_old')), 1::bigint, 'Patient liest den abgeschlossenen Plan');
SELECT t.ok(t.count(format('SELECT 1 FROM public.phases WHERE plan_id = %L', :'plan_old')) > 0, 'Patient liest dessen Phasen');
SELECT t.ok(t.count(format('SELECT 1 FROM public.plan_items WHERE plan_id = %L', :'plan_old')) > 0, 'Patient liest dessen Positionen');
SELECT t.is(app.current_plan_id(t.id('pat_a1')), t.id('plan_new'), 'aktueller Plan ist der neue');
