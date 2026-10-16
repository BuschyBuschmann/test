-- L2 / Migration 02: Kern-Tabellen, Constraints, Fremdschluessel (Plan 6.2)
-- Idempotent (IF NOT EXISTS bzw. Katalogpruefung). Rechte und RLS: Migration 03.
-- Kalendertage sind date (lokaler Tag des Geraets, Datumsbasis 6.7), Zeitpunkte timestamptz.

CREATE TABLE IF NOT EXISTS public.practices (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text NOT NULL CHECK (btrim(name) <> ''),
  is_test    boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.physios (
  id           uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  practice_id  uuid NOT NULL REFERENCES public.practices (id),
  display_name text NOT NULL CHECK (btrim(display_name) <> ''),
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS physios_practice_idx ON public.physios (practice_id);

CREATE TABLE IF NOT EXISTS public.patients (
  id                 uuid PRIMARY KEY,
  practice_id        uuid NOT NULL REFERENCES public.practices (id),
  first_name         text NOT NULL CHECK (btrim(first_name) <> ''),
  last_name          text CHECK (last_name IS NULL OR btrim(last_name) <> ''),
  main_physio_id     uuid REFERENCES public.physios (id) ON DELETE SET NULL,
  auth_user_id       uuid UNIQUE REFERENCES auth.users (id) ON DELETE SET NULL,
  status             text NOT NULL DEFAULT 'invited'
                       CHECK (status IN ('invited', 'active', 'deleting', 'access_deleted')),
  bound_at           timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  -- nur fuer die Idempotenzpruefung von create_patient (6.6), kein Spalten-Grant
  create_params_hash text,
  -- Manny-Look im Konto (O-41); null = nicht uebertragen; Schreiben nur ueber set_manny_look
  manny_look         text CHECK (manny_look IS NULL OR manny_look IN ('brille', 'ohne'))
);
CREATE INDEX IF NOT EXISTS patients_practice_idx ON public.patients (practice_id);

CREATE TABLE IF NOT EXISTS public.injuries (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id     uuid NOT NULL REFERENCES public.patients (id),
  label          text NOT NULL CHECK (btrim(label) <> ''),
  reference_date date NOT NULL,
  started_on     date NOT NULL,
  closed_on      date,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CHECK (closed_on IS NULL OR closed_on >= started_on),
  UNIQUE (id, patient_id)
);
-- genau eine aktive Verletzung je Patient (DB-T78)
CREATE UNIQUE INDEX IF NOT EXISTS injuries_one_active_idx
  ON public.injuries (patient_id) WHERE closed_on IS NULL;

CREATE TABLE IF NOT EXISTS public.invitations (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id      uuid NOT NULL REFERENCES public.patients (id),
  code_hmac       bytea NOT NULL UNIQUE,
  created_at      timestamptz NOT NULL DEFAULT now(),
  expires_at      timestamptz NOT NULL,
  redeemed_at     timestamptz,
  redeemed_by     uuid,
  revoked_at      timestamptz,
  failed_attempts integer NOT NULL DEFAULT 0 CHECK (failed_attempts >= 0)
);
-- hoechstens eine offene (nicht eingeloeste, nicht widerrufene) Einladung je Patient (DB-T64b)
CREATE UNIQUE INDEX IF NOT EXISTS invitations_one_open_idx
  ON public.invitations (patient_id) WHERE redeemed_at IS NULL AND revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS public.redeem_attempts (
  id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uid uuid NOT NULL,
  at  timestamptz NOT NULL,
  ok  boolean NOT NULL
);
CREATE INDEX IF NOT EXISTS redeem_attempts_uid_at_idx ON public.redeem_attempts (uid, at);

CREATE TABLE IF NOT EXISTS public.exercises (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  practice_id          uuid REFERENCES public.practices (id),  -- null = Katalog
  name                 text NOT NULL CHECK (btrim(name) <> ''),
  description          text NOT NULL CHECK (btrim(description) <> ''),
  is_example           boolean NOT NULL DEFAULT false,
  created_by           uuid,
  created_by_role      text CHECK (created_by_role IS NULL OR created_by_role IN ('physio', 'patient', 'seed')),
  default_sets         integer CHECK (default_sets IS NULL OR default_sets > 0),
  default_reps         integer CHECK (default_reps IS NULL OR default_reps > 0),
  default_duration_sec integer CHECK (default_duration_sec IS NULL OR default_duration_sec > 0),
  default_weight_kg    numeric(6,2) CHECK (default_weight_kg IS NULL OR default_weight_kg > 0),
  pause_sec            integer CHECK (pause_sec IS NULL OR pause_sec > 0),
  materials            text[] NOT NULL DEFAULT '{}',
  locations            text[] NOT NULL DEFAULT '{}'
                         CHECK (locations <@ ARRAY['home', 'practice', 'gym']::text[]),
  short_instruction    text CHECK (short_instruction IS NULL OR btrim(short_instruction) <> ''),
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  CHECK (array_position(materials, NULL) IS NULL),
  CHECK (array_position(locations, NULL) IS NULL)
);
CREATE INDEX IF NOT EXISTS exercises_practice_idx ON public.exercises (practice_id);

-- Plan je Verletzung (plans.injury_id unique); patient_id muss zur Verletzung passen
CREATE TABLE IF NOT EXISTS public.plans (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id       uuid NOT NULL REFERENCES public.patients (id),
  injury_id        uuid NOT NULL UNIQUE,
  current_phase_id uuid,
  version          integer NOT NULL DEFAULT 1 CHECK (version >= 1),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       uuid,
  closed           boolean NOT NULL DEFAULT false,
  FOREIGN KEY (injury_id, patient_id) REFERENCES public.injuries (id, patient_id),
  UNIQUE (id, patient_id)
);
CREATE INDEX IF NOT EXISTS plans_patient_idx ON public.plans (patient_id);

CREATE TABLE IF NOT EXISTS public.phases (
  id            uuid PRIMARY KEY,
  plan_id       uuid NOT NULL REFERENCES public.plans (id) ON DELETE CASCADE,
  position      integer NOT NULL CHECK (position >= 0),
  title         text NOT NULL CHECK (btrim(title) <> ''),
  planned_weeks integer NOT NULL CHECK (planned_weeks BETWEEN 1 AND 52),
  UNIQUE (id, plan_id)
);
CREATE INDEX IF NOT EXISTS phases_plan_idx ON public.phases (plan_id);

-- aktuelle Phase: muss eine Phase desselben Plans sein; beim Loeschen der Phase NULL
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plans_current_phase_fk') THEN
    ALTER TABLE public.plans ADD CONSTRAINT plans_current_phase_fk
      FOREIGN KEY (current_phase_id, id) REFERENCES public.phases (id, plan_id)
      ON DELETE SET NULL (current_phase_id);
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS public.plan_items (
  id                    uuid PRIMARY KEY,
  plan_id               uuid NOT NULL,
  phase_id              uuid NOT NULL,
  exercise_id           uuid NOT NULL REFERENCES public.exercises (id) ON DELETE RESTRICT,
  position              integer NOT NULL CHECK (position >= 0),
  sets                  integer CHECK (sets IS NULL OR sets > 0),
  reps                  integer CHECK (reps IS NULL OR reps > 0),
  duration_sec          integer CHECK (duration_sec IS NULL OR duration_sec > 0),  -- Dauer je Satz (O-17)
  weight_kg             numeric(6,2) CHECK (weight_kg IS NULL OR weight_kg > 0),
  pause_sec             integer CHECK (pause_sec IS NULL OR pause_sec > 0),
  load_note             text,
  release               text NOT NULL DEFAULT 'active' CHECK (release IN ('active', 'prepared')),
  release_on            date,
  release_with_phase_id uuid,
  easier_variant_of     uuid,  -- E-30: leichtere Variante, Position derselben Phase
  CHECK (
    (release = 'active' AND release_on IS NULL AND release_with_phase_id IS NULL)
    OR (release = 'prepared' AND num_nonnulls(release_on, release_with_phase_id) = 1)
  ),
  CHECK (easier_variant_of IS NULL OR easier_variant_of <> id),
  UNIQUE (id, phase_id),
  FOREIGN KEY (phase_id, plan_id) REFERENCES public.phases (id, plan_id) ON DELETE CASCADE,
  FOREIGN KEY (release_with_phase_id, plan_id) REFERENCES public.phases (id, plan_id),
  FOREIGN KEY (easier_variant_of, phase_id) REFERENCES public.plan_items (id, phase_id)
    ON DELETE SET NULL (easier_variant_of)
);
CREATE INDEX IF NOT EXISTS plan_items_plan_idx ON public.plan_items (plan_id);
CREATE INDEX IF NOT EXISTS plan_items_exercise_idx ON public.plan_items (exercise_id);

-- Akte (unveraendert aus v1.2)
CREATE TABLE IF NOT EXISTS public.treaters (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES public.patients (id),
  role       text NOT NULL CHECK (btrim(role) <> ''),
  name       text NOT NULL CHECK (btrim(name) <> ''),
  phone      text,
  email      text,
  address    text,
  note       text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, patient_id)
);
CREATE INDEX IF NOT EXISTS treaters_patient_idx ON public.treaters (patient_id);

CREATE TABLE IF NOT EXISTS public.appointments (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id      uuid NOT NULL REFERENCES public.patients (id),
  treater_id      uuid,
  starts_at       timestamptz NOT NULL,
  title           text NOT NULL CHECK (btrim(title) <> ''),
  location        text,
  created_by_role text NOT NULL CHECK (created_by_role IN ('physio', 'patient', 'seed')),
  created_by      uuid,
  created_at      timestamptz NOT NULL DEFAULT now(),
  -- Behandler muss zum selben Patienten gehoeren
  FOREIGN KEY (treater_id, patient_id) REFERENCES public.treaters (id, patient_id)
    ON DELETE SET NULL (treater_id)
);
CREATE INDEX IF NOT EXISTS appointments_patient_idx ON public.appointments (patient_id);

CREATE TABLE IF NOT EXISTS public.history_entries (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id  uuid NOT NULL REFERENCES public.patients (id),
  kind        text NOT NULL CHECK (btrim(kind) <> ''),
  title       text NOT NULL CHECK (btrim(title) <> ''),
  occurred_on date,
  note        text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS history_entries_patient_idx ON public.history_entries (patient_id);

CREATE TABLE IF NOT EXISTS public.consents (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id  uuid NOT NULL REFERENCES public.patients (id),
  kind        text NOT NULL CHECK (kind ~ '^[a-z_]{1,40}$'),
  version     text NOT NULL CHECK (version ~ '^[a-z0-9_.-]{1,40}$'),
  accepted_at timestamptz NOT NULL DEFAULT now(),
  revoked_at  timestamptz
);
CREATE INDEX IF NOT EXISTS consents_patient_idx ON public.consents (patient_id);

CREATE TABLE IF NOT EXISTS public.account_events (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES public.patients (id),
  kind       text NOT NULL CHECK (kind IN ('bound', 'rebound')),
  at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS account_events_patient_idx ON public.account_events (patient_id);
