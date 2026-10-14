// CuraChip und StatusChip (Design-Brief v2, 4 und 3.2; V2-4, V2-23, V2-29):
// 13 sp/700, Pille, Status immer mit Symbol und Text, wählbare Chips mit
// Hit-Area ≥ 48 dp, Kontraste in beiden Themen.
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/ui/components/cura_chip.dart';
import 'package:curaone/ui/components/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/world_app.dart';

void main() {
  group('CuraChip', () {
    testWidgets('13 sp/700 DM Sans, Pille, chip-neutral, 36 dp sichtbar, '
        'Hit-Area 48 dp', (WidgetTester tester) async {
      int taps = 0;
      await pumpWorld(
        tester,
        Center(
          child: CuraChip(
            label: 'Tauschen',
            icon: Icons.swap_horiz_rounded,
            onPressed: () => taps++,
          ),
        ),
      );
      final CuraColors c = colorsAt(tester, find.byType(CuraChip));
      final TextStyle s = tester.widget<Text>(find.text('Tauschen')).style!;
      expect(s.fontSize, 13);
      expect(s.fontWeight, FontWeight.w700);
      expect(s.fontFamily, 'DMSans');
      expect(s.color, c.text1);
      final BoxDecoration d = decorationsUnder(
        tester,
        find.byType(CuraChip),
      ).first;
      expect(d.color, c.chipNeutralFill);
      expect(d.borderRadius, BorderRadius.circular(CuraRadius.pill));
      final Size size = tester.getSize(find.byType(CuraChip));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
      final Size visible = tester.getSize(
        find
            .descendant(
              of: find.byType(CuraChip),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(visible.height, greaterThanOrEqualTo(36));
      await tester.tap(find.byType(CuraChip));
      expect(taps, 1);
    });

    testWidgets('chip-neutral: ink-1 7 % (Hell), Weiß 10 % (Dunkel)', (
      WidgetTester tester,
    ) async {
      expect(CuraColors.light.chipNeutralFill.a, closeTo(0.07, 0.005));
      expect(CuraColors.light.chipNeutralFill.toARGB32() & 0xFFFFFF, 0x211B16);
      expect(CuraColors.dark.chipNeutralFill.a, closeTo(0.10, 0.005));
      expect(CuraColors.dark.chipNeutralFill.toARGB32() & 0xFFFFFF, 0xFFFFFF);
    });
  });

  group('StatusChip', () {
    Widget chips() => const Center(
      child: Wrap(
        spacing: 8,
        children: <Widget>[
          StatusChip(label: 'Erledigt', kind: StatusKind.success),
          StatusChip(label: 'Schmerz', kind: StatusKind.warn),
          StatusChip(label: 'Zuhause'),
        ],
      ),
    );

    testWidgets('Status immer mit Symbol (✓, ⚠, Info) und Text', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, chips());
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      for (final String t in <String>['Erledigt', 'Schmerz', 'Zuhause']) {
        final TextStyle s = tester.widget<Text>(find.text(t)).style!;
        expect(s.fontSize, 13, reason: t);
        expect(s.fontWeight, FontWeight.w700);
      }
      expect(
        decorationsUnder(tester, find.byType(StatusChip)).first.borderRadius,
        BorderRadius.circular(CuraRadius.pill),
      );
    });

    testWidgets('Farben chip-success und chip-warn im Thema Hell', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, chips());
      final CuraColors c = colorsAt(tester, find.byType(StatusChip).first);
      expect(c.chipSuccessFill, const Color(0xFFDDF3E6));
      expect(c.chipSuccessText, const Color(0xFF14532D));
      expect(c.chipWarnFill, const Color(0xFFFFE3DD));
      expect(c.chipWarnText, const Color(0xFF7A1A12));
      expect(
        contrastRatio(c.chipSuccessText, c.chipSuccessFill),
        closeTo(7.8, 0.15),
      );
      expect(contrastRatio(c.chipWarnText, c.chipWarnFill), closeTo(8.7, 0.15));
      final Color okText = tester
          .widget<Text>(find.text('Erledigt'))
          .style!
          .color!;
      expect(okText, c.chipSuccessText);
      expect(
        tester.widget<Text>(find.text('Schmerz')).style!.color,
        c.chipWarnText,
      );
    });

    testWidgets('Text ≥ 4,5:1 in allen Themen und bei Hohem Kontrast', (
      WidgetTester tester,
    ) async {
      for (final CuraColors c in <CuraColors>[
        CuraColors.light,
        CuraColors.dark,
        CuraColors.lightHighContrast,
        CuraColors.darkHighContrast,
      ]) {
        expect(
          contrastRatio(c.chipSuccessText, c.chipSuccessFill),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(c.chipWarnText, c.chipWarnFill),
          greaterThanOrEqualTo(4.5),
        );
        // Neutral: Text auf der Karte im Worst Case.
        expect(
          worstCaseContrast(
            c.text1,
            compose(c.chipNeutralFill, c.surfaceOpaque),
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    testWidgets('Mandarine ist nie Statusfarbe', (WidgetTester tester) async {
      for (final Brightness b in Brightness.values) {
        await pumpWorld(tester, chips(), brightness: b);
        await tester.pumpAndSettle();
        final CuraColors c = colorsAt(tester, find.byType(StatusChip).first);
        for (final BoxDecoration d in decorationsUnder(
          tester,
          find.byType(Wrap),
        )) {
          expect(d.color, isNot(c.accent));
          expect(d.color, isNot(c.accentSoft));
        }
      }
    });

    testWidgets('wählbar: Hit-Area ≥ 48 dp, gewählt mit Rand zusätzlich zu '
        'Symbol und Text', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int taps = 0;
      await pumpWorld(
        tester,
        Center(
          child: Wrap(
            spacing: 8,
            children: <Widget>[
              StatusChip(label: 'Praxis', onPressed: () => taps++),
              StatusChip(label: 'Zuhause', selected: true, onPressed: () {}),
            ],
          ),
        ),
      );
      final Rect a = tester.getRect(find.byType(StatusChip).first);
      expect(a.height, greaterThanOrEqualTo(48));
      expect(a.width, greaterThanOrEqualTo(48));
      await tester.tap(find.text('Praxis'));
      expect(taps, 1);
      final CuraColors c = colorsAt(tester, find.byType(StatusChip).first);
      final BoxDecoration sel = decorationsUnder(
        tester,
        find.byType(StatusChip).last,
      ).first;
      expect((sel.border! as Border).top.color, c.text1);
      expect((sel.border! as Border).top.width, CuraSize.selectedBorder);
      expect(
        decorationsUnder(tester, find.byType(StatusChip).first).first.border,
        isNull,
      );
      expect(
        tester.getSemantics(find.text('Zuhause')),
        matchesSemantics(
          label: 'Zuhause',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });

    testWidgets('nicht wählbar: kein Tippziel, Screenreader liest den Text', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpWorld(tester, chips());
      expect(find.bySemanticsLabel('Erledigt'), findsOneWidget);
      final SemanticsData d = tester
          .getSemantics(find.bySemanticsLabel('Erledigt'))
          .getSemanticsData();
      expect(d.hasAction(SemanticsAction.tap), isFalse);
      h.dispose();
    });
  });
}
