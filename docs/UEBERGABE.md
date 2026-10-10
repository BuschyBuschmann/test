# Übergabe an die nächste Sitzung

Stand: 2026-10-07 (Abend) · Sitzung: https://claude.ai/code/session_01Ck3JuAWSeXZfvE4hCvkths
Vorherige Sitzung: https://claude.ai/code/session_01D5CHDFnfv9z12fZKngJeAZ · Branch: `claude/wonderful-bell-beag0y`

## Wo wir stehen

Projekt: Reha-Begleiter-App **CuraOne** (Physio, erster Typ Kreuzband/ACL). Erster Ausschnitt =
Onboarding (4 Schritte), Pfad mit Manny und Streak, „Heute“, plus „Deine Daten“, Manny-Chat
(nur sichtbar, ohne Schreiben) und Nachrichten-Platzhalter. Ohne KI, alles lokal.

| Schritt | Status | Ergebnis |
|---|---|---|
| Design-Brief v1 inkl. Errata E-1/E-2 | freigegeben | `docs/design/design-brief-v1.md` (Abschnitt 14 Errata) |
| Brief-Ergänzung 1 (Rückgängig, Tageswechsel, Deine Daten, Pfad-Tipps) | freigegeben | `docs/design/design-brief-v1-ergaenzung-1.md` (UI-37–69) |
| Brief-Ergänzung 3 (Ausblick Prävention & Gesundheitssport) | freigegeben | `docs/design/design-brief-v1-ergaenzung-3.md` (UI-90–99), Mockup `docs/design/mockups/pfad-ausblick-v1.png` |
| Brief-Ergänzung 2 (Manny-Chat, Nachrichten) | freigegeben | `docs/design/design-brief-v1-ergaenzung-2.md` (UI-70–89), Mockups `docs/design/mockups/*-v4.png`, `manny-chat-v1.png`, `nachrichten*-v1.png` |
| Vollständigkeits-Check (`/app-experience`) | gespeichert | `docs/produkt/curaone-vollstaendigkeit.md` |
| **Flutter-Plan v1.3** | **freigegeben** | `docs/plan/flutter-plan-v1.md` (9 Pakete, Abschnitt 14; Nutzerentscheidungen Abschnitt 18) |
| KI-Plan v1.2 (nächster Ausschnitt, Spec 7) | zur Freigabe, 2 Review-Runden durch | `docs/plan/ki-plan-v1.md`; Entscheidungen E-1–E-26 offen |
| `KONVENTIONEN.md` | verbindlich | Projektstamm |

### Umsetzung (App unter `app/`, alle Pakete mit sonnet)

| Paket | Status | Verifikation (vom Orchestrator nachgeprüft) |
|---|---|---|
| U1a Fundament | ✅ committet | analyze 0 |
| U1b Logik + State | ✅ committet | |
| Review R-U1 (opus) + Korrektur U1-K1 + Re-Review | ✅ Freigabe | |
| Fix „Bug ≠ Datenverlust“ (U1-K2) | ✅ committet | |
| U2a Bausteine | ✅ committet | 9 Goldens (Bilder committet, **Sichtung durch ui-designer und Nutzerfreigabe stehen aus**) |
| U2p Prüf-Infrastruktur | ✅ committet | Preview-App, Matrix (103 Fälle, 5,7 s), `tool/screens/shoot.mjs` (Pipette, Pixel-Kontrast, CDP-Simulation), Web-Punkte 12.5 geklärt |
| Stand gesamt | | `flutter analyze` 0 · `flutter test --exclude-tags golden,matrix` 554 grün · `--tags golden` 9 grün · `--tags matrix` 103 grün |
| **Review nach U2p** (Plan 14: Bausteine + Prüf-Infrastruktur) | **offen – hier ansetzen** | reviewer (opus) Code + ui-designer Design-Abnahme der Goldens/Screenshots, parallel |
| U2b Routen + Onboarding + Shell | offen | danach U2c, U3a, U3b, U4 (Reihenfolge verbindlich) |

## Wichtige Entscheidungen dieser Sitzung (Auswahl, vollständig in Plan Abschnitt 18 und Brief-Abschnitten „Nutzerentscheidungen“)

