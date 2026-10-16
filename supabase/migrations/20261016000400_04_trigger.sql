-- L2 / Migration 04: Trigger-Funktionen created_by, injury_id, Schreibsperre (Plan 6.3). Idempotent.
-- Trigger-Namen mit Praefix tNN_, weil Postgres BEFORE-Trigger alphabetisch ausfuehrt:
-- t10 Schreibsperre, t20 injury_id, t30 created_by.

-- Vertrauenswuerdige Sitzung ohne Patienten-/Physio-JWT: Seed mit service_role (JWT-Rolle) oder
-- eine direkte Datenbanksitzung (Migrationsrolle, SQL-Konsole). API-Anfragen laufen immer mit
-- der Sitzungsrolle anon bzw. authenticated (PostgREST setzt role), sind also nie privilegiert.
-- Nur fuer Trigger, kein EXECUTE fuer API-Rollen.
CREATE OR REPLACE FUNCTION app.is_privileged_session() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT coalesce(auth.role() = 'service_role', false)
      OR coalesce(pg_catalog.current_setting('role', true), 'none') NOT IN ('anon', 'authenticated')
$$;
REVOKE EXECUTE ON FUNCTION app.is_privileged_session() FROM PUBLIC, anon, authenticated;

-- created_by / created_by_role serverseitig (m-3, DB-T16)
CREATE OR REPLACE FUNCTION app.set_created_by() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF app.is_privileged_session() THEN
    -- Seed: Werte wie geliefert, Rolle mindestens 'seed'
    NEW.created_by_role := coalesce(NEW.created_by_role, 'seed');
    RETURN NEW;
  END IF;
  NEW.created_by := app.uid();
  IF app.current_physio_practice() IS NOT NULL THEN
    NEW.created_by_role := 'physio';
  ELSIF app.current_patient_id() IS NOT NULL THEN
    NEW.created_by_role := 'patient';
  ELSE
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END
$$;

-- Schreibsperre fuer Schreibvorgaenge im Namen des Patienten (v1.2 4.3, NEU-1/NEU-2, DB-T70)
CREATE OR REPLACE FUNCTION app.lock_patient_for_write() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_row     jsonb;
  v_patient uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_row := pg_catalog.to_jsonb(OLD);
  ELSE
    v_row := pg_catalog.to_jsonb(NEW);
  END IF;

  -- Physio-Sitzungen und Seed sind ausgenommen (NEU-2)
  IF app.is_privileged_session() OR app.current_physio_practice() IS NOT NULL THEN
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
  END IF;

  v_patient := (v_row ->> 'patient_id')::uuid;

  IF TG_OP = 'DELETE' THEN
    PERFORM 1 FROM public.patients pt
     WHERE pt.id = v_patient AND pt.status IN ('active', 'deleting')
       FOR SHARE;
  ELSE
    PERFORM 1 FROM public.patients pt
     WHERE pt.id = v_patient AND pt.status = 'active'
       FOR SHARE;
  END IF;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'patient_not_active' USING ERRCODE = '42501';
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$$;

-- injury_id serverseitig; Client-Werte werden immer ueberschrieben (DB-T61, MINOR-4, MINOR-D)
CREATE OR REPLACE FUNCTION app.set_injury_id() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_injury  uuid;
  v_patient uuid;
BEGIN
  IF TG_TABLE_NAME = 'training_sessions' THEN
    -- Verletzung des mitgesendeten Plans; der Plan muss diesem Patienten gehoeren
    SELECT pl.injury_id, pl.patient_id INTO v_injury, v_patient
      FROM public.plans pl WHERE pl.id = NEW.plan_id;
    IF NOT FOUND OR v_patient IS DISTINCT FROM NEW.patient_id THEN
      RAISE EXCEPTION 'foreign_plan' USING ERRCODE = '42501';
    END IF;
  ELSIF TG_TABLE_NAME IN ('exercise_results', 'session_checkups') THEN
    -- Verletzung der referenzierten Session; Session muss demselben Patienten gehoeren
    SELECT ts.injury_id, ts.patient_id INTO v_injury, v_patient
      FROM public.training_sessions ts WHERE ts.id = NEW.training_session_id;
    IF NOT FOUND OR v_patient IS DISTINCT FROM NEW.patient_id THEN
      RAISE EXCEPTION 'foreign_training_session' USING ERRCODE = '42501';
    END IF;
  ELSE
    -- Tageseintraege (ab L5/L7): zentrale Herleitung, spaeter nach local_day (MINOR-G)
    v_injury := app.injury_for_patient_day(NEW.patient_id, NEW.local_day);
    IF v_injury IS NULL THEN
      RAISE EXCEPTION 'no_active_injury' USING ERRCODE = '42501';
    END IF;
  END IF;
  NEW.injury_id := v_injury;
  RETURN NEW;
END
$$;

REVOKE EXECUTE ON FUNCTION app.set_created_by(), app.lock_patient_for_write(), app.set_injury_id()
  FROM PUBLIC, anon, authenticated;

-- Trigger auf Tabellen aus Migration 02 (Training: Migration 06, Vorlagen: Migration 07)
DROP TRIGGER IF EXISTS t10_lock_patient_for_write ON public.appointments;
CREATE TRIGGER t10_lock_patient_for_write
  BEFORE INSERT OR UPDATE OR DELETE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION app.lock_patient_for_write();
DROP TRIGGER IF EXISTS t30_set_created_by ON public.appointments;
CREATE TRIGGER t30_set_created_by
  BEFORE INSERT ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION app.set_created_by();

DROP TRIGGER IF EXISTS t10_lock_patient_for_write ON public.consents;
CREATE TRIGGER t10_lock_patient_for_write
  BEFORE INSERT OR UPDATE OR DELETE ON public.consents
  FOR EACH ROW EXECUTE FUNCTION app.lock_patient_for_write();

DROP TRIGGER IF EXISTS t30_set_created_by ON public.exercises;
CREATE TRIGGER t30_set_created_by
  BEFORE INSERT ON public.exercises
  FOR EACH ROW EXECUTE FUNCTION app.set_created_by();
