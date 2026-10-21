#!/usr/bin/env bash
# DB-T31 race_delete_vs_insert (Plan 12.2, M-4): Verbindung A haelt delete_my_data offen, B schreibt
# eine Session und C ein Ergebnis im Namen desselben Patienten -> B und C warten auf die Sperre und
# scheitern danach mit 42501; danach keine Zeilen des Patienten in training_sessions/exercise_results.
# Aufruf durch run_local_pg.sh mit DB (Wegwerf-Datenbank aus der Vorlage) und PGBIN.
set -euo pipefail
P=("$PGBIN/psql" -X -q -d "$DB")
OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
ok()  { echo "ok - $1"; }
nok() { echo "not ok - $1"; exit 1; }

"${P[@]}" -v ON_ERROR_STOP=1 -c "SELECT t.seed_base()" >/dev/null
PLAN="$("${P[@]}" -tAc "SELECT id FROM public.plans WHERE patient_id = t.id('pat_a1')")"

PGAPPNAME=race_a "${P[@]}" -v ON_ERROR_STOP=1 >"$OUT/a" 2>&1 <<SQL &
SELECT t.as_user(t.id('anon_a1'), true);
BEGIN;
SELECT 'A:' || public.delete_my_data();
SELECT pg_sleep(3);
COMMIT;
SQL
PID_A=$!
sleep 1
PGAPPNAME=race_b "${P[@]}" >"$OUT/b" 2>&1 <<SQL &
SELECT t.as_user(t.id('anon_a1'), true);
INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode)
VALUES (gen_random_uuid(), t.id('pat_a1'), '$PLAN', current_date, 'checklist');
SQL
PID_B=$!
PGAPPNAME=race_c "${P[@]}" >"$OUT/c" 2>&1 <<SQL &
SELECT t.as_user(t.id('anon_a1'), true);
INSERT INTO public.exercise_results (id, patient_id, training_session_id, local_day, status)
VALUES (gen_random_uuid(), t.id('pat_a1'), t.id('ts_pat_a1'), current_date, 'done');
SQL
PID_C=$!
sleep 1
WAITING="$("${P[@]}" -tAc "SELECT count(*) FROM pg_stat_activity WHERE application_name IN ('race_b', 'race_c') AND wait_event_type = 'Lock'")"
wait "$PID_A" || nok "Verbindung A (delete_my_data) fehlgeschlagen: $(cat "$OUT/a")"
wait "$PID_B" || true
wait "$PID_C" || true

[ "$WAITING" = "2" ] && ok "B und C warten auf die Sperre von delete_my_data (pg_stat_activity: Lock)" || nok "B/C warten nicht (wartend: $WAITING)"
grep -q 'A:ok' "$OUT/a" && ok "A: delete_my_data -> ok" || nok "A: $(cat "$OUT/a")"
grep -q 'patient_not_active' "$OUT/b" && ok "B (training_sessions) scheitert nach dem Warten mit 42501 patient_not_active" || nok "B: $(cat "$OUT/b")"
grep -q 'patient_not_active' "$OUT/c" && ok "C (exercise_results) scheitert nach dem Warten mit 42501 patient_not_active" || nok "C: $(cat "$OUT/c")"
N="$("${P[@]}" -tAc "SELECT (SELECT count(*) FROM public.training_sessions WHERE patient_id = t.id('pat_a1')) + (SELECT count(*) FROM public.exercise_results WHERE patient_id = t.id('pat_a1'))")"
[ "$N" = "0" ] && ok "danach keine Zeilen des Patienten in training_sessions/exercise_results" || nok "Restzeilen: $N"
S="$("${P[@]}" -tAc "SELECT status FROM public.patients WHERE id = t.id('pat_a1')")"
[ "$S" = "access_deleted" ] && ok "Status access_deleted" || nok "Status: $S"
