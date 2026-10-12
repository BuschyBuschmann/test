# Flutter-Plan Ausschnitt 2 „Fundament“: Patienten-Framework mit Physio-Zugang (ohne KI)

Status: **FREIGEGEBEN (2026-10-12) mit Nutzerentscheidungen; Prüfung am Code in F2-1R** · v1.2 (v1.1 nach Re-Review R-P2-RR und Nutzerentscheidungen Runde 2; v1.1 nach Review R-P2) · Paket P2-K2 · Autor: `flutter-developer` · Stand 2026-10-12

Verbindliche Grundlagen:
- `docs/produkt/curaone-spezifikation-manny-gehirn.md` (FREIGEGEBEN 2026-10-11), Abschnitt 4 (P-1 bis P-5, A-1 bis A-4, T-1), 7, 8, 10.
- Nutzerentscheidung: **Backend Supabase in der EU** (Spec 3, Punkt 13).
- **Nutzerentscheidungen 2026-10-12** (Abschnitt 0).
- `KONVENTIONEN.md` (Regeln 1–5), `docs/plan/flutter-plan-v1.md` v1.3 (Architektur, Prüf-Infrastruktur 12), KI-Plan v2.2 (Löschkonzept, Chat-Bindung).

Kontext (gelesen, nicht zur Anforderung umgedeutet): `docs/UEBERGABE.md`, `docs/produkt/curaone-app-pruefung.md`, Code unter `app/lib` (nur lesend; Stand HEAD `5a493ed`, parallel laufende Änderungen unter `app/` sind beim Start von F2-3 neu zu lesen).

Kennzeichnung: **B-n** = Annahme, **O-n** = Frage (O-1 bis O-7 aus der Spec, O-8 bis O-16 aus diesem Plan; Stand: Abschnitt 12), **R2-n** = Risiko, **X2-n** = externer Schritt, **F2-n** = Arbeitspaket, **DB-Tn** = benannter Datenbanktest (Abschnitt 10.2), **[entschieden]** = vom Plan vorgeschlagener, vom Nutzer am 2026-10-12 bestätigter Wert; **[Vorschlag]** = noch nicht bestätigter Wert; **[vor F2-1 zu entscheiden]** = blockierender offener Wert. Gestaltung kommt über Ablauf C vom `ui-designer`; dieser Plan nennt **Funktionen und Zustände**.

---

## 0. Nutzerentscheidungen (verbindlich)

**2026-10-12, zu Plan v1:**
- **O-13** Physio-Web im selben Flutter-Projekt, zweiter Einstieg `main_physio.dart` (Variante W-A).
- **O-4** Pfad aus Physio-Phasen mit geplanten Wochen; aktuelle Phase setzt der Physio; Units werden nur durch Training erledigt; Streak und Freezes bleiben.
- **O-10** „Heute“ ohne KI: Übungen der aktuellen Phase der Reihe nach, bis die Zeitwahl gefüllt ist; Tauschen aus dem Rest der Phase.
- **O-9** „Alles löschen“: alle Patientendaten und das Konto; Einträge des Physios bleiben bei der Praxis ohne Verbindung zum Patienten.
- Übrige Vorschläge (O-1 bis O-3, O-5 bis O-8, O-11, O-12, O-14 bis O-16) gelten als **Annahmen**. Die Warnzeichen-Schwellen (O-2) werden vor dem Bau separat abgefragt.

**2026-10-12, zu Review R-P2:**
- **N-1** Handywechsel/Neubindung: Der Chat bleibt beim alten Gerät. Ein neuer Code startet ein neues Gespräch, der alte Chat wird gelöscht. Plan, Verlauf und Befinden bleiben. Der Patient wird über jede Neuanmeldung informiert.
- **N-2** Warnzeichen aus dem Chat (auch Krise/Selbstgefährdung) gehen an den Physio, ohne Chattext (Stufe, Zeitpunkt); die Einwilligung nennt das ausdrücklich, auch für Krisen.
- **N-3** Ersatzprogramm bei hohem Schmerz: automatisch kürzen nach fester Regel mit Hinweis (KI-Plan v2.2, 4.2).
- **N-4** Der Physio sieht alle Patienten seiner Praxis (keine Zuordnung Physio–Patient).
- **N-5** Alle MINOR-, KI-MINOR- und NITPICK-Befunde einarbeiten; nötige Werte schlägt der Plan vor; E-24 bleibt als Annahme/offen gekennzeichnet.

**2026-10-12, Runde 2 (Re-Review R-P2-RR):**
- **N-6** Keine globale Einlöse-Bremse; nur je Sitzung (5 Fehlversuche je 15 Minuten); Hauptschutz ist die Entropie des Codes.
- **N-7** Bestätigt: Code 10 Zeichen Crockford-Base32 mit HMAC und Pepper (4.5); Dauer-Schätzregel 4 s je Wiederholung + 60 s je Satzpause (6.4); Kürzungsregel E-36 und Zahlenverbot E-37 (KI-Plan v2.2).
- **N-8** NEU-1 bis NEU-8 und NITPICKs einarbeiten; danach freigegeben, Prüfung am Code in F2-1R.

**Vor F2-1 bzw. KI-1/KI-2 zu entscheiden (blockierend):** O-2 Warnzeichen-Schwellen; KI-Plan E-7, E-15, E-27, E-28, E-30, E-31.

---

## 1. Kurzfassung

| Thema | Plan |
|---|---|
| Backend | Supabase-Projekt in EU-Region: Postgres mit RLS, Supabase Auth. **Keine Edge Functions in Ausschnitt 2**. Storage nicht (O-5 = später) |
| Rollenmodell | Tabellen und `SECURITY DEFINER`-Funktionen gehören der Migrationsrolle; RLS **ohne `FORCE`** (der Eigentümer umgeht RLS, die API-Rollen nicht). Jede Definer-Funktion prüft Rechte selbst. Supabase-Standardrechte werden ausdrücklich entzogen (Abschnitt 4.1) |
| Datenmodell | 17 Tabellen (Abschnitt 4.3), alle mit RLS; Praxis trennt Physios; Patient sieht nur sich selbst; jeder Physio sieht alle Patienten seiner Praxis (N-4) |
| Auth Physio | E-Mail + Passwort, keine Selbstregistrierung |
| Auth Patient | Anonyme Supabase-Sitzung (Rolle `authenticated`, Claim `is_anonymous`) **ohne Rechte**, bis `redeem_invitation(code)` sie an genau einen Patienten bindet. Code 10 Zeichen Crockford-Base32 (50 Bit), HMAC-gespeichert, Ablauf 14 Tage, Bremse nur je Sitzung (N-6) |
| Neubindung (N-1) | Neuer Code bindet die neue Sitzung; alte Sitzung verliert Zugriff, ihr Auth-Konto wird gelöscht; ab Ausschnitt 3 wird der Chat der alten Identität gelöscht; Hinweis auf beiden Geräten |
| Physio-Web | zweiter Einstieg im selben Projekt (O-13) |
| Patienten-App | Start mit Code → Einwilligung (nennt Physio-Sicht inkl. Warnzeichen aus dem Chat, auch bei Krisen, N-2) → Pfad aus Phasen (O-4) → „Heute“ der Reihe nach (O-10) mit Übungsdetail und Tauschen → Befinden → Akte → „Alles löschen“ mit Backend (O-9) |
| Plan speichern | stabile IDs: Upsert nach ID, nur Entferntes löschen; Verlauf bleibt unberührt |
| Offline | Lesen aus Zwischenspeicher; Schreiben über persistente Warteschlange; vor dem Löschen wird sie angehalten und geleert |
| Testdaten | `dart run tool/seed/seed.dart` |
| Verifikation | bestehende Kette + 47 benannte DB-Tests gegen lokales Postgres 16 mit Supabase-Rollen-Nachbildung; Ende-zu-Ende erst mit lokalem Supabase-Stack |

---

## 2. Physio-Web-Zugang (O-13 entschieden: W-A)

Zweiter Einstiegspunkt im selben Flutter-Projekt: `app/lib/main_physio.dart`, Code unter `app/lib/physio/`, Build `flutter build web -t lib/main_physio.dart -o build/physio_web`. Begründung (aus v1): gemeinsame reine Logik, Modelle, Repositories, Validierung und Prüfketten; Tree-Shaking hält den Physio-Code aus dem Patienten-Build. Verworfen: eigenes Projekt mit gemeinsamem Paket (Umbau während Parallelarbeit), eigene Web-App (zweite Sprache).

Grenzen per statischer Regel:
- `lib/physio/**` importiert nichts aus `lib/ui/**` außer `lib/ui/components/**` (falls der Brief Bausteine teilt); `lib/ui/**` nichts aus `lib/physio/**`.
- `package:supabase_flutter` nur unter `lib/backend/**` und in `main*.dart`.
- Physio-Texte in `lib/l10n/strings_physio_de.dart`.

Bereitstellung: lokal (Annahme O-16); Hosting nur auf Wunsch (X2-6).

---

## 3. Projekt- und Ordnerstruktur

