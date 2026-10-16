-- DB-T05 unbound_anonymous_rpc_denied (Plan 12.2): anonyme, ungebundene Sitzung: jede RPC
-- ausser redeem_invitation/delete_my_data -> 42501 (je RPC ein Fall); Vollstaendigkeit per Katalog.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
CREATE TEMP TABLE covered (fn text);
INSERT INTO covered VALUES ('create_patient'), ('regenerate_invitation'), ('accept_consent'), ('save_plan'),
  ('set_current_phase'), ('set_manny_look'), ('get_my_manny_look'), ('redeem_invitation'), ('delete_my_data');
GRANT SELECT ON covered TO PUBLIC;
SELECT t.is((SELECT string_agg(p.proname, ', ') FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'public' AND has_function_privilege('authenticated', p.oid, 'EXECUTE')
                AND p.proname NOT IN (SELECT fn FROM covered)), NULL,
            'jede fuer authenticated ausfuehrbare RPC ist in diesem Test abgedeckt');

INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_unbound'), true);
SELECT t.as_user(t.id('anon_unbound'), true);
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''X'', ''Knie'', NULL, %L)', gen_random_uuid(), t.today()), '42501', 'create_patient -> 42501');
SELECT t.throws(format('SELECT * FROM public.regenerate_invitation(%L)', t.id('pat_a2')), '42501', 'regenerate_invitation -> 42501');
SELECT t.throws('SELECT public.accept_consent(''physio_sharing'', ''physio_sharing-2'')', '42501', 'accept_consent -> 42501');
SELECT t.throws(format('SELECT public.save_plan(%L, 1, ''{"phases":[],"items":[]}'')', t.id('pat_a2')), '42501', 'save_plan -> 42501');
SELECT t.throws(format('SELECT public.set_current_phase(%L, %L)', t.id('pat_a1'), gen_random_uuid()), '42501', 'set_current_phase -> 42501');
SELECT t.throws('SELECT public.set_manny_look(''ohne'')', '42501', 'set_manny_look -> 42501');
SELECT t.throws('SELECT public.get_my_manny_look()', '42501', 'get_my_manny_look -> 42501');
-- erlaubt: redeem_invitation (Ergebniscode) und delete_my_data (already_deleted)
SELECT t.is(public.redeem_invitation('ZZZZZ-ZZZZZ'), 'invalid', 'redeem_invitation erlaubt (Ergebnis invalid)');
SELECT t.is(public.delete_my_data(), 'already_deleted', 'delete_my_data erlaubt (already_deleted)');
