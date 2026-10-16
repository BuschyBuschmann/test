-- L2 / Migration 05: Einladung inkl. create_patient/regenerate_invitation, redeem_invitation,
-- Plan (save_plan, set_current_phase), Einwilligung, Loeschen, Manny-Look (Plan 6.4-6.7, 6.13).
-- Idempotent (CREATE OR REPLACE).
--
-- Alle RPCs: SECURITY DEFINER, SET search_path = '', REVOKE EXECUTE FROM PUBLIC, anon,
-- GRANT EXECUTE TO authenticated; erste Anweisung prueft den Aufrufer.
-- Fehlercodes (Meldungstext = Code fuer die App):
--   42501  not_allowed (Aufrufer/Zugehoerigkeit), foreign_template, patient_not_invitable
--   22023  invalid_local_day, first_name_required, injury_or_template_required, invalid_payload,
--          invalid_release, invalid_easier_variant, invalid_manny_look, id_required
--   P0001  conflict, current_phase_required, foreign_id, plan_closed, idempotency_mismatch
--   55000  pepper_missing (Pepper nicht gesetzt, X2-11)
-- redeem_invitation und delete_my_data liefern Ergebniscodes als Rueckgabewert.

-- ---------------------------------------------------------------------------
-- interne Hilfen (kein EXECUTE fuer API-Rollen)
-- ---------------------------------------------------------------------------

-- Plausibilitaet fuer sofortige Aufrufe: +-1 Tag um das UTC-Datum (6.7 Nr. 3)
CREATE OR REPLACE FUNCTION app.check_local_day_immediate(p_local_day date) RETURNS void
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF p_local_day IS NULL
     OR p_local_day < app.utc_today() - 1
     OR p_local_day > app.utc_today() + 1 THEN
    RAISE EXCEPTION 'invalid_local_day' USING ERRCODE = '22023';
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION app.invite_pepper() RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v text;
BEGIN
  SELECT s.value INTO v FROM app.secrets s WHERE s.name = 'invite_pepper';
  IF v IS NULL THEN
    RAISE EXCEPTION 'pepper_missing' USING ERRCODE = '55000';
  END IF;
  RETURN v;
END
$$;

-- Normalisierung (6.5): Grossschreibung; Leerzeichen und Bindestriche entfernen; O->0, I/L->1
CREATE OR REPLACE FUNCTION app.normalize_invite_code(p_code text) RETURNS text
LANGUAGE sql IMMUTABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT pg_catalog.translate(
           pg_catalog.regexp_replace(pg_catalog.upper(p_code), '[[:space:]-]', '', 'g'),
           'OIL', '011')
$$;

CREATE OR REPLACE FUNCTION app.invite_code_hmac(p_code text) RETURNS bytea
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT extensions.hmac(p_code, app.invite_pepper(), 'sha256')
$$;

-- Neue Einladung: widerruft offene, erzeugt 10 Zeichen Crockford-Base32 (50 Bit) aus
-- gen_random_bytes, speichert nur HMAC-SHA256(pepper, code); Ablauf 14 Tage (O-7)
CREATE OR REPLACE FUNCTION app.new_invitation(p_patient uuid)
RETURNS TABLE (code text, expires_at timestamptz)
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
#variable_conflict use_column
DECLARE
  c_alphabet constant text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  v_bytes   bytea;
  v_code    text;
  v_expires timestamptz := app.utc_now() + interval '14 days';
  v_try     integer := 0;
BEGIN
  UPDATE public.invitations i
     SET revoked_at = app.utc_now()
   WHERE i.patient_id = p_patient
     AND i.redeemed_at IS NULL
     AND i.revoked_at IS NULL;
  LOOP
    v_try := v_try + 1;
    v_bytes := extensions.gen_random_bytes(10);
    v_code := '';
    FOR k IN 0..9 LOOP
      -- 256 ist durch 32 teilbar: die unteren 5 Bit sind gleichverteilt
      v_code := v_code || pg_catalog.substr(c_alphabet, (pg_catalog.get_byte(v_bytes, k) & 31) + 1, 1);
    END LOOP;
    BEGIN
      INSERT INTO public.invitations (patient_id, code_hmac, created_at, expires_at)
      VALUES (p_patient, app.invite_code_hmac(v_code), app.utc_now(), v_expires);
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      IF v_try >= 3 THEN RAISE; END IF;
    END;
  END LOOP;
  code := v_code;
  expires_at := v_expires;
  RETURN NEXT;
END
$$;