```
supabase/                                  # Repo-Stamm, Layout der Supabase-CLI
  config.toml                              # lokaler Stack (anonyme Anmeldung an, Registrierung aus); ohne Secrets
  migrations/
    <ts>_01_rollen_und_rechte.sql          # REVOKE der Standardrechte, Default Privileges, Schema app
    <ts>_02_grundschema.sql                # Tabellen, Typen, Constraints, Fremdschlüssel
    <ts>_03_rls.sql                        # RLS an (ohne FORCE), Hilfsfunktionen, Policies, Spalten-Grants
    <ts>_04_trigger.sql                    # created_by-Setzer, Schreibsperre je Patient, Warnzeichen
    <ts>_05_funktionen.sql                 # RPCs (Einladung, Plan, Phase, Einwilligung, Löschen)
  tests/
    shim/supabase_roles.sql                # NUR Tests ohne Supabase-Stack: Rollen, Grants, auth-Schema (10.1)
    db/T01_*.sql … T40_*.sql               # benannte DB-Tests (10.2)
    db/race/*.sh                           # Nebenläufigkeitstests mit zwei Verbindungen
    run_local_pg.sh                        # initdb (Temp), Shim, Migrationen, Tests, Abbau
app/
  config/supabase.example.json             # Platzhalter: SUPABASE_URL, SUPABASE_ANON_KEY, INVITE_LINK_BASE
  config/supabase.local.json               # nicht eingecheckt
  lib/
    main.dart, main_physio.dart, main_preview.dart, main_physio_preview.dart
    logic/   framework.dart, wellbeing.dart, invite_code.dart, plan_today.dart, exercise_duration.dart,
             path_from_phases.dart, outbox.dart, plan_validation.dart
    data/    framework_repository.dart, framework_cache.dart, outbox_store.dart, account_deleter.dart
    backend/ supabase_config.dart, supabase_patient_repository.dart, supabase_physio_repository.dart,
             outbox_sender.dart, backend_errors.dart
    ui/      start/ (Code, Link, Hinweise), onboarding/ (Einwilligung), today/exercise_detail_sheet.dart,
             wellbeing/, record/
    physio/  physio_app.dart, login/, patients/, invite/, plan_editor/, record/, history/
    l10n/strings_physio_de.dart
    dev/     Fake-Repositories, Szenarien Patient und Physio
  tool/seed/seed.dart, tool/seed/testdaten.json
  tool/screens/  shoot.mjs, nav_checks.mjs (+ Physio)
```

`.gitignore` ergänzt um `app/config/supabase.local.json`, `supabase/.temp/`, `supabase/.branches/`, `.env*`.

---

## 4. Backend

### 4.1 Rollen- und Rechtemodell (M-1, M-2, M-3)

Supabase-Rollen (laut Supabase-Doku; Attribute im echten Stack **zu bestätigen**, X2-8): `anon` (ohne Anmeldung), `authenticated` (jede angemeldete Sitzung, **auch anonyme**; Unterscheidung über JWT-Claim `is_anonymous`), `service_role` (`BYPASSRLS`, nur Seed), Migrationsrolle `postgres` (Eigentümer).

Festlegungen:
1. **Eigentümer:** Alle Tabellen, Sichten und Funktionen in `public` und `app` gehören der Migrationsrolle. RLS wird mit `ENABLE ROW LEVEL SECURITY` eingeschaltet, **nicht** mit `FORCE` (v1 korrigiert): Mit `FORCE` und einem Eigentümer ohne `BYPASSRLS` sehen `SECURITY DEFINER`-Funktionen 0 Zeilen (im Review mit Postgres 16 belegt). Die API-Rollen sind nie Eigentümer, für sie gilt RLS immer.
2. **Standardrechte entziehen:** Supabase vergibt standardmäßig Tabellenrechte an `anon` und `authenticated` und `EXECUTE` an `PUBLIC`. Migration 01:
   - `REVOKE ALL ON ALL TABLES/SEQUENCES IN SCHEMA public FROM anon, authenticated;`
   - `REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public, app FROM PUBLIC, anon, authenticated;`
   - `ALTER DEFAULT PRIVILEGES … REVOKE …` für künftige Objekte (gleiche Liste).
   - Danach **einzeln** `GRANT` nur der benötigten Operationen an `authenticated` (Spalte „Recht“ in 4.3) und `EXECUTE` nur auf die RPCs in 4.4.
   - Schema `app` (Hilfsfunktionen) ohne `USAGE` für `anon`; `authenticated` erhält `USAGE` nur, weil Policies die Hilfsfunktionen aufrufen, und `EXECUTE` nur auf diese Hilfsfunktionen.
3. **Keine Sichten über geschützte Tabellen** ohne `security_invoker = true`. Die Einladungs-Sicht aus v1 entfällt; der Physio liest `invitations` direkt mit RLS-Policy und **Spalten-Grant ohne `code_hmac`** (M-2).
4. **Jede `SECURITY DEFINER`-Funktion:** `SET search_path = ''`, voll qualifizierte Namen, prüft als Erstes Aufrufer und Rolle (anonym/gebunden/Physio) und die Zugehörigkeit (Praxis, Patient) selbst – RLS gilt in ihr nicht.
5. **Hilfsfunktionen** (Definer, `STABLE`): `app.uid()` (= `auth.uid()`), `app.is_anonymous()` (Claim `is_anonymous`, fehlend = `false`), `app.current_physio_practice()`, `app.current_patient_id()` (gebunden **und** `status = 'active'`), `app.physio_can_see_patient(p)`.
6. **Seed** nutzt `service_role` (nur lokal bzw. X2-4), nie die App.

### 4.2 Auth-Nachbildung für Tests: siehe 10.1.

### 4.3 Tabellen

Grundsätze: `uuid`-Schlüssel; Schreibvorgänge der Warteschlange mit Geräte-IDs (`insert … on conflict (id) do nothing`); `timestamptz`; Kalendertage `date`; Test-Kennzeichen `practices.is_test`.

| Tabelle | Wichtige Spalten | Recht für `authenticated` (über RLS) | Schreibpfad sonst |
|---|---|---|---|
| `practices` | `id`, `name`, `is_test` | SELECT (Physio eigene Praxis) | Seed |
| `physios` | `id` → `auth.users` (`ON DELETE CASCADE`), `practice_id`, `display_name` | SELECT (gleiche Praxis) | Seed |
| `patients` | `id`, `practice_id`, `first_name`, `last_name`, `injury_label`, `reference_date`, `auth_user_id` → `auth.users` (**`ON DELETE SET NULL`**, unique), `status` (`invited` · `active` · `deleting` · `access_deleted`), `current_phase_id` → `phases` (`ON DELETE SET NULL`), `bound_at` | SELECT (Physio der Praxis; Patient eigene Zeile); UPDATE der Stammdatenspalten (Physio, Spalten-Grant) | RPCs (Bindung, Status, Phase) |
| `invitations` | `id`, `patient_id`, `code_hmac`, `expires_at`, `redeemed_at`, `redeemed_by`, `revoked_at`, `failed_attempts` | SELECT nur über Spalten-Grant `(id, patient_id, expires_at, redeemed_at, revoked_at, failed_attempts)` (Physio der Praxis); `select=*` scheitert daher, das Repository nennt die Spalten ausdrücklich | RPCs |
| `redeem_attempts` | `id`, `uid`, `at`, `ok` | – | `redeem_invitation`; löscht bei jedem Aufruf Zeilen älter als 24 Stunden (NITPICK; DB-T47) |
| `exercises` | `id`, `practice_id` (null = Katalog), `name`, `description` (beide `CHECK` nicht leer), `is_example`, `created_by` | SELECT (Physio: Katalog + Praxis; Patient: nur Übungen im eigenen Plan); INSERT/UPDATE eigene Praxis (Physio); DELETE nur ungenutzt | Seed (Katalog) |
| `plans` | `id`, `patient_id` (unique), `version`, `updated_at`, `updated_by` | SELECT | `save_plan` |
| `phases` | `id`, `plan_id`, `position`, `title`, `planned_weeks` (`CHECK 1–52`) | SELECT | `save_plan` |
| `plan_items` | `id`, `plan_id`, `phase_id` (`ON DELETE CASCADE` innerhalb des Plans), `exercise_id` (`ON DELETE RESTRICT`), `position`, `sets`, `reps`, `duration_min` (je `null` oder `CHECK > 0`), `load_note` | SELECT | `save_plan` |
| `treaters` | `id`, `patient_id`, `role`, `name`, `phone`, `email`, `address`, `note` | SELECT (beide); INSERT/UPDATE/DELETE (Physio) | – |
| `appointments` | `id`, `patient_id`, `treater_id` (`ON DELETE SET NULL`), `starts_at`, `title`, `location`, `created_by_role`, `created_by` | SELECT (beide); INSERT/UPDATE/DELETE nur eigene (`created_by = app.uid()`) | – |
| `history_entries` | `id`, `patient_id`, `kind`, `title`, `occurred_on`, `note` | SELECT (beide); INSERT/UPDATE/DELETE (Physio) | – |
| `training_sessions` | `id` (Gerät), `patient_id`, `local_day`, `logged_at`, `phase_id` (**`ON DELETE SET NULL`**), `plan_version`, `items` (`jsonb`-Momentaufnahme, **kein** Fremdschlüssel auf `plan_items`) | SELECT (beide); INSERT, DELETE eigene (Patient, Rückgängig) | – |
| `wellbeing_reports` | `id` (Gerät), `patient_id`, `local_day`, `reported_at`, `pain` 0–10, `swelling` 0–3, `mood` 1–5 | SELECT (beide); **kein** direktes INSERT/UPDATE/DELETE (m-5) | `report_wellbeing` (B-15), `delete_my_data` |
| `warning_rules` | `id`, `version`, `rule jsonb`, `active`, `is_provisional` | – | Migration/Seed |
| `warning_signs` | `id`, `patient_id`, `created_at`, `source` (`wellbeing`; ab Ausschnitt 3 `chat`), `layer` (`trigger`; ab Ausschnitt 3 `device`/`server`/`model`), `level`, `reason_code`, `wellbeing_report_id`, `client_message_id` (Ausschnitt 3), `seen_at`; **keine Textspalte** | SELECT (Physio der Praxis); **kein INSERT** | Trigger (Ausschnitt 2); RPC/Funktionen aus KI-Plan v2.2 4.3 (Ausschnitt 3) |
| `consents` | `id`, `patient_id`, `kind`, `version`, `accepted_at`, `revoked_at` | SELECT (beide) | `accept_consent` |
| `account_events` | `id`, `patient_id`, `kind` (`bound`, `rebound`), `at` | SELECT (Patient) | `redeem_invitation` (N-1) |

