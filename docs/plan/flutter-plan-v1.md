# Flutter-Plan v1.3: CuraOne, erster Ausschnitt

Status: **FREIGEGEBEN (2026-10-07)** · v1.3 (v1.1 überarbeitet nach Review R-P1/A-P1; v1.2 ergänzt um Brief-Ergänzung 2 „Manny-Chat und Nachrichten“, KI-Plan Abschnitt 11 und `KONVENTIONEN.md`; v1.3 Präzisierungen aus Re-Review R-P1-RR und Nutzerentscheidungen) · Paket P1-K3 · Autor: `flutter-developer` · Stand 2026-10-07

Verbindliche Vorgaben (gelten im Wortlaut, dieser Plan setzt sie nur technisch um):
- `docs/design/design-brief-v1.md` (freigegeben, UI-1 … UI-36, Nutzerentscheidungen Abschnitt 12) **einschließlich Abschnitt 14 „Errata"**: Erratum E-1 (UI-7 neue Fassung, Glow-Regel nach Untergrund) und Erratum E-2 (UI-4 präzisiert, `accent` als Text nur auf `bg`). Wo dieser Plan UI-4 oder UI-7 nennt, gilt die Errata-Fassung.
- `docs/design/design-brief-v1-ergaenzung-1.md` (freigegeben, UI-37 … UI-69, Nutzerentscheidungen Abschnitt 8)
- `docs/design/design-brief-v1-ergaenzung-2.md` (freigegeben, UI-70 … UI-89; **neue Fassungen** von UI-24, UI-31, UI-59 und Ergänzung 1 Abschnitt 3.5; Präzisierungen von UI-37, UI-39, UI-41, UI-63; Brief v1 Abschnitt 13 teilweise aufgehoben; Nutzerentscheidungen Abschnitt 8: Glow im Chat bleibt, **nur die deaktivierte Eingabeleiste** wird gebaut). Wo dieser Plan eines dieser Kriterien nennt, gilt die Fassung aus Ergänzung 2.
- `docs/plan/ki-plan-v1.md` Abschnitt 11 (KS-1 … KS-10) in der vom Nutzer **verschlankten** Form (N-17): KS-1 synchron, KS-4 minimal ohne JSON/Speicherung, KS-5 **nur `messages`** (lesend; `canSend` entfällt mit der aktiven Variante, Präzisierung des Orchestrators zu P1-K2), KS-6 nur, was der Brief verlangt (`ChatComposer` **nur deaktiviert**, keine aktive Variante, kein Variantentest), KS-7 entfällt, KS-9 Löscher-Liste. Keine KI, kein Netzwerk, keine Red-Flag-Vorprüfung im ersten Ausschnitt.
- `/home/user/test/KONVENTIONEN.md` (verbindlich, Regeln 1–5). Die Abschnittsnummer 12.1 dieses Plans wird dort zitiert und bleibt deshalb stabil.
- Logik-Entscheidungen des Nutzers aus dem Arbeitspaket P1 und aus der Review-Runde (Abschnitt 18)

Kontext: Spec 1, 2, 3 (`Spec 1-7.docx`), `docs/UEBERGABE.md`, `docs/produkt/curaone-vollstaendigkeit.md`, Mockups `docs/design/mockups/*-v3.png` (v1) sowie `pfad-v4.png`, `heute-v4.png`, `manny-chat-v1.png`, `nachrichten-v1.png`, `nachrichten-chat-v1.png` (Ergänzung 2; nur Orientierung).

Kennzeichnung: **A-n** = Annahme (gilt bis zur Klärung), **F-n** = offene Frage (Abschnitt 17), **N-n** = Nutzerentscheidung (Abschnitt 18), **Brief-E-n** = Erratum im Brief, **K-n** = bekannte Einschränkung des Prototyps.

---

## 1. Kurzfassung

| Thema | Entscheidung im Plan |
|---|---|
| Ort im Repo | Neues Flutter-Projekt unter `/home/user/test/app/` (Repo-Stamm bleibt für Docs/Specs) |
| Plattformen | Android, iOS, Web (Web nur als Prüfumgebung für Screenshots, kein Produktziel) |
| State-Management | Flutter-Bordmittel: ein `AppController` (`ChangeNotifier`) über `InheritedNotifier`, plus lokale `State`-Objekte für reine UI-Zustände. Kein Zusatzpaket |
| Navigation | Navigator 1.0 mit `navigatorKey`; zwei Wurzel-Routen (Onboarding, Home mit Tabs in `IndexedStack` + `TickerMode`); eigene Routen für Sheets/Dialoge; Vollbild-Routen für Manny-Chat, Nachrichten und Beispiel-Chat (ohne Nav); Löschen und Neustart nach unlesbaren Daten per `pushAndRemoveUntil` |
| Speicherung | Ein versioniertes JSON-Dokument unter einem festen Schlüssel in `shared_preferences`, hinter `StateStore`; Migrationskette je Schemaversion; unlesbare Daten → automatischer Neustart (N-12) |
| Reine Logik | `lib/logic/` ohne Flutter-Import: Tag/Uhr, Streak, Pfad-Generator und -Layout, Pools, Tagesprogramm/Tageswechsel, Rückgängig, Manny-Anlässe, Manny-Textquelle und -Kontext (KS-1–3), Chat-Datenmodell (KS-4), Profiländerung, Plural-Helfer |
| Tokens | `ThemeExtension`s `CuraColors` (inkl. `scrim`), `CuraTypography`; Konstanten `CuraSpace`, `CuraRadius`, `CuraSize`, `CuraShadow`, `CuraMotion`; Variante „Hoher Kontrast" als eigener Token-Satz |
| Pakete | `shared_preferences` (pub.dev) und `flutter_localizations` (SDK). Sonst nichts |
| Fonts | Variable TTFs von Bricolage Grotesque und DM Sans als Assets inkl. `OFL.txt`; Gewicht per `fontWeight` **und** `FontVariation` |
| Backend | Nicht angebunden. Entscheidungsvorlage: **Supabase (EU-Region)** empfohlen, Firebase als Alternative (Abschnitt 11) |
| Verifikation | `flutter analyze`, Unit-, Widget-, Golden-Tests, gestufte Matrix, statische Code-Regeln als Test, Web-Screenshots per Playwright/Chromium inkl. CDP-Farbsehschwäche-Simulation und Pixel-Kontrastmessung. Gerätekriterien explizit markiert |
| Chat/Nachrichten | Nur sichtbar, ohne Funktion: Manny-Chat mit festem Beispielverlauf und deaktivierter Eingabeleiste, Nachrichten-Übersicht und Beispiel-Chats nur ansehbar; nichts gespeichert, nichts gesendet; Einstieg über Button-Gruppe (Pfad, Heute) und Manny auf dem Pfad |
| Umsetzung | 9 Umsetzungspakete (sonnet), in dieser Reihenfolge: U1a, U1b, U2a (Bausteine), U2p (Prüf-Infrastruktur), U2b, U2c (Chat + Nachrichten), U3a (Pfad), U3b (Heute), U4; ein Schreiber (Abschnitt 14) |

---

## 2. Umgebung und Machbarkeits-Spike (tatsächlich ausgeführt, v1)

Im Wegwerfprojekt unter dem Scratchpad (nicht im Repo) geprüft, Flutter 3.47.6 / Dart 3.13.5:

| Prüfung | Ergebnis |
|---|---|
| `flutter create --platforms=android,ios,web`, `flutter pub add shared_preferences`, `flutter_localizations` | ok, `shared_preferences` 2.5.6 aufgelöst (pub.dev über Proxy erreichbar) |
| `flutter build web --release --no-web-resources-cdn` | ok, CanvasKit lokal gebündelt, **keine externen Requests** beim Laden (mit gebündelten Fonts) |
| Playwright 1.56.1 + `/opt/pw-browsers/chromium-1194/chrome-linux/chrome` | Screenshots bei 390×844 und 320×568 ok; `BackdropFilter`, Radialverlauf sichtbar |
| Textskalierung per Query-Parameter (`MediaQuery`-Override) | ok (200 % bricht um) |
| Variable Fonts (DM Sans `[opsz,wght]`, Bricolage `[opsz,wdth,wght]`) aus `github.com/google/fonts` (raw) | Download ok, Rendering Web ok mit `FontVariation('wght', …)` |
| Golden-Test mit echten Fonts (`FontLoader`) unter `flutter test` | ok, Text lesbar im Golden |
| CDP `Emulation.setEmulatedVisionDeficiency` (`protanopia`, `deuteranopia`, `achromatopsia`; `tritanopia` ist derselbe CDP-Typ-Satz) | ok, wirkt auf die Canvas-Ausgabe (Pixelwerte geprüft) |
| Playwright `page.clock.install({time})` | `Date` liefert die gesetzte Zeit. **Nicht geprüft:** ob Flutter/CanvasKit mit installierter Fake-Uhr weiter Frames rendert (offen, U2p, Abschnitt 12.5) |
| Material-Icons für Goldens | vorhanden unter `/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf` |
| Kontraste der Brief-Tabelle und der Errata nachgerechnet (WCAG, sRGB, Glow als Alpha-Komposition unter Glas) | Modell stimmt mit Brief überein (z. B. `text-2` auf Glas über 16 % Glow 5,35; `accent` auf `surface-opaque` 4,42; `accent-hi` auf Glas über 12 % Glow 4,36) |

Nicht vorhanden: Android-SDK, Xcode, Emulator/Gerät, GTK (kein Linux-Desktop-Target). Folge: keine Gerätetests, keine Profile-Messung (UI-10), kein echtes TalkBack/VoiceOver.

---

## 3. Projekt- und Ordnerstruktur

```
app/                                   # flutter create --org com.example --project-name curaone (F-12)
  pubspec.yaml
  analysis_options.yaml                # flutter_lints (Standard aus flutter create)
  dart_test.yaml                       # Tags: golden (plattformabhängig), matrix (lang laufend)
  assets/fonts/
    BricolageGrotesque[opsz,wdth,wght].ttf
    DMSans[opsz,wght].ttf
    OFL-BricolageGrotesque.txt
    OFL-DMSans.txt
  lib/
    main.dart                          # Produktions-Einstieg: echter Store, Systemuhr, Systemsignale
    main_preview.dart                  # NUR Prüfumgebung (Web): Szenario, Uhrzeit, Skalierung, HC, RM, Text-Dump per URL
    app.dart                           # CuraApp: MaterialApp, Theme, Locale de, navigatorKey, AppScope, ContentFrame
    l10n/strings_de.dart               # alle sichtbaren Texte, Screenreader-Labels, Tooltips, Hinweistexte (Konvention 4); OHNE Flutter-Import, damit lib/logic/ sie nutzen darf
    logic/                             # reine Dart-Logik, KEIN import 'package:flutter/...'
      clock.dart                       # typedef Clock, LocalDay
      plural.dart                      # tage(n): "1 Tag" / "n Tage"
      streak.dart                      # StreakState, StreakEngine
      path_model.dart                  # PathUnit, UnitKind, UnitStatus
      path_generator.dart              # Beispielpfad (Platzhalter) + Fortschritt
      path_layout.dart                 # Positionen der Units (geschwungen), Polster, testbar ohne Widgets
      placeholder_pools.dart           # Übungen, Termine, Manny-Texte, Fakten (alle als PLATZHALTER markiert)
      day_program.dart                 # DayProgramState, Ableitung der Übungsliste, Tauschen/Entfernen/Eigene
      day_rollover.dart                # Tageswechsel-Erkennung und -Anwendung
      undo.dart                        # TrainingSnapshot (Rückgängig)
      manny_occasions.dart             # welche Blase wann (Anlässe, einmal pro Tag)
      profile.dart                     # Profil, Verletzungstyp, Profiländerung inkl. Neuberechnung
      manny_text_source.dart           # KS-1: MannyTextSource (synchron) + PlaceholderMannyTextSource
      manny_context.dart               # KS-3: MannyContext.from(AppState, LocalDay) + toJson
      chat_model.dart                  # KS-4: ChatMessage {id, author, kind, status, text}, Enums; kein JSON
      app_state.dart                   # AppState (unveränderlich) + JSON
      migrations.dart                  # Migrationskette Schema n -> n+1, Lesetoleranz
    data/
      state_store.dart                 # abstract StateStore {load, save, deleteAll}, kAllStorageKeys
      prefs_state_store.dart           # shared_preferences-Implementierung (zugleich erster DataEraser)
      data_eraser.dart                 # KS-9: abstract DataEraser {eraseAll}; Liste im AppController
      manny_chat_source.dart           # KS-5: MannyChatSource {messages(vorname)} + ExampleMannyChatSource (kein canSend)
    state/
      app_controller.dart              # ChangeNotifier: hält AppState, ruft Logik, schreibt Store
      app_scope.dart                   # InheritedNotifier<AppController>
      transient_ui.dart                # Undo-Fenster, offene Blase/Hinweis (nicht persistiert)
    theme/
      tokens.dart                      # Rohwerte (einzige Stelle mit Hex-Werten und Zahlen)
      cura_colors.dart                 # ThemeExtension (dark, darkHighContrast)
      cura_typography.dart             # ThemeExtension der Textstile
      cura_metrics.dart                # CuraSpace, CuraRadius, CuraSize, CuraShadow
      cura_motion.dart                 # Dauern/Kurve + reduzierte Bewegung
      cura_theme.dart                  # ThemeData-Aufbau, DatePicker-Theme
      glow.dart                        # Glow-Geometrie und Alpha-Funktion (geteilt von Painter und Test)
      contrast.dart                    # WCAG-Berechnung (für Test UI-3 und UI-7)
    ui/
      components/                      # Bausteine aus Brief 5 und Ergänzung 2 (siehe Abschnitt 9)
      routes/                          # CuraSheetRoute, CuraDialogRoute, CuraFullscreenRoute (Chat/Nachrichten), Platzhalterseite Datenschutz
      onboarding/                      # OnboardingFlow, Step1Name … Step4Date
      home/                            # HomeShell (Tabs, Zurück, Lifecycle)
      path/                            # PathScreen, PathView (Painter), PathHeader-Anbindung
      today/                           # TodayScreen, TrainingModeSheet, CustomExerciseDialog
      data_sheet/                      # DataSheet „Deine Daten", DeleteDialog, DiscardDialog
      chat/                            # MannyChatScreen (Vollbild-Route)
      messages/                        # MessagesScreen, ExampleChatScreen, example_contacts.dart (KS-10, eigene feste Daten, Kommentar „unverbindlicher Platzhalter, keine Spec“)
    dev/scenarios.dart                 # benannte AppState-Fixtures (für Tests und main_preview)
  test/
    flutter_test_config.dart           # lädt Fonts + MaterialIcons für alle Tests
    fixtures/state_v1.json             # gespeichertes Dokument je Schemaversion (Migrationstest)
    support/                           # FakeClock (Standard 2026-10-07, Mittwoch), Stores, pumpApp(), Viewports
    logic/                             # Unit-Tests (Abschnitt 7)
    theme/                             # Kontrast-, Glow- und Token-Tests
    static/code_rules_test.dart        # Code-Suche als Test (Abschnitt 12.3)
    components/                        # Widget-Tests der Bausteine
    screens/                           # Widget-Tests der Abläufe
    matrix/                            # gestufte Matrix (Abschnitt 12.2), Tag matrix
    golden/                            # Golden-Tests (Tag golden)
  tool/screens/
    shoot.mjs                          # Playwright: Web-Screenshots aller Szenarien/Varianten + Pixel-Kontrast
    scenarios.json                     # Liste der Szenarien/Viewports/Varianten
```

Begründung: Trennung `logic` (rein Dart, Brief 9 und Ergänzung 5) / `state` (Bindeglied) / `ui` macht die Logik ohne Widgets testbar und lässt später ein Backend hinter `data/` treten, ohne Screens zu ändern.

---

## 4. Screens und Navigation

### 4.1 Routen und Wurzel

| Route | Art | Inhalt |
|---|---|---|
| `StartGate` | erste Route | lädt `AppState` aus dem Store; Ladeansicht (statische Glas-Kreise, kein Shimmer, keine künstliche Verzögerung) |
| `OnboardingRoute(step, notice)` | Seite | `OnboardingFlow` mit 4 Schritten in **einer** Route; Schrittwechsel intern; `notice` ∈ {keine, gelöscht, Neustart nach unlesbaren Daten} |
| `HomeRoute` | Seite | `HomeShell`: `IndexedStack` mit `PathScreen` und `TodayScreen`, je Tab in `TickerMode(enabled: tab aktiv)`, `FloatingNav` |
| `PrivacyPlaceholderRoute` | Seite | Platzhalterseite „Datenschutzerklärung" (aus Schritt 2) |
| `CuraSheetRoute` | eigene `PopupRoute` | „Wie willst du trainieren?" (Heute), „Deine Daten" (Pfad) |
| `CuraDialogRoute` | eigene `RawDialogRoute`-Variante | „Eigene Übung", „Alles löschen?", „Änderungen verwerfen?" |
| System-Datumsauswahl | `showDatePicker` | Onboarding Schritt 4 und Sheet (gleiche `DateCard`) |
| `MannyChatRoute` | `CuraFullscreenRoute` (eigene `PageRoute`) | Manny-Chat, Vollbild ohne Nav (Ergänzung 2, 3.2) |
| `MessagesRoute` | `CuraFullscreenRoute` | Nachrichten-Übersicht (Ergänzung 2, 3.3) |
| `ExampleChatRoute(contactId)` | `CuraFullscreenRoute` | Beispiel-Chat eines Kontakts (Ergänzung 2, 3.4); wird über `MessagesRoute` gelegt |

Übergänge:
- `StartGate` → `pushReplacement` auf Onboarding (Schritt aus dem Speicher, UI-16) oder Home (Onboarding abgeschlossen).
- Gespeicherte Daten unlesbar oder unbekanntes Schema (N-12): Daten verwerfen (`deleteAll`), `OnboardingRoute(step: 0, notice: neustart)`. Snackbar über der Mikrofon-Zeile: „Deine gespeicherten Daten waren nicht lesbar. Du startest neu." (4 s, ohne Aktion, Muster wie „Alle Daten sind gelöscht.") – Text und Form A-34.
- Onboarding Schritt 4 „Weiter" → `pushAndRemoveUntil(HomeRoute, (_) => false)`; Home öffnet auf Tab **Pfad** (A-1), Manny-Begrüßung (Anlass Begrüßung).
- Löschen bestätigt → `pushAndRemoveUntil(OnboardingRoute(step: 0, notice: gelöscht), (_) => false)` (Ergänzung 3.2, UI-51). Damit sind Sheet, Dialog, Home und alle Tab-States entfernt; der `AppController` setzt seinen Zustand auf `AppState.initial()` und verwirft Schnappschuss, Timer und offene Hinweise.
- Manny-Chat und Nachrichten werden aus `HomeShell` per `push` über die `HomeRoute` gelegt (Einstieg: Button-Gruppe auf Pfad/Heute, Manny auf dem Pfad). Der Beispiel-Chat wird über die Nachrichten gelegt; Zurück führt in die Übersicht, danach auf den Tab, von dem aus geöffnet wurde (der Tab bleibt im `IndexedStack` unverändert, UI-80). Vor dem `push`: Rückgängig-Fenster beenden, Snackbar schließen, `NodeHint` schließen, sichtbare Blase schließen (zählt als gezeigt) (Ergänzung 2 K11, 3.1; UI-39, UI-86).
- Tabwechsel ist **keine** Route; Tabs bleiben im `IndexedStack` erhalten (Scrollposition). Der inaktive Tab läuft in `TickerMode(enabled: false)`, damit keine Animation im Hintergrund weiterläuft (UI-8); Timer des inaktiven Tabs (Snackbar, `NodeHint`) werden beim Tabwechsel beendet.

### 4.2 Fortsetzen nach Neustart (UI-16, UI-43, UI-51)
- Jede Eingabe im Onboarding (Name, Typ, Freitext, Datum, aktueller Schritt) wird sofort persistiert. Neustart setzt beim gespeicherten Schritt fort, Eingaben vorbefüllt.
- Consent: wird beim Tippen auf „Verstanden, weiter" gespeichert. Geht der Nutzer zurück und bestätigt erneut, wird der Zeitstempel überschrieben (A-2).
- Nach Abschluss startet die App immer auf Home/Tab Pfad (A-1).

### 4.3 Zurück-Verhalten (Android-Taste, Escape, Web)
Umsetzung mit `PopScope(canPop: false, onPopInvokedWithResult: …)` auf Onboarding und Home. Reihenfolge (N-6, N-13):

