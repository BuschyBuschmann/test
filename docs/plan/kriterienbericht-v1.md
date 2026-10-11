# Kriterienbericht v1: CuraOne, erster Ausschnitt (Paket U4)

Stand: HEAD eb10547 plus Paket U4 (nicht committet) · Autor: `flutter-developer` · Bezug: `docs/plan/flutter-plan-v1.md` (Abschnitte 12, 13, 14, 19), Design-Brief v1 mit Errata sowie Ergänzungen 1 bis 3.

Der Bericht hält je Kriterium UI-1 bis UI-99 fest, was **tatsächlich ausgeführt** wurde und was nicht. Er ersetzt weder die Sichtabnahme durch den `ui-designer` noch das Review durch den `reviewer`; wo deren Prüfung im Plan vorgesehen ist, steht das in der Bemerkung.

## 1. Bedeutung der Status

| Status | Bedeutung |
|---|---|
| **erfüllt** | Das Kriterium ist mit den im Plan (Abschnitt 13) vorgesehenen **automatischen** Prüfungen belegt, und diese Prüfungen wurden in dieser Umgebung ausgeführt und liefen grün. Nachweis nennt Testdatei, Szenario oder Skript. |
| **teilweise** | Ein Teil ist belegt; der Rest ist **[D-offen]** (nur auf einem Gerät prüfbar) oder braucht eine Sichtprüfung (Screenshots), die nicht der Umsetzer vornimmt. Die Bemerkung nennt den offenen Teil. |
| **[D-offen]** | Hier nicht prüfbar. Prüfpunkt steht in Abschnitt 5. |
| **nicht erfüllt** | Bewusst offen. In diesem Bericht gibt es keinen solchen Eintrag. |

Prüfarten (Plan 12.2): U Unit-Test · W Widget-Test · M Matrix (M-Layout, M-Modus, M-Kontrast) · C Code-Suche als Test (`test/static/code_rules_test.dart`) · S Web-Screenshot-Lauf (`tool/screens/`) · R Review · D Gerät.

## 2. Was in dieser Umgebung ausgeführt wurde

Alle Befehle im Verzeichnis `/home/user/test/app` mit `export PATH=/opt/flutter/bin:$PATH`.

| Prüfung | Ergebnis |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | ohne Änderungen (Exit 0) |
| `flutter analyze` | No issues found |
| `flutter test --exclude-tags golden,matrix` | 1013 Tests, alle grün (978 vorher, 35 neu: 33 in `data_sheet_test.dart`, 2 Selbsttests der Matrix) |
| `flutter test --tags golden` | 9 Goldens grün, unverändert (kein Golden neu erzeugt) |
| `flutter test --tags matrix` | 827 Fälle grün (736 vorher, 91 neu), Laufzeit 338 s; 17 Richtwert-Befunde, alle Pfad auf 320 × 568 (nicht neu) |
| Web-Build `-t lib/main_preview.dart` und vollständiger `shoot.mjs`-Lauf | Web-Build ok; 1115 Bilder (1005 Szenario-Bilder, 110 Simulationen) in 3488 s; Pipette 9/9 Δ 0; Pixel-Kontrast 4025 Texte/Symbole, 0 unter Schwelle |
| `tool/screens/nav_checks.mjs` | 79/79 ohne Fehler (18 neue Punkte für Deine Daten: Profil ändern, Verwerfen, Löschen) |
| `tool/screens/main_smoke.mjs` | alle Punkte ok (eigener Build `lib/main.dart`, Port 8766) |

Screenshots dieses Laufs liegen unter `/tmp/claude-0/-home-user-test/17fd6f3c-de69-5d07-b67c-c1ea446d8068/scratchpad/screens/u4/` (nicht eingecheckt, Plan 12.5); die Kontaktbögen heißen `index.html` je Variante, die Kontrastwerte stehen in `contrast.csv`.

## 3. Kriterien UI-1 bis UI-99

### Brief v1 (UI-1 bis UI-36, mit Errata E-1 bis E-4)

