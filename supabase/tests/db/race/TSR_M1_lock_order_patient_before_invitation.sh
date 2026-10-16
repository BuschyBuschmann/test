#!/usr/bin/env bash
# Sicherheitsreview F2-1R MINOR-1 (Sperrreihenfolge Patient vor Einladung): zwei Verbindungen
# rufen gleichzeitig redeem_invitation und eine Funktion auf, die Patient und Einladung sperrt.
# Eine dritte Verbindung (G, nur Torwaechter) haelt die Patientenzeile kurz, damit die beiden
# Aufrufe deterministisch verschraenkt werden: B wartet zuerst auf den Patienten, A danach.
# Ohne einheitliche Reihenfolge haelt A die Einladung und wartet auf den Patienten, B haelt den
# Patienten und wartet auf die Einladung -> 40P01 deadlock detected.
# Mit Fix: kein Deadlock; A liefert den definierten Ergebniscode 'invalid' (Einladung inzwischen
# widerrufen), B ist erfolgreich.
#   Szenario 1: redeem_invitation (A) gegen regenerate_invitation (B, Physio)
#   Szenario 2: redeem_invitation als Neubindung (A) gegen delete_my_data (B, gebundener Patient)
set -euo pipefail
P=("$PGBIN/psql" -X -q -d "$DB")
OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
ok()  { echo "ok - $1"; }
nok() { echo "not ok - $1"; exit 1; }

"${P[@]}" -v ON_ERROR_STOP=1 -c "SELECT t.seed_base()" >/dev/null

# race_scenario NAME PATIENT CODE SQL_B
race_scenario() {
  local name="$1" pat="$2" code="$3" sql_b="$4" waiting rc_a rc_b
  PGAPPNAME="g_$name" "${P[@]}" -v ON_ERROR_STOP=1 >"$OUT/g_$name" 2>&1 <<SQL &
BEGIN;
SELECT 1 FROM public.patients WHERE id = t.id('$pat') FOR UPDATE;
SELECT pg_sleep(2);
COMMIT;
SQL
  local pid_g=$!
  sleep 0.5
  PGAPPNAME="b_$name" "${P[@]}" -v ON_ERROR_STOP=1 -tA >"$OUT/b_$name" 2>&1 <<SQL &
$sql_b
SQL
  local pid_b=$!
  sleep 0.5
  PGAPPNAME="a_$name" "${P[@]}" -v ON_ERROR_STOP=1 -tA >"$OUT/a_$name" 2>&1 <<SQL &
SELECT 'A:' || t.redeem('anon_race_$name', '$code');
SQL
  local pid_a=$!
  sleep 0.5
  waiting="$("${P[@]}" -tAc "SELECT count(*) FROM pg_stat_activity WHERE application_name IN ('a_$name', 'b_$name') AND wait_event_type = 'Lock'")"
  wait "$pid_g" || nok "$name: Torwaechter fehlgeschlagen: $(cat "$OUT/g_$name")"
  rc_a=0; wait "$pid_a" || rc_a=$?
  rc_b=0; wait "$pid_b" || rc_b=$?

  [ "$waiting" = "2" ] && ok "$name: A und B warten gleichzeitig auf die Patientenzeile (verschraenkt)" \
    || nok "$name: Verschraenkung nicht hergestellt (wartend: $waiting)"
  ! grep -q 'deadlock detected\|40P01' "$OUT/a_$name" "$OUT/b_$name" \
    && ok "$name: kein deadlock detected (40P01)" \
    || nok "$name: Deadlock: A: $(cat "$OUT/a_$name") | B: $(cat "$OUT/b_$name")"
  [ "$rc_a" = "0" ] && grep -q '^A:invalid$' "$OUT/a_$name" \
    && ok "$name: A (redeem_invitation) liefert den Ergebniscode invalid" \
    || nok "$name: A: $(cat "$OUT/a_$name")"
  [ "$rc_b" = "0" ] && grep -q '^B:' "$OUT/b_$name" \
    && ok "$name: B erfolgreich ($(grep '^B:' "$OUT/b_$name" | head -1 | cut -c1-14))" \
    || nok "$name: B: $(cat "$OUT/b_$name")"
}

# Szenario 1: eingeladener Patient pat_a2, Code aus der Anlage
CODE1="$("${P[@]}" -tAc "SELECT t.code('pat_a2')")"
race_scenario regen pat_a2 "$CODE1" \
  "SELECT t.as_user(t.id('phys_a1')); SELECT 'B:' || code FROM public.regenerate_invitation(t.id('pat_a2'));"
CODE1B="$(grep '^B:' "$OUT/b_regen" | cut -d: -f2)"
R="$("${P[@]}" -tAc "SELECT t.redeem('anon_race_regen2', '$CODE1B')")"
[ "$R" = "ok" ] && ok "regen: neuer Code aus B einloesbar" || nok "regen: neuer Code -> $R"

# Szenario 2: aktiver Patient pat_a1 mit offener Einladung (Neubindung) gegen delete_my_data
CODE2="$("${P[@]}" -tA -v ON_ERROR_STOP=1 <<'SQL' | tail -1
SELECT t.as_user(t.id('phys_a1'));
SELECT code FROM public.regenerate_invitation(t.id('pat_a1'));
SQL
)"
race_scenario delete pat_a1 "$CODE2" \
  "SELECT t.as_user(t.id('anon_a1'), true); SELECT 'B:' || public.delete_my_data();"
grep -q '^B:ok$' "$OUT/b_delete" && ok "delete: delete_my_data -> ok" || nok "delete: B: $(cat "$OUT/b_delete")"
S="$("${P[@]}" -tAc "SELECT status || '/' || coalesce(auth_user_id::text, 'null') FROM public.patients WHERE id = t.id('pat_a1')")"
[ "$S" = "access_deleted/null" ] && ok "delete: Patient access_deleted, keine Bindung an A" || nok "delete: Patient: $S"
