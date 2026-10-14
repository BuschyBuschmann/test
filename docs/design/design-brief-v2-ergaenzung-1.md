# Design-Brief v2, Ergänzung 1: Manny mit finalen Grafiken und Look-Wahl

Status: **BRIEF ZUR FREIGABE** · Stand 2026-10-14 · Paket K-M1 · Grundlage: Nutzerauftrag „Bitte nehme diese beiden Designs für manny. Man soll am Anfang wählen können zwischen mit und ohne Brille.“

**Wirkung:** Diese Ergänzung **ersetzt Abschnitt 6 „Manny“ von `design-brief-v2.md` vollständig** (Stilregeln, Umsetzung, Verwendung, Posentabelle) und das Kriterium **V2-56**. Ergänzt werden Onboarding-Schritt „Wie soll Manny aussehen?“, Profil-Zeile „Manny-Look“, Kriterien V2-65 bis V2-75 und Migrationshinweise. Alles andere in Brief v2 gilt unverändert. Orientierung: `mockups/v2-manny-wahl.png` (Onboarding-Schritt, Abend-Welt) und `mockups/v2-heute.png` (Manny-Knopf mit Variante „mit Brille“ in der Welt). Die übrigen `mockups/v2-*.png` zeigen noch die alte Platzhalter-Skizze und gelten nur für Layout, nicht für Manny.

## 6. Manny (ersetzt Abschnitt 6 aus Brief v2)

### 6.1 Die finalen Grafiken
Manny ist ein Pinguin in zwei Varianten, **Mit Brille** und **Ohne Brille**, je Variante 3 Posen plus Kopf. Die Bilder sind vom Nutzer erstellt, die Rechte liegen vor (Nutzerentscheidung 2026-10-14). Es sind die **finalen** Grafiken; die Platzhalter-Kennzeichnung entfällt.

| Datei (je `brille/` und `ohne/`) | Inhalt | Hinweis |
|---|---|---|
| `normal.png` | aufrecht, Flügel seitlich, leichtes Lächeln | Standard |
| `freudig.png` | offener Mund, gelbe Strahlen (`#FEBD28`) links und rechts | Mit Brille: Brille bleibt auf; Ohne Brille: Augen zu „^ ^“ |
| `traurig.png` | Mundwinkel unten, blaue Träne (`#4FB9EB`) | Mit Brille: Brille bleibt auf, Träne darunter; Ohne Brille: Augenbrauen schräg |
| `kopf.png` | Kopf als Rundform | Manny-Knopf, Avatare |

**Stilregeln (aus den Bildern gemessen):** flacher Sticker-Stil, gleichmäßige fast schwarze Kontur (`#040F17`, ca. 3 % der Figurhöhe), Körper dunkles Schiefer (`#253640`) mit hellerem Glanzstreifen, Bauch Creme (`#FDF9E8`) mit grauem Schattensaum unten, Schnabel und Füße Orange (`#FD9231`), große runde Flügel, breite Füße. Mit Brille: schwarze, eckige Sonnenbrille mit zwei Glanzstreifen, kein Stirnband. Ohne Brille: große schwarze Augen mit weißen Glanzpunkten. Der Bodenschatten der Vorlage ist entfernt; die Figur steht auf der Fußlinie der Leinwand.
**Die Figur wird nie umgefärbt, gedreht, gespiegelt oder verzerrt.** Beschriftungen der Vorlage („Normal“ usw.) sind nicht Teil der Bilder.
**Strahlen und Träne gehören zur Pose.** Das Wort „Trösten“ aus Brief v2 bedeutet jetzt: Pose `traurig`.

