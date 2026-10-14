# Flutter-Plan Ausschnitt 2 „Fundament“: Patienten-Framework, Training, Check-ups und Physio-Bereich (ohne KI)

Status: **PLAN ZUR FREIGABE** · v2.2 (v1.2 FREIGEGEBEN 2026-10-12 → v2.0 nach den freigegebenen Produkt- und Design-Ergebnissen vom 2026-10-14 → v2.1 nach Review S3-3, Nutzerentscheidungen N-14 und Manny-Entscheidung N-15 → v2.2 nach Re-Review S3-RR und Nutzerentscheidungen N-16) · Pakete S3-1, S3-K1, S3-K2 · Autor: `flutter-developer` · Stand 2026-10-14

## Änderungsprotokoll v2.1 → v2.2 (Paket S3-K2, Re-Review S3-RR und Nutzerentscheidungen N-16)

| Befund / Entscheidung | Änderung | Stelle |
|---|---|---|
| MAJOR-A `physio_can_see_patient` ließ gebundene Patienten durch | Patientenklausel nur noch in `current_injury_id`/`current_plan_id`; `physio_can_see_patient` nur für Physios der Praxis, ohne Selbstbezug; DB-T81 mit Fall „Patient, eigene ID → `false`“ und Physio-Policies | 6.1 Nr. 5, DB-T81 |
| MAJOR-B ±1 Tag verwarf verspätete Check-ups | `submit_daily_checkup`: Grenze Bindungstag − 1 bis UTC-Datum + 1 (kein Höchstalter, Annahme B-35); `invalid_local_day` in der Warteschlange zurückgestellt statt verworfen; Physio-RPCs und `manny-today` bleiben bei ±1; Fixture (h), DB-T83 „Check-up 3 Tage verspätet“ | 6.7 Nr. 3/5, 6.4, 8.6, 8.11, DB-T80, DB-T83, 12.3, B-35 |
| MINOR-C Aufruferprüfung bricht Trigger/Seed | interne ungeprüfte `app.active_injury_id_internal(p)` nur für Trigger und geprüfte Definer-Funktionen, kein `EXECUTE` für API-Rollen; DB-T45, DB-T81 erweitert | 6.1 Nr. 5, 6.3, DB-T45, DB-T81 |
| MINOR-D fremde `training_session_id` | `set_injury_id` prüft, dass die Session demselben Patienten gehört (sonst `42501`); DB-T61 erweitert | 6.3, DB-T61 |
| MINOR-E Fixtures unter `app/` für L2 | Ablage `supabase/tests/fixtures/local_day/`, angelegt von F2-1; Dart-Tests lesen sie nur | 2.3 (F2-1, F2-3), 5, 6.7 Nr. 5; KI-Plan 4.2.1 |
| MINOR-F gleichzeitige Wiederholung `create_patient` | App sendet nicht erneut, solange ein Aufruf läuft, und zeigt nur die Antwort des zuletzt gestarteten; DB-T64b + W-Test | 6.6, DB-T64b, 13.3 |
| NIT R2-19, R2-25, Testbereich T01…, NEU-7 | „aktiv oder vorbereitet“; alle 24 Dateien (V2-73); `T01 … T85`; `warning_raised` nur aus Warnzeichen, die dieser Check-up selbst erzeugt hat (`trigger_checkup_id`) | 16, 5, 6.2, 6.4, DB-T41 |
| N-16 O-41 Manny-Look im Konto | `patients.manny_look`, Schreiben nur über `set_manny_look` (Definer, nur eigener Patient), Warteschlangen-Art `manny_look_set`, Übertragung bei Bindung, „Alles löschen“ setzt zurück; L1 nur lokal, Spalte/RPC L2, App L3; DB-T85; Neubindungs-Regel als Annahme B-36 mit Rückfrage O-44 | 0, 2.2, 2.3, 3.5, 6.2, 6.4, 6.13, 8.1, 8.10, 8.11, 12.2, 13.5, 14, 17 |
| N-16 O-42, O-43 | entschieden: „nächstes Ziel“ = Titel der nächsten Phase; Look-Schritt vor dem Code-Feld; B-31/B-34 entfallen | 0, 3.2, 3.5, 3.7, 6.12, 8.1, 13.3, 14, 17 |
| N-16 Zählweise je Verletzung | Stimmungskette und Anstiegsregel nur über Check-ups derselben Verletzung; DB-T57, DB-T77 erweitert | 0, 6.9, 7.2, DB-T57, DB-T77 |
| N-16 eine Benachrichtigung je Eingang | Trigger setzt `trigger_checkup_id`; Physio-Liste und Kachel 2 fassen Stimmungs-Warnzeichen eines Eingangs zu einer Meldung zusammen (je Tag bleibt ein Warnzeichen); DB-T84 | 6.2, 6.9, 6.12, 9, DB-T84 |
| N-16 Bestätigungen | nachträgliche Warnzeichen (R2-24) und gelockerte Übungs-/Storage-Policy für vorbereitete Positionen vom Nutzer bestätigt | 0, 6.7 Nr. 2, 6.9, 16 |

Ältere Änderungsprotokolle (v2.0 → v2.1, v1.2 → v2.0, v1 → v1.1 → v1.2) stehen in Abschnitt 19.

---

Verbindliche Grundlagen:
- `docs/produkt/curaone-spezifikation-manny-gehirn.md` (FREIGEGEBEN 2026-10-11), Abschnitt 4 (P-1–P-5, A-1–A-4, T-1), 7, 8, 10.
- `docs/produkt/curaone-ablaeufe-training-checkup.md` (FREIGEGEBEN 2026-10-14): T-1–T-6, C-1–C-3, Abläufe 1–4, Randfälle.
- `docs/produkt/curaone-physio-bereich.md` (FREIGEGEBEN 2026-10-14): PB-1–PB-9, Ausschnitt 2 = PB-A–PB-G (ohne KI); PB-5 Physio-KI → KI-Plan v2.5.
- `docs/produkt/curaone-feed.md` (FREIGEGEBEN 2026-10-14): Feed erst ab Ausschnitt 4 → hier nur Abgrenzung.
- `docs/design/design-brief-v2.md` (FREIGEGEBEN 2026-10-14), insbesondere Abschnitt 10 (Migration) und 11 (V2-1–V2-64); `docs/design/grunddesign-v2.md`.
- `docs/design/design-brief-v2-ergaenzung-1.md` (FREIGEGEBEN 2026-10-14; Manny mit finalen Grafiken und Look-Wahl; ersetzt Brief-Abschnitt 6 und V2-56, ergänzt Onboarding-Schritt 6a, Profil-Zeile 6b, V2-65–V2-75 und die Migrationsliste 10) und die Bilder unter `docs/design/manny/{brille,ohne}/` (normal, freudig, traurig, kopf; 1x, `2.0x/`, `3.0x/`). Dieser Plan nennt Funktion, Speicherung, Lieferung und Prüfung; Gestaltung, Maße und Posen-Zuordnung gelten im Wortlaut der Ergänzung.
- Nutzerentscheidungen 2026-10-12 und 2026-10-14 (Abschnitt 0, einschließlich N-16).
- `KONVENTIONEN.md` (Regeln 1–5), `docs/plan/flutter-plan-v1.md` v1.3 (Architektur, Prüf-Infrastruktur 12), KI-Plan v2.5 (Löschkonzept, Chat-Bindung, Kürzungsregel 4.2.3).

Kontext (gelesen, nicht zur Anforderung umgedeutet): `docs/UEBERGABE.md`, `docs/plan/checkliste-naechste-sitzung.md`, Code unter `app/lib` und `app/test` (nur lesend; Stand HEAD `39d8a8d`). Ausschnitt 2 ist noch nicht gebaut: Es gibt kein `supabase/`-Verzeichnis, also auch keine Migrationen, die geändert werden müssten.

Kennzeichnung: **L-n** = Lieferung, **F2-…** = Arbeitspaket, **B-n** = Annahme, **O-n** = offene Frage (O-1–O-7 Spec, O-8–O-16 Plan v1.2, O-17 ff. neu), **R2-n** = Risiko, **X2-n** = externer Schritt, **DB-Tn** = benannter Datenbanktest (12.2), **TR-/CU-/RF-** = Schritte der Abläufe (13.2), **[entschieden]** = vom Nutzer bestätigt, **[Vorschlag]** = noch nicht bestätigter Wert, **[blockiert L-n]** = muss vor Lieferung n entschieden sein, **(Produkt-Annahme)** = Annahme aus einem freigegebenen Produktdokument. Gestaltung kommt vom `ui-designer`; dieser Plan nennt Funktionen, Zustände, Daten und Prüfungen.

---

## 0. Nutzerentscheidungen (verbindlich)

**2026-10-12, zu Plan v1 und Reviews (unverändert gültig):**
- **O-13** Physio-Zugang im selben Flutter-Projekt, zweiter Einstieg `main_physio.dart` (W-A).
- **O-4** Pfad aus Physio-Phasen mit geplanten Wochen; aktuelle Phase setzt der Physio; Units werden nur durch Training erledigt; Streak und Freezes bleiben.
- **O-10** „Heute“ ohne KI: Übungen der aktuellen Phase der Reihe nach, bis die Zeitwahl gefüllt ist; Tauschen aus dem Rest der Phase.
- **O-9** „Alles löschen“: alle Patientendaten und das Konto; Einträge des Physios bleiben bei der Praxis ohne Verbindung zum Patienten.
- **N-1** Neubindung: Chat bleibt beim alten Gerät und wird gelöscht; Plan, Verlauf, Befinden bleiben; Hinweis bei jeder Neuanmeldung.
- **N-2** Warnzeichen aus dem Chat (auch Krise) gehen ohne Text an den Physio; die Einwilligung nennt das.
- **N-3** Ersatzprogramm bei hohem Schmerz: Kürzung nach fester Regel mit Hinweis (KI-Plan 4.2.3).
- **N-4** Jeder Physio sieht alle Patienten seiner Praxis.
- **N-6** Keine globale Einlöse-Bremse; nur je Sitzung (5 Fehlversuche je 15 Minuten).
- **N-7** Code 10 Zeichen Crockford-Base32 mit HMAC und Pepper; Dauer-Schätzregel (8.4); Kürzungsregel E-36, Zahlenverbot E-37.
- Übrige Vorschläge aus v1.2 (O-1–O-3, O-5–O-8, O-11, O-12, O-14–O-16) gelten als Annahmen.

**2026-10-14 (neu):**
- **N-9** Produktdokumente Training/Check-up, Physio-Bereich und Feed sind freigegeben (T-1–T-6, C-1–C-3, PB-1–PB-9, F-1–F-4).
- **N-10** C-3 präzisiert: Stimmung wird nur erfasst und dem Physio gezeigt. Bei sehr schlechter Stimmung an 5 Tagen in Folge bekommt der Physio eine Nachricht (Warnzeichen ohne Details), **mehr nicht**, keine Reaktion gegenüber dem Patienten. Die Schwelle „sehr schlecht“ ist inzwischen entschieden (N-14, O-2a).
- **N-11** Design-Brief v2 freigegeben; Smileys im Prototyp als Emoji; Thema-Override System/Hell/Dunkel im Profil; „Transparenz reduzieren“ als App-Schalter plus Hoher Kontrast (kein iOS-Plattformaufruf).
- **N-12** Reihenfolge: **Das Redesign (Umbau aller bestehenden Screens und Goldens auf Brief v2 inkl. neuer Leiste/Navigation, Tageszeit-Welt, Manny – seit N-15 mit den finalen Grafiken statt Platzhaltern) ist die erste Lieferung von Ausschnitt 2**; danach entstehen alle neuen Screens direkt im neuen Look.
- **N-13** Physio-KI (PB-5) erst in Ausschnitt 3 (KI-Plan v2.5); Feed erst ab Ausschnitt 4.
- **N-14 Offene Werte entschieden (2026-10-14; in v2.1 in alle Abschnitte eingearbeitet):**
  - **O-17:** „Zeit“ einer Übung = **Dauer je Satz in Sekunden** (`duration_sec`). Zusätzlich bestätigt: (a) die Schätzregel N-7 nutzt die Pause des Physios (`pause_sec`), ohne Angabe weiter 60 s (8.4); (b) die Kürzung E-36 halbiert die Dauer je Satz in Sekunden: `max(1, abrunden(Dauer / 2))` (8.7, KI-Plan 4.2.3).
  - **O-18:** Schwellung **bleibt** als 6. Frage im Tages-Check-up (0–3), feste Spalte `swelling`.
  - **O-19:** Einschränkungen als **Einzelwert-Skala keine / leicht / deutlich / stark** (ein Wert, keine Bereichsliste).
  - **O-2:** Warnzeichen bei **Schmerz ≥ 7**, **Anstieg ≥ 3 gegenüber dem Check-up des Vortags** (kein Check-up am Vortag → keine Anstiegsregel), **Schwellung „stark“** (3 von 3). Bei starker Schwellung sieht der Patient **denselben festen Hinweis** wie bei hohem Schmerz (`notify_patient = true`). Die Werte sind entschieden, nicht vorläufig.
  - **O-2a:** „Sehr schlechte Stimmung“ = Smiley **1 oder 2** (Skala 1–5, 1 = sehr schlecht; `mood_max = 2`).
  - **O-2b:** 5 aufeinanderfolgende Kalendertage mit Check-up und Stimmung ≤ 2 → Nachricht an den Physio; **an jedem weiteren solchen Tag erneut** eine Nachricht; **ein Tag ohne Check-up unterbricht die Kette**. Der Patient erfährt nichts (`notify_patient = false`).
  - **E-28:** Kürzung des Tagesprogramms **ab Schmerz 6** (Schmerz ≥ 6; liegt unter der Warnschwelle 7).
- **N-15 Manny (2026-10-14):** Manny bekommt finale, vom Nutzer gelieferte Grafiken in zwei Varianten **mit Brille / ohne Brille** (je Posen Normal, Freudig, Traurig und Kopf; weitere Posen fallen auf diese zurück). Der Patient wählt die Variante **im Onboarding** (eigener Schritt „Wie soll Manny aussehen?“) und kann sie **im Profil** jederzeit ändern. Die Rechte liegen beim Nutzer; Manny ist **kein Platzhalter** mehr. Die Rechtefrage bleibt nur für die 3D-Objekte (Flamme, Stern, Pokal) offen. Gestaltung: `docs/design/design-brief-v2-ergaenzung-1.md` (**FREIGEGEBEN 2026-10-14**; ersetzt Brief-Abschnitt 6), Bilder: `docs/design/manny/`. Alles in **L1** (3.5); seit N-16 kommt die Speicherung im Konto in L2/L3 dazu.
- **N-16 Entscheidungen zum Re-Review (2026-10-14; in v2.2 eingearbeitet):**
  - **O-41:** Der Manny-Look wird **zusätzlich im Konto (Backend) gespeichert**, damit er beim Gerätewechsel erhalten bleibt: Spalte `patients.manny_look`, Schreibrecht nur für den Patienten selbst über die Definer-Funktion `set_manny_look`, Synchronisation über die Warteschlange; **lokal bleibt die Quelle für die Anzeige**; vor der Bindung nur lokal, bei der Bindung wird der lokale Wert übertragen. L1 bleibt ohne Backend; Spalte und Funktion in L2, App-Anbindung in L3 (3.5, 6.2, 6.4, 8.1). „Alles löschen“ erfasst den Wert (6.13).
  - **O-42:** „Nächstes Ziel“ in Kachel 6 = Titel der nächsten Phase (6.12).
  - **O-43:** Im Code-Start steht der Look-Schritt **vor dem Code-Feld** (3.7 Teil A, 8.1).
  - **R2-24 bestätigt:** Nachträgliche Warnzeichen durch verspätete Check-ups sind gewollt (6.9).
  - **Vorschau vorbereiteter Übungen bestätigt:** Der Patient liest Übungen (und ab L8 deren Bilder) aktiver **und** vorbereiteter Positionen seines aktuellen Plans über die API (6.7 Nr. 2, 6.11).
  - **Zählweise je Verletzung:** Stimmungskette (O-2b) und Anstiegsregel (Vortag) zählen **je Verletzung**; mit einer neuen Verletzung beginnt die Zählung neu, der Vortag einer anderen Verletzung zählt nicht (6.9).
  - **Zusammenfassen:** Entstehen durch einen verspäteten Check-up mehrere Stimmungs-Warnzeichen auf einmal, bleibt es je Tag ein Warnzeichen; der Physio bekommt für diesen Eingang **eine gemeinsame Meldung** (6.9, 6.12, 9).

**Blockierende offene Punkte (Stand v2.2; vollständig in Abschnitt 14):**

| Punkt | blockiert |
|---|---|
| Brief-Ergänzung F2-D2 (Screens, die Brief v2 nicht gestaltet, und Brief-Folgen aus N-14, 3.7) | L3, L5, L6, L7 (jeweils der passende Teil) |
| E-7, E-15, E-27, E-31 | nur Ausschnitt 3 (KI-Plan) |
| E-30 leichtere Variante | nicht blockierend für Ausschnitt 2 (ohne Entscheidung bietet „Schmerz melden“ nur den Abbruch); Schema-Entscheidung **vor L2 empfohlen** |
| O-44 Manny-Look bei Neubindung auf neuem Gerät: Konto-Wert oder im Code-Start gewählter Wert? | L3 (Annahme B-36: Konto-Wert gewinnt) |

O-17, O-18, O-19, O-2 (inkl. O-2a, O-2b) und E-28 blockieren nichts mehr (N-14); O-41, O-42, O-43 sind entschieden (N-16).

---

## 1. Kurzfassung

| Thema | Plan v2.2 |
|---|---|
| Lieferungen | **L1 Redesign** → L2 Backend-Kern → L3 Patienten-App am Backend → L4 Training (Session, Check-up nach der Einheit) → L5 Tages-Check-up, Stimmungs-Nachricht, Kürzung, Frage an den Physio → L6 Physio-Grundgerüst (Liste, neuer Patient, Plan, Akte) → L7 Physio-Patientenübersicht (Kacheln, Notizen, Fragen, Historie) → L8 Übungs-Baukasten mit Bildern → L9 Ende-zu-Ende, Kriterienbericht, Gesamtreview |
| Backend | Supabase EU: Postgres mit RLS, Supabase Auth, **Storage nur für Übungsbilder** (neu, L8). **Keine Edge Functions in Ausschnitt 2** |
| Rollenmodell | unverändert (6.1): Eigentümer = Migrationsrolle, RLS **ohne `FORCE`**, Standardrechte entzogen, Definer-Funktionen mit `search_path = ''` und eigener Rechteprüfung, Sichten nur `security_invoker = true` |
| Datenmodell | 26 Tabellen (6.2), Praxis trennt Physios, Patient sieht nur sich, jeder Physio sieht alle Patienten seiner Praxis (N-4); „Hauptphysio“ ist nur Zuordnung für den Reiter „Meine Patienten“, kein Zugriffsrecht |
| Auth | Physio E-Mail + Passwort, keine Selbstregistrierung; Patient anonyme Sitzung ohne Rechte bis `redeem_invitation` (unverändert) |
| Neuer Patient | Vorname + Verletzung oder Vorlage → ein RPC-Aufruf → sofort QR, Link, „Teilen“ (6.6) |
| Patienten-App | Start mit Code → Einwilligung → Pfad aus Phasen → Heute (Check-up-Karte, Liste mit Bild/Material/Ort, Abhaken, „Training starten“) → Session → Check-up nach der Einheit; Chats (Manny angeheftet), Profil (Darstellung, Frage an meinen Physio, Deine Daten) |
| Physio | Patienten (Reiter Meine/Praxis, Suche, Warnmarker) · Übungen (Baukasten) · Chats (Platzhalter) · Konto; Handy und Rechner |
| Offline | Lesen aus Zwischenspeicher, Schreiben über persistente Warteschlange; Session läuft offline vollständig |
| Verifikation | Standard-Prüfung, Goldens (nach Nutzerfreigabe), Matrix, `shoot.mjs`/`nav_checks.mjs` (Patient und Physio), DB-Tests gegen lokales Postgres 16 mit Supabase-Rollen-Nachbildung, Storage-/E2E-Tests erst mit lokalem Supabase-Stack (X2-8) |

---

## 2. Lieferungen und Paketschnitt

### 2.1 Regeln für alle Lieferungen
1. **Lauffähig:** Nach jeder Lieferung startet `main.dart` (und ab L6 `main_physio.dart`), die Standard-Prüfung aus `KONVENTIONEN.md` ist grün, Goldens und Matrix sind grün (neue Goldens erst nach Nutzerfreigabe).
2. **Einzeln reviewbar:** Jede Lieferung hat einen abgegrenzten Schreibbereich, eigenes Review (`reviewer`) und – wenn sie Oberfläche ändert – eine Design-Abnahme (`ui-designer`), beide read-only und parallel. Lieferungen mit Migrationen bekommen zusätzlich ein Sicherheitsreview der Migrationen, **bevor** App-Code darauf aufbaut.
3. **Pflichtliste je neuer Tabelle mit Patientendaten** (6.14): Schreibsperre, Löschumfang, Rechte-Inventar DB-T01, Praxis-Isolation DB-T06, Patient-nur-selbst DB-T08 werden in derselben Lieferung erweitert.
4. **Fake-Repositories:** Jede Lieferung, die Backend-Daten zeigt, ergänzt die Fake-Repositories und Szenarien (`lib/dev/`, `scenarios.json`), damit Matrix, Goldens und `nav_checks.mjs` ohne Backend laufen.
5. Pakete einer Lieferung laufen **nacheinander** (gemeinsame Dateien), außer ausdrücklich parallel markiert.
6. Commit/Zwischensicherung nur nach verifiziertem Paket und nur, wenn der Orchestrator es freigibt.

### 2.2 Übersicht

| Lieferung | Ergebnis (lauffähig) | Pakete | Abhängigkeit | Verifikation | Blockiert durch |
|---|---|---|---|---|---|
| **L1 Redesign-Migration** | Ausschnitt-1-App vollständig im Look von Brief v2: Welt, Thema Hell/Dunkel, Glas, neue Leiste mit 4 Zielen, Manny-Knopf, **Manny mit finalen Grafiken in beiden Varianten (mit/ohne Brille), Look-Schritt im Onboarding (5 Schritte), Profil-Zeile „Manny-Look“** (N-15, Brief-Ergänzung 1), Profil mit „Darstellung“, Chats mit Manny angeheftet; alle Goldens neu | F2-R1, F2-R2, F2-R3, F2-R4, F2-L1R | – | 3.6 | – |
| **L2 Backend-Kern** | Migrationen für Rollen, Praxen, Physios, Patienten, Verletzungen, Einladung, Übungen (inkl. Baukasten-Felder), Vorlagen, Pläne, Akte, Einwilligung, Training (`training_sessions` mit allen Spalten inkl. `mode`, `exercise_results`), `create_patient`, `regenerate_invitation`, Spalte `patients.manny_look` mit `set_manny_look` (O-41); gemeinsame Fixtures `local_day`; Seed; DB-Tests | F2-1, F2-1R, F2-2 | F2-1/F2-1R: – (parallel zu L1, schreiben nur unter `supabase/` und `.gitignore`); **F2-2: nach L1** (schreibt `app/tool/seed/`, `app/pubspec.yaml`, `app/pubspec.lock`) | DB-Tests (12.2), Seed lokal (X2-8) | – (O-17 entschieden) |
| **L3 Patienten-App am Backend** | Start mit Code, Einwilligung, Neubindung, Pfad aus Phasen, Heute aus dem Plan mit Abhaken (Ablauf 3 ohne Check-up), Übungsdetail, Tauschen, Akte, „Alles löschen“ mit Backend, Warteschlange, Manny-Look im Konto (Übertragung bei Bindung, Synchronisation, O-41), Demo-Modus | F2-3, F2-4a, F2-4b, F2-L3R | L1, L2, F2-D2 Teil A | U/W/C, Goldens, Matrix, `nav_checks` | F2-D2 Teil A |
| **L4 Training** | „Training starten“: Packliste, geführte Session mit Zähler, Halte-/Dauer-/Pausen-Timer, Gesamtzeit, Pause, Überspringen, Beenden, Schmerz melden, Zusammenfassung; Check-up nach der Einheit (auch nach „Fertig für heute“) | F2-5a (Migration), F2-5b, F2-5c, F2-L4R | L3 | DB-Tests, U (Timer/Session mit fester Uhr), W, Goldens, Matrix, `nav_checks` | (E-30 nur für die Variante) |
| **L5 Check-ups und Frage an den Physio** | Tages-Check-up-Karte, Warnzeichen-Trigger inkl. Stimmungs-Nachricht (5 Tage), Kürzung bei Schmerz (E-36), „Frage an meinen Physio“ mit Status | F2-6a (Migration), F2-6b, F2-6c, F2-L5R | L4, F2-D2 Teil B | DB-Tests, U, W, Goldens, Matrix | F2-D2 Teil B (inkl. Brief-Folgen aus O-18/O-19, 3.7) |
| **L6 Physio-Grundgerüst** | `main_physio.dart` responsiv (Leiste/Seitenleiste), Anmeldung, Konto, Chats-Platzhalter, Patientenliste mit Reitern, Suche, Hauptphysio, Warnmarker; Neuer Patient in 30 s mit QR/Link/Teilen/Vorlage; Plan-Editor; Akte-Pflege | F2-7a (Migration), F2-7b, F2-7c, F2-7d, F2-L6R | L2, L5 (Warnmarker), F2-D2 Teil C | DB-Tests, W, Goldens, Matrix Handy + Rechner, `nav_checks` Physio, Ablaufprüfung < 30 s | F2-D2 Teil C |
| **L7 Physio-Patientenübersicht** | Kopf-Karte, Kacheln 2–8 mit Details, Notiz, Fragen „besprochen“, Historie über Verletzungen, neue Verletzung, `seen_at` | F2-8a (Migration), F2-8b, F2-8c, F2-L7R | L6, L4, L5, F2-D2 Teil D | DB-Tests, W, Goldens, Matrix (Rechner ohne Scrollen), `nav_checks` | F2-D2 Teil D |
| **L8 Übungs-Baukasten** | Ziel „Übungen“, Baukasten mit allen Feldern, Bilder hochladen (Storage), „Damit anfangen“, Zuweisung an Patienten mit Phase; Bilder beim Patienten in Liste, Detail, Session | F2-9a (Migration + Storage), F2-9b, F2-9c, F2-L8R | L6, L4 | DB-Tests, Storage-Tests (Stack), W, Goldens, Matrix | O-24 (Annahme möglich), X2-8 für Storage-Tests |
| **L9 Abschluss** | Ende-zu-Ende gegen lokalen Supabase-Stack, Stack-Wiederholung ausgewählter DB-Tests, Kriterienbericht v2, Gesamtreview und Design-Abnahme | F2-10, F2-R | L1–L8, X2-8 | E2E, Kriterienbericht | X2-8 |

