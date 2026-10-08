# Design-Brief v1, Ergänzung 2: Manny-Chat und Nachrichten (nur sichtbar, ohne Funktion)

Status: **FREIGEGEBEN (2026-10-07)** · Umsetzung nach Freigabe: `flutter-developer` · Bezug: `docs/design/design-brief-v1.md` (freigegeben 2026-10-07) und `docs/design/design-brief-v1-ergaenzung-1.md` (freigegeben 2026-10-07)
Quellen: Spec 7 (Manny als KI-Chatbot), Spec 8 (Health Social, nur Patientensicht), `docs/plan/ki-plan-v1.md` Abschnitt 11 (KS-1 bis KS-10), Grunddesign K3 (vom Nutzer freigegeben, Varianten 1A, V2 und Nachrichten-Button B).
Orientierungsbilder (kein Pixel-Vorbild, Datum und Wochentage darin sind keine Vorgabe): `docs/design/mockups/pfad-v4.png`, `heute-v4.png`, `manny-chat-v1.png`, `nachrichten-v1.png`, `nachrichten-chat-v1.png`.

**Geltung.** Tokens (Brief v1 3.1 bis 3.6), Komponenten (5, Ergänzung 1 Abschnitt 2), Regeln (Abschnitt 4 Akzent-Rollen, Abschnitt 8) und die Errata E-1/E-2 gelten unverändert. Diese Ergänzung fügt hinzu und ändert **ausdrücklich genannte** Stellen (Abschnitt 1, Tabelle "Änderungen"). **UI-1 bis UI-69 bleiben gültig, außer den dort mit neuem Wortlaut genannten.** Neue Kriterien beginnen bei **UI-70**.

**Umfang dieses Ausschnitts.** Der Manny-Chat ist **erreichbar und sichtbar, Schreiben ist nicht möglich** (die KI folgt im nächsten Ausschnitt). Die Nachrichten-Übersicht und Beispiel-Chats sind **nur ansehbar**. Alle Inhalte sind feste Platzhalter, nichts wird gesendet, gespeichert oder abgerufen.

---

## 1. Konflikte mit den Briefen und ihre Auflösung

| # | Konflikt | Auflösung |
|---|---|---|
| K1 | Brief v1 6.2 / UI-24: Zone unten rechts über der Nav ist für den Chat-Button reserviert, unten links für den Montags-Brief. | Unten rechts steht jetzt die **Button-Gruppe** (Manny-Button, darüber Nachrichten-Button), und sonst nichts. Unten links bleibt frei. UI-24 erhält neuen Wortlaut (Tabelle unten). |
| K2 | Ergänzung 1, 3.5 / UI-59: "Manny selbst nimmt keine Tipps an; ein Tipp auf Manny trifft die Unit darunter". | **Nutzerentscheidung (Grunddesign 1A):** Manny auf dem Pfad ist antippbar und öffnet den Chat. Die Unit darunter bleibt über ihre eigene Fläche tippbar. Satz in 3.5 und UI-59 erhalten neuen Wortlaut. |
| K3 | UI-31 (Heute: letzter Inhalt nicht verdeckt) und der Nachrichten-Button (Variante B) über der Primärbutton-Reihe. | **Scroll-Reserve** von 56 dp (48 dp Button plus 8 dp Abstand) zusätzlich am Ende der Liste. UI-31 erhält neuen Wortlaut. Auf dem Pfad gilt dieselbe Reserve. |
| K4 | Brief v1 6.3: "Training starten" ist ein Primärbutton in voller Breite. | Auf Heute teilt sich der Primärbutton die Reihe mit dem Manny-Button (Breite = Bildschirm minus 32 dp minus 56 dp minus 8 dp). Text, Höhe 56 dp und Stil bleiben. |
| K5 | Snackbar auf Heute (Ergänzung 1, 2): "12 dp über dem Primärbutton" läge jetzt unter dem Nachrichten-Button. | Die Snackbar liegt **12 dp über der Button-Gruppe** (Oberkante Nachrichten-Button) und verdeckt nur Listeninhalt. Nichts der Gruppe wird verdeckt. UI-37 und UI-41 werden präzisiert. |
| K6 | Spec 7: Button "persistent auf allen Screens" gegenüber Onboarding. | Der Manny-Button erscheint **ab Pfad und Heute**, nicht im Onboarding (Einwilligung steht aus, Manny begleitet dort bereits, Spec 1), nicht im Manny-Chat, in den Nachrichten-Screens und unter Sheets und Dialogen. Das ist eine **bewusste Abweichung von Spec 7**, vom Nutzer bestätigt. |
| K7 | Blur-Budget (UI-6, UI-47): höchstens 2 `BackdropFilter`. | Alle neuen Elemente sind **opak** oder Glas ohne Blur. Chat, Nachrichten und Beispiel-Chat haben **0** `BackdropFilter` (keine Nav). Auf Pfad und Heute ändert sich die Zählung nicht (Nav plus Blase oder Sheet). |
| K8 | Akzent-Rollen (Abschnitt 4): Akzent nur für Handlung und Fortschritt. | In den neuen Elementen kommt `accent` nicht vor (Senden ist deaktiviert). Zugehörigkeit von Nachrichten wird nie über Akzent, `status-error`, `cat-frist` oder `tri-*` getragen. Die Pinguin-Zeichnung (Schnabel, Füße `accent-hi`) ist Teil von Manny und gilt nicht als Akzent-Verwendung. |
| K9 | Brief v1 Abschnitt 13 / 6.0: "Manny-Chat und Sprachfunktion (Spec 7), Community und Freunde und Familie (Spec 8)" sind nicht enthalten. | **Teilweise aufgehoben:** Manny-Chat nur als sichtbarer Platzhalter ohne Funktion, Nachrichten-Übersicht und Beispiel-Chats nur ansehbar. Weiterhin nicht enthalten: Sprachfunktion, Community, jede echte Chat-, KI-, Sende- oder Benachrichtigungsfunktion. |
| K10 | Direktnachrichten haben **keine Spec**. Spec 8 führt Chat Patient-Physio ausdrücklich als Out of Scope (Spec 4 listet "In-App Chat mit Physio" als Out of Scope), Familie und Freunde nur als offene Frage ("Form der Unterstützung"), für Ärzte gibt es keine Aussage (Haftung, DSGVO Art. 9 ungeklärt). | Die Nachrichten-Screens sind ein **unverbindlicher Platzhalter**. Sie legen keine Funktion, Kategorie oder Datenstruktur fest und ersetzen keine Spec. Das steht im Code-Kommentar der Screens und im Abschlussbericht. In der App sind sie als "Beispiel" gekennzeichnet (3.3). |
| K11 | Rückgängig-Fenster (UI-39) endet bei Wechsel auf den Pfad, damit freie Zonen unberührt bleiben. | Es endet **auch beim Öffnen von Manny-Chat oder Nachrichten** (neue Route über Heute). Präzisierung in UI-39 (Tabelle unten). |
| K12 | Der KI-Plan (KS-1 bis KS-10) verlangt, dass der Chat später ohne Umbau der Screens ergänzt wird. | Chat-Screen besteht aus zwei gemeinsamen Bausteinen (`ChatMessageList`, `ChatComposer`); die Nachrichten kommen aus Daten, nicht fest im Screen (Abschnitt 2.2 und 6). Die aktive Eingabe wird im KI-Brief KI-D gestaltet, nicht jetzt vorbereitet. |