**Trigger (Migration 04):**
- `app.set_created_by()` – `BEFORE INSERT` auf `appointments`, `exercises`: setzt `created_by = app.uid()` und `created_by_role` aus der Rolle (Physio/Patient); Client-Werte werden überschrieben (m-3).
- `app.lock_patient_for_write()` – `BEFORE INSERT/UPDATE/DELETE` auf `training_sessions`, `wellbeing_reports`, `appointments`, `consents`, `warning_signs` (ab Ausschnitt 3 auch Chat-Tabellen, KI-Plan v2.2, 8; NEU-3). **`SECURITY DEFINER`, `SET search_path = ''`** (NEU-1: als Invoker verlangte `FOR SHARE` eine UPDATE-Berechtigung, ein aktiver Patient konnte nicht schreiben).
  - Zeile: bei INSERT/UPDATE `NEW`, bei **DELETE `OLD`** (NEU-1); `patient_id` daraus.
  - **Gilt nur für Schreibvorgänge im Namen des Patienten** (NEU-2): ausgenommen sind Physio-Sitzungen (`app.current_physio_practice() IS NOT NULL`) und der Seed (`service_role`, erkennbar an `auth.role()` bzw. `current_user`). Edge Functions ab Ausschnitt 3 schreiben im Namen des Patienten und unterliegen der Sperre (KI-Plan v2.2, 8).
  - Prüfung: `SELECT 1 FROM public.patients WHERE id = <patient_id> AND status = <erlaubt> FOR SHARE`; keine Zeile → `42501`. Erlaubt ist bei INSERT/UPDATE nur `active`, bei DELETE `active` oder `deleting` (damit die Löschung ab Ausschnitt 3 nach dem Setzen von `deleting` die eigenen Daten entfernen kann, KI-Plan v2.2, 8).
  - Damit pflegt der Physio Akte und Termine auch für Patienten mit Status `invited` oder `access_deleted`; der Seed schreibt ohne Bindung.
  - Serialisiert gegen `delete_my_data` (M-4): Die Löschfunktion hält `FOR UPDATE` auf derselben Zeile; ihre eigenen Löschungen laufen in derselben Transaktion, solange der Status noch `active` ist (4.7, Reihenfolge).
- `app.raise_warning_signs()` – `AFTER INSERT` auf `wellbeing_reports`, `SECURITY DEFINER`, `SET search_path = ''`, wertet aktive `warning_rules` aus (O-2) (m-5).

### 4.4 Funktionen (RPC)

Alle: `SECURITY DEFINER`, `SET search_path = ''`, `REVOKE EXECUTE … FROM PUBLIC, anon`, `GRANT EXECUTE … TO authenticated`; erste Anweisung prüft den Aufrufer, Fehler `42501`.

| Funktion | Erlaubter Aufrufer (selbst geprüft) | Wirkung |
|---|---|---|
| `create_patient(first_name, last_name, injury_label, reference_date)` | Physio (nicht anonym, `physios`-Zeile) | Patient in eigener Praxis + Einladung; liefert Klartext-Code einmalig |
| `regenerate_invitation(patient_id)` | Physio derselben Praxis | widerruft offene Einladung, erzeugt neue (O-8) |
| `redeem_invitation(code)` | **anonyme** Sitzung (`is_anonymous = true`), **kein** Physio, **nicht bereits gebunden** (M-3) | Bremsen prüfen (4.5), Code normalisieren, HMAC vergleichen, Ablauf/Widerruf/eingelöst prüfen. Patient `invited` → binden. Patient `active` (Neubindung, N-1) → alte Identität lösen, `app.on_rebind(old_uid)` (Ausschnitt 3: Chat der alten Identität löschen), altes Auth-Konto löschen, `account_events.rebound`. Ergebnis `ok` · `ok_rebound` · `invalid` · `already_used` · `expired` · `too_many_attempts` · `not_allowed` |
| `accept_consent(kind, version)` | gebundener Patient | Einwilligung speichern |
| `report_wellbeing(id, local_day, pain, swelling, mood)` | gebundener, aktiver Patient | idempotenter Insert (Geräte-ID) mit Schreibsperre wie 4.3; liefert nur `warning_raised boolean`. `warning_raised` wird **immer** aus vorhandenen `warning_signs` mit `wellbeing_report_id = id` ermittelt, auch bei Wiederholung derselben ID (NEU-7) (B-15, O-12) |
| `save_plan(patient_id, expected_version, plan jsonb)` | Physio derselben Praxis | siehe 4.6 |
| `set_current_phase(patient_id, phase_id)` | Physio derselben Praxis | Phase muss zum Plan des Patienten gehören |
| `mark_warnings_seen(patient_id)` | Physio derselben Praxis | `seen_at` setzen (O-11) |
| `delete_my_data()` | gebundener Patient; ungebundene anonyme Sitzung → `already_deleted` | siehe 4.7 |

### 4.5 Einladungscode (m-2) [entschieden, N-6/N-7]

| Punkt | Festlegung | Begründung |
|---|---|---|
| Alphabet | Crockford-Base32: `0–9`, `A–Z` ohne `I L O U` (32 Zeichen) | keine verwechselbaren Zeichen, 5 Bit je Zeichen |
| Länge | 10 Zeichen, Anzeige `XXXXX-XXXXX` | **50 Bit** (≈ 1,1 · 10¹⁵ Codes); auch bei 1000 gültigen Codes Trefferchance je Versuch ≈ 10⁻¹² |
| Normalisierung | Großschreibung; Leerzeichen und Bindestriche entfernen; `O→0`, `I`/`L→1` | Tippfehler beim Abschreiben |
| Erzeugung | `gen_random_bytes` (pgcrypto) in der Funktion | kryptografischer Zufall |
| Speicherung | `HMAC-SHA256(pepper, code)`; Pepper in einer Tabelle `app.secrets` ohne Rechte für API-Rollen, Wert per externem Schritt (X2-11), lokal per Testwert | Datenbank-Abzug allein verrät keine Codes |
| Bremse je Sitzung | 5 Fehlversuche je 15 Minuten | Tippfehler erlaubt, Durchprobieren nicht |
| Bremse global | **keine** (N-6) | Hauptschutz ist die Entropie: selbst bei 10⁶ Fehlversuchen über viele Sitzungen und 1000 gültigen Codes liegt die Trefferchance bei ≈ 10⁻⁶; eine globale Bremse ließe sich zum Sperren aller Einlösungen missbrauchen |
| Bremse je IP | Supabase-Ratenbegrenzung für anonyme Anmeldungen (Wert im Projekt prüfen) und optional Captcha (X2-2) | die Datenbank sieht die IP nicht zuverlässig |
| Ablauf | 14 Tage (O-7, Annahme) | |

### 4.6 Plan speichern mit stabilen IDs (M-5)

- Das Physio-Web vergibt IDs für neue Phasen und Positionen auf dem Client; bestehende behalten ihre ID.
- `save_plan`: in einer Transaktion, `SELECT … FROM plans WHERE id = … FOR UPDATE`, Version prüfen (`conflict`), dann
  1. Phasen: Upsert nach `id`; Phasen, die im Payload fehlen, löschen (ihre `plan_items` per `CASCADE`);
  2. Positionen: Upsert nach `id`; fehlende löschen;
  3. `current_phase_id` aus dem Payload setzen; Pflicht, sobald Phasen existieren, und muss eine Phase dieses Plans sein → sonst Fehler `current_phase_required`;
  4. Prüfungen: **jede Phasen- und Positions-ID im Payload gehört zu diesem Plan oder existiert noch nirgends** – eine ID eines anderen Plans → Fehler `foreign_id` (NEU-5; DB-T46); Übung ist Katalog oder eigene Praxis; Wertebereiche; Pflichtfelder eigener Übungen (Constraint);
  5. `version + 1`.
