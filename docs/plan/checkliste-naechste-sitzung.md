# Checkliste: Weiter nach dem Limit-Reset (Stand 2026-10-14)

Arbeitsweise wie bisher: Orchestrator koordiniert, eine Frage pro Schritt, nichts wird umgesetzt ohne Freigabe. Nach jedem verifizierten Schritt wird committet und gepusht. Bei einem Sitzungslimit plant der Orchestrator selbst eine Erinnerung für kurz nach dem Reset.

## Schritt 0: Einstieg (ca. 5 Min)
- [ ] Präsentation kurz auswerten: Was kam gut an, was fehlte, gab es Fehler? Das Feedback nehme ich in die Anregungen auf.
- [ ] Stand prüfen: Branch `claude/wonderful-bell-beag0y`, `git status` sauber, letzter Commit wie in `docs/UEBERGABE.md`.

## Schritt 1: Offene To-dos abschließen („Schnelle Klarheit“, Korrekturrunde SK-1-K1)
Die Befunde aus Code-Review und Design-Abnahme sind schon vom Nutzer entschieden, Details in `docs/UEBERGABE.md`. Die Umsetzung macht der `ui-designer`.
- [ ] Pflicht: Der Screenreader liest den Hinweis bei anderen Verletzungstypen sicher vor (Live-Region `InfoNote`).
- [ ] Pflicht: Der Hinweis ist im Onboarding auch auf kleinen Bildschirmen bzw. bei großer Schrift nach der Auswahl sichtbar.
- [ ] Die Freeze-/Streak-Erklärung wird bei 200 % nicht abgeschnitten und zeigt nach einer Größenänderung weiter auf den richtigen Chip.
- [ ] „Datenschutzerklärung“ ohne Wortbruch; der Fokusring der Chips hat Abstand zur Pille.
- [ ] Nutzerwahl umsetzen: Play-Symbol zurück auf „Training eintragen“, „Manuell“ heißt „Ich trainiere selbst und trage es ein“.
- [ ] Aufräumen: Link-Semantik, stabile Keys, Reste von „Training starten“.
- [ ] Verifikation: analyze, Tests, Goldens, Matrix, `nav_checks`. Danach Re-Review nur der Korrekturen, Commit, Web-Link aktualisieren.

## Schritt 2: Anregungen ausarbeiten (Dialog, noch keine Umsetzung)
Grundlage: `docs/produkt/curaone-anregungen-2026-10-13.md`. Ich prüfe zuerst, welche Anregungen schon in Spezifikation und Plan stehen, damit nichts doppelt geplant wird.
- [x] **2a Training unterstützen** (`/app-experience`, Ablauf): Timer, Checkliste zum Abhaken, Materialien, Bilder, Ort. Bezug zu A-2 (Übungsdetail) und M-3 (Übung begleiten).
- [x] **2b Patienten-Check-ups** (`/app-experience`):
  - Check-up nach jeder Einheit (kurz, optional je Übung).
  - Check-up auf „Heute“ (Wohlbefinden, Schmerz, Einschränkungen, Psyche, Motivation).
  - Bezug zu A-3 (Befinden) und zu den Warnzeichen. Psyche ist dabei ein sensibles Thema: Warnzeichen und Datenschutz klären.
- [x] **2c Physio-Bereich** (`/product-strategist`, dann `/app-experience`):
  - 5-Minuten-Übersicht je Patient: was auf einen Blick, was beim Aufklappen.
  - Liste mit eigenen Patienten und Praxis-Patienten zum Vertreten.
  - Übungs-Baukasten: Felder, Bilder auswählen/hochladen/KI-generiert, direkte Zuordnung zu Patienten.
  - Historie je Patient.
  - Physio-KI: Aufgaben und Grenzen.
  - Neuer Patient: Anlegen und Verbinden per QR/Link in wenigen Sekunden. Der Ablauf steht schon im Plan Ausschnitt 2 (Einladung) und wird hier vereinfacht.
  - Bezug zu P-1 bis P-5.
