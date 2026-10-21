-- DB-T12 redeem_already_bound (Plan 12.2): bereits gebundene Sitzung -> not_allowed
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.create_patient('phys_a1', 'pat_a2', 'Ben', 'Schulter');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(public.redeem_invitation(t.code('pat_a2')), 'not_allowed', 'gebundene Sitzung (Anna) -> not_allowed');
SELECT t.as_admin();
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a2')), 'invited', 'Ben bleibt eingeladen');
SELECT t.is((SELECT auth_user_id FROM public.patients WHERE id = t.id('pat_a1')), t.id('anon_a1'), 'Anna bleibt gebunden');
-- zweite gebundene Sitzung (Clara) mit Code einer anderen Patientin
SELECT t.as_user(t.id('anon_a3'), true);
SELECT t.is(public.redeem_invitation(t.code('pat_a1')), 'not_allowed', 'gebundene Sitzung (Clara) mit fremdem Code -> not_allowed');