-- Vorlage in einen leeren Plan kopieren (neue IDs; 6.6 Schritt 3/4).
-- payload: {"phases":[{"title","planned_weeks","items":[{"exercise_id","sets","reps",
--   "duration_sec","weight_kg","pause_sec","load_note","release","release_on",
--   "release_with_phase" (0-basierter Phasenindex), "easier_variant_of" (0-basierter
--   Positionsindex in derselben Phase)}]}]}
CREATE OR REPLACE FUNCTION app.copy_template_into_plan(p_plan uuid, p_payload jsonb, p_practice uuid)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_phase     jsonb;
  v_pidx      bigint;
  v_item      jsonb;
  v_iidx      bigint;
  v_phase_ids uuid[] := '{}';
  v_item_ids  jsonb := '{}';
  v_new       uuid;
  v_rwp       integer;
  v_var       integer;
  v_ex        uuid;
BEGIN
  IF p_payload IS NULL OR pg_catalog.jsonb_typeof(p_payload -> 'phases') IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'invalid_payload' USING ERRCODE = '22023';
  END IF;

  FOR v_phase, v_pidx IN
    SELECT x.value, x.ordinality FROM pg_catalog.jsonb_array_elements(p_payload -> 'phases') WITH ORDINALITY x
  LOOP
    v_new := pg_catalog.gen_random_uuid();
    INSERT INTO public.phases (id, plan_id, position, title, planned_weeks)
    VALUES (v_new, p_plan, (v_pidx - 1)::integer, v_phase ->> 'title', (v_phase ->> 'planned_weeks')::integer);
    v_phase_ids := v_phase_ids || v_new;
  END LOOP;

  FOR v_phase, v_pidx IN
    SELECT x.value, x.ordinality FROM pg_catalog.jsonb_array_elements(p_payload -> 'phases') WITH ORDINALITY x
  LOOP
    IF pg_catalog.jsonb_typeof(coalesce(v_phase -> 'items', '[]'::jsonb)) <> 'array' THEN
      RAISE EXCEPTION 'invalid_payload' USING ERRCODE = '22023';
    END IF;
    FOR v_item, v_iidx IN
      SELECT x.value, x.ordinality
        FROM pg_catalog.jsonb_array_elements(coalesce(v_phase -> 'items', '[]'::jsonb)) WITH ORDINALITY x
    LOOP
      v_ex := (v_item ->> 'exercise_id')::uuid;
      IF NOT EXISTS (SELECT 1 FROM public.exercises e
                      WHERE e.id = v_ex AND (e.practice_id IS NULL OR e.practice_id = p_practice)) THEN
        RAISE EXCEPTION 'foreign_id' USING ERRCODE = 'P0001';
      END IF;
      v_rwp := (v_item ->> 'release_with_phase')::integer;
      IF v_rwp IS NOT NULL AND (v_rwp < 0 OR v_rwp >= pg_catalog.cardinality(v_phase_ids)) THEN
        RAISE EXCEPTION 'invalid_payload' USING ERRCODE = '22023';
      END IF;
      v_new := pg_catalog.gen_random_uuid();
      INSERT INTO public.plan_items (id, plan_id, phase_id, exercise_id, position, sets, reps,
        duration_sec, weight_kg, pause_sec, load_note, release, release_on, release_with_phase_id)
      VALUES (v_new, p_plan, v_phase_ids[v_pidx], v_ex, (v_iidx - 1)::integer,
        (v_item ->> 'sets')::integer, (v_item ->> 'reps')::integer,
        (v_item ->> 'duration_sec')::integer, (v_item ->> 'weight_kg')::numeric,
        (v_item ->> 'pause_sec')::integer, v_item ->> 'load_note',
        coalesce(v_item ->> 'release', 'active'), (v_item ->> 'release_on')::date,
        CASE WHEN v_rwp IS NULL THEN NULL ELSE v_phase_ids[v_rwp + 1] END);
      v_item_ids := v_item_ids || pg_catalog.jsonb_build_object(v_pidx || ':' || (v_iidx - 1), v_new);
    END LOOP;
  END LOOP;

  FOR v_phase, v_pidx IN
    SELECT x.value, x.ordinality FROM pg_catalog.jsonb_array_elements(p_payload -> 'phases') WITH ORDINALITY x
  LOOP
    FOR v_item, v_iidx IN
      SELECT x.value, x.ordinality
        FROM pg_catalog.jsonb_array_elements(coalesce(v_phase -> 'items', '[]'::jsonb)) WITH ORDINALITY x
    LOOP
      v_var := (v_item ->> 'easier_variant_of')::integer;
      IF v_var IS NOT NULL THEN
        IF NOT (v_item_ids ? (v_pidx || ':' || v_var)) OR v_var = v_iidx - 1 THEN
          RAISE EXCEPTION 'invalid_easier_variant' USING ERRCODE = '22023';
        END IF;
        UPDATE public.plan_items pi
           SET easier_variant_of = (v_item_ids ->> (v_pidx || ':' || v_var))::uuid
         WHERE pi.id = (v_item_ids ->> (v_pidx || ':' || (v_iidx - 1)))::uuid;
      END IF;
    END LOOP;
  END LOOP;

  UPDATE public.plans pl SET current_phase_id = v_phase_ids[1] WHERE pl.id = p_plan;
