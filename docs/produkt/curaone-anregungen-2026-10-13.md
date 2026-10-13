# CuraOne – Anregungen des Nutzers nach der ersten Fassung (2026-10-13)

Status: **Rohfassung, noch nicht ausgearbeitet.** Das sind Stichpunkte im Wortlaut des Nutzers. Sie werden mit `/product-strategist` und `/app-experience` im Dialog ausgearbeitet. Bis dahin ist nichts davon beauftragt.

## 1. Social-Media-Gedanke
Ein Feed bzw. eine „For You“-Seite, die Übungen, Prävention usw. zeigt. Eine Art Instagram, aber bezogen auf Gesundheit und die eigene Verletzung. Dazu wichtige Artikel zur Verletzung, News zu neuen Behandlungsmöglichkeiten, News der eigenen Krankenkasse usw.

## 2. Physio-Bereich
1. **Patientenliste:** die eigenen Patienten und die der ganzen Praxis (zum Vertreten). Beim Anklicken sollen alle wichtigen Informationen direkt sichtbar sein, denn der Physio hat vor der Stunde höchstens 5–10 Minuten Zeit für den Patienten in der App. Gemeint sind z. B.:
   - Wie oft hat der Patient trainiert?
   - Welche Übungen gingen gut, welche schlecht?
   - Gab es Schmerzen?
   - Wurde das Gewicht erhöht?
   - Wie sind Motivation und Wohlbefinden?
   - Gibt es neue Ansätze zur Behandlung?
   - und vieles mehr.
2. **Übungen erstellen:** sehr leicht, wie ein Baukastensystem. Folgende Angaben gehören dazu:
   - Name, Zeit, Wiederholungen, Gewicht
   - Hilfsmittel
   - Gym ja/nein
   - „Damit anfangen“ ja/nein
   - Bilder: auswählen, von der KI erstellen lassen oder hochladen
   - direkte Zuordnung zu den Patienten, für die die Übung relevant ist
3. **Eigene KI**, die den Physio unterstützt.
4. **Historie je Patient:** Welche Verletzungen gab es? Wie lange dauerte es, bis alles wieder gut war? Wie sorgfältig wurden die Übungen gemacht? usw.

## 3. Patienten-Abfrage
1. Nach jeder Einheit ein kurzer Check-up, wie das Training lief: was gut war, was schlecht. Am besten je Übung, aber nur, wenn der Patient sich dafür Zeit nehmen will.
2. Möglichkeit zum Check-up auf „Heute“: Wohlbefinden, Schmerzen, Einschränkungen, psychische Probleme, Motivation usw.

## 4. Training
Das Training muss deutlich mehr unterstützt werden:
- Timer
- Checkliste zum Abhaken der Übungen
- Liste der Materialien je Übung
- Bilder zu den Übungen
- Ort, an dem die Übung gemacht werden kann
- usw.

## Erste Einordnung (Orchestrator, nicht entschieden)
- Teile davon berühren bereits freigegebene Pläne und gehören vor dem Bau von Ausschnitt 2 geklärt:
  - Physio-Patientenliste und Historie → Spec P-5, Plan Ausschnitt 2.
  - Übungsbaukasten → P-3.
  - Check-ups → A-3.
  - Trainingsunterstützung → A-2, M-3.
- Neu gegenüber der Spezifikation sind: Feed/News, Physio-KI, Bilder (auch KI-erstellt), Ort und Hilfsmittel je Übung, Check-up je Übung nach der Einheit.
- Prüfpunkte für den Feed: woher die Inhalte kommen (Artikel, News, Krankenkassen) sowie Rechte und Quellen.
