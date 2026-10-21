#!/usr/bin/env bash
# DB-Tests gegen ein lokales Wegwerf-Postgres 16 mit Supabase-Rollen-Nachbildung (Plan 12.1, 12.2).
#
#   supabase/tests/run_local_pg.sh [FILTER]
#
# Ablauf: initdb (Temp) -> Nachbildung -> Migrationen von null -> Idempotenz-Pruefung
# (Migrationen ein zweites Mal, Schema-Abzug vorher/nachher gleich) -> je Testdatei eine
# frische Datenbank aus der Vorlage -> Race-Tests mit zwei Verbindungen -> Abbau.
#
# Umgebungsvariablen:
#   PGBIN       Postgres-Binaerdateien (Standard /usr/lib/postgresql/16/bin)
#   PG_WORKDIR  Arbeitsverzeichnis (Standard: mktemp -d). Muss fuer den Server-Benutzer
#               erreichbar sein; laeuft das Skript als root, startet der Server als "postgres".
#   PG_PORT     Port (Standard 55432; nur Unix-Socket, kein TCP)
#   KEEP=1      Cluster nach dem Lauf nicht abbauen (Hinweis zum Stoppen wird ausgegeben)
# FILTER: nur Tests, deren Dateiname den Text enthaelt (z. B. T13 oder race).
#
# Ausschliesslich lokal: keine Verbindung zu einem echten Supabase-Projekt, keine Secrets.
# Der Pepper ist ein offensichtlicher Test-Platzhalter (tests/shim/test_pepper.sql).

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPA="$(cd "$HERE/.." && pwd)"
PGBIN="${PGBIN:-/usr/lib/postgresql/16/bin}"
PORT="${PG_PORT:-55432}"
FILTER="${1:-}"
KEEP="${KEEP:-0}"

if [ -n "${PG_WORKDIR:-}" ]; then
  WORK="$PG_WORKDIR"
  mkdir -p "$WORK"
else
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/curaone-pg.XXXXXX")"
fi
DATA="$WORK/data"
SOCK="$WORK/sock"
LOGS="$WORK/logs"
rm -rf "$DATA" "$SOCK" "$LOGS"
mkdir -p "$SOCK" "$LOGS"

RUN_AS=()
if [ "$(id -u)" = "0" ]; then
  RUN_AS=(runuser -u postgres --)
  chown postgres "$WORK" "$SOCK" "$LOGS"
fi

export PGHOST="$SOCK" PGPORT="$PORT" PGUSER="supabase_admin"
export SUPABASE_DIR="$SUPA"
PSQL=("$PGBIN/psql" -X -q -v ON_ERROR_STOP=1)

cleanup() {
  if [ "$KEEP" = "1" ]; then
    echo "KEEP=1: Cluster laeuft weiter. Stoppen: ${RUN_AS[*]} $PGBIN/pg_ctl -D $DATA stop -m fast"
    return
  fi
  if [ -f "$DATA/postmaster.pid" ]; then
    "${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$DATA" stop -m fast -w >/dev/null 2>&1 || true
  fi
  if [ -z "${PG_WORKDIR:-}" ]; then rm -rf "$WORK"; else rm -rf "$DATA" "$SOCK"; fi
}
trap cleanup EXIT

echo "== Cluster anlegen ($WORK)"
"${RUN_AS[@]}" "$PGBIN/initdb" -D "$DATA" -U supabase_admin --auth=trust -E UTF8 --locale=C >"$LOGS/initdb.log" 2>&1
"${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$DATA" -l "$LOGS/server.log" -w \
  -o "-c listen_addresses='' -k $SOCK -p $PORT -c fsync=off -c timezone=UTC" start >/dev/null

