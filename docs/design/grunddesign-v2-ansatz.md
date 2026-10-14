# Grunddesign v2: Richtungsansatz (zur Entscheidung)

Hinweis: Ansatz 1 (Mockup entfernt, enthielt Stock-Ausschnitte) ist durch "Ansatz 2" unten abgelöst.

**Leitidee.** Eine Health-App, die sich anfühlt wie Instagram mit Duolingo-Fortschritt: helle, warme Oberfläche, große runde Karten und Knöpfe mit sichtbarer Kante und Schatten, dazu ein Orange-Grau-Verlauf als Kopfbereich. Glas gibt es nur dort, wo Inhalt darunter durchläuft (Leiste, Sheets). Jede erledigte Handlung wird gefeiert.

**Hell oder dunkel.** Empfehlung: Hell (warmes Sand `#F7F2EB`) als Standard, Dunkel (warmes Graphit `#17120F`) als gleichwertiges zweites Thema nach System-Einstellung. Grund: Das Leitbild (Instagram, Duolingo) ist hell, Aquarell-Manny und 3D-Objekte wirken auf Hell am besten, Text auf Glas ist auf Hell leichter sicher lesbar. Die v1-Tokens sind schon semantisch, Dunkel bleibt also erhalten.

**Farbe und Typografie.** Mandarine `#FF7A2E` für Handlung (Text darauf Tinte `#211B16`, 6,55:1; Weiß wäre nur 2,6:1), Kantenton `#C95A17`. Orange als Text nur `#B8470F` (5,3:1). Gold `#FFC23D` für Fortschritt/Streak, Grün für Erledigt, Tinte `#211B16` / `#5A5048` (7,05:1). Kopfverlauf Orange nach Rauchgrau unter einem 40-%-Dunkelscrim: weißer Text hat dort mindestens 4,1:1, am hellsten Fleck nachzuschärfen (siehe Frage 3). Schrift: Bricolage Grotesque, fett (700–800), für Überschriften und große Zahlen, DM Sans für Text. Beides ist bereits gebündelt, keine neue Abhängigkeit.

**Tiefe, 3D, Glas.**
- Knöpfe, Pfad-Units und Karten haben eine feste Unterkante (3D wie bei Duolingo) plus warmen, getönten Schatten. Beim Drücken sinken sie ein.
- 3D-Objekte (Flamme, Stern, Pokal, Theraband) als vorgerenderte WebP-Icons, Fallback aus Verläufen im Code. Manny und Objekte ragen über Kartenränder.
- Echtes Glas (Blur) nur für Leiste, Manny-Knopf und Sheets, höchstens 3 gleichzeitig (v1: 2). Karten nutzen Pseudo-Glas ohne Blur.
- Lesbarkeit: Glas hat mindestens 78 % Weiß. Gemessen bleibt `#5A5048` auch über Schwarz bei 4,64:1 und Tinte bei 10,07:1. Orange-Text liegt nie auf Glas. Bei „Transparenz reduzieren“ und hohem Kontrast wird alles opak. Barrierefreiheits-Kriterien aus v1 (WCAG AA, 48 dp, 200 % Schrift, reduzierte Bewegung, Fokus, Screenreader) bleiben unverändert.

**Leiste unten (5 Ziele).** Pfad, Heute, Feed, Chats, Profil (Profil mit Avatar, Chats mit Ungelesen-Zähler). Bis der Feed kommt (Ausschnitt 4), sind es vier Ziele. Manny bleibt über Tipp auf Manny im Pfad, einen kleinen Manny-Knopf über der Leiste (nur Pfad und Heute) und als angepinnte erste Unterhaltung in „Chats“ erreichbar.

**Manny.** Feste Aquarell-Illustrationen je Pose als WebP mit Transparenz; Bewegung im Code (Hüpfen, Quetschen, Wippen), kein Lottie/Rive, weil sich Aquarell nicht sauber vektorisieren lässt. Für kleine Größen (Knopf, Avatar) braucht es eigene, vereinfachte Köpfe.

## Rückfragen
1. [blockierend für Manny] Wer liefert die Manny-Illustrationen, und wer besitzt die Rechte? Das Inspirationsbild zeigt Spuren eines Stock-Wasserzeichens und darf ohne Lizenz nicht ausgeliefert werden. Fehlende Posen (Trösten, Denken, Schlafen, Kopf) müssten neu gezeichnet werden.
2. Hell als Standard mit Dunkel als zweitem Thema: einverstanden, oder lieber nur ein Thema?
3. Der Kopfverlauf ist hier eher Braun-Orange, damit weißer Text lesbar bleibt. Soll er heller und lebhafter werden, mit dunklem Text darauf?

