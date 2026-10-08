// FloatingNav (Brief 5.4, UI-6, UI-33, UI-35): Maße, aktiv/inaktiv, Labels,
// Skalierungsgrenze 1,3, Schatten, Blur, Hoher Kontrast, Tastatur.
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/theme/cura_theme.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

const List<NavItem> _items = <NavItem>[
  NavItem(icon: Icons.route_rounded, label: 'Pfad'),
  NavItem(icon: Icons.event_available_rounded, label: 'Heute'),
];

Widget _nav({int index = 0, ValueChanged<int>? onSelected}) => Align(
  alignment: Alignment.bottomCenter,
  child: FloatingNav(
    items: _items,
    currentIndex: index,
    onSelected: onSelected ?? (_) {},
  ),
);

/// Die Pill-Leiste (der Eintrag mit Blur und Rand).
Finder _bar() => find.descendant(
  of: find.byType(FloatingNav),
  matching: find.byType(BackdropFilter),
);

void main() {
  testWidgets('Maße: 64 dp hoch, 16 dp Seitenabstand, 22 dp zum unteren Rand', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _nav());
    final Rect bar = tester.getRect(_bar());
    expect(bar.height, 64);
    expect(bar.left, 16);
    expect(bar.right, 390 - 16);
    expect(844 - bar.bottom, 22);
    expect(CuraSize.navHeight, 64);
  });

  testWidgets('Safe Area unten wird zusätzlich eingehalten', (
    WidgetTester tester,
  ) async {
    setViewport(tester, Viewports.phone);
    await tester.pumpWidget(
      MaterialApp(
        theme: CuraTheme.build(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
          ),
          child: Scaffold(body: _nav()),
        ),
      ),
    );
    final Rect bar = tester.getRect(_bar());
    expect(844 - bar.bottom, 22 + 34);
  });

  testWidgets('Pill: E2-Fläche, Blur, Rand hair, Schatten 0/10/30', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _nav());
    expect(backdropCount(tester), 1);
    final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
    final Iterable<BoxDecoration> d = decorationsUnder(
      tester,
      find.byType(FloatingNav),
    );
    expect(
      d.any(
        (BoxDecoration x) =>
            x.color == c.floatFill &&
            x.border == Border.all(color: c.borderHair, width: 1),
      ),
      isTrue,
    );
    expect(
      d.any((BoxDecoration x) => x.boxShadow == CuraShadow.floating),
      isTrue,
    );
    expect(CuraShadow.floating.single.offset, const Offset(0, 10));
    expect(CuraShadow.floating.single.blurRadius, 30);
  });

  testWidgets('Hoher Kontrast: opak, Rand -hc, kein Blur, kein Schatten', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _nav(), highContrast: true);
    expect(backdropCount(tester), 0);
    final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
    final Iterable<BoxDecoration> d = decorationsUnder(
      tester,
      find.byType(FloatingNav),
    );
    expect(
      d.any(
        (BoxDecoration x) =>
            x.color == const Color(0xFF1B2129) &&
            x.border == Border.all(color: c.borderControlHc, width: 1),
      ),
      isTrue,
    );
    expect(d.every((BoxDecoration x) => x.boxShadow == null), isTrue);
  });

  testWidgets('Ausblend-Verlauf: transparent zu bg unter der Leiste', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _nav());
    final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
    final Iterable<BoxDecoration> d = decorationsUnder(
      tester,
      find.byType(FloatingNav),
    );
    final LinearGradient g = d
        .map((BoxDecoration x) => x.gradient)
        .whereType<LinearGradient>()
        .single;
    expect(g.colors.last, c.bg);
    expect(g.colors.first.a, 0);
    expect(g.begin, Alignment.topCenter);
    // Die Fläche reicht bis zum unteren Rand und ist größer als die Leiste.
    final Rect all = tester.getRect(find.byType(FloatingNav));
    expect(all.bottom, 844);
    expect(all.height, greaterThan(64 + 22));
    expect(
      FloatingNav.occupiedHeight(tester.element(find.byType(FloatingNav))),
      64 + 22,
    );
  });

  testWidgets('Aktiv: accent-soft, 1 dp Rand accent 60 %, Icon accent-hi, '
      'Label text-1; inaktiv text-2', (WidgetTester tester) async {
    await pumpApp(tester, _nav());
    final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
    final Finder activeBox = find.ancestor(
      of: find.text('Pfad'),
      matching: find.byWidgetPredicate(
        (Widget w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration).color == c.accentSoft,
      ),
    );
    expect(activeBox, findsOneWidget);
    expect(tester.getSize(activeBox).height, greaterThanOrEqualTo(48));
    expect(
      (tester.widget<DecoratedBox>(activeBox).decoration as BoxDecoration)
          .border,
      Border.all(color: c.navActiveBorder, width: 1),
    );
    expect(c.navActiveBorder.a, closeTo(0.6, 0.005));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.route_rounded)).color,
      c.accentHi,
    );
    expect(tester.widget<Text>(find.text('Pfad')).style!.color, c.text1);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.event_available_rounded)).color,
      c.text2,
    );
    expect(tester.widget<Text>(find.text('Heute')).style!.color, c.text2);
  });

  testWidgets('Icon und Label immer beide sichtbar', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _nav());
    expect(find.text('Pfad'), findsOneWidget);
    expect(find.text('Heute'), findsOneWidget);
    expect(find.byType(Icon), findsNWidgets(2));
  });

  testWidgets('Labels sind ab Textskalierung 1,3 begrenzt, der Rest wächst', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _nav());
    final double normal = tester.getSize(find.text('Pfad')).height;
    await pumpApp(tester, _nav(), textScale: 1.3);
    final double at13 = tester.getSize(find.text('Pfad')).height;
    await pumpApp(tester, _nav(), textScale: 2);
    final double at2 = tester.getSize(find.text('Pfad')).height;
    expect(at13, greaterThan(normal));
    expect(at2, at13);
    final Text t = tester.widget(find.text('Pfad'));
    expect(
      MediaQuery.textScalerOf(tester.element(find.byWidget(t))).scale(10),
      closeTo(13, 0.001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tipp wählt, Semantik: Schaltfläche mit Label und Auswahl', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle h = tester.ensureSemantics();
    final List<int> picked = <int>[];
    await pumpApp(tester, _nav(onSelected: picked.add));
    await tester.tap(find.text('Heute'));
    expect(picked, <int>[1]);
    expect(
      tester.getSemantics(find.text('Pfad')),
      matchesSemantics(
        label: 'Pfad',
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
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // `textContrastGuideline` liest im aktiven Eintrag die Icon-Pixel
    // (accent-hi) als Text und meldet fälschlich 2,27; die Paare werden daher
    // aus den Tokens gerechnet (siehe nächster Test).
    h.dispose();
  });

  testWidgets('Kontraste der Paare (Brief 3.1): Label text-1 auf aktiver '
      'Pill ≥ 4,5, inaktiv text-2 auf Nav ≥ 4,5, Icon accent-hi ≥ 3', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _nav());
    final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
    final Color nav = floatOverBg(c);
    final Color pill = compose(c.accentSoft, nav);
    expect(contrastRatio(c.text1, pill), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(c.text2, nav), greaterThanOrEqualTo(7.0));
    expect(contrastRatio(c.accentHi, pill), greaterThanOrEqualTo(3));
  });

  testWidgets('Tastatur: Tab erreicht die Einträge, Enter wählt', (
    WidgetTester tester,
  ) async {
    final List<int> picked = <int>[];
    await pumpApp(tester, _nav(onSelected: picked.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(picked, <int>[1]);
  });

  testWidgets('320 dp und 200 %: keine Überläufe', (WidgetTester tester) async {
    await pumpApp(tester, _nav(), size: Viewports.small, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
