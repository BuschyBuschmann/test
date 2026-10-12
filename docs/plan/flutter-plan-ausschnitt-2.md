# Flutter-Plan Ausschnitt 2 „Fundament“: Patienten-Framework mit Physio-Zugang (ohne KI)

Status: **PLAN ZUR FREIGABE** · v1 · Paket P2 · Autor: `flutter-developer` · Stand 2026-10-11

Verbindliche Grundlagen:
- `docs/produkt/curaone-spezifikation-manny-gehirn.md` (FREIGEGEBEN 2026-10-11), Abschnitt 4 (P-1 bis P-5, A-1 bis A-4, T-1), Abschnitt 7 (Folgen für Ausschnitt 1), Abschnitt 8 (nicht enthalten), Abschnitt 10 (O-1 bis O-7).
- Nutzerentscheidung: **Backend Supabase in der EU** (Spec 3, Punkt 13; KI-Plan E-13).
- `KONVENTIONEN.md` (Regeln 1–5), `docs/plan/flutter-plan-v1.md` v1.3 (Architektur, Prüf-Infrastruktur 12), KI-Plan v1.2 Abschnitt 9 (Löschkonzept).

Kontext (gelesen, nicht zur Anforderung umgedeutet): `docs/UEBERGABE.md`, `docs/produkt/curaone-app-pruefung.md`, Code unter `app/lib` (nur lesend).

Kennzeichnung: **B-n** = Annahme dieses Plans, **O-n** = offene Frage (O-1 bis O-7 aus der Spec, ab O-8 neu aus diesem Plan), **R2-n** = Risiko, **X2-n** = externer Schritt, **F2-n** = Arbeitspaket. Alles ist ein **Vorschlag**; Produkt- und Gestaltungsentscheidungen trifft der Nutzer. Gestaltung (Layouts, Texte im Wortlaut, Farben) kommt über Ablauf C vom `ui-designer`; dieser Plan nennt nur **Funktionen und Zustände**.

Hinweis zur Parallelarbeit: Während dieser Plan entsteht, arbeitet ein anderer Agent unter `app/`. Die Umsetzungspakete F2-3 ff. beginnen erst, wenn dieser Schreibbereich frei ist. Der Plan verweist auf den Code-Stand von HEAD `5a493ed`.

---

## 1. Kurzfassung

| Thema | Vorschlag |
|---|---|
| Backend | Supabase-Projekt in EU-Region (z. B. Frankfurt): Postgres mit Row-Level-Security, Supabase Auth. **Keine Edge Functions in Ausschnitt 2** (alles über Tabellen, RLS und wenige `SECURITY DEFINER`-Funktionen). Storage nur, falls O-5 = „jetzt“ |
| Datenmodell | 16 Tabellen (Abschnitt 4), alle mit RLS, Grundsatz „verweigern“. Praxis trennt Physios; Patient sieht nur sich selbst; Physio sieht nur Patienten der eigenen Praxis; der Manny-Chat existiert in Ausschnitt 2 noch nicht im Backend |
| Auth Physio | E-Mail + Passwort, **keine Selbstregistrierung**; Test-Physios legt der Seed an |
| Auth Patient | Anonyme Supabase-Sitzung **ohne Rechte**, bis sie per `redeem_invitation(code)` an genau einen Patienten gebunden ist. Code einmalig, gehasht gespeichert, mit Ablauf (O-7) und Versuchsbremse |
| Physio-Web | **Zweiter Einstiegspunkt im selben Flutter-Projekt** (`lib/main_physio.dart`, Code unter `lib/physio/`), nur als Web gebaut. Gemeinsame Modelle, Datenschicht, Tokens und Prüf-Infrastruktur (O-13) |
| Patienten-App | Start mit Code → Einwilligung → Pfad aus Physio-Phasen; „Heute“ aus dem Plan mit Übungsdetail und Tauschen nur innerhalb der Phase; Befinden melden; Akte (Behandler, Termine, Krankengeschichte); „Alles löschen“ inklusive Backend (KI-Plan v1.2 Abschnitt 9, vorgezogen) |
| Offline | Lesen aus lokalem Zwischenspeicher (letzter Plan). Schreiben (Training, Befinden, eigene Termine) lokal zuerst, dann über eine persistente **Ausgangswarteschlange** mit idempotenten IDs |
| Beispielpfad | Bleibt nur in der Prüfumgebung und als Präsentations-Rückfall per Build-Schalter, nicht in der normalen App (O-14) |
| Testdaten | `dart run tool/seed/seed.dart` legt Testpraxen, Physios, Patienten, Pläne, Akte und Verlauf an bzw. setzt sie zurück; nur für als Test markierte Daten |
| Neue Pakete | `supabase_flutter` (App und Physio-Web), `app_links` (Einladungslink öffnen), `qr_flutter` (QR im Physio-Web), `supabase` (Seed-Skript, dev) |
| Verifikation | Bestehende Kette (`analyze`, Unit/Widget, Matrix, Goldens, `shoot.mjs`, `nav_checks.mjs`) mit gefälschten Repositories; **RLS-Tests** als SQL gegen ein lokales Postgres 16 mit Auth-Nachbildung (Supabase-CLI und Docker-Daemon fehlen hier); Ende-zu-Ende gegen lokalen Supabase-Stack, sobald verfügbar |
| Pakete | F2-0 Entscheidungen, F2-D Gestaltung (Ablauf C), F2-1 Schema+RLS, F2-2 Seed, F2-3 Datenschicht, F2-4a/b Physio-Web, F2-5a/b/c Patienten-App, F2-6 Integration, Reviews (Abschnitt 13) |

---

## 2. Physio-Web-Zugang: Technikvorschlag (O-13)

| Variante | Beschreibung | Vorteile | Nachteile |
|---|---|---|---|
| **W-A (Empfehlung): zweiter Einstiegspunkt im selben Flutter-Projekt** | `app/lib/main_physio.dart`, Code unter `app/lib/physio/`, Build `flutter build web -t lib/main_physio.dart -o build/physio_web` | eine Sprache; gemeinsame reine Logik (`lib/logic/`), Datenmodelle, Repositories und Validierung (z. B. „eigene Übung braucht Name und Beschreibung“ an genau einer Stelle); gemeinsame Tokens; vorhandene Prüfketten (Matrix, statische Regeln, `shoot.mjs`, `nav_checks.mjs`) sofort nutzbar; Dart-Tree-Shaking hält den Physio-Code aus dem Patienten-Build heraus (anderer Einstiegspunkt) | Patienten- und Physio-Code teilen ein Paket → Grenze per statischer Regel nötig; Flutter Web lädt CanvasKit (große erste Ladezeit, für eine Präsentation unkritisch); Formulare und Tabellen in Flutter Web sind weniger „webtypisch“ (Textauswahl, Browser-Autofill nur eingeschränkt) |
| W-B: eigenes Flutter-Projekt `physio_web/` + gemeinsames Dart-Paket `packages/cura_core/` | saubere Trennung | wie W-A, plus klare Paketgrenze | Umbau von `app/` (Logik und Modelle in ein Paket verschieben) **während** dort parallel gearbeitet wird; doppelte Prüf-Infrastruktur; mehr Aufwand ohne Nutzen für den Prototyp |
| W-C: eigene Web-Anwendung (z. B. TypeScript/React) | webtypisch | zweite Sprache und Toolchain, doppelte Modelle/Validierung, nicht im Zuständigkeitsbereich `flutter-developer`, eigene Prüfketten |

**Empfehlung W-A.** Spätere Auslagerung nach W-B bleibt möglich, weil die Grenze von Anfang an per Regel erzwungen wird:
- `lib/physio/**` importiert nichts aus `lib/ui/**` außer `lib/ui/components/**` (falls der Brief Bausteine teilt), `lib/ui/**` importiert nichts aus `lib/physio/**`.
- `package:supabase_flutter` nur unter `lib/backend/**` und in den beiden `main*.dart`.
- Physio-Texte in eigener Datei `lib/l10n/strings_physio_de.dart` (Konvention 4 sinngemäß; Vorschlag für `KONVENTIONEN.md`, Abschnitt 16), damit Patienten- und Physio-Pakete nicht dieselbe Textdatei bearbeiten.

