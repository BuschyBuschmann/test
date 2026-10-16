-- DB-T15 patient_cannot_modify_physio_entries (Plan 12.2, A-4): Patient aendert keine Behandler,
-- Krankengeschichte, Physio-Termine, Plaene, Phasen, Positionen, Verletzungen, Uebungen, Vorlagen
-- und keine Stammdaten. (Notizen: L7.)
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT id AS plan_a1, current_phase_id AS phase_a1 FROM public.plans WHERE patient_id = t.id('pat_a1') \gset
\o /dev/null
SELECT t.as_user(t.id('anon_a1'), true);
-- UPDATE/DELETE wirken nicht (0 Zeilen) bzw. kein Recht
SELECT t.is(t.val(format('WITH u AS (UPDATE public.treaters SET name = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('tr_pat_a1'))), '0', 'treaters UPDATE: 0 Zeilen');
SELECT t.is(t.val(format('WITH u AS (DELETE FROM public.treaters WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('tr_pat_a1'))), '0', 'treaters DELETE: 0 Zeilen');
SELECT t.throws(format('INSERT INTO public.treaters (patient_id, role, name) VALUES (%L, ''Arzt'', ''X'')', t.id('pat_a1')), '42501', 'treaters INSERT verweigert');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.history_entries SET title = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('he_pat_a1'))), '0', 'history_entries UPDATE: 0 Zeilen');
SELECT t.is(t.val(format('WITH u AS (DELETE FROM public.history_entries WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('he_pat_a1'))), '0', 'history_entries DELETE: 0 Zeilen');
SELECT t.throws(format('INSERT INTO public.history_entries (patient_id, kind, title) VALUES (%L, ''op'', ''X'')', t.id('pat_a1')), '42501', 'history_entries INSERT verweigert');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.appointments SET title = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_phys_pat_a1'))), '0', 'Physio-Termin UPDATE: 0 Zeilen');
SELECT t.is(t.val(format('WITH u AS (DELETE FROM public.appointments WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_phys_pat_a1'))), '0', 'Physio-Termin DELETE: 0 Zeilen');
SELECT t.throws(format('UPDATE public.plans SET version = 99 WHERE id = %L', :'plan_a1'), '42501', 'plans UPDATE verweigert');
SELECT t.throws(format('DELETE FROM public.plans WHERE id = %L', :'plan_a1'), '42501', 'plans DELETE verweigert');
SELECT t.throws(format('UPDATE public.phases SET title = ''X'' WHERE plan_id = %L', :'plan_a1'), '42501', 'phases UPDATE verweigert');
SELECT t.throws(format('INSERT INTO public.phases (id, plan_id, position, title, planned_weeks) VALUES (gen_random_uuid(), %L, 9, ''X'', 1)', :'plan_a1'), '42501', 'phases INSERT verweigert');
SELECT t.throws(format('DELETE FROM public.plan_items WHERE plan_id = %L', :'plan_a1'), '42501', 'plan_items DELETE verweigert');
SELECT t.throws(format('UPDATE public.plan_items SET sets = 9 WHERE plan_id = %L', :'plan_a1'), '42501', 'plan_items UPDATE verweigert');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.injuries SET label = ''X'' WHERE patient_id = %L RETURNING 1) SELECT count(*) FROM u', t.id('pat_a1'))), '0', 'injuries UPDATE: 0 Zeilen');
SELECT t.throws(format('INSERT INTO public.injuries (patient_id, label, reference_date, started_on) VALUES (%L, ''X'', current_date, current_date)', t.id('pat_a1')), '42501', 'injuries INSERT verweigert');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.exercises SET name = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('ex_cat1'))), '0', 'exercises UPDATE: 0 Zeilen');
SELECT t.is(t.val(format('WITH u AS (DELETE FROM public.exercises WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('ex_cat1'))), '0', 'exercises DELETE: 0 Zeilen');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description) VALUES (%L, ''X'', ''Y'')', t.id('practice_a')), '42501', 'exercises INSERT verweigert');
SELECT t.throws(format('INSERT INTO public.plan_templates (practice_id, name) VALUES (%L, ''X'')', t.id('practice_a')), '42501', 'plan_templates INSERT verweigert');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.patients SET first_name = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('pat_a1'))), '0', 'eigene Stammdaten UPDATE: 0 Zeilen');
SELECT t.throws(format('UPDATE public.patients SET status = ''invited'' WHERE id = %L', t.id('pat_a1')), '42501', 'patients.status UPDATE verweigert');
SELECT t.throws(format('SELECT public.save_plan(%L, 1, ''{"phases":[],"items":[]}'')', t.id('pat_a1')), '42501', 'save_plan als Patient -> 42501');
SELECT t.throws(format('SELECT public.set_current_phase(%L, %L)', t.id('pat_a1'), :'phase_a1'), '42501', 'set_current_phase als Patient -> 42501');
SELECT t.as_admin();
SELECT t.is((SELECT name FROM public.treaters WHERE id = t.id('tr_pat_a1')), 'Dr. Test', 'Behandler unveraendert');
SELECT t.is((SELECT title FROM public.appointments WHERE id = t.id('apt_phys_pat_a1')), 'Physio-Termin', 'Physio-Termin unveraendert');
SELECT t.is((SELECT label FROM public.injuries WHERE patient_id = t.id('pat_a1')), 'Knie', 'Verletzung unveraendert');