Querpaket **F2-D2 Brief-Ergänzung v2-1** (`ui-designer`, Ablauf C): gestaltet, was Brief v2 nicht enthält (Liste 3.7). Teil A vor L3, Teil B vor L5 (enthält die Brief-Folgen aus N-14, freigabepflichtig), Teil C vor L6, Teil D vor L7; Start parallel zu L1/L2. Manny ist nicht Teil von F2-D2 (bereits durch Brief-Ergänzung 1 gestaltet und freigegeben).

Querpaket **F2-0 Entscheidungen** (Nutzer/Orchestrator): O-17, O-2/O-2a/O-2b, E-28, O-18, O-19 sind **erledigt** (N-14); übrige nicht blockierend (Annahmen, 14).

### 2.3 Pakete im Einzelnen

| Paket | Inhalt | Rolle | Abhängigkeit | Verifikation |
|---|---|---|---|---|
| F2-R1 | Tokens 3.1–3.6 (Welt je Tageszeit, Inhaltsflächen Hell/Dunkel, Typografie, Radien, Tiefe, Bewegung) in `lib/theme/*`; reine Weltfunktion `lib/logic/world_time.dart` (Phase und Mischung aus fester Uhr); `glow.dart` entfernen; `CuraBlur` mit Zähler bis 3; Darstellungs-Einstellungen (Welt, Thema, Transparenz reduzieren, Ton, Vibration) als lokaler Speicher; Zustandsfeld `mannyLook` mit Schema-Sprung 1 → 2 (3.5); `WorldBackground` als Ersatz von `GlowBackground` an allen Verwendungsstellen, damit die App lauffähig bleibt | `flutter-developer` | – | U Weltfunktion (V2-6), Kontrasttests V2-3/V2-4, Token-/Regeltests `test/static`, Standard-Prüfung |
| F2-R2 | Komponenten aus Brief 4: `HeaderCard`, `GlassCard`, `OrbNode`, `FloatingNav` (Ruhe/Aktiv), `PrimaryPill`, `GlassPill`, `CuraChip`/`StatusChip`, `Sheet`, `Dialog`, `Snackbar`, `MannyIllustration`/`MannyButton`/`MannyBubble` aus den **finalen PNGs beider Varianten** (Assets unter `app/assets/manny/`, zentrale Posen-Abbildung, Halo in Nacht, Kopf auf heller Scheibe; Brief-Ergänzung 1, 6.2–6.6), Auswahlkarten „Manny-Look“, Umbau der Bestandskomponenten laut Brief 10 und Ergänzung 1, 10 | `flutter-developer` | F2-R1 | Komponententests, Komponenten-Goldens (Welten × Thema × Hoher Kontrast, Manny je Variante), V2-10/11/12/18/23/31/32/33, V2-56 (ersetzt), V2-69–V2-74 |
| F2-R3 | `HomeShell` mit 4 Zielen und Leisten-Sichtbarkeit je Route; Manny-Knopf; `ActionCluster` und `MessagesButton` entfallen; Pfad (Kugeln, Kopf-Karte, Manny neben aktueller Kugel); Chats (Manny angeheftet, Beispieldaten gekennzeichnet); Profil inkl. „Darstellung“ und Zeile „Manny-Look“ mit Sheet (Ergänzung 1, 6b) | `flutter-developer` | F2-R2 | W, Szenario-Goldens, Matrix, `nav_checks` (neue Tab-Wege), V2-68 |
| F2-R4 | Heute (Optik Brief 7.2, Verhalten Ausschnitt 1), Onboarding mit neuem Schritt 1 „Wie soll Manny aussehen?“ (5 Schritte, Ergänzung 1, 6a) und „Deine Daten“ in neuer Optik; Restbausteine; alle Szenario-Goldens neu; `shoot.mjs` in 4 Welten; Kriterien-Selbstprüfung V2 | `flutter-developer` | F2-R3 | Goldens, Matrix, `shoot.mjs`, `nav_checks`, Web-Build, V2-65–V2-67, V2-75 |
| F2-L1R | Review (Code) ∥ Design-Abnahme gegen Brief v2 und Brief-Ergänzung 1 | `reviewer` ∥ `ui-designer` | F2-R4 | Befundliste → Korrekturpaket |
| F2-D2 | Brief-Ergänzung v2-1 (Teile A–D, 3.7) | `ui-designer` | – | Nutzerfreigabe |
| F2-1 | Migrationen 01–07 (Kern, inkl. `create_patient`, `regenerate_invitation`, `training_sessions` vollständig, `patients.manny_look` und `set_manny_look`), Nachbildung, gemeinsame Fixtures `supabase/tests/fixtures/local_day/` (6.7 Nr. 5, MINOR-E), DB-Tests der Lieferung L2 (12.2), `.gitignore`-Einträge (5) | `flutter-developer` | – (O-17 entschieden) | `supabase/tests/run_local_pg.sh` |
| F2-1R | Sicherheitsreview Rollen, RLS, Definer, Einladung, Neubindung, Löschen, neue Kern-Tabellen | `reviewer` | F2-1 | Befundliste |
| F2-2 | Seed + Testdaten (10); Dev-Abhängigkeit `supabase` in `app/pubspec.yaml` | `flutter-developer` | F2-1R **und** F2-L1R (L1 abgeschlossen; gemeinsame Dateien `app/pubspec.yaml`/`.lock`, MAJOR-1) | DB-T40 (Stack), lokaler Lauf gegen Postgres soweit ohne Auth-Admin möglich |
| F2-3 | Datenschicht App: Repositories, Zwischenspeicher, Warteschlange, Zustandsmigration, `AccountDeleter`, reine Logik (`plan_today`, `path_from_phases`, `exercise_duration`, `invite_code`, `outbox` inkl. `manny_look_set` und zurückgestellter Einträge); Dart-Tests lesen die Fixtures aus `supabase/tests/fixtures/local_day/` (nur lesend) | `flutter-developer` | L1, F2-1R | U, C |
| F2-4a | Start mit Code (Look-Schritt vor dem Code-Feld, O-43), Einwilligung, Neubindung (beide Geräte), Manny-Look bei Bindung übertragen bzw. übernehmen (8.1), Löschen mit Backend, Demo-Modus | `flutter-developer` | F2-3, F2-D2 A | W, Goldens, Matrix, `nav_checks` |
| F2-4b | Pfad aus Phasen (inkl. „ausgelassen“, Leerzustand), Heute aus dem Plan mit Abhaken, Übungsdetail, Tauschen, Akte („Mein Plan und meine Verletzung“) | `flutter-developer` | F2-4a | U, W, Goldens, Matrix, `nav_checks` |
| F2-5a | Migration Check-up nach der Einheit (`session_checkups`, `session_checkup_items`, `submit_session_checkup`), DB-Tests; `training_sessions` ist seit L2 vollständig (MINOR-3) | `flutter-developer` | L3 | DB-Tests |
| F2-5b | Session: Packliste, Übungsbildschirm, `RepCounter`, Timer, Pause/Überspringen/Beenden/Schmerz melden, Hintergrund und Sperre, Mitternacht, Ton/Vibration | `flutter-developer` | F2-5a | U (Session-Zustandsautomat, Timer mit fester Uhr), W, Goldens, Matrix |
| F2-5c | Zusammenfassung, Check-up nach der Einheit (Session und „Fertig für heute“), `RatingScale` | `flutter-developer` | F2-5b | W, Goldens, Matrix, `nav_checks` |
| F2-6a | Migration `daily_checkups` (inkl. `swelling`, `limitations` als Skala), `warning_rules` (entschiedene Werte O-2), `warning_signs`, Trigger inkl. Anstiegs- und Stimmungsregel (reihenfolgeunabhängig, je Verletzung, `trigger_checkup_id` für die gemeinsame Meldung, 6.9), `submit_daily_checkup`, `patient_questions`, `ask_physio` | `flutter-developer` | L4 | DB-Tests |
| F2-6b | `DailyCheckupCard` (6 Fragen), `PainSlider`, Kürzung bei Schmerz ab 6 (`fallbackToday` mit Schmerzzweig), Hinweis „Heute etwas kürzer“, fester Hinweis bei Schmerz- und Schwellungs-Warnzeichen | `flutter-developer` | F2-6a, F2-D2 B | U, W, Goldens, Matrix |
| F2-6c | „Frage an meinen Physio“ (Profil-Zeile mit Zahl offener, Eingabe, Liste mit Status), Einwilligungstext-Version `physio_sharing-2` | `flutter-developer` | F2-6a, F2-D2 B | W, Goldens, Matrix |
| F2-7a | Migration `set_main_physio`; DB-T48, DB-T49 (`create_patient`, `regenerate_invitation` und Vorlagen-Lesezugriff liegen seit v2.1 in L2, MINOR-2) | `flutter-developer` | L2 | DB-Tests |
| F2-7b | Physio-Shell responsiv, Anmeldung, Konto, Chats-Platzhalter, Patientenliste | `flutter-developer` | F2-7a, F2-D2 C | W, Goldens, Matrix (390×844, 1024×768, 1280×800) |
| F2-7c | Neuer Patient in 30 s, QR/Link/Teilen, neuer Code | `flutter-developer` | F2-7b | W, Ablaufprüfung, Goldens |
| F2-7d | Plan-Editor (Phasen, Wochen, aktuelle Phase, Positionen mit Grenzen, Freischaltung, Vorlage übernehmen), Akte-Pflege | `flutter-developer` | F2-7c | W, DB-Tests (save_plan), Goldens, Matrix |
| F2-8a | Migration `practice_notes`, `mark_question_discussed`, `start_new_injury`, `close_injury` (O-29), Kachel-Sichten, `mark_warnings_seen`; DB-Tests | `flutter-developer` | L6 | DB-Tests |
| F2-8b | Patientenübersicht: Kopf-Karte, Kacheln 2–8, Details (Sheet am Handy, Seitenpanel am Rechner), Slot Kachel 1 leer | `flutter-developer` | F2-8a, F2-D2 D | W, Goldens, Matrix (Rechner ohne Scrollen) |
| F2-8c | Notiz, Fragen „besprochen“, Historie, neue Verletzung | `flutter-developer` | F2-8b | W, Goldens, Matrix, `nav_checks` |
| F2-9a | Migration Storage-Bucket und -Policies, `exercise_images`, `assign_exercise`; DB-Tests (Policies auf `storage.objects` nur gegen Stack) | `flutter-developer` | L6, O-24 | DB-Tests, Stack-Tests (X2-8) |
| F2-9b | Ziel „Übungen“ (Liste Katalog + Praxis), Baukasten-Formular mit allen Feldern, „Damit anfangen“, Zuweisung | `flutter-developer` | F2-9a | W, Goldens, Matrix |
| F2-9c | Bilder: Auswahl/Upload im Baukasten, Anzeige beim Patienten (Liste, Detail, Session) mit Illustration als Rückfall | `flutter-developer` | F2-9b | W, Goldens, Stack-Test Upload/Download |
| F2-L3R … F2-L8R | Review ∥ Design-Abnahme je Lieferung; bei Migrationen vorab Sicherheitsreview der Migrationen (Teil des jeweiligen R-Pakets, vor dem App-Paket) | `reviewer` ∥ `ui-designer` | jeweils letzte Pakete | Befundliste |
| F2-10 | E2E gegen lokalen Supabase-Stack, Stack-Wiederholung (12.2), Kriterienbericht v2 | `flutter-developer` | L1–L8, X2-8 | E2E, Bericht |
| F2-R | Gesamtreview + Design-Abnahme | `reviewer` ∥ `ui-designer` | F2-10 | Befundliste |

Reihenfolge: (F2-D2 ∥ L1 ∥ F2-1 → F2-1R) → F2-2 → L3 → L4 → L5 → L6 → L7 → L8 → L9. **Parallel** laufen nur L1 (schreibt unter `app/`) und F2-1/F2-1R (schreiben unter `supabase/` einschließlich der gemeinsamen Fixtures `supabase/tests/fixtures/local_day/` und die Stamm-`.gitignore`); diese Bereiche sind getrennt, auch für Formatter und Generatoren (`dart format` läuft nur über `app/lib`, `app/test`). F2-2 (Seed) schreibt unter `app/` (`tool/seed/`, `pubspec.yaml`, `pubspec.lock`) und läuft deshalb **erst nach L1** (MAJOR-1). Ab F2-2 nacheinander.

---

## 3. Lieferung L1: Redesign-Migration

### 3.1 Ziel und Grenze
Die Ausschnitt-1-App (Onboarding, Pfad, Heute, Deine Daten, Manny-Chat nur ansehen, Nachrichten-Platzhalter) wird vollständig auf Brief v2 umgestellt. **Verhalten, Texte und Abläufe aus Ausschnitt 1 bleiben**, soweit Brief v2, Abschnitt 2 sie nicht ersetzt. Kein Backend, keine neuen Funktionen außer denen, die Brief v2 für die bestehenden Screens verlangt (Leiste, Manny-Knopf, Profil, Darstellung, Chats-Liste), und der Manny-Look-Wahl aus N-15 (Onboarding-Schritt, Profil-Zeile; Brief-Ergänzung 1).

### 3.2 Zuordnung Brief 10 → Pakete

| Gebaut (Brief 10) | Paket | Hinweis |
|---|---|---|
| `lib/theme/*` (Farben, Rollen, Typo, Motion, Glow) | F2-R1 | `glow.dart` entfällt; `cura_blur.dart` zählt bis 3; neue Tokens nur in `lib/theme/` (Regel 1) |
| `glow_background.dart`, `cura_blur.dart` | F2-R1 | `WorldBackground` (eine gecachte Ebene, `RepaintBoundary`, `ExcludeSemantics`) |
| `floating_nav.dart`, `action_cluster.dart`, `messages_button.dart`, `manny_chat_button.dart` | F2-R2 (Bausteine), F2-R3 (Einbau) | Leiste 4 Ziele, Manny-Knopf nur auf Pfad und Heute, Cluster entfällt |
| `glass_card.dart`, `category_card.dart`, `choice_card.dart`, `cura_chip.dart`, `cura_dialog.dart`, `cura_snackbar.dart`, `date_card.dart`, `cura_text_field.dart` | F2-R2 | Optik 3.2/3.5 |
| Manny laut Migrationsliste Brief-Ergänzung 1, 10: `manny.dart` (Painter entfällt, PNG nach Variante, Pose, Crop), `lib/logic/manny_occasions.dart` (zentrale Posen-Abbildung), `manny_bubble.dart`, `manny_chat_button.dart`, `chat_avatar.dart`, `chat_message_list.dart`, `manny_chat_screen.dart`, `path_view.dart`, `onboarding_manny.dart`, `cura_metrics.dart` (Größen), `lib/dev/scenarios.dart` (Posen-Szenario) | F2-R2 (Bausteine), F2-R3 (Einbau) | 3.5 |
| `app/pubspec.yaml`, `app/assets/manny/` | F2-R2 | Kopie aus `docs/design/manny/{brille,ohne}/` inkl. `2.0x/`, `3.0x/`; Verzeichnisse als Assets deklariert |
| `lib/logic/app_state.dart`, `profile.dart`, `lib/logic/migrations.dart`, `lib/data/data_eraser.dart` | F2-R1 (Feld, Schema), F2-R4 (Onboarding) | Feld `mannyLook`, Schema 1 → 2, Zurücksetzen beim Löschen (3.5) |
| `lib/ui/path/*`, `path_node.dart`, `path_header.dart` | F2-R3 | `OrbNode`, `HeaderCard` |
| `lib/ui/home/home_shell.dart`, `lib/ui/routes/*` | F2-R3 | 4 Ziele, Scroll-Position je Tab, Leiste nicht in Vollbild/Onboarding/Sheets |
| `lib/ui/messages/*`, `lib/ui/chat/*` | F2-R3 | Ziel „Chats“, Manny angeheftet |
| neu: Profil, Darstellung | F2-R3 | 3.4 |
| `lib/ui/today/*` | F2-R4 | Optik 7.2; Verhalten Ausschnitt 1 („Training eintragen“) bleibt bis L3; Check-up-Karte, Session, Abhaken kommen in L3–L5 |
| `lib/ui/onboarding/*` (`onboarding_flow.dart`, `step1_name.dart` … `step4_date.dart`), `lib/ui/data_sheet/*` | F2-R4 | Optik; Onboarding bekommt Schritt 1 „Wie soll Manny aussehen?“ (5 Schritte, Ergänzung 1, 6a), sonst bleibt das Verhalten; Onboarding wird in L3 durch den Code-Start ersetzt, bleibt aber für den Demo-Modus (B-20); der Look-Schritt geht in den Code-Start mit, vor das Code-Feld (8.1, O-43 entschieden) |
| Goldens `test/golden/goldens/*` | F2-R2 (Komponenten), F2-R4 (Szenarien) | alle neu; `glow.png` entfällt (3.6); `manny_poses.png` je Variante, Look-Schritt (Hell, Dunkel, 200 % Schrift, 320 dp) laut Ergänzung 1, 10 |
| Tests Onboarding (Schrittzahl, Reihenfolge, Persistenz), Migration, `manny_occasions` | F2-R1/F2-R2/F2-R4 | an 5 Schritte, Schema-Sprung und neue Posen-Abbildung anpassen |
| Tests `test/theme`, `test/static`, `test/components` | F2-R1/F2-R2 | auf neue Werte umstellen |

### 3.3 Navigation in Ausschnitt 2 (Feed-Frage geklärt)
- **Patient:** Pfad · Heute · Chats · Profil. **Kein Feed-Ziel und kein Platzhalter** in Ausschnitt 2: Brief v2, Abschnitt 5 („Feed ab Ausschnitt 4, davor 4 Ziele ohne Lücke“) und 7.12 („bis dahin fehlt das Ziel ohne Platzhalter“). Die Leiste ist so gebaut, dass ein fünftes Ziel ohne Umbau an Position 3 eingefügt werden kann (Ziele als Liste, V2-15). Hinweis: Im Auftrag stand „Feed nur Platzhalter“; der freigegebene Brief sagt „ohne Platzhalter“. Der Plan folgt dem Brief (Rückfrage O-33, nicht blockierend).
- **Manny-Zugang:** Tipp auf Manny im Pfad, Manny-Knopf (Pfad, Heute), angehefteter Eintrag in Chats; keine zusätzliche Fokusstation (V2-21).
- **Zurück:** Tab-Wechsel behält Scroll-Position je Tab; Android-Zurück wie Ausschnitt 1 (Heute → Pfad; Pfad: erst Blase/Hinweis schließen).

### 3.4 Profil und Darstellung in L1
- Profil zeigt Kopf-Karte (Avatar-Initiale, Name, „Verletzung · Phase · Woche“ aus dem lokalen Zustand), drei Kacheln (Streak, Trainingstage, Freezes), Liste.
- Listenzeilen in L1: **Deine Daten** (bestehendes Sheet), **Manny-Look** (N-15; Lage, Sheet und Verhalten laut Brief-Ergänzung 1, 6b), **Darstellung**, **Hilfe und Datenschutz** (bestehende Datenschutz-Seite). **Mein Plan und meine Verletzung** kommt mit L3 (Akte), **Frage an meinen Physio** mit L5. **Erinnerungen:** keine Spezifikation, Push ist ausgeschlossen (Spec 8) → Zeile entfällt bis zur Klärung (O-23).
- **Darstellung:** Welt (Automatisch/Morgen/Mittag/Abend/Nacht), Thema (System/Hell/Dunkel, N-11), Transparenz reduzieren (App-Schalter, N-11), Ton, Vibration (Standard an, B-17). Speicher: neuer Schlüssel `curaone.display.v1` (in `kAllStorageKeys`, wird von „Alles löschen“ entfernt, B-21). Ton und Vibration wirken erst ab L4.

### 3.5 Manny: finale Grafiken und Look-Wahl (N-15, Brief-Ergänzung 1)
Manny ist kein Platzhalter mehr. Gestaltung, Maße, Posen-Zuordnung, Halo und Scheibe, Onboarding-Schritt und Profil-Zeile gelten im Wortlaut von `docs/design/design-brief-v2-ergaenzung-1.md` (FREIGEGEBEN 2026-10-14); dieser Abschnitt plant nur die Umsetzung. Alles in **L1**.
- **Assets:** Kopie der 24 Dateien aus `docs/design/manny/{brille,ohne}/` (normal, freudig, traurig, kopf; 1x, `2.0x/`, `3.0x/`) nach `app/assets/manny/{brille,ohne}/`; in `app/pubspec.yaml` die Verzeichnisse `assets/manny/brille/` und `assets/manny/ohne/` deklarieren (Flutter wählt die Dichte-Varianten selbst). Quelle und Erzeugungsskript bleiben unter `docs/design/manny/`; die App ändert die Bilder nicht. Kein Platzhalter-Hinweis, kein `LIESMICH`-Platzhaltertext; Lizenzhinweis-Eintrag entfällt für Manny (Rechte beim Nutzer, N-15). Die alte Skizze `manny4.py`/`_MannyPainter` entfällt (V2-56 ersetzt).
- **Posen:** eine zentrale Abbildung Anlass → Datei in `lib/logic/manny_occasions.dart` (Tabelle 6.3 der Ergänzung; neue Anlässe fallen auf `normal` zurück). Die gewählte Variante gilt in jeder Pose.
- **Speicherung der Wahl:** Feld `mannyLook` (`brille` · `ohne`) im lokalen App-Zustand (`lib/logic/app_state.dart`/`profile.dart`), gespeichert sofort bei Tipp (Neustart im Onboarding behält die Wahl). **Schema-Sprung 1 → 2** in `lib/logic/migrations.dart` (`kCurrentSchema = 2`): nicht abgeschlossenes Onboarding `step + 1`; `mannyLook = brille` für alle Bestandsdaten; wer das Onboarding abgeschlossen hat, wird nicht erneut gefragt (Ergänzung 1, 10). „Alles löschen“ setzt den Look auf die Vorbelegung „Mit Brille“ zurück und startet das Onboarding bei Schritt 1 (`data_eraser.dart`).
- **Backend (O-41 entschieden, N-16):** In **L1 bleibt der Look nur auf dem Gerät** (kein Backend). Ab L2 gibt es die Spalte `patients.manny_look` (`brille` · `ohne`, `null` = noch nicht übertragen) und die Definer-Funktion `set_manny_look(look)` (nur der gebundene, aktive Patient für die eigene Zeile, 6.4); ab L3 gleicht die App den Wert ab: **lokal bleibt die Quelle für die Anzeige**, jede Änderung im Profil geht über die Warteschlange (`manny_look_set`, 8.11); vor der Bindung nur lokal, bei der Bindung wird der lokale Wert übertragen (8.1; Neubindung auf neuem Gerät B-36/O-44). „Alles löschen“ setzt den Konto-Wert auf `null` (6.13). Folge: Nach einem Gerätewechsel steht der Look im Konto bereit.
- **Onboarding:** neuer Schritt 1 „Wie soll Manny aussehen?“, Onboarding 5 statt 4 Schritte, „Mit Brille“ vorbelegt, Weiter immer aktiv (Ergänzung 1, 6a). Ab L3 (Code-Start statt Onboarding, 8.1) bleibt der Look-Schritt Teil des Einstiegs, vor dem Code-Feld (O-43 entschieden).
- **Profil:** Zeile „Manny-Look“ mit Sheet, Wechsel sofort und ohne Neustart an allen Manny-Stellen (Ergänzung 1, 6b).
- **Darstellung:** Halo nur in Welt Nacht für Manny direkt auf der Welt; Kopf immer auf heller Scheibe; Mindestgröße Kopf 40 dp; Bewegung im Code, bei „Bewegung reduzieren“ statisch (Ergänzung 1, 6.2–6.5). Neue Werte (Halo, Scheibe, Größen) als Tokens in `lib/theme/` (Regel 1).
- **Prüfung:** 3.6; Rückverfolgung 13.4 (V2-56 ersetzt, V2-65–V2-75) und 13.5.

