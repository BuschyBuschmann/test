# Design-Brief v1: CuraOne, erster Ausschnitt (Onboarding, Pfad, Heute)

Status: FREIGEGEBEN (2026-10-07) · Umsetzung: `flutter-developer` · Quellen: Spec 1, 2, 3 (Spec 4, 5, 7, 8 nur dort, wo ausdrücklich genannt)
Basis: Grunddesign v2 (dunkel, Glas, vom Nutzer freigegeben), mit der Änderung "Akzent Orange-Rot, dunkler und edler".
Referenzbilder (nur Orientierung, kein Pixel-Vorbild): `docs/design/mockups/pfad-v3.png` und `docs/design/mockups/heute-v3.png`.

---

## 1. Nutzerziel und wichtigste Aktionen

Der Nutzer ist ein rehabender (Hobby-)Sportler mit einem Kreuzbandriss. Er soll
1. in unter 3 Minuten per Tap seine Situation eingeben (Onboarding) und sich dabei begleitet fühlen, nicht wie bei einem Formular,
2. beim Öffnen sofort sehen, wo er auf seinem Reha-Pfad steht und wie lang sein Streak ist,
3. wissen, was er heute tun soll (Zeit wählen, Übungen sehen, anpassen) und das Training als erledigt eintragen.

Ton in allen Texten: direkt, menschlich, motivierend, "du". Nie klinisch, kein Juristendeutsch, Humor dosiert.

## 2. Gestaltungsrichtung (Kurzfassung)

Dunkel, ruhig, hochwertig. Anthrazit-Blau als Grund, warm-weißer Text, ein einziger Akzent in gebranntem Kupfer-Orange für Handlung und Fortschritt, dezenter Lichtschein in den Ecken, halbtransparente Glas-Flächen mit feinem Rand, schwebende Pill-Navigation. Manny ist ein flaches, reduziertes Emblem in Schiefer-Blau. Bewusst vermieden: dünne kontrastschwache Typo, Glow hinter Text, Orange/Rot-Flächen mit medizinischer Bedeutung, Blur auf jeder Karte, Bounce-Optik.

---

## 3. Design-Tokens

Alle Werte sind als **Semantik-Tokens** zu implementieren (z. B. als `ThemeExtension`), nicht als verstreute Hex-Werte, damit später ein heller Modus ergänzt werden kann. Komponenten verwenden nur Tokens. Kontraste sind nach WCAG 2.x (relative Luminanz, sRGB) berechnet. "Glas" bedeutet die ungünstigste Stelle der Glas-Füllung (`#22272D`, Weiß 8,5 % über Grund).

### 3.1 Farben (Dunkel)

| Token | Wert | Verwendung |
|---|---|---|
| `bg` | `#0E131A` | Screen-Grund |
| `surface-glass-top` / `-bottom` | Weiß 8,5 % / 4 % über `bg` (ca. `#22272D` / `#181C23`) | Glas-Karte, Verlauf von oben nach unten |
| `surface-float` | `#18202A` mit 82 % Deckkraft (ca. `#161E27` auf `bg`) | Nav, Sprechblase, Sheets (mit Blur) |
| `surface-opaque` | `#1B2129` | Ersatz für Glas/Float bei hohem Kontrast |
| `border-hair` | Weiß 14 % | Rand von Karten (dekorativ, nicht allein Träger einer Bedienung) |
| `border-control` | Weiß 40 % | Rand von bedienbaren Feldern (Eingabefeld, nicht gewählte Auswahlkarte, Chip) |
| `border-control-hc` | Weiß 45 % auf `surface-opaque` | wie oben im Modus hoher Kontrast |
| `text-1` | `#F2F0EB` | Haupttext |
| `text-2` | `#A9B0BC` | Sekundärtext |
| `text-3` | `#9AA2AF` | Tertiärtext (nur 13 sp und größer, nicht auf Glow) |
| `accent` | `#D9622B` ("Kupfer") | Füllung primärer Buttons, aktuelle Pfad-Unit, Ringe, Fortschritt |
| `accent-hi` | `#E8794A` | Akzent als Icon/Streak-Flamme/Rand auf dunklem Grund, Pressed-Zustand der Füllung |
| `accent-soft` | `accent` mit 16 % Deckkraft | Hintergrund gewählter Chips, aktiver Tab, gewählter Karten |
| `on-accent` | `#0E131A` | Text und Icons auf `accent` |
| `focus-ring` | `#F2F0EB`, 2 dp, 2 dp Abstand | Tastatur- und Switch-Fokus |
| `cat-physio` | `#5B9DFF` | Kategorie Physio (Spec 2, Blau) |
| `cat-arzt` | `#A98BFF` | Kategorie Arzt (Spec 2, Lila) |
| `cat-uebung` | `#3DDC97` | Kategorie Übungen (Spec 2, Grün) |
| `cat-frist` | `#FF5C70` | Kategorie Fristen (Spec 2, Rot) |
| `tri-gruen` / `tri-gelb` / `tri-orange` / `tri-rot` | `#3DDC97` / `#F7E04A` / `#FFA62B` / `#FF5C70` | Triage (Spec 4), im ersten Ausschnitt nur als Token reserviert |
| `status-error` | `#FF5C70` (gleich `tri-rot`) | Fehlerzustände, immer mit Icon und Text |
| `streak-freeze` | `#8FBBFF` | Streak-Freeze-Symbol |
| `glow-ember` | `#FF6A3D` | nur Hintergrund-Lichtschein |

Hinweis: Kategorie- und Triage-Farben sind in Spec 2 und Spec 4 als Beispiele ("z. B.") genannt. Die hier gewählten Töne sind ein Vorschlag, aufgehellt für Dunkel. Die Zuordnung (Physio blau, Arzt lila, Übungen grün, Fristen rot) bleibt wie in der Spec.

**Gemessene Kontraste (Verhältnis):**

| Kombination | auf `bg` | auf Glas | Mindestziel |
|---|---|---|---|
| `text-1` `#F2F0EB` | 16,37 | 13,21 | 4,5 |
| `text-2` `#A9B0BC` | 8,54 | 6,89 | 4,5 |
| `text-3` `#9AA2AF` | 7,24 | 5,85 | 4,5 |
| `accent` `#D9622B` | 5,09 | 4,11 | 3 (Fläche/Icon), 4,5 (Text, nur auf `bg`) |
| `accent-hi` `#E8794A` | 6,45 | 5,20 | 4,5 (Text) / 3 (Icon) |
| `cat-physio` | 6,84 | 5,52 | 4,5 |
| `cat-arzt` | 6,94 | 5,60 | 4,5 |
| `cat-uebung` | 10,55 | 8,51 | 4,5 |
| `cat-frist` / `tri-rot` | 6,23 | 5,03 | 4,5 |
| `tri-orange` | 9,53 | 7,69 | 4,5 |
| `tri-gelb` `#F7E04A` | 13,95 | (nicht auf Glas verwendet) | 4,5 |
| `on-accent` auf `accent` | 5,09 | | 4,5 (Buttontext 18 sp, 600) |
| `on-accent` auf Pressed `#DD7240` | 5,82 | | 4,5 |
| `border-control` (Weiß 40 %) | 3,80 | 3,64 | 3 |
| `text-1` auf `accent-soft`-Fläche (Auswahl) | 11,03 | | 4,5 |
| `accent-hi` Icon auf `accent-soft`-Fläche | 4,35 | | 3 |
| `text-1` auf Nav-aktiv (`accent-soft`) | 12,30 | | 4,5 |
| `text-2` auf Nav `#161E27` | 7,70 | | 4,5 |
| Manny: Rand (Weiß 35 %) auf `bg` | 3,22 | | 3 |
| Manny: Bauch `#F2F0EB` auf Körper `#34425F` | 8,82 | | 3 |
| Triage-Karte (Tönung 18 %): `text-1` | grün 11,36 · gelb 10,49 · orange 11,77 · rot 13,05 | | 4,5 |
| `text-1` / `text-2` / `accent-hi` auf `surface-opaque` | 14,23 / 7,42 / 5,60 | | 4,5 |

