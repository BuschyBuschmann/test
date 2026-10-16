// Pfad-Ausblick (Design-Abnahme L1 m2, V2-4/5): eine Karte wie alle anderen
// (`GlassCard`, 92 % `card`), nur der Rand ist gestrichelt; Schrift hält 4,5:1
// im Worst Case auf der Karte.
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/path_outlook.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('Ausblick: GlassCard mit 92 % Deckung, gestrichelter Rand', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: PathOutlook(onPressed: () {}),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(PathOutlook),
        matching: find.byType(GlassCard),
      ),
      findsOneWidget,
    );
    final CuraColors c = CuraColors.of(
      tester.element(find.byType(PathOutlook)),
    );
    expect(c.cardFillTop.a, closeTo(Palette.cardAlpha, 0.005));
    expect(Palette.cardAlpha, 0.92);
    final bool dashed = find
        .descendant(
          of: find.byType(PathOutlook),
          matching: find.byType(CustomPaint),
        )
        .evaluate()
        .any(
          (Element e) =>
              (e.widget as CustomPaint).foregroundPainter is DashedRRectPainter,
        );
    expect(dashed, isTrue);
  });

  test(
    'Ausblick: Titel (text-1) und Untertitel (text-2) ≥ 4,5:1 auf der Karte',
    () {
      for (final CuraColors c in <CuraColors>[
        CuraColors.light,
        CuraColors.dark,
        CuraColors.lightHighContrast,
        CuraColors.darkHighContrast,
      ]) {
        expect(
          worstCaseContrast(c.text1, c.cardFillTop),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          worstCaseContrast(c.text2, c.cardFillTop),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

  testWidgets('Ausblick: gerenderte Schriftfarben sind text-1 und text-2', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, PathOutlook(onPressed: () {}));
    final CuraColors c = CuraColors.of(
      tester.element(find.byType(PathOutlook)),
    );
    final List<Color?> colors = <Color?>[
      for (final RichText r in tester.widgetList<RichText>(
        find.descendant(
          of: find.byType(PathOutlook),
          matching: find.byType(RichText),
        ),
      ))
        if (r.text.toPlainText().trim().isNotEmpty &&
            r.text.toPlainText().codeUnitAt(0) < 0xE000)
          r.text.style?.color,
    ];
    expect(colors, containsAll(<Color>[c.text1, c.text2]));
  });
}