END
$$;

-- Hook bei Neubindung (N-1); Ausschnitt 3 loescht hier den Chat der alten Identitaet (KI-Plan)
CREATE OR REPLACE FUNCTION app.on_rebind(p_old_uid uuid) RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  -- in Ausschnitt 2 nichts zu tun
  RETURN;
END
$$;

REVOKE EXECUTE ON FUNCTION
  app.check_local_day_immediate(date),
  app.invite_pepper(),
  app.normalize_invite_code(text),
  app.invite_code_hmac(text),
  app.new_invitation(uuid),
  app.copy_template_into_plan(uuid, jsonb, uuid),
  app.on_rebind(uuid)
FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- create_patient (6.6, PB-8, PB-E)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_patient(
  p_id             uuid,
  p_first_name     text,
  p_injury_label   text,
  p_template_id    uuid,
  p_local_day      date,
  p_last_name      text DEFAULT NULL,
  p_reference_date date DEFAULT NULL
)
RETURNS TABLE (patient_id uuid, code text, expires_at timestamptz)
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
#variable_conflict use_column
DECLARE
  v_practice    uuid := app.current_physio_practice();
  v_physio      uuid := app.uid();
  v_first       text := nullif(btrim(p_first_name), '');
  v_last        text := nullif(btrim(p_last_name), '');
  v_label_in    text := nullif(btrim(p_injury_label), '');
  v_label       text;
  v_tpl_label   text;
  v_tpl_payload jsonb;
  v_hash        text;
  v_inserted    uuid;
  v_ex_practice uuid;
  v_ex_status   text;
  v_ex_hash     text;
  v_injury      uuid;
  v_plan        uuid;
  v_code        text;
  v_expires     timestamptz;
BEGIN
  IF v_practice IS NULL THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'id_required' USING ERRCODE = '22023';
  END IF;
  IF v_first IS NULL THEN
    RAISE EXCEPTION 'first_name_required' USING ERRCODE = '22023';
  END IF;
  IF v_label_in IS NULL AND p_template_id IS NULL THEN
    RAISE EXCEPTION 'injury_or_template_required' USING ERRCODE = '22023';
  END IF;
  PERFORM app.check_local_day_immediate(p_local_day);

  IF p_template_id IS NOT NULL THEN
    SELECT t.injury_label, t.payload INTO v_tpl_label, v_tpl_payload
      FROM public.plan_templates t
     WHERE t.id = p_template_id
       AND (t.practice_id IS NULL OR t.practice_id = v_practice);
    IF NOT FOUND THEN
      RAISE EXCEPTION 'foreign_template' USING ERRCODE = '42501';
    END IF;
  END IF;
  v_label := coalesce(v_label_in, nullif(btrim(v_tpl_label), ''));
  IF v_label IS NULL THEN
    RAISE EXCEPTION 'injury_or_template_required' USING ERRCODE = '22023';
  END IF;

  -- Parametervergleich ueber normalisierte Eingaben; local_day zaehlt nicht (MINOR-1)
  v_hash := pg_catalog.encode(extensions.digest(
              pg_catalog.jsonb_build_array(v_first, v_last, v_label_in, p_template_id, p_reference_date)::text,
              'sha256'), 'hex');

  -- serialisiert: ein gleichzeitiger zweiter Aufruf mit derselben id wartet hier
  INSERT INTO public.patients (id, practice_id, first_name, last_name, main_physio_id, status,
                               create_params_hash)
  VALUES (p_id, v_practice, v_first, v_last, v_physio, 'invited', v_hash)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_inserted;

  IF v_inserted IS NULL THEN
    SELECT pt.practice_id, pt.status, pt.create_params_hash
      INTO v_ex_practice, v_ex_status, v_ex_hash
      FROM public.patients pt WHERE pt.id = p_id FOR UPDATE;
    IF v_ex_practice IS DISTINCT FROM v_practice OR v_ex_status IS DISTINCT FROM 'invited' THEN
      RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
    END IF;
    IF v_ex_hash IS DISTINCT FROM v_hash THEN
      RAISE EXCEPTION 'idempotency_mismatch' USING ERRCODE = 'P0001';
    END IF;
    -- Wiederholung: Antwort ging verloren; alte Einladung widerrufen, neuer Code
    SELECT ni.code, ni.expires_at INTO v_code, v_expires FROM app.new_invitation(p_id) ni;
    patient_id := p_id; code := v_code; expires_at := v_expires;
    RETURN NEXT;
    RETURN;
  END IF;

  INSERT INTO public.injuries (patient_id, label, reference_date, started_on)
  VALUES (p_id, v_label, coalesce(p_reference_date, p_local_day), p_local_day)
  RETURNING id INTO v_injury;

  INSERT INTO public.plans (patient_id, injury_id, updated_by, updated_at)
  VALUES (p_id, v_injury, v_physio, app.utc_now())
  RETURNING id INTO v_plan;

  IF v_tpl_payload IS NOT NULL THEN
    PERFORM app.copy_template_into_plan(v_plan, v_tpl_payload, v_practice);
  END IF;

  SELECT ni.code, ni.expires_at INTO v_code, v_expires FROM app.new_invitation(p_id) ni;
  patient_id := p_id; code := v_code; expires_at := v_expires;
  RETURN NEXT;
