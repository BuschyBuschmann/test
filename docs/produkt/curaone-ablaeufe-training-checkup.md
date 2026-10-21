# CuraOne – Abläufe „Training“ und „Check-ups“

Status: FREIGEGEBEN (2026-10-14) · Stand 2026-10-14 · Grundlage: `curaone-anregungen-2026-10-13.md` (Abschnitte 3 und 4) und `curaone-spezifikation-manny-gehirn.md` (A-2, A-3, M-3)
Leitbild aus der Präsentation: modern und jung, „Instagram × Duolingo für Gesundheit“. Die visuelle Gestaltung übernimmt später der `ui-designer`.

## Nutzerentscheidungen (2026-10-14)

| # | Thema | Entscheidung |
|---|---|---|
| T-1 | Grundform | **Beides wählbar:** eine geführte Session im Vollbild (eine Übung nach der anderen) als Standard. Wer will, hakt direkt auf „Heute“ als Checkliste ab. |
| T-2 | Timer | Alle vier: Halte- bzw. Dauer-Timer, Pausen-Timer, Wiederholungen mitzählen, Gesamtzeit. |
| T-3 | Ort | Nur als Angabe an der Übung: Fitnessstudio, Physiopraxis und/oder Zuhause. Kein Filter, keine Karte. |
| T-4 | Material | Vor dem Start als Packliste, die man abhaken kann. Zusätzlich steht das Material bei jeder Übung. |
| T-5 | Abbruch | **Teilweise zählt:** pausieren, überspringen und beenden sind möglich. Erledigte Übungen werden gespeichert. Ab einer erledigten Übung zählt der Tag für den Streak. |
| T-6 | Bilder | Katalog-Bilder (Start- und Endposition) und Uploads des Physios bzw. KI-Bilder vom Physio. Videos kommen später. Ohne Bild erscheint eine neutrale Illustration. |
| C-1 | Check-up nach der Einheit | **1 Tipp plus optionale Details:** Pflicht ist „Wie lief’s?“ mit 5 Smileys. Danach optional je Übung: leicht / passend / schwer / Schmerz, dazu „Gewicht erhöht“ ja oder nein. |
| C-2 | Tages-Check-up | **Karte oben auf „Heute“, einmal täglich**, bis sie ausgefüllt oder weggeklickt ist. Abgefragt werden Schmerz 0–10, Wohlbefinden, Motivation, Einschränkungen und Stimmung. |
| C-3 | Psyche bzw. Stimmung | **Nur erfassen:** Die Werte werden gespeichert und dem Physio gezeigt. Die App reagiert gegenüber dem Patienten nicht. **Ausnahme:** Bei sehr schlechter Stimmung an fünf Tagen in Folge bekommt der Physio eine Nachricht (Warnzeichen ohne Details), mehr passiert nicht. Was „sehr schlecht“ heißt, wird mit den Warnzeichen-Schwellen (O-2) festgelegt. |

## Ablauf 1: Training vorbereiten (Heute)
**Auslöser:** Der Patient öffnet „Heute“. **Ziel:** wissen, was heute ansteht und was man dafür braucht.
1. Oben steht die Tages-Check-up-Karte, falls sie heute noch offen ist (siehe Ablauf 4).
2. Darunter steht das Tagesprogramm als Liste. Jede Übung zeigt Bild, Name, Umfang (Sätze × Wiederholungen bzw. Dauer), Material und Ort, z. B. „Zuhause · Praxis“.
3. Ein Tipp auf eine Übung öffnet das Übungsdetail: Bild bzw. Bilder, Beschreibung des Physios, Grenzen, Material, Ort.
4. Unten stehen zwei Wege:
   - **„Training starten“** (Standard): geführte Session, siehe Ablauf 2.
   - **Abhaken in der Liste:** Jede Übung hat ein Häkchen, siehe Ablauf 3.

## Ablauf 2: Geführte Session
**Ziel:** sicher und motiviert alle Übungen schaffen, ohne nachdenken zu müssen.
1. **Packliste:** „Du brauchst heute: Theraband, Stuhl“. Die Punkte lassen sich abhaken. Fehlt etwas, kann man die betroffene Übung direkt tauschen, nur gegen eine Übung aus derselben Phase, die der Physio freigegeben hat. Danach tippt man „Los geht’s“.
2. **Übungsbildschirm im Vollbild:**
   - Oben ein Fortschrittsbalken (Übung 2 von 5) und die laufende Gesamtzeit.
   - Groß das Bild der Übung, darunter Name und Kurzanleitung.
   - Bei Wiederholungen ein großer Zähler zum Antippen, z. B. „7 / 12“.
   - Bei Übungen auf Zeit ein Countdown. Am Ende gibt es Ton bzw. Vibration.