### 6.2 Format, Maße, Ableitung
- **Datei und Ablage:** PNG mit Transparenz, `docs/design/manny/{brille,ohne}/{normal,freudig,traurig,kopf}.png` (1x), `2.0x/` und `3.0x/` daneben (Flutter-Konvention für auflösungsabhängige Assets). Erzeugt per `docs/design/manny/make_manny_assets.py` aus `quelle/*.webp` (reproduzierbar; Verfahren: Flood-Fill vom Rand, kein globaler Weiß-Schlüssel, Kantenband mit Alpha-Entmischung, daher kein weißer Saum). Gesamtgröße aller 24 Dateien ca. 1,7 MB.
- **Körper-Leinwand (drei Posen, beide Varianten identisch):** 3x = 474 × 579 px, **1x = 158 × 193 dp**, 2x = 316 × 386 px. Alle sechs Körperbilder teilen Leinwand, Fußlinie (unten) und Körpermitte (horizontal): ein Wechsel der Pose oder Variante lässt die Figur nicht springen. Rand an der jeweils weitesten Pose (Freudig mit Strahlen) 8 dp (24 px bei 3x), unten 8 dp.
- **Kopf-Leinwand:** quadratisch, 3x = 330 px, **1x = 110 × 110 dp**, 2x = 220 px. Die Zeichnung füllt 87 % bis 93 % der Breite und etwa 80 % der Höhe.
- **Darstellungsgrößen (Leinwandhöhe, die Figur selbst ist ca. 92 % davon):** Pfad 88 dp (Figur ca. 80 dp, bisher `mannyPathHeight` 80), Onboarding Name-Schritt 120 dp, Auswahlkarten 190 dp (Höchstwert), Chat-Vollbild-Kopf 56 dp. Kein Bild wird größer als seine Leinwand in dp dargestellt (3x-Datei ist dann pixelgenau, keine Hochskalierung).
- **Bewegung im Code** (Hüpfen, Quetschen, Wippen; kein Lottie/Rive), bei „Bewegung reduzieren“ statisch (V2-26 bleibt).

### 6.3 Posen-Zuordnung (3 Posen + Kopf, mit Fallback)
Es wird mit diesen drei Posen gearbeitet. Weitere Posen kann der Nutzer später liefern; Dateinamen und Zuordnung sind darauf ausgelegt (neue Datei `<variante>/<pose>.png` plus eine Zeile in dieser Tabelle).

| Anlass (Abschnitt 6 alt) | Pose | Bisheriger Code (`MannyPose`) |
|---|---|---|
| Standard (Chat-Avatar groß, Pfad, Onboarding) | `normal` | `neutral` |
| Begrüßen (Tagesbeginn, Moin-Blase) | `freudig` | `neutral` (ändert sich) |
| Feier (Session-Ende, Streak, Meilenstein) | `freudig` | `feiernd` |
| Ziel (aktuelle Station, Boss) | `normal` (Fallback) | neu |
| Erinnerung (freundlich) | `normal` (Fallback) | `motiviert` (Neustart, Streak-Gefahr) |
| Training-Begleiter (Session, Packliste) | `normal` (Fallback) | neu |
| Trösten (Schmerz melden, schlechter Tag) | `traurig` | neu |
| Denken (Chat „schreibt“, Laden) | `normal` (Fallback) | neu |
| Schlafen (Ruhetag, Nacht) | `normal` (Fallback) | neu |
| Kopf (Manny-Knopf, Chat-Liste, Avatare) | `kopf` | `crop: head` |

Neue Enum-Werte für die Anlässe (Ziel, Training, Denken, Schlafen, Trösten) sind erlaubt und fallen in einer zentralen Abbildung auf die Dateien zurück. **Die Regel „Brille wird bei Trösten, Schlafen, Denken abgesetzt“ entfällt:** die gewählte Variante bleibt in jeder Pose gleich. Das Mikro-Verhalten Erinnerung bleibt freundlich, nie schuldzuweisend; wegen der Fallback-Pose trägt die Blase den Ton, nicht das Bild.

