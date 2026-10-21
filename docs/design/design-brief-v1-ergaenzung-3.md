# Design-Brief v1, Ergänzung 3: Ausblick "Prävention & Gesundheitssport" hinter dem Boss

Status: **FREIGEGEBEN (2026-10-10)** · Umsetzung nach Freigabe: `flutter-developer` · Bezug: `docs/design/design-brief-v1.md` (inkl. Errata, Abschnitt 14), `design-brief-v1-ergaenzung-1.md` (3.5 NodeHint, UI-37 bis UI-69), `design-brief-v1-ergaenzung-2.md` (UI-70 bis UI-89), `docs/plan/flutter-plan-v1.md` (7.2, 7.3)
Orientierungsbild (kein Pixel-Vorbild, Schloss-Symbol und Schrift sind Platzhalter): `docs/design/mockups/pfad-ausblick-v1.png`

**Geltung.** Alles Bestehende (Tokens, Komponenten, Regeln, Errata E-1/E-2, UI-1 bis UI-89) gilt unverändert, außer den in Abschnitt 5 ausdrücklich genannten Stellen. Neue Kriterien beginnen bei **UI-90** (höchste bisher vergebene Nummer: UI-89 in Ergänzung 2).

## 1. Anlass und Nutzerentscheidungen

Der Reha-Pfad soll nicht mit der Boss-Unit enden. Danach schließt eine Phase "Prävention & Gesundheitssport" an, die den Nutzer weiter begleitet.

Vom Nutzer entschieden:
1. Im ersten Ausschnitt nur ein **Ausblick**: hinter dem Boss ein gesperrter Abschnitt "Prävention & Gesundheitssport". Die volle Phase kommt später mit eigener Spec.
2. "Return to Sport" **bleibt der Boss** (Höhepunkt der Reha). Die Pfadlinie führt darüber hinaus weiter zum gesperrten Ausblick.

**Bewusst nicht festgelegt (nichts erfunden):** Länge der Phase, Inhalte, Wahlmöglichkeiten, Streak- und Freeze-Regeln dort, Wochenrhythmus, Fachinhalte. Der Ausblick enthält deshalb keine Wochenzahl, keine Übung, keine Fachaussage und keine Zusage zu Umfang oder Regeln. Er sagt nur: Hier geht es danach weiter.

## 2. Gestaltung des Ausblicks

### 2.1 Element: `PathOutlook` (neu, Abschnittsmarke, **keine Unit**)

Eine breite, mittig sitzende Marke am oberen Ende des Pfads, ganz oberhalb des Boss. Sie ist bewusst **kein Kreis** und **keine Unit**: Sie zählt nicht zu den Units des Beispielpfads, hat keine Woche, keine Phase, keinen Status außer "gesperrt", keinen Ring und trägt nie Manny. Die andere Form zeigt: Das ist ein neues Kapitel, nicht die nächste Station der Reha.

| Eigenschaft | Vorgabe |
|---|---|
| Position | horizontal **zentriert** im Pfadbereich (nicht der Links/Rechts-Wechsel der Units), oberhalb des Boss |
| Breite | `min(Pfadbreite − 2 × 16 dp, 300 dp)` |
| Höhe | mindestens 72 dp (= `unitLarge`), wächst mit Textskalierung |
| Form | Radius `CuraRadius.card` (24) |
| Füllung | Glas (`surface-glass-top` nach `-bottom`), bei hohem Kontrast `surface-opaque`; **kein Blur** (kein Blur-Budget verbraucht) |
| Rand | **gestrichelt** (Strich 6 dp, Lücke 4 dp), `controlBorder` 1,5 dp, Farbe wie Zustand "Gesperrt" (`lockedBorder`, Weiß 20 %; bei hohem Kontrast wie dort `border-control-hc`). Gestrichelt trennt ihn formal von den durchgezogenen Rändern der Units. |
| Inhalt (links nach rechts) | Schloss-Kreis 36 dp (Rand und Schloss wie "Gesperrt": `lockedBorder`, `lockedIcon` Weiß 50 %), Abstand 12 dp, Textblock; Innenabstand 14 dp oben und unten, 16 dp seitlich |
| Titel | "Prävention & Gesundheitssport", Stil `heading`, `text-1` (13,18:1 auf Glas), bricht um |
| Untertitel | "Danach geht es weiter", Stil `secondary`, `text-2` (6,88:1 auf Glas) |
| Zustand | immer **gesperrt**. Es gibt keinen aktuellen und keinen erledigten Zustand. |
| Bewegung | keine (statisch, kein Puls, kein Schein, keine Animation) |
| Drücken | Füllung 10 % heller wie bei Units (Ergänzung 1, 3.5) |

