-- DB-T47 redeem_attempts_cleanup (Plan 12.2): Eintraege aelter als 24 h werden beim naechsten
-- Aufruf von redeem_invitation entfernt; juengere bleiben.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
INSERT INTO public.redeem_attempts (uid, at, ok) VALUES
  (t.id('old1'), now() - interval '25 hours', false),
  (t.id('old2'), now() - interval '3 days', true),
  (t.id('young'), now() - interval '23 hours', false);
SELECT t.is(t.redeem('anon_c', 'ZZZZZ-ZZZZZ'), 'invalid', 'beliebiger Aufruf');
SELECT t.is((SELECT count(*) FROM public.redeem_attempts WHERE uid IN (t.id('old1'), t.id('old2'))), 0::bigint, 'Eintraege > 24 h entfernt');
SELECT t.is((SELECT count(*) FROM public.redeem_attempts WHERE uid = t.id('young')), 1::bigint, 'Eintrag < 24 h bleibt');
SELECT t.is((SELECT count(*) FROM public.redeem_attempts WHERE uid = t.id('anon_c') AND NOT ok), 1::bigint, 'neuer Fehlversuch protokolliert');
SELECT t.ok(NOT has_table_privilege('authenticated', 'public.redeem_attempts', 'SELECT'), 'redeem_attempts fuer authenticated nicht lesbar');
