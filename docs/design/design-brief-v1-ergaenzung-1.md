# Design-Brief v1, Ergänzung 1: Rückgängig, Tageswechsel, "Deine Daten", Pfad-Tipps

Status: FREIGEGEBEN (2026-10-07) · Umsetzung: `flutter-developer` · Bezug: `docs/design/design-brief-v1.md` (freigegeben 2026-10-07)
Quelle der Vorschläge: `docs/produkt/curaone-vollstaendigkeit.md` (V1 bis V5, vom Nutzer gewählt)

**Geltung.** Tokens (3.1 bis 3.6), Komponenten (5), Regeln (Abschnitt 4, 8) und die Nutzerentscheidungen aus Abschnitt 12 des Briefs v1 gelten unverändert. Diese Ergänzung fügt nur hinzu. **UI-1 bis UI-36 bleiben unverändert**, neue Kriterien beginnen bei **UI-37**. Zwei Stellen des Briefs v1 werden nur präzisiert, nicht geändert (6.3 Zeitpunkt der Manny-Feier, 5.9 Kopfzeile um ein Icon erweitert); beides steht unter Rückfragen.

---

## 1. Konflikte mit dem Brief und ihre Auflösung

| # | Konflikt | Auflösung |
|---|---|---|
| K1 | Kopfzeile (5.9) hat rechts schon Freeze- und Streak-Pill, 320 dp Breite ist knapp. | Icon "Deine Daten" kommt als **letztes** Element rechts hinzu. Reicht die Breite nicht (linker Textblock unter 150 dp, ca. bei 320 dp oder Textskalierung über 1,15), bricht die Kopfzeile um (siehe 3.1). Inhalt von UI-22 bleibt vollständig erhalten. |
| K2 | Freie Zonen unten links/rechts (6.2, UI-24) müssen frei bleiben. | Auf dem Pfad gibt es **keine** Snackbar. Rückmeldungen dort laufen über den am Knoten verankerten Hinweis (V5) oder über sichtbare Zustandsänderung. Snackbars gibt es nur auf Heute (über dem Primärbutton) und im Onboarding (über der Mikrofon-Zeile). |
| K3 | Blur-Budget (3.5, UI-6): höchstens 2. Sheet E2 plus Nav ist schon 2. | Beim Öffnen von "Deine Daten" wird eine sichtbare Manny-Blase **geschlossen** (zählt als weggetippt). Bestätigungsdialoge, Snackbar und Knoten-Hinweis sind **opak ohne Blur** (`surface-opaque`). Scrim ist ein einfacher Schwarz-Wert ohne Blur. |
| K4 | Abschnitt 4: `status-error` nur für Status, Akzent nur für Handlung und Fortschritt. "Alles löschen" ist eine Handlung mit Warnwirkung. | Das Löschen verwendet **weder** `status-error` (wäre Status als Handlung) **noch** `accent` (Orange-Rot als Löschbutton wäre von einer Warnung nicht unterscheidbar). Es ist **neutral** (Umriss-Button), und die Gefahr wird durch Wort, Symbol, Ort (ganz unten im Sheet), Klartext und Bestätigungsdialog getragen. Im Dialog ist die **sichere** Aktion die betonte (hell gefüllt). `status-error` kommt nur beim echten Fehlerfall "Löschen fehlgeschlagen" vor (mit Icon und Text). So gilt dieselbe Linie wie in Abschnitt 4, Punkt 4 und 5 (Warnkontext: neutrale Aktionen, opake Fläche). |
| K5 | Sichtbare Folge der Streak-Regeln beim Tageswechsel gehört der Logik. | Hier nicht festgelegt (Orchestrator klärt separat). Die Kopfzeile zeigt wie in 6.2 den jeweils gültigen Streak-Zustand. |

---

## 2. Neue Bausteine (alle mit vorhandenen Tokens; ein neuer Hilfs-Token)

