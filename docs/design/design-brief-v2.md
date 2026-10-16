# Design-Brief v2: CuraOne, Tageszeit-Welt, Glas und Manny

Status: **FREIGEGEBEN (2026-10-14)** · Stand 2026-10-14 · Grundlage: freigegebenes `grunddesign-v2.md` (inkl. Manny A „Lässig“, Tageszeit-Welt, Glas-Kugeln, Leiste, Physio in ruhigerer Welt) und die freigegebenen Produktdokumente `docs/produkt/curaone-ablaeufe-training-checkup.md`, `curaone-physio-bereich.md`, `curaone-spezifikation-manny-gehirn.md`, `curaone-feed.md`. Orientierung: `mockups/v2-grunddesign-uebersicht.png` und die Einzelbilder `mockups/v2-*.png`.

**Dieser Brief löst `design-brief-v1.md`, die Errata E-1 bis E-5 und die Ergänzungen 1 bis 3 als Gestaltungsvorgabe ab.** Verhalten, Inhalte, Texte und Abläufe aus v1 bleiben, soweit Abschnitt 2 sie nicht ausdrücklich ersetzt. Die Mockups sind Skizzen (Beispieldaten, Manny als Platzhalter). Maßgeblich ist dieser Text; bei Abweichung gilt er (z. B. Kartendeckung 92 %, siehe 3.5).

## 1. Nutzerziel und wichtigste Aktionen
- **Patient (täglich):** wissen, was heute ansteht, trainieren (geführt oder abhaken), kurz sagen, wie es ging und wie es einem geht, Fortschritt und Streak sehen, mit Physio und Manny schreiben. Die App soll modern und jung wirken und trotzdem ruhig und lesbar bleiben.
- **Physio (Handy zwischen zwei Patienten, Rechner für Pläne):** in 5 bis 10 Minuten alles Wichtige zu einem Patienten erfassen, Patienten finden, Übungen bauen, einen neuen Patienten in 30 Sekunden anlegen.

## 2. Was bleibt, was ersetzt wird

| Bereich | Bleibt (verbindlich) | Wird ersetzt |
|---|---|---|
| Barrierefreiheit | WCAG-AA-Kontraste (Text ≥ 4,5:1, Symbole und Bedienränder ≥ 3:1), Zielgrößen ≥ 48 dp mit ≥ 8 dp Abstand, 200 % Schriftgröße, reduzierte Bewegung, hoher Kontrast, sichtbarer Fokus, Screenreader-Labels, Zustände nie nur durch Farbe (v1 UI-3, 5, 8, 9, 18, 19, 32–36) | nur die Zahlen- und Wortlaute der Messwerte (neue Tabellen, Abschnitt 3) |
| Inhalte und Abläufe | Onboarding (4 Schritte), Pfad-Logik, Streak und Freeze, Heute mit Zeitwahl 10/20/30, Tauschen/Entfernen/Rückgängig, Tageswechsel, „Deine Daten“, Pfad-Tipps, Ausblick Prävention, Manny-Chat und Nachrichten, Texte auf Deutsch, „du“, kurz | Optik und Anordnung dort, wo dieser Brief etwas anderes zeigt |
| Warnkontext | Triage- und Fristen-Screens opak und neutral: kein Akzent-Button, keine Welt, kein Glas; Orange ist nie Statusfarbe (v1 Abschnitt 4, UI-17) | nichts |
| E-2, E-3, E-4, E-5 | Orange als Text nur der dunkle Ton (neu `accent-text`), Fortschrittskreis-Ausnahme, Fehlertext beim Start, Sheet „Deine Daten“ im kompakten Zustand opak ohne Blur | Zahlenwerte der Farben |
| Theme | Semantik-Tokens, Hell und Dunkel | **Dunkel als einziges Theme:** jetzt Hell und Dunkel für Inhaltsflächen (System), dazu Tageszeit-Welt |
| E-1, Glow | – | Glow, Glow-Regeln, `glow-ember`: entfallen, ersetzt durch Welt und Regel „Text nie direkt auf der Welt“ (3.1, 3.5) |
| Farbe | Kategorie-Zuordnung (Physio blau, Arzt lila, Übung grün, Frist rot) | Kupfer `#D9622B` → Mandarine `#FF7A2E`; Kategorie-Töne neu |
| Typografie | DM Sans (Text), Bricolage Grotesque, nichts unter 13 sp | Titel und Zahlen jetzt Gewicht 700–800 |
| Glas | – | Blur-Budget 2 → 3; Karten sind Pseudo-Glas ohne Blur; Leiste mit Ruhe-/Aktiv-Zustand |
| Navigation | – | 2 Tabs plus Button-Gruppe → 5 Ziele (Patient) bzw. 4 (Physio) |
| Pfad-Units | Größenstufen und Zustände Erledigt/Aktuell/Gesperrt/Boss | flache Kreise → Glas-Kugeln |
| Motion | Reduzierte Bewegung (E-3), Dauer-Token als Basis | „Keine Bounce-Kurven“ → einmalige Federn erlaubt (3.6) |
| Manny | Posen als Parameter, Tipp auf Manny öffnet Chat | Flachformen-Platzhalter → Skizze Variante A (Abschnitt 6) |

## 3. Tokens

### 3.1 Welt (nur Hintergrund und Glasfarbe von Kopf-Karte und Leiste)
Die Welt ist statisch pro Frame: Himmelsverlauf, Licht (Sonne/Mond), drei Hügelebenen, Dunstbänder, Körnung (Sterne nachts). **Keine harten Konturen** zwischen Ebenen: jede Ebene läuft nach unten in Transparenz aus, hinten stärker weichgezeichnet, dazwischen Dunst. Text und Bedienelemente liegen **nie direkt auf der Welt**, sondern auf Karte, Kopf-Karte, Leiste oder Label-Chip.

| Token-Satz | Morgen | Mittag | Abend | Nacht |
|---|---|---|---|---|
| `world-sky` (Verlauf oben→unten) | `#BCD2EA`, `#F3C6B6` 34 %, `#F7DFCB` 58 %, `#F6EDE0` 80 %, `#F7F2EB` | `#8EC3EC`, `#CDE5F4` 36 %, `#E9F2EE` 60 %, `#F6F3EA` 82 %, `#F7F2EB` | `#F2B58C`, `#E8A68A` 16 %, `#C8B1A8` 36 %, `#DCCFC4` 58 %, `#F1E8DD` 80 %, `#F7F2EB` | `#141A33`, `#2B2547` 30 %, `#4A3548` 55 %, `#2B2230` 78 %, `#1C1620` |
| `world-hill-far/mid/near` | `#B4AFC6` / `#D2C0BC` / `#F6EDE2` | `#9DB6C6` / `#C4D3D1` / `#F1F0E8` | `#A99AA6` / `#9C8E9B` / `#F4ECE2` | `#4A4468` / `#3A3354` / `#2E2634` |
| `world-light` (Position) | Sonne links (24 %, 28 %), `#FFE9C2` | Sonne hoch (70 %, 9 %), `#FFFFFF` | Sonne rechts (78 %, 20 %), `#FFE9C8` | Mond (78 %, 18 %), `#FFF3D6`, 46 Sterne |
| `world-floor` (Farbe unter der Leiste) | `#F7F2EB` | `#F7F2EB` | `#F7F2EB` | `#1C1620` |
| `header-tint` / Deckkraft | `#2A211C` 66 % | `#23303A` 66 % | `#281E18` 66 % | `#0F0B1A` 58 % |
| `nav-tint`, Ruhe / Aktiv | Weiß 35 % / 78 % | Weiß 35 % / 78 % | Weiß 35 % / 78 % | `#1A1320` 45 % / 82 % |
| `nav-ink` (Label, Symbole) | `#211B16` | `#211B16` | `#211B16` | `#F5EFE8` |
| `chip-world` (Label-Chip, Deckkraft 72–74 %) | Weiß, Text `#211B16` | Weiß, Text `#211B16` | Weiß, Text `#211B16` | `#1E1626`, Text `#FFFFFF` |