### Änderungen an freigegebenen Kriterien (neuer Wortlaut ersetzt den alten im Wortlaut)

**Alle sechs sind Nutzerentscheidungen bzw. folgen aus ihnen (Grunddesign vom Nutzer freigegeben 2026-10-07).**

- **UI-24 (neu, ersetzt UI-24):** Unten **links** über der Nav bleibt der Platz für den Montags-Brief frei von Elementen, die Interaktionen oder Inhalte verdecken. Unten **rechts** über der Nav steht ausschließlich die Button-Gruppe aus Manny-Button und Nachrichten-Button (UI-70 bis UI-72), sonst nichts.
- **UI-31 (neu, ersetzt UI-31):** Der letzte Inhalt der Heute-Liste ist auf jedem Gerät vollständig erreichbar. Er wird weder von der Primärbutton-Reihe noch vom Nachrichten-Button noch von der Nav verdeckt (Reserve am Listenende: Höhe der Reihe plus Nav plus 16 dp plus 56 dp), auch bei 320 × 568 dp und 200 % Schrift. Keine Aktion ("Tauschen", "Entfernen", "Eigene Übung") liegt am Scrollende unter einem Button.
- **UI-59 (neu, ersetzt UI-59):** Tipp auf die aktuelle Unit wechselt auf den Tab "Heute"; die Nav zeigt "Heute" aktiv. Tipp auf Manny auf dem Pfad öffnet den Manny-Chat und wechselt **nicht** den Tab. Eine sichtbare Manny-Blase schließt dabei in beiden Fällen.
- **Ergänzung 1, 3.5, letzter Satz des ersten Absatzes (neu):** "Manny nimmt Tipps an und öffnet den Manny-Chat. Die Unit darunter bleibt über ihre eigene Fläche tippbar (siehe 3.2 dieser Ergänzung)."
- **UI-39 (Zusatz am Ende):** "Auch das Öffnen des Manny-Chats oder der Nachrichten beendet das Fenster."
- **UI-37 und UI-41 (Präzisierung "direkt über dem Button"):** Die Snackbar steht 12 dp über der Button-Gruppe (Oberkante des Nachrichten-Buttons), verdeckt weder Nav noch Primärbutton-Reihe noch Button-Gruppe.
- **UI-63 (letzter Satz neu):** "Die Zone unten links (UI-24) ist weiterhin frei; unten rechts steht nur die Button-Gruppe. Auf dem Pfad erscheint keine Snackbar."
- **K6 (Änderung vom 2026-10-08, Nutzer freigegeben; Anlass Abnahme A-U3, Befund B2):** Die Hinweiskarte (`ExampleNotice`) im Manny-Chat, in den Nachrichten und im Beispiel-Chat ist nur bei normaler Schrift und ausreichender Höhe fest. **Sie wandert als erstes Element in die Liste (scrollt mit), sobald die Textskalierung mindestens 1,5 beträgt ODER die verfügbare Höhe unter 400 dp liegt.** Begründung der Schwelle: Bei 320 × 568 dp und 200 % (Kopf 143 dp, Karte 131 dp, Leiste 110 dp) blieben nur ca. 150 dp, im Querformat (Höhe 320 dp) nur ca. 55 dp für den Verlauf, sodass beim Öffnen keine Nachricht sichtbar war. Bei 400 dp Höhe und mehr (alle Hochformat-Telefone ab 568 dp, auch mit Tastatur außerhalb dieser Regel) bleibt die Karte fest. "Verfügbare Höhe" ist die Höhe der Route ohne Systemleisten und ohne Tastatur. Die frühere Fassung ("fest, scrollt nicht weg", 3.2 und 3.4) bleibt zur Nachvollziehbarkeit stehen und gilt nicht mehr. Betroffen: 2.2 (letzter Punkt), 3.2, 3.3, 3.4, UI-76, UI-80, UI-88 (Wortlaut unten in Abschnitt 6).
- **Brief v1 Abschnitt 13 (Nicht enthalten):** Der Eintrag "Manny-Chat und Sprachfunktion (Spec 7), Community und Freunde und Familie (Spec 8)" wird laut K9 teilweise aufgehoben.

---

## 2. Bausteine

Alle mit vorhandenen Tokens. **Keine neuen Tokens.** Neue Widgets sind unten markiert, vorhandene werden wiederverwendet.

