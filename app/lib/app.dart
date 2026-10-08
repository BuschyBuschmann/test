// `CuraApp` (Plan 3, 8.1): `MaterialApp` mit Theme, Locale `de`, AppScope und
// StartGate als erster Route. Der Token-Satz „Hoher Kontrast“ wird im
// `MaterialApp.builder` nach `MediaQuery.highContrast` gewählt
// ([CuraThemeSelector]); die Prüfumgebung schaltet davor ihre Overrides
// ([previewWrapper], nur `main_preview`). Ein Override oberhalb von
// `MaterialApp` würde nicht wirken, weil `MaterialApp` seine `MediaQuery`
// aus der View neu erzeugt.
//
// Der `ContentFrame` (höchstens 560 dp) steckt in jedem Screen
// (`ScreenFrame`), nicht im Builder: Hintergrund und Glow laufen so über die
// volle Breite (Plan 4.5), Scrim und Dialoge ebenfalls.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/manny_chat_source.dart';
import 'l10n/strings_de.dart';
import 'state/app_controller.dart';
import 'state/app_scope.dart';
import 'state/chat_source_scope.dart';
import 'theme/cura_theme.dart';
import 'ui/start/start_gate.dart';

/// Wählt den Token-Satz nach `MediaQuery.highContrast` (Normal oder
/// „Hoher Kontrast“).
class CuraThemeSelector extends StatelessWidget {
  const CuraThemeSelector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CuraTheme.build(highContrast: MediaQuery.highContrastOf(context)),
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
    this.chatSource = const ExampleMannyChatSource(),
  });

  final AppController controller;

  /// Quelle des Manny-Chat-Verlaufs (KS-5, nur lesend). Standard: fester
  /// Beispielverlauf.
  final MannyChatSource chatSource;

  /// Start vor der ersten Route. Standard: `controller.load()`. Die
  /// Prüfumgebung und Tests ersetzen ihn (z. B. um vorher zu löschen).
  final Future<void> Function(AppController controller)? startup;

  final PreviewWrapper? previewWrapper;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: ChatSourceScope(
        source: chatSource,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          title: S.appTitle,
          theme: CuraTheme.build(),
          locale: const Locale('de'),
          supportedLocales: const <Locale>[Locale('de')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext context, Widget? app) {
            final Widget themed = CuraThemeSelector(child: app!);
            final PreviewWrapper? wrap = previewWrapper;
            return wrap == null ? themed : wrap(context, themed);
          },
          home: StartGate(startup: startup),
        ),
      ),
    );
  }
}