- **Verlauf bleibt unberührt:** `training_sessions` hat keinen Fremdschlüssel auf `plan_items` (Momentaufnahme in `items`); `phase_id` wird beim Löschen einer Phase `NULL`.
- App: Tagesänderungen (`removed`, `swaps`) verweisen auf `plan_items.id`; entfallene IDs werden verworfen (B-10).
- Tests DB-T20 bis DB-T24, DB-T46.

### 4.7 Löschen (O-9, M-4, m-6)

`delete_my_data()`:
1. Aufrufer prüfen; nicht gebunden und anonym → `already_deleted` (idempotent; die App wertet das als Erfolg).
2. `SELECT … FROM patients WHERE auth_user_id = app.uid() FOR UPDATE` → wartet auf laufende Schreibvorgänge (die `FOR SHARE` halten) und blockiert neue.
3. Löscht – solange der Status noch `active` ist, damit die Schreibsperre in derselben Transaktion greift (NEU-1) – vom Patienten erzeugte Daten: `training_sessions`, `wellbeing_reports`, `warning_signs` des Patienten, eigene `appointments`, `consents`, `account_events` (ab Ausschnitt 3 auch Chat-Tabellen, KI-Plan v2.2, 8).
4. Bleibt bei der Praxis (O-9): Patientenzeile (Stammdaten), Plan, Behandler, Krankengeschichte, Physio-Termine; **erst danach** `auth_user_id = NULL`, `status = 'access_deleted'`, offene Einladungen widerrufen. Der Physio kann diese Daten weiter pflegen (NEU-2; DB-T44).
5. Löscht das Auth-Konto `auth.users` des Aufrufers (B-7; Ausweg Edge Function, R2-12).
6. Ein Schreibvorgang, der auf die Sperre gewartet hat, findet danach `status <> 'active'` und scheitert mit `42501` (DB-T31).

`deleting` wird in Ausschnitt 2 nicht sichtbar (eine Transaktion); der Wert existiert im Typ für Ausschnitt 3, wenn Edge Functions lange Antworten streamen (KI-Plan v2.2, 8).

---

## 5. Auth und Zugang

### 5.1 Physio (P-1)
E-Mail und Passwort, keine Selbstregistrierung. Zustände: Laden, falsche Zugangsdaten (verständliche Meldung, kein Zugang), keine Verbindung, Sitzung abgelaufen, Konto ohne Physio-Zeile („Kein Physio-Zugang“, Abmelden). Abmelden jederzeit. Jeder Physio sieht alle Patienten seiner Praxis (N-4).

### 5.2 Patient (A-1)
1. Start ohne Bindung → Startbildschirm „Zugang über deinen Physio“ mit Code-Feld. Kein anderer Weg (Ausnahme Präsentationsmodus, O-14).
2. „Weiter“: anonyme Anmeldung (falls keine Sitzung), dann `redeem_invitation`.
3. `ok` → Einwilligung → Pfad. `ok_rebound` → Hinweis „Neu angemeldet: Auf deinem bisherigen Gerät ist der Zugang beendet, dein Manny-Gespräch beginnt neu“ (Wortlaut F2-D; Chat-Teil erst ab Ausschnitt 3) → Einwilligung → Pfad.
4. Fehler je Ergebniscode mit eigenem Text; `already_used` mit Hinweis (P-2 AK 2).

**Einwilligung (A-1 AK 3, N-2):** nennt ausdrücklich, dass der Physio Verlauf, Befinden und Warnzeichen sieht – **auch Warnzeichen aus dem Manny-Chat, einschließlich Hinweisen auf eine Krise, nur mit Stufe und Zeitpunkt, ohne Chattext** – und den Manny-Chat selbst nicht. Wortlaut F2-D/Nutzer. Versionsnummer `physio_sharing-1`.

**Neuanmeldung, altes Gerät (N-1):** Die alte Sitzung erhält beim nächsten Aufruf `401`/`42501`; die Sitzungserneuerung scheitert, weil das Konto gelöscht ist → App zeigt „Du wurdest auf einem anderen Gerät angemeldet“, löscht lokale Daten, Startbildschirm (B-11).

**Link und QR (m-9) [Vorschlag]:**
- Inhalt des QR-Codes = Einladungslink. Mit gesetztem `INVITE_LINK_BASE` (Präsentation im Browser, Annahme O-16): `<INVITE_LINK_BASE>/?einladung=XXXXX-XXXXX`. Ohne: `curaone://einladung?code=XXXXX-XXXXX` (App auf dem Gerät).
- Das Physio-Web zeigt Code, Link und QR (P-2 AK 1); eine Konfiguration, kein Umschalter in der Oberfläche.
- Der Link füllt das Code-Feld, eingelöst wird erst nach Bestätigung (B-8). Paket `app_links` für das URL-Schema.

---

## 6. Patienten-App: Umbau des ersten Ausschnitts

Nähte: `PathSource`/`TodaySource.prepare()`, `StateStore`, `DataEraser`-Liste, `MannyTextSource`, `MannyContext`.

### 6.1 Zustandsdokument und Migration
Schema 2: Abschnitt `account {patientId, boundAt}`; neue Schlüssel `curaone.framework.v1`, `curaone.outbox.v1`, `curaone.deletion.v1` in `kAllStorageKeys`. Migration 1 → 2: ohne `account` → Startbildschirm. Nach dem Einlösen startet der lokale Fortschritt neu (B-9). Fixture `state_v2.json`.

### 6.2 Laden und Zwischenspeicher
Laden bei Start, Fortsetzen und **Öffnen von „Heute“** (P-3 AK 3). Fehler/offline → Zwischenspeicher mit Hinweis „nicht aktuell“; ohne Zwischenspeicher → Fehlerzustand mit „Nochmal versuchen“. Status `access_deleted`/gelöste Bindung → lokale Daten löschen, Startbildschirm (B-11).

### 6.3 Pfad aus Physio-Phasen (O-4 entschieden; Regel vollständig, m-7)
Reine Funktion `buildPathFromPhases(phases, currentPhaseId, completedUnitIds)` in `lib/logic/path_from_phases.dart`; `path_generator.dart` bleibt für den Beispielpfad.

1. **Aufbau:** Phasen in Physio-Reihenfolge. Je Phase `planned_weeks` Wochen; je Woche 3 Trainingstage und 1 Wochenziel (wie im ersten Ausschnitt); am Ende jeder Phase ein Phasen-Abschluss; nach der letzten Phase Boss „Return to Sport“, darüber der Ausblick (unverändert).
2. **IDs:** `<phaseId>-w<n>-d<k>`, `<phaseId>-w<n>-goal`, `<phaseId>-end`, `boss` – an die stabile Phasen-ID gebunden (4.6).
3. **Erledigt** ausschließlich über `completedUnitIds` (lokal). Kein Datumsautomatismus mehr: Der Teil der Grenze K-1, nach dem Units allein durch das Kalenderdatum erledigt wurden, entfällt. Bestehen bleibt, dass die Kopfzeile „Woche N“ die Kalenderwoche seit `reference_date` zeigt und daher von der Lage der aktuellen Unit abweichen kann (NITPICK).
4. **Aktuelle Unit** = erste nicht erledigte Unit **der aktuellen Phase** in Reihenfolge. „Training eintragen“ erledigt genau diese Unit.
5. **Aktuelle Phase vollständig erledigt:** keine aktuelle Unit; Manny sitzt auf der letzten erledigten Unit der Phase; Eintragen zählt nur für Streak und Verlauf, bis der Physio weiterschaltet.
6. **Physio schaltet vor:** Units früherer Phasen, die nicht erledigt sind, bekommen den Anzeigestatus „ausgelassen“ (nicht erledigt, nicht antippbar; Gestaltung F2-D); aktuelle Unit = erste offene Unit der neuen Phase.
7. **Physio schaltet zurück:** Erledigtes bleibt erledigt; aktuelle Unit = erste offene Unit der nun aktuellen Phase (oder Regel 5); Units späterer Phasen sind „gesperrt“.
8. **Phasen später als die aktuelle:** gesperrt. Boss immer gesperrt.
9. **Planänderung:** Units entfernter Phasen/Wochen fallen weg, ihre IDs in `completedUnitIds` werden ignoriert; neue Wochen erscheinen offen.
10. **Kopfzeile:** „Woche N“ = Kalenderwoche seit `reference_date` (Begrenzung 1 … Summe `planned_weeks`), „Phase P · <Titel>“ mit P = Position der aktuellen Phase. Ohne Phasen: Leerzustand „Dein Physio stellt deinen Plan noch zusammen“ (Wortlaut F2-D).
11. Streak, Freezes, Feier, Manny-Anlässe unverändert. Label „Beispielpfad“ nur im Beispielmodus.

