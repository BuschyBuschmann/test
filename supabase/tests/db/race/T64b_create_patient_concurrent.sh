#!/usr/bin/env bash
# DB-T64b (Teil zwei Verbindungen, Plan 6.6 MINOR-1/MINOR-F): zwei gleichzeitige create_patient-
# Aufrufe mit derselben id und denselben Parametern -> genau ein Patient, genau eine offene
# Einladung, kein 23505; der zweite wartet auf den ersten und widerruft dessen Code.
set -euo pipefail
P=("$PGBIN/psql" -X -q -d "$DB")
OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
ok()  { echo "ok - $1"; }
nok() { echo "not ok - $1"; exit 1; }

"${P[@]}" -v ON_ERROR_STOP=1 -c "SELECT t.seed_base()" >/dev/null

PGAPPNAME=race_a "${P[@]}" -v ON_ERROR_STOP=1 -tA >"$OUT/a" 2>&1 <<'SQL' &
SELECT t.as_user(t.id('phys_a1'));
BEGIN;
SELECT 'CODE:' || code FROM public.create_patient(t.id('pat_race'), 'Rudi', 'Knie', NULL, t.today());
SELECT pg_sleep(2);
COMMIT;
SQL
PID_A=$!
sleep 0.7
PGAPPNAME=race_b "${P[@]}" -v ON_ERROR_STOP=1 -tA >"$OUT/b" 2>&1 <<'SQL' &
SELECT t.as_user(t.id('phys_a1'));
SELECT 'CODE:' || code FROM public.create_patient(t.id('pat_race'), 'Rudi', 'Knie', NULL, t.today());
SQL
PID_B=$!
sleep 0.7
WAITING="$("${P[@]}" -tAc "SELECT count(*) FROM pg_stat_activity WHERE application_name = 'race_b' AND wait_event_type = 'Lock'")"
RC_A=0; wait "$PID_A" || RC_A=$?
RC_B=0; wait "$PID_B" || RC_B=$?

[ "$WAITING" = "1" ] && ok "zweiter Aufruf wartet auf den ersten (Lock)" || nok "zweiter Aufruf wartet nicht (wartend: $WAITING)"
[ "$RC_A" = "0" ] && ok "erster Aufruf erfolgreich" || nok "A: $(cat "$OUT/a")"
[ "$RC_B" = "0" ] && ! grep -q '23505\|duplicate key' "$OUT/b" && ok "zweiter Aufruf erfolgreich, kein 23505" || nok "B: $(cat "$OUT/b")"
CODE_A="$(grep -o 'CODE:[0-9A-Z]*' "$OUT/a" | cut -d: -f2)"
CODE_B="$(grep -o 'CODE:[0-9A-Z]*' "$OUT/b" | cut -d: -f2)"
[ -n "$CODE_A" ] && [ -n "$CODE_B" ] && [ "$CODE_A" != "$CODE_B" ] && ok "beide Antworten mit unterschiedlichem Code" || nok "Codes: '$CODE_A' '$CODE_B'"
N="$("${P[@]}" -tAc "SELECT count(*) FROM public.patients WHERE id = t.id('pat_race')")"
[ "$N" = "1" ] && ok "genau ein Patient" || nok "Patienten: $N"
N="$("${P[@]}" -tAc "SELECT count(*) FROM public.injuries WHERE patient_id = t.id('pat_race')")"
[ "$N" = "1" ] && ok "genau eine Verletzung und damit ein Plan" || nok "Verletzungen: $N"
N="$("${P[@]}" -tAc "SELECT count(*) FROM public.invitations WHERE patient_id = t.id('pat_race') AND redeemed_at IS NULL AND revoked_at IS NULL")"
[ "$N" = "1" ] && ok "genau eine offene Einladung" || nok "offene Einladungen: $N"
R="$("${P[@]}" -tAc "SELECT t.redeem('anon_race_a', '$CODE_A')")"
[ "$R" = "invalid" ] && ok "Code des ersten (aelteren) Aufrufs -> invalid" || nok "Code A: $R"
R="$("${P[@]}" -tAc "SELECT t.redeem('anon_race_b', '$CODE_B')")"
[ "$R" = "ok" ] && ok "Code des zuletzt gestarteten Aufrufs -> ok" || nok "Code B: $R"