### 6.4 Sichtbarkeit auf Welt und Flächen
Die Figur ist dunkel mit fast schwarzer Kontur. Gemessen gegen die Tokens aus 3.1: Auf den Welten Morgen, Mittag, Abend ist der Kontrast der Kontur zu den Hügeln hoch (Abend `world-hill-mid` `#9C8E9B`: ca. 6:1). **In der Welt Nacht** (`world-hill-near` `#2E2634`) sinkt er auf ca. 1,3:1: die Kontur verschwindet, nur Bauch, Schnabel und Füße lesen. Regeln, ohne die Bilder zu ändern:
- **Halo auf der Welt (nur Nacht, nur Manny direkt auf der Welt, z. B. Pfad):** Kreis hinter der Figur, Durchmesser 1,15 × Leinwandbreite, Weiß 28 % (rechnerisch Kontur gegen Halo über `world-hill-near` ca. 3,3:1), weicher Auslauf am Rand. Mit „Transparenz reduzieren“ oder Hoher Kontrast: Halo opak `card`.
- **Kopf immer auf heller Scheibe:** Manny-Knopf (Glas Weiß 78 %, wie Leiste aktiv, auch in Nacht), Chat-Avatar und Chat-Kopf auf Scheibe `#FBF3E4` (Durchmesser = Größe, Kopf darin 86 %), in Hell und Dunkel gleich. Siehe `mockups/v2-heute.png`.
- Auf Karten (`card` Weiß 92 % im Thema Hell) braucht Manny nichts. Im Thema Dunkel gilt die Scheibe wie oben.

### 6.5 Kleine Größen
Geprüft im Kontaktbogen `docs/design/manny/manny-uebersicht.png` (Kopf bei 40/56/80 dp, 1x und 3x, hell und dunkel):
- **56 dp und 80 dp:** klar lesbar in beiden Varianten.
- **40 dp:** bei 2x und 3x (praktisch alle aktuellen Telefone) lesbar: Brille bzw. Augen, Schnabel und Rundform erkennbar, Kontur 1,1 dp (3 physische px bei 3x). Bei 1x (mdpi) wirkt die Mit-Brille-Variante noch erkennbar, die Ohne-Brille-Variante verliert die Glanzpunkte. **Mindestgröße Kopf: 40 dp; nichts darunter**, keine Kopf-Variante für 32 dp. Brief v2 verlangte vereinfachte Köpfe mit Kontur ≥ 3 px: erfüllt ohne Sonderzeichnung, vorausgesetzt Mindestgröße und helle Scheibe.

### 6.6 Bildbeschreibung für Screenreader
„Manny, dein Begleiter“ (bestehender Text `mannyImageLabel`), einmal je Darstellung, unabhängig von Variante und Pose; nicht doppelt zur Sprechblase (Blase trägt den Inhalt). Strahlen und Träne sind Teil der Grafik und haben kein eigenes Label. Wo Manny als Knopf oder Avatar auftritt, trägt der Knopf/die Zeile sein eigenes Label und das Bild ist ausgeblendet. Auswahlkarten siehe 6.7.

### 6.7 Verwendung
Unverändert aus Brief v2 Abschnitt 6: Manny ist nie modal und blockiert nichts; Sprechblase höchstens 2 Sätze, X ≥ 48 dp, höchstens einmal pro Anlass und Tag (v1 UI-23); Manny reagiert nicht auf Stimmungswerte (Spec C-3), aber auf Schmerzmeldung in der Session mit Trösten (jetzt Pose `traurig`); Erinnerungen nie schuldzuweisend. Manny-Zugänge unverändert (Abschnitt 5).

## 6a. Onboarding: neuer Schritt 1 „Wie soll Manny aussehen?“

**Heutige Schrittfolge (aus `app/lib/ui/onboarding/onboarding_flow.dart` gelesen):** 1 Name, 2 Datenschutz (Zustimmung), 3 Verletzungstyp, 4 Datum; `_lastStep = 3`, `StepProgress`, „Schritt N von 4“.
**Neu: 5 Schritte.** Der Look-Schritt steht **vor dem Namen**, weil Manny ab dem Namen-Schritt mit Blase und Figur auftritt und dort bereits die gewählte Variante zeigen soll. Alternativen (am Ende) hätten Manny in vier Schritten in einer nicht gewählten Variante gezeigt.

| Nr. | Schritt | Manny |
|---|---|---|
| 1 | **Wie soll Manny aussehen?** (neu) | keine Figur oben, keine Blase: die zwei Karten sind Manny |
| 2 | Name (bisher 1), Blase „Moin, ich bin Manny …“ | gewählte Variante, Pose `freudig` (Begrüßen), 120 dp |
| 3 | Datenschutz (bisher 2) | gewählte Variante, `normal` |
| 4 | Verletzungstyp (bisher 3) | wie bisher |
| 5 | Datum (bisher 4) | wie bisher |

