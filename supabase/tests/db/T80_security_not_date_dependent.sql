-- DB-T80 security_not_date_dependent (Plan 12.2, 6.7 Nr. 2/3, MAJOR-2): keine Policy und keine in
-- Policies verwendete Hilfsfunktion (rekursiv) nutzt Datums-/Uhrzeitfunktionen; create_patient lehnt
-- local_day ausserhalb +-1 Tag um das UTC-Datum ab (Fixture d). Fixtures c/e/f/g stimmen mit den
-- Zeitzonendaten von Postgres ueberein. (storage.objects: Stack, L8/L9; start_new_injury: L7;
-- submit_daily_checkup: L5.)
\set ON_ERROR_STOP 1
\o /dev/null
\set fx_c `cat "$SUPABASE_DIR/tests/fixtures/local_day/c_timezones_midnight.json"`
\set fx_d `cat "$SUPABASE_DIR/tests/fixtures/local_day/d_out_of_range.json"`
\set fx_e `cat "$SUPABASE_DIR/tests/fixtures/local_day/e_dst_berlin_2026-10-25.json"`
\set fx_f `cat "$SUPABASE_DIR/tests/fixtures/local_day/f_session_over_midnight.json"`
\set fx_g `cat "$SUPABASE_DIR/tests/fixtures/local_day/g_checkup_0010.json"`
SELECT t.seed_base();

CREATE TEMP TABLE forbidden AS SELECT '(?i)\m(now|current_date|current_time|current_timestamp|localtime|localtimestamp|clock_timestamp|statement_timestamp|transaction_timestamp|timeofday|utc_now|utc_today)\M' AS re;
SELECT t.ok((SELECT count(*) FROM pg_policies WHERE schemaname IN ('public', 'app')) >= 30, 'Policies gefunden (mindestens 30)');
SELECT t.is((SELECT string_agg(tablename || '.' || policyname, ', ') FROM pg_policies, forbidden
              WHERE schemaname IN ('public', 'app') AND (coalesce(qual, '') || ' ' || coalesce(with_check, '')) ~ forbidden.re), NULL,
            'keine Policy verwendet Datums- oder Uhrzeitfunktionen');
-- in Policies verwendete Funktionen und rekursiv alle darin aufgerufenen app-Funktionen
CREATE TEMP TABLE policy_funcs AS
WITH RECURSIVE f(name) AS (
  SELECT DISTINCT m[1] FROM pg_policies, regexp_matches(coalesce(qual, '') || ' ' || coalesce(with_check, ''), 'app\.([a-z_]+)\(', 'g') m
   WHERE schemaname IN ('public', 'app')
  UNION
  SELECT m[1] FROM f JOIN pg_proc p ON p.proname = f.name AND p.pronamespace = 'app'::regnamespace,
         regexp_matches(p.prosrc, 'app\.([a-z_]+)\(', 'g') m
)
SELECT name FROM f;
SELECT t.is((SELECT string_agg(name, ',' ORDER BY name) FROM policy_funcs),
            'active_injury_id_internal,current_injury_id,current_patient_id,current_physio_practice,current_plan_id,is_anonymous,patient_can_see_exercise,physio_can_see_patient,uid',
            'erfasste Hilfsfunktionen der Policies (rekursiv)');
SELECT t.is((SELECT string_agg(p.proname, ', ') FROM pg_proc p JOIN policy_funcs f ON f.name = p.proname, forbidden
              WHERE p.pronamespace = 'app'::regnamespace AND p.prosrc ~ forbidden.re), NULL,
            'keine in Policies verwendete Hilfsfunktion nutzt Datums- oder Uhrzeitfunktionen');