| Baustein | Zweck und Aufbau |
|---|---|
| Token `scrim` (neu) | Schwarz 60 %, im Modus Hoher Kontrast 72 %. Kein Blur. Dunkelt Inhalt hinter Sheet und Dialog ab. |
| `PillButton` Variante **Neutral hell** (konkretisiert Abschnitt 4, Punkt 4) | Füllung `text-1`, Text `on-accent`, 56 dp, Pill (Kontrast 16,37:1). Pressed: Füllung wird reines Weiß (die Füllung ist schon fast weiß, "10 % heller" gilt hier als Weiß). |
| `PillButton` Variante **Umriss** (konkretisiert Abschnitt 4, Punkt 4) | Keine Füllung (Pressed: Weiß 10 %), 1,5 dp Rand `border-control` (Hoher Kontrast: `border-control-hc`), Text und Icon `text-1`, 56 dp, Pill. |
| `CuraSnackbar` (neu; gilt rückwirkend auch für "Entfernt. Rückgängig") | Fläche `surface-opaque`, Rand `border-hair` (Hoher Kontrast `border-control-hc`), Radius 20, Innenabstand 16, Text `body` `text-1`, optionale Aktion rechts als Text-Button in `accent-hi` (5,60:1 auf `surface-opaque`), Hit-Area 48 dp. Liegt 12 dp über dem fixierten Primärbutton auf Heute, mit 16 dp Seitenrand. Immer nur eine Snackbar: eine neue ersetzt die alte, und die alte Aktion verfällt. Erscheint mit Einblenden plus 8 dp Schiebung (`dur-base`). Live-Region (liest sich beim Erscheinen vor). Nie Blur. |
| `NodeHint` (neu) | Kleiner Hinweis am Pfad-Knoten: `surface-opaque`, Rand `border-hair`, Radius 16, Innenabstand 12/16, Text `secondary` (14 sp) `text-1`, Pfeil 8 dp zum Knoten. Maximale Breite min(240 dp, Bildschirmbreite minus 32 dp), Text bricht um. Keine Aktion, kein X (kein Sprechblasen-Ersatz). Kein Blur. |
| `CuraDialog` (neu) | Bestätigungsdialog: `surface-opaque`, Rand `border-hair` (Hoher Kontrast `border-control-hc`), Radius 24, Breite Bildschirm minus 32 dp (max. 400 dp), Icon 28 dp `text-1`, Titel `title`, Text `body`, Buttons gestapelt, volle Breite, 56 dp, Abstand 8 dp. Scrim `scrim`. Inhalt scrollt, wenn er nicht passt; die Buttons bleiben unten sichtbar. Einblenden (`dur-base`), kein Skalieren. Kein Blur, kein Glow-Eindruck. |
| `HeaderIconButton` (neu) | 48 × 48 dp Hit-Area, Icon 24 dp, Fläche transparent, Icon `text-2` (8,54:1 auf `bg`), Pressed: Kreis Weiß 10 %. Hoher Kontrast: zusätzlich Kreisrand `border-control-hc`. Tooltip bei Langdruck/Hover. |
| `DataSheet` "Deine Daten" (neu, E2) | Sheet nach 3.5 (`surface-float`, Blur σ = 16, Radius oben 28, Schatten), Höhe nach Inhalt, höchstens 90 % der Bildschirmhöhe. Aufbau siehe 3.2. |
| Wiederverwendet | `CuraTextField`, `ChoiceCard` (einschließlich Karte "Anderes / selbst eingeben" mit Freitext), Datumskarte aus Onboarding Schritt 4 (im Folgenden `DateCard`, falls beim Bau noch nicht als eigenes Widget vorhanden: aus Schritt 4 herauslösen, nicht kopieren), `PillButton` Primär, `GlassCard`. |

---

## 3. Vorschläge im Einzelnen

### 3.1 V3, Teil 1: Einstieg "Deine Daten" in der Pfad-Kopfzeile

- **Ort:** `PathHeader`, ganz rechts hinter der Streak-Pill. Nur auf dem Tab "Pfad" (die Heute-Ansicht bekommt keinen Einstieg).
- **Icon:** `person_outline_rounded` (abgerundetes Material-Icon), 24 dp, `text-2`. Bewusst ohne Füllung und ohne Akzent, damit es unauffällig bleibt.
- **Normales Layout** (Breite ab ca. 360 dp bei Textskalierung bis 1,15): eine Zeile. Links Textblock ("Woche N", "Phase M · Kreuzband", ggf. "Beispielpfad"), rechts Freeze-Pill, 4 dp, Streak-Pill, 4 dp, `HeaderIconButton`. Abstand zwischen den drei Zielen mindestens 8 dp (Pills liegen näher, wenn ihre Hit-Area die 48 dp einhält; sonst 8 dp).
- **Umbruch-Layout** (linker Textblock bekäme unter 150 dp, also typischerweise 320 dp oder Textskalierung über 1,15): Zeile 1: Textblock (volle restliche Breite) und rechts `HeaderIconButton`. Zeile 2 (8 dp tiefer): Freeze- und Streak-Pill linksbündig. Der Zusatz "eingefroren" (6.2) steht wie bisher an der Streak-Pill und darf in Zeile 2 umbrechen. Es wird nichts abgeschnitten oder überlagert.
- **Screenreader:** "Deine Daten, Schaltfläche". Fokusreihenfolge: Textblock, Freeze, Streak, "Deine Daten" (visuelle Reihenfolge).
- **Zustände:** Standard, Pressed (Kreis Weiß 10 %), Fokus (`focus-ring` um den Kreis), Hoher Kontrast (Kreisrand).

### 3.2 V3 und V4: Sheet "Deine Daten"

**Öffnen:** Tipp auf das Icon. Sheet schiebt von unten ein (`dur-base`). Eine sichtbare Manny-Blase wird dabei geschlossen (K3). Der Fokus geht auf den Sheet-Titel, beim Schließen zurück auf das Icon.

**Aufbau (von oben nach unten):**

1. **Kopf:** Titel "Deine Daten" (`title`), darunter `secondary` `text-2`: "Alles bleibt auf diesem Gerät. Hier kannst du es ändern oder löschen." Rechts oben Schließen-Button (X, Hit-Area 48 dp). Kopf scrollt nicht mit.
2. **Scrollbereich:**
   - Abschnittslabel `label` "DEIN PROFIL" (Großbuchstaben nur im Stil, nicht im Text).
   - **Name:** `CuraTextField`, Label "Dein Name", vorbefüllt. Pflichtfeld (nach Trimmen nicht leer).
   - **Verletzung:** Label `label` "VERLETZUNG", darunter vier `ChoiceCard`s wie in Onboarding Schritt 3 (Kreuzbandriss (ACL), Bänderriss Sprunggelenk, Muskelfaserriss, Anderes / selbst eingeben). Aktueller Typ ist gewählt. Bei "Anderes" erscheint das optionale Textfeld "Was ist passiert?" (vorbefüllt, falls vorhanden).
   - **Zeitpunkt:** Label `label` "VERLETZUNG ODER OP", darunter die `DateCard` mit dem gespeicherten Datum (z. B. "3. September 2026"). Tipp öffnet die Datumsauswahl des Systems (Dark-Theme, Akzent `accent`), nur Datum bis heute wählbar (wie Schritt 4).
   - **Hinweiszeile** (Info-Icon `text-2` plus `secondary` `text-2`): "Ändern sich Verletzung oder Datum, werden Woche, Phase und Pfad neu berechnet. Dein Streak bleibt." (Inhalt hängt an Rückfrage 1.)
   - Trennlinie `border-hair`.
   - Abschnittslabel `label` "DATEN LÖSCHEN", Text `body` `text-2`: "Löscht alles auf diesem Gerät und nimmt deine Einwilligung zurück. Danach startest du neu." Darunter **Umriss-Button** (Icon `delete_outline_rounded`) "Alle Daten löschen und neu starten". Keine Akzentfarbe, kein `status-error`.
