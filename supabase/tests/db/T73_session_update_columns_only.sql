-- DB-T73 session_update_columns_only (Plan 12.2, 6.2): Patient aendert an training_sessions nur
-- ended_at, active_seconds, ended_early, streak_after (eigene Sessions).
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(t.val(format('WITH u AS (UPDATE public.training_sessions SET ended_at = now(), active_seconds = 120, ended_early = true, streak_after = 4 WHERE id = %L RETURNING 1) SELECT count(*) FROM u',
            t.id('ts_pat_a1'))), '1', 'erlaubte Spalten aenderbar');
SELECT t.throws(format('UPDATE public.training_sessions SET %s WHERE id = %L', c, t.id('ts_pat_a1')), '42501', 'Spalte nicht aenderbar: ' || split_part(c, ' ', 1))
  FROM unnest(ARRAY['local_day = current_date - 3', 'items = ''[]''', 'mode = ''guided''', format('plan_id = %L', gen_random_uuid()),
                    format('patient_id = %L', t.id('pat_a3')), format('injury_id = %L', gen_random_uuid()), 'phase_id = NULL',
                    'plan_version = 9', 'started_at = now()', 'logged_at = now()', format('id = %L', gen_random_uuid())]) c;
SELECT t.is(t.val(format('WITH u AS (UPDATE public.training_sessions SET active_seconds = 1 WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('ts_pat_a3'))), '0',
            'fremde Session: 0 Zeilen');
SELECT t.throws(format('UPDATE public.training_sessions SET active_seconds = -1 WHERE id = %L', t.id('ts_pat_a1')), '23514', 'active_seconds negativ -> 23514');
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(t.val(format('WITH u AS (UPDATE public.training_sessions SET active_seconds = 1 WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('ts_pat_a1'))), '0',
            'Physio aendert Sessions nicht');
SELECT t.as_admin();
SELECT t.is((SELECT active_seconds || '/' || streak_after FROM public.training_sessions WHERE id = t.id('ts_pat_a1')), '120/4', 'Werte der erlaubten Aenderung');
