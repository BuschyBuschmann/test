-- DB-T21 save_plan_keeps_history (Plan 12.2, M-5): Plan speichern inkl. Loeschen einer Phase laesst
-- training_sessions und exercise_results (Momentaufnahmen) unveraendert; phase_id -> NULL.
-- (session_checkup_items: ab L4.)
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT pl.id AS plan, pl.current_phase_id AS cur, (SELECT ph.id FROM public.phases ph WHERE ph.plan_id = pl.id AND ph.id <> pl.current_phase_id) AS other
  FROM public.plans pl WHERE pl.patient_id = t.id('pat_a1') \gset
\o /dev/null
CREATE TEMP TABLE before_ts AS SELECT id, items, local_day, plan_version, injury_id, plan_id FROM public.training_sessions WHERE patient_id = t.id('pat_a1');
CREATE TEMP TABLE before_er AS SELECT * FROM public.exercise_results WHERE patient_id = t.id('pat_a1');
SELECT t.ok((SELECT phase_id = :'cur'::uuid FROM public.training_sessions WHERE id = t.id('ts_pat_a1')), 'Session verweist vorher auf die aktuelle Phase');
SELECT t.ok((SELECT plan_item_id IS NOT NULL FROM public.exercise_results WHERE id = t.id('er_pat_a1')), 'Ergebnis verweist auf eine Position');
-- neuer Plan nur mit der anderen Phase (aktuelle Phase und ihre Positionen entfallen)
SELECT t.as_user(t.id('phys_a1'));
SELECT t.lives(format('SELECT public.save_plan(%L, %s, %L::jsonb)', t.id('pat_a1'), t.plan_version('pat_a1'),
  jsonb_build_object('current_phase_id', :'other'::uuid,
    'phases', jsonb_build_array(jsonb_build_object('id', :'other'::uuid, 'position', 0, 'title', 'einzige Phase', 'planned_weeks', 2)),
    'items', '[]'::jsonb)), 'Phase mit Training geloescht');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM public.phases WHERE id = :'cur'::uuid), 0::bigint, 'Phase ist geloescht');
SELECT t.is((SELECT phase_id FROM public.training_sessions WHERE id = t.id('ts_pat_a1')), NULL::uuid, 'training_sessions.phase_id -> NULL');
SELECT t.is((SELECT count(*) FROM (SELECT id, items, local_day, plan_version, injury_id, plan_id FROM public.training_sessions WHERE patient_id = t.id('pat_a1')
             EXCEPT SELECT * FROM before_ts) x), 0::bigint, 'training_sessions sonst unveraendert (Momentaufnahme items, Tag, Version)');
SELECT t.is((SELECT count(*) FROM (SELECT * FROM public.exercise_results WHERE patient_id = t.id('pat_a1') EXCEPT SELECT * FROM before_er) x), 0::bigint,
            'exercise_results unveraendert (plan_item_id bleibt als Momentaufnahme)');
SELECT t.is((SELECT count(*) FROM public.plan_items pi WHERE pi.id = (SELECT plan_item_id FROM public.exercise_results WHERE id = t.id('er_pat_a1'))), 0::bigint,
            'die referenzierte Position existiert nicht mehr, Ergebnis bleibt trotzdem');
SELECT t.is((SELECT count(*) FROM pg_constraint c WHERE c.conrelid IN ('public.training_sessions'::regclass, 'public.exercise_results'::regclass)
              AND c.contype = 'f' AND c.confrelid = 'public.plan_items'::regclass), 0::bigint, 'keine Fremdschluessel aus Verlaufstabellen auf plan_items');