**Layout (`mockups/v2-manny-wahl.png`):** Kopf-Karte mit Fortschritt „Schritt 1 von 5“ und Titel „Wie soll Manny aussehen?“ (Text nur auf der Kopf-Karte, V2-5). Darunter **zwei gleich große Auswahlkarten** nebeneinander (je ca. 175 dp breit bei 390 dp Breite, Mindesthöhe 300 dp): Manny `normal` (Leinwand bis 190 dp hoch, auf Kartenbreite begrenzt), Name („Mit Brille“, „Ohne Brille“), Radio-Kreis 28 dp, darunter Text „Ausgewählt“ bei der gewählten Karte. Darunter Hinweiskarte: „Du kannst das jederzeit im Profil ändern.“ Unten Zurück (Glas, 112 dp) und Weiter (Primär, Mandarine, 56 dp), Abstand 12 dp, wie in den übrigen Schritten. Reihenfolge: Mit Brille links bzw. oben, Ohne Brille rechts bzw. unten. Bei Breite < 360 dp oder Systemschrift > 130 % stehen die Karten **untereinander** (Karte dann Bild links 120 dp, Text rechts); der Weiter-Button bleibt erreichbar (Scrollbereich mit Reserve).
**Auswahl und Radio-Semantik:** die ganze Karte ist ein Radio (Rolle „Auswahl“, eine Gruppe „Manny-Look“, Zustand gewählt/nicht gewählt, „1 von 2“). Gewählt: Rand 3 dp Mandarine, Fläche `#FFF1E4`, gefüllter Kreis mit Haken, Text „Ausgewählt“ (nie nur Farbe). Nicht gewählt: Rand 3 dp neutral (≥ 3:1), leerer Kreis. Tastatur: Tab fokussiert die Gruppe (ein Tab-Stopp), Pfeiltasten wechseln die Auswahl, Leertaste wählt, Fokusring 3 dp um die Karte. Hit-Area: ganze Karte, ≥ 48 dp.
**Label der Karten für den Screenreader:** „Manny mit Brille, ausgewählt, 1 von 2“ bzw. „Manny ohne Brille, nicht ausgewählt, 2 von 2“; die Bilder darin sind ausgeblendet.
**Vorbelegung (Annahme):** **Mit Brille** ist vorausgewählt, damit „Weiter“ sofort geht und niemand eine Pflichtentscheidung vor dem eigentlichen Start treffen muss. Begründung: Die Sonnenbrille war das freigegebene Markenzeichen (Grunddesign v2, Variante „Lässig“) und das Bild des Nutzers steht an erster Stelle. Die Vorbelegung ist eine Annahme und kein Zwang; Ohne Brille ist gleichberechtigt.
**Weiter:** immer aktiv (es gibt immer eine Wahl). Tipp auf eine Karte speichert die Wahl **sofort** (Neustart im Onboarding behält sie); Weiter geht zu Schritt 2. Kein Dialog, keine Animation länger als 120 ms bei reduzierter Bewegung; sonst Karte federt einmal (Brief 3.6).
**Zurück:** aus Schritt 2 zurück zu Schritt 1 mit erhaltener Wahl. Aus Schritt 1 wie bisher aus dem ersten Schritt: App verlassen (`SystemNavigator.pop`, bestehendes Verhalten). Die Mikrofon-Funktion bleibt dem Namen-Schritt vorbehalten und erscheint hier nicht.

## 6b. Profil: Zeile „Manny-Look“

Neue Zeile in der Profil-Liste (Brief 7.6), **direkt über „Darstellung“**: Symbol-Kachel mit Manny-Kopf (aktuelle Variante, auf Scheibe), Titel „Manny-Look“, Wert „Mit Brille“ bzw. „Ohne Brille“, Chevron, ≥ 56 dp hoch. Tipp öffnet ein **opakes Sheet** „Manny-Look“ (Brief 3.5, kein Blur) mit denselben zwei Karten wie in 6a (gleiche Radio-Semantik, gleiche Zustände), dem Hinweis „Gilt für die ganze App.“ und einem Button „Fertig“. **Wechsel ohne Neustart:** die Auswahl wirkt sofort, die Zeile im Hintergrund zeigt den neuen Wert und Kopf, nach „Fertig“ (oder Schließen) zeigen Pfad, Heute, Chats, Chat-Vollbild und Manny-Knopf die neue Variante. Das Screenreader-Echo bei Wahl: „Manny-Look: Ohne Brille“. Beim Löschen aller Daten („Deine Daten“) wird der Look auf die Vorbelegung zurückgesetzt und das Onboarding startet wieder bei Schritt 1.