3. **Fußleiste fest unten** (16 dp Abstand, über Safe Area und Tastatur): Primärbutton "Speichern" (56 dp, `accent`). Disabled, solange nichts geändert ist, der Name leer ist oder (nicht möglich, aber abgesichert) das Datum in der Zukunft liegt.

**Kein** Manny und **keine** Mikrofon-Zeile im Sheet (die gehören zum Onboarding-Ablauf, 6.1).

**Speichern (V4):**
- Sheet schließt. Der Name erscheint sofort in "Heute, [Name]" und in allen Manny-Texten.
- Wurden Verletzung oder Datum geändert: Woche, Phase und Pfad werden neu berechnet, die Kopfzeile zeigt die neuen Werte, der Pfad scrollt auf die aktuelle Unit (ca. 55 % Höhe, wie 6.2; bei reduzierter Bewegung ohne Animation).
- **Streak, Freeze-Zahl und die Heute-Tagesänderungen (Tauschen/Entfernen/eigene Übungen/Erledigt) bleiben unverändert.** Begründung: Der Streak zählt tatsächlich trainierte Tage. Eine Korrektur eines Tippfehlers darf niemanden bestrafen und nichts verfälschen.
- **Erledigte Pfad-Units (Vorschlag, siehe Rückfrage 1):** Der Pfad zeigt nach dem Speichern den Stand, der zu den neuen Angaben passt, so als wäre die Person mit diesen Angaben gestartet: Units vor der aktuellen Woche zeigen Haken. Einzelne bereits eingetragene Trainingstage werden nicht auf den neuen Pfad übertragen. Begründung: Der Pfad hängt laut 6.2 am Datum. Ein zweiter, davon unabhängiger Fortschrittsstand würde zu widersprüchlichen Anzeigen führen.
- Es gibt keine Snackbar auf dem Pfad (K2). Rückmeldung ist das Schließen des Sheets und die sichtbare Änderung. Screenreader hört "Gespeichert. Pfad neu berechnet." bzw. bei nur geändertem Namen "Gespeichert."

**Schließen mit ungespeicherten Änderungen** (X, Zurück, Escape, Tipp auf Scrim oder Wegwischen): `CuraDialog` "Änderungen verwerfen?", Text "Du hast Änderungen noch nicht gespeichert.", Buttons: **"Weiter bearbeiten"** (Neutral hell, Anfangsfokus) und **"Verwerfen"** (Umriss). Ohne Änderungen schließt das Sheet direkt.

**Löschen (V3, Teil 2):** Tipp auf "Alle Daten löschen und neu starten" öffnet `CuraDialog`:
- Icon `delete_outline_rounded` in `text-1`.
- Titel: "Alles löschen?"
- Text: "Name, Verletzung, Pfad, Streak und deine Einwilligung werden von diesem Gerät gelöscht. Das lässt sich nicht rückgängig machen. Danach startest du wieder bei Schritt 1."
- Buttons (gestapelt): **"Abbrechen"** (Neutral hell, **Anfangsfokus**) oben, **"Ja, alles löschen"** (Umriss, Icon `delete_outline_rounded`) darunter.
- Abbrechen, Zurück, Escape und Tipp auf den Scrim brechen ab. Es wird nichts gelöscht.
- **Bestätigt:** Alle lokalen Daten werden gelöscht (Name, Verletzungstyp und -text, Datum, Einwilligung mit Zeitstempel und Version, Onboarding-Stand, Pfadfortschritt, Streak und Freezes, Tagesprogramm mit allen Tagesänderungen, Zeitwahl, Tageszähler der Manny-Blasen, ausstehende Feier). Der gesamte Navigationsstapel wird ersetzt: Onboarding **Schritt 1** ("Schritt 1 von 4", leeres Namensfeld, Manny begrüßt wie beim Erststart). Per Zurück gelangt man **nicht** zurück zu Pfad oder Sheet. Auf Schritt 1 erscheint eine Snackbar über der Mikrofon-Zeile: "Alle Daten sind gelöscht." (4 s, ohne Aktion). Schritt 2 (Datenschutz) muss wieder bestätigt werden. Was die Zurück-Taste auf Schritt 1 selbst tut, ist nicht Teil dieser Ergänzung.
- **Laden:** lokal, in der Regel sofort. Dauert es über 300 ms, zeigt der Button "Ja, alles löschen" einen Fortschrittskreis und ist deaktiviert.
- **Fehler:** Im Dialog erscheint über den Buttons `error_outline`-Icon in `status-error` plus Text "Das Löschen hat nicht geklappt. Versuch es nochmal." (Text in `text-1`). Der Button heißt dann "Nochmal versuchen". `status-error` ist hier Status (erlaubt), nie Handlungsfarbe.