Folgerungen (verbindlich):
- Akzent als **Text** nur auf `bg` oder `surface-opaque` (5,09 bzw. 5,60+). Auf Glas als Text immer `accent-hi` (5,20) oder `text-1`. (siehe Erratum E-2: für `surface-opaque` korrigiert, dort gilt `accent-hi`)
- Beschriftungen in `accent-soft`-Flächen sind immer `text-1`. Der Akzent erscheint dort nur als Icon (4,35 ≥ 3) und als Rand.
- Der Körper von Manny (`#34425F`) hat auf `bg` nur 1,86:1. Er ist deshalb nie ohne Rand (Weiß 35 %, 1 dp) und weißen Bauch zu zeichnen.

### 3.2 Glow-Regeln (Lichtschein)

- Zwei weiche Radialverläufe in `glow-ember` hinter dem gesamten Inhalt: oben links (Mitte -30, 40 dp, Radius 260 dp, Spitze 24 % Deckkraft, bei 70 % des Radius null) und unten rechts (Mitte 50 dp rechts neben und 24 dp über dem unteren Bildschirmrand, Radius 300 dp, Spitze 14 %).
- Rein dekorativ: `ExcludeSemantics`, nie interaktiv, nie als Statusfarbe.
- Statisch im ersten Ausschnitt (keine Atmung/Animation). Einmal als gecachte Ebene (`RepaintBoundary`) pro Screen, nicht pro Karte.
- (siehe Erratum E-1: Glow-Regel nach Untergrund, ersetzt die Abstandsregel) Maximal 16 % effektive Deckkraft dort, wo Text liegt. Das ist erfüllt, wenn Text mindestens 70 dp vom Mittelpunkt entfernt steht (Deckkraft dort ≤ 0,15). Gemessen: `text-2` über Glas über 16 % Glow hat noch 5,35:1.
- Farbiger Text (Kategorie-Label, `text-3`) nur dort, wo der Glow höchstens 12 % beträgt (Abstand zum Mittelpunkt ≥ 91 dp). Das ist die Regel, damit z. B. Physio-Blau auf Glas über Glow nicht unter 4,5:1 fällt (bei 16 % wären es 4,29).
- Der Glow wird auf Screens mit Triage-Ergebnis oder Fristen-Detail **ausgeschaltet** (siehe Abschnitt 4).

### 3.3 Typografie

Fonts: **Bricolage Grotesque** (Überschriften, Zahlen) und **DM Sans** (Text). Beide als Asset in der App bündeln (OFL-Lizenz prüfen und mitliefern), **kein** Laden zur Laufzeit.

| Token | Font | Größe/Zeilenhöhe (sp) | Gewicht | Verwendung |
|---|---|---|---|---|
| `display` | Bricolage | 32/36 | 500 | Screen-Titel ("Heute, Jakob") |
| `title` | Bricolage | 24/28 | 500 | Kopfzeile "Woche 5", Onboarding-Frage |
| `heading` | Bricolage | 18/24 | 500 | Kartentitel |
| `numeral` | Bricolage | 20/24 | 600 | Streak-Zahl, Uhrzeit (24/28) |
| `button` | Bricolage | 18/24 | 600 | Primärbutton |
| `body` | DM Sans | 16/24 | 400 | Fließtext |
| `body-strong` | DM Sans | 16/24 | 600 | Hervorhebung |
| `secondary` | DM Sans | 14/20 | 500 | Meta-Angaben |
| `label` | DM Sans | 13/16 | 600, Großbuchstaben, Laufweite 0,06 em | Abschnittstitel |
| `caption` | DM Sans | 13/16 | 500 | Pfad-Beschriftungen |

Regeln: Nichts unter 13 sp. Kein Schriftgewicht unter 400. Systemseitige Schriftgrößen werden unterstützt (siehe UI-Kriterien). Zeilenumbruch statt Abschneiden, Ausnahme nur mit Tooltip-Alternative für einzelne Labels.

### 3.4 Abstände, Radien, Größen

- Raster 4 dp: `space-1 = 4`, `2 = 8`, `3 = 12`, `4 = 16`, `5 = 20`, `6 = 24`, `8 = 32`, `10 = 40`. Seitenrand 16 dp.
- Radien: `radius-card = 24`, `radius-pill = 999`, `radius-chip-inner = 12`, `radius-sheet = 28` (oben), `radius-icon-tile = 7`.
- Touch-Ziele: mindestens 48 × 48 dp für alles Antippbare, auch wenn es kleiner aussieht (Hit-Area vergrößern). Abstand zwischen Zielen mindestens 8 dp.
- Nav: 64 dp hoch, 16 dp Abstand zu den Seiten, 22 dp zum unteren Rand (plus Safe Area). Aktiver Tab: Pill 48 dp hoch.
- Primärbutton: 56 dp hoch, volle Pill. Chip/Segment: 48 dp hoch.

### 3.5 Elevation und Glas

| Ebene | Aufbau |
|---|---|
| E0 Grund | `bg` plus Glow |
| E1 Glas-Karte | Verlauf `surface-glass-top` zu `-bottom`, Rand `border-hair` 1 dp, innere Lichtkante oben (Weiß 10 %, 1 dp), **kein Blur**, kein Schatten |
| E2 Schwebend (Nav, Sprechblase, Sheet) | `surface-float`, Blur σ = 16, Rand `border-hair`, Schatten 0/10/30 dp Schwarz 45 % (nur Nav und Sheet) |
| Primär-Button | Füllung `accent`, Schein 0/8/28 dp `accent` 28 % |
| Hoher Kontrast | Alle E1/E2 werden zu `surface-opaque`, Rand `border-control-hc`, kein Blur, kein Glow |

**Blur-Budget:** höchstens **2** `BackdropFilter` gleichzeitig sichtbar pro Screen (Nav plus Sprechblase oder Sheet). Karten, Chips und Listenelemente nutzen nie Blur. Kein Blur innerhalb scrollender Listen pro Element.

### 3.6 Motion

| Token | Wert |
|---|---|
| `dur-fast` | 120 ms |
| `dur-base` | 200 ms |
| `dur-slow` | 320 ms |
| `curve` | `easeOutCubic` |

Verwendete Animationen im ersten Ausschnitt: Seitenwechsel im Onboarding (Schiebung 24 dp und Einblenden, `dur-base`), Sprechblase (Einblenden plus 8 dp Schiebung, `dur-base`), Unit-Abschluss (einmaliger Ring-Puls, `dur-slow`), Auswahlkarte (Randwechsel, `dur-fast`). Keine Dauerschleifen, keine Bounce-Kurven. Die Manny-Animationen (Spec 3) sind eine externe Abhängigkeit und im Platzhalter nicht enthalten.

**Reduzierte Bewegung** (`MediaQuery.disableAnimations`): alle Schiebungen und Pulse entfallen, Zustandswechsel sind Sofortwechsel oder ein Überblenden von höchstens `dur-fast`. Der Pfad scrollt weiterhin normal. Manny zeigt statische Posen. (siehe Erratum E-3)

---

## 4. Konflikt (b): Akzent Orange-Rot gegenüber Triage und Fristen

**Problem.** Der vom Nutzer gewählte Akzent ist orange-rot. Orange und Rot haben in der App aber medizinische Bedeutung: Triage-Orange ("Pausieren") und -Rot ("Sofort zum Arzt") (Spec 4) und Fristen-Rot (Spec 2). Ein Akzent in dieser Farbfamilie darf nie mit einer Warnung verwechselt werden, und eine Warnung nie wie ein normaler Button aussehen.

**Lösung (die Akzentfarbe bleibt wie vom Nutzer gewählt).**

