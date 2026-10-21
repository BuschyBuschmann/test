-- DB-T17 own_appointments_only (Plan 12.2): Patient aendert/loescht nur eigene Termine, Physio nur
-- selbst angelegte. Termine bleiben fuer beide lesbar.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(t.val(format('WITH u AS (UPDATE public.appointments SET title = ''geaendert'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_pat_pat_a1'))), '1', 'Patient aendert eigenen Termin');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.appointments SET title = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_phys_pat_a1'))), '0', 'Patient aendert Physio-Termin nicht');
SELECT t.ok(t.count(format('SELECT 1 FROM public.appointments WHERE id = %L', t.id('apt_phys_pat_a1'))) = 1, 'Patient liest Physio-Termin');
SELECT t.throws(format('UPDATE public.appointments SET created_by_role = ''physio'' WHERE id = %L', t.id('apt_pat_pat_a1')), '42501', 'Patient aendert created_by_role nicht (Spalten-Grant)');
SELECT t.throws(format('UPDATE public.appointments SET patient_id = %L WHERE id = %L', t.id('pat_a3'), t.id('apt_pat_pat_a1')), '42501', 'Patient aendert patient_id nicht');
SELECT t.as_user(t.id('phys_a2'));
SELECT t.is(t.val(format('WITH u AS (UPDATE public.appointments SET title = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_phys_pat_a1'))), '0', 'Physio A2 aendert Termin von A1 nicht');
SELECT t.is(t.val(format('WITH u AS (DELETE FROM public.appointments WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_phys_pat_a1'))), '0', 'Physio A2 loescht Termin von A1 nicht');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.appointments SET title = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_pat_pat_a1'))), '0', 'Physio aendert Patienten-Termin nicht');
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(t.val(format('WITH u AS (UPDATE public.appointments SET title = ''neu'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_phys_pat_a1'))), '1', 'Physio A1 aendert eigenen Termin');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(t.val(format('WITH u AS (DELETE FROM public.appointments WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_phys_pat_a1'))), '0', 'Patient loescht Physio-Termin nicht');
SELECT t.is(t.val(format('WITH u AS (DELETE FROM public.appointments WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_pat_pat_a1'))), '1', 'Patient loescht eigenen Termin');
-- Behandler eines anderen Patienten kann nicht verknuepft werden
SELECT t.throws(format('INSERT INTO public.appointments (patient_id, treater_id, starts_at, title) VALUES (%L, %L, now(), ''x'')', t.id('pat_a1'), t.id('tr_pat_a3')), '23503', 'Behandler eines anderen Patienten -> Fremdschluessel-Fehler');
