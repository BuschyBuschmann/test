# Design-Brief v2, Ergänzung 2: Code-Start, Akte, Einwilligung, Check-up mit sechs Fragen, Frage an meinen Physio

Status: **BRIEF ZUR FREIGABE** · Stand 2026-10-14 · Paket F2-D2 (Teil A und Teil B) · Grundlage: Flutter-Plan Ausschnitt 2 v2.2 (FREIGEGEBEN mit Auflagen N-17), Abschnitt 3.7 Teil A und Teil B mit den verwiesenen Abschnitten 6.9, 7.2, 8.1, 8.6, 8.7, 8.10, O-12 (6.9, 8.6) und den Nutzerentscheidungen N-14 bis N-17; `design-brief-v2.md`, `design-brief-v2-ergaenzung-1.md` (Manny), `grunddesign-v2.md`; Produkt: `curaone-ablaeufe-training-checkup.md`, `curaone-spezifikation-manny-gehirn.md`.

**Wirkung.** Diese Ergänzung gestaltet, was Brief v2 nicht gestaltet: den Einstieg mit Code (Teil A, gebraucht vor Lieferung L3), die Akte, Lade-/Fehler-/„nicht aktuell“-Zustände mit Backend, das Löschen mit Backend, und (Teil B, vor L5) den Tages-Check-up mit sechs Fragen, die „Frage an meinen Physio“ und die festen Hinweise. Sie **ersetzt** nur die in Abschnitt 0 genannten Stellen von Brief v2; alles andere gilt unverändert (Welt, Glas, Blur-Budget, Zielgrößen, Typografie, Warnkontext, Manny nach Ergänzung 1). **Keine neue Richtung:** gleiche Karten (`card` 92 %), Kopf-Karte, `PrimaryPill`, `GlassPill`, gleiche Tokens. Neue Werte nur als Tokens in `lib/theme/` (V2-1).

**Orientierung (Abend-Welt, 390 × 844, Skizzen mit Beispieldaten; maßgeblich ist dieser Text):**
`mockups/v2-e2-codestart-look.png` · `v2-e2-codestart-code.png` · `v2-e2-einwilligung.png` · `v2-e2-checkup-schwellung.png` · `v2-e2-checkup-einschraenkung.png` · `v2-e2-frage-physio.png` · `v2-e2-hinweis-heute.png` · `v2-e2-kachel2.png` · `v2-e2-pfad-ausgelassen.png`. Quellen: `mockups/v2-src/gen7.py`, Render `r9.js`. Die Mockups zeigen die Leiste ohne Feed-Ziel (Ausschnitt 2: vier Ziele).

---

## 0. Was ersetzt wird, was neu ist

| Stelle in Brief v2 / Ergänzung 1 | Wirkung dieser Ergänzung |
|---|---|
| 7.2, Zeile „Einmal am Tag · 5 schnelle Fragen“ | **ersetzt:** „Einmal am Tag · 6 schnelle Fragen“ |
| 7.2, „Fünf Fragen nacheinander: Wohlbefinden, Schmerz, Motivation, Einschränkungen (Auswahl-Chips oder ‚keine‘), Stimmung … ‚Frage 2 von 5‘“ | **ersetzt** durch B3: sechs Fragen, Reihenfolge Wohlbefinden · Schmerz · **Schwellung** · Motivation · **Einschränkungen (Einzelwert-Skala keine / leicht / deutlich / stark, keine Chips mehr)** · Stimmung; „Frage N von 6“ |
| **V2-38** | **ersetzt** (Text in Abschnitt 6, „V2-38 neu“) |
| 7.2, Satz „Ab der Schmerzschwelle gilt die Kürzungsregel E-36; das Tagesprogramm zeigt den Hinweis ‚Heute etwas kürzer‘“ | **konkretisiert** durch B5 (Schwelle Schmerz ≥ 6 laut Plan 8.7, Gestaltung des Hinweises) |
| 7.9, Kachel 2 „Befinden · Motivation · Warnzeichen“ | **ersetzt** durch B6: zeigt zusätzlich Schwellung und Einschränkungs-Stufe; Warnzeichen „Schwellung stark“ mit Symbol und Text |
| 7.8, Warnzeichen-Marker (Symbol und Text) | **ergänzt** um „Schwellung stark“ |
| Ergänzung 1, 6a/V2-65 bis V2-67 (Onboarding mit fünf Schritten) | **bleibt** für den Demo-Modus (B-20). Im Code-Start steht derselbe Look-Schritt als Schritt 1 (A1); Karten, Radio-Semantik und Vorbelegung unverändert |
| Brief 4, Komponenten | **ergänzt** um `StepScale`, `LevelGlyph`, `NoticeCard`, `CodeField`; `OrbNode` bekommt den Zustand *Ausgelassen* (A6) |
| Brief 7.6 Profil, Zeilen „Mein Plan und meine Verletzung“, „Frage an meinen Physio (Zahl offener)“ | **ausgeführt** (A7, B2) |

Nicht geändert: `RatingScale`, `PainSlider`, Zeitwahl, Session, Check-up nach der Einheit, Physio-Liste (außer Marker), Baukasten, Neuer Patient.

---

## 1. Gemeinsame Bausteine

### 1.1 `NoticeCard` (neu): Hinweiskarte
Eine eigene, **opake** Karte (`card` 100 %, kein Blur, keine Welt dahinter, Radius 24, Innenabstand 14/16 dp). Aufbau: Symbolkreis 36 dp links, Titel (`heading` 17 sp, falls vorhanden), Text (`body` 14,5 sp/Gewicht 500, nie unter 13 sp), optional eine Aktion (`GlassPill`, ≥ 48 dp, nie Mandarine). Das Symbol steht immer **mit** Text (V2-29). Varianten:

| Variante | Einsatz | Symbolkreis | Rand | Textfarbe |
|---|---|---|---|---|
| `info` | „Heute etwas kürzer“, Leerzustände | `ink-2` mit weißem Zeichen | keiner (Fläche `ink-1` 6 % in einer Karte) | `ink-1` |
| `stale` | „Nicht aktuell“ | `ink-2` (↻) | 1,5 dp `border-control` | `ink-1` |
| `error` | Ladefehler, Code-Fehler | `error-text` (!) | 2 dp `error-text` | `error-text` (Hell 5,5:1; weißer Grund 6,5:1) |
| `sync` | „Ein Eintrag konnte nicht gesendet werden“ | `ink-2` (↻) | 1,5 dp `border-control` | `ink-1` |
| `fixed-hint` | fester Hinweis zu Schmerz/Schwellung (B4) | `ink-1` mit weißem „!“ | 2,5 dp `ink-1` 70 % (6,3:1 auf Weiß) | `ink-1` |

Die Varianten `fixed-hint` und `error` folgen dem **Warnkontext** (Brief 2): opak, neutral, kein Mandarine-Button, kein Glas darunter, Orange nie Statusfarbe. Titel nie in Großbuchstaben, nie Rot/Orange als Füllung.

### 1.2 `StepScale` (neu): Stufenwahl mit vier Stufen
Einzelwahl für Schwellung (0–3) und Einschränkungen (keine/leicht/deutlich/stark). Bedienelement **bewusst keine Segmentleiste ohne Symbol und kein Regler**, weil die Stufen Wörter sind und der Wert zählt, nicht eine Strecke (Brief 3.2: Wert immer auch als Text).
- **Vier gleich große Kacheln** in einer Reihe (bei 390 dp je ca. 76 × 88 dp, Abstand 8 dp, Radius 20): oben `LevelGlyph`, darunter das Wort (`chip`-Größe 14 sp/700).
- **`LevelGlyph`** (neu, rein anzeigend, auch im Physio-Bereich nutzbar): drei aufsteigende Balken (Höhe 10/16/22 dp, Breite 9 dp, 2 dp Kontur `ink-1`); gefüllt = Stufe (keine: 0 gefüllt, leicht: 1, deutlich: 2, stark: 3). **Nur `ink-1`, keine Ampelfarben**: die Stufe wird nie über Farbe kodiert.
- **Ungewählt:** Fläche Weiß, Rand 2 dp `border-control` (3,8:1). **Gewählt:** Rand 3 dp Mandarine, Fläche `accent-soft`, Haken-Punkt 20 dp oben rechts, darunter Text „Ausgewählt: deutlich“ (nie nur Farbe, wie Ergänzung 1, 6a). Der Mandarine-Rand allein erreicht 3:1 nicht (2,6:1); die Auswahl ist deshalb durch Haken, Text und den weiterhin ≥ 3:1 liegenden Rand der Nachbarn eindeutig.
- **Semantik:** Radio-Gruppe, Gruppenlabel = Fragetext; je Kachel „keine, 1 von 4, nicht ausgewählt“ bzw. „deutlich, 3 von 4, ausgewählt“. Tastatur: ein Tab-Stopp in der Gruppe, Pfeiltasten wechseln, Leertaste wählt, Fokusring 3 dp um die Kachel (V2-23, V2-28). Hit-Area = ganze Kachel (≥ 48 dp).
- **Umbruch:** bei Breite < 360 dp oder Systemschrift > 130 % stehen die Stufen **untereinander** als Zeilen (56 dp hoch: Radio-Kreis links, `LevelGlyph`, Wort), wie die Look-Karten in Ergänzung 1, 6a. Nichts wird abgeschnitten (V2-24).
- **Beschreibungen je Stufe** gibt es nicht (nur die Wörter); siehe Offene Frage 9.