1. **Rolle trennen.** Der Akzent bedeutet ausschließlich "Handlung und Fortschritt": primäre Buttons, aktueller Pfadpunkt, Streak, aktiver Tab, Fortschrittsbalken. Er bedeutet nie Status, Warnung, Fehler oder Frist. Für Status gibt es eigene Tokens (`status-error`, `cat-frist`, `tri-*`), und die dürfen nicht für Handlung verwendet werden.
2. **Farbton abstufen.** Der Akzent ist ein gebranntes Kupfer (Farbton ca. 19°). Triage-Orange ist ein helles Bernstein-Orange (ca. 35°), Triage-Rot und Frist-Rot sind ein kühles Rosé-Rot (ca. 353°), jeweils deutlich heller als der Akzent. Der Akzent liegt damit zwischen beiden und ist bewusst gedeckter. Triage-Gelb ist ein Zitronengelb (ca. 52°).
3. **Form und Beschriftung tragen die Bedeutung, nicht die Farbe.**
   - Triage-Ergebnis: eine opake, mit 18 % getönte Karte (Tönung in der Ergebnisfarbe), großes Symbol, Klartext-Label ("Normal", "Vorsicht", "Pausieren", "Sofort zum Arzt"), Stufenanzeige "1 von 4" bis "4 von 4" als vier Segmente. Farbe ist nie das einzige Signal.
   - Fristen: Kartenstreifen in `cat-frist`, Uhr-Icon und Label "Frist". Nie ein Akzent-Streifen.
   - Fehler: `status-error` mit Warn-Icon und Text.
4. **Keine Akzent-Elemente im Warnkontext.** Auf dem Triage-Ergebnis und in Frist-Details gibt es keinen Akzent-Button. Dort sind Aktionen neutral (heller Button `text-1` mit `on-accent`-Text, 16,37:1, oder Umriss-Button mit `border-control`). Der Glow wird in diesen Screens ausgeschaltet. So kann ein Nutzer in einer Warnsituation Orange/Rot nur noch als Bedeutung lesen.
5. **Keine Glas-/Glow-Hintergründe unter Warnungen.** Triage-/Fristen-Karten sind opak, damit der orange Lichtschein ihre Farbe nicht verfälscht.
6. **Prüfbar.** Siehe UI-17 bis UI-19 (Rollenregel, Graustufentest, Farbsehschwächen-Simulation).

Im ersten Ausschnitt gibt es weder Triage noch Fristen. Die Tokens und diese Regeln sind jetzt festgelegt, damit die spätere Umsetzung nicht gegen den Akzent arbeiten muss. Der Akzent selbst ist bereits im ersten Ausschnitt im Einsatz.

---

## 5. Komponenten

Alle Komponenten erhalten Screenreader-Labels (siehe Abschnitt 8) und sichtbaren Fokuszustand (`focus-ring`). Pressed-Zustand: Füllung hellt um 10 % auf (nicht abdunkeln, damit der Kontrast steigt). Disabled: Inhalt `text-1` mit 38 % Deckkraft (3,28:1, nur für wirklich deaktivierte Elemente), Füllung Weiß 10 %.

### 5.1 Glas-Karte (`GlassCard`, neu)
Zweck: Container für Inhalt. Aufbau E1 (3.5), Radius 24, Innenabstand 16 (links 22, wenn Kategorie-Streifen). Kein Blur.

### 5.2 Kategorie-Karte (`CategoryCard`, neu, baut auf 5.1)
Inhalt: 4 dp Streifen links in Kategoriefarbe (14 dp Abstand oben und unten, Enden rund), Icon-Kachel (20 dp, Radius 7, gefüllt mit Kategoriefarbe, Icon in `on-accent`-Dunkel) plus Label in Kategoriefarbe (13 sp, 600) plus Titel (`heading`), Meta (`secondary`). Rechts optional Uhrzeit (`numeral`, 24 sp). Optionale Aktionsleiste (siehe 5.3).
Kategorie wird durch Streifen **und** Icon **und** Label gezeigt.

### 5.3 Pill-Button und Chip (`PillButton`, `CuraChip`, neu)
- **Primär:** Füllung `accent`, Text `on-accent`, `button`-Stil, 56 dp, Icon optional links.
- **Sekundär (Aktionschip):** Füllung Weiß 7 %, `text-1`, 36 dp sichtbar, Hit-Area 48 dp (Beispiele: "Tauschen" mit Pfeile-Icon, "Entfernen" mit X-Icon).
- **Segment (Zeitwahl):** 48 dp, Pill, nicht gewählt: Glas-Füllung, Rand `border-control`, Text `text-2`; gewählt: `accent-soft`-Füllung, 1,5 dp Rand `accent-hi`, Text `text-1` Gewicht 700.
- **Gestrichelte Aktion** ("+ Eigene Übung"): 48 dp, Rand gestrichelt `border-control`, Text `text-1`.

### 5.4 Schwebende Navigation (`FloatingNav`, neu)
Pill-Leiste E2, 64 dp, zwei Einträge im ersten Ausschnitt: **Pfad** und **Heute** (Icon plus Label, immer beide sichtbar). Aktiv: Pill 48 dp mit `accent-soft` und 1 dp Rand `accent` (60 %), Icon `accent-hi`, Label `text-1`. Inaktiv: Icon und Label `text-2`. Inhalt scrollt darunter durch und blendet unten mit Verlauf in `bg` aus. Nav ist ab einer Textskalierung über 1,3 auf diesen Wert begrenzt (Labels), der Rest wächst normal.

### 5.5 Pfad-Units (`PathNode`, neu)
Größen (Durchmesser): klein 48 dp (Trainingstag), mittel 60 dp (Wochenziel), groß 72 dp (Phasen-Abschluss), Boss 92 dp (Return to Sport). Zustände:

| Zustand | Aussehen |
|---|---|
| Erledigt | Füllung `text-1`, dunkler Haken (`on-accent`-Dunkel), Verbindungslinie dahinter hell (`text-1`, 3 dp, rund) |
| Aktuell | Füllung `accent`, Flaggen-Icon in `on-accent`, äußerer Ring 1,5 dp `accent` 40 % im Abstand 9 dp, weicher Schein (Radialverlauf `accent` 50 %) |
| Gesperrt | `bg` plus Glas-Füllung, Rand Weiß 20 %, Schloss-Symbol Weiß 50 % (4,87:1) |
| Boss gesperrt | wie Gesperrt, Rand `accent` 55 %, Stern `accent-hi` |
| Groß gesperrt | wie Gesperrt, Stern Weiß 50 % |

Beschriftung unter großen und Boss-Units sowie mittleren (`caption`, `text-3`). Zukünftige Strecke: gepunktete Linie Weiß 22 %, 3 dp. Der Pfad ist geschwungen (Kurve durch alternierende Positionen links/rechts, keine gerade Linie), vertikal scrollend, Zukunft oben.

### 5.6 Manny-Platzhalter und Sprechblase (`MannyPlaceholder`, `MannyBubble`, neu)
- **Manny:** Flutter-Formen (`CustomPainter`): Körper `#34425F` mit Rand Weiß 35 % (1 dp), Flügel, weißer Bauch `#F2F0EB`, zwei weiße Augen mit dunklen Pupillen, Schnabel und Füße in `accent-hi`. Drei Posen als Parameter (`neutral`, `motiviert`, `feiernd`), statisch. Höhe auf dem Pfad ca. 80 dp, im Onboarding 56–64 dp, in der Sprechblase nicht enthalten. Eine spätere Illustration ersetzt nur dieses Widget.
- **Sprechblase:** E2, Radius 20, Text `body` 14,5 sp aufwärts (nicht kleiner als 14), maximal 2 Sätze (Spec 3), X-Button oben rechts (Hit-Area 48 dp). Tap irgendwo auf Blase oder Hintergrund schließt sie ebenso. Platzierung: rechts neben Manny mit Pfeil nach links. Wenn rechts weniger als 140 dp Platz ist (schmale Displays), oberhalb von Manny, Breite max. 280 dp.
- Manny und Blase sind nie modal. Nichts wird blockiert.