**Bereitstellung für die Präsentation:** lokal (`flutter build web …` + statischer Server wie heute in der Prüfumgebung) oder gehostet. Hosting wäre ein weiterer Anbieter bzw. ein externer Schritt (O-16, X2-6).

---

## 3. Projekt- und Ordnerstruktur (Erweiterung von Flutter-Plan v1.3 Abschnitt 3)

```
supabase/                                  # Repo-Stamm, Layout der Supabase-CLI
  config.toml                              # lokaler Stack (Auth: anonyme Anmeldung an, Registrierung aus); ohne Secrets
  migrations/
    <ts>_01_grundschema.sql                # Tabellen, Typen, Constraints
    <ts>_02_rls.sql                        # RLS an, Hilfsfunktionen, Policies, Grants
    <ts>_03_funktionen.sql                 # RPCs (Einladung, Plan speichern, Löschen)
    <ts>_04_warnzeichen.sql                # Regeltabelle + Trigger auf Befinden (O-2)
  tests/
    auth_shim.sql                          # NUR für Tests ohne Supabase-Stack: Schema auth, auth.uid(), Rollen
    rls/*.sql                              # RLS- und Funktionstests (Assertions in DO-Blöcken)
    run_local_pg.sh                        # initdb in Temp-Verzeichnis, Shim + Migrationen + Tests, Abbau
app/
  config/
    supabase.example.json                  # Platzhalter: SUPABASE_URL, SUPABASE_ANON_KEY, INVITE_LINK_BASE
    supabase.local.json                    # NICHT eingecheckt (.gitignore); per --dart-define-from-file
  lib/
    main.dart                              # Patienten-App: + Supabase-Init, Deep-Link-Empfang
    main_physio.dart                       # NEU: Physio-Web
    main_preview.dart                      # Prüfumgebung Patient: gefälschte Repositories, kein Netz
    main_physio_preview.dart               # NEU: Prüfumgebung Physio-Web, gefälschte Repositories
    logic/                                 # rein Dart (Konvention 3)
      framework.dart                       # NEU: Patient, Plan, Phase, PlanItem, Exercise, Treater, Appointment, HistoryEntry
      wellbeing.dart                       # NEU: Befindensmeldung, Skalen (O-3)
      invite_code.dart                     # NEU: Format, Normalisierung (Groß/Klein, Leerzeichen, Bindestriche)
      plan_today.dart                      # NEU: Heute aus Plan + Zeitwahl (O-10), Tausch-Kandidaten
      path_from_phases.dart                # NEU: Pfad aus Physio-Phasen (O-4); path_generator.dart bleibt für den Beispielpfad
      outbox.dart                          # NEU: Ausgangswarteschlange (Einträge, Zusammenfassen, Undo)
      plan_validation.dart                 # NEU: Pflichtfelder eigener Übung, Grenzenbereiche (Physio-Web und Tests)
    data/
      framework_repository.dart            # NEU: Schnittstellen (lesen/schreiben), keine Supabase-Typen
      framework_cache.dart                 # NEU: letzter Stand lokal (Schlüssel curaone.framework.v1)
      outbox_store.dart                    # NEU: Schlüssel curaone.outbox.v1
      account_deleter.dart                 # NEU: Backend-Löschung vor den lokalen Löschern (KI-Plan v1.2, 9)
    backend/                               # NEU: einzige Stelle mit supabase_flutter
      supabase_config.dart                 # liest --dart-define, Fehlerzustand bei fehlender Konfiguration
      supabase_patient_repository.dart
      supabase_physio_repository.dart
      outbox_sender.dart                   # sendet Warteschlange bei Start/Resume/Verbindung
    ui/
      start/                               # + Code-Eingabe, Einladungslink, „Zugang über deinen Physio“
      onboarding/                          # Einwilligung neu (A-1), Name/Verletzung/Datum entfallen im Einladungsweg
      today/exercise_detail_sheet.dart     # NEU (A-2)
      wellbeing/                           # NEU (A-3)
      record/                              # NEU Akte (A-4)
    physio/                                # NEU Physio-Web (P-1 … P-5)
      physio_app.dart, login/, patients/, invite/, plan_editor/, record/, history/
    l10n/strings_physio_de.dart            # NEU (Vorschlag, siehe 2)
    dev/                                   # + Fake-Repositories, neue Szenarien (Patient und Physio)
  tool/
    seed/seed.dart                         # NEU T-1
    seed/testdaten.json                    # NEU: Umfang nach O-6, Katalog nach O-1
    screens/                               # shoot.mjs, nav_checks.mjs: + Physio-Szenarien und Abläufe
```

`.gitignore` (Repo-Stamm bzw. `app/`) ergänzt um `app/config/supabase.local.json`, `supabase/.temp/`, `supabase/.branches/`, `.env*`.

---

## 4. Datenmodell (Postgres, Schema `public`)

Grundsätze:
- Alle Tabellen `ENABLE ROW LEVEL SECURITY` und `FORCE ROW LEVEL SECURITY`; Rolle `anon` erhält **keine** Rechte auf Tabellen; `authenticated` nur die per Policy freigegebenen Operationen. Ohne passende Policy: kein Zugriff.
- Primärschlüssel `uuid`. Schreibvorgänge der App, die über die Warteschlange laufen, erzeugen die ID **auf dem Gerät** (idempotentes `insert … on conflict (id) do nothing`).
- `created_at`/`updated_at` als `timestamptz`; Kalendertage als `date` (vom Gerät in Ortszeit berechnet, wie `LocalDay`).
- Test-Kennzeichen `is_test` an `practices`; Seed und Reset berühren **nur** Daten unter `is_test = true`.

| Tabelle | Wichtige Spalten | Schreibt | Liest |
|---|---|---|---|
| `practices` | `id`, `name`, `is_test` | Seed | eigene Physios |
| `physios` | `id` = `auth.users.id`, `practice_id`, `display_name` | Seed | Physios derselben Praxis |
| `patients` | `id`, `practice_id`, `first_name`, `last_name`, `injury_label`, `reference_date` (Verletzungs- oder OP-Datum für „Woche N“, B-3), `auth_user_id` (unique, null bis Einlösung), `status` (`invited` · `active` · `access_deleted`), `current_phase_id` | Physio (Stammdaten), Funktionen (Bindung, Status) | Physio der Praxis; Patient nur die eigene Zeile |
| `invitations` | `id`, `patient_id`, `code_hash` (SHA-256 eines Codes mit hoher Entropie), `expires_at` (O-7), `redeemed_at`, `revoked_at`, `failed_attempts` | nur Funktionen | Physio der Praxis (ohne Hash, über View) |
| `exercises` | `id`, `practice_id` (null = CuraOne-Katalog), `name` (Pflicht), `description` (Pflicht), `is_example` (O-1), `created_by` | Seed (Katalog), Physio (eigene der Praxis) | Physio: Katalog + eigene Praxis; Patient: nur Übungen im eigenen Plan |
| `plans` | `id`, `patient_id` (unique), `version` (int, für Konfliktprüfung), `updated_at`, `updated_by` | Funktion `save_plan` | Physio der Praxis, Patient (eigener) |
| `phases` | `id`, `plan_id`, `position`, `title`, `planned_weeks` (nur bei O-4 Variante A) | `save_plan` | wie `plans` |
| `plan_items` (Freigabe mit Grenzen) | `id`, `plan_id`, `phase_id`, `exercise_id`, `position`, `sets`, `reps`, `duration_min`, `load_note` (Belastungshinweis) | `save_plan` | wie `plans` |
| `treaters` (Behandler) | `id`, `patient_id`, `role` (`physio` · `arzt` · `sonstige`), `name`, `phone`, `email`, `address`, `note` | Physio | Physio der Praxis, Patient |
| `appointments` (Termine) | `id`, `patient_id`, `treater_id` (optional), `starts_at`, `title`, `location`, `created_by_role` (`physio` · `patient`), `created_by` | Physio (eigene Einträge), Patient (eigene Einträge) | beide; Ändern/Löschen nur, wer angelegt hat (A-4) |
| `history_entries` (Krankengeschichte) | `id`, `patient_id`, `kind` (`injury` · `surgery` · `past_therapy` · `current_treatment` · `treatment_option`), `title`, `occurred_on` (optional), `note` | Physio | Physio der Praxis, Patient (lesend, B-4) |
| `training_sessions` (Verlauf) | `id` (Gerät), `patient_id`, `local_day`, `logged_at`, `phase_id`, `plan_version`, `items` (`jsonb`: Momentaufnahme `plan_item_id`, Name, Sätze, Wdh., Dauer, `custom`) | Patient (Warteschlange) | Patient, Physio der Praxis |
| `wellbeing_reports` (Befinden) | `id` (Gerät), `patient_id`, `local_day`, `reported_at`, `pain`, `swelling`, `mood` (Skalen O-3, als `CHECK`) | Patient (Warteschlange) | Patient, Physio der Praxis |
| `warning_rules` | `id`, `version`, `rule` (`jsonb`: Feld, Vergleich, Schwelle), `active`, `is_provisional` | Migration/Seed | nur Funktionen |
| `warning_signs` (Warnzeichen) | `id`, `patient_id`, `created_at`, `source` (`wellbeing`; ab Ausschnitt 3 `chat`), `level`, `reason_code`, `wellbeing_report_id`, `seen_at` (O-11) | Trigger (nicht der Client) | Physio der Praxis; Patient nicht (B-5) |
| `consents` | `id`, `patient_id`, `kind` (`physio_sharing`), `version`, `accepted_at`, `revoked_at` | Patient (über Funktion beim Einlösen bzw. danach) | Patient, Physio der Praxis (nur ob/wann) |
| `documents` + Storage-Bucket | nur wenn O-5 = „Ausschnitt 2“ | Patient | Patient, Physio der Praxis |

