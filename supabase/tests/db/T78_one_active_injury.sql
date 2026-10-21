-- DB-T78 one_active_injury (Plan 12.2, 6.8): zweite aktive Verletzung -> Constraint-Fehler;
-- abgeschlossene Verletzungen beliebig viele.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.throws(format('INSERT INTO public.injuries (patient_id, label, reference_date, started_on) VALUES (%L, ''Zweite'', current_date, current_date)', t.id('pat_a1')),
                '23505', 'zweite aktive Verletzung -> 23505');
SELECT t.lives(format('INSERT INTO public.injuries (patient_id, label, reference_date, started_on, closed_on) VALUES (%L, ''Alt'', ''2025-01-01'', ''2025-01-01'', ''2025-03-01'')', t.id('pat_a1')),
               'abgeschlossene Verletzung zusaetzlich');
SELECT t.lives(format('INSERT INTO public.injuries (patient_id, label, reference_date, started_on, closed_on) VALUES (%L, ''Alt2'', ''2024-01-01'', ''2024-01-01'', ''2024-03-01'')', t.id('pat_a1')),
               'zweite abgeschlossene');
SELECT t.throws(format('INSERT INTO public.injuries (patient_id, label, reference_date, started_on, closed_on) VALUES (%L, ''X'', ''2025-01-01'', ''2025-02-01'', ''2025-01-15'')', t.id('pat_a1')),
                '23514', 'Abschluss vor Beginn -> 23514');
SELECT t.throws(format('INSERT INTO public.plans (patient_id, injury_id) SELECT %L, id FROM public.injuries WHERE patient_id = %L AND closed_on IS NULL', t.id('pat_a1'), t.id('pat_a1')),
                '23505', 'zweiter Plan fuer dieselbe Verletzung -> 23505');
SELECT t.throws(format('INSERT INTO public.plans (patient_id, injury_id) SELECT %L, id FROM public.injuries WHERE patient_id = %L AND label = ''Alt''', t.id('pat_a3'), t.id('pat_a1')),
                '23503', 'Plan mit Verletzung eines anderen Patienten -> 23503');
SELECT t.is((SELECT count(*) FROM public.injuries WHERE patient_id = t.id('pat_a1') AND closed_on IS NULL), 1::bigint, 'genau eine aktive');
