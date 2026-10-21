-- L2 / Migration 06: training_sessions (alle Spalten inkl. mode, plan_id; MINOR-3), exercise_results
-- (Plan 6.2, 6.3). Idempotent.
-- Pflichtliste 6.14 je Tabelle: RLS + Grants (DB-T01), Praxis-Isolation (DB-T06), Patient nur
-- selbst (DB-T08), anonym nichts (DB-T04), Schreibsperre (DB-T70), Loeschumfang (DB-T71),
-- injury_id serverseitig (DB-T61).

CREATE TABLE IF NOT EXISTS public.training_sessions (
  id             uuid PRIMARY KEY,                       -- Geraete-ID
  patient_id     uuid NOT NULL REFERENCES public.patients (id),
  injury_id      uuid NOT NULL REFERENCES public.injuries (id),  -- Trigger, aus plan_id
  plan_id        uuid NOT NULL,                          -- Plan der Momentaufnahme (auch abgeschlossen)
  local_day      date NOT NULL,                          -- lokaler Tag des Geraets (6.7)
  logged_at      timestamptz NOT NULL DEFAULT now(),
  phase_id       uuid,
  plan_version   integer CHECK (plan_version IS NULL OR plan_version >= 1),
  items          jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(items) = 'array'),  -- Momentaufnahme, kein FK
  mode           text NOT NULL CHECK (mode IN ('guided', 'checklist')),
  started_at     timestamptz,
  ended_at       timestamptz,
  active_seconds integer CHECK (active_seconds IS NULL OR active_seconds >= 0),
  ended_early    boolean,
  streak_after   integer CHECK (streak_after IS NULL OR streak_after >= 0),  -- vom Geraet (B-25)
  CHECK (ended_at IS NULL OR started_at IS NULL OR ended_at >= started_at),
  FOREIGN KEY (plan_id, patient_id) REFERENCES public.plans (id, patient_id),
  -- Phase des Plans; beim Loeschen der Phase NULL (Verlauf bleibt, DB-T21)
  FOREIGN KEY (phase_id, plan_id) REFERENCES public.phases (id, plan_id) ON DELETE SET NULL (phase_id),
  UNIQUE (id, patient_id)
);
CREATE INDEX IF NOT EXISTS training_sessions_patient_day_idx ON public.training_sessions (patient_id, local_day);
CREATE INDEX IF NOT EXISTS training_sessions_injury_idx ON public.training_sessions (injury_id);

CREATE TABLE IF NOT EXISTS public.exercise_results (
  id                  uuid PRIMARY KEY,                  -- Geraete-ID
  patient_id          uuid NOT NULL REFERENCES public.patients (id),
  injury_id           uuid NOT NULL REFERENCES public.injuries (id),  -- Trigger, aus der Session
  training_session_id uuid NOT NULL REFERENCES public.training_sessions (id) ON DELETE CASCADE,
  local_day           date NOT NULL,
  plan_item_id        uuid,                              -- Momentaufnahme, kein FK
  exercise_id         uuid,                              -- Momentaufnahme, kein FK
  exercise_name       text,                              -- Momentaufnahme
  status              text NOT NULL CHECK (status IN ('done', 'skipped')),
  sets_done           integer CHECK (sets_done IS NULL OR sets_done >= 0),
  reps_done           integer CHECK (reps_done IS NULL OR reps_done >= 0),
  logged_at           timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS exercise_results_patient_day_idx ON public.exercise_results (patient_id, local_day);
CREATE INDEX IF NOT EXISTS exercise_results_session_idx ON public.exercise_results (training_session_id);

ALTER TABLE public.training_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_results  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.training_sessions, public.exercise_results FROM anon, authenticated;
-- INSERT ganze Zeile (injury_id wird vom Trigger ueberschrieben); UPDATE nur Ende-Spalten
GRANT SELECT, INSERT, DELETE ON public.training_sessions TO authenticated;
GRANT UPDATE (ended_at, active_seconds, ended_early, streak_after) ON public.training_sessions TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.exercise_results TO authenticated;

DROP POLICY IF EXISTS training_sessions_select ON public.training_sessions;
CREATE POLICY training_sessions_select ON public.training_sessions FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(patient_id) OR patient_id = app.current_patient_id());
DROP POLICY IF EXISTS training_sessions_insert_patient ON public.training_sessions;
CREATE POLICY training_sessions_insert_patient ON public.training_sessions FOR INSERT TO authenticated
  WITH CHECK (patient_id = app.current_patient_id());
DROP POLICY IF EXISTS training_sessions_update_patient ON public.training_sessions;
CREATE POLICY training_sessions_update_patient ON public.training_sessions FOR UPDATE TO authenticated
  USING (patient_id = app.current_patient_id())
  WITH CHECK (patient_id = app.current_patient_id());
DROP POLICY IF EXISTS training_sessions_delete_patient ON public.training_sessions;
CREATE POLICY training_sessions_delete_patient ON public.training_sessions FOR DELETE TO authenticated
  USING (patient_id = app.current_patient_id());

DROP POLICY IF EXISTS exercise_results_select ON public.exercise_results;
CREATE POLICY exercise_results_select ON public.exercise_results FOR SELECT TO authenticated
  USING (app.physio_can_see_patient(patient_id) OR patient_id = app.current_patient_id());
DROP POLICY IF EXISTS exercise_results_insert_patient ON public.exercise_results;
CREATE POLICY exercise_results_insert_patient ON public.exercise_results FOR INSERT TO authenticated
  WITH CHECK (patient_id = app.current_patient_id());
DROP POLICY IF EXISTS exercise_results_delete_patient ON public.exercise_results;
CREATE POLICY exercise_results_delete_patient ON public.exercise_results FOR DELETE TO authenticated
  USING (patient_id = app.current_patient_id());

-- Trigger: t10 Schreibsperre, t20 injury_id
DROP TRIGGER IF EXISTS t10_lock_patient_for_write ON public.training_sessions;
CREATE TRIGGER t10_lock_patient_for_write
  BEFORE INSERT OR UPDATE OR DELETE ON public.training_sessions
  FOR EACH ROW EXECUTE FUNCTION app.lock_patient_for_write();
DROP TRIGGER IF EXISTS t20_set_injury_id ON public.training_sessions;
CREATE TRIGGER t20_set_injury_id
  BEFORE INSERT ON public.training_sessions
  FOR EACH ROW EXECUTE FUNCTION app.set_injury_id();

DROP TRIGGER IF EXISTS t10_lock_patient_for_write ON public.exercise_results;
CREATE TRIGGER t10_lock_patient_for_write
  BEFORE INSERT OR UPDATE OR DELETE ON public.exercise_results
  FOR EACH ROW EXECUTE FUNCTION app.lock_patient_for_write();
DROP TRIGGER IF EXISTS t20_set_injury_id ON public.exercise_results;
CREATE TRIGGER t20_set_injury_id
  BEFORE INSERT ON public.exercise_results
  FOR EACH ROW EXECUTE FUNCTION app.set_injury_id();
