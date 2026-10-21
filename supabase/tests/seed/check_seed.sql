-- Pruefungen des Testdaten-Seeds (Plan Ausschnitt 2, Abschnitt 10; Teil von DB-T40):
-- erwartete Datensaetze, Kennzeichnung als Testdaten, Rechte der Rollen auf den Seed-Daten.
-- Laeuft als Superuser/Migrationsrolle gegen eine Datenbank, in der der Seed gelaufen ist
-- (lokal: run_seed_local_pg.sh; im Stack zusaetzlich nach X2-4, dort ohne die Nachbildung).
--
--   psql -X -v ON_ERROR_STOP=1 -v code_lena=<Einladungscode> -f check_seed.sql
-- code_lena ist optional; mit Code wird zusaetzlich eingeloest und die Sicht des Patienten geprueft.
-- Ausgabe: "NOTICE:  ok - <Text>"; ein Fehlschlag bricht mit "not ok - <Text>" ab.

\set ON_ERROR_STOP 1
SET client_min_messages = notice;

DROP SCHEMA IF EXISTS seedchk CASCADE;
CREATE SCHEMA seedchk;
GRANT USAGE ON SCHEMA seedchk TO PUBLIC;

CREATE FUNCTION seedchk.ok(p_cond boolean, p_msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_cond IS TRUE THEN RAISE NOTICE 'ok - %', p_msg;
  ELSE RAISE EXCEPTION 'not ok - %', p_msg; END IF;
END $$;

CREATE FUNCTION seedchk.eq(p_got anyelement, p_want anyelement, p_msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_got IS NOT DISTINCT FROM p_want THEN RAISE NOTICE 'ok - %', p_msg;
  ELSE RAISE EXCEPTION 'not ok - % (erhalten: %, erwartet: %)', p_msg, p_got, p_want; END IF;
END $$;

CREATE FUNCTION seedchk.n(p_sql text) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v bigint;
BEGIN
  EXECUTE 'SELECT count(*) FROM (' || p_sql || ') s' INTO v;
  RETURN v;
END $$;

-- Zeilenzahl oder -1 bei fehlendem Recht (42501)
CREATE FUNCTION seedchk.n_or_denied(p_sql text) RETURNS bigint LANGUAGE plpgsql AS $$
BEGIN
  RETURN seedchk.n(p_sql);
EXCEPTION WHEN insufficient_privilege THEN
  RETURN -1;
END $$;

CREATE FUNCTION seedchk.as_user(p_uid uuid, p_anonymous boolean DEFAULT false) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE 'RESET ROLE';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'role', 'authenticated', 'is_anonymous', p_anonymous)::text, false);
  EXECUTE 'SET ROLE authenticated';
END $$;

CREATE FUNCTION seedchk.reset() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE 'RESET ROLE';
  PERFORM set_config('request.jwt.claims', '', false);
END $$;

CREATE FUNCTION seedchk.physio(p_email text) RETURNS uuid LANGUAGE sql STABLE AS
  $$ SELECT id FROM auth.users WHERE email = p_email $$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA seedchk TO PUBLIC;

-- ---------------------------------------------------------------------------
-- 1. Umfang und Kennzeichnung als Testdaten (Admin-Sicht)
-- ---------------------------------------------------------------------------
SELECT seedchk.eq((SELECT count(*) FROM public.practices WHERE is_test), 2::bigint, '2 Test-Praxen');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.practices WHERE is_test AND name NOT LIKE '%Testdaten%'),
                  'Praxisnamen tragen die Kennzeichnung "Testdaten"');
SELECT seedchk.ok((SELECT bool_and(c = 2) AND count(*) = 2
                     FROM (SELECT count(*) c FROM public.physios ph
                             JOIN public.practices pr ON pr.id = ph.practice_id AND pr.is_test
                            GROUP BY pr.id) s),
                  'je Test-Praxis genau 2 Physios');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.physios ph
                               JOIN public.practices pr ON pr.id = ph.practice_id AND pr.is_test
                               JOIN auth.users u ON u.id = ph.id
                              WHERE u.email NOT LIKE '%@test.curaone.invalid'),
                  'alle Test-Physios haben ein Konto @test.curaone.invalid');