| ID | Status | Nachweis | Bemerkung |
|---|---|---|---|
| UI-1 | erfüllt | C: `code_rules_test` Regeln 1, 2 | Review (`reviewer`) steht nach U4 an. |
| UI-2 | erfüllt | U: `test/theme/tokens_test.dart` (Token-Dump exakt); S: Pipette `cmp-pipette` im `shoot.mjs`-Lauf | Pipette ±1 je Kanal, Ergebnis siehe Abschnitt 2. |
| UI-3 | erfüllt | U: `test/theme/contrast_test.dart` (alle Paare, auch `accent` auf `surface-opaque` und `accent-hi` auf Glas 12 % als „nicht für Text“) | |
| UI-4 | erfüllt | C: Regel 5; U: `test/theme/accent_text_test.dart`, `theme_test.dart`; M-Kontrast aller Szenarien | Neue Dateien in `lib/ui/data_sheet/` tragen keinen `accent` als Textfarbe. |
| UI-5 | erfüllt | U: `test/theme/typography_test.dart`; M-Layout (alle `RenderParagraph`s ≥ 13 sp, Gewicht ≥ 400) | |
| UI-6 | erfüllt | C: Regel 3; M-Layout (`BackdropFilter` ≤ 2 bzw. 0 in Chat/Nachrichten); `test/components/layout_surfaces_test.dart` | Mit Sheet „Deine Daten“ zählen Nav und Sheet (2); im kompakten Zustand ist das Sheet opak (1). |
| UI-7 | erfüllt | U: `glow_test.dart`, `contrast_test.dart`; W: `layout_surfaces_test.dart`; M-Layout Glow-Alpha-Regel je Text; S: Pixel-Kontrast | Gilt nach Brief-Präzisierung nur in der **Ruhelage** (bekannte Grenze, Abschnitt 4). |
| UI-8 | teilweise | W/M-Modus: `path_components_test`, `manny_bubble_test`, `home_shell_test`, `path_screen_test`, `data_sheet_test` (UI-64); M-Modus aller 83 Szenarien (RM, jeder Tipp-Übergang) | [D-offen] D-2: Systemschalter auf dem Gerät. Fortschrittskreis des Löschens läuft nach E-3 weiter (nur dieser). Die Datumsauswahl blendet jetzt über `CuraDialogRoute` ein (vorher feste 150 ms, über der 120-ms-Grenze). |
| UI-9 | teilweise | W: `layout_surfaces_test`, `path_screen_test`, `data_sheet_test` (HC: Sheet, Dialoge opak, Scrim 72 %, kein Blur); U: 4,37 ≥ 4,3; M-Modus HC | [D-offen] D-3: Systemsignal (iOS 13+, Android 14+). |
| UI-10 | [D-offen] | – | D-4: Scroll-Performance des Pfads im Profile-Modus. Vorbereitend: C/W, Blur nur in Nav, Blase, Sheet. |
| UI-11 | erfüllt | W: `test/screens/onboarding_test.dart` (Ablauf 1 bis 4) | |
| UI-12 | erfüllt | W: `onboarding_test` (disabled bei „“ und „   “, Name in Manny-Texten) | |
| UI-13 | erfüllt | W: `onboarding_test` (Zeitstempel, Version, Link); U: `app_controller_test` | |
| UI-14 | erfüllt | W: `onboarding_test`, `form_components_test` | |
| UI-15 | erfüllt | W: `onboarding_test` | |
| UI-16 | erfüllt | W: `onboarding_test` (Mikrofon, Zurück, Fortsetzen); S: `nav_checks.mjs` (Reload, `page.goBack()`) | |
| UI-17 | erfüllt | C: Regeln 4, 5 (neue Allowlist-Datei `delete_error_notice.dart` für `status-error` im Löschfehler) | Review steht an. |
| UI-18 | teilweise | W: `path_components_test`, `today_screen_test`, `path_screen_test` (Icon plus Label je Zustand); S: Achromatopsie-Bilder aller Szenarien erzeugt | Sichtprüfung der Graustufen-Bilder durch `ui-designer` offen. |
| UI-19 | teilweise | W: `today_screen_test` (Icon plus Label je Kategorie); S: Protanopie, Deuteranopie, Tritanopie für 9 Szenarien erzeugt | Sichtprüfung offen. |
| UI-20 | erfüllt | U: `path_layout_test`; W: `path_components_test`, `path_screen_test` | |
| UI-21 | erfüllt | W: `path_screen_test` (40 bis 65 % der Viewport-Höhe in allen Lagen) | |
| UI-22 | erfüllt | W: `path_components_test`, `path_screen_test` | |
| UI-23 | erfüllt | W: `path_screen_test`, `manny_bubble_test`; U: `manny_occasions_test` | |
| UI-24 | erfüllt | M-Layout (Zonen unten links/rechts) aller Pfad-Szenarien; W: `path_screen_test` | |
| UI-25 | erfüllt | W: `path_components_test`; U: `path_test` | |
| UI-26 | erfüllt | W: `today_screen_test`; U: `day_program_test` | |
| UI-27 | erfüllt | W: `today_screen_test` | |
| UI-28 | erfüllt | W: `today_screen_test` | |
| UI-29 | erfüllt | W: `today_screen_test` | |
| UI-30 | erfüllt | W: `today_screen_test`; U: `app_controller_test`, `day_rollover_test` | |
| UI-31 | erfüllt | W: `today_screen_test`; M-Layout (Erreichbarkeit nach Scrollen, auch `today-snackbar-cluster`) | |
| UI-32 | teilweise | M-Layout (`androidTapTargetGuideline`, Abstand ≥ 8 dp) aller Szenarien inkl. der neuen | [D-offen] D-6: Layout-Inspektor auf dem Gerät. |
| UI-33 | erfüllt | M-Layout bei 2,0 aller Szenarien; W: `today_screen_test`, `onboarding_test`, `floating_nav_test` (Nav ≤ 1,3); C: Regel 11 | Im Sheet „Deine Daten“ bricht der Titel des Löschen-Buttons um; ab 1,5 entfällt dort das Symbol (Abschnitt 6). |
| UI-34 | erfüllt | M-Layout 320 × 568; W: `manny_bubble_test`, `onboarding_test` | |
| UI-35 | teilweise | W: Labels, Reihenfolge, `FocusRing`; M-Kontrast (`labeledTapTargetGuideline`) | [D-offen] D-1: TalkBack/VoiceOver. |
| UI-36 | erfüllt | C: Regeln 8, 10 auf `strings_de.dart` (inkl. der neuen Texte) | Tonprüfung durch `ui-designer` offen (Plan 13). |