**Zeitregel.** Feste Gerätezeit (lokal): Morgen 5–10, Mittag 10–17, Abend 17–21, Nacht 21–5 Uhr. An jeder Grenze T wird linear über 30 Minuten von T−15 min bis T+15 min zwischen den Farbwerten beider Phasen überblendet (alle Tokens der Tabelle, Sonne wechselt weich die Position). Die Welt wird beim Öffnen eines Screens und per Minuten-Timer im Hintergrund neu berechnet, nie sichtbar während einer Eingabe animiert. Bei „Bewegung reduzieren“ springt die Welt nur beim Öffnen. Einstellung „Welt“ in Profil → Darstellung: Automatisch (Standard), Morgen, Mittag, Abend, Nacht (fester Look, keine Überblendung). Die Welt gilt für alle Patientenscreens. **Physio-Bereich: dieselbe Welt, ruhiger:** Ebenen auf 50 % Deckkraft, keine Sonne/Mond/Sterne/Körnung, Karten 96 % Deckkraft.

**Kontrast je Welt** (WCAG-Verhältnis, Worst Case = ungünstigster Untergrund unter dem Glas; Messung per Test, Quelle der Rechnung: `mockups/v2-src/gen3.py`):

| Welt | Kopf-Karte, weißer Text (gegen reines Weiß) | Label-Chip | Leiste Ruhe, Label | Leiste Aktiv, Label |
|---|---|---|---|---|
| Morgen | 5,2 | 8,6 | 10,1 | 14,4 |
| Mittag | 4,6 | 9,1 | 10,1 | 14,4 |
| Abend | 5,3 | 8,6 | 10,1 | 14,4 |
| Nacht | 4,8 | 7,0 | 9,5 | 13,8 |

Die Leiste rechnet gegen Schwarz, Weiß und Mandarine unter dem Schleier (70 % `world-floor`, Höhe 150 dp). Text in der Kopf-Karte ist immer `#FFFFFF` (Gewicht ≥ 500), kein Grauton.

### 3.2 Inhaltsflächen: Thema Hell und Dunkel (folgt dem System, in Profil überschreibbar)
Nacht ist **nicht** automatisch dunkel: Welt und Thema sind unabhängig.

| Token | Hell | Dunkel |
|---|---|---|
| `card` | Weiß **92 %** | `#241D18` **92 %** |
| `ink-1` / `text-1` | `#211B16` | `#F5EFE8` |
| `ink-2` / `text-2` | `#5A5048` | `#CFC5BB` |
| `accent` (Füllung) | Mandarine `#FF7A2E`, Verlauf `#FFA063`→`#FF7A2E` | gleich |
| `on-accent` | `#211B16` (6,55:1; auf `#FFA063` 8,48:1) | gleich |
| `accent-text` (Orange als Text) | `#A83F0B` | `#FF9A62` |
| `success-text` | `#1B6E47` | `#5FD39A` |
| `error-text` / `status-error` | `#B3261E` | `#FF8A80` |
| `cat-physio` / `cat-arzt` | `#2A62B0` / `#6B49C9` | `#8DB8FF` / `#B9A4FF` |
| `cat-uebung` / `cat-frist` | `#1B6E47` / `#B3261E` | `#5FD39A` / `#FF8A80` |
| `chip-neutral` | `ink-1` 7 % auf Karte, Text `ink-1` | Weiß 10 % auf Karte, Text `text-1` |
| `chip-success` / `chip-warn` | `#DDF3E6` mit `#14532D` (7,8:1) / `#FFE3DD` mit `#7A1A12` (8,7:1), immer mit Symbol (✓ bzw. ⚠) und Text | getönte dunkle Chips, Text ≥ 4,5:1 (Test) |
| `border-control` | `ink-1` 55 % (3,6:1 im Worst Case) | `text-1` 45 % (3,8:1) |
| `gold` (Fortschritt, Ziel) | `#FFC23D`, Symbole darauf `#8A3A0C` | gleich |
| `focus-ring` | 3 dp, `ink-1` mit 2 dp weißem Außenrand | 3 dp `text-1` mit 2 dp dunklem Außenrand |

**Gemessene Werte auf Karte (92 %), Worst Case über Schwarz/Weiß/Mandarine/Grau darunter:** Hell: `ink-1` 14,3 · `ink-2` 6,6 · `accent-text` 5,2 · `success-text` 5,2 · `error-text` 5,5 · `cat-physio` 5,1 · `cat-arzt` 5,2. Dunkel: `text-1` 11,5 · `text-2` 7,7 · `accent-text` 6,3 · `success-text` 7,1 · `error-text` 5,8 · `cat-physio` 6,5 · `cat-arzt` 6,2. Karten mit nur 80 % Deckung würden für farbigen Text 3,3 bis 4,1 ergeben und sind deshalb **nicht zulässig**.

**Fortschrittsbalken und Regler:** Spur `ink-1` 14 % plus 1 dp Rand `border-control`, Füllung Mandarine oder Gold; Wert steht immer auch als Text (z. B. „4 von 7 Tagen“, „3/10“), weil Füllung gegen Spur nur 2:1 erreicht.

### 3.3 Typografie
Fonts: **Bricolage Grotesque** (Titel, Zahlen, Buttons) und **DM Sans** (Text), schon gebündelt, Lizenzdateien liegen bei.

| Token | Font | Größe/Zeile (sp) | Gewicht |
|---|---|---|---|
| `display` | Bricolage | 36/38 | 800 |
| `title` | Bricolage | 30/32 (Kopf-Karte), 24/28 | 800 |
| `heading` | Bricolage | 20/23 | 800 |
| `counter` | Bricolage | 52/52 (Zähler-Orb), Einheit 30 | 800 |
| `numeral` | Bricolage | 28/30 (Kacheln), 17–18 | 800 |
| `button` | Bricolage | 18/24 | 800 |
| `body` | DM Sans | 16/24 | 400–600 |
| `body-strong` | DM Sans | 16/24 | 700 |
| `secondary` | DM Sans | 14/20 | 500–600 |
| `meta` / `chip` | DM Sans | 13/16 | 600–700 |

Nichts unter 13 sp, Gewicht ≥ 400. Bei Systemschrift 200 % wächst alles mit, Umbruch statt Abschneiden; nur die Leiste begrenzt Labels auf 130 %.

### 3.4 Radien, Abstände, Größen
Raster 4 dp (`space-1…10` wie v1), Seitenrand 14 dp (Karten) bzw. 16 dp (Text). Radien: Karte 28, Kopf-Karte 32, Bildkachel 18, Chip/Button/Leiste Pille (999), Sheet oben 32, Kugeln rund. Zielgrößen ≥ 48 × 48 dp (Hit-Area darf größer als die Optik sein), Abstand zwischen Zielen ≥ 8 dp. Primärbutton 56 dp, Glas-Button 52 dp, Smiley 46 dp sichtbar (Hit-Area 48), Leiste 72 dp hoch, 14 dp Seitenabstand, 24 dp unten plus Safe Area; Leiste-Tab 62 × 56 dp (Physio 76 × 56).