SELECT seedchk.eq((SELECT count(*) FROM public.patients p JOIN public.practices pr ON pr.id = p.practice_id AND pr.is_test),
                  5::bigint, '5 Test-Patienten');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.patients p JOIN public.practices pr ON pr.id = p.practice_id AND pr.is_test
                               WHERE p.last_name IS DISTINCT FROM 'Testperson'),
                  'Test-Patienten sind erfundene "Testperson"-Eintraege');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.patients p JOIN public.practices pr ON pr.id = p.practice_id AND pr.is_test
                               LEFT JOIN public.physios ph ON ph.id = p.main_physio_id AND ph.practice_id = p.practice_id
                              WHERE ph.id IS NULL),
                  'jeder Test-Patient hat einen Hauptphysio seiner Praxis');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.patients p JOIN public.practices pr ON pr.id = p.practice_id AND pr.is_test
                               WHERE p.status <> 'invited' OR p.auth_user_id IS NOT NULL),
                  'Test-Patienten sind eingeladen und ungebunden (Codes nur auf der Konsole)');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.patients p JOIN public.practices pr ON pr.id = p.practice_id AND pr.is_test
                               WHERE (SELECT count(*) FROM public.invitations i WHERE i.patient_id = p.id
                                        AND i.redeemed_at IS NULL AND i.revoked_at IS NULL) <> 1),
                  'jeder Test-Patient hat genau eine offene Einladung');

-- ---------------------------------------------------------------------------
-- 2. Katalog, Vorlagen
-- ---------------------------------------------------------------------------
SELECT seedchk.eq((SELECT count(*) FROM public.exercises WHERE practice_id IS NULL AND created_by_role = 'seed' AND is_example),
                  15::bigint, '15 Katalog-Uebungen (Beispiel)');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.exercises WHERE practice_id IS NULL AND created_by_role = 'seed'
                               AND (description NOT LIKE 'Beispiel%(Testdaten)%' OR short_instruction IS NULL
                                    OR cardinality(locations) = 0)),
                  'Katalog gekennzeichnet (Beispiel/Testdaten), mit Kurzanleitung und Ort');
SELECT seedchk.ok(EXISTS (SELECT 1 FROM public.exercises WHERE practice_id IS NULL AND created_by_role = 'seed'
                           AND cardinality(materials) > 0 AND pause_sec IS NOT NULL),
                  'Baukasten-Felder Material und Pause gesetzt');
SELECT seedchk.eq((SELECT count(*) FROM public.plan_templates WHERE practice_id IS NULL AND is_example AND created_by_role = 'seed'),
                  3::bigint, '3 Beispielvorlagen');
SELECT seedchk.eq((SELECT count(*) FROM public.exercises e JOIN public.practices pr ON pr.id = e.practice_id AND pr.is_test),
                  2::bigint, '2 praxiseigene Test-Uebungen');

-- ---------------------------------------------------------------------------
-- 3. Verletzungen, Plaene, Phasen, Positionen
-- ---------------------------------------------------------------------------
CREATE TEMP VIEW tp AS
  SELECT p.* FROM public.patients p JOIN public.practices pr ON pr.id = p.practice_id AND pr.is_test;

SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM tp WHERE (SELECT count(*) FROM public.injuries i WHERE i.patient_id = tp.id AND i.closed_on IS NULL) <> 1),
                  'jeder Patient hat genau eine aktive Verletzung');
SELECT seedchk.eq((SELECT count(*) FROM public.injuries i JOIN tp ON tp.id = i.patient_id WHERE i.closed_on IS NOT NULL),
                  1::bigint, 'ein Patient mit abgeschlossener frueherer Verletzung (Historie)');
SELECT seedchk.ok(EXISTS (SELECT 1 FROM public.injuries i JOIN public.plans pl ON pl.injury_id = i.id
                           WHERE i.closed_on IS NOT NULL AND pl.closed AND pl.current_phase_id IS NOT NULL
                             AND EXISTS (SELECT 1 FROM public.training_sessions ts WHERE ts.plan_id = pl.id AND ts.injury_id = i.id)),
                  'abgeschlossene Verletzung: geschlossener Plan mit Verlauf');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.injuries i JOIN tp ON tp.id = i.patient_id
                               LEFT JOIN public.plans pl ON pl.injury_id = i.id
                              WHERE pl.id IS NULL OR pl.closed <> (i.closed_on IS NOT NULL)
                                 OR pl.current_phase_id IS NULL OR pl.version <> 1),
                  'zu jeder Verletzung ein Plan, aktuelle Phase gesetzt, geschlossen nur bei abgeschlossener Verletzung');
SELECT seedchk.ok((SELECT count(DISTINCT ph.position) >= 3
                     FROM public.plans pl JOIN tp ON tp.id = pl.patient_id AND NOT pl.closed
                     JOIN public.phases ph ON ph.id = pl.current_phase_id),
                  'Patienten stehen in unterschiedlichen Phasen (mindestens 3 verschiedene)');