### Ergänzung 1 (UI-37 bis UI-69)

| ID | Status | Nachweis | Bemerkung |
|---|---|---|---|
| UI-37 | erfüllt | W: `today_screen_test`, `cura_snackbar_test`; S: `nav_checks.mjs` | |
| UI-38 | erfüllt | W: `today_screen_test`; U: `app_controller_test`, `day_rollover_test` | |
| UI-39 | erfüllt | W: `today_screen_test`, `cura_snackbar_test`, `chat_flow_test` | |
| UI-40 | erfüllt | W: `path_screen_test`, `today_screen_test`; U: `app_controller_test` | |
| UI-41 | erfüllt | W: `today_screen_test`, `cura_snackbar_test` | |
| UI-42 | teilweise | W: `today_screen_test`, `home_shell_test` (FakeClock plus `resumed`) | [D-offen] D-7: Gerätedatum und Zeitzone. |
| UI-43 | erfüllt | W: `today_screen_test`, `app_controller_test`; S: Reload in `nav_checks.mjs` | |
| UI-44 | erfüllt | W: `today_screen_test`, `home_shell_test`, `data_sheet_test` („Deine Daten“ bleibt bei Tageswechsel offen, keine Snackbar darunter) | |
| UI-45 | erfüllt | U: `manny_occasions_test`; W: `path_screen_test`, `today_screen_test` | |
| UI-46 | erfüllt | W: `data_sheet_test` (Icon in der Pfad-Kopfzeile, 48 dp, Tooltip, Label, nicht auf Heute); `action_buttons_test`; M-Layout `path-header-wrap` und `path-*` bei 320 und 2,0; S: `nav_checks.mjs` | |
| UI-47 | erfüllt | W: `data_sheet_test` (Blase schließt und zählt als gezeigt, auch eine erst nach dem Öffnen fällige; Hinweis schließt; `BackdropFilter` = 2 mit Sheet und mit Dialog); M-Layout `data-sheet`, `path-sheet-open`, `data-*-dialog` (≤ 2) | Fix in `PathScreen._visit`: Keine Blase unter einer Route über Home (sonst 3. Blur-Fläche bei 200 %). |
| UI-48 | erfüllt | W: `data_sheet_test` (Kopf und Fußleiste fest, X, Zurück, Escape, Scrim, Wischen auf dem Kopf, Fokusrückgabe, Routenname, erste Tab-Station „Schließen“); `cura_routes_test`; M-Layout `data-sheet` | Fokus auf dem Titel beim Öffnen ist die Semantik-Folge des Routennamens (Plan 4.4). |
| UI-49 | erfüllt | W: `data_sheet_test` (Umriss-Button, Dialog opak, „Abbrechen“ hell mit Anfangsfokus, „Ja, alles löschen“ Umriss, alertdialog); C: Regel 4/5 | |
| UI-50 | erfüllt | W: `data_sheet_test` (Abbrechen, Zurück, Escape, Scrim: nichts gelöscht, Fokus zurück) | |
| UI-51 | erfüllt | W: `data_sheet_test` (Schritt 1 leer, Zurück erreicht Pfad/Sheet nicht, Snackbar 4 s, Speicher leer, Neustart bei Schritt 1, Einwilligung erneut, Ausgangswerte); U: `app_controller_delete_test`; S: `nav_checks.mjs` (localStorage leer, Reload) | |
| UI-52 | erfüllt | W: `data_sheet_test` (Kreis erst ab 300 ms, Button gesperrt, Doppeltipp = ein Vorgang, alle Schließwege wirkungslos, Ansage „Wird gelöscht“, Fehler: Icon, Text, „Nochmal versuchen“, RAM unverändert, erneuter Versuch); U: `app_controller_delete_test` | `Abbrechen` ist ab sichtbarem Kreis deaktiviert. |
| UI-53 | erfüllt | W: `data_sheet_test` (dieselben Widgets, kein Manny, keine Mikrofon-Zeile, „Anderes“ vorbefüllt); C: Regel 6 (beide Orte nutzen die eine Klasse) | |
| UI-54 | erfüllt | W: `data_sheet_test`; U: `profile_test` | |
| UI-55 | erfüllt | W: `data_sheet_test` (nur Name; Typ und Datum: Pfad neu, Streak, Freezes, Heute-Änderungen bleiben, `pulsePending` leer, kein Puls, aktuelle Unit auf 55 %, Ansagen; nur Typ in gleicher Woche zentriert neu); `path_screen_test` | Der Pfad zentriert jetzt auch bei gleicher Unit und Woche neu (Schlüssel aus Typ und Datum). |
| UI-56 | erfüllt | W: `data_sheet_test` | |
| UI-57 | erfüllt | W: `data_sheet_test` (alle fünf Schließwege, Weiter bearbeiten, Verwerfen, Scrim, Aufbau); S: `nav_checks.mjs` (inkl. Browser-Zurück) | |
| UI-58 | teilweise | W: `data_sheet_test` (320 × 568 mit Tastatur: „Speichern“ sichtbar, Feld sichtbar und fokussiert über den Wechsel in den kompakten Zustand; bei 200 % ebenso); M-Layout `data-sheet-keyboard` (alle Viewports, 1,0 und 2,0) | [D-offen] D-5: echte Tastatur. Bei kleiner Fläche mit Tastatur weicht das Sheet vom Brief ab (Abschnitt 6, A-U4-1). |
| UI-59 | erfüllt | W: `path_screen_test` | |
| UI-60 | erfüllt | W: `path_screen_test`; U: `path_test` | |
| UI-61 | erfüllt | W: `path_screen_test` | |
| UI-62 | erfüllt | W: `path_screen_test`, `path_components_test` | |
| UI-63 | erfüllt | W: `path_screen_test`; M-Layout | |
| UI-64 | erfüllt | W: `data_sheet_test` (RM: Sheet und Dialoge ohne Schiebung, nach 121 ms keine Animation; Fortschrittskreis darf drehen), `path_components_test`, `cura_snackbar_test`; M-Modus RM aller Szenarien, jeder Tipp-Übergang | Datumsauswahl über eigene Route, damit ≤ 120 ms. |
| UI-65 | erfüllt | W: `data_sheet_test` (HC: Sheet, Dialoge opak, `border-control-hc`, Scrim 72 %, kein Blur, Kreisrand am Icon), `cura_dialog_test`, `cura_snackbar_test`, `path_screen_test`; M-Modus HC | |
| UI-66 | erfüllt | W: `data_sheet_test` (320 × 568 bei 200 %); M-Layout aller neuen Szenarien bei 2,0 | Kompakter Zustand (Abschnitt 6). |
| UI-67 | erfüllt | C: Regeln 1 bis 5; U: `tokens_test` (`scrim` 60/72 %) | |
| UI-68 | teilweise | W: `data_sheet_test` (Routennamen, Fokusrückgabe, Ansagen, Tastaturbedienung); `cura_dialog_test`; S: ARIA in `nav_checks.mjs` | [D-offen] D-1: TalkBack/VoiceOver. |
| UI-69 | erfüllt | C: Regeln 8, 10 | Tonprüfung durch `ui-designer` offen. |

