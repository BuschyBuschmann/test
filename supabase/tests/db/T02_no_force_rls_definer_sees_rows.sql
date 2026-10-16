-- DB-T02 no_force_rls_definer_sees_rows (Plan 12.2, 6.1 Nr. 1, M-1): RLS ist an, aber nicht
-- erzwungen; Definer-Funktionen (Eigentuemer postgres, hier ohne BYPASSRLS) sehen Zeilen,
-- API-Rollen unterliegen RLS. Gegenprobe: mit FORCE sieht dieselbe Funktion 0 Zeilen.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();

SELECT t.is((SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname IN ('public', 'app') AND c.relkind = 'r' AND c.relforcerowsecurity),
            0::bigint, 'keine Tabelle mit FORCE ROW LEVEL SECURITY');
SELECT t.ok((SELECT NOT rolbypassrls AND NOT rolsuper FROM pg_roles WHERE rolname = 'postgres'),
            'Eigentuemer postgres hat im Test weder SUPERUSER noch BYPASSRLS (Gegenprobe aussagekraeftig)');
SELECT t.ok((SELECT bool_and(pg_get_userbyid(c.relowner) = 'postgres') FROM pg_class c
               JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname IN ('public', 'app') AND c.relkind IN ('r', 'v', 'S')),
            'alle Tabellen, Sichten und Sequenzen gehoeren der Migrationsrolle');
SELECT t.ok((SELECT bool_and(pg_get_userbyid(p.proowner) = 'postgres') FROM pg_proc p
               JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname IN ('public', 'app')),
            'alle Funktionen gehoeren der Migrationsrolle');

-- neuer Code fuer Ben (eingeladen)
SELECT t.create_patient('phys_a2', 'pat_a2', 'Ben', 'Schulter');

-- API-Rolle: unbound anonyme Sitzung sieht keine Einladungen (kein Recht bzw. 0 Zeilen)
INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_x'), true);
SELECT t.as_user(t.id('anon_x'), true);
SELECT t.ok(t.sees_nothing('SELECT id FROM public.invitations'), 'API-Rolle sieht keine Einladungen (RLS/Rechte)');
SELECT t.ok(t.sees_nothing('SELECT id FROM public.patients'), 'API-Rolle sieht keine Patienten (RLS)');
-- Definer-Funktion liest die Einladung trotzdem
SELECT t.is(public.redeem_invitation(t.code('pat_a2')), 'ok', 'Definer-Funktion redeem_invitation sieht die Einladung (ohne FORCE)');

-- Gegenprobe mit FORCE
SELECT t.as_admin();
SELECT t.create_patient('phys_a1', 'pat_force', 'Fritz', 'Knie');
ALTER TABLE public.invitations FORCE ROW LEVEL SECURITY;
INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_y'), true);
SELECT t.as_user(t.id('anon_y'), true);
SELECT t.is(public.redeem_invitation(t.code('pat_force')), 'invalid', 'Gegenprobe: mit FORCE sieht dieselbe Definer-Funktion 0 Zeilen');
SELECT t.as_admin();
ALTER TABLE public.invitations NO FORCE ROW LEVEL SECURITY;