END
$$;

-- ---------------------------------------------------------------------------
-- regenerate_invitation (O-8, N-1)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.regenerate_invitation(p_patient_id uuid)
RETURNS TABLE (code text, expires_at timestamptz)
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
#variable_conflict use_column
DECLARE
  v_status  text;
  v_code    text;
  v_expires timestamptz;
BEGIN
  IF NOT app.physio_can_see_patient(p_patient_id) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  SELECT pt.status INTO v_status FROM public.patients pt WHERE pt.id = p_patient_id FOR UPDATE;
  IF v_status NOT IN ('invited', 'active') THEN
    RAISE EXCEPTION 'patient_not_invitable' USING ERRCODE = '42501';
  END IF;
  SELECT ni.code, ni.expires_at INTO v_code, v_expires FROM app.new_invitation(p_patient_id) ni;
  code := v_code; expires_at := v_expires;
  RETURN NEXT;
END
$$;

-- ---------------------------------------------------------------------------
-- redeem_invitation (v1.2 4.4/4.5, M-3, N-1, N-6)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.redeem_invitation(p_code text)
RETURNS text
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid     uuid := app.uid();
  v_now     timestamptz := app.utc_now();
  v_code    text;
  v_hmac    bytea;
  v_inv     record;
  v_status  text;
  v_old     uuid;
  v_result  text;