### Ergänzung 2 (UI-70 bis UI-89)

| ID | Status | Nachweis | Bemerkung |
|---|---|---|---|
| UI-70 | erfüllt | W: `chat_flow_test`, `today_screen_test`, `onboarding_test`, `data_sheet_test` (bei offenem „Deine Daten“ und offenem Löschdialog: weder Semantik-Knoten noch Fokus noch Tipp); S: `nav_checks.mjs` | |
| UI-71 | erfüllt | W: `chat_flow_test`, `today_screen_test` (auch Umbruchszustand), `onboarding_test`; M-Layout | |
| UI-72 | erfüllt | W: `action_buttons_test`, `chat_flow_test`; C: Regel 12 | |
| UI-73 | erfüllt | W: `today_screen_test`, `pill_button_test`; M-Layout (`checkTodayGroup`) | |
| UI-74 | erfüllt | W: `path_screen_test`, `manny_test` | |
| UI-75 | erfüllt | W: `path_screen_test`; U: `path_layout_test`, `overlay_placement_test`; M-Layout (`path-scrolled-bottom`, `path-cluster-*`) | Bekannte Grenzen: Abschnitt 4. |
| UI-76 | erfüllt | W: `chat_components_test`, `chat_flow_test` (inkl. Wachstums-Test) | |
| UI-77 | erfüllt | W: `chat_components_test`, `chat_flow_test`; C: Regel 16 | |
| UI-78 | erfüllt | W: `chat_flow_test`; C: Regel 12 | |
| UI-79 | erfüllt | W: `chat_components_test`, `chat_flow_test` | |
| UI-80 | erfüllt | W: `chat_components_test`, `chat_flow_test` | |
| UI-81 | erfüllt | C: Regeln 1, 2, 8, 10; W: `chat_components_test`, `chat_flow_test` | |
| UI-82 | erfüllt | C: Regel 15; U: `app_controller_delete_test` (Löscher-Reihenfolge, Abbruch beim ersten Fehler, RAM unverändert); W: `data_sheet_test` (Löschen über den Dialog, neues Onboarding mit anderem Namen: Beispielverlauf „Moin Mia …“, im Speicher nur das Zustandsdokument ohne Chat-Rest), `chat_flow_test` | W-Teil mit dem echten Löschweg über Sheet und Dialog (U4). |
| UI-83 | erfüllt | C: Regel 14 | Review steht an. |
| UI-84 | erfüllt | C: Regel 13; W: `chat_components_test` („Beispiel“ sichtbar) | |
| UI-85 | erfüllt | C: Regeln 3, 12; M-Layout (Chat 0, Pfad/Heute ≤ 2 auch mit Sheet) | |
| UI-86 | erfüllt | W: `chat_flow_test`, `chat_components_test`, `home_shell_test`; S: `nav_checks.mjs` | |
| UI-87 | erfüllt | W: `action_buttons_test`, `chat_components_test`; M-Modus HC | |
| UI-88 | erfüllt | W: `chat_components_test`, `chat_flow_test`; M-Layout (`chat-manny-scale15`, `messages-scale15`) | |
| UI-89 | teilweise | W: `chat_flow_test`, `chat_components_test` (Labels, Reihenfolge, Routennamen) | [D-offen] D-1: TalkBack/VoiceOver. |