Tokens nur aus dem bestehenden System; keine neuen Farben, Radien oder Schriftstile. Neu sind nur Strichlängen 6/4 dp als Maß in `cura_metrics.dart` (Ablage wie die anderen Pfad-Maße) und der Strichel-Painter für den Rand.

### 2.2 Pfadlinie über den Boss hinaus

- Die gepunktete **Zukunftslinie** (Weiß 22 %, 3 dp, runde Punkte, Abstand 9 dp, wie bisher) läuft vom Boss weiter nach oben zum Ausblick. Sie endet an der **Unterkante der Marke** in deren horizontaler Mitte (Aussparung um die Marke 1 dp, wie `pathLineClipUnit`) und läuft um die Beschriftung "Return to Sport" herum (Aussparung 2 dp, wie bisher).
- Kurve: kubische Bézier wie zwischen Units; weil die Marke zentriert ist und der Boss links oder rechts liegen kann, entsteht ein weicher Bogen.
- Lichter Abstand zwischen Boss-Oberkante (bzw. Boss-Beschriftung, falls sie oben läge) und Unterkante der Marke: mindestens `pathUnitGapMin` (84 dp).
- Über die Marke hinaus geht keine Linie (der Pfad endet dort sichtbar, ohne Auslaufen ins Leere).
- Die Linie bleibt für Screenreader ausgeblendet (unverändert).

### 2.3 Boss bleibt Boss

Boss-Unit unverändert (92 dp, Rand `accent` 55 %, Stern `accent-hi`, Beschriftung "Return to Sport"). Der Ausblick ist **leiser** als der Boss: kein Akzent, kein Stern, gestrichelt, Glas. Der Boss bleibt der visuelle Höhepunkt.

## 3. Texte (Deutsch, "du", Ton der Spec; alle in `strings_de.dart`)

| Zweck | Text |
|---|---|
| Titel (sichtbar) | Prävention & Gesundheitssport |
| Untertitel (sichtbar) | Danach geht es weiter |
| NodeHint beim Antippen | Nach Return to Sport geht es hier weiter. Die Details folgen noch. |
| Screenreader-Label | Prävention und Gesundheitssport, gesperrt. |
| Screenreader beim Aktivieren (Ansage) | Nach Return to Sport geht es hier weiter. Die Details folgen noch. |

Begründungen: Der Titel ist der vom Nutzer genannte Name. "Danach geht es weiter" und der Hint versprechen nur die Fortsetzung, nichts zu Dauer, Inhalt oder Regeln. "Die Details folgen noch" ist ehrlich, ohne Termin. Im Screenreader-Label steht "und" statt "&", damit die Ausgabe sauber ist. Keine klinischen Begriffe, kein "Patient", keine Sie-Form. Die Wortlisten-Prüfung (Plan 12.3, Regel 10) muss grün bleiben; die neuen Texte enthalten keinen Listeneintrag. Der Hint hat zwei kurze Sätze und bleibt damit unter der Satzgrenze für Manny-Texte (gilt formal nur für Manny, wird hier freiwillig eingehalten).

## 4. Auswirkungen auf bestehende Regeln

