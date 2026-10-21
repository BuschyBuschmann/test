-- DB-T37 rpc_execute_grants (Plan 12.2, 6.4): jede RPC: kein EXECUTE fuer PUBLIC/anon, EXECUTE fuer
-- authenticated; Aufruferpruefung als erste Anweisung (je RPC ein Fall "falsche Rolle").
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid, p.oid::regprocedure::text AS sig FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public' AND p.prokind = 'f' ORDER BY 2 LOOP
    PERFORM t.ok(NOT has_function_privilege('anon', r.oid, 'EXECUTE'), r.sig || ': kein EXECUTE fuer anon');
    PERFORM t.ok(NOT EXISTS (SELECT 1 FROM pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f'::"char", p.proowner))) a
                              WHERE p.oid = r.oid AND a.grantee = 0), r.sig || ': kein EXECUTE fuer PUBLIC');
    PERFORM t.ok(has_function_privilege('authenticated', r.oid, 'EXECUTE'), r.sig || ': EXECUTE fuer authenticated');
    PERFORM t.ok((SELECT prosecdef FROM pg_proc WHERE oid = r.oid), r.sig || ': SECURITY DEFINER');
  END LOOP;
END $$;
-- falsche Rolle: Patient ruft Physio-RPCs
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''X'', ''Knie'', NULL, %L)', gen_random_uuid(), t.today()), '42501', 'Patient: create_patient -> 42501');
SELECT t.throws(format('SELECT * FROM public.regenerate_invitation(%L)', t.id('pat_a1')), '42501', 'Patient: regenerate_invitation (eigene ID) -> 42501');
SELECT t.throws(format('SELECT public.save_plan(%L, 1, ''{"phases":[],"items":[]}'')', t.id('pat_a1')), '42501', 'Patient: save_plan -> 42501');
SELECT t.throws(format('SELECT public.set_current_phase(%L, %L)', t.id('pat_a1'), gen_random_uuid()), '42501', 'Patient: set_current_phase -> 42501');
SELECT t.is(public.redeem_invitation('ABCDE-FGHJK'), 'not_allowed', 'Patient (gebunden): redeem_invitation -> not_allowed');
-- falsche Rolle: Physio ruft Patienten-RPCs
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws('SELECT public.accept_consent(''physio_sharing'', ''physio_sharing-2'')', '42501', 'Physio: accept_consent -> 42501');
SELECT t.throws('SELECT public.delete_my_data()', '42501', 'Physio: delete_my_data -> 42501');
SELECT t.throws('SELECT public.set_manny_look(''ohne'')', '42501', 'Physio: set_manny_look -> 42501');
SELECT t.throws('SELECT public.get_my_manny_look()', '42501', 'Physio: get_my_manny_look -> 42501');
SELECT t.is(public.redeem_invitation('ABCDE-FGHJK'), 'not_allowed', 'Physio: redeem_invitation -> not_allowed');
-- Aufruferpruefung vor Eingabepruefung: falsche Rolle mit ungueltigen Werten -> 42501, nicht 22023
SELECT t.throws('SELECT public.set_manny_look(''pink'')', '42501', 'Physio mit ungueltigem Wert: zuerst 42501');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, '''', NULL, NULL, NULL)', gen_random_uuid()), '42501', 'Patient mit ungueltigen Werten: create_patient zuerst 42501');
SELECT t.throws(format('SELECT public.save_plan(%L, 1, NULL)', t.id('pat_a1')), '42501', 'Patient mit ungueltigem Payload: save_plan zuerst 42501');
