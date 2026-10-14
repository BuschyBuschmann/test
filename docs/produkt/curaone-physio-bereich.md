# CuraOne – Physio-Bereich

Status: FREIGEGEBEN (2026-10-14) · Stand 2026-10-14 · Ergänzt `curaone-spezifikation-manny-gehirn.md` (P-1 bis P-5). Grundlage: `curaone-anregungen-2026-10-13.md` Abschnitt 2, Abläufe `curaone-ablaeufe-training-checkup.md`.

## Nutzerentscheidungen (2026-10-14)

| # | Thema | Entscheidung |
|---|---|---|
| PB-1 | Gerät | **Handy und Rechner**: kurzer Blick am Handy zwischen zwei Patienten, Pläne und Übungen bequem am Rechner. Beide Geräte zeigen dieselben Inhalte, das Handy kompakter. |
| PB-2 | Patientenansicht | **Kacheln**, und ein Tipp auf eine Kachel zeigt jeweils mehr Details. Ohne Scrollen sichtbar sind die Kacheln aus PB-3. |
| PB-3 | Kacheln | 1. **KI-Kurzbriefing** (Ausschnitt 3) · 2. **Befinden, Motivation, Warnzeichen** als eine Kachel · 3. **Schmerz-Trend** als kleine Grafik · 4. **Training seit dem letzten Termin** · 5. **Übungen gut/schlecht** · 6. **Phase und nächstes Ziel** · 7. **Fragen des Patienten** · 8. **Notiz vom letzten Termin** |
| PB-4 | Fragen des Patienten | Der Patient stellt sie **aktiv an den Physio** über ein eigenes Feld in der App. Sie haben nichts mit dem Manny-Chat zu tun; der Chat bleibt privat. |
| PB-5 | Physio-KI | Sie hat vier Aufgaben: Kurzbriefing je Patient, beim Anlegen von Übungen helfen (inkl. KI-Bild), Plan-Anpassungen vorschlagen (nur als Vorschlag, der Physio entscheidet), Fachfragen beantworten (mit Quelle, ohne Gewähr). |
| PB-6 | Baukasten „Damit anfangen“ | Ja heißt, die Übung ist **ab sofort im Plan aktiv**. Nein heißt, sie ist vorbereitet und wird später freigeschaltet (ab einer Phase oder einem Datum). |
| PB-7 | Historie | Sie reicht **über alle Verletzungen hinweg**. Je Verletzung zeigt sie Zeitraum, Dauer bis „wieder gut“, Trainingstreue, Schmerzverlauf, Phasen und Notizen. Eine neue Verletzung startet einen neuen Plan beim selben Patienten. |
| PB-8 | Neuer Patient | Pflicht sind **nur Vorname und Verletzung** bzw. eine Plan-Vorlage. Danach erscheinen sofort QR-Code und Link zum Teilen. Alles Weitere lässt sich später ergänzen. Ziel: unter 30 Sekunden. |
| PB-9 | Aufteilung | **Ausschnitt 2:** alles ohne KI. **Ausschnitt 3** (zusammen mit der Manny-KI): die Physio-KI aus PB-5. |

## Ausschnitt 2: Nutzergeschichten und Akzeptanzkriterien

**PB-A Patientenliste.** Als Physio möchte ich meine Patienten und die der Praxis finden, damit ich auch vertreten kann.
- AK: Die Liste hat zwei Reiter: „Meine Patienten“ und „Praxis“. Ein Patient mit offenem Warnzeichen ist in beiden Reitern markiert.
- AK: Ein Suchfeld findet einen Patienten über den Namen.
- AK: „Meine“ sind die Patienten, deren Hauptphysio man ist. Hauptphysio ist zunächst, wer den Patienten anlegt; man kann ihn ändern. *(Annahme)*

**PB-B Patientenübersicht in Kacheln.** Als Physio möchte ich in 5 Minuten alles Wichtige erfassen.
- AK: Beim Öffnen eines Patienten sind die Kacheln 2–8 aus PB-3 sichtbar, auf dem Rechner ohne Scrollen, auf dem Handy in einer Spalte.
- AK: Ein Tipp auf eine Kachel öffnet ihre Detailansicht, zum Beispiel:
  - Schmerz-Trend: Verlauf der letzten 30 Tage mit allen Werten.
  - Übungen gut/schlecht: Bewertung je Übung aus den Check-ups.
