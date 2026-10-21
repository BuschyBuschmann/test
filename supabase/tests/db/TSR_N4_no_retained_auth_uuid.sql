-- Sicherheitsreview F2-1R NIT-4 (Nutzerentscheidung: entfernen): nach Neubindung bzw.
-- delete_my_data behalten invitations.redeemed_by und redeem_attempts.uid die alte bzw.
-- geloeschte Auth-UUID nicht. Die Einladung bleibt ueber redeemed_at als eingeloest erkennbar.
\set ON_ERROR_STOP 1
\o /dev/null
SELECT t.seed_base();
SELECT t.ok((SELECT count(*) FROM public.invitations WHERE redeemed_by = t.id('anon_a1')) = 1
            AND (SELECT count(*) FROM public.redeem_attempts WHERE uid = t.id('anon_a1')) >= 1,
            'Ausgangslage: Auth-UUID von anon_a1 in invitations.redeemed_by und redeem_attempts');

-- Neubindung pat_a1: anon_a1 -> anon_a1_neu
SELECT t.as_user(t.id('phys_a1'));
CREATE TEMP TABLE c1 AS SELECT code FROM public.regenerate_invitation(t.id('pat_a1'));
GRANT SELECT ON c1 TO PUBLIC;
SELECT t.as_admin();
SELECT t.is(t.redeem('anon_a1_neu', (SELECT code FROM c1)), 'ok_rebound', 'Neubindung -> ok_rebound');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE redeemed_by = t.id('anon_a1')), 0::bigint,
            'Neubindung: keine Einladung mit redeemed_by = alte Auth-UUID');
SELECT t.is((SELECT count(*) FROM public.redeem_attempts WHERE uid = t.id('anon_a1')), 0::bigint,
            'Neubindung: keine redeem_attempts der alten Auth-UUID');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_a1') AND redeemed_at IS NOT NULL), 2::bigint,
            'Neubindung: beide Einladungen ueber redeemed_at als eingeloest erkennbar');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE redeemed_by = t.id('anon_a1_neu')), 1::bigint,
            'Neubindung: aktuelle Identitaet bleibt in redeemed_by der eingeloesten Einladung');
SELECT t.ok((SELECT count(*) FROM public.redeem_attempts WHERE uid = t.id('anon_a1_neu')) >= 1,
            'Neubindung: Versuche der aktuellen Identitaet bleiben (Bremse)');
SELECT t.is((SELECT count(*) FROM auth.users WHERE id = t.id('anon_a1')), 0::bigint, 'Neubindung: altes Auth-Konto geloescht');

-- delete_my_data pat_a3 (anon_a3)
SELECT t.as_user(t.id('anon_a3'), true);
SELECT t.is(public.delete_my_data(), 'ok', 'delete_my_data -> ok');
SELECT t.as_admin();
SELECT t.is((SELECT count(*) FROM public.invitations WHERE redeemed_by = t.id('anon_a3')), 0::bigint,
            'delete_my_data: keine Einladung mit redeemed_by = geloeschte Auth-UUID');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_a3') AND redeemed_by IS NOT NULL), 0::bigint,
            'delete_my_data: redeemed_by aller Einladungen des Patienten NULL');
SELECT t.is((SELECT count(*) FROM public.redeem_attempts WHERE uid = t.id('anon_a3')), 0::bigint,
            'delete_my_data: keine redeem_attempts der geloeschten Auth-UUID');
SELECT t.is((SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_a3') AND redeemed_at IS NOT NULL), 1::bigint,
            'delete_my_data: Einladung ueber redeemed_at als eingeloest erkennbar');
SELECT t.ok((SELECT count(*) FROM public.redeem_attempts WHERE uid = t.id('anon_b1')) >= 1,
            'delete_my_data: Versuche anderer Sitzungen unberuehrt');