BEGIN
  -- nur anonyme, ungebundene Sitzung, kein Physio
  IF v_uid IS NULL OR NOT app.is_anonymous()
     OR EXISTS (SELECT 1 FROM public.physios ph WHERE ph.id = v_uid)
     OR EXISTS (SELECT 1 FROM public.patients pt WHERE pt.auth_user_id = v_uid) THEN
    RETURN 'not_allowed';
  END IF;

  -- Bereinigung (> 24 h) und Bremse je Sitzung: 5 Fehlversuche je 15 Minuten
  DELETE FROM public.redeem_attempts ra WHERE ra.at < v_now - interval '24 hours';
  IF (SELECT count(*) FROM public.redeem_attempts ra
       WHERE ra.uid = v_uid AND NOT ra.ok AND ra.at > v_now - interval '15 minutes') >= 5 THEN
    RETURN 'too_many_attempts';
  END IF;

  v_code := app.normalize_invite_code(p_code);
  IF v_code IS NULL OR v_code !~ '^[0-9A-HJKMNP-TV-Z]{10}$' THEN
    INSERT INTO public.redeem_attempts (uid, at, ok) VALUES (v_uid, v_now, false);
    RETURN 'invalid';
  END IF;

  v_hmac := app.invite_code_hmac(v_code);
  SELECT i.id, i.patient_id, i.expires_at, i.redeemed_at, i.revoked_at INTO v_inv
    FROM public.invitations i WHERE i.code_hmac = v_hmac FOR UPDATE;
  IF NOT FOUND THEN
    v_result := 'invalid';
  ELSIF v_inv.revoked_at IS NOT NULL THEN
    v_result := 'invalid';
  ELSIF v_inv.redeemed_at IS NOT NULL THEN
    v_result := 'already_used';
  ELSIF v_inv.expires_at <= v_now THEN
    v_result := 'expired';
  END IF;
  IF v_result IS NOT NULL THEN
    INSERT INTO public.redeem_attempts (uid, at, ok) VALUES (v_uid, v_now, false);
    IF v_inv.id IS NOT NULL THEN
      UPDATE public.invitations i SET failed_attempts = i.failed_attempts + 1 WHERE i.id = v_inv.id;
    END IF;
    RETURN v_result;
  END IF;

  SELECT pt.status, pt.auth_user_id INTO v_status, v_old
    FROM public.patients pt WHERE pt.id = v_inv.patient_id FOR UPDATE;

  IF v_status = 'invited' THEN
    UPDATE public.patients pt
       SET auth_user_id = v_uid, status = 'active', bound_at = v_now
     WHERE pt.id = v_inv.patient_id;
    INSERT INTO public.account_events (patient_id, kind, at) VALUES (v_inv.patient_id, 'bound', v_now);
    v_result := 'ok';
  ELSIF v_status = 'active' THEN
    -- Neubindung: alte Identitaet loesen, Hook, altes Auth-Konto loeschen (N-1)
    UPDATE public.patients pt
       SET auth_user_id = v_uid, bound_at = v_now
     WHERE pt.id = v_inv.patient_id;
    IF v_old IS NOT NULL THEN
      PERFORM app.on_rebind(v_old);
      DELETE FROM auth.users u WHERE u.id = v_old;
    END IF;
    INSERT INTO public.account_events (patient_id, kind, at) VALUES (v_inv.patient_id, 'rebound', v_now);
    v_result := 'ok_rebound';
  ELSE
    INSERT INTO public.redeem_attempts (uid, at, ok) VALUES (v_uid, v_now, false);
    RETURN 'invalid';
  END IF;

  UPDATE public.invitations i SET redeemed_at = v_now, redeemed_by = v_uid WHERE i.id = v_inv.id;
  INSERT INTO public.redeem_attempts (uid, at, ok) VALUES (v_uid, v_now, true);
  RETURN v_result;
END
$$;

-- ---------------------------------------------------------------------------
-- accept_consent
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_consent(p_kind text, p_version text)
RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_patient uuid := app.current_patient_id();
  v_id      uuid;
BEGIN
  IF v_patient IS NULL THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  SELECT c.id INTO v_id FROM public.consents c
   WHERE c.patient_id = v_patient AND c.kind = p_kind AND c.version = p_version
     AND c.revoked_at IS NULL
   LIMIT 1;
  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;
  INSERT INTO public.consents (patient_id, kind, version, accepted_at)
  VALUES (v_patient, p_kind, p_version, app.utc_now())
  RETURNING id INTO v_id;
  RETURN v_id;
END
$$;

-- ---------------------------------------------------------------------------
-- save_plan (M-5, 6.7)
-- payload: {"plan_id"?: uuid, "current_phase_id": uuid|null,
--   "phases": [{"id","position","title","planned_weeks"}],
--   "items":  [{"id","phase_id","exercise_id","position","sets","reps","duration_sec",
--              "weight_kg","pause_sec","load_note","release","release_on",
--              "release_with_phase_id","easier_variant_of"}]}
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.save_plan(p_patient_id uuid, p_expected_version integer, p_plan jsonb)
RETURNS integer
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_practice uuid;
  v_plan_id  uuid;
  v_given    uuid;
  v_version  integer;
  v_closed   boolean;
  v_current  uuid;
  v_phases   jsonb;
  v_items    jsonb;