### 5.7 Onboarding-Auswahlkarte (`ChoiceCard`, neu)
Glas-Karte (E1), volle Breite, mindestens 64 dp hoch, Text `heading`, optional Untertitel `secondary`. Nicht gewählt: Rand `border-control`. Gewählt: Füllung `accent-soft`, 2 dp Rand `accent-hi`, Haken-Icon rechts (zusätzlich zur Farbe). Escape-Hatch-Karte "Anderes / selbst eingeben" mit Stift-Icon. Einfachauswahl.

### 5.8 Fortschrittsanzeige (`StepProgress`, neu)
Text "Schritt X von 4" (`secondary`, `text-2`) plus segmentierter Balken (4 Segmente, 4 dp hoch, Abstand 4 dp). Erledigt und aktuell: `accent`; offen: Weiß 18 %. Der Text trägt die Information, der Balken ergänzt (Screenreader liest nur den Text).

### 5.9 Weitere Bausteine
Kopfzeile Pfad (`PathHeader`): links "Woche N" (`title`) und "Phase M · Kreuzband" (`secondary`), rechts Freeze-Pill (Schneeflocke plus Zahl, `streak-freeze`) und Streak-Pill (Flamme `accent-hi` plus Zahl `numeral`). Eingabefeld (`CuraTextField`): 56 dp, Rand `border-control`, Fokus `accent-hi` 2 dp, Label oberhalb, `body`. Mikrofon-Button (`MicButton`): 56 dp Kreis, Glas, Rand `border-control`, Mikrofon-Icon `text-1`.

---

## 6. Screens und Zustände

### 6.0 Umfang des ersten Ausschnitts (Vorschlag mit Begründung)

| Bereich | Im Ausschnitt? | Begründung |
|---|---|---|
| Spec 1 Schritt 1 (Manny und Name) | Ja | trägt die Ansprache mit Namen |
| Spec 1 Schritt 2 (Consent) | Ja, Oberfläche und lokales Speichern (Zeitstempel, Version `prototype-0`) | Pflichtschritt der Spec. **Der Erklärtext ist Platzhalter und muss vor einem echten Einsatz juristisch freigegeben werden (Datenschutz-Konzept, Anwalt).** |
| Spec 1 Schritt 3 (Verletzungstyp) | Ja, alle vier Karten | ACL ist der erste Typ, die anderen vier Optionen stehen in der Spec |
| Spec 1 Schritt 4 (Datum) | Ja | liefert Woche und Phase für den Pfad (Ableitung als Platzhalter, siehe 6.2) |
| Spec 1 Schritt 5 (Dokument-Upload) | **Nein**, nicht im Ausschnitt | braucht Kamera, Dateiauswahl und Lesbarkeitsprüfung (KI), also Backend |
| Spec 1 Schritt 6 (Dein Team) | **Nein**, nicht im Ausschnitt | braucht Google Places (API-Key, Kosten, Kontakt-Datenmodell) |
| Chat und Sprachmemo "Noch etwas hinzufügen?" bei jedem Schritt | **Nur Platzhalter**: Mikrofon-Button und Zeile sind sichtbar, Antippen zeigt Manny-Hinweis "Das kann ich bald, heute noch nicht." | Spec verlangt, dass das Mikro immer sichtbar ist. Funktion braucht Spracherkennung und KI (Spec 7) |
| Manny-Einführungsanimation | Statisches Bild (Platzhalter) | externe Abhängigkeit |
| Spec 3 Pfad, Manny, Streak | Ja, mit Platzhalterdaten | Kern des Ausschnitts |
| Spec 3 Motivierende Fakten und Manny-Nachrichten | Ja, mit **festen Beispieltexten** statt KI/Physio-Pool | Fakten-Pool und KI sind Abhängigkeiten |
| Spec 3 Streak-Logik | Anzeige und einfache Regeln, Details siehe 6.2 | Ruhetage/Physio-Tage hängen am Kalender (nicht im Ausschnitt) |
| Spec 3 Push-Benachrichtigungen | Nein | eigene Abhängigkeit |
| Spec 2 Tagesprogramm minimal | Ja (siehe 6.3) | |
| Spec 2 Kalender, Vor-/Nachbereitung, Tap-Abfrage, Modi Passiv/Aktiv | Nein | |

Folge für die Anzeige: Die Fortschrittsanzeige zeigt **"Schritt X von 4"**, nicht "von 6" wie in Spec 1. Das ist eine bewusste Abweichung, weil zwei Schritte fehlen. Alternative siehe Offene Entscheidungen.

### 6.1 Onboarding

**Gemeinsames Layout (Schritte 1–4):** `bg`, Glow. Oben: Zurück-Pfeil (48 dp, ab Schritt 2) und `StepProgress`. Darunter Manny links (56–64 dp) mit einer Sprechblase (ein kurzer Satz, wegtippbar, X). Mitte: Inhalt. Unten fest: Primärbutton "Weiter" (56 dp, deaktiviert bis Eingabe vorhanden). Direkt über dem Button eine Zeile "Noch etwas hinzufügen?" mit `MicButton` (Platzhalter, siehe 6.0). Inhalt scrollt, Button bleibt sichtbar, auch bei eingeblendeter Tastatur.

**Schritt 1: Manny und Name.** Manny groß (ca. 120 dp, zentriert oben). Text Manny (Spec): "Moin, ich bin Manny und begleite dich durch deine Reha. Wie heißt du?" Texteingabe `CuraTextField` (Label "Dein Name"), Tastatur öffnet sich erst beim Antippen. "Weiter" aktiv ab einem Zeichen (nach Trimmen). Ab hier spricht Manny den Nutzer mit Namen an.
**Schritt 2: Datenschutz.** Manny: "Kurz und ehrlich, [Name]: Das passiert mit deinen Daten." Glas-Karte mit drei Kurzabschnitten (Was gespeichert wird, Wie lange, Dein Recht auf Löschung), Text als Platzhalter markiert, Link "Datenschutzerklärung lesen" (öffnet Platzhalterseite), Button "Verstanden, weiter". Nicht überspringbar. Beim Bestätigen Zeitstempel und Version lokal speichern.
**Schritt 3: Verletzungstyp.** Manny: "Was hat's erwischt, [Name]?" `ChoiceCard`s: Kreuzbandriss (ACL) / Bänderriss Sprunggelenk / Muskelfaserriss / Anderes / selbst eingeben. Bei "Anderes" erscheint darunter ein Textfeld "Was ist passiert?" (Freitext, optional, der Weiter-Button ist trotzdem aktiv). Auswahl einer der vier Karten aktiviert "Weiter".
**Schritt 4: Zeitpunkt.** Manny: "Wann war die Verletzung oder OP?" Eine Karte mit dem gewählten Datum (Platzhalter "Datum wählen") öffnet den Datumsauswahl-Dialog des Systems (im Dark-Theme, Akzent `accent`). Nur Datum bis heute wählbar (Annahme). Keine Phasen-Selbsteinschätzung (Spec). "Weiter" aktiv nach Auswahl. Nach "Weiter" Übergang zur Pfad-Ansicht, Manny begrüßt dort (siehe 6.2).

**Zustände Onboarding:** Standard, Fokus (Eingabefeld), Fehler (z. B. leerer Name bei "Weiter": Button bleibt deaktiviert, kein roter Fehlertext nötig), Laden entfällt (alles lokal), "Zurück" behält Eingaben. Beim Abbruch der App wird der Stand lokal gehalten und beim Neustart fortgesetzt (Annahme, damit keine Eingabe verloren geht).

### 6.2 Pfad (Home, Tab "Pfad")

Layout (von oben): Statusleiste, `PathHeader`, scrollender Pfad (Zukunft oben, Vergangenheit unten), `FloatingNav`. Platz unten rechts über der Nav (56 dp, 16 dp Abstand) und unten links bleibt **frei** für den späteren Manny-Chat-Button (Spec 7) bzw. Montags-Brief (Spec 5). Nichts wird dort gezeichnet.

Inhalt: Pfad-Einheit ist die **Woche** (Spec 3). Je Woche mehrere kleine Units (Trainingstage), eine mittlere (Wochenziel); am Ende einer Phase eine große Unit (Phasen-Abschluss), am Ende des Pfads die Boss-Unit "Return to Sport". Manny sitzt auf der aktuellen Unit. Erledigte Units sind klar markiert (Haken).