| Baustein | Zweck und Aufbau |
|---|---|
| `MannyChatButton` (neu) | Kreis **56 dp** (Hit-Area 56), `surface-opaque`, Rand 1,5 dp `border-control` (Hoher Kontrast: `border-control-hc`), Schatten 0/6/16 dp Schwarz 40 %, **kein Blur, kein Glow, kein Akzent-Ring**. Inhalt: Manny-Kopf (Pose neutral, ca. 38 dp, aus `MannyPlaceholder`, nicht doppelt gezeichnet). Pressed: Überlagerung Weiß 10 %. Fokus: `focus-ring`. Tooltip und Screenreader "Manny, Chat öffnen". |
| `MessagesButton` (neu) | Kreis **48 dp**, sonst wie `MannyChatButton`. Icon `chat_bubble_outline_rounded` 24 dp `text-1` (14,23:1 auf `surface-opaque`). Tooltip und Screenreader "Nachrichten". |
| `ActionCluster` (neu) | Anordnung der beiden Buttons. **Pfad:** rechts 16 dp Seitenrand, Manny-Button 16 dp über der Nav, Nachrichten-Button **rechtsbündig** 8 dp darüber. **Heute:** der Manny-Button sitzt in der Reihe von "Training starten" (8 dp Abstand, unten bündig), der Nachrichten-Button rechtsbündig 8 dp über dem Manny-Button. Beide Buttons liegen über dem Inhalt (Inhalt scrollt darunter), unter jedem Scrim. Mockup `heute-v4.png` zeigt ca. 16 dp Abstand statt 8 dp, maßgeblich sind 8 dp. |
| Primärbutton-Reihe Heute (geändert) | `PillButton` Primär, Breite = Bildschirm minus 32 dp minus 56 dp minus 8 dp, Höhe 56 dp (wächst bei Umbruch), danach `MannyChatButton`. Zustände Training starten, Heute erledigt, deaktiviert unverändert. |
| `ChatScreenScaffold` (neu) | Vollbild-Route ohne Nav: Statusleiste, Kopf (opak `bg`, 1 dp `border-hair` unten), Inhalt, optional fester Fuß. Wiederverwendet für Manny-Chat, Nachrichten und Beispiel-Chat. Kein `BackdropFilter`. |
| `ChatHeader` (neu) | Zurück-Pfeil (`HeaderIconButton`-Stil, 48 dp), Avatar oder Manny-Emblem 32 bis 36 dp, Titel (`heading`, 18/24), Untertitel (`secondary` 13 sp `text-2`). |
| `ChatMessageList` (neu, **gemeinsamer Baustein**) | Stellt eine Liste von Nachrichten dar (Autor: Nutzer, Manny, Hinweis; Art: Text, Eskalation, Disclaimer, Blase; Status: sendend, streamend, fertig, abgebrochen, fehlgeschlagen). Stellt Manny-Text ohne Blase dar, Nutzer-Text in einer Blase (2.2). Kann eine **letzte Nachricht darstellen, deren Text wächst** (kein Abschneiden, keine Überlagerung; folgt dem Ende, solange der Nutzer am Ende steht, und springt nicht, wenn er hochgescrollt hat). Status außer "fertig" werden in diesem Ausschnitt nicht eigens gestaltet und wie "fertig" dargestellt (Gestaltung folgt im KI-Brief). |
| `ChatComposer` (neu, **gemeinsamer Baustein**) | Eingabeleiste mit Zustand **deaktiviert + Hinweis** (2.2). Wird vom Manny-Chat und vom Beispiel-Chat verwendet. Es gibt in diesem Ausschnitt **nur** den deaktivierten Zustand. Der aktive Zustand folgt in KI-D. |
| `ContactRow` (neu) | Zeile der Nachrichten-Übersicht (3.3). |
| `ExampleNotice` (neu, auf `GlassCard`) | Hinweiskarte "Beispiel" (E1-Glas, Radius 16, Innenabstand 10/14, Info-Icon 20 dp `text-2`, Text `secondary`). Dauerhaft sichtbar, nicht ausblendbar. |
| `ChatBubble` Mensch (neu) | Blase im Beispiel-Chat: du rechts (`surface-opaque`, Rand `border-hair`), Gegenüber links (Glas E1 ohne Blur). Radius 20, Ecke zur Absenderseite 6 dp, höchstens 80 % Breite, Innenabstand 12/16, `body`, `text-1`. |
| Wiederverwendet | `GlassCard`, `HeaderIconButton`, `CuraSnackbar`, `NodeHint`, `MannyPlaceholder`, `MannyBubble`, `FloatingNav`, `PillButton`. |

### 2.1 Gemeinsame Regeln der neuen Screens

- Vollbild-Routen **ohne** Nav, ohne Manny- und Nachrichten-Button. Sie öffnen mit Einblenden plus 24 dp Schiebung von rechts (`dur-base`, `curve`).
- Zurück, Android-Zurück und Escape schließen die Route. Der Fokus geht an das auslösende Element zurück (Button, Zeile oder Manny-Zone). Anfangsfokus beim Öffnen: auf dem Zurück-Pfeil, Screenreader liest zuerst den Titel.
- Hintergrund `bg` mit dem Glow wie auf den anderen Screens (Errata E-1 gilt, siehe Abschnitt 4). Mockups zeigen den Glow.
- Alle sichtbaren Texte in `strings_de.dart` (Konvention 4), alle Farben, Abstände, Radien, Schriften aus `lib/theme/` (Konvention 1), kein `BackdropFilter` (Konvention 2).

### 2.2 `ChatMessageList` und `ChatComposer` im Einzelnen

**Nachrichten:**
- **Manny:** Text `body` (16/24) `text-1` direkt auf `bg`, linksbündig, **ohne Blase**. Vor jedem Manny-Block (aufeinanderfolgende Manny-Nachrichten bilden einen Block) steht das Manny-Emblem 26 dp, der Text beginnt 36 dp vom Rand. Zeilenlänge höchstens 560 dp. (Mockup `manny-chat-v1.png` zeigt das Emblem nur beim ersten Block; maßgeblich ist diese Regel.)
- **Nutzer:** Blase rechts, `surface-opaque`, Rand `border-hair`, Radius 20, untere rechte Ecke 6 dp, höchstens 80 % Breite, Innenabstand 12/16, `body` `text-1`.
- **Hinweis (Autor "Hinweis"):** wie `ExampleNotice`, mittig, volle Breite. (Im ersten Ausschnitt nicht in der Liste verwendet, der Beispiel-Hinweis ist fester Teil des Screens.)
- Abstand zwischen Nachrichten 20 dp, zwischen Blöcken gleichen Autors 8 dp. Seitenrand 16 dp.
- Die Liste beginnt oben. Ist der Inhalt länger als der Bereich, steht beim Öffnen das Ende sichtbar.

**Eingabeleiste (`ChatComposer`):**
- Pill, Radius 28, mindestens 56 dp hoch, 16 dp Seitenrand, Füllung `surface-opaque`, Rand 1 dp `border-hair`.
- **Zustand deaktiviert (einziger erreichbarer Zustand):** Platzhaltertext "Schreib Manny" (`body`, `text-2`), rechts Senden-Kreis 40 dp (Hit-Area 48 dp) mit Pfeil-nach-oben-Icon `text-3` auf Weiß 10 %. Antippen öffnet **keine Tastatur** und tut nichts. Fokus erreicht die Leiste nicht, Screenreader liest sie vor. Direkt **über** der Leiste steht dauerhaft sichtbar (nicht nur als Platzhalter) die Hinweiszeile: Info-Icon 18 dp plus Text (`secondary` 14 sp, `text-1`).
- **Zustand aktiv:** folgt in KI-D (Brief des KI-Ausschnitts). Er wird in diesem Ausschnitt weder gestaltet noch vorbereitet.
- Im ersten Ausschnitt gibt es keinen Wert "darf senden" und keine Umschaltung; die Leiste ist fest deaktiviert.
- **Disclaimer** (nur im Manny-Chat): unter der Leiste, mittig, `caption` (13 sp) `text-3` (7,24:1 auf `bg`), dauerhaft sichtbar: "Manny ersetzt keine medizinische Beratung."
- Der feste Fußbereich (Hinweiszeile, Leiste, Disclaimer) belegt höchstens 40 % der Bildschirmhöhe. Würde er bei großer Schrift mehr brauchen, scrollen Hinweiszeile und Disclaimer ab Skalierung 1,5 am Ende des Verlaufs mit (der Disclaimer bleibt am Ende der Liste erreichbar und die Leiste bleibt unten fest). **K6:** Unter denselben Bedingungen (Skalierung ab 1,5 oder verfügbare Höhe unter 400 dp) scrollt auch die Hinweiskarte des Screens mit; Hinweiszeile und Disclaimer wandern bei Höhe unter 400 dp ebenfalls ans Listenende.