BEGIN
  IF NOT app.physio_can_see_patient(p_patient_id) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  v_practice := app.current_physio_practice();
  v_plan_id := app.current_plan_id(p_patient_id);

  IF p_plan IS NULL OR pg_catalog.jsonb_typeof(p_plan) <> 'object'
     OR pg_catalog.jsonb_typeof(p_plan -> 'phases') IS DISTINCT FROM 'array'
     OR pg_catalog.jsonb_typeof(p_plan -> 'items') IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'invalid_payload' USING ERRCODE = '22023';
  END IF;
  v_phases := p_plan -> 'phases';
  v_items := p_plan -> 'items';

  -- nur der aktuelle Plan (aktive Verletzung); abgeschlossener Plan -> plan_closed (DB-T62/T74)
  IF p_plan ? 'plan_id' THEN
    v_given := (p_plan ->> 'plan_id')::uuid;
    IF v_given IS DISTINCT FROM v_plan_id THEN
      IF EXISTS (SELECT 1 FROM public.plans pl
                  WHERE pl.id = v_given AND pl.patient_id = p_patient_id AND pl.closed) THEN
        RAISE EXCEPTION 'plan_closed' USING ERRCODE = 'P0001';
      END IF;
      RAISE EXCEPTION 'foreign_id' USING ERRCODE = 'P0001';
    END IF;
  END IF;
  IF v_plan_id IS NULL THEN
    RAISE EXCEPTION 'plan_closed' USING ERRCODE = 'P0001';
  END IF;

  SELECT pl.version, pl.closed INTO v_version, v_closed
    FROM public.plans pl WHERE pl.id = v_plan_id FOR UPDATE;
  IF v_closed THEN
    RAISE EXCEPTION 'plan_closed' USING ERRCODE = 'P0001';
  END IF;
  IF v_version IS DISTINCT FROM p_expected_version THEN
    RAISE EXCEPTION 'conflict' USING ERRCODE = 'P0001';
  END IF;

  -- Struktur: IDs vorhanden und eindeutig
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_phases) AS x(id uuid) WHERE x.id IS NULL)
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_items) AS x(id uuid, phase_id uuid, exercise_id uuid)
                 WHERE x.id IS NULL OR x.phase_id IS NULL OR x.exercise_id IS NULL)
     OR (SELECT count(*) <> count(DISTINCT x.id) FROM pg_catalog.jsonb_to_recordset(v_phases) AS x(id uuid))
     OR (SELECT count(*) <> count(DISTINCT x.id) FROM pg_catalog.jsonb_to_recordset(v_items) AS x(id uuid)) THEN
    RAISE EXCEPTION 'invalid_payload' USING ERRCODE = '22023';
  END IF;

  -- jede Phasen- und Positions-ID gehoert zu diesem Plan oder existiert noch nirgends (NEU-5)
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_phases) AS x(id uuid)
               JOIN public.phases ph ON ph.id = x.id WHERE ph.plan_id <> v_plan_id)
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_items) AS x(id uuid)
               JOIN public.plan_items pi ON pi.id = x.id WHERE pi.plan_id <> v_plan_id) THEN
    RAISE EXCEPTION 'foreign_id' USING ERRCODE = 'P0001';
  END IF;

  -- Phasenbezuege der Positionen nur auf Phasen dieses Payloads (DB-T65)
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_items) AS x(phase_id uuid, release_with_phase_id uuid)
              WHERE x.phase_id NOT IN (SELECT y.id FROM pg_catalog.jsonb_to_recordset(v_phases) AS y(id uuid))
                 OR (x.release_with_phase_id IS NOT NULL AND x.release_with_phase_id NOT IN
                       (SELECT y.id FROM pg_catalog.jsonb_to_recordset(v_phases) AS y(id uuid)))) THEN
    RAISE EXCEPTION 'foreign_id' USING ERRCODE = 'P0001';
  END IF;

  -- Uebung: Katalog oder eigene Praxis (DB-T19)
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_items) AS x(exercise_id uuid)
              WHERE NOT EXISTS (SELECT 1 FROM public.exercises e
                                 WHERE e.id = x.exercise_id
                                   AND (e.practice_id IS NULL OR e.practice_id = v_practice))) THEN
    RAISE EXCEPTION 'foreign_id' USING ERRCODE = 'P0001';
  END IF;

  -- Freischaltung je Position (6.7): active ohne Felder, prepared mit genau einem
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_items)
                AS x(release text, release_on date, release_with_phase_id uuid)
              WHERE NOT (
                (coalesce(x.release, 'active') = 'active' AND x.release_on IS NULL AND x.release_with_phase_id IS NULL)
                OR (x.release = 'prepared' AND num_nonnulls(x.release_on, x.release_with_phase_id) = 1))) THEN
    RAISE EXCEPTION 'invalid_release' USING ERRCODE = '22023';
  END IF;

  -- leichtere Variante (E-30): andere Position derselben Phase in diesem Payload
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_items) AS x(id uuid, phase_id uuid, easier_variant_of uuid)
              WHERE x.easier_variant_of IS NOT NULL
                AND (x.easier_variant_of = x.id OR NOT EXISTS (
                      SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_items) AS y(id uuid, phase_id uuid)
                       WHERE y.id = x.easier_variant_of AND y.phase_id = x.phase_id))) THEN
    RAISE EXCEPTION 'invalid_easier_variant' USING ERRCODE = '22023';
  END IF;

  -- aktuelle Phase: Pflicht, sobald Phasen existieren
  v_current := (p_plan ->> 'current_phase_id')::uuid;
  IF pg_catalog.jsonb_array_length(v_phases) > 0 THEN
    IF v_current IS NULL OR v_current NOT IN
         (SELECT y.id FROM pg_catalog.jsonb_to_recordset(v_phases) AS y(id uuid)) THEN
      RAISE EXCEPTION 'current_phase_required' USING ERRCODE = 'P0001';
    END IF;
  ELSE
    v_current := NULL;
  END IF;

  -- Anwenden: nur Entferntes loeschen, sonst Upsert nach ID
  DELETE FROM public.plan_items pi
   WHERE pi.plan_id = v_plan_id
     AND pi.id NOT IN (SELECT x.id FROM pg_catalog.jsonb_to_recordset(v_items) AS x(id uuid));
  UPDATE public.plan_items pi SET easier_variant_of = NULL
   WHERE pi.plan_id = v_plan_id AND pi.easier_variant_of IS NOT NULL;

  INSERT INTO public.phases (id, plan_id, position, title, planned_weeks)
  SELECT x.id, v_plan_id, x.position, x.title, x.planned_weeks
    FROM pg_catalog.jsonb_to_recordset(v_phases) AS x(id uuid, position integer, title text, planned_weeks integer)
  ON CONFLICT (id) DO UPDATE
    SET position = EXCLUDED.position, title = EXCLUDED.title, planned_weeks = EXCLUDED.planned_weeks;

  INSERT INTO public.plan_items (id, plan_id, phase_id, exercise_id, position, sets, reps, duration_sec,
    weight_kg, pause_sec, load_note, release, release_on, release_with_phase_id, easier_variant_of)
  SELECT x.id, v_plan_id, x.phase_id, x.exercise_id, x.position, x.sets, x.reps, x.duration_sec,
         x.weight_kg, x.pause_sec, x.load_note, coalesce(x.release, 'active'), x.release_on,
         x.release_with_phase_id, NULL
    FROM pg_catalog.jsonb_to_recordset(v_items) AS x(id uuid, phase_id uuid, exercise_id uuid,
         position integer, sets integer, reps integer, duration_sec integer, weight_kg numeric,
         pause_sec integer, load_note text, release text, release_on date, release_with_phase_id uuid)
  ON CONFLICT (id) DO UPDATE
    SET phase_id = EXCLUDED.phase_id, exercise_id = EXCLUDED.exercise_id, position = EXCLUDED.position,
        sets = EXCLUDED.sets, reps = EXCLUDED.reps, duration_sec = EXCLUDED.duration_sec,
        weight_kg = EXCLUDED.weight_kg, pause_sec = EXCLUDED.pause_sec, load_note = EXCLUDED.load_note,
        release = EXCLUDED.release, release_on = EXCLUDED.release_on,
        release_with_phase_id = EXCLUDED.release_with_phase_id, easier_variant_of = NULL;

  UPDATE public.plan_items pi
     SET easier_variant_of = x.easier_variant_of
    FROM pg_catalog.jsonb_to_recordset(v_items) AS x(id uuid, easier_variant_of uuid)
   WHERE pi.id = x.id AND x.easier_variant_of IS NOT NULL;

  DELETE FROM public.phases ph
   WHERE ph.plan_id = v_plan_id
     AND ph.id NOT IN (SELECT y.id FROM pg_catalog.jsonb_to_recordset(v_phases) AS y(id uuid));

  UPDATE public.plans pl
     SET current_phase_id = v_current,
         version = pl.version + 1,
         updated_at = app.utc_now(),
         updated_by = app.uid()
   WHERE pl.id = v_plan_id
  RETURNING pl.version INTO v_version;
  RETURN v_version;