Unit-Tests: Aufbau und IDs für 1/3 Phasen mit 1/4/12 Wochen; Eintragen erledigt die aktuelle Unit; Ende der Phase (Regel 5); Vorschalten mit offenen Units (Regel 6); Zurückschalten (Regel 7); Plan verkürzt/verlängert (Regel 9); Kopfzeile bei Datum heute, +27, +200 Tage und in der Zukunft; leerer Plan; Boss nie aktuell.

### 6.4 „Heute“ aus dem Plan (O-10 entschieden; A-2)
- **Dauer je Position (m-8) [entschieden, N-7]**, Funktion `estimateMinutes` in `lib/logic/exercise_duration.dart`, gleiche Regel im Physio-Web (Anzeige) und im KI-Plan (S8b):
  - `duration_min` gesetzt → dieser Wert;
  - sonst `sets` und `reps` gesetzt → `aufrunden((sets × reps × 4 s + (sets − 1) × 60 s) / 60)`, mindestens 1;
  - sonst nur `sets` → `sets × 1 Minute`; sonst 5 Minuten.
  - Begründung: 4 s je Wiederholung und 60 s Satzpause sind übliche Richtwerte für ruhige Kräftigungsübungen; das Physio-Web zeigt die Schätzung neben der Position, der Physio kann jederzeit eine Dauer eintragen.
- **Liste:** Positionen der aktuellen Phase in Physio-Reihenfolge, so lange aufnehmen, wie die Summe ≤ Zeitwahl (10/20/30) bleibt; ist schon die erste Position länger, wird nur sie gezeigt (mindestens eine Übung). Überschrift „ca. N Min“ aus der Summe.
- **Tauschen** (A-2 AK 2): Kandidaten = übrige Positionen der aktuellen Phase, die heute nicht in der Liste stehen; keine → Tauschen nicht angeboten.
- **Übungsdetail** (A-2 AK 1): Beschreibung, Sätze, Wiederholungen, Dauer (gesetzt oder „ca.“ geschätzt), Belastungshinweis; Katalog-Beispiel gekennzeichnet (O-1).
- „Eigene Übung“ des Patienten entfällt (O-15, Annahme).
- Termine aus `appointments`.
- „Training eintragen“: lokal wie bisher + Warteschlange `training_sessions` mit Momentaufnahme.

### 6.5 Befinden (A-3)
Schmerz 0–10, Schwellung 0–3, Stimmung 1–5 (O-3, Annahme); lokal + Warteschlange; Warnzeichen per Trigger (O-2, Schwellen werden separat abgefragt); fester Hinweis an den Patienten bei Treffer (O-12, Annahme): Die App kennt die Schwellen nicht selbst, sondern liest nach dem Senden, ob ein Warnzeichen entstand (Rückgabe der Insert-Funktion `report_wellbeing` – siehe B-15) – offline erscheint der Hinweis nach dem Senden.

### 6.6 Akte (A-4)
Lesend Behandler, Termine, Krankengeschichte (B-4); eigene Termine anlegen/ändern/löschen; Physio-Einträge nur lesen (RLS, DB-T15). Dokumente später (O-5). „Deine Daten“: Profil wird Leseansicht.

### 6.7 „Alles löschen“ mit Backend (O-9; M-4)
Reihenfolge in der App:
1. Sperre wie bisher (Bedienung gesperrt, Schreibschlange des lokalen Speichers leeren).
2. **`OutboxSender.pauseAndDrain()`**: keine neuen Sendungen starten, **laufende HTTP-Anfragen abwarten** (Zeitlimit; danach gelten sie als unklar, der Server-Lock schützt trotzdem).
3. Merkzeichen `curaone.deletion.v1 = requested`.
4. `delete_my_data()`; `ok` oder `already_deleted` = Erfolg.
5. Lokal: Zustand, Zwischenspeicher, **Warteschlange verwerfen**, Abmelden, zuletzt Merkzeichen.
Fehlerregeln aus KI-Plan v1.2 Abschnitt 9 (sicher nicht gelöscht / unklar / lokaler Fehler). Nach Abbruch läuft der Sender wieder an. Offline: kein „nur lokal löschen“ (**E-24 bleibt Annahme/offen**, N-5).

### 6.8 Ausgangswarteschlange (m-4)
Einträge `{id, kind, payload, createdAt, attempts}`; Arten `training_insert`, `training_delete`, `wellbeing_insert`, `appointment_upsert`, `appointment_delete`; Reihenfolge erhalten; Senden bei Start, Fortsetzen, neuem Eintrag.

Fehlerbehandlung (`backend_errors.dart`):
| Antwort | Behandlung |
|---|---|
| Netz, Zeitüberschreitung, 5xx | später erneut, steigende Wartezeit |
| 401 / abgelaufenes JWT | **erst Sitzung erneuern**, dann erneut; scheitert die Erneuerung, weil das Konto nicht mehr existiert → gelöste Bindung (6.2) |
| `23505` (Schlüssel existiert) | Erfolg (idempotent) |
| `42501` (RLS/Rechte) | **dauerhaft**: Eintrag verwerfen, Bindung prüfen |
| andere 4xx | dauerhaft, Eintrag verwerfen, Debug-Log |

### 6.9 Beispielpfad (O-14, Annahme)
Nur Prüfumgebung und Build-Schalter `--dart-define=CURAONE_DEMO=true`.

### 6.10 Manny ohne KI
Platzhaltertexte bleiben; `MannyContext` aus dem Framework.

---

## 7. Physio-Web: Funktionen und Zustände

| Bereich | Funktionen | Zustände |
|---|---|---|
| Anmeldung | E-Mail, Passwort, Anmelden, Abmelden | leer, Laden, falsche Daten, offline, Sitzung abgelaufen, kein Physio-Konto |
| Patientenliste | **alle** Patienten der Praxis (N-4): Name, Phase, letzte Aktivität, Status, Warnzeichen-Markierung; anlegen | Laden, leer, Fehler, mit Warnzeichen |
| Anlegen + Einladen | Stammdaten; Code, Link, QR; kopieren; neuen Code erzeugen (O-8) mit Hinweis „bisheriges Gerät verliert den Zugang“ | Formular ungültig, Speichern, Fehler, angezeigt, eingelöst, abgelaufen |
| Plan | Phasen anlegen/umbenennen/ordnen/löschen, **geplante Wochen**, aktuelle Phase setzen; Katalog- und eigene Übungen; je Position Sätze, Wdh., Dauer (mit geschätzter Dauer, m-8), Belastungshinweis, Phase; ordnen, entfernen; Speichern | Laden, leer, ungespeichert, Validierungsfehler mit Feldnennung, „aktuelle Phase fehlt“, Speichern, Konflikt, gespeichert |
| Eigene Übung | Name, Beschreibung (Pflicht); bearbeiten; löschen nur ungenutzt (B-13) | wie oben |
| Akte | Behandler, Termine, Krankengeschichte: CRUD; Patienten-Termine lesend | Laden, leer, Fehler, Speichern, Löschen bestätigen |
| Verlauf | je Tag Übungen und Befinden; Warnzeichen mit Grund und Stufe (ab Ausschnitt 3 auch aus dem Chat, ohne Text) | Laden, leer, Fehler, ungesehen/gesehen |
| Manny-Chat | nirgends | – |

Desktop-Viewports 1280×800, 1024×768.

---

## 8. Testdaten-Seed und Reset (T-1)
`dart run tool/seed/seed.dart --target local|remote [--confirm-remote]`; `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` nur aus der Umgebung. Löscht nur `is_test`-Praxen und Test-Konten (`@test.curaone.invalid`), legt Katalog (O-1), 2 Praxen, Physios, Patienten, Pläne mit stabilen IDs, Akte, 14 Tage Verlauf und Befinden, ein Warnzeichen an (O-6, Annahme); gibt Codes nur auf der Konsole aus. Test: zweimal hintereinander → gleicher Endzustand; Kontrollpraxis mit `is_test = false` unverändert (DB-T40, braucht Stack).

---

## 9. Pakete (pub.dev)
`supabase_flutter`, `app_links`, `qr_flutter`; `supabase` (dev, Seed). Versionen beim Hinzufügen bestimmt, Lizenz/Pflege prüft F2-3. Bewusst nicht: State-Management-Pakete, `go_router`, Kamera, `http`.

---

## 10. Teststrategie

### 10.1 Supabase-Rollen-Nachbildung für Tests (M-3)
`supabase/tests/shim/supabase_roles.sql` bildet nach, was die Policies und Funktionen brauchen:
- Rollen `anon`, `authenticated` (beide `NOLOGIN`, ohne `BYPASSRLS`), `service_role` (`NOLOGIN BYPASSRLS`), `authenticator` (`LOGIN NOINHERIT`, darf in die drei wechseln), Eigentümer `postgres`.
- **Standard-Grants wie Supabase:** `GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role`; `GRANT ALL ON ALL TABLES/SEQUENCES/FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role` sowie `ALTER DEFAULT PRIVILEGES` gleichlautend; `EXECUTE` für `PUBLIC` bleibt Postgres-Standard. Damit prüfen die Tests, dass Migration 01 diese Rechte wirklich entzieht.
- Schema `auth` mit `auth.users(id, email, is_anonymous)`, `auth.uid()` und `auth.jwt()` aus `current_setting('request.jwt.claims', true)`.
- Sitzungen im Test: `SET ROLE authenticated; SET request.jwt.claims = '{"sub":"…","role":"authenticated","is_anonymous":true}'` (anonym) bzw. `false` (Physio/gebundener Patient); `SET ROLE anon` ohne `sub`.
- Hinweis: Nachbildung, nicht Supabase. Rollenattribute, GoTrue, PostgREST-Fehlercodes und das Löschen in `auth.users` (B-7) werden in F2-6 gegen den echten Stack bestätigt (X2-8).

