-- Test-Helfer fuer die DB-Tests (nur Test-Vorlage, nie in Migrationen). Laeuft als Superuser.
-- Schema t ist testintern und von Rechte-Inventar-Pruefungen (DB-T01) ausgenommen.
--
-- Pruefungen melden "NOTICE: ok - <Text>"; ein Fehlschlag bricht mit "not ok - <Text>" ab
-- (psql ON_ERROR_STOP). Sitzungswechsel: t.as_admin(), t.as_owner(), t.as_anon(),
-- t.as_user(uid, anonym), t.as_service(). Uhr: t.set_clock(ts), t.reset_clock().

\set ON_ERROR_STOP 1

CREATE SCHEMA IF NOT EXISTS t;
GRANT USAGE ON SCHEMA t TO PUBLIC;

CREATE OR REPLACE FUNCTION t.id(p_name text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT md5(p_name)::uuid $$;

CREATE OR REPLACE FUNCTION t.ok(p_cond boolean, p_msg text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_cond IS TRUE THEN
    RAISE NOTICE 'ok - %', p_msg;
  ELSE
    RAISE EXCEPTION 'not ok - %', p_msg;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION t.is(p_got anyelement, p_want anyelement, p_msg text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_got IS NOT DISTINCT FROM p_want THEN
    RAISE NOTICE 'ok - %', p_msg;
  ELSE
    RAISE EXCEPTION 'not ok - % (erhalten: %, erwartet: %)', p_msg, p_got, p_want;
  END IF;
END $$;

-- Anweisung muss mit SQLSTATE p_state (und optional Meldung LIKE p_like) scheitern
CREATE OR REPLACE FUNCTION t.throws(p_sql text, p_state text, p_msg text, p_like text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_state text;
  v_text  text;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_text = MESSAGE_TEXT;
    IF v_state = p_state AND (p_like IS NULL OR v_text LIKE p_like) THEN
      RAISE NOTICE 'ok - %', p_msg;
      RETURN;
    END IF;
    RAISE EXCEPTION 'not ok - % (Fehler %: %, erwartet % %)', p_msg, v_state, v_text, p_state, coalesce(p_like, '');
  END;
  RAISE EXCEPTION 'not ok - % (kein Fehler, erwartet %)', p_msg, p_state;
END $$;

-- Anweisung muss ohne Fehler laufen
CREATE OR REPLACE FUNCTION t.lives(p_sql text, p_msg text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_state text;
  v_text  text;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_text = MESSAGE_TEXT;
    RAISE EXCEPTION 'not ok - % (Fehler %: %)', p_msg, v_state, v_text;
  END;
  RAISE NOTICE 'ok - %', p_msg;
END $$;

-- Zeilenzahl einer Abfrage in der aktuellen Rolle
CREATE OR REPLACE FUNCTION t.count(p_sql text) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE v bigint;
BEGIN
  EXECUTE 'SELECT count(*) FROM (' || p_sql || ') s' INTO v;
  RETURN v;
END $$;

-- erster Wert einer Abfrage als Text
CREATE OR REPLACE FUNCTION t.val(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  EXECUTE p_sql INTO v;
  RETURN v;
END $$;

-- 0 Zeilen oder permission denied (42501)
CREATE OR REPLACE FUNCTION t.sees_nothing(p_sql text) RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE v bigint;
BEGIN
  BEGIN
    EXECUTE 'SELECT count(*) FROM (' || p_sql || ') s' INTO v;
  EXCEPTION WHEN insufficient_privilege THEN
    RETURN true;
  END;
  RETURN v = 0;
END $$;

-- Fehlercode einer Anweisung ('' = kein Fehler)
CREATE OR REPLACE FUNCTION t.sqlstate_of(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v_state text;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE;
    RETURN v_state;
  END;
  RETURN '';
END $$;


-- JSON mit Platzhaltern {{name}} -> t.id(name)
CREATE OR REPLACE FUNCTION t.j(p text) RETURNS jsonb LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE r text := p; m text;
BEGIN
  FOR m IN SELECT DISTINCT (regexp_matches(p, '\{\{([a-z0-9_]+)\}\}', 'g'))[1] LOOP
    r := replace(r, '{{' || m || '}}', t.id(m)::text);
  END LOOP;
  RETURN r::jsonb;
END $$;

-- Version des aktuellen Plans (in der aktuellen Rolle gelesen)
CREATE OR REPLACE FUNCTION t.plan_version(p_patient text) RETURNS integer LANGUAGE sql STABLE AS $$
  SELECT pl.version FROM public.plans pl WHERE pl.patient_id = t.id(p_patient) AND NOT pl.closed
$$;

-- save_plan mit aktueller Version und Platzhalter-JSON
CREATE OR REPLACE FUNCTION t.save_plan(p_patient text, p_payload text) RETURNS integer LANGUAGE sql AS $$
  SELECT public.save_plan(t.id(p_patient), t.plan_version(p_patient), t.j(p_payload))
$$;

-- Sitzungen -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION t.as_admin() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE 'RESET ROLE';
  PERFORM set_config('request.jwt.claims', '', false);
END $$;

CREATE OR REPLACE FUNCTION t.as_owner() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE 'RESET ROLE';
  PERFORM set_config('request.jwt.claims', '', false);
  EXECUTE 'SET ROLE postgres';
END $$;

CREATE OR REPLACE FUNCTION t.as_anon() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE 'RESET ROLE';
  PERFORM set_config('request.jwt.claims', '{"role":"anon"}', false);
  EXECUTE 'SET ROLE anon';
END $$;

CREATE OR REPLACE FUNCTION t.as_user(p_uid uuid, p_anonymous boolean DEFAULT false) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE 'RESET ROLE';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'role', 'authenticated', 'is_anonymous', p_anonymous)::text, false);
  EXECUTE 'SET ROLE authenticated';
END $$;

-- Seed-Sitzung: service_role mit passendem JWT, ohne Patienten-/Physio-Bezug
CREATE OR REPLACE FUNCTION t.as_service() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE 'RESET ROLE';
  PERFORM set_config('request.jwt.claims', '{"role":"service_role"}', false);
  EXECUTE 'SET ROLE service_role';
END $$;

-- Uhr (nur in der Wegwerf-Datenbank des Tests) ------------------------------
CREATE OR REPLACE FUNCTION t.set_clock(p_ts timestamptz) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  EXECUTE format(
    'CREATE OR REPLACE FUNCTION app.utc_now() RETURNS timestamptz LANGUAGE sql STABLE '
    'SET search_path = '''' AS $f$ SELECT %L::timestamptz $f$', p_ts);
END $$;

CREATE OR REPLACE FUNCTION t.reset_clock() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  EXECUTE 'CREATE OR REPLACE FUNCTION app.utc_now() RETURNS timestamptz LANGUAGE sql STABLE '
          'SET search_path = '''' AS $f$ SELECT pg_catalog.now() $f$';
END $$;

CREATE OR REPLACE FUNCTION t.today() RETURNS date
LANGUAGE sql STABLE SECURITY DEFINER AS $$ SELECT app.utc_today() $$;

-- Ablage fuer Codes und Hook-Aufrufe ----------------------------------------
CREATE TABLE IF NOT EXISTS t.codes (name text PRIMARY KEY, code text NOT NULL);
CREATE TABLE IF NOT EXISTS t.calls (fn text NOT NULL, arg text, at timestamptz DEFAULT clock_timestamp());
GRANT ALL ON ALL TABLES IN SCHEMA t TO PUBLIC;

CREATE OR REPLACE FUNCTION t.code(p_name text) RETURNS text
LANGUAGE sql STABLE AS $$ SELECT code FROM t.codes WHERE name = p_name $$;

-- Physio legt Patienten an und merkt sich den Code
CREATE OR REPLACE FUNCTION t.create_patient(p_physio text, p_name text, p_first text, p_label text,
  p_template text DEFAULT NULL) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_code text;
BEGIN
  PERFORM t.as_user(t.id(p_physio));
  SELECT c.code INTO v_code
    FROM public.create_patient(t.id(p_name), p_first, p_label,
           CASE WHEN p_template IS NULL THEN NULL ELSE t.id(p_template) END, t.today()) c;
  PERFORM t.as_admin();
  INSERT INTO t.codes (name, code) VALUES (p_name, v_code)
  ON CONFLICT (name) DO UPDATE SET code = EXCLUDED.code;
END $$;

-- anonyme Sitzung anlegen und Code einloesen; liefert das Ergebnis
CREATE OR REPLACE FUNCTION t.redeem(p_anon text, p_code text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  PERFORM t.as_admin();
  INSERT INTO auth.users (id, is_anonymous) VALUES (t.id(p_anon), true) ON CONFLICT (id) DO NOTHING;
  PERFORM t.as_user(t.id(p_anon), true);
  v := public.redeem_invitation(p_code);
  PERFORM t.as_admin();
  RETURN v;
END $$;

-- Basis-Fixture: 2 Praxen, 3 Physios, Uebungen, Vorlagen, 4 Patienten (3 gebunden) mit Daten.
-- Nur Testdaten.
CREATE OR REPLACE FUNCTION t.seed_base() RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  r text;
  v_pat text;
  v_plan uuid;
  v_phase uuid;
  v_item uuid;
BEGIN
  PERFORM t.as_admin();
  INSERT INTO public.practices (id, name, is_test) VALUES
    (t.id('practice_a'), 'Praxis A (Test)', true),
    (t.id('practice_b'), 'Praxis B (Test)', true);
  INSERT INTO auth.users (id, email) VALUES
    (t.id('phys_a1'), 'a1@test.curaone.invalid'),
    (t.id('phys_a2'), 'a2@test.curaone.invalid'),
    (t.id('phys_b1'), 'b1@test.curaone.invalid');
  INSERT INTO public.physios (id, practice_id, display_name) VALUES
    (t.id('phys_a1'), t.id('practice_a'), 'Physio A1'),
    (t.id('phys_a2'), t.id('practice_a'), 'Physio A2'),
    (t.id('phys_b1'), t.id('practice_b'), 'Physio B1');

  INSERT INTO public.exercises (id, practice_id, name, description, is_example, materials, locations) VALUES
    (t.id('ex_cat1'), NULL, 'Kniebeuge', 'Beispiel-Uebung Katalog', true, '{Matte}', '{home}'),
    (t.id('ex_cat2'), NULL, 'Bruecke', 'Beispiel-Uebung Katalog', true, '{}', '{home,gym}'),
    (t.id('ex_cat3'), NULL, 'Wadenheben', 'nicht in einem Plan', true, '{}', '{}'),
    (t.id('ex_a1'), t.id('practice_a'), 'Uebung A', 'Uebung der Praxis A', false, '{Band}', '{practice}'),
    (t.id('ex_a2'), t.id('practice_a'), 'Uebung A2', 'ungenutzt', false, '{}', '{}'),
    (t.id('ex_b1'), t.id('practice_b'), 'Uebung B', 'Uebung der Praxis B', false, '{}', '{}');

  INSERT INTO public.plan_templates (id, practice_id, name, injury_label, is_example, payload) VALUES
    (t.id('tpl_ex'), NULL, 'Beispiel Knie', 'Knie (Beispiel)', true, jsonb_build_object('phases', jsonb_build_array(
       jsonb_build_object('title', 'Phase 1', 'planned_weeks', 2, 'items', jsonb_build_array(
         jsonb_build_object('exercise_id', t.id('ex_cat1'), 'sets', 3, 'reps', 10),
         jsonb_build_object('exercise_id', t.id('ex_cat2'), 'sets', 2, 'duration_sec', 30,
                            'release', 'prepared', 'release_with_phase', 1))),
       jsonb_build_object('title', 'Phase 2', 'planned_weeks', 3, 'items', jsonb_build_array(
         jsonb_build_object('exercise_id', t.id('ex_cat2'), 'sets', 3, 'reps', 12),
         jsonb_build_object('exercise_id', t.id('ex_cat1'), 'sets', 2, 'reps', 8, 'easier_variant_of', 0)))))),
    (t.id('tpl_a'), t.id('practice_a'), 'Vorlage A', 'Huefte', false, jsonb_build_object('phases', jsonb_build_array(
       jsonb_build_object('title', 'Start', 'planned_weeks', 4, 'items', jsonb_build_array(
         jsonb_build_object('exercise_id', t.id('ex_a1'), 'sets', 3, 'reps', 10)))))),
    (t.id('tpl_b'), t.id('practice_b'), 'Vorlage B', 'Ruecken', false, jsonb_build_object('phases', jsonb_build_array(
       jsonb_build_object('title', 'Start', 'planned_weeks', 4, 'items', jsonb_build_array(
         jsonb_build_object('exercise_id', t.id('ex_b1'), 'sets', 3, 'reps', 10))))));

  PERFORM t.create_patient('phys_a1', 'pat_a1', 'Anna', 'Knie', 'tpl_ex');
  PERFORM t.create_patient('phys_a2', 'pat_a2', 'Ben', 'Schulter');
  PERFORM t.create_patient('phys_a1', 'pat_a3', 'Clara', NULL, 'tpl_a');
  PERFORM t.create_patient('phys_b1', 'pat_b1', 'Dora', NULL, 'tpl_b');

  FOREACH v_pat IN ARRAY ARRAY['pat_a1', 'pat_a3', 'pat_b1'] LOOP
    r := t.redeem('anon_' || substr(v_pat, 5), t.code(v_pat));
    IF r <> 'ok' THEN RAISE EXCEPTION 'seed: redeem % -> %', v_pat, r; END IF;
  END LOOP;

  -- Daten je gebundenem Patienten (als Patient) und Akte (als Physio)
  FOREACH v_pat IN ARRAY ARRAY['pat_a1', 'pat_a3', 'pat_b1'] LOOP
    PERFORM t.as_admin();
    SELECT pl.id, pl.current_phase_id INTO v_plan, v_phase
      FROM public.plans pl WHERE pl.patient_id = t.id(v_pat) AND NOT pl.closed;
    SELECT pi.id INTO v_item FROM public.plan_items pi WHERE pi.plan_id = v_plan ORDER BY pi.position LIMIT 1;
    PERFORM t.as_user(t.id('anon_' || substr(v_pat, 5)), true);
    INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, phase_id, plan_version, mode)
    VALUES (t.id('ts_' || v_pat), t.id(v_pat), v_plan, t.today(), v_phase, 1, 'checklist');
    INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, plan_item_id, status)
    VALUES (t.id('er_' || v_pat), t.id(v_pat), t.id('ts_' || v_pat), t.today(), v_item, 'done');
    INSERT INTO public.appointments (id, patient_id, starts_at, title)
    VALUES (t.id('apt_pat_' || v_pat), t.id(v_pat), now() + interval '2 days', 'eigener Termin');
    PERFORM public.accept_consent('physio_sharing', 'physio_sharing-2');
    PERFORM public.set_manny_look('brille');
  END LOOP;

  FOREACH v_pat IN ARRAY ARRAY['pat_a1', 'pat_a2', 'pat_a3', 'pat_b1'] LOOP
    PERFORM t.as_user(CASE WHEN v_pat = 'pat_b1' THEN t.id('phys_b1') ELSE t.id('phys_a1') END);
    INSERT INTO public.treaters (id, patient_id, role, name)
    VALUES (t.id('tr_' || v_pat), t.id(v_pat), 'Hausarzt', 'Dr. Test');
    INSERT INTO public.history_entries (id, patient_id, kind, title)
    VALUES (t.id('he_' || v_pat), t.id(v_pat), 'op', 'Eingriff (Test)');
    INSERT INTO public.appointments (id, patient_id, starts_at, title)
    VALUES (t.id('apt_phys_' || v_pat), t.id(v_pat), now() + interval '7 days', 'Physio-Termin');
  END LOOP;
  PERFORM t.as_admin();
END $$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA t TO PUBLIC;