**Nicht im Backend in Ausschnitt 2:** Streak, Freezes, Manny-Anlässe, Feier, Tagesänderungen (bleiben im lokalen `AppState` wie bisher, O-4), Manny-Chat (Ausschnitt 3, KI-Plan v2).

**Constraints, die die Akzeptanzkriterien stützen:**
- `exercises`: `CHECK (length(trim(name)) > 0 AND length(trim(description)) > 0)` (P-3 AK 2, zweite Sicherung neben der Formularprüfung).
- `plan_items.phase_id` gehört zum selben `plan_id` (zusammengesetzter Fremdschlüssel).
- `plan_items.exercise_id` ist Katalog oder Übung derselben Praxis (Prüfung in `save_plan`).
- `invitations`: höchstens eine nicht eingelöste, nicht widerrufene Einladung je Patient (partieller Unique-Index).
- `patients.auth_user_id` unique → „ein Code, genau ein Patient“ (P-2 AK 2).

### 4.1 RLS-Hilfsfunktionen und Policies

Hilfsfunktionen (`SECURITY DEFINER`, `STABLE`, `SET search_path = ''`, Eigentümer ohne Login):
- `app.current_physio_practice()` → `practice_id` des angemeldeten Physios oder `null`.
- `app.current_patient_id()` → `patients.id` mit `auth_user_id = auth.uid()` und `status = 'active'` oder `null`.
- `app.physio_can_see_patient(p uuid)` → Patient gehört zur Praxis des Physios.

Policies (Muster, je Tabelle ausformuliert in `<ts>_02_rls.sql`):
- **Physio:** `using (app.physio_can_see_patient(patient_id))` für Lesen; Schreiben nur auf den Tabellen aus der Spalte „Schreibt“.
- **Patient:** `using (patient_id = app.current_patient_id())`; Insert nur mit `with check (patient_id = app.current_patient_id())`; bei `appointments` Update/Delete zusätzlich `created_by = auth.uid()`.
- **Anonyme, nicht gebundene Sitzung:** `app.current_patient_id()` ist `null` → keine Zeile sichtbar, kein Schreiben möglich; einziger erlaubter Aufruf ist `redeem_invitation`.
- Physio-Policies verwenden nie `auth.uid()` eines Patienten; Patienten-Policies nie die Praxis. Spalten, die der Patient nicht sehen soll, liegen nicht in seiner Zeile (Warnzeichen getrennt, Einladungs-Hash nie lesbar).

### 4.2 Funktionen (RPC, `SECURITY DEFINER`, Eingaben geprüft)

| Funktion | Aufrufer | Wirkung |
|---|---|---|
| `create_patient(first_name, last_name, injury_label, reference_date)` | Physio | legt Patient in der eigenen Praxis an, erzeugt Einladung; **liefert Klartext-Code einmalig** zurück (gespeichert wird nur der Hash) |
| `regenerate_invitation(patient_id)` | Physio | widerruft offene Einladung, erzeugt neue (nur bei O-8 = ja; sonst entfällt) |
| `redeem_invitation(code)` | anonyme Sitzung | normalisiert Code, prüft Hash, Ablauf, Widerruf, „bereits eingelöst“; bindet `auth.uid()` an den Patienten, setzt `status = 'active'`. Ergebnis als Code: `ok` · `invalid` · `already_used` · `expired` · `too_many_attempts`. Versuchsbremse je Sitzung und je Code (B-6) |
| `accept_consent(kind, version)` | Patient | speichert Einwilligung (A-1) |
| `save_plan(patient_id, expected_version, plan jsonb)` | Physio | ersetzt Phasen und Positionen **atomar**, prüft Pflichtfelder, Wertebereiche und Praxiszugehörigkeit; bei abweichender Version Fehler `conflict` (zwei Physios gleichzeitig); erhöht `version` |
| `set_current_phase(patient_id, phase_id)` | Physio | aktuelle Phase setzen (O-4) |
| `mark_warnings_seen(patient_id)` | Physio | setzt `seen_at` (O-11) |
| `delete_my_data()` | Patient | löscht die vom Patienten erzeugten Daten (Umfang O-9), löst die Bindung, setzt `status = 'access_deleted'`, löscht das anonyme Auth-Konto (B-7). Idempotent |

Warnzeichen entstehen **serverseitig** per Trigger `after insert on wellbeing_reports` anhand aktiver `warning_rules` (O-2). Der Client kann keine Warnzeichen anlegen oder unterdrücken.

---

## 5. Auth und Zugang

### 5.1 Physio (P-1)
- Supabase Auth mit E-Mail und Passwort. Öffentliche Registrierung **aus**; Konten entstehen nur über den Seed (Admin-Schnittstelle mit Service-Schlüssel, lokal) bzw. später über einen eigenen Ablauf.
- Zustände Web: Anmelden (Laden), falsche Zugangsdaten (verständliche Meldung, kein Zugang; P-1 AK 2), keine Verbindung, Sitzung abgelaufen → zurück zur Anmeldung, Konto ohne `physios`-Zeile → „Kein Physio-Zugang“ und Abmelden.
- Abmelden jederzeit.

### 5.2 Patient (A-1)
Ablauf:
1. Start ohne Bindung → Startbildschirm „Zugang über deinen Physio“ mit Code-Feld (A-1 AK 2). Kein anderer Weg in die App (Ausnahme: Präsentationsmodus O-14).
2. „Weiter“: anonyme Anmeldung (falls noch keine Sitzung), dann `redeem_invitation(code)`.
3. Ergebnis `ok` → Einwilligung (A-1 AK 3: Physio sieht Verlauf, Befinden und Warnzeichen, nicht den Manny-Chat; Wortlaut über den `ui-designer`/Nutzer) → `accept_consent` → Pfad mit dem Plan des Physios (A-1 AK 1).
4. Fehler: `invalid`, `already_used` (P-2 AK 2: „mit Hinweis abgelehnt“), `expired`, `too_many_attempts`, keine Verbindung, Server nicht konfiguriert. Je Fall ein eigener Text (Gestaltung F2-D).

**Einladungslink und QR (P-2 AK 1):**
- Mobil: eigenes URL-Schema `curaone://einladung?code=<CODE>` (keine eigene Domain nötig). Paket `app_links` empfängt den Link beim Kaltstart und bei laufender App; der Code wird ins Feld übernommen und **nicht** automatisch eingelöst, bevor der Nutzer bestätigt (B-8).
- Web (Prüfumgebung bzw. Präsentation im Browser): `<INVITE_LINK_BASE>/?einladung=<CODE>`.
- Ein https-App-Link (Android App Links/iOS Universal Links) bräuchte eine Domain mit Verifizierungsdateien (X2-7); für den Prototyp nicht empfohlen.
- QR-Code im Physio-Web enthält den Link (Paket `qr_flutter`). Die Patienten-App scannt selbst nichts (Kamera-App öffnet den Link) → kein Kamera-Paket.