### Ergänzung 3 (UI-90 bis UI-99, umgesetzt in U3c)

| ID | Status | Nachweis | Bemerkung |
|---|---|---|---|
| UI-90 | erfüllt | W: `path_screen_test` | |
| UI-91 | erfüllt | W: `path_screen_test` (Glas, Strichel-Rand, kein Blur; HC opak) | |
| UI-92 | erfüllt | W: `path_screen_test` | |
| UI-93 | erfüllt | W: `path_screen_test` | |
| UI-94 | erfüllt | W: `path_screen_test`; U: `path_layout_test` | |
| UI-95 | erfüllt | U: `path_test`; W: `path_screen_test` | |
| UI-96 | erfüllt | W: `path_screen_test` | |
| UI-97 | erfüllt | U: `path_layout_test`; W: `path_screen_test` (320 und 430 dp) | |
| UI-98 | erfüllt | W: `path_screen_test` | |
| UI-99 | erfüllt | W: `path_screen_test`; M-Kontrast und Glow-Regel `path-outlook`, `path-outlook-hint` | |

Zusammenfassung: **erfüllt 88 · teilweise 10 · [D-offen] 1 · nicht erfüllt 0** (99 Kriterien). „Teilweise“ sind UI-8, 9, 18, 19, 32, 35, 42, 58, 68 und 89; Ursache ist jeweils der Geräteteil oder die Sichtprüfung, nie ein fehlgeschlagener Test. [D-offen] ist UI-10.