## 11. UI-Akzeptanzkriterien (ersetzt V2-56, ergänzt V2-65 ff.)

- **V2-56 (ersetzt):** Manny erscheint ausschließlich aus den 8 gelieferten PNGs (`brille/` oder `ohne/` nach Wahl, Posen `normal`, `freudig`, `traurig`, `kopf`), nie als gezeichneter Platzhalter; die Variante ist in allen Posen und an allen Stellen dieselbe; nicht gelieferte Anlässe fallen nach Tabelle 6.3 auf die Fallback-Pose zurück; es gibt keine Platzhalter-Kennzeichnung mehr (Code-Suche: kein `CustomPainter` für Manny, kein Hinweis „Platzhalter“).
- **V2-65:** Das Onboarding hat 5 Schritte mit „Schritt N von 5“; Schritt 1 ist „Wie soll Manny aussehen?“ mit zwei Karten „Mit Brille“ und „Ohne Brille“; Name, Datenschutz, Verletzung, Datum sind Schritt 2 bis 5.
- **V2-66:** Die Karten sind eine Radio-Gruppe: genau eine ist gewählt, gewählt = Rand 3 dp Mandarine plus Haken plus Text „Ausgewählt“; Screenreader liest „Manny mit Brille, ausgewählt, 1 von 2“; Pfeiltasten wechseln, Tab hat einen Stopp in der Gruppe, Fokusring sichtbar; Hit-Area je Karte ≥ 48 dp.
- **V2-67:** Beim ersten Öffnen ist „Mit Brille“ vorgewählt, Weiter ist aktiv; nach Wahl „Ohne Brille“ und Weiter zeigen Name-Schritt, Datenschutz, Pfad, Heute und Chats Manny ohne Brille; Zurück aus Schritt 2 zeigt Schritt 1 mit erhaltener Wahl; nach App-Neustart mitten im Onboarding ist die Wahl erhalten.
- **V2-68:** Profil hat die Zeile „Manny-Look“ (≥ 56 dp, Wert und Kopf sichtbar); das Sheet wechselt die Variante sofort und ohne Neustart; danach zeigt jede sichtbare Manny-Stelle (Pfad, Heute-Knopf, Chats, Chat-Vollbild) die neue Variante (Widget-Test: Asset-Pfad vorher `brille/…`, nachher `ohne/…`); die Wahl bleibt nach Neustart erhalten.
- **V2-69:** In Welt Nacht steht hinter Manny auf dem Pfad ein Halo (Weiß 28 %, 1,15 × Leinwandbreite); Kontur gegen den Untergrund hinter der Figur ≥ 3:1 (Renderprobe); Manny-Knopf, Chat-Avatar und Chat-Kopf stehen auf heller Scheibe in allen Welten und Themen; mit „Transparenz reduzieren“ ist der Halo opak.
- **V2-70:** Pose-Zuordnung nach Tabelle 6.3 (Unit-Test der Abbildung): Feier und Begrüßen liefern `freudig`, Schmerzmeldung in der Session und „schlechter Tag“ liefern `traurig`, alle übrigen Anlässe `normal`, Knopf und Avatare `kopf`; die Brille ist in keiner Pose abgesetzt (gleiche Variante in allen Posen).
- **V2-71:** Das Manny-Bild hat das Label „Manny, dein Begleiter“ genau einmal je Darstellung, ist neben Blase, Knopf oder Zeile mit eigenem Label ausgeblendet; Strahlen und Träne haben kein eigenes Label.
- **V2-72:** Kein Manny-Kopf wird kleiner als 40 dp dargestellt (Code-Prüfung der Größen); 40 dp und 56 dp stehen auf heller Scheibe; im Kontaktbogen bleiben Brille bzw. Augen, Schnabel und Kontur bei 40 dp @3x erkennbar.
- **V2-73:** Alle 24 Dateien (8 Bilder × 1x/2x/3x) sind als Assets deklariert, das Gerät lädt die passende Dichte (Widget-Test mit `devicePixelRatio` 1, 2, 3), und kein Bild wird größer als seine Leinwand (Körper 158 × 193 dp, Kopf 110 dp) dargestellt.
- **V2-74:** Mit „Bewegung reduzieren“ ist Manny statisch und der Look-Wechsel überblendet nicht länger als 120 ms (V2-26 bleibt).
- **V2-75:** Bei Systemschrift 200 % und bei 320 × 568 dp stehen die Look-Karten untereinander, alles ist lesbar, Weiter und Zurück erreichbar, kein horizontales Scrollen (V2-24, V2-25).