1. **Boss nie aktuell:** unverändert. Der Boss behält Status "gesperrt" in allen Fällen.
2. **Ausblick nie aktuell:** Er ist kein Element der Unit-Liste, hat keine ID in `completedUnitIds`, taucht in der Statusableitung nicht auf und kann weder erledigt noch aktuell werden. "Aktuell = erste nicht erledigte Unit außer Boss" bleibt wörtlich gültig. Manny sitzt nie auf dem Ausblick.
3. **Units-Zählung:** Der Beispielpfad hat weiter **52 Units** und weiter die IDs `w{W}-d{1..3}`, `w{W}-goal`, `p{P}-end`, `boss`. Der Ausblick ist ein eigenes Darstellungselement (z. B. `PathOutlook`) ohne Einfluss auf Generator, Fortschritt, Streak oder Profil-Neuberechnung (N-7).
4. **Polster oben:** Die Regel "jede Unit auf 55 % der Viewport-Höhe scrollbar" gilt auch für den Ausblick. Er ist jetzt das oberste Element, `padTop` (0,55 × Viewport-Höhe, abzüglich des Platzes, den das oberste Element ohnehin darüber hat) bezieht sich auf den Ausblick. Der Boss bleibt dadurch ebenfalls auf 55 % scrollbar. Das initiale `jumpTo` auf die aktuelle bzw. Manny-Unit bleibt unverändert.
5. **Label "Beispielpfad":** bleibt unverändert in der Kopfzeile, auch für ACL. Der Ausblick bekommt kein eigenes Beispiel-Label (er ist selbst ein Ausblick, die Kopfzeile gilt für den ganzen Pfad).
6. **Kopfzeile:** unverändert ("Woche 12", "Phase 3 · Kreuzband" bleibt auch im Endfall). Der Ausblick ist keine Phase 4 und erscheint nicht in der Kopfzeile.
7. **Endfall** (alles bis vor Boss erledigt): unverändert. Manny sitzt auf der letzten erledigten Unit, Eintragen zählt nur für den Streak. Boss und Ausblick bleiben gesperrt, NodeHints wie bisher beziehungsweise nach 3.
8. **NodeHint:** gleiche Komponente, gleiches Verhalten wie bei gesperrten Units (Ergänzung 1, 3.5): kein Tabwechsel, schließt eine Manny-Blase, höchstens einer gleichzeitig, Erscheinen über der Marke (wenn oben weniger als 64 dp frei sind, darunter), Schließen durch Tipp, Scrollen, Escape/Zurück, Tabwechsel und nach 5 s (nicht bei aktivem Screenreader). Pfeil zeigt auf die Marke (Mitte), Hint sitzt zentriert über ihr.
9. **Blur-Budget, freie Zonen, Streak, Freezes, Tageswechsel, Heute:** nicht berührt.
10. **Glow (E-1):** Der Ausblick liegt in der Ruhelage nicht im Bereich des Lichtflecks (zentriert, mindestens 45 dp vom Rand); Text auf Glas bleibt unter der Schwelle 16 % (`text-1`, `text-2`). Die Prüfung läuft wie UI-7 über die Alpha-Funktion. Inhalt, den der Nutzer unter den Lichtfleck scrollt, ist laut Präzisierung 2026-10-08 ausgenommen.
11. **Hoher Kontrast:** Marke opak (`surface-opaque`) mit `border-control-hc` (gestrichelt), kein Glow.
12. **Reduzierte Bewegung:** nichts zu tun (statisch); NodeHint wie bisher sofort.

## 5. Betroffene Stellen in Brief und Plan (vom Orchestrator anzupassen, hier nicht geändert)

**`docs/design/design-brief-v1.md`**
- **5.5 Pfad-Units:** Verweis ergänzen: "Hinter dem Boss folgt der Ausblick `PathOutlook` (Ergänzung 3), keine Unit." Die Größenliste bleibt (kein weiterer Durchmesser).
- **5.5, Zeile "Zukünftige Strecke":** ergänzen, dass die Linie vom Boss bis zum Ausblick reicht.
- **6.2 Inhalt:** Satz "am Ende des Pfads die Boss-Unit" ergänzen um "dahinter ein gesperrter Ausblick 'Prävention & Gesundheitssport' (Ergänzung 3)".
- **8 Screenreader (Zeile mit Boss-Label):** Label des Ausblicks ergänzen (Abschnitt 3 dieser Ergänzung).
- **13 Nicht enthalten:** "Return-to-Sport-Phase (Spec 6) bis auf die Boss-Unit als gesperrtes Element" ergänzen um "und den gesperrten Ausblick Prävention & Gesundheitssport; die volle Phase folgt mit eigener Spec".
- Bezug in Abschnitt 14 (Errata) nicht nötig; E-1 gilt unverändert.

**`docs/design/design-brief-v1-ergaenzung-1.md`**
- **3.5 Tabelle "Gesperrt":** Zeile oder Fußnote für den Ausblick ergänzen (Text aus Abschnitt 3 dieser Ergänzung, nicht Teil von "Kommt in Woche N").
- **UI-60 und UI-63:** Hinweis aufnehmen, dass der Ausblick wie eine gesperrte Unit bedienbar ist (neue Kriterien UI-91 bis UI-93 decken es ab, keine Textänderung zwingend).