### 3.5 Tiefe, Glas, Blur-Budget
- **Ebenen:** E0 Welt · E1 Karten (Pseudo-Glas: Fläche `card`, 1 dp Lichtkante oben, Schatten 0/18/30 mit negativem Spread, warm getönt, **kein Blur**) · E2 Glas (Kopf-Karte, Leiste, Manny-Knopf; Sheets opak) · E3 Objekte (Kugeln, Manny).
- **Kugel (Glas-Objekt):** Radialverlauf mit Glanzpunkt oben links, Innenschatten unten, 1 dp helle Kante, Bodenschatten (Ellipse, getönt). Keine harten Unterkanten an Buttons.
- **Blur-Budget (Obergrenze 3): höchstens 3 gleichzeitig sichtbare `BackdropFilter` pro Screen.** Zulässig sind nur Leiste, Kopf-Karte und Manny-Knopf (damit sind es höchstens 3). Sheets und Dialoge sind opak ohne Blur. Karten, Chips, Listenzeilen, Kugeln und die Session-Buttons nutzen nie Blur (Session-Buttons: Weiß 90 % ohne Blur).
- **Regel „Text nie direkt auf der Welt“** (ersetzt E-1): Jeder Text steht auf einer Fläche mit gemessenem Kontrast aus 3.1/3.2. Die Statuszeile (Uhrzeit, Akku) ist systemseitig und ausgenommen.
- **Transparenz reduzieren / Hoher Kontrast:** alle Glasflächen (Kopf-Karte, Leiste, Sheet, Knopf) werden opak (`card` 100 %, Kopf-Karte `header-tint` 100 %, Leiste `card` 100 %), kein Blur, Welt ohne Körnung, Dunst, Sterne und Sonne/Mond (ruhiger Verlauf), Ränder `border-control` hoher Kontrast ≥ 4,3:1. Quelle: Systemoption (hoher Kontrast; iOS „Transparenz reduzieren“ per Plattformaufruf) und ein App-Schalter in Profil → Darstellung („Transparenz reduzieren“).
- **Fallback ohne Blur-Unterstützung** (Plattform oder Leistung): wie „Transparenz reduzieren“ für die betroffene Fläche.

### 3.6 Bewegung
| Token | Wert |
|---|---|
| `dur-fast` / `dur-base` / `dur-slow` | 120 / 200 / 320 ms |
| `dur-celebrate` | höchstens 1800 ms |
| `curve` | `easeOutCubic`; **Feder** (`spring`, einmaliges Überschwingen ≤ 8 %, ≤ 600 ms) nur für Fortschrittsfüllung, Kugel-Pop, Zähler-Orb |
| `world-fade` | 30 Minuten linear |

Momente: **Feier** (Manny hüpft, 2–3 Sterne, Zähler zählt hoch, Haptik), **Fortschritt** (Balken füllt sich mit Feder), **Streak** (Flamme zuckt einmal), **Kugel-Pop** bei Abschluss, **Orb-Druck** beim Zählen. Keine Dauerschleifen (außer Fortschrittskreis eines laufenden Vorgangs nach E-3), kein Blinken > 3 Hz, keine Parallaxe der Welt. **Reduzierte Bewegung:** alle Federn, Hüpfer, Pops und die Weltüberblendung entfallen; Zustandswechsel sind Sofortwechsel oder Überblendung ≤ `dur-fast`; die Feier erscheint als statische Karte mit feiernder Manny-Pose und Text. Haptik und Ton lassen sich abschalten (Standard an).

## 4. Komponenten

| Komponente | Zweck und Aufbau | Neu/vorhanden |
|---|---|---|
| `WorldBackground` | Welt aus 3.1, eine gecachte Ebene (`RepaintBoundary`, `ExcludeSemantics`), nicht pro Karte | ersetzt `GlowBackground` |
| `HeaderCard` | Kopf-Karte E2: Titel (`title`), Untertitel (`secondary`, Weiß), Chips (Streak, Freeze), optional Fortschritt; Tönung nach 3.1; Radius 32 | neu |
| `GlassCard` | E1: `card` 92 %, Radius 28, Innenabstand 16 | vorhanden, neu gestaltet |
| `OrbNode` | Pfad-Kugel. Größen: Trainingstag 56, Wochenziel 62, Phasen-Abschluss 80, aktuell 92, Boss 104 dp. Zustände siehe unten | ersetzt `PathNode` |
| `FloatingNav` | Leiste mit Ruhe und Aktiv (4.1) | vorhanden, neu |
| `SideNav` | Seitenleiste Physio am Rechner (≥ 840 dp): gleiche Ziele, Glas wie Leiste, Label rechts vom Symbol | neu |
| `PrimaryPill` | Primärbutton: Verlauf Mandarine, Text `on-accent`, 56 dp, Lichtkante oben, Schein unten (0/14/24, Mandarine 70 %), kein harter Rand; Gedrückt: 2 % kleiner, Schein halb; Deaktiviert: Weiß 50 % mit `ink-2`-Text und Rand | neu |
| `GlassPill` | Sekundärbutton, Weiß 90 % (ohne Blur), 52 dp, Rand `border-control`, Text `ink-1` | neu |
| `CuraChip` / `StatusChip` | 13 sp/700, Radius Pille; Status immer mit Symbol; wählbare Chips ≥ 48 dp Hit-Area | vorhanden, neu |
| `RatingScale` | 5 Smileys, jeder mit Text-Label (Screenreader und sichtbar bei gewähltem Eintrag): „sehr schlecht … sehr gut“; Auswahl: 2 dp Rand Mandarine plus Haken-Punkt und `accent-soft` Fläche | neu |
| `PainSlider` | 0–10, Wert als Text, Stufen per ± Schaltflächen bedienbar (ohne Gesten) | neu |
| `RepCounter` | Zähler-Orb 150 dp, Zahl `counter`; Tippen = +1, daneben Schaltfläche „−1 rückgängig“ | neu |
| `ExerciseRow` | Bildkachel 56, Name, Umfang, Material, Ort-Chips, Abhak-Kreis (Hit 48) | neu |
| `DailyCheckupCard` | siehe 7.2 | neu |
| `PatientTile` | Physio-Kachel: Titel, Kerninhalt, Detail-Chevron; Tipp öffnet Detail | neu |
| `MannyIllustration` / `MannyButton` / `MannyBubble` | siehe Abschnitt 6 | ersetzt `MannyPlaceholder` |
| `Sheet` | Radius 32 oben, `card` 100 % opak, kein Blur, Griff, Schließen-Schaltfläche 48 dp, Fokus gefangen | vorhanden, neu |
| `Dialog` | opak `card`, Radius 28, Scrim `ink-1` 45 %, Primäraktion rechts oder oben, Abbrechen immer vorhanden; Warn-Dialoge neutral (kein Mandarine) | vorhanden, neu |
| `Snackbar` („Eingetragen. Rückgängig“) | wie v1 Ergänzung 1, `card` opak, 6 s | vorhanden, neu |

**`OrbNode`-Zustände:** *Erledigt* (Perlglas, Haken `#8A3A0C`), *Aktuell* (Mandarine-Kugel mit Halo, dunkle Flagge, Tipp → Heute), *Gesperrt* (Grauglas, Schloss `ink-2`, Tipp → Hinweis), *Ziel/Boss* (Gold, Stern `#B8470F`-Ton, gesperrt oder aktiv), *Phasen-Abschluss* (80 dp, Stern). Jeder Zustand hat Symbol und Label (nicht nur Farbe); Screenreader: „Tag 12, erledigt“, „Heute, aktuell“, „gesperrt“, „Ziel Return to Sport, gesperrt“.

### 4.1 Leiste (`FloatingNav`)
- **Ruhe:** Glas 35 % (Tag) bzw. 45 % dunkel (Nacht), Blur σ 30, Lichtkante, Schatten weich. Darunter liegt ein Schleier (150 dp hoch, 70 % `world-floor`), damit der Untergrund begrenzt bleibt. Label und Symbole `nav-ink`, Gewicht 700, Linienstärke 2,2 dp.
- **Aktiv:** Glas 78 % (Nacht 82 %). Auslöser: Tipp oder Fokus in der Leiste, Beginn eines Scrolls des Inhalts, Screenreader-Fokus. Rückkehr zu Ruhe nach 2 s ohne Interaktion. Wechsel in `dur-base`, bei reduzierter Bewegung sofort. In Ruhe und Aktiv gleich: Größe, Positionen, Hit-Areas, Fokusring.
- **Aktiver Tab:** Pille 56 dp hoch, Mandarine-Verlauf, Label und Symbol `on-accent` (≥ 6,5:1), Text immer sichtbar. Alle Tabs zeigen Symbol **und** Label.
- **Chats:** Ungelesen-Zähler als Zahl im Badge (`#B3261E` mit weißem Text und Rand), Screenreader „Chats, 2 ungelesen“.
- **Profil:** Avatar (Initialen) statt Symbol.
- Fallbacks (3.5): opak bei „Transparenz reduzieren“/Hoher Kontrast.

