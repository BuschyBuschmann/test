// Goldens ganzer Szenarien der App (Abschluss-Review R-AB, Nutzerentscheidung
// 2026-10-11): „Deine Daten“ (Sheet, geändert, beide Dialoge) und der
// Pfad-Ausblick bei 390 × 844, Skalierung 1,0, normal. Sie laufen durch
// dieselbe Preview-App wie Browser und Matrix. Referenz ist ausschließlich
// diese Linux-Umgebung; Erzeugung mit `--update-goldens`, Sichtung durch den
// `ui-designer`, Freigabe durch den Nutzer (Plan 12.1).
@Tags(<String>['golden'])
library;

import 'package:curaone/dev/preview_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  for (final String id in <String>[
    'data-sheet',
    'data-sheet-dirty',
    'data-delete-dialog',
    'data-discard-dialog',
    'path-outlook',
  ]) {
    testWidgets('scenario_$id', (WidgetTester tester) async {
      setViewport(tester, Viewports.phone);
      await tester.pumpWidget(
        PreviewApp(config: PreviewConfig(scenarioId: id)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(PreviewApp),
        matchesGoldenFile('goldens/scenario_$id.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
