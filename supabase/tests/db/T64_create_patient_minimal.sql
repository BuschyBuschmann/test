-- DB-T64 create_patient_minimal (Plan 12.2, 6.6, PB-8): Vorname + Verletzung oder Vorlage genuegen;
-- ohne beides bzw. leerer Vorname -> Fehler; Hauptphysio = Aufrufer; Code einmalig (nur in der
-- Antwort, gespeichert nur als HMAC), genau eine offene Einladung.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
CREATE TEMP TABLE r1 AS SELECT * FROM public.create_patient(t.id('pat_m1'), 'Mia', 'Knie', NULL, t.today());
SELECT t.is((SELECT count(*) FROM r1), 1::bigint, 'Vorname + Verletzung -> angelegt');
SELECT t.lives(format('SELECT * FROM public.create_patient(%L, ''Max'', NULL, %L, %L)', t.id('pat_m2'), t.id('tpl_a'), t.today()), 'Vorname + Vorlage -> angelegt');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Moe'', NULL, NULL, %L)', gen_random_uuid(), t.today()), '22023', 'ohne Verletzung und Vorlage -> Fehler', 'injury_or_template_required');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Moe'', ''  '', NULL, %L)', gen_random_uuid(), t.today()), '22023', 'Verletzung nur Leerzeichen -> Fehler', 'injury_or_template_required');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, '''', ''Knie'', NULL, %L)', gen_random_uuid(), t.today()), '22023', 'leerer Vorname -> Fehler', 'first_name_required');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, NULL, ''Knie'', NULL, %L)', gen_random_uuid(), t.today()), '22023', 'Vorname NULL -> Fehler', 'first_name_required');
SELECT t.throws(format('SELECT * FROM public.create_patient(NULL, ''Moe'', ''Knie'', NULL, %L)', t.today()), '22023', 'id NULL -> Fehler', 'id_required');
SELECT t.is((SELECT main_physio_id FROM public.patients WHERE id = t.id('pat_m1')), t.id('phys_a1'), 'Hauptphysio = Aufrufer');
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_m1')), 'invited', 'Status invited');
SELECT t.is((SELECT practice_id FROM public.patients WHERE id = t.id('pat_m1')), t.id('practice_a'), 'Praxis = Praxis des Aufrufers');
SELECT t.is((SELECT count(*) FROM public.plans WHERE patient_id = t.id('pat_m1')), 1::bigint, 'leerer Plan angelegt');
SELECT t.is((SELECT current_phase_id FROM public.plans WHERE patient_id = t.id('pat_m1')), NULL::uuid, 'ohne Vorlage keine Phase');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_m1') AND redeemed_at IS NULL AND revoked_at IS NULL), 1::bigint, 'genau eine offene Einladung');
SELECT t.as_admin();
SELECT t.ok((SELECT create_params_hash ~ '^[0-9a-f]{64}$' FROM public.patients WHERE id = t.id('pat_m1')), 'create_params_hash gespeichert (SHA-256)');
SELECT t.is((SELECT count(*) FROM public.invitations i WHERE position(convert_to((SELECT code FROM r1), 'UTF8') IN i.code_hmac) > 0), 0::bigint, 'Klartext-Code nicht gespeichert');
SELECT t.is(t.redeem('anon_m1', (SELECT code FROM r1)), 'ok', 'Code aus der Antwort ist einloesbar');
SELECT t.is(t.redeem('anon_m1b', (SELECT code FROM r1)), 'already_used', 'Code nur einmal einloesbar');
