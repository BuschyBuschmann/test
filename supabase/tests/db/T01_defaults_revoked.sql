-- DB-T01 defaults_revoked (Plan 12.2, 6.1 Nr. 2, 6.2, 6.4, 6.14 Pflicht "RLS an, keine Rechte
-- ausser den genannten"): Rechte-Inventar fuer anon, authenticated und PUBLIC in public und app
-- entspricht genau der Liste aus 6.2/6.4. Schema t ist testintern und ausgenommen.
\set ON_ERROR_STOP 1
\o /dev/null

CREATE TEMP TABLE expected (obj text, col text, priv text, grantee text);
INSERT INTO expected VALUES
  -- Schemas
  ('schema app', NULL, 'USAGE', 'authenticated'),
  ('schema public', NULL, 'USAGE', 'anon'),            -- Supabase-Standard, ohne Objektrechte
  ('schema public', NULL, 'USAGE', 'authenticated'),
  ('schema public', NULL, 'USAGE', 'PUBLIC'),           -- Postgres-Standard seit 15
  -- Tabellen (Tabellenrechte)
  ('public.practices', NULL, 'SELECT', 'authenticated'),
  ('public.physios', NULL, 'SELECT', 'authenticated'),
  ('public.injuries', NULL, 'SELECT', 'authenticated'),
  ('public.exercises', NULL, 'SELECT', 'authenticated'),
  ('public.exercises', NULL, 'INSERT', 'authenticated'),
  ('public.exercises', NULL, 'DELETE', 'authenticated'),
  ('public.plans', NULL, 'SELECT', 'authenticated'),
  ('public.phases', NULL, 'SELECT', 'authenticated'),
  ('public.plan_items', NULL, 'SELECT', 'authenticated'),
  ('public.treaters', NULL, 'SELECT', 'authenticated'),
  ('public.treaters', NULL, 'INSERT', 'authenticated'),
  ('public.treaters', NULL, 'UPDATE', 'authenticated'),
  ('public.treaters', NULL, 'DELETE', 'authenticated'),
  ('public.appointments', NULL, 'SELECT', 'authenticated'),
  ('public.appointments', NULL, 'INSERT', 'authenticated'),
  ('public.appointments', NULL, 'DELETE', 'authenticated'),
  ('public.history_entries', NULL, 'SELECT', 'authenticated'),
  ('public.history_entries', NULL, 'INSERT', 'authenticated'),
  ('public.history_entries', NULL, 'UPDATE', 'authenticated'),
  ('public.history_entries', NULL, 'DELETE', 'authenticated'),
  ('public.consents', NULL, 'SELECT', 'authenticated'),
  ('public.account_events', NULL, 'SELECT', 'authenticated'),
  ('public.training_sessions', NULL, 'SELECT', 'authenticated'),
  ('public.training_sessions', NULL, 'INSERT', 'authenticated'),
  ('public.training_sessions', NULL, 'DELETE', 'authenticated'),
  ('public.exercise_results', NULL, 'SELECT', 'authenticated'),
  ('public.exercise_results', NULL, 'INSERT', 'authenticated'),
  ('public.exercise_results', NULL, 'DELETE', 'authenticated'),
  ('public.plan_templates', NULL, 'SELECT', 'authenticated'),
  ('public.plan_templates', NULL, 'INSERT', 'authenticated'),
  ('public.plan_templates', NULL, 'DELETE', 'authenticated'),
  -- Spalten-Grants
  ('public.patients', 'id', 'SELECT', 'authenticated'),
  ('public.patients', 'practice_id', 'SELECT', 'authenticated'),
  ('public.patients', 'first_name', 'SELECT', 'authenticated'),
  ('public.patients', 'last_name', 'SELECT', 'authenticated'),
  ('public.patients', 'main_physio_id', 'SELECT', 'authenticated'),
  ('public.patients', 'status', 'SELECT', 'authenticated'),
  ('public.patients', 'bound_at', 'SELECT', 'authenticated'),
  ('public.patients', 'created_at', 'SELECT', 'authenticated'),
  ('public.patients', 'first_name', 'UPDATE', 'authenticated'),
  ('public.patients', 'last_name', 'UPDATE', 'authenticated'),
  ('public.injuries', 'label', 'UPDATE', 'authenticated'),
  ('public.injuries', 'reference_date', 'UPDATE', 'authenticated'),
  ('public.invitations', 'id', 'SELECT', 'authenticated'),
  ('public.invitations', 'patient_id', 'SELECT', 'authenticated'),
  ('public.invitations', 'created_at', 'SELECT', 'authenticated'),
  ('public.invitations', 'expires_at', 'SELECT', 'authenticated'),
  ('public.invitations', 'redeemed_at', 'SELECT', 'authenticated'),
  ('public.invitations', 'revoked_at', 'SELECT', 'authenticated'),
  ('public.invitations', 'failed_attempts', 'SELECT', 'authenticated'),
  ('public.exercises', 'name', 'UPDATE', 'authenticated'),
  ('public.exercises', 'description', 'UPDATE', 'authenticated'),
  ('public.exercises', 'default_sets', 'UPDATE', 'authenticated'),
  ('public.exercises', 'default_reps', 'UPDATE', 'authenticated'),
  ('public.exercises', 'default_duration_sec', 'UPDATE', 'authenticated'),
  ('public.exercises', 'default_weight_kg', 'UPDATE', 'authenticated'),
  ('public.exercises', 'pause_sec', 'UPDATE', 'authenticated'),
  ('public.exercises', 'materials', 'UPDATE', 'authenticated'),
  ('public.exercises', 'locations', 'UPDATE', 'authenticated'),
  ('public.exercises', 'short_instruction', 'UPDATE', 'authenticated'),
  ('public.exercises', 'updated_at', 'UPDATE', 'authenticated'),
  ('public.appointments', 'treater_id', 'UPDATE', 'authenticated'),
  ('public.appointments', 'starts_at', 'UPDATE', 'authenticated'),
  ('public.appointments', 'title', 'UPDATE', 'authenticated'),
  ('public.appointments', 'location', 'UPDATE', 'authenticated'),
  ('public.training_sessions', 'ended_at', 'UPDATE', 'authenticated'),
  ('public.training_sessions', 'active_seconds', 'UPDATE', 'authenticated'),
  ('public.training_sessions', 'ended_early', 'UPDATE', 'authenticated'),
  ('public.training_sessions', 'streak_after', 'UPDATE', 'authenticated'),
  ('public.plan_templates', 'name', 'UPDATE', 'authenticated'),
  ('public.plan_templates', 'injury_label', 'UPDATE', 'authenticated'),
  ('public.plan_templates', 'payload', 'UPDATE', 'authenticated'),
  -- RPCs (6.4)
  ('public.create_patient(uuid,text,text,uuid,date,text,date)', NULL, 'EXECUTE', 'authenticated'),
  ('public.regenerate_invitation(uuid)', NULL, 'EXECUTE', 'authenticated'),
  ('public.redeem_invitation(text)', NULL, 'EXECUTE', 'authenticated'),
  ('public.accept_consent(text,text)', NULL, 'EXECUTE', 'authenticated'),
  ('public.save_plan(uuid,integer,jsonb)', NULL, 'EXECUTE', 'authenticated'),
  ('public.set_current_phase(uuid,uuid)', NULL, 'EXECUTE', 'authenticated'),
  ('public.delete_my_data()', NULL, 'EXECUTE', 'authenticated'),
  ('public.set_manny_look(text)', NULL, 'EXECUTE', 'authenticated'),
  ('public.get_my_manny_look()', NULL, 'EXECUTE', 'authenticated'),
  -- Hilfsfunktionen fuer Policies (6.1 Nr. 5); nicht die internen
  ('app.uid()', NULL, 'EXECUTE', 'authenticated'),
  ('app.is_anonymous()', NULL, 'EXECUTE', 'authenticated'),
  ('app.current_physio_practice()', NULL, 'EXECUTE', 'authenticated'),
  ('app.current_patient_id()', NULL, 'EXECUTE', 'authenticated'),
  ('app.physio_can_see_patient(uuid)', NULL, 'EXECUTE', 'authenticated'),
  ('app.current_injury_id(uuid)', NULL, 'EXECUTE', 'authenticated'),
  ('app.current_plan_id(uuid)', NULL, 'EXECUTE', 'authenticated'),
  ('app.patient_can_see_exercise(uuid)', NULL, 'EXECUTE', 'authenticated');

CREATE TEMP TABLE actual AS
WITH roles AS (
  SELECT oid, rolname FROM pg_roles WHERE rolname IN ('anon', 'authenticated')
  UNION ALL SELECT 0::oid, 'PUBLIC'
)
-- Tabellen, Sichten, Sequenzen
SELECT n.nspname || '.' || c.relname AS obj, NULL::text AS col, a.privilege_type AS priv, r.rolname AS grantee
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  CROSS JOIN LATERAL aclexplode(coalesce(c.relacl, acldefault((CASE WHEN c.relkind = 'S' THEN 's' ELSE 'r' END)::"char", c.relowner))) a
  JOIN roles r ON r.oid = a.grantee
 WHERE n.nspname IN ('public', 'app') AND c.relkind IN ('r', 'v', 'm', 'S', 'p', 'f')
UNION ALL
-- Spalten
SELECT n.nspname || '.' || c.relname, att.attname, a.privilege_type, r.rolname
  FROM pg_attribute att
  JOIN pg_class c ON c.oid = att.attrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  CROSS JOIN LATERAL aclexplode(att.attacl) a
  JOIN roles r ON r.oid = a.grantee
 WHERE n.nspname IN ('public', 'app') AND att.attacl IS NOT NULL AND att.attnum > 0 AND NOT att.attisdropped
UNION ALL
-- Funktionen (proacl NULL = Standard, also EXECUTE fuer PUBLIC)
SELECT n.nspname || '.' || p.proname || '(' || replace(oidvectortypes(p.proargtypes), ', ', ',') || ')',
       NULL, a.privilege_type, r.rolname
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  CROSS JOIN LATERAL aclexplode(coalesce(p.proacl, acldefault('f'::"char", p.proowner))) a
  JOIN roles r ON r.oid = a.grantee
 WHERE n.nspname IN ('public', 'app')
UNION ALL
-- Schemas
SELECT 'schema ' || n.nspname, NULL, a.privilege_type, r.rolname
  FROM pg_namespace n
  CROSS JOIN LATERAL aclexplode(coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))) a
  JOIN roles r ON r.oid = a.grantee
 WHERE n.nspname IN ('public', 'app');