SELECT t.ok((SELECT prosrc ~ 'now' FROM pg_proc WHERE oid = 'app.utc_now()'::regprocedure), 'Gegenprobe: das Suchmuster erkennt now() in app.utc_now');
-- Datumsfreie Schemafunktion auch fuer auth.*: Policies nutzen auth nur ueber app.uid/app.is_anonymous
SELECT t.is((SELECT count(*) FROM pg_policies WHERE schemaname IN ('public', 'app') AND (coalesce(qual, '') || coalesce(with_check, '')) ~ 'auth\.'), 0::bigint,
            'Policies greifen nicht direkt auf auth.* zu');

-- Plausibilitaet sofortiger Aufrufe (create_patient) mit Fixture d
SELECT t.set_clock((:'fx_d'::jsonb ->> 'server_utc_instant')::timestamptz);
SELECT t.as_user(t.id('phys_a1'));
SELECT CASE WHEN c ->> 'immediate' = 'accepted'
         THEN t.lives(format('SELECT * FROM public.create_patient(%L, ''Fix'', ''Knie'', NULL, %L)', gen_random_uuid(), c ->> 'local_day'), 'create_patient angenommen: ' || (c ->> 'local_day'))
         ELSE t.throws(format('SELECT * FROM public.create_patient(%L, ''Fix'', ''Knie'', NULL, %L)', gen_random_uuid(), c ->> 'local_day'), '22023',
                       'create_patient invalid_local_day: ' || (c ->> 'local_day'), 'invalid_local_day')
       END
  FROM jsonb_array_elements(:'fx_d'::jsonb -> 'cases') c;
-- Fixture c: alle Zeitzonen-Faelle liegen innerhalb +-1 und werden bei passender Server-Uhr angenommen
SELECT t.as_admin();
SELECT set_config('fx.c', :'fx_c', false);
DO $$
DECLARE c jsonb;
BEGIN
  FOR c IN SELECT jsonb_array_elements(current_setting('fx.c')::jsonb -> 'cases') LOOP
    PERFORM t.as_admin();
    PERFORM t.is(((c ->> 'utc_instant')::timestamptz AT TIME ZONE (c ->> 'timezone'))::date, (c ->> 'local_day')::date,
                 format('Fixture c %s %s: local_day = Postgres-Zeitzone', c ->> 'timezone', c ->> 'device_time'));
    PERFORM t.set_clock((c ->> 'utc_instant')::timestamptz);
    PERFORM t.as_user(t.id('phys_a1'));
    PERFORM t.lives(format('SELECT * FROM public.create_patient(%L, ''Z'', ''Knie'', NULL, %L)', gen_random_uuid(), c ->> 'local_day'),
                    format('Fixture c %s: local_day %s angenommen', c ->> 'timezone', c ->> 'local_day'));
  END LOOP;
END $$;
SELECT t.as_admin();
SELECT t.is(((c ->> 'utc_instant')::timestamptz AT TIME ZONE 'Europe/Berlin')::date, (:'fx_e'::jsonb -> 'expect' ->> 'local_day')::date,
            'Fixture e ' || (c ->> 'device_time') || ': lokaler Tag 2026-10-25')
  FROM jsonb_array_elements(:'fx_e'::jsonb -> 'cases') c;
SELECT t.is(extract(epoch FROM ('2026-10-26 00:00 Europe/Berlin'::timestamptz - '2026-10-25 00:00 Europe/Berlin'::timestamptz)) / 3600,
            (:'fx_e'::jsonb -> 'expect' ->> 'day_length_hours')::numeric, 'Fixture e: Umstellungstag hat 25 Stunden');
SELECT t.is(((:'fx_f'::jsonb -> 'session_start' ->> 'utc_instant')::timestamptz AT TIME ZONE 'Europe/Berlin')::date, (:'fx_f'::jsonb -> 'expect' ->> 'local_day')::date,
            'Fixture f: Session-Start bestimmt den Tag');
SELECT t.is(((:'fx_g'::jsonb -> 'case' ->> 'utc_instant')::timestamptz AT TIME ZONE 'Europe/Berlin')::date, (:'fx_g'::jsonb -> 'expect' ->> 'local_day')::date,
            'Fixture g: 00:10 gehoert zum neuen Tag');
