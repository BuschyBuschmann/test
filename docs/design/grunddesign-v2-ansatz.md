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