migrations=( "$SUPA"/migrations/*.sql )

setup_db() {  # $1 = Datenbankname
  "${PSQL[@]}" -d postgres -c "CREATE DATABASE $1" >/dev/null
  "${PSQL[@]}" -d "$1" -f "$HERE/shim/supabase_roles.sql" >/dev/null
  "${PSQL[@]}" -d postgres -c "ALTER DATABASE $1 OWNER TO postgres" >/dev/null
}

apply_migrations() {  # $1 = Datenbankname; laeuft als Migrationsrolle postgres
  local m
  for m in "${migrations[@]}"; do
    PGUSER=postgres "${PSQL[@]}" -d "$1" -f "$m" >"$LOGS/migrate.$(basename "$m").log" 2>&1 || {
      echo "FEHLER in Migration $(basename "$m"):"; cat "$LOGS/migrate.$(basename "$m").log"; return 1; }
  done
}

pass=0; fail=0; checks=0
failed=()

echo "== Migrationen von null (${#migrations[@]} Dateien) und Idempotenz"
setup_db curaone_idem
apply_migrations curaone_idem
"$PGBIN/pg_dump" -s -d curaone_idem | grep -v '^\\\(un\)\?restrict ' >"$LOGS/schema_1.sql"
apply_migrations curaone_idem
"$PGBIN/pg_dump" -s -d curaone_idem | grep -v '^\\\(un\)\?restrict ' >"$LOGS/schema_2.sql"
if diff -q "$LOGS/schema_1.sql" "$LOGS/schema_2.sql" >/dev/null; then
  echo "PASS MIG-IDEM  Migrationen zweimal angewandt, Schema-Abzug unveraendert ($(wc -l <"$LOGS/schema_1.sql") Zeilen)"
  pass=$((pass + 1))
else
  echo "FAIL MIG-IDEM  Schema nach zweitem Lauf verschieden:"; diff "$LOGS/schema_1.sql" "$LOGS/schema_2.sql" | head -40
  fail=$((fail + 1)); failed+=("MIG-IDEM")
fi

echo "== Vorlage fuer Tests"
setup_db curaone_tpl
apply_migrations curaone_tpl
"${PSQL[@]}" -d curaone_tpl -f "$HERE/shim/test_pepper.sql" >/dev/null
"${PSQL[@]}" -d curaone_tpl -f "$HERE/db/_helpers.sql" >"$LOGS/helpers.log" 2>&1 || { cat "$LOGS/helpers.log"; exit 1; }
"${PSQL[@]}" -d postgres -c "ALTER DATABASE curaone_tpl WITH IS_TEMPLATE true" >/dev/null

run_sql_test() {  # $1 = Datei
  local f="$1" name db out rc n
  name="$(basename "$f" .sql)"
  db="t_$(echo "$name" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9_\n' '_')"
  "${PSQL[@]}" -d postgres -c "CREATE DATABASE $db TEMPLATE curaone_tpl OWNER postgres" >/dev/null
  set +e
  out="$("${PSQL[@]}" -d "$db" -f "$f" 2>&1)"; rc=$?
  set -e
  "${PSQL[@]}" -d postgres -c "DROP DATABASE $db WITH (FORCE)" >/dev/null
  printf '%s\n' "$out" >"$LOGS/$name.log"
  n="$(grep -c 'NOTICE:  ok - ' <<<"$out" || true)"
  if [ $rc -eq 0 ] && [ "$n" -gt 0 ] && ! grep -q 'not ok - ' <<<"$out"; then
    printf 'PASS %-48s %3d Pruefungen\n' "$name" "$n"; pass=$((pass + 1)); checks=$((checks + n))
  else
    printf 'FAIL %-48s (Exit %d, %d ok)\n' "$name" "$rc" "$n"
    grep -E 'ERROR|not ok' <<<"$out" | head -5 | sed 's/^/     /'
    fail=$((fail + 1)); failed+=("$name")
  fi
}

run_race_test() {  # $1 = Skript
  local f="$1" name db out rc n
  name="race/$(basename "$f" .sh)"
  db="r_$(basename "$f" .sh | tr 'A-Z' 'a-z' | tr -c 'a-z0-9_\n' '_')"
  "${PSQL[@]}" -d postgres -c "CREATE DATABASE $db TEMPLATE curaone_tpl OWNER postgres" >/dev/null
  set +e
  out="$(DB="$db" PGBIN="$PGBIN" bash "$f" 2>&1)"; rc=$?
  set -e
  "${PSQL[@]}" -d postgres -c "DROP DATABASE $db WITH (FORCE)" >/dev/null
  printf '%s\n' "$out" >"$LOGS/$(basename "$f" .sh).log"
  n="$(grep -c '^ok - \|NOTICE:  ok - ' <<<"$out" || true)"
  if [ $rc -eq 0 ] && [ "$n" -gt 0 ] && ! grep -q 'not ok - ' <<<"$out"; then
    printf 'PASS %-48s %3d Pruefungen\n' "$name" "$n"; pass=$((pass + 1)); checks=$((checks + n))
  else
    printf 'FAIL %-48s (Exit %d, %d ok)\n' "$name" "$rc" "$n"
    grep -E 'ERROR|not ok' <<<"$out" | head -5 | sed 's/^/     /'
    fail=$((fail + 1)); failed+=("$name")
  fi
}

echo "== DB-Tests"
for f in "$HERE"/db/T*.sql; do
  [ -e "$f" ] || continue
  [ -n "$FILTER" ] && [[ "$(basename "$f")" != *"$FILTER"* ]] && continue
  run_sql_test "$f"
done
for f in "$HERE"/db/race/*.sh; do
  [ -e "$f" ] || continue
  [ -n "$FILTER" ] && [[ "race/$(basename "$f")" != *"$FILTER"* ]] && continue
  run_race_test "$f"
done

echo "== Ergebnis: $pass bestanden, $fail fehlgeschlagen, $checks Einzelpruefungen (Logs: $LOGS)"
if [ "$fail" -gt 0 ]; then
  printf '   fehlgeschlagen: %s\n' "${failed[*]}"
  exit 1
fi