**Zustände des Sheets:** Standard, Fokus je Feld (wie Onboarding), Geändert (Speichern aktiv), Datumsauswahl offen (System-Dialog), Löschen-Dialog offen, Verwerfen-Dialog offen, Löschfehler. Laden/leer entfallen (lokal, immer gefüllt).

### 3.3 V1: "Eingetragen. Rückgängig"

**Ablauf nach "Training eintragen" (Manuell):**
1. Das Sheet "Wie willst du trainieren?" schließt (`dur-base`).
2. Auf Heute steht der Button "Heute erledigt" (6.3). Streak, Erledigt-Status und Unit-Abschluss sind **sofort** übernommen (UI-30 gilt wie bisher).
3. Gleichzeitig erscheint die `CuraSnackbar` "Eingetragen." mit Aktion **"Rückgängig"**, 12 dp über dem Button.
4. **Fenster 8 Sekunden.** Der Timer pausiert, solange die Snackbar Fokus hat oder der Zeiger darüber liegt. Bei aktivem Screenreader (`MediaQuery.accessibleNavigation`) läuft kein Timer; die Snackbar bleibt, bis eine Aktion, ein Tabwechsel oder eine andere Snackbar sie beendet.
5. Das Fenster **endet** durch: Ablauf, Wechsel auf den Tab "Pfad", Erscheinen einer anderen Snackbar (z. B. "Entfernt. Rückgängig"), Tageswechsel, Escape/Wegwischen der Snackbar. Danach ist der Eintrag endgültig und "Rückgängig" nicht mehr erreichbar.

**Rückgängig:** Nimmt vollständig zurück: Button wieder "Training starten", Streak und Freeze-Anzeige wie **vor** dem Eintragen (inkl. Zustand "eingefroren", falls vorher so), Unit wieder "aktuell" (nicht erledigt), und die Feier ist gestrichen. Die Snackbar schließt ohne Folgemeldung (der Button zeigt das Ergebnis). Screenreader hört "Eintrag zurückgenommen." Erneutes Eintragen ist normal möglich.

**Reihenfolge von Feier und Rückgängig (Festlegung, damit Manny nicht irritiert):**
- Die Manny-Feier (Pose `feiernd`, Text aus 6.2) und der Ring-Puls der Unit (`dur-slow`) laufen **nicht** auf Heute und **nicht** gleichzeitig mit der Snackbar, sondern erst, wenn der Nutzer das nächste Mal den Tab "Pfad" öffnet, **nachdem** das Fenster geendet hat. Wechselt er während der 8 Sekunden auf den Pfad, endet das Fenster (Punkt 5) und die Feier läuft sofort danach.
- Nach "Rückgängig" gibt es **keine** Feier und keinen Puls. Die Feier verfällt außerdem um Mitternacht, ist also nur am selben Tag ausstehend und zeigt sich höchstens einmal (UI-23).
- Manny feiert also nie etwas, das gleich darauf zurückgenommen wird.

**Texte:** "Eingetragen." · Aktion "Rückgängig". **Screenreader:** Snackbar liest "Eingetragen. Rückgängig, Schaltfläche"; die Aktion heißt "Eintrag rückgängig machen".

### 3.4 V2: Tageswechsel auf "Heute" (nur sichtbare Folgen)

- **Regel für den Nutzer:** Jeder Kalendertag (Gerätezeit, lokales Datum) hat sein eigenes Programm. Tauschen, Entfernen, eigene Übungen und "Heute erledigt" bleiben bis Mitternacht erhalten, auch nach App-Neustart.
- **Erkennen:** Beim Zurückkehren in die App (aus dem Hintergrund) und beim Wechsel auf Heute oder Pfad wird das Datum mit dem zuletzt gesehenen Tag verglichen. Jede Abweichung gilt als Wechsel. Kein Timer um Mitternacht.
- **Was der Nutzer beim Wechsel sieht:**
  - Heute zeigt das neue Datum, das frische Programm (ohne Tagesänderungen des Vortags), und den Button "Training starten" statt "Heute erledigt". Der Wechsel erfolgt ohne Animation (Sofortwechsel, auch bei normaler Bewegung).
  - War Heute dabei sichtbar: Snackbar "Neuer Tag, neues Programm." (ohne Aktion, 5 s). War der Pfad sichtbar, gibt es keine Meldung; die Kopfzeile zeigt den dann gültigen Streak-Zustand (K5).
  - Offene Heute-Sheets und -Dialoge ("Wie willst du trainieren?", "Eigene Übung") werden geschlossen, ein laufendes "Rückgängig"-Fenster endet. Ein halb ausgefüllter "Eigene Übung"-Dialog geht dabei verloren (kleiner Verlust, vermeidet Eintrag auf den falschen Tag). "Deine Daten" bleibt offen und unverändert.
  - Die Tageszähler der Manny-Blasen (höchstens einmal pro Anlass und Tag, UI-23) beginnen neu.
- **Zeitwahl 10/20/30:** bleibt auf dem zuletzt gewählten Wert (Vorliebe, keine Tagesänderung). Nach dem Löschen aller Daten und beim Erststart gilt 20 Min (siehe Rückfrage 2).
- **Screenreader:** Beim Wechsel wird "Neuer Tag. Dein Programm für heute ist neu." angesagt.
- **Reduzierte Bewegung:** unverändert (der Wechsel ist ohnehin sofort).

### 3.5 V5: Tippen auf Pfad-Units

