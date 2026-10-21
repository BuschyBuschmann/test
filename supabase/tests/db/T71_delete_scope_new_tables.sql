-- DB-T71 delete_scope_new_tables (Plan 12.2, 6.13, 6.14): jede Tabelle mit patient_id ist im
-- Loeschumfang oder ausdruecklich "bleibt bei der Praxis"; nach delete_my_data sind die
-- Patienten-Tabellen leer und die Praxis-Tabellen unveraendert. (Notizen ab L7.)
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
CREATE TEMP TABLE deleted_tbl (tbl text, cond text);
INSERT INTO deleted_tbl VALUES ('training_sessions', 'true'), ('exercise_results', 'true'), ('consents', 'true'),
  ('account_events', 'true'), ('appointments', 'created_by_role = ''patient''');
CREATE TEMP TABLE kept_tbl (tbl text, cond text);
INSERT INTO kept_tbl VALUES ('patients', 'true'), ('injuries', 'true'), ('plans', 'true'), ('treaters', 'true'),
  ('history_entries', 'true'), ('invitations', 'true'), ('appointments', 'created_by_role = ''physio''');
SELECT t.is((SELECT string_agg(c.relname, ', ') FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname = 'public' AND c.relkind = 'r'
                AND (EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'patient_id') OR c.relname = 'patients')
                AND c.relname NOT IN (SELECT tbl FROM deleted_tbl UNION SELECT tbl FROM kept_tbl)), NULL,
            'jede Tabelle mit Patientendaten ist eingeordnet (geloescht oder bleibt bei der Praxis)');
CREATE TEMP TABLE kept_before AS SELECT k.tbl, k.cond, t.count(format('SELECT 1 FROM public.%I WHERE %s AND %s = %L', k.tbl, k.cond,
  CASE WHEN k.tbl = 'patients' THEN 'id' ELSE 'patient_id' END, t.id('pat_a1'))) AS n FROM kept_tbl k;
SELECT t.ok(t.count(format('SELECT 1 FROM public.%I WHERE %s AND patient_id = %L', d.tbl, d.cond, t.id('pat_a1'))) > 0, d.tbl || ': vorher Daten vorhanden') FROM deleted_tbl d;
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(public.delete_my_data(), 'ok', 'delete_my_data');
SELECT t.as_admin();
SELECT t.is(t.count(format('SELECT 1 FROM public.%I WHERE %s AND patient_id = %L', d.tbl, d.cond, t.id('pat_a1'))), 0::bigint, d.tbl || ': geloescht') FROM deleted_tbl d;
SELECT t.is(t.count(format('SELECT 1 FROM public.%I WHERE %s AND %s = %L', k.tbl, k.cond, CASE WHEN k.tbl = 'patients' THEN 'id' ELSE 'patient_id' END, t.id('pat_a1'))),
            k.n, k.tbl || ': bleibt bei der Praxis') FROM kept_before k;
