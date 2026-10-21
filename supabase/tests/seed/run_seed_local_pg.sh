#!/usr/bin/env bash
# Lokaler Lauf des Testdaten-Seeds gegen ein Wegwerf-Postgres 16 mit Supabase-Nachbildung
# (Paket F2-2; DB-T40 laeuft in voller Form erst gegen den echten Stack, X2-8).
#
#   supabase/tests/seed/run_seed_local_pg.sh
#
# Ablauf: Cluster -> Nachbildung + Migrationen + Test-Pepper -> Kontrollpraxis (kein Test) ->
# Seed-SQL aus app/tool/seed (derselbe Plan wie der API-Weg) -> Seed 1 -> Pruefungen ->
# Pruefsumme -> Seed 2 -> gleiche Pruefsumme, Kontrollpraxis unveraendert -> Einladungscode
# einloesen und Patientensicht pruefen -> Abbau.
#
# Nicht abgedeckt (kein Auth-Admin, kein GoTrue): Konten werden direkt in auth.users der
# Nachbildung angelegt; die Auth-Admin-API und das Passwort-Login des echten Stacks bleiben
# unverifiziert.
#
# Umgebungsvariablen:
#   PGBIN       Postgres-Binaerdateien (Standard /usr/lib/postgresql/16/bin)
#   PG_WORKDIR  Arbeitsverzeichnis (Standard: mktemp -d)
#   PG_PORT     Port (Standard 55442; nur Unix-Socket)
#   DART        Dart-Aufruf (Standard: dart; mit Flutter z. B. /opt/flutter/bin/dart)
#   KEEP=1      Cluster nach dem Lauf nicht abbauen
# Ausschliesslich lokal: keine Verbindung zu einem echten Projekt, keine Secrets.
# CURAONE_SEED_PASSWORD ist fuer den echten Lauf Pflicht; hier gilt ein offensichtlicher Platzhalter
# (der SQL-Weg legt keine Konten mit Passwort an).

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPA="$(cd "$HERE/../.." && pwd)"
APP="$(cd "$SUPA/../app" && pwd)"
export CURAONE_SEED_PASSWORD="${CURAONE_SEED_PASSWORD:-PLATZHALTER-NUR-LOKAL}"
PGBIN="${PGBIN:-/usr/lib/postgresql/16/bin}"
PORT="${PG_PORT:-55442}"
DART="${DART:-dart}"
KEEP="${KEEP:-0}"

if [ -n "${PG_WORKDIR:-}" ]; then WORK="$PG_WORKDIR"; mkdir -p "$WORK"
else WORK="$(mktemp -d "${TMPDIR:-/tmp}/curaone-seed-pg.XXXXXX")"; fi
DATA="$WORK/data"; SOCK="$WORK/sock"; LOGS="$WORK/logs"
rm -rf "$DATA" "$SOCK" "$LOGS"; mkdir -p "$SOCK" "$LOGS"

RUN_AS=()
if [ "$(id -u)" = "0" ]; then
  RUN_AS=(runuser -u postgres --)
  chown postgres "$WORK" "$SOCK" "$LOGS"
fi
# Skripte und Seed-SQL muessen fuer den Server-Benutzer nicht lesbar sein; psql laeuft als aufrufender Benutzer.

export PGHOST="$SOCK" PGPORT="$PORT" PGUSER="supabase_admin"
PSQL=("$PGBIN/psql" -X -q -v ON_ERROR_STOP=1)

cleanup() {
  if [ "$KEEP" = "1" ]; then
    echo "KEEP=1: Cluster laeuft weiter. Stoppen: ${RUN_AS[*]} $PGBIN/pg_ctl -D $DATA stop -m fast"; return
  fi
  if [ -f "$DATA/postmaster.pid" ]; then
    "${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$DATA" stop -m fast -w >/dev/null 2>&1 || true
  fi
  if [ -z "${PG_WORKDIR:-}" ]; then rm -rf "$WORK"; else rm -rf "$DATA" "$SOCK"; fi
}
trap cleanup EXIT

fail() { echo "FAIL $*"; exit 1; }

echo "== Cluster anlegen ($WORK)"
"${RUN_AS[@]}" "$PGBIN/initdb" -D "$DATA" -U supabase_admin --auth=trust -E UTF8 --locale=C >"$LOGS/initdb.log" 2>&1
"${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$DATA" -l "$LOGS/server.log" -w \
  -o "-c listen_addresses='' -k $SOCK -p $PORT -c fsync=off -c timezone=UTC" start >/dev/null