Alle `PathNode`s werden bedienbar (Hit-Area mindestens 48 dp, sichtbarer `focus-ring`, Pressed: Füllung 10 % heller, Enter/Leertaste aktiviert). Ein Tipp auf eine Unit schließt außerdem eine sichtbare Manny-Blase und führt danach die Aktion aus (5.6: Tipp irgendwo schließt die Blase). Manny selbst nimmt keine Tipps an; ein Tipp auf Manny trifft die Unit darunter.

| Zustand | Verhalten | Text |
|---|---|---|
| **Aktuell** | Wechsel auf den Tab "Heute" (Nav zeigt "Heute" aktiv). Gilt auch, wenn heute schon erledigt ist (Heute zeigt dann "Heute erledigt"). | kein Hinweis |
| **Gesperrt** | `NodeHint` über der Unit (wenn oben weniger als 64 dp frei sind: darunter), kein Tabwechsel. | Trainingstag, Wochenziel: "Kommt in Woche N". Phasen-Abschluss und Boss mit Beschriftung: "Phasen-Abschluss kommt in Woche N" bzw. "Return to Sport kommt in Woche N". Liegt die Unit in der laufenden Woche: "Kommt noch diese Woche". Der Ausblick `PathOutlook` (Ergänzung 3) ist keine Unit und hat einen eigenen Text: "Nach Return to Sport geht es hier weiter. Die Details folgen noch." |
| **Erledigt** | `NodeHint`, kein Tabwechsel. | "Erledigt. Das hast du geschafft." |

**Form des Hinweises (Festlegung):** `NodeHint` am Knoten, **nicht** die Manny-Blase und **nicht** eine Snackbar. Begründung: Manny sitzt woanders auf dem Pfad, sodass eine Blase den Bezug zur getippten Unit verliert und mit den Blasen-Anlässen (einmal pro Tag) kollidiert. Eine Snackbar würde die freien Zonen (K2) überdecken. Der `NodeHint` ist opak, verbraucht kein Blur-Budget (nur Nav und eine eventuelle Blase bleiben, also höchstens 2) und steht direkt an der Unit.

**Verhalten des Hinweises:** Höchstens einer gleichzeitig (ein neuer ersetzt den alten). Er schließt durch Tipp irgendwo, Scrollen, Escape/Zurück, Tabwechsel und nach 5 Sekunden; bei aktivem Screenreader nicht automatisch. Er bleibt vollständig im sichtbaren Bereich (mindestens 16 dp Seitenrand, horizontal verschoben, Pfeil bleibt an der Unit). Erscheinen: Einblenden (`dur-fast`); bei reduzierter Bewegung sofort.

**Screenreader-Labels (Ergänzung zu Abschnitt 8):** Unit ist eine Schaltfläche. "Woche 5, Trainingstag 3, aktuell. Öffnet Heute." · "Woche 7, Trainingstag 1, gesperrt." (Aktivieren sagt zusätzlich "Kommt in Woche 7." an) · "Woche 3, Trainingstag 2, erledigt." (Aktivieren sagt "Erledigt. Das hast du geschafft." an) · Boss: "Return to Sport, gesperrt." (Aktivieren: "Return to Sport kommt in Woche 12.").

---

## 4. Querschnitt für alle neuen Elemente

- **Reduzierte Bewegung:** Keine Schiebung, kein Skalieren. Sheet, Dialog, Snackbar, Hinweis und Scrim blenden höchstens `dur-fast` (120 ms) ein oder erscheinen sofort. Neuberechneter Pfad springt ohne Scroll-Animation auf die aktuelle Unit.
- **Hoher Kontrast:** Sheet, Dialog, Snackbar und Hinweis sind `surface-opaque` mit Rand `border-control-hc`, Scrim 72 %, kein Blur, kein Glow. Karten und Felder im Sheet haben ebenfalls opake Füllung und `border-control-hc` (Kontrast wie im Brief 3.1, 4,37:1). `HeaderIconButton` erhält einen Kreisrand.
- **200 % Schrift:** Titel und Texte brechen um, nichts wird abgeschnitten. Sheet-Inhalt scrollt, Kopf und Fußleiste ("Speichern") bleiben sichtbar. Dialogtext scrollt, Buttons bleiben unten. Snackbar: Aktion rutscht unter den Text (rechtsbündig), wenn sie nicht daneben passt (ab Skalierung 1,3 oder zu schmal). `NodeHint` wächst in der Höhe.
- **320 × 568 dp:** Kopfzeile im Umbruch-Layout (3.1). Sheet höchstens 90 % Höhe, Tastatur: Fußleiste bleibt über der Tastatur, fokussiertes Feld scrollt in den sichtbaren Bereich. Dialog Breite Bildschirm minus 32 dp. Kein horizontales Scrollen.
- **Sichtbare Fokusreihenfolge** wie visuell: Sheet: Schließen, Name, Karten (oben nach unten), Datum, Löschen, Speichern. Dialog: Abbrechen, dann Bestätigen. Fokus wird im Sheet und Dialog gehalten und danach an das auslösende Element zurückgegeben. Alle Sheets und Dialoge haben Semantik als eigene Route mit Namen ("Deine Daten", "Alles löschen?", "Änderungen verwerfen?"), Löschen- und Verwerfen-Dialog als `alertdialog`.
- **Kontraste:** Neue Paare: `accent-hi`-Text auf `surface-opaque` 5,60:1, `text-1` auf `surface-opaque` 14,23:1, `text-2` auf `surface-float` ≥ 7,0 (Nav-Wert 7,70). `border-control` auf Glas über `surface-float` im Sheet: grob gerechnet ca. 3,4:1 (Ziel 3). Diese Schätzung ist in den Kontrasttest (UI-3) aufzunehmen und beim Bau zu prüfen.
- **Texte:** Deutsch, "du", kurz, direkt, nie klinisch.

