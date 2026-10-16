-- DB-T68a patient_can_see_exercise (Plan 12.2, 6.7 Nr. 2, MAJOR-2, N-16): Hilfsfunktion und
-- exercises-Policy ohne Storage: aktive und vorbereitete Positionen -> sichtbar, zu jeder Uhrzeit
-- (Fixtures a/b, Server-Uhr 22:30 und 00:30 UTC); Uebung eines fremden oder abgeschlossenen Plans
-- -> nicht sichtbar.
\set ON_ERROR_STOP 1
\o /dev/null
\set fx_a `cat "$SUPABASE_DIR/tests/fixtures/local_day/a_berlin_0030_release_on_d.json"`
\set fx_b `cat "$SUPABASE_DIR/tests/fixtures/local_day/b_berlin_2330_day_before.json"`
SELECT t.seed_base();
-- Annas Plan: ex_cat1 aktiv, ex_cat2 vorbereitet ab Phase 2 (Vorlage); dazu ex_cat3 vorbereitet ab Datum D
SELECT t.as_admin();
INSERT INTO public.plan_items (id, plan_id, phase_id, exercise_id, position, release, release_on)
SELECT t.id('it_d'), pl.id, pl.current_phase_id, t.id('ex_cat3'), 9, 'prepared', (:'fx_a'::jsonb -> 'item' ->> 'release_on')::date
  FROM public.plans pl WHERE pl.patient_id = t.id('pat_a1');
SELECT t.is((:'fx_a'::jsonb -> 'item' ->> 'release_on'), (:'fx_b'::jsonb -> 'item' ->> 'release_on'), 'Fixtures a und b verwenden dasselbe release_on');
SELECT t.is(((:'fx_a'::jsonb -> 'case' ->> 'utc_instant')::timestamptz AT TIME ZONE (:'fx_a'::jsonb -> 'case' ->> 'timezone'))::date,
            (:'fx_a'::jsonb -> 'case' ->> 'local_day')::date, 'Fixture a: local_day passt zur Postgres-Zeitzone');
SELECT t.is(((:'fx_b'::jsonb -> 'case' ->> 'utc_instant')::timestamptz AT TIME ZONE (:'fx_b'::jsonb -> 'case' ->> 'timezone'))::date,
            (:'fx_b'::jsonb -> 'case' ->> 'local_day')::date, 'Fixture b: local_day passt zur Postgres-Zeitzone');

DO $$
DECLARE ts timestamptz;
BEGIN
  FOREACH ts IN ARRAY ARRAY['2026-07-14T22:30:00Z', '2026-07-15T00:30:00Z', '2026-07-14T21:30:00Z', '2026-07-14T22:30:00Z']::timestamptz[] LOOP
    PERFORM t.as_admin();
    PERFORM t.set_clock(ts);
    PERFORM t.as_user(t.id('anon_a1'), true);
    PERFORM t.ok(app.patient_can_see_exercise(t.id('ex_cat1')), format('%s UTC: aktive Position sichtbar (Hilfsfunktion)', ts));
    PERFORM t.ok(app.patient_can_see_exercise(t.id('ex_cat2')), format('%s UTC: vorbereitet ab Phase sichtbar', ts));
    PERFORM t.ok(app.patient_can_see_exercise(t.id('ex_cat3')), format('%s UTC: vorbereitet ab Datum D sichtbar', ts));
    PERFORM t.is(t.count('SELECT 1 FROM public.exercises WHERE id IN (''' || t.id('ex_cat1') || ''',''' || t.id('ex_cat2') || ''',''' || t.id('ex_cat3') || ''')'),
                 3::bigint, format('%s UTC: exercises-Policy liefert alle drei', ts));
  END LOOP;
END $$;
SELECT t.as_admin();
SELECT t.reset_clock();
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(app.patient_can_see_exercise(t.id('ex_a1')), false, 'Uebung aus Claras Plan (fremder Plan) nicht sichtbar');
SELECT t.is(t.count(format('SELECT 1 FROM public.exercises WHERE id = %L', t.id('ex_a1'))), 0::bigint, 'Policy: fremde Plan-Uebung nicht lesbar');
SELECT t.is(app.patient_can_see_exercise(t.id('ex_b1')), false, 'Uebung der Praxis B nicht sichtbar');
-- abgeschlossener Plan (Nachbildung Verletzungswechsel) mit neuem Plan ohne ex_cat1
SELECT t.as_admin();
UPDATE public.injuries SET closed_on = t.today() WHERE patient_id = t.id('pat_a1');
UPDATE public.plans SET closed = true WHERE patient_id = t.id('pat_a1');
INSERT INTO public.injuries (id, patient_id, label, reference_date, started_on) VALUES (t.id('inj_new'), t.id('pat_a1'), 'Neu', t.today(), t.today());
INSERT INTO public.plans (id, patient_id, injury_id) VALUES (t.id('plan_new'), t.id('pat_a1'), t.id('inj_new'));
INSERT INTO public.phases (id, plan_id, position, title, planned_weeks) VALUES (t.id('phn'), t.id('plan_new'), 0, 'Neu', 1);
INSERT INTO public.plan_items (id, plan_id, phase_id, exercise_id, position) VALUES (t.id('itn'), t.id('plan_new'), t.id('phn'), t.id('ex_a1'), 0);
SELECT t.as_user(t.id('anon_a1'), true);
SELECT t.is(app.patient_can_see_exercise(t.id('ex_cat1')), false, 'Uebung nur im abgeschlossenen Plan -> nicht sichtbar');
SELECT t.is(t.count(format('SELECT 1 FROM public.exercises WHERE id = %L', t.id('ex_cat1'))), 0::bigint, 'Policy: Uebung des abgeschlossenen Plans nicht lesbar');
SELECT t.is(app.patient_can_see_exercise(t.id('ex_a1')), true, 'Uebung des neuen aktuellen Plans sichtbar');
SELECT t.is(t.count('SELECT 1 FROM public.plans'), 2::bigint, 'Patient liest weiter beide Plaene (auch den abgeschlossenen)');
