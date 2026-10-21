-- DB-T32 auth_user_delete_set_null (Plan 12.2, m-6): Loeschen in auth.users setzt
-- patients.auth_user_id = NULL (Patientenzeile bleibt); Physio-Zeile wird mitgeloescht (CASCADE).
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
DELETE FROM auth.users WHERE id = t.id('anon_a1');
SELECT t.is((SELECT auth_user_id FROM public.patients WHERE id = t.id('pat_a1')), NULL::uuid, 'auth_user_id -> NULL');
SELECT t.is((SELECT count(*) FROM public.patients WHERE id = t.id('pat_a1')), 1::bigint, 'Patientenzeile bleibt');
SELECT t.is((SELECT count(*) FROM public.training_sessions WHERE patient_id = t.id('pat_a1')), 1::bigint, 'Verlauf bleibt');
DELETE FROM auth.users WHERE id = t.id('phys_a2');
SELECT t.is((SELECT count(*) FROM public.physios WHERE id = t.id('phys_a2')), 0::bigint, 'Physio-Zeile per CASCADE geloescht');
SELECT t.is((SELECT main_physio_id FROM public.patients WHERE id = t.id('pat_a2')), NULL::uuid, 'Hauptphysio -> NULL (ON DELETE SET NULL)');
SELECT t.is((SELECT count(*) FROM public.patients WHERE id = t.id('pat_a2')), 1::bigint, 'Patient des geloeschten Physios bleibt');
