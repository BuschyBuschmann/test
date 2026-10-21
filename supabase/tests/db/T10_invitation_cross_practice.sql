-- DB-T10 invitation_cross_practice (Plan 12.2): Physio B liest keine Einladung der Praxis A und
-- kann fuer Patienten der Praxis A keinen Code erzeugen.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_b1'));
SELECT t.is(t.count(format('SELECT id FROM public.invitations WHERE patient_id IN (%L, %L, %L)', t.id('pat_a1'), t.id('pat_a2'), t.id('pat_a3'))),
            0::bigint, 'Physio B sieht keine Einladung der Praxis A');
SELECT t.ok(t.count(format('SELECT id FROM public.invitations WHERE patient_id = %L', t.id('pat_b1'))) > 0, 'Physio B sieht eigene');
SELECT t.throws(format('SELECT * FROM public.regenerate_invitation(%L)', t.id('pat_a2')), '42501', 'Physio B: regenerate_invitation fuer Praxis A -> 42501');
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(t.count(format('SELECT id FROM public.invitations WHERE patient_id = %L', t.id('pat_b1'))), 0::bigint, 'Physio A sieht keine Einladung der Praxis B');
