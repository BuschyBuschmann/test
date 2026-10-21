# CuraOne Grunddesign v2

Status: FREIGEGEBEN (2026-10-14), Manny A „Lässig“ (Platzhalter-Skizze bis zur Rechteklärung) · Stand 2026-10-14 · Grunddesign, kein Brief. Vorarbeit und Begründungen: `grunddesign-v2-ansatz.md` (Ansätze 1–4). Mockups (Abend-Welt, 390×844, Beispieldaten, Manny = Platzhalter): `mockups/v2-grunddesign-uebersicht.png` und `v2-heute.png`, `v2-session.png`, `v2-checkup.png`, `v2-profil.png`, `v2-chats.png`, `v2-physio.png`; Pfad: `v2-ansatz4-abend.png`; Tageszeiten: `v2-ansatz3-tageszeiten.png`; Manny: `v2-manny-sticker.png`. Quellen: `mockups/v2-src/`.

## 1. Leitidee
Eine ruhige Welt aus Licht, Ebenen und Glas, die sich mit der Tageszeit verändert. Pfad-Stationen sind schwebende Glas-Kugeln, Karten und Leiste sind Milchglas, Orange ist das Licht und die Handlung. Modern und jung heißt: große runde Formen, viel Fläche, klare fette Typo, ein Maskottchen mit Haltung (Manny mit Sonnenbrille). Jede erledigte Handlung wird gefeiert, aber nie laut oder kindisch.

## 2. Tokens (grob)
**Welt je Tageszeit** (Himmelsverlauf oben nach unten; Boden = Farbe unter der Leiste):

| Welt | Himmel | Ebenen (hinten, Mitte, vorn) | Licht | Boden |
|---|---|---|---|---|
| Morgen | `#BCD2EA`, `#F3C6B6`, `#F7DFCB` | `#B4AFC6`, `#D2C0BC`, `#F6EDE2` | tiefe Sonne links | `#F7F2EB` |
| Mittag | `#8EC3EC`, `#CDE5F4`, `#E9F2EE` | `#9DB6C6`, `#C4D3D1`, `#F1F0E8` | Sonne hoch rechts | `#F7F2EB` |
| Abend | `#F2B58C`, `#C8B1A8`, `#DCCFC4` | `#A99AA6`, `#9C8E9B`, `#F4ECE2` | Sonne rechts, warm | `#F7F2EB` |
| Nacht | `#141A33`, `#4A3548`, `#2B2230` | `#4A4468`, `#3A3354`, `#2E2634` | Mond, Sterne | `#1C1620` |

**Immer gleich:** Akzent Mandarine `#FF7A2E` (Verlauf `#FFA063` nach `#FF7A2E`), Text darauf immer Tinte `#211B16` (6,55:1; Weiß nur 2,6:1). Orange als Text nur `#B8470F` (5,3:1 auf Weiß). Tinte `#211B16`, Sekundär `#5A5048` (7,0:1 auf Weiß). Gold `#FFC23D` (Fortschritt, Ziel), Erfolg Grün nur mit Symbol, Fehler `#B3261E`. Kategorie-Farben (Physio blau, Arzt lila, Übung grün, Frist rot) bleiben als Zuordnung, Töne für Hell nachgezogen.

**Typografie:** Bricolage Grotesque 700–800 für Titel, Zahlen und Buttons (Titel 30–36 sp, Zähler bis 52 sp), DM Sans 400–700 für Text (Fließtext 16 sp, Meta 13–14 sp). Nichts unter 13 sp, Gewicht ab 400. Beides ist bereits gebündelt.

**Radien:** Karten 28, Kopf-Karte 32, Chips und Buttons Pille (999), Kacheln 18, Kugeln rund. **Abstand:** Raster 4 dp, Seitenrand 14–16 dp. **Zielgrößen:** ≥ 48 × 48 dp (Prüfauftrag: Chips, Zähler-Orb und Smileys erreichen dies per Hit-Area).

