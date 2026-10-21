-- DB-T63 create_patient_from_template (Plan 12.2, 6.6): Vorlage mit neuen IDs kopiert, aktuelle
-- Phase = erste Phase; fremde Vorlage -> 42501; reference_date ohne Eingabe = uebergebener local_day;
-- local_day ausserhalb +-1 Tag um das UTC-Datum -> invalid_local_day (Fixture d, 6.7 Nr. 5).
\set ON_ERROR_STOP 1
\o /dev/null
\set fx_d `cat "$SUPABASE_DIR/tests/fixtures/local_day/d_out_of_range.json"`
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a2'));
CREATE TEMP TABLE r AS SELECT * FROM public.create_patient(t.id('pat_t'), 'Tom', NULL, t.id('tpl_ex'), t.today());
GRANT SELECT ON r TO PUBLIC;
SELECT t.ok((SELECT code ~ '^[0-9A-HJKMNP-TV-Z]{10}$' AND patient_id = t.id('pat_t') AND expires_at > now() FROM r), 'Rueckgabe: patient_id, Code, expires_at');
SELECT t.is((SELECT label FROM public.injuries WHERE patient_id = t.id('pat_t')), 'Knie (Beispiel)', 'Verletzung aus der Vorlage uebernommen');
SELECT t.is((SELECT reference_date FROM public.injuries WHERE patient_id = t.id('pat_t')), t.today(), 'reference_date = local_day');
SELECT t.is((SELECT started_on FROM public.injuries WHERE patient_id = t.id('pat_t')), t.today(), 'started_on = local_day');
SELECT t.is((SELECT string_agg(title || ':' || planned_weeks || ':' || position, ',' ORDER BY position) FROM public.phases ph JOIN public.plans pl ON pl.id = ph.plan_id WHERE pl.patient_id = t.id('pat_t')),
            'Phase 1:2:0,Phase 2:3:1', 'Phasen kopiert (Titel, Wochen, Reihenfolge)');
SELECT t.is((SELECT count(*) FROM public.plan_items pi JOIN public.plans pl ON pl.id = pi.plan_id WHERE pl.patient_id = t.id('pat_t')), 4::bigint, '4 Positionen kopiert');
SELECT t.is((SELECT count(*) FROM public.phases a JOIN public.plans pa ON pa.id = a.plan_id, public.phases b JOIN public.plans pb ON pb.id = b.plan_id
              WHERE pa.patient_id = t.id('pat_t') AND pb.patient_id = t.id('pat_a1') AND a.id = b.id), 0::bigint, 'neue Phasen-IDs (nicht die einer anderen Kopie)');
SELECT t.is((SELECT pl.current_phase_id = ph.id FROM public.plans pl JOIN public.phases ph ON ph.plan_id = pl.id AND ph.position = 0 WHERE pl.patient_id = t.id('pat_t')), true,
            'aktuelle Phase = erste Phase');
SELECT t.is((SELECT ph.position FROM public.plan_items pi JOIN public.plans pl ON pl.id = pi.plan_id JOIN public.phases ph ON ph.id = pi.release_with_phase_id
              WHERE pl.patient_id = t.id('pat_t') AND pi.release = 'prepared'), 1, 'vorbereitet ab Phase 2: Bezug auf die kopierte Phase');
SELECT t.is((SELECT v.exercise_id FROM public.plan_items pi JOIN public.plans pl ON pl.id = pi.plan_id JOIN public.plan_items v ON v.id = pi.easier_variant_of
              WHERE pl.patient_id = t.id('pat_t')), t.id('ex_cat2'), 'leichtere Variante (E-30) auf die kopierte Position derselben Phase');
SELECT t.is((SELECT main_physio_id FROM public.patients WHERE id = t.id('pat_t')), t.id('phys_a2'), 'Hauptphysio = Aufrufer');
-- Bezugsdatum aus der Eingabe
SELECT t.lives(format('SELECT * FROM public.create_patient(%L, ''Ute'', ''Fuss'', NULL, %L, ''Muster'', %L)', t.id('pat_u'), t.today(), '2026-01-05'), 'mit Nachname und Bezugsdatum');
SELECT t.is((SELECT reference_date FROM public.injuries WHERE patient_id = t.id('pat_u')), '2026-01-05'::date, 'reference_date = Eingabe');
SELECT t.is((SELECT last_name FROM public.patients WHERE id = t.id('pat_u')), 'Muster', 'Nachname gespeichert');
-- Verletzung angegeben + Vorlage: Eingabe gewinnt
SELECT t.lives(format('SELECT * FROM public.create_patient(%L, ''Vera'', ''Sprunggelenk'', %L, %L)', t.id('pat_v'), t.id('tpl_a'), t.today()), 'Verletzung und Vorlage');
SELECT t.is((SELECT label FROM public.injuries WHERE patient_id = t.id('pat_v')), 'Sprunggelenk', 'eingegebene Verletzung gewinnt');
-- fremde Vorlage
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''X'', NULL, %L, %L)', gen_random_uuid(), t.id('tpl_b'), t.today()), '42501', 'Vorlage der Praxis B -> 42501');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''X'', NULL, %L, %L)', gen_random_uuid(), gen_random_uuid(), t.today()), '42501', 'unbekannte Vorlage -> 42501');
-- Plausibilitaet local_day (sofortiger Aufruf) mit Fixture d bei fester Server-Uhr
SELECT t.as_admin();
SELECT t.set_clock((:'fx_d'::jsonb ->> 'server_utc_instant')::timestamptz);
SELECT t.as_user(t.id('phys_a2'));
SELECT t.is(t.today(), (:'fx_d'::jsonb ->> 'server_utc_date')::date, 'Server-Uhr auf Fixture-Zeit gesetzt');
SELECT CASE WHEN c ->> 'immediate' = 'accepted'
         THEN t.lives(format('SELECT * FROM public.create_patient(%L, ''Fix'', ''Knie'', NULL, %L)', gen_random_uuid(), c ->> 'local_day'),
                      format('local_day %s (UTC %s Tage): angenommen', c ->> 'local_day', c ->> 'offset_days'))
         ELSE t.throws(format('SELECT * FROM public.create_patient(%L, ''Fix'', ''Knie'', NULL, %L)', gen_random_uuid(), c ->> 'local_day'),
                      '22023', format('local_day %s (UTC %s Tage): invalid_local_day', c ->> 'local_day', c ->> 'offset_days'), 'invalid_local_day')
       END
  FROM jsonb_array_elements(:'fx_d'::jsonb -> 'cases') c;
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Fix'', ''Knie'', NULL, NULL)', gen_random_uuid()), '22023', 'local_day fehlt -> invalid_local_day', 'invalid_local_day');