**Gerätewechsel/Neuinstallation:** Die anonyme Sitzung ist an das Gerät gebunden; ein benutzter Code gilt nicht noch einmal. Vorschlag O-8: Physio erzeugt einen neuen Code; Einlösen bindet den Patienten an die neue Sitzung, die alte verliert den Zugriff.

**Missbrauchsschutz:** Ungebundene anonyme Sitzungen sehen nichts. Codes mit hoher Entropie (Vorschlag: 10 Zeichen aus einem Alphabet ohne verwechselbare Zeichen, angezeigt in Zweiergruppen), Versuchsbremse in `redeem_invitation`. Optional Captcha bei anonymer Anmeldung (Supabase-Einstellung, X2-2), für die Präsentation nicht nötig.

---

## 6. Patienten-App: Umbau des ersten Ausschnitts

Bestehende Nähte werden genutzt: `PathSource`/`TodaySource` (`prepare()` mit Laden/Fehler, Kommentar „Das spätere Physio-Framework tritt hier an“), `StateStore`, `DataEraser`-Liste, `MannyTextSource`, `MannyContext`.

### 6.1 Zustandsdokument und Migration
- `curaone.state.v1` erhält Schema 2: neuer Abschnitt `account {patientId, boundAt}`; `onboarding.name/injuryType/injuryOther/injuryDate` werden im Einladungsweg nicht mehr befüllt (Name, Verletzung, Datum kommen aus `patients` bzw. der Akte; Spec 7).
- Migration 1 → 2: vorhandene Dokumente ohne `account` → Startbildschirm mit Code (A-1 AK 2). Nach dem Einlösen startet der lokale Fortschritt neu (Streak, Pfad), damit kein Beispiel-Fortschritt in einen echten Plan gerät (B-9).
- Neue Schlüssel `curaone.framework.v1` (Zwischenspeicher) und `curaone.outbox.v1` (Warteschlange), beide in `kAllStorageKeys`; Merkzeichen `curaone.deletion.v1` aus KI-Plan v1.2 Abschnitt 9.

### 6.2 Laden und Zwischenspeicher
- Beim Start, beim Fortsetzen und **beim Öffnen von „Heute“** lädt die App Plan, aktuelle Phase, Übungen, Akte (P-3 AK 3: „beim nächsten Öffnen von Heute“). Umsetzung über `TodaySource.prepare()`/`PathSource.prepare()`.
- Erfolg → Zwischenspeicher aktualisieren. Fehler/offline → letzter Stand aus dem Zwischenspeicher mit Hinweis „nicht aktuell“ (Gestaltung F2-D); ohne Zwischenspeicher → Fehlerzustand mit „Nochmal versuchen“ (wie bisher).
- Ändert sich die Planversion während des Tages, verfallen Tagesänderungen (`removed`, `swaps`), die auf nicht mehr vorhandene Positionen zeigen; `done` bleibt (B-10).
- Patient mit Status `access_deleted` oder gelöster Bindung → zurück zum Startbildschirm, lokale Daten werden gelöscht (B-11).

### 6.3 Pfad aus Physio-Phasen (A-1 AK 1, O-4)
- Neue reine Funktion `buildPathFromPhases(phases, currentPhaseId, completedUnitIds, …)` in `lib/logic/path_from_phases.dart`; `path_generator.dart` bleibt unverändert für den Beispielpfad.
- Kopfzeile „Woche N“ aus `reference_date`; „Phase P · <Titel der Physio-Phase>“.
- Label „Beispielpfad“ entfällt im echten Plan (UI-25 gilt nur noch im Beispielmodus; Brief-Änderung in F2-D).
- Streak, Freezes, Feier, Manny-Anlässe unverändert (Vorschlag O-4).
- Der gesperrte Ausblick „Prävention & Gesundheitssport“ bleibt als Darstellungselement (O-4 bestätigen).

### 6.4 „Heute“ aus dem Plan (A-2)
- Übungsliste nach Regel O-10 aus den Positionen der **aktuellen Phase**; Anzeige: Name, Sätze × Wiederholungen bzw. Dauer.
- **Übungsdetail** (A-2 AK 1): jede Übung antippbar → Sheet mit Beschreibung, Sätzen, Wiederholungen, Dauer, Belastungshinweis des Physios. Zustände: Standard, Beschreibung lang (scrollt), Katalog-Beispiel gekennzeichnet (O-1).
- **Tauschen** (A-2 AK 2): Kandidaten = Positionen der aktuellen Phase, die heute nicht in der Liste stehen (`swapCandidates`). Keine Kandidaten → Tauschen nicht angeboten (Gestaltung F2-D). Nie Übungen anderer Phasen oder aus dem Katalog.
- „Eigene Übung“ des Patienten: O-15.
- **Termine** aus `appointments` statt Platzhalter-Pool; „Beispiel“-Kennzeichnung entfällt.
- „Training eintragen“: lokal wie bisher (Streak, Pfad, Rückgängig) **plus** Warteschlangeneintrag `training_sessions` mit Momentaufnahme der Liste. Rückgängig innerhalb des Fensters entfernt den Eintrag aus der Warteschlange bzw. reiht ein Löschen ein.

### 6.5 Befinden melden (A-3)
- Eingabe Schmerz, Schwellung, Stimmung nach O-3; Einstieg und Häufigkeit nach O-3 (Gestaltung F2-D).
- Speichern lokal + Warteschlange → `wellbeing_reports`; der Trigger erzeugt ggf. ein Warnzeichen (O-2).
- Zustände: leer, ausgefüllt, gesendet, „wird gesendet, sobald Verbindung besteht“, Fehler (dauerhaft abgelehnt, z. B. Bindung gelöst).
- Hinweis an den Patienten bei Warnzeichen: O-12.

### 6.6 Akte (A-4)
- Lesend: Behandler (Rolle, Name, Kontakt), Termine (vom Physio und eigene), Krankengeschichte (B-4).
- Eigene Termine anlegen, ändern, löschen; vom Physio Eingetragenes nur lesen (A-4 AK 1; doppelt gesichert durch RLS).
- Dokumente nur bei O-5 = „Ausschnitt 2“.
- Zustände: Laden, leer je Bereich, Fehler, offline (Zwischenspeicher), Speichern läuft, Speichern fehlgeschlagen.
- „Deine Daten“: Profilfelder Name/Verletzung/Datum werden zur Leseansicht (kommen aus der Akte); Bearbeiten entfällt im Einladungsweg (Gestaltung F2-D).

### 6.7 „Alles löschen“ mit Backend (Spec 7; KI-Plan v1.2 Abschnitt 9)
- Vorgezogen aus dem KI-Plan: `AccountDeleter` vor den lokalen Löschern, Merkzeichen `curaone.deletion.v1`, Fehlerregeln „sicher nicht gelöscht“ / „unklar“ / „lokaler Fehler nach Backend-Löschung“, Snackbar nur nach vollständigem Erfolg.
- Backend-Teil: `delete_my_data()` (Umfang O-9). Danach lokal: Zustand, Zwischenspeicher, Warteschlange, Sitzung abmelden, zuletzt Merkzeichen.
- Offline: kein „nur lokal löschen“, klare Fehlermeldung (Vorschlag wie KI-Plan E-24).
- Nach dem Löschen: Startbildschirm mit Code (nicht mehr Onboarding Schritt 1).

### 6.8 Ausgangswarteschlange (B-12)
- `Outbox` (rein Dart): Einträge `{id, kind, payload, createdAt, attempts}`; Arten `training_insert`, `training_delete`, `wellbeing_insert`, `appointment_upsert`, `appointment_delete`.
- Senden bei Start, Fortsetzen, nach jedem neuen Eintrag; Reihenfolge erhalten; idempotent über Geräte-IDs; dauerhafte Fehler (RLS-Ablehnung) → Eintrag verwerfen und Zustand „Bindung prüfen“.
- Löschen leert die Warteschlange erst **nach** erfolgreicher Backend-Löschung.