---

## 5. Technische Hinweise

- Betroffen sind die künftigen Dateien von `PathHeader`, `PathNode`, Heute-Seite, Onboarding (Wiederverwendung von `CuraTextField`, `ChoiceCard`, `DateCard`) und die Token-Definition (`scrim`). Das Repo enthält noch keinen Flutter-Code.
- Keine neuen Abhängigkeiten. Datumsauswahl: `showDatePicker` mit eigenem Theme. Ansagen: `SemanticsService.announce` bzw. Live-Region.
- Rückgängig als **Schnappschuss** vor dem Eintragen (Streak-Wert, Freeze-Anzahl und -Zustand, Unit-Zeiger, Erledigt-Flag, ausstehende Feier), den "Rückgängig" zurückspielt. Die Logik bleibt rein Dart und getrennt von der UI.
- Tageswechsel über einen Tagesschlüssel (lokales Datum) im Speicher; Prüfung bei `AppLifecycleState.resumed` und Tabwechsel.
- Löschen leert **alle** lokalen Speicher der App und ersetzt den Navigationsstapel (z. B. `pushAndRemoveUntil`), damit keine veralteten Zustände (Provider, Caches) überleben.
- Geändert-Prüfung ("dirty") im Sheet vergleicht mit den gespeicherten Werten (Name nach Trimmen).
- Blur-Zählung: Nav plus entweder Sheet oder Blase. Dialog, Snackbar und Hinweis haben keinen `BackdropFilter`.

---

## 6. UI-Akzeptanzkriterien (ab UI-37)

**V1 Rückgängig**
- UI-37: Nach "Training eintragen" schließt das Sheet, der Button zeigt "Heute erledigt", und direkt über dem Button steht eine Snackbar "Eingetragen." mit der Aktion "Rückgängig" (Hit-Area ≥ 48 dp).
- UI-38: Tipp auf "Rückgängig" setzt zurück: Button "Training starten", Streak-Zahl, Freeze-Zahl und "eingefroren"-Zustand wie vor dem Eintragen, Unit wieder "aktuell". Beim anschließenden Öffnen des Pfads erscheinen weder Manny-Feier noch Ring-Puls.
- UI-39: Die Snackbar verschwindet nach 8 s (nicht bei aktivem Screenreader, pausiert bei Fokus/Hover). Nach Ablauf, Wechsel auf den Pfad oder Erscheinen einer anderen Snackbar ist "Rückgängig" nicht mehr erreichbar und der Eintrag endgültig.
- UI-40: Manny-Feier und Ring-Puls erscheinen weder auf Heute noch gleichzeitig mit der Snackbar, sondern beim nächsten Öffnen des Pfads nach Ende des Fensters, höchstens einmal und nur am selben Tag.
- UI-41: Die Snackbar ist opak (`surface-opaque`), hat keinen `BackdropFilter`, verdeckt weder Nav noch Primärbutton und liest sich beim Erscheinen vor ("Eingetragen. Rückgängig, Schaltfläche"). Dasselbe Aussehen hat "Entfernt. Rückgängig".

**V2 Tageswechsel**
- UI-42: Nach Umstellen des Gerätedatums auf den Folgetag und Zurückkehren in die App zeigt Heute das neue Datum, ein frisches Programm ohne Tauschen/Entfernen/eigene Übungen des Vortags und "Training starten" statt "Heute erledigt".
- UI-43: Am selben Kalendertag bleiben Tauschen, Entfernen, eigene Übungen und "Heute erledigt" auch nach vollständigem App-Neustart erhalten.
- UI-44: War beim Tageswechsel Heute sichtbar, erscheint die Snackbar "Neuer Tag, neues Programm." ohne Aktion. Offene Sheets und Dialoge der Heute-Seite sind geschlossen, ein laufendes "Rückgängig" ist verfallen, "Deine Daten" bleibt unverändert offen. Der Wechsel hat keine Animation.
- UI-45: Eine am Vortag gezeigte Manny-Blase desselben Anlasses kann am neuen Tag wieder erscheinen. Die Zeitwahl behält den zuletzt gewählten Wert.

