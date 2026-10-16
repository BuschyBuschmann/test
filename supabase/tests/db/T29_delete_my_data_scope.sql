-- DB-T29 delete_my_data_scope (Plan 12.2, 6.13, O-9): loescht die Patientendaten (training_sessions,
-- exercise_results, eigene appointments, consents, account_events; manny_look = null); Physio-Eintraege
-- bleiben; status = access_deleted, auth_user_id = NULL, offene Einladungen widerrufen, Auth-Konto weg.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
-- offene Einladung (neuer Code fuer Anna) und Daten der Kontrollpatientin Clara
SELECT t.as_user(t.id('phys_a1'));
SELECT * FROM public.regenerate_invitation(t.id('pat_a1'));
SELECT t.as_admin();
CREATE TEMP TABLE other_before AS
  SELECT 'ts' k, count(*) n FROM public.training_sessions WHERE patient_id = t.id('pat_a3')
  UNION ALL SELECT 'er', count(*) FROM public.exercise_results WHERE patient_id = t.id('pat_a3')
  UNION ALL SELECT 'apt', count(*) FROM public.appointments WHERE patient_id = t.id('pat_a3')
  UNION ALL SELECT 'c', count(*) FROM public.consents WHERE patient_id = t.id('pat_a3');

SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(public.delete_my_data(), 'ok', 'delete_my_data -> ok');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM public.training_sessions WHERE patient_id = t.id('pat_a1')), 0::bigint, 'training_sessions geloescht');
SELECT t.is((SELECT count(*) FROM public.exercise_results WHERE patient_id = t.id('pat_a1')), 0::bigint, 'exercise_results geloescht');
SELECT t.is((SELECT count(*) FROM public.appointments WHERE patient_id = t.id('pat_a1') AND created_by_role = 'patient'), 0::bigint, 'eigene Termine geloescht');
SELECT t.is((SELECT count(*) FROM public.consents WHERE patient_id = t.id('pat_a1')), 0::bigint, 'consents geloescht');
SELECT t.is((SELECT count(*) FROM public.account_events WHERE patient_id = t.id('pat_a1')), 0::bigint, 'account_events geloescht');
SELECT t.is((SELECT manny_look FROM public.patients WHERE id = t.id('pat_a1')), NULL::text, 'manny_look = null');
-- bleibt bei der Praxis
SELECT t.is((SELECT count(*) FROM public.patients WHERE id = t.id('pat_a1')), 1::bigint, 'Patientenzeile bleibt');
SELECT t.is((SELECT first_name FROM public.patients WHERE id = t.id('pat_a1')), 'Anna', 'Stammdaten bleiben');
SELECT t.is((SELECT count(*) FROM public.injuries WHERE patient_id = t.id('pat_a1')), 1::bigint, 'Verletzung bleibt');
SELECT t.is((SELECT count(*) FROM public.plans WHERE patient_id = t.id('pat_a1')), 1::bigint, 'Plan bleibt');
SELECT t.ok((SELECT count(*) FROM public.phases ph JOIN public.plans pl ON pl.id = ph.plan_id WHERE pl.patient_id = t.id('pat_a1')) > 0, 'Phasen bleiben');
SELECT t.is((SELECT count(*) FROM public.treaters WHERE patient_id = t.id('pat_a1')), 1::bigint, 'Behandler bleiben');
SELECT t.is((SELECT count(*) FROM public.history_entries WHERE patient_id = t.id('pat_a1')), 1::bigint, 'Krankengeschichte bleibt');
SELECT t.is((SELECT count(*) FROM public.appointments WHERE patient_id = t.id('pat_a1') AND created_by_role = 'physio'), 1::bigint, 'Physio-Termine bleiben');
-- Status und Bindung
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a1')), 'access_deleted', 'status = access_deleted');
SELECT t.is((SELECT auth_user_id FROM public.patients WHERE id = t.id('pat_a1')), NULL::uuid, 'auth_user_id = NULL');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_a1') AND redeemed_at IS NULL AND revoked_at IS NULL), 0::bigint, 'offene Einladungen widerrufen');
SELECT t.is((SELECT count(*) FROM auth.users WHERE id = t.id('anon_a1')), 0::bigint, 'Auth-Konto des Aufrufers geloescht (B-7)');
-- Kontrollpatientin unveraendert
SELECT t.is((SELECT count(*) FROM (
  SELECT 'ts' k, count(*) n FROM public.training_sessions WHERE patient_id = t.id('pat_a3')
  UNION ALL SELECT 'er', count(*) FROM public.exercise_results WHERE patient_id = t.id('pat_a3')
  UNION ALL SELECT 'apt', count(*) FROM public.appointments WHERE patient_id = t.id('pat_a3')
  UNION ALL SELECT 'c', count(*) FROM public.consents WHERE patient_id = t.id('pat_a3')
  EXCEPT SELECT * FROM other_before) x), 0::bigint, 'Daten anderer Patienten unveraendert');
SELECT t.is((SELECT manny_look FROM public.patients WHERE id = t.id('pat_a3')), 'brille', 'manny_look anderer Patienten unveraendert');
-- Physio sieht den Patienten weiter, alte Identitaet nichts mehr
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a1')), 'access_deleted', 'Physio sieht Status access_deleted');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.ok(t.sees_nothing('SELECT 1 FROM public.patients'), 'alte Sitzung sieht nichts mehr');