### 10.2 Benannte DB-Tests
Jede Sicherheitsaussage dieses Plans hat genau einen Test (Datei `supabase/tests/db/<ID>_<name>.sql`).

| ID | Name | Aussage |
|---|---|---|
| DB-T01 | `defaults_revoked` | `anon` und `authenticated` haben nach den Migrationen keine Tabellenrechte außer den in 4.3 genannten; `EXECUTE` nur auf Funktionen aus 4.4/4.1 |
| DB-T02 | `no_force_rls_definer_sees_rows` | Definer-Funktionen sehen Zeilen (kein `FORCE`); API-Rollen unterliegen RLS |
| DB-T03 | `anon_role_sees_nothing` | Rolle `anon`: jede Tabelle 0 Zeilen bzw. `permission denied`, jede RPC verweigert |
| DB-T04 | `unbound_anonymous_sees_nothing` | anonyme, ungebundene Sitzung: alle Tabellen 0 Zeilen |
| DB-T05 | `unbound_anonymous_rpc_denied` | anonyme, ungebundene Sitzung: jede RPC außer `redeem_invitation`/`delete_my_data` → `42501` (je RPC ein Fall) |
| DB-T06 | `physio_practice_isolation` | Physio Praxis A sieht 0 Zeilen Praxis B in jeder Tabelle (P-1 AK 1) |
| DB-T07 | `physio_sees_all_practice_patients` | Physio sieht alle Patienten seiner Praxis, auch von Kollegen angelegte (N-4) |
| DB-T08 | `patient_sees_only_self` | gebundener Patient sieht nur eigene Zeilen |
| DB-T09 | `invitation_hash_not_readable` | `code_hmac` für keine API-Rolle lesbar; keine Sicht über `invitations` ohne `security_invoker` (M-2) |
| DB-T10 | `invitation_cross_practice` | Physio B liest keine Einladung Praxis A |
| DB-T11 | `redeem_requires_anonymous` | `redeem_invitation` als Physio oder nicht-anonyme Sitzung → `not_allowed` (M-3) |
| DB-T12 | `redeem_already_bound` | bereits gebundene Sitzung → `not_allowed` |
| DB-T13 | `redeem_results` | `ok`, `already_used`, `expired`, `invalid`, widerrufen → `invalid` |
| DB-T14 | `redeem_throttle` | 6. Fehlversuch je Sitzung in 15 Min → `too_many_attempts`; eine **andere** Sitzung ist davon nicht betroffen (keine globale Bremse, N-6) |
| DB-T15 | `patient_cannot_modify_physio_entries` | Patient kann Behandler, Krankengeschichte, Physio-Termine, Plan nicht ändern (A-4) |
| DB-T16 | `created_by_server_side` | gefälschtes `created_by`/`created_by_role` wird überschrieben (m-3) |
| DB-T17 | `own_appointments_only` | Patient ändert/löscht nur eigene Termine; Physio nur eigene |
| DB-T18 | `exercise_requires_name_description` | eigene Übung ohne Name bzw. Beschreibung → Constraint-Fehler (P-3 AK 2) |
| DB-T19 | `exercise_cross_practice` | Physio nutzt keine Übung einer fremden Praxis in `save_plan` |
| DB-T20 | `save_plan_stable_ids` | unveränderte Positionen behalten ID; nur Entferntes gelöscht (M-5) |
| DB-T21 | `save_plan_keeps_history` | Plan speichern (inkl. Löschen einer Phase) lässt `training_sessions` unverändert; `phase_id` → `NULL` (M-5) |
| DB-T22 | `save_plan_current_phase` | aktuelle Phase entfernt ohne Ersatz → `current_phase_required` |
| DB-T23 | `save_plan_version_conflict` | alte Version → `conflict` |
| DB-T24 | `save_plan_cross_practice` | Physio Praxis B speichert Plan Praxis A → `42501` |
| DB-T25 | `warning_only_by_trigger` | `authenticated` kann nicht in `warning_signs` schreiben; Trigger erzeugt Zeile nach Regel |
| DB-T26 | `warning_trigger_definer_search_path` | Trigger-Funktion ist Definer mit `search_path = ''`; Schatten-Objekt im Suchpfad wirkt nicht (m-5) |
| DB-T27 | `wellbeing_append_only` | Patient kann `wellbeing_reports` nicht ändern oder löschen (m-5) |
| DB-T28 | `patient_no_warning_read` | Patient liest keine `warning_signs` (B-5) |
| DB-T29 | `delete_my_data_scope` | löscht Patienten-Daten; Physio-Einträge bleiben; `status = access_deleted`, `auth_user_id = NULL` (O-9) |
| DB-T30 | `delete_my_data_idempotent` | zweiter Aufruf bzw. ungebundene Sitzung → `already_deleted` (m-6) |
| DB-T31 | `race_delete_vs_insert` | Verbindung A hält `delete_my_data` offen, B schreibt Training → B wartet und scheitert mit `42501`; danach keine Patientenzeile in `training_sessions` (M-4; Shell-Test mit zwei Verbindungen) |
| DB-T32 | `auth_user_delete_set_null` | Löschen in `auth.users` setzt `patients.auth_user_id = NULL` (m-6) |
| DB-T33 | `rebind_detaches_old_identity` | `ok_rebound`: alte Identität sieht 0 Zeilen, ihr Auth-Konto ist weg, `account_events.rebound` existiert (N-1) |
| DB-T34 | `rebind_keeps_history` | Plan, Verlauf, Befinden bleiben nach Neubindung sichtbar für die neue Identität (N-1) |
| DB-T35 | `rebind_hook_called` | `app.on_rebind(old_uid)` wird aufgerufen (Ausschnitt 3 löscht dort den Chat; KI-Plan DB-K03) |
| DB-T36 | `inactive_patient_blocked` | Patient mit Status `access_deleted`/`deleting` kann nicht schreiben |
| DB-T37 | `rpc_execute_grants` | jede RPC: kein `EXECUTE` für `PUBLIC`/`anon`; Aufruferprüfung als erste Anweisung (je RPC Fall „falsche Rolle“) |
| DB-T38 | `definer_functions_search_path` | alle Definer-Funktionen haben `search_path = ''` (Katalogabfrage) |
| DB-T39 | `set_current_phase_foreign_phase` | Phase eines anderen Plans → Fehler |
| DB-T40 | `seed_idempotent_only_test_data` | Seed zweimal → gleicher Zustand; Nicht-Test-Praxis unverändert (braucht Supabase-Stack) |
| DB-T41 | `report_wellbeing_scope` | `report_wellbeing`: nur gebundener, aktiver Patient; `patient_id` aus der Sitzung; wiederholte ID idempotent und liefert **dasselbe** `warning_raised` wie der erste Aufruf (NEU-7); Rückgabe enthält nur `warning_raised` |
| DB-T42 | `active_patient_writes_and_undoes` | aktiver Patient (Rolle `authenticated`, ohne UPDATE-Recht auf `patients`) legt Training, Befinden, eigenen Termin an und löscht Training (Rückgängig) und Termin – alles erfolgreich (NEU-1) |
| DB-T43 | `delete_my_data_with_data` | `delete_my_data` mit vorhandenen Trainings, Befinden, Warnzeichen, Terminen, Einwilligungen läuft ohne Fehler durch; danach Zustand wie DB-T29 (NEU-1) |
| DB-T44 | `physio_maintains_record_invited_and_deleted` | Physio legt/ändert/löscht Behandler, Krankengeschichte, Termine für Patienten mit Status `invited` und `access_deleted` (NEU-2) |
| DB-T45 | `seed_writes_without_binding` | `service_role` schreibt Verlauf, Befinden, Termine für ungebundene Patienten (NEU-2; Seed) |
| DB-T46 | `save_plan_foreign_ids` | Payload mit Phasen- bzw. Positions-ID eines anderen Plans → `foreign_id`, nichts geändert (NEU-5) |
| DB-T47 | `redeem_attempts_cleanup` | Einträge älter als 24 h werden beim nächsten Aufruf entfernt (NITPICK) |

DB-T01 bis DB-T39 und DB-T41 bis DB-T47 laufen gegen lokales Postgres 16 mit Nachbildung (hier ausführbar); **DB-T01, DB-T11, DB-T12, DB-T33, DB-T37, DB-T40, DB-T45** zusätzlich gegen den echten Stack in F2-6 (NEU-6: Standardrechte und `EXECUTE`-Grants von Supabase sind nur dort sicher bestätigt).

### 10.3 Übrige Ebenen

