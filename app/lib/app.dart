// `CuraApp` (Plan 3, 8.1): `MaterialApp` mit Theme, Locale `de`, AppScope und
// StartGate als erster Route. Der Token-Satz „Hoher Kontrast“ wird im
// `MaterialApp.builder` nach `MediaQuery.highContrast` gewählt
// ([CuraThemeSelector]); die Prüfumgebung schaltet davor ihre Overrides
// ([previewWrapper], nur `main_preview`). Ein Override oberhalb von
// `MaterialApp` würde nicht wirken, weil `MaterialApp` seine `MediaQuery`
// aus der View neu erzeugt.
//
// Der `ContentFrame` (höchstens 560 dp) steckt in jedem Screen
// (`ScreenFrame`), nicht im Builder: Hintergrund und Welt laufen so über die
// volle Breite (Plan 4.5), Scrim und Dialoge ebenfalls.
//
// Darstellung (Brief v2 3.1/3.2/3.5): Thema (System/Hell/Dunkel), „Transparenz
// reduzieren“ und die Welt kommen aus dem [DisplayController]; Welt und Thema
// sind unabhängig. Der [WorldHost] hält die Welt (Zeitregel, Minuten-Timer),
// das [BlurBudgetScope] begrenzt die Blur-Flächen auf 3.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/manny_chat_source.dart';
import 'l10n/strings_de.dart';
import 'state/app_controller.dart';
import 'state/app_scope.dart';
import 'state/chat_source_scope.dart';
import 'state/display_controller.dart';
import 'state/display_scope.dart';
import 'state/world_scope.dart';
import 'theme/cura_theme.dart';
import 'logic/display_settings.dart';
import 'ui/components/cura_blur.dart';
import 'ui/path/path_source.dart';
import 'ui/today/today_source.dart';
import 'ui/start/start_gate.dart';

/// Wählt den Token-Satz: Thema (System/Hell/Dunkel aus den Einstellungen,
/// sonst `MediaQuery.platformBrightness`) und Kontrast. „Hoher Kontrast“ gilt
/// bei `MediaQuery.highContrast` **oder** gesetztem App-Schalter „Transparenz
/// reduzieren“ (Brief 3.5, Entscheidung 5).
class CuraThemeSelector extends StatelessWidget {
  const CuraThemeSelector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final DisplaySettings settings =
        DisplayScope.maybeOf(context)?.settings ?? const DisplaySettings();
    final Brightness brightness = switch (settings.theme) {
      ThemeChoice.light => Brightness.light,
      ThemeChoice.dark => Brightness.dark,
      ThemeChoice.system => MediaQuery.platformBrightnessOf(context),
    };
    return Theme(
      data: CuraTheme.build(
        brightness: brightness,
        highContrast:
            MediaQuery.highContrastOf(context) || settings.reduceTransparency,
      ),
      child: child,
    );
  }
}

/// Umhüllt den Navigator vor dem Theme-Wähler (nur Prüfumgebung).
typedef PreviewWrapper = Widget Function(BuildContext context, Widget child);

class CuraApp extends StatelessWidget {
  const CuraApp({
    super.key,
    required this.controller,
    this.startup,
    this.previewWrapper,
    this.navigatorKey,
    this.display,
    this.chatSource = const ExampleMannyChatSource(),
    this.pathSource = const ImmediatePathSource(),
    this.todaySource = const ImmediateTodaySource(),
  });

  final AppController controller;

  /// Darstellungs-Einstellungen (Welt, Thema, Transparenz, Ton, Vibration).
  /// Ohne Angabe gelten die Standardwerte (Welt Automatisch, Thema System).
  final DisplayController? display;

  /// Quelle des Manny-Chat-Verlaufs (KS-5, nur lesend). Standard: fester
  /// Beispielverlauf.
  final MannyChatSource chatSource;

  /// Quelle der Pfaddaten (Ladezustand des Pfad-Tabs). Standard: sofort da.
  final PathSource pathSource;

  /// Quelle des Tagesprogramms (Ladezustand des Tabs Heute). Standard: sofort
  /// da.
  final TodaySource todaySource;

  /// Start vor der ersten Route. Standard: `controller.load()`. Die
  /// Prüfumgebung und Tests ersetzen ihn (z. B. um vorher zu löschen).
  final Future<void> Function(AppController controller)? startup;

  final PreviewWrapper? previewWrapper;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final Widget app = _buildApp();
    final DisplayController? d = display;
    return d == null ? app : DisplayScope(controller: d, child: app);
  }

  Widget _buildApp() {
    return AppScope(
      controller: controller,
      child: ChatSourceScope(
        source: chatSource,
        child: PathSourceScope(
          source: pathSource,
          child: TodaySourceScope(
            source: todaySource,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              title: S.appTitle,
              theme: CuraTheme.build(),
              locale: const Locale('de'),
              supportedLocales: const <Locale>[Locale('de')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext context, Widget? app) {
                final Widget themed = WorldHost(
                  child: BlurBudgetScope(child: CuraThemeSelector(child: app!)),
                );
                final PreviewWrapper? wrap = previewWrapper;
                return wrap == null ? themed : wrap(context, themed);
              },
              home: StartGate(startup: startup),
            ),
          ),
        ),
      ),
    );
  }
}