## 5. Navigation
**Patient:** Pfad · Heute · Feed (ab Ausschnitt 4, davor 4 Ziele ohne Lücke) · Chats · Profil. Begründung: tägliche Schleife links, soziale und persönliche Ziele rechts, Instagram-nah. Startziel: Pfad. Die Leiste ist auf Hauptscreens sichtbar, **nicht** in der Session, in Chat-Vollbildern, Onboarding und Sheets/Dialogen (dann nicht fokussierbar). Zurück-Verhalten: Tab-Wechsel behält Scroll-Position je Tab.
**Manny-Zugang:** (1) Tipp auf Manny auf dem Pfad, (2) Manny-Knopf (Kopf, 56 dp, rechts 18 dp, 16 dp über der Leiste) nur auf Pfad und Heute, (3) in Chats immer angeheftet als oberste Unterhaltung (nicht entfernbar). Manny bekommt keine eigene Tastaturstation zusätzlich zum Manny-Knopf.
**Physio:** Patienten · Übungen · Chats · Konto. Am Handy Leiste unten wie oben (4 Ziele), am Rechner (≥ 840 dp Breite) Seitenleiste links 240 dp mit denselben Zielen, Inhalt bis 1200 dp mittig. Gleiche Welt, ruhiger (3.1).

## 6. Manny
**Stilregeln (Variante A „Lässig“, Platzhalter-Skizze bis Rechte geklärt):** flacher Sticker-Stil, gleichmäßige sehr dunkle Kontur (Marine `#0B1020`, etwa 4–5 px bei 390 Breite), wenige Flächen mit einem Schattenton, Körper Blau-Grau `#2A3A57`, Bauch Creme `#FFF1D8`, Schnabel und Füße Orange `#FF9A2E`, **schwarze Sonnenbrille** als Markenzeichen, kein Stirnband, breites Grinsen, lässige Haltung leicht schräg (−7°), lange seitliche Flügel, breite Füße. Der Kopf bleibt klar vom Körper abgesetzt. Quelle der Skizze: `mockups/v2-src/manny4.py` (Variante A); Vorbild nur als Stil-Inspiration, nichts übernommen.
**Umsetzung:** feste Illustrationen je Pose (WebP/PNG mit Transparenz, 1x/2x/3x), Bewegung im Code (Hüpfen, Quetschen, Wippen), kein Lottie/Rive. Kleine Größen (Knopf 56, Avatar 48, 40) brauchen vereinfachte Köpfe mit Kontur ≥ 3 px. Die Brille wird bei Trösten, Schlafen und Denken abgesetzt bzw. hochgeschoben.
**Verwendung:** Manny ist nie modal und blockiert nichts; Sprechblase höchstens 2 Sätze, X ≥ 48 dp, höchstens einmal pro Anlass und Tag (v1 UI-23 bleibt). Manny reagiert nicht auf Stimmungswerte gegenüber dem Patienten (Spec C-3); er reagiert auf Schmerzmeldung in der Session mit Trösten. Erinnerungen nie schuldzuweisend.

| Pose | Einsatz | Im Entwurf |
|---|---|---|
| Standard (lässig) | Chat-Avatar, Pfad, Onboarding | ja |
| Begrüßen | Tagesbeginn, Moin-Blase | neu zu zeichnen |
| Feier (Arme hoch, Sterne) | Session-Ende, Streak, Meilenstein | ja |
| Ziel (Fahne) | aktuelle Station, Boss | neu |
| Erinnerung | freundliche Erinnerung | neu |
| Training-Begleiter (läuft, Rucksack) | Session, Packliste | neu |
| Trösten (Brille ab, Hand auf der Brust) | Schmerz melden, schlechter Tag | ja |
| Denken (Brille hoch) | Chat „schreibt“, Laden | neu |
| Schlafen | Ruhetag, Nacht | neu |
| Kopf (Knopf 40/56/80) | Manny-Knopf, Chat-Liste | ja (nur Standard) |
Bildbeschreibung für Screenreader: „Manny, dein Begleiter“ (nicht doppelt zur Blase); reine Zierbilder ausgeblendet.

## 7. Screens
Für alle Screens gilt: Welt als Hintergrund (Physio ruhiger), Kopf-Karte oben, Inhalt scrollt unter der Leiste, letzter Inhalt ist über der Leiste vollständig erreichbar (Reserve = Leiste + 16 dp), Zustände Laden (statische Platzhalter, höchstens 300 ms ohne Shimmer), Leer, Fehler („… konnte nicht geladen werden“ mit „Nochmal versuchen“, Symbol plus Text) und Erfolg sind gestaltet.

### 7.1 Pfad
Kopf-Karte: „Woche N“, „Phase M · Verletzung“, Chips Freeze (0–2, Symbol ❄) und Streak (Flamme, Zahl), Wochenbalken „N von 7 Tagen“; Zustand „eingefroren“ zusätzlich als Wort. Darunter die Welt mit `OrbNode`s entlang einer geschwungenen gestrichelten Linie (Zukunft oben); Beschriftungen als Label-Chip. Manny steht neben der aktuellen Kugel (rechts, links bei Platzmangel); Tipp öffnet den Chat. Beim Öffnen ist die aktuelle Kugel auf ca. 55 % der Höhe zentriert. Hinter dem Boss der Ausblick „Danach: Prävention & Gesundheitssport“ (Verhalten und Texte der Ergänzung 3, kein Unit). Beispielpfad bleibt als „Beispielpfad“ gekennzeichnet. Tipp auf Kugeln wie bisher (aktuell → Heute, übrige → Hinweisblase mit Schließen). Streak-Zustände und Freeze-Anzeige wie v1.

### 7.2 Heute inkl. Tages-Check-up
Kopf-Karte „Heute, <Name>“, Datum, Streak. **`DailyCheckupCard`** (einmal täglich, Spec C-2): Titel „Wie geht’s dir heute?“, Zusatz „Einmal am Tag · 5 schnelle Fragen“, Schließen (X, 48 dp). Fünf Fragen nacheinander: Wohlbefinden (`RatingScale`), Schmerz 0–10 (`PainSlider`), Motivation (`RatingScale`), Einschränkungen (Auswahl-Chips oder „keine“), Stimmung (`RatingScale`). „Weiter“ pro Frage; Fortschritt „Frage 2 von 5“ als Text. Nach dem Ausfüllen wird die Karte klein („Erledigt, danke!“), nach Schließen kommt sie erst am nächsten Tag wieder. Stimmung wird nur erfasst, Manny reagiert nicht darauf (C-3). Ab der Schmerzschwelle gilt die Kürzungsregel E-36; das Tagesprogramm zeigt den Hinweis „Heute etwas kürzer“.
**Trainingskarte:** Überschrift „Dein Training“, „ca. N Min · x von y“, Zeitwahl 10/20/30 (20 vorgewählt, Segment ≥ 48 dp). Je `ExerciseRow` Bild (Platzhalter-Illustration, nie leere Fläche), Name, Umfang, Material, Ort-Chips („Zuhause · Praxis“), Abhak-Kreis; Tipp auf die Zeile öffnet das Übungsdetail (Bilder Start/Ende, Beschreibung, Grenzen, Material, Ort) mit Tauschen/Entfernen (Rückgängig) wie v1. Termin-Karten (Physio blau, Arzt lila) mit Streifen, Symbol, Label, Titel, Uhrzeit wie v1. **„Training starten“** (`PrimaryPill`) startet die Session; **Abhaken** direkt in der Liste ist der zweite Weg. Erste abgehakte Übung zählt für den Streak (T-5); „Fertig für heute“ erscheint nach der letzten; Abhaken ist am selben Tag rückgängig. Leer: „Heute noch nichts geplant.“ mit „Eigene Übung“, „Training starten“ deaktiviert. Tageswechsel wie Ergänzung 1.