### 6.9 Beispielpfad und Präsentationsmodus (O-14)
Vorschlag: Der Beispielpfad bleibt in `main_preview.dart`/Szenarien (Prüfinfrastruktur braucht ihn) und als Build-Schalter `--dart-define=CURAONE_DEMO=true` für eine Präsentation ohne Backend. In der normalen App gibt es ohne Code keinen Zugang (A-1 AK 2). Damit erledigt sich der Befund „andere Verletzungstypen zeigen denselben Kreuzband-Pfad“ (App-Prüfung) im echten Weg.

### 6.10 Manny ohne KI
Platzhaltertexte bleiben (KS-1). `MannyContext` bezieht Vorname, Verletzung, Phase künftig aus dem Framework statt aus dem Onboarding; Feldschema bleibt kompatibel zum KI-Plan.

---

## 7. Physio-Web: Funktionen und Zustände (Gestaltung über Ablauf C)

| Bereich | Funktionen | Zustände |
|---|---|---|
| Anmeldung (P-1) | E-Mail, Passwort, Anmelden, Abmelden | leer, Laden, falsche Zugangsdaten, keine Verbindung, Sitzung abgelaufen, kein Physio-Konto |
| Patientenliste (P-1, P-5) | Liste der Patienten **der eigenen Praxis**: Name, Phase, letzte Aktivität, Status (eingeladen/aktiv/Zugang gelöscht), **Warnzeichen-Markierung**; Patient anlegen | Laden, leer, Fehler, mit Warnzeichen |
| Patient anlegen + Einladen (P-2) | Vorname, Nachname, Verletzung/OP-Bezeichnung, Bezugsdatum; danach Anzeige **Code, Link, QR**; Code/Link kopieren; ggf. neuen Code erzeugen (O-8) | Formular leer/ungültig, Speichern läuft, Fehler, Einladung angezeigt, Code eingelöst, Code abgelaufen |
| Plan (P-3) | Phasen anlegen/umbenennen/ordnen/löschen, aktuelle Phase setzen; Übungen aus **Katalog** (Suche/Liste) und **eigene Übungen** hinzufügen; je Position Sätze, Wiederholungen, Dauer, Belastungshinweis, Phase; ordnen, entfernen; Speichern | Laden, leer, ungespeicherte Änderungen (Verlassen-Warnung), Validierungsfehler mit **Nennung des fehlenden Felds** (P-3 AK 2), Speichern läuft, Konflikt (inzwischen geändert), gespeichert |
| Eigene Übung (P-3) | Name (Pflicht), Beschreibung (Pflicht); bearbeiten; Löschen nur, wenn in keinem Plan verwendet (B-13) | wie oben |
| Akte (P-4) | Behandler (Physio, Arzt, sonstige) mit Rolle, Kontakt; Termine; Krankengeschichte (Verletzungen, OP, frühere Therapien, aktuelle Behandlungen, Behandlungsmöglichkeiten): anlegen, ändern, löschen; eigene Termine des Patienten sichtbar, nicht änderbar | Laden, leer je Bereich, Fehler, Speichern, Löschen bestätigen |
| Verlauf (P-5) | je Tag erledigte Übungen und gemeldetes Befinden; Liste der Warnzeichen mit Grund; ältere Tage nachladen | Laden, leer, Fehler, Warnzeichen ungesehen/gesehen (O-11) |
| Manny-Chat | **nirgends** (P-5 AK 3); keine Tabelle, kein Menüpunkt, kein Datenpfad | – |

Zielgeräte: Desktop-Browser (Vorschlag Prüf-Viewports 1280×800 und 1024×768; schmale Breite nur, wenn der Brief es verlangt). Physio-Texte in `strings_physio_de.dart`; Ton und Begriffe (z. B. „Patient“, der in der Patienten-App per Wortliste verboten ist) legt der Brief fest → die statische Regel 10 gilt nur für `strings_de.dart`.

---

## 8. Testdaten-Seed und Reset (T-1)

- Befehl (im Verzeichnis `app/`): `dart run tool/seed/seed.dart --target local|remote [--confirm-remote]`.
- Liest `SUPABASE_URL` und `SUPABASE_SERVICE_ROLE_KEY` **nur aus der Umgebung**; bricht ab, wenn sie fehlen. Gegen eine nicht-lokale URL nur mit `--confirm-remote` (jede Ausführung remote ist ein externer Schritt X2-4).
- Ablauf: (1) alle Praxen mit `is_test = true` samt abhängiger Daten löschen; Test-Auth-Konten (Kennung über E-Mail-Domain `@test.curaone.invalid` bzw. gespeicherte Seed-Kennung) löschen; (2) Katalogübungen (O-1) anlegen bzw. aktualisieren; (3) Praxen, Physio-Konten (bestätigt, Passwort aus `CURAONE_SEED_PASSWORD` oder erzeugt und ausgegeben), Patienten, Pläne mit Phasen, Akte, Verlauf und Befinden der letzten Tage, mindestens ein Warnzeichen; (4) Einladungscodes erzeugen und **auf der Konsole ausgeben** (nicht in Dateien schreiben).
- Inhalt aus `tool/seed/testdaten.json`, Umfang nach O-6.
- Test: Seed zweimal hintereinander gegen den lokalen Stack → gleicher Endzustand (Anzahlen), keine Nicht-Test-Daten berührt (eine Kontrollpraxis mit `is_test = false` bleibt unverändert).
- Ohne lokalen Supabase-Stack nicht ausführbar → bis dahin „unverifiziert“.

---

## 9. Pakete (pub.dev)

| Paket | Wo | Zweck | Begründung |
|---|---|---|---|
| `supabase_flutter` | `dependencies` | Auth (anonym, E-Mail), Datenbankzugriff, Sitzung speichern | offizieller Flutter-Client des gewählten Backends |
| `app_links` | `dependencies` | Einladungslink beim Kaltstart und bei laufender App empfangen | A-1 AK 1 („oder Öffnen des Links“); Flutter-Bordmittel decken Kaltstart und laufende App nicht einheitlich ab |
| `qr_flutter` | `dependencies` (nur Physio-Web nutzt es; Tree-Shaking entfernt es aus dem Patienten-Build) | QR-Code aus dem Link zeichnen | P-2 AK 1 |
| `supabase` | `dev_dependencies` | Seed-Skript auf der Dart-VM (Admin-Aufrufe mit Service-Schlüssel) | gleiche Sprache wie die App, kein `package.json` nötig |

Versionen werden beim Hinzufügen per `flutter pub add` bestimmt und im Paketbericht genannt; Lizenz und Pflegezustand prüft F2-3. Bewusst **nicht**: State-Management-Pakete (Bordmittel reichen weiter), `go_router` (Navigator 1.0 bleibt; Physio-Web mit eigener schlanker Routen-Tabelle), Kamera-/Scanner-Pakete, `http` (kommt erst mit dem KI-Ausschnitt).

---

## 10. Teststrategie

Bestehende Infrastruktur wird weiterverwendet (Flutter-Plan 12; `KONVENTIONEN.md` Regel 5).

