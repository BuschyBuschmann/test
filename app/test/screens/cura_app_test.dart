// `CuraApp` (U2b, Plan 8.1): Auswahl des Token-Satzes im `MaterialApp.builder`
// nach dem Systemsignal (Produktionsweg `main.dart`), Locale, AppScope.
import 'package:curaone/state/app_scope.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_motion.dart';
import 'package:curaone/ui/components/glow_background.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/controller_harness.dart';

CuraColors _colors(WidgetTester tester) =>
    CuraColors.of(tester.element(find.byType(HomeShell)));

void main() {
  testWidgets('Normal: dunkler Token-Satz mit Glow, deutsche Locale', (
    WidgetTester tester,
  ) async {
    final Harness h = await Harness.onboarded();
    addTearDown(h.dispose);
    await pumpCura(tester, h.controller);
    expect(_colors(tester).highContrast, isFalse);
    expect(find.byType(GlowBackground), findsOneWidget);
    final BuildContext context = tester.element(find.byType(HomeShell));
    expect(Localizations.localeOf(context).languageCode, 'de');
    expect(AppScope.of(context), same(h.controller));
    await disposeApp(tester);
  });

  testWidgets('Systemsignal Hoher Kontrast wählt den HC-Satz (ohne Override)', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final Harness h = await Harness.onboarded();
    addTearDown(h.dispose);
    await pumpCura(tester, h.controller);
    expect(_colors(tester).highContrast, isTrue);
    // HC: kein Glow, kein Blur.
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      find.byType(CustomPaint).evaluate().where((Element e) {
        return (e.widget as CustomPaint).painter.runtimeType.toString() ==
            'GlowPainter';
      }),
      isEmpty,
    );
    await disposeApp(tester);
  });

  testWidgets('Systemsignal Bewegung reduzieren erreicht CuraMotion', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final Harness h = await Harness.onboarded();
    addTearDown(h.dispose);
    await pumpCura(tester, h.controller);
    expect(
      CuraMotion.of(tester.element(find.byType(HomeShell))).reduced,
      isTrue,
    );
    await disposeApp(tester);
  });
}
