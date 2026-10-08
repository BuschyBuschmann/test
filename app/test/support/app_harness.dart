import 'package:curaone/app.dart';
import 'package:curaone/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

/// Baut die echte [CuraApp] (StartGate, Routen, Theme) mit [controller].
/// Mit [settle] läuft der Start durch (Laden, Weiterleitung, Einblenden).
Future<void> pumpCura(
  WidgetTester tester,
  AppController controller, {
  Size size = Viewports.phone,
  bool settle = true,
  GlobalKey<NavigatorState>? navigatorKey,
  Future<void> Function(AppController)? startup,
  double keyboard = 0,
}) async {
  setViewport(tester, size);
  if (keyboard > 0) {
    // Eingeblendete Tastatur: Pixelverhältnis 1, also dp = Pixel.
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.resetViewInsets);
  }
  await tester.pumpWidget(
    CuraApp(
      controller: controller,
      navigatorKey: navigatorKey,
      startup: startup,
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Baut die Wurzel ab (beendet Timer der Snackbar), damit der Test sauber endet.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

/// Fängt `SystemNavigator.pop` ab (Android-Zurück auf der ersten Ebene).
/// Liefert die Anzahl der Aufrufe.
class SystemPopRecorder {
  SystemPopRecorder(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'SystemNavigator.pop') count++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  int count = 0;
}

/// App-Lebenszyklus: aus dem Hintergrund zurück (`resumed` kommt nur nach
/// `inactive`, sonst ruft `AppLifecycleListener.onResume` nicht).
void resumeApp(WidgetTester tester) {
  for (final AppLifecycleState s in <AppLifecycleState>[
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}