## 4. Bekannte Einschränkungen (K-1, K-2) und Grenzen der Prüfung

| Nr. | Einschränkung | Umgang |
|---|---|---|
| **K-1** | Wer täglich trainiert, schließt Units schneller ab als Wochen vergehen. Die aktuelle Unit sitzt dann in einer späteren Woche als „Woche W“ der Kopfzeile, gesperrte Units dieser späteren Woche zeigen „Kommt in Woche N“, obwohl sie schon dran sind, und „Kommt noch diese Woche“ bezieht sich auf die Datumswoche W (Plan 7.2, A-11). | Im Prototyp akzeptiert (Platzhalter-Pfad). Lösung kommt mit dem Physio-Framework. Test `path_test` hält den Fall fest (Datumswoche bleibt). |
| **K-2** | Manny-Chat und Nachrichten sind reine Ansicht. Die Nachrichten sind ein unverbindlicher Platzhalter ohne Spec (Ergänzung 2, K10); jede Datei unter `lib/ui/messages/` trägt den Kommentar „Unverbindlicher Platzhalter, keine Spec“ (C: Regel 13). Der Chat speichert nichts (UI-82). | Im KI-Ausschnitt neu bewerten (R-9, R-10). |
| G-1 | **Overlays werden nur in der Ruhelage gelesen.** Marker innerhalb eines Scrollbereichs werden je Scanposition nicht neu gelesen; die Glow-Regel gilt nur im eingeschwungenen Ausgangszustand. | Bekannte Grenze der Matrix (R-U3 MINOR-2). |
| G-2 | **Blase und Hinweis zählen beim Scrollen nicht als Hindernis** (`kDismissedOnScroll`): Der Pfad schließt beide, sobald der Nutzer scrollt. | Bekannte Grenze, im Plan 4.6 so festgelegt. |
| G-3 | **Horizontales Scrollen ist nicht abgedeckt:** Die Matrix prüft vertikale Scrollbereiche; „kein horizontales Scrollen“ folgt aus fehlenden Layout-Exceptions und aus dem Aufbau, nicht aus einer eigenen Prüfung. | Bekannte Grenze. |
| G-4 | **Geräteprüfungen [D-offen]** (Abschnitt 5). | Prüfliste unten. |
| G-5 | Die 17 Richtwert-Befunde der Matrix (Sichtfläche zwischen Kopf und Overlays unter 120 dp bei 320 × 568 auf dem Pfad) sind unverändert; keiner stammt aus den neuen Szenarien (`build/matrix/matrix.txt`). | Richtwert, Meldung an `ui-designer`, keine stille Umgestaltung (Plan 12.2). |
| G-6 | **Goldens:** Die 9 freigegebenen Goldens sind unverändert grün. Neue Goldens für die `data-*`-Szenarien wurden **nicht** erzeugt (Plan 12.1: Sichtung durch `ui-designer` und Nutzerfreigabe vor dem Einchecken). | Entscheidung offen (Rückfrage Q-3 an den Orchestrator). |

## 5. [D-offen]-Prüfliste für den Nutzer (Gerät oder Emulator)

Für Android: Android-SDK/Emulator, `flutter run` bzw. `flutter run --profile`. Für iOS: Xcode. Vorbereitung ohne Konto-Aktion; keine Zugangsdaten nötig.

