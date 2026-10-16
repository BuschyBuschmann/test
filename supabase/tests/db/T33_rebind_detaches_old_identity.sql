-- DB-T33 rebind_detaches_old_identity (Plan 12.2, N-1): ok_rebound: alte Identitaet sieht 0 Zeilen,
-- ihr Auth-Konto ist weg, account_events.rebound existiert.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
INSERT INTO t.codes SELECT 'pat_a1_new', code FROM public.regenerate_invitation(t.id('pat_a1'));
SELECT t.as_admin();
SELECT t.is(t.redeem('anon_a1_new', t.code('pat_a1_new')), 'ok_rebound', 'neues Geraet -> ok_rebound');
SELECT t.is((SELECT auth_user_id FROM public.patients WHERE id = t.id('pat_a1')), t.id('anon_a1_new'), 'neue Identitaet gebunden');
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a1')), 'active', 'Status bleibt active');
SELECT t.is((SELECT count(*) FROM auth.users WHERE id = t.id('anon_a1')), 0::bigint, 'altes Auth-Konto geloescht');
SELECT t.is((SELECT count(*) FROM public.account_events WHERE patient_id = t.id('pat_a1') AND kind = 'rebound'), 1::bigint, 'account_events.rebound');
SELECT t.ok((SELECT bound_at > now() - interval '1 minute' FROM public.patients WHERE id = t.id('pat_a1')), 'bound_at = Zeit der Neubindung');
SELECT t.as_user(t.id('anon_a1'), true);
DO $$
DECLARE tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['patients', 'injuries', 'plans', 'phases', 'plan_items', 'exercises', 'treaters', 'appointments',
                             'history_entries', 'consents', 'account_events', 'training_sessions', 'exercise_results'] LOOP
    PERFORM t.ok(t.sees_nothing(format('SELECT 1 FROM public.%I', tbl)), format('alte Identitaet sieht nichts in %s', tbl));
  END LOOP;
END $$;
SELECT t.throws(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) SELECT gen_random_uuid(), %L, %L, current_date, ''checklist''',
                t.id('pat_a1'), gen_random_uuid()), '42501', 'alte Identitaet kann nicht schreiben');
SELECT t.is(public.redeem_invitation(t.code('pat_a1_new')), 'already_used', 'alte Identitaet (jetzt ungebunden) kann den Code nicht noch einmal nutzen');
