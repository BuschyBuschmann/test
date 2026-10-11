# Übergabe an die nächste Sitzung

Stand: 2026-10-11 (Abend) · Sitzung: https://claude.ai/code/session_01Ck3JuAWSeXZfvE4hCvkths
Vorherige Sitzung: https://claude.ai/code/session_01D5CHDFnfv9z12fZKngJeAZ · Branch: `claude/wonderful-bell-beag0y`

## Wo wir stehen

Projekt: Reha-Begleiter-App **CuraOne** (Physio, erster Typ Kreuzband/ACL). **Der erste Ausschnitt ist fertig umgesetzt, reviewt und abgenommen:**
- Onboarding (4 Schritte)
- Pfad mit Manny, Streak und Ausblick „Prävention & Gesundheitssport“
- „Heute“
- „Deine Daten“
- Manny-Chat (nur ansehen, ohne Schreiben)
- Nachrichten-Platzhalter

Alles ohne KI, alle Daten lokal.

### Dokumente

| Dokument | Status | Ort |
|---|---|---|
| Design-Brief v1 inkl. Errata E-1 bis E-5 | freigegeben | `docs/design/design-brief-v1.md` (Abschnitt 14) |
| Brief-Ergänzung 1 (Rückgängig, Tageswechsel, Deine Daten, Pfad-Tipps) | freigegeben | `docs/design/design-brief-v1-ergaenzung-1.md` (UI-37–69) |
| Brief-Ergänzung 2 (Manny-Chat, Nachrichten) | freigegeben | `docs/design/design-brief-v1-ergaenzung-2.md` (UI-70–89) |
| Brief-Ergänzung 3 (Ausblick Prävention & Gesundheitssport) | freigegeben | `docs/design/design-brief-v1-ergaenzung-3.md` (UI-90–99), Mockup `docs/design/mockups/pfad-ausblick-v1.png` |
| Vollständigkeits-Check (`/app-experience`) | gespeichert | `docs/produkt/curaone-vollstaendigkeit.md` |
| Flutter-Plan v1.3 (+ Paket U3c) | freigegeben, umgesetzt | `docs/plan/flutter-plan-v1.md` |
| **Kriterienbericht** UI-1 bis UI-99 | aktuell | `docs/plan/kriterienbericht-v1.md` (89 erfüllt, 9 teilweise, 1 [D-offen]; Geräte-Prüfliste Abschnitt 5) |
| KI-Plan v1.2 (nächster Ausschnitt, Spec 7) | zur Freigabe | `docs/plan/ki-plan-v1.md`; Entscheidungen E-1 bis E-26 offen |
| `KONVENTIONEN.md` | verbindlich | Projektstamm |

### Umsetzung (App unter `app/`; Umsetzung mit sonnet, Code-Reviews mit opus)

| Paket | Status |
|---|---|
| U1a Fundament, U1b Logik + State, Review R-U1 + Korrekturen | ✅ |
| U2a Bausteine, U2p Prüf-Infrastruktur, Review R-U2/A-U2 + Korrekturen | ✅ |
| U2b Routen/Onboarding/Shell, U2c Chat + Nachrichten, Review R-U3/A-U3 + Korrekturen | ✅ |
| U3a Pfad, U3b Heute, U3c Pfad-Ausblick, U4 Deine Daten + Kriterienbericht | ✅ |
| **Abschluss-Review** (reviewer opus + ui-designer) mit Korrekturrunden AB-K1, AB-K2 | ✅ FREIGABE bzw. ABGENOMMEN MIT AUFLAGEN; alle Auflagen erledigt |

Letzter Prüfstand (HEAD `99ec406`, vom Orchestrator nachgeprüft):
- `flutter analyze` 0
- `flutter test --exclude-tags golden,matrix` 1069 grün
- `--tags golden` 14 grün (9 + 5 neue, vom Nutzer freigegeben)
- `--tags matrix` 847 grün (RM: 582/582 Tap-Ziele)

Laut Umsetzer zusätzlich:
- `nav_checks.mjs` 79/79 (zweimal)
- `main_smoke.mjs` ok
- Pixel-Kontrast 0 unter Schwelle

## Wichtige Entscheidungen (Auswahl; vollständig in Plan Abschnitt 18, Brief-Abschnitten „Nutzerentscheidungen“ und Errata)

- Modelle: haiku leicht, sonnet normal, opus schwer; Review möglichst mit anderem Modell als die Umsetzung.
- Streak:
  - Jeder verpasste Tag kostet der Reihe nach 1 Freeze, danach wird 1 ungedeckter Tag toleriert, beim 2. ungedeckten Tag Reset.
  - Start mit 2 Freezes. „Abends“ beginnt um 18:00.