| Nr. | Prüfpunkt | Kriterien | Vorgehen und Erwartung |
|---|---|---|---|
| D-1 | TalkBack und VoiceOver | UI-35, 68, 89 | Alle Screens durchgehen. In „Deine Daten“: Routenname „Deine Daten“, Kopf, Felder, Karten mit „ausgewählt“, Datum, Lösch-Button, „Speichern“. Verwerfen- und Löschdialog werden als Dialog angesagt (Titel zuerst). Nach dem Speichern: „Gespeichert.“ bzw. „Gespeichert. Pfad neu berechnet.“ Während des Löschens: „Ja, alles löschen, Wird gelöscht“. Nichts Dekoratives wird vorgelesen. |
| D-2 | Systemoption „Bewegung reduzieren“ | UI-8, 64 | Android: Animationen entfernen; iOS: Bewegung reduzieren. Sheet und Dialoge ohne Schiebung. Der Fortschrittskreis im Löschdialog dreht weiter (Ausnahme E-3), sonst bewegt sich nichts. |
| D-3 | Hoher Kontrast | UI-9, 65, 87 | iOS 13+ (Kontrast erhöhen) bzw. Android 14+: Sheet, Dialoge, Karten opak mit sichtbarem Rand, Scrim dunkler, kein Blur, kein Glow. |
| D-4 | Scroll-Performance des Pfads | UI-10 | `flutter run --profile` auf einem Mittelklasse-Gerät, Pfad scrollen, Sheet öffnen: Performance-Overlay, keine dauerhaften Frames über 16 ms durch Blur. Messung dokumentieren. |
| D-5 | Echte Tastatur im Sheet | UI-58 | Auf einem kleinen Gerät (oder Emulator 320 dp Breite, 568 dp Höhe): „Deine Daten“ öffnen, Namensfeld antippen. Erwartung: „Speichern“ bleibt über der Tastatur sichtbar, das Feld und der Cursor sind im Bild, die Tastatur bleibt beim Tippen offen (der Fokus geht beim Wechsel in den kompakten Zustand nicht verloren). Der Abschnitt „Daten löschen“ ist nur bei sichtbarer Tastatur weg und kehrt mit ihr zurück. Karte „Anderes“ mit Freitext prüfen. |
| D-6 | Hit-Areas | UI-32 | Layout-Inspektor bzw. Semantik-Debugging: alle antippbaren Elemente ≥ 48 × 48 dp, auch im Sheet. |
| D-7 | Gerätedatum und Zeitzone | UI-42, 44 | Gerätedatum auf den Folgetag stellen, App fortsetzen: Heute zeigt das neue Datum. Mit offenem „Deine Daten“: Sheet bleibt offen und unverändert. |
| D-8 | Android-Zurück | UI-48, 50, 57 | Zurück im Sheet ohne Änderung: schließt. Mit Änderung: „Änderungen verwerfen?“. Im Löschdialog: schließt, während des Löschens wirkungslos. Android 14+ Predictive Back: keine Vorschau-Animation (gewollt, `canPop: false`). |
| D-9 | Datumsauswahl | UI-15, 53, 4 | Im Sheet und im Onboarding Schritt 4: Dark-Theme, Akzent nur `accent`/`accent-hi`, nur Daten bis heute wählbar. Die Auswahl öffnet jetzt über die App-eigene Dialogroute (`showCuraDatePicker`), nicht über `showDatePicker`. |
| D-10 | Systemschrift 200 % (Android 14, nichtlinear) | UI-33, 66 | Sheet und Dialoge: nichts abgeschnitten; ab 150 % ohne Symbol am Lösch-Button; Speichern erreichbar. |
| D-11 | Löschen auf echtem Speicher | UI-51 | Löschen bestätigen, App beenden und neu starten: Onboarding Schritt 1, Einwilligung erneut nötig. |
| D-12 | Safe Area und Notch | UI-66 | Sheet unten über dem Home-Indikator, Fußleiste nicht überdeckt, Landscape. |
| D-13 | Blur-Optik (Impeller) | UI-6, 47 | Sheet und Nav: Glas-Eindruck wie in den Screenshots; die Performance ist nicht aus dem Web ableitbar. |
| D-14 | Hardware-Tastatur | UI-48, 68 | Tab-Reihenfolge im Sheet: Schließen, Name, Karten, Datum, Löschen, Speichern; Escape schließt bzw. öffnet Verwerfen; Fokus kehrt zum Icon zurück. |

## 6. Abweichungen und Annahmen aus U4 (zur Bestätigung durch `ui-designer` bzw. Orchestrator)