### 7.3 Geführte Session (Vollbild, ohne Leiste)
**Packliste** zuerst: „Du brauchst heute: …“ mit abhakbaren Punkten (Manny als Begleiter), fehlt etwas: Übung tauschen (nur freigegebene Übung derselben Phase), „Los geht’s“. **Übungsbildschirm:** oben Schließen, segmentierter Fortschritt „Übung 2 von 5“ (Text sichtbar), Gesamtzeit; Karte mit großem Übungsbild (Start-/Endposition, sonst Illustration), Name, Kurzanleitung, Chips (Material, Ort, „Satz 2 von 3“); in der Mitte `RepCounter` „7 / 12“; bei Zeitübungen Countdown im Orb mit Ansage „noch 10 Sekunden“, Ton und Vibration am Ende (abschaltbar); Manny kommentiert kurz. **Satz fertig:** Pausen-Timer (Dauer vom Physio, Orb zeigt Restzeit, „Überspringen“). **Übung fertig:** kurze Feier (Kugel-Pop, Segment füllt sich), automatisch nächste Übung. Unten immer: Pause (alle Timer halten), Überspringen (gilt als nicht erledigt), Schmerz melden (Sheet: nur freigegebene leichtere Variante oder Abbruch, Manny-Pose Trösten); Schließen oder Beenden fragt per Dialog, Erledigtes wird gespeichert (T-5). **Ende:** Zusammenfassung (Gesamtzeit, Übungen, Streak) mit Manny-Feier, dann Check-up. App im Hintergrund oder Sperre: Session pausiert an derselben Stelle; Offline läuft alles, Ergebnisse gehen über die Warteschlange. Alles ohne Gesten bedienbar.

### 7.4 Check-up nach der Einheit
Manny feiert, Titel „Geschafft, <Name>!“, Chips Zeit, Übungen, Streak. Pflicht: „Wie lief’s?“ mit `RatingScale` (5 Smileys mit Label). Optional „Details je Übung?“ klappt auf: je Übung leicht/passend/schwer/Schmerz (Segment) und Schalter „Gewicht erhöht“; bei übersprungenen Übungen „Warum übersprungen?“ (Zeit/Schmerz/Material fehlte/anderes). „Speichern“ (`PrimaryPill`, aktiv sobald Pflichtfrage beantwortet), „Später“ (Karte bleibt auf Heute bis Tagesende). Nach dem Speichern: Snackbar „Gespeichert“, Rückkehr zu Heute oder Pfad.

### 7.5 Checkliste
Ist das Abhaken auf Heute (7.2, Ablauf 3 der Produktspec). Die Packliste der Session (7.3) nutzt dieselbe `ExerciseRow`-Optik mit Kreis statt Bild. Abgehakt: gefüllter Kreis mit Haken und durchgestrichen nicht erforderlich, Zustand per Symbol und Screenreader („erledigt“).

### 7.6 Profil
Kopf-Karte mit Avatar-Kugel (Initiale), Name, „Verletzung · Phase · Woche“. Drei Kacheln (Streak, Trainingstage, Freezes). Liste: Mein Plan und meine Verletzung · Frage an meinen Physio (Zahl offener) · Deine Daten (Sheet, v1 Ergänzung 1, E-5) · Erinnerungen · **Darstellung** (Welt: Automatisch/Morgen/Mittag/Abend/Nacht · Thema: System/Hell/Dunkel · Transparenz reduzieren · Ton · Vibration) · Hilfe und Datenschutz. Jede Zeile ≥ 56 dp hoch, Chevron.

### 7.7 Chats
Kopf-Karte „Chats“. **Manny angeheftet oben** (Kopf-Avatar, „Angeheftet“-Symbol mit Text), darunter Physio, Arzt, Praxis-Team: Avatar mit Initialen (keine Personenfotos), Name, Rolle, letzte Nachricht (eine Zeile), Zeit, Ungelesen-Zahl. Tipp öffnet Vollbild-Chat (ohne Leiste; Verhalten und Bausteine von Ergänzung 2 bleiben, neu gestaltet: eigene Blasen `card`, Eingabeleiste `GlassPill`). Der Manny-Chat ist privat; der Physio sieht ihn nie. Beispieldaten sind als „Beispieldaten“ gekennzeichnet, solange keine echte Funktion besteht.

### 7.8 Physio-Patientenliste
Kopf-Karte „Patienten“, Reiter „Meine Patienten“ / „Praxis“ (Segment), Suchfeld (Name), Zeilen: Avatar (Initialen), Name, Verletzung · Phase, letzter Termin, **Warnzeichen-Marker mit Symbol und Text** (in beiden Reitern), Chevron. „Neuer Patient“ als `PrimaryPill`. Warn-Inhalte neutral und opak, kein Akzent.

### 7.9 Physio-Patientenübersicht (Kacheln)
Kopf-Karte: Name, Verletzung · Woche · Phase, „Letzter Termin vor N Tagen“. Darunter ein Slot „KI-Kurzbriefing“ (Kachel 1, erst Ausschnitt 3). Kacheln 2–8 aus PB-3 in dieser Reihenfolge, **am Handy eine Spalte**, am Rechner dreispaltig ohne Scrollen: Befinden · Motivation · Warnzeichen (offene Warnzeichen zuerst, Symbol + Text) · Schmerz-Trend (30 Tage, Linie, Wert als Text) · Training seit dem letzten Termin (Tage im Verhältnis, Streak, übersprungene mit Grund) · Übungen gut/schlecht (Chips mit Symbol) · Phase und nächstes Ziel · Fragen des Patienten („besprochen“-Markierung) · Notiz vom letzten Termin (Autor, Datum). Tipp auf eine Kachel öffnet das Detail (Sheet am Handy, Seitenpanel am Rechner). Inhalte des Manny-Chats erscheinen nirgends. Historie (PB-G) erreichbar über „Historie“ in der Kopf-Karte.

### 7.10 Baukasten (Übung anlegen)
Formular als Karte(n), Pflichtfelder Name und Beschreibung zuerst, weitere als Abschnitte: Zeit/Sätze/Wiederholungen/Gewicht, Pausendauer, Hilfsmittel (Chips), Ort (Mehrfachauswahl Zuhause/Praxis/Fitnessstudio), „Damit anfangen“ (Schalter, Erklärtext: ja = ab sofort aktiv, nein = vorbereitet), Bilder (hochladen, auswählen; KI-Bild später), Zuweisung an Patienten mit Phase. Speichern ist `PrimaryPill`, die Übung ist praxisweit wiederverwendbar. Am Rechner zweispaltig (Formular links, Vorschau der Patientenansicht rechts).

### 7.11 Neuer Patient in 30 Sekunden (QR)
Ein Screen: Vorname (Pflicht), Verletzung oder Plan-Vorlage (Pflicht), „Anlegen“. Danach sofort QR-Code (mindestens 200 dp, hoher Kontrast Schwarz auf Weiß, quiet zone ≥ 4 Module), Link, „Teilen“ (SMS, Mail, Messenger) und „Fertig“. Alles Weitere später ergänzbar. Fehler (z. B. offline): Hinweis mit „Nochmal versuchen“, nichts geht verloren.

### 7.12 Feed (ab Ausschnitt 4)
Platz in der Leiste ist reserviert (5. Ziel). Gestaltung folgt in einem eigenen Entwurf; bis dahin fehlt das Ziel ohne Platzhalter.

## 8. Accessibility (Querschnitt)
- Semantik: eine Überschriftenhierarchie je Screen (Kopf-Karte = Überschrift Ebene 1); Listen als Listen; Tabs mit Rolle „Tab“ und Zustand „ausgewählt“; Karten fokussierbar nur wenn sie tippbar sind.
- Fokus: sichtbar (3 dp), Reihenfolge = visuelle (Kopf-Karte → Inhalt → Leiste), bei Sheets/Dialogen gefangen, bei Schließen zurück zum Auslöser. Welt, Dunst, Sterne und Zierobjekte `ExcludeSemantics`.
- Labels: Kugeln, Zähler („7 von 12 Wiederholungen, tippen zum Zählen“), Timer, Smileys (Text je Stufe), Slider („Schmerz, 3 von 10“), Warnmarker („Warnzeichen: Schmerz an 3 Tagen“), Fortschritt („Übung 2 von 5“).
- Zustand nie nur durch Farbe (UI-18/19 bleiben): Warn-, Status- und Auswahlzustände haben Symbol und Text.
- 200 % Schrift: nichts abgeschnitten, Primärbutton erreichbar, Zähler-Orb wächst nicht über den Bildschirm (Zahl skaliert bis 130 %), Leiste-Labels bei 130 % begrenzt.
- Reduzierte Bewegung, reduzierte Transparenz, hoher Kontrast: siehe 3.5/3.6.
- Ton und Vibration abschaltbar; keine reine Ton-Information.