**Tiefe und Glas:** Vier Ebenen: Welt, Karten, Glas (Leiste, Kopf-Karte, Sheets), Objekte (Kugeln, Manny). Karten sind Pseudo-Glas (Weiß 80 %, Lichtkante oben, getönter Schatten), **ohne Blur**. Echter Blur nur für Kopf-Karte, Leiste, Manny-Knopf und Sheets: **höchstens 3 gleichzeitig** (v1: 2). Kugeln: Radialverlauf, Glanzfleck, Innenschatten, Bodenschatten. Keine Knöpfe mit harter Unterkante. 3D-Objekte (Flamme, Stern, Pokal) vorgerendert, Fallback aus Verläufen.

**Lesbarkeit auf Glas:** Text liegt nie direkt auf der Welt, sondern auf Karte, Kopf-Karte (dunkles Milchglas 58–66 %) oder Label-Chip. Leiste in Ruhe: Glas 35 %, 70-%-Schleier in der Bodenfarbe darunter, Worst-Case-Kontrast der Labels ≥ 9,5:1; aktiv (Tippen, Scrollen, Fokus): Glas 78–82 %. Gemessene Werte je Welt: `grunddesign-v2-ansatz.md`, Ansatz 3 (alle ≥ 4,5:1).

## 3. Bewegung
- Prinzip: kurz, federnd, einmalig. Keine Dauerschleifen außer Fortschritt laufender Vorgänge (E-3).
- Momente: Feier (Manny springt, Sterne, Zähler zählt hoch, ≤ 1,8 s), Fortschrittsbalken füllt sich mit Feder (≤ 600 ms), Streak-Flamme zuckt einmal, Kugel poppt beim Abschluss, Zähler-Orb drückt sich beim Tippen ein, Haptik beim Zählen und bei Satzende (abschaltbar). Weltwechsel überblendet über 30 Minuten.
- Reduzierte Bewegung: keine Federn, keine Feier-Animation (statische Karte mit feiernder Manny-Pose), kein Weltwechsel sichtbar, Zustandswechsel höchstens 120 ms Überblendung. Nichts blinkt mehr als 3 Mal pro Sekunde.

## 4. Navigation
Leiste unten, 5 Ziele: **Pfad, Heute, Feed, Chats, Profil.** Bis zum Feed (Ausschnitt 4) vier Ziele. Begründung: Pfad und Heute sind die tägliche Schleife, Chats und Profil sind laut Nutzer in die Leiste gewandert, der Feed ist das Instagram-Element und kommt in die Mitte-rechts wie Entdecken. Profil mit Avatar. Ungelesen-Zähler an Chats (Zahl plus Text für Screenreader). **Manny-Zugang:** Tipp auf Manny im Pfad, kleiner Manny-Knopf über der Leiste (nur Pfad und Heute), angepinnte erste Unterhaltung in „Chats“. Die Session ist Vollbild ohne Leiste. **Physio-Bereich** hat eine eigene Leiste: Patienten, Übungen, Chats, Konto; am Rechner Seitenleiste (Kacheln gleich, breiter).

## 5. Manny
Eigene Skizze im Sticker-Stil (Details und Abgrenzung: Ansatz 4): dunkle Kontur, Blau-Grau, Creme-Bauch, schwarze Sonnenbrille, Stirnband in Akzentorange, Kopf und Körper zwei Formen, leicht schräg. Umsetzung: feste Illustrationen (WebP/PNG mit Transparenz, 1x/2x/3x) je Pose, Bewegung im Code (Hüpfen, Quetschen, Wippen), kein Lottie/Rive. Bis finale Illustrationen mit Rechten vorliegen, bleibt es Platzhalter.

