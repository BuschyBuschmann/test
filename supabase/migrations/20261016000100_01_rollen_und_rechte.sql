-- L2 / Migration 01: Standardrechte entziehen, Default Privileges, Schema app (Plan 6.1 Nr. 1-2, 5)
-- Idempotent: jede Anweisung darf erneut laufen.
-- Eigentuemer aller Objekte ist die Migrationsrolle (postgres). RLS wird spaeter mit
-- ENABLE (nie FORCE, M-1) eingeschaltet.

-- Schema app: Hilfsfunktionen, Trigger-Funktionen, Geheimnisse. Nicht ueber die API
-- exponiert (supabase/config.toml: [api] schemas = ["public"]).
CREATE SCHEMA IF NOT EXISTS app;
REVOKE ALL ON SCHEMA app FROM PUBLIC;
REVOKE ALL ON SCHEMA app FROM anon;
-- authenticated braucht USAGE, weil Policies Hilfsfunktionen aus app aufrufen;
-- EXECUTE wird je Hilfsfunktion einzeln vergeben (Migration 03).
GRANT USAGE ON SCHEMA app TO authenticated;

-- Bestehende Rechte in public entziehen (Supabase vergibt sie standardmaessig)
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC, anon, authenticated;
REVOKE ALL ON ALL TABLES IN SCHEMA app FROM PUBLIC, anon, authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA app FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA app FROM PUBLIC, anon, authenticated;

-- Kuenftige Objekte der Migrationsrolle: keine Rechte fuer API-Rollen
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON TABLES FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA app REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA app REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon, authenticated;
-- Postgres-Standard EXECUTE fuer PUBLIC gilt global (nicht je Schema); global entziehen
ALTER DEFAULT PRIVILEGES FOR ROLE postgres REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- Geheimnisse (Pepper fuer die Code-HMAC, Plan 6.5). Kein Wert in der Migration:
-- der Pepper wird per externem Schritt X2-11 gesetzt, lokal in den Tests ein Test-Platzhalter.
CREATE TABLE IF NOT EXISTS app.secrets (
  name  text PRIMARY KEY,
  value text NOT NULL CHECK (length(value) >= 16)
);
REVOKE ALL ON app.secrets FROM PUBLIC, anon, authenticated;

-- Server-Uhr an genau einer Stelle (Plan 6.7 Nr. 3: nur fuer Plausibilitaetsgrenzen,
-- Bereinigung und Ablauf). Kein EXECUTE fuer API-Rollen; Policies verwenden sie nie (DB-T80).
CREATE OR REPLACE FUNCTION app.utc_now() RETURNS timestamptz
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT pg_catalog.now()
$$;

CREATE OR REPLACE FUNCTION app.utc_today() RETURNS date
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT (app.utc_now() AT TIME ZONE 'UTC')::date
$$;

REVOKE EXECUTE ON FUNCTION app.utc_now(), app.utc_today() FROM PUBLIC, anon, authenticated;