## 10. Migration (ergänzt die Tabelle aus Brief v2)

| Gebaut | Änderung |
|---|---|
| `app/lib/ui/components/manny.dart` (`MannyPlaceholder`, `MannyGeometry`, `_MannyPainter`, `MannyCrop`) | Painter entfällt; neues Widget zeigt PNG nach Variante, Pose, Crop (`full`/`head`), Größen und Semantik beibehalten; Dateikopf-Kommentar aktualisieren |
| `lib/logic/manny_occasions.dart` (`MannyPose`) | zentrale Abbildung Anlass/Pose → Datei (Tabelle 6.3); `greeting` wird `freudig` |
| `lib/ui/components/manny_bubble.dart`, `manny_chat_button.dart`, `chat_avatar.dart`, `chat_message_list.dart` (Zeile ca. 140), `lib/ui/chat/manny_chat_screen.dart` (Zeile ca. 46), `lib/ui/path/path_view.dart` (Zeile ca. 204), `lib/ui/onboarding/onboarding_manny.dart` | Variante aus dem Zustand lesen, helle Scheibe für Kopf, Halo in Nacht, Größen nach 6.2 |
| `lib/ui/onboarding/onboarding_flow.dart`, `step1_name.dart` … `step4_date.dart` | 5 Schritte (`_lastStep = 4`), neuer Look-Schritt, `_stepPage`, `_bubbleText`, `_next`, `_back`, `StepProgress` total 5; Name-Schritt wird Index 1 |
| `lib/logic/app_state.dart` (`OnboardingState.step` Bereich 0 bis 3), `profile.dart`, `lib/data/data_eraser.dart` | Schrittbereich 0 bis 4; Feld für den Manny-Look (Ablage nach Entscheidung des Umsetzers, muss Neustart überleben und vom Löschen aller Daten zurückgesetzt werden) |
| `lib/logic/migrations.dart` (`kCurrentSchema`) | Schema +1: nicht abgeschlossenes Onboarding: `step` + 1 (alter Schritt 1 wird Schritt 2); Look = `brille` (mit Brille) für alle Bestandsdaten; abgeschlossene Nutzer sehen den Look-Schritt nicht |
| `lib/l10n/strings_de.dart` | Texte „Wie soll Manny aussehen?“, „Mit Brille“, „Ohne Brille“, „Ausgewählt“, „Du kannst das jederzeit im Profil ändern.“, „Manny-Look“, „Gilt für die ganze App.“, `stepOf` Gesamt 5 |
| `lib/theme/cura_metrics.dart` (`mannyPathHeight`, `mannyOnboarding*`, `mannyHeadInButton`) | Größen auf Leinwandhöhen nach 6.2 umstellen |
| Profil (neu in v2) | Zeile „Manny-Look“ plus Sheet (6b) |
| `app/pubspec.yaml`, `app/assets/manny/` | Dateien aus `docs/design/manny/{brille,ohne}` kopieren (inkl. `2.0x/`, `3.0x/`), Verzeichnisse als Assets deklarieren; Quelle bleibt `docs/design/manny` |
| `lib/dev/scenarios.dart` (Zeilen ca. 434 bis 486) | Posen-Szenario auf `normal`/`freudig`/`traurig` und beide Varianten |
| **Goldens** `test/golden/goldens/manny_poses.png` (neu: je Variante), `scenario_*`, Onboarding-Szenarien | neu erzeugen; zusätzlich Golden für den Look-Schritt (Hell, Dunkel, 200 % Schrift, 320 dp) |
| Tests Onboarding (Schrittzahl, Reihenfolge, Persistenz), Migration, `manny_occasions` | an 5 Schritte, Schemasprung und neue Pose-Abbildung anpassen |