- Eintrag über Mitternacht zählt für den Vortag. Unlesbare Daten führen zum automatischen Neustart; Programmierfehler zu „Nochmal versuchen“ (Daten bleiben).
- Pfad endet nicht mit Return to Sport: Darüber steht der gesperrte Ausblick „Prävention & Gesundheitssport“ (Ergänzung 3). Die volle Phase kommt später.
- Große Schrift (ab 150 %):
  - Pfad: Eine feste schmale Zeile mit „Woche N“ und dem Icon „Deine Daten“ bleibt stehen.
  - Dialoge scrollen als Ganzes, ihre Buttons zeigen dann kein Symbol.
  - Daten-Sheet: kompakter Zustand bei < 440 dp (Erratum E-5).
  - „Verwerfen“ schließt das Sheet.
- Prüfwerkzeuge:
  - Keine Szenario-Ausnahmen in der Matrix.
  - Ausnahmen nur eng gefasst und mit Selbsttest (Blase/Hint beim Scrollen, bekannte Messeigenheit von Textfeldern).
- Commits: nur auf Nutzerauftrag; Zwischensicherungen nach jedem verifizierten Paket sind freigegeben.

## Offene Punkte

1. **Geräteprüfung durch den Nutzer:** `docs/plan/kriterienbericht-v1.md` Abschnitt 5 (D-1 bis D-14). Dazu gehören TalkBack/VoiceOver, Systemschalter für Bewegung und Kontrast, echte Tastatur, Safe Area, Android-Zurück und Blur-Optik.
2. **`/app-experience`, Bereich 4:** die gebaute App im Browser prüfen, wie früher vereinbart („Vorher Check + später Prüfung“).
3. **Bekannte Grenzen:**
   - Overlays werden nur in der Ruhelage gelesen.
   - Horizontales Scrollen ist nicht abgedeckt.
   - Der Hinweis zum Ausblick zeigt bei 320×568 × 2,0 nur 3 von 5 Zeilen (scrollt innen, kein Timer-Schließen; akzeptiert).
   - Restfenster der Textfeld-Kontrast-Ausnahme (< 1,1).
   - 23 Richtwert-Befunde „Sichtfläche“ auf dem Pfad (nur beratend).
4. **Vorschläge für `KONVENTIONEN.md`** (Nutzer fragen, nicht ungefragt eintragen):
   - Beispieltexte der Prüfumgebung in `lib/dev/preview_texts.dart`.
   - `lib/dev`/`main_preview.dart` nie Teil von `main.dart`.
   - Neue Szenarien in `scenarios.dart` **und** `scenarios.json`.
   - Datumsauswahl nur über `showCuraDatePicker`.
   - Zustandsabhängige Strukturen bauen Felder nicht neu auf (Fokuserhalt).
   - Überdeckte Routen zählen in der Matrix nicht.
5. **Phase „Prävention & Gesundheitssport“:** Spec später über `/product-strategist`. Offen sind Länge, Inhalte und Wahlmöglichkeiten, Streak-/Freeze-Regeln und Wochenrhythmus dort sowie die Fachinhalte (Physio-Framework).
6. **KI-Plan:** Freigabe und Entscheidungen E-1 bis E-26 vor dem KI-Ausschnitt. Blockierend sind u. a. Backend, Weg zur KI/EU-Region, Auth, Zugang in der Testphase und Limits.
7. **Direktnachrichten** haben keine Spec (Platzhalter), später über `/product-strategist`.
8. **Bekannte Blocker unverändert:** Physio-Framework, Datenschutz-Konzept (Anwalt, inkl. MDR-Frage), Manny-Illustration.
9. **PR:** Seit dem gemergten PR #7 liegt alles auf dem Branch. Bei Bedarf einen neuen PR erstellen (nur auf Nutzerwunsch).

## Prüfbefehle (im Verzeichnis `app/`)

```
export PATH=/opt/flutter/bin:$PATH
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --exclude-tags golden,matrix
flutter test --tags golden
flutter test --tags matrix
flutter build web --release --no-web-resources-cdn -t lib/main_preview.dart
npx http-server build/web -p 8765 -s &   # dann: node tool/screens/shoot.mjs, node tool/screens/nav_checks.mjs
```
Hinweis: Hintergrund-Server per PID beenden, nicht per `pkill -f` (trifft die eigene Shell).

## Startprompt für die neue Sitzung

> Lies `docs/UEBERGABE.md`, `KONVENTIONEN.md` und `docs/plan/kriterienbericht-v1.md`.
> Der erste Ausschnitt ist fertig. Nächste Schritte nach Wahl des Nutzers: Geräteprüfung bzw. `/app-experience` Bereich 4, PR, KI-Plan-Entscheidungen oder Spec „Prävention & Gesundheitssport“.
