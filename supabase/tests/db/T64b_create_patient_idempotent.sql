-- DB-T64b create_patient_idempotent (Plan 12.2, 6.6, MINOR-1, MINOR-F; gleichzeitige Aufrufe:
-- db/race/T64b_create_patient_concurrent.sh): gleiche id mit gleichen Parametern -> kein zweiter
-- Patient, alte Einladung widerrufen, neuer Code; andere Parameter -> idempotency_mismatch, nichts
-- geaendert; fremde Praxis bzw. Status <> invited -> 42501; zwei Aufrufe nacheinander -> nur der
-- Code der zweiten Antwort ist einloesbar.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
CREATE TEMP TABLE r1 AS SELECT * FROM public.create_patient(t.id('pat_i'), ' Ida ', 'Knie', NULL, t.today());
GRANT SELECT ON r1 TO PUBLIC;
CREATE TEMP TABLE r2 AS SELECT * FROM public.create_patient(t.id('pat_i'), 'Ida', 'Knie ', NULL, t.today() - 1);
GRANT SELECT ON r2 TO PUBLIC;
SELECT t.is((SELECT count(*) FROM public.patients WHERE id = t.id('pat_i')), 1::bigint, 'Wiederholung: kein zweiter Patient');
SELECT t.is((SELECT count(*) FROM public.injuries WHERE patient_id = t.id('pat_i')), 1::bigint, 'keine zweite Verletzung');
SELECT t.is((SELECT count(*) FROM public.plans WHERE patient_id = t.id('pat_i')), 1::bigint, 'kein zweiter Plan');
SELECT t.ok((SELECT r1.code <> r2.code FROM r1, r2), 'neuer Code (Wiederholung mit normalisiert gleichen Eingaben, anderer local_day)');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_i')), 2::bigint, 'zwei Einladungen insgesamt');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_i') AND revoked_at IS NULL AND redeemed_at IS NULL), 1::bigint, 'genau eine offene');
-- andere Parameter
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Ida'', ''Huefte'', NULL, %L)', t.id('pat_i'), t.today()), 'P0001', 'andere Verletzung -> idempotency_mismatch', 'idempotency_mismatch');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Ida'', ''Knie'', NULL, %L, ''Neu'')', t.id('pat_i'), t.today()), 'P0001', 'zusaetzlicher Nachname -> idempotency_mismatch', 'idempotency_mismatch');
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Ida'', ''Knie'', %L, %L)', t.id('pat_i'), t.id('tpl_a'), t.today()), 'P0001', 'zusaetzliche Vorlage -> idempotency_mismatch', 'idempotency_mismatch');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_i')), 2::bigint, 'nach mismatch nichts geaendert (Einladungen)');
SELECT t.is((SELECT label FROM public.injuries WHERE patient_id = t.id('pat_i')), 'Knie', 'nach mismatch nichts geaendert (Verletzung)');
-- fremde Praxis mit derselben id
SELECT t.as_user(t.id('phys_b1'));
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Ida'', ''Knie'', NULL, %L)', t.id('pat_i'), t.today()), '42501', 'gleiche id aus fremder Praxis -> 42501');
-- zwei Aufrufe nacheinander: nur der zweite Code gilt (MINOR-F)
SELECT t.as_admin();
SELECT t.is(t.redeem('anon_i1', (SELECT code FROM r1)), 'invalid', 'Code der ersten Antwort -> invalid');
SELECT t.is(t.redeem('anon_i2', (SELECT code FROM r2)), 'ok', 'Code der zweiten Antwort -> ok');
-- Status <> invited
SELECT t.as_user(t.id('phys_a1'));
SELECT t.throws(format('SELECT * FROM public.create_patient(%L, ''Ida'', ''Knie'', NULL, %L)', t.id('pat_i'), t.today()), '42501', 'Wiederholung nach Bindung (active) -> 42501');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_i')), 2::bigint, 'nach Bindung keine neue Einladung');
