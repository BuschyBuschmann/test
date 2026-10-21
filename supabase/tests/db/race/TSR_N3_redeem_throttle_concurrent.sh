#!/usr/bin/env bash
# Sicherheitsreview F2-1R NIT-3: die Bremse von redeem_invitation (5 Fehlversuche je Sitzung und
# 15 Minuten) gilt auch fuer gleichzeitige Aufrufe derselben Sitzung. Acht Verbindungen derselben
# anonymen Sitzung loesen gleichzeitig einen widerrufenen Code ein; ein Torwaechter G haelt die
# Einladungszeile, sodass alle Aufrufe gleichzeitig unterwegs sind.
# Vor dem Fix: alle acht zaehlen vor dem ersten Eintrag -> 8 x invalid, kein too_many_attempts.
# Mit Fix (Sitzungs-Sperre): genau 5 x invalid, 3 x too_many_attempts.
# Ausserdem: Index mit fuehrender Spalte at fuer die Bereinigung.
set -euo pipefail
P=("$PGBIN/psql" -X -q -d "$DB")
OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
ok()  { echo "ok - $1"; }
nok() { echo "not ok - $1"; exit 1; }
N=8

"${P[@]}" -v ON_ERROR_STOP=1 -c "SELECT t.seed_base()" >/dev/null
OLD="$("${P[@]}" -tAc "SELECT t.code('pat_a2')")"
"${P[@]}" -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
SELECT t.as_user(t.id('phys_a1'));
SELECT * FROM public.regenerate_invitation(t.id('pat_a2'));
SELECT t.as_admin();
INSERT INTO auth.users (id, is_anonymous) VALUES (t.id('anon_thr'), true);
SQL
INV="$("${P[@]}" -tAc "SELECT id FROM public.invitations WHERE patient_id = t.id('pat_a2') AND revoked_at IS NOT NULL")"

PGAPPNAME=thr_g "${P[@]}" -v ON_ERROR_STOP=1 >"$OUT/g" 2>&1 <<SQL &
BEGIN;
SELECT 1 FROM public.invitations WHERE id = '$INV' FOR UPDATE;
SELECT pg_sleep(2);
COMMIT;
SQL
PID_G=$!
sleep 0.5
PIDS=()
for i in $(seq 1 $N); do
  PGAPPNAME=thr_$i "${P[@]}" -v ON_ERROR_STOP=1 -tA >"$OUT/r$i" 2>&1 <<SQL &
SELECT 'R:' || t.redeem('anon_thr', '$OLD');
SQL
  PIDS+=($!)
done
sleep 1
WAITING="$("${P[@]}" -tAc "SELECT count(*) FROM pg_stat_activity WHERE application_name LIKE 'thr\_%' AND application_name <> 'thr_g' AND wait_event_type = 'Lock'")"
wait "$PID_G"
for p in "${PIDS[@]}"; do wait "$p" || true; done

[ "$WAITING" = "$N" ] && ok "alle $N Aufrufe gleichzeitig unterwegs (wartend: $WAITING)" || nok "nicht gleichzeitig (wartend: $WAITING)"
INVALID="$(cat "$OUT"/r* | grep -c '^R:invalid$' || true)"
TOO="$(cat "$OUT"/r* | grep -c '^R:too_many_attempts$' || true)"
[ "$INVALID" = "5" ] && [ "$TOO" = "3" ] && ok "gleichzeitig: 5 x invalid, 3 x too_many_attempts" \
  || nok "gleichzeitig: invalid=$INVALID too_many_attempts=$TOO ($(cat "$OUT"/r* | tr '\n' ' '))"
F="$("${P[@]}" -tAc "SELECT count(*) FROM public.redeem_attempts WHERE uid = t.id('anon_thr') AND NOT ok")"
[ "$F" = "5" ] && ok "genau 5 Fehlversuche gespeichert" || nok "Fehlversuche: $F"
IX="$("${P[@]}" -tAc "SELECT count(*) FROM pg_index x JOIN pg_attribute a ON a.attrelid = x.indrelid AND a.attnum = x.indkey[0] WHERE x.indrelid = 'public.redeem_attempts'::regclass AND a.attname = 'at'")"
[ "$IX" -ge 1 ] && ok "Index mit fuehrender Spalte at auf redeem_attempts (Bereinigung)" || nok "kein Index auf redeem_attempts(at)"