SELECT seedchk.ok(EXISTS (SELECT 1 FROM public.plan_items pi JOIN tp ON tp.id = (SELECT patient_id FROM public.plans WHERE id = pi.plan_id)
                           WHERE pi.release = 'prepared' AND pi.release_on IS NOT NULL)
              AND EXISTS (SELECT 1 FROM public.plan_items pi JOIN tp ON tp.id = (SELECT patient_id FROM public.plans WHERE id = pi.plan_id)
                           WHERE pi.release = 'prepared' AND pi.release_with_phase_id IS NOT NULL),
                  'Positionen "vorbereitet" nach Datum und nach Phase');
SELECT seedchk.ok(EXISTS (SELECT 1 FROM public.plan_items WHERE easier_variant_of IS NOT NULL),
                  'mindestens eine leichtere Variante');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.plan_items pi
                               JOIN public.exercises e ON e.id = pi.exercise_id
                               JOIN public.plans pl ON pl.id = pi.plan_id
                               JOIN public.patients p ON p.id = pl.patient_id
                              WHERE e.practice_id IS NOT NULL AND e.practice_id <> p.practice_id),
                  'keine Position nutzt eine Uebung einer fremden Praxis');

-- ---------------------------------------------------------------------------
-- 4. Akte, Termine, Training
-- ---------------------------------------------------------------------------
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM tp WHERE NOT EXISTS (SELECT 1 FROM public.appointments a WHERE a.patient_id = tp.id AND a.starts_at > app.utc_now())),
                  'jeder Patient hat einen kommenden Termin');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.appointments a JOIN tp ON tp.id = a.patient_id
                               WHERE a.created_by_role <> 'physio' OR a.created_by IS DISTINCT FROM tp.main_physio_id),
                  'Termine gehoeren dem Hauptphysio (bearbeitbar)');
SELECT seedchk.ok((SELECT count(*) FROM public.treaters t JOIN tp ON tp.id = t.patient_id) >= 3
                  AND (SELECT count(*) FROM public.history_entries h JOIN tp ON tp.id = h.patient_id) >= 3,
                  'Akte: Behandler und Verlaufseintraege vorhanden');
SELECT seedchk.ok(EXISTS (SELECT 1 FROM public.training_sessions ts JOIN tp ON tp.id = ts.patient_id
                           GROUP BY ts.patient_id
                          HAVING min(ts.local_day) = app.utc_today() - 14 AND max(ts.local_day) = app.utc_today() - 1),
                  'Training ueber 14 Tage (heute-14 bis gestern)');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.training_sessions ts JOIN tp ON tp.id = ts.patient_id
                               WHERE ts.local_day >= app.utc_today()),
                  'keine Einheit heute oder in der Zukunft');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.training_sessions ts JOIN public.plans pl ON pl.id = ts.plan_id
                               WHERE ts.injury_id IS DISTINCT FROM pl.injury_id),
                  'injury_id der Einheiten per Trigger gesetzt (= Verletzung des Plans)');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.exercise_results er JOIN public.training_sessions ts ON ts.id = er.training_session_id
                               WHERE er.injury_id IS DISTINCT FROM ts.injury_id OR er.patient_id <> ts.patient_id),
                  'injury_id der Ergebnisse = Verletzung der Einheit');
SELECT seedchk.ok(EXISTS (SELECT 1 FROM public.exercise_results WHERE status = 'skipped')
              AND EXISTS (SELECT 1 FROM public.exercise_results WHERE status = 'done'),
                  'Ergebnisse mit abgehakten und uebersprungenen Uebungen');
SELECT seedchk.ok(EXISTS (SELECT 1 FROM public.training_sessions WHERE mode = 'guided')
              AND EXISTS (SELECT 1 FROM public.training_sessions WHERE mode = 'checklist'),
                  'beide Modi (gefuehrt, Checkliste) vertreten');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.training_sessions ts
                               WHERE jsonb_array_length(ts.items) <> (SELECT count(*) FROM public.exercise_results er WHERE er.training_session_id = ts.id)),
                  'Momentaufnahme der Einheit passt zu den Ergebnissen');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.training_sessions ts WHERE ts.streak_after < 1), 'streak_after >= 1');
SELECT seedchk.ok(NOT EXISTS (SELECT 1 FROM public.training_sessions ts
                               WHERE ts.streak_after <> 1 + coalesce((SELECT t2.streak_after FROM public.training_sessions t2
                                                                       WHERE t2.patient_id = ts.patient_id AND t2.plan_id = ts.plan_id
                                                                         AND t2.local_day = ts.local_day - 1), 0)),
                  'streak_after zaehlt aufeinanderfolgende Trainingstage');