END
$$;

-- ---------------------------------------------------------------------------
-- set_current_phase: Phase muss zum aktuellen Plan gehoeren; erhoeht version
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_current_phase(p_patient_id uuid, p_phase_id uuid)
RETURNS integer
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_plan_id uuid;
  v_closed  boolean;
  v_version integer;
BEGIN
  IF NOT app.physio_can_see_patient(p_patient_id) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  v_plan_id := app.current_plan_id(p_patient_id);
  IF v_plan_id IS NULL THEN
    RAISE EXCEPTION 'plan_closed' USING ERRCODE = 'P0001';
  END IF;
  SELECT pl.closed INTO v_closed FROM public.plans pl WHERE pl.id = v_plan_id FOR UPDATE;
  IF v_closed THEN
    RAISE EXCEPTION 'plan_closed' USING ERRCODE = 'P0001';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.phases ph WHERE ph.id = p_phase_id AND ph.plan_id = v_plan_id) THEN
    RAISE EXCEPTION 'foreign_id' USING ERRCODE = 'P0001';
  END IF;
  UPDATE public.plans pl
     SET current_phase_id = p_phase_id, version = pl.version + 1,
         updated_at = app.utc_now(), updated_by = app.uid()
   WHERE pl.id = v_plan_id
  RETURNING pl.version INTO v_version;
  RETURN v_version;
