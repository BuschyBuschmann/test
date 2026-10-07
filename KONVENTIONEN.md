# Konventionen (verbindlich)

Vom Nutzer am 2026-10-07 freigegeben. Gilt für alle Agenten und Sessions. Herkunft: Vorschlag aus `docs/plan/flutter-plan-v1.md`.

## Flutter-App CuraOne (`app/`)

1. **Tokens nur aus `lib/theme/`.** Farben, Abstände, Radien, Schriftstile, Schatten und Motion kommen ausschließlich aus den Token-Definitionen. Außerhalb von `lib/theme/` kein `Color(0x…)` und keine festen Schriftgrößen.
2. **`BackdropFilter` nur über `CuraBlur`.** Kein direkter Blur in Karten, Chips oder Listenelementen (Blur-Budget laut Design-Brief 3.5).
3. **`lib/logic/` ohne Flutter-Import.** Reine Dart-Logik (Streak, Pfad, Pools, Tageswechsel usw.) bleibt unabhängig von der UI und unit-testbar.
4. **Alle sichtbaren Texte in `lib/l10n/strings_de.dart`.** Auch Screenreader-Labels, Tooltips und Hinweistexte.
5. **Standard-Prüfung** vor jeder Rückmeldung (im Verzeichnis `app/`):
   ```
   export PATH=/opt/flutter/bin:$PATH
   flutter pub get
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze
   flutter test --exclude-tags golden,matrix
   ```
   Matrix, Goldens und Web-Screenshots wie in `docs/plan/flutter-plan-v1.md`, Abschnitt 12.1.
