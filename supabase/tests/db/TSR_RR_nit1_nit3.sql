-- DB-TSR-RR F2-1RR NIT-1: redeem_invitation mit UUID ohne auth.users-Zeile (altes JWT nach
-- delete_my_data) -> not_allowed und kein redeem_attempts-Eintrag.
-- F2-1RR NIT-3: access_deleted -> regenerate_invitation -> 42501 patient_not_invitable.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
-- NIT-1: Sitzung ohne auth.users-Zeile (anonymes JWT, Konto geloescht)
SELECT t.as_user(t.id('ghost_anon'), true);
SELECT t.is(public.redeem_invitation(t.code('pat_a2')), 'not_allowed', 'UID ohne auth.users-Zeile, gueltiger Code -> not_allowed');
SELECT t.is(public.redeem_invitation('!!!'), 'not_allowed', 'UID ohne auth.users-Zeile, ungueltiger Code -> not_allowed');
SELECT t.as_admin();
SELECT t.is((SELECT count(*)::int FROM public.redeem_attempts WHERE uid = t.id('ghost_anon')), 0, 'kein redeem_attempts-Eintrag fuer die UID ohne auth.users-Zeile');
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a2')), 'invited', 'pat_a2 bleibt eingeladen');
-- nach delete_my_data: altes JWT erneut einloesen
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(public.delete_my_data(), 'ok', 'delete_my_data -> ok');
SELECT t.as_admin();
SELECT t.is((SELECT count(*)::int FROM auth.users WHERE id = t.id('anon_a1')), 0, 'Auth-Konto von Anna geloescht');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(public.redeem_invitation(t.code('pat_a2')), 'not_allowed', 'altes JWT nach delete_my_data -> not_allowed');
SELECT t.is(public.redeem_invitation('!!!'), 'not_allowed', 'altes JWT, ungueltiger Code -> not_allowed');
SELECT t.as_admin();
SELECT t.is((SELECT count(*)::int FROM public.redeem_attempts WHERE uid = t.id('anon_a1')), 0, 'kein redeem_attempts-Eintrag mit geloeschter UUID');
-- NIT-3: access_deleted -> regenerate_invitation
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a1')), 'access_deleted', 'pat_a1 ist access_deleted');
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT * FROM public.regenerate_invitation(%L)', t.id('pat_a1')), '42501', 'access_deleted -> regenerate_invitation -> 42501', 'patient_not_invitable');
SELECT t.as_admin();
SELECT t.is((SELECT count(*)::int FROM public.invitations WHERE patient_id = t.id('pat_a1') AND redeemed_at IS NULL AND revoked_at IS NULL), 0, 'keine neue offene Einladung fuer access_deleted');