---

## 3. Screens im Einzelnen

### 3.1 Einstieg: Button-Gruppe und Manny auf dem Pfad

**Wo sichtbar:** Tab "Pfad" und Tab "Heute". **Nicht** sichtbar: Onboarding, Manny-Chat, Nachrichten, Beispiel-Chat, und nicht bedienbar unter Sheets und Dialogen (Scrim darüber, Buttons aus der Semantik und Fokusreihenfolge entfernt, solange modal).

**Pfad:** Gruppe schwebt über dem Pfad (Pfad scrollt darunter). Der Pfad hat unten eine Scroll-Reserve von Nav plus 16 dp plus 56 dp plus 8 dp plus 48 dp plus 16 dp, damit auch die unterste Unit über die Gruppe geschoben werden kann. Unten links bleibt frei.

**Heute:** Siehe Bausteine, K3, K4, K5. Der Nachrichten-Button liegt auf der Liste rechts über der Reihe, die Liste hat am Ende 56 dp Reserve (UI-31). Scrollt der Inhalt mittendrin unter den Button, ist das zulässig (er ist wegscrollbar), am Ende nicht.

**Manny auf dem Pfad (Variante 1A):**
- Tipp auf Manny öffnet den Manny-Chat. Hit-Fläche: gezeichnete Manny-Form plus 8 dp Rand, mindestens 48 × 48 dp, **endet an der Standlinie** (Unterkante der Füße). Die Unit reagiert nur außerhalb dieser Fläche (Tipp auf Unit unverändert nach 3.5 der Ergänzung 1: aktuell → Heute).
- Das ist ein **zusätzlicher Weg**: Manny bekommt keine eigene Fokusstation und keinen eigenen Eintrag für Tastatur, Switch oder Screenreader (der Manny-Button übernimmt). Das Bild-Label bleibt "Manny, dein Begleiter" (nicht doppelt zur Blase).
- Pressed: Manny-Form kurz Weiß 10 % heller. Keine Animation, keine Pose-Änderung.
- Tipp auf Manny bei sichtbarer Blase: Blase schließt, Chat öffnet. Die Blase erscheint danach nicht erneut (der Anlass zählt als gezeigt).
- Auf anderen Screens ist Manny nicht tippbar (Onboarding-Manny, Blasen).

**Wechselwirkung mit anderen Pfad-Elementen:**
- `MannyBubble`: Wenn die Blase (rechts neben Manny, 5.6) weniger als 8 dp über dem Nachrichten-Button enden würde, erscheint sie wie in 5.6 für schmale Displays **über Manny**. Sie überdeckt die Button-Gruppe nie.
- `NodeHint`: Er wird so gesetzt, dass er die Button-Gruppe nicht überdeckt (Ausweichen nach oben oder links, Pfeil bleibt an der Unit). Er schließt zusätzlich beim Öffnen von Chat oder Nachrichten.
- "Deine Daten"-Sheet: Gruppe liegt unter dem Scrim, wird nicht gelesen und nicht fokussiert.
- Tageswechsel (Ergänzung 1, 3.4): Wird er bei offenem Chat erkannt, zeigt Heute beim Zurückkehren das neue Datum **ohne** die Snackbar "Neuer Tag, neues Programm." (Heute war nicht sichtbar).

### 3.2 Manny-Chat (Vollbild-Route, Orientierung: `manny-chat-v1.png`)

**Aufbau von oben nach unten:**
1. `ChatHeader`: Zurück, Manny-Emblem 34 dp, Titel "Manny" (`heading`), Untertitel "Dein Reha-Begleiter". Kein "Neuer Chat", kein Mikrofon, kein Menü.
2. `ExampleNotice` (fest unter dem Kopf; **geändert durch K6:** scrollt nur bei Textskalierung ab 1,5 oder verfügbarer Höhe unter 400 dp als erstes Listenelement mit, sonst nicht): Label "BEISPIELVERLAUF" (`label`, `text-1`; Großbuchstaben nur im Stil, Text "Beispielverlauf") und `secondary`: "So sieht dein Chat bald aus."
3. `ChatMessageList` mit dem **Beispielverlauf** (feste Platzhalter, nicht gespeichert, "Jakob" ist der Name aus dem Onboarding):
   - Manny: "Moin Jakob. Wie läuft dein Tag?"
   - Nutzer: "Ich hab heute keine Zeit."
   - Manny: "Dann machen wir die 10-Minuten-Variante. Das schaffst du. Sag mir kurz Bescheid, wenn du durch bist."
   Die Texte sind bewusst nicht medizinisch (Spec 7 Themenbeispiel "Tagesplanung").
4. Fest unten: Hinweiszeile "Schreiben kann ich bald, heute noch nicht." (gleiche Wortwahl wie der Mikrofon-Hinweis im Onboarding), `ChatComposer` (deaktiviert), Disclaimer.

**Zustände dieses Ausschnitts:** Standard (oben). Laden, Fehler, Offline, Leer entfallen (rein lokal, fester Inhalt). Streaming, Senden, Abbrechen, Wiederholen, Eskalationskarte, Limit, Einwilligung gehören zum KI-Brief. Es gibt keinen Verlauf, der gelöscht werden könnte (der Beispielverlauf wird nicht gespeichert).

**Screenreader:** Route "Manny, Chat". Die Hinweiskarte wird zuerst gelesen. Nachrichten: "Manny: …" bzw. "Du: …". Hinweiszeile und Disclaimer werden vorgelesen. Leiste: "Nachricht an Manny, noch nicht verfügbar", Senden-Kreis: "Senden, noch nicht verfügbar".

### 3.3 Nachrichten (Vollbild-Route, Orientierung: `nachrichten-v1.png`)