**`docs/plan/flutter-plan-v1.md`**
- **7.2 Pfad-Generator:** Satz "Gesamt 52 Units" bestätigen und ergänzen, dass der Ausblick nicht Teil der Liste ist (Konstante z. B. `kPathOutlookShown = true`, Darstellung nur in der UI). "Boss bleibt immer gesperrt (Brief 13)" um "Ausblick ebenfalls kein Status" ergänzen. Unit-Tests: Anzahl bleibt 52, Ausblick nie `current`.
- **7.2 NodeHint-Texte und Screenreader-Labels:** Texte aus Abschnitt 3 ergänzen (Schlüssel z. B. `outlookTitle`, `outlookSubtitle`, `outlookHint`, `outlookLabel`).
- **7.3 Pfad-Layout:** `layout()` liefert zusätzlich eine Placement-Angabe für den Ausblick (Mitte x = Pfadbreite / 2, Höhe statt Durchmesser); `padTop` bezieht sich auf das oberste Element (Ausblick); Test "für den Ausblick existiert ein Offset, der ihn auf 55 % setzt". Test "Abstand Boss zu Ausblick ≥ 84 dp".
- **Dateiliste / Komponenten (Abschnitt Struktur):** neue Komponente `PathOutlook` und Linienende im `_PathLinesPainter` (`app/lib/ui/path/path_view.dart`, `app/lib/ui/components/`), Strings in `app/lib/l10n/strings_de.dart`.
- **Tests (UI-Abschnitt/Matrix):** UI-90 bis UI-99 in die Testzuordnung aufnehmen (Widget-Test, Screenshot-Matrix 320×568, 390×844, 430×932, 200 % Schrift, hoher Kontrast).

**Hinweis zum Stand des Codes (nicht ändern, nur beachten):** `strings_de.dart` hat für den Boss in der laufenden Woche 12 den Text "Dein Ziel: zurück in deinen Sport." (`hintBossGoal`, Nutzerentscheidung), während Brief/Plan "Return to Sport kommt in Woche 12" nennen. Das ist für diese Ergänzung unerheblich, sollte aber bei der Anpassung der Dokumente mit dem Code abgeglichen werden.

## 6. UI-Akzeptanzkriterien (Fortsetzung)

- UI-90: Am oberen Ende des Pfads steht oberhalb der Boss-Unit "Return to Sport" eine Marke mit dem Titel "Prävention & Gesundheitssport" und dem Untertitel "Danach geht es weiter". Der Boss ist weiterhin die 92-dp-Unit mit Stern und Beschriftung "Return to Sport"; darüber steht keine weitere Unit.
- UI-91: Die Marke zeigt Schloss, gestrichelten Rand (`lockedBorder`) und Glas-Füllung (bei hohem Kontrast `surface-opaque` mit `border-control-hc`), hat keinen Blur, keinen Ring, keinen Schein, keinen Stern und keine Animation. Sie ist horizontal mittig, höchstens 300 dp und höchstens Pfadbreite minus 32 dp breit, mindestens 72 dp hoch.
- UI-92: Tipp auf die Marke zeigt einen `NodeHint` mit "Nach Return to Sport geht es hier weiter. Die Details folgen noch.", wechselt nicht den Tab, schließt eine sichtbare Manny-Blase und verhält sich sonst wie UI-62 (opak, ohne Blur, höchstens einer, im sichtbaren Bereich, bricht bei 200 % um, schließt durch Tipp, Scrollen, Escape und nach 5 s, nicht bei aktivem Screenreader).
- UI-93: Die Marke hat Hit-Area ≥ 48 dp, sichtbaren `focus-ring`, ist mit Enter und Leertaste auslösbar, ist für den Screenreader eine Schaltfläche mit dem Label "Prävention und Gesundheitssport, gesperrt." und sagt beim Aktivieren den Hinweistext an. Fokusreihenfolge: Marke, dann Boss, dann die übrigen Units von oben nach unten.
- UI-94: Die gepunktete Zukunftslinie (Weiß 22 %, 3 dp) führt vom Boss zur Unterkante der Marke (Mitte) und endet dort. Über die Marke hinaus gibt es keine Linie. Der lichte Abstand zwischen Boss und Marke beträgt mindestens 84 dp.
- UI-95: Der Ausblick ist nie aktuell und nie erledigt: In allen Szenarien (Start, Mitte, Endfall, Profiländerung) sitzt Manny nie auf ihm, und er taucht nicht in `completedUnitIds` oder der Statusableitung auf. Der Beispielpfad hat weiterhin genau 52 Units, der Boss ist nie aktuell.
- UI-96: Im Endfall (alles bis vor Boss erledigt) verhalten sich Manny, Eintragen, Streak und Boss unverändert; Boss und Marke sind gesperrt.
- UI-97: Jede Unit, der Boss und die Marke lassen sich per Scrollen auf 55 % der Viewport-Höhe bringen (Test der Layout-Funktion für erste, mittlere, letzte Unit, Boss und Marke bei 320 und 430 dp Breite). Die Marke und der Boss liegen nie hinter Kopfzeile oder Navigation verdeckt in der Endlage.
- UI-98: Die Kopfzeile zeigt weiterhin "Woche N", "Phase M · Kurzname" und das Label "Beispielpfad" (auch für ACL); es erscheint keine Phase 4 und kein Wochenwert für den Ausblick. Die Texte der Marke enthalten keine Zahl, keine Übung und keine Zeitangabe.
- UI-99: Bei 200 % Systemschrift und bei 320 × 568 dp bricht der Titel der Marke um, nichts wird abgeschnitten oder überlappt, kein horizontales Scrollen; Titel und Untertitel haben Kontrast ≥ 4,5:1 (Alpha-Prüfung nach E-1 in der Ruhelage), und der Test der statischen Regeln (Tokens nur aus `lib/theme/`, Texte nur in `strings_de.dart`, Wortlisten Ton) bleibt grün.