| Ebene | Inhalt |
|---|---|
| U | `invite_code` (Normalisierung, Alphabet), `exercise_duration` (alle Zweige), `plan_today` (Füllregel, mindestens eine, Tausch-Kandidaten), `path_from_phases` (6.3), `outbox` (Reihenfolge, Undo, Fehlerklassen 6.8, `pauseAndDrain`), `plan_validation`, Migration 1 → 2 |
| W | Startbildschirm (alle Ergebniscodes inkl. `ok_rebound`), altes Gerät nach Neubindung, Einwilligung (Text wörtlich inkl. N-2), Übungsdetail, Tauschen, Befinden inkl. Hinweis, Akte, Löschen (Sender angehalten vor Backend-Aufruf; sicher/unklar/lokaler Fehler), offline; Physio-Web alle Bereiche aus 7 |
| C | Regeln 1–16 + Grenze Patient/Physio, `supabase_flutter` nur `lib/backend/**`, keine Schlüsselmuster, keine Chat-Begriffe in `lib/physio/**` |
| M, G, S, N | wie v1: neue Szenarien in Matrix, Goldens nach Freigabe, `shoot.mjs` mit zweitem Build, `nav_checks.mjs` mit Abläufen Patient und Physio (Fake-Repositories) |
| E2E | gegen lokalen Supabase-Stack (F2-6, nach X2-8) |

---

## 11. Zuordnung der Akzeptanzkriterien

| AK | Umsetzung | Prüfung |
|---|---|---|
| P-1 AK 1 | 5.1, 7, 4.1 | DB-T06, DB-T07, W, N |
| P-1 AK 2 | 5.1 | W, E2E |
| P-2 AK 1 | `create_patient`, 5.2, 7 | W, S, N |
| P-2 AK 2 | unique `auth_user_id`, `redeem_invitation` | DB-T13, W, N |
| P-3 AK 1 | 7, 4.6 | W, DB-T20 |
| P-3 AK 2 | `plan_validation`, Constraint | U, W, DB-T18 |
| P-3 AK 3 | 6.2 | W, E2E |
| P-4 AK | 7, 4.3 | W, DB-T15 |
| P-5 AK 1 | 7 | W, DB-T08, E2E |
| P-5 AK 2 | Trigger 4.3, O-2, O-11 | DB-T25, W, E2E |
| P-5 AK 3 | kein Chat im Backend (Ausschnitt 2); ab Ausschnitt 3 KI-Plan DB-K01 | C |
| A-1 AK 1 | 5.2, 6.3 | W, N, E2E |
| A-1 AK 2 | 5.2, 6.1 | W, N, DB-T04 |
| A-1 AK 3 | Einwilligung 5.2 (N-2) | W |
| A-2 AK 1 | 6.4 | W, M, S |
| A-2 AK 2 | 6.4 | U, W |
| A-3 AK | 6.5 | U, W, DB-T27, E2E |
| A-4 AK 1 | 6.6 | W, DB-T15, DB-T17 |
| A-4 AK 2 | O-5 später | – |
| T-1 AK | 8 | DB-T40 |

---

## 12. Fragen: Stand

| Nr. | Stand | Inhalt |
|---|---|---|
| O-1 | Annahme | gekennzeichnete Beispieltexte auf Basis der Platzhalter-Übungen |
| O-2 | **[vor F2-1 zu entscheiden]** | Befinden-Regeln als gekennzeichnete Startliste; Schwellen setzt der Nutzer (Diskussionsstand: Schmerz ≥ 7, Anstieg ≥ 3, Schwellung „stark“). Chat-Warnzeichen kommen mit Ausschnitt 3 |
| O-3 | Annahme | Schmerz 0–10, Schwellung 0–3, Stimmung 1–5; täglich angeboten, kein Push |
| O-4 | **entschieden** | 6.3 |
| O-5 | Annahme | später |
| O-6 | Annahme | 2 Praxen, 5 Patienten, je 3 Phasen, 14 Tage Verlauf |
| O-7 | Annahme | 14 Tage, einmalig |
| O-8 | Annahme, präzisiert durch N-1 | neuer Code; Neubindung nach 4.4 |
| O-9 | **entschieden** | 4.7 |
| O-10 | **entschieden** | 6.4 |
| O-11 | Annahme | `seen_at` beim Öffnen der Patientenansicht |
| O-12 | Annahme | fester Hinweis bei Warnzeichen aus Befinden; Wortlaut vom Nutzer (wie KI-Plan E-17) |
| O-13 | **entschieden** | 2 |
| O-14 | Annahme | 6.9 |
| O-15 | Annahme | „Eigene Übung“ des Patienten entfällt |
| O-16 | Annahme | Patienten-App im Browser, Physio-Web lokal; QR nach 5.2 |
| E-24 | **Annahme/offen** (N-5) | Löschen offline: kein „nur lokal“ |

**Entschieden (N-7):** Code-Parameter (4.5), Dauer-Schätzregel (6.4). **Weiter [Vorschlag], nicht blockierend:** QR-Inhalt (5.2), Status „ausgelassen“ (6.3 Regel 6, Gestaltung F2-D). **[vor F2-1 zu entscheiden]:** O-2.

---

## 13. Arbeitspakete

| Paket | Inhalt | Rolle | Abhängigkeit |
|---|---|---|---|
| F2-0 | O-2-Schwellen entscheiden (blockierend vor F2-1) | Nutzer/Orchestrator | – |
| F2-D | Ablauf C: Patienten-Ergänzung (Start, Neuanmeldung-Hinweise beider Geräte, Einwilligung mit N-2, Übungsdetail, Tauschen, Befinden + Hinweis, Akte, Löschen, offline, Pfad mit „ausgelassen“ und Leerzustand) und Physio-Web | `ui-designer` | – |
| F2-1 | Migrationen 01–05, Nachbildung, DB-T01 bis DB-T39 | `flutter-developer` | F2-0 |
| F2-1R | Sicherheitsreview Rollen, RLS, Definer, Einladung, Löschen, Neubindung | `reviewer` | F2-1 |
| F2-2 | Seed + Testdaten | `flutter-developer` | F2-1 |
| F2-3 | Datenschicht App, Logik, Warteschlange, Migration, `AccountDeleter`; U/C | `flutter-developer` | F2-1 |
| F2-4a/b | Physio-Web I (Anmeldung, Liste, Anlegen/Einladen) / II (Plan, Akte, Verlauf) | `flutter-developer` | F2-D, F2-3 |
| F2-5a/b/c | Patienten-App I (Start, Neubindung, Einwilligung, Löschen, Demo) / II (Pfad, Heute) / III (Befinden, Akte) | `flutter-developer` | F2-D, F2-3 |
| F2-6 | E2E gegen lokalen Supabase-Stack, DB-T01/11/12/33/37/40/45 dort, Kriterienbericht | `flutter-developer` | alle, X2-8 |
| F2-R | Gesamtreview + Design-Abnahme | `reviewer`, `ui-designer` | F2-6 |

Reihenfolge wie v1: F2-0 → (F2-D ∥ F2-1 → F2-1R → F2-2/F2-3) → F2-4a → F2-4b → F2-5a → F2-5b → F2-5c → F2-6 → F2-R; Physio- und Patienten-Pakete nacheinander (gemeinsame Dateien).

---

## 14. Externe Schritte (nur benannt; jeweils einzeln zur Freigabe)

| Nr. | Schritt | Zweck | Risiko |
|---|---|---|---|
| X2-1 | Supabase-Projekt in EU-Region anlegen | Backend | Kosten; Pausieren im kostenlosen Tarif |
| X2-2 | Auth: E-Mail/Passwort an, Registrierung aus, anonyme Anmeldung an, Ratenbegrenzung prüfen, optional Captcha | Zugang | offene Registrierung bei Fehlkonfiguration |
| X2-3 | `supabase link --project-ref <ref>`, `supabase db push` – nach DB-Tests und F2-1R | Schema live | offene Daten bei Fehlern |
| X2-4 | Seed remote (`… --target remote --confirm-remote`, Schlüssel nur in der Shell) | Testdaten | löscht Testdaten |
| X2-5 | `app/config/supabase.local.json` füllen | Konfiguration | – |
| X2-6 | Hosting Physio-/Patienten-Web (nur auf Wunsch) | Präsentation | weiterer Anbieter |
| X2-7 | Domain + App-Links (nur bei https-Links) | Deep Links | Domain nötig |
| X2-8 | **Werkzeuginstallation** in der Entwicklungsumgebung: Supabase-CLI, Docker-Daemon starten | lokaler Stack, E2E, DB-T40 | Installation in der Umgebung |
| X2-9 | Android-/iOS-Build beim Nutzer (nur bei Gerät) | Präsentation | Signatur |
| X2-10 | AV-Vertrag, Datenschutz-Konzept | echte Daten | nicht nötig bei Testdaten |
| X2-11 | Pepper für die Code-HMAC im Projekt setzen (`app.secrets`, per SQL-Konsole oder Supabase Vault; nie im Repo) | Code-Speicherung | Verlust → offene Codes ungültig, neu erzeugen |

Befehle vor Ausführung gegen die aktuelle Supabase-Doku prüfen.

