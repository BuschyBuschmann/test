-- DB-T65 plan_item_release (Plan 12.2, 6.7, PB-6; E-30): Freischalt-Felder: active ohne Felder,
-- prepared mit genau einem; Phase aus demselben Plan (sonst foreign_id); leichtere Variante nur
-- Position derselben Phase (Pruefung in save_plan und im Schema).
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\o
SELECT (SELECT ph.id FROM public.phases ph JOIN public.plans pl ON pl.id = ph.plan_id WHERE pl.patient_id = t.id('pat_a1') LIMIT 1) AS foreign_phase \gset
\o /dev/null
\set ph '"phases":[{"id":"{{ph1}}","position":0,"title":"P1","planned_weeks":2},{"id":"{{ph2}}","position":1,"title":"P2","planned_weeks":2}],"current_phase_id":"{{ph1}}"'
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(t.save_plan('pat_a2', '{' || :'ph' || ',"items":[{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0,"release":"active"},'
  || '{"id":"{{i2}}","phase_id":"{{ph2}}","exercise_id":"{{ex_cat2}}","position":0,"release":"prepared","release_on":"2026-11-01"},'
  || '{"id":"{{i3}}","phase_id":"{{ph1}}","exercise_id":"{{ex_a1}}","position":1,"release":"prepared","release_with_phase_id":"{{ph2}}"},'
  || '{"id":"{{i4}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat2}}","position":2,"easier_variant_of":"{{i1}}"}]}'), 2, 'gueltige Freischaltungen und Variante gespeichert');
SELECT t.is((SELECT release || '/' || coalesce(release_on::text, '-') || '/' || coalesce((release_with_phase_id = t.id('ph2'))::text, '-') FROM public.plan_items WHERE id = t.id('i2')),
            'prepared/2026-11-01/-', 'vorbereitet ab Datum');
SELECT t.is((SELECT release_with_phase_id FROM public.plan_items WHERE id = t.id('i3')), t.id('ph2'), 'vorbereitet ab Phase');
SELECT t.is((SELECT easier_variant_of FROM public.plan_items WHERE id = t.id('i4')), t.id('i1'), 'leichtere Variante gespeichert');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0,"release":"prepared"}]}'),
                '22023', 'prepared ohne Feld -> invalid_release', 'invalid_release');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0,"release":"prepared","release_on":"2026-11-01","release_with_phase_id":"{{ph2}}"}]}'),
                '22023', 'prepared mit beiden Feldern -> invalid_release', 'invalid_release');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0,"release":"active","release_on":"2026-11-01"}]}'),
                '22023', 'active mit Datum -> invalid_release', 'invalid_release');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0,"release":"sometimes"}]}'),
                '22023', 'unbekannter Freischaltwert -> invalid_release', 'invalid_release');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0,"release":"prepared","release_with_phase_id":"' || :'foreign_phase' || '"}]}'),
                'P0001', 'Freischalt-Phase aus anderem Plan -> foreign_id', 'foreign_id');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0},{"id":"{{i4}}","phase_id":"{{ph2}}","exercise_id":"{{ex_cat2}}","position":0,"easier_variant_of":"{{i1}}"}]}'),
                '22023', 'Variante aus anderer Phase -> invalid_easier_variant', 'invalid_easier_variant');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0,"easier_variant_of":"{{i1}}"}]}'),
                '22023', 'Variante auf sich selbst -> invalid_easier_variant', 'invalid_easier_variant');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0,"easier_variant_of":"{{nix}}"}]}'),
                '22023', 'Variante ausserhalb des Payloads -> invalid_easier_variant', 'invalid_easier_variant');
SELECT t.is((SELECT version FROM public.plans WHERE patient_id = t.id('pat_a2')), 2, 'ungueltige Payloads aendern nichts');
-- Variante entfernen: Bezug wird geloescht, Position bleibt
SELECT t.is(t.save_plan('pat_a2', '{' || :'ph' || ',"items":[{"id":"{{i4}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat2}}","position":0,"easier_variant_of":null}]}'), 3, 'Position i1 entfernt');
SELECT t.is((SELECT easier_variant_of FROM public.plan_items WHERE id = t.id('i4')), NULL::uuid, 'Variante entfaellt mit');
-- Schema-Ebene (direkt als Admin)
SELECT t.as_admin();
SELECT t.throws(format('UPDATE public.plan_items SET release = ''prepared'' WHERE id = %L', t.id('i4')), '23514', 'Schema: prepared ohne Feld -> 23514');
SELECT t.throws(format('UPDATE public.plan_items SET release_on = ''2026-01-01'' WHERE id = %L', t.id('i4')), '23514', 'Schema: active mit Datum -> 23514');
SELECT t.throws(format('UPDATE public.plan_items SET release = ''prepared'', release_with_phase_id = %L WHERE id = %L', :'foreign_phase', t.id('i4')), '23503', 'Schema: Freischalt-Phase aus anderem Plan -> 23503');
INSERT INTO public.plan_items (id, plan_id, phase_id, exercise_id, position)
  SELECT t.id('i5'), plan_id, t.id('ph2'), t.id('ex_cat1'), 0 FROM public.plan_items WHERE id = t.id('i4');
SELECT t.throws(format('UPDATE public.plan_items SET easier_variant_of = %L WHERE id = %L', t.id('i4'), t.id('i5')), '23503', 'Schema: Variante aus anderer Phase -> 23503');
SELECT t.throws(format('UPDATE public.plan_items SET easier_variant_of = id WHERE id = %L', t.id('i4')), '23514', 'Schema: Variante auf sich selbst -> 23514');
SELECT t.throws(format('UPDATE public.plan_items SET duration_sec = 0 WHERE id = %L', t.id('i4')), '23514', 'Schema: duration_sec 0 -> 23514');
SELECT t.throws(format('UPDATE public.plan_items SET weight_kg = -1 WHERE id = %L', t.id('i4')), '23514', 'Schema: weight_kg negativ -> 23514');
SELECT t.throws(format('UPDATE public.plan_items SET pause_sec = 0 WHERE id = %L', t.id('i4')), '23514', 'Schema: pause_sec 0 -> 23514');