### 3.6 Verifikation L1
- Standard-Prüfung (`KONVENTIONEN.md` Regel 5).
- Unit: Weltfunktion an allen Testzeiten aus V2-6 (feste Uhr).
- Kontrasttests V2-3 (Welt-Tabelle 3.1) und V2-4 (Inhaltsflächen 3.2, Worst Case), Rand ≥ 3:1.
- Statisch: kein `Color(0x…)`/keine festen Schriftgrößen außerhalb `lib/theme/` (V2-1), `BackdropFilter` nur in Leiste, Kopf-Karte, Manny-Knopf über `CuraBlur` (V2-11), Mandarine nie als Textfarbe (V2-32), Text-Vorfahren-Regel (V2-5).
- Widget: Blur-Zähler ≤ 3 pro Screen in Welt Abend und Nacht (V2-10), Leiste Ruhe/Aktiv mit fester Uhr (V2-16/18), Transparenz reduzieren/Hoher Kontrast (V2-12), Leisten-Sichtbarkeit je Route (V2-19).
- Manny (3.5): Unit Posen-Abbildung (V2-70) und Migration 1 → 2 mit Fixture `state_v1_onboarding_step2.json` (Schritt +1, Look `brille`) und `state_v1_done.json` (kein Look-Schritt); Widget Onboarding 5 Schritte, Vorbelegung, Zurück/Neustart mit erhaltener Wahl (V2-65–V2-67), Radio-Semantik und Tastatur (V2-66), Profil-Wechsel ohne Neustart mit Asset-Pfad vorher `brille/…`, nachher `ohne/…` (V2-68), Label einmal je Darstellung (V2-71), Dichte-Auswahl bei `devicePixelRatio` 1/2/3 und Größenobergrenzen (V2-72, V2-73), reduzierte Bewegung (V2-74), 200 % und 320×568 (V2-75); statisch: kein `CustomPainter` für Manny, kein „Platzhalter“-Hinweis (V2-56); Renderprobe Halo/Kontur in Nacht (V2-69).
- Goldens: Komponenten in 4 Welten × Hell/Dunkel × Hoher Kontrast; Szenario-Goldens je Screen in einer Grundwelt (Mittag, Hell) plus Pfad und Heute in allen 4 Welten × 2 Themen und jeder Screen einmal mit Hoher Kontrast (**[Vorschlag] Umfang, O-32**). Neue Goldens erst nach Nutzerfreigabe.
- Matrix: bestehende Prüfungen (320×568, 200 %, reduzierte Bewegung, Hoher Kontrast, Tap-Ziele ≥ 48 dp, Abstände) auf alle Szenarien; neue Prüfung „Text nicht direkt auf der Welt“.
- `shoot.mjs` in 4 Welten (Weltwahl über Darstellung), `nav_checks.mjs` mit neuen Tab-Wegen, Web-Build.
- Nicht hier prüfbar: V2-14 (Profil-Messung auf Mittelklassegerät), V2-28 (TalkBack/VoiceOver) → Geräte-Prüfliste im Kriterienbericht (wie v1, Abschnitt 5).

### 3.7 Brief-Ergänzung F2-D2 (was Brief v2 nicht gestaltet)
Brief v2 gestaltet Pfad, Heute, Session, Check-ups, Profil, Chats, Physio-Liste, -Übersicht, Baukasten, Neuer Patient. **Nicht gestaltet** und für Ausschnitt 2 nötig:
- **Teil A (vor L3):** Einbettung des Manny-Look-Schritts in den Code-Start (Lage entschieden: vor dem Code-Feld, O-43; gleiche Karten wie Ergänzung 1, 6a), Startbildschirm „Zugang über deinen Physio“ mit Code-Feld und Ergebniscodes, Einwilligung (`physio_sharing-2`, 7.2), Neuanmeldungs-Hinweise auf beiden Geräten, Leerzustand „Dein Physio stellt deinen Plan noch zusammen“, Pfad-Status „ausgelassen“, Akte-Ansicht „Mein Plan und meine Verletzung“ (Behandler, Termine, eigene Termine, Krankengeschichte), „nicht aktuell“-Hinweis, Lade-/Fehlerzustände mit Backend, Löschen mit Backend (sicher/unklar/lokaler Fehler).
- **Teil B (vor L5):** „Frage an meinen Physio“ (Eingabe, Liste, Status „besprochen“), fester Hinweis bei Schmerz- **und Schwellungs**-Warnzeichen (O-12, O-2: derselbe Hinweis), Hinweis „Heute etwas kürzer“ im Detail.
  **Brief-Folgen aus N-14 (Ergänzung freigegebener Brief-Kriterien, Nutzerfreigabe nötig, vor L5; gestaltet vom `ui-designer`, dieser Plan nennt nur die Änderung):**
  - Brief 7.2 „Einmal am Tag · 5 schnelle Fragen“ und „Fünf Fragen nacheinander“ → **sechs** Fragen mit Schwellung 0–3 (O-18); Lage der Frage, Bezeichnungen der Stufen 0–3 und Bedienelement gestaltet der `ui-designer`.
  - V2-38 „Frage N von 5“ → „Frage N von 6“.
  - Brief 7.2 Einschränkungen „Auswahl-Chips oder ‚keine‘“ → **Einzelwert-Skala** keine / leicht / deutlich / stark (O-19).
  - Brief 7.9 Kachel 2 „Befinden · Motivation · Warnzeichen“ → zeigt zusätzlich **Schwellung** (und die Einschränkungs-Stufe); Warnzeichen „Schwellung stark“ mit Symbol und Text wie die übrigen.
- **Teil C (vor L6):** Physio-Anmeldung, Konto, Chats-Platzhalter, Plan-Editor (Handy und Rechner), Akte-Pflege, Code neu erzeugen, Vorlagenauswahl.
- **Teil D (vor L7):** Historie (je Verletzung), Notiz anlegen, neue Verletzung anlegen, Kachel-Details, die Brief 7.9 nicht ausführt, Inhalt der Kachel 6 „Phase und nächstes Ziel“ nach der Datenquelle 6.12 („nächstes Ziel“ = Titel der nächsten Phase, O-42 entschieden).

---

## 4. Physio-Zugang (O-13: W-A) auf Handy und Rechner (PB-1)

- Zweiter Einstieg `app/lib/main_physio.dart`, Code unter `app/lib/physio/`, Build `flutter build web -t lib/main_physio.dart -o build/physio_web`. Begründung unverändert (gemeinsame Logik, Modelle, Repositories, Prüfketten; Tree-Shaking).
- **Responsiv (neu):** unter 840 dp Breite Leiste unten mit 4 Zielen (Patienten · Übungen · Chats · Konto), eine Spalte; ab 840 dp Seitenleiste links 240 dp, Inhalt bis 1200 dp mittig, Kacheln dreispaltig (V2-22, V2-59). Kein Hover-only, Tastatur bedienbar. Dieselbe Welt, ruhiger (V2-61).
- **Prüf-Viewports Physio:** 390×844 und 320×568 (Handy), 1024×768 und 1280×800 (Rechner). Kacheln 2–8 bei 1280×800 ohne Scrollen (PB-B AK 1).
- Bereitstellung lokal (Annahme O-16); Hosting nur auf Wunsch (X2-6). Am Handy wird der Physio-Zugang im mobilen Browser genutzt (keine native Physio-App, B-2).
- Grenzen per statischer Regel (unverändert): `lib/physio/**` importiert aus `lib/ui/**` nur `lib/ui/components/**`; `lib/ui/**` nichts aus `lib/physio/**`; `package:supabase_flutter` nur unter `lib/backend/**` und `main*.dart`; Physio-Texte in `lib/l10n/strings_physio_de.dart`; **keine Chat-Begriffe und keine Chat-Modelle in `lib/physio/**`**.
- Ziel „Chats“ im Physio-Bereich: Direktnachrichten sind nicht spezifiziert (Spec 8) → Platzhalter „Kommt später“ (Annahme, O-27).
- Ziel „Konto“: Name, Praxis, Abmelden (Annahme; Gestaltung F2-D2 C).

---

## 5. Projekt- und Ordnerstruktur

```
supabase/                                  # Repo-Stamm, Layout der Supabase-CLI
  config.toml                              # lokaler Stack (anonyme Anmeldung an, Registrierung aus, Storage an); ohne Secrets
  migrations/
    <ts>_01_rollen_und_rechte.sql          # L2: REVOKE der Standardrechte, Default Privileges, Schema app
    <ts>_02_grundschema.sql                # L2: Kern-Tabellen, Typen, Constraints, Fremdschlüssel
    <ts>_03_rls.sql                        # L2: RLS (ohne FORCE), Hilfsfunktionen, Policies, Spalten-Grants
    <ts>_04_trigger.sql                    # L2: created_by/author, injury_id, Schreibsperre
    <ts>_05_funktionen.sql                 # L2: Einladung inkl. create_patient/regenerate_invitation, Plan, Phase, Einwilligung, Löschen
    <ts>_06_training.sql                   # L2: training_sessions (alle Spalten inkl. mode, plan_id), exercise_results
    <ts>_07_vorlagen.sql                   # L2: plan_templates
    <ts>_08_session_checkup.sql            # L4: session_checkups, session_checkup_items
    <ts>_09_tages_checkup_warnzeichen.sql  # L5 (inkl. Fragen)
    <ts>_10_physio_liste.sql               # L6 (nur set_main_physio)
    <ts>_11_physio_uebersicht.sql          # L7 (Notizen, Verletzungen, Sichten)
    <ts>_12_baukasten_storage.sql          # L8
  tests/
    shim/supabase_roles.sql                # nur Tests ohne Stack (12.1)
    db/T01_*.sql … T85_*.sql               # benannte DB-Tests (12.2)
    fixtures/local_day/*.json              # L2 (F2-1): gemeinsame Fixtures Mitternacht/Zeitzone (6.7), auch für Dart-Tests und KI-Plan
    db/race/*.sh                           # Nebenläufigkeit mit zwei Verbindungen
    stack/*.sql|*.sh                       # nur gegen lokalen Supabase-Stack (Storage, Auth-Admin, Seed)
    run_local_pg.sh                        # initdb (Temp), Shim, Migrationen, Tests, Abbau
    run_stack.sh                           # gegen lokalen Stack (nach X2-8)
app/
  assets/manny/brille/, assets/manny/ohne/ # L1: finale Grafiken (normal, freudig, traurig, kopf; 1x, 2.0x/, 3.0x/), Kopie aus docs/design/manny/
  assets/illustrations/                    # L1/L3: neutrale Übungs-Illustration (Platzhalter)
  config/supabase.example.json             # Platzhalter: SUPABASE_URL, SUPABASE_ANON_KEY, INVITE_LINK_BASE
  config/supabase.local.json               # nicht eingecheckt
  lib/
    main.dart, main_physio.dart, main_preview.dart, main_physio_preview.dart
    logic/   world_time.dart (L1), framework.dart, invite_code.dart, plan_today.dart, exercise_duration.dart,
             path_from_phases.dart, outbox.dart, plan_validation.dart, session_machine.dart (L4),
             checkup.dart (L5), fallback_today.dart (L5, Kürzung), packing_list.dart (L4), manny_occasions.dart (L1)
    data/    framework_repository.dart, framework_cache.dart, outbox_store.dart, account_deleter.dart,
             display_settings_store.dart (L1), session_store.dart (L4); Manny-Look im App-Zustand (L1, 3.5)
    backend/ supabase_config.dart, supabase_patient_repository.dart, supabase_physio_repository.dart,
             supabase_image_repository.dart (L8), outbox_sender.dart, backend_errors.dart
    ui/      start/, onboarding/, path/, today/, session/ (L4), checkup/ (L4/L5), chats/ (L1), profile/ (L1),
             record/ (L3), questions/ (L5), data_sheet/
    physio/  physio_app.dart, shell/, login/, account/, patients/, invite/, overview/ (L7), history/ (L7),
             plan_editor/, record/, exercises/ (L8)
    l10n/    strings_de.dart, strings_physio_de.dart
    dev/     Fake-Repositories, Szenarien Patient und Physio
  tool/seed/seed.dart, tool/seed/testdaten.json   # F2-2, erst nach L1 (MAJOR-1)
  tool/screens/  shoot.mjs, nav_checks.mjs (+ Physio, + Welten)
```

`.gitignore` ergänzt um `app/config/supabase.local.json`, `supabase/.temp/`, `supabase/.branches/`, `.env*`.

---

## 6. Backend

### 6.1 Rollen- und Rechtemodell (unverändert aus v1.2, M-1–M-3)

Supabase-Rollen: `anon`, `authenticated` (auch anonyme Sitzungen, Claim `is_anonymous`), `service_role` (nur Seed), Migrationsrolle `postgres` (Eigentümer). Attribute im echten Stack zu bestätigen (X2-8).

1. **Eigentümer und RLS:** Alle Tabellen, Sichten und Funktionen in `public` und `app` gehören der Migrationsrolle. RLS mit `ENABLE ROW LEVEL SECURITY`, **nicht** mit `FORCE` (M-1: mit `FORCE` und einem Eigentümer ohne `BYPASSRLS` sehen `SECURITY DEFINER`-Funktionen 0 Zeilen; im Review mit Postgres 16 belegt). Die API-Rollen sind nie Eigentümer; für sie gilt RLS immer. *Hinweis:* Der Auftrag zu v2.0 nennt „FORCE RLS“ als bisherige Regel; freigegeben ist das Gegenteil. Der Plan bleibt bei der freigegebenen Entscheidung (Rückfrage O-40, nicht blockierend).
2. **Standardrechte entziehen** (Migration 01, unverändert): `REVOKE ALL` auf Tabellen/Sequenzen für `anon`, `authenticated`; `REVOKE EXECUTE` für `PUBLIC`, `anon`, `authenticated`; gleichlautende `ALTER DEFAULT PRIVILEGES`; danach einzelne `GRANT`s laut 6.2/6.4.
3. **Sichten** nur mit `security_invoker = true` (neu genutzt für Kachel-Sichten, 6.12; DB-T72).
4. **Jede `SECURITY DEFINER`-Funktion:** `SET search_path = ''`, voll qualifizierte Namen, prüft als Erstes Aufrufer, Rolle und Zugehörigkeit.
5. **Hilfsfunktionen** (Definer, `STABLE`): `app.uid()`, `app.is_anonymous()`, `app.current_physio_practice()`, `app.current_patient_id()` (gebunden und `active`), `app.physio_can_see_patient(p)`, **neu** `app.current_injury_id(p)` (aktive Verletzung des Patienten), `app.current_plan_id(p)` (Plan der aktiven Verletzung), `app.patient_can_see_exercise(e)` (Übung in **irgendeiner** Position des aktuellen Plans, aktiv oder vorbereitet, **ohne Datumsbezug**, 6.7; L2 für `exercises`, L8 für Bilder).
   - **Aufruferprüfung auch in Hilfsfunktionen mit Patienten-Parameter (MINOR-9, korrigiert MAJOR-A):**
     - `app.physio_can_see_patient(p)` liefert nur dann `true`, wenn der Aufrufer ein Physio ist (`app.current_physio_practice()` nicht `null`) und `p` zu dessen Praxis gehört; **keine Patientenklausel und kein Selbstbezug**. Ein gebundener Patient bekommt auch für die eigene ID `false`; damit lassen die Physio-Policies (z. B. `practice_notes` SELECT, UPDATE `patients.first_name`/`last_name`, `injuries.label`, Schreiben in `treaters`/`history_entries`, `invitations` SELECT) keinen Patienten durch.
     - `app.current_injury_id(p)` und `app.current_plan_id(p)` liefern nur dann einen Wert, wenn `p = app.current_patient_id()` (Patient für sich selbst) oder `app.physio_can_see_patient(p)` (Physio der Praxis) gilt; sonst `null`.
     - Damit verraten die Hilfsfunktionen auch bei direktem Aufruf nichts über fremde Patienten.
     - **Interne Variante ohne Aufruferprüfung (MINOR-C):** `app.active_injury_id_internal(p)` (aktive Verletzung, ohne Prüfung) für Trigger (`set_injury_id`, 6.3) und für Definer-Funktionen, die den Aufrufer schon geprüft haben. Kein `EXECUTE` für `PUBLIC`, `anon`, `authenticated`; nur die Eigentümerrolle ruft sie (Definer-Kontext). So funktionieren auch Schreibvorgänge ohne Patienten-JWT (Seed mit `service_role`, DB-T45).
   - **Schema `app` ist nicht über die API erreichbar:** `supabase/config.toml` `[api] schemas` nennt nur `public` (im echten Projekt X2-3 prüfen); `authenticated` hat `USAGE` auf `app` und `EXECUTE` nur auf den Hilfsfunktionen, die Policies brauchen (nicht auf der internen Variante). DB-T81.
6. **Seed** nur mit `service_role` (lokal bzw. X2-4).
7. **Storage (neu, L8):** ein privater Bucket `exercise-images`; Policies auf `storage.objects` (6.11). Keine öffentlichen URLs.

### 6.2 Tabellen

Grundsätze unverändert: `uuid`-Schlüssel; Schreibvorgänge der Warteschlange mit Geräte-IDs (`on conflict (id) do nothing`); `timestamptz`; Kalendertage `date` (lokaler Tag des Geräts, Datumsbasis 6.7); `practices.is_test`. Spalte „L“ = Lieferung.

| Tabelle | L | Wichtige Spalten | Recht für `authenticated` (über RLS) | Schreibpfad sonst |
|---|---|---|---|---|
| `practices` | 2 | `id`, `name`, `is_test` | SELECT (Physio eigene Praxis) | Seed |
| `physios` | 2 | `id` → `auth.users` (`ON DELETE CASCADE`), `practice_id`, `display_name` | SELECT (gleiche Praxis) | Seed |
| `patients` | 2 | `id`, `practice_id`, `first_name` (`CHECK` nicht leer), `last_name` (**jetzt optional**), `main_physio_id` → `physios` (`ON DELETE SET NULL`), `auth_user_id` → `auth.users` (`ON DELETE SET NULL`, unique), `status` (`invited` · `active` · `deleting` · `access_deleted`), `bound_at`, `created_at`, `create_params_hash` (**neu**, nur für die Idempotenzprüfung von `create_patient`, kein Spalten-Grant, 6.6), `manny_look` (**neu v2.2**, `brille` · `ohne`, `null` = nicht übertragen; O-41) | SELECT (Physio der Praxis; Patient eigene Zeile; `manny_look` per Spalten-Grant lesbar, der Physio-Bereich zeigt ihn nicht); UPDATE `first_name`, `last_name` (Physio, Spalten-Grant); **kein** UPDATE-Recht auf `manny_look` | RPCs (Bindung, Status, Hauptphysio, `set_manny_look`) |
| `injuries` **neu** | 2 | `id`, `patient_id`, `label` (`CHECK` nicht leer), `reference_date` (für „Woche N“), `started_on`, `closed_on` (null = aktiv), unique partiell „eine aktive Verletzung je Patient“ | SELECT (Physio der Praxis; Patient eigene); UPDATE `label`, `reference_date` (Physio, Spalten-Grant) | `create_patient`, `start_new_injury`, `close_injury` |
| `invitations` | 2 | unverändert: `id`, `patient_id`, `code_hmac`, `expires_at`, `redeemed_at`, `redeemed_by`, `revoked_at`, `failed_attempts` | SELECT nur Spalten-Grant **ohne** `code_hmac` (Physio der Praxis) | RPCs |
| `redeem_attempts` | 2 | unverändert | – | `redeem_invitation` (Bereinigung > 24 h) |
| `exercises` | 2 | `id`, `practice_id` (null = Katalog), `name`, `description` (beide `CHECK` nicht leer), `is_example`, `created_by`, **neu (PB-F):** `default_sets`, `default_reps`, `default_duration_sec` (O-17), `default_weight_kg`, `pause_sec`, `materials text[]`, `locations text[]` (`CHECK` ⊆ {`home`,`practice`,`gym`}), `short_instruction` (optional, für die Session; B-27) | SELECT (Physio: Katalog + Praxis; Patient: nur Übungen, die in einer Position seines aktuellen Plans stehen – aktiv oder vorbereitet, ohne Datumsbezug, 6.7); INSERT/UPDATE eigene Praxis (Physio); DELETE nur ungenutzt | Seed (Katalog) |
| `exercise_images` **neu** | 8 | `id`, `exercise_id` (`ON DELETE CASCADE`), `kind` (`start` · `end` · `other`), `storage_path`, `position`, `created_by` | SELECT wie `exercises`; INSERT/DELETE (Physio eigene Praxis, nicht Katalog) | Seed (Katalog, falls Bilder vorhanden) |
| `plan_templates` **neu** | 2 | `id`, `practice_id` (null = CuraOne-Beispiel), `name`, `injury_label`, `is_example`, `payload jsonb` (Phasen mit Positionen, Übungs-IDs), `created_by` | SELECT (Physio: Beispiele + eigene Praxis); INSERT/UPDATE/DELETE eigene Praxis (Physio) – **UI zum Speichern eigener Vorlagen ist offen (O-25)** | Seed (Beispiele) |
| `plans` | 2 | `id`, `patient_id`, **`injury_id` (unique, statt `patient_id` unique)**, **`current_phase_id`** → `phases` (`ON DELETE SET NULL`, statt an `patients`), `version`, `updated_at`, `updated_by`, `closed` (gesetzt mit der Verletzung) | SELECT (Physio der Praxis; Patient alle eigenen, auch abgeschlossene) | `save_plan`, `create_patient`, `start_new_injury`, `assign_exercise` |
| `phases` | 2 | unverändert: `id`, `plan_id`, `position`, `title`, `planned_weeks` (`CHECK 1–52`) | SELECT | `save_plan` |
| `plan_items` | 2 | `id`, `plan_id`, `phase_id` (`CASCADE`), `exercise_id` (`RESTRICT`), `position`, `sets`, `reps`, `duration_sec` (Dauer je Satz in Sekunden, O-17 [entschieden]; ersetzt `duration_min`), `weight_kg`, `pause_sec`, `load_note`, je `null` oder `CHECK > 0`; **neu (PB-6):** `release` (`active` · `prepared`), `release_on date`, `release_with_phase_id` → `phases` (gleicher Plan); `CHECK`: `prepared` braucht genau eines von beiden; optional `easier_variant_of` (E-30, nur falls entschieden) | SELECT | `save_plan`, `assign_exercise` |
| `treaters` | 2 | unverändert | SELECT (beide); INSERT/UPDATE/DELETE (Physio) | – |
| `appointments` | 2 | unverändert | SELECT (beide); INSERT/UPDATE/DELETE nur eigene | – |
| `history_entries` | 2 | unverändert (Krankengeschichte der Akte, nicht die Historie PB-G) | SELECT (beide); INSERT/UPDATE/DELETE (Physio) | – |
| `training_sessions` | 2 | `id` (Gerät), `patient_id`, `injury_id` (Trigger, aus `plan_id`), `plan_id` (**neu**, Plan der Momentaufnahme, vom Gerät; muss ein Plan dieses Patienten sein, auch abgeschlossen), `local_day`, `logged_at`, `phase_id` (`SET NULL`), `plan_version`, `items jsonb` (Momentaufnahme, kein FK), **neu:** `mode` (`guided` · `checklist`), `started_at`, `ended_at`, `active_seconds`, `ended_early`, `streak_after` (vom Gerät gemeldet, B-25). **Alle Spalten entstehen in L2** (Migration 06), weil L3 `mode = checklist` schreibt (MINOR-3) | SELECT (beide); INSERT (Patient); UPDATE nur `ended_at`, `active_seconds`, `ended_early`, `streak_after` (Patient, eigene, Spalten-Grant); DELETE eigene | – |
| `exercise_results` **neu** | 2 | `id` (Gerät), `patient_id`, `injury_id` (Trigger, aus der Session), `training_session_id` → `training_sessions` (`CASCADE`), `local_day`, `plan_item_id` (Momentaufnahme, **kein FK**), `exercise_id` (Momentaufnahme, kein FK), `exercise_name` (Momentaufnahme), `status` (`done` · `skipped`), `sets_done`, `reps_done`, `logged_at` | SELECT (beide); INSERT, DELETE eigene (Patient; Rückgängig am selben Tag, B-24) | – |
| `session_checkups` **neu** | 4 | `id` (Gerät), `patient_id`, `injury_id` (Trigger, aus der Session), `training_session_id` (`SET NULL`), `local_day`, `rating` 1–5, `created_at` | SELECT (beide); INSERT (Patient) über `submit_session_checkup`; kein UPDATE/DELETE | RPC |
| `session_checkup_items` **neu** | 4 | `checkup_id` (`CASCADE`), `plan_item_id` (Momentaufnahme), `exercise_id`, `difficulty` (`easy` · `right` · `hard` · `pain`, null), `weight_increased` bool (null), `skip_reason` (`time` · `pain` · `material` · `other`, null) | wie `session_checkups` | RPC |
| `daily_checkups` **neu, ersetzt `wellbeing_reports`** | 5 | `id` (Gerät), `patient_id`, `injury_id` (Trigger), `local_day` (unique je Patient), `reported_at`, `pain` 0–10, `wellbeing` 1–5, `motivation` 1–5, `swelling` 0–3 (O-18 [entschieden], 3 = stark), `limitations` **ein Wert** aus `none` · `mild` · `marked` · `severe` (= keine / leicht / deutlich / stark, O-19 [entschieden]), `mood` 1–5; alle Pflicht | SELECT (beide); **kein** direktes INSERT/UPDATE/DELETE | `submit_daily_checkup`, `delete_my_data` |
| `warning_rules` | 5 | `id`, `version`, `rule jsonb`, `active` | – | Migration (entschiedene Werte aus O-2, 6.9; nicht vorläufig) |
| `warning_signs` | 5 | `id`, `patient_id`, `created_at`, `source` (`checkup` **neu**; ab Ausschnitt 3 `chat`), `layer`, `level`, `reason_code`, `daily_checkup_id`, `local_day` (**neu**, Tag des auslösenden Check-ups; partieller Unique-Index `(patient_id, reason_code, local_day) WHERE source = 'checkup'`, 6.9), `client_message_id` (Ausschnitt 3), `notify_patient` bool (**neu**, `true` für Schmerz und Schwellung, `false` für die Stimmungs-Nachricht), `trigger_checkup_id` (**neu v2.2**, der Check-up, dessen Eingang das Warnzeichen erzeugt hat; für `warning_raised` und die gemeinsame Meldung, 6.9), `seen_at`; **keine Textspalte** | SELECT (Physio der Praxis); kein INSERT | Trigger (L5); Chat-Funktionen (Ausschnitt 3) |
| `patient_questions` **neu** | 5 | `id` (Gerät), `patient_id`, `injury_id` (Trigger), `text` (`CHECK` nicht leer, Länge ≤ O-34), `created_at`, `status` (`open` · `discussed`), `discussed_at`, `discussed_by` | SELECT (Patient eigene; Physio der Praxis); INSERT nur über `ask_physio` | `ask_physio`, `mark_question_discussed` |
| `practice_notes` **neu** | 7 | `id`, `patient_id`, `injury_id` (Trigger), `author_id` (Trigger, = Physio), `created_at`, `text` (`CHECK` nicht leer) | SELECT, INSERT (Physio der Praxis); **Patient: keine Policy** (PB-C); UPDATE/DELETE nicht vorgesehen (O-26) | – |
| `consents` | 2 | unverändert; neue Version `physio_sharing-2` (7.2) | SELECT (beide) | `accept_consent` |
| `account_events` | 2 | unverändert | SELECT (Patient) | `redeem_invitation` |

