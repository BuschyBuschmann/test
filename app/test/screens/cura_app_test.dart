// `CuraApp` (U2b, Plan 8.1): Auswahl des Token-Satzes im `MaterialApp.builder`
// nach dem Systemsignal (Produktionsweg `main.dart`), Locale, AppScope.
import 'package:curaone/state/app_scope.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_motion.dart';
import 'package:curaone/theme/world_painter.dart';
import 'package:curaone/ui/components/world_background.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/controller_harness.dart';
import '../support/backdrops.dart';

CuraColors _colors(WidgetTester tester) =>
    CuraColors.of(tester.element(find.byType(HomeShell)));

void main() {
  testWidgets('Normal: heller Token-Satz mit Welt, deutsche Locale', (
    WidgetTester tester,
  ) async {
    final Harness h = await Harness.onboarded();
    addTearDown(h.dispose);
    await pumpCura(tester, h.controller);
    expect(_colors(tester).highContrast, isFalse);
    expect(_colors(tester).isDark, isFalse, reason: 'System = Hell im Test');
    expect(find.byType(WorldBackground), findsOneWidget);
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
    // HC: kein Blur, Welt ohne Körnung, Dunst, Sterne und Sonne/Mond.
    expect(activeBackdrops(), findsNothing);
    final Iterable<WorldPainter> worlds = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((CustomPaint p) => p.painter)
        .whereType<WorldPainter>();
    expect(worlds, isNotEmpty);
    expect(worlds.every((WorldPainter p) => !p.decor), isTrue);
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
