-- DB-T11 redeem_requires_anonymous (Plan 12.2, M-3): redeem_invitation als Physio oder als
-- nicht-anonyme Sitzung -> not_allowed; die Einladung bleibt offen.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.create_patient('phys_a1', 'pat_a2', 'Ben', 'Schulter');
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(public.redeem_invitation(t.code('pat_a2')), 'not_allowed', 'Physio -> not_allowed');
SELECT t.as_user(t.id('phys_a1'), true);
SELECT t.is(public.redeem_invitation(t.code('pat_a2')), 'not_allowed', 'Physio mit Claim is_anonymous -> not_allowed');
SELECT t.as_admin();
INSERT INTO auth.users (id, email, is_anonymous) VALUES (t.id('user_plain'), 'x@test.curaone.invalid', false);
SELECT t.as_user(t.id('user_plain'), false);
SELECT t.is(public.redeem_invitation(t.code('pat_a2')), 'not_allowed', 'nicht-anonyme Sitzung -> not_allowed');
SELECT t.as_admin();
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a2')), 'invited', 'Patient bleibt eingeladen');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_a2') AND redeemed_at IS NULL AND revoked_at IS NULL),
            1::bigint, 'Einladung bleibt offen');
SELECT t.is(t.redeem('anon_ben', t.code('pat_a2')), 'ok', 'anonyme Sitzung loest danach ein');
