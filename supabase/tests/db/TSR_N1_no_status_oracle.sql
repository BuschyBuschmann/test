-- Sicherheitsreview F2-1R NIT-1: kein Existenz-/Statusorakel ueber die Schreibsperre (t10 vor
-- t30/RLS). Eine ungebundene anonyme Sitzung (und ein gebundener Patient fuer fremde Patienten)
-- erhaelt fuer aktive, eingeladene, geloeschte und unbekannte Patienten dieselbe Antwort
-- 42501 not_allowed. Vor dem Fix: eingeladen/unbekannt/geloescht -> patient_not_active,
-- aktiv -> not_allowed (aus t30). create_patient: fremde Praxis erhaelt fuer jede vorhandene id
-- unabhaengig von Status und Parametern dieselbe Antwort.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
-- pat_b1 loescht seinen Zugang (access_deleted)
SELECT t.as_user(t.id('anon_b1'), true);
SELECT public.delete_my_data();
SELECT t.as_admin();
INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_x'), true);
SELECT t.is((SELECT string_agg(status, ',' ORDER BY id) FROM public.patients WHERE id IN (t.id('pat_a1'), t.id('pat_a2'), t.id('pat_b1'))),
            (SELECT string_agg(s, ',' ORDER BY i) FROM (VALUES (t.id('pat_a1'), 'active'), (t.id('pat_a2'), 'invited'), (t.id('pat_b1'), 'access_deleted')) v(i, s)),
            'Ausgangslage: aktiv, eingeladen, geloescht');

-- Fehler (SQLSTATE:Meldung) einer Anweisung
CREATE FUNCTION pg_temp.err(p_sql text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE v_state text; v_msg text;
BEGIN
  BEGIN EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
    RETURN v_state || ':' || v_msg;
  END;
  RETURN 'kein Fehler';
END $$;

-- ungebundene anonyme Sitzung
SELECT t.as_user(t.id('anon_x'), true);
SELECT t.is(pg_temp.err(format('INSERT INTO public.appointments (id, patient_id, starts_at, title) VALUES (gen_random_uuid(), %L, now(), %L)', t.id(p), 'x')),
            '42501:not_allowed', 'ungebunden, Termin fuer ' || p || ' -> 42501 not_allowed')
  FROM unnest(ARRAY['pat_a1', 'pat_a2', 'pat_b1', 'pat_unbekannt']) p;
SELECT t.is(pg_temp.err(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (gen_random_uuid(), %L, gen_random_uuid(), current_date, %L)', t.id(p), 'checklist')),
            '42501:not_allowed', 'ungebunden, Session fuer ' || p || ' -> 42501 not_allowed')
  FROM unnest(ARRAY['pat_a1', 'pat_a2', 'pat_b1', 'pat_unbekannt']) p;

-- gebundener Patient pat_a1 fuer fremde Patienten
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(pg_temp.err(format('INSERT INTO public.appointments (id, patient_id, starts_at, title) VALUES (gen_random_uuid(), %L, now(), %L)', t.id(p), 'x')),
            '42501:not_allowed', 'gebunden (pat_a1), Termin fuer ' || p || ' -> 42501 not_allowed')
  FROM unnest(ARRAY['pat_a3', 'pat_a2', 'pat_b1', 'pat_unbekannt']) p;
SELECT t.lives(format('INSERT INTO public.appointments (id, patient_id, starts_at, title) VALUES (gen_random_uuid(), %L, now(), %L)', t.id('pat_a1'), 'eigener'),
               'gebunden (pat_a1), eigener Termin weiterhin moeglich');

-- create_patient mit vorhandener fremder id: Status und Parameter bleiben verborgen
SELECT t.as_user(t.id('phys_b1'));
SELECT t.is(pg_temp.err(format('SELECT * FROM public.create_patient(%L, %L, %L, NULL, %L)', t.id(v.p), v.f, v.l, t.today())),
            '42501:not_allowed', 'fremde Praxis, vorhandene id ' || v.p || ' (' || v.f || '/' || v.l || ') -> 42501 not_allowed')
  FROM (VALUES ('pat_a1', 'Anna', 'Knie'), ('pat_a2', 'Ben', 'Schulter'), ('pat_a2', 'Andere', 'Huefte')) v(p, f, l);