**Platzhalterdaten (Annahme, keine medizinische Aussage):** Ein Generator liefert für ACL einen festen Beispielpfad, dessen Länge und Phasen **nur Demo-Werte** sind (z. B. 12 Wochen in 3 Phasen mit je 3 Trainingstagen und 1 Wochenziel pro Woche). Die aktuelle Woche ergibt sich aus dem Datum (Schritt 4). Die echten Werte kommen aus dem Physio-Framework (Blocker, extern). Bei Datum in der Zukunft, über das Pfadende oder bei anderem Verletzungstyp: derselbe Beispielpfad mit Hinweiszeile "Beispielpfad" in der Kopfzeile (kleines Label), damit nichts als echte Planung erscheint.

**Streak (Spec 3):** Anzeige in der Kopfzeile mit Zahl. Regeln der Spec: Ruhetage und Physio-Tage unterbrechen den Streak nicht; 1 verpasster Tag: Streak friert 24 h ein; 2 verpasste Tage: Reset auf 0 mit Neustart-Nachricht von Manny; höchstens 2 Freezes. Im Ausschnitt gibt es **keine Ruhetage-/Physio-Tage-Quelle** (Kalender fehlt), daher gilt als Platzhalter: jeder Tag ohne erledigtes Training zählt als verpasst. Zustände der Anzeige:
- Aktiv: Flamme `accent-hi` plus Zahl.
- Eingefroren: Flamme in `streak-freeze` (Blau) plus Zahl, Zusatzlabel "eingefroren" (Text, nicht nur Farbe).
- Reset: Zahl 0, Flamme in `text-3`.
- Freezes: Schneeflocken-Pill mit Zahl 0, 1 oder 2.
Wie Freezes verdient werden ("Belohnung für Meilensteine"), ist im Ausschnitt nicht spezifiziert: im Prototyp wird eine feste Startzahl (Annahme: 2) gesetzt, ein Verdienen findet nicht statt.

**Manny-Auftritte (Spec 3):** Im Ausschnitt nur zwei Anlässe, mit **festen Beispieltexten**: (1) nach dem Onboarding / erste Session: "Moin [Name], los geht's. Dein Weg beginnt hier." (2) Streak-Gefahr (abends, wenn heute noch nichts eingetragen): "Dein Streak von [N] Tagen wartet auf dich. Heute noch eine Runde?" Dazu optional ein Beispielfakt im Sprechblasenformat, z. B. "Dein Gewebe baut sich gerade aktiv um. Heute zählt." (Beispiel aus Spec 3, Platzhalter bis zum Physio-Pool). Anlass (3) Feier nach Eintragen eines Trainings (Pose `feiernd`, "Stark, [Name]. Das war Tag [N]."). Alle sofort wegtippbar (X oder Tap irgendwo), erscheinen höchstens einmal pro Anlass und Tag. Die Texte sind Platzhalter bis zur KI-Anbindung.

**Zustände Pfad:** Standard, Laden (statische Glas-Kreise als Platzhalter, kein Shimmer, höchstens 300 ms sichtbar), Fehler ("Dein Pfad konnte nicht geladen werden." plus Button "Nochmal versuchen", `status-error`-Icon), Streak-Zustände (oben), Manny-Blase sichtbar/ausgeblendet. Leerer Zustand entfällt (der Pfad hat immer Inhalt). Beim Öffnen: aktuelle Unit auf ca. 55 % der Höhe zentriert.

### 6.3 Heute (Tab "Heute"), minimal nach Spec 2

Layout: Datum (`secondary`, deutsch, z. B. "Dienstag, 7. Oktober") und `display` "Heute, [Name]". Segment "10 Min / 20 Min / 30 Min" (Spec 2, Standard 20 Min). Abschnitt TERMINE (`label`): Physio-/Arzt-`CategoryCard`s des Tages. **Im Ausschnitt gibt es keinen Kalender**, deshalb zeigt der Bereich Platzhalter-Beispieltermine (1 Physio-Termin mit Uhrzeit und Ort, als "Beispiel" markiert) oder, bei keinem Termin, den leeren Zustand "Heute keine Termine." (Bereich bleibt). Abschnitt ÜBUNGEN · ca. N MIN: Übungs-`CategoryCard`s (Name, Wiederholungen, Dauer; Aktionen "Tauschen" und "Entfernen"), danach "+ Eigene Übung". Darunter fest über der Nav der Primärbutton "Training starten".

Verhalten:
- Zeitwahl ändert Anzahl und Dauer der Übungen (aus einem **festen Platzhalter-Pool**, nicht aus dem Physio-Framework).
- Tauschen ersetzt die Übung durch die nächste Alternative aus dem Pool (Platzhalter für den KI-Vorschlag). Entfernen löscht sie mit sofortiger Rückgängig-Möglichkeit (Snackbar "Entfernt. Rückgängig").
- Eigene Übung: Dialog mit Name, Wiederholungen, Dauer (Platzhalter-Formular, Pflichtfeld nur der Name).
- "Training starten" öffnet ein Sheet "Wie willst du trainieren?" mit den drei Modi aus Spec 2. Im Ausschnitt ist nur **Manuell** aktiv ("Ich trage es nachher ein"), Passiv und Aktiv sind sichtbar, aber deaktiviert mit Zusatz "Folgt". Bei Manuell: Bestätigung "Training eintragen", danach Status Erledigt: der Tag zählt für den Streak, die aktuelle Pfad-Unit wird erledigt und Manny feiert (Blase, siehe 6.2). Die Feedback-Abfrage (überspringbar, Spec 2) ist **nicht** im Ausschnitt.
- Kein Abbruch-/Pause-Fluss (gehört zu Passiv/Aktiv).

**Zustände Heute:** Standard, Leer (alle Übungen entfernt: Karte "Heute noch nichts geplant." plus Aktion "Eigene Übung"; "Training starten" deaktiviert), Fehler (Übungen nicht ladbar: Text plus "Nochmal versuchen"), Erledigt (Button wird zu inaktivem "Heute erledigt" mit Haken; Übungen bleiben sichtbar), Laden (statische Glas-Platzhalterkarten).

**Scroll-Verhalten Heute:** Der Inhalt scrollt unter dem fixierten Button und der Nav. Der letzte Inhalt hat unten ausreichend Abstand (mindestens Höhe von Button plus Nav plus 16 dp), damit nichts verdeckt bleibt.

---

## 7. Responsives Verhalten

- Referenz: 390 × 844 dp. Getestet werden mindestens 320 × 568 dp (kleinstes Telefon), 390 × 844 dp und 430 × 932 dp, jeweils Hoch- und, wo möglich, Querformat (im Querformat reicht Lesbarkeit und Scrollbarkeit, keine eigene Gestaltung).
- Seitenrand 16 dp, Inhalte volle Breite bis 560 dp. Breiter (Tablet): Inhalt wird in der Mitte auf 560 dp begrenzt, Hintergrund und Glow laufen voll durch. Keine Tablet-spezifische Gestaltung im ersten Ausschnitt.
- Tastatur: Primärbutton bleibt sichtbar (über der Tastatur). Eingabefeld wird in den sichtbaren Bereich gescrollt.
- Safe Areas (Notch, Home-Indikator) werden berücksichtigt, die schwebende Nav liegt über der Safe Area.
- Kleine Displays: Sprechblase wechselt über Manny (5.6). Auf dem Pfad dürfen Unit-Positionen horizontal skalieren (Breite minus 2 × 16 dp), Einheiten behalten ihre Größe.

---

## 8. Accessibility

