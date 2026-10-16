// Goldens ganzer Szenarien der App (Abschluss-Review R-AB, Nutzerentscheidung
// 2026-10-11; F2-R3, F2-R4, Plan 3.6): jeder Screen einmal bei 390 × 844,
// Skalierung 1,0, Welt Mittag, Hell; der Look-Schritt zusätzlich Dunkel, mit
// 200 % Schrift und bei 320 dp; Pfad und Heute in allen vier Welten × beiden
// Themen; ausgewählte Screens mit Hohem Kontrast. Sie laufen durch dieselbe
// Preview-App wie Browser und Matrix. Referenz ist ausschließlich diese
// Linux-Umgebung; Erzeugung mit `--update-goldens`, Sichtung durch den
// `ui-designer`, Freigabe durch den Nutzer (Plan 12.1).
@Tags(<String>['golden'])
library;

import 'package:curaone/dev/preview_app.dart';
import 'package:curaone/logic/display_settings.dart';
import 'package:curaone/logic/world_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/world_app.dart';

/// Ein Szenario-Golden: [name] ist die Bilddatei ohne Endung.
void _golden(String name, PreviewConfig config, {Size size = Viewports.phone}) {
  testWidgets('scenario_$name', (WidgetTester tester) async {
    setViewport(tester, size);
    await tester.pumpWidget(PreviewApp(config: config));
    await tester.pumpAndSettle();
    // Manny-Bilder laden, bevor das Bild entsteht.
    await precacheImages(tester);
    await expectLater(
      find.byType(PreviewApp),
      matchesGoldenFile('goldens/scenario_$name.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void main() {
  // Jeder Screen einmal in der Grundwelt (Mittag, Hell, 390 × 844).
  for (final String id in <String>[
    'path-active',
    'path-outlook',
    'chats',
    'profile',
    'profile-look-sheet',
    'profile-display-sheet',
    'data-sheet',
    'data-sheet-dirty',
    'data-delete-dialog',
    'data-discard-dialog',
    'data-privacy',
    // F2-R4: Heute und Onboarding.
    'today-standard',
    'today-empty',
    'today-done',
    'today-mode-sheet',
    'ob0-look',
    'ob0-look-ohne',
    'ob1-name',
    'ob1-name-ohne',
    'ob2',
    'ob3-acl',
    'ob3-muscle',
    'ob4-date',
    'ob2-privacy',
  ]) {
    _golden(id, PreviewConfig(scenarioId: id));
  }

  // Look-Schritt: Dunkel, 200 % Schrift und 320 dp (Ergänzung 1, 10).
  _golden(
    'ob0-look_dark',
    const PreviewConfig(scenarioId: 'ob0-look', theme: ThemeChoice.dark),
  );
  _golden(
    'ob0-look_scale2',
    const PreviewConfig(scenarioId: 'ob0-look', textScale: 2),
  );
  _golden(
    'ob0-look_320',
    const PreviewConfig(scenarioId: 'ob0-look'),
    size: Viewports.small,
  );

  // Pfad und Heute in allen vier Welten × beiden Themen (Plan 3.6).
  for (final String id in <String>['path-active', 'today-standard']) {
    for (final WorldChoice world in <WorldChoice>[
      WorldChoice.morning,
      WorldChoice.midday,
      WorldChoice.evening,
      WorldChoice.night,
    ]) {
      for (final ThemeChoice theme in <ThemeChoice>[
        ThemeChoice.light,
        ThemeChoice.dark,
      ]) {
        if (world == WorldChoice.midday && theme == ThemeChoice.light) {
          continue; // = Grundwelt oben
        }
        _golden(
          '${id}_${world.name}_${theme.name}',
          PreviewConfig(scenarioId: id, world: world, theme: theme),
        );
      }
    }
  }

  // Jeder Screen einmal mit Hohem Kontrast.
  for (final String id in <String>[
    'path-active',
    'chats',
    'profile',
    'today-standard',
    'ob0-look',
    'ob1-name',
    'data-sheet',
  ]) {
    _golden('${id}_hc', PreviewConfig(scenarioId: id, highContrast: true));
  }
}