| Nr. | Festlegung | Grund und Auswirkung |
|---|---|---|
| A-U4-1 | **Kompakter Zustand des Sheets.** Bleibt über der Tastatur (bzw. im Querformat) weniger als 440 dp Höhe, nimmt das Sheet den ganzen Platz, sein Kopf läuft als erstes Element mit dem Inhalt (wie im Onboarding und im Chat), die Fläche ist opak (`surface-opaque`, kein Blur), die Fußleiste mit „Speichern“ bleibt fest, mit engerem Rand. Ist dabei die **Tastatur sichtbar**, entfällt der Abschnitt „Daten löschen“, bis sie wieder weg ist. | Brief 3.2 verlangt „Kopf scrollt nicht mit“ und „Speichern bleibt sichtbar“. Beides lässt sich bei 320 × 568 mit 300 dp Tastatur nicht halten: Der feste Kopf (Titel, Untertitel) ließe kaum Platz für ein Feld, und bei 200 % Schrift wäre der Lösch-Button allein 224 dp hoch, also höher als der Scrollbereich. Außerdem scheint bei geringer Höhe der Lichtfleck durch die Glasfläche auf den Titel (über 16 %, E-1). Die Matrix prüft das Tastatur-Szenario ohne Ausnahme an allen Viewports und Skalierungen. **Folge:** Auf kleinen Geräten mit Tastatur scrollt der Titel weg und „Schließen“ ist dann nur nach oben scrollend erreichbar (Zurück, Escape und Scrim schließen weiter). Normale Bildschirmhöhen ohne Tastatur und verfügbare Höhen ab 440 dp (Bildschirm minus Tastatur, z. B. 390 × 844 mit Tastatur) sind nicht betroffen. Fokus und Eingabeverbindung des Feldes bleiben beim Wechsel erhalten (Test). |
| A-U4-2 | **Oberkante des Sheets** höchstens 90 % hoch **und** mindestens 64 dp von der Bildschirmoberkante (`CuraSize.sheetTopClearance`). | Der Titel liegt sonst bei sichtbarer Tastatur im Bereich über 16 % Glow (Text auf Glas ≤ 16 %, E-1). Wirkt auch beim Trainings-Sheet (bei 568 dp 7 dp weniger Höhe). |
| A-U4-3 | **Lösch-Button ohne Symbol ab Textskalierung 1,5.** | Vier Zeilen Text mit Symbol; ohne Symbol drei. Der Text hat Vorrang. |
| A-U4-4 | **Datumsauswahl über `showCuraDatePicker`** (`DatePickerDialog` auf der `CuraDialogRoute`) statt `showDatePicker`, für Onboarding und Sheet. | `showDatePicker` blendet mit festen 150 ms ein; bei „Bewegung reduzieren“ gelten höchstens 120 ms (UI-8, UI-64). Die Matrix hatte das bisher nur zufällig nicht berührt. Gleiches Widget, gleiche Grenzen. |
| A-U4-5 | **Während des Löschens ist „Abbrechen“ ab sichtbarem Fortschrittskreis deaktiviert**; davor bleibt die Fläche unverändert (Tipps ignoriert). | Plan 6.3: Zurück, Escape, Scrim wirkungslos; „Abbrechen“ bricht den laufenden Vorgang nicht ab, also gesperrt. |
| A-U4-6 | **„Verwerfen“ schließt das Sheet** (die Änderungen gehen mit ihm unter, nichts wird gespeichert). | UI-57 „setzt die Felder zurück, ohne zu speichern“; Schließen ist der Zweck des Dialogs (Schließversuch mit Änderungen). |
| A-U4-7 | **Keine Blase unter einer Route über Home** (`PathScreen._visit` wartet nicht, sondern entfällt). | Eine unter dem Sheet erscheinende Blase hätte ein drittes Blur-Element gebildet und wäre unbemerkt als gezeigt gezählt worden (UI-47). Sie erscheint beim nächsten Pfad-Besuch. |
| A-U4-8 | **Neue Matrix-Hilfen:** Kopf und innere Tap-Ziele überdeckter Routen zählen nicht (`headerRect`, `_renderTapRects` mit `isBuriedRoute`); `_tapEveryTarget` liest die Ziele vor jedem Tipp neu; `settle` lässt `loops`-Szenarien in 60 Frames à 50 ms laufen (Skript-Tipps und 300-ms-Kreis). | Alle drei sind Korrekturen der Harness, keine Ausnahmen für einzelne Szenarien. Selbsttests in `matrix_checks_test.dart`. |
| A-U4-9 | Neuer Token `MotionTokens.busyDelay` (300 ms) und `CuraMotion.busyDelay`. | Statische Regel 2 (keine Zahlen außerhalb `lib/theme/`). |