**Hinfällig aus Brief v2:** Abschnitt 6 (ersetzt durch diese Ergänzung), Abschnitt 2 Zeile „Manny: Flachformen-Platzhalter → Skizze Variante A“, die Platzhalter-Kennzeichnung (Abschnitt 6, V2-56, Annahme „Bildplatzhalter“ nur für Manny), Offene Entscheidung 1 **für Manny** (Rechte erledigt; offen bleiben nur die 3D-Objekte Flamme, Stern, Pokal), Abschnitt 14 „echte Illustrationen“ für Manny, Hinweis „Mockups: Manny als Platzhalter“ für `v2-heute.png`, Abschnitt 2 „Onboarding (4 Schritte)“ (jetzt 5), Quelle `manny4.py` und `mockups/v2-manny-varianten.png`, `v2-manny-sticker.png` (nur noch historisch). Brief v1 UI-Kriterien zu Onboarding mit „4 Schritten“ gelten mit Schrittzahl 5.

## Annahmen
- Vorbelegung **Mit Brille** (Begründung in 6a). Alternative: keine Vorbelegung mit deaktiviertem Weiter; verworfen, weil es eine Hürde am Einstieg schafft.
- Look-Schritt als Schritt 1 vor dem Namen.
- Bestandsdaten: Look `mit Brille`; wer das Onboarding schon abgeschlossen hat, wird nicht erneut gefragt, sondern findet den Wechsel im Profil.
- Der Halo in Nacht (Weiß 28 %) und die Scheibenfarbe `#FBF3E4` sind Gestaltungsentscheidungen aus der Messung (6.4) und müssen per Renderprobe bestätigt werden (V2-69).
- Mit nur drei Posen sind Ziel, Erinnerung, Training, Denken und Schlafen visuell gleich (`normal`); die Bedeutung trägt Text bzw. Umgebung.
- Der Nutzer verantwortet die Nutzungsrechte; Dateien im Repo: `quelle/*.webp` (Originale) und die Ableitungen.

## Offene Entscheidungen
1. **[nicht blockierend]** Nachweis der Rechte im Repo (z. B. ein Satz in `docs/design/manny/` zu Urheber und Entstehung)? Falls die Bilder mit einem KI-Bildwerkzeug entstanden sind: Nutzungsbedingungen für kommerzielle Nutzung und Store-Angaben prüfen. *Annahme bis zur Klärung:* kein Nachweis nötig für den Prototyp.
2. **[nicht blockierend]** Weitere Posen später (Ziel/Fahne, Training, Denken, Schlafen, Erinnerung)? *Annahme:* nein, Fallback `normal`. *Auswirkung:* nur die Zuordnungstabelle und Dateien ändern sich.
3. **[nicht blockierend]** Traurig mit Träne bei Schmerzmeldung: gewünscht oder zu dramatisch? *Annahme:* ja, Trösten = `traurig` (Nutzerentscheidung).
4. **[nicht blockierend]** Halo in Nacht gewünscht, oder soll Manny in Nacht grundsätzlich nur auf Scheibe/Karte stehen? *Annahme:* Halo (6.4).
5. **[nicht blockierend]** Soll Bestandsnutzern nach dem Update einmalig der Wechsel angeboten werden (Hinweis im Profil)? *Annahme:* nein.

## Nicht enthalten
Weitere Posen, Änderungen an den Bildern außer Freistellen und Zuschnitt, Animation der Bilder im Detail (bleibt Hüpfen/Quetschen/Wippen im Code), Varianten über „mit/ohne Brille“ hinaus (Farben, Accessoires), App-Code (Umsetzung beim `flutter-developer`), 3D-Objekte (Flamme, Stern, Pokal) und deren Rechte.
