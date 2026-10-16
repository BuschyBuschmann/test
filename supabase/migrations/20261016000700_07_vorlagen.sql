-- L2 / Migration 07: plan_templates (Plan 6.2, 6.6; O-25: UI zum Speichern eigener Vorlagen offen)
-- Idempotent. payload-Format siehe app.copy_template_into_plan (Migration 05).

CREATE TABLE IF NOT EXISTS public.plan_templates (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  practice_id     uuid REFERENCES public.practices (id),  -- null = CuraOne-Beispiel
  name            text NOT NULL CHECK (btrim(name) <> ''),
  injury_label    text CHECK (injury_label IS NULL OR btrim(injury_label) <> ''),
  is_example      boolean NOT NULL DEFAULT false,
  payload         jsonb NOT NULL DEFAULT '{"phases": []}'::jsonb
                    CHECK (jsonb_typeof(payload -> 'phases') = 'array'),
  created_by      uuid,
  created_by_role text CHECK (created_by_role IS NULL OR created_by_role IN ('physio', 'patient', 'seed')),
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS plan_templates_practice_idx ON public.plan_templates (practice_id);

ALTER TABLE public.plan_templates ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.plan_templates FROM anon, authenticated;
GRANT SELECT, INSERT, DELETE ON public.plan_templates TO authenticated;
GRANT UPDATE (name, injury_label, payload) ON public.plan_templates TO authenticated;

-- Physio: Beispiele + eigene Praxis lesen, nur eigene schreiben (DB-T76). Patient: nichts.
DROP POLICY IF EXISTS plan_templates_select_physio ON public.plan_templates;
CREATE POLICY plan_templates_select_physio ON public.plan_templates FOR SELECT TO authenticated
  USING (
    (practice_id IS NULL AND app.current_physio_practice() IS NOT NULL)
    OR practice_id = app.current_physio_practice()
  );
DROP POLICY IF EXISTS plan_templates_insert_physio ON public.plan_templates;
CREATE POLICY plan_templates_insert_physio ON public.plan_templates FOR INSERT TO authenticated
  WITH CHECK (practice_id = app.current_physio_practice());
DROP POLICY IF EXISTS plan_templates_update_physio ON public.plan_templates;
CREATE POLICY plan_templates_update_physio ON public.plan_templates FOR UPDATE TO authenticated
  USING (practice_id = app.current_physio_practice())
  WITH CHECK (practice_id = app.current_physio_practice());
DROP POLICY IF EXISTS plan_templates_delete_physio ON public.plan_templates;
CREATE POLICY plan_templates_delete_physio ON public.plan_templates FOR DELETE TO authenticated
  USING (practice_id = app.current_physio_practice());

DROP TRIGGER IF EXISTS t30_set_created_by ON public.plan_templates;
CREATE TRIGGER t30_set_created_by
  BEFORE INSERT ON public.plan_templates
  FOR EACH ROW EXECUTE FUNCTION app.set_created_by();