### 1.3 `CodeField` (neu, auf Basis `cura_text_field`)
Eingabefeld für den Einladungscode (Plan 6.5: 10 Zeichen Crockford-Base32, Anzeige `XXXXX-XXXXX`). Höhe 68 dp, Radius 22, Rand 3 dp `border-control` (Fehler: `error-text` **und** Symbol und Text darunter), Text `heading` 27 sp/800 mit 2 dp Buchstabenabstand, Schriftskalierung nur bis 130 % (wie die Zähler-Zahl, V2-24). Sichtbares Label „Dein Code“ **über** dem Feld (kein Platzhalter als einziges Label). Verhalten: Großschreibung automatisch; Leerzeichen, Bindestriche und Kleinschreibung werden toleriert; der Bindestrich nach dem 5. Zeichen wird automatisch gesetzt; Einfügen aus der Zwischenablage funktioniert; Autokorrektur, Vorschläge und Rechtschreibung aus; Tastaturtyp Text. Die Ersetzungen `O→0`, `I`/`L→1` macht die Eingabe still (Plan 6.5), ohne Hinweis.

### 1.4 Statuschips (vorhandener `StatusChip`)
Neue Texte, immer Symbol plus Text: `↻ Wird gesendet` · `⏸ Wartet auf Verbindung` · `✓ Gesendet` · `○ offen` · `✓ besprochen`. Ton: `chip-neutral` bzw. `chip-success` (7,3:1 bis 7,8:1); „Wird gesendet“ in `#FFE9D6` mit `#7A3A0C` (7,3:1). Orange nie als Statusfarbe: die Tönung dient nur der Unterscheidung, Bedeutung tragen Symbol und Wort.

---

## 2. Teil A: Zugang, Einwilligung, Akte, Zustände mit Backend (vor L3)

### A1. Code-Start (ersetzt das Onboarding für echte Zugänge)
Der Code-Start löst im Backend-Modus das Onboarding ab (Plan 8.1; Name, Verletzung und Datum kommen aus der Akte). Der Demo-Modus behält das fünfstufige Onboarding (B-20). Kopf-Karte wie im Onboarding: Fortschrittssegmente, „Schritt N von M“ (Text), Titel (`title` 28/30). Keine Leiste (V2-19).

| Schritt | Inhalt | Wann |
|---|---|---|
| 1 | **Wie soll Manny aussehen?** (Karten und Verhalten unverändert aus Ergänzung 1, 6a) | nur, wenn noch kein Look gewählt wurde (L1-Bestand wird nicht erneut gefragt, Plan 8.1) |
| 2 (bzw. 1) | **Zugang über deinen Physio** (A2) | immer |
| (Zwischenhinweis) | Neuanmeldungs-Hinweis (A4) | nur nach `ok_rebound`; zählt **nicht** als Schritt |
| 3 (bzw. 2) | **Was dein Physio sieht** (Einwilligung, A3) | immer |
| danach | Laden (A9), dann Pfad | |

- **M** = 3 mit Look-Schritt, sonst 2. Der Look-Schritt steht **vor dem Code-Feld** (O-43); in Schritt 2 steht Manny bereits in der gewählten Variante (Mockup `v2-e2-codestart-code.png`).
- **Zurück:** aus dem Code-Schritt zurück zum Look-Schritt (falls vorhanden) mit erhaltener Wahl; aus dem ersten Schritt wie bisher App verlassen (`SystemNavigator.pop`). **In der Einwilligung gibt es kein Zurück**, weil der Code dann schon eingelöst ist; Android-Zurück verlässt die App, ein Neustart setzt bei der Einwilligung fort (Konto ohne Einwilligung).
- **Look-Wert und Konto:** bei erster Bindung bleibt der lokal gewählte Look (Plan 8.1). Nach `ok_rebound` gilt der Look aus dem Konto (N-17, O-44 entschieden); weicht er vom eben gewählten ab, nennt der Neuanmeldungs-Hinweis das (A4).

### A2. Startbildschirm „Zugang über deinen Physio“ (`v2-e2-codestart-code.png`)
**Zweck (A-1):** Ohne gültigen Code kommt man nicht weiter; der Bildschirm erklärt, dass der Zugang vom Physio kommt.

Aufbau von oben: Kopf-Karte „Zugang über deinen Physio“ (Schritt N von M) · Manny `normal` 112 dp in der gewählten Variante mit Blase „Moin! Den Code bekommst du von deinem Physio.“ (≤ 2 Sätze, Blase ohne X, weil sie nicht wiederkehrt) · Karte mit `CodeField`, Label „Dein Code“, Fehlerblock darunter · Erklärkarte: „Dein Physio legt dich an und gibt dir einen Code oder QR-Code. Ohne Code geht es nicht weiter. Hast du einen Link bekommen, öffne ihn: Der Code steht dann schon im Feld.“ · unten Zurück (Glas, 112 dp) und **Weiter** (`PrimaryPill`, 56 dp). Es gibt **keinen** Weg an der Code-Eingabe vorbei und keinen In-App-QR-Scanner (nicht im Plan; der QR-Code wird mit der Kamera des Telefons gelesen und öffnet den Link).

**Zustände**

| Zustand | Darstellung |
|---|---|
| leer | `Weiter` deaktiviert (Weiß 50 %, Text und Rand, wie `PrimaryPill` deaktiviert); Screenreader-Hinweis am Knopf „Gib zuerst deinen Code ein“ |
| unvollständig (< 10 Zeichen) | `Weiter` deaktiviert; Zeichenzähler nicht nötig, der Bindestrich zeigt den Fortschritt |
| vollständig | `Weiter` aktiv |
| aus Link übernommen | Feld gefüllt, darunter `info`-Zeile „Code aus dem Link übernommen“ (Symbol + Text); eingelöst wird **erst nach Tipp auf Weiter** (B-8) |
| Prüfung läuft | Feld und Zurück deaktiviert; `Weiter` zeigt Fortschrittsring (E-3) und „Wird geprüft“ (Live-Region); Doppeltipp löst nur einmal aus |
| Fehler | Feldrand `error-text`, darunter Fehlerblock mit Symbol (!) und Text, Ansage als Live-Region; der eingegebene Code bleibt stehen, das Feld bleibt bedienbar |

**Ergebnisse von `redeem_invitation` und Fehler (Texte [Vorschlag], „du“, kurz, nie klinisch)**

| Ergebnis | Verhalten und Text |
|---|---|
| `ok` | weiter zur Einwilligung (A3) |
| `ok_rebound` | weiter zum Neuanmeldungs-Hinweis (A4), danach Einwilligung bzw. Laden (Annahme, Offene Frage 14) |
| `invalid` | „Dieser Code passt nicht. Prüfe ihn noch einmal oder frag deinen Physio.“ |
| `already_used` | „Dieser Code wurde schon benutzt. Bitte deinen Physio um einen neuen Code.“ (P-2 AK: bereits benutzter Code wird mit Hinweis abgelehnt) |
| `expired` | „Dieser Code ist abgelaufen. Bitte deinen Physio um einen neuen Code.“ |
| `too_many_attempts` | „Zu viele Versuche. Warte etwa 15 Minuten und versuche es dann noch einmal.“ (Bremse 5 Fehlversuche je 15 Minuten, N-6; kein Rest-Countdown, weil der Server keine Restzeit liefert) |
| `not_allowed` | „Das geht auf diesem Gerät gerade nicht. Starte die App neu und versuche es noch einmal.“ (Bedeutung offen, Offene Frage 7) |
| Netzfehler, Timeout, 5xx | „Keine Verbindung oder der Server antwortet nicht. Prüfe dein Internet und versuche es noch einmal.“ mit Schaltfläche **Nochmal versuchen** im Fehlerblock; der Code bleibt im Feld |

Der Fehlerblock nennt **nie**, ob ein Code „fast“ stimmt, und zeigt keinen Zähler der Fehlversuche.

### A3. Einwilligung `physio_sharing-2` (`v2-e2-einwilligung.png`)
Die Einwilligung folgt dem Einlösen (`accept_consent` braucht einen gebundenen Patienten, Plan 6.4). **Bis zur Einwilligung werden keine Patientendaten gesendet** (Plan 8.1: vor der Bindung nichts, danach nur, was der Ablauf verlangt). Aufbau: Kopf-Karte „Was dein Physio sieht“ (Schritt N von M; Untertitel „Hallo <Vorname>, ein letzter Schritt.“, der Vorname kommt aus der eigenen Patientenzeile) · Karte 1 „Damit dein Physio dich begleiten kann, sieht er:“ mit **Häkchenliste** (grüner Kreis mit ✓ `success-text`-Ton, 24 dp, mit Text; je Zeile fetter Stichwortanfang) · Karte 2 „Das sieht er nie“ mit ✕-Kreis (`ink-1`) · Karte 3 „Dein Recht auf Löschung“ (wie bisher im Onboarding: Löschen unter Profil → Deine Daten nimmt die Einwilligung zurück) · Primärknopf **„Ich bin einverstanden“** · Textlink „Datenschutzerklärung lesen“ (bestehende Seite).