| Ort | 1. offen? schließen | 2. sonst |
|---|---|---|
| Sheet/Dialog/Datumsauswahl | Route wird gepoppt (Sheet „Deine Daten" mit Änderungen: Verwerfen-Dialog statt Schließen; Löschdialog während des Löschens gesperrt, 6.1) | – |
| Onboarding | **nichts** – Mannys Blase zählt im Onboarding nicht als offenes Overlay (N-13) | Schritt 2–4: einen Schritt zurück (Eingaben bleiben, Seitenwechsel in Gegenrichtung). Schritt 1: App schließen (`SystemNavigator.pop`) |
| Home, Tab Heute | (Heute hat keine Blase/Hinweise) | Wechsel auf Tab Pfad (beendet ein Rückgängig-Fenster, Ergänzung 3.3 Punkt 5) |
| Home, Tab Pfad | Manny-Blase oder `NodeHint` sichtbar → schließen | App schließen (`SystemNavigator.pop`) |
| Manny-Chat, Nachrichten, Beispiel-Chat | – (keine Overlays) | Route schließen (`canPop: true`); Beispiel-Chat → Nachrichten → Tab (UI-80, UI-86) |

- Snackbars werden von Zurück nicht gesondert behandelt; auf Heute führt Zurück zum Pfad, wodurch die Snackbar endet.
- Escape: Sheets/Dialoge über die Standard-`DismissIntent` der Modal-Routen (geht durch `PopScope`). Die Vollbild-Routen bekommen in `ChatScreenScaffold` ein eigenes `Shortcuts`/`Actions`-Paar Escape → `maybePop`, weil `DismissIntent` nur Modal-Routen schließt (in U2c per Test bestätigen). Blase und `NodeHint` über eigene `Shortcuts`/`Actions`. Die Snackbar schließt mit Escape (Ergänzung 3.3 Punkt 5). Im Onboarding schließt Escape die Blase (Brief 8), die Zurück-Taste nicht (N-13).
- iOS: `SystemNavigator.pop` ist dort wirkungslos; iOS hat keine Zurück-Taste, das ist erwartetes Verhalten.
- **Web (n6):** Flutter Web leitet den Browser-Zurück-Button an `popRoute` weiter; damit gilt dieselbe Tabelle wie für Android. Festgelegtes Verhalten: Browser-Zurück = Android-Zurück; auf Pfad bzw. Schritt 1 bleibt die Seite stehen (`SystemNavigator.pop` ist im Web wirkungslos). Prüfung in U2b mit Playwright `page.goBack()` (Onboarding Schritt 3 → 2, Heute → Pfad). Weicht das Web ab, wird das dokumentiert; maßgeblich bleiben die Widget-Tests mit `handlePopRoute`.
- Android 14+ „Predictive Back": mit `canPop: false` keine Vorschau-Animation; gewollt, weil die Aktion kontextabhängig ist.

### 4.4 Sheets und Dialoge
- **`CuraSheetRoute`** (eigene `PopupRoute` statt `showModalBottomSheet`). Grund (im SDK geprüft): Beim Wegwischen ruft `showModalBottomSheet` direkt `Navigator.pop` auf und umgeht `PopScope`; Ergänzung 3.2 verlangt den Verwerfen-Dialog auch beim Wegwischen. Die eigene Route ruft beim Wischen und beim Scrim-Tipp `Navigator.maybePop` auf.
  - **Wischgeste (n5):** Die vertikale Ziehgeste liegt nur auf dem fixen Kopf (Titelzeile inkl. Fläche oberhalb) des Sheets, nicht auf dem Scrollbereich; dadurch kein Gestenkonflikt mit dem inneren Scrollen. Schließen ab 30 % der Sheet-Höhe oder Fling > 700 dp/s nach unten, sonst zurückfedern (`dur-base`, RM: sofort). Test: Fling auf dem Kopf schließt (bzw. öffnet Verwerfen-Dialog), Fling im Scrollbereich scrollt nur den Inhalt.
  - Übergang: Schiebung `dur-base`; bei reduzierter Bewegung Einblenden ≤ `dur-fast` ohne Schiebung. Scrim-Farbe aus Token `scrim`. Fläche mit `CuraBlur` (zählt zum Blur-Budget), bei HC opak.
- **`CuraDialogRoute`**: Scrim `scrim`, Einblenden `dur-base` (RM: ≤ `dur-fast`), kein Skalieren, kein Blur. Scrim → `maybePop`.
- Routennamen für Screenreader (`namesRoute`/`scopesRoute`): „Deine Daten", „Wie willst du trainieren?", „Eigene Übung", „Alles löschen?" und „Änderungen verwerfen?" (beide als `alertdialog`-Semantik über `SemanticsRole.alertDialog`, in Flutter 3.47 vorhanden).
- Fokus: Beim Öffnen bekommt die Route einen eigenen `FocusScope`; Startfokus im Dialog auf der sicheren Aktion (`autofocus`). Screenreader-Fokus beim Öffnen von „Deine Daten" auf dem Titel (Routenname), Tastatur-Reihenfolge beginnt mit „Schließen" (A-30; laut ui-designer kein Konflikt). Beim Schließen: `await route.popped; if (trigger.context?.mounted ?? false) trigger.focusNode.requestFocus();` – der Auslöser kann durch Tageswechsel oder Löschen nicht mehr existieren (n5).
- **`CuraFullscreenRoute`** (Chat, Nachrichten, Beispiel-Chat): opake `PageRoute`, Übergang Einblenden + 24 dp Schiebung von rechts (`dur-base`, `curve`); RM: Einblenden ≤ `dur-fast`, keine Schiebung (Ergänzung 2, 2.1, 4). Kein Scrim, kein Blur. Routennamen „Manny, Chat“, „Nachrichten“, „Beispiel-Chat [Name]“. **Anfangsfokus** auf dem Zurück-Pfeil (`autofocus`), Screenreader liest zuerst den Titel (Kopf vor dem Zurück-Pfeil in der Semantik-Reihenfolge per `OrdinalSortKey`, sichtbare Tastatur-Reihenfolge beginnt beim Zurück-Pfeil). **Fokusrückgabe** an das auslösende Element (Manny-Button, Nachrichten-Button, Kontaktzeile) mit `mounted`-Prüfung wie oben; wurde über Manny auf dem Pfad geöffnet (keine eigene Fokusstation), geht der Fokus an den Manny-Button (A-38).
- Heute-Routen werden im `HomeShell` registriert, damit der Tageswechsel genau diese schließen kann (`navigator.removeRoute`); „Deine Daten" bleibt offen (Ergänzung 3.4, UI-44). Ausnahme Trainings-Sheet bei Eintrag über Mitternacht: 7.5.

### 4.5 Screens (Kurzüberblick, Details im Brief)
- **Gemeinsam:** `ContentFrame` (B-3, Brief 7): Inhalte volle Breite bis 560 dp, darüber mittig auf 560 dp begrenzt; Hintergrund und Glow laufen über die volle Breite. Die `FloatingNav` und fixe Buttons liegen innerhalb des Rahmens.
- **Onboarding** (Brief 6.1): gemeinsames Layout, Schritte 1–4, `StepProgress`, Manny + Blase, `MicButton`-Zeile, fester Primärbutton über Tastatur (`Scaffold.resizeToAvoidBottomInset`), Inhalt scrollt, Snackbar-Platz über der Mikrofon-Zeile. Seitenwechsel als `SlideTransition` 24 dp + Einblenden (`dur-base`), bei Zurück in Gegenrichtung; RM: Sofortwechsel (B-8).
- **Pfad** (Brief 6.2, Ergänzung 1 3.1/3.5, Ergänzung 2 3.1): `PathHeader` (fix), Pfad scrollt darunter (Zukunft oben, oben/unten gepolstert, 7.3), Manny auf aktueller Unit (antippbar → Manny-Chat), Blase, `NodeHint`, keine Snackbar; unten links frei, unten rechts nur die Button-Gruppe (UI-24 neu).
- **Manny-Chat, Nachrichten, Beispiel-Chat** (Ergänzung 2, 3.2–3.4): Vollbild-Routen über `ChatScreenScaffold`, ohne Nav und ohne Button-Gruppe, Glow wie auf den anderen Screens, 0 `BackdropFilter`.
- **Heute** (Brief 6.3, Ergänzung 1 3.3/3.4, Ergänzung 2 K3–K5): Datum, „Heute, [Name]", Segment, TERMINE, ÜBUNGEN · CA. N MIN, „+ Eigene Übung", feste **Primärbutton-Reihe** über der Nav („Training starten“ + Manny-Button), Nachrichten-Button rechtsbündig 8 dp darüber, Snackbar 12 dp über der Button-Gruppe (Oberkante Nachrichten-Button), Scroll-Reserve am Listenende (4.6).
- **Deine Daten** (Ergänzung 3.2): Sheet mit fixem Kopf und fixer Fußleiste, Scrollbereich dazwischen.

### 4.6 Button-Gruppe, Manny-Tipp, Scroll-Reserven (Ergänzung 2, 3.1)
- **Sichtbarkeit:** nur in `HomeShell` (Tabs Pfad und Heute), und dort **nur im Standard-Zustand des jeweiligen Tabs** (Festlegung A-43, v1.3): In den Zuständen Laden (`path-loading`, `today-loading`) und Fehler (`path-error`, `today-error`) wird die Gruppe nicht gebaut (der Chat braucht den Namen aus dem geladenen Zustand; Fehler-/Ladeansicht bleibt ohne Zusatz-Bedienung). Der `StartGate`-Fehler liegt vor der `HomeRoute`, dort gibt es keine Gruppe. Nicht im Onboarding (eigene Route ohne Gruppe), nicht in den Vollbild-Routen (die `HomeRoute` ist verdeckt). Unter Sheets und Dialogen liegt sie unter dem Scrim; `ModalBarrier` blockiert die Semantik darunter, der neue `FocusScope` hält den Tastaturfokus in der Modal-Route (UI-70: per Test bestätigen: keine Semantik-Knoten der Gruppe und kein Fokus bei offenem Sheet/Dialog).
- **Ebene:** Die Gruppe liegt über dem Scrollinhalt, neben der Nav und unterhalb aller Routen. Konkret: `HomeShell`-`Stack` = [Tab-Inhalt (`IndexedStack`), Pfad-`ActionCluster` (nur bei Tab Pfad), `FloatingNav`]; auf Heute ist der Manny-Button Teil der fixen Primärbutton-Reihe von `TodayScreen`, der Nachrichten-Button sitzt rechtsbündig 8 dp darüber (gleiches Widget `ActionCluster` im Modus `today`).
- **Positionen:** Pfad: rechts 16 dp, Manny-Button 16 dp über der Nav-Oberkante, Nachrichten-Button rechtsbündig 8 dp darüber. Heute: Der Nachrichten-Button sitzt **8 dp über der Oberkante des Manny-Buttons** (UI-71), nicht über der Oberkante der Reihe; bricht „Training starten“ um, ist die Reihe höher als 56 dp, der Manny-Button bleibt unten bündig und der Nachrichten-Button folgt ihm (Position aus dem Rechteck des Manny-Buttons, per `CompositedTransformFollower` bzw. aus der gemessenen Reihenhöhe minus 56 dp). Die Scroll-Reserve von 56 dp (UI-31) bleibt davon unberührt, weil der Nachrichten-Button dann neben dem höheren Primärbutton liegt. Heute: Reihe = `PillButton` Primär (Breite = verfügbare Breite − 56 − 8; bei 320 dp genau 224 dp) + 8 dp + Manny-Button 56 dp, `CrossAxisAlignment.end` (unten bündig; nur der Primärbutton wächst bei Umbruch). Positionen innerhalb des `ContentFrame`.
- **Scroll-Reserven aus gemessenen Höhen** (nicht aus festen Pixelwerten; Messung per `LayoutBuilder`/`SizeChangedLayoutNotifier` der Reihe und der Nav):
  - Heute (UI-31 neu): Reserve am Listenende = Höhe der Primärbutton-Reihe + Nav-Höhe inkl. Abstand + 16 dp + 56 dp (Nachrichten-Button 48 + 8).
  - Pfad (UI-75): `padBottom` = max(7.3-Zentrier-Polster, Nav inkl. Abstand + 16 + 56 + 8 + 48 + 16 dp), damit die unterste Unit über die Gruppe geschoben werden kann.
- **Snackbar auf Heute:** 12 dp über der Oberkante des Nachrichten-Buttons, 16 dp Seitenrand; verdeckt nur Listeninhalt (UI-37/41 präzisiert, UI-73).
- **Manny-Tipp auf dem Pfad (UI-59 neu, UI-74):** `MannyPlaceholder` ist auf dem Pfad nicht mehr `IgnorePointer`. Eigener Hit-Bereich: gezeichnete Form (Pfad aus dem Painter) + 8 dp Rand, mindestens 48 × 48 dp, **unten abgeschnitten an der Standlinie** (Fußunterkante); umgesetzt per `CustomPainter.hitTest` bzw. eigener `RenderBox.hitTestSelf`, nicht als `GestureDetector` über der Unit. `GestureDetector(excludeFromSemantics: true)`, `ExcludeFocus` → keine eigene Fokusstation, kein Semantik-Button; das Bild-Label „Manny, dein Begleiter“ bleibt. Pressed: Form 10 % heller (keine Animation, keine Pose-Änderung). Tipp schließt eine sichtbare Blase (zählt als gezeigt) und öffnet den Manny-Chat; Tab bleibt. Die Unit reagiert nur außerhalb der Manny-Fläche (Ergänzung 1 3.5 neuer Satz). Onboarding-Manny und Manny im Button/Chat sind nicht als Chat-Einstieg tippbar.
- **Kollisionen:** `MannyBubble` wechselt über Manny, wenn sie rechts weniger als 8 dp über der Oberkante des Nachrichten-Buttons enden würde; `NodeHint` weicht nach oben bzw. links aus, Pfeil bleibt an der Unit. Beide prüfen gegen das Rechteck der Gruppe (vom `ActionCluster` per `GlobalKey` bereitgestellt) (UI-75).
- **Rückfall, wenn kein Platz ist (MINOR-5, v1.3; Worst Case 320×568 bei 200 %):** Blase: Reihenfolge rechts → über Manny → **Pfad scrollt** per `jumpTo` (RM) bzw. kurzer Animation so weit nach unten, dass über Manny Platz ist (die Blase gilt erst nach dem Scrollen als erschienen) → reicht auch das nicht (Blase höher als die freie Fläche zwischen Kopfzeile und Gruppe), wird die Blase über Manny gesetzt, auf die freie Fläche begrenzt und ihr Inhalt scrollt intern; sie überdeckt die Gruppe nie. `NodeHint`: oben → unten → links neben der Unit (bei Units der rechten Bahn) → Pfad scrollt die Unit in die obere Hälfte und setzt den Hinweis darunter → als Letztes auf die freie Fläche begrenzt mit innerem Scrollen. Alle Stufen sind deterministisch und per W-Test für `path-cluster-bubble`/`path-cluster-hint` bei 320×568 und Skalierung 2,0 abgedeckt.
- **Fokusreihenfolge** (Ergänzung 2, 4) per `FocusTraversalGroup` + `OrderedTraversalPolicy`: Pfad: Kopf (Text, Freeze, Streak, „Deine Daten“), Units, Nachrichten-Button, Manny-Button, Nav. Heute: Kopf, Zeitwahl, Karten und Aktionen, „Eigene Übung“, Nachrichten-Button, „Training starten“, Manny-Button, Nav.
- **Tageswechsel bei offenem Chat/Nachrichten:** `HomeShell` erkennt den Wechsel weiterhin über `onResume`; die Snackbar „Neuer Tag, neues Programm.“ erscheint nur, wenn Tab Heute aktiv **und** `HomeRoute` die oberste Route ist. Sonst zeigt Heute beim Zurückkehren das neue Datum ohne Snackbar (Ergänzung 2, 3.1, A-5 dort). Die Ansage „Neuer Tag. …“ entfällt dann ebenfalls (A-39, vom ui-designer bestätigt).
- **Reihenfolge beim Tageswechsel auf Heute (MINOR-3, v1.3), auch beim Eintrag über Mitternacht:** (1) Zustand anwenden (bei Mitternacht: erst Eintrag für `openedDay`, dann `rollover`, 7.5); (2) **alle registrierten Heute-Routen schließen** (Trainings-Sheet, „Eigene Übung“; `removeRoute` bzw. `pop` des Sheets) und das Ende der Entfernung abwarten (nächster Frame); (3) **dann** prüfen: Tab Heute aktiv **und** `HomeRoute` oberste Route; (4) nur wenn (3) zutrifft: Snackbar „Neuer Tag, neues Programm.“ und Ansage. Ist „Deine Daten“ oder eine Vollbild-Route offen, ist (3) falsch → keine Snackbar. Test: Sheet offen, FakeClock +1 Tag, „Training eintragen“ → Sheet zu, danach Snackbar sichtbar; mit zusätzlich offenem Chat → keine Snackbar.

---

## 5. State-Management

**Ansatz:** Bordmittel. Ein `AppController extends ChangeNotifier` hält den unveränderlichen `AppState`, eine `Clock`, einen `StateStore`, eine `MannyTextSource` (KS-1) und eine `List<DataEraser>` (KS-9), alle per Konstruktor injiziert. Die `MannyChatSource` (KS-5) gehört nicht in den Controller (nichts wird gespeichert) und wird über ein eigenes `InheritedWidget` (`ChatSourceScope`) bereitgestellt. Bereitstellung über `AppScope extends InheritedNotifier<AppController>`. Screens lesen per `AppScope.of(context)`. Reine UI-Zustände (Textfeld-Entwurf im Sheet, offene `NodeHint`, Snackbar-Timer, Fokus) liegen in `State`-Objekten der Screens bzw. in `TransientUi` (zweiter, nicht persistierter `ChangeNotifier`).

**Begründung:**
- Umfang: ein Gerät, ein Nutzer, ein Zustandsdokument, keine Netzwerk-Streams. `ChangeNotifier` reicht und kostet keine Abhängigkeit (Rollenvorgabe „Pakete nur mit Grund", Brief 9).
- Testbarkeit: Uhr und Store werden im Konstruktor injiziert; die Logik liegt in reinen Funktionen (Abschnitt 7), der Controller ist dünn.
- Löschen ohne Altlasten (Ergänzung 5): genau ein langlebiger Zustandshalter; `deleteAll()` setzt ihn zurück, alle anderen Zustände hängen an Routen, die `pushAndRemoveUntil` entfernt.
- Wachstum: Kommt ein Backend, tritt eine Repository-Schicht hinter `StateStore`; ein späterer Umstieg auf Riverpod o. Ä. bleibt möglich.
- Verworfen: Riverpod/Bloc/Provider (zusätzliche Abhängigkeit ohne Mehrwert in diesem Umfang).

**Controller-Methoden:**
`load()`, `retryLoad()`; Onboarding: `setName`, `setStep`, `acceptConsent`, `selectInjury`, `setInjuryOther`, `setInjuryDate`, `completeOnboarding`; Heute: `selectTime`, `swapExercise`, `removeExercise` → Undo-Token, `undoRemove`, `addCustomExercise`, `logTraining({required LocalDay forDay})` → `TrainingResult {snapshot?, dayChanged}`, `undoTraining(snapshot)`; Tag: `checkDayChange()` → `DayChangeResult`; Pfad: `onPathVisible()` → nächste Blase/Feier, `markBubbleShown`, `consumeCelebration`; Profil: `updateProfile(ProfileDraft)` → `ProfileUpdateResult {nameChanged, pathRecomputed}`; `deleteAll()` (ruft die Löscher der Reihe nach, 6.3).

**Undo-Fenster (MINOR-7b, v1.3):** Fenster, Timer und Schnappschuss-Halter liegen ausschließlich in `TransientUi`; es gibt genau **eine** Methode `TransientUi.endUndoWindow()`, die Tabwechsel, Tageswechsel, eine neue Snackbar und das Öffnen von Chat/Nachrichten gleichermaßen aufrufen. Eine eigene Controller-Methode `beforeOpenFullscreen()` gibt es nicht (v1.2 gestrichen); `HomeShell` ruft vor dem `push` `endUndoWindow()`, schließt `NodeHint` und Blase.

**Tageswechsel zuerst (N-11):** Jede mutierende Methode ruft als Erstes `checkDayChange()` auf (gemeinsamer Wrapper `_mutate`). Einzige Ausnahme ist `logTraining(forDay)` mit `forDay` < heute (Eintrag über Mitternacht, 7.5): dort wird erst der Eintrag für `forDay` angewendet, danach der Tageswechsel. Liefert `checkDayChange()` einen Wechsel, bekommt die UI ihn als Ergebnis (Snackbar, Routen schließen, Undo beenden), bevor die eigentliche Aktion auf dem neuen Tag wirkt. Tests: jede mutierende Methode mit FakeClock einen Tag weiter → Wechsel wird zuerst angewendet.

**Persistenz:** Nach jeder Zustandsänderung wird das ganze Dokument geschrieben (< 5 KB) über eine serielle Schreibschlange. Schreibfehler außer beim Löschen: keine UI (Brief), Zustand bleibt im Speicher, nächster Schreibvorgang versucht es erneut; Debug-Log (A-4).

---

## 6. Datenmodell und lokale Speicherung

### 6.1 Dokument, Schlüssel `curaone.state.v1`

```jsonc
{
  "schema": 1,
  "onboarding": {
    "completed": false,
    "step": 0,                       // 0..3 = Schritt 1..4
    "name": "",                      // ungetrimmt gespeichert, Prüfung auf trim()
    "injuryType": null,              // "acl" | "ankle" | "muscle" | "other"
    "injuryOther": "",               // Freitext bei "other", optional
    "injuryDate": null               // "YYYY-MM-DD" (lokales Datum)
  },
  "consent": null,                   // { "acceptedAt": "2026-10-07T08:12:30.123Z" (UTC, ISO 8601), "version": "prototype-0" }
  "streak": {
    "count": 0,
    "freezes": 2,                    // Startwert 2, max 2, kein Verdienen (N-1)
    "lastTrainingDay": null,         // "YYYY-MM-DD"
    "evaluatedThrough": null,        // letzter vollständig ausgewerteter Tag
    "coveredInGap": 0,               // per Freeze gedeckte verpasste Tage in der aktuellen Lücke
    "uncoveredInGap": 0,             // ungedeckte verpasste Tage in der aktuellen Lücke
    "resetNoticePending": false      // Manny-Neustart-Nachricht fällig
  },
  "path": {
    "completedUnitIds": [],          // zusätzlich zur Datumsableitung erledigte Units (7.2)
    "pulsePending": null             // Unit-ID für einmaligen Ring-Puls (gehört zur Feier)
  },
  "day": {
    "dayKey": "2026-10-07",          // EINZIGE Quelle für den „zuletzt gesehenen Tag" (kein separates lastSeenDay)
    "removed": [],
    "swaps": {},                     // Basis-ID -> Anzahl Tausch-Schritte
    "custom": [],                    // [{ "id", "name", "reps", "minutes" }]
    "done": false
  },
  "prefs": { "timeChoice": 20 },     // 10 | 20 | 30; 20 nur bei Erststart/nach Löschen (N-8)
  "manny": {
    "lastShown": {},                 // Anlass -> "YYYY-MM-DD"
    "greetingPending": false
  },
  "celebration": null                // { "day": "YYYY-MM-DD", "streak": 13, "unitId": "w5-d3" }
}
```

Änderung gegenüber v1: `lastSeenDay` entfällt; `day.dayKey` ist die einzige Quelle für den Tageswechsel (NITPICK reviewer).

**Nicht persistiert (bewusst):** Rückgängig-Schnappschuss und -Fenster, Undo-Daten für „Entfernt", offene Blase/`NodeHint`, Snackbar. Ein App-Neustart beendet das Fenster (A-5).

### 6.2 Versionierung, Migration, Lesetoleranz (N-12)
- **Versionsregel:** `schema` wird erhöht bei jeder inkompatiblen Änderung (Feld umbenannt/entfernt, Typ oder Bedeutung geändert). Ein **neues optionales** Feld mit Standardwert erhöht die Version nicht.
- **Migrationskette:** `migrations.dart` enthält `Map<int, Json Function(Json)>` (n → n+1). Beim Laden: `while (schema < kCurrentSchema) json = migrations[schema]!(json)`. Für jede Schemaversion liegt ein gespeichertes Beispieldokument in `test/fixtures/state_v<n>.json`; ein Test lädt jedes Fixture und prüft das erwartete `AppState`.
- **Lesetoleranz:** Fehlende optionale Felder → Standardwert (`AppState.initial()`-Werte). Unbekannte zusätzliche Felder → ignoriert. Fehlende Pflichtfelder (`schema`, `onboarding.completed`, `onboarding.step`), falscher Typ, ungültiges Datum, `schema` > `kCurrentSchema` oder ohne Migration, kein gültiges JSON → **unlesbar**.
- **Unlesbar → automatisch neu starten:** Daten verwerfen (`deleteAll`), Onboarding Schritt 1 mit Hinweis (4.1, A-34). Kein Fehlerzustand mit „Nochmal versuchen" für diesen Fall.
- **Fehler der Plattform beim Lesen** (Exception aus `shared_preferences`, nicht der Inhalt): Fehlerzustand mit „Nochmal versuchen" (Brief 6.2 Pfad / 6.3 Heute), weil die Daten möglicherweise intakt sind. Da vor dem Lesen unklar ist, ob das Onboarding abgeschlossen war, zeigt `StartGate` diesen Fehlerzustand im Pfad-Layout (A-6 neu).
- Tests: Fixture v1 lädt; fehlendes optionales Feld → Standard; zusätzliches Feld → ignoriert; kaputtes JSON, `schema: 99`, fehlendes Pflichtfeld → Neustart-Pfad (Store geleert, Onboarding Schritt 1, Hinweis); Lese-Exception → Fehlerzustand; Roundtrip `toJson`/`fromJson` aller Felder inkl. `coveredInGap`, `uncoveredInGap`, `evaluatedThrough` (n2).

### 6.3 Store und Löschen
- `abstract class StateStore { Future<AppState?> load(); Future<void> save(AppState s); Future<void> deleteAll(); }`
- `PrefsStateStore` mit `SharedPreferencesAsync`. **Feste Schlüsselliste** `kAllStorageKeys = {'curaone.state.v1'}` (wächst mit jeder neuen Schlüssel-Einführung); `deleteAll()` ruft `clear(allowList: kAllStorageKeys)` – `SharedPreferencesAsync.clear` arbeitet mit exakten Schlüsseln, nicht mit Präfixen (n4).
- **Löscher-Liste (KS-9):** `abstract class DataEraser { Future<void> eraseAll(); }` in `lib/data/data_eraser.dart`; `PrefsStateStore` implementiert ihn. Der `AppController` erhält `List<DataEraser>` per Konstruktor; im ersten Ausschnitt **genau ein** Löscher (der Store). Reihenfolge = Listenreihenfolge, der erste Fehler bricht ab. Kein Chat-Speicherschlüssel (KS-7 entfällt; Chat und Nachrichten speichern nichts, `kAllStorageKeys` unverändert, UI-82). Risiko für später (R-9): Bei mehreren Löschern kann ein Fehler im zweiten einen Teil-Löschstand hinterlassen; im ersten Ausschnitt ausgeschlossen.
- **Ablauf `deleteAll()` im Controller (n4):** (1) Flag `_deleting = true`, neue Schreibaufträge werden ab jetzt verworfen; (2) auf das Leerlaufen der seriellen Schreibschlange warten; (3) alle `DataEraser` der Reihe nach (`eraseAll()`); (4) Erfolg: Zustand `AppState.initial()`, Transientes verwerfen, Navigation (4.1), `_deleting` bleibt bis zum Neuaufbau gesetzt; (5) Fehler: RAM-Zustand **unverändert**, `_deleting = false`, Schreiben wieder erlaubt, Fehler an den Dialog.
- **Sperren während des Löschens (n4):** Solange `busy`: Zurück/Escape/Scrim wirkungslos (`PopScope(canPop: false)`, Barriere ignoriert), „Ja, alles löschen" deaktiviert (ab 300 ms zusätzlich Fortschrittskreis), Doppeltipp löst nur einen Vorgang aus.
- Testvarianten: `InMemoryStore`, `FailingStore` (wirft bei `load`/`deleteAll`), `SlowStore` (Completer), `CorruptStore` (liefert vorgegebenen Rohtext).
- Sicherheit: Speicher unverschlüsselt; vertretbar für den Prototyp ohne echte Patientendaten. Vor Echtbetrieb verschlüsselte Speicherung im Datenschutz-Konzept entscheiden (R-3).

### 6.4 Zeit und Datum
- `typedef Clock = DateTime Function();` – Produktion `DateTime.now`, Tests `FakeClock`. Standard-Fixture 2026-10-07 = **Mittwoch** (das Mockup „Dienstag, 7. Oktober" ist nur Orientierung).
- `LocalDay` (Jahr, Monat, Tag); Arithmetik über `DateTime.utc(y, m, d)`, damit Sommerzeitwechsel keine Tage verschieben. Tageswechsel = `LocalDay.from(clock()) != day.dayKey` (jede Abweichung, auch rückwärts und durch Zeitzonenwechsel, Ergänzung 7.2).
- Consent-Zeitstempel als UTC-ISO-8601.
- Deutsche Datumsformate per eigener, getesteter Funktion („Mittwoch, 7. Oktober", „3. September 2026").

---

## 7. Reine Dart-Logik (unit-testbar, `lib/logic/`)

Regel: Kein Import aus `package:flutter`, keine Plattform-Aufrufe; alle Funktionen bekommen `today`/`now` als Parameter. Statischer Test prüft das (12.3, Regel 7).

### 7.1 Streak (`streak.dart`) – Regel vom Nutzer bestätigt (N-1, N-10)

1. Ein Tag gilt als verpasst, wenn er vollständig vergangen ist (vor `today`) und an ihm kein Training eingetragen wurde. Der laufende Tag ist nie verpasst.
2. Verpasste Tage einer Lücke (seit dem letzten Trainingstag) werden **chronologisch** ausgewertet: Ist ein Freeze vorhanden, wird er für diesen Tag verbraucht (gedeckt). Sonst ist der Tag ungedeckt.
3. Reset auf 0 beim **2. ungedeckten** verpassten Tag der Lücke. Ein einzelner ungedeckter Tag wird toleriert (Spec 3: „friert 24 h ein").
4. Anzeige „eingefroren", solange die Lücke mindestens einen verpassten Tag hat und kein Reset erfolgt ist (gedeckt oder toleriert); auch „1 verpasster Tag ohne Freeze" → „eingefroren", Freezes 0.
5. Verbrauchte Freezes werden nicht erstattet.
6. Bei Streak 0 keine Freeze-Nutzung und kein „eingefroren" (A-8). Anzeige wie „Reset" (Zahl 0, Flamme `text-3`).
7. Nach einem Reset ist die Lücke abgeschlossen: weitere Auswertungen verbrauchen keine Freezes und erzeugen keine weitere Neustart-Nachricht (bis wieder trainiert wird).
8. `logTraining(s, day)` **wertet intern zuerst bis `day` aus** (N-11) und erhöht dann: liegt `day` nach `lastTrainingDay`: `count + 1` (nach Reset 1), Lücke zurückgesetzt, Zustand aktiv. Am selben Tag nur einmal (idempotent).
9. Auswertung ist idempotent und holt beliebig viele Tage nach; gespeichert wird `evaluatedThrough`.
10. Uhr rückwärts (`today < lastTrainingDay` oder `< evaluatedThrough`): keine Auswertung, kein Verbrauch; Eintragen erhöht den Streak nicht (A-9, Details 7.5).
11. `resetNoticePending = true` beim Reset aus `count > 0`.

**API:** `StreakState evaluate(StreakState s, LocalDay today)`; `StreakState logTraining(StreakState s, LocalDay day)`; `StreakView view(StreakState s)` → `{count, freezes, display: active|frozen|reset}`.

**Unit-Testfälle (Pflicht):** (`L` = letzter Trainingstag, `T` = heute)

| # | Ausgang | Ereignis | Erwartung |
|---|---|---|---|
| S1 | neu: count 0, freezes 2 | 3 Tage ohne Training | count 0, freezes 2, display reset |
| S2 | count 5, L = T−1 | auswerten | aktiv 5, freezes 2 |
| S3 | count 5, L = T−1 | eintragen; nochmal eintragen | 6; zweites Eintragen ändert nichts |
| S4 | count 5, L = T−2, freezes 2 | auswerten | frozen, 5, freezes 1 |
| S5 | count 5, L = T−2, freezes 0 | auswerten | frozen, 5, freezes 0 |
| S6 | count 5, L = T−3, freezes 0 | auswerten | reset 0, resetNoticePending |
| S7 | count 5, L = T−3, freezes 2 | auswerten | frozen, 5, freezes 0 |
| S8 | count 5, L = T−3, freezes 1 | auswerten | frozen, 5, freezes 0 |
| S9 | count 5, L = T−4, freezes 1 | auswerten | reset 0, freezes 0 |
| S10 | count 5, L = T−4, freezes 2 | auswerten | frozen, 5, freezes 0 |
| S11 | S4-Ergebnis | eintragen | aktiv 6, freezes 1 |
| S12 | beliebig | zweimal am selben Tag auswerten | identisch, kein Doppelverbrauch |
| S13 | count 5, L = T−4, freezes 1 | tageweise auswerten vs. einmal bei T | identisch |
| S14 | Reset (count 0) | eintragen | count 1, aktiv |
| S15 | L = 2026-10-24, T = 2026-10-26 (Sommerzeitende) | auswerten | genau 1 verpasster Tag |
| S16 | L = T+1 (Uhr zurückgestellt) | auswerten/eintragen | unverändert |
| S17 | count 0, L = T−5 | auswerten | keine Freezes verbraucht, kein frozen |
| S18 | Schnappschuss vor Eintragen bei Zustand frozen | Rückgängig | identisch zum Zustand vorher |
| S19 | count 5, L = T−2, freezes 2, **ohne** vorheriges `evaluate` | eintragen | intern ausgewertet: freezes 1, count 6, aktiv (n2) |
| S20 | L = 2026-03-28, T = 2026-03-30 (Sommerzeitbeginn 29.03.) | auswerten | genau 1 verpasster Tag |
| S21 | L = 2028-02-28, T = 2028-03-01 (Schalttag 29.02.) | auswerten | genau 1 verpasster Tag |
| S22 | L = 2026-12-31, T = 2027-01-02 (Jahreswechsel) | auswerten | genau 1 verpasster Tag |
| S23 | count 5, L = T−7, freezes 2 | auswerten | 2 gedeckt, Reset am 4. verpassten Tag; count 0, freezes 0, resetNoticePending; erneutes `evaluate` am Folgetag: keine Änderung, keine zweite Nachricht |
| S24 | JSON-Roundtrip | `toJson`/`fromJson` mit `coveredInGap`, `uncoveredInGap`, `evaluatedThrough` gesetzt | identisch |
| S25 | Uhr zurückgestellt + Tageswechsel (7.5) | eintragen | Programm des Tages `done`, Streak unverändert, keine Unit, keine Feier |

Zeitzonenwechsel nach Osten (z. B. Reise) kann einen Kalendertag überspringen; der übersprungene Tag zählt dann als verpasst (Freeze oder Toleranz). Als Risiko R-8 benannt, keine Sonderlogik im Prototyp.

### 7.2 Pfad-Generator (`path_generator.dart`, `path_model.dart`)

**Beispielpfad (Platzhalter, Brief 6.2, A-10):** 12 Wochen, 3 Phasen à 4 Wochen. Je Woche: 3 Trainingstage (klein), 1 Wochenziel (mittel). Am Ende jeder Phase (Woche 4, 8, 12) eine große Unit „Phasen-Abschluss". Danach die Boss-Unit „Return to Sport" (Woche 12). Reihenfolge je Woche: Tag 1, Tag 2, Tag 3, Wochenziel, ggf. Phasen-Abschluss. Gesamt 52 Units. Gleich für alle Verletzungstypen (N-3), immer mit Label „Beispielpfad" – **auch für ACL** (UI-25; bewusste Abweichung vom Mockup, das kein Label zeigt). Konstante `kSamplePathIsPlaceholder = true`.

IDs stabil: `w{W}-d{1..3}`, `w{W}-goal`, `p{P}-end`, `boss`.

**Aktuelle Woche:** `W = floor((today − injuryDate) / 7) + 1`, begrenzt auf 1…12; Datum in der Zukunft (Uhr zurückgestellt) → W = 1. **Phase** = `ceil(W / 4)`.

**Status je Unit:**
- erledigt ⇔ `unit.week < W` **oder** `unit.id ∈ completedUnitIds`.
- aktuell = erste nicht erledigte Unit in Pfadreihenfolge, **außer Boss** (Boss bleibt immer gesperrt, Brief 13).
- sonst gesperrt.
- Eintragen erledigt die aktuelle Unit (UI-30). Ist die laufende Woche fertig, rückt „aktuell" in die nächste Woche vor (A-11).
- Keine aktuelle Unit mehr (alles bis vor Boss erledigt): Manny sitzt auf der letzten erledigten Unit, Eintragen zählt nur für den Streak (A-11).
- **K-1 (bekannte Einschränkung, n9):** Wer täglich trainiert, schließt Units schneller ab als Wochen vergehen. Dann sitzt die aktuelle Unit in einer späteren Woche als „Woche W" in der Kopfzeile, und gesperrte Units dieser späteren Woche zeigen „Kommt in Woche N", obwohl sie schon dran sind; „Kommt noch diese Woche" bezieht sich auf die Datumswoche W. Im Prototyp akzeptiert (Platzhalter-Pfad), wird im Abschlussbericht von U4 genannt; Lösung kommt mit dem Physio-Framework.

**Profiländerung (N-7, Ergänzung 3.2 V4):** Ändern sich Typ **oder** Datum: `completedUnitIds` geleert, alles neu abgeleitet. Name allein oder nur der „Anderes"-Freitext: keine Neuberechnung (A-12). Streak, Freezes, `day.*` (inkl. `done`), `prefs.timeChoice` bleiben. **Folgen festgelegt (n3):**
- `path.pulsePending` wird geleert (kein Puls auf einem neu berechneten Pfad).
- `celebration` bleibt nur, wenn `celebration.unitId` im neuen Pfad erledigt ist; sonst gestrichen.
- `day.done` bleibt (Tagesänderungen bleiben laut N-7). Dann kann Heute „Heute erledigt" zeigen, während der Pfad eine aktuelle Unit hat; das ist konsistent mit Ergänzung 3.5 (Tipp auf aktuelle Unit öffnet Heute, „auch wenn heute schon erledigt"). Erneutes Eintragen am selben Tag ist nicht möglich.
- Tests: alle drei Fälle plus „nur Name geändert → nichts davon".

**Kopfzeile:** „Woche W", „Phase P · <Kurzname>"; Kurznamen (A-13, Vorschlag ui-designer): ACL „Kreuzband", Sprunggelenk „Sprunggelenk", Muskelfaserriss „Muskelfaser", Anderes „Reha".

**NodeHint-Texte (Ergänzung 3.5):** gesperrt, Woche der Unit = W → „Kommt noch diese Woche"; sonst Trainingstag/Wochenziel „Kommt in Woche N", Phasen-Abschluss „Phasen-Abschluss kommt in Woche N", Boss „Return to Sport kommt in Woche 12". Erledigt: „Erledigt. Das hast du geschafft."

**Screenreader-Labels:** „Woche 5, Trainingstag 3, aktuell. Öffnet Heute." · „Woche 7, Trainingstag 1, gesperrt." · „Woche 3, Trainingstag 2, erledigt." · Boss „Return to Sport, gesperrt." · analog „Woche 5, Wochenziel, gesperrt.", „Woche 8, Phasen-Abschluss, gesperrt." (A-14).

**Unit-Tests:** Anzahl/Reihenfolge/IDs; W und Phase für Datum heute, vor 4/5/27/28/84/200 Tagen; Status bei W = 5; Eintragen setzt nächste Unit aktuell; Wochenende → nächste Woche; Endfall; Boss nie aktuell; Neuberechnung (siehe oben); Hinweistexte inkl. „noch diese Woche".

### 7.3 Pfad-Layout (`path_layout.dart`)
Reine Funktion `layout(units, width, viewportHeight) → {placements: List<NodePlacement {center, diameter}>, totalHeight, padTop, padBottom}`. Vertikal von unten (Woche 1) nach oben (Boss), konstanter Abstand je Unit plus Durchmesser; x alternierend über eine Sinuskurve innerhalb `width − 2×16 dp` (Brief 7). Verbindungen als kubische Bézier-Strecken.

**Polster (M4, B-7):** Oben und unten wird der Scrollinhalt so gepolstert, dass **jede** Unit, auch die erste (Woche 1, Tag 1) und die letzte (Boss), auf 55 % der Viewport-Höhe gescrollt werden kann: `padBottom = 0,45 × viewportHeight` (abzüglich des Platzes, den die erste Unit unten ohnehin hat), `padTop = 0,55 × viewportHeight` entsprechend. Damit begrenzt der Scrollbereich das initiale `jumpTo` nicht mehr. Zusätzlich gilt unten die Reserve für die Button-Gruppe (4.6, Ergänzung 2): `padBottom = max(Zentrier-Polster, Nav + 16 + 56 + 8 + 48 + 16 dp)` aus gemessenen Höhen. Initiales Scrollen und Neuberechnung nach Profiländerung (UI-55): Offset so, dass die aktuelle Unit (bzw. Manny-Unit) auf 55 % liegt; `jumpTo` (RM und Neuberechnung ohne Animation, Ergänzung 4).

Tests: x innerhalb der Grenzen inkl. Durchmesser; nicht alle x gleich (UI-20); y streng monoton; Durchmesser 48/60/72/92; bei 320 und 430 dp gültig; für erste, letzte und mittlere Unit existiert ein gültiger Offset, der sie auf 55 % setzt.

### 7.4 Platzhalter-Pools (`placeholder_pools.dart`)
Alle Inhalte als **Platzhalter** gekennzeichnet (Konstante + Kommentar), keine medizinische Aussage.
- **Übungspool:** Basisübungen je Zeitwahl, Summe der Dauern genau 10/20/30 Min; Basis 10 ⊂ 20 ⊂ 30 (gleiche IDs), damit Tagesänderungen beim Zeitwechsel per ID erhalten bleiben. Je Basisübung Alternativen für „Tauschen" (zyklisch, A-15). Namen aus dem Mockup („Kniebeuge am Stuhl", 3 × 12 Wdh., 6 Min; „Brücke mit Fersendruck", 3 × 15 Wdh., 7 Min) plus weitere Platzhalter, deren Texte der `ui-designer` prüft.
- **Termine (N-14):** Physio Mo–Fr 17:00 „Physiotherapie, Praxis Müller", Meta „Köln-Ehrenfeld · Beispiel"; zusätzlich Fr 09:30 Arzt „Kontrolltermin Orthopädie", Meta „<Ort> · Beispiel" (Ort-Platzhalter vom `ui-designer` zu bestätigen); Sa/So keine Termine → Leerzustand „Heute keine Termine." Reihenfolge nach Uhrzeit. „Beispiel" steht in der Meta-Zeile (`caption`, `text-3`); Screenreader „Beispieltermin, Physio, Physiotherapie, Praxis Müller, 17:00 Uhr" (A-16).
- **Manny-Texte** (fest, Brief 6.1/6.2/6.0): Onboarding-Sätze je Schritt, Mikrofon-Hinweis „Das kann ich bald, heute noch nicht.", Begrüßung, Streak-Gefahr, Feier, Neustart „Neuer Anlauf, [Name]. Dein Pfad bleibt, der Streak startet heute neu." (Pose `motiviert`, A-17), Beispielfakt „Dein Gewebe baut sich gerade aktiv um. Heute zählt." (kein Rotieren).
- **Plural (B-5):** `tage(n)` in `plural.dart`: „1 Tag", sonst „n Tage" (auch 0). Verwendet in Streak-Gefahr-Blase („Dein Streak von 1 Tag …"), Screenreader („Streak: 1 Tag") und wo die Kopfzeile Tage nennt. Test n = 0, 1, 2.
- **Tests:** Manny-Texte ≤ 2 Sätze (Satzzählung mit Abkürzungs-Allowlist „ca.", „z. B.", „Nr."); Ton-Prüfung per Wortlisten (12.3, Regel 10); Summen 10/20/30.

### 7.5 Tagesprogramm, Tageswechsel, Eintrag über Mitternacht (`day_program.dart`, `day_rollover.dart`)
- `deriveExercises(DayProgramState d, int timeChoice)`: Basis je Zeitwahl, minus `removed`, mit `swaps` ersetzt, plus `custom` am Ende.
- **Überschrift (B-6):** „Übungen · ca. N Min" mit N = Summe der Dauern der angezeigten Übungen (gerundet). Ohne Änderungen = Zeitwahl (UI-26). Bei leerer Liste nur „Übungen" (Darstellung „ÜBUNGEN").
- **Leer + Erledigt gleichzeitig (B-6):** Button zeigt „Heute erledigt" (Erledigt gewinnt), die Liste zeigt die Leer-Karte „Heute noch nichts geplant." mit Aktion „Eigene Übung".
- Nach Erledigt bleiben Tauschen/Entfernen/Eigene Übung/Zeitwahl bedienbar (A-19).
- `rollover(AppState s, LocalDay today)`: wenn `today != s.day.dayKey`: `day = DayProgramState.fresh(today)` (Zeitwahl bleibt, N-8), `celebration` verfällt, wenn `celebration.day != today`, `pulsePending` verfällt mit ihr, Streak `evaluate`. Ergebnis `changed: true` (Snackbar, Ansage, Routen schließen, Undo beenden). Blasen-Zähler beginnen implizit neu.
- Aufrufzeitpunkte: App-Start, `AppLifecycleListener.onResume`, jeder Tabwechsel, **jede mutierende Controller-Methode zuerst** (N-11). Kein Timer um Mitternacht.
- **Eintrag über Mitternacht (N-11):** Das Trainings-Sheet merkt sich beim Öffnen `openedDay`. „Training eintragen" ruft `logTraining(forDay: openedDay)`. Ist `openedDay` < heute: (1) Streak `logTraining(openedDay)` (zählt für den Vortag), Unit erledigt, `day.done = true` für das Programm von `openedDay`; (2) danach `rollover(today)`: frisches Programm, „Training starten", Streak-Auswertung für heute (der Vortag ist dadurch nicht verpasst); die Feier gehört zu `openedDay` und verfällt sofort, kein Rückgängig-Fenster (der Tageswechsel beendet es, Ergänzung 3.3 Punkt 5). Sichtbar: Sheet schließt, danach Snackbar „Neuer Tag, neues Programm." und Ansage, Reihenfolge und Bedingung siehe 4.6 („Reihenfolge beim Tageswechsel auf Heute“). Auch das Trainings-Sheet wird beim Tageswechsel geschlossen, wenn es ohne Eintrag offen bleibt (Ergänzung 3.4).
- **Uhr rückwärts (n2, A-9):** Jede Abweichung ist ein Wechsel → frisches Programm für den früheren Tag. Eintragen dort: `day.done = true`, Streak unverändert, keine Unit erledigt, keine Feier (S25).
- **Tests:** Ableitung je Zeitwahl; Entfernen/Tauschen/Eigene; Zeitwechsel erhält Änderungen; Rollover setzt Tagesänderungen und `done` zurück, behält Zeitwahl; selber Tag No-op; rückwärts = Wechsel; Feier vom Vortag verfällt; Eintrag über Mitternacht (23:59 Sheet öffnen, 00:01 eintragen): Streak zählt Vortag, heute nicht verpasst, Programm heute frisch, keine Feier, kein Undo; Leer + Erledigt; Überschrift leer.

### 7.6 Rückgängig (`undo.dart`)
`TrainingSnapshot` = `{streak (gesamter StreakState), path.completedUnitIds, path.pulsePending, day.done, celebration}` vor dem Eintragen. `undo(state, snapshot)` spielt genau diese Felder zurück. Tests: S18, Unit wieder aktuell, Feier gestrichen, erneutes Eintragen möglich, Undo nach Tageswechsel vom Controller abgelehnt.
„Entfernt. Rückgängig": Token `{exerciseId, previousRemoved}`; nur eine Snackbar gleichzeitig.

### 7.7 Manny-Anlässe (`manny_occasions.dart`)
`BubbleDecision? nextBubble(AppState s, DateTime now)` beim Sichtbarwerden des Pfads. Priorität (A-20): 1. Feier (ausstehend, `day == today`, kein Undo-Fenster) → Pose `feiernd`, „Stark, [Name]. Das war Tag [N]." + Ring-Puls; 2. Neustart (`resetNoticePending`, Pose `motiviert`); 3. Begrüßung (`greetingPending`, einmal nach Onboarding, A-21); 4. Streak-Gefahr (`now.hour >= kEveningHour` = 18, N-2; heute nicht erledigt; `count > 0`); 5. Beispielfakt (A-22: höchstens einmal pro Tag beim ersten Pfad-Besuch, wenn kein anderer Anlass fällig ist **und heute noch nicht trainiert** wurde). Jeder Anlass höchstens einmal pro Tag (`lastShown`). Nicht gezeigte Anlässe bleiben fällig.
Tests: Priorität, 17:59 vs. 18:00, einmal pro Tag, am Folgetag wieder (UI-45), Feier nicht während Undo-Fenster, Feier verfällt um Mitternacht, nach Undo keine Feier, Fakt nicht nach Training.

### 7.8 Profil (`profile.dart`)
`ProfileDraft`, `isDirty` (Name nach `trim()`), `canSave` (dirty, Name nicht leer, Datum ≤ heute), `apply(state, draft, today)` → neuer Zustand + `{nameChanged, pathRecomputed}` für Ansage „Gespeichert. Pfad neu berechnet." bzw. „Gespeichert.".

### 7.9 Manny-Textquelle, Kontext, Fakten (KS-1, KS-2, KS-3)
- **KS-1 `MannyTextSource` (synchron, rein):** `lib/logic/manny_text_source.dart` mit `abstract class MannyTextSource { String bubbleText(MannyOccasion occasion, MannyContext ctx); FactRef fact(MannyContext ctx); }` und `PlaceholderMannyTextSource`, die exakt die bisherigen Platzhaltertexte aus `strings_de.dart` liefert (Name eingesetzt, Plural-Helfer). Injektion in den `AppController` wie `Clock`; `nextBubble` (7.7) liefert weiter nur den **Anlass**, der Text kommt aus der Quelle. Anlasslogik, Priorität, `lastShown` und „Tageswechsel zuerst" bleiben unverändert. Tests: U: Platzhalterquelle liefert für jeden Anlass die bisherigen Texte (≤ 2 Sätze); W: Pfad zeigt den Text einer `FakeMannyTextSource`.
- **KS-2 Fakten als ID + Text:** `FactRef {String id, String text}` in `placeholder_pools.dart`; der Beispielfakt erhält eine feste ID. Test: IDs eindeutig und stabil, Text unverändert.
- **KS-3 `MannyContext`:** `lib/logic/manny_context.dart`, `MannyContext.from(AppState s, LocalDay today)` mit Vorname (getrimmt), `injuryType`, Verletzungsdatum, Woche, Phase, Streak, Freezes, heute erledigt, Zeitwahl, Anzahl Übungen heute; **kein** „Anderes"-Freitext. `toJson()` mit festen Feldnamen (wie im KI-Plan; reine Funktion, nichts wird gesendet oder gespeichert). **Bewusst ohne Verbraucher im ersten Ausschnitt** (KS-3: Schema für den späteren Server); nur der Stabilitätstest nutzt es; `// ignore`-freie öffentliche API, damit `flutter analyze` nicht anschlägt. Tests: Woche/Phase identisch zur Kopfzeile, Werte nach Training, Reset, Profiländerung; `toJson` stabil.
- `strings_de.dart` hat keinen Flutter-Import, damit `lib/logic/` die Texte nutzen darf (Konvention 3 und 4; statische Regel 7 prüft `lib/logic/` und `lib/l10n/`).

### 7.10 Chat-Datenmodell und Beispielverlauf (KS-4, KS-5, KS-10)
- **KS-4 (minimal):** `lib/logic/chat_model.dart`: `ChatMessage {String id, ChatAuthor author, ChatKind kind, ChatStatus status, String text}` mit `copyWith`; Enums `ChatAuthor {user, manny, notice}`, `ChatKind {text, escalation, disclaimer, bubble}`, `ChatStatus {sending, streaming, done, aborted, failed}` (Werte aus Brief-Ergänzung 2, 2.2). **Kein JSON, keine Persistenz, kein Zeitstempel.** Test: Gleichheit/`copyWith`.
- **KS-5 (nur lesend):** `lib/data/manny_chat_source.dart`: `abstract class MannyChatSource { List<ChatMessage> messages(String vorname); }` und `ExampleMannyChatSource` mit dem Beispielverlauf aus Ergänzung 2, 3.2 (Texte aus `strings_de.dart`, Name aus dem Onboarding eingesetzt). **Kein** `canSend`, `send`, `cancel`, `retry`, `deleteAll`, `Stream` (kommt im KI-Ausschnitt). Bereitstellung per `ChatSourceScope`.
- **Eingabeleiste:** `ChatComposer` existiert **nur in der deaktivierten Form** (Nutzerentscheidung Ergänzung 2 Abschnitt 8, Präzisierung des Orchestrators): kein `canSend`-Wert, keine aktive Variante, kein Variantentest. Die aktive Variante und `canSend` folgen im KI-Ausschnitt (KI-D/KI-5).
- **KS-10 Nachrichten getrennt:** Die Beispielkontakte und Beispiel-Chats liegen als eigene feste Daten in `lib/ui/messages/example_contacts.dart` (eigener kleiner Typ `ExampleContact {id, section, initials, nameKey, roleKey, lines: [(fromMe, textKey)], dayKey}`), **nicht** als `ChatMessage`. Gemeinsam mit dem Manny-Chat ist nur Darstellung (`ChatScreenScaffold`, `ChatHeader`, `ExampleNotice`, `ChatComposer`). Dateikopf-Kommentar: „Unverbindlicher Platzhalter, keine Spec (Brief-Ergänzung 2, K10).“ (statische Regeln 13, 14).
- **Nichts wird gespeichert** (UI-82): Chat- und Nachrichten-Code greift weder auf `StateStore` noch auf mutierende `AppController`-Methoden zu (statische Regel 15); nach „Alles löschen" und neuem Onboarding zeigt der Chat denselben Beispielverlauf mit dem neuen Namen.

---

## 8. Token-Architektur und Darstellung

### 8.1 Tokens
- `tokens.dart`: einzige Datei mit Hex-Werten und Zahlen (Farben 3.1, `scrim` 60 %/72 %, Typo 3.3, Raster/Radien/Größen 3.4, Motion 3.6, Glow-Parameter 3.2, Blur σ 16, Schatten, Unit-/Nav-/Manny-Größen, Snackbar-Dauern).
- `CuraColors extends ThemeExtension<CuraColors>`: semantische Felder (`bg`, `surfaceGlassTop/Bottom`, `surfaceFloat`, `surfaceOpaque`, `borderHair`, `borderControl`, `text1..3`, `accent`, `accentHi`, `accentSoft`, `onAccent`, `focusRing`, `catPhysio/Arzt/Uebung/Frist`, `triGruen/Gelb/Orange/Rot`, `statusError`, `streakFreeze`, `glowEmber`, `scrim`) plus abgeleitete Rollen (`cardFill`, `floatFill`, `controlBorder`, `blurEnabled`, `glowEnabled`, `shadowsEnabled`). Instanzen `CuraColors.dark` und `CuraColors.darkHighContrast`. Benennung so, dass ein heller Modus nur neue Werte braucht.
- **Akzent als Text (Brief-E-2, UI-4):** `accent` als Textfarbe nur auf `bg`. Auf `surface-opaque` (4,42:1), Glas, `CuraDialog`, `CuraSnackbar`, `NodeHint` und DatePicker-Textbuttons: `accentHi` oder `text1`. DatePicker-Theme: `textButtonTheme`/`confirmButtonStyle`/`cancelButtonStyle` mit `accentHi`; gewählter Tag bleibt Fläche `accent` mit `on-accent`.
- `CuraTypography`: `display`, `title`, `heading`, `numeral`, `numeralLarge` (24/28), `button`, `body`, `bodyStrong`, `secondary`, `label`, `caption`, `bubble` (14,5 sp), `segment` (DM Sans 16/24, **400** = `body`, nicht gewählt, `text-2`), `segmentSelected` (DM Sans 16/24, 700, `text-1`) (A-23). Jeder Stil setzt `fontFamily`, `fontSize`, `height`, `fontWeight` **und** `fontVariations: [wght, opsz]` (Bricolage zusätzlich `wdth 100`). **opsz-Regel:** `opsz = fontSize`, begrenzt auf die Achse (DM Sans 9–40, Bricolage 12–96), entspricht `font-optical-sizing: auto` im Web; Prüfung per Golden je Stil (Typo-Tafel).
- `label`-Stil: Großbuchstaben nur in der Darstellung. `CuraLabel` zeigt `text.toUpperCase()` (Laufweite 0,06 em) und setzt `Semantics(label: text)` in normaler Schreibweise.
- `CuraSpace`, `CuraRadius`, `CuraSize`, `CuraShadow` als `static const`.
- `CuraMotion.of(context)`: `fast/base/slow`, `curve`, `reduced` = `MediaQuery.disableAnimationsOf(context) || View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion` (iOS meldet „Bewegung reduzieren" nur über `reduceMotion`).
- **Auswahl HC/RM und Overrides:** `MaterialApp` erzeugt seine eigene `MediaQuery` aus der View; ein Override **oberhalb** von `MaterialApp` wirkt daher nicht. Reihenfolge in `MaterialApp.builder`: (1) nur in `main_preview`: `PreviewOverrides` (setzt `MediaQuery` mit Skalierung/HC/RM), (2) `CuraThemeSelector` (liest `MediaQuery.highContrastOf` und setzt die `CuraColors`-Instanz in ein `Theme`), (3) `ContentFrame`. `CuraMotion` liest zusätzlich ein `PreviewMotionOverride`-InheritedWidget, weil `reduceMotion` aus dem `platformDispatcher` kommt. Widget-Tests prüfen **beide** Wege: Systemsignal über `accessibilityFeaturesTestValue` (Produktionspfad `main.dart`) und Preview-Override (n7). Im Web ist der HC-Override damit wirksam; ob das Browser-Signal (`forced-colors`) ankommt, ist offen (12.5).
- `ThemeData`: `brightness: dark`, `colorScheme` aus Tokens (`primary = accent`, `onPrimary = on-accent`, `surface = surface-opaque`), `datePickerTheme` dunkel. Locale `de` mit `GlobalMaterialLocalizations`.

### 8.2 Glow (Brief-E-1, UI-7 neue Fassung)
- `glow.dart`: Geometrie und Alpha-Funktion als reiner Code, geteilt von Painter und Tests: oben links Mitte (−30, 40), r 260, Spitze 0,24; unten rechts Mitte (Breite + 50, Höhe − 24), r 300, Spitze 0,14; `alpha(d) = peak × max(0, 1 − d / (0,7 × r))` (lineare Stops 0 und 0,7). Gesamt-Alpha an einem Punkt = Komposition beider Verläufe (`1 − (1−a1)(1−a2)`).
- `GlowBackground` (einmal je Screen-Root, hinter dem Inhalt, volle Breite auch außerhalb des `ContentFrame`): `ExcludeSemantics` > `IgnorePointer` > `RepaintBoundary` > `CustomPaint` mit zwei `RadialGradient`s. Statisch. Bei `glowEnabled == false` (HC) nicht gebaut.
- **Prüfregel (statt Abstand, Brief-E-1):** Für jeden `RenderParagraph` wird der Glow-Alpha am dem jeweiligen Mittelpunkt nächstgelegenen Punkt des Text-Rechtecks berechnet. Untergrund: „Glas", wenn ein Vorfahr `GlassCard` oder eine E2-Fläche (`FloatingNav`, `MannyBubble`, Sheet) ist (A-35: E2 streng wie Glas behandelt), sonst `bg`; opake Flächen (Snackbar, Dialog, Hinweis) sind glowfrei. Schwellen: `bg` ≤ 24 %; `text-1/2/3` auf Glas ≤ 16 %; farbiger Text und `accent-hi` auf Glas ≤ 12 % **und** zusätzlich berechneter WCAG-Kontrast ≥ 4,5 bei diesem Alpha. Hinweis: Laut Errata-Tabelle erreicht `accent-hi` auf Glas bei 12 % nur 4,34 und `cat-frist` 4,19; die Zusatzbedingung macht das explizit (praktisch: `accent-hi` als Text auf Glas nur bei ≤ 9 % Glow, `cat-physio` ≤ 13 %). Im Ausschnitt ist kein `accent-hi`-Text auf Glas vorgesehen (Snackbar-Aktion liegt auf `surface-opaque`). Eine „benannte Ausnahme" gibt es nicht mehr.

### 8.3 Blur-Budget
Einzige Stelle mit `BackdropFilter`: `CuraBlur`, verwendet nur von `FloatingNav`, `MannyBubble` und `CuraSheetRoute`. Button-Gruppe, Hinweiskarten, Kontaktzeilen, Blasen und Eingabeleiste: kein Blur. Manny-Chat, Nachrichten und Beispiel-Chat: **0** `BackdropFilter` (keine Nav) (UI-85). Bei `blurEnabled == false` (HC) nur opake Fläche. Dialog, Snackbar, `NodeHint`, Karten, Chips: nie Blur. Öffnen von „Deine Daten" schließt eine sichtbare Blase (Ergänzung K3).

### 8.4 Schatten, Schein, Linien (B-8)
- Primärbutton: Schein 0/8/28 dp `accent` 28 %; bei HC entfällt er (`shadowsEnabled`).
- Nav und Sheet: Schatten 0/10/30 dp Schwarz 45 %; unter der Nav blendet der Inhalt mit einem Verlauf in `bg` aus.
- Pfad: erledigte Verbindung `text-1` 3 dp, runde Enden; zukünftige Strecke gepunktet Weiß 22 % 3 dp; aktuelle Unit mit Ring 1,5 dp `accent` 40 % im Abstand 9 dp und weichem Schein (Radialverlauf `accent` 50 %).
- Pressed: Primär +10 % Helligkeit (`#DD7240`), Neutral hell → reines Weiß, Umriss → Füllung Weiß 10 %.
- Manny-Button und Nachrichten-Button: Schatten 0/6/16 dp Schwarz 40 % (Wert aus Ergänzung 2, als `CuraShadow.actionButton` in `tokens.dart`; kein neuer Design-Token, nur die Ablage des Brief-Werts). Dieser Schatten **bleibt bei HC** (Ergänzung 2, 4) und hängt deshalb nicht an `shadowsEnabled`. Pressed: Überlagerung Weiß 10 %. Kein Glow, kein Akzent-Ring.

### 8.5 Hoher Kontrast
`darkHighContrast`: `cardFill`/`floatFill` = `surface-opaque`, `controlBorder` = `border-control-hc` (auch Kartenrand), `scrim` 72 %, kein Blur, kein Glow, keine Schatten/Scheine; `HeaderIconButton` mit Kreisrand. Ergänzung 2: Manny-/Nachrichten-Button, `ExampleNotice`, Eingabeleiste, Blasen (auch die Glas-Blase des Gegenübers) und Avatare `surface-opaque` mit `border-control-hc` (UI-87). Plattform: Signal nur iOS 13+ und Android API 34+ (R-5).

### 8.6 Fonts
- `BricolageGrotesque[opsz,wdth,wght].ttf`, `DMSans[opsz,wght].ttf` und die beiden `OFL.txt` aus `github.com/google/fonts` (`ofl/bricolagegrotesque`, `ofl/dmsans`), unverändert.
- Lizenz: SIL OFL 1.1; Lizenztext mitliefern und über `LicenseRegistry.addLicense` registrieren (A-24).
- Kein `google_fonts`, kein Laden zur Laufzeit; Web-Build mit `--no-web-resources-cdn`.

---

## 9. Komponenten (Brief 5, Ergänzung 1 Abschnitt 2, Ergänzung 2 Abschnitt 2) → Dateien

| Baustein | Datei (`lib/ui/components/`) | Hinweise |
|---|---|---|
| `ContentFrame` | `content_frame.dart` | max. 560 dp mittig (B-3) |
| `GlowBackground` | `glow_background.dart` | 8.2 |
| `CuraBlur` | `cura_blur.dart` | einziger `BackdropFilter` |
| `GlassCard` | `glass_card.dart` | E1, kein Blur, innere Lichtkante |
| `CategoryCard` | `category_card.dart` | Streifen + Icon-Kachel + Label + Titel + Meta (inkl. „· Beispiel") + Uhrzeit, Aktionsleiste; Kategorien `physio/arzt/uebung` (`frist` reserviert) |
| `PillButton` (Primär, Neutral hell, Umriss), `CuraChip`, `TimeSegment`, `DashedAction` | je eigene Datei | Hit-Area 48 dp, Pressed 8.4, Disabled 38 %, Fortschrittskreis-Zustand |
| `FloatingNav` | `floating_nav.dart` | Labels über `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`, Ausblend-Verlauf |
| `PathNode` | `path_node.dart` | Größen, Zustände, Ring-Puls (RM: aus), Fokus/Enter/Leertaste, Semantics-Button |
| `PathView` | `../path/path_view.dart` | ein `CustomPainter` für Linien (ausgeblendet für Screenreader), Units als Widgets, Polster 7.3 |
| `MannyPlaceholder` | `manny.dart` | `CustomPainter`, Posen `neutral/motiviert/feiernd`, statisch, Label „Manny, dein Begleiter"; Parameter `crop: full | head` (Kopf für Manny-Button ca. 38 dp und Chat-Emblem 26/34 dp, eine Zeichnung, nicht doppelt); `hitPath()` für den Manny-Tipp (Form + 8 dp, bis Standlinie, 4.6); außerhalb des Pfads `IgnorePointer` |
| `MannyBubble` | `manny_bubble.dart` | E2 mit `CuraBlur`, X 48 dp, Platzierung rechts bzw. oberhalb (< 140 dp), max. 280 dp, Live-Region, nicht modal; Tipp irgendwo schließt (durchlässiger `Listener`) |
| `ChoiceCard`, `StepProgress`, `CuraTextField`, `DateCard`, `MicButton` | je eigene Datei | **eine** Implementierung für Onboarding und Sheet (UI-53) |
| `PathHeader` + `StatPill` + `HeaderIconButton` | `path_header.dart`, `stat_pill.dart`, `header_icon_button.dart` | Zeilen- und Umbruch-Layout (linker Block < 150 dp → Umbruch); Freeze- und Streak-Pill sind **reine Info** mit Semantics-Label, keine Schaltflächen, kein Tap-Ziel (B-8); „eingefroren"; Tooltip „Deine Daten" |
| `CuraSnackbar` + `SnackbarHost` | `cura_snackbar.dart` | opak, eine gleichzeitig, Live-Region, Dauern 4 s („Alle Daten sind gelöscht.", Neustart-Hinweis), 5 s („Neuer Tag, neues Programm."), 8 s („Eingetragen.", „Entfernt.") (B-8); Pause bei Fokus/Hover, ohne Timer bei `accessibleNavigation`; Aktion ab Skalierung 1,3 unter dem Text |
| `NodeHint` | `node_hint.dart` | `OverlayEntry`, opak, Pfeil, Breite min(240, Breite − 32), geklemmt, oben/unten-Wahl, schließt bei Tipp/Scroll/Escape/Tab/5 s |
| `CuraDialog` | `cura_dialog.dart` | Aufbau Ergänzung 1 Abschnitt 2, Buttons gestapelt, Inhalt scrollt |
| `CuraLabel` | `cura_label.dart` | Großbuchstaben nur visuell |
| `FocusRing` | `focus_ring.dart` | `focus-ring` 2 dp, 2 dp Abstand |
| `MannyChatButton` | `manny_chat_button.dart` | Kreis 56 dp, `surface-opaque`, Rand 1,5 dp `border-control` (HC `-hc`), Schatten 8.4, Manny-Kopf; Tooltip/Semantik „Manny, Chat öffnen"; `focus-ring`, Enter/Leertaste |
| `MessagesButton` | `messages_button.dart` | Kreis 48 dp, sonst wie oben; Icon `chat_bubble_outline_rounded` 24 dp `text-1`; „Nachrichten" |
| `ActionCluster` | `action_cluster.dart` | Modus `path` (beide Buttons gestapelt) / `today` (nur Nachrichten-Button über der Reihe); stellt sein Rechteck per `GlobalKey` für Blase/Hinweis bereit (4.6) |
| `PrimaryActionRow` | `../today/primary_action_row.dart` | „Training starten"/„Heute erledigt"/deaktiviert + 8 dp + `MannyChatButton`, unten bündig; meldet ihre Höhe für die Scroll-Reserve |
| `ChatScreenScaffold` | `chat_screen_scaffold.dart` | Vollbild ohne Nav: Glow, Kopf (opak `bg`, 1 dp `border-hair` unten), Inhalt, optional fester Fuß; Escape → `maybePop`; kein `BackdropFilter` |
| `ChatHeader` | `chat_header.dart` | Zurück-Pfeil (48 dp, `HeaderIconButton`-Stil, `autofocus`), Emblem/Avatar 32–36 dp, Titel `heading`, Untertitel `secondary` `text-2` (A-40) |
| `ExampleNotice` | `example_notice.dart` | `GlassCard` Radius 16, Innenabstand 10/14, Info-Icon 20 dp `text-2`, optional `CuraLabel` + Text `secondary`; nicht ausblendbar |
| `ChatMessageList` | `chat_message_list.dart` | rendert `List<ChatMessage>` nach Autor: Manny ohne Blase auf `bg` mit Emblem 26 dp **je Manny-Block**, Text ab 36 dp, max. 560 dp; Nutzer-Blase rechts (`surface-opaque`, `border-hair`, Radius 20, Ecke unten rechts 6 dp, ≤ 80 % Breite, 12/16); Abstände 20/8 dp; **vollständige Darstellung aller Enum-Werte (MINOR-7a, v1.3)** per erschöpfendem `switch` ohne `default` (Dart 3, der Compiler meldet Lücken): Autor `manny` → Manny-Text ohne Blase, `user` → Nutzer-Blase rechts, `notice` → Hinweiskarte wie `ExampleNotice`, mittig, volle Breite; Art `text` → Darstellung des Autors, `disclaimer` → Zeile `caption` `text-3` mittig (wie der Disclaimer unter der Leiste), `escalation` und `bubble` → vorläufig wie `text` des jeweiligen Autors (eigene Gestaltung folgt im KI-Brief KI-D); Status ≠ `done` wie `done`; W-Test rendert jede Kombination Autor × Art einmal ohne Overflow; beim Öffnen Ende sichtbar; **Ende-Folgen:** steht der Nutzer am Ende (Offset ≥ max − 1 dp), springt die Liste nach jedem Layout an das neue Ende, sonst nicht; Semantik „Manny: …"/„Du: …" |
| `ChatComposer` | `chat_composer.dart` | **nur deaktiviert**: Pill Radius 28, ≥ 56 dp, `surface-opaque`, Rand 1 dp `border-hair`, Platzhalter (`body` `text-2`), Senden-Kreis 40 dp (Hit-Area 48) mit `arrow_upward_rounded` `text-3` auf Weiß 10 %; kein `TextField` (öffnet keine Tastatur), `ExcludeFocus`, Semantik „Nachricht an Manny, noch nicht verfügbar" / „Senden, noch nicht verfügbar" (bzw. Beispiel-Chat-Varianten); Hinweiszeile darüber (Info-Icon 18 dp + `secondary` `text-1`), optional Disclaimer darunter (`caption` `text-3`, mittig) |
| `ChatFooterLayout` | in `chat_screen_scaffold.dart` | Fuß (Hinweis, Leiste, Disclaimer) höchstens 40 % der Höhe; ab Textskalierung 1,5 wandern Hinweiszeile und Disclaimer ans Ende der Liste (scrollen mit), die Leiste bleibt fest; in den Nachrichten wandert ab 1,5 die `ExampleNotice` als erstes Element in die Liste |
| `ContactRow` | `../messages/contact_row.dart` | ≥ 72 dp, ganze Zeile antippbar, `focus-ring`, Pressed Weiß 10 %; Avatar 48 dp (Initialen, `surface-opaque`, Ring 2 dp: Physio `cat-physio`, Ärzte `cat-arzt`, sonst Weiß 30 %), Name `bodyStrong`, letzte Nachricht `secondary` `text-2` (umbrechend), Zeit `caption` `text-3`; Semantik nach Ergänzung 2, 3.5 |
| `ChatBubble` (Mensch) | `../messages/chat_bubble.dart` | eigene rechts `surface-opaque` + `border-hair`, Gegenüber links `GlassCard`-Füllung ohne Blur; Radius 20, Ecke zur Absenderseite 6 dp, ≤ 80 %, 12/16, `body` `text-1`; optionale Tagesüberschrift `CuraLabel` mittig |

**Eigene Übung (B-4):** `CuraDialog`-Rahmen mit drei `CuraTextField`s: Name (Pflicht, getrimmt), Wiederholungen vorbefüllt „3 × 10", Dauer in Minuten vorbefüllt „5" (ganze Zahl 1–120); ein geleertes Feld fällt beim Hinzufügen auf die Vorgabe zurück, damit jede Karte Name, Wiederholungen und Dauer zeigt (UI-27). Buttons gestapelt: „Hinzufügen" (Primär, disabled bei leerem Namen) und „Abbrechen" (Umriss).

**Icons** (abgerundete Material-Icons, A-25 nach ui-designer): Nav `route_rounded` / `event_available_rounded`; Physio `accessibility_new_rounded`, Arzt `medical_services_rounded`, Übung `fitness_center_rounded`; Streak `local_fire_department_rounded`, Freeze `ac_unit_rounded`; Units `flag_rounded` / `check_rounded` / `lock_rounded` / `star_rounded`; Tauschen `swap_horiz_rounded`, Entfernen `close_rounded`, Schließen `close_rounded`; Zurück `arrow_back_rounded`; Auswahl-Haken `check_circle_rounded`; „Anderes" `edit_rounded`; `DateCard` `calendar_today_rounded`; „Training starten" `play_arrow_rounded`, „Heute erledigt" `check_rounded`; Modi Manuell `edit_note_rounded`, Passiv `sensors_rounded`, Aktiv `play_circle_rounded`; Mikro `mic_none_rounded`; Daten `person_outline_rounded`; Löschen `delete_outline_rounded`; Fehler `error_outline_rounded`; Info `info_outline_rounded`; Nachrichten `chat_bubble_outline_rounded`; Senden (deaktiviert) `arrow_upward_rounded`; Chat-Zurück `arrow_back_rounded`.

**Texte:** alle in `lib/l10n/strings_de.dart` (A-26), inkl. Semantics-Labels, Tooltips, `hintText`.

---

## 10. Pakete

| Paket | Quelle | Zweck | Begründung |
|---|---|---|---|
| `shared_preferences` ^2.5.6 | pub.dev, Flutter-Team | lokale Speicherung des Zustandsdokuments (Android/iOS/Web) | kleinste offizielle Lösung für ein Dokument < 5 KB; funktioniert im Web (Prüfumgebung). Datei via `path_provider` hätte im Web keinen Speicher; Datenbank wäre überdimensioniert |
| `flutter_localizations` | Flutter-SDK | deutsche Texte in Material-Bausteinen (DatePicker, Tooltips, Barrieren-Semantik) | Brief 8: „Alle Texte Deutsch" |
| `flutter_test`, `flutter_lints` | SDK/Standard | Tests, Lints | Standard |

Bewusst **nicht**: `google_fonts`, State-Management-Pakete, `intl` direkt (nur transitiv), `go_router`, `clock`, Golden-Hilfspakete; `cupertino_icons` wird aus der Vorlage entfernt. Playwright/Chromium sind in der Umgebung vorhanden, kein `package.json` im Projekt (Import über `/opt/node-tools/node_modules/playwright`, überschreibbar per `PLAYWRIGHT_MODULE`).

---

## 11. Backend-Vorschlag (nur Entscheidungsvorlage, im Ausschnitt nicht angebunden)

Anforderungen aus den Specs: Konto/Auth (später), Profil und Onboarding-Daten, Consent mit Zeitstempel und Löschrecht (Spec 1), Dokument-Upload mit KI-Lesbarkeitsprüfung (Spec 1), Kontakte mit Places-Suche (Spec 1), In-App-Kalender mit Kategorien, Status und Erinnerungen (Spec 2), Trainingsdaten und Feedback, Streak/Pfad (Spec 3), Push (Spec 2/3), Symptom-Check/Triage (Spec 4), KI-Chat (Spec 7), Health Social (Spec 8). Gesundheitsdaten (DSGVO Art. 9) → Datenhaltung in der EU, Auftragsverarbeitung, strenge Zugriffskontrolle.

**Empfehlung: Supabase (EU-Region, z. B. Frankfurt).**
- Relationales Postgres passt zu Kalender, Kontakten, Physio-Framework, Social-Graph (Spec 8) und Auswertungen (Spec 5).
- Zugriff über Row-Level-Security-Policies als SQL-Migrationen im Repo (versionierbar, testbar mit lokalem Supabase).
- Storage für Dokumente mit Policies; Edge Functions für KI-Aufrufe ohne Schlüssel in der App.
- Open Source und selbst betreibbar.

**Nachteile Supabase:** keine fertige Offline-Synchronisation in Flutter (eigener Cache/Sync nötig; der lokale Zustand dieses Ausschnitts bleibt nutzbar); Push braucht FCM/APNs; RLS erfordert Sorgfalt und Tests; kleineres Flutter-Ökosystem als Firebase.

**Alternative Firebase:** Offline-Persistenz eingebaut, FCM nativ, Auth/Crashlytics ausgereift. Nachteile: Dokumentmodell passt schlechter zu relationalen Abfragen; stärkere Anbieterbindung; Datenschutzbewertung für Gesundheitsdaten im Datenschutz-Konzept klären (keine Rechtsberatung).

Unabhängig von der Wahl: Datenschutz-Konzept (Anwalt) vor echten Patientendaten; Entscheidung trifft der Nutzer.

---

## 12. Verifikationskonzept

### 12.1 Befehle (im Verzeichnis `/home/user/test/app`)
```
export PATH=/opt/flutter/bin:$PATH
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze                                        # 0 Issues
flutter test --exclude-tags golden,matrix              # Unit, Widget, statische Regeln (schnell)
flutter test --tags matrix                             # gestufte Matrix (lang)
flutter test --tags golden                             # Goldens (Referenz: diese Linux-Umgebung)
flutter build web --release --no-web-resources-cdn -t lib/main_preview.dart
npx http-server build/web -p 8765 -s &
CHROME_EXECUTABLE=/opt/pw-browsers/chromium-1194/chrome-linux/chrome node tool/screens/shoot.mjs
```
Die Tags `golden` und `matrix` sind in `dart_test.yaml` deklariert (unbekannte Tags würden sonst eine Warnung erzeugen). Goldens werden mit `--update-goldens` erzeugt, vom `ui-designer` gesichtet und erst nach Nutzerfreigabe eingecheckt; sie sind nur in dieser Linux-Umgebung verbindlich. Laufzeit der Matrix wird in U2p gemessen und in jedem Paketbericht genannt.

### 12.2 Testarten

| Kürzel | Art | Werkzeug |
|---|---|---|
| **U** | Unit-Test reine Logik | `test/logic`, `test/theme` |
| **W** | Widget-Test | `FakeClock`, Fake-Stores, `tester.view.physicalSize`, `MediaQueryData`-Overrides (inkl. `viewInsets`, `padding`), `accessibilityFeaturesTestValue`, `handlePopRoute()`, `handleAppLifecycleStateChanged`, `sendKeyEvent`, `takeAnnouncements()`, `meetsGuideline(...)` |
| **M** | gestufte Matrix (n7) | **M-Layout** (alle Zustände aus 12.4 × 320×568, 390×844, 430×932 × Skalierung 1,0/2,0, normal): keine Layout-Exceptions, Tap-Ziele ≥ 48 dp, Abstand ≥ 8 dp zwischen Tap-Ziel-Rechtecken (paarweise, ohne verschachtelte), Schriftgröße ≥ 13 sp/Gewicht ≥ 400 aller `RenderParagraph`s, Primärbutton sichtbar und antippbar, Zone unten links frei und unten rechts nur Button-Gruppe (Pfad, UI-24 neu), letzter Eintrag erreichbar und nicht unter Primärbutton-Reihe, Nachrichten-Button oder Nav (Heute, UI-31 neu), Button-Gruppe vollständig sichtbar und nicht über der Nav (nur in Zuständen, in denen sie gebaut wird: Pfad/Heute Standard; nicht in Laden/Fehler, Onboarding, Vollbild-Routen; bei offenem Sheet/Dialog sichtbar unter dem Scrim, aber nicht bedienbar, A-43), **Inhalt nach Scrollen erreichbar** (jedes Tap-Ziel der Heute-Liste und jede Unit lässt sich in eine Lage scrollen, in der es vollständig sichtbar und per Hit-Test erreichbar ist, nicht unter Snackbar, Gruppe, Reihe oder Nav; Pflichtfälle `today-snackbar-cluster`, `path-cluster-bubble`, `path-cluster-hint` bei 320×568 und 2,0), Mindest-Sichtfläche zwischen Kopf und Overlays ≥ 120 dp (**Richtwert**: Unterschreitung wird als Befund an den `ui-designer` gemeldet, nicht still umgestaltet), Blase/`NodeHint` überdecken die Gruppe nicht, `BackdropFilter` ≤ 2 (Pfad/Heute) bzw. 0 (Chat/Nachrichten), Chat-Fuß ≤ 40 % der Höhe, Glow-Alpha-Regel 8.2. **M-Modus** (alle Zustände × 390×844 × 1,0 × {HC, RM}): HC-Flächen/kein Blur/kein Glow, RM ohne laufende Animation nach 121 ms. **M-Kontrast** (alle Zustände × 390×844 × 1,0 × {normal, HC}): `textContrastGuideline`, `labeledTapTargetGuideline`. Zusätzlich 768×1024 für `ob1-name`, `path-active`, `today-standard`, `chat-manny`, `messages` (ContentFrame, B-3). Fallzahlen sind **Richtwerte** (ca. 65 Szenarien: M-Layout ca. 400, M-Modus ca. 130, M-Kontrast ca. 130); die tatsächliche Zahl und Laufzeit meldet U2p |
| **G** | Golden | alle Zustände bei 390×844 normal; Auswahl bei 320×568, 200 %, HC, Notch-Padding, Tastatur-Szenarien, Typo-Tafel |
| **C** | Code-Suche als Test | `test/static/code_rules_test.dart` (12.3) |
| **S** | Web-Screenshot | `tool/screens/shoot.mjs` (12.5): Sichtprüfung `ui-designer`/`reviewer`, Pixel-Pipette, Pixel-Kontrast |
| **R** | Code-Review | `reviewer` mit Checkliste |
| **D** | Gerät/Emulator | **hier nicht prüfbar**; offener Prüfpunkt an den Nutzer |

### 12.3 Statische Regeln (Test C)
1. Kein `Color(0x`, `Color.fromARGB`, `Colors.` (Ausnahme `Colors.transparent`), `fontSize:` außerhalb `lib/theme/`.
2. Keine Zahl-Literale außer `0` in `EdgeInsets.*(`, `SizedBox(width:/height:`, `BorderRadius.circular(`, `Duration(milliseconds:`, `Positioned(left:/top:/right:/bottom:/width:/height:`, `Container(width:/height:`, `BoxConstraints(`, `BoxShadow(`, `Border.all(width:`, `.withValues(alpha:` und `.withOpacity(` außerhalb `lib/theme/` (KONVENTIONEN Regel 1; MINOR-6) (`EdgeInsets.zero`, `SizedBox.shrink()` erlaubt; Painter-Geometrie in `manny.dart` explizit ausgenommen).
3. `BackdropFilter` nur in `cura_blur.dart`; `CuraBlur` nur in `floating_nav.dart`, `manny_bubble.dart`, `cura_sheet_route.dart`.
4. `statusError`, `catFrist`, `tri*` nur in Fehler-/Status-Widgets (Allowlist: Fehleransichten Pfad/Heute, Löschfehler im Dialog); nie in `PillButton`/`CuraChip` oder Widgets mit `onPressed`/`onTap`.
5. `accent` nie als Textfarbe (`TextStyle(color: …accent)` / `.copyWith(color: …accent)`) außer in einer Allowlist von Dateien, deren Text nachweislich auf `bg` liegt; in `cura_dialog.dart`, `cura_snackbar.dart`, `node_hint.dart`, `glass_card.dart`-Nachfahren und im DatePicker-Theme nur `accentHi`/`text1` (Brief-E-2). `accent`/`accentHi` nicht in Fehler-/Status-Widgets. Begründung UI-4: Die Regel deckt **alle** Codepfade ab, auch Zustände, die kein Matrix-Szenario rendert; `textContrastGuideline` (M-Kontrast) und Review ergänzen.
6. `ChoiceCard`, `CuraTextField`, `DateCard` je genau eine Klassendefinition, von Onboarding und Sheet importiert (UI-53).
7. `lib/logic/**` und `lib/l10n/**` importieren nichts aus `package:flutter` und **auch nicht `dart:ui`** (bewusst ausgeschlossen, damit die Logik auf reiner Dart-VM testbar bleibt; Konvention 3).
8. Sichtbare und vorgelesene Texte nur aus `strings_de.dart`: String-Literale (einfache **und** doppelte Anführungszeichen) in `Text(`, `Semantics(label:`, `Tooltip(message:`, `hintText:`, `labelText:`, `semanticsLabel:` außerhalb dieser Datei verboten.
9. Kein `Ticker`/`AnimationController` in `glow_background.dart` und `manny.dart`.
10. Ton (UI-36/69) auf `strings_de.dart`: Wortliste Sie-Form (`Ihr`, `Ihre`, `Ihren`, `Ihrem`, `Ihnen`; `Sie` großgeschrieben mitten im Satz ist immer ein Treffer; `Sie` am Satzanfang ist mehrdeutig und muss in einer Allowlist begründet stehen) und Wortliste klinischer Begriffe (z. B. „Patient", „Indikation", „Therapieplan", „Compliance", „Proband"; Liste vom `ui-designer` zu bestätigen).
11. Kein Abschneiden (B-9): kein `TextOverflow.ellipsis`/`TextOverflow.clip`/`TextOverflow.fade`, kein `FittedBox` um Text, `maxLines` nur in einer Allowlist mit Tooltip-Alternative (derzeit leer).
12. Ergänzung 2 (UI-72, UI-78, UI-85): In `manny_chat_button.dart`, `messages_button.dart`, `action_cluster.dart`, `lib/ui/chat/**`, `lib/ui/messages/**`, `chat_*.dart`, `example_notice.dart` kein `accent` (auch nicht `accentHi` außer über `MannyPlaceholder`), kein `CuraBlur`/`BackdropFilter`, kein `GlowBackground` außer im `ChatScreenScaffold`, kein `statusError`/`catFrist`/`tri*`; im Manny-Chat kein `Icons.mic*`, kein Text „Neuer Chat", kein Menü-Icon.
13. Jede Datei unter `lib/ui/messages/` beginnt mit dem Kommentar „Unverbindlicher Platzhalter, keine Spec" (UI-84).
14. `lib/ui/messages/**` importiert weder `chat_model.dart` noch `manny_chat_source.dart` (UI-83, KS-10).
15. `lib/ui/chat/**`, `lib/ui/messages/**` und `lib/data/manny_chat_source.dart` referenzieren weder `StateStore`/`SharedPreferences*` noch mutierende `AppController`-Methoden (UI-82).
16. `ChatComposer` enthält kein `TextField`/`EditableText` und keinen Parameter für eine aktive Variante (Nutzerentscheidung Ergänzung 2 Abschnitt 8).

### 12.4 Zustandsliste (für M, G, S; benannte Szenarien in `lib/dev/scenarios.dart`)
Onboarding: `ob1-empty`, `ob1-name`, `ob1-keyboard`, `ob2`, `ob3-none`, `ob3-acl`, `ob3-other`, `ob3-other-keyboard`, `ob4-empty`, `ob4-date`, `ob1-deleted-snackbar`, `ob1-corrupt-snackbar`, `ob-mic-hint`.
Pfad: `path-loading`, `path-error`, `path-active` (Woche 5, Streak 12, Freezes 2), `path-frozen`, `path-reset`, `path-bubble-greeting`, `path-bubble-danger`, `path-bubble-restart`, `path-celebration`, `path-hint-locked`, `path-hint-done`, `path-week1`, `path-end`, `path-header-wrap` (Skalierung 1,2).
Heute: `today-loading`, `today-error`, `today-standard` (Mi, Physio-Beispiel), `today-friday` (Arzt + Physio), `today-weekend` (keine Termine), `today-10`, `today-30`, `today-empty`, `today-done`, `today-empty-done`, `today-snackbar-removed`, `today-snackbar-logged`, `today-mode-sheet`, `today-custom-dialog`, `today-custom-dialog-keyboard`, `today-newday-snackbar`.
Deine Daten: `data-sheet`, `data-sheet-other`, `data-sheet-dirty`, `data-discard-dialog`, `data-delete-dialog`, `data-delete-busy`, `data-delete-error`, `data-sheet-keyboard`.
Ergänzung 2 (neu): `path-cluster-bubble` (Blase nahe der Gruppe, Wechsel über Manny), `path-cluster-hint` (`NodeHint` an einer Unit nahe der Gruppe), `path-scrolled-bottom` (unterste Unit über die Gruppe geschoben), `path-sheet-open` (Gruppe unter Scrim), `today-cluster` (= `today-standard` mit Reihe und Nachrichten-Button, bis Listenende gescrollt), `today-done-cluster`, `today-snackbar-cluster` (Snackbar über der Gruppe), `chat-manny`, `chat-manny-scale15` (Fuß-Regel ab 1,5), `messages`, `messages-scale15`, `example-chat-physio`, `example-chat-family`, `example-chat-doctor`. Die Pfad-/Heute-Szenarien aus v1.1 zeigen ab U3 automatisch die Button-Gruppe.
Tastatur-Szenarien (B-10, nur W/G): 320×568 mit `viewInsets.bottom = 300`: Primärbutton bzw. „Speichern"/„Hinzufügen" sichtbar, fokussiertes Feld sichtbar.

### 12.5 Web-Screenshot-Pipeline (S)
- `main_preview.dart` liest URL-Parameter: `scenario` (seedet `InMemoryStore`; `live` = echter Store für Reload-Prüfungen), `now` (ISO-Ortszeit für `FakeClock`), `scale`, `hc=1`, `rm=1`, `a11y=1` (`SemanticsBinding.instance.ensureSemantics()`), `dumpText=1` (gibt nach dem ersten Frame per `print` eine JSON-Liste aller `RenderParagraph`-Rechtecke mit Textfarbe und Untergrundklasse aus). Wird nur mit `-t` gebaut.
- `shoot.mjs`: Playwright, `timezoneId: 'Europe/Berlin'`, `locale: 'de-DE'`, `deviceScaleFactor: 2`. Je Szenario: Viewports 320×568, 390×844, 430×932 (Querformat 568×320/844×390 als Stichprobe; 768×1024 für `ob1-name`, `path-active`, `today-standard`), Varianten `normal`, `scale2`, `hc`, `rm`. CDP-Simulation bei 390×844: `achromatopsia` für alle Szenarien (UI-18); `protanopia`, `deuteranopia`, `tritanopia` für `today-standard`, `today-friday`, `path-active`, `path-frozen`, `ob3-acl`, `messages` (Avatar-Ringe Physio/Ärzte, UI-19/UI-79). Vergleich mit den Orientierungsbildern `pfad-v4.png`, `heute-v4.png`, `manny-chat-v1.png`, `nachrichten-v1.png`, `nachrichten-chat-v1.png` durch den `ui-designer` (kein Pixelvergleich). Abläufe Ergänzung 2: Manny-Button → Chat → `page.goBack()`; Nachrichten-Button → Zeile → Beispiel-Chat → zurück → zurück (landet auf dem Ausgangs-Tab). Interaktionen per Koordinaten bzw. ARIA bei `a11y=1`. Browser-Zurück per `page.goBack()` (4.3).
- **Pixel-Pipette (UI-2):** an einer glowfreien Stelle `#0E131A`, im Primärbutton `#D9622B`, in einem Titel `#F2F0EB`, jeweils Toleranz ±1 je Kanal (PIL).
- **Pixel-Kontrast (UI-7, Brief-E-1):** Für jeden Text aus `dumpText` mit Glow-Alpha > 0 wird im Screenshot der Hintergrund als Median der Pixel im Text-Rechteck gemessen, die nicht der Textfarbe (±12) entsprechen; WCAG-Kontrast Textfarbe/Hintergrund wird gegen 4,5 geprüft und als Tabelle ausgegeben.
- Ausgabe: `app/build/screens/<variant>/<viewport>/<scenario>.png`, `index.html` (Kontaktbogen), `contrast.csv`; nicht eingecheckt.
- **Offen, in U2p zu klären:** (a) ob Flutter/CanvasKit mit `page.clock.install` weiter rendert – sonst nur `now`-Parameter plus Tabwechsel; (b) ob das Browser-HC-Signal (`forcedColors: 'active'`) ankommt – sonst nur `hc=1`; (c) Laufzeit des Screenshot-Laufs (Anzahl Bilder ca. 65 Szenarien × 3 × 4 + Simulationen).

### 12.6 Plattformunterschiede Web vs. Mobile

| Aspekt | Web (Prüfumgebung) | Android/iOS | Folge |
|---|---|---|---|
| `BackdropFilter` | CanvasKit, funktioniert; Performance nicht repräsentativ | GPU (Impeller) | Optik im Web, UI-10 nur Gerät |
| Speicher | `localStorage` je Origin | DataStore / NSUserDefaults | Neustart im Web = Reload |
| Zurück-Taste | Browser-Zurück → `popRoute` (in U2b geprüft) | Android-Taste/Geste; iOS keine | maßgeblich W (`handlePopRoute`) |
| Lifecycle | `visibilitychange` ≈ hidden/resumed | echtes Pausieren/Fortsetzen | Resume per W, Gerät D |
| Textskalierung | `scale`-Parameter (linear) | System (Android 14 nichtlinear) | Web prüft Worst Case |
| Hoher Kontrast | `hc=1`-Override; Browser-Signal offen | iOS 13+, Android API 34+ | Override/W; Systemsignal D |
| Reduzierte Bewegung | `prefers-reduced-motion`; zusätzlich `rm=1` | Android `disableAnimations`; iOS `reduceMotion` | `CuraMotion` liest beide |
| Safe Areas | keine | vorhanden | W/G mit `padding`/`viewPadding` |
| Tastatur | keine Soft-Tastatur | Soft-Tastatur | W mit `viewInsets`, Gerät D |
| Screenreader | ARIA-Baum (`a11y=1`) | TalkBack/VoiceOver | Labels W/S; Bedienbarkeit D |
| Zeitzone/Uhr | `timezoneId`, `page.clock` (offen) | Gerätezeit | Logik U/W mit `FakeClock` |
| Ansagen | `sendAnnouncement` → ARIA-Live | TalkBack/VoiceOver | W (`takeAnnouncements`), Snackbar zusätzlich Live-Region |

---

## 13. Zuordnung UI-1 … UI-89

„Prüfung": Kürzel aus 12.2. **[D-offen]** = auf echtem Gerät zu prüfen, hier nicht prüfbar.

| ID | Umsetzungsort | Prüfung |
|---|---|---|
| UI-1 | `lib/theme/*`, alle Komponenten | C (Regeln 1, 2); R |
| UI-2 | `tokens.dart`, `cura_colors.dart` | U (Token-Dump exakt); S (Pipette ±1) |
| UI-3 | `contrast.dart`, `test/theme/contrast_test.dart` | U: alle Paare aus Brief 3.1, Ergänzung 4 und Errata-Tabelle (Glow 0/12/16/24 %, `bg`/Glas) aus Tokens per Alpha-Komposition; zusätzlich `accent` auf `surface-opaque` (4,42, als „nicht für Text" markiert) und `accent-hi` auf Glas bei 12 % (4,34–4,36, als „nicht für Text bei 12 %" markiert); Schwellen 4,5 Text / 3 Symbol/Rand; Test schlägt fehl, wenn ein als Text verwendetes Paar darunter liegt |
| UI-4 (Brief-E-2) | Komponenten mit Akzent-Text, DatePicker-Theme | C (Regel 5, Begründung dort); M-Kontrast; R |
| UI-5 | `cura_typography.dart` | U (alle Stile ≥ 13 sp, ≥ w400); M-Layout |
| UI-6 | `cura_blur.dart`, Nav, Blase, Sheet | C (Regel 3); M-Layout (≤ 2) |
| UI-7 (Brief-E-1) | `glow.dart`, `glow_background.dart` | W (Baum: `ExcludeSemantics` + `RepaintBoundary`, keine Animation, Spitzen 0,24/0,14); U (Alpha-Funktion); M-Layout (Alpha je `RenderParagraph` nach Untergrund ≤ 24/16/12 % plus Kontrast ≥ 4,5 für farbigen Text, 8.2); S (Pixel-Kontrast Glow-naher Texte) |
| UI-8 | `cura_motion.dart`, alle Übergänge, `TickerMode` je Tab | W (mit `disableAnimations` **und** `reduceMotion`, Systemsignal und Preview-Override: jeden Übergang auslösen, nach 121 ms `hasRunningAnimations == false`, auch mit inaktivem Tab im `IndexedStack`); M-Modus; C (Regel 9); [D-offen] Systemschalter |
| UI-9 | `darkHighContrast`, `CuraBlur`, `GlowBackground` | W (Füllung `#1B2129`, 0 Blur, kein Glow, keine Scheine; beide Wege); U (4,37 ≥ 4,3); M-Modus; G; [D-offen] Systemsignal |
| UI-10 | `PathView` | **[D-offen] nicht prüfbar hier**; vorbereitend C/W (kein Blur in Units, Glow gecacht) |
| UI-11 | `onboarding/` | W (Ablauf 1→4, „Schritt X von 4", Semantik nur Text) |
| UI-12 | `step1_name.dart` | W (disabled bei „" und „   ", aktiv bei „J"; Name in Manny-Texten) |
| UI-13 | `step2_consent.dart` | W (nicht überspringbar; Store `acceptedAt` = FakeClock-UTC, `version: prototype-0`; Link) |
| UI-14 | `step3_injury.dart`, `ChoiceCard` | W (4 Karten, Einfachauswahl, Haken, 2 dp, `accent-soft`; „Anderes" → optionales Feld); G |
| UI-15 | `step4_date.dart`, `DateCard` | W (disabled bis Auswahl; `lastDate` heute; `initialDate` ≥ `firstDate`; kein „Phase") |
| UI-16 | `MicButton`, `OnboardingFlow`, Store | W (Mikro auf allen Schritten; Hinweis; Zurück **je Schritt** einen Schritt zurück mit erhaltenen Eingaben, auch bei sichtbarer Blase (N-13); Schritt 1 → `SystemNavigator.pop`; Neustart = neu pumpen); S (Reload, `page.goBack()`) |
| UI-17 | gesamte UI | C (Regeln 4, 5); R |
| UI-18 | Kategorien, Auswahl, Streak | W (Label/Icon/„eingefroren"); S (`achromatopsia`, Checkliste je Paar: Physio/Arzt/Übung, gewählt/nicht gewählt, aktiv/eingefroren/Reset, aktuell/erledigt/gesperrt) |
| UI-19 | `CategoryCard` | W (Icon + Label je Kategorie); S (`protanopia`, `deuteranopia`, `tritanopia`; Szenarien `today-standard`, `today-friday`, `path-active`, `path-frozen`, `ob3-acl`) |
| UI-20 | `path_layout.dart`, `PathNode`, `PathView` | U (geschwungen); W (Größen, Icons, Ring, Linienarten 8.4); G |
| UI-21 | `PathScreen`, Polster 7.3 | W (alle 3 Viewports, inkl. `path-week1` und `path-end`: Mittelpunkt der aktuellen Unit bei **40–65 %** der Viewport-Höhe; Manny sitzt auf der Unit) |
| UI-22 | `PathHeader`, `StatPill` | W (Texte, Freeze 0/1/2, „eingefroren"; Pills ohne Tap-Ziel) |
| UI-23 | `MannyBubble`, `manny_occasions.dart` | W (X ≥ 48; Tipp irgendwo; Unit/Nav bedienbar; einmal pro Tag); U (≤ 2 Sätze mit Abkürzungs-Allowlist) |
| UI-24 (neu, Erg. 2) | `PathScreen`, `HomeShell`, `ActionCluster` | M-Layout (unten links über der Nav keine Overlay-/Fest-Elemente; unten rechts ausschließlich `MannyChatButton` + `MessagesButton`: Hit-Test aller nicht scrollenden Render-Objekte in der Zone) |
| UI-25 | `PathHeader`, Generator | W („Beispielpfad" für alle 4 Typen inkl. ACL); U |
| UI-26 | `TimeSegment`, `day_program.dart` | W (20 beim Erststart; Wechsel ändert Liste und Überschrift); U |
| UI-27 | `CategoryCard`, Heute, `CustomExerciseDialog` | W (Name, Wdh., Dauer, Aktionen, auch für eigene Übungen mit geleerten Feldern; Entfernen → „Rückgängig"; Tauschen) |
| UI-28 | `CategoryCard` | W (Farben `cat-*`, Titel, Uhrzeit, „· Beispiel"); G |
| UI-29 | Heute Leerzustand | W (Leer-Karte, „Training starten" disabled; Überschrift „ÜBUNGEN"; Leer + Erledigt: Button „Heute erledigt") |
| UI-30 | `TrainingModeSheet`, `logTraining` | W; U |
| UI-31 (neu, Erg. 2) | Heute, Scroll-Reserve 4.6 | M-Layout (bis zum Ende scrollen: letzte Karte und alle Aktionen „Tauschen“/„Entfernen“/„Eigene Übung“ vollständig über Primärbutton-Reihe, Nachrichten-Button und Nav; Reserve = gemessene Reihenhöhe + Nav + 16 + 56 dp; alle Viewports inkl. 320×568, Skalierung 2,0, auch bei umgebrochenem „Training starten“) |
| UI-32 | alle antippbaren Elemente | M-Layout (`androidTapTargetGuideline`, Abstände ≥ 8 dp automatisiert); [D-offen] Layout-Inspektor |
| UI-33 | alle Screens, `FloatingNav` | M-Layout (2,0 ohne Overflow, Primärbutton erreichbar, Nav ≤ 1,3); C (Regel 11); S |
| UI-34 | alle Screens, `MannyBubble` | M-Layout (320×568); W (Blase über Manny, im Bildschirm); S |
| UI-35 | Semantics, `FocusRing` | W (Labels, Dekoratives ausgeblendet, Tab-Reihenfolge, Fokus sichtbar); M-Kontrast (`labeledTapTargetGuideline`); S (ARIA); **[D-offen]** TalkBack/VoiceOver |
| UI-36 | `strings_de.dart` | C (Regeln 8, 10); U (≤ 2 Sätze); R (`ui-designer`) |
| UI-37 (präzisiert, Erg. 2) | Heute, `CuraSnackbar` | W (Sheet zu, „Heute erledigt“, Snackbar „Eingetragen.“ + „Rückgängig“ **12 dp über der Oberkante des Nachrichten-Buttons**, Aktion ≥ 48 dp, kein Überlapp mit Reihe/Gruppe/Nav) |
| UI-38 | `undo.dart`, Heute | W; U (S18) |
| UI-39 (Zusatz Erg. 2) | `CuraSnackbar`, `HomeShell` | W (`pump(7,9 s)`/`8 s`; `accessibleNavigation`; Fokus/Hover-Pause; Ende bei Tabwechsel/zweiter Snackbar **und beim Öffnen von Manny-Chat oder Nachrichten**; danach kein „Rückgängig“, Eintrag bleibt) |
| UI-40 | `manny_occasions.dart`, `PathScreen` | U; W |
| UI-41 (präzisiert, Erg. 2) | `CuraSnackbar` | W (opak, kein Blur, Position 12 dp über der Button-Gruppe, verdeckt weder Nav noch Reihe noch Gruppe, Live-Region, Label; gleiche Komponente für „Entfernt."); G |
| UI-42 | `day_rollover.dart`, `HomeShell`, Controller | W (FakeClock +1 Tag, `resumed`; zusätzlich: mutierende Aktion am neuen Tag wendet zuerst den Wechsel an; Eintrag über Mitternacht zählt für den Vortag, N-11); U; [D-offen] Gerätedatum |
| UI-43 | Store, `day_program.dart` | W (neu pumpen am selben Tag); S (Reload) |
| UI-44 | `HomeShell`, Snackbar | W (Snackbar 5 s, Heute-Routen geschlossen inkl. Trainings-Sheet, Undo verfallen, „Deine Daten" bleibt offen, keine Animation, Ansage) |
| UI-45 | `manny_occasions.dart`, `prefs.timeChoice` | U; W |
| UI-46 | `PathHeader`, `HeaderIconButton` | W (Position, 48 dp, Tooltip, Label, nicht auf Heute; 320×568 und 2,0: Umbruch, alles sichtbar); S |
| UI-47 | `DataSheet`, `CuraBlur` | W |
| UI-48 | `DataSheet`, `CuraSheetRoute` | W (Kopf/Fußleiste fix; Zurück/Escape; Fling auf Kopf vs. Scrollbereich; Fokus hinein und zurück, mit `mounted`-Prüfung) |
| UI-49 | `DataSheet`, `CuraDialog` | W; C |
| UI-50 | `DeleteDialog` | W (Abbrechen, Zurück, Escape, Scrim → unverändert; während `busy` wirkungslos, Doppeltipp nur ein Vorgang) |
| UI-51 | `AppController.deleteAll`, Navigation | W (Schritt 1 leer; Zurück erreicht Pfad/Sheet nicht; Snackbar 4 s; neu pumpen → Schritt 1; Consent erneut; danach Streak 0, Freezes 2, keine Einträge, Zeitwahl 20; Store enthält keinen Schlüssel aus `kAllStorageKeys`); S (Reload) |
| UI-52 | `DeleteDialog` | W (`FailingStore` → Icon + Text + „Nochmal versuchen", RAM unverändert; `SlowStore` → `pump(Duration(milliseconds: 301))` zeigt Fortschrittskreis, Button disabled; kein `pumpAndSettle` wegen endloser Fortschrittsanimation) |
| UI-53 | `DataSheet` | W; C (Regel 6) |
| UI-54 | `profile.dart`, `DataSheet` | U; W |
| UI-55 | `updateProfile`, `PathScreen` | W (inkl. Neuberechnung nach `path-week1`/`path-end`-Lage: aktuelle Unit bei 40–65 %; `pulsePending`/Feier/`day.done` nach 7.2); U |
| UI-56 | `DataSheet` | W |
| UI-57 | `DataSheet`, `DiscardDialog` | W (alle Schließwege inkl. Wischen auf dem Kopf) |
| UI-58 | `DataSheet` | W/G (`data-sheet-keyboard`); **[D-offen]** echte Tastatur |
| UI-59 (neu, Erg. 2) | `PathNode`, `MannyPlaceholder.hitPath`, `HomeShell` | W (Tipp auf die aktuelle Unit außerhalb der Manny-Fläche → Tab Heute aktiv; Tipp auf Manny → Manny-Chat geöffnet, Tab unverändert; sichtbare Blase schließt in beiden Fällen) |
| UI-60 | `NodeHint`, Generator | W; U |
| UI-61 | `NodeHint` | W |
| UI-62 | `NodeHint` | W |
| UI-63 (letzter Satz neu, Erg. 2) | `PathNode` | M-Layout (≥ 48 dp; unten links frei, unten rechts nur Button-Gruppe; keine Snackbar auf dem Pfad); W (Fokus, Enter/Leertaste, Labels) |
| UI-64 | `CuraMotion`, Routen, Snackbar, Hinweis | W (RM, beide Wege); M-Modus |
| UI-65 | `darkHighContrast` | W; M-Modus; G |
| UI-66 | Sheet, Dialoge, Snackbar | M-Layout; W (Tastatur-Szenarien); S |
| UI-67 | neue Komponenten | C (Regeln 1–5); U (`scrim` 60/72 %) |
| UI-68 | Routen, Semantics, Ansagen | W (Routennamen, Fokusrückgabe, `takeAnnouncements`, Tastaturbedienung); S (ARIA); **[D-offen]** TalkBack/VoiceOver |
| UI-69 | `strings_de.dart` | C (Regeln 8, 10); R (`ui-designer`) |

**Prüfliste ergänzend zu den Kriterien (B-8, für `ui-designer`-Abnahme):** Primärbutton-Schein (HC: aus); Nav-Schatten und Ausblend-Verlauf; gepunktete Zukunftslinie Weiß 22 % 3 dp, erledigte Linie 3 dp rund, Schein der aktuellen Unit; Snackbar-Dauern 4/5/8 s; Onboarding-Seitenwechsel Schiebung 24 dp + Einblenden, Gegenrichtung bei Zurück; Pressed-Zustände (Neutral hell → Weiß, Umriss → Weiß 10 %); Freeze-/Streak-Pill ohne Tap-Ziel. Jeder Punkt hat einen W- oder G-Test im Paket des jeweiligen Bausteins (U2a, U2b, U3a, U3b).

**Ergänzung 2 (UI-70 … UI-89):**

| ID | Umsetzungsort | Prüfung |
|---|---|---|
| UI-70 | `MannyChatButton`, `ActionCluster`, `PrimaryActionRow`, `HomeShell` | W (auf Pfad und Heute im Standard-Zustand sichtbar, in `path-loading`/`path-error`/`today-loading`/`today-error` und beim `StartGate`-Fehler nicht gebaut (A-43), Kreis 56 dp, Füllung/Rand per Widget-Eigenschaften, Tooltip und Label „Manny, Chat öffnen“, Tipp öffnet `MannyChatRoute`; im Onboarding, Chat, Nachrichten, Beispiel-Chat nicht im Baum; bei offenem Sheet/Dialog weder Semantik-Knoten noch fokussierbar noch per Tap erreichbar); G |
| UI-71 | `MessagesButton`, `ActionCluster` | W (8 dp über der Oberkante des Manny-Buttons, rechtsbündig per Rechteckvergleich, **auch im Umbruchszustand** von „Training starten“ bei 320 dp und Skalierung ≥ 1,3, wenn die Reihe höher als 56 dp ist; 48 dp; Tooltip/Label „Nachrichten“; öffnet `MessagesRoute`; Sichtbarkeit wie UI-70, in Laden/Fehler nicht gebaut) |
| UI-72 | beide Buttons | M-Layout/W (Hit-Area ≥ 48, `focus-ring` bei Tastaturfokus, Enter/Leertaste, Pressed-Überlagerung); C (Regel 12: kein Blur/Glow/Akzent); W (HC: `border-control-hc`, Schatten bleibt) |
| UI-73 | `PrimaryActionRow`, `CuraSnackbar` | W (Breite Primärbutton = Breite − 96 dp, bei 320 dp 224 dp; unten bündig; bei 2,0 wächst nur der Primärbutton; Zustände „Heute erledigt“/deaktiviert; Snackbar 12 dp über der Gruppe); M-Layout; G |
| UI-74 | `MannyPlaceholder.hitPath`, `PathScreen` | W (Tipp in die Manny-Form und in den 8-dp-Rand → Chat, Tab unverändert; Tipp unterhalb der Standlinie bzw. außerhalb → Unit-Verhalten: aktuell → Heute, gesperrt/erledigt → `NodeHint`; Blase schließt und erscheint am selben Tag nicht erneut; Manny hat keinen Fokusstopp und keine Button-Semantik, Fokus-Traversal überspringt ihn) |
| UI-75 | `MannyBubble`, `NodeHint`, `PathLayout`-Polster | W (`path-cluster-bubble`: Blase über Manny, kein Schnitt mit dem Gruppen-Rechteck; `path-cluster-hint`: Hinweis weicht aus, Pfeil an der Unit); M-Layout (`path-scrolled-bottom`: unterste Unit oberhalb der Gruppe positionierbar) |
| UI-76 | `MannyChatScreen`, `ChatMessageList`, `ChatHeader`, `ExampleNotice`, `ExampleMannyChatSource` | W (Kopf, Karte „Beispielverlauf“/„So sieht dein Chat bald aus.“, drei Nachrichten mit Namen aus dem Onboarding; Manny ohne Blase mit Emblem je Block, Nutzer-Blase rechts ≤ 80 %; Rendern aus `ChatMessage`-Objekten; **Wachstums-Test:** Test-Widget ersetzt die Nachrichtenliste schrittweise durch eine mit wachsendem Text der letzten Nachricht: kein Overflow, letzte Zeile sichtbar, solange am Ende; nach Hochscrollen bleibt der Offset unverändert); G; U (KS-4) |
| UI-77 (Nutzerentscheidung Erg. 2 §8) | `ChatComposer` (nur deaktiviert) | W (Hinweiszeile „Schreiben kann ich bald, heute noch nicht.“, Leiste „Schreib Manny“, Senden-Kreis deaktiviert, Disclaimer wörtlich; Tipp auf Leiste/Senden: kein `TextInput`-Kanal geöffnet (`tester.testTextInput.isVisible == false`), keine Zustandsänderung; Leiste nicht fokussierbar, aber Semantik-Label vorhanden; Hinweis und Disclaimer immer im Baum sichtbar). **Kein** Test „darf senden = ja“ (entfällt); C (Regel 16) |
| UI-78 | `MannyChatScreen` | C (Regel 12: kein Mikro, kein „Neuer Chat“, kein Menü, keine Chips, kein `accent`); S (`chat-manny`) |
| UI-79 | `MessagesScreen`, `ContactRow`, `example_contacts.dart` | W (Kopf, Karte „Beispiel-Ansicht. Echte Chats folgen.“, vier Abschnitte als Semantik-Überschriften mit den sechs Kontakten; Avatar-Ringfarben; Vorschau = letzte Nachricht, umbrechend; Zeile ≥ 72 dp, ganze Zeile antippbar, `focus-ring`; kein Badge/Suche/Neuer Chat); S (inkl. Farbsehschwächen) |
| UI-80 | `ExampleChatScreen`, `ChatBubble` | W (je Kontakt: Kopf mit Avatar, Name, „[Rolle] · Beispiel“, Karte, Blasen rechts/links mit Semantik „Du: …“ bzw. „[Name]: …“, Hinweiszeile „Schreiben in Chats folgt bald.“, deaktivierte Leiste „Nachricht“, **kein** Disclaimer; Zurück → Übersicht → Ausgangs-Tab, für Start auf Pfad und auf Heute) |
| UI-81 | `strings_de.dart` | C (Regeln 8, 10 auf neue Texte); W (Disclaimer wörtlich „Manny ersetzt keine medizinische Beratung.“); C (Regeln 1, 2) |
| UI-82 | Chat/Nachrichten ohne Speicher, `DataEraser` | C (Regel 15); W (nach „Alles löschen“ und neuem Onboarding mit anderem Namen: Beispielverlauf mit neuem Namen, Store enthält nur Schlüssel aus `kAllStorageKeys`); U (KS-9: Löscher-Reihenfolge, Abbruch beim ersten Fehler, RAM unverändert) |
| UI-83 | `example_contacts.dart`, `lib/ui/messages/` | C (Regel 14); R |
| UI-84 | `lib/ui/messages/` | C (Regel 13); W („Beispiel“-Kennzeichnung in UI-79/80 sichtbar) |
| UI-85 | `CuraBlur`-Verwendung | C (Regeln 3, 12); M-Layout (Chat/Nachrichten/Beispiel-Chat: 0; Pfad/Heute mit Gruppe, Blase, Sheet, Snackbar: ≤ 2) |
| UI-86 | `CuraFullscreenRoute`, `HomeShell` | W (**A-39:** Chat bzw. Nachrichten offen, FakeClock +1 Tag, `AppLifecycleState.resumed` → keine Snackbar, `takeAnnouncements()` leer; nach Zurück zeigt Heute das neue Datum und frisches Programm, weiterhin ohne Snackbar; Fokus zurück auf Manny-Button/Nachrichten-Button/Kontaktzeile, mit `mounted`-Prüfung; Zurück via `handlePopRoute`, Escape via `sendKeyEvent`; RM: keine Schiebung, nach 121 ms keine laufende Animation; Undo-Fenster endet beim Öffnen); S (`page.goBack()`) |
| UI-87 | `darkHighContrast`, neue Bausteine | W/M-Modus (Buttons, Karten, Leiste, Blasen, Avatare `#1B2129` + `border-control-hc`, 0 Blur, kein Glow); M-Layout (Glow-Alpha-Regel auf Chat-/Nachrichten-Screens, 8.2) |
| UI-88 | `ChatFooterLayout`, `PrimaryActionRow`, Scroll-Reserven | M-Layout (320×568 und 2,0: keine Overflows, kein horizontales Scrollen, Leiste und Disclaimer erreichbar, Fuß ≤ 40 % der Höhe, ab 1,5 Hinweis/Disclaimer in der Liste; Pfad/Heute: beide Buttons vollständig sichtbar, Listenende frei); W (`chat-manny-scale15`, `messages-scale15`); S |
| UI-89 | Semantik, Fokus aller neuen Elemente | W (Labels aus Ergänzung 2 3.5; Fokusreihenfolge Pfad/Heute/Chat/Nachrichten per Tab-Taste wie 4.6; Routennamen; Überschriften-Semantik); S (ARIA); **[D-offen]** TalkBack/VoiceOver |

Hier nicht (vollständig) prüfbar: UI-10 vollständig; Geräteteil von UI-8, UI-9, UI-32, UI-35, UI-42, UI-58, UI-68, UI-89.

---

## 14. Meilensteine und Umsetzungspakete (für sonnet)

Sequenziell, ein Schreiber. Jedes Paket endet mit grünen Befehlen aus 12.1 (soweit Teile existieren), Matrix und Screenshot-Lauf für die **bis dahin vorhandenen** Szenarien (ab U2p), und einem Kriterien-Status.

| Paket | Inhalt | Ergebnis / Abnahme | Abhängigkeit |
|---|---|---|---|
| **U1a Fundament** | `flutter create` unter `app/` (android, ios, web; Org-Platzhalter F-12), Pakete, Fonts + OFL + Lizenzregistrierung, Lints, `dart_test.yaml` (Tags), Test-Support (FakeClock, Stores inkl. `CorruptStore`, Font-Loader, `flutter_test_config.dart`), Tokens + `ThemeExtension`s + `glow.dart` + `contrast.dart` + Kontrast-/Glow-/Token-Tests, `code_rules_test` (Regeln 1–16, anfangs gegen leere UI). **Maßkonstanten aus Brief-Ergänzung 2 (MINOR-6)** in `tokens.dart`/`cura_metrics.dart` als Ablage der Brief-Werte, keine neuen Design-Tokens: Manny-Button 56, Nachrichten-Button 48, Abstand Gruppe 8, Snackbar-Abstand 12, Rand 16, Senden-Kreis 40 (Hit-Area 48), Eingabeleiste Radius 28/Höhe ≥ 56, Hinweiskarte Radius 16/Innenabstand 10/14, Blasen Radius 20/Ecke 6/Innenabstand 12/16, Avatar 48 (Kopf 36, Emblem 26/34, Manny-Kopf im Button 38), Manny-Text-Einzug 36, Zeilenlänge 560, Kontaktzeile ≥ 72, Abstände 20/8, Schwellen 80 % (Blasenbreite), 40 % (Chat-Fuß), 1,5 (Textskalierung Mitscrollen), Manny-Hit-Rand 8, Schatten 0/6/16 Schwarz 40 % (`CuraShadow.actionButton`), Routen-Schiebung 24 | `flutter analyze` 0; UI-2 (U), UI-3, UI-5 (U), UI-67 (U) | Freigabe dieses Plans |
| **U1b Logik + State** | gesamte `lib/logic/` inkl. Migrationen/Fixtures, `AppState`-JSON, KS-1 `MannyTextSource`, KS-2 `FactRef`, KS-3 `MannyContext`, KS-4 `chat_model.dart`, `StateStore`/`PrefsStateStore`, KS-9 `DataEraser`-Liste, KS-5 `MannyChatSource` (nur `messages`), `AppController` (inkl. `_mutate` mit Tageswechsel zuerst, `deleteAll`-Ablauf über Löscher), `TransientUi` (Undo-Fenster) ohne UI; alle Unit-Tests aus Abschnitt 6.2 und 7 (S1–S25, 7.9, 7.10). **Größe:** das größte Logikpaket; eine **Zwischenstand-Rückmeldung** ist zulässig nach Teil 1 (`clock`, `plural`, `streak`, `path_*`, `placeholder_pools`, `day_*`, `undo`, `manny_occasions`, `profile` mit Tests) vor Teil 2 (`app_state`, `migrations`, Store/Löscher, KS-1–5, Controller, `TransientUi`) | alle U grün; UI-25/26/30/38/40/45/54 (U-Teil), UI-82 (U-Teil Löscher) | U1a |
| **U2a Bausteine (geteilt)** | genau diese Bausteine mit Widget-Tests und Goldens: `ContentFrame`, `GlowBackground`, `CuraBlur`, `GlassCard`, `PillButton` (Primär, Neutral hell, Umriss), `FloatingNav`, `MannyPlaceholder` (Posen, `crop`, `hitPath`), `MannyBubble`, `ChoiceCard`, `StepProgress`, `CuraTextField`, `DateCard`, `MicButton`, `HeaderIconButton`, `CuraSnackbar` + `SnackbarHost`, `CuraDialog`, `CuraLabel`, `FocusRing`, `MannyChatButton`, `MessagesButton`, `ActionCluster`; Typo-Tafel-Golden; B-8-Details der genannten Bausteine | UI-1, 4–9, 32, 35, 72 für diese Bausteine | U1b |
| **U2p Prüf-Infrastruktur (neu, Nutzerentscheidung)** | `main_preview.dart` (Preview-App mit URL-Parametern 12.5), Grundgerüst `lib/dev/scenarios.dart` (Szenario-Registry + Baustein-Szenarien), Matrix-Harness mit den Stufen M-Layout/M-Modus/M-Kontrast inkl. aller Prüffunktionen aus 12.2 (Glow-Alpha, Freie Zonen, Erreichbarkeit nach Scrollen, Abstände, Fuß-Anteil), `tool/screens/shoot.mjs` inkl. Pipette, Pixel-Kontrast, CDP-Simulationen, Kontaktbogen; Klärung der Web-Punkte 12.5 (a–c) und gemessene Laufzeiten | Harness läuft für die U2a-Szenarien grün; Bericht mit Fallzahlen/Laufzeiten; erster Screenshot-Lauf | U2a |
| **U2b Routen + Onboarding + Shell** | `CuraSheetRoute`, `CuraDialogRoute`, `StartGate` (inkl. Neustart bei unlesbaren Daten und Fehlerzustand), Onboarding komplett, `HomeShell` mit Nav, `TickerMode`, Zurück-Logik (inkl. `page.goBack()`), Lifecycle-Haken; Tabs mit einfachen Platzhalter-Inhalten, bis U3a/U3b sie ersetzen; Szenarien `ob*` | UI-11–17, 33, 34 für Onboarding; UI-70/71 (nicht im Onboarding); Matrix + Screenshots für `ob*` | U2p |
| **U2c Chat + Nachrichten** | `CuraFullscreenRoute`, `ChatScreenScaffold`, `ChatHeader`, `ExampleNotice`, `ChatMessageList` (alle Enum-Werte, Ende-Folgen), `ChatComposer` (nur deaktiviert), `ChatFooterLayout`, `ContactRow`, `ChatBubble`; `MannyChatScreen`, `MessagesScreen`, `ExampleChatScreen`, `example_contacts.dart`; `ChatSourceScope`; Anbindung im `HomeShell`: `ActionCluster` (Modus `path`) über dem Pfad-Tab, Öffnen/Schließen inkl. `endUndoWindow()`, Fokusrückgabe, Sichtbarkeit unter Sheets, Tageswechsel bei offenem Chat (A-39); Szenarien `chat-*`, `messages*`, `example-chat-*` | UI-70, 71, 76–89 (soweit ohne fertige Pfad-/Heute-Screens prüfbar); Matrix + Screenshots für die neuen Szenarien | U2b |
| **U3a Pfad** | `PathScreen`, `PathView`, `PathNode`, `PathHeader`, `StatPill`, `NodeHint` (alle nur hier), Layout mit Zentrier-Polster und Gruppen-Reserve, Scroll, Manny-Tipp, Anlässe über `MannyTextSource`, Feier/Puls, Unit-Tipps, Kollisionen und Rückfall (4.6); Szenarien `path*` | UI-18–25, 59–63, 74, 75; UI-24 neu; Matrix + Screenshots für `path*` | U2c |
| **U3b Heute** | `TodayScreen`, `PrimaryActionRow`, `CategoryCard`, `CuraChip`, `TimeSegment`, `DashedAction`, `TrainingModeSheet`, `CustomExerciseDialog` (alle nur hier), Nachrichten-Button (`ActionCluster` Modus `today`, 8 dp über dem Manny-Button), Snackbar 12 dp über der Gruppe, Scroll-Reserve (UI-31 neu), Tageswechsel inkl. Eintrag über Mitternacht in der Reihenfolge aus 4.6; Szenarien `today*` | UI-26–31, 37–45, 71 (Umbruchszustand), 73; Matrix + Screenshots für `today*` | U3a |
| **U4 Deine Daten + Abschluss** | `DataSheet`, `DeleteDialog`, `DiscardDialog` (Profil ändern, Verwerfen, Löschen inkl. Sperre/Fehler/Laden, Gruppe unter dem Scrim), restliche Szenarien in Matrix/Goldens/Screenshots, Kriterienbericht UI-1…UI-89 mit K-1, K-2 und [D-offen]-Prüfliste für den Nutzer | UI-46–58, 64–69, 82 (W-Teil), Rest von 70–89; vollständiger Bericht | U3b |

**Reihenfolge (verbindlich):** U1a → U1b → U2a → U2p → U2b → U2c → U3a → U3b → U4. Jeder Baustein aus Abschnitt 9 ist genau **einem** Paket zugeordnet (Tabelle oben); Pakete nach U2p bringen ihre Szenarien in die Registry und lassen Matrix und Screenshot-Lauf für ihre Szenarien laufen. Zwischenstand-Rückmeldungen sind in jedem Paket zulässig, wenn sie als solche gekennzeichnet sind (kein `ERLEDIGT` vor Abschluss aller Paketkriterien).

Begründung der Schnitte (M5, v1.2/v1.3): U1a/U1b trennen Infrastruktur von Logik; die KS-Teile sind klein, rein Dart und gehören zur Logik (U1b). U2a liefert nur die geteilten Bausteine; die **Prüf-Infrastruktur ist ein eigenes Paket U2p** (Nutzerentscheidung v1.3), damit U2a klein bleibt und jedes folgende Paket seine Szenarien sofort prüft. Screen-spezifische Bausteine liegen bei ihrem Screen-Paket (U3a/U3b/U4), damit es keine Doppelzuordnung gibt. Die Chat-/Nachrichten-Bausteine und -Screens bilden ein **eigenes Paket U2c**, weil sie ein eigener Schreibbereich mit eigenen Szenarien sind und U2a/U2b sonst zu groß würden. **U3 wird geteilt** (U3a Pfad, U3b Heute): Mit Manny-Tipp, Button-Gruppe, Reserven und Kollisionsregeln wäre ein gemeinsames Paket für ein sonnet-Paket zu groß. Die Kopplung über Eintragen/Rückgängig/Feier liegt in der Logik (U1b) und ist in U3a über Szenario-Zustände prüfbar; U3b prüft den Ablauf Heute → Pfad am Ende. U4 enthält nur den Rest und den Bericht. Reviews: nach U1b (Logik inkl. KS), nach U2p (Bausteine und Prüf-Infrastruktur zusammen), nach U2c (Chat-Bausteine, Fokus, Speicherfreiheit), nach U4 (gesamt).

---

## 15. Externe Schritte

Für diesen Ausschnitt **keine** Aktionen gegen Konten oder Cloud-Dienste nötig.

Hinweise (Netzwerkzugriffe in U1a, keine Konto-Aktionen): `flutter pub get` (pub.dev); Download der Font-Dateien und `OFL.txt` von `raw.githubusercontent.com/google/fonts/main/ofl/...` (OFL 1.1).

Später, jeweils einzeln zur Freigabe: Backend-Projekt (Abschnitt 11), echte Paket-/Bundle-ID (F-12), Signaturschlüssel, Store-Einträge. Gerätetests ([D-offen]) brauchen auf einem Rechner des Nutzers Android-SDK/Emulator bzw. Xcode und `flutter run` / `flutter run --profile`.

**Vom Nutzer einzutragende Werte:** keine.

---

## 16. Annahmen

| Nr. | Annahme | Auswirkung |
|---|---|---|
| A-1 | Start nach abgeschlossenem Onboarding auf Tab Pfad | Start-Tab |
| A-2 | Erneutes Bestätigen des Consent überschreibt den Zeitstempel | Consent |
| A-3 | Zurück auf Onboarding Schritt 1 schließt die App – **durch N-13 bestätigt** | Android |
| A-4 | Schreibfehler außer beim Löschen ohne UI; nächster Schreibvorgang versucht erneut | kein Fehler-UI |
| A-5 | App-Neustart beendet das Rückgängig-Fenster | Undo |
| A-6 | (neu) Plattform-Lesefehler → Fehlerzustand im Pfad-Layout mit „Nochmal versuchen"; unlesbarer Inhalt → automatischer Neustart (N-12) | Fehlerfall |
| A-8 | Streak 0: keine Freeze-Nutzung, Anzeige wie „Reset", keine Neustart-Nachricht ohne vorherigen Streak | Erststart |
| A-9 | Zurückgestellte Uhr: keine Streak-Auswertung; Eintragen setzt nur `done` (7.5, S25) | Randfall |
| A-10 | Pfadstruktur 7.2 (Phasen-Abschluss auch Woche 12, danach Boss) | Pfadbild, F-8 |
| A-11 | Nach erledigter Woche rückt „aktuell" vor; ohne verbleibende Unit sitzt Manny auf der letzten erledigten (K-1) | Fortschritt |
| A-12 | Nur Name oder nur Freitext → keine Neuberechnung; Typwechsel allein → Neuberechnung | Profil |
| A-13 | Kurznamen: „Kreuzband", „Sprunggelenk", „Muskelfaser", „Reha" (Vorschlag ui-designer) | Kopfzeile |
| A-14 | Screenreader-Labels für Wochenziel/Phasen-Abschluss analog zu Brief-Beispielen | Semantik |
| A-15 | Tauschen zyklisch | Heute |
| A-16 | „Beispiel" in der Meta-Zeile, Screenreader „Beispieltermin, …"; Ort des Arzt-Beispiels vom ui-designer | Heute |
| A-17 | Neustart-Text „Neuer Anlauf, [Name]. Dein Pfad bleibt, der Streak startet heute neu.", Pose `motiviert` (Vorschlag ui-designer) | Manny |
| A-19 | Nach „Heute erledigt" bleiben Programmänderungen bedienbar (ui-designer: bleibt) | Heute |
| A-20 | Priorität der Blasen: Feier > Neustart > Begrüßung > Streak-Gefahr > Fakt | Manny |
| A-21 | Begrüßung einmalig nach Onboarding | Manny, F-17 |
| A-22 | Beispielfakt einmal pro Tag beim ersten Pfad-Besuch ohne anderen Anlass, nur wenn heute noch nicht trainiert, kein Rotieren (Vorschlag ui-designer) | Manny |
| A-23 | Segment nicht gewählt DM Sans 16/24, 400 `text-2`; gewählt 700 `text-1` | Typo |
| A-24 | OFL-Texte zusätzlich in `LicenseRegistry` | Lizenz |
| A-25 | Icon-Auswahl Abschnitt 9 (nach ui-designer) | Optik |
| A-26 | Texte als Dart-Konstanten statt `gen-l10n` | Struktur |
| A-27 | DatePicker: `firstDate` = min(heute − 2 Jahre, gespeichertes Datum), `lastDate` = heute, `initialDate` = gespeichertes Datum oder heute (immer ≥ `firstDate`) | Eingabe, F-7 |
| A-29 | (erledigt durch B-8: „Entfernt." 8 s wie „Eingetragen.") | – |
| A-30 | Screenreader-Fokus auf Sheet-Titel, Tastatur beginnt mit „Schließen" (ui-designer: kein Konflikt) | Fokus |
| A-31 | Tageswechsel beim Wechsel auf Heute → Heute gilt als sichtbar (Snackbar) | Ergänzung 3.4 |
| A-32 | Jeder Onboarding-Schritt zeigt beim Betreten seine Manny-Blase erneut | Onboarding |
| A-33 | Ladeansicht nicht künstlich verlängert/verkürzt | Laden |
| A-34 | (neu) Hinweis nach unlesbaren Daten: Snackbar „Deine gespeicherten Daten waren nicht lesbar. Du startest neu." über der Mikrofon-Zeile, 4 s, ohne Aktion, Live-Region | N-12 |
| A-35 | (neu) Für die Glow-Regel gelten E2-Flächen (Nav, Blase, Sheet) streng als „Glas" | UI-7-Test |
| A-36 | (neu) Wischgeste des Sheets nur auf dem fixen Kopf; Schwelle 30 % Höhe oder 700 dp/s | Sheet |
| A-37 | (neu) Klinische Wortliste für Regel 10 als Startliste, vom ui-designer zu ergänzen | Tonprüfung |
| A-38 | (v1.2, **vom ui-designer bestätigt**) Wurde der Manny-Chat über Manny auf dem Pfad geöffnet (keine Fokusstation), geht der Fokus beim Schließen an den Manny-Button | Fokus, UI-86 |
| A-39 | (v1.2, **vom ui-designer bestätigt**) Tageswechsel bei offenem Chat/Nachrichten: weder Snackbar noch Ansage „Neuer Tag …“; Heute zeigt beim Zurückkehren das neue Datum | Ergänzung 2 3.1 |
| A-40 | (v1.2, **vom ui-designer bestätigt**, F-20 geklärt) Wo Ergänzung 2 Größen nennt, die kein Token sind (Avatar-Initialen „`heading`-Größe 17“, Chat-Untertitel „`secondary` 13 sp“), werden die Tokens `heading` (18/24) bzw. `secondary` (14/20) verwendet (Konvention 1, „keine neuen Tokens“) | Typo, F-20 |
| A-41 | (v1.2) Chat-Emblem und Manny-Kopf im Button sind der Kopf-Ausschnitt von `MannyPlaceholder` (Pose `neutral`) | Optik |
| A-42 | (v1.2) Die Escape-Taste schließt Vollbild-Routen über eigene `Shortcuts` im `ChatScreenScaffold` | Tastatur |
| A-43 | (v1.3, Festlegung) Button-Gruppe nur im Standard-Zustand von Pfad und Heute; nicht in Laden/Fehler und nicht beim `StartGate`-Fehler | Sichtbarkeit, UI-70/71, Matrix |

Entfallen: A-7 (jetzt N-10), A-18 (jetzt N-15), A-28 (jetzt N-16).

---

## 17. Offene Fragen

**Blockierend:** keine.

**[nicht blockierend]** (Annahme gilt bis zur Klärung)
- **F-7** Frühestes wählbares Verletzungsdatum. — *Annahme:* A-27.
- **F-8** Pfadstruktur am Ende (Phasen-Abschluss Woche 12 vor Boss). — *Annahme:* A-10.
- **F-12** Paket-ID/Organisation. — *Annahme:* `com.example.curaone`, Dart-Paket `curaone`, App-Name „CuraOne"; vor Store-Einreichung ersetzen.
- **F-17** Begrüßung einmalig oder täglich? — *Annahme:* einmalig (A-21).
- **F-18 (neu, an ui-designer)** Ort-Platzhalter für den Freitags-Arzttermin und Bestätigung der klinischen Wortliste (A-16, A-37).

Geschlossen: F-20 (ui-designer: bestehende Tokens `heading` 18/24, `secondary` 14/20), F-19 (N-19, Zusatzbedingung bestätigt), F-1 (N-10), F-2 (Brief-E-1), F-3 (A-17), F-4 (A-13), F-5 (A-22), F-6 (N-15), F-9 (B-8), F-10 (N-14), F-11 (N-16), F-13 (A-19 bleibt), F-15 (K-1 akzeptiert), F-16 (kein Konflikt).

---

## 18. Übernommene Nutzerentscheidungen (Prüfliste P2)

| Nr. | Entscheidung | Wo im Plan |
|---|---|---|
| Brief 12.1 | „Schritt X von 4" | 4.5, UI-11 |
| Brief 12.2 | Beispielpfad mit Label für alle Typen | 7.2, UI-25 |
| Brief 12.3 | Sheet mit drei Modi, nur „Manuell" aktiv | 4.1, UI-30 |
| Brief 12.4–6 | Datenschutztext Platzhalter; Freezes Startzahl 2; Akzent mit Kontrasttest | 6.1, UI-3 |
| Brief-E-1 | UI-7 nach Untergrund (Variante A, Optik unverändert) | 8.2, UI-7 |
| Brief-E-2 | `accent` als Text nur auf `bg` | 8.1, 12.3 Regel 5, UI-4 |
| Erg. 8.1 | Pfad bei Typ/Datum neu berechnet, Streak bleibt | 7.2, 7.8, UI-55 |
| Erg. 8.2 | Zeitwahl bleibt; 20 nur Erststart/nach Löschen | 6.1, 7.5 |
| Erg. 8.3 | Feier erst beim nächsten Pfad-Besuch nach dem Fenster | 7.7, UI-40 |
| Erg. 8.4–6 | Fenster endet bei Wechsel auf Pfad; Kopfzeile erweitert; Snackbar-Gestaltung auch für „Entfernt" | 7.6, 9 |
| N-1 | Freeze automatisch, Start 2, kein Verdienen, max 2, jeder Tag ohne Training verpasst | 7.1 |
| N-2 | „Abends" ab 18:00 lokal (Konstante) | 7.7 |
| N-3 | Alle Verletzungstypen → Beispielpfad | 7.2 |
| N-4 | Prototyp mit Platzhalterdaten, ohne KI | 7.4 |
| N-5 | Kein Backend, nichts gesendet, kein Konto | 6, 11, 15 |
| N-6 | Android-Zurück: Heute → Pfad; Pfad → App schließen; Offenes zuerst schließen | 4.3 |
| N-7 | Profiländerung: Pfad neu, Streak/Freezes/Tagesänderungen bleiben | 7.2, 7.8 |
| N-8 | Zeitwahl bleibt nach Tageswechsel | 7.5 |
| N-9 | Verifikation mit Web-Screenshots (Chromium), Viewports, 200 %, Graustufen, Farbsehschwächen | 12 |
| N-10 | F-1: Freezes chronologisch je verpasstem Tag, danach 1 ungedeckter Tag toleriert („eingefroren"), Reset beim 2. ungedeckten | 7.1 |
| N-11 | Eintrag aus am Vortag geöffnetem Sheet zählt für den Vortag, danach Tageswechsel; jede mutierende Methode prüft zuerst den Tageswechsel; `logTraining` evaluiert intern | 5, 7.1, 7.5, UI-42 |
| N-12 | Unlesbare Daten/unbekanntes Schema → automatisch neu starten mit Hinweis; Migrations-Hook, Fixtures, Versionsregel, Lesetoleranz | 4.1, 6.2 |
| N-13 | Zurück im Onboarding immer einen Schritt zurück; Blase zählt dort nicht als Overlay; Schritt 1 → App schließen | 4.3, UI-16 |
| N-14 | Beispieltermine: Physio Mo–Fr 17:00, Arzt zusätzlich Fr 09:30, Sa/So leer | 7.4 |
| N-15 | „ca. N Min" = Summe der angezeigten Übungen (B-6) | 7.5 |
| N-16 | Eigene Übung: Wdh. „3 × 10" und Dauer „5" vorbefüllt, Rückfall auf Vorgabe, Buttons „Hinzufügen"/„Abbrechen" (B-4) | 9 |
| Erg. 2 | Manny-Chat und Nachrichten nur sichtbar; Manny auf dem Pfad antippbar (1A); Button-Gruppe (V2, Nachrichten-Button B); keine Buttons im Onboarding (bewusste Abweichung von Spec 7); Glow im Chat bleibt; nur deaktivierte Eingabeleiste; Emblem je Manny-Block; Snackbar über der Gruppe; Hinweiszeile ab 1,5 mitscrollend; Undo-Ende beim Öffnen von Chat/Nachrichten; Direktnachrichten unverbindlicher Platzhalter | 4.1, 4.6, 7.10, 9, 13 |
| N-17 | KS-Schnittstellen schlank: KS-1 synchron, KS-4 minimal ohne JSON/Speicherung, KS-5 nur `messages` (kein `canSend`), KS-6 nur, was der Brief verlangt, KS-7 entfällt, KS-9 Löscher-Liste; keine KI, kein Netzwerk, keine Red-Flag-Vorprüfung | 7.9, 7.10, 6.3 |
| N-18 | `ChatComposer` nur deaktiviert, keine aktive Variante, kein Variantentest, kein `canSend` (Präzisierung zu P1-K2) | 7.10, 9, 12.3 Regel 16, UI-77 |
| N-19 | F-19: zusätzlich berechneter Kontrast ≥ 4,5:1 für farbigen Text/`accent-hi` auf Glas | 8.2, UI-7 |
| N-20 | Prüf-Infrastruktur als eigenes Paket U2p; 9 Pakete | 14 |
| N-21 | F-20, A-38, A-39 vom ui-designer bestätigt | 16, 17 |
| KONV | `KONVENTIONEN.md` Regeln 1–5 verbindlich | 3, 8, 12.1, 12.3 |

---

## 19. Risiken, bekannte Einschränkungen, Review-Empfehlung

| Nr. | Risiko / Einschränkung | Umgang |
|---|---|---|
| R-1 | Keine Gerätetests in dieser Umgebung | [D-offen]; Prüfliste im U4-Bericht |
| R-2 | Goldens plattformabhängig | Tag `golden`, Referenz nur diese Linux-Umgebung |
| R-3 | Unverschlüsselter lokaler Speicher | vor Echtbetrieb im Datenschutz-Konzept klären |
| R-4 | Eigene Sheet-Route statt `showModalBottomSheet` | nötig für Verwerfen beim Wischen; W-Tests inkl. Fling |
| R-5 | HC-Signal nur iOS 13+/Android API 34+; Reduced Motion auf iOS über `reduceMotion` | `CuraMotion` liest beide; HC per Override testbar |
| R-6 | Web-Fake-Uhr und Browser-HC-Signal ungeklärt; Laufzeit von Matrix und Screenshot-Lauf | in U2p klären und messen (12.5) |
| R-8 | Zeitzonenwechsel nach Osten kann einen Tag überspringen → zählt als verpasst | benannt, keine Sonderlogik |
| K-1 | Pfad kann der Datumswoche vorauslaufen (Kopfzeile/„Kommt in Woche N") | akzeptiert, im U4-Bericht nennen |
| K-2 | Manny-Chat und Nachrichten sind reine Ansicht; Nachrichten ohne Spec (Ergänzung 2 K10) | im Code-Kommentar und im U4-Bericht nennen |
| R-9 | KS-9: bei künftig mehreren Löschern Teil-Löschstand möglich, wenn ein späterer Löscher fehlschlägt | im ersten Ausschnitt nur ein Löscher; im KI-Ausschnitt neu bewerten |
| R-10 | `ChatMessageList` „Ende folgen“ ist im ersten Ausschnitt nur per Test-Widget geprüft (keine echten wachsenden Nachrichten) | im KI-Ausschnitt mit echtem Streaming erneut prüfen |

Review-Schwerpunkte: nach U1b Streak/Pfad/Tageswechsel/Migration (Tabellen 6.2, 7.1, 7.5); nach U2a Token-Disziplin, Blur-Budget, Glow-Prüfung, Fokus/Semantik; nach U4 Löschen (Vollständigkeit, Sperren, Stapel), Rückgängig/Feier, Matrix- und Screenshot-Ergebnisse gegen UI-1 … UI-89; nach U2c Chat-Bausteine (Ende-Folgen, deaktivierte Leiste), Fokusrückgabe, Sichtbarkeit der Button-Gruppe, Speicherfreiheit (UI-82/83).

---

## 20. Änderungsprotokoll v1 → v1.1

| Befund | Änderung |
|---|---|
| N F-1 | Regel bestätigt (N-10); „Alternative", R-7, U1-Abhängigkeit und A-7 entfernt (7.1, 14, 16, 18) |
| N M1 | Eintrag über Mitternacht zählt für den Vortag; `_mutate` mit Tageswechsel zuerst; `logTraining` evaluiert intern; Tests S19, 7.5 (5, 7.1, 7.5, UI-42) |
| N M2 | Unlesbare Daten → automatischer Neustart mit Hinweis (A-34); Migrationskette, Fixtures, Versionsregel, Lesetoleranz (4.1, 6.2) |
| N M3 | Zurück im Onboarding immer ein Schritt; Blase kein Overlay; Test je Schritt (4.3, UI-16) |
| B-1 / F-2 | Glow-Prüfung per Alpha nach Untergrund (Brief-E-1), geteilte `glow.dart`, Pixel-Kontrast im Screenshot-Lauf; benannte Ausnahme entfernt (8.2, 12.5, UI-7) |
| B-2 | `accent` als Text nur auf `bg`; DatePicker-Textbuttons `accent-hi`; Paare in UI-3; Regel 5 (8.1, 12.3, UI-3, UI-4) |
| F-10 | Termine Mo–Fr Physio, Fr Arzt, Sa/So leer (7.4, Szenarien) |
| M4 / B-7 | Scroll-Polster oben/unten; Testfenster 40–65 %; `path-week1`/`path-end` in UI-21/UI-55 (7.3, 13) |
| M5 | Pakete U1a/U1b/U2a/U2b/U3/U4; Matrix und Screenshot-Skript ab U2a je Paket (14) |
| n2 | Tests S19–S25, Roundtrip, Reset-Lücke, Uhr rückwärts + Rollover; R-8 Zeitzone (7.1, 7.5, 19) |
| n3 | Profiländerung: `pulsePending`, Feier, `day.done` festgelegt und getestet (7.2) |
| n4 | Löschen: Sperren während `busy`, Schreibschlange abwarten, RAM bei Fehler unverändert, feste Schlüsselliste (6.3, UI-50/51/52) |
| n5 | Fokusrückgabe mit `mounted`-Prüfung; Wischgeste nur auf Kopf, Fling-Test (4.4, A-36) |
| n6 | Browser-Zurück = `popRoute`, Prüfung mit `page.goBack()` (4.3, 12.5) |
| n7 | Gestufte Matrix; UI-4-Begründung; Abstände ≥ 8 dp automatisiert; Wortlisten statt naiver Regex; Satzzählung mit Allowlist; Regel 8 erweitert; `Colors.transparent`; Null-Literale; UI-52 mit `pump(Duration)`; Pipette ±1; beide HC/RM-Wege getestet (12.2, 12.3, 13) |
| n8 | `TickerMode` je Tab, Timer beim Tabwechsel beenden (4.1, UI-8) |
| n9 / F-15 | Als bekannte Einschränkung K-1 benannt (7.2, 19) |
| reviewer offen | `page.clock`, HC-Override-Reihenfolge (oberhalb `MaterialApp` wirkungslos → im `builder`), Matrix-Laufzeit benannt (8.1, 12.5, R-6) |
| NITPICK reviewer | Tags in `dart_test.yaml` erwähnt; `lastSeenDay` entfernt, `day.dayKey` einzige Quelle (6.1, 12.1) |
| B-3 | `ContentFrame` 560 dp, Viewport 768×1024 (4.5, 9, 12.2, 12.5) |
| B-4 / F-11 | Eigene Übung mit Vorgaben und Rückfall, Buttons (9, N-16) |
| B-5 | Plural-Helfer `tage(n)` mit Tests (7.4) |
| B-6 | Leer + Erledigt; Überschrift bei leerer Liste; N = Summe (7.5) |
| B-8 | Schein/Schatten/Linien/Dauern/Seitenwechsel/Pressed/Pills als Info (8.4, 9, 13 Prüfliste) |
| B-9 | Regel 11 gegen Abschneiden (12.3) |
| B-10 | Tastatur-Szenarien als W + Golden (12.4) |
| UI-18/19/36/69 | Tritanopie, zusätzliche Szenarien, Checkliste je Paar, klinische Wortliste (12.5, 13, 12.3) |
| A-13, A-16, A-17, A-22, A-25 | Vorschläge des ui-designers übernommen |
| F-7 | `initialDate` ≥ `firstDate` sichergestellt (A-27, UI-15) |
| NITPICK ui-designer | Segment nicht gewählt 400; opsz = Schriftgröße (geklemmt) mit Golden; FakeClock-Fixture Mittwoch; „Beispielpfad" auch für ACL als bewusste Abweichung; F-16 geschlossen |
| Konvention | Nutzerentscheidungen heißen jetzt N-n (statt E-n), um Verwechslung mit Brief-Errata E-1/E-2 zu vermeiden |

---

## 21. Änderungsprotokoll v1.1 → v1.2

| Anlass | Änderung |
|---|---|
| Brief-Ergänzung 2 (freigegeben) | Als Vorgabe aufgenommen (Kopf); neue Fassungen UI-24, UI-31, UI-59, Präzisierungen UI-37/39/41/63 in Abschnitt 13 übernommen; UI-70 … UI-89 zugeordnet |
| Erg. 2 Navigation | Vollbild-Routen `MannyChatRoute`, `MessagesRoute`, `ExampleChatRoute` über `CuraFullscreenRoute`; Zurück-Tabelle, Escape über `ChatScreenScaffold`, Anfangsfokus Zurück-Pfeil, Fokusrückgabe (A-38), Undo-Ende/Hinweis- und Blasen-Schließen vor dem Öffnen (4.1, 4.3, 4.4) |
| Erg. 2 Button-Gruppe | Neuer Abschnitt 4.6: Sichtbarkeit (nicht Onboarding/Chat/Nachrichten/unter Sheets), Ebene, Positionen, Fokusreihenfolge, Kollision mit Blase/`NodeHint`, Tageswechsel bei offenem Chat (A-39) |
| Erg. 2 Pfad | Manny antippbar mit eigenem Hit-Pfad bis zur Standlinie, ohne Fokusstation; Gruppen-Reserve im Pfad-Polster (4.6, 9) |
| Erg. 2 Heute | `PrimaryActionRow` mit Manny-Button, Nachrichten-Button darüber, Snackbar 12 dp über der Gruppe, Scroll-Reserve aus gemessenen Höhen (4.5, 4.6, 9) |
| Erg. 2 Bausteine | `MannyChatButton`, `MessagesButton`, `ActionCluster`, `PrimaryActionRow`, `ChatScreenScaffold`, `ChatHeader`, `ExampleNotice`, `ChatMessageList`, `ChatComposer` (nur deaktiviert), `ChatFooterLayout`, `ContactRow`, `ChatBubble`; `MannyPlaceholder` mit `crop`/`hitPath`; Icons ergänzt (9); Schatten der Buttons bleibt bei HC (8.4, 8.5); 0 Blur in Chat/Nachrichten (8.3) |
| KI-Plan Abschnitt 11, schlank (N-17) | KS-1/2/3 als 7.9, KS-4/5/10 als 7.10, KS-9 Löscher-Liste in 6.3, KS-7 entfällt (kein Chat-Schlüssel), Struktur in Abschnitt 3 ergänzt; `strings_de.dart` ohne Flutter-Import |
| Präzisierung Orchestrator (N-18) | `ChatComposer` nur deaktiviert, kein `canSend`, keine aktive Variante, kein Variantentest (7.10, 9, Regel 16, UI-77) |
| `KONVENTIONEN.md` | Als verbindlich aufgenommen; Abschnitt 12.1 bleibt stabil, weil die Konventionen ihn zitieren |
| F-19 bestätigt (N-19) | Offene Frage geschlossen; Zusatzbedingung in 8.2 bleibt |
| Verifikation | Statische Regeln 12–16; neue Szenarien in 12.4; Matrix-Prüfungen für Gruppe, Reserven, Chat-Fuß; Screenshot-Abläufe und Farbsehschwächen für Nachrichten (12.2–12.5) |
| Pakete | Neues Paket U2c (Chat + Nachrichten); U3 geteilt in U3a (Pfad) und U3b (Heute), weil U3 mit den Ergänzungen zu groß würde; KS-Logik in U1b; Bericht umfasst UI-1 … UI-89 (14) |
| Annahmen, Fragen, Risiken | A-38 … A-42; F-20 (Typo-Werte ohne Token); K-2, R-9, R-10 (16, 17, 19) |

---

## 22. Änderungsprotokoll v1.2 → v1.3 (Re-Review R-P1-RR, Nutzerentscheidungen; Plan danach FREIGEGEBEN)

| Befund | Änderung |
|---|---|
| MINOR-1 | Nachrichten-Button auf Heute 8 dp über der Oberkante des Manny-Buttons, auch bei umgebrochenem „Training starten“ (4.6); W-Test im Umbruchszustand in UI-71 (13) |
| MINOR-2 + N-20 | Prüf-Infrastruktur als eigenes Paket **U2p**; U2a-Bausteinliste explizit; screen-spezifische Bausteine eindeutig U3a/U3b/U4; Reihenfolge U1a → U1b → U2a → U2p → U2b → U2c → U3a → U3b → U4; U1b mit zulässiger Zwischenstand-Rückmeldung nach Teil 1 (14) |
| MINOR-3 | Reihenfolge beim Tageswechsel auf Heute und beim Eintrag über Mitternacht: Zustand → Heute-Routen schließen und abwarten → Bedingung „Heute aktiv und `HomeRoute` oberste Route“ → Snackbar/Ansage (4.6, 7.5) |
| MINOR-4 | Prüfzeile A-39 in UI-86 (FakeClock +1 Tag bei offenem Chat/Nachrichten, `resumed` → keine Snackbar, keine Ansage, nach Zurück neues Datum) (13) |
| MINOR-4b | Sichtbarkeit der Button-Gruppe in Laden/Fehler und beim `StartGate`-Fehler festgelegt (A-43, 4.6); Matrix-Regel eingeschränkt (12.2); UI-70 angepasst |
| MINOR-5 | M-Layout: „Inhalt nach Scrollen erreichbar“ mit Pflichtfällen bei 320×568 und 2,0, Mindest-Sichtfläche als Richtwert (12.2); Rückfallkette für Blase und `NodeHint` (4.6) |
| MINOR-6 | Maßkonstanten aus Ergänzung 2 in U1a abgelegt (14); statische Regel 2 erweitert um `Positioned`, `Container`, `BoxConstraints`, `BoxShadow`, `Border.all`, `withValues(alpha:)`, `withOpacity` (12.3) |
| MINOR-7a | `ChatMessageList`: Darstellung aller Enum-Werte festgelegt, erschöpfender `switch`, Test je Kombination (9) |
| MINOR-7b | `beforeOpenFullscreen()` gestrichen; einziges `TransientUi.endUndoWindow()`; Undo-Zustand nur in `TransientUi` (5) |
| NITPICK | Matrixzahlen als Richtwerte gekennzeichnet (12.2); Regel 7 schließt `dart:ui` bewusst aus (12.3); `MannyContext.toJson()` als bewusst ohne Verbraucher gekennzeichnet (7.9) |
| Bestätigungen | F-20, A-38, A-39 als geklärt markiert (16, 17, 18) |
| Status | Kopf auf v1.3, Status FREIGEGEBEN (2026-10-07) |
