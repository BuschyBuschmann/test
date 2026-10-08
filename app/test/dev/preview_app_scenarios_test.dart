// App-Szenarien der Prüfumgebung (U2b): die echte App startet mit dem Speicher
// des Szenarios (`ob*`, `shell-*`), `live=1` nutzt den echten Speicher für
// Reload-Prüfungen im Browser.
import 'package:curaone/dev/preview_app.dart';
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Siehe test/data/stores_test.dart: In-Memory-Ersatz der Plattform.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/app_harness.dart';
import '../support/pump_app.dart';

Future<void> _pump(WidgetTester tester, PreviewConfig config) async {
  setViewport(tester, Viewports.phone);
  await tester.pumpWidget(PreviewApp(config: config));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ob-mic-hint: Skript tippt den Mikrofon-Button', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'ob-mic-hint'));
    expect(find.text(S.micHint), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('ob1-deleted-snackbar: echter Löschweg, Schritt 1 mit Hinweis', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const PreviewConfig(scenarioId: 'ob1-deleted-snackbar'),
    );
    expect(find.text('Schritt 1 von 4'), findsOneWidget);
    expect(find.text(S.dataDeleted), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('ob1-corrupt-snackbar: Neustart nach unlesbaren Daten', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const PreviewConfig(scenarioId: 'ob1-corrupt-snackbar'),
    );
    expect(find.text('Schritt 1 von 4'), findsOneWidget);
    expect(find.text(S.dataUnreadable), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('shell-tab-today: Home mit aktivem Tab Heute', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'shell-tab-today'));
    expect(
      tester.state<HomeShellState>(find.byType(HomeShell)).activeTab,
      HomeTab.today,
    );
    await disposeApp(tester);
  });

  testWidgets('ob3-acl: Szenario setzt Zustand (Schritt 3, ACL gewählt)', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'ob3-acl'));
    expect(find.text('Schritt 3 von 4'), findsOneWidget);
    expect(find.text(S.onboardingStep3('Jakob')), findsOneWidget);
  });

  testWidgets('Tastatur-Szenario blendet die Platzhalterfläche ein', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'ob1-keyboard'));
    expect(
      tester.view.viewInsets.bottom,
      0,
      reason: 'Echte View bleibt unberührt, nur MediaQuery wird überschrieben',
    );
    expect(find.byKey(const ValueKey<String>('overlay:keyboard')), findsOne);
    final Rect button = tester.getRect(find.byType(PillButton));
    expect(button.bottom, lessThanOrEqualTo(Viewports.phone.height - 300));
    await disposeApp(tester);
  });

  group('live=1 (echter Speicher, Reload)', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    testWidgets('Eingabe überlebt den Neuaufbau (Reload)', (
      WidgetTester tester,
    ) async {
      const PreviewConfig live = PreviewConfig(
        scenarioId: 'ob1-empty',
        live: true,
      );
      await _pump(tester, live);
      await tester.enterText(find.byType(TextField), 'Jakob');
      await tester.pump();
      await tester.tap(find.widgetWithText(PillButton, S.next));
      await tester.pumpAndSettle();
      expect(find.text('Schritt 2 von 4'), findsOneWidget);
      await disposeApp(tester);

      // „Reload“: neue App, derselbe Speicher.
      await _pump(tester, live);
      expect(find.text('Schritt 2 von 4'), findsOneWidget);
      expect(find.text(S.onboardingStep2('Jakob')), findsOneWidget);
      await disposeApp(tester);
    });
  });
}