**Wortlaut [Vorschlag, braucht Nutzerfreigabe, Plan 7.2 „Wortlaut F2-D2 A/Nutzer“]** — enthält ausdrücklich alle Punkte der Einwilligung `physio_sharing-2`:
1. **deinen Verlauf:** erledigte und übersprungene Übungen, bei übersprungenen mit Grund
2. **deine Check-ups:** Schmerz, Schwellung, Einschränkungen, Wohlbefinden, Motivation und Stimmung
3. **deine Fragen** an deinen Physio
4. **Warnzeichen,** zum Beispiel bei hohem Schmerz oder starker Schwellung. Auch Warnzeichen aus deinem Chat mit Manny, bis hin zu Hinweisen auf eine Krise. Dazu sieht er nur Stufe und Zeitpunkt, keinen Text aus dem Chat.
5. **eine Meldung zur Stimmung:** War sie an 5 Tagen mit Check-up hintereinander sehr schlecht (die zwei schlechtesten Smileys), bekommt er eine Meldung, an jedem weiteren Tag wieder. Details sieht er nicht. Ein Tag ohne Check-up beendet die Zählung; bei einer neuen Verletzung beginnt sie neu. Die App zeigt dir diese Meldung nicht an.
- **Das sieht er nie:** Deinen Chat mit Manny. Er bleibt privat.
- **Dein Recht auf Löschung:** Du kannst alles jederzeit löschen (Profil → Deine Daten). Dann nimmst du auch deine Einwilligung zurück.
- Darunter, wie bisher, der Hinweis „Platzhaltertext. Er wird vor dem echten Einsatz ersetzt.“ (nur Testdaten, Rechtsprüfung ruht bis echte Daten).

**Verhalten:** Kein Häkchenfeld, keine Vorauswahl, **eine ausdrückliche Handlung** (Tipp auf „Ich bin einverstanden“). Alle Punkte stehen vollständig sichtbar im Fließtext; nichts ist hinter „Mehr“ versteckt. Bei Systemschrift ≤ 130 % steht der Primärknopf fest unten (Inhalt scrollt dahinter, letzter Inhalt mit Reserve erreichbar); bei > 130 % steht er am Ende des Scrollinhalts. Es gibt **keinen Ablehnen-Knopf** (Annahme, Offene Frage 2): Unter dem Knopf steht kein Druck-Text, aber der Titel zeigt, dass der nächste Schritt die Einwilligung ist; wer nicht zustimmt, bleibt auf dieser Seite.
**Zustände:** *Senden:* Knopf mit Fortschrittsring und „Wird gesendet“, Rest deaktiviert. *Fehler* (`error`-Block über dem Knopf): „Das hat nicht geklappt. Versuch es noch einmal.“ mit Knopf „Nochmal versuchen“. *Offline:* „Ohne Verbindung geht das nicht. Verbinde dich und versuche es noch einmal.“ Erfolg: weiter zum Laden (A9).

### A4. Neuanmeldungs-Hinweise (beide Geräte; N-1, Annahme B-11)
Beide Hinweise sind **eigene Vollbild-Hinweise** (Kopf-Karte mit Titel, eine Karte mit drei kurzen Zeilen, ein Knopf), keine Toasts: Sie müssen gelesen werden.

**Neues Gerät (nach `ok_rebound`), Titel „Du bist neu angemeldet“** [Vorschlag]:
- „Dein Plan, dein Verlauf und deine Check-ups sind noch da.“
- „Dein Chat mit Manny bleibt auf dem alten Gerät und wird dort gelöscht.“
- „Manny sieht so aus wie bei dir zuvor: <Mit Brille / Ohne Brille>. Du kannst das im Profil ändern.“ (nur, wenn der Konto-Look vom zuletzt gewählten abweicht, B-36/N-17)
Knopf **„Verstanden“** (`PrimaryPill`, hier ohne Warnkontext, weil es nur Information ist). Fokus startet auf der Überschrift; die Karte wird beim Öffnen vorgelesen.

**Altes Gerät (Bindung gelöst, `access_deleted` oder gelöste Bindung beim nächsten Laden, Plan 8.2/B-11):** Die lokalen Daten sind schon gelöscht (inkl. Chat und Look-Vorbelegung). Vor dem Code-Start erscheint der Hinweis, **Titel „Du bist auf einem anderen Gerät angemeldet“** [Vorschlag]: „Die Daten auf diesem Gerät wurden gelöscht, auch dein Chat mit Manny. Um hier weiterzumachen, brauchst du einen neuen Code von deinem Physio.“ Knopf **„Weiter“** → Code-Start (beginnt wieder bei Schritt 1). Bei `access_deleted` (Zugang beendet): Titel „Dein Zugang wurde beendet“, Text „Die Daten auf diesem Gerät wurden gelöscht. Brauchst du wieder Zugang, frag deinen Physio nach einem neuen Code.“ Der Hinweis erscheint erst, wenn das Gerät die gelöste Bindung bemerkt (beim Start, Fortsetzen oder Öffnen von Heute), nicht sofort.

### A5. Leerzustand „Dein Physio stellt deinen Plan noch zusammen“
Gilt, wenn der Patient gebunden und eingewilligt hat, aber **kein Plan** oder **ein Plan ohne Phasen/Positionen** vorliegt (Plan 8.3, „Leerzustand“). Eine `GlassCard`/Karte mit Manny `normal` 120 dp, Titel „Dein Physio stellt deinen Plan noch zusammen“ (`heading`), Text „Sobald er fertig ist, siehst du hier deinen Pfad. Schau später noch einmal vorbei.“ und **`GlassPill` „Aktualisieren“** (≥ 52 dp; lädt neu, mit Ansage „Plan wird geladen“ / „Noch kein Plan“). Kopf-Karte ohne „Woche/Phase“: Titel „Pfad“, Untertitel = Verletzung aus der Akte, falls vorhanden.
- **Heute** zeigt dieselbe Karte statt der Trainingsliste („Training starten“ entfällt, nicht nur deaktiviert; V2-43 gilt für den Fall „Plan vorhanden, heute nichts“, dort bleibt „Heute noch nichts geplant.“).
- Der **Tages-Check-up bleibt verfügbar** (Annahme, Offene Frage 10): Er hängt nicht am Plan.
- Der Manny-Knopf bleibt, Manny sagt in diesem Zustand nichts Zusätzliches.

### A6. Pfad-Status „ausgelassen“ (`v2-e2-pfad-ausgelassen.png`)
**Definition (Annahme, Offene Frage 1):** Eine Einheit (Trainingstag, Wochenziel) einer **vergangenen Woche**, an der nichts erledigt wurde. Sie ist **nicht erledigt**, nicht gesperrt und nicht „aktuell“; die aktuelle Kugel bleibt die erste noch offene Einheit von heute an (Plan 8.3).
- **`OrbNode`-Zustand *Ausgelassen*:** gleiche Größenstufen wie die übrigen Kugeln; Perlglas auf 38 % Weiß, **gestrichelter Rand 3 dp** `ink-1` 55 % (gegen die Welt im Worst Case ≥ 3:1, per Test), Symbol ↷ (Bogenpfeil, `accent-text`-Ton `#8A3A0C`, nicht Rot, nicht Schloss, nicht Haken). Label-Chip: „Woche 4, Tag 1 · ausgelassen“. Er unterscheidet sich von *Gesperrt* (Grauglas, Schloss) durch Rand und Symbol, von *Erledigt* (Perlglas, Haken) ebenso.
- **Tipp** öffnet die Hinweisblase (`NoticeCard info`, X ≥ 48 dp): „Diesen Tag hast du ausgelassen. Das ist okay. Mach mit der aktuellen Einheit weiter.“ — **nie schuldzuweisend**, keine Zahl verpasster Tage, keine Wirkung auf den Streak nach außen angekündigt.
- **Screenreader:** „Woche 4, Trainingstag 1, ausgelassen.“ (Hinweistext beim Aktivieren).
- Streak-Logik und Kopf-Karte ändern sich nicht.

### A7. Akte „Mein Plan und meine Verletzung“ (A-4)
**Route** aus Profil → Zeile „Mein Plan und meine Verletzung“, Vollbild-Route mit Leiste (Tab Profil aktiv) und Zurück-Schaltfläche (48 dp) in der Kopf-Karte; Kopf-Karte: Titel „Mein Plan und meine Verletzung“, Untertitel „Verletzung · Phase · Woche“. Vier Karten, in dieser Reihenfolge:
1. **Verletzung und Plan:** Name der Verletzung, „Woche N“ (aus Bezugsdatum, B-3), Phase mit Titel und geplanten Wochen, darunter der **Plan-Überblick** als Liste der Phasen (Titel, „N Wochen“, Zahl der Übungen) mit der aktuellen Phase markiert (**Symbol ▶ und Text „aktuell“**), „Zuletzt von deinem Physio geändert: <Datum>“. Übungen selbst stehen weiter auf Heute (kein zweiter Weg).
2. **Behandler:** je Eintrag Initialen-Avatar (keine Fotos), Name, Rolle (Physio, Arzt, jeweils Text und Kategorie-Streifen/-Symbol wie Termin-Karten), Kontakt als **Text** (Telefon, E-Mail; keine Anruf-/Mail-Aktion, Offene Frage 8).
3. **Termine:** Liste (Datum, Uhrzeit, Titel, Ort, Kategorie-Streifen Physio blau / Arzt lila mit Symbol und Label wie V2-44). Einträge **von deinem Physio** tragen ein Schloss-Symbol und den Text „Von deinem Physio, nur lesen“; **eigene** Termine tragen „Von dir“ und eine Menü-/Bearbeiten-Schaltfläche (≥ 48 dp). **„Termin hinzufügen“** (`GlassPill`) öffnet ein opakes Sheet „Termin“ mit Titel (Pflicht), Datum und Uhrzeit (Pflicht), Ort (optional), Art (Physio · Arzt · Sonstiges) [Felder Annahme, Offene Frage 8], Speichern (`PrimaryPill`) und Schließen. Löschen eines eigenen Termins fragt per Dialog „Termin löschen?“ (Abbrechen immer vorhanden, Warn-Dialog neutral).
4. **Krankengeschichte (nur lesen):** Einträge nach Datum absteigend mit Art (Verletzung, OP, frühere Therapie, aktuelle Behandlung, Behandlungsmöglichkeit; Text, nicht nur Farbe), Titel und Notiztext; Schloss-Symbol und „Von deinem Physio, nur lesen“. Der Patient kann nichts ändern (A-4, DB-T15). Leer: „Dein Physio hat noch nichts eingetragen.“