| Pose / Zustand | Einsatz | Vorhanden im Entwurf |
|---|---|---|
| Standard, lässig | Chat-Avatar, Pfad, Onboarding | ja |
| Begrüßen (winkt) | Tagesbeginn, Moin-Blase | neu |
| Feier (Arme hoch, Sterne) | Session-Ende, Streak, Meilenstein | ja |
| Ziel (Fahne) | aktuelle Pfad-Station, Boss | neu |
| Erinnerung (zeigt auf Uhr) | freundliche Erinnerung, nie schuldzuweisend | neu |
| Training-Begleiter (läuft/Rucksack) | Session, Packliste | neu |
| Trösten (Brille ab, Hand auf der Brust) | Schmerz melden, schlechter Tag | ja |
| Denken (Brille hoch, Finger am Schnabel) | Chat „schreibt“, Laden | neu |
| Schlafen / Ruhetag | Ruhetag, Nacht-Welt | neu |
| Kopf (Knopf, 40–80 px) | Manny-Knopf, Chat-Liste, Avatar | ja (nur Standard) |
Für kleine Größen sind eigene, vereinfachte Köpfe nötig. Manny reagiert nicht auf Stimmungswerte (Spec C-3), nur auf Schmerzmeldung in der Session.

## 6. Kern-Screens in Worten (Skizzen siehe Mockups)
- **Pfad** (`v2-ansatz4-abend.png`): Kopf-Karte „Woche 5 · Phase 2“ mit Streak, Freezes, Wochenbalken. Darunter die Welt mit gestrichelter Linie und Glas-Kugeln: erledigt (Perlglas, Haken), aktuell (große Orange-Kugel mit Halo, Flagge), gesperrt (Grauglas, Schloss), Ziel (Gold, Stern) mit Label-Chip. Manny steht neben der aktuellen Kugel. Leiste und Manny-Knopf unten.
- **Heute** (`v2-heute.png`): Kopf-Karte mit Datum und Streak. Tages-Check-up-Karte oben (Smileys für Wohlbefinden, Schmerz-Regler, „Weiter“ durch 5 Fragen, Schließen), nach dem Ausfüllen klein („Erledigt, danke“). Karte „Dein Training“: je Übung Bildkachel, Name, Umfang, Material, Ort-Chip und Abhaken; Button „Training starten“ (Standardweg), abhaken in der Liste als zweiter Weg.
- **Trainings-Session** (`v2-session.png`): Vollbild ohne Leiste. Oben Schließen, segmentierter Fortschritt „Übung 2 von 5“, Gesamtzeit. Karte mit großem Übungsbild (Start-/Endposition, Platzhalter), Name, Kurzanleitung, Chips für Material, Ort, Satz. In der Mitte ein großer Orb als Zähler „7 / 12“ (Tippen zählt; bei Zeitübungen Countdown mit Ton und Vibration). Manny kommentiert kurz. Unten Pause, Überspringen, Schmerz melden (Schmerz bietet die freigegebene leichtere Variante oder Abbruch). Pausen-Timer erscheint im Orb. Vor dem Start: Packliste zum Abhaken (Rucksack-Manny).
- **Check-up nach der Einheit** (`v2-checkup.png`): Manny feiert, „Geschafft“ mit Zeit, Übungen, Streak. Pflicht ist „Wie lief’s?“ mit fünf Smileys (mit Text-Label für Screenreader). „Details je Übung?“ klappt auf (leicht, passend, schwer, Schmerz, Gewicht erhöht), „Speichern“, „Später“.
- **Profil** (`v2-profil.png`): Kopf-Karte mit Avatar, Name, Verletzung, Phase. Drei Kacheln (Streak, Trainingstage, Freezes). Liste: Plan und Verletzung, Frage an meinen Physio, Deine Daten, Erinnerungen, Darstellung (Welt: Automatisch oder fest), Hilfe und Datenschutz.
- **Chats** (`v2-chats.png`): Manny oben angeheftet, darunter Physio, Arzt, Praxis-Team; Avatare als Initialen, Ungelesen-Zähler mit Zahl. Keine Personenfotos im Entwurf.
- **Physio-Patientenübersicht, Handy** (`v2-physio.png`): Kopf-Karte mit Patient, Verletzung, Phase, letzter Termin. Eine Spalte Kacheln nach PB-3: Befinden/Motivation/Warnzeichen (Warnzeichen mit Symbol und Text, nicht nur Farbe), Schmerz-Trend, Training seit dem letzten Termin, Übungen gut/schlecht, Fragen, Phase und Ziel (Notiz darunter; KI-Briefing kommt in Ausschnitt 3). Tipp öffnet die Details. Nüchterner als der Patientenbereich: weniger Welt, mehr Fläche. Warn-Inhalte bleiben neutral und opak (v1, Abschnitt 4).
- **Feed (nicht gestaltet):** Karten im Instagram-Stil mit Quelle und Datum; später ein eigener Entwurf.