**Begründete Änderungen gegenüber v1.2:**
- `patients.injury_label`, `reference_date`, `current_phase_id` und `plans.patient_id unique` werden durch `injuries` und `plans.injury_id`/`plans.current_phase_id` ersetzt, weil PB-7/PB-G mehrere Verletzungen mit je eigenem Plan beim selben Patienten verlangen. Die Rechte bleiben gleich verteilt (Physio pflegt, Patient liest).
- `wellbeing_reports`/`report_wellbeing` werden durch `daily_checkups`/`submit_daily_checkup` ersetzt (C-2: andere Werte, einmal täglich). Die Sicherheitsregeln aus v1.2 (kein direktes INSERT, unveränderlich, Rückgabe nur ein Wahrheitswert) bleiben.
- `duration_min` → `duration_sec` (Dauer je Satz in Sekunden), entschieden mit O-17 (N-14).
- `daily_checkups.limitations` ist ein Einzelwert statt `text[]` (O-19), `swelling` eine feste Spalte (O-18).

### 6.3 Trigger

- `app.set_created_by()` – `BEFORE INSERT` auf `appointments`, `exercises`, `exercise_images`, `plan_templates`: setzt `created_by`/`created_by_role` serverseitig (m-3).
- `app.set_note_author()` **neu** – `BEFORE INSERT` auf `practice_notes`: `author_id = app.uid()`, muss Physio der Praxis des Patienten sein.
- `app.set_injury_id()` **neu** – `BEFORE INSERT`, Definer, `search_path = ''`; Client-Werte für `injury_id` werden immer überschrieben (DB-T61). Herleitung je Tabelle (MINOR-4), damit eine offline gespeicherte Session des alten Tags nach `start_new_injury` bei ihrer alten Verletzung bleibt:
  - `training_sessions`: `injury_id = plans.injury_id` des mitgesendeten `plan_id`; der Plan muss diesem Patienten gehören (sonst `42501`), darf auch abgeschlossen sein;
  - `exercise_results`, `session_checkups`: `injury_id` der referenzierten `training_session` (damit nie abweichend von ihrer Session); die Session muss **demselben Patienten** gehören wie die neue Zeile (`training_sessions.patient_id = NEW.patient_id`, sonst `42501`, MINOR-D: der Fremdschlüssel allein prüft das nicht, weil er RLS umgeht); ohne Session (nur `session_checkups` nach `SET NULL`, beim Insert nicht möglich) → Fehler;
  - `daily_checkups`, `patient_questions`, `practice_notes`: aktive Verletzung zum Zeitpunkt des Eingangs (interne Variante `app.active_injury_id_internal(patient_id)` ohne Aufruferprüfung, 6.1 Nr. 5, MINOR-C; Annahme B-32). Der Aufrufer ist an dieser Stelle schon durch RLS bzw. die aufrufende RPC geprüft.
- `app.lock_patient_for_write()` – unverändert in Logik (Definer, `search_path = ''`, `OLD` bei DELETE, nur Patienten-Schreibvorgänge, `FOR SHARE`, INSERT/UPDATE nur `active`, DELETE `active`/`deleting`), **Tabellenliste erweitert:** `training_sessions`, `exercise_results`, `session_checkups`, `session_checkup_items` (über `checkup_id` → `patient_id`), `daily_checkups`, `patient_questions`, `appointments`, `consents`, `warning_signs` (ab Ausschnitt 3 auch Chat-Tabellen). DB-T70.
- `app.raise_warning_signs()` – `AFTER INSERT` auf `daily_checkups` (statt `wellbeing_reports`), Definer, `search_path = ''`, wertet aktive `warning_rules` aus (O-2, Regeln, Reihenfolgeunabhängigkeit und Zählweise je Verletzung 6.9); setzt bei jedem neu angelegten Warnzeichen `trigger_checkup_id = NEW.id` (gemeinsame Meldung, 6.9).

### 6.4 Funktionen (RPC)

Alle: `SECURITY DEFINER`, `SET search_path = ''`, `REVOKE EXECUTE … FROM PUBLIC, anon`, `GRANT EXECUTE … TO authenticated`; erste Anweisung prüft den Aufrufer, Fehler `42501`.

| Funktion | L | Erlaubter Aufrufer | Wirkung |
|---|---|---|---|
| `create_patient(id, first_name, injury_label, template_id, local_day, last_name?, reference_date?)` | 2 | Physio | 6.6 (UI in L6) |
| `regenerate_invitation(patient_id)` | 2 | Physio derselben Praxis | unverändert (O-8, N-1; UI in L6) |
| `redeem_invitation(code)` | 2 | anonyme, ungebundene Sitzung | unverändert (Ergebnisse `ok` · `ok_rebound` · `invalid` · `already_used` · `expired` · `too_many_attempts` · `not_allowed`) |
| `accept_consent(kind, version)` | 2 | gebundener Patient | unverändert |
| `save_plan(patient_id, expected_version, plan jsonb)` | 2 | Physio derselben Praxis | 6.7 |
| `set_current_phase(patient_id, phase_id)` | 2 | Physio derselben Praxis | Phase muss zum **aktuellen** Plan gehören; erhöht `version` (damit „Heute“ neu lädt) |
| `delete_my_data()` | 2 | gebundener Patient | 6.13 |
| `set_manny_look(look)` **neu v2.2** | 2 (App ab L3) | gebundener, aktiver Patient (Status mit `FOR SHARE` wie die Schreibsperre) | setzt `manny_look` nur in der Zeile `app.current_patient_id()`; Wert aus fester Liste (`brille` · `ohne`), sonst Fehler; idempotent (gleicher Wert erneut = Erfolg); kein Patienten-Parameter, kein anderer Schreibweg (O-41, DB-T85) |
| `submit_session_checkup(id, training_session_id, local_day, rating, items jsonb)` **neu** | 4 | gebundener, aktiver Patient | idempotenter Insert von Kopf und Positionen in einer Transaktion; Werte aus festen Listen; `skip_reason` nur bei Positionen, die in dieser Session `skipped` sind (sonst Fehler) |
| `submit_daily_checkup(id, local_day, pain, wellbeing, motivation, swelling, limitations, mood)` **neu, ersetzt `report_wellbeing`** | 5 | gebundener, aktiver Patient | idempotenter Insert (Geräte-ID); `local_day` nach der Grenze für Warteschlangen-Einträge (6.7 Nr. 3: Bindungstag − 1 bis UTC-Datum + 1); zweite Meldung am selben Tag mit anderer ID → `already_submitted`; Rückgabe nur `warning_raised boolean` = es gibt ein Warnzeichen mit `notify_patient = true` und `trigger_checkup_id` = dieser Check-up (die Stimmungs-Nachricht zählt **nicht**, C-3; DB-T58); bei Wiederholung derselben ID gleiche Antwort, auch wenn inzwischen ein nachträgliches `pain_rise` für diesen Tag entstanden ist (das trägt die ID des verspäteten Vortags, NEU-7) |
| `ask_physio(id, text)` **neu** | 5 | gebundener, aktiver Patient | idempotenter Insert; `patient_id` aus der Sitzung; Länge laut O-34 |
| `set_main_physio(patient_id, physio_id)` **neu** | 6 | Physio derselben Praxis | Ziel-Physio muss derselben Praxis angehören; ändert keine Rechte (N-4) |
| `mark_warnings_seen(patient_id)` | 7 | Physio derselben Praxis | unverändert (O-11) |
| `mark_question_discussed(question_id, discussed boolean)` **neu** | 7 | Physio derselben Praxis | setzt bzw. entfernt `discussed` mit Zeit und Physio |
| `start_new_injury(patient_id, id, label, local_day, template_id?, reference_date?)` **neu** | 7 | Physio derselben Praxis | schließt die aktive Verletzung (`closed_on = local_day` des Physio-Geräts, Datumsbasis 6.7, Plan `closed`), legt neue Verletzung und leeren bzw. aus Vorlage gefüllten Plan an (PB-G AK 2) |
| `close_injury(patient_id, closed_on)` **neu, nur falls O-29 so entschieden** | 7 | Physio derselben Praxis | Verletzung abschließen ohne neue |
| `assign_exercise(exercise_id, assignments jsonb)` **neu** | 8 | Physio derselben Praxis | 6.11 |

### 6.5 Einladungscode (unverändert, N-6/N-7)

| Punkt | Festlegung |
|---|---|
| Alphabet | Crockford-Base32 (32 Zeichen, ohne `I L O U`) |
| Länge | 10 Zeichen, Anzeige `XXXXX-XXXXX`, 50 Bit |
| Normalisierung | Großschreibung; Leerzeichen und Bindestriche entfernen; `O→0`, `I`/`L→1` |
| Erzeugung | `gen_random_bytes` (pgcrypto) in der Funktion |
| Speicherung | `HMAC-SHA256(pepper, code)`, Pepper in `app.secrets` ohne Rechte für API-Rollen (X2-11) |
| Bremse je Sitzung | 5 Fehlversuche je 15 Minuten |
| Bremse global | keine (N-6) |
| Bremse je IP | Supabase-Ratenbegrenzung anonymer Anmeldungen, optional Captcha (X2-2) |
| Ablauf | 14 Tage (O-7, Annahme), einmalig |

### 6.6 Neuer Patient in 30 Sekunden (PB-8, PB-E)

- **Eingabe:** Vorname (Pflicht) und **entweder** Verletzung (Freitext) **oder** Plan-Vorlage (Pflicht ist eines von beiden; mit Vorlage wird deren `injury_label` übernommen, wenn keine Verletzung eingegeben ist). Nachname, Bezugsdatum und Akte später.
- **Ein Aufruf:** `create_patient(id, first_name, injury_label, template_id, local_day, …)`:
  1. Aufrufer ist Physio; `id` vom Client erzeugt (**Idempotenz**, neu).
  2. **Serialisiert und mit Parametervergleich (MINOR-1):** Die Funktion legt die Patientenzeile mit `INSERT … ON CONFLICT (id) DO NOTHING` an. Ein gleichzeitiger zweiter Aufruf mit derselben `id` wartet dabei auf die erste Transaktion (kein `23505` an den Client). Kommt keine neue Zeile zurück, liest sie die bestehende mit `FOR UPDATE` und vergleicht `create_params_hash` (SHA-256 über normalisierte `first_name`, `last_name`, `injury_label`, `template_id`, `reference_date`; `local_day` zählt nicht):
     - gleiche Praxis, Status `invited`, gleicher Hash (Antwort ging verloren, Wiederholung): offene Einladung widerrufen und neue erzeugen, neuen Klartext-Code zurückgeben (der alte Code wurde nie angezeigt);
     - gleiche Praxis, Status `invited`, **anderer Hash** → Fehler `idempotency_mismatch`, nichts geändert (die App erzeugt für geänderte Eingaben eine neue `id`);
     - anderer Status oder fremde Praxis → `42501`.
  3. Sonst: Patient (`main_physio_id = Aufrufer`, PB-A AK 3), Verletzung (`reference_date` = Eingabe oder `local_day` des Physio-Geräts, B-19, Datumsbasis 6.7), Plan (leer oder **Kopie der Vorlage mit neuen IDs**, aktuelle Phase = erste Phase), Einladung.
  4. Vorlage muss Beispiel oder eigene Praxis sein, Übungen darin Katalog oder eigene Praxis (sonst `42501` bzw. `foreign_id`).
  5. Rückgabe: `patient_id`, Klartext-Code (einmalig), `expires_at`.
- **Anzeige sofort:** QR-Code (≥ 200 dp, Schwarz auf Weiß, Ruhezone ≥ 4 Module), Link, „Teilen“ (System-Teilen: SMS, Mail, Messenger; im Browser Web-Share, sonst „Link kopieren“), „Fertig“. Code-, Link- und QR-Regeln unverändert (v1.2 5.2: `<INVITE_LINK_BASE>/?einladung=XXXXX-XXXXX` bzw. `curaone://einladung?code=…`; Link füllt das Feld, Einlösen nach Bestätigung, B-8).
- **Fehler/offline:** Hinweis mit „Nochmal versuchen“; Eingaben bleiben, Wiederholung mit derselben `id` (Schritt 2) – nichts geht verloren, kein doppelter Patient. Ändert der Physio vor der Wiederholung Eingaben, erzeugt die App eine neue `id`.
- **Gleichzeitige Wiederholung (MINOR-F):** Solange ein `create_patient`-Aufruf läuft, sendet die App keinen weiteren („Speichern“/„Nochmal versuchen“ ohne Wirkung, Ladezustand). Endet ein Aufruf durch Zeitüberschreitung des Clients, kann der Server ihn trotzdem noch abschließen; eine danach gestartete Wiederholung wartet auf ihn (Schritt 2) und widerruft dessen Code. Die App zeigt deshalb **nur die Antwort des zuletzt gestarteten Aufrufs** und verwirft spätere Antworten älterer Aufrufe. So ist der angezeigte QR-Code immer der gültige. Prüfung: DB-T64b (zwei Aufrufe nacheinander: nur der Code der zweiten Antwort ist einlösbar) und W-Test in F2-7c (Knopf während des Aufrufs ohne Wirkung; verspätete Antwort eines älteren Aufrufs wird nicht angezeigt).
- **Nach dem Einlösen** landet der Patient nach der Einwilligung direkt auf dem Pfad seines Plans (PB-E AK 2; Einwilligung bleibt Pflicht nach A-1 AK 3, O-39).
- **Prüfung < 30 s:** Ablaufprüfung in `nav_checks.mjs` (Physio, Fake-Repository): Anzahl Pflichteingaben = 2, Tipps bis QR = 1, gemessene Zeit vom Öffnen bis QR sichtbar; zusätzlich manuelle Stoppuhr-Prüfung gegen den lokalen Stack in L9.
- Tests: DB-T63, DB-T64, DB-T64b (inkl. Parametervergleich und zwei Verbindungen); W; Golden. Die Funktion entsteht in L2 (Seed und DB-Tests brauchen sie), die Oberfläche in L6 (MINOR-2).

### 6.7 Plan speichern (M-5, erweitert)

Unverändert: stabile IDs, Upsert nach ID, nur Entferntes löschen, Version prüfen, `current_phase_required`, `foreign_id`, Verlauf bleibt (keine FKs aus Verlaufstabellen auf `plan_items`). **Neu:**
- arbeitet nur auf dem **aktuellen** Plan (aktive Verletzung); abgeschlossener Plan → `plan_closed` (DB-T62);
- Freischaltung je Position prüfen: `release = active` → keine Freischalt-Felder; `prepared` → genau eines aus `release_on`/`release_with_phase_id`, Phase aus demselben Plan (sonst `foreign_id`, DB-T65);
- Werte `weight_kg`, `pause_sec`, `duration_sec` `null` oder > 0.
- **„Freigegeben“ für Heute, Tauschen, Packliste und den KI-Plan** = Position der aktuellen Phase mit `release = active`, **oder** `prepared` mit `release_on ≤ local_day`, **oder** `prepared` mit `release_with_phase_id`, dessen Phase-Position ≤ Position der aktuellen Phase ist (Annahme zur Semantik von PB-6, O-28). Reine Funktion `isReleased(item, plan, localDay)` in `lib/logic/plan_today.dart`, gleiche Fixtures im KI-Plan.
- **Datumsbasis (MAJOR-2, gewählte Lösung):**
  1. **Ein Kalendertag des Patienten ist immer der lokale Tag seines Geräts (`local_day`).** Das Gerät berechnet ihn und sendet ihn mit (Check-ups, Sessions, Ergebnisse; im KI-Plan als Eingabe von `manny-today`).
  2. **Sicherheitsregeln hängen nicht vom Datum ab.** `app.patient_can_see_exercise`, die `exercises`-Policy (6.2) und die Storage-Policy (6.11) prüfen nur „Übung steht in einer Position des aktuellen Plans (aktiv oder vorbereitet)“. Begründung: Der Patient liest ohnehin alle `plan_items` seines Plans einschließlich vorbereiteter Positionen (6.2); die Datumsprüfung schützte nur Name, Beschreibung und Bild und erzeugte die Lücke 0–2 Uhr (MESZ), in der eine Position sichtbar, ihre Übung aber per RLS verweigert war. „Freigegeben“ ist damit eine Anzeige- und Auswahlregel (App, `manny-today`), keine Zugriffsregel. Diese gelockerte Übungs- und Storage-Policy (Patient liest Übungen aktiver **und** vorbereiteter Positionen seines aktuellen Plans über die API) ist vom Nutzer ausdrücklich bestätigt (N-16).
  3. **Serverlogik, die einen Tag braucht, bekommt ihn als Eingabe** und prüft nur die Plausibilität; die Grenze hängt davon ab, ob der Aufruf sofort oder über die Warteschlange kommt (MAJOR-B):
     - **Sofortige Aufrufe** (`start_new_injury`, `create_patient` für das Standard-Bezugsdatum; im KI-Plan `manny-today`, S8b Regel 3): `local_day` innerhalb von ±1 Tag um das UTC-Datum des Servers (deckt alle Zeitzonen UTC−12 bis UTC+14 ab), sonst `invalid_local_day`.
     - **Warteschlangen-Einträge mit Tagesprüfung** (`submit_daily_checkup`): Ein offline erfasster Check-up kann Tage später ankommen. Gültig ist deshalb `Bindungstag − 1 ≤ local_day ≤ UTC-Datum + 1` (Bindungstag = UTC-Datum von `patients.bound_at` der aktuellen Bindung; −1/+1 wegen der Zeitzonen). **Kein Höchstalter:** Offline-Zeiträume haben keine festgelegte Obergrenze, und jede feste Grenze würde einen echten, nur spät gesendeten Check-up verwerfen. Begründung der Untergrenze: Die Warteschlange gehört zur aktuellen Bindung (bei Neubindung bzw. gelöster Bindung werden die lokalen Daten verworfen, B-11), ein Eintrag mit früherem Tag kann also nur aus einer falschen Geräteuhr stammen. Annahme B-35.
     - **Nie still verloren:** `invalid_local_day` ist in der Warteschlange **kein** Grund zum Verwerfen; der Eintrag wird zurückgestellt (8.11). Verspätet angenommene Check-ups werden ganz normal ausgewertet (Warnzeichen für ihren Tag und nachträglich für Folgetage, 6.9).
     - Kein Server-Code verwendet `current_date`/`now()::date` für Patienten- oder Physio-Tage; Ausnahme nur die Plausibilitätsgrenzen oben, Bereinigung (`redeem_attempts` > 24 h) und Ablauf der Einladung (`expires_at`, `timestamptz`).
  4. Alternative „Zeitzone je Patient speichern“ verworfen: neues Datenfeld, und der Server müsste trotzdem der Geräteuhr bzw. -zone vertrauen.
  5. **Gemeinsame Fixtures „Mitternacht/Zeitzone“** (`supabase/tests/fixtures/local_day/*.json`, angelegt in L2 von F2-1, weil die DB-Tests von L2 sie brauchen und F2-1 parallel zu L1 nur unter `supabase/` schreibt (MINOR-E); genutzt von SQL-Tests, Dart-Unit-Tests ab L3 (nur lesend, Pfad relativ zu `app/`) und den Server-Tests des KI-Plans): (a) Europe/Berlin 00:30 MESZ am Tag D (UTC noch D−1) mit `release_on = D` → freigegeben, Übung und Bild für den Patienten lesbar; (b) gleiche Lage 23:30 am Tag D−1 → nicht freigegeben, Übung trotzdem lesbar (Position des Plans); (c) Pacific/Auckland UTC+13 und America/Los_Angeles UTC−7 jeweils kurz vor und nach Mitternacht → `local_day` gültig; (d) `local_day` = UTC-Datum + 2 → `invalid_local_day` (sofortige Aufrufe und Warteschlange); `local_day` = UTC-Datum − 2 → `invalid_local_day` nur bei sofortigen Aufrufen; (e) Umstellungstag Sommer-/Winterzeit Europe/Berlin (2026-10-25); (f) Session über Mitternacht → alle Ergebnisse mit `local_day` des Session-Starts (8.5); (g) Check-up um 00:10 nach Mitternacht zählt für den neuen Tag (Anstiegs- und Stimmungsregel, 6.9); (h) Check-up am Tag D offline erfasst, am Tag D+3 gesendet → angenommen und ausgewertet; Check-up mit Tag vor dem Bindungstag − 1 → `invalid_local_day`, in der App zurückgestellt (DB-T83, U `outbox`).

### 6.8 Verletzungen und Historie (PB-7, PB-G)

- Genau eine aktive Verletzung je Patient (partieller Unique-Index). Daten mit `injury_id` (Training, Ergebnisse, Check-ups, Fragen, Notizen) bekommen sie serverseitig (6.3).
- Historie je Verletzung (Sicht `v_injury_history`, `security_invoker`): Zeitraum (`started_on`–`closed_on`), Dauer bis Abschluss (Tage), Trainingstreue (Tage mit ≥ 1 erledigter Übung / Kalendertage des Zeitraums, **Annahme O-30**), Schmerzverlauf (aus `daily_checkups.pain`), Phasen (aus dem Plan der Verletzung), Notizen.
- Neue Verletzung: `start_new_injury` (6.4). Die Historie bleibt erhalten (DB-T62).
- Patient: Pfad, Heute und Session nutzen nur den aktuellen Plan. Was der Patient von abgeschlossenen Verletzungen sieht, ist nicht spezifiziert → Annahme: nichts zusätzlich in Ausschnitt 2 (O-38).
- Das lokale Pfad-Fortschrittsmodell (B-14) startet bei neuer Verletzung neu (neue Phasen-IDs); Streak und Freezes bleiben (Annahme B-26).

### 6.9 Check-ups und Stimmungs-Nachricht (C-1–C-3)

- **Check-up nach der Einheit** (`submit_session_checkup`): Pflicht `rating` 1–5; optional je Position `difficulty`, `weight_increased`, bei übersprungenen `skip_reason`. Nach dem Speichern beim Physio im Verlauf (Kacheln „Übungen gut/schlecht“, „Training seit dem letzten Termin“).
- **Tages-Check-up** (`submit_daily_checkup`): einmal je lokalem Tag; sechs Werte (6.2, O-18, O-19). Wegklicken wird **nur lokal** gespeichert (B-22), weil es nichts an den Physio meldet.
- **Warnzeichen aus dem Tages-Check-up** (Trigger, Regeln aus `warning_rules`, Werte entschieden in N-14/O-2):

  | Regel (`reason_code`) | Bedingung für den Tag D | `notify_patient` |
  |---|---|---|
  | `pain_high` | `pain ≥ 7` | `true` (fester Hinweis O-12) |
  | `pain_rise` | Check-up am Vortag D−1 **derselben Verletzung** vorhanden **und** `pain(D) − pain(D−1) ≥ 3`; ohne Check-up am Vortag oder mit Vortag einer anderen Verletzung keine Anstiegsregel (N-16) | `true` (fester Hinweis O-12) |
  | `swelling_severe` | `swelling = 3` („stark“) | `true` (**derselbe** feste Hinweis wie bei hohem Schmerz) |
  | `mood_low_streak` | D ist der 5. oder ein weiterer aufeinanderfolgender Kalendertag mit Check-up **derselben Verletzung** und `mood ≤ 2` (O-2a/O-2b, N-16) | `false` |

  Ein Check-up kann mehrere Warnzeichen auslösen (z. B. Schmerz 8 und Schwellung 3); `submit_daily_checkup` meldet `warning_raised = true`, sobald zu diesem Check-up mindestens eines mit `notify_patient = true` besteht.
- **Stimmungs-Nachricht (C-3, N-10, O-2a/O-2b [entschieden]):** Regelart `mood_streak` mit `mood_max = 2` und `days = 5`. Kette = aufeinanderfolgende Kalendertage (`local_day`), an denen ein Check-up mit `mood ≤ 2` vorliegt; ein Tag ohne Check-up oder mit `mood ≥ 3` unterbricht.
- **Zählweise je Verletzung (N-16):** Kette und Vortag werden nur über Check-ups mit derselben `injury_id` gebildet (`injury_id` des Check-ups = aktive Verletzung beim Eingang, B-32). Mit einer neuen Verletzung beginnt die Zählung neu; ein Check-up einer anderen Verletzung zählt weder als Vortag noch als Kettenglied. Am 5. Tag der Kette entsteht ein Warnzeichen, **an jedem weiteren Tag der Kette erneut eines** (Tag 6, 7, …).
- **Reihenfolgeunabhängig (MINOR-5):** Warnzeichen aus dem Check-up gehören zu einem Tag (`warning_signs.local_day`, Unique je `patient_id`, `reason_code`, `local_day`). Beim Eingang des Check-ups für Tag X wertet der Trigger aus:
  - alle Tagesregeln für X;
  - `pain_rise` zusätzlich für X+1, falls dessen Check-up schon vorliegt (der Vortag kam verspätet);
  - `mood_low_streak` für X und für die schon vorliegenden Folgetage X+1, X+2, … der zusammenhängenden Kette (jeweils nur derselben Verletzung).
  Fehlende Warnzeichen werden angelegt (`ON CONFLICT DO NOTHING`), vorhandene nie gelöscht. Ergebnis: Die Menge der Warnzeichen hängt nur von den Check-up-Daten ab, nicht von der Eingangsreihenfolge. Ein verspätet eingegangener Check-up kann deshalb ein Warnzeichen für einen späteren, schon gemeldeten Tag nachträglich erzeugen. Das ist gewollt (der Physio erfährt den Sachverhalt, nur später; vom Nutzer bestätigt, N-16) und bleibt selten, weil die Warteschlange je Gerät streng in Einfügereihenfolge sendet (FIFO, 8.11). Ein nachträgliches Warnzeichen mit `notify_patient = true` erreicht den Patienten nicht mehr als Hinweis; es steht beim Physio wie jedes andere.
  - Ergebnis: `warning_signs` mit `source = 'checkup'`, `reason_code = 'mood_low_streak'`, ohne weitere Details, `notify_patient = false`.
  - Gegenüber dem Patienten **keine** Reaktion: `submit_daily_checkup` meldet sie nicht (DB-T58), Manny reagiert nicht (V2-57), kein Hinweis, keine Ansicht.
  - Beim Physio: Markierung in der Liste (PB-A AK 1) und in der Kachel „Befinden, Motivation, Warnzeichen“ (PB-B AK 4).
