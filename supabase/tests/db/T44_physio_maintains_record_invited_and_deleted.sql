-- DB-T44 physio_maintains_record_invited_and_deleted (Plan 12.2, NEU-2): Physio legt an, aendert
-- und loescht Behandler, Krankengeschichte und Termine fuer Patienten mit Status invited und
-- access_deleted (Schreibsperre gilt nur fuer Patienten-Schreibvorgaenge).
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('anon_a3'), true);
SELECT t.is(public.delete_my_data(), 'ok', 'Clara loescht ihre Daten (access_deleted)');
SELECT t.as_user(t.id('phys_a1'));
DO $$
DECLARE p text;
BEGIN
  FOREACH p IN ARRAY ARRAY['pat_a2', 'pat_a3'] LOOP
    PERFORM t.lives(format('INSERT INTO public.treaters (id, patient_id, role, name) VALUES (%L, %L, ''Orthopaede'', ''Dr. X'')', t.id('trn_' || p), t.id(p)), p || ': Behandler anlegen');
    PERFORM t.is(t.val(format('WITH u AS (UPDATE public.treaters SET phone = ''0'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('trn_' || p))), '1', p || ': Behandler aendern');
    PERFORM t.is(t.val(format('WITH d AS (DELETE FROM public.treaters WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('trn_' || p))), '1', p || ': Behandler loeschen');
    PERFORM t.lives(format('INSERT INTO public.history_entries (id, patient_id, kind, title) VALUES (%L, %L, ''op'', ''X'')', t.id('hen_' || p), t.id(p)), p || ': Krankengeschichte anlegen');
    PERFORM t.is(t.val(format('WITH u AS (UPDATE public.history_entries SET note = ''n'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('hen_' || p))), '1', p || ': Krankengeschichte aendern');
    PERFORM t.is(t.val(format('WITH d AS (DELETE FROM public.history_entries WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('hen_' || p))), '1', p || ': Krankengeschichte loeschen');
    PERFORM t.lives(format('INSERT INTO public.appointments (id, patient_id, starts_at, title) VALUES (%L, %L, now(), ''Termin'')', t.id('aptn_' || p), t.id(p)), p || ': Termin anlegen');
    PERFORM t.is(t.val(format('WITH u AS (UPDATE public.appointments SET title = ''neu'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('aptn_' || p))), '1', p || ': Termin aendern');
    PERFORM t.is(t.val(format('WITH d AS (DELETE FROM public.appointments WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('aptn_' || p))), '1', p || ': Termin loeschen');
    PERFORM t.is(t.val(format('WITH u AS (UPDATE public.patients SET last_name = ''Muster'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id(p))), '1', p || ': Nachname pflegen');
  END LOOP;
END $$;
SELECT t.as_admin();
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a2')) || '/' || (SELECT status FROM public.patients WHERE id = t.id('pat_a3')),
            'invited/access_deleted', 'Status unveraendert');
