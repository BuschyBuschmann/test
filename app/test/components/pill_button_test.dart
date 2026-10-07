// PillButton (Brief 5.3, Ergänzung 1; UI-1, UI-32, UI-35, UI-67): Varianten,
// Pressed (Plan 8.4), Disabled, Fortschrittskreis, Hit-Area, Fokus, Tastatur.
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/ui/components/focus_ring.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

Widget _button(
  PillButtonVariant v, {
  VoidCallback? onPressed,
  bool busy = false,
  IconData? icon,
  String label = 'Training starten',
}) => Padding(
  padding: const EdgeInsets.all(16),
  child: Align(
    alignment: Alignment.topCenter,
    child: PillButton(
      label: label,
      variant: v,
      onPressed: onPressed,
      busy: busy,
      icon: icon,
    ),
  ),
);

BoxDecoration _pill(WidgetTester tester) =>
    decorationsUnder(tester, find.byType(PillButton)).first;

Future<TestGesture> _press(WidgetTester tester) async {
  final TestGesture g = await tester.startGesture(
    tester.getCenter(find.byType(PillButton)),
  );
  await tester.pump();
  return g;
}

void main() {
  group('Primär', () {
    testWidgets('Füllung accent, Text on-accent im button-Stil, 56 dp, Pill, '
        'Schein 0/8/28', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _button(PillButtonVariant.primary, onPressed: () {}),
      );
      final CuraColors c = colorsAt(tester, find.byType(PillButton));
      final BoxDecoration d = _pill(tester);
      expect(d.color, c.accent);
      expect(d.color, const Color(0xFFD9622B));
      expect(d.borderRadius, BorderRadius.circular(CuraRadius.pill));
      expect(d.boxShadow, CuraShadow.primaryGlow);
      expect(d.boxShadow!.single.offset, const Offset(0, 8));
      expect(d.boxShadow!.single.blurRadius, 28);
      expect(tester.getSize(find.byType(PillButton)).height, 56);
      final TextStyle s = tester
          .widget<Text>(find.text('Training starten'))
          .style!;
      expect(s.color, c.onAccent);
      expect(s.fontFamily, 'BricolageGrotesque');
      expect(s.fontSize, 18);
      expect(s.fontWeight, FontWeight.w600);
      expect(backdropCount(tester), 0);
    });

    testWidgets('Hoher Kontrast: kein Schein', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _button(PillButtonVariant.primary, onPressed: () {}),
        highContrast: true,
      );
      expect(_pill(tester).boxShadow, isNull);
      expect(_pill(tester).color, const Color(0xFFD9622B));
    });

    testWidgets('Pressed: Füllung #DD7240', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _button(PillButtonVariant.primary, onPressed: () {}),
      );
      final TestGesture g = await _press(tester);
      expect(_pill(tester).color, const Color(0xFFDD7240));
      await g.up();
      await tester.pump();
      expect(_pill(tester).color, const Color(0xFFD9622B));
    });
  });

  group('Neutral hell', () {
    testWidgets('Füllung text-1, Text on-accent; Pressed reines Weiß', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _button(
          PillButtonVariant.neutral,
          onPressed: () {},
          label: 'Abbrechen',
        ),
      );
      final CuraColors c = colorsAt(tester, find.byType(PillButton));
      expect(_pill(tester).color, c.text1);
      expect(_pill(tester).boxShadow, isNull);
      expect(
        tester.widget<Text>(find.text('Abbrechen')).style!.color,
        c.onAccent,
      );
      final TestGesture g = await _press(tester);
      expect(_pill(tester).color, const Color(0xFFFFFFFF));
      await g.up();
    });
  });

  group('Umriss', () {
    testWidgets('keine Füllung, 1,5 dp Rand border-control, Text text-1; '
        'Pressed Weiß 10 %', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _button(
          PillButtonVariant.outline,
          onPressed: () {},
          icon: Icons.delete_outline_rounded,
          label: 'Ja, alles löschen',
        ),
      );
      final CuraColors c = colorsAt(tester, find.byType(PillButton));
      BoxDecoration d = _pill(tester);
      expect(d.color, isNull);
      expect(d.border, Border.all(color: c.borderControl, width: 1.5));
      expect(
        tester.widget<Text>(find.text('Ja, alles löschen')).style!.color,
        c.text1,
      );
      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.delete_outline_rounded),
      );
      expect(icon.color, c.text1);
      expect(icon.size, 24);
      final TestGesture g = await _press(tester);
      d = _pill(tester);
      expect(d.color, c.pressedOverlay);
      await g.up();
    });

    testWidgets('Hoher Kontrast: Rand border-control-hc', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _button(PillButtonVariant.outline, onPressed: () {}),
        highContrast: true,
      );
      final CuraColors c = colorsAt(tester, find.byType(PillButton));
      expect(
        _pill(tester).border,
        Border.all(color: c.borderControlHc, width: 1.5),
      );
    });
  });

  group('Disabled und Fortschritt', () {
    testWidgets(
      'Disabled: Füllung Weiß 10 %, Inhalt text-1 38 %, keine Aktion',
      (WidgetTester tester) async {
        int taps = 0;
        await pumpApp(tester, _button(PillButtonVariant.primary));
        final CuraColors c = colorsAt(tester, find.byType(PillButton));
        expect(_pill(tester).color, c.disabledFill);
        expect(_pill(tester).boxShadow, isNull);
        final Color text = tester
            .widget<Text>(find.text('Training starten'))
            .style!
            .color!;
        expect(text, c.disabledContent);
        expect(text.a, closeTo(0.38, 0.005));
        await tester.tap(find.byType(PillButton));
        expect(taps, 0);
        final SemanticsHandle h = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.text('Training starten')),
          matchesSemantics(
            label: 'Training starten',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
        h.dispose();
      },
    );

    testWidgets('busy: Fortschrittskreis, Label bleibt, Tipp wirkungslos', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpApp(
        tester,
        _button(
          PillButtonVariant.outline,
          onPressed: () => taps++,
          busy: true,
          label: 'Ja, alles löschen',
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Ja, alles löschen'), findsOneWidget);
      await tester.tap(find.byType(PillButton), warnIfMissed: false);
      expect(taps, 0);
      // Höhe unverändert (Kreis ersetzt das Icon, keine Höhenänderung).
      expect(tester.getSize(find.byType(PillButton)).height, 56);
    });
  });

  group('Bedienung', () {
    testWidgets('Tipp löst aus', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        _button(PillButtonVariant.primary, onPressed: () => taps++),
      );
      await tester.tap(find.byType(PillButton));
      expect(taps, 1);
    });

    testWidgets('Tastatur: Tab fokussiert mit focus-ring (2 dp, 2 dp Abstand), '
        'Enter und Leertaste lösen aus', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        _button(PillButtonVariant.primary, onPressed: () => taps++),
      );
      expect(find.byType(FocusRing), findsOneWidget);
      expect(tester.widget<FocusRing>(find.byType(FocusRing)).focused, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final FocusRing ring = tester.widget<FocusRing>(find.byType(FocusRing));
      expect(ring.focused, isTrue);
      final CuraColors c = colorsAt(tester, find.byType(PillButton));
      // Ring: Kante 4 dp außerhalb (2 dp Abstand + 2 dp Breite), Farbe focus-ring.
      final Finder ringBox = find.descendant(
        of: find.byType(FocusRing),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border ==
                  Border.all(color: c.focusRing, width: 2),
        ),
      );
      expect(ringBox, findsOneWidget);
      final Rect button = tester.getRect(find.byType(PillButton));
      final Rect ringRect = tester.getRect(ringBox);
      expect(ringRect.left, button.left - 4);
      expect(ringRect.top, button.top - 4);
      expect(ringRect.right, button.right + 4);
      expect(ringRect.bottom, button.bottom + 4);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 2);
    });

    testWidgets('Hit-Area ≥ 48 dp und Labels (Guidelines)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        _button(PillButtonVariant.primary, onPressed: () {}),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      h.dispose();
    });

    testWidgets(
      'Semantik: Schaltfläche mit Text als Label, Icon ausgeblendet',
      (WidgetTester tester) async {
        final SemanticsHandle h = tester.ensureSemantics();
        await pumpApp(
          tester,
          _button(
            PillButtonVariant.primary,
            onPressed: () {},
            icon: Icons.play_arrow_rounded,
          ),
        );
        expect(
          tester.getSemantics(find.text('Training starten')),
          matchesSemantics(
            label: 'Training starten',
            isButton: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        h.dispose();
      },
    );
  });

  group('Layout', () {
    testWidgets('Umbruch bei 320 dp und 200 %: wächst in die Höhe, nichts '
        'abgeschnitten', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _button(
          PillButtonVariant.primary,
          onPressed: () {},
          label: 'Training eintragen und weitermachen',
        ),
        size: Viewports.small,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PillButton)).height, greaterThan(56));
    });

    testWidgets('Breite im Primärbutton-Row: Viewport − 96 dp (bei 320 dp '
        '224 dp, UI-73)', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: PillButton(label: 'Training starten', onPressed: () {}),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 56, height: 56),
            ],
          ),
        ),
        size: Viewports.small,
      );
      expect(tester.getSize(find.byType(PillButton)).width, 224);
    });
  });
}