## 7. Annahmen

- A-1 (bestätigt): Die Marke ist zentriert statt im Links/Rechts-Wechsel, damit sie nicht wie eine weitere Unit gelesen wird.
- A-2 (bestätigt): Der Titel ist genau die vom Nutzer genannte Bezeichnung; der Untertitel "Danach geht es weiter" und der Hint sind mein Textvorschlag und versprechen nur die Fortsetzung.
- A-3: Der Ausblick erscheint für alle Verletzungstypen gleich (wie der Beispielpfad, N-3), da es keine typspezifische Aussage gibt.
- A-4: Der Ausblick ist Platzhalter und wird mit der späteren Spec zur echten Phase; die Marke ersetzt sich dann durch deren Units. Das steht im Code-Kommentar von `PathOutlook`.
- A-5: Das Schloss-Symbol bleibt in der Marke, auch wenn die Phase später freischaltbar wird (dann neuer Brief).

## 8. Nutzerentscheidungen (2026-10-10)

Der Nutzer hat entschieden: **Variante A** (breite Karte, mittig) und der Untertitel „Danach geht es weiter" **bleibt**. Variante B entfällt. Die ursprüngliche Abwägung bleibt zur Nachvollziehbarkeit stehen:

1. **Form des Ausblicks.** Variante A (empfohlen, hier ausgearbeitet): breite Marke, gestrichelt, mittig, keine Unit. Vorteil: klar ein neues Kapitel, kein 53. Pfadpunkt, genug Platz für den langen Titel ohne Abkürzung, bricht bei großer Schrift sauber um. Variante B: gesperrte große Unit (72 dp, Kreis, Schloss) mit Beschriftung darunter wie "Phasen-Abschluss". Vorteil: weniger neuer Code, gleiche Form wie bestehende Units; Nachteil: wirkt wie eine weitere Station, der lange Titel steht nur als kleine Beschriftung, Verwechslung mit den Phasen-Abschlüssen. *Auswirkung:* Bei B entfallen `PathOutlook` und Strichel-Painter, UI-91 und UI-97 ändern sich entsprechend. Empfehlung: A.
2. **Untertitel "Danach geht es weiter".** Alternative: kein Untertitel (nur Titel und Schloss). Auswirkung: ruhiger, aber weniger erklärend. Bis zur Klärung gilt der Untertitel.

## 9. Nicht enthalten

Die volle Phase Prävention & Gesundheitssport (Länge, Inhalte, Wahlmöglichkeiten, Streak-/Freeze-Regeln, Wochenrhythmus, Fachinhalte), jede Freischaltlogik, eigene Manny-Texte oder -Anlässe dafür, Push, Fortschrittsanzeige für diese Phase, eigener Beispiel-Hinweis außer der Kopfzeile, Änderung am Boss oder am Beispielpfad-Generator, Codeänderungen unter `app/` (nicht Teil dieses Pakets).
