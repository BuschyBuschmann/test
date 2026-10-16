-- Pruefsumme des Testdaten-Zustands (DB-T40: zweimal seeden -> gleicher Endzustand).
-- Nur lesend. Fluechtige Spalten (Zeitstempel mit Default now(), Einladungen) fehlen in der Projektion;
-- Physio-Verweise erscheinen als E-Mail, weil GoTrue die Konto-IDs im echten Stack neu vergibt.
--
--   psql -X -At -f snapshot.sql        -> Zeilen "seed:<tabelle> <md5>" und "control:<tabelle> <md5>"
-- seed:    Zeilen der Praxen mit is_test, Beispiel-Katalog und Beispielvorlagen
-- control: alles ausserhalb der Testdaten (muss vom Seed unberuehrt bleiben)

\set ON_ERROR_STOP 1

CREATE TEMP VIEW _scope_patients AS
  SELECT p.id, pr.is_test FROM public.patients p JOIN public.practices pr ON pr.id = p.practice_id;

CREATE OR REPLACE FUNCTION pg_temp.digest_of(p_sql text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  EXECUTE format('SELECT coalesce(md5(string_agg(j::text, ''|'' ORDER BY j::text)), ''leer'') FROM (%s) s(j)', p_sql) INTO v;
  RETURN v;
END $$;

CREATE OR REPLACE FUNCTION pg_temp.email_of(p uuid) RETURNS text LANGUAGE sql STABLE AS
  $$ SELECT email FROM auth.users WHERE id = p $$;

CREATE TEMP TABLE _out (k text, v text);

DO $$
DECLARE
  v_scope boolean;
  v_label text;
  r       record;
  v_sql   text;
BEGIN
  FOREACH v_scope IN ARRAY ARRAY[true, false] LOOP
    v_label := CASE WHEN v_scope THEN 'seed' ELSE 'control' END;
    -- (Tabelle, Projektion, Filter)
    FOR r IN
      SELECT * FROM (VALUES
        ('practices',
         'to_jsonb(t) - ''created_at''',
         format('FROM public.practices t WHERE t.is_test = %L', v_scope)),
        ('physios',
         'to_jsonb(t) - ''created_at'' - ''id'' || jsonb_build_object(''email'', pg_temp.email_of(t.id))',
         format('FROM public.physios t WHERE t.practice_id IN (SELECT id FROM public.practices WHERE is_test = %L)', v_scope)),
        ('patients',
         'to_jsonb(t) - ''created_at'' - ''create_params_hash'' - ''main_physio_id'' - ''auth_user_id'' - ''bound_at'' || jsonb_build_object(''main_physio'', pg_temp.email_of(t.main_physio_id))',
         format('FROM public.patients t WHERE t.practice_id IN (SELECT id FROM public.practices WHERE is_test = %L)', v_scope)),
        ('exercises',
         'to_jsonb(t) - ''created_at'' - ''updated_at''',
         CASE WHEN v_scope
              THEN 'FROM public.exercises t WHERE t.practice_id IN (SELECT id FROM public.practices WHERE is_test) OR (t.practice_id IS NULL AND t.created_by_role = ''seed'')'
              ELSE 'FROM public.exercises t WHERE NOT (t.practice_id IN (SELECT id FROM public.practices WHERE is_test) OR (t.practice_id IS NULL AND t.created_by_role = ''seed''))' END),
        ('plan_templates',
         'to_jsonb(t) - ''created_at''',
         CASE WHEN v_scope
              THEN 'FROM public.plan_templates t WHERE t.practice_id IN (SELECT id FROM public.practices WHERE is_test) OR (t.practice_id IS NULL AND t.created_by_role = ''seed'')'
              ELSE 'FROM public.plan_templates t WHERE NOT (t.practice_id IN (SELECT id FROM public.practices WHERE is_test) OR (t.practice_id IS NULL AND t.created_by_role = ''seed''))' END)
      ) x(tbl, proj, src)
    LOOP
      EXECUTE format('SELECT pg_temp.digest_of(%L)', 'SELECT ' || r.proj || ' ' || r.src) INTO v_sql;
      INSERT INTO _out VALUES (v_label || ':' || r.tbl, v_sql);
    END LOOP;
    -- Patienten-bezogene Tabellen
    FOR r IN
      SELECT * FROM (VALUES
        ('injuries', 'to_jsonb(t) - ''created_at'''),
        ('plans', 'to_jsonb(t) - ''updated_at'' - ''updated_by'' || jsonb_build_object(''updated_by_email'', pg_temp.email_of(t.updated_by))'),
        ('treaters', 'to_jsonb(t) - ''created_at'''),
        ('history_entries', 'to_jsonb(t) - ''created_at'''),
        ('appointments', 'to_jsonb(t) - ''created_at'' - ''created_by'' || jsonb_build_object(''created_by_email'', pg_temp.email_of(t.created_by))'),
        ('training_sessions', 'to_jsonb(t)'),
        ('exercise_results', 'to_jsonb(t)')
      ) x(tbl, proj)
    LOOP
      v_sql := format('SELECT %s FROM public.%I t WHERE t.patient_id IN (SELECT id FROM _scope_patients WHERE is_test = %L)',
                      r.proj, r.tbl, v_scope);
      EXECUTE format('SELECT pg_temp.digest_of(%L)', v_sql) INTO v_sql;
      INSERT INTO _out VALUES (v_label || ':' || r.tbl, v_sql);
    END LOOP;
    -- ueber den Plan erreichbar
    v_sql := format('SELECT to_jsonb(t) FROM public.phases t WHERE t.plan_id IN (SELECT pl.id FROM public.plans pl WHERE pl.patient_id IN (SELECT id FROM _scope_patients WHERE is_test = %L))', v_scope);
    EXECUTE format('SELECT pg_temp.digest_of(%L)', v_sql) INTO v_sql;
    INSERT INTO _out VALUES (v_label || ':phases', v_sql);
    v_sql := format('SELECT to_jsonb(t) FROM public.plan_items t WHERE t.plan_id IN (SELECT pl.id FROM public.plans pl WHERE pl.patient_id IN (SELECT id FROM _scope_patients WHERE is_test = %L))', v_scope);
    EXECUTE format('SELECT pg_temp.digest_of(%L)', v_sql) INTO v_sql;
    INSERT INTO _out VALUES (v_label || ':plan_items', v_sql);
  END LOOP;
END $$;

SELECT k || ' ' || v FROM _out ORDER BY k;