## 7. Verhältnis zu Brief v1, Errata und Ergänzungen
**Bleibt (verbindlich):** Barrierefreiheits-Kriterien: WCAG-AA-Kontraste (Text ≥ 4,5:1, Symbole und Bedienränder ≥ 3:1), Zielgrößen ≥ 48 dp mit ≥ 8 dp Abstand, 200 % Schrift (Leiste-Labels bei 130 % begrenzt), reduzierte Bewegung, sichtbarer Fokusring, Screenreader-Labels, Zustände nie nur über Farbe (UI-3, 5, 8, 9, 18, 19, 32–36). Hoher Kontrast: alles opak, kein Blur, keine Welt-Textur. Semantik-Tokens und Dark-Fähigkeit. Triage und Fristen: opak und neutral, ohne Akzent und ohne Welt (Abschnitt 4, UI-17). Texte Deutsch, „du“, kurz. E-2 sinngemäß (Orange als Text nur der dunkle Ton), E-3 (Fortschrittskreis), E-4 (Fehlertext), E-5 (Sheet „Deine Daten“ kompakt opak ohne Blur). Ergänzung 1 (Rückgängig, Tageswechsel, „Deine Daten“, Pfad-Tipps) und Ergänzung 3 (Ausblick Prävention) bleiben im Verhalten, werden im neuen Stil gezeichnet. Ergänzung 2 (Manny-Chat und Nachrichten): Verhalten bleibt, Einstieg ändert sich (siehe 4).

**Abgelöst:** dunkles Standard-Theme (jetzt Welt nach Tageszeit, Systemthema hell/dunkel für Inhaltsflächen); Blur-Budget 2 (jetzt 3); E-1 Glow-Regeln (ersetzt durch Regel „Text nie direkt auf der Welt“ und die Kontrasttabelle je Welt); Glow-Tokens; Kupfer `#D9622B` (jetzt Mandarine mit dunkler Tinte); Bricolage 500 und 18 sp Button (jetzt 700–800); Manny-Platzhalter aus Flachformen (jetzt Skizze nach Ansatz 4); Nav mit 2 Einträgen und Manny-Knopf unten rechts (jetzt 5 Ziele, Manny-Knopf über der Leiste, nur Pfad und Heute); Verbot von Bounce (jetzt einmalige Federn); Pfad-Units als flache Kreise (jetzt Glas-Kugeln); Welt-Hintergrund statt statischem Glow.
**Folgen für die Umsetzung:** Goldens und alle gebauten Screens müssen neu gezeichnet werden. Neue UI-Kriterien (Kontrasttest je Welt, Blur-Zähler ≤ 3, Leistenzustände) entstehen im Brief.

## 8. Offene Fragen
1. **[blockierend für finale Manny und 3D-Objekte]** Wer zeichnet oder liefert die Illustrationen, mit welchen Rechten? Dieser Entwurf ist nur Platzhalter. Die Vorlage (Etsy) darf nicht übernommen werden.
2. Zeitgrenzen der Welt (5/10/17/21 Uhr, 30 Minuten Überblendung) und Tageszeit nur für die Welt, Inhaltsflächen nach System hell/dunkel: einverstanden?
3. Feed: eigener Entwurf in Ausschnitt 4, oder soll er schon im Brief eine Karte bekommen?
4. Physio-Bereich: am Rechner Seitenleiste mit zwei Spalten Kacheln. Soll er denselben Welt-Look tragen, oder nüchtern und ohne Welt? *Annahme:* gleiche Welt, aber ruhiger und mit mehr Fläche.
5. Smileys im Check-up als Emoji (systemabhängig) oder eigene Manny-Gesichter (mehr Arbeit, einheitlicher)? *Annahme:* Emoji im Prototyp.
