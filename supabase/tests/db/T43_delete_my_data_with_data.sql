-- DB-T43 delete_my_data_with_data (Plan 12.2, NEU-1): delete_my_data mit Daten aller Patienten-
-- Tabellen der Lieferung 2 (mehrere Sessions, Ergebnisse, Termine, Einwilligungen, Ereignisse) laeuft
-- ohne Fehler durch (Schreibsperre in derselben Transaktion); danach Zustand wie DB-T29.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT id AS plan_a1 FROM public.plans WHERE patient_id = t.id('pat_a1') \gset
\o /dev/null
SELECT t.as_user(t.id('anon_a1'), true);
INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode)
  SELECT t.id('ts_m' || i), t.id('pat_a1'), :'plan_a1', t.today() - i, 'guided' FROM generate_series(1, 5) i;
INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status)
  SELECT t.id('er_m' || i || j), t.id('pat_a1'), t.id('ts_m' || i), t.today() - i, 'done' FROM generate_series(1, 5) i, generate_series(1, 3) j;
INSERT INTO public.appointments (patient_id, starts_at, title) SELECT t.id('pat_a1'), now() + i * interval '1 day', 'T' || i FROM generate_series(1, 3) i;
SELECT public.accept_consent('physio_sharing', 'physio_sharing-1');
SELECT t.as_admin();
SELECT t.ok((SELECT count(*) FROM public.exercise_results WHERE patient_id = t.id('pat_a1')) = 16, 'vorher 16 Ergebnisse');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(public.delete_my_data(), 'ok', 'delete_my_data mit vielen Daten -> ok');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM public.training_sessions WHERE patient_id = t.id('pat_a1'))
          + (SELECT count(*) FROM public.exercise_results WHERE patient_id = t.id('pat_a1'))
          + (SELECT count(*) FROM public.appointments WHERE patient_id = t.id('pat_a1') AND created_by_role = 'patient')
          + (SELECT count(*) FROM public.consents WHERE patient_id = t.id('pat_a1'))
          + (SELECT count(*) FROM public.account_events WHERE patient_id = t.id('pat_a1')), 0::bigint, 'alle Patientendaten geloescht');
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a1')), 'access_deleted', 'Status access_deleted');
SELECT t.is((SELECT count(*) FROM public.appointments WHERE patient_id = t.id('pat_a1')), 1::bigint, 'Physio-Termin bleibt');
