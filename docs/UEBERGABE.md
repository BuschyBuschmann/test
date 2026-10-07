# Übergabe an die nächste Sitzung

Stand: 2026-10-07 · Vorherige Sitzung: https://claude.ai/code/session_01D5CHDFnfv9z12fZKngJeAZ

## Wo wir stehen

Projekt: Reha-Begleiter-App (Arbeitsname **CuraOne**), Fokus Physiotherapie, erster
Verletzungstyp Kreuzbandriss (ACL). Drei Säulen: Physio-Reha-App, Duolingo-artige
Motivation (Pfad, Manny, Streak), Health Social Media.

| Schritt | Status | Ergebnis |
|---|---|---|
| Specs 1–7 | vorhanden | `Spec 1-7.docx` |
| Spec 8 Health Social Media | fertig, reviewt, gemergt | `specs/spec-8-health-social.md` |
| Grunddesign (Ablauf C, Schritt 1–2) | **freigegeben** (v2 + Änderungen) | siehe unten |
| Design-Brief (Ablauf C, Schritt 3) | **freigegeben** | `docs/design/design-brief-v1.md`, Mockups in `docs/design/mockups/` |
| Flutter-Planung (Ablauf E, Schritt 1) | **offen – hier ansetzen** | – |
| Umsetzung erster Ausschnitt | offen | – |

## Festgelegte Entscheidungen

**Arbeitsweise (Orchestrator, `CLAUDE.md`)**
- Modelle: haiku leicht, sonnet normal, opus schwer (Standard, vom Nutzer freigegeben).
- Prompt-Aufbereitung und Review jeweils anbieten (keine abweichende Dauer-Präferenz).
- Keine Commits/Pushes/PRs ohne Nutzerauftrag.

**Produkt**
- Erste Version = **„Prototyp, der weiterwächst“**: echter Flutter-Code mit
  Platzhalterdaten; Backend und DSGVO kommen schrittweise.
- Erster Ausschnitt: Onboarding (Spec 1, vereinfacht), Pfad/Home mit Manny und Streak
  (Spec 3), minimales Tagesprogramm „Heute“ (Spec 2). Ohne KI. Physio-Framework als
  klar markiertes Beispiel-Framework (ACL) – echte Inhalte sind Blocker für den Livebetrieb.
- Spec 8: nur Patientensicht; Chat Patient–Physio gehört eher in den Reha-Bereich
  (eigene Spec oder Erweiterung offen).

**Design (freigegebenes Grunddesign v2 + Nutzeränderungen)**
- Dunkel als Standard, Hintergrund Anthrazit-Blau `#0E131A`; Hell später über Tokens.
- Edel/modern: Glas-Karten (halbtransparent, feiner heller Rand), schwebende
  Pill-Navigation, dezenter orange-roter Lichtschein in den Ecken (nie hinter Text).
- **Akzent: Kupfer `#D9622B`** (Nutzerwunsch „Orange-Rot, dunkler und edler“), `accent-hi` `#E8794A`.
  Triage-/Fristenfarben dafür verschoben (Triage-Orange `#FFA62B`, Rot/Frist `#FF5C70`); Details Brief Abschnitt 4.
- Schriften: Bricolage Grotesque (Überschriften/Zahlen), DM Sans (Text), als Assets gebündelt.
- Manny: Pinguin in Schiefer-Blau, Platzhalter aus Flutter-Formen (3 Posen) bis zur
  Illustration. „CuraOne“ als Textmarke ohne Logo.
- Inspiration des Nutzers: dunkle Glas-UI mit orange-roten Glow-Verläufen.
- Mockups: `docs/design/mockups/pfad-v3.png`, `docs/design/mockups/heute-v3.png` (Orientierung, kein Pixel-Vorbild).

## Nächste Schritte (Ablauf E in `CLAUDE.md`)

1. **Umgebung prüfen:** `flutter --version` und `flutter doctor`. Fehlt das SDK, das
   Setup-Skript der Umgebung prüfen – ohne SDK ist keine Verifikation möglich.
2. **Design-Brief:** `docs/design/design-brief-v1.md` ist freigegeben und gilt im Wortlaut als
   Vorgabe. Nutzerentscheidungen bei Freigabe: Onboarding „X von 4“ (Name, Datenschutz,
   Verletzungstyp, Datum), alle Verletzungstypen nutzen den gekennzeichneten Beispielpfad,
   „Training starten“ öffnet Sheet mit drei Modi, nur „Manuell“ aktiv. 36 UI-Kriterien (UI-1 … UI-36).
3. **Planungspaket an `flutter-developer`** (Modell: opus): Projektstruktur, Screens,
   Navigation, State-Management, Datenmodell, Backend-Vorschlag (Firebase oder
   Supabase, Nutzer entscheidet), Pakete, Zuordnung der UI-Akzeptanzkriterien.
   Plan dem Nutzer zur Freigabe vorlegen.
4. **Umsetzungspaket an `flutter-developer`** (sonnet) mit freigegebenem Plan und Brief.
5. **Abnahme parallel:** Design-Abnahme `ui-designer`, Code-Review `reviewer`
   (anderes Modell als die Umsetzung).
6. Externe Schritte (Backend-Projekt, Deploy, Stores) nie ungefragt ausführen.

## Bekannte Blocker und offene Punkte

- Physio-Framework (Übungspool, Phasen, Mindestmengen, Fakten) – Blocker laut Specs.
- Datenschutz-Konzept (Anwalt) vor echten Patientendaten.
- Manny-Illustration und -Animationen (extern).
- Google-Places-API-Key (Spec 1, Schritt 6) – im Prototyp nicht nötig.
- Spec 3/4/5: Out-of-Scope-Texte noch nicht an Spec 8 angepasst.
- Zwei optionale Nitpicks in Spec 8 (Share-Sheet-Zuordnung; „keine Anbindung anderer
  Personen“ zu weit gefasst).

## Startprompt für die neue Sitzung

> Lies `docs/UEBERGABE.md` und `docs/design/design-brief-v1.md`. Prüfe, ob das
> Flutter-SDK verfügbar ist. Dann weiter mit Schritt 3: Planungspaket an den
> `flutter-developer` für den ersten Ausschnitt.
