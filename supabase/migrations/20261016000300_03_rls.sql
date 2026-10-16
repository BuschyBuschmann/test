-- L2 / Migration 03: RLS (ENABLE, nie FORCE; M-1), Hilfsfunktionen, Policies, Spalten-Grants
-- (Plan 6.1 Nr. 1-5, 6.2). Idempotent.
--
-- Hilfsfunktionen: SECURITY DEFINER, STABLE, SET search_path = '', voll qualifiziert.
-- Aufruferpruefung (MINOR-9, MAJOR-A): Funktionen mit Patienten-Parameter verraten fuer
-- fremde Patienten nichts. app.active_injury_id_internal ist die ungepruefte Variante nur
-- fuer Trigger und bereits gepruefte Definer-Funktionen (MINOR-C), ohne EXECUTE fuer API-Rollen.

-- ---------------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION app.uid() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT auth.uid()
$$;

CREATE OR REPLACE FUNCTION app.is_anonymous() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
$$;

CREATE OR REPLACE FUNCTION app.current_physio_practice() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT ph.practice_id
  FROM public.physios ph
  WHERE ph.id = app.uid()
    AND NOT app.is_anonymous()
$$;

-- gebundener Patient mit Status active
CREATE OR REPLACE FUNCTION app.current_patient_id() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT pt.id
  FROM public.patients pt
  WHERE pt.auth_user_id = app.uid()
    AND pt.status = 'active'
$$;

-- nur Physios der Praxis des Patienten; keine Patientenklausel, kein Selbstbezug (MAJOR-A)
CREATE OR REPLACE FUNCTION app.physio_can_see_patient(p uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.patients pt
    WHERE pt.id = p
      AND pt.practice_id = app.current_physio_practice()
  )
$$;

-- intern, ohne Aufruferpruefung (MINOR-C): aktive Verletzung
CREATE OR REPLACE FUNCTION app.active_injury_id_internal(p uuid) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT i.id
  FROM public.injuries i
  WHERE i.patient_id = p
    AND i.closed_on IS NULL
$$;

-- intern: Verletzung fuer einen Tageseintrag (Tages-Check-up, Fragen, Notizen ab L5/L7).
-- Heute (B-32): aktive Verletzung beim Eingang; p_local_day wird noch nicht verwendet.
-- Auflage MINOR-G (vor L5): hier auf "an p_local_day aktive Verletzung"
-- (injuries.started_on/closed_on) umstellen; alle Trigger nutzen nur diese Funktion.
CREATE OR REPLACE FUNCTION app.injury_for_patient_day(p uuid, p_local_day date) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT app.active_injury_id_internal(p)
$$;

CREATE OR REPLACE FUNCTION app.current_injury_id(p uuid) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT CASE
           WHEN p = app.current_patient_id() OR app.physio_can_see_patient(p)
             THEN app.active_injury_id_internal(p)
         END
$$;

CREATE OR REPLACE FUNCTION app.current_plan_id(p uuid) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT pl.id
  FROM public.plans pl
  WHERE pl.injury_id = app.current_injury_id(p)
$$;

-- Uebung steht in irgendeiner Position (aktiv oder vorbereitet) des aktuellen Plans des
-- aufrufenden Patienten; ohne Datumsbezug (6.7 Nr. 2, N-16)
CREATE OR REPLACE FUNCTION app.patient_can_see_exercise(e uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.plan_items pi
    WHERE pi.exercise_id = e
      AND pi.plan_id = app.current_plan_id(app.current_patient_id())
  )
$$;

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA app FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION
  app.uid(),
  app.is_anonymous(),
  app.current_physio_practice(),
  app.current_patient_id(),
  app.physio_can_see_patient(uuid),
  app.current_injury_id(uuid),
  app.current_plan_id(uuid),
  app.patient_can_see_exercise(uuid)
TO authenticated;

-- ---------------------------------------------------------------------------
-- RLS einschalten (ENABLE, nicht FORCE)
-- ---------------------------------------------------------------------------

ALTER TABLE app.secrets             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practices        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.physios          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.injuries         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.redeem_attempts  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phases           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_items       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treaters         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.history_entries  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consents         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_events   ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- Grants (nur authenticated; anon bekommt nichts). Standardrechte entzieht Migration 01.
-- ---------------------------------------------------------------------------

REVOKE ALL ON public.practices, public.physios, public.patients, public.injuries,
  public.invitations, public.redeem_attempts, public.exercises, public.plans, public.phases,
  public.plan_items, public.treaters, public.appointments, public.history_entries,
  public.consents, public.account_events
FROM anon, authenticated;

GRANT SELECT ON public.practices TO authenticated;
GRANT SELECT ON public.physios TO authenticated;
-- patients: ohne auth_user_id, create_params_hash und manny_look (NIT-1: kein Leserecht
-- des Physios; der Patient liest seinen Look ueber get_my_manny_look())
GRANT SELECT (id, practice_id, first_name, last_name, main_physio_id, status, bound_at, created_at)
  ON public.patients TO authenticated;