## 9. Technische Hinweise
- Neue/Umbau-Tokens in `lib/theme/*` (`cura_colors.dart`, `tokens.dart`, `cura_typography.dart`, `cura_motion.dart`, `cura_metrics.dart`, `cura_roles.dart`, `contrast.dart`); `glow.dart` entfällt, `cura_blur.dart` zählt bis 3. Keine neuen Abhängigkeiten ohne Grund; Fonts schon gebündelt.
- Welt als eine `CustomPainter`-/Bild-Ebene mit Cache; Ebenen-Weichzeichnung vorab (nicht pro Frame); Weltwechsel nur per Minuten-Timer; Blur-Zähler als Test.
- Zeit: lokale Gerätezeit; Test mit fester Uhr.
- Illustrationen als Assets mit Lizenz-Hinweis; Platzhalter klar benennen.
- Zählen/Timer müssen im Hintergrund pausieren und Zeitstempel statt Dauern speichern (Spec).
- Physio-Bereich ist Flutter-Web am Rechner: Seitenleiste ab 840 dp, kein Hover-only.

## 10. Migration (was neu gezeichnet werden muss)
| Gebaut | Änderung |
|---|---|
| `lib/theme/*` (Farben, Rollen, Typo, Motion, Glow) | neue Tokens, Welt, Themen, Glow entfällt |
| `lib/ui/components/glow_background.dart`, `cura_blur.dart` | ersetzt durch `WorldBackground`, Blur-Zähler 3 |
| `floating_nav.dart`, `action_cluster.dart`, `messages_button.dart`, `manny_chat_button.dart` | Leiste 5 Ziele mit Ruhe/Aktiv, Manny-Knopf, Cluster entfällt |
| `glass_card.dart`, `category_card.dart`, `choice_card.dart`, `cura_chip.dart`, `cura_dialog.dart`, `cura_snackbar.dart`, `date_card.dart`, `cura_text_field.dart` | Optik nach 3.2/3.5 |
| `manny.dart`, `manny_bubble.dart`, `chat_avatar.dart`, `onboarding_manny.dart` | Variante A (Platzhalter), Posenliste |
| `lib/ui/path/*` | Glas-Kugeln, Kopf-Karte, Welt |
| `lib/ui/today/*` | Check-up-Karte, Übungszeilen mit Bild/Material/Ort, Session-Einstieg (Session, Packliste, Check-up nach der Einheit sind neu) |
| `lib/ui/home/home_shell.dart`, `lib/ui/routes/*` | 5 Ziele, Leisten-Sichtbarkeit je Route |
| `lib/ui/messages/*`, `lib/ui/chat/*` | Chats-Tab mit Manny angeheftet |
| `lib/ui/onboarding/*`, `lib/ui/data_sheet/*` | Optik, Verhalten bleibt |
| Neu | Profil, Session, Check-up, Physio-Bereich (Liste, Kacheln, Baukasten, neuer Patient), Darstellung |
| **Goldens** `test/golden/goldens/*` (u. a. `nav_cluster*`, `controls*`, `surfaces*`, `glow`, `typo_board`, `manny_poses`, alle `scenario_*`) | alle neu erzeugen (Welten × Thema × hoher Kontrast); `glow.png` entfällt |
| Tests `test/theme`, `test/static`, `test/components` | Kontrast-, Blur-, Token-Tests auf die neuen Werte umstellen (V2-3 bis V2-9) |

## 11. UI-Akzeptanzkriterien
**Tokens und Welt**
- V2-1: Alle Farben, Abstände, Radien, Schriften kommen aus Tokens; außerhalb der Token-Datei gibt es kein `Color(0x…)` und keine festen Schriftgrößen (Code-Suche).
- V2-2: Jede der 4 Welten rendert mit den Tokens aus 3.1; Stichprobe der Himmelsfarbe oben und der Bodenfarbe unten entspricht der Tabelle (Screenshot oder Token-Dump).
- V2-3: Ein Test berechnet die Kontraste aus 3.1 (Kopf-Karte weiß, Label-Chip, Leiste Ruhe/Aktiv je Welt gegen Schwarz, Weiß, Mandarine) und schlägt unter 4,5:1 fehl.
- V2-4: Ein Test berechnet die Kontraste aus 3.2 für Hell und Dunkel auf der Karte (92 %) im Worst Case, für `ink`/`text`, `accent-text`, `success-text`, `error-text` und Kategorie-Töne, und schlägt unter 4,5:1 fehl; Bedienränder unter 3:1 ebenso.
- V2-5: Kein Text steht direkt auf der Welt: Jeder Text-Widget-Vorfahre ist `HeaderCard`, `GlassCard`, `FloatingNav`, `Sheet`, `Dialog` oder Label-Chip (Code-Prüfung und Screenshot der Screens aus 7 in allen 4 Welten).
- V2-6: Zeitregel: bei Testzeiten 04:59, 05:00, 09:44, 09:45, 10:00, 10:15, 16:44, 17:00, 20:45, 21:00, 21:15, 05:15 liefert die Weltfunktion die Phase bzw. die Mischung nach 3.1 (Unit-Test mit fester Uhr; außerhalb der 30-min-Fenster reine Phase, in der Mitte 50:50).
- V2-7: Die Einstellung „Welt“ (Automatisch/Morgen/Mittag/Abend/Nacht) wirkt sofort; ein fester Look wird nicht überblendet und bleibt nach App-Neustart erhalten.
- V2-8: Welt und Thema sind unabhängig: Welt Nacht mit Thema Hell zeigt helle Karten (`card` Weiß 92 %) und dunkle Kopf-Karte und Leiste; Welt Mittag mit Thema Dunkel zeigt dunkle Karten.
- V2-9: Zwischen den Hügelebenen gibt es keine hart gezeichnete Kontur und kein Segment mit Kantensprung (Screenshot-Prüfung, vergrößert).

**Glas und Blur**
- V2-10: Pro Screen sind höchstens 3 `BackdropFilter` gleichzeitig im Baum (Widget-Test pro Screen in Welt Abend und Nacht); Karten, Chips, Zeilen, Kugeln und Session-Buttons enthalten keinen.
- V2-11: Sheets und Dialoge sind opak (`card` 100 %) und enthalten keinen Blur; Blur kommt nur in Leiste, Kopf-Karte und Manny-Knopf vor (Code-Suche).
- V2-12: Mit „Transparenz reduzieren“ oder Hoher Kontrast sind Kopf-Karte, Leiste, Sheet und Manny-Knopf opak, kein `BackdropFilter`, die Welt ohne Körnung, Dunst, Sterne und Sonne/Mond, Ränder ≥ 4,3:1 (Widget-Test und Screenshot).
- V2-13: Triage- und Fristen-Screens sind opak und ohne Welt und ohne Mandarine-Button (Code-Prüfung, bleibt aus v1).
- V2-14: Pro Frame wird die Welt nicht neu gezeichnet (eine `RepaintBoundary`, Profil-Messung des Entwicklers dokumentiert, keine dauerhaften Frames über 16 ms durch Blur auf einem Mittelklassegerät).

