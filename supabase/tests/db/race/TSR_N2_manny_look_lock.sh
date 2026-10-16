#!/usr/bin/env bash
# Sicherheitsreview F2-1R NIT-2: set_manny_look sperrt die Patientenzeile gleich mit FOR NO KEY
# UPDATE statt FOR SHARE + UPDATE. B (Patient) haelt eine Lesesperre aus einem Schreibvorgang
# (t10 FOR SHARE) und ruft danach set_manny_look auf; A ruft set_manny_look dazwischen auf.
# Vor dem Fix: A erhaelt FOR SHARE und wartet beim UPDATE auf B, B wartet beim UPDATE auf A
# -> 40P01 deadlock detected. Mit Fix: A wartet von Anfang an, beide erfolgreich, A zuletzt.
set -euo pipefail
P=("$PGBIN/psql" -X -q -d "$DB")
OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
ok()  { echo "ok - $1"; }
nok() { echo "not ok - $1"; exit 1; }

"${P[@]}" -v ON_ERROR_STOP=1 -c "SELECT t.seed_base()" >/dev/null
PLAN="$("${P[@]}" -tAc "SELECT id FROM public.plans WHERE patient_id = t.id('pat_a1')")"

PGAPPNAME=race_b "${P[@]}" -v ON_ERROR_STOP=1 -tA >"$OUT/b" 2>&1 <<SQL &
SELECT t.as_user(t.id('anon_a1'), true);
BEGIN;
INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode)
VALUES (gen_random_uuid(), t.id('pat_a1'), '$PLAN', current_date, 'checklist');
SELECT pg_sleep(1.5);
SELECT public.set_manny_look('ohne');
COMMIT;
SELECT 'B:done';
SQL
PID_B=$!
sleep 0.5
PGAPPNAME=race_a "${P[@]}" -v ON_ERROR_STOP=1 -tA >"$OUT/a" 2>&1 <<'SQL' &
SELECT t.as_user(t.id('anon_a1'), true);
SELECT public.set_manny_look('brille');
SELECT 'A:done';
SQL
PID_A=$!
sleep 0.5
WAITING="$("${P[@]}" -tAc "SELECT count(*) FROM pg_stat_activity WHERE application_name = 'race_a' AND wait_event_type = 'Lock'")"
RC_A=0; wait "$PID_A" || RC_A=$?
RC_B=0; wait "$PID_B" || RC_B=$?

[ "$WAITING" = "1" ] && ok "A wartet auf B (Sperre der Patientenzeile)" || nok "A wartet nicht (wartend: $WAITING)"
! grep -q 'deadlock detected\|40P01' "$OUT/a" "$OUT/b" && ok "kein deadlock detected (40P01)" \
  || nok "Deadlock: A: $(cat "$OUT/a") | B: $(cat "$OUT/b")"
[ "$RC_A" = "0" ] && grep -q '^A:done$' "$OUT/a" && ok "A: set_manny_look erfolgreich" || nok "A: $(cat "$OUT/a")"
[ "$RC_B" = "0" ] && grep -q '^B:done$' "$OUT/b" && ok "B: Schreibvorgang und set_manny_look erfolgreich" || nok "B: $(cat "$OUT/b")"
L="$("${P[@]}" -tAc "SELECT manny_look FROM public.patients WHERE id = t.id('pat_a1')")"
[ "$L" = "brille" ] && ok "zuletzt geschriebener Look (A) gilt" || nok "Look: $L"
