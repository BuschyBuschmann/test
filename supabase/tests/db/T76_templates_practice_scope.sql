-- DB-T76 templates_practice_scope (Plan 12.2, 6.2, O-25): Physio liest Beispiele + eigene Vorlagen,
-- schreibt nur eigene; Patient sieht keine Vorlagen.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is((SELECT string_agg(name, ',' ORDER BY name) FROM public.plan_templates), 'Beispiel Knie,Vorlage A', 'Physio A liest Beispiel + eigene');
SELECT t.lives(format('INSERT INTO public.plan_templates (id, practice_id, name, payload) VALUES (%L, %L, ''Eigene'', ''{"phases":[]}'')', t.id('tpl_own'), t.id('practice_a')), 'eigene Vorlage anlegen');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.plan_templates SET name = ''Eigene 2'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('tpl_own'))), '1', 'eigene aendern');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.plan_templates SET name = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('tpl_ex'))), '0', 'Beispiel aendern: 0 Zeilen');
SELECT t.is(t.val(format('WITH d AS (DELETE FROM public.plan_templates WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('tpl_ex'))), '0', 'Beispiel loeschen: 0 Zeilen');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.plan_templates SET name = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('tpl_b'))), '0', 'fremde Vorlage aendern: 0 Zeilen');
SELECT t.throws(format('UPDATE public.plan_templates SET practice_id = NULL WHERE id = %L', t.id('tpl_own')), '42501', 'eigene Vorlage nicht zum Beispiel machen (practice_id)');
SELECT t.throws(format('UPDATE public.plan_templates SET is_example = true WHERE id = %L', t.id('tpl_own')), '42501', 'is_example nicht aenderbar');
SELECT t.throws('INSERT INTO public.plan_templates (practice_id, name) VALUES (NULL, ''Beispiel'')', '42501', 'Beispiel-Vorlage anlegen verweigert');
SELECT t.throws(format('INSERT INTO public.plan_templates (practice_id, name, payload) VALUES (%L, ''X'', ''{"phases":1}'')', t.id('practice_a')), '23514', 'payload ohne phases-Liste -> 23514');
SELECT t.is(t.val(format('WITH d AS (DELETE FROM public.plan_templates WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('tpl_own'))), '1', 'eigene loeschen');
SELECT t.as_user(t.id('phys_b1'));
SELECT t.is((SELECT string_agg(name, ',' ORDER BY name) FROM public.plan_templates), 'Beispiel Knie,Vorlage B', 'Physio B liest Beispiel + eigene');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(t.count('SELECT 1 FROM public.plan_templates'), 0::bigint, 'Patient sieht keine Vorlagen');
