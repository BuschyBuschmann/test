-- DB-T34 rebind_keeps_history (Plan 12.2, N-1): Plan, Verlauf und Ergebnisse bleiben nach der
-- Neubindung sichtbar fuer die neue Identitaet. (Check-ups und Fragen: ab L4/L5.)
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
INSERT INTO t.codes SELECT 'pat_a1_new', code FROM public.regenerate_invitation(t.id('pat_a1'));
SELECT t.as_admin();
SELECT t.is(t.redeem('anon_a1_new', t.code('pat_a1_new')), 'ok_rebound', 'Neubindung');
SELECT t.as_user(t.id('anon_a1_new'), true);
SELECT t.is((SELECT count(*) FROM public.plans), 1::bigint, 'Plan sichtbar');
SELECT t.ok((SELECT count(*) FROM public.plan_items) > 0, 'Positionen sichtbar');
SELECT t.is((SELECT count(*) FROM public.training_sessions WHERE id = t.id('ts_pat_a1')), 1::bigint, 'alte Session sichtbar');
SELECT t.is((SELECT count(*) FROM public.exercise_results WHERE id = t.id('er_pat_a1')), 1::bigint, 'alte Ergebnisse sichtbar');
SELECT t.is((SELECT count(*) FROM public.appointments WHERE id = t.id('apt_pat_pat_a1')), 1::bigint, 'eigener Termin sichtbar');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.appointments SET title = ''neu'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('apt_pat_pat_a1'))), '1',
            'eigener Termin vom alten Geraet bleibt aenderbar');
SELECT t.is((SELECT count(*) FROM public.consents), 1::bigint, 'Einwilligung bleibt');
SELECT t.is((SELECT count(*) FROM public.account_events), 2::bigint, 'account_events bound + rebound');
SELECT t.is(public.get_my_manny_look(), 'brille', 'Manny-Look aus dem Konto lesbar (O-44: Konto-Wert gewinnt)');
-- neue Identitaet schreibt
SELECT t.lives(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (gen_random_uuid(), %L, %L, current_date, ''done'')',
               t.id('pat_a1'), t.id('ts_pat_a1')), 'neue Identitaet schreibt in die alte Session');