**Leiste und Navigation**
- V2-15: Die Leiste zeigt für Patienten Pfad, Heute, Chats, Profil und ab Ausschnitt 4 zusätzlich Feed in dieser Reihenfolge; Physio: Patienten, Übungen, Chats, Konto. Jeder Tab zeigt Symbol und Label.
- V2-16: In Ruhe hat die Leiste 35 % Glas (Nacht 45 % dunkel), nach Tipp, Fokus oder Scrollbeginn 78 % (Nacht 82 %), nach 2 s ohne Interaktion wieder Ruhe (Widget-Test mit fester Uhr).
- V2-17: Unter der Leiste liegt ein 150-dp-Schleier mit 70 % `world-floor`; Label und Symbole der Leiste erreichen in Ruhe im Worst Case ≥ 4,5:1 (V2-3).
- V2-18: Größe, Position, Hit-Areas und Fokusring der Leiste ändern sich zwischen Ruhe und Aktiv nicht.
- V2-19: Die Leiste ist auf Session, Chat-Vollbild, Onboarding und unter Sheets/Dialogen nicht sichtbar bzw. nicht fokussierbar.
- V2-20: Chats-Tab zeigt bei ungelesenen Nachrichten eine Zahl und der Screenreader sagt „Chats, N ungelesen“.
- V2-21: Manny ist erreichbar über Tipp auf Manny im Pfad, den Manny-Knopf (nur Pfad und Heute) und den angehefteten Eintrag in Chats; Manny hat keine zusätzliche Fokusstation neben dem Knopf.
- V2-22: Am Rechner (≥ 840 dp) zeigt der Physio-Bereich eine Seitenleiste mit denselben vier Zielen; darunter die Leiste unten.

**Zielgrößen, Schrift, Bewegung, Screenreader**
- V2-23: Alle antippbaren Elemente haben eine Hit-Area ≥ 48 × 48 dp und ≥ 8 dp Abstand (inkl. Smileys, Abhak-Kreise, X der Karte, Chips, Segmente, ±-Schaltflächen).
- V2-24: Bei Systemschrift 200 % ist auf allen Screens aus 7 alles lesbar, nichts abgeschnitten, der Primärbutton und die letzte Zeile erreichbar; Leiste-Labels auf 130 % begrenzt.
- V2-25: Bei 320 × 568 dp ist jede Funktion erreichbar, kein horizontales Scrollen.
- V2-26: Mit „Bewegung reduzieren“ gibt es keine Feder-, Hüpf-, Pop-, Schiebe- oder Überblend-Animationen länger als 120 ms; die Weltüberblendung entfällt; die Feier erscheint als statische Karte mit Manny-Pose „Feier“ und Text (Ausnahme nur Fortschrittskreis nach E-3).
- V2-27: Kein Element blinkt mehr als 3 Mal pro Sekunde; es gibt keine Dauerschleifen außer dem Fortschrittskreis.
- V2-28: Mit TalkBack/VoiceOver sind alle Screens aus 7 vollständig bedienbar; die Labels aus Abschnitt 8 werden vorgelesen, Welt und Zierobjekte nicht; der Fokus ist sichtbar (3 dp) und folgt der visuellen Reihenfolge.
- V2-29: Zustände sind nie nur durch Farbe erkennbar: Warnmarker, Statuschips, Auswahl und Kugelzustände haben Symbol und Text (Graustufen-Screenshot und Simulation von Rot-Grün-Schwäche).
- V2-30: Kein Text unter 13 sp oder Gewicht unter 400.

**Komponenten und Pfad**
- V2-31: Der Primärbutton hat Füllung Mandarine mit Text `#211B16` (Kontrast ≥ 6,5:1), 56 dp Höhe, keine harte Unterkante; Deaktiviert ist als Weiß 50 % mit Text und Rand erkennbar.
- V2-32: Orange als Text nutzt nur `accent-text`; Mandarine als Textfarbe kommt nirgends vor (Code-Suche).
- V2-33: Fortschrittsbalken und Regler zeigen den Wert zusätzlich als Text und haben einen Rand ≥ 3:1.
- V2-34: Der Pfad zeigt Kugeln in den Größen 56/62/80/92/104 dp mit den Zuständen Erledigt (Haken), Aktuell (Flagge, Halo), Gesperrt (Schloss), Ziel (Stern); jede mit Label oder Semantik-Text.
- V2-35: Die Kopf-Karte des Pfads zeigt „Woche N“, „Phase M“, Streak, Freeze (0–2) und „N von 7 Tagen“; im Zustand eingefroren steht zusätzlich das Wort „eingefroren“.
- V2-36: Beim Öffnen des Pfads ist die aktuelle Kugel sichtbar und ungefähr vertikal zentriert (±15 % der Höhe); Manny steht neben ihr, Tipp auf Manny öffnet den Chat.
- V2-37: Beispielpfad ist als „Beispielpfad“ gekennzeichnet, solange kein echter Pfad vorliegt; die Sprechblase hat X ≥ 48 dp und höchstens 2 Sätze.

**Heute und Check-up-Karte**
- V2-38: Heute zeigt oben die Check-up-Karte, sofern heute nicht erledigt oder weggeklickt; fünf Fragen nacheinander mit „Frage N von 5“; nach Ausfüllen „Erledigt, danke!“ in kleiner Karte; nach Schließen am selben Tag nicht mehr, am nächsten Tag wieder.
- V2-39: Jede Smiley-Stufe hat ein Text-Label für Screenreader; die gewählte Stufe ist sichtbar durch Rand und Haken, nicht nur durch Farbe.
- V2-40: Der Schmerz-Regler ist ohne Gesten bedienbar (± Schaltflächen) und liest „Schmerz, N von 10“ vor.
- V2-41: Zeitwahl 10/20/30 Min ist sichtbar (20 vorgewählt); ein Wechsel ändert die Liste und „ca. N Min“ sofort.
- V2-42: Jede Übungszeile zeigt Bild (oder Illustration), Name, Umfang, Material, Ort-Chips und einen Abhak-Kreis; Tipp auf die Zeile öffnet das Detail mit Tauschen/Entfernen und Rückgängig.
- V2-43: Die erste abgehakte Übung zählt für den Streak; Abhaken ist am selben Tag rückgängig machbar; bei leerer Liste erscheint „Heute noch nichts geplant.“ mit „Eigene Übung“ und „Training starten“ ist deaktiviert.
- V2-44: Termin-Karten tragen Streifen, Symbol, Label, Titel und Uhrzeit in der Kategoriefarbe; Kategorie ist nicht nur an der Farbe erkennbar.

**Session und Check-up**
- V2-45: „Training starten“ öffnet erst die Packliste (abhakbar, „Los geht’s“), dann das Vollbild ohne Leiste; fehlendes Material erlaubt nur Tauschen gegen freigegebene Übungen derselben Phase.
- V2-46: Der Übungsbildschirm zeigt Schließen, Fortschritt „Übung N von M“ als Text, Gesamtzeit, Bild, Name, Kurzanleitung, Material, Ort, Satz N von M und den Zähler-Orb „x / y“.
- V2-47: Tippen auf den Orb zählt +1, „−1 rückgängig“ macht es rückgängig; der Screenreader liest „x von y Wiederholungen“; ohne Gesten bedienbar.
- V2-48: Bei Zeitübungen läuft ein Countdown mit Ansage „noch 10 Sekunden“ und Signal am Ende; Ton und Vibration sind abschaltbar und nie die einzige Information.
- V2-49: Nach dem letzten Satz startet der Pausen-Timer automatisch und ist überspringbar; nach der letzten Übung erscheint die Zusammenfassung mit Gesamtzeit, Übungen und Streak.
- V2-50: Pause hält alle Timer an; Überspringen markiert nicht erledigt; Beenden zeigt einen Dialog und speichert Erledigtes; Schmerz melden bietet nur die freigegebene leichtere Variante oder Abbruch und zeigt Manny in der Pose Trösten.
- V2-51: Wird die App im Hintergrund oder gesperrt, steht die Session beim Zurückkehren pausiert an derselben Stelle; offline läuft sie vollständig.
- V2-52: Der Check-up nach der Einheit hat als Pflicht nur „Wie lief’s?“ mit 5 beschrifteten Smileys; „Speichern“ ist erst nach Antwort aktiv; „Details je Übung?“ ist optional (leicht/passend/schwer/Schmerz, „Gewicht erhöht“, Grund bei übersprungenen); „Später“ lässt die Karte bis Tagesende auf Heute.