3. **Satz fertig:** Der Pausen-Timer startet automatisch (Dauer vom Physio) und lässt sich überspringen. Danach folgt der nächste Satz.
4. **Übung fertig:** Ein kurzes Erfolgssignal (Duolingo-Moment), dann automatisch die nächste Übung.
5. **Jederzeit möglich:**
   - **Pause:** Alle Timer halten an.
   - **Übung überspringen:** Die Übung gilt als nicht erledigt.
   - **Beenden:** Bisher Erledigtes wird gespeichert.
   - **Schmerz melden:** Bietet die freigegebene leichtere Variante oder einen Abbruch an. Das deckt sich mit M-3 bzw. dem KI-Plan.
6. **Ende:** Zusammenfassung mit Gesamtzeit, Zahl der erledigten Übungen und Streak. Manny feiert. Danach folgt der Check-up nach der Einheit (Ablauf 4a).

## Ablauf 3: Abhaken auf „Heute“
1. Der Patient hakt einzelne Übungen in der Liste ab. Das Übungsdetail kann bei Bedarf Timer bzw. Zähler für genau diese Übung starten.
2. Sobald die erste Übung abgehakt ist, zählt der Tag für den Streak (T-5).
3. Ist die letzte Übung abgehakt oder tippt man „Fertig für heute“, folgt die Zusammenfassung und dann der Check-up nach der Einheit.
4. Rückgängig: Ein abgehaktes Häkchen lässt sich am selben Tag wieder entfernen.

## Ablauf 4: Check-ups
**4a Nach der Einheit**
1. Pflicht ist eine einzige Frage: „Wie lief’s?“ mit 5 Smileys.
2. Optional, über „Details je Übung?“: Je Übung wählt man leicht / passend / schwer / Schmerz und kann „Gewicht erhöht“ setzen.
3. Bei übersprungenen Übungen erscheint optional „Warum übersprungen?“ mit den Antworten Zeit / Schmerz / Material fehlte / anderes.
4. Speichern. Die Werte erscheinen beim Physio im Verlauf.

**4b Tages-Check-up**
1. Die Karte „Wie geht’s dir heute?“ steht oben auf „Heute“, einmal pro Tag.
2. Abgefragt werden fünf schnelle Werte: Schmerz 0–10, Wohlbefinden, Motivation, Einschränkungen und Stimmung.
3. Nach dem Ausfüllen wird die Karte klein („Erledigt, danke!“). Wegklicken geht ebenfalls; die Karte kommt erst am nächsten Tag wieder.
4. Die Werte gehen an den Physio (Verlauf) und beeinflussen das Tagesprogramm: Ab der Schmerzschwelle gilt die Kürzungsregel E-36 aus dem KI-Plan.
5. Stimmung und psychische Werte werden nur erfasst und dem Physio gezeigt. Bei sehr schlechter Stimmung an fünf Tagen in Folge bekommt der Physio eine Nachricht (C-3).

## Varianten, Fehler, Randfälle
- **Kein Bild vorhanden:** Es erscheint eine neutrale Illustration, nie eine leere Fläche.
- **App wird während der Session geschlossen oder das Handy gesperrt:** Beim Zurückkehren steht die Session pausiert an derselben Stelle. Nach Mitternacht gilt der Tageswechsel wie bisher, und Erledigtes zählt für den Vortag.
- **Offline:** Die Session läuft vollständig. Die Ergebnisse gehen über die Warteschlange aus Plan Ausschnitt 2 nach.
- **Barrierefreiheit:**
  - Timer und Zähler haben Screenreader-Ansagen, z. B. „noch 10 Sekunden“.
  - Ton bzw. Vibration lassen sich abschalten.
  - Alles ist auch ohne Gesten bedienbar.
  - Bei „Bewegung reduzieren“ gibt es keine Feier-Animation.

## Offene Fragen
1. **Erledigt (C-3):** Der Nutzer hat entschieden, dass bei sehr schlechter Stimmung an fünf Tagen in Folge nur der Physio eine Nachricht bekommt. Offen bleibt, wie „sehr schlecht“ definiert ist; das wird mit O-2 festgelegt.
2. **Zählt ein Tag mit nur abgehaktem Tages-Check-up, aber ohne Übung, für den Streak?** Annahme: nein.
3. **Ton bzw. Vibration standardmäßig an?** Annahme: an, abschaltbar.
4. **Gewicht:** nur „erhöht“ ja/nein, oder genaue kg-Angabe? Annahme: ja/nein, die kg-Angabe kommt später mit dem Übungsbaukasten (Physio-Bereich).
