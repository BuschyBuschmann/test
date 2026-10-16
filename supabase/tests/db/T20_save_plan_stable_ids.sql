-- DB-T20 save_plan_stable_ids (Plan 12.2, M-5, 6.7): unveraenderte Positionen behalten ihre ID,
-- nur Entferntes wird geloescht, Upsert nach ID, Version +1.
\set ON_ERROR_STOP 1
\o /dev/null
\ir _plan_base.psql
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(t.save_plan('pat_a2', :'base'), 2, 'erstes Speichern -> Version 2');
SELECT t.is((SELECT count(*) FROM public.plan_items pi WHERE pi.plan_id = app.current_plan_id(t.id('pat_a2'))), 3::bigint, '3 Positionen');
SELECT t.is((SELECT current_phase_id FROM public.plans WHERE patient_id = t.id('pat_a2')), t.id('ph1'), 'aktuelle Phase gesetzt');
-- it2 entfernen, it1 aendern, it4 neu, Phase 2 umbenennen
SELECT t.is(t.save_plan('pat_a2',
  '{"current_phase_id":"{{ph1}}","phases":[{"id":"{{ph1}}","position":0,"title":"Phase 1","planned_weeks":2},{"id":"{{ph2}}","position":1,"title":"Phase 2 neu","planned_weeks":4}],"items":[{"id":"{{it1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0,"sets":4,"reps":8},{"id":"{{it4}}","phase_id":"{{ph1}}","exercise_id":"{{ex_a1}}","position":1,"sets":1},{"id":"{{it3}}","phase_id":"{{ph2}}","exercise_id":"{{ex_a1}}","position":0,"duration_sec":30}]}'),
  3, 'zweites Speichern -> Version 3');
SELECT t.is((SELECT string_agg(id::text, ',' ORDER BY id) FROM public.plan_items WHERE plan_id = app.current_plan_id(t.id('pat_a2'))),
            (SELECT string_agg(x::text, ',' ORDER BY x) FROM unnest(ARRAY[t.id('it1'), t.id('it3'), t.id('it4')]) x),
            'IDs it1, it3 behalten, it2 entfernt, it4 neu');
SELECT t.is((SELECT sets FROM public.plan_items WHERE id = t.id('it1')), 4, 'it1 aktualisiert (Upsert nach ID)');
SELECT t.is((SELECT title || '/' || planned_weeks FROM public.phases WHERE id = t.id('ph2')), 'Phase 2 neu/4', 'Phase aktualisiert, gleiche ID');
SELECT t.is((SELECT updated_by FROM public.plans WHERE patient_id = t.id('pat_a2')), t.id('phys_a1'), 'updated_by = Aufrufer');
-- gleicher Payload erneut: nur Version steigt, IDs gleich
SELECT t.is(t.save_plan('pat_a2', :'base'), 4, 'drittes Speichern -> Version 4');
SELECT t.is((SELECT count(*) FROM public.plan_items WHERE id IN (t.id('it1'), t.id('it2'), t.id('it3'))), 3::bigint, 'Positionen wieder wie im Basis-Payload');