**Zustände der Akte:** *Laden* (statische Platzhalter ≤ 300 ms, dann „Wird geladen“ mit Ring) · *Leer je Karte* (Behandler: „Noch kein Behandler eingetragen.“; Termine: „Noch keine Termine.“ mit „Termin hinzufügen“) · *Fehler ohne Zwischenspeicher* (`error`-Karte „Deine Akte konnte nicht geladen werden.“ + „Nochmal versuchen“) · *„nicht aktuell“* (A8) · *Termin speichern/löschen offline:* Eintrag erscheint sofort mit `⏸ Wartet auf Verbindung`, wird über die Warteschlange nachgesendet. Dokumente: nicht enthalten (O-5).

### A8. Hinweis „Nicht aktuell“ und Aktualisieren
Wenn Laden fehlschlägt oder offline ist und ein Zwischenspeicher vorhanden ist (Plan 8.2), erscheint unter der Kopf-Karte eine `NoticeCard stale`: Symbol ↻, **„Nicht aktuell. Stand: heute, 09:12.“**, darunter „Dein Physio hat vielleicht etwas geändert.“ und **„Aktualisieren“** (`GlassPill`). Gilt auf Pfad, Heute, Akte und Frage-Liste. Zeitangabe: „heute, HH:MM“ / „gestern, HH:MM“ / „Mo, 12. Okt., HH:MM“. Beim Aktualisieren: Knopf „Wird aktualisiert“ mit Ring, danach verschwindet die Karte und die Ansage „Aktualisiert.“ folgt; scheitert es erneut, bleibt die Karte, Fokus bleibt auf der Schaltfläche. Mit Zwischenspeicher steht der Inhalt immer sofort da, das Laden im Hintergrund zeigt nichts, solange es gelingt.

### A9. Laden und Fehler ohne Zwischenspeicher
- **Laden** (Start, Fortsetzen, nach Einwilligung): statische Platzhalter ≤ 300 ms ohne Shimmer; dauert es länger, steht in der Mitte Manny `normal` 96 dp, der Text „Dein Plan wird geladen“ und ein Fortschrittsring (Ausnahme E-3); Live-Region „Wird geladen“. Keine Leiste während des Ladens nach der Einwilligung, sonst wie Brief 7.
- **Fehler:** bestehender Text „Dein Pfad konnte nicht geladen werden.“ (Heute: „Dein Programm …“, Akte: „Deine Akte …“, Fragen: „Deine Fragen …“) mit `error`-Karte und **„Nochmal versuchen“**; Fokus auf die Überschrift der Karte.
- **Gelöste Bindung / `access_deleted`:** keine Fehlerkarte, sondern der Hinweis aus A4 (altes Gerät).

