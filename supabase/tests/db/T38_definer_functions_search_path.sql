-- DB-T38 definer_functions_search_path (Plan 12.2, 6.1 Nr. 4): alle SECURITY DEFINER-Funktionen in
-- public und app haben search_path = '' (Katalogabfrage); Schatten-Objekt im Suchpfad wirkt nicht.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.is((SELECT string_agg(p.oid::regprocedure::text, ', ') FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname IN ('public', 'app') AND p.prosecdef
                AND NOT coalesce('search_path=""' = ANY (p.proconfig), false)), NULL,
            'jede Definer-Funktion hat search_path = ''''');
SELECT t.ok((SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname IN ('public', 'app') AND p.prosecdef) >= 25,
            'Katalogabfrage erfasst alle Definer-Funktionen (mindestens 25)');
SELECT t.is((SELECT string_agg(p.oid::regprocedure::text, ', ') FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname IN ('public', 'app') AND NOT p.prosecdef AND p.proname NOT IN ('utc_now', 'utc_today')), NULL,
            'alle Funktionen ausser der Uhr sind Definer');
SELECT t.ok((SELECT bool_and('search_path=""' = ANY (p.proconfig)) FROM pg_proc p WHERE p.oid IN ('app.utc_now()'::regprocedure, 'app.utc_today()'::regprocedure)),
            'auch die Uhr-Funktionen haben search_path = ''''');
-- Schatten-Objekt: eine Tabelle public.physios-Ersatz im Suchpfad des Aufrufers wirkt nicht
CREATE SCHEMA evil;
CREATE TABLE evil.physios (id uuid, practice_id uuid);
INSERT INTO evil.physios VALUES (t.id('anon_a1'), t.id('practice_b'));
CREATE FUNCTION evil.btrim(text) RETURNS text LANGUAGE sql AS $$ SELECT 'boese' $$;
GRANT USAGE ON SCHEMA evil TO authenticated;
GRANT SELECT ON evil.physios TO authenticated;
GRANT EXECUTE ON FUNCTION evil.btrim(text) TO authenticated;
SELECT t.as_user(t.id('anon_a1'), true);
SET search_path = evil, public;
SELECT t.is(app.current_physio_practice(), NULL::uuid, 'Schatten-Tabelle evil.physios wirkt nicht');
SELECT t.is(public.get_my_manny_look(), 'brille', 'RPC arbeitet trotz Schatten-Objekten korrekt');
RESET search_path;
