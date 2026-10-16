#!/usr/bin/env bash
# F2-1RR MINOR-A: dieselbe anonyme Sitzung loest parallel zwei verschiedene Codes ein.
# T1 loest den Code von pat_a2 (eingeladen) ein, T2 den Neubindungscode von pat_a1 (aktiv, an
# anon_a1 gebunden). Ein Torwaechter G haelt pat_a2, damit T1 die Sitzungssperre haelt und auf
# den Patienten wartet, waehrend T2 vor der Sitzungssperre wartet; die Bindungspruefung von T2
# lief vor der Sperre. auth.users wird vorab angelegt (t.redeem wuerde per ON CONFLICT
# serialisieren), und die Aufrufe gehen direkt an public.redeem_invitation.
# Vor dem Fix: T2 -> ERROR duplicate key patients_auth_user_id_key (23505).
# Mit Fix: T2 -> not_allowed, pat_a1 bleibt an anon_a1 gebunden, Sitzung nur an pat_a2.
set -euo pipefail
P=("$PGBIN/psql" -X -q -d "$DB")
OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
ok()  { echo "ok - $1"; }
nok() { echo "not ok - $1"; exit 1; }

"${P[@]}" -v ON_ERROR_STOP=1 -c "SELECT t.seed_base()" >/dev/null
CODE1="$("${P[@]}" -tAc "SELECT t.code('pat_a2')")"
CODE2="$("${P[@]}" -tA -v ON_ERROR_STOP=1 <<'SQL' | tail -1
SELECT t.as_user(t.id('phys_a1'));
SELECT code FROM public.regenerate_invitation(t.id('pat_a1'));
SQL
)"
"${P[@]}" -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
SELECT t.as_admin();
INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_rra'), true);
SQL

PGAPPNAME=rra_g "${P[@]}" -v ON_ERROR_STOP=1 >"$OUT/g" 2>&1 <<SQL &
BEGIN;
SELECT 1 FROM public.patients WHERE id = t.id('pat_a2') FOR UPDATE;
SELECT pg_sleep(2);
COMMIT;
SQL
PID_G=$!
sleep 0.5
PGAPPNAME=rra_1 "${P[@]}" -v ON_ERROR_STOP=1 -tA >"$OUT/t1" 2>&1 <<SQL &
SELECT t.as_user(t.id('anon_rra'), true);
SELECT 'T1:' || public.redeem_invitation('$CODE1');
SQL
PID_1=$!
sleep 0.5
PGAPPNAME=rra_2 "${P[@]}" -v ON_ERROR_STOP=1 -tA >"$OUT/t2" 2>&1 <<SQL &
SELECT t.as_user(t.id('anon_rra'), true);
SELECT 'T2:' || public.redeem_invitation('$CODE2');
SQL
PID_2=$!
sleep 0.5
WAITING="$("${P[@]}" -tAc "SELECT count(*) FROM pg_stat_activity WHERE application_name IN ('rra_1', 'rra_2') AND wait_event_type = 'Lock'")"
wait "$PID_G" || nok "Torwaechter fehlgeschlagen: $(cat "$OUT/g")"
RC1=0; wait "$PID_1" || RC1=$?
RC2=0; wait "$PID_2" || RC2=$?

[ "$WAITING" = "2" ] && ok "T1 (auf Patient) und T2 (auf Sitzungssperre) warten gleichzeitig" || nok "nicht verschraenkt (wartend: $WAITING)"
[ "$RC1" = "0" ] && grep -q '^T1:ok$' "$OUT/t1" && ok "T1 loest pat_a2 ein -> ok" || nok "T1: $(cat "$OUT/t1")"
! grep -q '23505\|duplicate key' "$OUT/t2" && ok "T2: kein duplicate key (23505)" || nok "T2: $(cat "$OUT/t2")"
[ "$RC2" = "0" ] && grep -q '^T2:not_allowed$' "$OUT/t2" && ok "T2 liefert not_allowed" || nok "T2: $(cat "$OUT/t2")"
S="$("${P[@]}" -tAc "SELECT string_agg(name || '=' || coalesce(auth_user_id::text, 'null'), ',' ORDER BY name) FROM (SELECT 'a1' AS name, auth_user_id FROM public.patients WHERE id = t.id('pat_a1') UNION ALL SELECT 'a2', auth_user_id FROM public.patients WHERE id = t.id('pat_a2')) x")"
[ "$S" = "a1=$("${P[@]}" -tAc "SELECT t.id('anon_a1')"),a2=$("${P[@]}" -tAc "SELECT t.id('anon_rra')")" ] \
  && ok "pat_a1 bleibt an anon_a1, pat_a2 an die Sitzung gebunden" || nok "Bindungen: $S"