**Profil, Chats, Manny**
- V2-53: Profil zeigt Avatar-Kugel, Name, Verletzung, Phase, Woche, drei Kacheln und die Liste inkl. „Darstellung“ (Welt, Thema, Transparenz reduzieren, Ton, Vibration); jede Zeile ≥ 56 dp.
- V2-54: In Chats steht Manny immer als oberster, angehefteter Eintrag (nicht entfernbar); weitere Zeilen zeigen Initialen-Avatar, Name, Rolle, eine Vorschauzeile, Zeit, Ungelesen-Zahl; es gibt keine Personenfotos.
- V2-55: Der Manny-Chat bleibt privat: Inhalte erscheinen im Physio-Bereich nirgends.
- V2-56: Manny erscheint als Variante A (schwarze Sonnenbrille, dunkle Kontur, Creme-Bauch, orange Schnabel/Füße, kein Stirnband) in allen Posen der Tabelle 6 soweit geliefert; fehlende Posen fallen auf „Standard“ zurück; Platzhalter sind gekennzeichnet, solange keine lizenzierten Illustrationen vorliegen.
- V2-57: Manny blockiert nichts, ist nie modal, die Blase hat höchstens 2 Sätze und erscheint pro Anlass höchstens einmal pro Tag; bei Schmerzmeldung erscheint er als Trösten, bei Stimmungswerten reagiert er nicht.

**Physio**
- V2-58: Die Patientenliste hat Reiter „Meine Patienten“ und „Praxis“, ein Suchfeld nach Namen und markiert Patienten mit Warnzeichen in beiden Reitern mit Symbol und Text.
- V2-59: Die Patientenübersicht zeigt die Kacheln 2–8 aus PB-3 in der festgelegten Reihenfolge, am Handy in einer Spalte, am Rechner ohne Scrollen sichtbar; die Kachel „Befinden, Motivation, Warnzeichen“ zeigt offene Warnzeichen zuerst.
- V2-60: Ein Tipp auf eine Kachel öffnet deren Detail (Schmerz-Trend 30 Tage mit Werten, Übungen je Bewertung usw.); die Kachel „Training seit dem letzten Termin“ zeigt Verhältnis, Streak und übersprungene Übungen mit Grund.
- V2-61: Der Physio-Bereich nutzt dieselbe Welt in ruhiger Form (Ebenen 50 %, keine Sonne/Mond/Sterne/Körnung, Karten 96 %); Warn- und Statuskacheln sind neutral und opak.
- V2-62: Der Baukasten hat Pflichtfelder Name und Beschreibung und optional Zeit, Wiederholungen, Gewicht, Hilfsmittel, Ort, „Damit anfangen“ (mit Erklärtext), Bilder und Zuweisung an Patienten mit Phase.
- V2-63: „Neuer Patient“ verlangt nur Vorname und Verletzung oder Vorlage; nach „Anlegen“ erscheinen sofort QR-Code (≥ 200 dp, Schwarz auf Weiß, Ruhezone ≥ 4 Module), Link und „Teilen“; der Ablauf ist in unter 30 Sekunden schaffbar (Ablaufprüfung).

**Texte und Sprache**
- V2-64: Alle sichtbaren Texte sind Deutsch, „du“, kurz und nie klinisch; Beispieldaten sind als solche gekennzeichnet.

## 12. Annahmen
- Karte 92 % statt der in den Mockups skizzierten 80 %, damit farbiger Text im Worst Case besteht (3.2). Die Mockups bleiben Orientierung, nicht Pixelvorgabe.
- Das Thema (Hell/Dunkel) folgt dem System und ist in Profil überschreibbar; die Welt ist davon unabhängig.
- „Später“ im Check-up nach der Einheit hält die Karte bis Tagesende offen.
- Der Weltwechsel nutzt feste Zeiten nach lokaler Gerätezeit, keine Sonnenzeiten.
- Emojis dienen im Prototyp als Smileys (systemabhängig); eigene Manny-Gesichter wären eine spätere Option.
- Bildplatzhalter (Strichfigur, Bildkacheln) ersetzen Katalog- und Physio-Bilder.

## 13. Offene Entscheidungen und Rückfragen
1. **[blockierend für die Auslieferung, nicht für den Prototyp]** Rechte an den Illustrationen: Wer zeichnet oder liefert die finale Manny-Figur (alle Posen, Köpfe) und die 3D-Objekte (Flamme, Stern, Pokal), mit welchen Nutzungsrechten? Bis dahin laufen die Platzhalter, die als solche gekennzeichnet sind; die Etsy-Vorlage darf nicht verwendet werden.
2. Feed: eigener Entwurf in Ausschnitt 4 (Karten, Quelle und Datum, Moderation). *Annahme:* später.
3. Smileys: Emoji oder eigene Manny-Gesichter? **Entschieden (2026-10-14):** Emoji im Prototyp.
4. Thema-Override (System/Hell/Dunkel) im Profil: gewünscht oder nur System? **Entschieden (2026-10-14):** Override im Profil (System/Hell/Dunkel).
5. Plattformschalter für „Transparenz reduzieren“ (iOS-Systemoption) braucht einen Plattformaufruf; Android hat keine Entsprechung. **Entschieden (2026-10-14):** App-Schalter plus Hoher Kontrast reichen.

## 14. Nicht enthalten
Feed-Gestaltung, Community-Funktionen, KI-Kurzbriefing und Physio-KI (Ausschnitt 3), Übungsvideos, Tablet-spezifische Layouts des Patientenbereichs, Karte/Filter für Orte, ein vollständiger Entwurf der Onboarding- und Pfad-Texte (Texte aus v1 bleiben), echte Illustrationen und 3D-Objekte, Fotos von Personen.

## Errata (2026-10-16, nach Design-Abnahme L1, vom Nutzer bestätigt)

- **E-V2-1 zu V2-6 (Weltüberblendung):** Himmel, Hügel und Kopf-Karte mischen im 30-min-Fenster linear; Label-Chip und Leiste springen bei t = 0,5 auf die neue Phase, weil eine lineare Mischung dort nur ~1,02:1 Kontrast hätte. In jedem Moment gilt ein gemessenes Paar. Test bei t = 0,49/0,51.
- **E-V2-2 zu V2-26 (Bewegung reduzieren):** Es läuft keine Überblendung; öffnet man die App innerhalb eines Übergangsfensters, ist eine ruhende Mischfarbe zulässig.
- **E-V2-3 zu V2-24 (große Schrift):** Ab Textskalierung ≥ 1,5 läuft der Sheet-Kopf (Titel, „Schließen“) mit dem Inhalt; Griff und Ziehgeste entfallen; Schließen bleibt über Zurück, Tippen daneben, Escape und Fußleiste möglich. Gilt für alle Sheets.
- **E-V2-4 Kopf-Karten-Chips:** Füllung Schwarz 22 % statt Weiß 18 % (sonst ~3,9:1).
- **E-V2-5 Onboarding-Kopf-Karten-Titel:** Schritt 1 „Wie soll Manny aussehen?“, 2 „Wie heißt du?“, 3 „Datenschutz“, 4 „Was hat’s erwischt?“, 5 „Wann war es?“; „Zurück“ auch auf Schritt 1.
- **E-V2-6 Hoher Kontrast der Welt:** nur ruhiger Verlauf, ohne Hügelebenen, Sterne, Sonne, Dunst, Körnung.
- **E-V2-7 Übernommene Detailwerte:** Schatten E1 Spread −12, Deckkraft 16 % Hell / 45 % Dunkel; `GlassPill` in beiden Themen hell (Weiß 90 %, Tinte `#211B16`); Gold-Rand der Kugel `#F2BC3A`; Symbol der Kategorie-Kachel Weiß; im Hohen Kontrast weißer Rand der Kopf-Karte; Halo-Deckkraft folgt der Mondmenge der Welt.
