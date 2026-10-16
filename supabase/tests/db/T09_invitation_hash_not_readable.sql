-- DB-T09 invitation_hash_not_readable (Plan 12.2, M-2): code_hmac fuer keine API-Rolle lesbar;
-- keine Sicht ueber invitations.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws('SELECT code_hmac FROM public.invitations', '42501', 'Physio: SELECT code_hmac verweigert');
SELECT t.throws('SELECT * FROM public.invitations', '42501', 'Physio: SELECT * verweigert (Spalten-Grant)');
SELECT t.ok(t.count('SELECT id, patient_id, expires_at, redeemed_at, revoked_at, failed_attempts FROM public.invitations') > 0,
            'Physio: erlaubte Spalten lesbar');
SELECT t.throws('SELECT redeemed_by FROM public.invitations', '42501', 'Physio: redeemed_by nicht lesbar');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.throws('SELECT code_hmac FROM public.invitations', '42501', 'Patient: SELECT code_hmac verweigert');
SELECT t.as_service();
SELECT t.throws('SELECT code_hmac FROM public.invitations', '42501', 'service_role: SELECT code_hmac verweigert');
SELECT t.as_anon();
SELECT t.throws('SELECT code_hmac FROM public.invitations', '42501', 'anon: SELECT code_hmac verweigert');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM pg_depend d JOIN pg_rewrite rw ON rw.oid = d.objid
              JOIN pg_class v ON v.oid = rw.ev_class
             WHERE d.refobjid = 'public.invitations'::regclass AND v.oid <> 'public.invitations'::regclass),
            0::bigint, 'keine Sicht haengt von invitations ab');
