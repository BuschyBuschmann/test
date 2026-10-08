// Routen der App (Plan 4.1) als Fabrikfunktionen. Die Seiten selbst liegen
// in `lib/ui/onboarding/` und `lib/ui/home/`.
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../state/app_controller.dart' show StartNotice;
import '../home/home_shell.dart';
import '../onboarding/onboarding_flow.dart';
import '../onboarding/privacy_placeholder_page.dart';
import 'cura_page_route.dart';

abstract final class AppRoutes {
  /// Onboarding bei [step] (0 … 3) mit einem Hinweis nach Löschen bzw.
  /// unlesbaren Daten. Ohne [step] gilt der gespeicherte Schritt.
  static Route<void> onboarding(
    BuildContext context, {
    int? step,
    StartNotice notice = StartNotice.none,
  }) => curaPageRoute<void>(
    context,
    (BuildContext context) => OnboardingFlow(initialStep: step, notice: notice),
  );

  /// Home mit den Tabs Pfad und Heute; öffnet auf Pfad (A-1).
  static Route<void> home(BuildContext context) =>
      curaPageRoute<void>(context, (BuildContext context) => const HomeShell());

  /// Platzhalterseite „Datenschutzerklärung“ (aus Onboarding Schritt 2).
  static Route<void> privacy(BuildContext context) => curaPageRoute<void>(
    context,
    (BuildContext context) => const PrivacyPlaceholderPage(),
  );

  /// Löschen bestätigt (Ergänzung 1, 3.2; U4): ersetzt den gesamten
  /// Navigationsstapel durch das Onboarding bei Schritt 1. Ablauf des
  /// Aufrufers: erst `await controller.deleteAll()` (bei Fehler im Dialog
  /// bleiben), dann diese Methode; der `OnboardingFlow` ruft nach seinem ersten
  /// Frame `controller.completeDeletion()` und zeigt den Hinweis.
  ///
  /// Kein Rückgabewert: Das Future von `pushAndRemoveUntil` endet erst mit der
  /// neuen Route und darf nicht abgewartet werden.
  static void restartOnboarding(
    NavigatorState navigator, {
    StartNotice notice = StartNotice.deleted,
  }) {
    final Route<void> route = onboarding(
      navigator.context,
      step: 0,
      notice: notice,
    );
    unawaited(
      navigator.pushAndRemoveUntil<void>(route, (Route<dynamic> r) => false),
    );
  }
}