- **Kontrast:** Tabelle 3.1 gilt. Text ≥ 4,5:1, Symbole und Ränder bedienbarer Elemente ≥ 3:1.
- **Farbe nie allein:** Kategorien (Streifen, Icon, Label), Auswahl (Rand, Haken), Streak-Einfrieren (Label), Triage (Label, Stufe).
- **Touch-Ziele:** ≥ 48 × 48 dp, Abstände ≥ 8 dp.
- **Schriftgrößen:** Layout bricht bei Systemgröße bis 200 % um und scrollt, nichts wird abgeschnitten oder überlappt (Nav-Labels ab 130 % begrenzt, 5.4).
- **Hoher Kontrast** (`MediaQuery.highContrast`): Glas und Float werden zu `surface-opaque`, Glow aus, `border-control-hc` für Ränder.
- **Reduzierte Bewegung:** siehe 3.6.
- **Fokus und Tastatur/Switch:** Sichtbarer `focus-ring`. Reihenfolge entspricht der visuellen Reihenfolge von oben nach unten und links nach rechts. Primärbutton ist über die Tastatur erreichbar. Sprechblase hat Schließen-Aktion, Escape/Zurück schließt sie.
- **Screenreader (TalkBack/VoiceOver), Beispiele für Labels:**
  - Pfad-Unit: "Woche 5, Trainingstag 3, aktuell" / "… erledigt" / "… gesperrt". Boss: "Return to Sport, gesperrt". Die Pfadlinie ist ausgeblendet.
  - Streak: "Streak: 12 Tage" und "Streak-Freezes: 2". Eingefroren: "Streak: 12 Tage, eingefroren".
  - Manny-Blase: Text wird vorgelesen, Schließen-Button "Nachricht schließen". Manny-Bild: "Manny, dein Begleiter" (nicht doppelt zur Blase).
  - Auswahlkarte: "Kreuzbandriss (ACL), Auswahl, nicht ausgewählt/ausgewählt".
  - Fortschritt: "Schritt 3 von 4".
  - Kategorie-Karte: "Physio, Physiotherapie, Praxis Müller, 17:00 Uhr". Übung: "Übung, Kniebeuge am Stuhl, 3 mal 12 Wiederholungen, 6 Minuten", Aktionen "Kniebeuge am Stuhl tauschen" / "… entfernen".
  - Mikrofon-Button: "Spracheingabe, noch nicht verfügbar".
  - Glow, Pfadlinie und rein dekorative Icons: ausgeblendet.
- **Sprache:** Alle Texte Deutsch, Datumsformat deutsch.

---

## 9. Technische Hinweise

- Es gibt noch keinen Flutter-Code im Repo. Projektstruktur legt der `flutter-developer` fest. Eine `KONVENTIONEN.md` existiert nicht (Stand dieses Briefs).
- Keine neuen Abhängigkeiten ohne Grund. Fonts als Assets bündeln, **kein** `google_fonts`-Laden zur Laufzeit. Icons: eingebaute abgerundete Material-Icons, Manny und Pfad per `CustomPainter`/`Path`. Datumsauswahl: die der Plattform/Flutters, mit eigenem Theme.
- Tokens als `ThemeExtension`, Dark als einziger Modus im ersten Ausschnitt. Die Tokens sind so zu benennen, dass ein heller Modus später nur neue Werte braucht (Basis: Palette aus Grunddesign v1).
- Glow als gecachte Ebene, Blur nur gemäß 3.5. Bei Hoher Kontrast Fallback auf opake Flächen.
- Streak-Logik, Pfad-Generator und Platzhalter-Pools als eigene, von der UI getrennte, testbare Klassen (reine Dart-Logik) mit klar markierten Platzhalterdaten.
- Lokale Speicherung des Onboarding-Stands und des Consent (Zeitstempel, Version). Löschbar (Spec 1: Rollback). Es wird nichts gesendet.
- Externe Abhängigkeiten (nur benannt): Manny-Illustration und -Animationen, Physio-Framework (Pfad, Fakten, Übungspool), Google Places, KI/Spracherkennung (Spec 7), Datenschutz-Konzept (Anwalt).

---

## 10. UI-Akzeptanzkriterien

Prüfbar auf Gerät/Emulator, soweit nicht anders vermerkt.

**Tokens und Optik**
- UI-1: Alle Farben, Abstände, Radien und Schriftstile kommen aus Tokens. Im Code gibt es außer in der Token-Definition kein `Color(0x…)` und keine festen Schriftgrößen (Stichprobe per Code-Suche).
- UI-2: Bildschirmgrund ist `#0E131A`, Haupttext `#F2F0EB`, Akzent `#D9622B` (Stichprobe per Screenshot-Pipette bzw. Token-Dump).
- UI-3: Die berechneten Kontraste der Tabelle 3.1 stimmen für die verwendeten Paare (Text ≥ 4,5:1, Symbole und Ränder bedienbarer Elemente ≥ 3:1). Ein Test (Unit-Test oder Skript) berechnet sie aus den Tokens und schlägt fehl, wenn ein Paar darunter fällt.
- UI-4: Akzent als Textfarbe wird nur auf `bg`/`surface-opaque` verwendet, auf Glas nur `accent-hi` oder `text-1` (Code-Review). (siehe Erratum E-2: präzisierte Fassung)
- UI-5: Kein Text mit Größe unter 13 sp oder Gewicht unter 400.

**Glas, Glow, Motion**
- UI-6: Pro Screen sind höchstens 2 `BackdropFilter` im Widget-Baum gleichzeitig sichtbar (Nav und Sprechblase/Sheet). Karten, Chips und Listenelemente enthalten keinen (Code-Suche).
- UI-7 (siehe Erratum E-1: neue Fassung gilt): Der Glow ist statisch, `ExcludeSemantics`, in einer `RepaintBoundary` und hat höchstens 24 % Spitzen-Deckkraft. Text liegt mindestens 70 dp vom Glow-Mittelpunkt entfernt (Screenshot-Prüfung der Screens aus 6).
- UI-8: Mit eingeschalteter Systemoption "Bewegung reduzieren" gibt es auf allen Screens keine Schiebe-, Puls- oder Fade-Animationen länger als 120 ms. Manny zeigt statische Posen. (siehe Erratum E-3)
- UI-9: Bei "Hoher Kontrast" haben Karten, Nav, Blase und Sheets opake Füllungen (`#1B2129`), kein Blur, keinen Glow, und Ränder erreichen ≥ 4,3:1 (gemessen 4,37).
- UI-10: Die Scroll-Performance des Pfads liegt auf einem Mittelklasse-Testgerät nach Augenschein ohne sichtbares Ruckeln (Flutter-Profile: keine dauerhaften Frames über 16 ms durch Blur; Messung durch den Entwickler dokumentieren).

**Onboarding**
- UI-11: Der Ablauf hat die Schritte Manny/Name, Datenschutz, Verletzungstyp, Datum. Die Fortschrittsanzeige zeigt "Schritt X von 4" und passt sich bei jedem Schritt an.
- UI-12: Bei Schritt 1 ist "Weiter" deaktiviert, solange der Name leer ist (nach Trimmen). Danach wird der Name in allen folgenden Manny-Texten verwendet.
- UI-13: Schritt 2 ist nicht überspringbar. Nach "Verstanden, weiter" sind Zeitstempel und Version lokal gespeichert. Es gibt einen Link "Datenschutzerklärung lesen".
- UI-14: Schritt 3 zeigt vier Karten (ACL, Bänderriss Sprunggelenk, Muskelfaserriss, Anderes / selbst eingeben). Genau eine ist wählbar, die gewählte hat Haken, 2 dp Rand und getönte Füllung. Bei "Anderes" erscheint ein optionales Textfeld.
- UI-15: Schritt 4 verlangt ein Datum (nicht in der Zukunft), "Weiter" ist bis dahin deaktiviert. Es gibt keine Phasen-Auswahl.
- UI-16: Auf jedem Onboarding-Schritt ist der Mikrofon-Button sichtbar und antippbar. Antippen zeigt den Hinweis "noch nicht verfügbar" und stürzt nicht ab. Zurück behält die Eingaben. Nach App-Neustart mitten im Onboarding wird am letzten Schritt fortgesetzt.

