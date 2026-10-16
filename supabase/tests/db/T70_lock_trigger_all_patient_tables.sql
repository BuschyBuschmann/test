-- DB-T70 lock_trigger_all_patient_tables (Plan 12.2, 6.3, 6.14): Schreibsperre auf allen Tabellen
-- mit Patienten-Schreibweg (Katalogabfrage); jede Tabelle mit patient_id ist eingeordnet; Tabellen
-- ohne Sperre haben keine Schreib-Policy fuer Patienten; Schreibversuch bei inaktivem Status
-- scheitert. Wettlauf mit delete_my_data: db/race/T31_race_delete_vs_insert.sh.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
CREATE TEMP TABLE locked (tbl text);
INSERT INTO locked VALUES ('training_sessions'), ('exercise_results'), ('appointments'), ('consents');
CREATE TEMP TABLE not_locked (tbl text, why text);
INSERT INTO not_locked VALUES ('patients', 'nur RPCs und Physio'), ('injuries', 'nur Physio/RPC'), ('plans', 'nur RPC'),
  ('invitations', 'nur RPC'), ('treaters', 'nur Physio'), ('history_entries', 'nur Physio'), ('account_events', 'nur redeem_invitation');
GRANT SELECT ON locked, not_locked TO PUBLIC;
SELECT t.is((SELECT string_agg(c.relname, ', ') FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
              JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname IN ('patient_id', 'id') AND (a.attname = 'patient_id' OR c.relname = 'patients')
             WHERE n.nspname = 'public' AND c.relkind = 'r'
               AND c.relname NOT IN (SELECT tbl FROM locked UNION SELECT tbl FROM not_locked)), NULL,
            'jede Tabelle mit patient_id ist als gesperrt oder ohne Patienten-Schreibweg eingeordnet');
SELECT t.ok(EXISTS (SELECT 1 FROM pg_trigger tg WHERE tg.tgrelid = ('public.' || l.tbl)::regclass AND tg.tgname = 't10_lock_patient_for_write'
                      AND tg.tgtype & 1 = 1 AND tg.tgtype & 2 = 2 AND tg.tgtype & (4 | 8 | 16) = (4 | 8 | 16)),
            l.tbl || ': BEFORE INSERT/UPDATE/DELETE FOR EACH ROW Schreibsperre') FROM locked l;
SELECT t.ok((SELECT p.prosecdef AND 'search_path=""' = ANY (p.proconfig) FROM pg_proc p WHERE p.oid = 'app.lock_patient_for_write()'::regprocedure),
            'Sperr-Funktion ist Definer mit search_path = ''''');
SELECT t.is((SELECT string_agg(DISTINCT pol.tablename, ', ') FROM pg_policies pol
              WHERE pol.schemaname = 'public' AND pol.tablename IN (SELECT tbl FROM not_locked) AND pol.cmd <> 'SELECT'
                AND (coalesce(pol.qual, '') || coalesce(pol.with_check, '')) LIKE '%current_patient_id%'), NULL,
            'Tabellen ohne Sperre haben keine Schreib-Policy fuer Patienten');
-- Schreibversuche bei inaktivem Status (Bindung bleibt bestehen)
\o
SELECT id AS plan_a1 FROM public.plans WHERE patient_id = t.id('pat_a1') \gset
\o /dev/null
UPDATE public.patients SET status = 'access_deleted' WHERE id = t.id('pat_a1');
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.throws(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (gen_random_uuid(), %L, %L, current_date, ''checklist'')', t.id('pat_a1'), :'plan_a1'), '42501', 'access_deleted: training_sessions');
SELECT t.throws(format('INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status) VALUES (gen_random_uuid(), %L, %L, current_date, ''done'')', t.id('pat_a1'), t.id('ts_pat_a1')), '42501', 'access_deleted: exercise_results');
SELECT t.throws(format('INSERT INTO public.appointments (patient_id, starts_at, title) VALUES (%L, now(), ''x'')', t.id('pat_a1')), '42501', 'access_deleted: appointments');
SELECT t.throws('SELECT public.accept_consent(''physio_sharing'', ''physio_sharing-9'')', '42501', 'access_deleted: consents (accept_consent)');
-- Trigger allein (ohne RLS): eine Definer-Funktion (nur in dieser Test-Datenbank) schreibt im Namen
-- des Patienten, nachdem dessen Status gewechselt hat -> die Sperre verweigert
SELECT t.as_admin();
UPDATE public.patients SET status = 'active' WHERE id = t.id('pat_a1');
CREATE FUNCTION public.zz_insert_consent_after_status(p uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  UPDATE public.patients SET status = 'deleting' WHERE id = p;
  INSERT INTO public.consents (patient_id, kind, version) VALUES (p, 'physio_sharing', 'x-1');
END $$;
ALTER FUNCTION public.zz_insert_consent_after_status(uuid) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION public.zz_insert_consent_after_status(uuid) TO authenticated;
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.throws(format('SELECT public.zz_insert_consent_after_status(%L)', t.id('pat_a1')), '42501', 'Trigger allein: Patienten-Schreibvorgang bei Status deleting -> 42501', 'patient_not_active');
SELECT t.as_admin();
DROP FUNCTION public.zz_insert_consent_after_status(uuid);
-- Physio und Seed sind ausgenommen
UPDATE public.patients SET status = 'access_deleted' WHERE id = t.id('pat_a1');
SELECT t.as_user(t.id('phys_a1'));
SELECT t.lives(format('INSERT INTO public.appointments (patient_id, starts_at, title) VALUES (%L, now(), ''Physio'')', t.id('pat_a1')), 'Physio schreibt trotz access_deleted');
SELECT t.as_service();
SELECT t.lives(format('INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode) VALUES (gen_random_uuid(), %L, %L, current_date, ''checklist'')', t.id('pat_a1'), :'plan_a1'), 'Seed schreibt trotz access_deleted');