- [x] **2d Feed/News** (`/product-strategist`): Zielbild, Inhaltsquellen (eigene, Artikel, Krankenkassen), Personalisierung nach Verletzung, Prüfpunkte zu Rechten und Quellen. Wann im Ausbau, MVP oder später?
- [x] **2e Design-Überarbeitung** (`ui-designer`, Ablauf C, gestaltet erst nach den Inhalten aus 2a–2d):
  - Leiste unten neu: Pfad, Heute, Nachrichten, Profil/Konto. Wohin kommen dann der Manny-Button und „Deine Daten“?
  - Transparente Leiste wie bei iOS/Instagram, dazu Tiefe und 3D-Wirkung. Das berührt das Blur-Budget und die Glow-Regel E-1 im Brief.
  - Neuer Look nach `docs/design/inspiration/health-app-glas-orange.webp`.
  - Manny komplett neu nach `docs/design/inspiration/manny-pinguin-aquarell.png`: Aquarell-Pinguin mit Posen und Accessoires. Klären, ob als Illustration (Bilder) oder weiter gezeichnet im Code. Die Manny-Illustration war bisher ein bekannter Blocker.
  - Ablauf: Grunddesign zur Freigabe, dann Design-Brief v2 zur Freigabe. Danach ein Umbaupaket für die bestehenden Screens und Goldens.
- [ ] Für jedes Thema: Entscheidungen festhalten, Priorität (Ausschnitt 2 / 3 / 4 / später) festlegen und dem Nutzer zur Freigabe vorlegen.

## Schritt 3: Dokumente aktualisieren
- [ ] Die Spezifikation `docs/produkt/curaone-spezifikation-manny-gehirn.md` ergänzen bzw. eine neue Spezifikation schreiben, mit Nutzergeschichten und prüfbaren Akzeptanzkriterien. Der Nutzer gibt frei.
- [ ] Prüfen, was sich am freigegebenen Plan Ausschnitt 2 (v1.2) und am KI-Plan (v2.2) ändert. Ändern sie sich, gilt: Überarbeitung durch den `flutter-developer` (opus), Review durch den `reviewer` (opus), dann Freigabe durch den Nutzer.
- [ ] Neue Oberflächen (Physio-Bereich, Training, Check-up, ggf. Feed) laufen über Ablauf C: Grunddesign, Freigabe, Design-Brief und noch einmal Freigabe durch den `ui-designer`.

## Schritt 4: Offene Werte vor dem Bau von Ausschnitt 2 abfragen
- [ ] Warnzeichen-Schwellen beim Befinden (O-2), Schmerzschwelle für die Kürzung (E-28).
- [ ] KI-Grenzwerte und -Entscheidungen E-7, E-15, E-27, E-30, E-31. Sie werden erst für den KI-Ausschnitt gebraucht.

## Schritt 5: Bau Ausschnitt 2 starten (erst nach den Schritten 1–4)
- [ ] Externe Schritte einzeln zur Freigabe vorlegen:
  - Supabase-Projekt in der EU
  - lokale Werkzeuge (Supabase-CLI, Docker)
  - Pepper für den Einladungscode
- [ ] Pakete laut Plan, jeweils mit Verifikation, Review und Commit.

## Ergebnisse Schritt 2 (2026-10-14)
- 2a/2b → `docs/produkt/curaone-ablaeufe-training-checkup.md`
- 2c → `docs/produkt/curaone-physio-bereich.md` (Ausschnitt 2 ohne KI, Physio-KI in Ausschnitt 3)
- 2d → `docs/produkt/curaone-feed.md` (stufenweise ab Ausschnitt 4)
- Präsentations-Feedback: modern und jung, „Instagram × Duolingo für Gesundheit“
- 2e → `docs/design/grunddesign-v2.md` (Manny A „Lässig“) und `docs/design/design-brief-v2.md`, beide FREIGEGEBEN 2026-10-14

## Hinweise
- Was erledigt ist, wird hier abgehakt und in `docs/UEBERGABE.md` nachgetragen.
- Reihenfolge: erst Schritt 1 (klein, schließt Offenes ab), dann der Dialog in Schritt 2, weil er bestimmt, was in Ausschnitt 2 gebaut wird.
- Kläre in Schritt 2, ob das neue Design vor Ausschnitt 2 kommt (alle neuen Screens gleich im neuen Look) oder danach (zuerst die Funktionen). Empfehlung: das Grunddesign früh festlegen, damit Physio-Bereich und neue Screens nicht zweimal gestaltet werden.
- Prüfe in Schritt 1, ob sich die Restkorrekturen von „Schnelle Klarheit“ noch lohnen, wenn ohnehin ein Redesign kommt. Die zwei Pflichtpunkte (Screenreader, Sichtbarkeit) lohnen sich in jedem Fall.