**Konflikt b (Akzent und Warnfarben)**
- UI-17: Im Code gibt es keine Verwendung von `accent`/`accent-hi` für Status, Fehler, Warnung oder Frist, und keine Verwendung von `status-error`, `cat-frist`, `tri-*` für Handlungselemente (Code-Review).
- UI-18: In einer Graustufen-Darstellung der Screens aus Abschnitt 6 bleiben alle Kategorien, Auswahlzustände und der Streak-Zustand "eingefroren" unterscheidbar (Label oder Symbol vorhanden). Screenshot-Prüfung.
- UI-19: Bei Simulation von Rot-Grün-Schwäche (Protanopie/Deuteranopie) bleiben Kategorie-Karten durch Icon und Label unterscheidbar (Screenshot-Prüfung mit Simulator).

**Pfad (Spec 3)**
- UI-20: Der Pfad ist geschwungen (nicht gerade), vertikal scrollbar, mit vier Unit-Größen (48/60/72/92 dp). Erledigte Units zeigen Haken, die aktuelle ist in Akzentfarbe mit Ring, gesperrte zeigen Schloss.
- UI-21: Manny sitzt auf der aktuellen Unit. Beim Öffnen des Tabs ist sie sichtbar und ungefähr vertikal zentriert (±15 % der Höhe).
- UI-22: Die Kopfzeile zeigt "Woche N", "Phase M", die Streak-Zahl und die Freeze-Anzahl (0–2). Im Zustand "eingefroren" steht zusätzlich das Wort "eingefroren".
- UI-23: Die Sprechblase hat ein sichtbares X mit Hit-Area ≥ 48 dp und schließt auch durch Tippen irgendwo. Sie enthält höchstens 2 Sätze, blockiert keine Bedienung und erscheint pro Anlass höchstens einmal pro Tag.
- UI-24: Der Platz für Chat-Button (unten rechts) und Montags-Brief (unten links) ist frei von Elementen, die Interaktionen oder Inhalte verdecken.
- UI-25: Der Beispielpfad ist als "Beispielpfad" gekennzeichnet, solange kein Framework-Pfad vorliegt.

**Heute (Spec 2, minimal)**
- UI-26: Zeitwahl 10/20/30 Min ist sichtbar, 20 vorgewählt. Ein Wechsel ändert die Übungsliste und die Überschrift "Übungen · ca. N Min" sofort.
- UI-27: Jede Übungskarte zeigt Name, Wiederholungen und Dauer sowie die Aktionen "Tauschen" und "Entfernen". Entfernen bietet "Rückgängig". Tauschen ersetzt die Übung.
- UI-28: Eine Termin-Karte zeigt Streifen in `cat-physio`/`cat-arzt`, Icon, Label, Titel und Uhrzeit. Übungen zeigen Streifen, Icon und Label in `cat-uebung`.
- UI-29: Sind alle Übungen entfernt, erscheint "Heute noch nichts geplant." mit der Aktion "Eigene Übung", und "Training starten" ist deaktiviert.
- UI-30: "Training starten" öffnet ein Sheet mit drei Modi. Nur "Manuell" ist aktiv, die anderen sind als "Folgt" deaktiviert. Nach Eintragen erscheint "Heute erledigt", der Streak erhöht sich um 1 und die aktuelle Pfad-Unit ist erledigt.
- UI-31: Der letzte Inhalt der Liste ist auf jedem Gerät vollständig erreichbar und wird weder vom Button noch von der Nav verdeckt.

**Zugänglichkeit und Responsivität**
- UI-32: Alle antippbaren Elemente haben eine Hit-Area von mindestens 48 × 48 dp (Prüfung mit Flutter-Semantik-Debugging oder Layout-Inspektor).
- UI-33: Bei Systemschriftgröße 200 % ist auf allen Screens alles lesbar, nichts wird abgeschnitten und der Primärbutton bleibt erreichbar. Die Nav-Labels sind auf 130 % begrenzt.
- UI-34: Bei 320 × 568 dp ist jede Funktion der Screens erreichbar, kein horizontales Scrollen, die Sprechblase steht über Manny und nicht darüber hinaus über den Rand.
- UI-35: Mit TalkBack/VoiceOver ist jeder Screen vollständig bedienbar. Die Labels aus Abschnitt 8 werden vorgelesen, dekorative Elemente nicht. Der Fokus ist sichtbar (`focus-ring`).
- UI-36: Alle sichtbaren Texte sind Deutsch und im Ton der Spec ("du", kurz, direkt, nie klinisch).

---

## 11. Annahmen

1. Dunkel ist der einzige Modus im ersten Ausschnitt, ein heller Modus folgt später über die Semantik-Tokens (Spec 3 schließt nur nutzerseitige Themes aus).
2. "CuraOne" erscheint als Textmarke ohne Logo (Arbeitsname laut Spec 4).
3. Manny ist ein Platzhalter aus Flutter-Formen mit drei statischen Posen.
4. Kategorie- und Triage-Töne sind Vorschläge ("z. B." laut Spec 2/4).
5. Pfad-Länge, Phasen, Trainingstage und Beispieltexte sind Demo-Platzhalter und keine medizinischen Aussagen.
6. Datum der Verletzung darf nicht in der Zukunft liegen.
7. Der Name wird per Tastatur eingegeben (Spec 1 nennt "Tap oder Sprache", aber ein Name lässt sich nicht antippen). Die Spracheingabe ist Platzhalter.
8. Der Onboarding-Stand bleibt lokal erhalten, damit bei App-Abbruch nichts verloren geht.
9. Startwert für Streak-Freezes im Prototyp: 2 (feste Annahme, kein Verdienen).
10. Streak im Prototyp: Jeder Tag ohne erledigtes Training zählt als verpasst (Ruhetage und Physio-Tage fehlen mangels Kalender).
11. Farben, Fontnamen und Lizenz: Kontraste sind berechnet, die Lizenzprüfung der Fonts und ein Test auf realen Geräten stehen aus.

## 12. Offene Entscheidungen

**Nutzerentscheidungen bei Freigabe (2026-10-07):** Punkt 1 → "von 4". Punkt 2 → Beispielpfad mit Label für alle Verletzungstypen. Punkt 3 → Sheet mit drei Modi, nur "Manuell" aktiv. Punkte 4–6 bleiben wie beschrieben (Annahmen des Briefs gelten).

1. **Fortschritt "von 4" oder "von 6"?** Vorschlag: "von 4", weil Upload und Team fehlen. Alternative: "von 6" mit zwei Schritten als überspringbare Platzhalter. *Auswirkung:* ehrlichere Anzeige vs. Spec-Treue.
2. **Verhalten bei anderen Verletzungstypen als ACL:** Vorschlag: alle laufen im Prototyp in denselben Beispielpfad, mit "Beispielpfad"-Label. Alternative: Nicht-ACL-Karten deaktivieren ("Folgt"). *Auswirkung:* Spec nennt vier Optionen, das Framework existiert nur für den ersten Typ.
3. **Modus-Auswahl beim Start:** Vorschlag: Sheet mit nur "Manuell" aktiv. Alternative: Button heißt direkt "Als erledigt eintragen" ohne Sheet. *Auswirkung:* Sheet kündigt Passiv/Aktiv an, Alternative ist schlanker.
4. **Datenschutztext:** Platzhaltertext, der vor Echtbetrieb juristisch ersetzt werden muss (Datenschutz-Konzept, Anwalt).
5. **Streak-Freezes:** feste Startzahl im Prototyp oder gar nicht anzeigen, bis das Verdienen spezifiziert ist.
6. **Akzent-Feinabstimmung:** `#D9622B` ist ein Vorschlag mit nachgewiesenem Kontrast. Wird der Wert nach Sichtung geändert, müssen die Kontraste in 3.1 neu berechnet werden (Test UI-3 deckt das ab).

## 13. Nicht enthalten

Kalender-Ansicht, Vor-/Nachbereitung, Tap-Abfrage, Modi Passiv/Aktiv, Push-Benachrichtigungen, Symptom-Check und Triage-Ansicht (Spec 4; nur Tokens und Regeln), Fortschritts-Ansicht (Spec 5), Return-to-Sport-Phase (Spec 6) bis auf die Boss-Unit als gesperrtes Element, Manny-Chat und Sprachfunktion (Spec 7), Community und Freunde und Familie (Spec 8), Dokument-Upload, Team/Google Places, heller Modus, Manny-Illustration und -Animationen, Physio-Framework, echte KI-Texte.