- AK: „Training seit dem letzten Termin“ zeigt die Trainingstage im Verhältnis zu den Tagen seit dem letzten Termin, den Streak und übersprungene Übungen mit Grund.
- AK: Die Kachel mit Befinden, Motivation und Warnzeichen zeigt offene Warnzeichen zuerst. Eine Nachricht bei schlechter Stimmung über 5 Tage (C-3) erscheint dort.
- AK: Inhalte des Manny-Chats erscheinen nirgends.

**PB-C Notiz.** Als Physio möchte ich nach dem Termin eine kurze Notiz hinterlassen, damit eine Vertretung Bescheid weiß.
- AK: Die Notiz ist für alle Physios der Praxis sichtbar, mit Autor und Datum. Der Patient sieht sie nicht. *(Annahme)*

**PB-D Fragen des Patienten.** Als Patient möchte ich meinem Physio eine Frage stellen, damit er sie in der nächsten Stunde klärt.
- AK: In der App gibt es „Frage an meinen Physio“. Die Frage erscheint in der Kachel „Fragen des Patienten“.
- AK: Der Physio kann eine Frage als „besprochen“ markieren; der Patient sieht diesen Status. Eine Chat-Funktion ist das nicht.

**PB-E Neuer Patient in 30 Sekunden.** Als Physio möchte ich einen Patienten mit Vorname und Verletzung anlegen und sofort QR-Code und Link bekommen.
- AK: Nach Eingabe von Vorname und Verletzung bzw. Plan-Vorlage und einem Tipp auf „Anlegen“ erscheinen QR-Code, Link und „Teilen“ (z. B. per SMS, Mail, Messenger).
- AK: Der Patient landet nach dem Einlösen direkt in seinem Plan. Gibt es eine Vorlage, ist der Plan schon gefüllt.

**PB-F Übungs-Baukasten.** Als Physio möchte ich Übungen wie mit einem Baukasten anlegen.
- AK: Pflichtfelder sind Name und Beschreibung. Optional:
  - Zeit, Wiederholungen bzw. Sätze, Gewicht
  - Hilfsmittel bzw. Material
  - Ort (Zuhause / Praxis / Fitnessstudio)
  - „Damit anfangen“ (PB-6)
  - Pausen-Dauer
  - Bilder (Upload, später KI-Bild)
- AK: Beim Speichern kann man die Übung direkt einem oder mehreren Patienten zuweisen. Bei jedem zugewiesenen Patienten erscheint sie in der gewählten Phase.
- AK: Die Übung ist für die ganze Praxis wiederverwendbar.

**PB-G Historie.** Als Physio möchte ich den Verlauf aller Verletzungen eines Patienten sehen.
- AK: Die Historie zeigt je Verletzung Zeitraum, Dauer bis zum Abschluss, Trainingstreue (Anteil erledigter Trainingstage), Schmerzverlauf und Notizen.
- AK: Ein Patient kann eine neue Verletzung bekommen; das legt einen neuen Plan an und erhält die Historie.

## Ausschnitt 3: Physio-KI (Kurzfassung, Details im KI-Plan)
- **Kurzbriefing:** drei Sätze über der Patientenübersicht, nur aus Verlauf, Check-ups und Warnzeichen. Nie aus dem Manny-Chat.
- **Übung per KI:** Aus einer kurzen Beschreibung füllt die KI den Baukasten vor und erzeugt auf Wunsch ein Bild. Der Physio prüft und speichert; ohne ihn wird nichts aktiv.
- **Plan-Vorschläge:** Hinweise wie „3× schwer und Schmerz bei der Kniebeuge, leichtere Variante?“. Übernommen wird ein Vorschlag nur per Tipp des Physios.
- **Fachfragen:** Antworten mit Quellenangabe und dem Hinweis „keine Gewähr“.

## Offene Fragen
1. **Plan-Vorlagen je Verletzung:** Wer erstellt sie: CuraOne, die Praxis oder beide? *Annahme:* CuraOne liefert Beispielvorlagen, die Praxis kann eigene speichern.
2. **Hauptphysio:** Kann es mehrere geben? *Annahme:* einer, änderbar.
3. **KI-Bilder:** Für sie ist ein Bilddienst nötig. Claude erzeugt keine Bilder; Anbieter und Kosten sind offen und kommen in den KI-Plan.
4. **Fachfragen-KI:** Woher kommen die Quellen? Nur Leitlinien-Texte, die wir hinterlegen, oder Websuche? Gehört in den KI-Plan.
5. **Physio-Seite auf dem Handy:** Bisher plant der Plan sie als Web-Zugang. Mit PB-1 muss die Web-Seite auch am Handy gut bedienbar sein; das Flutter-Web-Target macht das möglich.