**Vom Nutzer einzutragende Werte (ohne Werte):** `SUPABASE_URL`, öffentlicher Client-Schlüssel, `SUPABASE_SERVICE_ROLE_KEY` (nur Shell), Projekt-Referenz, `CURAONE_SEED_PASSWORD` (optional), `INVITE_LINK_BASE`, Pepper (X2-11).

---

## 15. Risiken

| Nr. | Risiko | Umgang |
|---|---|---|
| R2-1 | RLS-/Rechtefehler | Rollenmodell 4.1, DB-T01 bis DB-T39, F2-1R vor X2-3 |
| R2-2 | Nachbildung ≠ Supabase | 10.1; Bestätigung in F2-6 |
| R2-3 | Massenhaft anonyme Konten | ohne Rechte; Bremsen 4.5; Captcha optional |
| R2-4 | Umfang | kleine Pakete |
| R2-5 | Gestaltung blockiert UI | F2-D früh |
| R2-6 | Warteschlange: doppelt/verloren | Geräte-IDs, Fehlerklassen 6.8, Tests |
| R2-7 | Flutter Web als Formular-Oberfläche | für Präsentation vertretbar |
| R2-8 | Präsentation offline | Demo-Modus, Zwischenspeicher |
| R2-9 | Pausiertes Projekt | vor Termin prüfen |
| R2-10 | Parallelarbeit unter `app/` | Start erst danach |
| R2-11 | Katalog wirkt geprüft | Kennzeichnung |
| R2-12 | `auth.users` aus Definer-Funktion nicht löschbar | B-7 in F2-6; Ausweg Edge Function |
| R2-13 | Physio löst selbst einen neuen Code ein und wird „Patient“ | sieht danach nur Plan/Verlauf (sieht er ohnehin); Chat der alten Identität wird gelöscht (N-1), der Patient bemerkt den Zugangsverlust; Ereignis `account_events` |
| R2-14 | Durchprobieren von Codes über viele anonyme Sitzungen | keine globale Bremse (N-6); Schutz durch 50 Bit Entropie, Bremse je Sitzung, Ratenbegrenzung anonymer Anmeldungen und optional Captcha (X2-2) |
| R2-15 | Wartende Schreibvorgänge beim Löschen (Sperre) verlängern Antwortzeiten | Transaktionen kurz; Zeitlimit in der App |

---

## 16. Annahmen

| Nr. | Annahme |
|---|---|
| B-1 | keine KI, keine Edge Functions in Ausschnitt 2 |
| B-2 | Physio-Web Deutsch, Desktop |
| B-3 | „Woche N“ aus `reference_date` |
| B-4 | Patient liest Krankengeschichte |
| B-5 | Patient sieht `warning_signs` nicht |
| B-7 | `delete_my_data()` darf `auth.users` des Aufrufers löschen |
| B-8 | Link füllt Feld, Einlösen nach Bestätigung |
| B-9 | lokaler Fortschritt startet nach dem Einlösen neu |
| B-10 | entfallene Positions-IDs verwerfen Tagesänderungen, `done` bleibt |
| B-11 | gelöste Bindung → lokale Daten weg, Startbildschirm |
| B-12 | Schreiben über Warteschlange |
| B-13 | eigene Übungen je Praxis wiederverwendbar |
| B-14 | Streak und Pfad-Fortschritt lokal |
| B-15 | Befinden wird über die RPC `report_wellbeing` statt direktem Insert gesendet, damit die App erfährt, ob ein Warnzeichen entstand (für O-12), ohne `warning_signs` lesen zu dürfen (DB-T41, DB-T27, DB-T31, DB-T36) |

(B-6 aus v1 ist durch 4.5 ersetzt.)

---

## 17. Vorschläge für `KONVENTIONEN.md` (nur auf Nutzerwunsch)
1. Physio-Texte in `strings_physio_de.dart`.
2. `supabase_flutter` nur unter `lib/backend/**` und `main*.dart`.
3. Importgrenze `lib/physio/**` ↔ `lib/ui/**`.
4. Jede Tabelle mit RLS; jede Sicherheitsaussage mit benanntem DB-Test; Definer-Funktionen mit `search_path = ''` und eigener Rechteprüfung.
5. Keine Schlüssel in Dateien.

---

## 18. Änderungsprotokoll v1 → v1.1 (Review R-P2, Nutzerentscheidungen 2026-10-12)

| Befund / Entscheidung | Abschnitt |
|---|---|
| M-1 FORCE RLS / Definer-Eigentümer | 4.1 (1, 4, 5); DB-T02, DB-T38 |
| M-2 Sicht über `invitations`, Default-Grants, `EXECUTE PUBLIC` | 4.1 (2, 3), 4.3 (`invitations`), 4.4; DB-T01, DB-T05, DB-T09, DB-T37 |
| M-3 anonyme Sitzung = `authenticated` + `is_anonymous`; Shim; `redeem_invitation` Aufruferprüfung | 4.1, 4.4, 10.1; DB-T11, DB-T12 |
| M-4 Wettrennen Löschen/Warteschlange | 4.3 (Trigger `lock_patient_for_write`), 4.7, 6.7 (`pauseAndDrain`); DB-T31, DB-T36 |
| M-5 `save_plan` IDs/Fremdschlüssel | 4.3 (FK-Verhalten), 4.6; DB-T20 bis DB-T23 |
| M-6 Neubindung lässt Physio den Chat lesen | 4.4 (`redeem_invitation` Neubindung, `app.on_rebind`), 5.2, R2-13; DB-T33 bis DB-T35; KI-Plan v2.1 4.4 |
| m-1 Stand Entscheidungen 2026-10-12 | 0, 12 |
| m-2 Code, Entropie, Bremsen, HMAC | 4.5, X2-11; DB-T14 |
| m-3 `created_by` serverseitig | 4.3 (Trigger); DB-T16 |
| m-4 Warteschlange 401/42501 | 6.8 |
| m-5 Trigger Definer, `search_path`, Befinden unveränderlich | 4.3; DB-T26, DB-T27 |
| m-6 `auth_user_id` `SET NULL`, Idempotenz | 4.3, 4.7; DB-T30, DB-T32 |
| m-7 Pfadregel vollständig | 6.3 |
| m-8 Dauer-Schätzregel | 6.4, 7 |
| m-9 QR-Inhalt | 5.2 |
| K-m3 Status `deleting` | 4.3, 4.7 |
| K-m6 Werkzeuginstallation | X2-8 |
| N-1 Neubindung | 0, 4.4, 5.2; DB-T33 bis DB-T35 |
| N-2 Chat-Warnzeichen inkl. Krise an Physio, Einwilligung | 0, 5.2, 7 |
| N-3 Ersatzprogramm bei Schmerz | 0; KI-Plan v2.1 4.2 |
| N-4 alle Patienten der Praxis | 0, 5.1, 7; DB-T07 |
| N-5 Werte vorgeschlagen, E-24 offen | 4.5, 6.4, 5.2, 6.7, 12 |
| O-4, O-9, O-10, O-13 entschieden | 0, 6.3, 4.7, 6.4, 2 |
| Neu | B-15, R2-13 bis R2-15, X2-11, Tabellen `redeem_attempts`, `account_events` |

### Änderungsprotokoll v1.1 → v1.2 (Re-Review R-P2-RR, Nutzerentscheidungen Runde 2)

| Befund / Entscheidung | Abschnitt |
|---|---|
| NEU-1 Lock-Trigger Definer, `OLD` bei DELETE | 4.3 (Trigger), 4.7 (Reihenfolge); DB-T42, DB-T43 |
| NEU-2 Sperre nur für Patienten-Schreibvorgänge; Physio und Seed pflegen Akte | 4.3, 4.7 Punkt 4; DB-T44, DB-T45 |
| NEU-3 Warnzeichen und Chat-Tabellen in der Sperre | 4.3; KI-Plan v2.2, 8 (DB-K10 mit zwei Verbindungen) |
| NEU-4 Freitextprüfung | KI-Plan v2.2, 4.7 |
| NEU-5 fremde IDs in `save_plan` | 4.6 Punkt 4; DB-T46 |
| NEU-6 DB-T01/T37 gegen echten Stack | 10.2 (Absatz unter der Tabelle), 13 F2-6 |
| NEU-7 `warning_raised` bei Wiederholung | 4.4 `report_wellbeing`; DB-T41 |
| NEU-8 Kürzungsregel ohne Sätze, S8b bei Schmerz | KI-Plan v2.2, 4.2.1 Regel 7, 4.2.3 |
| NITPICK K-1 zu stark | 6.3 Regel 3 |
| NITPICK `redeem_attempts` Bereinigung | 4.3; DB-T47 |
| NITPICK `invitations` `select=*` | 4.3 |
| NITPICK E-25 | KI-Plan v2.2, 13 |
| N-6 keine globale Bremse | 0, 1, 4.5, R2-14; DB-T14 |
| N-7 Werte bestätigt | 0, 4.5, 6.4, 12 |
| N-8 Freigabe, Prüfung in F2-1R | Status, 0 |
| Blockierende offene Werte markiert | 0, 12, 13 F2-0 |
