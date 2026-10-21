-- DB-T07 physio_sees_all_practice_patients (Plan 12.2, N-4): jeder Physio sieht alle Patienten
-- seiner Praxis, unabhaengig vom Hauptphysio (auch von Kollegen angelegte).
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.is((SELECT main_physio_id FROM public.patients WHERE id = t.id('pat_a1')), t.id('phys_a1'), 'Hauptphysio von Anna = Anleger A1');
SELECT t.as_user(t.id('phys_a2'));
SELECT t.is((SELECT count(*) FROM public.patients), 3::bigint, 'Physio A2 sieht alle 3 Patienten der Praxis A');
SELECT t.ok(EXISTS (SELECT 1 FROM public.patients WHERE id = t.id('pat_a1')), 'A2 sieht von A1 angelegte Anna');
SELECT t.ok(EXISTS (SELECT 1 FROM public.plans WHERE patient_id = t.id('pat_a1')), 'A2 sieht Annas Plan');
SELECT t.ok(EXISTS (SELECT 1 FROM public.training_sessions WHERE patient_id = t.id('pat_a1')), 'A2 sieht Annas Training');
SELECT t.ok(EXISTS (SELECT 1 FROM public.invitations WHERE patient_id = t.id('pat_a3')), 'A2 sieht Einladungen von Claras Konto (ohne Hash)');
SELECT t.is(app.physio_can_see_patient(t.id('pat_a3')), true, 'physio_can_see_patient fuer Kollegen-Patient = true');
SELECT t.as_user(t.id('phys_a1'));
SELECT t.ok(EXISTS (SELECT 1 FROM public.patients WHERE id = t.id('pat_a2')), 'A1 sieht von A2 angelegten Ben');
