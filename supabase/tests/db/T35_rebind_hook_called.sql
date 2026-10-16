-- DB-T35 rebind_hook_called (Plan 12.2, N-1): app.on_rebind(old_uid) wird bei ok_rebound mit der
-- alten Identitaet aufgerufen, bei ok nicht. (Ausschnitt 3 loescht dort den Chat; KI-Plan DB-K03.)
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
GRANT INSERT ON t.calls TO postgres;
-- Hook in dieser Wegwerf-Datenbank protokollieren lassen (gleiche Signatur, Definer, search_path)
CREATE OR REPLACE FUNCTION app.on_rebind(p_old_uid uuid) RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  INSERT INTO t.calls (fn, arg) VALUES ('on_rebind', p_old_uid::text);
END $$;
SELECT t.ok((SELECT pg_get_userbyid(proowner) = 'postgres' FROM pg_proc WHERE oid = 'app.on_rebind(uuid)'::regprocedure), 'Hook gehoert weiter der Migrationsrolle');
SELECT t.create_patient('phys_a1', 'pat_h', 'Hanna', 'Knie');
SELECT t.is(t.redeem('anon_h', t.code('pat_h')), 'ok', 'erste Bindung');
SELECT t.is((SELECT count(*) FROM t.calls), 0::bigint, 'bei ok kein Hook-Aufruf');
SELECT t.as_user(t.id('phys_a1'));
INSERT INTO t.codes SELECT 'pat_h2', code FROM public.regenerate_invitation(t.id('pat_h'));
SELECT t.as_admin();
SELECT t.is(t.redeem('anon_h2', t.code('pat_h2')), 'ok_rebound', 'Neubindung');
SELECT t.is((SELECT string_agg(fn || ':' || arg, ',') FROM t.calls), 'on_rebind:' || t.id('anon_h')::text, 'Hook genau einmal mit alter Identitaet aufgerufen');
SELECT t.ok(NOT has_function_privilege('authenticated', 'app.on_rebind(uuid)', 'EXECUTE'), 'Hook nicht fuer authenticated ausfuehrbar');