---

## 14. Errata (freigegeben 2026-10-07)

Diese Errata sind vom Nutzer freigegeben und haben Vorrang vor den Stellen, auf die sie verweisen. Der ursprüngliche Text bleibt zur Nachvollziehbarkeit stehen.

### E-1: Glow-Regel nach Untergrund (ersetzt die Abstandsregel in 3.2 und UI-7)

**Anlass.** Text am Seitenrand (x = 16 dp) liegt höchstens 46 dp vom Glow-Mittelpunkt (−30, 40) entfernt (Alpha bis 17,9 %). Die Regel "mindestens 70 dp" ist daher nicht überall erfüllbar. Der Kontrast ist dennoch gesichert, weil er vom Untergrund abhängt (nachgerechnet, WCAG 2.x, Glow als linearer Alpha-Abfall `Alpha = Spitze × (1 − d / (0,7 × Radius))`).

**Regel (ersetzt Abstände 70 dp / 91 dp):**
1. Spitze weiter höchstens 24 %. Der Glow bleibt statisch, `ExcludeSemantics`, in einer `RepaintBoundary`.
2. Text direkt auf `bg` (`text-1`, `text-2`, `text-3`): Glow-Alpha bis 24 % zulässig (Kontrast mindestens 5,10).
3. `text-1`, `text-2`, `text-3` auf Glas: Glow-Alpha ≤ 16 % (Kontrast mindestens 4,55).
4. Farbiger Text (Kategorie-Label) und `accent-hi` als Text auf Glas: Glow-Alpha ≤ 12 %.
5. **Prüfung** per Alpha am dem Glow-Mittelpunkt nächstgelegenen Punkt des Text-Rechtecks (Alpha-Funktion aus 3.2) gegen die Schwellen 24 / 16 / 12 %, nicht per Abstand. Der Untergrund ergibt sich daraus, ob der Text in einer Glas-Karte liegt.

**UI-7 (neue Fassung, ersetzt die alte im Wortlaut):**
- UI-7: Der Glow ist statisch, `ExcludeSemantics`, in einer `RepaintBoundary` und hat höchstens 24 % Spitzen-Deckkraft. Am nächstgelegenen Punkt jedes Text-Rechtecks beträgt der Glow-Alpha höchstens 24 % bei Text direkt auf `bg`, höchstens 16 % bei `text-1`/`text-2`/`text-3` auf Glas und höchstens 12 % bei farbigem Text und `accent-hi` auf Glas (Prüfung per Test der Alpha-Funktion und Screenshot-Prüfung der Screens aus 6).

**Ergänzung zu 3.1: Kontraste über Glow (Verhältnis).**

| Glow-Alpha | Untergrund | text-1 | text-2 | text-3 | accent-hi | cat-physio | cat-arzt | cat-frist |
|---|---|---|---|---|---|---|---|---|
| 0 % | bg | 16,37 | 8,54 | 7,24 | 6,45 | 6,84 | 6,94 | 6,23 |
| 0 % | Glas | 13,18 | 6,88 | 5,83 | 5,19 | 5,51 | 5,59 | 5,01 |
| 12 % | bg | 14,17 | 7,39 | 6,27 | 5,58 | 5,93 | 6,01 | 5,39 |
| 12 % | Glas | 11,00 | 5,74 | 4,87 | 4,34 | 4,60 | 4,67 | 4,19 |
| 15,3 % | bg | 13,46 | 7,02 | 5,96 | 5,30 | 5,63 | 5,71 | 5,12 |
| 15,3 % | Glas | 10,41 | 5,43 | 4,61 | 4,10 | 4,35 | 4,42 | 3,96 |
| 16 % | bg | 13,30 | 6,94 | 5,89 | 5,24 | 5,56 | 5,64 | 5,06 |
| 16 % | Glas | 10,28 | 5,37 | 4,55 | 4,05 | 4,30 | 4,36 | 3,91 |
| 17,9 % | bg | 12,88 | 6,72 | 5,70 | 5,08 | 5,39 | 5,47 | 4,90 |
| 17,9 % | Glas | 9,95 | 5,19 | 4,40 | 3,92 | 4,16 | 4,22 | 3,78 |
| 24 % | bg | 11,53 | 6,02 | 5,10 | 4,54 | 4,82 | 4,89 | 4,39 |
| 24 % | Glas | 8,91 | 4,65 | 3,94 | 3,51 | 3,73 | 3,78 | 3,39 |

Folgen: Farbiger Text und `accent-hi` auf Glas nur bei Alpha ≤ 12 % (`cat-physio` 4,60, `cat-arzt` 4,67; `accent-hi` 4,34 und `cat-frist` 4,19 liegen darunter, daher dort nur `text-1` oder opake Fläche). `text-3` bleibt auf Glas bis 16 % bei mindestens 4,55. Der Test UI-3 nimmt diese Paare auf.

### E-2: Akzent als Text nur auf `bg` (korrigiert die Folgerung in 3.1 und UI-4)

**Anlass.** `accent` `#D9622B` auf `surface-opaque` `#1B2129` hat nur **4,42:1** (nachgerechnet). Die Angabe "5,09 bzw. 5,60+" in 3.1 galt für `accent` auf `bg` bzw. für `accent-hi` auf `surface-opaque`.

**Korrektur:**
- `accent` als **Text** nur auf `bg` (5,09).
- Auf `surface-opaque`, Glas, in `CuraDialog`, `CuraSnackbar`, `NodeHint` und in den Textbuttons des Datumsauswahl-Dialogs gilt `accent-hi` (5,60 auf `surface-opaque`) oder `text-1`. Füllungen und Flächen (gewählter Tag, Primärbutton) bleiben `accent`.
- Das Paar `accent` auf `surface-opaque` (4,42) ist in den Test UI-3 aufzunehmen und darf für Text nicht verwendet werden.

**UI-4 (präzisierte Fassung):**
- UI-4: Akzent (`accent`) als Textfarbe wird nur auf `bg` verwendet. Auf `surface-opaque`, Glas, in Dialogen, Snackbars, Hinweisen und in Datumsauswahl-Textbuttons nur `accent-hi` oder `text-1` (Code-Review und Kontrasttest).

### E-3: Fortschrittskreis bei reduzierter Bewegung (Ausnahme von UI-8, freigegeben 2026-10-08)

**Anlass.** Der Fortschrittskreis laufender Vorgänge (z. B. `PillButton` mit `busy`, Löschen-Dialog) ist ein Zustandsanzeiger, kein Schiebe-, Puls- oder Fade-Effekt. Ein statischer Kreis würde "hängt" signalisieren.

**Regel.** Fortschrittskreise laufender Vorgänge dürfen bei "Bewegung reduzieren" weiterdrehen, unter diesen Bedingungen:
- reine Drehung, keine Schiebung, kein Puls, kein Skalieren;
- nur während des Vorgangs, sichtbar erst nach mehr als 300 ms;
- kein Ein- oder Ausblenden länger als 120 ms;
- keine Dauerschleife außerhalb eines Vorgangs;
- Screenreader erhalten eine Statusansage (z. B. "Wird gelöscht").

**UI-8 (neue Fassung, ersetzt die alte im Wortlaut):**
- UI-8: Mit eingeschalteter Systemoption "Bewegung reduzieren" gibt es auf allen Screens keine Schiebe-, Puls- oder Fade-Animationen länger als 120 ms. Manny zeigt statische Posen. Ausgenommen sind Fortschrittskreise laufender Vorgänge unter den Bedingungen von E-3 (reine Drehung, nur während des Vorgangs und erst nach 300 ms sichtbar, kein Ein-/Ausblenden über 120 ms, keine Dauerschleife außerhalb eines Vorgangs, Statusansage für Screenreader).
