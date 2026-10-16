-- DB-T85 manny_look_patient_only (Plan 12.2, O-41, N-16, Auflage NIT-1): set_manny_look setzt nur
-- die eigene Zeile; ungueltiger Wert -> Fehler; direktes UPDATE auf patients.manny_look ->
-- permission denied; Physio und anonyme/ungebundene Sitzung -> 42501; Status <> active -> 42501;
-- delete_my_data -> manny_look = null; Physio hat kein Leserecht (NIT-1).
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.lives('SELECT public.set_manny_look(''ohne'')', 'Patient setzt eigenen Look');
SELECT t.is(public.get_my_manny_look(), 'ohne', 'Patient liest eigenen Look ueber get_my_manny_look');
SELECT t.lives('SELECT public.set_manny_look(''ohne'')', 'gleicher Wert erneut: idempotent');
SELECT t.throws('SELECT public.set_manny_look(''pink'')', '22023', 'ungueltiger Wert -> invalid_manny_look', 'invalid_manny_look');
SELECT t.throws('SELECT public.set_manny_look(NULL)', '22023', 'NULL -> invalid_manny_look', 'invalid_manny_look');
SELECT t.throws(format('UPDATE public.patients SET manny_look = ''brille'' WHERE id = %L', t.id('pat_a1')), '42501', 'direktes UPDATE manny_look -> permission denied');
SELECT t.throws('SELECT manny_look FROM public.patients', '42501', 'Patient: SELECT manny_look direkt -> permission denied (nur ueber RPC)');
SELECT t.as_admin();
SELECT t.is((SELECT manny_look FROM public.patients WHERE id = t.id('pat_a1')), 'ohne', 'eigene Zeile gesetzt');
SELECT t.is((SELECT string_agg(coalesce(manny_look, '-'), ',' ORDER BY first_name) FROM public.patients WHERE id <> t.id('pat_a1')), '-,brille,brille', 'andere Zeilen unveraendert');
-- Physio
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws('SELECT public.set_manny_look(''brille'')', '42501', 'Physio: set_manny_look -> 42501');
SELECT t.throws('SELECT public.get_my_manny_look()', '42501', 'Physio: get_my_manny_look -> 42501');
SELECT t.throws('SELECT manny_look FROM public.patients', '42501', 'Physio: kein Leserecht auf patients.manny_look (NIT-1)');
SELECT t.throws(format('UPDATE public.patients SET manny_look = ''brille'' WHERE id = %L', t.id('pat_a1')), '42501', 'Physio: UPDATE manny_look -> permission denied');
SELECT t.ok(NOT has_column_privilege('authenticated', 'public.patients', 'manny_look', 'SELECT')
            AND NOT has_column_privilege('authenticated', 'public.patients', 'manny_look', 'UPDATE'), 'Katalog: kein Spaltenrecht auf manny_look');
-- anonym, ungebunden
SELECT t.as_admin();
INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_free'), true);
SELECT t.as_user(t.id('anon_free'), true);
SELECT t.throws('SELECT public.set_manny_look(''brille'')', '42501', 'ungebunden: set_manny_look -> 42501');
-- Status <> active
SELECT t.as_admin();
UPDATE public.patients SET status = 'deleting' WHERE id = t.id('pat_a3');
SELECT t.as_user(t.id('anon_a3'), true);
SELECT t.throws('SELECT public.set_manny_look(''ohne'')', '42501', 'Status deleting -> 42501');
SELECT t.as_admin();
SELECT t.is((SELECT manny_look FROM public.patients WHERE id = t.id('pat_a3')), 'brille', 'Claras Look unveraendert');
-- Loeschen setzt zurueck
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(public.delete_my_data(), 'ok', 'delete_my_data');
SELECT t.as_admin();
SELECT t.is((SELECT manny_look FROM public.patients WHERE id = t.id('pat_a1')), NULL::text, 'manny_look nach dem Loeschen = null');
-- Neubindung: Konto-Wert bleibt erhalten und ist auf dem neuen Geraet lesbar (O-44)
SELECT t.as_user(t.id('phys_b1'));
INSERT INTO t.codes SELECT 'pat_b1_new', code FROM public.regenerate_invitation(t.id('pat_b1'));
SELECT t.as_admin();
SELECT t.is(t.redeem('anon_b1_new', t.code('pat_b1_new')), 'ok_rebound', 'Neubindung Dora');
SELECT t.as_user(t.id('anon_b1_new'), true);
SELECT t.is(public.get_my_manny_look(), 'brille', 'neues Geraet liest den Konto-Wert');