**Einstieg:** Nachrichten-Button. Kopf: Zurück, Titel "Nachrichten" (`title`). Darunter `ExampleNotice`: "Beispiel-Ansicht. Echte Chats folgen." (fest; ab Textskalierung 1,5 **oder bei verfügbarer Höhe unter 400 dp (K6)** scrollt sie als erstes Element der Liste mit).

**Liste in vier Abschnitten** mit `label`-Überschriften (Screenreader: Überschrift): PHYSIO, FAMILIE, FREUNDE, ÄRZTE (Text "Physio", "Familie", "Freunde", "Ärzte"). Gruppierung statt Filter. Keine Suche, kein "Neuer Chat", kein Ungelesen-Badge, keine Zähler.

**Zeile (`ContactRow`):** mindestens 72 dp hoch, ganze Zeile antippbar, `focus-ring`, Pressed Weiß 10 %.
- Avatar 48 dp mit Initialen (`heading`-Größe 17), Füllung `surface-opaque`, Rand 2 dp: Physio `cat-physio`, Ärzte `cat-arzt`, Familie und Freunde Weiß 30 % (neutral). Die Kategorie steht zusätzlich als Text (Abschnittsüberschrift und Screenreader), Farbe ist nie das einzige Signal.
- Name `body-strong`, darunter die letzte Nachricht (`secondary`, `text-2`, **bricht um**, wird nicht abgeschnitten), rechts Zeitangabe (`caption`, `text-3`), Platzhalterwerte ("Mo", "Di" …).
- Screenreader: "Beispielkontakt Praxis Müller, Physio. Letzte Nachricht: …, Montag. Öffnet Beispiel-Chat."

**Beispielkontakte (erfunden, alle Texte sind Platzhalter, Vorschau = letzte Nachricht des jeweiligen Beispiel-Chats):**

| Abschnitt | Kontakt (Initialen) | Beispiel-Chat (Reihenfolge, "Du" = Nutzer) | Zeit |
|---|---|---|---|
| Physio | Praxis Müller (PM) | Praxis: "Moin Jakob, dein Termin ist am Donnerstag um 17:00 Uhr." · Du: "Perfekt, ich bin pünktlich da." · Praxis: "Bring bitte Sportschuhe mit." | Mo |
| Familie | Mama (M) | Du: "Heute Training geschafft." · Mama: "Schön, dass du dranbleibst!" | Di |
| Familie | Tim (Bruder) (T) | Du: "Samstag habe ich noch nichts vor." · Tim: "Soll ich dich am Samstag abholen?" | So |
| Freunde | Lena (L) | Du: "Bin zu Hause." · Lena: "Wie lief dein Tag?" | Sa |
| Freunde | Basti (B) | Du: "Bin bald wieder fit." · Basti: "Kaffee, wenn du wieder darfst?" | Fr |
| Ärzte | Dr. Weber, Orthopädie (DW) | Du: "Ich möchte den Termin gern bestätigen." · Dr. Weber: "Termin am 14. um 9:30 bestätigt." | Do |

Inhalte sind rein organisatorisch, **keine** Reha- oder Medizinaussagen von Menschen. Die Trennbezeichnung "Du" im Chat dient nur der Beschreibung hier.

### 3.4 Beispiel-Chat (Vollbild-Route, Orientierung: `nachrichten-chat-v1.png`)

- Kopf: Zurück, Avatar 36 dp, Name (`heading`), Untertitel Rolle plus "Beispiel" (z. B. "Physio · Beispiel", "Familie · Beispiel").
- `ExampleNotice`: "Beispiel-Chat. Nur zum Ansehen." (fest; **K6:** ab Textskalierung 1,5 oder bei verfügbarer Höhe unter 400 dp scrollt sie als erstes Listenelement mit).
- Verlauf aus `ChatBubble` Mensch (3.3, Tabelle): eigene Nachrichten rechts, Gegenüber links, optional eine Tagesüberschrift (`label`, mittig, z. B. "Montag", Platzhalter). Zugehörigkeit ist über Ausrichtung **und** Screenreader-Präfix ("Du:", Name) erkennbar, nie über Farbe allein. Der Chat sieht bewusst anders aus als der Manny-Chat (Blasen beidseitig gegenüber Manny-Text ohne Blase), damit KI und Mensch nicht verwechselt werden.
- Fest unten: Hinweiszeile "Schreiben in Chats folgt bald.", `ChatComposer` deaktiviert (Platzhalter "Nachricht"). **Kein** Disclaimer (der Hinweis zu Manny gehört nur in den Manny-Chat).
- Zurück führt in die Übersicht, von dort Zurück auf den Tab (Pfad oder Heute), von dem aus geöffnet wurde.

### 3.5 Texte (alle Deutsch, "du", Ton der Spec; Ablage `strings_de.dart`)

| Ort | Text |
|---|---|
| Manny-Button (Tooltip, Semantik) | "Manny, Chat öffnen" |
| Nachrichten-Button (Tooltip, Semantik) | "Nachrichten" |
| Manny-Chat Titel / Untertitel | "Manny" / "Dein Reha-Begleiter" |
| Beispiel-Hinweis Manny-Chat | "Beispielverlauf" / "So sieht dein Chat bald aus." |
| Beispielverlauf | siehe 3.2 |
| Hinweiszeile Manny-Chat | "Schreiben kann ich bald, heute noch nicht." |
| Platzhalter Manny-Eingabe | "Schreib Manny" |
| Disclaimer (wörtlich Spec 7) | "Manny ersetzt keine medizinische Beratung." |
| Semantik Leiste / Senden (deaktiviert) | "Nachricht an Manny, noch nicht verfügbar" / "Senden, noch nicht verfügbar" |
| Nachrichten Titel / Hinweis | "Nachrichten" / "Beispiel-Ansicht. Echte Chats folgen." |
| Abschnitte | "Physio", "Familie", "Freunde", "Ärzte" |
| Beispiel-Chat Hinweis | "Beispiel-Chat. Nur zum Ansehen." |
| Hinweiszeile / Platzhalter Beispiel-Chat | "Schreiben in Chats folgt bald." / "Nachricht" |
| Rolle im Kopf | "Physio · Beispiel", "Familie · Beispiel", "Freunde · Beispiel", "Arzt · Beispiel" |
| Semantik Kontaktzeile | "Beispielkontakt [Name], [Abschnitt]. Letzte Nachricht: [Text], [Tag]. Öffnet Beispiel-Chat." |

---

## 4. Querschnitt für alle neuen Elemente

