-- DB-T30 delete_my_data_idempotent (Plan 12.2, m-6): zweiter Aufruf bzw. ungebundene Sitzung ->
-- already_deleted; Physio -> 42501.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(public.delete_my_data(), 'ok', 'erster Aufruf -> ok');
SELECT t.is(public.delete_my_data(), 'already_deleted', 'zweiter Aufruf (gleiche Sitzung) -> already_deleted');
SELECT t.as_admin();
INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_new'), true);
SELECT t.as_user(t.id('anon_new'), true);
SELECT t.is(public.delete_my_data(), 'already_deleted', 'ungebundene Sitzung -> already_deleted');
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws('SELECT public.delete_my_data()', '42501', 'Physio -> 42501');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM auth.users WHERE id = t.id('phys_a1')), 1::bigint, 'Physio-Konto bleibt');