-- ---------------------------------------------------------------------------
-- 5. Rechte auf den Seed-Daten
-- ---------------------------------------------------------------------------
SELECT seedchk.as_user(seedchk.physio('nord1@test.curaone.invalid'));
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.patients'), 3::bigint, 'Physio Nord 1 sieht nur die 3 Patienten der eigenen Praxis');
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.practices'), 1::bigint, 'Physio Nord 1 sieht nur die eigene Praxis');
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.exercises'), 16::bigint, 'Katalog (15) + eigene Uebung der Praxis; keine fremde Praxis-Uebung');
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.plan_templates'), 3::bigint, 'Physio sieht die Beispielvorlagen');
SELECT seedchk.ok(seedchk.n('SELECT 1 FROM public.training_sessions') > 0
                  AND seedchk.n('SELECT 1 FROM public.training_sessions ts JOIN public.patients p ON p.id = ts.patient_id WHERE p.last_name <> ''Testperson''') = 0
                  AND seedchk.n('SELECT 1 FROM public.training_sessions ts WHERE ts.patient_id NOT IN (SELECT id FROM public.patients)') = 0,
                  'Verlauf: nur Patienten der eigenen Praxis sichtbar');
SELECT seedchk.eq(seedchk.n_or_denied('SELECT code_hmac FROM public.invitations'), -1::bigint, 'code_hmac ist fuer den Physio nicht lesbar');
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.appointments WHERE created_by = auth.uid()'),
                  seedchk.n('SELECT 1 FROM public.appointments a JOIN public.patients p ON p.id = a.patient_id WHERE p.main_physio_id = auth.uid()'),
                  'Physio sieht seine eigenen Termine als bearbeitbar angelegt');
SELECT seedchk.reset();

SELECT seedchk.as_user(seedchk.physio('sued2@test.curaone.invalid'));
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.patients'), 2::bigint, 'Physio Sued 2 sieht nur die 2 Patienten der Praxis Sued');
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.exercises'), 16::bigint, 'Sued: Katalog + eigene Uebung, nicht die der Praxis Nord');
SELECT seedchk.reset();

-- anonym und unbekannte Identitaet: nichts
SET ROLE anon;
SELECT seedchk.eq(seedchk.n_or_denied('SELECT 1 FROM public.patients'), -1::bigint, 'anon: kein Zugriff auf Patienten');
SELECT seedchk.reset();
SELECT seedchk.as_user(gen_random_uuid(), true);
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.patients') + seedchk.n('SELECT 1 FROM public.training_sessions')
                  + seedchk.n('SELECT 1 FROM public.exercises') + seedchk.n('SELECT 1 FROM public.plan_templates'),
                  0::bigint, 'ungebundene anonyme Sitzung sieht keine Seed-Daten');
SELECT seedchk.reset();

-- service_role (Seed-Rolle): Einladungs-HMAC bleibt auch fuer sie gesperrt
SET ROLE service_role;
SELECT seedchk.eq(seedchk.n_or_denied('SELECT code_hmac FROM public.invitations'), -1::bigint, 'code_hmac ist auch fuer service_role nicht lesbar');
SELECT seedchk.reset();

-- ---------------------------------------------------------------------------
-- 6. Optional: Einladungscode einloesen und Sicht des Patienten (nur mit -v code_lena=...)
-- ---------------------------------------------------------------------------
\if :{?code_lena}
INSERT INTO auth.users (id, is_anonymous) VALUES ('0e1e0000-0000-4000-8000-0000000000a1', true) ON CONFLICT (id) DO NOTHING;
SELECT seedchk.as_user('0e1e0000-0000-4000-8000-0000000000a1', true);
SELECT seedchk.eq(public.redeem_invitation(:'code_lena'), 'ok', 'Einladungscode eines Test-Patienten wird eingeloest');
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.patients'), 1::bigint, 'Patient sieht nur sich selbst');
SELECT seedchk.ok(seedchk.n('SELECT 1 FROM public.training_sessions') >= 10
                  AND seedchk.n('SELECT 1 FROM public.training_sessions WHERE patient_id <> (SELECT id FROM public.patients)') = 0,
                  'Patient sieht seinen Trainingsverlauf (mindestens 10 Einheiten), sonst nichts');
SELECT seedchk.ok(seedchk.n('SELECT 1 FROM public.plan_items') > 0 AND seedchk.n('SELECT 1 FROM public.exercises') > 0
                  AND seedchk.n('SELECT 1 FROM public.exercises') < 15,
                  'Patient sieht Plan und nur die Uebungen seines Plans');
SELECT seedchk.eq(seedchk.n('SELECT 1 FROM public.plan_templates'), 0::bigint, 'Patient sieht keine Vorlagen');
SELECT seedchk.reset();
\endif

DROP SCHEMA seedchk CASCADE;
