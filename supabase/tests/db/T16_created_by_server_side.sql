-- DB-T16 created_by_server_side (Plan 12.2, 6.3, m-3): gefaelschtes created_by/created_by_role
-- wird ueberschrieben (appointments, exercises, plan_templates; exercise_images ab L8).
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('anon_a1'), true);
INSERT INTO public.appointments (id, patient_id, starts_at, title, created_by, created_by_role)
VALUES (t.id('apt_fake'), t.id('pat_a1'), now(), 'gefaelscht', t.id('phys_a1'), 'physio');
SELECT t.as_user(t.id('phys_a1'));
INSERT INTO public.appointments (id, patient_id, starts_at, title, created_by, created_by_role)
VALUES (t.id('apt_fake2'), t.id('pat_a1'), now(), 'gefaelscht', t.id('anon_a1'), 'patient');
INSERT INTO public.exercises (id, practice_id, name, description, created_by, created_by_role)
VALUES (t.id('ex_fake'), t.id('practice_a'), 'Neu', 'Neu', t.id('phys_a2'), 'seed');
INSERT INTO public.plan_templates (id, practice_id, name, created_by, created_by_role)
VALUES (t.id('tpl_fake'), t.id('practice_a'), 'Neu', t.id('phys_b1'), 'patient');
SELECT t.as_admin();
SELECT t.is((SELECT created_by::text || '/' || created_by_role FROM public.appointments WHERE id = t.id('apt_fake')),
            t.id('anon_a1')::text || '/patient', 'Patient-Termin: created_by = Aufrufer, Rolle patient');
SELECT t.is((SELECT created_by::text || '/' || created_by_role FROM public.appointments WHERE id = t.id('apt_fake2')),
            t.id('phys_a1')::text || '/physio', 'Physio-Termin: created_by = Aufrufer, Rolle physio');
SELECT t.is((SELECT created_by::text || '/' || created_by_role FROM public.exercises WHERE id = t.id('ex_fake')),
            t.id('phys_a1')::text || '/physio', 'Uebung: created_by = Aufrufer');
SELECT t.is((SELECT created_by::text || '/' || created_by_role FROM public.plan_templates WHERE id = t.id('tpl_fake')),
            t.id('phys_a1')::text || '/physio', 'Vorlage: created_by = Aufrufer');
SELECT t.ok((SELECT bool_and(tgenabled = 'O') FROM pg_trigger WHERE tgname = 't30_set_created_by') AND
            (SELECT count(*) FROM pg_trigger WHERE tgname = 't30_set_created_by') = 3, 'Trigger an 3 Tabellen aktiv');
