// F2-R4: Kopf-Karte auf Heute und „kein Text direkt auf der Welt“ (V2-5) für
// Heute, alle Onboarding-Schritte, die Datenschutzseite und „Deine Daten“ in
// der Preview-App (derselbe Weg wie Browser und Matrix).
import 'package:curaone/dev/preview_app.dart';
import 'package:curaone/dev/text_probe.dart';
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/ui/components/header_card.dart';
import 'package:curaone/ui/components/world_label_chip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/pump_app.dart';

Future<void> _open(WidgetTester tester, String id) async {
  setViewport(tester, Viewports.phone);
  await tester.pumpWidget(PreviewApp(config: PreviewConfig(scenarioId: id)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Heute: Kopf-Karte mit Titel, Datum, Streak; Abschnitte als '
      'Label-Chips', (WidgetTester tester) async {
    await _open(tester, 'today-standard');
    expect(
      find.descendant(
        of: find.byType(HeaderCard),
        matching: find.text(S.todayTitle('Jakob')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(HeaderCard),
        matching: find.text('Mittwoch, 7. Oktober'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(WorldLabelChip),
        matching: find.text(S.appointmentsHeading),
      ),
      findsOneWidget,
    );
    await disposeApp(tester);
  });

  for (final String id in <String>[
    'today-standard',
    'today-empty',
    'ob0-look',
    'ob1-name',
    'ob2',
    'ob3-other',
    'ob4-date',
    'ob2-privacy',
    'data-privacy',
    'data-sheet',
  ]) {
    testWidgets('V2-5: kein Text direkt auf der Welt ($id)', (
      WidgetTester tester,
    ) async {
      await _open(tester, id);
      final TextProbe p = probeTexts(view: Viewports.phone);
      final List<String> onWorld = <String>[
        for (final ProbedText t in p.texts)
          if (t.onScreen && !t.isIcon && t.ground == TextGround.bg) t.text,
      ];
      expect(onWorld, isEmpty);
      await disposeApp(tester);
    });
  }
}
