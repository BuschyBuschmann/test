-- DB-T39 set_current_phase_foreign_phase (Plan 12.2, 6.4): Phase eines anderen Plans -> Fehler;
-- Phase eines abgeschlossenen Plans desselben Patienten -> Fehler; gueltige Phase -> Version + 1.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT (SELECT ph.id FROM public.phases ph JOIN public.plans pl ON pl.id = ph.plan_id WHERE pl.patient_id = t.id('pat_a3') LIMIT 1) AS foreign_phase,
       (SELECT ph.id FROM public.phases ph JOIN public.plans pl ON pl.id = ph.plan_id WHERE pl.patient_id = t.id('pat_a1') ORDER BY ph.position DESC LIMIT 1) AS own_phase,
       (SELECT version FROM public.plans WHERE patient_id = t.id('pat_a1')) AS v0 \gset
\o /dev/null
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT public.set_current_phase(%L, %L)', t.id('pat_a1'), :'foreign_phase'), 'P0001', 'Phase von Claras Plan -> foreign_id', 'foreign_id');
SELECT t.throws(format('SELECT public.set_current_phase(%L, %L)', t.id('pat_a1'), gen_random_uuid()), 'P0001', 'unbekannte Phase -> foreign_id', 'foreign_id');
SELECT t.is(public.set_current_phase(t.id('pat_a1'), :'own_phase'), :v0 + 1, 'eigene Phase -> Version + 1');
SELECT t.is((SELECT current_phase_id FROM public.plans WHERE patient_id = t.id('pat_a1')), :'own_phase'::uuid, 'aktuelle Phase gesetzt');
-- abgeschlossener Plan (Verletzungswechsel per Admin nachgebildet; start_new_injury folgt in L7)
SELECT t.as_admin();
UPDATE public.injuries SET closed_on = t.today() WHERE patient_id = t.id('pat_a1') AND closed_on IS NULL;
UPDATE public.plans SET closed = true WHERE patient_id = t.id('pat_a1');
INSERT INTO public.injuries (id, patient_id, label, reference_date, started_on) VALUES (t.id('inj_new'), t.id('pat_a1'), 'Neu', t.today(), t.today());
INSERT INTO public.plans (id, patient_id, injury_id) VALUES (t.id('plan_new'), t.id('pat_a1'), t.id('inj_new'));
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT public.set_current_phase(%L, %L)', t.id('pat_a1'), :'own_phase'), 'P0001', 'Phase des abgeschlossenen Plans -> foreign_id', 'foreign_id');
SELECT t.is((SELECT current_phase_id FROM public.plans WHERE id = t.id('plan_new')), NULL::uuid, 'neuer Plan unveraendert');