SELECT t.is((SELECT string_agg(format('%s %s %s %s', obj, coalesce(col, '-'), priv, grantee), '; ' ORDER BY obj, col, priv)
               FROM (SELECT * FROM actual EXCEPT SELECT * FROM expected) x),
            NULL, 'keine Rechte ueber das Inventar hinaus (anon, authenticated, PUBLIC)');
SELECT t.is((SELECT string_agg(format('%s %s %s %s', obj, coalesce(col, '-'), priv, grantee), '; ' ORDER BY obj, col, priv)
               FROM (SELECT * FROM expected EXCEPT SELECT * FROM actual) x),
            NULL, 'alle Rechte des Inventars sind vergeben');
SELECT t.is((SELECT count(*) FROM actual WHERE grantee = 'anon' AND obj <> 'schema public'), 0::bigint,
            'anon hat keinerlei Objektrechte');
SELECT t.is((SELECT count(*) FROM actual WHERE grantee = 'PUBLIC' AND obj <> 'schema public'), 0::bigint,
            'PUBLIC hat keine Objektrechte in public und app (auch kein EXECUTE)');

-- RLS an allen Tabellen (Pflichtliste 6.14), ohne FORCE (M-1)
SELECT t.is((SELECT string_agg(n.nspname || '.' || c.relname, ', ')
               FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname IN ('public', 'app') AND c.relkind IN ('r', 'p') AND NOT c.relrowsecurity),
            NULL, 'RLS an jeder Tabelle in public und app');