- **Eine gemeinsame Meldung je Eingang (N-16):** Schließt ein verspäteter Check-up eine Lücke, können mehrere `mood_low_streak`-Warnzeichen auf einmal entstehen (z. B. Tag 5 kommt nach den Tagen 6 und 7 an → Warnzeichen für 5, 6 und 7). Es bleibt **je Tag ein Warnzeichen** (Unique je Tag, Reihenfolgeunabhängigkeit unverändert). Entstehung der gemeinsamen Meldung:
  - **Trigger** (`app.raise_warning_signs`, L5): setzt an allen in diesem Eingang angelegten Warnzeichen `trigger_checkup_id = NEW.id`.
  - **Ansicht** (Physio-Liste L6 und `v_wellbeing_overview`/Kachel 2 L7): `mood_low_streak`-Warnzeichen mit gleicher `trigger_checkup_id` werden zu **einer** Meldung zusammengefasst (betroffene Tage im Detail); Marker und Zählung „neu“ zählen diese Meldung einmal. `mark_warnings_seen` setzt `seen_at` weiter je Warnzeichen. Es gibt in Ausschnitt 2 keine weitere Benachrichtigung (kein Push), die Meldung ist der Marker bzw. der Eintrag.
  - Test: DB-T84.
  - Ein Hilfsangebot-Hinweis an den Patienten (Anregung aus der App-Experience-Prüfung) ist **nicht** Teil des Plans (O-21).
- Tests: DB-T25, DB-T27, DB-T41 (angepasst), DB-T55–DB-T58, DB-T60, DB-T75, DB-T77, DB-T82, DB-T83, DB-T84.

### 6.10 Fragen des Patienten und Notizen (PB-C, PB-D)

- `patient_questions`: Patient stellt über `ask_physio`; sieht eigene Fragen mit Status; Physio der Praxis liest und markiert „besprochen“ (auch zurücknehmbar, Annahme). Kein Chat: keine Antworten, keine Verbindung zu Chat-Tabellen; nicht im Manny-Kontext und nicht im Physio-KI-Briefing (Annahme, KI-Plan v2.5).
- `practice_notes`: nur Physios der Praxis, mit Autor und Datum; **keine Patienten-Policy**, auch nicht über Sichten (DB-T50). Bearbeiten/Löschen nicht vorgesehen (O-26).
- Löschen (O-9): Fragen sind Patientendaten → werden gelöscht; Notizen sind Einträge des Physios → bleiben bei der Praxis.

### 6.11 Übungs-Baukasten, Bilder, Zuweisung (PB-F, PB-6, T-6) – L8

- **Felder:** 6.2 `exercises`; Pflicht Name und Beschreibung (Constraint + Formularprüfung mit Feldnennung, P-3 AK 2). Praxisweit wiederverwendbar (B-13).
- **Bilder:** Bucket `exercise-images` (privat). Pfad `<practice_id>/<exercise_id>/<image_id>.<ext>`; Formate und Größe über Bucket-Einstellungen (`allowed_mime_types`, `file_size_limit`, **[Vorschlag] JPEG/PNG/WebP, 5 MB; O-24**). Policies auf `storage.objects`:
  - INSERT/DELETE: Physio, erstes Pfadsegment = eigene Praxis, Übung gehört der Praxis;
  - SELECT: Physio derselben Praxis; Patient nur, wenn `app.patient_can_see_exercise(exercise_id)` (Übung in einer Position seines aktuellen Plans, aktiv oder vorbereitet, ohne Datumsbezug, 6.7; vom Nutzer bestätigt, N-16);
  - `anon`: nichts. Abruf per Download mit Sitzung, keine öffentlichen URLs.
  - Katalog-Bilder: CuraOne hat keine; Anzeige = neutrale Illustration (RF-1, Brief 12). KI-Bilder erst Ausschnitt 3 (KI-Plan).
- **„Damit anfangen“ (PB-6):** Ja → `release = active`; Nein → `prepared` mit Datum oder Phase (6.7).
- **Zuweisung beim Speichern:** `assign_exercise(exercise_id, [{patient_id, phase_id, release, release_on, release_with_phase_id, sets, reps, duration_sec, weight_kg, pause_sec}])`: alle Patienten derselben Praxis, Phase gehört zum aktuellen Plan des jeweiligen Patienten, Plan nicht abgeschlossen, **`release_with_phase_id` (falls gesetzt) ist eine Phase desselben Plans** (MINOR-8; Freischalt-Regeln wie `save_plan`, 6.7: `active` ohne Freischalt-Felder, `prepared` mit genau einem); je Patient neue Position am Ende der Phase, Werte aus den Übungs-Vorgaben, wenn nicht angegeben; `version + 1` je Plan; **alles oder nichts** (eine ungültige Zuweisung → nichts geändert, DB-T67). Konflikt mit gleichzeitigem `save_plan` über die Plan-Sperre.
- Tests: DB-T66–DB-T69, Stack-Tests Storage.

### 6.12 Sichten für die Kacheln (PB-B) – L7

Alle `security_invoker = true`, nur über Tabellen, die der Physio ohnehin lesen darf; keine Sicht über Chat-Tabellen (ab Ausschnitt 3 statisch und per `pg_depend` geprüft, KI-Plan DB-K12):
- `v_training_since_last_appointment` – Trainingstage (≥ 1 erledigte Übung) / Tage seit letztem Termin, letzter gemeldeter `streak_after`, übersprungene Übungen mit Grund. „Letzter Termin“ = letzter vergangener Termin aus `appointments` mit `created_by_role = physio`; ohne → seit `bound_at` (Annahme O-30).
- `v_exercise_feedback` – je Übung Anzahl leicht/passend/schwer/Schmerz und „Gewicht erhöht“.
- `v_pain_trend` – Schmerz je Tag, 30 Tage.
- `v_wellbeing_overview` – letzte Werte Wohlbefinden, Motivation, Stimmung, Einschränkungs-Stufe, **Schwellung** (O-18, Kachel 2); offene Warnzeichen zuerst (inkl. `swelling_severe`, `pain_rise`); `mood_low_streak` je `trigger_checkup_id` zu einer Meldung zusammengefasst (6.9, N-16).
- **Kachel 6 „Phase und nächstes Ziel“ (MINOR-7):** keine eigene Sicht; Datenquelle ist der Plan der aktiven Verletzung, den der Physio ohnehin lädt (`plans.current_phase_id`, `phases.title`, `phases.planned_weeks`, `phases.position`, „Woche N“ aus `injuries.reference_date`). „Nächstes Ziel“ = Titel der nächsten Phase nach Position (O-42 entschieden, N-16); in der letzten Phase **[Vorschlag]** „letzte Phase“ (Wortlaut F2-D2 D). Reine Funktion `phase_summary` in `lib/logic/` (U-Test).
- `v_injury_history` – 6.8.
- Tests: DB-T72 (alle Sichten `security_invoker`), DB-T06/DB-T08 erweitert um Sichten.

### 6.13 Löschen (O-9, M-4; erweitert)

`delete_my_data()` wie v1.2 (Aufrufer prüfen, `FOR UPDATE`, Löschen solange `active`, Auth-Konto löschen, `already_deleted` idempotent). **Löschumfang erweitert:** `training_sessions`, `exercise_results`, `session_checkups` (+ Positionen), `daily_checkups`, `warning_signs` des Patienten, `patient_questions`, eigene `appointments`, `consents`, `account_events`. Außerdem wird `patients.manny_look` auf `null` gesetzt (Einstellung des Patienten, O-41). **Bleibt bei der Praxis:** Patientenzeile (Stammdaten), Verletzungen, Pläne, Behandler, Krankengeschichte, Physio-Termine, `practice_notes`, Übungen und Bilder. DB-T29, DB-T43, DB-T71, DB-T85.

### 6.14 Pflichtliste je neuer Tabelle mit Patientendaten

| Pflicht | Prüfung |
|---|---|
| RLS an, keine Rechte außer den genannten | DB-T01 (Inventar) |
| Praxis-Isolation | DB-T06 |
| Patient sieht nur sich | DB-T08 |
| anonyme/ungebundene Sitzung sieht nichts | DB-T04 |
| Schreibsperre bei Patienten-Schreibvorgängen | DB-T70 |
| im Löschumfang oder ausdrücklich „bleibt bei der Praxis“ | DB-T71 |
| `injury_id` serverseitig | DB-T61 |
| keine Chat-Bezüge (ab Ausschnitt 3) | KI-Plan DB-K12 |

---

## 7. Auth und Zugang

### 7.1 Physio (P-1)
Unverändert (E-Mail + Passwort, keine Selbstregistrierung, Zustände Laden/falsche Daten/offline/Sitzung abgelaufen/kein Physio-Konto, Abmelden). Am Handy und am Rechner gleich (PB-1).

### 7.2 Patient (A-1)
Ablauf unverändert aus v1.2 5.2 (Startbildschirm mit Code, anonyme Anmeldung, `redeem_invitation`, Ergebniscodes, `ok_rebound`-Hinweis, altes Gerät nach Neubindung, B-11).
**Einwilligung `physio_sharing-2` (neu wegen C-1–C-3, PB-B, PB-D):** nennt ausdrücklich, dass der Physio Verlauf, erledigte und übersprungene Übungen mit Grund, die Check-ups (einschließlich **Schwellung** und **Stimmung**), die Fragen an den Physio und Warnzeichen sieht – auch Warnzeichen aus dem Manny-Chat einschließlich Hinweisen auf eine Krise (nur Stufe und Zeitpunkt, ohne Chattext, N-2) und eine Meldung, wenn die Stimmung an **5 aufeinanderfolgenden Tagen mit Check-up sehr schlecht** (Smiley 1 oder 2) war, und **an jedem weiteren solchen Tag erneut** (ohne Details; ein Tag ohne Check-up beendet die Zählung, mit einer neuen Verletzung beginnt sie neu; die App zeigt dem Patienten dazu nichts an; C-3, O-2a/O-2b, N-16) – und dass er den Manny-Chat selbst nie sieht. Wortlaut F2-D2 A/Nutzer.

---

## 8. Patienten-App

### 8.1 Zustandsdokument und Migration (L3)
Schema 1 → 2 entsteht schon in **L1** (Manny-Look, Onboarding 5 Schritte, 3.5). L3 ergänzt **Schema 3**: Abschnitt `account {patientId, boundAt}`; Schlüssel `curaone.framework.v1`, `curaone.outbox.v1`, `curaone.deletion.v1`, **neu** `curaone.display.v1` (L1), `curaone.session.v1` (L4), `curaone.checkup.v1` (L5, Wegklicken je Tag) in `kAllStorageKeys`. Migration 2 → 3: ohne `account` → Startbildschirm (außer Demo-Modus); `mannyLook` bleibt erhalten. Nach dem Einlösen startet der lokale Fortschritt neu (B-9), **der lokale Manny-Look bleibt**. Der Code-Start enthält den Look-Schritt aus L1 **vor dem Code-Feld** (O-43 entschieden; Einbettung F2-D2 Teil A); wer schon aus L1 einen Look gewählt hat, wird nicht erneut gefragt. Fixtures `state_v2.json`, `state_v3.json`.
**Manny-Look und Konto (O-41, N-16):** Lokal bleibt die Quelle für die Anzeige. Vor der Bindung wird nichts gesendet. Nach `ok` (erste Bindung) stellt die App `manny_look_set` mit dem lokalen Wert in die Warteschlange. Nach `ok_rebound` (Neubindung auf einem anderen Gerät) gilt bis zur Klärung von O-44 Annahme B-36: Hat das Konto schon einen Wert, übernimmt das neue Gerät diesen lokal (Zweck von O-41: Look bleibt beim Gerätewechsel erhalten); ist er `null`, wird der lokale Wert übertragen. Jede spätere Änderung im Profil: lokal sofort, dann `manny_look_set`. Spätere Ladevorgänge überschreiben den lokalen Wert nicht.

### 8.2 Laden und Zwischenspeicher (L3)
Unverändert: Laden bei Start, Fortsetzen und Öffnen von „Heute“ (P-3 AK 3); Fehler/offline → Zwischenspeicher mit „nicht aktuell“; ohne Zwischenspeicher Fehlerzustand mit „Nochmal versuchen“; `access_deleted`/gelöste Bindung → lokale Daten löschen, Startbildschirm. Das Framework enthält jetzt auch: Verletzung, Freischalt-Felder, Material, Ort, Pause, Bilder-Metadaten (ab L8), offene Fragen (ab L5), **Schmerzschwelle für die Kürzung** (E-28 = 6, ab L5; 8.7).

### 8.3 Pfad aus Physio-Phasen (O-4; L3)
Regeln 1–11 aus v1.2 6.3 unverändert (Aufbau, IDs, Erledigt nur über `completedUnitIds`, aktuelle Unit, „ausgelassen“, „gesperrt“, Planänderung, Kopfzeile aus `injuries.reference_date`, Leerzustand). **Neu:** Eine Unit gilt als erledigt, sobald der Tag für den Streak zählt (erste erledigte Übung, T-5); nimmt der Patient am selben Tag alle Häkchen zurück, wird auch die Unit wieder offen (Annahme B-23). Darstellung als `OrbNode` (L1).

### 8.4 Heute aus dem Plan (O-10, A-2, Ablauf 1 und 3; L3)
- **Dauer je Position** (`estimateMinutes` in `lib/logic/exercise_duration.dart`, N-7 angepasst nach O-17 [entschieden, N-14]); P = `pause_sec` des Physios, ohne Angabe 60 s; S = `max(sets, 1)`; erste zutreffende Zeile:
  - `duration_sec` gesetzt (Dauer je Satz) → `max(1, aufrunden((S × duration_sec + (S − 1) × P) / 60))`;
  - sonst `sets` und `reps` gesetzt → `max(1, aufrunden((sets × reps × 4 s + (sets − 1) × P) / 60))`;
  - sonst nur `sets` → `sets × 1 Minute`; sonst 5 Minuten.
  Gleiche Regel im Physio-Web (Anzeige „ca. N Min“), in der Kürzung (8.7) und im KI-Plan (S8b Regel 6); gemeinsame Fixtures (alle Zweige, P gesetzt/leer).
- **Liste:** nur **freigegebene** Positionen (6.7, mit `local_day` des Geräts) der aktuellen Phase der Reihe nach bis zur Zeitwahl 10/20/30 (mindestens eine). Je Zeile Bild (oder Illustration), Name, Umfang, Material, Ort-Chips, Abhak-Kreis (V2-42).
- **Übungsdetail:** Bilder Start/Ende (oder Illustration), Beschreibung, Grenzen (Sätze, Wdh., Dauer, Gewicht, Pause, Belastungshinweis), Material, Ort; Tauschen/Entfernen mit Rückgängig; Timer bzw. Zähler für genau diese Übung (TR-3.1, L4).
- **Tauschen:** übrige freigegebene Positionen der aktuellen Phase, die heute nicht in der Liste stehen.
- **Abhaken (Ablauf 3):** Häkchen → `exercise_results` (`done`, `training_session` der Art `checklist` für den Tag, Geräte-ID je Tag) über die Warteschlange; erste Übung zählt für den Streak (T-5); Rückgängig am selben Tag (löscht das Ergebnis). Nach der letzten Übung oder „Fertig für heute“: Zusammenfassung (L3), danach Check-up nach der Einheit (ab L4).
- **„Training starten“** (`PrimaryPill`) erscheint erst mit L4; L3 baut nur das Abhaken (keine Knöpfe ohne Funktion).
- **„Training eintragen“** aus Ausschnitt 1 entfällt mit L3 (ersetzt durch Abhaken/Session, Brief 7.2).
- **Leerzustand:** „Heute noch nichts geplant.“; „Eigene Übung“ laut V2-43 steht im Widerspruch zu O-15 (eigene Übung des Patienten entfällt) → **O-22**; Annahme bis Klärung: O-15 gilt, „Eigene Übung“ entfällt im Backend-Modus, bleibt im Demo-Modus.
- Termine aus `appointments`.

### 8.5 Geführte Session (Ablauf 2, T-1–T-6; L4)
- **Zustandsautomat** `lib/logic/session_machine.dart` (rein, testbar): Packliste → Übung (Satz n, Zählen bzw. Countdown) → Pause → … → Übung fertig → nächste → Ende. Ereignisse: Zählen +1/−1, Satz fertig, Pause überspringen, Pause/Fortsetzen, Überspringen, Beenden, Schmerz melden (Variante/Abbruch). **Zeitstempel statt Dauern** (Brief 9); Gesamtzeit = Summe aktiver Abschnitte.
- **Packliste:** Material aller Übungen des Tages, zusammengeführt (Groß-/Kleinschreibung ignoriert, Annahme O-36), abhakbar; Tauschen nur gegen freigegebene Positionen derselben Phase (V2-45); „Los geht’s“.
- **Übungsbildschirm:** Fortschritt „Übung N von M“, Gesamtzeit, Bild/Illustration, Name, Kurzanleitung (`short_instruction`, sonst erste Zeile der Beschreibung, B-27), Material, Ort, „Satz N von M“, `RepCounter` „x / y“ bzw. Countdown mit Ansage „noch 10 Sekunden“, Ton/Vibration am Ende (abschaltbar, Standard an, B-17).
- **Satz fertig:** Pausen-Timer automatisch (Dauer `pause_sec`, sonst 60 s, B-28), überspringbar.
- **Übung fertig:** kurzes Erfolgssignal (bei reduzierter Bewegung statisch), automatisch nächste.
- **Jederzeit:** Pause (alle Timer halten), Überspringen (`skipped`), Beenden (Dialog; Erledigtes gespeichert), Schmerz melden (Sheet: freigegebene leichtere Variante **nur falls E-30 entschieden und gesetzt**, sonst nur Abbruch; Manny „Trösten“).
- **Ende:** Zusammenfassung (Gesamtzeit, erledigte Übungen, Streak), Manny-Feier, dann Check-up nach der Einheit.
- **Hintergrund/Sperre:** Zustand in `curaone.session.v1`; beim Zurückkehren pausiert an derselben Stelle (`AppLifecycleListener`). **Mitternacht:** alle Ergebnisse tragen den `local_day` des Session-Starts (Erledigtes zählt für den Vortag, wie Ausschnitt 1).
- **Offline:** läuft vollständig; Ergebnisse über die Warteschlange.
- **Barrierefreiheit:** Ansagen (`SemanticsService.announce`) für Timer und Zähler, alles ohne Gesten (Schaltflächen für +1, −1, Pause, Überspringen), Ton/Vibration abschaltbar und nie einzige Information, bei „Bewegung reduzieren“ keine Feier-Animation.
- **Ton:** zuerst ohne neues Paket (`SystemSound`, `HapticFeedback`); reicht das auf einer Zielplattform nicht (insbesondere Web), wird ein Audio-Paket mit Begründung vorgeschlagen (O-37).

### 8.6 Check-ups (Ablauf 4; L4/L5)
- **Nach der Einheit (L4):** Pflicht „Wie lief’s?“ (`RatingScale`, 5 Emoji-Smileys mit Text-Label, N-11); „Details je Übung?“ optional (leicht/passend/schwer/Schmerz, „Gewicht erhöht“ ja/nein – Annahme B-18), bei übersprungenen „Warum übersprungen?“ (Zeit/Schmerz/Material fehlte/anderes). „Speichern“ erst nach Pflichtantwort; „Später“ lässt die Karte bis Tagesende auf Heute (Brief 12). Senden über die Warteschlange (`submit_session_checkup`).
- **Tages-Check-up (L5):** `DailyCheckupCard` oben auf Heute, einmal pro Tag; **sechs** Fragen nacheinander (Wohlbefinden, Schmerz 0–10, Motivation, Einschränkungen als Einzelwert-Skala keine/leicht/deutlich/stark, Stimmung, **Schwellung 0–3**; Reihenfolge, Stufenbezeichnungen und „Frage N von 6“ laut Brief 7.2 mit Brief-Ergänzung F2-D2 Teil B); „Erledigt, danke!“; Wegklicken lokal bis zum nächsten Tag. Senden über die Warteschlange (`submit_daily_checkup`); auch Tage später gesendete Check-ups werden angenommen und ausgewertet (6.7 Nr. 3, 8.11). Bei `warning_raised = true` (Schmerz ≥ 7, Anstieg ≥ 3 zum Vortag oder Schwellung 3) derselbe feste Hinweis (O-12, O-2; offline erst nach dem Senden). Stimmung: keine Reaktion (C-3).

### 8.7 Kürzung bei Schmerz (Ablauf 4b Schritt 4, E-36; L5)
- Ablauf 4b verlangt die Kürzungsregel E-36 schon ohne KI. Die deterministische Funktion `fallbackToday(phaseItems, timeChoice, pain)` (KI-Plan v2.5, 4.2.3) wird daher in L5 gebaut: ab **Schmerz ≥ 6** (E-28 [entschieden]) halbe Zeitwahl (mindestens 5 Minuten), leichtere Variante bevorzugt (nur falls E-30), sonst Kürzung der Sätze bzw. der Dauer je Satz (`max(1, abrunden(duration_sec / 2))` Sekunden, O-17 b) bzw. der Wiederholungen, Hinweis „Heute etwas kürzer“ (Brief 7.2; Wortlaut F2-D2 B/E-17).
- Schmerzwert = Schmerz aus dem heutigen Tages-Check-up; ohne Check-up keine Kürzung.
- Die Schwelle E-28 (= 6) kommt mit dem Framework (8.2), damit die Kürzung auch offline wirkt und Server und App denselben Wert nutzen; sie ist kein Geheimnis. Die Warnzeichen-Schwellen (O-2) bleiben serverseitig.
- Änderung gegenüber KI-Plan v2.2 4.2.3 („Ausschnitt 2 kennt keine Schmerzkürzung“): durch den freigegebenen Ablauf 4b überholt; im KI-Plan v2.3/v2.4 nachgezogen.
- Dauer-Zweig der Kürzung in Sekunden je Satz (O-17 b, entschieden); gemeinsame Fixtures mit dem KI-Plan (6.2 dort).

### 8.8 Frage an meinen Physio (PB-D; L5)
Profil-Zeile „Frage an meinen Physio“ mit Zahl offener Fragen; Eingabe (Länge O-34), Liste eigener Fragen mit Status „offen“/„besprochen“; Senden über die Warteschlange (`ask_physio`). Kein Chat, keine Antworten.

### 8.9 Akte (A-4; L3)
Profil-Zeile „Mein Plan und meine Verletzung“: Verletzung, Phase, Plan-Überblick, Behandler, Termine (eigene anlegen/ändern/löschen), Krankengeschichte (lesend). Physio-Einträge nur lesen (DB-T15). Dokumente später (O-5).

### 8.10 „Alles löschen“ mit Backend (O-9, M-4; L3)
Reihenfolge unverändert (Sperre, `OutboxSender.pauseAndDrain()`, Merkzeichen, `delete_my_data()` – setzt auch `patients.manny_look` auf `null` –, lokal verwerfen inkl. Session-Zustand, Darstellung, zurückgestellter Warteschlangen-Einträge und Manny-Look (Vorbelegung „Mit Brille“, 3.5), Abmelden). E-24 bleibt Annahme/offen.

### 8.11 Ausgangswarteschlange (m-4)
**Reihenfolge:** je Gerät strikt in Einfügereihenfolge (FIFO); ein Eintrag mit dauerhaftem Fehler wird verworfen und blockiert die folgenden nicht (MINOR-5, 6.9). Arten: `training_session_upsert` (Start/Ende einer Session, mit `plan_id`), `exercise_result_insert`, `exercise_result_delete`, `session_checkup_submit`, `daily_checkup_submit`, `question_submit`, `appointment_upsert`, `appointment_delete`, **neu** `manny_look_set` (L3, O-41). Fehlerklassen unverändert (Netz/5xx später; 401 erst Sitzung erneuern; `23505` Erfolg; `42501` dauerhaft; andere 4xx dauerhaft; **neu:** `already_submitted` beim Tages-Check-up = Erfolg). **Neu (MAJOR-B):** `invalid_local_day` ist **nicht** dauerhaft: Der Eintrag wird zurückgestellt (bleibt in `curaone.outbox.v1`, blockiert die folgenden nicht, neuer Versuch bei jedem Start und jeder neuen Verbindung) und erst bei Erfolg oder durch „Alles löschen“ entfernt. Ein Check-up geht so nie still verloren (Annahme B-35).

### 8.12 Demo-Modus (O-14) und Manny ohne KI
Nur Prüfumgebung und `--dart-define=CURAONE_DEMO=true`: Onboarding und Beispielpfad aus Ausschnitt 1 im neuen Look (B-20). Manny-Texte ohne KI bleiben (feste Texte); Manny in der gewählten Variante (3.5); `MannyContext` aus dem Framework; Manny reagiert nicht auf Stimmung (V2-57), nur auf Schmerz melden (Trösten = Pose `traurig`, Ergänzung 1, 6.3).

---

## 9. Physio-Bereich: Funktionen und Zustände