### A10. Hinweis „Ein Eintrag konnte nicht gesendet werden“ (Auflage N-17/NIT-2)
Für dauerhaft ungültige, zurückgestellte Warteschlangen-Einträge (z. B. `invalid_local_day`, Plan 8.11), die nicht verloren gehen, aber nicht ankommen. **Dezent:** eine `NoticeCard sync` direkt unter der Kopf-Karte auf **Heute** (Symbol ↻, Text „Ein Eintrag konnte nicht gesendet werden.“ bzw. „N Einträge konnten nicht gesendet werden.“, darunter „Er bleibt auf diesem Gerät. Die App versucht es weiter.“, Aktion **„Nochmal senden“** (`GlassPill`, löst sofort einen neuen Versuch aus) und X zum Ausblenden (48 dp, nur lokal, kommt bei einem **neuen** zurückgestellten Eintrag wieder). Sie nennt **keine Details und keine Werte** (insbesondere keine Stimmung) und erscheint nicht als Modal oder Ton. Mit Erfolg des Versuchs verschwindet sie mit der Ansage „Gesendet.“ Der Patient kann zurückgestellte Einträge nicht selbst verwerfen (Offene Frage 11).

### A11. Löschen mit Backend („Alles löschen“, O-9, M-4, Plan 8.10)
Das bestehende Sheet „Deine Daten“ und der Dialog „Alles löschen?“ bleiben; **Text und Zustände ändern sich**, weil jetzt Daten bei der Praxis liegen.
- **Dialog (Warn-Dialog, neutral, opak, Abbrechen immer vorhanden und zuerst fokussiert, kein Mandarine):** Titel „Alles löschen?“ · Text [Vorschlag] „Dein Konto, dein Verlauf, deine Check-ups, deine Fragen und deine eigenen Termine werden gelöscht, auf diesem Gerät und bei deinem Physio-Zugang. Was dein Physio selbst eingetragen hat (Plan, Akte, Notizen), bleibt in der Praxis, ohne Verbindung zu dir. Das lässt sich nicht rückgängig machen. Danach startest du neu.“ · Knöpfe „Abbrechen“ und „Ja, alles löschen“.
- **Ablauf in Anzeige:** Beim Bestätigen sperrt die App (Plan 8.10: Sperre), der Knopf zeigt „Wird gelöscht“ (Live-Region, wie `busyStatusDeleting`); davor, falls nötig, die Zeile „Offene Einträge werden noch gesendet …“. Abbrechen ist ab dem Serveraufruf deaktiviert.

| Ausgang | Anzeige und Verhalten |
|---|---|
| **sicher gelöscht** (Server bestätigt, auch `already_deleted`) | Dialog schließt, lokale Daten sind verworfen (Look auf „Mit Brille“ zurückgesetzt), der Code-Start beginnt bei Schritt 1; Snackbar „Alle Daten sind gelöscht.“ (4 s) |
| **unklar** (Verbindung brach ab oder Zeitüberschreitung, ob der Server gelöscht hat, ist offen) | Dialog bleibt mit `error`-Block: „Wir konnten nicht bestätigen, ob alles gelöscht wurde. Prüfe deine Verbindung und versuche es noch einmal.“; Knöpfe **„Nochmal versuchen“** (wiederholt `delete_my_data`, idempotent) und „Schließen“. Das Merkzeichen bleibt; beim nächsten Start steht statt der App der Hinweis „Löschen noch nicht abgeschlossen“ mit „Nochmal versuchen“ (Annahme, Offene Frage 12) |
| **lokaler Fehler** (Server bestätigt, lokales Verwerfen scheitert) | Dialog bleibt mit `error`-Block: „Auf dem Server ist alles gelöscht. Auf diesem Gerät konnte nicht alles entfernt werden. Versuch es nochmal.“; **„Nochmal versuchen“** wiederholt nur das lokale Verwerfen (kein neuer Serveraufruf) |
| **offline** (E-24, Annahme) | Dialog bleibt, nichts wurde gesperrt oder gelöscht: „Ohne Verbindung kannst du nichts löschen. Verbinde dich und versuche es noch einmal.“ |

- **Sheet „Deine Daten“ im Backend-Modus:** Name, Verletzung und Datum kommen vom Physio und sind hier **nur lesbar** (Annahme, Offene Frage 13); die Zeile „Alles bleibt auf diesem Gerät.“ entfällt und wird durch „Deine Angaben liegen bei deinem Physio-Zugang. Hier kannst du sie ansehen oder alles löschen.“ ersetzt [Vorschlag]. Der Text „Daten löschen“ im Sheet nennt Konto und Praxis wie im Dialog.

---

## 3. Teil B: Check-up, feste Hinweise, Frage an meinen Physio (vor L5)

### B1. Brief-Folgen aus N-14 (Zusammenfassung)
Sechs Fragen (Schwellung 0–3 kommt dazu), Einschränkungen als Einzelwert-Skala keine / leicht / deutlich / stark statt Chips, V2-38 „Frage N von 6“, Kachel 2 zeigt Schwellung und Einschränkungs-Stufe, Warnzeichen „Schwellung stark“ mit Symbol und Text. Details in B3 und B6.

### B2. Profil-Einstieg
Profil-Zeile „Frage an meinen Physio“ (≥ 56 dp) mit **Zähler als Text**: „2 offen“ bzw. „keine offen“ (Symbol plus Wort, nie nur eine Zahl im Badge); Screenreader „Frage an meinen Physio, 2 offen“. Tipp öffnet die Route B7. Die Zahl zählt Fragen im Status „offen“ und noch nicht gesendete.

### B3. Tages-Check-up mit sechs Fragen (`v2-e2-checkup-schwellung.png`, `v2-e2-checkup-einschraenkung.png`)
Die `DailyCheckupCard` (Brief 7.2) bleibt eine Karte oben auf Heute: Titel „Wie geht’s dir heute?“, Zusatz **„Einmal am Tag · 6 schnelle Fragen“**, Schließen (X, 48 dp). Darunter **eine Frage zur Zeit**: Zeile „Frage N von 6“ (Text) mit sechs Fortschrittssegmenten (Mandarine gefüllt/neutral Spur plus Text; Wert nie nur über Füllung, V2-33), Fragetext (`heading` 19/23), Bedienelement, darunter bei Wahl „Ausgewählt: …“, unten **Zurück** (`GlassPill`, 112 dp) und **Weiter** (`PrimaryPill`, 56 dp; bei Frage 6 „Fertig“).

| N | Frage (Text [Vorschlag]) | Bedienelement | Wert (Backend) |
|---|---|---|---|
| 1 | Wie fühlst du dich heute insgesamt? | `RatingScale` (5 Smileys, Label „sehr schlecht … sehr gut“) | `wellbeing` 1–5 |
| 2 | Wie stark ist dein Schmerz heute? | `PainSlider` 0–10, Wert als Text „Schmerz, 3 von 10“, ±-Schaltflächen | `pain` 0–10 |
| 3 | **Wie geschwollen ist die verletzte Stelle heute?** | **`StepScale`: keine · leicht · deutlich · stark** | `swelling` 0–3 (3 = stark) |
| 4 | Wie motiviert bist du heute? | `RatingScale` | `motivation` 1–5 |
| 5 | **Wie sehr schränkt dich die Verletzung heute im Alltag ein?** | **`StepScale`: keine · leicht · deutlich · stark** | `limitations` `none`·`mild`·`marked`·`severe` |
| 6 | Wie ist deine Stimmung heute? | `RatingScale` | `mood` 1–5 |

**Begründung der Lage von Schwellung (Frage 3):** Schwellung und Schmerz sind die beiden körperlichen Warnwerte; sie stehen **direkt hintereinander**, damit der Patient sie im selben Gedanken beantwortet. Die übrige Reihenfolge bleibt wie in Brief 7.2 (Wohlbefinden als Einstieg, Stimmung zuletzt, damit die weichste Frage den Abschluss bildet); die Alternative „Einschränkungen direkt nach Schwellung“ steht in Offene Frage 9.
**Stufenwörter:** Schwellung und Einschränkungen nutzen **dieselben vier Wörter** keine/leicht/deutlich/stark (Plan: „3 = stark“, O-19), damit nichts zu lernen ist. Die Beschriftung der Stufe 0–3 für Screenreader lautet „keine, 1 von 4“ … „stark, 4 von 4“; der Wert 0–3 bleibt intern.

**Verhalten**
- **Pflicht:** Alle sechs Werte sind Pflicht (Schema). „Weiter“ ist erst nach einer Antwort aktiv; deaktiviert bleibt es fokussierbar mit Hinweis „Wähle zuerst eine Antwort“. Der Schmerz-Regler startet **ohne Wert** („Schmerz: noch nicht gewählt“); `+` setzt auf 1, `−` auf 0, Tipp auf die Spur setzt den Wert (Annahme, Offene Frage 9).
- **Zurück:** springt eine Frage zurück, die Antworten bleiben erhalten. Gesendet wird **erst nach Frage 6 („Fertig“)**.
- **Schließen (X):** verwirft die Antworten, die Karte ist für heute weg (lokal, B-22); die Snackbar „Check-up übersprungen. Rückgängig“ (6 s, bestehendes Muster) bringt sie zurück (Annahme, Offene Frage 9).
- **Fokus:** Nach „Weiter“ springt der Screenreader-Fokus auf den neuen Fragetext, Ansage „Frage 3 von 6. Wie geschwollen ist die verletzte Stelle heute?“.
- **Stimmung (C-3):** Die Frage 6 und alles danach ist **für jeden Wert identisch**: gleiche Texte, keine Zusatzkarte, keine andere Manny-Pose, kein anderer Ton, keine andere Haptik, kein Hilfsangebot (O-21). Die Stimmung taucht nirgends gegenüber dem Patienten wieder auf (V2-57).

**Abschluss und Senden:** Nach „Fertig“ wird die Karte klein: „Erledigt, danke!“ mit Statuschip `↻ Wird gesendet` → `✓ Gesendet` bzw. offline `⏸ Wartet auf Verbindung` (Text: „Wird gesendet, sobald du wieder online bist.“). Senden läuft über die Warteschlange; `already_submitted` zählt als Erfolg und zeigt keinen Fehler. Der Patient kann den Check-up danach nicht ändern. Nach Schließen der kleinen Karte kommt sie erst am nächsten Tag wieder (V2-38 neu).

### B4. Fester Hinweis bei Schmerz- und Schwellungs-Warnzeichen (`v2-e2-hinweis-heute.png`)
**Auslöser:** Die Antwort von `submit_daily_checkup` meldet `warning_raised = true` (Schmerz ≥ 7, Anstieg ≥ 3 zum Vortag derselben Verletzung **oder** Schwellung „stark“; Plan 6.9). Der Hinweis ist **derselbe** für alle drei Gründe und nennt **keinen** Grund, keine Zahl und keinen Schwellenwert (die Schwellen bleiben serverseitig, Plan 8.7). Die Stimmungs-Nachricht löst **nie** einen Hinweis aus (C-3, DB-T58).

**Darstellung:** `NoticeCard fixed-hint` auf **Heute**, direkt **unter** der kleinen Karte „Erledigt, danke!“, **über** dem Training (Mockup). Opak, neutral, kein Manny, kein Mandarine, kein Primärknopf. **Wortlaut [Vorschlag, Freigabe über E-17/KI-L nötig]:**
- Titel: „Hinweis zu deinen Werten“
- Text: „Deine Angaben zu Schmerz oder Schwellung sind heute auffällig. Dein Physio sieht sie in deinem Verlauf. Bist du unsicher oder wird es schlimmer, sprich ihn an oder such ärztliche Hilfe.“
Der Text verspricht keine Reaktion und keinen Zeitpunkt (es gibt keine Benachrichtigung, Plan 6.9) und enthält keine Diagnose.

**Verhalten:** Erscheint **erst nach erfolgreichem Senden** (offline entsprechend später; Plan 8.6; Offene Frage 5); kein Ton, keine Vibration, kein Fokusraub, Ansage als höfliche Live-Region („Hinweis zu deinen Werten …“). Bleibt **bis zum Tagesende** stehen und ist nicht wegklickbar (Offene Frage 6); am nächsten Tag ist er weg, außer ein neuer Check-up löst ihn erneut aus. Nach Ablauf bleibt der Inhalt des Check-ups nirgends für den Patienten sichtbar (O-20).

### B5. Hinweis „Heute etwas kürzer“ (Plan 8.7, E-36)
**Auslöser:** Der Schmerzwert aus dem **heutigen** Tages-Check-up ist ≥ 6 (E-28); ohne Check-up keine Kürzung. Die Schwelle kommt mit dem Framework und wirkt auch offline.
- **Liste (Heute):** Oben in der Trainingskarte, unter „Dein Training“ und der Zeitzeile (jetzt „ca. N Min“ der gekürzten Liste), eine `NoticeCard info` im Karteninneren: Symbol ▾, Titel **„Heute etwas kürzer“**, Text [Vorschlag, Freigabe über E-17] „Weil dein Schmerz heute höher ist, ist dein Programm kürzer: ca. 10 statt 20 Min.“ (Zahlen aus der Berechnung 8.7). Nicht wegklickbar, weil sie die geänderte Liste erklärt.
- **Zeilen:** gekürzte Übungen tragen einen Chip „▾ gekürzt“ (Symbol plus Text) und in der Umfangszeile „2 × 12 statt 3 × 12“ (bzw. Dauer/Wiederholungen entsprechend).
- **Übungsdetail:** Eine Zeile „Heute gekürzt: 2 statt 3 Sätze. Dein Physio hat 3 geplant.“ (nennt die Planwerte des Physios, damit er nichts anderes liest; Grenzen und Beschreibung unverändert).
- **Zeitwahl 10/20/30** bleibt bedienbar; der Hinweis nennt die gekürzte Zeit.
- Der Hinweis erscheint **auch bei Schmerz ≥ 7** zusätzlich zu B4 (beide, B4 zuerst). Er ist **keine Warnung**: neutral, ohne Warnsymbol.

### B6. Physio-Kachel 2 mit Schwellung und Einschränkung (`v2-e2-kachel2.png`)
Brief 7.9 Kachel 2 heißt weiter „Befinden, Motivation, Warnzeichen“ und zeigt jetzt:
- **Warnzeichen zuerst** (offen vor gesehen): Chips mit **Symbol ⚠ und Text**, z. B. „⚠ Schwellung stark“, „⚠ Schmerz 8 von 10“ (`chip-warn` `#FFE3DD` mit `#7A1A12`, 8,7:1); Stimmungs-Meldungen weiter zu **einer** Meldung je Eingang zusammengefasst (Plan 6.9).
- **Stand:** „Check-up von heute, 07:40“ bzw. „vor N Tagen“.
- **Werte als Zeilen** (Label links, Wert als Text mit Zahl, rechts `LevelGlyph` für die vierstufigen Werte): Wohlbefinden „gut (4 von 5)“ mit Smiley · Motivation · Stimmung · **Schwellung „stark (3 von 3)“** · **Einschränkung „deutlich (2 von 3)“**. Die Stufe steht immer als Wort **und** Zahl, nie nur im Glyph.
- Am Rechner steht die Kachel in der dreispaltigen Übersicht ohne Scrollen (Brief 7.9, V2-59). Das Detail öffnet wie bisher (Sheet am Handy, Seitenpanel am Rechner); die **Detail-Ansicht gestaltet Teil D**, sie muss Schwellung und Einschränkung je Tag enthalten.
- Physio-Texte stehen in `strings_physio_de.dart` und enthalten **keine Chat-Begriffe** (Plan 4); Marker in Patientenliste und Kachel heißen z. B. „Schwellung stark“. Marker in der Liste (Brief 7.8): „⚠ Schwellung stark“, Screenreader „Warnzeichen: Schwellung stark“.

### B7. „Frage an meinen Physio“ (PB-D; `v2-e2-frage-physio.png`)
**Route** aus Profil (B2) mit Leiste (Tab Profil aktiv; bei geöffneter Tastatur ausgeblendet) und Zurück-Schaltfläche. **Kein Chat:** keine Blasen, kein „schreibt …“, keine Antworten, kein Manny, keine Verbindung zu Chats. Kopf-Karte: Titel „Frage an meinen Physio“, Untertitel „Kein Chat. Dein Physio liest sie und bespricht sie mit dir.“

Aufbau von oben:
1. **Eingabekarte:** Label „Deine Frage“, mehrzeiliges Feld (Mindesthöhe 92 dp, wächst bis 6 Zeilen, dann Scrollen im Feld), darunter links „Gesendete Fragen lassen sich nicht ändern.“, rechts der Zähler „88 / 500“ (Länge [Vorschlag] 500, O-34; ab 90 % zusätzlich als Text „noch 40 Zeichen“, Live-Region), **„Frage senden“** (`PrimaryPill`). Deaktiviert bei leerem oder nur aus Leerzeichen bestehendem Text. Zusätzlich eine kurze Zeile am unteren Kartenrand: „Bei Notfällen oder starken Beschwerden schreib nicht hier, sondern ruf deinen Physio an oder such ärztliche Hilfe.“ [Vorschlag, Freigabe über E-17].
2. **Liste „Deine Fragen“:** neueste zuerst; je Eintrag Fragetext (vollständig, Umbruch statt Abschneiden), Statuschip, Datum. Status: **`↻ Wird gesendet`** (liegt in der Warteschlange), **`⏸ Wartet auf Verbindung`** (offline), **`○ offen`** (gesendet, nicht besprochen), **`✓ besprochen`** mit „besprochen am 13. Okt.“. Der Physio kann „besprochen“ zurücknehmen (Annahme Plan 6.10); die Zeile springt dann auf „offen“. Aktualisiert wird beim Öffnen und mit der Schaltfläche „Aktualisieren“ (kein Pull-to-refresh als einziger Weg).
3. Keine Bearbeiten-/Löschen-Funktion.

**Zustände**

| Zustand | Darstellung |
|---|---|
| Liste leer | `info`-Karte: „Noch keine Fragen. Schreib auf, was du deinen Physio beim nächsten Termin fragen möchtest.“ |
| Laden | statische Platzhalter ≤ 300 ms, dann „Deine Fragen werden geladen“ mit Ring |
| Fehler ohne Zwischenspeicher | `error`-Karte „Deine Fragen konnten nicht geladen werden.“ + „Nochmal versuchen“; die Eingabe bleibt benutzbar |
| nicht aktuell | `NoticeCard stale` (A8) |
| Senden | Frage erscheint sofort oben mit `↻ Wird gesendet`, das Feld leert sich, Ansage „Frage wird gesendet.“; Fokus bleibt im Feld |
| zu lang / leer | Zähler wird zu Text „Zu lang: 12 Zeichen zu viel“ (Symbol + Text), Senden deaktiviert |
| Entwurf | ein nicht gesendeter Text bleibt beim Verlassen der Route erhalten (lokal, Annahme) |

**Manny und Physio-KI:** Fragen erscheinen nicht im Manny-Kontext und nicht im Physio-KI-Briefing (Plan 6.10); die Oberfläche zeigt davon nichts.

---

## 4. Accessibility (Querschnitt dieser Ergänzung)

| Thema | Vorgabe |
|---|---|
| Überschriften | je Screen eine Kopf-Karte als Ebene 1; Fragetext der Check-up-Karte Ebene 2; Karten-Titel Ebene 2 |
| Live-Regionen | Code-Fehler und Löschfehler **assertiv**; Hinweis nach Check-up (B4), Statuswechsel „Gesendet“, „Aktualisiert“, „Wird geprüft“ **höflich**; kein Fokusraub |
| Radios | `StepScale`, Look-Karten: eine Gruppe, ein Tab-Stopp, Pfeile wechseln, Leertaste wählt (V2-66-Muster) |
| Deaktivierte Knöpfe | bleiben fokussierbar mit Hinweis, was fehlt (A2, B3) |
| Fokus | sichtbar 3 dp; nach Seitenwechsel auf die Überschrift; nach Fehler am Auslöser (A2) bzw. an der Fehlerkarte (A9); bei Sheets/Dialogen gefangen, bei Schließen zurück zum Auslöser |
| Kontraste | alle Textpaare ≥ 4,5:1, Bedienränder ≥ 3:1: gemessen u. a. `#7A3A0C` auf `#FFE9D6` 7,3; `#14532D` auf `#DDF3E6` 7,8; `#7A1A12` auf `#FFE3DD` 8,7; `#8A3A0C` auf `#FFF1E4` 7,0; `error-text` auf Weiß 6,5; Rand 2 dp `border-control` auf Weiß 3,8; `fixed-hint`-Rand 6,3 |
| Zustand nie nur Farbe | Warn-, Status-, Auswahl- und Stufenzustände tragen Symbol **und** Text; `LevelGlyph` nur in `ink-1` |
| 200 % Schrift, 320 × 568 dp | Look- und Stufenkacheln wechseln auf Zeilen (A1, 1.2); Code-Feld bis 130 % skaliert, Rest umbricht; Einwilligungsknopf am Ende des Scrollinhalts; nichts abgeschnitten, kein horizontales Scrollen |
| Reduzierte Bewegung | keine Federn, Pops, Verschiebungen > 120 ms; Fortschrittsring nur als E-3-Ausnahme; Kachelwahl springt statt zu federn |
| Hoher Kontrast / Transparenz reduzieren | Kopf-Karte opak; Karten und `NoticeCard` sind schon opak; Ränder ≥ 4,3:1 |
| Ton/Vibration | keine Ton-/Haptik-Information in dieser Ergänzung; der feste Hinweis kommt ohne Ton |
| Sprache | alles Deutsch, „du“, kurz, nie klinisch; keine Fachbegriffe wie „Ödem“ oder „Warnzeichen-Regel“ gegenüber dem Patienten |

## 5. Technische Hinweise
- **Ablage (Vorschlag, entscheidet der Umsetzer):** Code-Start unter `app/lib/ui/start/` (neben `start_gate.dart`: Schritte Zugang, Einwilligung, Hinweise A4); neue Bausteine `step_scale.dart`, `level_glyph.dart`, `notice_card.dart`, `code_field.dart` unter `app/lib/ui/components/` (`LevelGlyph` dort, damit der Physio-Bereich ihn nutzen darf: `lib/physio/**` importiert aus `lib/ui/**` nur `components/**`); Check-up-Karte, Hinweise B4/B5 unter `app/lib/ui/today/`; Akte und Frage-Route unter einem neuen Profil-Ordner `app/lib/ui/profile/`. Keine neue Abhängigkeit.
- **Texte** ausschließlich in `lib/l10n/strings_de.dart` (Physio: `strings_physio_de.dart`); Wortlaute mit [Vorschlag] als Konstanten, damit Freigaben (E-17, Einwilligung) nur Texte ändern.
- **Tokens:** neue Werte (Stufenkachel-Maße, Glyph-Höhen 10/16/22, `fixed-hint`-Rand, `accent-soft` bleibt) nur in `lib/theme/` (V2-1).
- **Prüfung:** Goldens je neuer Screen in Hell/Dunkel, 200 % Schrift und 320 dp (Code-Start Look/Code mit allen Fehlern, Einwilligung, Hinweise, Akte, Frage-Route, Check-up Frage 3 und 5, Kachel 2); Widget-Tests für Zustände; Kontrasttest für die neuen Paare; statische Regel „keine Chat-Begriffe in `lib/physio/**`“ bleibt.
- Abhängigkeiten zu Plan-Abschnitten: 6.5, 6.9, 7.2, 8.1, 8.2, 8.3, 8.6–8.11, 9.

---

## 6. UI-Akzeptanzkriterien (fortlaufend ab V2-76)

**V2-38 neu (ersetzt V2-38 aus Brief v2):** Heute zeigt oben die Check-up-Karte, sofern heute nicht erledigt oder weggeklickt; **sechs** Fragen nacheinander mit „Frage N von 6“ in der Reihenfolge Wohlbefinden, Schmerz, Schwellung, Motivation, Einschränkungen, Stimmung; die Karte nennt „Einmal am Tag · 6 schnelle Fragen“; nach Ausfüllen „Erledigt, danke!“ in kleiner Karte; nach Schließen am selben Tag nicht mehr, am nächsten Tag wieder.

**Code-Start und Zugang (Teil A)**
- V2-76: Der Code-Start hat die Schrittfolge Look (nur wenn noch nicht gewählt) → Zugang → Einwilligung; die Kopf-Karte zeigt „Schritt N von 3“ mit Look-Schritt bzw. „N von 2“ ohne; der Look-Schritt steht vor dem Code-Feld und zeigt die Karten aus Ergänzung 1 (V2-66, V2-67 gelten); der Demo-Modus behält das Onboarding mit fünf Schritten.
- V2-77: Wer in L1 schon einen Look gewählt hat, sieht den Look-Schritt nicht; Manny steht im Zugang-Schritt in der gewählten Variante.
- V2-78: Der Zugang-Screen hat den Titel „Zugang über deinen Physio“, ein sichtbares Label „Dein Code“ über dem Feld und einen Erklärtext, dass der Zugang über den Physio kommt; ohne gültigen Code gibt es keinen Weg zum Pfad (Test: Zurück/Android-Zurück führt nie in die App).
- V2-79: Das Code-Feld akzeptiert Klein-/Großschreibung, mit oder ohne Bindestrich und Leerzeichen, und zeigt den Code als `XXXXX-XXXXX`; „Weiter“ ist erst bei 10 gültigen Zeichen aktiv; Einfügen funktioniert; der Feldtext skaliert höchstens bis 130 %.
- V2-80: Wird der Code über einen Link gefüllt, steht dort „Code aus dem Link übernommen“, und eingelöst wird erst nach Tipp auf „Weiter“.
- V2-81: Für `invalid`, `already_used`, `expired`, `too_many_attempts`, `not_allowed` und Netzfehler erscheint der jeweilige Text aus A2 in einem Fehlerblock mit Symbol und Text (nicht nur Rand), der Feldinhalt bleibt, der Fehler wird als Live-Region angesagt; bei Netzfehler gibt es „Nochmal versuchen“.
- V2-82: Während der Prüfung sind Feld und Zurück deaktiviert, „Weiter“ zeigt „Wird geprüft“, und ein Doppeltipp löst genau einen Aufruf aus.
- V2-83: `ok` führt zur Einwilligung, `ok_rebound` zuerst zum Neuanmeldungs-Hinweis.
- V2-84: Der Neuanmeldungs-Hinweis auf dem neuen Gerät nennt, dass Plan, Verlauf und Check-ups erhalten bleiben und der Chat mit Manny auf dem alten Gerät bleibt und dort gelöscht wird; er endet mit „Verstanden“; weicht der Konto-Look vom gewählten ab, steht der Look-Satz darin; der Fokus beginnt auf der Überschrift.
- V2-85: Nach erkannter gelöster Bindung zeigt das alte Gerät vor dem Code-Start „Du bist auf einem anderen Gerät angemeldet“ (bei `access_deleted`: „Dein Zugang wurde beendet“) mit dem Hinweis, dass die Daten und der Chat auf diesem Gerät gelöscht wurden, und „Weiter“ führt zu Schritt 1 des Code-Starts.
- V2-86: Die Einwilligung nennt (Textabgleich mit Plan 7.2): Verlauf mit erledigten und übersprungenen Übungen samt Grund; Check-ups einschließlich Schwellung und Stimmung; Fragen an den Physio; Warnzeichen einschließlich solcher aus dem Manny-Chat und Hinweisen auf eine Krise (nur Stufe und Zeitpunkt, ohne Chattext); die Stimmungsmeldung nach 5 Tagen mit Check-up, an jedem weiteren Tag erneut, ohne Details, mit Abbruch durch einen Tag ohne Check-up und Neustart bei neuer Verletzung, ohne Anzeige in der App; dass der Physio den Manny-Chat nie sieht.
- V2-87: Zugestimmt wird nur durch Tipp auf „Ich bin einverstanden“ (kein vorangekreuztes Feld); der Knopf ist bei Schrift ≤ 130 % fest unten und bei > 130 % am Ende des Scrollinhalts erreichbar; es gibt kein Zurück; ein Neustart nach dem Einlösen setzt bei der Einwilligung fort; „Datenschutzerklärung lesen“ ist erreichbar.
- V2-88: Die Einwilligung hat Zustände Senden („Wird gesendet“), Fehler („Nochmal versuchen“) und Offline mit Symbol und Text.
- V2-89: Ohne Plan (oder ohne Phasen) zeigen Pfad und Heute die Karte „Dein Physio stellt deinen Plan noch zusammen“ mit „Aktualisieren“; „Training starten“ erscheint dort nicht; der Tages-Check-up bleibt erreichbar.
- V2-90: Die Pfad-Kugel *Ausgelassen* hat die Größe der übrigen Stufen, einen gestrichelten Rand ≥ 3:1 gegen die Welt (Messung, 4 Welten), das Symbol ↷, das Label „… ausgelassen“ und ist weder Schloss noch Haken noch rot; der Screenreader liest „Woche N, Trainingstag M, ausgelassen“.
- V2-91: Der Tipp auf eine ausgelassene Kugel zeigt „Diesen Tag hast du ausgelassen. Das ist okay. Mach mit der aktuellen Einheit weiter.“ in einer Hinweisblase mit X ≥ 48 dp; der Text enthält keine Zahl verpasster Tage und keine Schuldzuweisung (Textsuche).
- V2-92: Mit Zwischenspeicher steht der Inhalt sofort; ohne Zwischenspeicher gibt es statische Platzhalter ≤ 300 ms, danach „… wird geladen“ mit Fortschrittsring und Live-Region.
- V2-93: Ohne Zwischenspeicher zeigt ein Ladefehler eine Fehlerkarte „… konnte nicht geladen werden.“ (Symbol und Text) mit „Nochmal versuchen“; der Fokus steht auf der Karte.
- V2-94: Bei Fehler oder Offline mit Zwischenspeicher steht unter der Kopf-Karte „Nicht aktuell. Stand: <Zeit>.“ mit „Aktualisieren“; nach erfolgreicher Aktualisierung verschwindet sie mit der Ansage „Aktualisiert.“.
- V2-95: Für dauerhaft zurückgestellte Warteschlangen-Einträge steht auf Heute dezent „Ein Eintrag konnte nicht gesendet werden.“ (Mehrzahl bei mehreren) mit „Nochmal senden“; sie nennt keine Werte, ist weder modal noch mit Ton, lässt sich ausblenden und kehrt bei einem neuen Eintrag zurück.
- V2-96: Die Akte zeigt in dieser Reihenfolge Verletzung und Plan (Phase, Plan-Überblick mit markierter aktueller Phase als Symbol und Text), Behandler (Name, Rolle, Kontakt als Text), Termine, Krankengeschichte.
- V2-97: Einträge des Physios in Terminen und Krankengeschichte sind mit Schloss und „Von deinem Physio, nur lesen“ gekennzeichnet und nicht bearbeitbar; eigene Termine lassen sich anlegen (Sheet mit Titel, Datum, Uhrzeit Pflicht), ändern und nach Dialog löschen; Kategorie ist nicht nur an der Farbe erkennbar (V2-44).
- V2-98: Die Akte hat Zustände Laden, je Karte Leer, Fehler ohne Zwischenspeicher, „Nicht aktuell“ und offline gespeicherte Termine mit „Wartet auf Verbindung“.
- V2-99: Der Löschdialog nennt, dass Konto, Verlauf, Check-ups, Fragen und eigene Termine gelöscht werden, dass Einträge des Physios in der Praxis bleiben, und dass es nicht rückgängig zu machen ist; „Abbrechen“ ist vorhanden und zuerst fokussiert; kein Mandarine-Knopf.
- V2-100: Das Löschen hat vier unterscheidbare Ausgänge: sicher (Dialog schließt, Code-Start bei Schritt 1, Snackbar „Alle Daten sind gelöscht.“), unklar („Wir konnten nicht bestätigen …“, „Nochmal versuchen“, Merkzeichen bleibt), lokaler Fehler (Server gelöscht, nur lokales Verwerfen wird wiederholt) und offline (nichts gelöscht, klare Meldung); jeder Fehlerausgang hat Symbol und Text und wird angesagt.

**Check-up, Hinweise, Frage (Teil B)**
- V2-101: Der Check-up zeigt „Frage N von 6“ als Text mit sechs Fortschrittssegmenten; „Weiter“ ist erst nach einer Antwort aktiv (deaktiviert fokussierbar mit Hinweis); „Zurück“ erhält die Antworten; erst „Fertig“ nach Frage 6 sendet.
- V2-102: `StepScale` (Schwellung, Einschränkungen) zeigt vier Kacheln keine / leicht / deutlich / stark (je ≥ 48 dp, ≥ 8 dp Abstand) mit `LevelGlyph`; die gewählte Stufe hat Rand, Haken und den Text „Ausgewählt: …“; Radio-Semantik „deutlich, 3 von 4, ausgewählt“; Pfeiltasten wechseln, ein Tab-Stopp je Gruppe; `LevelGlyph` nutzt nur `ink-1`.
- V2-103: Frage 3 fragt „Wie geschwollen ist die verletzte Stelle heute?“ und liefert `swelling` 0–3 (keine = 0 … stark = 3); Frage 5 ersetzt die Auswahl-Chips durch einen Einzelwert aus keine / leicht / deutlich / stark (`none`/`mild`/`marked`/`severe`); es gibt keine Mehrfachauswahl mehr (Code-Suche: keine Chips in der Check-up-Karte).
- V2-104: Bei Systemschrift > 130 % oder Breite < 360 dp stehen die vier Stufen untereinander (Zeilen ≥ 56 dp), nichts ist abgeschnitten, „Weiter“ ist erreichbar (V2-24, V2-25).
- V2-105: Das X der Karte verwirft die Antworten und blendet die Karte für heute aus; die Snackbar „Check-up übersprungen. Rückgängig“ bringt sie zurück; nichts wird gesendet.
- V2-106: Die Stimmung wird nur erfasst: Für jeden Wert 1 bis 5 sind Texte, Karten, Manny-Pose, Ton und Haptik nach Frage 6 identisch (Widget-Test über alle fünf Werte); es erscheint nie eine Hilfe- oder Zusatzkarte zur Stimmung.
- V2-107: Nach „Fertig“ steht „Erledigt, danke!“ mit Statuschip „Wird gesendet“ → „Gesendet“ bzw. offline „Wartet auf Verbindung“; `already_submitted` zeigt keinen Fehler.
- V2-108: Der feste Hinweis „Hinweis zu deinen Werten“ erscheint nur, wenn der Server `warning_raised = true` meldet, mit **identischem** Text für hohen Schmerz, Schmerzanstieg und starke Schwellung; er nennt keinen Grund, keine Zahl und keinen Schwellenwert; die Stimmung löst ihn nie aus (Test mit Stimmung 1 und 2 über fünf Tage: kein Hinweis).
- V2-109: Der Hinweis ist eine opake neutrale `NoticeCard fixed-hint` ohne Welt, Glas, Mandarine-Knopf und Manny, mit Symbol und Text, höflicher Live-Region ohne Fokusraub und ohne Ton; er steht bis Tagesende auf Heute und ist nicht wegklickbar.
- V2-110: Bei Schmerz ≥ 6 im heutigen Check-up zeigt Heute „Heute etwas kürzer“ als neutrale Karte (ohne Warnsymbol) mit der gekürzten Zeit, gekürzte Zeilen tragen „▾ gekürzt“ und „x statt y“, das Übungsdetail nennt die Planwerte des Physios; ohne Check-up gibt es keine Kürzung; bei Schmerz ≥ 7 stehen beide Hinweise (B4 zuerst).
- V2-111: „Frage an meinen Physio“ hat Kopf-Karte mit dem Hinweis „Kein Chat …“, ein Feld mit Label „Deine Frage“, Zähler „N / 500“, „Gesendete Fragen lassen sich nicht ändern.“ und „Frage senden“; die Route enthält keine Blasen, keine Antworten und kein Manny.
- V2-112: „Frage senden“ ist bei leerem oder nur aus Leerzeichen bestehendem Text deaktiviert; über der Längengrenze steht „Zu lang: N Zeichen zu viel“ mit Symbol und Text; nach dem Senden steht die Frage sofort oben mit „Wird gesendet“, das Feld ist leer, die Ansage „Frage wird gesendet.“ folgt.
- V2-113: Die Liste „Deine Fragen“ zeigt neueste zuerst Fragetext (umbrechend), Datum und Status als Symbol plus Text: „Wird gesendet“, „Wartet auf Verbindung“, „offen“, „besprochen“ (mit Datum); eine vom Physio zurückgenommene Markierung zeigt wieder „offen“.
- V2-114: Die Frage-Route hat die Zustände Leer („Noch keine Fragen …“), Laden, Fehler ohne Zwischenspeicher („Deine Fragen konnten nicht geladen werden.“ mit „Nochmal versuchen“), „Nicht aktuell“; ein ungesendeter Text bleibt beim Verlassen erhalten.
- V2-115: Die Profil-Zeile „Frage an meinen Physio“ zeigt „N offen“ bzw. „keine offen“ als Text; der Screenreader liest „Frage an meinen Physio, N offen“.
- V2-116: Kachel 2 zeigt Warnzeichen zuerst (Symbol ⚠ und Text, z. B. „Schwellung stark“), dann Wohlbefinden, Motivation, Stimmung, Schwellung und Einschränkung je als Wort plus Zahl und (für die vierstufigen Werte) `LevelGlyph`, plus „Check-up von …“; Stimmungs-Warnzeichen eines Eingangs erscheinen als eine Meldung.
- V2-117: Der Warnzeichen-Marker der Patientenliste und der Kachel für starke Schwellung hat Symbol und Text „Schwellung stark“ (Screenreader „Warnzeichen: Schwellung stark“); in `lib/physio/**` kommt kein Chat-Begriff vor (statische Regel).

**Querschnitt**
- V2-118: Alle neuen Screens bestehen 200 % Schrift und 320 × 568 dp ohne Abschneiden, ohne horizontales Scrollen und mit erreichbarem Primärknopf (V2-24, V2-25), und mit „Bewegung reduzieren“ ohne Federn/Pops (V2-26).
- V2-119: Neue Farbpaare (Abschnitt 4) werden per Test auf ≥ 4,5:1 (Text) und ≥ 3:1 (Ränder) geprüft; Text steht nie direkt auf der Welt (V2-5); nur Leiste, Kopf-Karte und Manny-Knopf nutzen Blur (V2-10).
- V2-120: Alle sichtbaren Texte stehen in `strings_de.dart` bzw. `strings_physio_de.dart`, sind Deutsch, „du“, kurz und nie klinisch; Wortlaute mit [Vorschlag] sind als solche freigabepflichtig (E-17, Einwilligung).

---

## 7. Annahmen
- Die Einwilligung folgt dem Einlösen, weil `accept_consent` einen gebundenen Patienten braucht (Plan 6.4); bis dahin fließen keine Patientendaten.
- Vor dem Laden des Plans ist der **Name des Physios nicht** bekannt (der Patient kann `physios` nicht lesen); die Texte sagen deshalb „dein Physio“, Namen stehen erst in der Akte (Behandler).
- Der Look-Schritt entfällt, wenn schon aus L1 ein Look gewählt wurde; die Schrittzahl passt sich an.
- Die Stufenwörter für Schwellung entsprechen denen der Einschränkungen (keine/leicht/deutlich/stark); „stark“ = 3 (O-18).
- Fragetexte der sechs Fragen sind Vorschläge (Brief v2 nennt nur die Themen).
- „Ausgelassen“ = Einheit einer vergangenen Woche ohne Erledigung (v1.2 6.3 liegt nur als Verweis vor; Offene Frage 1).
- Der feste Hinweis gilt bis Tagesende und ist nicht wegklickbar; offline gesendete Check-ups lösen ihn erst nach dem Senden aus (Plan 8.6).
- Die Warteschlange bleibt unsichtbar, solange alles klappt; nur dauerhaft zurückgestellte Einträge (A10) und der Status der Check-up-Karte und Fragen zeigen sie.
- Der Tages-Check-up hängt nicht am Plan und bleibt ohne Plan verfügbar.
- Kontakt in der Akte ist Text; Termin-Felder (Titel, Datum, Uhrzeit, Ort, Art) sind eine Annahme, weil das Schema „unverändert“ aus v1.2 ist.

## 8. Offene Fragen

**Blockierend**
1. **[blockierend vor L3] „Ausgelassen“ bestätigen.** Annahme: Einheit einer vergangenen Woche ohne Erledigung, nicht nachholbar als „aktuell“. *Auswirkung:* Bedeutung und Text der Kugel (A6), Pfad-Logik 8.3. Die Regeln aus v1.2 6.3 liegen im Repo nicht mehr vor.
2. **[blockierend vor L3] Einwilligung verweigern.** Der Entwurf kennt **keinen Ablehnen-Knopf** (wer nicht zustimmt, bleibt auf der Seite). Soll es „Nicht einverstanden“ geben, und was passiert dann mit dem bereits gebundenen Zugang (Zugang beenden, Konto löschen)? *Auswirkung:* Freiwilligkeit der Einwilligung, Zusatz-Screen, `delete_my_data`-Weg.
3. **[blockierend vor L3] Wortlaut der Einwilligung** (Plan 7.2 „Wortlaut F2-D2 A/Nutzer“): Der Vorschlag in A3 enthält alle Pflichtpunkte; Freigabe durch den Nutzer nötig; Rechtsprüfung ruht bis echte Daten.
4. **[blockierend vor L5] Wortlaut des festen Hinweises und von „Heute etwas kürzer“** (E-17, über KI-L): Vorschläge in B4/B5; Texte liegen als Konstanten. *Auswirkung:* medizinisch-rechtliche Wirkung des Hinweises.

**Nicht blockierend**
5. **Offline-Check-up mit hohem Schmerz:** Der Hinweis erscheint erst nach dem Senden (Plan 8.6; Schwellen bleiben serverseitig), während die Kürzung (Schmerz ≥ 6) sofort wirkt. *Annahme:* so. Alternative: ein neutraler lokaler Hinweis bei jedem offline gesendeten Check-up (dann ohne Bezug auf Werte).
6. **Hinweis nicht wegklickbar bis Tagesende** *(Annahme)*; Alternative: „Verstanden“ blendet ihn aus.
7. **Bedeutung `not_allowed`** bei der Code-Einlösung. *Annahme:* Text „Das geht auf diesem Gerät gerade nicht. Starte die App neu …“.
8. **Akte:** Kontakt als Text ohne Anruf-/Mail-Aktion; Felder eines eigenen Termins (Titel, Datum, Uhrzeit, Ort, Art). *Annahme:* wie A7.
9. **Check-up-Details:** Reihenfolge (Alternative: Einschränkungen direkt nach Schwellung), Beschreibungen je Stufe statt nur Wörter, Startwert des Schmerz-Reglers („ohne Wert“), „Zurück“ in der Karte und Rückgängig-Snackbar beim Wegklicken. *Annahme:* wie B3.
10. **Check-up ohne Plan** erlaubt. *Annahme:* ja.
11. **Zurückgestellte Einträge** (A10): kein Verwerfen durch den Patienten. *Annahme:* bleiben bis Erfolg oder „Alles löschen“.
12. **Löschen unklar:** Verhalten nach „Schließen“ (Hinweis-Screen „Löschen noch nicht abgeschlossen“ beim nächsten Start, Inhalte gesperrt). *Annahme:* so (Plan 8.10: Sperre, Merkzeichen).
13. **„Deine Daten“ im Backend-Modus:** Name, Verletzung, Datum nur lesbar (kommen vom Physio). *Annahme:* lesend.
14. **Neuanmeldung:** Wird die Einwilligung nach `ok_rebound` erneut verlangt? *Annahme:* nein, wenn `physio_sharing-2` für diesen Patienten schon vorliegt; dann folgt auf den Hinweis direkt das Laden.
15. **Fragen:** Länge (O-34, [Vorschlag] 500), Entwurf bleibt lokal erhalten, Notfall-Zeile im Eingabefeld. *Annahme:* wie B7.

## 9. Nicht enthalten
Teil C (Physio-Anmeldung, Konto, Chats-Platzhalter, Plan-Editor, Akte-Pflege, Code neu erzeugen, Vorlagenauswahl) und Teil D (Historie, Notiz, neue Verletzung, Kachel-Details, Kachel 6) dieser Brief-Ergänzung; In-App-QR-Scanner; Push-Benachrichtigungen; ein Hilfsangebot bei schlechter Stimmung (O-21); Anrufen/Mailen aus der Akte; Dokument-Upload (O-5); die Detail-Ansicht von Kachel 2; ein Mockup für den Löschdialog, die Akte und den Neuanmeldungs-Hinweis (Beschreibung genügt, Bausteine sind abgebildet); echte Rechtsprüfung der Texte; App-Code (Umsetzung beim `flutter-developer`).
