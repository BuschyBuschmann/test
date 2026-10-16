# Fixtures „Mitternacht/Zeitzone“ (`local_day`)

Gemeinsame Fixtures nach Plan Ausschnitt 2, 6.7 Nr. 5 (a)–(h). Angelegt in L2 (F2-1).
Genutzt von den SQL-Tests unter `supabase/tests/db/` (DB-T63, DB-T68a, DB-T80), ab L3 von
Dart-Unit-Tests (nur lesend, Pfad relativ zu `app/`: `../supabase/tests/fixtures/local_day/`)
und von den Server-Tests des KI-Plans. Nur Testdaten.

Felder je Fall: `timezone` (IANA), `device_time` (lokale Zeit mit Offset), `utc_instant`,
`local_day` (lokaler Kalendertag des Geräts), `utc_date`, `offset_days` (= `local_day` − `utc_date`).
Erwartungen stehen unter `expect` bzw. je Fall (`immediate` = sofortige Aufrufe ±1 Tag,
`queue` = Warteschlangen-Grenze Bindungstag − 1 bis UTC-Datum + 1).

| Datei | Plan 6.7 Nr. 5 |
|---|---|
| `a_berlin_0030_release_on_d.json` | (a) |
| `b_berlin_2330_day_before.json` | (b) |
| `c_timezones_midnight.json` | (c), zusätzlich UTC+14/UTC−12 |
| `d_out_of_range.json` | (d) |
| `e_dst_berlin_2026-10-25.json` | (e) |
| `f_session_over_midnight.json` | (f) |
| `g_checkup_0010.json` | (g), Auswertung ab L5 |
| `h_late_checkup.json` | (h), Auswertung ab L5 (DB-T83) |

Die Zeitangaben sind mit der IANA-Zeitzonendatenbank erzeugt; DB-T80 prüft sie zusätzlich gegen
die Zeitzonendaten von Postgres.
