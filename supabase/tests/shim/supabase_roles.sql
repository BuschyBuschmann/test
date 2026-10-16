-- Nachbildung der Supabase-Umgebung fuer DB-Tests ohne Stack (Plan 12.1, v1.2 10.1).
-- NUR fuer lokale Tests gegen ein Wegwerf-Postgres. Nicht gegen ein echtes Projekt ausfuehren.
--
-- Laeuft als Superuser (im Test-Cluster: supabase_admin) vor den Migrationen.
-- Bildet nach:
--   * Rollen anon, authenticated (NOLOGIN, ohne BYPASSRLS), service_role (NOLOGIN BYPASSRLS),
--     authenticator (LOGIN NOINHERIT), Migrationsrolle postgres (Eigentuemer, hier bewusst
--     NOSUPERUSER NOBYPASSRLS, damit DB-T02 den Unterschied FORCE/kein FORCE wirklich zeigt).
--   * Standard-Grants wie Supabase (ALL fuer anon/authenticated/service_role in public,
--     EXECUTE fuer PUBLIC als Postgres-Standard), damit die Tests pruefen, dass Migration 01
--     sie wirklich entzieht.
--   * Schema auth mit auth.users, auth.uid(), auth.jwt(), auth.role() aus request.jwt.claims.
--   * Schema extensions mit pgcrypto (wie im Supabase-Projekt).
-- Nicht nachgebildet: GoTrue, PostgREST, Storage, echte Rollenattribute (Bestaetigung X2-8, L9).

\set ON_ERROR_STOP 1
SET client_min_messages = warning;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
    CREATE ROLE postgres LOGIN NOSUPERUSER NOBYPASSRLS CREATEROLE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticator') THEN
    CREATE ROLE authenticator LOGIN NOINHERIT;
  END IF;
END
$$;

GRANT anon, authenticated, service_role TO authenticator;

-- Erweiterungen wie im Supabase-Projekt im Schema extensions
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;

-- Schema auth (vereinfachte Nachbildung)
CREATE SCHEMA IF NOT EXISTS auth;
CREATE TABLE IF NOT EXISTS auth.users (
  id           uuid PRIMARY KEY,
  email        text,
  is_anonymous boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION auth.jwt() RETURNS jsonb
LANGUAGE sql STABLE AS $$
  SELECT coalesce(
    nullif(current_setting('request.jwt.claim', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')
  )::jsonb
$$;

CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT nullif(coalesce(
    current_setting('request.jwt.claim.sub', true),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  ), '')::uuid
$$;

CREATE OR REPLACE FUNCTION auth.role() RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT nullif(coalesce(
    current_setting('request.jwt.claim.role', true),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  ), '')::text
$$;

GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role, postgres;
GRANT EXECUTE ON FUNCTION auth.uid(), auth.jwt(), auth.role() TO anon, authenticated, service_role, postgres;
-- Migrationsrolle: Fremdschluessel auf auth.users und Loeschen des eigenen Kontos (B-7, R2-12;
-- im echten Stack in L9 zu bestaetigen)
GRANT SELECT, REFERENCES, DELETE ON auth.users TO postgres;
GRANT ALL ON auth.users TO service_role;

-- Standard-Grants wie Supabase (werden von Migration 01 fuer anon/authenticated entzogen)
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;