- Modelle: haiku leicht, sonnet normal, opus schwer; Review möglichst mit anderem Modell als Umsetzung.
- Streak: jeder verpasste Tag kostet der Reihe nach 1 Freeze, danach 1 ungedeckter Tag toleriert, beim 2. ungedeckten Reset; Start 2 Freezes. „Abends“ ab 18:00.
- Eintrag über Mitternacht zählt für den Vortag. Unlesbare Daten → automatischer Neustart; Programmierfehler → „Nochmal versuchen“ (Daten bleiben).
- Zurück: Onboarding immer ein Schritt zurück; Heute → Pfad; Pfad → App schließen.
- Manny-Button unten rechts (+ Manny auf dem Pfad antippbar), Nachrichten-Button gestapelt darüber, Scroll-Reserve auf Heute. Chat nur deaktivierte Eingabe (kein `canSend`).
- KS-Schnittstellen für die KI schlank (KS-1 synchron, KS-5 nur `messages`, KS-7 entfällt); Red-Flag-Vorprüfung erst im KI-Ausschnitt.
- Boss „Return to Sport“ zeigt in Woche 12 „Dein Ziel: zurück in deinen Sport.“
- Beispieltermine: Physio Mo–Fr 17:00, Arzt zusätzlich Fr 09:30.
- Commits: nur auf Nutzerauftrag; der Nutzer hat in dieser Sitzung Zwischensicherungen freigegeben.

## Offene Punkte

- **Nächster Schritt:** Review nach U2p (reviewer opus: `test/matrix/matrix_checks.dart` vs. Selbsttests, Ausnahme in `checkTextContrast`, Untergrund-Klassifizierung `lib/dev/text_probe.dart`, Pixel-Kontrast in `shoot.mjs`, Marker-Konventionen; außerdem U2a-Schwerpunkte `CuraPressable`, Snackbar-Timer, Manny-`hitPath`). Parallel ui-designer: Goldens (`app/test/golden/goldens/`), Screenshots (mit `shoot.mjs` neu erzeugen), U2a-Annahmen (Eingabefeld Radius 24 + Glas, Nav-Label `caption`, Dialog-Innenabstand 24, Manny-Geometrie, `bubble`-Zeilenhöhe 20), F-18 (Ort Arzttermin „Köln-Nippes · Beispiel“, klinische Wortliste), Rückfrage: dreht der Fortschrittskreis bei „Bewegung reduzieren“ weiter (Annahme: erlaubt)?
- Vorschläge für `KONVENTIONEN.md` (Nutzer fragen): Beispieltexte der Prüfumgebung in `lib/dev/preview_texts.dart`; `lib/dev`/`main_preview.dart` nie Teil von `main.dart`; neue Szenarien in `lib/dev/scenarios.dart` **und** `tool/screens/scenarios.json`.
- Verträge für Folgepakete: `AppController.completeDeletion()` sofort nach Neuaufbau des Onboardings (U2b/U4); Screens setzen `PreviewKeys`-Marker; Store in die Löscher-Liste in `main` (U2b).
- KI-Plan: Freigabe und Entscheidungen E-1–E-26 vor dem KI-Ausschnitt (blockierend u. a. Backend, Weg zur KI/EU-Region, Auth, Zugang Testphase, Limits).
- **Phase „Prävention & Gesundheitssport“ nach Return to Sport** (Nutzerwunsch 2026-10-10): im ersten Ausschnitt nur gesperrter Ausblick über dem Boss (Brief-Ergänzung 3, UI-90–99, Paket U3c). Volle Phase später über `/product-strategist`; offen: Länge, Inhalte/Wahlmöglichkeiten, Streak-/Freeze-Regeln und Wochenrhythmus dort, Fachinhalte (Physio-Framework).
- Direktnachrichten haben keine Spec (Platzhalter) → später `/product-strategist`.
- Bekannte Blocker unverändert: Physio-Framework, Datenschutz-Konzept (Anwalt, inkl. MDR-Frage), Manny-Illustration.

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
npx http-server build/web -p 8765 -s &   # dann: node tool/screens/shoot.mjs (Details Plan 12.1)
```

## Startprompt für die neue Sitzung

> Lies `docs/UEBERGABE.md`, `KONVENTIONEN.md` und `docs/plan/flutter-plan-v1.md` (Abschnitte 14 und 18).
> Weiter mit dem Review nach U2p (reviewer + ui-designer parallel), danach U2b.