-- Default Privileges der Migrationsrolle vergeben nichts an anon/authenticated/PUBLIC
SELECT t.is((SELECT count(*)
               FROM pg_default_acl d
               JOIN pg_roles o ON o.oid = d.defaclrole
               CROSS JOIN LATERAL aclexplode(d.defaclacl) a
              WHERE o.rolname = 'postgres'
                AND (a.grantee = 0 OR a.grantee IN (SELECT oid FROM pg_roles WHERE rolname IN ('anon', 'authenticated')))),
            0::bigint, 'Default Privileges: keine Rechte fuer API-Rollen und PUBLIC');

-- service_role liest code_hmac nicht (DB-T09 ergaenzt)
SELECT t.ok(NOT has_column_privilege('service_role', 'public.invitations', 'code_hmac', 'SELECT'),
            'service_role hat kein SELECT auf invitations.code_hmac');
-- Geheimnisse: keine API-Rolle liest app.secrets
SELECT t.ok(NOT has_table_privilege('authenticated', 'app.secrets', 'SELECT')
            AND NOT has_table_privilege('anon', 'app.secrets', 'SELECT')
            AND NOT has_table_privilege('service_role', 'app.secrets', 'SELECT'),
            'app.secrets fuer anon, authenticated, service_role nicht lesbar');
