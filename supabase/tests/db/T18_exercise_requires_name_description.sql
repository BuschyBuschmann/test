-- DB-T18 exercise_requires_name_description (Plan 12.2, P-3 AK 2): eigene Uebung ohne Name bzw.
-- Beschreibung -> Constraint-Fehler.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description) VALUES (%L, '''', ''Beschreibung'')', t.id('practice_a')), '23514', 'leerer Name -> 23514');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description) VALUES (%L, ''   '', ''Beschreibung'')', t.id('practice_a')), '23514', 'Name nur Leerzeichen -> 23514');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name, description) VALUES (%L, ''Name'', '''')', t.id('practice_a')), '23514', 'leere Beschreibung -> 23514');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, name) VALUES (%L, ''Name'')', t.id('practice_a')), '23502', 'fehlende Beschreibung -> 23502');
SELECT t.throws(format('INSERT INTO public.exercises (practice_id, description) VALUES (%L, ''B'')', t.id('practice_a')), '23502', 'fehlender Name -> 23502');
SELECT t.throws(format('UPDATE public.exercises SET name = '''' WHERE id = %L', t.id('ex_a1')), '23514', 'Name leeren -> 23514');
SELECT t.lives(format('INSERT INTO public.exercises (practice_id, name, description) VALUES (%L, ''Name'', ''Beschreibung'')', t.id('practice_a')), 'Name und Beschreibung -> angelegt');
