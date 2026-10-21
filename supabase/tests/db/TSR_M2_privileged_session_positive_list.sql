-- Sicherheitsreview F2-1R MINOR-2: app.is_privileged_session() als Positivliste. Privilegiert sind
-- nur die wirksamen Sitzungsrollen service_role, postgres, supabase_admin. Jede andere Rolle ist
-- es nicht: anon, authenticated (auch mit gefaelschtem JWT-Claim role=service_role),
-- authenticator ohne SET ROLE (role=none) und eine neue LOGIN-Rolle - weder per SET ROLE noch
-- als eigene Verbindung (\c). Vor dem Fix ("alles ausser anon/authenticated") waeren
-- authenticator und die neue LOGIN-Rolle privilegiert.
\set ON_ERROR_STOP 1
\o /dev/null
-- nur in dieser Wegwerf-Datenbank: Aufruf der internen Funktion fuer die Pruefrollen erlauben
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'curaone_test_tool') THEN
    CREATE ROLE curaone_test_tool LOGIN NOSUPERUSER NOBYPASSRLS;
  END IF;
END $$;
GRANT USAGE ON SCHEMA app TO authenticator, curaone_test_tool, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION app.is_privileged_session()
  TO authenticator, curaone_test_tool, anon, authenticated, service_role;

SELECT t.as_admin();
SELECT t.is(app.is_privileged_session(), true, 'supabase_admin ohne SET ROLE -> privilegiert');
SELECT t.as_owner();
SELECT t.is(app.is_privileged_session(), true, 'SET ROLE postgres (Migrationsrolle) -> privilegiert');
SELECT t.as_service();
SELECT t.is(app.is_privileged_session(), true, 'SET ROLE service_role (Seed) -> privilegiert');
SELECT t.as_anon();
SELECT t.is(app.is_privileged_session(), false, 'anon -> nicht privilegiert');
SELECT t.as_user(t.id('irgendwer'));
SELECT t.is(app.is_privileged_session(), false, 'authenticated -> nicht privilegiert');
RESET ROLE;
SET ROLE curaone_test_tool;
SELECT set_config('request.jwt.claims', '', false);
SELECT t.is(app.is_privileged_session(), false, 'SET ROLE neue LOGIN-Rolle -> nicht privilegiert');
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', false);
SELECT t.is(app.is_privileged_session(), false, 'SET ROLE neue LOGIN-Rolle mit JWT-Claim service_role -> nicht privilegiert');
RESET ROLE;
SET ROLE authenticator;
SELECT set_config('request.jwt.claims', '', false);
SELECT t.is(app.is_privileged_session(), false, 'SET ROLE authenticator -> nicht privilegiert');
RESET ROLE;
SELECT t.as_user(t.id('irgendwer'));
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', false);
SELECT t.is(app.is_privileged_session(), false, 'authenticated mit JWT-Claim role=service_role -> nicht privilegiert');
RESET ROLE;

-- eigene Verbindungen (session_user, role=none)
\c - authenticator
\o /dev/null
SELECT t.is(current_setting('role'), 'none', 'Verbindung authenticator: role = none');
SELECT t.is(app.is_privileged_session(), false, 'Verbindung authenticator, role=none -> nicht privilegiert');
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', false);
SELECT t.is(app.is_privileged_session(), false, 'Verbindung authenticator, role=none, JWT-Claim service_role -> nicht privilegiert');
\c - curaone_test_tool
\o /dev/null
SELECT t.is(app.is_privileged_session(), false, 'Verbindung neue LOGIN-Rolle, role=none -> nicht privilegiert');
\c - postgres
\o /dev/null
SELECT t.is(app.is_privileged_session(), true, 'Verbindung postgres, role=none -> privilegiert');