GRANT UPDATE (first_name, last_name) ON public.patients TO authenticated;
GRANT SELECT ON public.injuries TO authenticated;
GRANT UPDATE (label, reference_date) ON public.injuries TO authenticated;
-- invitations: ohne code_hmac und redeemed_by (M-2)
GRANT SELECT (id, patient_id, created_at, expires_at, redeemed_at, revoked_at, failed_attempts)
  ON public.invitations TO authenticated;
-- code_hmac fuer keine API-Rolle lesbar (DB-T09), auch nicht fuer service_role (Seed)
REVOKE SELECT ON public.invitations FROM service_role;
GRANT SELECT (id, patient_id, created_at, expires_at, redeemed_at, redeemed_by, revoked_at, failed_attempts)
  ON public.invitations TO service_role;
GRANT SELECT, INSERT, DELETE ON public.exercises TO authenticated;
GRANT UPDATE (name, description, default_sets, default_reps, default_duration_sec,
  default_weight_kg, pause_sec, materials, locations, short_instruction, updated_at)
  ON public.exercises TO authenticated;
GRANT SELECT ON public.plans, public.phases, public.plan_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.treaters TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.appointments TO authenticated;
GRANT UPDATE (treater_id, starts_at, title, location) ON public.appointments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.history_entries TO authenticated;
GRANT SELECT ON public.consents TO authenticated;
GRANT SELECT ON public.account_events TO authenticated;

-- ---------------------------------------------------------------------------
-- Policies (alle TO authenticated)
-- ---------------------------------------------------------------------------

-- practices: Physio eigene Praxis
DROP POLICY IF EXISTS practices_select ON public.practices;
CREATE POLICY practices_select ON public.practices FOR SELECT TO authenticated
  USING (id = app.current_physio_practice());

-- physios: gleiche Praxis
DROP POLICY IF EXISTS physios_select ON public.physios;
CREATE POLICY physios_select ON public.physios FOR SELECT TO authenticated
  USING (practice_id = app.current_physio_practice());

-- patients: Physio der Praxis; Patient eigene Zeile
DROP POLICY IF EXISTS patients_select ON public.patients;
CREATE POLICY patients_select ON public.patients FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(id) OR id = app.current_patient_id());
DROP POLICY IF EXISTS patients_update_physio ON public.patients;
CREATE POLICY patients_update_physio ON public.patients FOR UPDATE TO authenticated
  USING (app.physio_can_see_patient(id))
  WITH CHECK (app.physio_can_see_patient(id));

-- injuries
DROP POLICY IF EXISTS injuries_select ON public.injuries;
CREATE POLICY injuries_select ON public.injuries FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(patient_id) OR patient_id = app.current_patient_id());
DROP POLICY IF EXISTS injuries_update_physio ON public.injuries;
CREATE POLICY injuries_update_physio ON public.injuries FOR UPDATE TO authenticated
  USING (app.physio_can_see_patient(patient_id))
  WITH CHECK (app.physio_can_see_patient(patient_id));

-- invitations: nur Physio der Praxis (Spalten-Grant ohne code_hmac)
DROP POLICY IF EXISTS invitations_select_physio ON public.invitations;
CREATE POLICY invitations_select_physio ON public.invitations FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(patient_id));

-- redeem_attempts: keine Policy (nur redeem_invitation)

-- exercises: Physio Katalog + eigene Praxis; Patient nur Uebungen seines aktuellen Plans
DROP POLICY IF EXISTS exercises_select ON public.exercises;
CREATE POLICY exercises_select ON public.exercises FOR SELECT TO authenticated
  USING (
    (practice_id IS NULL AND app.current_physio_practice() IS NOT NULL)
    OR practice_id = app.current_physio_practice()
    OR app.patient_can_see_exercise(id)
  );
DROP POLICY IF EXISTS exercises_insert_physio ON public.exercises;
CREATE POLICY exercises_insert_physio ON public.exercises FOR INSERT TO authenticated
  WITH CHECK (practice_id = app.current_physio_practice());
DROP POLICY IF EXISTS exercises_update_physio ON public.exercises;
CREATE POLICY exercises_update_physio ON public.exercises FOR UPDATE TO authenticated
  USING (practice_id = app.current_physio_practice())
  WITH CHECK (practice_id = app.current_physio_practice());
DROP POLICY IF EXISTS exercises_delete_physio ON public.exercises;
CREATE POLICY exercises_delete_physio ON public.exercises FOR DELETE TO authenticated
  USING (practice_id = app.current_physio_practice());

