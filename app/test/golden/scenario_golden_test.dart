// Goldens ganzer Szenarien der App (Abschluss-Review R-AB, Nutzerentscheidung
// 2026-10-11; F2-R3): Pfad, Pfad-Ausblick, Chats, Profil, Manny-Look und
// Darstellung (neu in Brief v2) sowie „Deine Daten“ (Sheet, geändert, beide
// Dialoge; F2-R4) bei 390 × 844, Skalierung 1,0, normal, Welt Mittag, Hell. Sie laufen durch
// dieselbe Preview-App wie Browser und Matrix. Referenz ist ausschließlich
// diese Linux-Umgebung; Erzeugung mit `--update-goldens`, Sichtung durch den
// `ui-designer`, Freigabe durch den Nutzer (Plan 12.1).
@Tags(<String>['golden'])
library;

import 'package:curaone/dev/preview_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/world_app.dart';

void main() {
  for (final String id in <String>[
    // F2-R3: Pfad, Chats, Profil, Darstellung, Manny-Look (Mittag, Hell).
    'path-active',
    'path-outlook',
    'chats',
    'profile',
    'profile-look-sheet',
    'profile-display-sheet',
    // F2-R4: „Deine Daten“.
    'data-sheet',
    'data-sheet-dirty',
    'data-delete-dialog',
    'data-discard-dialog',
  ]) {
    testWidgets('scenario_$id', (WidgetTester tester) async {
      setViewport(tester, Viewports.phone);
      await tester.pumpWidget(
        PreviewApp(config: PreviewConfig(scenarioId: id)),
      );
      await tester.pumpAndSettle();
      // Manny-Bilder laden, bevor das Bild entsteht.
      await precacheImages(tester);
      await expectLater(
        find.byType(PreviewApp),
        matchesGoldenFile('goldens/scenario_$id.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