| Bereich | L | Funktionen | Zustände |
|---|---|---|---|
| Anmeldung, Konto | 6 | E-Mail, Passwort, Anmelden; Konto: Name, Praxis, Abmelden | leer, Laden, falsche Daten, offline, Sitzung abgelaufen, kein Physio-Konto |
| Shell | 6 | 4 Ziele; Leiste < 840 dp, Seitenleiste ≥ 840 dp | – |
| Patientenliste (PB-A) | 6 | Reiter „Meine Patienten“ (`main_physio_id = ich`) / „Praxis“ (alle, N-4); Suche nach Name (Vor- und Nachname, ohne Groß-/Kleinschreibung, im geladenen Bestand, B-29); Zeile: Initialen, Name, Verletzung · Phase, letzter Termin, Warnmarker (Symbol + Text) in beiden Reitern, Stimmungs-Warnzeichen eines Eingangs als eine Meldung (6.9, N-16); „Neuer Patient“; Hauptphysio ändern | Laden, leer (je Reiter), keine Treffer, Fehler, mit Warnzeichen |
| Neuer Patient (PB-E) | 6 | 6.6 | Formular ungültig, Speichern, Fehler mit „Nochmal versuchen“, QR angezeigt, eingelöst, abgelaufen; „Neuen Code erzeugen“ mit Hinweis „bisheriges Gerät verliert den Zugang“ |
| Plan (P-3) | 6 | Phasen anlegen/umbenennen/ordnen/löschen, geplante Wochen, aktuelle Phase; Positionen aus Katalog/Praxis mit Sätzen, Wdh., Dauer (mit Schätzung), Gewicht, Pause, Belastungshinweis, Phase, Freischaltung (aktiv/vorbereitet ab Datum/Phase); ordnen, entfernen; Speichern; Vorlage übernehmen beim Anlegen | Laden, leer, ungespeichert, Validierungsfehler mit Feldnennung, „aktuelle Phase fehlt“, Speichern, Konflikt, gespeichert, abgeschlossen (nur lesen) |
| Akte (P-4) | 6 | Behandler, Termine, Krankengeschichte: anlegen, ändern, löschen; Patienten-Termine lesend | Laden, leer, Fehler, Speichern, Löschen bestätigen |
| Patientenübersicht (PB-B) | 7 | Kopf-Karte (Name, Verletzung · Woche · Phase, „Letzter Termin vor N Tagen“, „Historie“); Slot Kachel 1 leer (Ausschnitt 3); Kacheln 2–8 (Kachel 2 mit Schwellung und Einschränkungs-Stufe, Kachel 6 aus dem Plan, 6.12); Detail je Kachel (Sheet am Handy, Seitenpanel am Rechner); `seen_at` beim Öffnen (O-11) | Laden, Fehler, leer je Kachel („noch keine Daten“) |
| Notiz (PB-C) | 7 | anlegen; Liste mit Autor, Datum; Kachel zeigt die neueste | Speichern, Fehler |
| Fragen (PB-D) | 7 | Kachel mit offenen zuerst; „besprochen“ setzen/zurücknehmen | leer, Fehler |
| Historie (PB-G) | 7 | je Verletzung Zeitraum, Dauer, Trainingstreue, Schmerzverlauf, Phasen, Notizen; „Neue Verletzung“ | Laden, leer, Fehler |
| Übungen (PB-F) | 8 | Liste Katalog + Praxis (Beispiele gekennzeichnet), Baukasten (6.11), Bilder, Zuweisung | Formular ungültig mit Feldnennung, Upload läuft/fehlgeschlagen, Speichern, Konflikt |
| Chats | 6 | Platzhalter (O-27) | – |
| Manny-Chat | – | **nirgends** | – |

---

## 10. Testdaten-Seed und Reset (T-1)

Paket F2-2, **erst nach L1** (MAJOR-1). `dart run tool/seed/seed.dart --target local|remote [--confirm-remote]`; Schlüssel nur aus der Umgebung. Löscht nur `is_test`-Praxen und Test-Konten (`@test.curaone.invalid`). Legt an (O-6, Annahme, erweitert):
- Katalog (O-1, gekennzeichnet) mit Baukasten-Feldern (Material, Ort, Pause, Kurzanleitung), ohne Bilder;
- CuraOne-Beispielvorlagen (gekennzeichnet, O-25);
- 2 Praxen, je 2 Physios, 5 Patienten in unterschiedlichen Phasen mit Hauptphysio;
- je Patient Verletzung und Plan mit stabilen IDs, darunter ein Patient mit abgeschlossener früherer Verletzung (Historie) und Positionen „vorbereitet“;
- Akte, Termine, 14 Tage Training (Session und Abhaken, mit übersprungenen Übungen und Gründen), Check-ups nach der Einheit, Tages-Check-ups, Fragen (offen/besprochen), Notizen;
- Warnzeichen nach den entschiedenen Regeln (O-2): je ein Fall Schmerz ≥ 7, Anstieg ≥ 3 zum Vortag, Schwellung 3, und eine Stimmungskette über 6 Tage (zwei Stimmungs-Nachrichten). Die Warnzeichen entstehen über den Trigger, nicht direkt geschrieben.
Codes nur auf der Konsole. Test: zweimal → gleicher Endzustand; Kontrollpraxis unverändert (DB-T40, braucht Stack).

---

## 11. Pakete (pub.dev)

| Paket | Zweck | Lieferung | Begründung |
|---|---|---|---|
| `supabase_flutter` | Backend-Client | L3 | wie v1.2 |
| `app_links` | Einladungslink | L3 | wie v1.2 |
| `qr_flutter` | QR-Code | L6 | wie v1.2 |
| `share_plus` **neu** | „Teilen“ per SMS/Mail/Messenger (PB-E AK 1) | L6 | System-Teilen ist ohne Paket nicht plattformübergreifend verfügbar; Web-Unterstützung beim Hinzufügen prüfen, Rückfall „Link kopieren“ |
| `file_picker` **neu** | Bildauswahl im Baukasten (Handy-Browser und Rechner) | L8 | Upload braucht eine Dateiauswahl im Web; Kandidat, Lizenz/Pflege in F2-9c prüfen |
| `supabase` (dev) | Seed | L2, Paket F2-2 (erst nach L1, gemeinsame `pubspec.yaml`) | wie v1.2 |

Versionen beim Hinzufügen bestimmt; Lizenz und Pflege prüft das jeweilige Paket. Manny braucht kein Paket (PNG-Assets, Bewegung im Code). Bewusst nicht: State-Management-Pakete, `go_router`, Kamera, `http`, Lottie/Rive, Bild-Cache-Pakete (O-35), Audio-Paket (nur nach O-37), Bildbearbeitung (O-38b).

---

## 12. Teststrategie

### 12.1 Supabase-Rollen-Nachbildung (unverändert, M-3)
`supabase/tests/shim/supabase_roles.sql` wie v1.2 10.1. **Neu:** Policies auf `storage.objects` lassen sich mit der Nachbildung nicht sinnvoll prüfen → Storage-Tests nur gegen den lokalen Stack (`supabase/tests/stack/`, X2-8). Die Hilfsfunktion `app.patient_can_see_exercise` wird zusätzlich ohne Storage gegen Postgres geprüft (DB-T68a).

### 12.2 Benannte DB-Tests
Jede Sicherheitsaussage hat genau einen Test. Spalte „L“ = Lieferung, in der der Test entsteht bzw. angepasst wird. Tests aus v1.2 behalten ihre Nummer.

| ID | L | Name | Aussage |
|---|---|---|---|
| DB-T01 | 2+ | `defaults_revoked` | Rechte-Inventar: nur die in 6.2/6.4 genannten Rechte; je Lieferung um neue Tabellen/RPCs erweitert |
| DB-T02 | 2 | `no_force_rls_definer_sees_rows` | Definer-Funktionen sehen Zeilen (kein `FORCE`), API-Rollen unterliegen RLS |
| DB-T03 | 2+ | `anon_role_sees_nothing` | `anon`: jede Tabelle/Sicht/RPC verweigert |
| DB-T04 | 2+ | `unbound_anonymous_sees_nothing` | anonyme, ungebundene Sitzung: alle Tabellen und Sichten 0 Zeilen |
| DB-T05 | 2+ | `unbound_anonymous_rpc_denied` | jede RPC außer `redeem_invitation`/`delete_my_data` → `42501` |
| DB-T06 | 2+ | `physio_practice_isolation` | Physio A sieht 0 Zeilen Praxis B in jeder Tabelle und Sicht |
| DB-T07 | 2 | `physio_sees_all_practice_patients` | alle Patienten der Praxis, unabhängig vom Hauptphysio (N-4) |
| DB-T08 | 2+ | `patient_sees_only_self` | gebundener Patient sieht nur eigene Zeilen |
| DB-T09 | 2 | `invitation_hash_not_readable` | `code_hmac` nicht lesbar; keine Sicht über `invitations` |
| DB-T10 | 2 | `invitation_cross_practice` | unverändert |
| DB-T11 | 2 | `redeem_requires_anonymous` | unverändert |
| DB-T12 | 2 | `redeem_already_bound` | unverändert |
| DB-T13 | 2 | `redeem_results` | unverändert |
| DB-T14 | 2 | `redeem_throttle` | unverändert (N-6) |
| DB-T15 | 2 | `patient_cannot_modify_physio_entries` | + Verletzungen, Pläne, Notizen, Übungen, Vorlagen |
| DB-T16 | 2 | `created_by_server_side` | + `exercise_images`, `plan_templates` |
| DB-T17 | 2 | `own_appointments_only` | unverändert |
| DB-T18 | 2 | `exercise_requires_name_description` | unverändert |
| DB-T19 | 2 | `exercise_cross_practice` | unverändert, + Vorlagen und `assign_exercise` |
| DB-T20 | 2 | `save_plan_stable_ids` | unverändert |
| DB-T21 | 2 | `save_plan_keeps_history` | + `exercise_results`, `session_checkup_items` (Momentaufnahmen bleiben) |
| DB-T22 | 2 | `save_plan_current_phase` | unverändert (jetzt `plans.current_phase_id`) |
| DB-T23 | 2 | `save_plan_version_conflict` | unverändert |
| DB-T24 | 2 | `save_plan_cross_practice` | unverändert |
| DB-T25 | 5 | `warning_only_by_trigger` | auf `daily_checkups` |
| DB-T26 | 5 | `warning_trigger_definer_search_path` | unverändert |
| DB-T27 | 5 | `checkup_append_only` | Patient kann `daily_checkups`, `session_checkups` nicht ändern/löschen (ersetzt `wellbeing_append_only`) |
| DB-T28 | 5 | `patient_no_warning_read` | unverändert (B-5) |
| DB-T29 | 2+ | `delete_my_data_scope` | Umfang 6.13 |
| DB-T30 | 2 | `delete_my_data_idempotent` | unverändert |
| DB-T31 | 2 | `race_delete_vs_insert` | unverändert (zwei Verbindungen); in L4/L5 zusätzlich je ein Fall `exercise_results`, `daily_checkups` |
| DB-T32 | 2 | `auth_user_delete_set_null` | unverändert |
| DB-T33 | 2 | `rebind_detaches_old_identity` | unverändert |
| DB-T34 | 2 | `rebind_keeps_history` | + Check-ups, Fragen, Ergebnisse |
| DB-T35 | 2 | `rebind_hook_called` | unverändert |
| DB-T36 | 2+ | `inactive_patient_blocked` | + alle neuen Patienten-Tabellen und RPCs |
| DB-T37 | 2+ | `rpc_execute_grants` | jede RPC inkl. neue |
| DB-T38 | 2+ | `definer_functions_search_path` | alle Definer-Funktionen inkl. neue |
| DB-T39 | 2 | `set_current_phase_foreign_phase` | + Phase eines abgeschlossenen Plans → Fehler |
| DB-T40 | 2 | `seed_idempotent_only_test_data` | Stack |
| DB-T41 | 5 | `submit_daily_checkup_scope` | ersetzt `report_wellbeing_scope`: nur gebundener, aktiver Patient; `patient_id` aus der Sitzung; Wiederholung idempotent mit gleicher Antwort, **auch nachdem ein verspäteter Vortag ein `pain_rise` für diesen Tag erzeugt hat** (NEU-7, `trigger_checkup_id`); Rückgabe nur `warning_raised` |
| DB-T42 | 2/3 | `active_patient_writes_and_undoes` | + `exercise_results` anlegen und löschen |
| DB-T43 | 2+ | `delete_my_data_with_data` | mit Daten aller Patienten-Tabellen |
| DB-T44 | 2 | `physio_maintains_record_invited_and_deleted` | unverändert |
| DB-T45 | 2+ | `seed_writes_without_binding` | unverändert; **erweitert (MINOR-C):** `service_role` legt `training_sessions`, `exercise_results` und ab L5 `daily_checkups` ohne Patienten-JWT an, `injury_id` wird über die interne Variante korrekt gesetzt |
| DB-T46 | 2 | `save_plan_foreign_ids` | unverändert |
| DB-T47 | 2 | `redeem_attempts_cleanup` | unverändert |
| DB-T48 | 6 | `main_physio_same_practice` | `set_main_physio` nur Physio derselben Praxis, Ziel derselben Praxis |
| DB-T49 | 6 | `main_physio_no_access_change` | Hauptphysio-Wechsel ändert keine Sichtbarkeit (beide Physios sehen weiter, N-4) |
| DB-T50 | 7 | `notes_practice_only` | Notizen: Physio der Praxis liest/legt an; Patient `permission denied`/0 Zeilen, auch über Sichten; fremde Praxis 0 |
| DB-T51 | 7 | `notes_author_server_side` | gefälschter `author_id` überschrieben |
| DB-T52 | 5 | `question_insert_own_only` | `ask_physio` nur eigener Patient; kein direktes INSERT |
| DB-T53 | 7 | `question_status_physio_only` | Patient kann Status nicht setzen; Physio über RPC; Patient sieht Status |
| DB-T54 | 5 | `question_text_limits` | leer bzw. zu lang → Fehler (Wert O-34) |
| DB-T55 | 5 | `daily_checkup_once_per_day` | zweite Meldung am selben Tag mit anderer ID → `already_submitted` |
| DB-T56 | 5 | `daily_checkup_ranges` | Werte außerhalb der Skalen → Fehler (Schmerz 0–10, Wohlbefinden/Motivation/Stimmung 1–5, Schwellung 0–3); fehlender Wert → Fehler |
| DB-T57 | 5 | `mood_streak_warning` | 5 aufeinanderfolgende Tage mit Check-up und `mood ≤ 2` → Warnzeichen `mood_low_streak` für Tag 5 ohne Details; Tag 6 und 7 in Folge → je ein weiteres; 4 Tage → keines; `mood = 3` → keines; Tag ohne Check-up unterbricht (Tage 1–4, Lücke, Tage 6–9 → keines); **Einfügen außer der Reihe** (Tag 3 zuletzt) → dieselbe Endmenge wie in Reihenfolge; Wiederholung derselben Check-up-ID → nichts zusätzlich (MINOR-5); **je Verletzung (N-16):** Tage 1–4 bei Verletzung A, `start_new_injury`, Tage 5–6 bei Verletzung B → keines; Tage 1–5 bei B → Warnzeichen für Tag 5 von B |
| DB-T58 | 5 | `mood_warning_not_reported_to_patient` | nur Stimmungs-Warnzeichen → `warning_raised = false`; Patient liest es nicht |
| DB-T59 | 2 | `exercise_results_own` | Patient legt nur eigene an, löscht nur eigene; Physio liest |
| DB-T60 | 4 | `session_checkup_scope` | nur eigener Patient; Wertelisten; `skip_reason` nur bei übersprungenen Positionen |
| DB-T61 | 2+ | `injury_id_server_side` | Client-Wert immer überschrieben; `training_sessions` aus `plan_id` (fremder Plan → `42501`); Session des alten Tags mit altem `plan_id` **nach** `start_new_injury` → alte Verletzung; `exercise_results`/`session_checkups` = Verletzung ihrer Session; `daily_checkups`/`patient_questions` = aktive Verletzung (MINOR-4); **`exercise_results`/`session_checkups` mit `training_session_id` eines anderen Patienten → `42501`, nichts geschrieben (MINOR-D)** |
| DB-T62 | 7 | `new_injury_keeps_history` | `start_new_injury`: alte Verletzung geschlossen, neuer Plan, alte Daten behalten `injury_id`; `save_plan` auf altem Plan → `plan_closed` |
| DB-T63 | 2 | `create_patient_from_template` | Vorlage kopiert mit neuen IDs, aktuelle Phase gesetzt; fremde Vorlage → `42501`; `reference_date` ohne Eingabe = übergebener `local_day`, außerhalb ±1 Tag → `invalid_local_day` |
| DB-T64 | 2 | `create_patient_minimal` | Vorname + Verletzung oder Vorlage genügen; ohne beides bzw. leerer Vorname → Fehler; Hauptphysio = Aufrufer; Code einmalig |
| DB-T64b | 2 | `create_patient_idempotent` | gleiche `id` mit gleichen Parametern erneut → kein zweiter Patient, alte Einladung widerrufen, neuer Code; gleiche `id` mit **anderen** Parametern → `idempotency_mismatch`, nichts geändert; fremde Praxis bzw. Status ≠ `invited` → `42501`; **zwei gleichzeitige Aufrufe** (zwei Verbindungen, `db/race/`) → genau ein Patient, genau eine offene Einladung, kein `23505` (MINOR-1); **zwei Aufrufe nacheinander** → nur der Code der zweiten Antwort ist einlösbar, der erste → `invalid` (MINOR-F; App-Teil als W-Test in F2-7c, 6.6) |
| DB-T65 | 2 | `plan_item_release` | Freischalt-Felder: genau eines bei `prepared`, Phase aus demselben Plan |
| DB-T66 | 2 | `exercise_builder_fields` | Werte- und Ortsliste geprüft; praxisweit sichtbar, fremde Praxis nicht |
| DB-T67 | 8 | `assign_exercise_all_or_nothing` | gültig → Position je Patient, Version +1; eine ungültige (fremde Praxis, fremde Phase, abgeschlossener Plan, `release_with_phase_id` aus anderem Plan, Freischalt-Felder unvollständig) → nichts geändert (MINOR-8) |
| DB-T68 | 8 | `storage_exercise_images` | **Stack:** Physio derselben Praxis lädt hoch/liest; fremde Praxis nicht; Patient liest nur Bilder von Übungen in Positionen seines aktuellen Plans (aktiv oder vorbereitet), nicht die anderer Pläne; `anon` nichts |
| DB-T68a | 2 | `patient_can_see_exercise` | Hilfsfunktion und `exercises`-Policy ohne Storage: aktive und vorbereitete Position → sichtbar, zu jeder Uhrzeit (Fixtures `local_day`, Server-Uhr auf 22:30 und 00:30 UTC gesetzt); Übung eines fremden oder abgeschlossenen Plans → nicht sichtbar (MAJOR-2) |
| DB-T69 | 8 | `exercise_images_rows` | Metadaten-Zeilen: Rechte wie `exercises`, Katalog nicht löschbar |
| DB-T70 | 2+ | `lock_trigger_all_patient_tables` | Schreibsperre auf allen Tabellen aus 6.3 (Katalogabfrage + Schreibversuch bei `access_deleted`) |
| DB-T71 | 2+ | `delete_scope_new_tables` | neue Patienten-Tabellen gelöscht; Notizen, Verletzungen, Pläne bleiben |
| DB-T72 | 7 | `views_security_invoker` | alle Sichten in `public` haben `security_invoker = true` (Katalog) |
| DB-T73 | 2 | `session_update_columns_only` | Patient ändert an `training_sessions` nur die erlaubten Spalten |
| DB-T74 | 2 | `plan_closed_read_only` | abgeschlossener Plan: Patient liest, niemand schreibt über `save_plan`/`assign_exercise` |
| DB-T75 | 5 | `limitations_scale` | `limitations` nur einer aus `none`/`mild`/`marked`/`severe`; Liste oder unbekannter Wert → Fehler (O-19) |
| DB-T76 | 2 | `templates_practice_scope` | Physio liest Beispiele + eigene Vorlagen, schreibt nur eigene |
| DB-T77 | 5 | `warning_rules_decided` | Schmerz 7 → `pain_high`, 6 → keines; Anstieg 3 zum Vortag → `pain_rise`, 2 → keines, ohne Vortags-Check-up → keines; Vortags-Check-up einer anderen Verletzung → kein `pain_rise` (N-16); Schwellung 3 → `swelling_severe`, 2 → keines; `notify_patient` = `true` für alle drei, `false` für `mood_low_streak`; `warning_raised` entsprechend; `warning_rules` hat keine Spalte `is_provisional` |
| DB-T78 | 2 | `one_active_injury` | zweite aktive Verletzung → Constraint-Fehler |
| DB-T79 | 7 | `views_aggregate_correct` | Kachel-Sichten liefern für Fixture-Daten die erwarteten Werte (Trainingstage, Verhältnis, Bewertungen, Schmerztrend, Schwellung, Einschränkungs-Stufe) |
| DB-T80 | 2+ | `security_not_date_dependent` | Katalogprüfung: keine Policy (inkl. `storage.objects` im Stack) und keine in Policies verwendete Hilfsfunktion nutzt `current_date`, `now()`, `localtime`, `current_timestamp`; `start_new_injury` und `create_patient` lehnen `local_day` außerhalb ±1 Tag um das UTC-Datum ab (MAJOR-2); `submit_daily_checkup` lehnt nur Werte nach UTC-Datum + 1 oder vor Bindungstag − 1 ab (MAJOR-B, 6.7 Nr. 3) |
| DB-T81 | 2 | `app_helpers_caller_checked` | `app.current_injury_id(p)`, `app.current_plan_id(p)`, `app.physio_can_see_patient(p)` liefern für fremde Patienten `null`/`false` (Physio fremder Praxis, anderer Patient, anonym); **gebundener Patient mit eigener ID → `physio_can_see_patient` = `false`**, `current_injury_id`/`current_plan_id` liefern ihm seine Werte; als Patient scheitern die Physio-Wege (`practice_notes` lesen, UPDATE `patients.first_name`, `injuries.label`, Schreiben in `treaters`/`history_entries`, `invitations` lesen: 0 Zeilen bzw. `permission denied`) (MAJOR-A); `app.active_injury_id_internal` für `authenticated`/`anon` nicht ausführbar (MINOR-C); `config.toml` exponiert nur `public` (MINOR-9) |
| DB-T82 | 5 | `checkup_warnings_order_independent` | Fixture-Folgen (Schmerz-Anstieg, Stimmungskette) in Reihenfolge und vertauscht eingefügt → gleiche Menge `(reason_code, local_day)`; verspäteter Vortag erzeugt `pain_rise` für den Folgetag (MINOR-5) |
| DB-T83 | 5 | `late_checkup_accepted` | Server-Uhr auf Tag D+3: Check-up mit `local_day = D` (nach dem Bindungstag) → angenommen, `pain_high` für D entsteht, Stimmungskette und Anstiegsregel für D und die vorhandenen Folgetage ausgewertet; `local_day` = UTC-Datum + 2 bzw. vor Bindungstag − 1 → `invalid_local_day` (MAJOR-B) |
| DB-T84 | 5/7 | `mood_warnings_one_notification` | Check-ups Tage 1–4 und 6–7 mit `mood ≤ 2`, danach Tag 5 → drei `mood_low_streak` (Tage 5, 6, 7) mit derselben `trigger_checkup_id`; `v_wellbeing_overview` (L7) liefert dafür **eine** Meldung mit drei Tagen; in Reihenfolge eingefügt → drei Meldungen (N-16) |
| DB-T85 | 2 | `manny_look_patient_only` | `set_manny_look` setzt nur die eigene Zeile; ungültiger Wert → Fehler; direktes UPDATE auf `patients.manny_look` → `permission denied`; Physio und anonyme/ungebundene Sitzung → `42501`; Status ≠ `active` → `42501`; `delete_my_data` → `manny_look` = `null` (O-41) |

Gegen lokales Postgres 16 mit Nachbildung (hier ausführbar, `/usr/lib/postgresql/16`): alle außer DB-T40, DB-T68 und dem Storage-Teil von DB-T80. **Zusätzlich gegen den echten Stack in L9:** DB-T01, DB-T11, DB-T12, DB-T33, DB-T37, DB-T40, DB-T45, DB-T68, DB-T80 (Storage-Teil), DB-T81 (exponierte Schemas).

### 12.3 Übrige Ebenen

| Ebene | Inhalt |
|---|---|
| U | `world_time` (V2-6), `manny_occasions` (V2-70), Migration 1 → 2 (Manny-Look, Onboarding-Schritt), `invite_code`, `exercise_duration` (alle Zweige, `duration_sec`, Pause des Physios/60 s, O-17), `plan_today` (Füllregel, `isReleased` mit Fixtures Mitternacht/Zeitzone 6.7, Tausch-Kandidaten), `phase_summary` (Kachel 6), `path_from_phases` (inkl. Unit-Erledigung nach T-5), `outbox` (alle Arten inkl. `manny_look_set`, Fehlerklassen, `pauseAndDrain`, `invalid_local_day` zurückgestellt statt verworfen, „Check-up 3 Tage verspätet“), `plan_validation`, `session_machine` (alle Übergänge, Pause, Hintergrund, Mitternacht, Überspringen, Beenden, Schmerz mit/ohne Variante; feste Uhr), `packing_list`, `checkup` (Karte heute offen/erledigt/weggeklickt), `fallback_today` (Kürzung ab Schmerz 6, Dauer-Zweig in Sekunden, Fixtures gemeinsam mit KI-Plan), Migration 2 → 3, Manny-Look-Abgleich bei Bindung (`ok`: lokaler Wert gesendet; `ok_rebound` mit Konto-Wert: übernommen, B-36) |
| W | je Lieferung alle Screens und Zustände aus 3, 8, 9; Ansagen (Semantik), ohne Gesten bedienbar, Leisten-Sichtbarkeit, Blur-Zähler, Transparenz reduzieren |
| C | Regeln 1–16 + Grenze Patient/Physio, `supabase_flutter` nur `lib/backend/**`, keine Schlüsselmuster, keine Chat-Begriffe in `lib/physio/**`, Text-nicht-auf-Welt, Mandarine nie als Text, Blur nur in drei Bausteinen |
| M | Matrix für alle Szenarien (Patient und Physio), Physio zusätzlich 1024×768 und 1280×800 („ohne Scrollen“ für Kacheln) |
| G | Goldens nach Nutzerfreigabe (Umfang O-32) |
| S, N | `shoot.mjs` (Welten, Patient und Physio), `nav_checks.mjs` mit Abläufen 1–4, PB-A–PB-G (Fake-Repositories), Ablaufprüfung < 30 s |
| E2E | gegen lokalen Supabase-Stack (L9, X2-8) |