| Ebene | Inhalt | Werkzeug | Hier ausführbar? |
|---|---|---|---|
| U (Logik) | `invite_code`, `plan_today` (Regel O-10, Tausch-Kandidaten nur aktuelle Phase), `path_from_phases`, `outbox` (Reihenfolge, Undo, Idempotenz), `plan_validation` (fehlendes Feld wird benannt), Migration Schema 1 → 2 mit Fixture `state_v2.json`, Warteschlange beim Löschen | `flutter test` | ja |
| W (Widget) | Startbildschirm (alle Fehlercodes), Einwilligung, Übungsdetail, Tauschen, Befinden, Akte (eigene vs. Physio-Termine), Löschen mit Backend (sicher/unklar/lokaler Fehler), offline mit Zwischenspeicher; Physio: Anmeldung, Liste mit Warnzeichen, Anlegen + Einladung, Plan-Editor inkl. Validierung und Konflikt, Akte, Verlauf | `flutter test`, **gefälschte Repositories** (`FakePatientRepository`, `FakePhysioRepository`) | ja |
| C (statisch) | bestehende Regeln 1–16 + neu: Grenze Patient/Physio (2), `supabase_flutter` nur in `lib/backend/**`, kein `service_role`/Schlüsselmuster in `lib/` und `tool/` (außer Umgebungsvariablen-Namen im Seed), keine Chat-Begriffe/Tabellen in `lib/physio/**`, `lib/logic/**` weiter ohne Flutter | `test/static/code_rules_test.dart` | ja |
| M (Matrix) | neue Patienten-Szenarien (`start-code-*`, `consent-physio`, `today-plan`, `today-plan-detail`, `wellbeing-*`, `record-*`, `delete-backend-*`, `offline-cache`) in allen Stufen; Physio-Szenarien mit Desktop-Viewports in M-Layout und M-Kontrast (Werte des Physio-Briefs) | `flutter test --tags matrix` | ja |
| G (Golden) | Auswahl nach Freigabe durch Nutzer wie bisher | `--tags golden` | ja |
| S (Screens) | `scenarios.json` + neue Physio-Liste; `shoot.mjs` erhält einen zweiten Build (`main_physio_preview.dart`) | Playwright/Chromium | ja |
| N (Abläufe) | `nav_checks.mjs`: Code eingeben → Fehler „bereits benutzt“ → gültiger Code → Einwilligung → Pfad; Link mit `?einladung=` füllt das Feld; Heute → Detail → Tauschen; Befinden; Akte eigener Termin; Löschen → Startbildschirm. Physio: Anmelden → Liste → Anlegen → Code/QR sichtbar → Plan speichern mit fehlender Beschreibung (Fehlermeldung nennt Feld) | Preview-Builds mit gefälschten Repositories (`live=1` behält localStorage) | ja |
| DB (RLS) | je Tabelle und Rolle: Physio Praxis A sieht keine Daten Praxis B (P-1 AK 1); Patient sieht nur sich; ungebundene anonyme Sitzung sieht nichts; Patient kann Physio-Termine/Behandler/Krankengeschichte nicht ändern (A-4); Warnzeichen nur per Trigger; Code doppelt einlösen → `already_used`; abgelaufen → `expired`; Versuchsbremse; `save_plan` mit fremder Übung/fehlenden Feldern/alter Version → Fehler; `delete_my_data` idempotent | SQL-Tests gegen lokales Postgres 16 mit `auth_shim.sql` (`/usr/lib/postgresql/16/bin` vorhanden) | **ja, mit Einschränkung**: Shim ≠ echter Supabase-Stack (GoTrue, PostgREST-Grants, anonyme Anmeldung) |
| E2E | Physio legt an → Patient löst ein → Plan ändern → „Heute“ zeigt Änderung (P-3 AK 3) → Befinden erscheint beim Physio (A-3) → Warnzeichen in Liste (P-5) → Löschen | Integrationstest (Tag `integration`) gegen lokalen Supabase-Stack | **nein**: Supabase-CLI fehlt, Docker-Daemon läuft nicht (X2-8) |

Laufzeiten der Matrix steigen; F2-3 misst sie und meldet sie im Paketbericht.

---

## 11. Zuordnung der Akzeptanzkriterien

| AK | Umsetzung | Prüfung |
|---|---|---|
| P-1 AK 1 (Liste, keine fremden Praxen) | Anmeldung 5.1, Liste 7, RLS 4.1 | DB (zwei Praxen), W, N |
| P-1 AK 2 (falsche Daten → Meldung, kein Zugang) | 5.1 | W (Fake-Fehler), E2E |
| P-2 AK 1 (Code, Link, QR) | `create_patient`, 7 | W, S, N |
| P-2 AK 2 (Code genau ein Patient; benutzter Code abgelehnt mit Hinweis) | Unique `auth_user_id`, Hash, `redeem_invitation` → `already_used`; Startbildschirm 5.2 | DB, W, N |
| P-3 AK 1 (Katalog + eigene, Felder je Übung) | Plan-Editor 7, `save_plan` | W, DB |
| P-3 AK 2 (eigene Übung: Name + Beschreibung Pflicht, Feld genannt) | `plan_validation.dart`, Formular, `CHECK` | U, W, DB |
| P-3 AK 3 (Patient sieht Änderung beim nächsten Öffnen von Heute) | Laden in `TodaySource.prepare()` 6.2 | W (Fake: neue Version), E2E |
| P-4 AK (Akte anlegen/ändern/löschen) | 7 „Akte“, RLS | W, DB |
| P-5 AK 1 (je Tag Übungen und Befinden) | Verlauf 7, `training_sessions`, `wellbeing_reports` | W, DB, E2E |
| P-5 AK 2 (Warnzeichen in Liste markiert) | Trigger 4, Liste 7, Regeln O-2, Dauer O-11 | DB, W, E2E |
| P-5 AK 3 (Chat nirgends sichtbar) | kein Chat im Backend; statische Regel; im KI-Ausschnitt RLS-Test „Physio sieht 0 Zeilen“ | C; DB-Test in Ausschnitt 3 |
| A-1 AK 1 (Code oder Link + Einwilligung → Plan statt Beispielpfad) | 5.2, 6.3 | W, N, E2E |
| A-1 AK 2 (ohne Code kein Weiterkommen; Erklärung) | Startbildschirm 5.2, Migration 6.1 | W, N |
| A-1 AK 3 (Einwilligung nennt Physio-Sicht, nicht Chat) | Einwilligung 5.2, Text aus Brief | W (Text wörtlich) |
| A-2 AK 1 (Übung antippbar, Beschreibung und Grenzen) | 6.4 | W, M, S |
| A-2 AK 2 (Tauschen nur aktuelle Phase) | `swapCandidates` 6.4 | U, W |
| A-3 AK (Schmerz, Schwellung, Stimmung; erscheint beim Physio) | 6.5, O-3 | U, W, DB, E2E |
| A-4 AK 1 (sehen, eigene Termine, Physio-Einträge nicht änderbar) | 6.6, RLS | W, DB |
| A-4 AK 2 (Dokumente nur bei O-5) | abhängig von O-5 | – |
| T-1 AK (ein Befehl, Neuanlage/Reset, Umfang) | 8, O-6 | Seed-Test lokal (E2E-Umgebung) |

---

## 12. Offene Fragen mit Vorschlag

### 12.1 Aus der Spezifikation

| Nr. | Vorschlag | Auswirkung |
|---|---|---|
| **O-1** Katalog-Inhalte | Beispieltexte von uns, sichtbar gekennzeichnet („Beispiel“, `is_example`), Ausgangspunkt die vorhandenen Platzhalter-Übungen aus `placeholder_pools.dart` mit kurzer Beschreibung; Ton prüft der `ui-designer`, Freigabe der Nutzer. Fachperson später | Kennzeichnung im Übungsdetail und im Physio-Katalog; Katalog-Datei im Seed; keine Aussage als „geprüft“ |
| **O-2** Warnzeichen | Für Ausschnitt 2 nur Befinden-Regeln als **gekennzeichnete Startliste** (`is_provisional`), z. B. Schmerz ab einer Schwelle, deutlicher Schmerzanstieg zur letzten Meldung, Schwellung höchste Stufe. Konkrete Schwellen setzt der Nutzer (Vorschlag zur Diskussion: Schmerz ≥ 7 von 10; Anstieg ≥ 3; Schwellung „stark“). Schlüsselwörter im Chat kommen mit Ausschnitt 3 (KI-Plan v2) | Regeltabelle statt fester Werte im Code; Änderung ohne App-Update; Physio-Liste markiert nach diesen Regeln |
| **O-3** Befinden | Schmerz 0–10 (numerische Skala), Schwellung 4 Stufen (keine, leicht, mittel, stark), Stimmung 5 Stufen. Häufigkeit: jederzeit möglich, einmal täglich angeboten (Einstieg z. B. auf „Heute“ bzw. nach „Training eintragen“; Gestaltung F2-D). Keine Push-Erinnerung (Spec 8) | `CHECK`-Bereiche, Datenmodell, Gestaltung; Grundlage für O-2 und Manny (Ausschnitt 3) |
| **O-4** Streak, Freezes, Pfad | **Variante A (Empfehlung):** Streak/Freezes/Feier unverändert. Pfad-Abschnitte = Physio-Phasen in Reihenfolge, Länge je Phase aus „geplante Wochen“ (neues Feld beim Physio), Units je Woche wie bisher; **aktuelle Phase setzt der Physio**; Units werden nur durch Training erledigt, nicht durch das Kalenderdatum (löst Grenze K-1). **Variante B:** Pfad zeigt je Phase eine feste Zahl Trainings-Units ohne Wochen. Ausblick bleibt | neues Feld `planned_weeks`, neuer Generator, sichtbare Änderung des Pfads (Brief-Ergänzung nötig); Phasenwechsel nur durch Physio |
| **O-5** Dokumente | **Später** (nicht Ausschnitt 2) | ohne Storage-Bucket, ohne Dateiauswahl-Paket; A-4 AK 2 entfällt in Ausschnitt 2 |
| **O-6** Testdaten-Umfang | 2 Praxen (die zweite zeigt die Trennung P-1); Praxis A: 2 Physios, 4 Patienten (Phase 1, Phase 2, Phase 3 mit Warnzeichen, 1 nur eingeladen); Praxis B: 1 Physio, 1 Patient. Je Plan 3 Phasen mit 4–6 Übungen; Verlauf und Befinden der letzten 14 Tage für die aktiven Patienten | Seed-Datei; Präsentationsdrehbuch |
| **O-7** Gültigkeit Code | 14 Tage, einmalig; nach Ablauf neuer Code durch Physio (O-8). Seed-Codes gelten bis zum nächsten Reset | `expires_at`; Fehlerfall „abgelaufen“ |