DB=curaone_seed
"${PSQL[@]}" -d postgres -c "CREATE DATABASE $DB" >/dev/null
"${PSQL[@]}" -d $DB -f "$SUPA/tests/shim/supabase_roles.sql" >/dev/null
"${PSQL[@]}" -d postgres -c "ALTER DATABASE $DB OWNER TO postgres" >/dev/null
for m in "$SUPA"/migrations/*.sql; do
  PGUSER=postgres "${PSQL[@]}" -d $DB -f "$m" >"$LOGS/migrate.$(basename "$m").log" 2>&1 \
    || { cat "$LOGS/migrate.$(basename "$m").log"; fail "Migration $(basename "$m")"; }
done
"${PSQL[@]}" -d $DB -f "$SUPA/tests/shim/test_pepper.sql" >/dev/null
echo "OK   Nachbildung, 7 Migrationen, Test-Pepper"

echo "== Kontrollpraxis (kein Test) anlegen"
"${PSQL[@]}" -d $DB >/dev/null <<'SQL'
SET ROLE service_role;
INSERT INTO public.practices (id, name, is_test) VALUES ('c0c0c0c0-0000-4000-8000-000000000001', 'Kontrollpraxis (echt)', false);
INSERT INTO auth.users (id, email) VALUES ('c0c0c0c0-0000-4000-8000-000000000002', 'kontrolle@example.invalid');
INSERT INTO public.physios (id, practice_id, display_name)
VALUES ('c0c0c0c0-0000-4000-8000-000000000002', 'c0c0c0c0-0000-4000-8000-000000000001', 'Kontroll-Physio');
INSERT INTO public.exercises (id, practice_id, name, description, created_by_role)
VALUES ('c0c0c0c0-0000-4000-8000-000000000003', 'c0c0c0c0-0000-4000-8000-000000000001', 'Kontroll-Uebung', 'bleibt unveraendert', 'physio');
INSERT INTO public.plan_templates (id, practice_id, name, created_by_role)
VALUES ('c0c0c0c0-0000-4000-8000-000000000004', 'c0c0c0c0-0000-4000-8000-000000000001', 'Kontroll-Vorlage', 'physio');
INSERT INTO public.patients (id, practice_id, first_name, main_physio_id, status)
VALUES ('c0c0c0c0-0000-4000-8000-000000000010', 'c0c0c0c0-0000-4000-8000-000000000001', 'Kontrolle', 'c0c0c0c0-0000-4000-8000-000000000002', 'invited');
INSERT INTO public.injuries (id, patient_id, label, reference_date, started_on)
VALUES ('c0c0c0c0-0000-4000-8000-000000000011', 'c0c0c0c0-0000-4000-8000-000000000010', 'Kontrolle', current_date, current_date);
INSERT INTO public.plans (id, patient_id, injury_id) VALUES ('c0c0c0c0-0000-4000-8000-000000000012', 'c0c0c0c0-0000-4000-8000-000000000010', 'c0c0c0c0-0000-4000-8000-000000000011');
INSERT INTO public.phases (id, plan_id, position, title, planned_weeks) VALUES ('c0c0c0c0-0000-4000-8000-000000000013', 'c0c0c0c0-0000-4000-8000-000000000012', 0, 'Kontrolle', 2);
INSERT INTO public.plan_items (id, plan_id, phase_id, exercise_id, position, sets, reps)
VALUES ('c0c0c0c0-0000-4000-8000-000000000014', 'c0c0c0c0-0000-4000-8000-000000000012', 'c0c0c0c0-0000-4000-8000-000000000013', 'c0c0c0c0-0000-4000-8000-000000000003', 0, 3, 10);
INSERT INTO public.training_sessions (id, patient_id, plan_id, local_day, mode)
VALUES ('c0c0c0c0-0000-4000-8000-000000000015', 'c0c0c0c0-0000-4000-8000-000000000010', 'c0c0c0c0-0000-4000-8000-000000000012', current_date - 1, 'checklist');
RESET ROLE;
SQL

echo "== Seed-SQL erzeugen ($DART run tool/seed/seed.dart --emit-sql)"
TODAY="$(date -u +%F)"
(cd "$APP" && "$DART" run tool/seed/seed.dart --emit-sql --today "$TODAY") >"$WORK/seed.sql" 2>"$LOGS/emit.log" \
  || { cat "$LOGS/emit.log"; fail "emit-sql"; }
echo "OK   $(wc -l <"$WORK/seed.sql") SQL-Zeilen, Bezugstag $TODAY"

run_seed() {  # $1 = Lauf-Nr
  "${PSQL[@]}" -1 -d $DB -f "$WORK/seed.sql" >"$LOGS/seed.$1.out" 2>"$LOGS/seed.$1.err" \
    || { cat "$LOGS/seed.$1.err"; fail "Seed-Lauf $1"; }
}
snapshot() { "$PGBIN/psql" -X -q -At -v ON_ERROR_STOP=1 -d $DB -f "$HERE/snapshot.sql" | sort; }

snapshot >"$LOGS/control.before"
echo "== Seed, Lauf 1"
run_seed 1
snapshot >"$LOGS/snap.1"
CODE_LENA="$(grep -o 'EINLADUNG Lena (Testperson) [0-9A-Z]*' "$LOGS/seed.1.out" | awk '{print $NF}')"
[ -n "$CODE_LENA" ] || fail "kein Einladungscode in der Seed-Ausgabe"
echo "OK   $(grep -c 'EINLADUNG' "$LOGS/seed.1.out") Einladungscodes erzeugt (nur Konsole/Log, nicht im Repository)"

echo "== Pruefungen auf den Seed-Daten (check_seed.sql)"
out="$("${PSQL[@]}" -d $DB -f "$HERE/check_seed.sql" 2>&1)" || { echo "$out" | grep -E 'ERROR|not ok' | head; fail "check_seed.sql (Lauf 1)"; }
n="$(grep -c 'NOTICE:  ok - ' <<<"$out" || true)"
echo "PASS check_seed.sql: $n Pruefungen (ohne Einloesung)"
# Einloesung veraendert den Zustand; daher erst nach den Pruefsummen (siehe unten, eigene DB-Kopie)

echo "== Seed, Lauf 2 (Reset + erneut)"
run_seed 2
snapshot >"$LOGS/snap.2"
if diff -q "$LOGS/snap.1" "$LOGS/snap.2" >/dev/null; then
  echo "PASS DB-T40 lokal: gleicher Endzustand nach zweitem Lauf ($(grep -c '^seed:' "$LOGS/snap.1") Tabellen-Pruefsummen)"
else
  diff "$LOGS/snap.1" "$LOGS/snap.2"; fail "Endzustand nach zweitem Lauf verschieden"
fi
grep '^control:' "$LOGS/snap.2" >"$LOGS/control.after"
grep '^control:' "$LOGS/control.before" >"$LOGS/control.before.f"
if diff -q "$LOGS/control.before.f" "$LOGS/control.after" >/dev/null; then
  echo "PASS DB-T40 lokal: Kontrollpraxis unveraendert ($(wc -l <"$LOGS/control.after") Tabellen-Pruefsummen)"
else
  diff "$LOGS/control.before.f" "$LOGS/control.after"; fail "Kontrollpraxis wurde veraendert"
fi
# Kontrollpraxis nicht leer (Pruefung ist aussagekraeftig)
grep -q '^control:training_sessions [0-9a-f]\{32\}$' "$LOGS/control.after" || fail "Kontroll-Pruefsumme leer"
[ "$("${PSQL[@]}" -At -d $DB -c "SELECT count(*) FROM public.practices WHERE NOT is_test")" = "1" ] || fail "Kontrollpraxis fehlt"
echo "PASS Reset-Umfang: nur is_test-Praxen und Testkonten entfernt (Kontrollpraxis, ihr Konto und ihre Daten vorhanden)"

echo "== Schutzpruefung: Mischfaelle brechen den Reset ab, ohne etwas zu aendern"
C1=c0c0c0c0-0000-4000-8000-000000000001
CP=c0c0c0c0-0000-4000-8000-000000000010
mixed() {  # $1 Name, $2 Aufbau-SQL, $3 Rueckbau-SQL, $4 erwarteter Meldungstext
  "${PSQL[@]}" -d $DB -c "$2" >/dev/null
  snapshot >"$LOGS/mix.before"
  if "${PSQL[@]}" -1 -d $DB -f "$WORK/seed.sql" >"$LOGS/mix.out" 2>"$LOGS/mix.err"; then
    fail "Mischfall $1: Seed lief trotz Mischfall durch"
  fi
  grep -q "$4" "$LOGS/mix.err" || { cat "$LOGS/mix.err"; fail "Mischfall $1: Meldung '$4' fehlt"; }
  snapshot >"$LOGS/mix.after"
  diff -q "$LOGS/mix.before" "$LOGS/mix.after" >/dev/null || fail "Mischfall $1: Zustand nach Abbruch veraendert"
  [ "$("${PSQL[@]}" -At -d $DB -c "SELECT count(*) FROM public.practices WHERE is_test")" = "2" ] \
    || fail "Mischfall $1: Testpraxen fehlen nach Abbruch"
  "${PSQL[@]}" -d $DB -c "$3" >/dev/null
  echo "PASS Mischfall $1: Abbruch mit Schutzmeldung, Zustand (Test- und Kontrolldaten) unveraendert"
}
mixed "A Testkonto ist Physio in Nicht-Testpraxis (Gross-/Kleinschreibung)" \
  "INSERT INTO auth.users (id, email) VALUES ('c0c0c0c0-0000-4000-8000-0000000000a1', 'Misch_A@Test.Curaone.Invalid'); INSERT INTO public.physios (id, practice_id, display_name) VALUES ('c0c0c0c0-0000-4000-8000-0000000000a1', '$C1', 'Misch');" \
  "DELETE FROM public.physios WHERE id = 'c0c0c0c0-0000-4000-8000-0000000000a1'; DELETE FROM auth.users WHERE id = 'c0c0c0c0-0000-4000-8000-0000000000a1';" \
  "Testkonto ist Physio in einer Praxis ohne is_test"
mixed "B Testkonto ist Hauptphysio eines echten Patienten" \
  "UPDATE public.patients SET main_physio_id = (SELECT id FROM auth.users WHERE email = 'nord1@test.curaone.invalid') WHERE id = '$CP';" \
  "UPDATE public.patients SET main_physio_id = 'c0c0c0c0-0000-4000-8000-000000000002' WHERE id = '$CP';" \
  "Hauptphysio oder Konto"
mixed "C Testkonto ist Konto eines echten Patienten" \
  "INSERT INTO auth.users (id, email) VALUES ('c0c0c0c0-0000-4000-8000-0000000000a2', 'misch_c@test.curaone.invalid'); UPDATE public.patients SET auth_user_id = 'c0c0c0c0-0000-4000-8000-0000000000a2' WHERE id = '$CP';" \
  "UPDATE public.patients SET auth_user_id = NULL WHERE id = '$CP'; DELETE FROM auth.users WHERE id = 'c0c0c0c0-0000-4000-8000-0000000000a2';" \
  "Hauptphysio oder Konto"
mixed "D Plan eines echten Patienten nutzt Uebung einer Testpraxis (RESTRICT)" \
  "UPDATE public.plan_items SET exercise_id = (SELECT id FROM public.exercises WHERE name LIKE 'Eigene Übung Nord%') WHERE id = 'c0c0c0c0-0000-4000-8000-000000000014';" \
  "UPDATE public.plan_items SET exercise_id = 'c0c0c0c0-0000-4000-8000-000000000003' WHERE id = 'c0c0c0c0-0000-4000-8000-000000000014';" \
  "RESTRICT"
mixed "E Physio ohne Testkonto in einer Testpraxis" \
  "INSERT INTO auth.users (id, email) VALUES ('c0c0c0c0-0000-4000-8000-0000000000a3', 'echt@example.invalid'); INSERT INTO public.physios (id, practice_id, display_name) SELECT 'c0c0c0c0-0000-4000-8000-0000000000a3', id, 'Echt' FROM public.practices WHERE is_test LIMIT 1;" \
  "DELETE FROM public.physios WHERE id = 'c0c0c0c0-0000-4000-8000-0000000000a3'; DELETE FROM auth.users WHERE id = 'c0c0c0c0-0000-4000-8000-0000000000a3';" \
  "Physio in einer Testpraxis ohne Testkonto"
mixed "F Vorlage einer echten Praxis verweist auf Uebung einer Testpraxis" \
  "UPDATE public.plan_templates SET payload = jsonb_build_object('phases', jsonb_build_array(jsonb_build_object('items', jsonb_build_array(jsonb_build_object('exercise_id', (SELECT id FROM public.exercises WHERE name LIKE 'Eigene Übung Nord%')))))) WHERE id = 'c0c0c0c0-0000-4000-8000-000000000004';" \
  "UPDATE public.plan_templates SET payload = '{\"phases\": []}'::jsonb WHERE id = 'c0c0c0c0-0000-4000-8000-000000000004';" \
  "Vorlage ausserhalb"
mixed "G Vorlage verweist mit UUID in Grossbuchstaben auf Uebung einer Testpraxis" \
  "UPDATE public.plan_templates SET payload = jsonb_build_object('phases', jsonb_build_array(jsonb_build_object('items', jsonb_build_array(jsonb_build_object('exercise_id', upper((SELECT id::text FROM public.exercises WHERE name LIKE 'Eigene Übung Nord%'))))))) WHERE id = 'c0c0c0c0-0000-4000-8000-000000000004';" \
  "UPDATE public.plan_templates SET payload = '{\"phases\": []}'::jsonb WHERE id = 'c0c0c0c0-0000-4000-8000-000000000004';" \
  "Vorlage ausserhalb"
# Gegenprobe: aehnliche, aber andere Domain wird nicht angefasst und loest keinen Abbruch aus
"${PSQL[@]}" -d $DB >/dev/null -c "INSERT INTO auth.users (id, email) VALUES ('c0c0c0c0-0000-4000-8000-0000000000a4', 'ahnlich@xtest.curaone.invalid'); INSERT INTO public.physios (id, practice_id, display_name) VALUES ('c0c0c0c0-0000-4000-8000-0000000000a4', '$C1', 'Aehnlich');"
run_seed 3
[ "$("${PSQL[@]}" -At -d $DB -c "SELECT count(*) FROM auth.users WHERE email = 'ahnlich@xtest.curaone.invalid'")" = "1" ] \
  || fail "Konto mit aehnlicher Domain wurde geloescht"
"${PSQL[@]}" -d $DB >/dev/null -c "DELETE FROM public.physios WHERE id = 'c0c0c0c0-0000-4000-8000-0000000000a4'; DELETE FROM auth.users WHERE id = 'c0c0c0c0-0000-4000-8000-0000000000a4';"
echo "PASS Gegenprobe: Konto @xtest.curaone.invalid bleibt, Seed laeuft durch"
snapshot >"$LOGS/snap.3"
diff -q <(grep '^seed:' "$LOGS/snap.2") <(grep '^seed:' "$LOGS/snap.3") >/dev/null || fail "Endzustand nach Lauf 3 verschieden"
echo "PASS Endzustand nach den Mischfaellen (Lauf 3) gleich"

echo "== Kommandozeile: Passwort ist Pflicht (vor jeder Verbindung)"
set +e
cli_out="$(cd "$APP" && env -u CURAONE_SEED_PASSWORD SUPABASE_URL=http://127.0.0.1:1 \
  SUPABASE_SERVICE_ROLE_KEY=PLATZHALTER-KEIN-ECHTER-SCHLUESSEL "$DART" run tool/seed/seed.dart --target local 2>&1)"
cli_rc=$?
set -e
[ "$cli_rc" = "2" ] && grep -q CURAONE_SEED_PASSWORD <<<"$cli_out" && ! grep -q PLATZHALTER-KEIN <<<"$cli_out" \
  || { echo "$cli_out"; fail "ohne CURAONE_SEED_PASSWORD kein Exit 2 mit Meldung"; }
echo "PASS ohne CURAONE_SEED_PASSWORD: Exit 2, Meldung, Schluessel nicht in der Ausgabe"

echo "== Einloesung eines Einladungscodes und Patientensicht"
CODE_LENA="$(grep -o 'EINLADUNG Lena (Testperson) [0-9A-Z]*' "$LOGS/seed.3.out" | awk '{print $NF}')"
out="$("${PSQL[@]}" -d $DB -v code_lena="$CODE_LENA" -f "$HERE/check_seed.sql" 2>&1)" \
  || { echo "$out" | grep -E 'ERROR|not ok' | head; fail "check_seed.sql mit Einloesung"; }
n2="$(grep -c 'NOTICE:  ok - ' <<<"$out" || true)"
echo "PASS check_seed.sql mit Einloesung: $n2 Pruefungen"

echo "== Ergebnis: bestanden (Pruefungen: $n ohne, $n2 mit Einloesung; Logs: $LOGS)"