-- plans, phases, plan_items: lesen (Physio der Praxis; Patient alle eigenen, auch abgeschlossene)
DROP POLICY IF EXISTS plans_select ON public.plans;
CREATE POLICY plans_select ON public.plans FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(patient_id) OR patient_id = app.current_patient_id());
DROP POLICY IF EXISTS phases_select ON public.phases;
CREATE POLICY phases_select ON public.phases FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.plans pl WHERE pl.id = phases.plan_id));
DROP POLICY IF EXISTS plan_items_select ON public.plan_items;
CREATE POLICY plan_items_select ON public.plan_items FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.plans pl WHERE pl.id = plan_items.plan_id));

-- treaters, history_entries: beide lesen, Physio pflegt
DROP POLICY IF EXISTS treaters_select ON public.treaters;
CREATE POLICY treaters_select ON public.treaters FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(patient_id) OR patient_id = app.current_patient_id());
DROP POLICY IF EXISTS treaters_insert_physio ON public.treaters;
CREATE POLICY treaters_insert_physio ON public.treaters FOR INSERT TO authenticated
  WITH CHECK (app.physio_can_see_patient(patient_id));
DROP POLICY IF EXISTS treaters_update_physio ON public.treaters;
CREATE POLICY treaters_update_physio ON public.treaters FOR UPDATE TO authenticated
  USING (app.physio_can_see_patient(patient_id))
  WITH CHECK (app.physio_can_see_patient(patient_id));
DROP POLICY IF EXISTS treaters_delete_physio ON public.treaters;
CREATE POLICY treaters_delete_physio ON public.treaters FOR DELETE TO authenticated
  USING (app.physio_can_see_patient(patient_id));

DROP POLICY IF EXISTS history_entries_select ON public.history_entries;
CREATE POLICY history_entries_select ON public.history_entries FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(patient_id) OR patient_id = app.current_patient_id());
DROP POLICY IF EXISTS history_entries_insert_physio ON public.history_entries;
CREATE POLICY history_entries_insert_physio ON public.history_entries FOR INSERT TO authenticated
  WITH CHECK (app.physio_can_see_patient(patient_id));
DROP POLICY IF EXISTS history_entries_update_physio ON public.history_entries;
CREATE POLICY history_entries_update_physio ON public.history_entries FOR UPDATE TO authenticated
  USING (app.physio_can_see_patient(patient_id))
  WITH CHECK (app.physio_can_see_patient(patient_id));
DROP POLICY IF EXISTS history_entries_delete_physio ON public.history_entries;
CREATE POLICY history_entries_delete_physio ON public.history_entries FOR DELETE TO authenticated
  USING (app.physio_can_see_patient(patient_id));

-- appointments: beide lesen; je Seite nur eigene schreiben.
-- Physio: selbst angelegte (created_by = Aufrufer). Patient: vom Patienten angelegte Termine
-- des eigenen Patienten (created_by_role = 'patient'), damit sie eine Neubindung ueberstehen.
-- created_by/created_by_role setzt der Trigger serverseitig (Migration 04).
DROP POLICY IF EXISTS appointments_select ON public.appointments;
CREATE POLICY appointments_select ON public.appointments FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(patient_id) OR patient_id = app.current_patient_id());
DROP POLICY IF EXISTS appointments_insert ON public.appointments;
CREATE POLICY appointments_insert ON public.appointments FOR INSERT TO authenticated
  WITH CHECK (
    (created_by_role = 'physio' AND app.physio_can_see_patient(patient_id))
    OR (created_by_role = 'patient' AND patient_id = app.current_patient_id())
  );
DROP POLICY IF EXISTS appointments_update ON public.appointments;
CREATE POLICY appointments_update ON public.appointments FOR UPDATE TO authenticated
  USING (
    (created_by_role = 'physio' AND created_by = app.uid() AND app.physio_can_see_patient(patient_id))
    OR (created_by_role = 'patient' AND patient_id = app.current_patient_id())
  )
  WITH CHECK (
    (created_by_role = 'physio' AND created_by = app.uid() AND app.physio_can_see_patient(patient_id))
    OR (created_by_role = 'patient' AND patient_id = app.current_patient_id())
  );
DROP POLICY IF EXISTS appointments_delete ON public.appointments;
CREATE POLICY appointments_delete ON public.appointments FOR DELETE TO authenticated
  USING (
    (created_by_role = 'physio' AND created_by = app.uid() AND app.physio_can_see_patient(patient_id))
    OR (created_by_role = 'patient' AND patient_id = app.current_patient_id())
  );

-- consents: beide lesen; schreiben nur accept_consent
DROP POLICY IF EXISTS consents_select ON public.consents;
CREATE POLICY consents_select ON public.consents FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(patient_id) OR patient_id = app.current_patient_id());

-- account_events: nur Patient
DROP POLICY IF EXISTS account_events_select ON public.account_events;
CREATE POLICY account_events_select ON public.account_events FOR SELECT TO authenticated
  USING (patient_id = app.current_patient_id());