---

## 13. Rückverfolgung

Prüfkürzel: U Unit, W Widget, C statisch, M Matrix, G Golden, S Screenshots, N `nav_checks`, DB Datenbanktest, E2E Ende-zu-Ende, D Geräte-Prüfliste.

### 13.1 Spezifikation Ausschnitt 2 (v1.2, angepasst)

| AK | Umsetzung | L | Prüfung |
|---|---|---|---|
| P-1 AK 1 | 7.1, 6.1 | 6 | DB-T06, DB-T07, W, N |
| P-1 AK 2 | 7.1 | 6 | W, E2E |
| P-2 AK 1 | 6.6 | 6 | W, S, N, DB-T64 |
| P-2 AK 2 | unique `auth_user_id`, `redeem_invitation` | 2/3 | DB-T13, W, N |
| P-3 AK 1 | 6.7, 9 | 6 | W, DB-T20 |
| P-3 AK 2 | Constraint, `plan_validation` | 2/6 | U, W, DB-T18 |
| P-3 AK 3 | 8.2 | 3 | W, E2E |
| P-4 AK | 9 Akte | 6 | W, DB-T15 |
| P-5 AK 1 | Kacheln 2–8 (Verlauf je Tag in den Details) | 7 | W, DB-T08, DB-T79, E2E |
| P-5 AK 2 | Trigger, Listenmarker | 5/6 | DB-T25, W, E2E |
| P-5 AK 3 | kein Chat in Ausschnitt 2; statische Regel | alle | C; ab Ausschnitt 3 KI-Plan DB-K01/DB-K12 |
| A-1 AK 1–3 | 7.2, 8.3 | 3 | W, N, DB-T04, E2E |
| A-2 AK 1–2 | 8.4 | 3 | U, W, M, S |
| A-3 AK | ersetzt durch Tages-Check-up (8.6) mit Schwellung 0–3 (O-18 entschieden) | 5 | U, W, DB-T27, DB-T41, DB-T56 |
| A-4 AK 1 | 8.9 | 3 | W, DB-T15, DB-T17 |
| A-4 AK 2 | O-5 später | – | – |
| T-1 AK | 10 | 2 | DB-T40 |

### 13.2 Abläufe Training und Check-ups (T-1–T-6, C-1–C-3)

| ID | Schritt / AK | Entscheidung | L | Umsetzung | Prüfung |
|---|---|---|---|---|---|
| TR-1.1 | Check-up-Karte oben auf Heute, falls offen | C-2 | 5 | 8.6 | W, U `checkup`, G |
| TR-1.2 | Liste: Bild, Name, Umfang, Material, Ort | T-3, T-6 | 3 (Bild ab 8) | 8.4 | W, G, M |
| TR-1.3 | Übungsdetail: Bilder, Beschreibung, Grenzen, Material, Ort | T-6 | 3 (Bild ab 8) | 8.4 | W, G |
| TR-1.4 | zwei Wege: „Training starten“ und Abhaken | T-1 | 3/4 | 8.4, 8.5 | W, N |
| TR-2.1 | Packliste abhakbar, Tausch nur freigegebene derselben Phase, „Los geht’s“ | T-4 | 4 | 8.5 | U `packing_list`, W |
| TR-2.2 | Vollbild: Fortschritt, Gesamtzeit, Bild, Name, Kurzanleitung, Zähler, Countdown mit Ton/Vibration | T-2 | 4 | 8.5 | U `session_machine`, W, G |
| TR-2.3 | Pausen-Timer automatisch, Dauer vom Physio, überspringbar | T-2 | 4 | 8.5 | U, W |
| TR-2.4 | Übung fertig: Erfolgssignal, automatisch nächste | – | 4 | 8.5 | W (inkl. reduzierte Bewegung) |
| TR-2.5 | Pause, Überspringen, Beenden (speichert), Schmerz melden (Variante/Abbruch) | T-5 | 4 | 8.5 | U, W, DB-T59 – Variante nur mit E-30 |
| TR-2.6 | Ende: Zusammenfassung, Manny-Feier, danach Check-up | – | 4 | 8.5, 8.6 | W, N |
| TR-3.1 | Abhaken; Timer/Zähler im Detail | T-1 | 3 (Timer 4) | 8.4 | W |
| TR-3.2 | erste abgehakte Übung zählt für den Streak | T-5 | 3 | 8.3, 8.4 | U streak/path, W |
| TR-3.3 | letzte Übung/„Fertig für heute“ → Zusammenfassung → Check-up | – | 3 (Check-up 4) | 8.4, 8.6 | W, N |
| TR-3.4 | Rückgängig am selben Tag | – | 3 | 8.4 | U, W, DB-T59 |
| CU-a.1 | Pflicht „Wie lief’s?“ mit 5 Smileys | C-1 | 4 | 8.6 | W, G |
| CU-a.2 | optional je Übung leicht/passend/schwer/Schmerz, „Gewicht erhöht“ | C-1 | 4 | 8.6, 6.9 | W, DB-T60 |
| CU-a.3 | „Warum übersprungen?“ Zeit/Schmerz/Material/anderes | – | 4 | 8.6, 6.9 | W, DB-T60 |
| CU-a.4 | Speichern; Werte beim Physio im Verlauf | – | 4/7 | 6.9, 6.12 | DB-T60, DB-T79, W |
| CU-b.1 | Karte einmal täglich | C-2 | 5 | 8.6 | U, W |
| CU-b.2 | sechs Werte (C-2 plus Schwellung O-18; Einschränkungen als Skala O-19) | C-2, O-18, O-19 | 5 | 8.6, 6.9 | W, DB-T56, DB-T75 |
| CU-b.3 | klein nach Ausfüllen; Wegklicken bis morgen | C-2 | 5 | 8.6 | U, W |
| CU-b.4 | Werte an Physio; Kürzung E-36 ab Schmerz 6 | C-2, E-28 | 5/7 | 8.7, 6.12 | U `fallback_today`, W, DB-T79 |
| CU-b.5 | Stimmung nur erfassen/zeigen; Nachricht an Physio ab 5 Tagen mit Stimmung ≤ 2, an jedem weiteren Tag erneut, Lücke unterbricht | C-3, O-2a, O-2b | 5/7 | 6.9 | DB-T57, DB-T58, DB-T77, DB-T82, W (keine Patientenreaktion) |
| CU-b.6 | Warnzeichen Schmerz ≥ 7, Anstieg ≥ 3 zum Vortag, Schwellung 3 → fester Hinweis an den Patienten, Marker beim Physio | O-2, O-12 | 5/6 | 6.9, 8.6 | DB-T77, DB-T82, W |
| RF-1 | kein Bild → neutrale Illustration | T-6 | 3 | 8.4 | W, G |
| RF-2 | Session nach Hintergrund/Sperre pausiert; Mitternacht zählt für Vortag | – | 4 | 8.5 | U (feste Uhr), W |
| RF-3 | offline: Session läuft, Warteschlange | – | 4 | 8.5, 8.11 | U `outbox`, W |
| RF-4 | Barrierefreiheit: Ansagen, Ton/Vibration abschaltbar, ohne Gesten, keine Feier-Animation bei reduzierter Bewegung | – | 4 | 8.5 | W, M, D |

### 13.3 Physio-Bereich (PB-1, PB-8, PB-A–PB-G)

| AK | L | Umsetzung | Prüfung |
|---|---|---|---|
| PB-1 Handy und Rechner, gleiche Inhalte | 6 | 4 | M (390×844, 320×568, 1024×768, 1280×800), W, S |
| PB-A AK 1 Reiter Meine/Praxis, Warnmarker in beiden | 6 | 9 | W, DB-T07, DB-T49 |
| PB-A AK 2 Suche nach Name | 6 | 9 | U (Filter), W |
| PB-A AK 3 Hauptphysio = Anleger, änderbar | 6 | 6.6, 6.4 | DB-T48, DB-T64, W |
| PB-B AK 1 Kacheln 2–8, Rechner ohne Scrollen, Handy eine Spalte (Kachel 6 aus dem Plan, O-42 entschieden) | 7 | 9, 6.12 | W, M (1280×800), G, U `phase_summary` |
| PB-B AK 2 Tipp öffnet Detail (Schmerz 30 Tage, Übungen je Bewertung) | 7 | 6.12, 9 | W, DB-T79 |
| PB-B AK 3 Training seit letztem Termin: Verhältnis, Streak, übersprungene mit Grund | 7 | 6.12 | DB-T79, W – Streak vom Gerät (B-25) |
| PB-B AK 4 Warnzeichen zuerst, Stimmungs-Nachricht dort (eine Meldung je Eingang, N-16) | 7 | 6.9, 6.12 | W, DB-T57, DB-T84 |
| PB-B AK 5 Manny-Chat nirgends | alle | 4, 6.12 | C, DB-T72; Ausschnitt 3 DB-K01/K12 |
| PB-C AK Notiz für Praxis, Autor, Datum, Patient sieht nicht | 7 | 6.10 | DB-T50, DB-T51, W |
| PB-D AK 1 „Frage an meinen Physio“ → Kachel | 5/7 | 8.8, 6.10 | DB-T52, W |
| PB-D AK 2 „besprochen“, Patient sieht Status, kein Chat | 7 | 6.10 | DB-T53, W |
| PB-E AK 1 / PB-8 Vorname + Verletzung/Vorlage → QR, Link, Teilen, < 30 s | 6 | 6.6 | DB-T63, DB-T64, DB-T64b, W (inkl. Wiederholung, MINOR-F), N (Ablaufprüfung), G |
| PB-E AK 2 nach Einlösen direkt im Plan, Vorlage gefüllt | 3/6 | 6.6, 7.2 | DB-T63, W, E2E |
| PB-F AK 1 Pflicht Name/Beschreibung, optionale Felder, Bilder | 8 | 6.11 | DB-T18, DB-T66, DB-T68, W |
| PB-F AK 2 Zuweisung an mehrere Patienten mit Phase | 8 | 6.11 | DB-T67, W |
| PB-F AK 3 praxisweit wiederverwendbar | 2/8 | 6.2 | DB-T66 |
| PB-6 „Damit anfangen“ ja/nein | 2/8 | 6.7, 6.11 | DB-T65, DB-T68a, DB-T80, U `isReleased` (Fixtures Mitternacht/Zeitzone), W |
| PB-G AK 1 Historie je Verletzung | 7 | 6.8 | DB-T79, W |
| PB-G AK 2 neue Verletzung, neuer Plan, Historie bleibt | 7 | 6.8 | DB-T62, W |

### 13.4 UI-Akzeptanzkriterien Brief v2 (gruppiert)

„Regression“ heißt: Jede spätere Lieferung prüft das Kriterium für ihre neuen Screens erneut (statische Regel, Matrix, Goldens).

| Kriterien | Thema | Erste Lieferung | Prüfung | Regression |
|---|---|---|---|---|
| V2-1 | Tokens | L1 (F2-R1) | C | alle |
| V2-2, V2-6, V2-7, V2-8, V2-9 | Welt, Zeitregel, Weltwahl, Welt/Thema unabhängig, keine Konturen | L1 (F2-R1/R2) | U, W, G, S (vergrößert) | – |
| V2-3, V2-4, V2-17 | Kontraste Welt, Inhaltsflächen, Leiste | L1 (F2-R1) | Kontrasttests | alle (neue Token-Paare) |
| V2-5 | Text nie direkt auf der Welt | L1 | C, M, S | alle |
| V2-10, V2-11, V2-12 | Blur-Budget, opake Sheets, Transparenz reduzieren | L1 (F2-R2/R3) | W, C | alle |
| V2-13 | Triage/Fristen opak | L1 | C | – |
| V2-14 | Leistung | L1 | D (Geräteprofil), dokumentiert | – |
| V2-15, V2-16, V2-18, V2-19, V2-20, V2-21 | Leiste, Ruhe/Aktiv, Sichtbarkeit, Badge, Manny-Zugang | L1 (F2-R3) | W (feste Uhr), N | L4 (Session ohne Leiste) |
| V2-22 | Physio-Seitenleiste | L6 | W, M, G | L7, L8 |
| V2-23, V2-24, V2-25, V2-27, V2-29, V2-30 | Zielgrößen, 200 %, 320×568, Blinken, nicht nur Farbe, Schriftgrößen | L1 | M, C, G (Graustufen) | alle |
| V2-26 | reduzierte Bewegung | L1 | W, M | L4 (Session, Feier) |
| V2-28 | Screenreader | L1 | W (Semantik), D | alle |
| V2-31, V2-32, V2-33 | Primärbutton, Orange als Text, Balken mit Text | L1 (F2-R2) | W, C | alle |
| V2-34, V2-35, V2-36, V2-37 | Pfad: Kugeln, Kopf-Karte, Zentrierung, Beispielpfad | L1 (F2-R3) | W, G, M | L3 (Pfad aus Phasen, „ausgelassen“) |
| V2-38, V2-40 | Tages-Check-up-Karte (6 Fragen, „Frage N von 6“ nach Brief-Ergänzung F2-D2 B), Schmerz-Regler | L5 | U, W, G | – |
| V2-39 | Smileys mit Label, Auswahl mit Rand und Haken | L4 (`RatingScale`) | W, G | L5 |
| V2-41, V2-44 | Zeitwahl, Termin-Karten | L1 | W, G | L3 (echte Daten) |
| V2-42 | Übungszeile | L1 (Optik) / L3 (Material, Ort) / L8 (Bild) | W, G | – |
| V2-43 | erste Übung zählt, Rückgängig, Leerzustand | L3 | U, W | „Eigene Übung“ O-22 ⚠ |
| V2-45 – V2-51 | Session | L4 | U, W, G, M | – |
| V2-52 | Check-up nach der Einheit | L4 | W, G | – |
| V2-53 | Profil, Darstellung | L1 | W, G | L3 („Mein Plan …“), L5 („Frage …“); „Erinnerungen“ O-23 ⚠ |
| V2-54 | Chats mit Manny angeheftet | L1 | W, G | – |
| V2-55 | Manny-Chat privat | L1 (C) | C, DB (Ausschnitt 3) | L6–L8 |
| V2-56 (ersetzt durch Brief-Ergänzung 1) | Manny nur aus den 8 PNGs nach Wahl, gleiche Variante überall, Fallback-Pose, kein Platzhalter | L1 (F2-R2) | W, G, C (kein Manny-`CustomPainter`, kein „Platzhalter“) | alle (neue Manny-Stellen) |
| V2-65, V2-66, V2-67 | Onboarding 5 Schritte mit Look-Schritt, Radio-Gruppe, Vorbelegung „Mit Brille“, Wahl bleibt bei Zurück/Neustart | L1 (F2-R4) | W, G, U (Migration 1 → 2) | L3 (Look-Schritt im Code-Start) |
| V2-68 | Profil-Zeile „Manny-Look“, Wechsel ohne Neustart überall | L1 (F2-R3) | W (Asset-Pfad vorher/nachher), N | – |
| V2-69 | Halo in Nacht, Kopf auf heller Scheibe | L1 (F2-R2) | Renderprobe, G (Nacht, Transparenz reduzieren) | – |
| V2-70 | Posen-Zuordnung | L1 (F2-R2) | U `manny_occasions` | L4 (Trösten = `traurig`, Feier = `freudig`) |
| V2-71, V2-72, V2-73 | Label einmal, Mindestgröße Kopf 40 dp, Dichte-Auswahl 1/2/3 und Größenobergrenzen | L1 (F2-R2) | W, C | alle |
| V2-74, V2-75 | Bewegung reduzieren beim Look-Wechsel; 200 % und 320×568 | L1 (F2-R4) | W, M, G | – |
| V2-57 | Manny nie modal; Trösten (Pose `traurig`) bei Schmerz; keine Reaktion auf Stimmung | L1 / L4 (Trösten) / L5 (Stimmung) | W | – |
| V2-58 | Patientenliste | L6 | W, G, M | – |
| V2-59, V2-60 | Kacheln, Details | L7 | W, G, M | – |
| V2-61 | Physio-Welt ruhig | L6 | W, G | L7, L8 |
| V2-62 | Baukasten | L8 | W, G | – |
| V2-63 | Neuer Patient in 30 s | L6 | W, N, G | – |
| V2-64 | Texte Deutsch, „du“, Beispieldaten gekennzeichnet | L1 | C, Review | alle |

### 13.5 Nutzerentscheidungen N-14, N-15 und N-16

| Entscheidung | Umsetzung | L | Prüfung |
|---|---|---|---|
| O-17 Dauer je Satz in Sekunden; Schätzregel mit `pause_sec`/60 s; Kürzung halbiert Sekunden | 6.2, 8.4, 8.7; KI-Plan 4.2 | 2/3/5 | U `exercise_duration`, U `fallback_today`, gemeinsame Fixtures |
| O-18 Schwellung 0–3 als 6. Frage, feste Spalte | 6.2, 8.6, 3.7 Teil B | 5 | DB-T56, W, G |
| O-19 Einschränkungen als Einzelwert-Skala | 6.2, 8.6, 3.7 Teil B | 5 | DB-T75, W |
| O-2 Schmerz ≥ 7, Anstieg ≥ 3 zum Vortag, Schwellung 3; gleicher Hinweis | 6.9, 8.6 | 5 | DB-T77, DB-T82, W |
| O-2a/O-2b Stimmung ≤ 2, ab Tag 5 jeden Tag, Lücke unterbricht, Patient erfährt nichts | 6.9, 7.2 | 5 | DB-T57, DB-T58, DB-T82 |
| E-28 Kürzung ab Schmerz 6 | 8.7 | 5 | U `fallback_today`, W |
| N-15 Manny finale Grafiken, zwei Varianten | 3.5, 5 | 1 | V2-56 (ersetzt), V2-69–V2-73 |
| N-15 Wahl im Onboarding | 3.5, 3.2 (F2-R4), 8.1 (Code-Start) | 1/3 | V2-65–V2-67, V2-75 |
| N-15 Wechsel im Profil jederzeit | 3.4, 3.5 (F2-R3) | 1 | V2-68 |
| N-15 lokal gespeichert (Quelle der Anzeige), Bestandsnutzer „Mit Brille“, Zurücksetzen bei „Alles löschen“ | 3.5, 8.1 | 1/3 | U Migration 1 → 2 und 2 → 3, W (Löschen) |
| N-15 Rechte beim Nutzer, kein Platzhalter | 3.5 | 1 | C (kein „Platzhalter“) |
| N-16 O-41 Manny-Look zusätzlich im Konto, Schreiben nur durch den Patienten, Warteschlange, Übertragung bei Bindung, „Alles löschen“ | 3.5, 6.2, 6.4, 6.13, 8.1, 8.10, 8.11 | 2/3 | DB-T85, DB-T29, U `outbox` und Abgleich bei Bindung, W |
| N-16 O-42 „nächstes Ziel“ = Titel der nächsten Phase | 6.12 | 7 | U `phase_summary`, W |
| N-16 O-43 Look-Schritt vor dem Code-Feld | 3.7 Teil A, 8.1 | 3 | W, N |
| N-16 nachträgliche Warnzeichen gewollt (R2-24) | 6.9 | 5 | DB-T82, DB-T83 |
| N-16 Vorschau vorbereiteter Übungen (Policy bestätigt) | 6.7 Nr. 2, 6.11 | 2/8 | DB-T68, DB-T68a |
| N-16 Zählweise je Verletzung | 6.9, 7.2 | 5 | DB-T57, DB-T77 |
| N-16 eine gemeinsame Meldung je Eingang | 6.9, 6.12, 9 | 5/6/7 | DB-T84, W (Liste, Kachel 2) |

---

## 14. Offene Fragen und Werte

Spalte „blockiert“: welche Lieferung ohne Entscheidung nicht abgeschlossen werden kann; „–“ = Annahme genügt.

**Entschieden und eingearbeitet (N-14, nicht mehr offen):** O-2, O-2a, O-2b, E-28, O-17, O-18, O-19 – Werte in Abschnitt 0, Umsetzung 13.5. **N-15 Manny:** Rechtefrage für Manny erledigt; offen bleibt sie nur für die 3D-Objekte (Brief v2, 13.1). **N-16 (entschieden, 2026-10-14):** O-41 (Manny-Look zusätzlich im Konto), O-42 (nächstes Ziel = Titel der nächsten Phase), O-43 (Look-Schritt vor dem Code-Feld) – Umsetzung 13.5.

| Nr. | Frage | Auswirkung | blockiert | Annahme bis Klärung |
|---|---|---|---|---|
| E-7 | Limits/Budgets KI | nur KI | Ausschnitt 3 | – |
| E-15 | Rückfallmodell | nur KI | Ausschnitt 3 | – |
| E-27 | Physio-Grenzen als Obergrenzen | nur KI | Ausschnitt 3 | – |
| E-30 | leichtere Variante (`easier_variant_of`) | Schmerz melden in der Session (8.5), Kürzung (8.7), Schema `plan_items` | – (vor L2 empfohlen) | ohne Variante nur Abbruch |
| E-31 | KI-Einwilligung getrennt | nur KI | Ausschnitt 3 | – |
| E-24 | Löschen offline nur lokal? | Löschen | – | nein, klare Fehlermeldung |
| O-20 | Sollen Tages-Check-up-Werte (außer Stimmung) im Patienten-Pfad oder Profil sichtbar sein? | Patientenansicht | – | nein (nicht spezifiziert) |
| O-21 | Hilfsangebot-Hinweis an den Patienten bei schlechter Stimmung (Anregung der App-Experience-Prüfung) | widerspricht C-3 „keine Reaktion“ | – | **nicht umgesetzt** |
| O-22 | „Eigene Übung“ im Leerzustand (V2-43) vs. O-15 „entfällt“ | Heute, Datenmodell | – | O-15 gilt im Backend-Modus |
| O-23 | Profil-Zeile „Erinnerungen“: Inhalt? (Push ausgeschlossen) | Profil | – | Zeile entfällt |
| O-24 | Bildformate und Größenlimit | Storage-Bucket | – (L8) | [Vorschlag] JPEG/PNG/WebP, 5 MB |
| O-25 | Plan-Vorlagen: wer erstellt sie, UI zum Speichern eigener Vorlagen? (Produkt-Annahme: CuraOne-Beispiele + eigene der Praxis) | Plan-Editor, Brief | – | in Ausschnitt 2 nur Auswahl (Beispiele und per Seed); Speichern eigener Vorlagen braucht Brief-Ergänzung |
| O-26 | Notizen bearbeiten/löschen? | Schema, Rechte | – | nein, nur anlegen |
| O-27 | Inhalt des Physio-Ziels „Chats“ | Physio-Shell | – | Platzhalter „Kommt später“ |
| O-28 | Semantik „vorbereitet, ab Phase“ (PB-6) | `isReleased`, KI-Freigabe | – | 6.7 |
| O-29 | Verletzung ohne neue abschließen (eigene Aktion)? | Historie „Dauer bis Abschluss“ | – | nur über „Neue Verletzung“ |
| O-30 | Trainingstreue: Nenner (Kalendertage oder geplante Trainingstage); „letzter Termin“ = letzter Physio-Termin? | Kacheln, Historie | – | Kalendertage; letzter vergangener Physio-Termin, sonst seit Bindung |
| O-31 | Streak beim Physio: vom Gerät gemeldet (B-25) oder serverseitig berechnet? | Kachel PB-B AK 3 | – | vom Gerät gemeldet |
| O-32 | Golden-Umfang (Welten × Thema × Hoher Kontrast je Screen oder Auswahl) | Testlaufzeit, Pflege | – | 3.6 |
| O-33 | Feed in der Leiste: Brief sagt „ohne Platzhalter“, Auftrag „Platzhalter“ | Navigation | – | Brief gilt: kein Ziel |
| O-34 | Länge einer Frage an den Physio | Constraint | – (L5) | [Vorschlag] 500 Zeichen |
| O-35 | Bilder offline (Zwischenspeicher)? | Session offline mit Bildern | – | kein eigener Bild-Cache; offline ohne Bild → Illustration |
| O-36 | Material: Freitext-Chips oder feste Liste? | Packliste | – | Freitext, zusammengeführt ohne Groß-/Kleinschreibung |
| O-37 | Ton am Timer-Ende ohne Audio-Paket ausreichend (Web)? | Paketwahl | – | erst ohne Paket; sonst Vorschlag in L4 |
| O-38 | Was sieht der Patient von abgeschlossenen Verletzungen? | Patienten-App | – | nichts zusätzlich |
| O-38b | Bilder vor dem Upload neu kodieren (Metadaten wie Standort entfernen)? | Datenschutz Bilder (nur Testdaten) | – | nein im Prototyp; Risiko R2-19 |
| O-39 | „direkt in seinem Plan“ (PB-E AK 2) – Einwilligung bleibt davor? | Ablauf nach Einlösen | – | ja, Einwilligung bleibt Pflicht (A-1 AK 3) |
| O-40 | Auftrag nennt „FORCE RLS“; freigegeben ist RLS ohne `FORCE` (M-1) | Sicherheitsmodell | – | freigegebene Entscheidung bleibt |
| O-44 **neu** | Manny-Look bei Neubindung auf einem neuen Gerät: gilt der Wert aus dem Konto oder der im Code-Start (vor dem Code-Feld) neu gewählte? | sichtbares Verhalten nach Gerätewechsel; O-41 („bei Bindung wird der lokale Wert übertragen“) und der Zweck „bleibt beim Gerätewechsel erhalten“ widersprechen sich in diesem Fall | L3 | Konto-Wert gewinnt, wenn vorhanden (B-36) |
| O-1, O-3, O-5–O-8, O-11, O-12, O-14–O-16 | wie v1.2 | – | – | Annahmen wie v1.2 (O-3 durch C-2 für Schmerz 0–10 und Stimmung 1–5 bestätigt) |

---