### 12.2 Neu aus diesem Plan

| Nr. | Frage | Vorschlag | Auswirkung |
|---|---|---|---|
| **O-8** | Gerätewechsel/verlorener Code: darf der Physio einen neuen Code erzeugen? | ja, alte Bindung wird gelöst | eine Funktion + ein Knopf im Physio-Web |
| **O-9** | Was löscht „Alles löschen“ des Patienten im Backend? | alles, was der Patient erzeugt hat (Verlauf, Befinden, Warnzeichen daraus, eigene Termine, Einwilligungen, Konto) + Bindung; Einträge des Physios (Plan, Akte, Patientenzeile) bleiben bei der Praxis, Status „Zugang gelöscht“ | Löschfunktion, Physio-Ansicht; Datenschutzfrage für echte Daten später |
| **O-10** | Wie entsteht „Heute“ ohne KI? | Übungen der aktuellen Phase in Physio-Reihenfolge, bis die Zeitwahl (10/20/30) gefüllt ist (mindestens eine); Tauschen bietet die übrigen Übungen der Phase. Alternative: alle Übungen der Phase, Zeitwahl entfällt bis Ausschnitt 3 (dann gäbe es keine Tausch-Kandidaten) | bestimmt Logik, Gestaltung und A-2 AK 2 |
| **O-11** | Wie lange bleibt ein Warnzeichen in der Liste markiert? | bis der Physio die Patientenansicht geöffnet hat (`seen_at` automatisch). Alternative: ausdrückliches „Gesehen“ | Funktion `mark_warnings_seen`, Gestaltung |
| **O-12** | Bekommt der Patient bei einer Befindensmeldung, die als Warnzeichen gilt, einen festen Hinweis (z. B. Physio kontaktieren)? | ja, fester Text, Wortlaut vom Nutzer/Fachleuten freigegeben (wie KI-Plan E-17) | Zustand im Befinden-Ablauf; ohne Entscheidung kein Hinweis |
| **O-13** | Technik Physio-Web | W-A (Abschnitt 2) | Projektstruktur, Paketschnitt |
| **O-14** | Beispielpfad | nur Prüfumgebung + Build-Schalter für Präsentation ohne Backend; entfällt in der normalen App | 6.9 |
| **O-15** | Bleibt „Eigene Übung“ für Patienten in „Heute“? | entfernen (Spec 3.1: Plan und Übungen pflegt der Physio). Alternative: behalten, im Verlauf als „eigene“ gekennzeichnet | sichtbare Änderung an „Heute“, Verlauf |
| **O-16** | Wo laufen die Apps in der Präsentation? | Patienten-App als Web-Build im Browser (wie Prüfumgebung) oder Android-Build auf dem Rechner des Nutzers (hier kein Android-SDK/Xcode); Physio-Web lokal. Hosting nur bei Bedarf | Deep-Link-Variante, externe Schritte X2-6/X2-7 |

**Blockierend vor Freigabe des Plans:** O-13, O-4, O-10, O-9. **Vor dem jeweiligen Paket zu klären** (Vorschlag als Annahme übernehmbar): O-1, O-2 (Schwellen), O-3, O-6, O-7, O-8, O-11, O-12, O-14, O-15, O-16. O-5: Empfehlung „später“.

---

## 13. Arbeitspakete

| Paket | Inhalt | Rolle | Abhängigkeit | Ergebnis/Abnahme |
|---|---|---|---|---|
| **F2-0** | Entscheidungen O-1 … O-16 | Nutzer/Orchestrator | – | Antworten im Paket F2-1 |
| **F2-D** | Gestaltung über Ablauf C: (a) Patienten-App-Ergänzung (Startbildschirm mit Code und Fehlern, Einwilligung, Übungsdetail, Tauschen, Befinden, Akte, Deine Daten lesend, Löschen mit Backend, offline/nicht aktuell, Pfad aus Phasen ohne Beispiel-Label); (b) Physio-Web Grunddesign + Brief | `ui-designer` | F2-0 | Briefe freigegeben |
| **F2-1** | Supabase-Schema, RLS, Funktionen, Warnzeichen-Trigger, `config.toml`, Auth-Shim, RLS-Tests am lokalen Postgres | `flutter-developer` | F2-0 (O-2, O-3, O-4, O-7, O-8, O-9) | alle DB-Tests grün |
| **F2-1R** | Review Sicherheit (RLS, `SECURITY DEFINER`, Einladung, Löschen) | `reviewer` | F2-1 | keine BLOCKER/MAJOR |
| **F2-2** | Seed/Reset + `testdaten.json` + Katalog | `flutter-developer` | F2-1, O-1, O-6 | Seed-Test lokal (sobald Stack da) |
| **F2-3** | Datenschicht App: Pakete, Konfiguration, `lib/logic`-Modelle und Ableitungen, Repositories (Schnittstellen, Supabase, Fakes), Zwischenspeicher, Warteschlange, Migration Schema 2, `AccountDeleter`; Unit-Tests; statische Regeln | `flutter-developer` | F2-1 | U/C grün, `analyze` 0 |
| **F2-4a** | Physio-Web I: Einstieg, Anmeldung, Patientenliste, Anlegen + Einladung (Code/Link/QR), Preview + Szenarien | `flutter-developer` | F2-D(b), F2-3 | W/M/S/N für diese Teile |
| **F2-4b** | Physio-Web II: Plan-Editor, eigene Übungen, Akte, Verlauf, Warnzeichen | `flutter-developer` | F2-4a | W/M/S/N |
| **F2-5a** | Patienten-App I: Start/Code/Link, Einwilligung, Migration, Löschen mit Backend, Präsentationsmodus | `flutter-developer` | F2-D(a), F2-3 | W/M/S/N |
| **F2-5b** | Patienten-App II: Pfad aus Phasen, „Heute“ aus Plan, Übungsdetail, Tauschen, Termine, Training → Warteschlange | `flutter-developer` | F2-5a | W/M/S/N |
| **F2-5c** | Patienten-App III: Befinden, Akte, Deine Daten lesend | `flutter-developer` | F2-5b | W/M/S/N |
| **F2-6** | Integration Ende-zu-Ende gegen lokalen Supabase-Stack inkl. Seed; Kriterienbericht P-1 … T-1 | `flutter-developer` | alle, X2-8 | E2E grün oder als unverifiziert gemeldet |
| **F2-R** | Gesamtreview + Design-Abnahme | `reviewer`, `ui-designer` | F2-6 | Freigabe |

Reihenfolge: F2-0 → (F2-D parallel zu F2-1/F2-1R/F2-2/F2-3, da getrennte Schreibbereiche: Docs vs. `supabase/`+`app/`) → F2-4a → F2-4b → F2-5a → F2-5b → F2-5c → F2-6 → F2-R. Physio- und Patienten-Pakete **nicht parallel**: gemeinsame Dateien `pubspec.yaml`, `lib/dev/scenarios.dart`, `tool/screens/scenarios.json`, Matrix-Harness. Parallel nur, wenn Szenario-Register und Textdateien vorher getrennt sind (dann F2-4 ∥ F2-5 möglich). Physio-Web zuerst, weil die Patienten-App echte Pläne zum Prüfen braucht und die Präsentation mit dem Anlegen beginnt.