END
$$;

-- ---------------------------------------------------------------------------
-- delete_my_data (v1.2 4.7, 6.13)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_my_data()
RETURNS text
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid     uuid := app.uid();
  v_patient uuid;
  v_status  text;
BEGIN
  IF v_uid IS NULL OR app.current_physio_practice() IS NOT NULL
     OR EXISTS (SELECT 1 FROM public.physios ph WHERE ph.id = v_uid) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  -- wartet auf laufende Schreibvorgaenge (FOR SHARE) und blockiert neue (M-4)
  SELECT pt.id, pt.status INTO v_patient, v_status
    FROM public.patients pt WHERE pt.auth_user_id = v_uid FOR UPDATE;
  IF v_patient IS NULL OR v_status NOT IN ('active', 'deleting') THEN
    RETURN 'already_deleted';
  END IF;

  -- vom Patienten erzeugte Daten, solange der Status noch active ist (NEU-1)
  DELETE FROM public.exercise_results er WHERE er.patient_id = v_patient;
  DELETE FROM public.training_sessions ts WHERE ts.patient_id = v_patient;
  DELETE FROM public.appointments ap WHERE ap.patient_id = v_patient AND ap.created_by_role = 'patient';
  DELETE FROM public.consents c WHERE c.patient_id = v_patient;
  DELETE FROM public.account_events ae WHERE ae.patient_id = v_patient;

  -- bleibt bei der Praxis: Patientenzeile, Verletzungen, Plaene, Akte, Physio-Termine (O-9)
  UPDATE public.patients pt
     SET manny_look = NULL, auth_user_id = NULL, status = 'access_deleted'
   WHERE pt.id = v_patient;
  UPDATE public.invitations i SET revoked_at = app.utc_now()
   WHERE i.patient_id = v_patient AND i.redeemed_at IS NULL AND i.revoked_at IS NULL;

  -- Auth-Konto des Aufrufers (B-7; im echten Stack in L9 zu bestaetigen, R2-12)
  DELETE FROM auth.users u WHERE u.id = v_uid;
  RETURN 'ok';
END
$$;

-- ---------------------------------------------------------------------------
-- Manny-Look im Konto (O-41, NIT-1)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_manny_look(p_look text)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid     uuid := app.uid();
  v_patient uuid;
BEGIN
  SELECT pt.id INTO v_patient
    FROM public.patients pt
   WHERE v_uid IS NOT NULL AND pt.auth_user_id = v_uid AND pt.status = 'active'
     FOR SHARE;
  IF v_patient IS NULL THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  IF p_look IS NULL OR p_look NOT IN ('brille', 'ohne') THEN
    RAISE EXCEPTION 'invalid_manny_look' USING ERRCODE = '22023';
  END IF;
  UPDATE public.patients pt SET manny_look = p_look WHERE pt.id = v_patient;
END
$$;

-- Lesen des eigenen Looks (NIT-1: kein Spalten-Grant auf patients.manny_look)
CREATE OR REPLACE FUNCTION public.get_my_manny_look()
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_patient uuid := app.current_patient_id();
  v_look    text;
BEGIN
  IF v_patient IS NULL THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  SELECT pt.manny_look INTO v_look FROM public.patients pt WHERE pt.id = v_patient;
  RETURN v_look;
END
$$;

-- ---------------------------------------------------------------------------
-- EXECUTE nur fuer authenticated
-- ---------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION
  public.create_patient(uuid, text, text, uuid, date, text, date),
  public.regenerate_invitation(uuid),
  public.redeem_invitation(text),
  public.accept_consent(text, text),
  public.save_plan(uuid, integer, jsonb),
  public.set_current_phase(uuid, uuid),
  public.delete_my_data(),
  public.set_manny_look(text),
  public.get_my_manny_look()
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION
  public.create_patient(uuid, text, text, uuid, date, text, date),
  public.regenerate_invitation(uuid),
  public.redeem_invitation(text),
  public.accept_consent(text, text),
  public.save_plan(uuid, integer, jsonb),
  public.set_current_phase(uuid, uuid),
  public.delete_my_data(),
  public.set_manny_look(text),
  public.get_my_manny_look()
TO authenticated;
