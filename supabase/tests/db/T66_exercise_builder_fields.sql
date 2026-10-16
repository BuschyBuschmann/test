-- DB-T66 exercise_builder_fields (Plan 12.2, 6.2, PB-F): Werte- und Ortsliste geprueft; eigene
-- Uebungen praxisweit sichtbar und pflegbar, fremde Praxis nicht; Patient sieht sie nur im Plan.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
SELECT t.lives(format($q$INSERT INTO public.exercises (id, practice_id, name, description, default_sets, default_reps, default_duration_sec,
  default_weight_kg, pause_sec, materials, locations, short_instruction)
  VALUES (%L, %L, 'Ausfallschritt', 'Langsam nach vorn', 3, 12, 40, 2.5, 45, '{Hantel,Matte}', '{home,practice,gym}', 'Knie ueber dem Fuss')$q$,
  t.id('ex_new'), t.id('practice_a')), 'Uebung mit allen Baukasten-Feldern');
SELECT t.is((SELECT default_duration_sec || '/' || pause_sec || '/' || array_to_string(locations, ',') FROM public.exercises WHERE id = t.id('ex_new')),
            '40/45/home,practice,gym', 'Felder gespeichert');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description, locations) VALUES (%L, ''X'', ''Y'', ''{beach}'')', t.id('practice_a')), '23514', 'unbekannter Ort -> 23514');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description, locations) VALUES (%L, ''X'', ''Y'', ARRAY[''home'', NULL])', t.id('practice_a')), '23514', 'Ort NULL in der Liste -> 23514');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description, default_sets) VALUES (%L, ''X'', ''Y'', 0)', t.id('practice_a')), '23514', 'default_sets 0 -> 23514');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description, default_duration_sec) VALUES (%L, ''X'', ''Y'', -5)', t.id('practice_a')), '23514', 'default_duration_sec negativ -> 23514');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description, default_weight_kg) VALUES (%L, ''X'', ''Y'', 0)', t.id('practice_a')), '23514', 'default_weight_kg 0 -> 23514');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description, pause_sec) VALUES (%L, ''X'', ''Y'', 0)', t.id('practice_a')), '23514', 'pause_sec 0 -> 23514');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description, short_instruction) VALUES (%L, ''X'', ''Y'', '' '')', t.id('practice_a')), '23514', 'leere Kurzanleitung -> 23514');
SELECT t.as_user(t.id('phys_a2'));
SELECT t.is(t.count(format('SELECT 1 FROM public.exercises WHERE id = %L', t.id('ex_new'))), 1::bigint, 'Kollege derselben Praxis sieht die Uebung (praxisweit)');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.exercises SET pause_sec = 60 WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('ex_new'))), '1', 'Kollege pflegt die Uebung');
SELECT t.ok(t.count('SELECT 1 FROM public.exercises WHERE practice_id IS NULL') >= 3, 'Katalog sichtbar');
SELECT t.as_user(t.id('phys_b1'));
SELECT t.is(t.count(format('SELECT 1 FROM public.exercises WHERE id = %L', t.id('ex_new'))), 0::bigint, 'fremde Praxis sieht die Uebung nicht');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(t.count(format('SELECT 1 FROM public.exercises WHERE id = %L', t.id('ex_new'))), 0::bigint, 'Patient sieht Uebung ausserhalb seines Plans nicht');
-- Loeschen nur ungenutzt
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(t.val(format('WITH d AS (DELETE FROM public.exercises WHERE id = %L RETURNING 1) SELECT count(*) FROM d', t.id('ex_a2'))), '1', 'ungenutzte Uebung loeschbar');
SELECT t.throws(format('DELETE FROM public.exercises WHERE id = %L', t.id('ex_a1')), '23503', 'genutzte Uebung (in Claras Plan) nicht loeschbar');
