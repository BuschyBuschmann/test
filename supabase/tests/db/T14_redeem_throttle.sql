-- DB-T14 redeem_throttle (Plan 12.2, 6.5, N-6): 6. Versuch nach 5 Fehlversuchen je Sitzung in
-- 15 Minuten -> too_many_attempts (auch mit gueltigem Code); eine andere Sitzung ist nicht betroffen
-- (keine globale Bremse); nach 15 Minuten wieder moeglich.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.create_patient('phys_a1', 'pat_a2', 'Ben', 'Schulter');
SELECT t.create_patient('phys_a1', 'pat_t2', 'Tina', 'Knie');
SELECT t.is(t.redeem('anon_x', 'ZZZZZ-ZZZZ' || i::text), 'invalid', format('Fehlversuch %s -> invalid', i)) FROM generate_series(1, 5) i;
SELECT t.is(t.redeem('anon_x', t.code('pat_a2')), 'too_many_attempts', '6. Versuch (gueltiger Code) -> too_many_attempts');
SELECT t.is((SELECT status FROM public.patients WHERE id = t.id('pat_a2')), 'invited', 'nichts gebunden');
SELECT t.is(t.redeem('anon_y', t.code('pat_t2')), 'ok', 'andere Sitzung nicht betroffen (keine globale Bremse)');
-- Fehlversuche 16 Minuten zurueckdatieren
UPDATE public.redeem_attempts SET at = at - interval '16 minutes' WHERE uid = t.id('anon_x');
SELECT t.is(t.redeem('anon_x', t.code('pat_a2')), 'ok', 'nach 15 Minuten wieder moeglich');
-- 4 Fehlversuche sperren nicht
SELECT t.create_patient('phys_a1', 'pat_t3', 'Uwe', 'Knie');
SELECT t.is(t.redeem('anon_z', 'ZZZZZ-ZZZZ' || i::text), 'invalid', format('z: Fehlversuch %s', i)) FROM generate_series(1, 4) i;
SELECT t.is(t.redeem('anon_z', t.code('pat_t3')), 'ok', 'nach 4 Fehlversuchen noch erlaubt');