## 15. Externe Schritte (nur benannt; jeweils einzeln zur Freigabe)

| Nr. | Schritt | Zweck | Risiko | vor |
|---|---|---|---|---|
| X2-1 | Supabase-Projekt in EU-Region anlegen | Backend | Kosten; Pausieren im kostenlosen Tarif | Live-Betrieb |
| X2-2 | Auth: E-Mail/Passwort an, Registrierung aus, anonyme Anmeldung an, Ratenbegrenzung prüfen, optional Captcha | Zugang | offene Registrierung bei Fehlkonfiguration | Live-Betrieb |
| X2-3 | `supabase link --project-ref <ref>`, `supabase db push` – je Lieferung nach DB-Tests und Sicherheitsreview | Schema live | offene Daten bei Fehlern | je Lieferung |
| X2-4 | Seed remote (`… --target remote --confirm-remote`) | Testdaten | löscht Testdaten | Präsentation |
| X2-5 | `app/config/supabase.local.json` füllen | Konfiguration | – | Live-Betrieb |
| X2-6 | Hosting Patienten-/Physio-Web (nur auf Wunsch; Physio am Handy braucht eine erreichbare Adresse) | Präsentation | weiterer Anbieter | Präsentation |
| X2-7 | Domain + App-Links (nur bei https-Links) | Deep Links | Domain nötig | – |
| X2-8 | **Werkzeuginstallation** in der Entwicklungsumgebung: Supabase-CLI, Docker-Daemon starten | lokaler Stack, Storage-Tests, E2E, DB-T40/T68 | Installation in der Umgebung | L8 (Storage-Tests), L9 |
| X2-9 | Android-/iOS-Build beim Nutzer (nur bei Gerät) | Präsentation, Geräte-Prüfliste (V2-14, V2-28) | Signatur | – |
| X2-10 | AV-Vertrag, Datenschutz-Konzept | echte Daten | nicht nötig bei Testdaten | echte Daten |
| X2-11 | Pepper für die Code-HMAC setzen (`app.secrets`, SQL-Konsole oder Vault; nie im Repo) | Code-Speicherung | Verlust → offene Codes ungültig | Live-Betrieb |
| X2-12 **neu** | Storage im Projekt prüfen: Bucket `exercise-images` aus der Migration angelegt, privat, Größen-/Typlimits gesetzt | Übungsbilder | öffentlicher Bucket bei Fehlkonfiguration | Live-Betrieb L8 |

Befehle vor Ausführung gegen die aktuelle Supabase-Doku prüfen.

**Vom Nutzer einzutragende Werte (ohne Werte):** `SUPABASE_URL`, öffentlicher Client-Schlüssel, `SUPABASE_SERVICE_ROLE_KEY` (nur Shell), Projekt-Referenz, `CURAONE_SEED_PASSWORD` (optional), `INVITE_LINK_BASE`, Pepper (X2-11).

---

## 16. Risiken

| Nr. | Risiko | Umgang |
|---|---|---|
| R2-1 | RLS-/Rechtefehler | Rollenmodell 6.1, Pflichtliste 6.14, DB-Tests, Sicherheitsreview je Lieferung vor X2-3 |
| R2-2 | Nachbildung ≠ Supabase | 12.1; Stack-Wiederholung in L9 |
| R2-3 | Massenhaft anonyme Konten | ohne Rechte; Bremsen 6.5; Captcha optional |
| R2-4 | **Umfang deutlich größer als v1.2** | 9 Lieferungen mit eigenem Review; Abbruch nach jeder Lieferung möglich, Stand bleibt lauffähig |
| R2-5 | Gestaltung blockiert UI | F2-D2 früh, parallel zu L1/L2 |
| R2-6 | Warteschlange: doppelt/verloren | Geräte-IDs, Idempotenz, Fehlerklassen, Tests |
| R2-7 | Flutter Web als Physio-Oberfläche am Handy (Tastatur, Teilen, Dateiauswahl im mobilen Browser) | Matrix 390×844/320×568, `nav_checks`, Geräte-Prüfliste; Rückfall „Link kopieren“ |
| R2-8 | Präsentation offline | Demo-Modus, Zwischenspeicher, Session offline |
| R2-9 | Pausiertes Projekt | vor Termin prüfen |
| R2-10 | Parallelarbeit unter `app/` | parallel nur L1 (`app/`) und F2-1/F2-1R (`supabase/`, `.gitignore`); F2-2 (Seed, `app/pubspec.yaml`) erst nach L1; ab F2-2 nacheinander (MAJOR-1) |
| R2-11 | Katalog und Vorlagen wirken geprüft | Kennzeichnung als Beispiel |
| R2-12 | `auth.users` aus Definer-Funktion nicht löschbar | B-7 in L9; Ausweg Edge Function |
| R2-13 | Physio löst selbst einen Code ein | wie v1.2 |
| R2-14 | Durchprobieren von Codes | wie v1.2 (N-6) |
| R2-15 | Wartende Schreibvorgänge beim Löschen | Transaktionen kurz; Zeitlimit |
| R2-16 **neu** | Goldens-Explosion durch Welten × Thema × Kontrast | Umfang O-32; Komponenten voll, Screens Auswahl |
| R2-17 **neu** | Timer-Genauigkeit und Hintergrundverhalten je Plattform (Web-Tab im Hintergrund) | Zeitstempel statt Dauern, Pause bei Lebenszyklus-Wechsel, Tests mit fester Uhr, Geräte-Prüfliste |
| R2-18 **neu** | Einladungslink in Messenger-Verläufen | einmalig einlösbar, 14 Tage, Neubindungs-Hinweis; „Neuen Code erzeugen“ |
| R2-19 **neu** | Übungsfotos mit Personen oder Standort-Metadaten | nur Testdaten; privater Bucket; Patient sieht nur Übungen (und Bilder) in Positionen seines aktuellen Plans, aktiv oder vorbereitet (N-16); O-38b |
| R2-20 **neu** | Stimmungsdaten sind besonders sensibel | nur Physio der Praxis, keine Reaktion in der App, Einwilligung nennt es, Löschen nach O-9, Datenschutz-Konzept vor echten Daten (X2-10) |
| R2-21 | Kürzung greift ab Schmerz 6 häufiger als die Warnzeichen | entschieden (E-28 = 6); Hinweis „Heute etwas kürzer“ erklärt es; Wirkung in L9 im Kriterienbericht beobachten |
| R2-22 **neu** | Streak beim Physio weicht vom Gerät ab (Gerät offline, Neubindung) | Anzeige „zuletzt gemeldet am …“ (Gestaltung F2-D2 D), O-31 |
| R2-23 **neu** | Kalendertage zwischen Gerät, Server (UTC) und Physio verschieden | Datumsbasis 6.7: Tage nur vom Gerät mit Plausibilitätsprüfung, Sicherheitsregeln ohne Datum, gemeinsame Fixtures Mitternacht/Zeitzone; DB-T68a, DB-T80 |
| R2-24 **neu** | Nachträgliche Warnzeichen durch verspätete Check-ups | gewollt (vom Nutzer bestätigt, N-16) und reihenfolgeunabhängig (6.9), FIFO je Gerät, eine gemeinsame Meldung je Eingang; verspätete Einträge nie verworfen (6.7 Nr. 3, 8.11); DB-T82, DB-T83, DB-T84 |
| R2-25 **neu** | Manny-Grafiken vergrößern App und Goldens (24 Dateien, ca. 1,7 MB) | alle 24 Dateien (4 Posen × 2 Varianten × 3 Dichten) im Repo, weil V2-73 die Dichte-Auswahl 1/2/3 verlangt; Goldens je Variante nur für Manny-Komponenten und Look-Schritt |

---

## 17. Annahmen

| Nr. | Annahme | Herkunft |
|---|---|---|
| B-1 | keine KI, keine Edge Functions in Ausschnitt 2 | v1.2 |
| B-2 | Physio-Bereich Deutsch, Flutter-Web am Rechner **und im Handy-Browser**; keine native Physio-App | v1.2, angepasst (PB-1) |
| B-3 | „Woche N“ aus `injuries.reference_date` | v1.2, angepasst |
| B-4 | Patient liest Krankengeschichte | v1.2 |
| B-5 | Patient sieht `warning_signs` nicht | v1.2 |
| B-7 | `delete_my_data()` darf `auth.users` des Aufrufers löschen | v1.2 |
| B-8 | Link füllt Feld, Einlösen nach Bestätigung | v1.2 |
| B-9 | lokaler Fortschritt startet nach dem Einlösen neu | v1.2 |
| B-10 | entfallene Positions-IDs verwerfen Tagesänderungen | v1.2 |
| B-11 | gelöste Bindung → lokale Daten weg, Startbildschirm | v1.2 |
| B-12 | Schreiben über Warteschlange | v1.2 |
| B-13 | eigene Übungen je Praxis wiederverwendbar (bestätigt durch PB-F AK 3) | v1.2 |
| B-14 | Streak und Pfad-Fortschritt lokal | v1.2 |
| B-15 | Check-ups über RPC (`submit_daily_checkup`, `submit_session_checkup`) statt direktem Insert | v1.2, angepasst |
| B-16 | Ein Tag mit nur ausgefülltem Tages-Check-up, aber ohne Übung, zählt **nicht** für den Streak | (Produkt-Annahme) Abläufe, Frage 2 |
| B-17 | Ton und Vibration standardmäßig an, abschaltbar | (Produkt-Annahme) Abläufe, Frage 3; Brief 3.6 |
| B-18 | Gewicht im Check-up nur „erhöht“ ja/nein; kg-Angabe im Baukasten | (Produkt-Annahme) Abläufe, Frage 4 |
| B-19 | Hauptphysio: genau einer je Patient, anfangs der Anleger, änderbar; nur Filter, kein Zugriffsrecht | (Produkt-Annahme) PB-A AK 3, Physio-Bereich Frage 2 |
| B-19a | Plan-Vorlagen: CuraOne liefert Beispielvorlagen, die Praxis kann eigene speichern (UI siehe O-25) | (Produkt-Annahme) Physio-Bereich Frage 1 |
| B-19b | Notiz nur für die Praxis sichtbar, Patient sieht sie nicht | (Produkt-Annahme) PB-C |
| B-19c | Bezugsdatum einer neuen Verletzung = Eingabe oder Anlagetag | Plan |
| B-20 | Demo-Modus behält Onboarding und Beispielpfad aus Ausschnitt 1 im neuen Look | Plan |
| B-21 | „Alles löschen“ entfernt auch Darstellungs- und Session-Zustand | Plan |
| B-22 | Wegklicken der Tages-Check-up-Karte nur lokal | Plan |
| B-23 | Unit erledigt mit der ersten erledigten Übung des Tages; zurückgenommen, wenn am selben Tag alle Häkchen entfernt werden | Plan (aus T-5) |
| B-24 | Rückgängig „am selben Tag“ prüft die App; der Server erlaubt das Löschen eigener Ergebnisse, solange der Patient aktiv ist | Plan |
| B-25 | Streak beim Physio = vom Gerät mit jeder Session gemeldeter Wert | Plan (O-31) |
| B-26 | Neue Verletzung: Streak und Freezes bleiben, Pfad startet neu | Plan |
| B-27 | Kurzanleitung in der Session = optionales Feld `short_instruction`, sonst erste Zeile der Beschreibung | Plan |
| B-28 | Pausendauer ohne Angabe des Physios: 60 s (wie Schätzregel N-7, bestätigt mit O-17 a) | Plan, N-14 |
| B-29 | Suche nach Name im geladenen Bestand der Praxis | Plan |
| B-30 | Smileys als Emoji (systemabhängig) | Nutzerentscheidung N-11 |
| B-31 | entfällt: Speicherung und Lage des Look-Schritts sind entschieden (N-16, O-41, O-43) | – |
| B-32 | `injury_id` von Tages-Check-ups und Fragen = aktive Verletzung beim Eingang (ein verspäteter Check-up vom Tag eines Verletzungswechsels kann bei der neuen Verletzung landen) | Plan (MINOR-4) |
| B-33 | Tagesangaben aus Physio-Aktionen (`closed_on`, Standard-`reference_date`) = lokaler Tag des Physio-Geräts | Plan (MAJOR-2, 6.7) |
| B-34 | entfällt: „nächstes Ziel“ = Titel der nächsten Phase ist entschieden (N-16, O-42); nur der Text für die letzte Phase bleibt [Vorschlag] (6.12) | – |
| B-35 | Plausibilitätsgrenze für Warteschlangen-Einträge (`submit_daily_checkup`): Bindungstag − 1 bis UTC-Datum + 1, ohne Höchstalter; `invalid_local_day` stellt den Eintrag zurück statt ihn zu verwerfen | Plan (MAJOR-B, 6.7 Nr. 3, 8.11) |
| B-36 | Neubindung auf neuem Gerät: Hat das Konto einen Manny-Look, übernimmt das neue Gerät ihn; sonst wird der lokale Wert übertragen | Plan (O-41, Rückfrage O-44) |

(B-6 aus v1 ist durch 6.5 ersetzt.)

---

## 18. Vorschläge für `KONVENTIONEN.md` (nur auf Nutzerwunsch)
1. Physio-Texte in `strings_physio_de.dart`.
2. `supabase_flutter` nur unter `lib/backend/**` und `main*.dart`.
3. Importgrenze `lib/physio/**` ↔ `lib/ui/**`.
4. Jede Tabelle mit RLS; jede Sicherheitsaussage mit benanntem DB-Test; Definer-Funktionen mit `search_path = ''` und eigener Rechteprüfung; **Pflichtliste 6.14 für jede neue Patienten-Tabelle**.
5. Keine Schlüssel in Dateien.
6. **Neu:** Welt- und Uhrzeit-abhängige Darstellung nur über `world_time.dart` mit injizierter Uhr; Tests immer mit fester Uhr.
7. **Neu:** Timer und Sessions speichern Zeitstempel, nie laufende Dauern.

---

## 19. Ältere Änderungsprotokolle

### v2.0 → v2.1 (Paket S3-K1)

| Befund / Entscheidung | Änderung | Stelle |
|---|---|---|
| MAJOR-1 L1 ∥ L2 nicht getrennt | Parallel nur L1 (`app/`) und F2-1/F2-1R (`supabase/`, `.gitignore`); F2-2 Seed (schreibt `app/tool/seed/`, `app/pubspec.yaml`/`.lock`) erst nach L1 | 2.2 (L2), 2.3 (F2-2), Reihenfolge 2.3, 5, 10, 11, R2-10 |
| MAJOR-2 „freigegeben“ ohne gemeinsame Datumsbasis | Tage nur vom Gerät (`local_day`) mit Plausibilitätsprüfung ±1 Tag; Sicherheitsregeln ohne Datum (Übung/Bild sichtbar für jede Position des aktuellen Plans); Fixtures „Mitternacht/Zeitzone“ | 6.1 Nr. 5, 6.2 `exercises`, 6.4, 6.6, 6.7 „Datumsbasis“, 6.11, 5, DB-T63, DB-T68, DB-T68a, DB-T80, R2-23, B-33; KI-Plan 4.2/4.2.1 |
| MINOR-1 `create_patient`-Idempotenz | `ON CONFLICT DO NOTHING` + `FOR UPDATE` (serialisiert), Parametervergleich per `create_params_hash`, abweichend → `idempotency_mismatch` | 6.2 `patients`, 6.6, DB-T64b |
| MINOR-2 zwei Lieferungen für `create_patient`/`regenerate_invitation` | beide in L2 (Migration 05), UI in L6; F2-7a nur `set_main_physio`; Vorlagen-Lesezugriff und DB-T76 in L2 | 6.4, 2.3 (F2-1, F2-7a), 5, 12.2 |
| MINOR-3 `training_sessions.mode` | alle Spalten in L2 (Migration 06); F2-5a nur Check-up nach der Einheit; DB-T73 in L2 | 6.2, 2.2, 2.3, 5, 12.2 |
| MINOR-4 `injury_id` serverseitig | Herleitung über `plan_id` der Session bzw. die Session; Check-ups/Fragen = aktive Verletzung (Annahme B-32) | 6.2, 6.3, 8.11, DB-T61, B-32 |
| MINOR-5 Stimmungskette reihenfolgeabhängig | Warnzeichen je Tag (`warning_signs.local_day`, Unique), Auswertung für X und Folgetage, FIFO je Gerät, Test außer der Reihe | 6.2, 6.9, 8.11, DB-T57, DB-T82, R2-24 |
| MINOR-6 (KI-Plan) | siehe KI-Plan v2.4 | KI-Plan 4.8.2, 6.2, 6.3 |
| MINOR-7 Kachel 6 ohne Datenquelle | Datenquelle Plan der aktiven Verletzung, `phase_summary`, Annahme „nächstes Ziel“ | 6.12, 9, 3.7 Teil D, 13.3, O-42, B-34 |
| MINOR-8 `assign_exercise` ohne Prüfung `release_with_phase_id` | Prüfung gleicher Plan und Freischalt-Regeln | 6.11, DB-T67 |
| MINOR-9 Hilfsfunktionen ohne Aufruferprüfung | Aufruferprüfung in `current_injury_id`/`current_plan_id`/`physio_can_see_patient`; Schema `app` nicht exponiert | 6.1 Nr. 5, DB-T81 |
| NIT Schätzregel ohne Dauer | „/60, aufrunden, min. 1“ ergänzt | 8.4 |
| N-14 O-17 (+ a, b) | `duration_sec` je Satz; Schätzregel mit `pause_sec`/60 s; Kürzung halbiert Sekunden | 0, 6.2, 8.4, 8.7, 12.3, 13.5 |
| N-14 O-18 | Schwellung 0–3 feste Spalte, 6. Frage | 0, 6.2, 6.4, 6.9, 6.12, 8.6, 3.7 Teil B, 13.1, 13.2, DB-T56 |
| N-14 O-19 | Einschränkungen Einzelwert-Skala | 6.2, 8.6, 3.7 Teil B, DB-T75 |
| N-14 O-2, O-2a, O-2b | Regeln entschieden (Vortag, Schwellung mit gleichem Hinweis, jeden weiteren Tag erneut, Lücke unterbricht); `is_provisional` entfällt; Einwilligungstext | 0, 6.2, 6.9, 7.2, 8.6, 10, DB-T57, DB-T77, 13.2, 14 |
| N-14 E-28 | Kürzung ab Schmerz 6 | 8.2, 8.7, 13.2, R2-21 |
| N-15 Manny (Brief-Ergänzung 1 freigegeben) | finale Grafiken beider Varianten in L1, Look-Schritt im Onboarding (5 Schritte), Profil-Zeile, lokal gespeichert mit Schema-Sprung 1 → 2, Look-Schritt auch im Code-Start, Tests und Rückverfolgung V2-56 (ersetzt), V2-65–V2-75 | 0, Grundlagen, 2.2, 2.3, 3.1–3.7, 5, 8.1, 8.12, 12.3, 13.4, 13.5, O-41, O-43, B-31, R2-25 |
| Brief-Folgen O-18/O-19 | Brief-Ergänzung in F2-D2 Teil B (vor L5, Nutzerfreigabe): 6 Fragen, „Frage N von 6“, Einschränkungen-Skala, Kachel 2 mit Schwellung | 3.7, 2.2 (L5), 13.4 |
| unverändert | Rollenmodell, RLS ohne `FORCE`, entzogene Standardrechte, Definer mit `search_path = ''`, Sichten `security_invoker`, Manny-Chat nie für Physio. Begründet geändert: Patientensicht auf `exercises`/Übungsbilder ohne Datumsbezug (MAJOR-2, enger: Aufruferprüfung der Hilfsfunktionen, MINOR-9) | 6.1 |

### v1.2 → v2.0 (Kurzfassung; Abschnittsangaben beziehen sich auf v2.0)

| Thema | Was ist neu oder geändert | Abschnitt |
|---|---|---|
| Grundlagen | neu: `curaone-ablaeufe-training-checkup.md` (T-1–T-6, C-1–C-3), `curaone-physio-bereich.md` (PB-1–PB-9, PB-A–PB-G), `curaone-feed.md` (nur Abgrenzung), `design-brief-v2.md` (ersetzt Brief v1 inkl. Errata/Ergänzungen), Nutzerentscheidungen 2026-10-14 | Kopf, 0 |
| Reihenfolge | **Redesign-Migration ist die erste Lieferung (L1)**; danach entstehen alle neuen Screens im neuen Look | 0, 2, 3 |
| Paketschnitt | v1.2-Pakete F2-0 … F2-R ersetzt durch **9 Lieferungen L1–L9**, je einzeln reviewbar und lauffähig | 2 |
| Navigation | Patient 4 Ziele (Pfad, Heute, Chats, Profil), **kein Feed-Ziel in Ausschnitt 2** (Brief v2, 5 und 7.12); Physio 4 Ziele, Leiste am Handy, Seitenleiste ab 840 dp | 3.3, 4 |
| Physio-Zugang | Flutter-Web-Einstieg `main_physio.dart` bleibt (W-A), muss jetzt **auch am Handy** bedienbar sein (PB-1) | 4 |
| Datenmodell | neu: `injuries`, `plan_templates`, `exercise_results`, `session_checkups`(+`_items`), `daily_checkups` (ersetzt `wellbeing_reports`), `patient_questions`, `practice_notes`, `exercise_images`; geändert: `patients`, `plans`, `plan_items`, `exercises`, `training_sessions`, `warning_signs` | 6.2 |
| Sicherheitsregeln | **unverändert:** RLS ohne `FORCE` (M-1), entzogene Standardrechte, Definer mit `search_path = ''`, Sichten nur mit `security_invoker`, Manny-Chat nie für Physio, Testdaten. **Begründete Änderungen:** Storage für Übungsbilder, `report_wellbeing` → `submit_daily_checkup`, Pläne je Verletzung, Schreibsperre und Löschumfang auf neue Tabellen erweitert | 6.1, 6.14 |
| Einladung | `create_patient` mit Pflicht nur Vorname + Verletzung **oder** Vorlage, idempotent per Client-ID, sofort QR + Link + Teilen; Code-Regeln (10 Zeichen Crockford-Base32, HMAC mit Pepper, Bremse je Sitzung) unverändert | 6.5, 6.6 |
| Check-ups | Tages-Check-up (C-2), Check-up nach der Einheit (C-1), Stimmungs-Nachricht nach 5 Tagen (C-3) als Warnzeichen ohne Details, keine Reaktion gegenüber dem Patienten | 6.9, 8.6 |
| Kürzung bei Schmerz | Kürzungsregel E-36 gilt laut Ablauf 4b jetzt **schon in Ausschnitt 2** (deterministisch, ohne KI); damit ist E-28 blockierend für L5 | 8.7, 14 |
| DB-Tests | DB-T01–T47 angepasst (Lieferung je Test), neu DB-T48–DB-T79 | 12.2 |
| Rückverfolgung | Abläufe 1–4, PB-A–PB-G, V2-1–V2-64, v1.2-AK | 13 |
| Offene Werte | O-2 (inkl. Schwelle „sehr schlechte Stimmung“), E-28, E-7, E-15, E-27, E-30, E-31 und neue Fragen O-17–O-40 mit Auswirkung und blockierter Lieferung | 14 |
| Annahmen | Produkt-Annahmen aus den Dokumenten übernommen und gekennzeichnet (B-16 ff.) | 17 |

### v1 → v1.1 (Review R-P2, Nutzerentscheidungen 2026-10-12)

| Befund / Entscheidung | Abschnitt (v1.1) |
|---|---|
| M-1 FORCE RLS / Definer-Eigentümer | 4.1; DB-T02, DB-T38 |
| M-2 Sicht über `invitations`, Default-Grants, `EXECUTE PUBLIC` | 4.1, 4.3, 4.4; DB-T01, DB-T05, DB-T09, DB-T37 |
| M-3 anonyme Sitzung, Shim, `redeem_invitation` | 4.1, 4.4, 10.1; DB-T11, DB-T12 |
| M-4 Wettrennen Löschen/Warteschlange | 4.3, 4.7, 6.7; DB-T31, DB-T36 |
| M-5 `save_plan` IDs/Fremdschlüssel | 4.3, 4.6; DB-T20 bis DB-T23 |
| M-6 Neubindung lässt Physio den Chat lesen | 4.4, 5.2, R2-13; DB-T33 bis DB-T35 |
| m-1 bis m-9, K-m3, K-m6 | siehe v1.1 |
| N-1 bis N-5, O-4, O-9, O-10, O-13 | 0, 2, 4.4, 4.7, 5.2, 6.3, 6.4, 7 |
| Neu | B-15, R2-13 bis R2-15, X2-11, `redeem_attempts`, `account_events` |

### v1.1 → v1.2 (Re-Review R-P2-RR, Nutzerentscheidungen Runde 2)

| Befund / Entscheidung | Abschnitt (v1.2) |
|---|---|
| NEU-1 Lock-Trigger Definer, `OLD` bei DELETE | 4.3, 4.7; DB-T42, DB-T43 |
| NEU-2 Sperre nur für Patienten-Schreibvorgänge | 4.3, 4.7; DB-T44, DB-T45 |
| NEU-3 Warnzeichen und Chat-Tabellen in der Sperre | 4.3; KI-Plan 8 |
| NEU-4 Freitextprüfung | KI-Plan 4.7 |
| NEU-5 fremde IDs in `save_plan` | 4.6; DB-T46 |
| NEU-6 DB-T01/T37 gegen echten Stack | 10.2, 13 |
| NEU-7 `warning_raised` bei Wiederholung | 4.4; DB-T41 |
| NEU-8 Kürzungsregel ohne Sätze | KI-Plan 4.2.1/4.2.3 |
| NITPICKs, N-6, N-7, N-8 | 4.3, 4.5, 6.3, 12 |

Die Abschnittsnummern in diesen Tabellen beziehen sich auf v1.1/v1.2; in v2.0 entsprechen 4.x → 6.x, 5.x → 7.x, 6.x → 8.x, 7 → 9, 8 → 10, 9 → 11, 10 → 12, 11 → 13, 12 → 14, 13 → 2, 14 → 15, 15 → 16, 16 → 17.