- **Reduzierte Bewegung:** Routenwechsel ohne Schiebung, höchstens 120 ms Einblenden oder sofort. Keine weitere Animation (Buttons erscheinen und verschwinden ohne Übergang).
- **Hoher Kontrast:** Buttons, Hinweiskarten, Eingabeleiste, Blasen, Avatare werden `surface-opaque` mit `border-control-hc`, Glas wird opak, Glow aus, Schatten der Buttons bleiben. Kein Blur.
- **200 % Schrift:** Alle Texte brechen um, nichts wird abgeschnitten. Manny-Button (56 dp) und Nachrichten-Button (48 dp) bleiben in dp fix (enthalten keinen Text). Auf Heute wächst "Training starten" in die Höhe (Textumbruch), der Manny-Button bleibt unten bündig, die Scroll-Reserve folgt der Reihenhöhe. Kontaktzeilen wachsen. Fester Chat-Fuß: Regel in 2.2 (40 %, ab 1,5 scrollt der Hinweis mit). Nav-Labels weiter ab 130 % begrenzt (5.4).
- **320 × 568 dp:** Primärbutton-Breite 224 dp ("Training starten" bricht notfalls um), Button-Gruppe vollständig sichtbar und nicht über der Nav, Pfad-Kopfzeile unverändert (Ergänzung 1, 3.1), Chat: Kopf, Hinweiskarte, Verlauf scrollbar, Fuß vollständig sichtbar, kein horizontales Scrollen, Nachrichten-Liste scrollt.
- **Blur-Budget:** Pfad und Heute: Nav plus entweder Blase oder Sheet (unverändert). Buttons, Hinweiskarten, Zeilen, Blasen, Eingabeleiste ohne `BackdropFilter`. Chat, Nachrichten, Beispiel-Chat: 0.
- **Glow (Errata E-1):** Text direkt auf `bg` höchstens 24 % Glow-Alpha, `text-1/2/3` auf Glas höchstens 16 %, farbiger Text und `accent-hi` auf Glas höchstens 12 %. Nachgerechnet für die Hinweiskarte (Text bei ca. 89 dp Abstand zum Glow-Mittelpunkt, Alpha unter 12 %) und die erste Blase (praktisch 0 %). Die Chat-Screens verwenden **keinen** `accent-hi`-Text auf Glas.
- **Akzent-Rollen:** siehe K8. `status-error`, `cat-frist`, `tri-*` kommen in den neuen Elementen nicht vor.
- **Fokus und Tastatur:** Fokusreihenfolge visuell (oben nach unten, links nach rechts): Pfad: Kopf (Text, Freeze, Streak, "Deine Daten"), Units, Nachrichten-Button, Manny-Button, Nav. Heute: Kopf, Zeitwahl, Karten und deren Aktionen, "Eigene Übung", Nachrichten-Button, "Training starten", Manny-Button, Nav. Chat: Zurück, Verlauf (lesend). Nachrichten: Zurück, Zeilen in Reihenfolge. Sichtbarer `focus-ring` (2 dp, Abstand 2 dp, `text-1`) um die Kreise, Enter und Leertaste lösen aus.
- **Semantik:** Neue Routen haben Namen ("Manny, Chat", "Nachrichten", "Beispiel-Chat [Name]"). Dekorative Elemente (Glow, Avatare als Bild, Linien) sind ausgeblendet. Abschnittsüberschriften sind Überschriften.
- **Texte:** Deutsch, "du", kurz, direkt, nie klinisch.

---

## 5. Technische Hinweise (Orientierung, Technik plant der `flutter-developer`)

Betroffen sind (künftige) Dateien: Pfad- und Heute-Seite (Button-Gruppe, Reihe, Scroll-Reserve, Manny-Tipp), `FloatingNav`-Umgebung (Gruppe oberhalb), neue Screens für Manny-Chat, Nachrichten und Beispiel-Chat, `strings_de.dart`, ggf. `chat_model` und `ChatRepository`. Das Repo enthält dazu noch keinen Flutter-Code. Keine neuen Abhängigkeiten, kein Netzwerk.

**Abgleich mit den Schnittstellen-Empfehlungen des KI-Plans (vom Nutzer für den ersten Ausschnitt übernommen):**

| KS | Was der Brief sichtbar oder prüfbar verlangt |
|---|---|
| KS-1, KS-2, KS-3 | Blasen und Fakten kommen aus einer austauschbaren Quelle (Platzhalter-Quelle, Fakten mit ID plus Text), der Kontext (Name, Verletzung, Woche, Streak …) ist eine reine Dart-Klasse. **Sichtbar ändert sich nichts**: Blasentexte und Anlässe bleiben wie in Brief v1 6.2. Kein neues UI-Kriterium. |
| KS-4 | Der Beispielverlauf besteht aus Nachrichten mit Autor (Nutzer, Manny, Hinweis), Art und Status, nicht aus fest verdrahteten Widgets (UI-76). |
| KS-5 | Nicht Teil dieses Ausschnitts: Es gibt kein Chat-Repository und keinen Wert "darf senden" (kommt mit KI-D). Die Leiste ist fest deaktiviert (UI-77). |
| KS-6 | `ChatMessageList` und `ChatComposer` sind eigene, gemeinsame Widgets (2.2). Die Liste verkraftet eine wachsende letzte Nachricht (UI-76). |
| KS-7 | Der erste Ausschnitt **speichert zum Chat nichts** (feste Beispielnachrichten). Ein eigener Speicherschlüssel entfällt, bis es etwas zu speichern gibt. Sichtbare Folge: "Alles löschen" lässt keinen Chat-Rest zurück (UI-82). |
| KS-8 | Alle Chat-Texte inklusive Disclaimer und Hinweiszeile liegen in `strings_de.dart` (3.5, UI-81). |
| KS-9 | "Alles löschen" (Ergänzung 1) soll künftig weitere Löscher kennen. Sichtbares Verhalten unverändert (UI-82). |
| KS-10 | Die Nachrichten-Platzhalter teilen **kein Datenmodell** mit dem Manny-Chat. Geteilt wird nur reine Darstellung (`ChatComposer`, `ChatScreenScaffold`, ggf. Listengerüst). Die Beispielkontakte sind eigene feste Daten (UI-83). |

Weitere Hinweise: Die Button-Gruppe liegt in einer eigenen Ebene (Overlay oder Stack) oberhalb des Inhalts und unterhalb von Sheets und Dialogen. Die Scroll-Reserve ergibt sich aus gemessenen Höhen (Reihe, Nav), nicht aus festen Pixelwerten. Für den Manny-Tipp ein eigener Hit-Bereich im Pfad (kein `GestureDetector` über der ganzen Unit). Die Kommentare der Nachrichten-Screens vermerken "unverbindlicher Platzhalter, keine Spec" (K10).

---

## 6. UI-Akzeptanzkriterien (ab UI-70)