---

# Ansatz 2 (löst die Teile oben ab, wo sie sich widersprechen)

Mockups: `mockups/v2-ansatz2-pfad.png` und `mockups/v2-ansatz2-leiste.png` (Quellen in `mockups/v2-src/`). Die Manny-Ausschnitte und der Aquarell-Stil aus Runde 1 sind entfernt. Das Duolingo-Leitbild entfällt, die Knöpfe mit fester Unterkante ebenfalls.

**Leitidee.** Eine ruhige Dämmerungs-Welt aus Licht, Ebenen und Glas statt Spielfeld: Pfad-Stationen sind schwebende Glas-Kugeln, Karten und Leiste sind Milchglas, Orange ist das Licht. Instagram-nah heißt: viel Fläche, wenig Rahmen, große runde Formen, klare Typo.

**Hintergrund.** Verlauf von Pfirsich (oben) über Rauchgrau-Lila zu hellem Sand (unten), eine weiche Sonne oben rechts, ein Lichtstreifen, drei halbtransparente Hügelebenen mit feiner heller Kante und leichte Körnung (Textur). Lesbarkeit: Text liegt nie direkt auf dem Hintergrund, sondern auf Glas-Karte oder Label-Chip; die unteren 150 dp laufen in einen Sand-Schleier aus.

**Unit-Stil.** Glas-Kugeln mit Lichtkante, Glanzfleck oben links, Innenschatten, Bodenschatten (sie schweben). Aktuell: große orange Leuchtkugel mit Halo-Ringen und dunklem Symbol (Weiß wäre nur 2,6:1). Erledigt: warmes Perlglas mit Haken, Gesperrt: mattes Grauglas mit Schloss, Ziel: goldene Kugel mit Stern. Zustand steht immer auch in Symbol und Label, nicht nur in Farbe. Die Kopf-Karte ist dunkles Milchglas (60 % Graphit), weißer Text hat im Worst Case 6,4:1.

**Leiste unten, zwei Zustände** (5 Ziele wie oben: Pfad, Heute, Feed, Chats, Profil).
- *Ruhe:* Glas nur 35 % Weiß, Blur 30. Beschriftung und Symbole in der dunklen Tinte `#211B16`, Gewicht 700, Linie 2,2 dp. Lesbar bleibt es, weil der Inhalt unter der Leiste in einen 70-%-Sandschleier ausläuft: Worst Case (darunter reines Schwarz) ergibt Tinte 10,1:1, Sekundärfarbe 4,66:1. Gemessen auch über Orange und Weiß.
- *Aktiv* (Tippen, Scrollen, Fokus; kehrt nach ca. 2 s Ruhe zurück): Glas 78 %, wie in Ansatz 1 (Tinte 10,1:1 auf Schwarz).
- Bei „Transparenz reduzieren“, hohem Kontrast oder ohne Blur-Unterstützung ist die Leiste immer opak. Bei „Bewegung reduzieren“ wechselt der Zustand ohne Überblendung. Der Ruhezustand ist rein optisch, Zielgröße (≥ 48 dp) und Fokusring bleiben.

**Manny-Stil (eigener Entwurf, kein Nachbau).** Rundes, eiförmiges Pummelchen in Nachtblau mit Verlauf und feiner Lichtkante, cremefarbener Bauch, weiche Konturen in dunklem Marineblau (2,5 statt kräftiges Schwarz), orange Schnabel und Füße. Markenzeichen ist eine **Sonnenbrille mit orange getönten Gläsern** (passt zum Licht-Orange der App); sie lässt sich ablegen (Trösten, Schlafen, Denken: Brille hoch oder ab). Ein erstes Platzhalter-SVG ist im Mockup, klar als „PLATZHALTER“ beschriftet. Pro Pose eine feste Illustration, Bewegung im Code.

