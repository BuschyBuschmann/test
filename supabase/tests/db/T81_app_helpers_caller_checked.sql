-- DB-T81 app_helpers_caller_checked (Plan 12.2, 6.1 Nr. 5, MAJOR-A, MINOR-C, MINOR-9):
-- current_injury_id, current_plan_id, physio_can_see_patient liefern fuer fremde Patienten
-- null/false (Physio fremder Praxis, anderer Patient, anonym); gebundener Patient mit eigener ID:
-- physio_can_see_patient = false, current_injury_id/current_plan_id = eigene Werte; als Patient
-- scheitern die Physio-Wege; active_injury_id_internal fuer authenticated/anon nicht ausfuehrbar;
-- config.toml exponiert nur public. (practice_notes: L7.)
\set ON_ERROR_STOP 1
\o /dev/null
\set cfg `cat "$SUPABASE_DIR/config.toml"`
SELECT t.seed_base();
\o
SELECT pl.id AS plan_a1, pl.injury_id AS injury_a1 FROM public.plans pl WHERE pl.patient_id = t.id('pat_a1') \gset
\o /dev/null
-- Physio fremder Praxis
SELECT t.as_user(t.id('phys_b1'));
SELECT t.is(app.physio_can_see_patient(t.id('pat_a1')), false, 'Physio B: physio_can_see_patient(Anna) = false');
SELECT t.is(app.current_injury_id(t.id('pat_a1')), NULL::uuid, 'Physio B: current_injury_id(Anna) = null');
SELECT t.is(app.current_plan_id(t.id('pat_a1')), NULL::uuid, 'Physio B: current_plan_id(Anna) = null');
-- Physio derselben Praxis
SELECT t.as_user(t.id('phys_a2'));
SELECT t.is(app.current_injury_id(t.id('pat_a1')), :'injury_a1'::uuid, 'Physio A2: current_injury_id(Anna) = Wert');
SELECT t.is(app.current_plan_id(t.id('pat_a1')), :'plan_a1'::uuid, 'Physio A2: current_plan_id(Anna) = Wert');
-- anderer Patient derselben Praxis
SELECT t.as_user(t.id('anon_a3'), true);
SELECT t.is(app.physio_can_see_patient(t.id('pat_a1')), false, 'Clara: physio_can_see_patient(Anna) = false');
SELECT t.is(app.current_injury_id(t.id('pat_a1')), NULL::uuid, 'Clara: current_injury_id(Anna) = null');
SELECT t.is(app.current_plan_id(t.id('pat_a1')), NULL::uuid, 'Clara: current_plan_id(Anna) = null');
-- anonym, ungebunden
SELECT t.as_admin();
INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_free'), true);
SELECT t.as_user(t.id('anon_free'), true);
SELECT t.is(app.physio_can_see_patient(t.id('pat_a1')), false, 'ungebunden: physio_can_see_patient = false');
SELECT t.is(app.current_injury_id(t.id('pat_a1')), NULL::uuid, 'ungebunden: current_injury_id = null');
SELECT t.is(app.current_plan_id(t.id('pat_a1')), NULL::uuid, 'ungebunden: current_plan_id = null');
-- Patient mit eigener ID (MAJOR-A)
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(app.physio_can_see_patient(t.id('pat_a1')), false, 'Anna, eigene ID: physio_can_see_patient = false');
SELECT t.is(app.current_injury_id(t.id('pat_a1')), :'injury_a1'::uuid, 'Anna, eigene ID: current_injury_id = eigene Verletzung');
SELECT t.is(app.current_plan_id(t.id('pat_a1')), :'plan_a1'::uuid, 'Anna, eigene ID: current_plan_id = eigener Plan');
-- Physio-Wege als Patient
SELECT t.is(t.val(format('WITH u AS (UPDATE public.patients SET first_name = ''X'' WHERE id = %L RETURNING 1) SELECT count(*) FROM u', t.id('pat_a1'))), '0', 'Patient: UPDATE patients.first_name 0 Zeilen');
SELECT t.is(t.val(format('WITH u AS (UPDATE public.injuries SET label = ''X'' WHERE patient_id = %L RETURNING 1) SELECT count(*) FROM u', t.id('pat_a1'))), '0', 'Patient: UPDATE injuries.label 0 Zeilen');
SELECT t.throws(format('INSERT INTO public.treaters (patient_id, role, name) VALUES (%L, ''A'', ''B'')', t.id('pat_a1')), '42501', 'Patient: INSERT treaters verweigert');
SELECT t.throws(format('INSERT INTO public.history_entries (patient_id, kind, title) VALUES (%L, ''A'', ''B'')', t.id('pat_a1')), '42501', 'Patient: INSERT history_entries verweigert');
SELECT t.is(t.count('SELECT id, patient_id FROM public.invitations'), 0::bigint, 'Patient: invitations 0 Zeilen');
-- interne Varianten
SELECT t.throws(format('SELECT app.active_injury_id_internal(%L)', t.id('pat_a3')), '42501', 'authenticated: active_injury_id_internal nicht ausfuehrbar');
SELECT t.throws(format('SELECT app.injury_for_patient_day(%L, current_date)', t.id('pat_a3')), '42501', 'authenticated: injury_for_patient_day nicht ausfuehrbar');
SELECT t.throws('SELECT app.utc_today()', '42501', 'authenticated: app.utc_today nicht ausfuehrbar');
SELECT t.throws('SELECT app.invite_pepper()', '42501', 'authenticated: app.invite_pepper nicht ausfuehrbar');
SELECT t.throws('SELECT value FROM app.secrets', '42501', 'authenticated: app.secrets nicht lesbar');
SELECT t.as_anon();
SELECT t.throws(format('SELECT app.active_injury_id_internal(%L)', t.id('pat_a3')), '42501', 'anon: active_injury_id_internal nicht ausfuehrbar');
SELECT t.as_admin();
SELECT t.ok(NOT has_function_privilege('authenticated', p.oid, 'EXECUTE'), 'kein EXECUTE fuer authenticated: ' || p.oid::regprocedure::text)
  FROM pg_proc p WHERE p.pronamespace = 'app'::regnamespace
   AND p.proname IN ('active_injury_id_internal', 'injury_for_patient_day', 'is_privileged_session', 'utc_now', 'utc_today', 'invite_pepper',
                     'invite_code_hmac', 'new_invitation', 'copy_template_into_plan', 'on_rebind', 'check_local_day_immediate', 'normalize_invite_code');
-- config.toml: [api] schemas = ["public"]
SELECT t.is((regexp_match(:'cfg', '\[api\][^\[]*?\n\s*schemas\s*=\s*(\[[^\]]*\])'))[1], '["public"]', 'config.toml: [api] schemas = ["public"]');
SELECT t.ok(:'cfg' !~ '"app"', 'config.toml nennt das Schema app nicht');