**V3 Einstieg und Löschen**
- UI-46: Die Kopfzeile des Pfads zeigt rechts hinter Freeze- und Streak-Pill das Icon "Deine Daten" (Hit-Area ≥ 48 dp, Tooltip, Screenreader "Deine Daten, Schaltfläche"). Auf Heute gibt es keinen solchen Einstieg. Bei 320 × 568 dp und bei 200 % Schrift überlappt oder verkürzt nichts in der Kopfzeile, und alle Angaben aus UI-22 sind sichtbar.
- UI-47: Beim Öffnen von "Deine Daten" schließt eine sichtbare Manny-Blase. Mit Sheet sind höchstens 2 `BackdropFilter` sichtbar (Nav und Sheet), auch bei offenem Dialog, offener Snackbar oder offenem Hinweis.
- UI-48: Das Sheet hat Titel, Schließen-Button (≥ 48 dp), Kopf und Fußleiste bleiben beim Scrollen sichtbar. Es lässt sich mit Zurück/Escape schließen. Der Fokus geht beim Öffnen in das Sheet und beim Schließen zurück auf das Icon.
- UI-49: "Alle Daten löschen und neu starten" ist ein Umriss-Button in `text-1` (weder `accent` noch `status-error`) ganz unten im Scrollbereich. Der Bestätigungsdialog ist opak ohne Blur, "Abbrechen" ist hell gefüllt und hat den Anfangsfokus, "Ja, alles löschen" ist ein Umriss-Button. Im Dialog erscheint weder `accent` noch `status-error`, außer im Fehlerfall (UI-52).
- UI-50: Abbrechen, Zurück, Escape und Tipp auf den Scrim im Löschdialog lassen alle Daten unverändert.
- UI-51: Nach "Ja, alles löschen" zeigt die App Onboarding Schritt 1 ("Schritt 1 von 4", leeres Namensfeld, kein gewählter Typ, kein Datum). Per Zurück erreicht man Pfad oder Sheet nicht wieder. Eine Snackbar "Alle Daten sind gelöscht." erscheint. Nach App-Neustart steht die App weiterhin bei Schritt 1. Schritt 2 (Datenschutz) muss neu bestätigt werden, und nach erneutem Onboarding sind Streak, Pfadfortschritt und Tagesänderungen auf Ausgangswerten.
- UI-52: Schlägt das Löschen fehl, zeigt der Dialog `status-error`-Icon plus Text "Das Löschen hat nicht geklappt. Versuch es nochmal." und den Button "Nochmal versuchen". Dauert das Löschen über 300 ms, zeigt der Bestätigungsbutton einen Fortschrittskreis und ist deaktiviert.

**V4 Profil ändern**
- UI-53: Das Sheet zeigt Name (`CuraTextField`), vier `ChoiceCard`s (aktueller Typ mit Haken und 2 dp Rand gewählt, bei "Anderes" der Freitext vorbefüllt) und die Datumskarte (gespeichertes Datum, nur Datum bis heute wählbar). Es sind dieselben Widgets wie im Onboarding (Code-Review: keine kopierten Varianten). Kein Manny und keine Mikrofon-Zeile im Sheet.
- UI-54: "Speichern" ist deaktiviert, solange nichts geändert wurde oder der Name (nach Trimmen) leer ist.
- UI-55: Nach "Speichern" schließt das Sheet. Der neue Name steht sofort in "Heute, [Name]". Bei geändertem Typ oder Datum zeigt die Kopfzeile neue Woche/Phase und der Pfad ist neu berechnet, die aktuelle Unit ist ungefähr zentriert (UI-21). Streak-Zahl, Freeze-Zahl und die Heute-Tagesänderungen sind unverändert.
- UI-56: Im Sheet steht dauerhaft der Hinweis "Ändern sich Verletzung oder Datum, werden Woche, Phase und Pfad neu berechnet. Dein Streak bleibt."
- UI-57: Schließen mit ungespeicherten Änderungen öffnet "Änderungen verwerfen?" mit "Weiter bearbeiten" (Anfangsfokus, hell) und "Verwerfen" (Umriss). Ohne Änderungen schließt das Sheet direkt. "Verwerfen" setzt die Felder zurück, ohne zu speichern.
- UI-58: Bei eingeblendeter Tastatur auf 320 × 568 dp bleibt "Speichern" sichtbar, und das fokussierte Feld ist sichtbar.

**V5 Pfad-Tipps**
- UI-59: Tipp auf die aktuelle Unit (auch auf Manny darüber) wechselt auf den Tab "Heute"; die Nav zeigt "Heute" aktiv. Eine sichtbare Manny-Blase schließt dabei.
- UI-60: Tipp auf eine gesperrte Unit zeigt einen `NodeHint` mit "Kommt in Woche N" (N = Woche dieser Unit; bei Phasen-Abschluss und Boss mit Beschriftung, in der laufenden Woche "Kommt noch diese Woche") und wechselt nicht den Tab.
- UI-61: Tipp auf eine erledigte Unit zeigt den `NodeHint` "Erledigt. Das hast du geschafft." und wechselt nicht den Tab.
- UI-62: Der `NodeHint` ist opak, ohne Blur, höchstens einer gleichzeitig, vollständig im sichtbaren Bereich (≥ 16 dp Seitenrand), bricht bei 200 % Schrift um. Er schließt durch Tipp irgendwo, Scrollen, Escape und nach 5 s (nicht bei aktivem Screenreader).
- UI-63 (gilt sinngemäß auch für den Ausblick, siehe UI-91 bis UI-93 in Ergänzung 3): Jede Unit hat Hit-Area ≥ 48 dp, sichtbaren `focus-ring`, ist mit Enter/Leertaste auslösbar und liest die Labels aus 3.5 vor. Die Freien Zonen unten links/rechts (UI-24) sind weiterhin frei, weil auf dem Pfad keine Snackbar erscheint.

**Querschnitt**
- UI-64: Mit "Bewegung reduzieren" haben Sheet, Dialoge, Snackbar, Hinweis und Scrim keine Schiebe- oder Skalieranimation und höchstens 120 ms Einblenden. Der neu berechnete Pfad springt ohne Animation.
- UI-65: Bei "Hoher Kontrast" sind Sheet, Dialoge, Snackbar und Hinweis opak (`#1B2129`) mit Rand `border-control-hc`, Scrim 72 %, ohne Blur und Glow. Der Icon-Button hat einen sichtbaren Kreisrand.
- UI-66: Bei 200 % Systemschrift und bei 320 × 568 dp ist jede neue Funktion erreichbar: Sheet scrollt, "Speichern" bleibt sichtbar, Dialogbuttons bleiben sichtbar, die Snackbar-Aktion ist erreichbar, kein horizontales Scrollen, nichts abgeschnitten.
- UI-67: Neue Elemente nutzen nur Tokens (`scrim` neu). Im Code verwendet kein Handlungselement `status-error`, `cat-frist` oder `tri-*`, und `accent`/`accent-hi` steht nicht für Status oder Warnung (erweitert UI-17 auf die neuen Elemente).
- UI-68: Alle neuen Elemente sind per TalkBack/VoiceOver und Tastatur vollständig bedienbar. Sheets und Dialoge haben einen Routennamen, Fokus wird beim Schließen zurückgegeben, Ansagen aus 3.2, 3.3 und 3.4 werden vorgelesen.
- UI-69: Alle neuen sichtbaren Texte sind Deutsch, in "du"-Form und im Ton der Spec.