## Rückfragen (Ansatz 2)
1. [blockierend für Manny und 3D-Objekte] Wer zeichnet bzw. liefert die finalen Illustrationen, und mit welchen Rechten? Das Sticker-Bild ist nur Inspiration und wurde nirgends übernommen.
2. Sonnenbrille als Markenzeichen: gut, oder soll Manny auch ohne Brille der Standard sein (Brille nur zu Feier und Sport)? Bei Schmerz und Trost wäre eine Brille unpassend, deshalb würde sie dort abgesetzt.
3. Ist die Dämmerungs-Welt (Pfirsich/Rauchgrau, Hügel) die richtige Atmosphäre, oder soll es eher Eis/Schnee-Blau (passend zum Pinguin) oder neutral Grau-Orange wie im Inspirationsbild sein?

---

# Ansatz 3: Tageszeiten-Welt

Mockups: `mockups/v2-ansatz3-morgen.png`, `-mittag.png`, `-abend.png`, `-nacht.png` und Übersicht `mockups/v2-ansatz3-tageszeiten.png`. Gleiche Komposition (Sonne bzw. Mond, drei Ebenen, Licht), nur Farbe und Licht wechseln. Abend ist die bisherige Dämmerung. Die Ebenen gehen jetzt fließend ineinander über: keine Konturen, jede Ebene läuft nach unten in Transparenz aus, mehr Weichzeichnung nach hinten, Dunstbänder zwischen den Ebenen. Quelle und Kontrastberechnung: `mockups/v2-src/gen3.py`, `kontraste3.json`.

**Tageszeit-Regel (Vorschlag).** Nach Gerätezeit: Morgen 5–10, Mittag 10–17, Abend 17–21, Nacht 21–5 Uhr. Die Welt blendet an den Grenzen über 30 Minuten weich zu der nächsten Phase über (Verlauf der Farbwerte), kein Umspringen. Der Wechsel passiert nur beim Öffnen des Screens und im Hintergrund, nie sichtbar während einer Eingabe. Bei „Bewegung reduzieren“ wird nur beim Öffnen umgestellt. Bleibt offen, ob jahreszeitliche Sonnenzeiten gewünscht sind (Annahme: nein, feste Zeiten).

**Lesbarkeit je Variante** (WCAG-Verhältnis, Worst Case gerechnet; Text muss ≥ 4,5 haben):

| Variante | Kopf-Karte, weißer Text (über reinem Weiß / über echtem Himmel) | Label-Chip | Leiste Ruhe (Schwarz/Orange/Weiß darunter) | Leiste Aktiv |
|---|---|---|---|---|
| Morgen | 5.2 (6.6) | 8.6 | 10.1 | 14.4 |
| Mittag | 4.6 (6.4) | 9.1 | 10.1 | 14.4 |
| Abend | 5.3 (7.2) | 8.6 | 10.1 | 14.4 |
| Nacht | 4.8 (18.6) | 7.0 | 9.5 | 13.8 |

Regeln dahinter: Kopf-Karte ist Milchglas mit 66 % (Tag) bzw. 58 % (Nacht) dunkler Tönung. Die Leiste hat unter sich immer einen Schleier in der Bodenfarbe (70 %), Label und Symbole nutzen die Primärfarbe der Variante (Tinte bei Tag, Cremeweiß bei Nacht). Nacht-Leiste ist dunkles Glas (45 % Ruhe, 82 % Aktiv). Orange Aktiv-Pille trägt immer dunkle Tinte (6,5:1). Nicht gemessen: Text im Kopf-Karte-Sekundärton und über echtem Bild, siehe Prüfung im Brief.

**Verhältnis zum hellen/dunklen Thema.** Vorschlag: Die Tageszeit bestimmt **nur die Welt** (Hintergrund, Licht, Glasfarbe von Kopf-Karte und Leiste). Die Inhaltsflächen (Karten in Heute, Chats, Profil) folgen dem Systemthema hell/dunkel. Nacht ist also nicht automatisch dunkel und umgekehrt: Wer nachts im Hellen-Modus ist, sieht auf Heute helle Karten und auf dem Pfad die Nacht-Welt. Grund: Systemthema ist eine bewusste Nutzerwahl und Barrierefreiheit (z. B. Hell wegen Sehschwäche), die Welt ist Atmosphäre. Gilt für den Pfad und Screens mit Welt-Hintergrund; Heute, Chats, Profil bekommen nur einen ruhigen Schleier der Welt oben.

**Bedienungshilfen.** In „Darstellung“ lässt sich ein fester Look wählen: Automatisch (Tageszeit), Morgen, Mittag, Abend oder Nacht. Bei „Transparenz reduzieren“ und hohem Kontrast gelten die Regeln aus Ansatz 2 und v1 unverändert: Karte, Leiste, Chips und Sheets opak, kein Blur; die Welt wird zu einem ruhigen Verlauf ohne Textur, Dunst und Sterne. Bei „Bewegung reduzieren“ keine Überblendung zwischen den Phasen.