Größe: Ausschnitt 2 ist deutlich größer als ein Paket des ersten Ausschnitts (zwei Oberflächen + Backend). Zwischenstand-Rückmeldungen sind je Paket zulässig.

---

## 14. Externe Schritte (nur benannt, nichts ausgeführt; jeweils einzeln zur Freigabe)

| Nr. | Schritt | Zweck | Risiko |
|---|---|---|---|
| X2-1 | Supabase-Konto/Organisation und **Projekt in EU-Region** anlegen (Konsole); Tarif wählen | Backend | Kosten; im kostenlosen Tarif können inaktive Projekte pausiert werden (vor der Präsentation prüfen) |
| X2-2 | Auth-Einstellungen: E-Mail/Passwort an, **öffentliche Registrierung aus**, **anonyme Anmeldung an**, ggf. Captcha; erlaubte Redirect-URLs | Zugang | falsche Einstellung öffnet Registrierung |
| X2-3 | Migrationen ausrollen: `supabase link --project-ref <ref>`, dann `supabase db push` – erst nach grünen RLS-Tests und Review F2-1R | Schema live | fehlerhafte Policies legen Daten offen |
| X2-4 | Seed gegen das entfernte Projekt: `SUPABASE_URL=… SUPABASE_SERVICE_ROLE_KEY=… dart run tool/seed/seed.dart --target remote --confirm-remote` (Werte nur in der Shell) | Testdaten | löscht/überschreibt Testdaten; Service-Schlüssel darf nie ins Repo |
| X2-5 | Werte in `app/config/supabase.local.json` eintragen (nicht eingecheckt) | App-Konfiguration | – |
| X2-6 | Hosting Physio-Web bzw. Patienten-Web (nur bei O-16 = gehostet), Anbieter/Region festlegen | Präsentation | weiterer Anbieter, Datenschutz |
| X2-7 | Domain + App-Links/Universal Links (nur falls https-Einladungslinks gewünscht) | Deep Links | Aufwand, Domain nötig |
| X2-8 | Lokale Werkzeuge in der Entwicklungsumgebung: Supabase-CLI installieren, Docker-Daemon starten (für lokalen Stack, Seed-Test, E2E) | Verifikation | Installationen in der Umgebung |
| X2-9 | Android-/iOS-Build auf einem Rechner des Nutzers (nur bei O-16 = Gerät) | Präsentation auf Handy | Signatur, Toolchain |
| X2-10 | AV-Vertrag mit Supabase, Datenschutz-Konzept | Voraussetzung für echte Daten | **nicht** nötig, solange nur Testdaten (Spec 13) |

Befehle sind vor Ausführung gegen die aktuelle Supabase-CLI-Dokumentation zu prüfen.

**Vom Nutzer einzutragende Werte (ohne Werte):** `SUPABASE_URL`, öffentlicher Client-Schlüssel (`SUPABASE_ANON_KEY` bzw. Nachfolger), `SUPABASE_SERVICE_ROLE_KEY` (nur Shell, nur Seed), Projekt-Referenz, `CURAONE_SEED_PASSWORD` (optional), `INVITE_LINK_BASE` (Web-Basis-URL für Einladungslinks).

---

## 15. Risiken

| Nr. | Risiko | Umgang |
|---|---|---|
| R2-1 | RLS-Fehler legen Gesundheitsdaten offen | Grundsatz verweigern, Hilfsfunktionen zentral, Tests je Tabelle und Rolle, Sicherheitsreview vor X2-3, nur Testdaten |
| R2-2 | Testumgebung ohne echten Supabase-Stack (Shim weicht ab) | DB-Tests am Shim früh, E2E-Paket F2-6 nach X2-8; bis dahin als unverifiziert melden |
| R2-3 | Massenhaft anonyme Konten | ungebundene Sitzungen ohne Rechte; Versuchsbremse; optional Captcha |
| R2-4 | Umfang: zwei Oberflächen + Backend | Pakete klein schneiden, Physio-Web schlank (Spec 12), keine Zusatzfunktionen |
| R2-5 | Gestaltung blockiert UI-Pakete | F2-D früh starten; Backend-/Datenpakete laufen unabhängig |
| R2-6 | Warteschlange: Doppel- oder Verlust-Einträge | Geräte-IDs, idempotente Inserts, Unit-Tests für Undo/Neustart/Löschen |
| R2-7 | Flutter Web als Formular-Oberfläche (Autofill, Textauswahl, Ladezeit) | für Präsentation vertretbar; Befund im Review; Wechsel zu W-B/W-C später möglich |
| R2-8 | Präsentation hängt vom Netz/Backend ab | Präsentationsmodus ohne Backend (O-14), Zwischenspeicher |
| R2-9 | Pausiertes Projekt im kostenlosen Tarif | vor Termin prüfen (X2-1) |
| R2-10 | Konflikte mit dem parallel arbeitenden Agenten unter `app/` | Umsetzung erst nach dessen Abschluss |
| R2-11 | Katalog wirkt „geprüft“ | Kennzeichnung „Beispiel“ überall (O-1) |
| R2-12 | Löschen des anonymen Auth-Kontos per Datenbankfunktion in Supabase nicht erlaubt | B-7 im lokalen Stack prüfen; Ausweg Edge Function `delete-account` mit Service-Schlüssel als Secret (KI-Plan v1.2) |

---

## 16. Annahmen

| Nr. | Annahme | Auswirkung |
|---|---|---|
| B-1 | Ausschnitt 2 enthält keine KI und keine Edge Functions | Backend nur DB/Auth |
| B-2 | Physio-Web nur Deutsch, Desktop-Browser | Viewports, Texte |
| B-3 | „Woche N“ bezieht sich auf ein Bezugsdatum (Verletzung bzw. OP) in den Patienten-Stammdaten | Feld `reference_date` |
| B-4 | Der Patient darf seine Krankengeschichte lesen | Policy, Akte-Ansicht |
| B-5 | Der Patient sieht die Tabelle Warnzeichen nicht (nur den Hinweis nach O-12) | Policy |
| B-6 | Versuchsbremse: begrenzte Fehlversuche je Sitzung und je Code in einem Zeitfenster; konkrete Werte im Paket F2-1 als Konstante, vom Nutzer bestätigt | Sicherheit |
| B-7 | Das anonyme Auth-Konto lässt sich aus `delete_my_data()` löschen | sonst Edge Function (R2-12) |
| B-8 | Ein geöffneter Link füllt das Code-Feld; Einlösen erst nach Bestätigung durch den Nutzer | Gestaltung F2-D |
| B-9 | Nach dem Einlösen beginnt der lokale Fortschritt neu | Migration |
| B-10 | Planänderung am selben Tag verwirft Tagesänderungen an entfallenen Positionen, `done` bleibt | Logik |
| B-11 | Gelöste Bindung/gelöschter Zugang → lokale Daten weg, Startbildschirm | Ablauf |
| B-12 | Schreiben über die Warteschlange (lokal zuerst) statt Sperren bei fehlender Verbindung | Umgang offline; Alternative „nur online“ ist einfacher, sperrt aber Training offline |
| B-13 | Eigene Übungen sind je Praxis wiederverwendbar; Änderung wirkt in allen Plänen; Löschen nur ungenutzt | Datenmodell |
| B-14 | Streak und Pfad-Fortschritt bleiben lokal; Neuinstallation setzt sie zurück | Prototyp-Grenze |

---

## 17. Vorschläge für `KONVENTIONEN.md` (nur auf Nutzerwunsch eintragen)

1. Physio-Web-Texte in `lib/l10n/strings_physio_de.dart`; Konvention 4 gilt sinngemäß.
2. `package:supabase_flutter` nur unter `lib/backend/**` und in `main*.dart`.
3. `lib/physio/**` und `lib/ui/**` importieren sich nicht gegenseitig (Ausnahme: geteilte Bausteine unter `lib/ui/components/**`, falls der Brief sie teilt).
4. Jede Tabelle hat RLS; jede neue Policy hat einen SQL-Test unter `supabase/tests/rls/`.
5. Keine Schlüssel in Dateien; Konfiguration per `--dart-define-from-file` aus nicht eingecheckter Datei, Seed nur mit Umgebungsvariablen.
