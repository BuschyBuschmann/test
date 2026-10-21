-- DB-T13 redeem_results (Plan 12.2, 6.5): ok, already_used, expired, invalid, widerrufen -> invalid;
-- Normalisierung des Codes; Code 10 Zeichen Crockford-Base32; nur HMAC gespeichert.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();

-- Format und Normalisierung
SELECT t.ok(t.code('pat_a1') ~ '^[0-9A-HJKMNP-TV-Z]{10}$', 'Code: 10 Zeichen Crockford-Base32');
SELECT t.is(app.normalize_invite_code(' abcde-fghjk '), 'ABCDEFGHJK', 'Normalisierung: Gross, ohne Leerzeichen/Bindestrich');
SELECT t.is(app.normalize_invite_code('o0iIlL'), '001111', 'Normalisierung: O->0, I/L->1');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE code_hmac = convert_to(t.code('pat_a1'), 'UTF8')), 0::bigint,
            'Klartext-Code ist nicht gespeichert');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE code_hmac = app.invite_code_hmac(t.code('pat_a1'))), 1::bigint,
            'gespeichert ist HMAC(pepper, code)');

-- ok mit Kleinschreibung und Bindestrich
SELECT t.create_patient('phys_a1', 'pat_n1', 'Nina', 'Knie');
SELECT t.is(t.redeem('anon_n1', lower(substr(t.code('pat_n1'), 1, 5) || '-' || substr(t.code('pat_n1'), 6))), 'ok',
            'ok (klein geschrieben, mit Bindestrich)');
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_n1')), 'active', 'Patient aktiv');
SELECT t.is((SELECT auth_user_id FROM public.patients WHERE id = t.id('pat_n1')), t.id('anon_n1'), 'Patient gebunden');
SELECT t.is((SELECT count(*) FROM public.account_events WHERE patient_id = t.id('pat_n1') AND kind = 'bound'), 1::bigint, 'account_events bound');
SELECT t.ok((SELECT redeemed_at IS NOT NULL AND redeemed_by = t.id('anon_n1') FROM public.invitations
              WHERE patient_id = t.id('pat_n1')), 'Einladung als eingeloest markiert');

-- already_used
SELECT t.is(t.redeem('anon_n2', t.code('pat_n1')), 'already_used', 'zweites Einloesen -> already_used');

-- expired
SELECT t.create_patient('phys_a1', 'pat_n3', 'Olaf', 'Knie');
UPDATE public.invitations SET expires_at = now() - interval '1 minute' WHERE patient_id = t.id('pat_n3');
SELECT t.is(t.redeem('anon_n3', t.code('pat_n3')), 'expired', 'abgelaufen -> expired');
SELECT t.ok((SELECT expires_at - created_at BETWEEN interval '13 days 23 hours' AND interval '14 days 1 hour'
               FROM public.invitations WHERE patient_id = t.id('pat_a2')), 'Ablauf 14 Tage (O-7)');

-- invalid
SELECT t.is(t.redeem('anon_n4', 'ZZZZZ-ZZZZZ'), 'invalid', 'unbekannter Code -> invalid');
SELECT t.is(t.redeem('anon_n4', 'abc'), 'invalid', 'falsches Format -> invalid');
SELECT t.is(t.redeem('anon_n4', NULL), 'invalid', 'NULL -> invalid');

-- widerrufen -> invalid
SELECT t.create_patient('phys_a1', 'pat_n5', 'Paul', 'Knie');
INSERT INTO t.codes VALUES ('pat_n5_old', t.code('pat_n5'));
SELECT t.as_user(t.id('phys_a1'));
SELECT t.ok((SELECT code IS NOT NULL FROM public.regenerate_invitation(t.id('pat_n5'))), 'regenerate_invitation liefert neuen Code');
SELECT t.is(t.redeem('anon_n5', t.code('pat_n5_old')), 'invalid', 'widerrufener Code -> invalid');
SELECT t.is((SELECT failed_attempts FROM public.invitations WHERE code_hmac = app.invite_code_hmac(t.code('pat_n5_old'))), 1,
            'Fehlversuch an der Einladung gezaehlt');

-- Patient mit Status access_deleted: Code ungueltig
SELECT t.create_patient('phys_a1', 'pat_n6', 'Rita', 'Knie');
UPDATE public.patients SET status = 'access_deleted' WHERE id = t.id('pat_n6');
SELECT t.is(t.redeem('anon_n6', t.code('pat_n6')), 'invalid', 'Patient access_deleted -> invalid');