---

## 7. Annahmen

1. "Deine Daten" ist nur vom Tab "Pfad" aus erreichbar (Vorschlag der Vollständigkeitsprüfung).
2. Gerätezeit und lokales Datum bestimmen den Kalendertag. Eine Zeitzonenänderung wird wie ein Datumswechsel behandelt.
3. Das Löschen erfasst "alle lokalen Daten" (Liste in 3.2). Es gibt kein Backend und keinen Export.
4. Eine Bestätigung genügt (kein Eintippen eines Wortes), weil der Prototyp nur lokal arbeitet und nichts Echtes verliert.
5. Die Weeknummer N eines gesperrten Knotens ist aus dem Pfadmodell bekannt (die Pfad-Einheit ist die Woche, Spec 3). Der Beispielpfad bleibt als solcher gekennzeichnet.
6. `person_outline_rounded` als Icon ist ein Vorschlag, jedes gleichwertige Profil-Icon im selben Stil ist zulässig.

## 8. Offene Entscheidungen und Rückfragen

**Nutzerentscheidungen bei Freigabe (2026-10-07):** Punkt 1 → Vorschlag (Pfad neu berechnet, Streak bleibt). Punkt 2 → Vorschlag (letzte Zeitwahl bleibt). Punkt 3 → Vorschlag (Feier erst beim nächsten Pfad-Besuch). Punkte 4–6 wie beschrieben. Zu Punkt 7 separat entschieden: Auto-Freeze bei 1 verpasstem Tag verbraucht 1 Freeze (ohne Freeze Reset beim 2. verpassten Tag); "abends" = ab 18:00 Uhr; Android-Zurück: auf Heute → Pfad, auf Pfad → App schließen (offene Sheets/Blasen/Hinweise zuerst), im Onboarding ein Schritt zurück.

1. **Erledigte Units und Streak bei Änderung von Verletzung oder Datum.** Vorschlag: Streak bleibt, Pfad wird aus den neuen Angaben neu berechnet (Haken vor der aktuellen Woche, einzelne Trainingstage werden nicht übertragen). Alternative: erledigte Units strikt behalten und nur die Wochenanzeige ändern. *Auswirkung:* Alternative kann zu Pfadständen führen, die nicht zum Datum passen. Der Hinweistext in 3.2 und UI-55/UI-56 hängen daran.
2. **Zeitwahl nach Tageswechsel.** Vorschlag: bleibt auf dem zuletzt gewählten Wert; 20 Min gilt nur beim Erststart und nach dem Löschen. Brief 6.3/UI-26 ("20 vorgewählt") wird dann so gelesen: Grundwert beim Erststart. Alternative: täglich zurück auf 20. *Auswirkung:* Vorschlag entspricht Erwartung von Vieltrainierenden, Alternative folgt UI-26 wörtlich.
3. **Zeitpunkt der Manny-Feier (Präzisierung zu 6.3/UI-30).** Brief nennt Feier nach Eintragen, aber nicht wo. Festlegung hier: erst beim nächsten Öffnen des Pfads nach dem Rückgängig-Fenster. UI-30 bleibt unverändert gültig (Streak und Unit sofort). Alternative: sofort auf Heute (kollidiert mit Rückgängig). Bitte bestätigen.
4. **Rückgängig-Fenster endet beim Wechsel auf den Pfad.** Alternative: Fenster läuft 8 s unabhängig vom Tab (bräuchte eine Snackbar auf dem Pfad und verletzt die freien Zonen, UI-24). Vorschlag bleibt, weil er die Zonen schützt.
5. **Kopfzeile 5.9 erweitert** (Icon, Umbruch bei Enge). Kein Kriterium aus UI-1 bis UI-36 wird geändert; UI-22 bleibt erfüllt.
6. **Snackbar-Gestaltung** ist im Brief v1 nirgends definiert. Die Definition hier gilt auch für die bestehende "Entfernt. Rückgängig"-Meldung (rein optische Festlegung).
7. *Nicht zu klären hier* (Orchestrator mit Nutzer): Streak-Freeze-Logik, Uhrzeit "abends", Zurück-Taste auf Tabs und Schritt 1. Diese Ergänzung legt dazu nichts fest.

Keine der Fragen blockiert den Start; für jede gilt bis zur Klärung der genannte Vorschlag.

## 9. Nicht enthalten

Hilfe und Feedback-Funktion, Benachrichtigungs-Einstellungen, Konto, Export, Anzeige oder Änderung der Einwilligung außer Löschen, Datenschutzerklärung im Sheet, Streak-Freeze- und "abends"-Logik, Android-Zurück-Verhalten, Snackbar auf dem Pfad, Rückgängig für andere Aktionen als "Training eintragen" und "Entfernen", Sheet-Einstieg auf dem Tab Heute.