## Rückfragen (Ansatz 3)
1. Sind die Zeitgrenzen (5/10/17/21 Uhr, 30 Minuten Überblendung) so gut, oder soll die Welt sich nur nach der Sonne am Wohnort richten?
2. Tageszeit nur für die Welt, Inhaltsflächen nach System hell/dunkel: einverstanden? Alternative: Nacht schaltet die ganze App dunkel.
3. [blockierend für Manny und 3D-Objekte, unverändert] Wer liefert die finalen Illustrationen und mit welchen Rechten?

---

# Ansatz 4 – Manny

Bilder: `mockups/v2-manny-sticker.png` (groß, Standard, Feier, Trösten, Kopf als Knopf in 3 Größen) und `mockups/v2-ansatz4-abend.png` (Abend-Pfad mit neuem Manny). Quelle: `mockups/v2-src/gen4.py` (SVG im Code gezeichnet). Alles weiterhin **Platzhalter** (im Bild so beschriftet), bis finale Illustrationen mit geklärten Rechten vorliegen. Der Aquarell-Stil entfällt.

**Stilregeln.**
- Flacher Sticker-Stil: gleichmäßige, sehr dunkle Kontur (Marine `#0B1020`, etwa 4–5 px bei 390 Breite, runde Ecken und Enden), wenige flache Farbflächen mit einem einzigen Schatten-Ton je Fläche (rechts bzw. unten), ein kleiner heller Reflex am Kopf.
- Farben: Körper Blau-Grau `#2A3A57` (Schatten `#1B2640`), Bauch Creme `#FFF1D8` (Schatten `#EAD5B4`), Schnabel und Füße Orange `#FF9A2E`, Stirnband Mandarine `#FF7A2E` (identisch mit dem App-Akzent).
- Schwarze Sonnenbrille mit je einem hellen Glanzreflex, breit über der Augenpartie. Sie ist Markenzeichen und lässt sich absetzen.
- Haltung: lässig stehend, Flügel leicht abstehend, Schnabel mit leichtem Lächeln. Die Kontur bleibt in allen Größen gleich dick relativ zur Figur, im Kopf-Knopf wird sie nicht dünner als 3 px.
- Posen aus Runde 1 bleiben gültig (Begrüßung, Feier, Erinnerung, Chat, Training, Trösten), je Pose eine feste Illustration, Bewegung im Code. Trösten: Brille ab (in der Hand), Augen sichtbar, Flügel auf der Brust, Brille nur wieder aufsetzen, wenn die Situation entspannt ist.

**Abgrenzung zur Vorlage (Etsy-Sticker, nur Inspiration, nichts übernommen).** Die Vorlage gibt nur die allgemeine Stil-Idee vor: Pinguin, dunkle Kontur, flache Farben, Sonnenbrille. Eigen sind:
- Aufrechte, symmetrische Birnenform mit rundem Kopf (die Vorlage ist schräg geneigt und eiförmig).
- Kein weißer Gesichtsbereich, der Bauch läuft spitz unter dem Schnabel zusammen, anderer Bauchumriss und Schattenverlauf.
- **Stirnband in Akzentorange** als Reha-Markenzeichen (Vorlage: keines), Brillengläser in einem eigenen Rechteckschnitt mit Bügeln.
- Dreizehige, runde Füße und eigene Flügelform. Alle Formen sind frei im Code gezeichnet, es wurde nichts durchgepaust oder aus der Vorlage übernommen.
- Grenze: Mit Sonnenbrille bleibt die Grundidee (Pinguin mit Sonnenbrille im Stil eines Stickers) naheliegend. Rechtlich geprüft ist das nicht (keine Rechtsberatung); die endgültige Figur sollte der Zeichner eigenständig entwerfen.

## Rückfragen (Ansatz 4)
1. [blockierend für die finale Figur] Wer zeichnet Manny endgültig, und mit welchen Rechten (Auftragszeichner, KI-Erstellung, Lizenz)? Dieser Entwurf ist nur Platzhalter und Briefing für den Zeichner.
2. Stirnband als Markenzeichen: gut, oder lieber ein anderes Reha-Zeichen (Kniebandage geht bei einem Pinguin schlecht; Alternativen: Schweißband am Flügel, kleines Pflaster)?
