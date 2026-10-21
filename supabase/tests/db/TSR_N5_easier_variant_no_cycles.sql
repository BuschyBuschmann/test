-- Sicherheitsreview F2-1R NIT-5: leichtere Variante darf selbst keine Variante sein (keine
-- Zyklen A->B, B->A und keine Ketten A->B->C), in save_plan und beim Kopieren einer Vorlage
-- (create_patient). Eine einfache Variante bleibt erlaubt.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
\set ph '"phases":[{"id":"{{ph1}}","position":0,"title":"P1","planned_weeks":2}],"current_phase_id":"{{ph1}}"'
\set ia '{"id":"{{i1}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat1}}","position":0'
\set ib '{"id":"{{i2}}","phase_id":"{{ph1}}","exercise_id":"{{ex_cat2}}","position":1'
\set ic '{"id":"{{i3}}","phase_id":"{{ph1}}","exercise_id":"{{ex_a1}}","position":2'
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[' || :'ia' || ',"easier_variant_of":"{{i2}}"},' || :'ib' || ',"easier_variant_of":"{{i1}}"}]}'),
                '22023', 'save_plan: Zyklus i1->i2, i2->i1 -> invalid_easier_variant', 'invalid_easier_variant');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[' || :'ia' || ',"easier_variant_of":"{{i2}}"},' || :'ib' || ',"easier_variant_of":"{{i3}}"},' || :'ic' || '}]}'),
                '22023', 'save_plan: Kette i1->i2->i3 -> invalid_easier_variant', 'invalid_easier_variant');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[' || :'ia' || ',"easier_variant_of":"{{i2}}"},' || :'ib' || ',"easier_variant_of":"{{i3}}"},' || :'ic' || ',"easier_variant_of":"{{i1}}"}]}'),
                '22023', 'save_plan: Zyklus ueber drei Positionen -> invalid_easier_variant', 'invalid_easier_variant');
SELECT t.is((SELECT count(*) FROM public.plan_items pi JOIN public.plans pl ON pl.id = pi.plan_id WHERE pl.patient_id = t.id('pat_a2')), 0::bigint,
            'save_plan: nach Ablehnung nichts gespeichert');
SELECT t.lives(format('SELECT t.save_plan(''pat_a2'', %L)', '{' || :'ph' || ',"items":[' || :'ia' || '},' || :'ib' || ',"easier_variant_of":"{{i1}}"},' || :'ic' || ',"easier_variant_of":"{{i1}}"}]}'),
               'save_plan: zwei einfache Varianten derselben Position erlaubt');

-- Vorlage mit Zyklus bzw. Kette (Indexbezug in derselben Phase)
SELECT t.as_admin();
INSERT INTO public.plan_templates (id, practice_id, name, injury_label, is_example, payload) VALUES
  (t.id('tpl_cycle'), t.id('practice_a'), 'Zyklus', 'Knie', false, jsonb_build_object('phases', jsonb_build_array(
     jsonb_build_object('title', 'P1', 'planned_weeks', 1, 'items', jsonb_build_array(
       jsonb_build_object('exercise_id', t.id('ex_cat1'), 'easier_variant_of', 1),
       jsonb_build_object('exercise_id', t.id('ex_cat2'), 'easier_variant_of', 0)))))),
  (t.id('tpl_chain'), t.id('practice_a'), 'Kette', 'Knie', false, jsonb_build_object('phases', jsonb_build_array(
     jsonb_build_object('title', 'P1', 'planned_weeks', 1, 'items', jsonb_build_array(
       jsonb_build_object('exercise_id', t.id('ex_cat1'), 'easier_variant_of', 1),
       jsonb_build_object('exercise_id', t.id('ex_cat2'), 'easier_variant_of', 2),
       jsonb_build_object('exercise_id', t.id('ex_a1')))))));
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Zora'', NULL, %L, %L)', t.id('pat_cycle'), t.id('tpl_cycle'), t.today()),
                '22023', 'Vorlage mit Zyklus -> invalid_easier_variant', 'invalid_easier_variant');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Zeno'', NULL, %L, %L)', t.id('pat_chain'), t.id('tpl_chain'), t.today()),
                '22023', 'Vorlage mit Kette -> invalid_easier_variant', 'invalid_easier_variant');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM public.patients WHERE id IN (t.id('pat_cycle'), t.id('pat_chain'))), 0::bigint,
            'Vorlage abgelehnt: kein Patient angelegt');
SELECT t.as_user(t.id('phys_a1'));
SELECT t.lives(format('SELECT * FROM public.create_patient(%L, ''Paul'', NULL, %L, %L)', t.id('pat_ok'), t.id('tpl_ex'), t.today()),
               'Beispielvorlage mit einfacher Variante weiterhin kopierbar');
