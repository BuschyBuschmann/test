// PillButton, PrimaryPill, GlassPill (Brief v2, 4; V2-23, V2-31, V2-32; Ergänzung
// 1): Varianten, Pressed, Disabled, Fortschrittskreis, Hit-Area, Fokus,
// Tastatur.
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/ui/components/focus_ring.dart';
import 'package:curaone/ui/components/glass_pill.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/components/primary_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';
import '../support/world_app.dart';

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
  group('Primär (PrimaryPill, V2-31)', () {
    testWidgets('Verlauf Mandarine, Text on-accent, 56 dp, Pill, Schein '
        '0/14/24, kein harter Rand', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _button(PillButtonVariant.primary, onPressed: () {}),
      );
      final CuraColors c = colorsAt(tester, find.byType(PillButton));
      final BoxDecoration d = _pill(tester);
      expect(d.color, isNull);
      final LinearGradient g = d.gradient! as LinearGradient;
      expect(g.colors, <Color>[c.accentTop, c.accent]);
      expect(g.colors.first, const Color(0xFFFFA063));
      expect(g.colors.last, const Color(0xFFFF7A2E));
      expect(d.borderRadius, BorderRadius.circular(CuraRadius.pill));
      expect(d.border, isNull, reason: 'kein harter Rand');
      expect(d.boxShadow, CuraShadow.primaryGlow);
      expect(d.boxShadow!.single.offset, const Offset(0, 14));
      expect(d.boxShadow!.single.blurRadius, 24);
      expect(d.boxShadow!.single.color.a, closeTo(0.70, 0.005));
      expect(tester.getSize(find.byType(PillButton)).height, 56);
      final TextStyle s = tester
          .widget<Text>(find.text('Training starten'))
          .style!;
      expect(s.color, c.onAccent);
      expect(s.color, const Color(0xFF211B16));
      expect(s.fontFamily, 'BricolageGrotesque');
      expect(s.fontSize, 18);
      expect(s.fontWeight, FontWeight.w800);
      expect(backdropCount(tester), 0);
      // Lichtkante oben (1 dp, Weiß).
      expect(
        find.descendant(
          of: find.byType(PillButton),
          matching: find.byWidgetPredicate(
            (Widget w) => w is ColoredBox && w.color == c.primaryEdge,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Kontrast Text auf Mandarine ≥ 6,5:1 (auch auf #FFA063)', (
      WidgetTester tester,
    ) async {
      final CuraColors c = CuraColors.light;
      expect(contrastRatio(c.onAccent, c.accent), greaterThanOrEqualTo(6.5));
      expect(contrastRatio(c.onAccent, c.accentTop), greaterThanOrEqualTo(6.5));
      final CuraColors d = CuraColors.dark;
      expect(contrastRatio(d.onAccent, d.accent), greaterThanOrEqualTo(6.5));
    });

    testWidgets('Hoher Kontrast: kein Schein, keine Lichtkante', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _button(PillButtonVariant.primary, onPressed: () {}),
        highContrast: true,
      );
      expect(_pill(tester).boxShadow, isNull);
      expect(
        (_pill(tester).gradient! as LinearGradient).colors.last,
        const Color(0xFFFF7A2E),
      );
      expect(
        find.descendant(
          of: find.byType(PillButton),
          matching: find.byWidgetPredicate((Widget w) => w is ColoredBox),
        ),
        findsNothing,
      );
    });

    testWidgets('Gedrückt: 2 % kleiner, Schein halb', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _button(PillButtonVariant.primary, onPressed: () {}),
      );
      final Size rest = tester.getSize(find.byType(PillButton));
      final TestGesture g = await _press(tester);
      expect(_pill(tester).boxShadow, CuraShadow.primaryGlowPressed);
      expect(
        _pill(tester).boxShadow!.single.color.a,
        closeTo(0.35, 0.005),
        reason: 'Schein halb',
      );
      expect(
        tester
            .widgetList<Transform>(
              find.descendant(
                of: find.byType(PillButton),
                matching: find.byType(Transform),
              ),
            )
            .any(
              (Transform t) => (t.transform.entry(0, 0) - 0.98).abs() < 0.0001,
            ),
        isTrue,
        reason: '2 % kleiner',
      );
      expect(
        tester.getSize(find.byType(PillButton)),
        rest,
        reason: 'Layout bleibt, nur die Darstellung schrumpft',
      );
      await g.up();
      await tester.pump();
      expect(_pill(tester).boxShadow, CuraShadow.primaryGlow);
    });

    testWidgets('PrimaryPill ist die Primär-Variante', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryPill(
            label: 'Training starten',
            onPressed: () => taps++,
          ),
        ),
      );
      expect(
        tester.widget<PillButton>(find.byType(PillButton)).variant,
        PillButtonVariant.primary,
      );
      await tester.tap(find.byType(PrimaryPill));
      expect(taps, 1);
      expect(tester.getSize(find.byType(PrimaryPill)).height, 56);
    });
  });

  group('Glas (GlassPill)', () {
    testWidgets('Weiß 90 % ohne Blur, 52 dp, Rand border-control, Text ink-1', (
      WidgetTester tester,
    ) async {
      for (final Brightness b in Brightness.values) {
        await pumpWorld(
          tester,
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassPill(label: 'Abbrechen', onPressed: () {}),
            ),
          ),
          brightness: b,
        );
        await tester.pumpAndSettle();
        final CuraColors c = colorsAt(tester, find.byType(PillButton));
        final BoxDecoration d = _pill(tester);
        expect(d.color, const Color(0xFFFFFFFF).withValues(alpha: 0.90));
        expect(d.color, c.glassPillFill);
        expect(d.boxShadow, isNull);
        expect(
          d.border,
          Border.all(color: c.glassPillBorder, width: 1.5),
          reason: 'Rand border-control',
        );
        expect(c.glassPillBorder.a, closeTo(0.55, 0.005));
        expect(tester.getSize(find.byType(PillButton)).height, 52);
        expect(
          tester.widget<Text>(find.text('Abbrechen')).style!.color,
          const Color(0xFF211B16),
          reason: 'ink-1, die Pille bleibt in beiden Themen hell',
        );
        expect(backdropCount(tester), 0, reason: 'ohne Blur');
      }
    });

    testWidgets('Text auf der Pille ≥ 4,5:1 in beiden Themen und HC', (
      WidgetTester tester,
    ) async {
      for (final CuraColors c in <CuraColors>[
        CuraColors.light,
        CuraColors.dark,
        CuraColors.lightHighContrast,
        CuraColors.darkHighContrast,
      ]) {
        // Worst Case: Weiß 90 % über Schwarz.
        final Color under = compose(c.glassPillFill, const Color(0xFF000000));
        expect(contrastRatio(c.glassPillInk, under), greaterThanOrEqualTo(4.5));
        expect(
          contrastOver(c.glassPillBorder, c.glassPillFill),
          greaterThanOrEqualTo(3.0),
          reason: 'Bedienrand ≥ 3:1',
        );
      }
    });

    testWidgets('Pressed getönt; Hoher Kontrast opak mit Rand -hc', (
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
      final TestGesture g = await _press(tester);
      expect(_pill(tester).color, c.glassPillPressed);
      await g.up();
      await pumpApp(
        tester,
        _button(
          PillButtonVariant.neutral,
          onPressed: () {},
          label: 'Abbrechen',
        ),
        highContrast: true,
      );
      await tester.pumpAndSettle();
      final CuraColors hc = colorsAt(tester, find.byType(PillButton));
      expect(_pill(tester).color, hc.glassPillFill);
      expect(hc.glassPillFill.a, 1);
      expect(
        _pill(tester).border,
        Border.all(color: hc.glassPillBorder, width: 1.5),
      );
      expect(hc.glassPillBorder.a, closeTo(0.75, 0.005));
    });

    testWidgets('GlassPill ist die Neutral-Variante', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassPill(label: 'Abbrechen', onPressed: () {}),
        ),
      );
      expect(
        tester.widget<PillButton>(find.byType(PillButton)).variant,
        PillButtonVariant.neutral,
      );
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
      'Primär deaktiviert: Weiß 50 % mit ink-2-Text und Rand (V2-31)',
      (WidgetTester tester) async {
        int taps = 0;
        await pumpApp(tester, _button(PillButtonVariant.primary));
        final CuraColors c = colorsAt(tester, find.byType(PillButton));
        expect(_pill(tester).color, c.primaryDisabledFill);
        expect(
          _pill(tester).color,
          const Color(0xFFFFFFFF).withValues(alpha: 0.5),
        );
        expect(_pill(tester).gradient, isNull);
        expect(_pill(tester).boxShadow, isNull);
        expect(
          _pill(tester).border,
          Border.all(color: c.controlBorder, width: 1.5),
        );
        final Color text = tester
            .widget<Text>(find.text('Training starten'))
            .style!
            .color!;
        expect(text, const Color(0xFF5A5048), reason: 'ink-2');
        expect(text, c.primaryDisabledInk);
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

    testWidgets(
      'Glas deaktiviert: Füllung text-1 10 %, Inhalt text-1 38 %, keine Aktion',
      (WidgetTester tester) async {
        int taps = 0;
        await pumpApp(tester, _button(PillButtonVariant.neutral));
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

    testWidgets('busy: Statusansage als Live-Region (Erratum E-3)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        _button(
          PillButtonVariant.outline,
          onPressed: () {},
          busy: true,
          label: 'Ja, alles löschen',
        ),
      );
      SemanticsNode n = tester.getSemantics(find.byType(PillButton));
      expect(n.label, 'Ja, alles löschen, ${S.busyStatusDefault}');
      expect(n.flagsCollection.isLiveRegion, isTrue);
      // Ohne busy: Label unverändert, keine Live-Region.
      await pumpApp(
        tester,
        _button(PillButtonVariant.outline, onPressed: () {}, label: 'Ja'),
      );
      n = tester.getSemantics(find.byType(PillButton));
      expect(n.label, 'Ja');
      expect(n.flagsCollection.isLiveRegion, isFalse);
      h.dispose();
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

    testWidgets('Tastatur: Tab fokussiert mit focus-ring (3 dp, 2 dp Abstand, '
        '2 dp Außenrand), Enter und Leertaste lösen aus', (
      WidgetTester tester,
    ) async {
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
      // Ring: Kante 5 dp außerhalb (2 dp Abstand + 3 dp Breite), Außenrand 2 dp.
      final Finder ringBox = find.descendant(
        of: find.byType(FocusRing),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border ==
                  Border.all(color: c.focusRing, width: 3),
        ),
      );
      expect(ringBox, findsOneWidget);
      final Rect button = tester.getRect(find.byType(PillButton));
      final Rect ringRect = tester.getRect(ringBox);
      expect(ringRect.left, button.left - 5);
      expect(ringRect.top, button.top - 5);
      expect(ringRect.right, button.right + 5);
      expect(ringRect.bottom, button.bottom + 5);
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