**Einstieg und Button-Gruppe**
- UI-70: Auf Pfad und Heute steht unten rechts über der Nav der Manny-Button (Kreis 56 dp, `surface-opaque`, Rand `border-control`, Manny-Kopf) mit Tooltip und Screenreader "Manny, Chat öffnen". Er öffnet den Manny-Chat. Im Onboarding, im Manny-Chat, in den Nachrichten-Screens und unter Sheets und Dialogen ist er nicht sichtbar bzw. nicht bedienbar.
- UI-71: Direkt über dem Manny-Button (8 dp, rechtsbündig) steht der Nachrichten-Button (Kreis 48 dp, Icon Sprechblase) mit Tooltip und Screenreader "Nachrichten". Er öffnet die Nachrichten-Übersicht. Seine Sichtbarkeit entspricht UI-70.
- UI-72: Beide Buttons haben Hit-Area ≥ 48 dp, sichtbaren `focus-ring`, sind mit Enter und Leertaste auslösbar, haben Pressed-Zustand und enthalten weder Blur noch Glow noch Akzentfarbe (Code-Suche). Hoher Kontrast: Rand `border-control-hc`.
- UI-73: Auf Heute teilen sich "Training starten" (Breite Bildschirm minus 96 dp) und der Manny-Button eine Reihe, beide unten bündig (Höhe 56 dp, bei Textumbruch wächst nur der Primärbutton). Zustände "Heute erledigt", deaktiviert und die Snackbar (12 dp über der Button-Gruppe) verhalten sich wie in Ergänzung 1 und Brief v1.
- UI-74: Tipp auf Manny (Form plus 8 dp) auf dem Pfad öffnet den Manny-Chat und wechselt nicht den Tab. Tipp auf die Unit außerhalb der Manny-Fläche wirkt wie bisher (aktuelle Unit: Heute, gesperrt/erledigt: `NodeHint`). Eine sichtbare Blase schließt bei beidem und erscheint nicht erneut. Manny hat keinen eigenen Fokusstopp, der Manny-Button ist der Tastatur- und Screenreader-Weg.
- UI-75: Die Blase und der `NodeHint` überdecken die Button-Gruppe nie (Blase wechselt über Manny, Hinweis weicht aus). Der Pfad hat unten Scroll-Reserve, sodass die unterste Unit über die Gruppe geschoben werden kann.

**Manny-Chat**
- UI-76: Der Manny-Chat zeigt Kopf (Zurück, Manny-Emblem, "Manny", "Dein Reha-Begleiter"), eine Karte "Beispielverlauf / So sieht dein Chat bald aus." (fest; **K6 (ersetzt "feste Karte"):** ab Textskalierung 1,5 oder bei verfügbarer Höhe unter 400 dp erstes Element der scrollenden Liste, dann steht beim Öffnen der Beispielverlauf sichtbar unter dem Kopf) und den Beispielverlauf (3.2). Manny-Nachrichten stehen ohne Blase auf `bg` (Emblem je Manny-Block), Nutzer-Nachrichten in einer Blase rechts (`surface-opaque`, Rand `border-hair`, höchstens 80 % Breite). Die Nachrichten werden aus Datenobjekten (Autor, Art, Status) durch `ChatMessageList` gerendert; ein Widget-Test mit einer letzten Nachricht, deren Text wächst, zeigt: nichts wird abgeschnitten oder überlagert, am Ende folgt die Liste dem Text, nach Hochscrollen springt sie nicht.
- UI-77: Unten stehen die Hinweiszeile "Schreiben kann ich bald, heute noch nicht.", die deaktivierte Eingabeleiste "Schreib Manny" mit deaktiviertem Senden-Kreis und der Disclaimer "Manny ersetzt keine medizinische Beratung." Tipp auf die Leiste öffnet keine Tastatur und löst nichts aus. Hinweiszeile und Disclaimer sind dauerhaft sichtbar, nicht nur als Platzhalter.
- UI-78: Im Manny-Chat gibt es kein Mikrofon, keinen "Neuer Chat"-Eintrag, kein Menü, keine Vorschlags-Chips und kein `accent` (Code-Suche und Screenshot).

**Nachrichten**
- UI-79: Die Nachrichten-Übersicht zeigt Kopf "Nachrichten", die feste Karte "Beispiel-Ansicht. Echte Chats folgen." und vier Abschnitte (Physio, Familie, Freunde, Ärzte) mit den Beispielkontakten aus 3.3. Jede Zeile hat Avatar (Ringfarbe Physio `cat-physio`, Ärzte `cat-arzt`, sonst neutral), Name, umbrechende letzte Nachricht und Zeitangabe, Hit-Area die ganze Zeile (≥ 72 dp), `focus-ring`. Es gibt weder Badge noch Suche noch Neuer-Chat-Aktion.
- UI-80: Tipp auf eine Zeile öffnet den Beispiel-Chat des Kontakts: Kopf mit Avatar, Name und "[Rolle] · Beispiel", Karte "Beispiel-Chat. Nur zum Ansehen." (Lage wie in UI-76, K6), Verlauf aus Blasen (eigene rechts `surface-opaque`, Gegenüber links Glas ohne Blur), Hinweiszeile "Schreiben in Chats folgt bald." und deaktivierte Leiste ohne Disclaimer. Zugehörigkeit ist auch per Screenreader erkennbar ("Du:", Name). Zurück führt in die Übersicht, danach auf den Tab, von dem aus geöffnet wurde.

**Texte, Löschen, Entkopplung**
- UI-81: Alle neuen sichtbaren Texte (3.5) und Semantik-Labels liegen in `strings_de.dart`, sind Deutsch, in "du"-Form. Der Disclaimer steht wörtlich wie in Spec 7. Farben, Abstände und Schriften nur aus `lib/theme/`.
- UI-82: Der Chat und die Nachrichten speichern nichts. Nach "Alles löschen" (Ergänzung 1) und anschließendem Onboarding sind die Beispielinhalte unverändert, und es bleibt kein Chat-Zustand außerhalb der Ausgangswerte zurück.
- UI-83: Der Nachrichten-Platzhalter nutzt kein Datenmodell des Manny-Chats. Gemeinsam sind nur Darstellungs-Widgets (`ChatComposer`, `ChatScreenScaffold`). Die Beispielkontakte liegen als eigene feste Daten vor (Code-Review).
- UI-84: Der Code der Nachrichten-Screens vermerkt als Kommentar, dass sie ein unverbindlicher Platzhalter ohne Spec sind, und die Screens kennzeichnen sich in der App als "Beispiel" (UI-79, UI-80).

**Querschnitt**
- UI-85: Die neuen Screens enthalten keinen `BackdropFilter`. Auf Pfad und Heute sind höchstens 2 `BackdropFilter` sichtbar (Nav plus Blase oder Sheet), auch mit Button-Gruppe und Snackbar (erweitert UI-6/UI-47).
- UI-86: Öffnen und Schließen der neuen Routen: Fokus kehrt zum auslösenden Element zurück, Zurück, Android-Zurück und Escape schließen. Mit "Bewegung reduzieren" keine Schiebung und höchstens 120 ms Einblenden. Das Rückgängig-Fenster endet beim Öffnen von Chat oder Nachrichten (UI-39).
- UI-87: Bei "Hoher Kontrast" sind Buttons, Karten, Eingabeleiste, Blasen und Avatare opak (`surface-opaque`) mit `border-control-hc`, ohne Blur und Glow. Der Glow genügt auf den neuen Screens Errata E-1 (Alpha-Prüfung wie UI-7).
- UI-88: Bei 200 % Systemschrift und bei 320 × 568 dp sind Manny-Chat, Nachrichten und Beispiel-Chat vollständig erreichbar: nichts abgeschnitten oder überlagert, kein horizontales Scrollen, Eingabeleiste und Disclaimer erreichbar (Chat-Fuß höchstens 40 % der Höhe, ab Skalierung 1,5 scrollt der Hinweis mit; **K6:** ab Skalierung 1,5 oder bei verfügbarer Höhe unter 400 dp scrollt auch die Hinweiskarte mit, und beim Öffnen ist mindestens die erste Nachricht des Verlaufs sichtbar, zu prüfen bei 320 × 568 dp mit 200 % und bei 568 × 320 dp). Auf Heute und Pfad sind beide Buttons vollständig sichtbar, und am Listenende ist nichts verdeckt (UI-31 neu).
- UI-89: Alle neuen Elemente sind per TalkBack/VoiceOver und Tastatur bedienbar, mit den Labels aus 3.5 und der Fokusreihenfolge aus Abschnitt 4.

---

## 7. Annahmen

1. Chat, Nachrichten und Beispiel-Chat sind Vollbild-Routen ohne Nav.
2. Der Beispielverlauf, die Beispielkontakte und alle Beispieltexte sind erfundene Platzhalter und rein lokal.
3. Der Nachrichten-Button ist rechtsbündig über dem Manny-Button (wie im Mockup), Abstand 8 dp.
4. Der Manny-Kopf im Button verwendet `MannyPlaceholder` (keine zweite Zeichnung).
5. Beim Tageswechsel über geöffnetem Chat entfällt die Snackbar (Heute war nicht sichtbar).
6. Der Manny-Tipp ist ein reiner Zusatzweg ohne eigene Fokusstation.
7. Die Wochentage in Zeitangaben und Tagesüberschriften sind Platzhalter, keine echte Chronologie.

## 8. Offene Entscheidungen und Rückfragen

**Nutzerentscheidungen bei Freigabe (2026-10-07):** Glow im Manny-Chat bleibt wie im Mockup (Errata E-1 gilt). Eingabeleiste: im ersten Ausschnitt **nur die deaktivierte Variante** bauen; die aktive Variante aus 2.2 wird nicht vorbereitet, sondern im KI-Brief "KI-D" gestaltet (UI-77: der Test mit "darf senden = ja" entfällt; Schnittstellen schlank laut KI-Plan-Review). Bereinigt 2026-10-07 gemäß Freigabe-Entscheidung (keine inhaltliche Änderung). Übrige Rückfragen gelten wie vorgeschlagen (Emblem je Manny-Block, Snackbar über der Button-Gruppe, Hinweiszeile ab Skalierung 1,5 mitscrollend, Rückgängig-Fenster endet beim Öffnen von Chat/Nachrichten). Direktnachrichten bleiben unverbindlicher Platzhalter ohne Spec.

Keine blockiert den Start. Bis zur Klärung gilt der genannte Vorschlag.

1. **Emblem je Manny-Block** (2.2). Vorschlag: vor jedem Block, das Mockup zeigt es nur vor dem ersten. Alternative: nur vor dem ersten. *Auswirkung:* nur Optik.
2. **Snackbar über der Button-Gruppe** statt direkt über dem Primärbutton (K5). Alternative: Nachrichten-Button blendet sich während der Snackbar aus. *Auswirkung:* Alternative versteckt eine Bedienung für bis zu 8 s. Vorschlag bleibt.
3. **Hinweiszeile scrollt ab Skalierung 1,5 mit** (2.2, 3.3). Alternative: immer fest. *Auswirkung:* bei 200 % bleibt sonst zu wenig Platz auf kleinen Displays.
4. **Rückgängig-Fenster endet beim Öffnen von Chat/Nachrichten** (K11). Alternative: Fenster läuft weiter und die Snackbar bleibt unter der neuen Route nicht erreichbar. *Auswirkung:* Alternative lässt den Nutzer etwas "rückgängig" machen, das er nicht sieht.
5. **Direktnachrichten ohne Spec** (K10, Platzhalter). Eine Entscheidung des Produktverantwortlichen und eigene Specs sind vor jeder echten Funktion nötig: Chat Patient-Physio (Spec 8 Out of Scope, Spec 4 Abgrenzung anzupassen), Familie und Freunde (Spec 8 offene Fragen: Form der Unterstützung, Sichtbarkeit, Push), Ärzte-Chat (Haftung und DSGVO Art. 9 mit Anwalt). Die Kategorie "Ärzte" im Platzhalter ist keine Zusage.
6. **Gestaltung der KI-Zustände** (Senden, Streaming, Abbrechen, Fehler, Offline, Limit, Einwilligung, Eskalationskarte, aktive Eingabe) folgt im Brief "KI-D" und gestaltet auch die aktive Eingabe (2.2).

## 9. Nicht enthalten

Senden, Antworten, KI-Logik, Streaming, Abbrechen und Wiederholen, Eskalationskarte, Limit-, Offline-, Fehler- und Einwilligungs-Zustände des Chats, Spracheingabe und -ausgabe, Mikrofon im Chat, Speichern oder Löschen von Chatverläufen, proaktive Chat-Nachrichten, Benachrichtigungen und Ungelesen-Zähler, Suche, neue Chats, Kontakte hinzufügen oder verwalten, Gruppenchats, Community (Spec 8), Manny-Eintrag in der Nachrichten-Übersicht, die Wahl des KI-Modells, Schnittstellen-Technik (KS-1 bis KS-10, plant der `flutter-developer`), Buttons im Onboarding, Chat-Einstiegspunkte außer Button und Manny auf dem Pfad.
