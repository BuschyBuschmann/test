// PathNode, StatPill, PathHeader, NodeHint und die begrenzte MannyBubble
// (U3a, Brief 5.5, 5.9, Ergänzung 1 3.1/3.5; UI-18, UI-20, UI-22, UI-25,
// UI-60 bis UI-63, UI-65; Regel 12, B-8).
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/injury_type.dart';
import 'package:curaone/logic/path_generator.dart';
import 'package:curaone/logic/path_model.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/theme/cura_theme.dart';
import 'package:curaone/ui/components/focus_ring.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/node_hint.dart';
import 'package:curaone/ui/components/path_header.dart';
import 'package:curaone/ui/components/path_node.dart';
import 'package:curaone/ui/components/stat_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

PathUnit _unit(String id) => kSamplePath.firstWhere((PathUnit u) => u.id == id);

double _diameter(PathUnit u) => switch (u.kind) {
  UnitKind.trainingDay => CuraSize.unitSmall,
  UnitKind.weekGoal => CuraSize.unitMedium,
  UnitKind.phaseEnd => CuraSize.unitLarge,
  UnitKind.boss => CuraSize.unitBoss,
};

Widget _node(
  String id,
  UnitStatus status, {
  VoidCallback? onPressed,
  bool pulse = false,
  VoidCallback? onPulseDone,
}) {
  final PathUnit u = _unit(id);
  return Center(
    child: SizedBox.square(
      dimension: _diameter(u),
      child: PathNode(
        key: ValueKey<String>('node-$id'),
        unit: u,
        status: status,
        diameter: _diameter(u),
        semanticLabel: unitSemanticsLabel(u, status),
        onPressed: onPressed ?? () {},
        pulse: pulse,
        onPulseDone: onPulseDone,
      ),
    ),
  );
}

/// Alle Dekorationen unter dem Knoten, die einen Kreis beschreiben.
List<BoxDecoration> _circles(WidgetTester tester, String id) =>
    decorationsUnder(
      tester,
      find.byKey(ValueKey<String>('node-$id')),
    ).where((BoxDecoration d) => d.shape == BoxShape.circle).toList();

/// Wie `pumpApp`, mit „Bewegung reduzieren“ (`disableAnimations`) im
/// `MaterialApp.builder` (ein Override oberhalb der App würde nicht wirken).
Future<void> _pumpReduced(WidgetTester tester, Widget child) async {
  setViewport(tester, Viewports.phone);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CuraTheme.build(),
      locale: const Locale('de'),
      supportedLocales: const <Locale>[Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: app!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PathNode (Brief 5.5, UI-20)', () {
    testWidgets('Größen 48 / 60 / 72 / 92 und Hit-Area mindestens 48 dp', (
      WidgetTester tester,
    ) async {
      for (final (String, double) c in <(String, double)>[
        ('w5-d1', 48),
        ('w5-goal', 60),
        ('p2-end', 72),
        ('boss', 92),
      ]) {
        await pumpApp(tester, _node(c.$1, UnitStatus.locked));
        final Size s = tester.getSize(find.byType(PathNode));
        expect(s, Size(c.$2, c.$2), reason: c.$1);
        expect(s.width, greaterThanOrEqualTo(CuraSize.touchTarget));
      }
    });

    testWidgets('erledigt: Füllung text-1, dunkler Haken (on-accent)', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, _node('w4-d1', UnitStatus.done));
      final CuraColors c = colorsAt(tester, find.byType(PathNode));
      expect(_circles(tester, 'w4-d1').single.color, c.text1);
      final Icon icon = tester.widget(find.byIcon(Icons.check_rounded));
      expect(icon.color, c.onAccent);
      expect(icon.size, 48 * CuraSize.unitIconFactor);
    });

    testWidgets('aktuell: Füllung accent, Flagge on-accent, Ring 1,5 dp '
        'accent 40 % im Abstand 9 dp', (WidgetTester tester) async {
      await pumpApp(tester, _node('w5-d1', UnitStatus.current));
      final CuraColors c = colorsAt(tester, find.byType(PathNode));
      expect(_circles(tester, 'w5-d1').single.color, c.accent);
      final Icon icon = tester.widget(find.byIcon(Icons.flag_rounded));
      expect(icon.color, c.onAccent);
      // Ring und Schein: eine Aura über den Kreis hinaus, außerhalb der Box.
      expect(
        tester.getSize(find.byType(PathNode)),
        const Size(48, 48),
        reason: 'die Aura vergrößert die Hit-Area nicht',
      );
      final Finder aura = find.descendant(
        of: find.byKey(const ValueKey<String>('node-w5-d1')),
        matching: find.byWidgetPredicate(
          (Widget w) => w is CustomPaint && w.painter != null,
        ),
      );
      expect(aura, findsOneWidget);
      final RenderBox box = tester.renderObject(aura);
      final double outer =
          CuraSize.unitRingGap +
          CuraSize.unitRingWidth +
          CuraSize.unitGlowExtent;
      expect(box.size, Size(48 + 2 * outer, 48 + 2 * outer));
    });

    testWidgets('gesperrt: Glas-Füllung, Rand Weiß 20 %, Schloss Weiß 50 %', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, _node('w6-d1', UnitStatus.locked));
      final CuraColors c = colorsAt(tester, find.byType(PathNode));
      final BoxDecoration d = _circles(tester, 'w6-d1').first;
      expect(d.gradient, c.cardFill);
      final Border border = d.border! as Border;
      expect(border.top.color, c.lockedBorder);
      expect(border.top.width, CuraSize.controlBorder);
      expect(c.lockedBorder.a, closeTo(0.20, 0.005));
      final Icon icon = tester.widget(find.byIcon(Icons.lock_rounded));
      expect(icon.color, c.lockedIcon);
      expect(c.lockedIcon.a, closeTo(0.50, 0.005));
    });

    testWidgets('Boss gesperrt: Rand accent 55 %, Stern accent-hi; groß '
        'gesperrt: Stern Weiß 50 %', (WidgetTester tester) async {
      await pumpApp(tester, _node('boss', UnitStatus.locked));
      final CuraColors c = colorsAt(tester, find.byType(PathNode));
      final Border boss = _circles(tester, 'boss').first.border! as Border;
      expect(boss.top.color, c.bossBorder);
      expect(c.bossBorder.a, closeTo(0.55, 0.005));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.star_rounded)).color,
        c.accentHi,
      );

      await pumpApp(tester, _node('p2-end', UnitStatus.locked));
      final Border big = _circles(tester, 'p2-end').first.border! as Border;
      expect(big.top.color, c.lockedBorder);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.star_rounded)).color,
        c.lockedIcon,
      );
    });

    testWidgets('Zustand nie nur in der Farbe: je Zustand ein anderes Symbol '
        'und ein Label (UI-18)', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      final Map<UnitStatus, IconData> icons = <UnitStatus, IconData>{
        UnitStatus.done: Icons.check_rounded,
        UnitStatus.current: Icons.flag_rounded,
        UnitStatus.locked: Icons.lock_rounded,
      };
      final Map<UnitStatus, String> labels = <UnitStatus, String>{
        UnitStatus.done: 'Woche 4, Trainingstag 1, erledigt.',
        UnitStatus.current: 'Woche 5, Trainingstag 1, aktuell. Öffnet Heute.',
        UnitStatus.locked: 'Woche 6, Trainingstag 1, gesperrt.',
      };
      final Map<UnitStatus, String> ids = <UnitStatus, String>{
        UnitStatus.done: 'w4-d1',
        UnitStatus.current: 'w5-d1',
        UnitStatus.locked: 'w6-d1',
      };
      for (final UnitStatus s in UnitStatus.values) {
        await pumpApp(tester, _node(ids[s]!, s));
        expect(find.byIcon(icons[s]!), findsOneWidget, reason: '$s');
        expect(
          tester.getSemantics(find.byIcon(icons[s]!)),
          matchesSemantics(
            label: labels[s],
            isButton: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      }
      h.dispose();
    });

    testWidgets('Tipp, Enter und Leertaste lösen aus; Fokus zeigt den Ring', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpApp(
        tester,
        _node('w5-d1', UnitStatus.current, onPressed: () => taps++),
      );
      await tester.tap(find.byType(PathNode));
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.widget<FocusRing>(find.byType(FocusRing)).focused, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 3);
    });

    testWidgets(
      'Pressed: Füllung 10 % heller (aktuell accent-pressed, erledigt '
      'Weiß, gesperrt Überlagerung Weiß 10 %)',
      (WidgetTester tester) async {
        for (final (String, UnitStatus) c in <(String, UnitStatus)>[
          ('w5-d1', UnitStatus.current),
          ('w4-d1', UnitStatus.done),
          ('w6-d1', UnitStatus.locked),
        ]) {
          await pumpApp(tester, _node(c.$1, c.$2));
          final CuraColors colors = colorsAt(tester, find.byType(PathNode));
          final TestGesture g = await tester.startGesture(
            tester.getCenter(find.byType(PathNode)),
          );
          await tester.pump();
          final List<BoxDecoration> d = _circles(tester, c.$1);
          switch (c.$2) {
            case UnitStatus.current:
              expect(d.single.color, colors.accentPressed);
            case UnitStatus.done:
              expect(d.single.color, colors.pureWhite);
            case UnitStatus.locked:
              expect(
                d.any((BoxDecoration x) => x.color == colors.pressedOverlay),
                isTrue,
              );
          }
          await g.up();
          await tester.pump();
        }
      },
    );

    testWidgets('Hoher Kontrast: gesperrter Rand border-control-hc, Füllung '
        'opak (UI-65)', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _node('w6-d1', UnitStatus.locked),
        highContrast: true,
      );
      final CuraColors c = colorsAt(tester, find.byType(PathNode));
      expect(c.highContrast, isTrue);
      final BoxDecoration d = _circles(tester, 'w6-d1').first;
      expect(d.gradient, c.cardFill);
      expect(
        (d.gradient! as LinearGradient).colors,
        everyElement(c.surfaceOpaque),
      );
      expect((d.border! as Border).top.color, c.controlBorder);
    });

    testWidgets('Ring-Puls: läuft dur-slow einmal und meldet das Ende', (
      WidgetTester tester,
    ) async {
      int done = 0;
      await pumpApp(tester, _node('w5-d1', UnitStatus.done, pulse: false));
      await pumpApp(
        tester,
        _node('w5-d1', UnitStatus.done, pulse: true, onPulseDone: () => done++),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(done, 0);
      await tester.pump(const Duration(milliseconds: 250));
      expect(done, 1);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.binding.transientCallbackCount, 0);
      expect(done, 1, reason: 'nur einmal');
    });

    testWidgets('Ring-Puls bei reduzierter Bewegung: entfällt (UI-8)', (
      WidgetTester tester,
    ) async {
      int done = 0;
      await _pumpReduced(
        tester,
        _node('w5-d1', UnitStatus.done, pulse: true, onPulseDone: () => done++),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(done, 1, reason: 'Ende wird sofort gemeldet');
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('StatPill (B-8: reine Information)', () {
    testWidgets('kein Tap-Ziel, kein Button; Label ersetzt den Inhalt', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        const Center(
          child: StatPill(
            icon: Icons.ac_unit_rounded,
            iconColor: Colors.white,
            value: '2',
            semanticLabel: 'Streak-Freezes: 2',
          ),
        ),
      );
      final SemanticsData d = tester
          .getSemantics(find.byType(StatPill))
          .getSemanticsData();
      expect(d.label, 'Streak-Freezes: 2');
      expect(d.hasAction(SemanticsAction.tap), isFalse);
      expect(d.flagsCollection.isButton, isFalse);
      expect(find.byType(GestureDetector), findsNothing);
      expect(find.byType(InkWell), findsNothing);
      h.dispose();
    });

    testWidgets('deckende Fläche surface-opaque, kein Blur, Rand border-hair', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const Center(
          child: StatPill(
            icon: Icons.ac_unit_rounded,
            iconColor: Colors.white,
            value: '2',
            semanticLabel: 'x',
          ),
        ),
      );
      final CuraColors c = colorsAt(tester, find.byType(StatPill));
      final BoxDecoration d = decorationsUnder(
        tester,
        find.byType(StatPill),
      ).first;
      expect(d.color, c.surfaceOpaque);
      expect((d.border! as Border).top.color, c.cardBorder);
      expect(backdropCount(tester), 0);
    });

    for (final double scale in <double>[1, 2]) {
      testWidgets('gemessene Breite stimmt mit der gebauten überein '
          '(×$scale)', (WidgetTester tester) async {
        await pumpApp(
          tester,
          Material(
            type: MaterialType.transparency,
            child: Builder(
              builder: (BuildContext context) => Align(
                alignment: Alignment.topLeft,
                child: Column(
                  children: <Widget>[
                    const StatPill(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.white,
                      value: '12',
                      extra: 'eingefroren',
                      semanticLabel: 'x',
                    ),
                    Text(
                      '${StatPill.measureWidth(context, value: '12', extra: 'eingefroren')}',
                    ),
                  ],
                ),
              ),
            ),
          ),
          textScale: scale,
        );
        final double built = tester.getSize(find.byType(StatPill)).width;
        final double measured = double.parse(
          (tester.widget(find.byType(Text).last) as Text).data!,
        );
        expect(measured, closeTo(built, 1.5));
      });
    }
  });

  group('PathHeader (Brief 5.9, Ergänzung 1 3.1, UI-22, UI-25)', () {
    Future<void> pumpHeader(
      WidgetTester tester, {
      Size size = Viewports.phone,
      double scale = 1,
      StreakView streak = const StreakView(
        count: 12,
        freezes: 2,
        display: StreakDisplay.active,
      ),
      InjuryType type = InjuryType.acl,
      VoidCallback? onOpenData,
      bool hc = false,
    }) => pumpApp(
      tester,
      PathHeader(
        week: 5,
        phaseLine: phaseLine(2, type),
        streak: streak,
        onOpenData: onOpenData ?? () {},
      ),
      size: size,
      textScale: scale,
      highContrast: hc,
    );

    testWidgets('Zeile bei 390 dp: Textblock links, Freeze, Streak, Icon '
        'rechts, alles in einer Zeile', (WidgetTester tester) async {
      await pumpHeader(tester);
      expect(find.text('Woche 5'), findsOneWidget);
      expect(find.text('Phase 2 · Kreuzband'), findsOneWidget);
      expect(find.text('BEISPIELPFAD'), findsOneWidget);
      final Rect text = tester.getRect(find.text('Woche 5'));
      final Rect freeze = tester.getRect(find.text('2'));
      final Rect streak = tester.getRect(find.text('12'));
      final Rect icon = tester.getRect(find.byType(HeaderIconButton));
      expect(text.left, 16);
      expect(freeze.left, greaterThan(text.right));
      expect(streak.left, greaterThan(freeze.right));
      expect(icon.left, greaterThan(streak.right));
      expect(icon.size, const Size(48, 48));
      expect(icon.right, 390 - 16);
      // eine Zeile: Freeze, Streak und Icon auf gleicher Höhe (Mitte).
      expect(freeze.center.dy, closeTo(streak.center.dy, 1));
      expect(icon.center.dy, closeTo(streak.center.dy, 2));
      // 4 dp zwischen den Pillen, 4 dp zum Icon.
      final Rect fp = tester.getRect(find.byType(StatPill).first);
      final Rect sp = tester.getRect(find.byType(StatPill).last);
      expect(sp.left - fp.right, CuraSize.statPillGap);
      expect(icon.left - sp.right, CuraSize.statPillGap);
    });

    testWidgets('Umbruch bei 320 dp: Zeile 1 Textblock und Icon, Zeile 2 '
        '(8 dp tiefer) beide Pillen linksbündig', (WidgetTester tester) async {
      await pumpHeader(tester, size: Viewports.small);
      final Rect text = tester.getRect(find.byType(Column).first);
      final Rect icon = tester.getRect(find.byType(HeaderIconButton));
      final Rect fp = tester.getRect(find.byType(StatPill).first);
      final Rect sp = tester.getRect(find.byType(StatPill).last);
      expect(icon.right, 320 - 16);
      expect(fp.left, 16);
      expect(
        fp.top,
        greaterThanOrEqualTo(
          tester.getRect(find.text('BEISPIELPFAD')).bottom + 8 - 0.5,
        ),
      );
      expect(sp.left, fp.right + CuraSize.statPillGap);
      expect(sp.top, fp.top);
      expect(text.top, lessThan(fp.top));
    });

    testWidgets('Umbruch bei Textskalierung 1,2 und 2,0: alles sichtbar, '
        'nichts überlagert, kein Überlauf', (WidgetTester tester) async {
      for (final double s in <double>[1.2, 2]) {
        await pumpHeader(
          tester,
          size: Viewports.small,
          scale: s,
          streak: const StreakView(
            count: 12,
            freezes: 1,
            display: StreakDisplay.frozen,
          ),
        );
        expect(tester.takeException(), isNull, reason: '×$s');
        final Rect icon = tester.getRect(find.byType(HeaderIconButton));
        expect(icon.right, lessThanOrEqualTo(320 - 16 + 0.01));
        for (final Finder f in <Finder>[
          find.text('Woche 5'),
          find.text('Phase 2 · Kreuzband'),
          find.text('eingefroren'),
          find.text('12'),
          find.text('1'),
        ]) {
          final Rect r = tester.getRect(f);
          expect(r.left, greaterThanOrEqualTo(0), reason: '×$s');
          expect(r.right, lessThanOrEqualTo(320.01), reason: '×$s');
        }
        // Das Icon überlagert keinen Text.
        for (final String t in <String>['Woche 5', 'Phase 2 · Kreuzband']) {
          expect(
            tester.getRect(find.text(t)).overlaps(icon),
            isFalse,
            reason: '$t ×$s',
          );
        }
      }
    });

    testWidgets('Freeze 0, 1, 2 mit Zahl und Label „Streak-Freezes: n“', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      for (final int n in <int>[0, 1, 2]) {
        await pumpHeader(
          tester,
          streak: StreakView(
            count: 12,
            freezes: n,
            display: StreakDisplay.active,
          ),
        );
        expect(find.byIcon(Icons.ac_unit_rounded), findsOneWidget);
        expect(find.bySemanticsLabel(S.freezesLabel(n)), findsOneWidget);
        expect(find.text('$n'), findsOneWidget);
      }
      h.dispose();
    });

    testWidgets('Streak aktiv: Flamme accent-hi, „Streak: 12 Tage“; kein Wort '
        '„eingefroren“', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpHeader(tester);
      final CuraColors c = colorsAt(tester, find.byType(PathHeader));
      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.local_fire_department_rounded))
            .color,
        c.accentHi,
      );
      expect(find.bySemanticsLabel('Streak: 12 Tage'), findsOneWidget);
      expect(find.text('eingefroren'), findsNothing);
      h.dispose();
    });

    testWidgets('Streak eingefroren: Flamme streak-freeze plus das Wort '
        '„eingefroren“ (Text, nicht nur Farbe, UI-18/UI-22)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpHeader(
        tester,
        streak: const StreakView(
          count: 12,
          freezes: 1,
          display: StreakDisplay.frozen,
        ),
      );
      final CuraColors c = colorsAt(tester, find.byType(PathHeader));
      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.local_fire_department_rounded))
            .color,
        c.streakFreeze,
      );
      expect(find.text('eingefroren'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Streak: 12 Tage, eingefroren'),
        findsOneWidget,
      );
      h.dispose();
    });

    testWidgets('Streak Reset: Zahl 0, Flamme text-3; ein Tag heißt „1 Tag“', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpHeader(
        tester,
        streak: const StreakView(
          count: 0,
          freezes: 0,
          display: StreakDisplay.reset,
        ),
      );
      final CuraColors c = colorsAt(tester, find.byType(PathHeader));
      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.local_fire_department_rounded))
            .color,
        c.text3,
      );
      expect(find.bySemanticsLabel('Streak: 0 Tage'), findsOneWidget);
      await pumpHeader(
        tester,
        streak: const StreakView(
          count: 1,
          freezes: 2,
          display: StreakDisplay.active,
        ),
      );
      expect(find.bySemanticsLabel('Streak: 1 Tag'), findsOneWidget);
      h.dispose();
    });

    testWidgets('„Beispielpfad“ für alle vier Verletzungstypen, auch ACL '
        '(UI-25), mit Kurzname in der Phasenzeile', (
      WidgetTester tester,
    ) async {
      final Map<InjuryType, String> names = <InjuryType, String>{
        InjuryType.acl: 'Kreuzband',
        InjuryType.ankle: 'Sprunggelenk',
        InjuryType.muscle: 'Muskelfaser',
        InjuryType.other: 'Reha',
      };
      for (final InjuryType t in InjuryType.values) {
        await pumpHeader(tester, type: t);
        expect(find.text('BEISPIELPFAD'), findsOneWidget, reason: '$t');
        expect(
          find.text('Phase 2 · ${names[t]}'),
          findsOneWidget,
          reason: '$t',
        );
      }
    });

    testWidgets('„Deine Daten“: 48 dp, Tooltip, Label, ruft den Einstieg; die '
        'Pillen sind keine Tap-Ziele', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int taps = 0;
      await pumpHeader(tester, onOpenData: () => taps++);
      expect(find.byTooltip('Deine Daten'), findsOneWidget);
      expect(find.bySemanticsLabel('Deine Daten'), findsOneWidget);
      await tester.tap(find.byType(HeaderIconButton));
      expect(taps, 1);
      // Antippen einer Pille tut nichts und trifft keine Schaltfläche.
      await tester.tap(find.text('12'));
      expect(taps, 1);
      h.dispose();
    });

    testWidgets('Fokusreihenfolge: nur „Deine Daten“ ist fokussierbar', (
      WidgetTester tester,
    ) async {
      await pumpHeader(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final Element? ctx =
          FocusManager.instance.primaryFocus?.context as Element?;
      bool inButton = false;
      ctx?.visitAncestorElements((Element e) {
        if (e.widget is HeaderIconButton) inButton = true;
        return !inButton;
      });
      expect(inButton, isTrue);
    });

    testWidgets('Hoher Kontrast: Pillen opak mit border-control-hc, Icon mit '
        'Kreisrand', (WidgetTester tester) async {
      await pumpHeader(tester, hc: true);
      final CuraColors c = colorsAt(tester, find.byType(PathHeader));
      final BoxDecoration d = decorationsUnder(
        tester,
        find.byType(StatPill).first,
      ).first;
      expect(d.color, c.surfaceOpaque);
      expect((d.border! as Border).top.color, c.controlBorder);
      expect(backdropCount(tester), 0);
    });
  });

  group('NodeHint (Ergänzung 1 3.5, UI-62)', () {
    Widget hint(
      HintArrow arrow, {
      String text = S.hintDone,
      double? maxBodyHeight,
    }) => Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 240,
        child: NodeHint(
          text: text,
          arrow: arrow,
          arrowCenter: 40,
          maxBodyHeight: maxBodyHeight,
        ),
      ),
    );

    testWidgets(
      'opak surface-opaque, Rand border-hair, Radius 16, Innenabstand '
      '12/16, kein Blur, secondary text-1',
      (WidgetTester tester) async {
        await pumpApp(tester, hint(HintArrow.down));
        final CuraColors c = colorsAt(tester, find.byType(NodeHint));
        final BoxDecoration d = decorationsUnder(
          tester,
          find.byType(NodeHint),
        ).firstWhere((BoxDecoration x) => x.borderRadius != null);
        expect(d.color, c.surfaceOpaque);
        expect((d.border! as Border).top.color, c.cardBorder);
        expect(d.borderRadius, BorderRadius.circular(16));
        expect(backdropCount(tester), 0);
        final Text t = tester.widget(find.text(S.hintDone));
        expect(t.style!.fontSize, 14);
        expect(t.style!.color, c.text1);
        final Rect body = tester.getRect(find.byType(NodeHint));
        final Rect text = tester.getRect(find.text(S.hintDone));
        expect(text.left - body.left, 16);
        expect(text.top - body.top, 12);
      },
    );

    testWidgets('Pfeil 8 dp an der gewählten Kante, alle vier Richtungen', (
      WidgetTester tester,
    ) async {
      for (final HintArrow a in HintArrow.values) {
        await pumpApp(tester, hint(a, text: 'Erledigt.'));
        expect(tester.takeException(), isNull, reason: '$a');
        final Size s = tester.getSize(find.byType(NodeHint));
        final bool vertical = a == HintArrow.down || a == HintArrow.up;
        // Körper 12 + 20 + 12 = 44 hoch; der Pfeil macht 8 dp dazu.
        if (vertical) {
          expect(s.height, 44 + 8, reason: '$a');
        } else {
          expect(s.width, closeTo(240, 0.5), reason: '$a');
          expect(s.height, greaterThanOrEqualTo(44), reason: '$a');
        }
      }
    });

    testWidgets('Live-Region mit dem Text als Label, ohne Aktion', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(tester, hint(HintArrow.up));
      final SemanticsData d = tester
          .getSemantics(find.byType(NodeHint))
          .getSemanticsData();
      expect(d.label, S.hintDone);
      expect(d.flagsCollection.isLiveRegion, isTrue);
      expect(d.hasAction(SemanticsAction.tap), isFalse);
      h.dispose();
    });

    testWidgets('Breite wächst nicht über die Vorgabe; lange Texte brechen um '
        '(Höhe wächst)', (WidgetTester tester) async {
      await pumpApp(
        tester,
        hint(
          HintArrow.down,
          text: 'Dieser Hinweistext ist absichtlich sehr lang und bricht um, weil er nicht in eine Zeile passt.',
        ),
      );
      final Size s = tester.getSize(find.byType(NodeHint));
      expect(s.width, lessThanOrEqualTo(240));
      expect(s.height, greaterThan(44 + 8 + 20));
    });

    testWidgets('begrenzt: der Text scrollt innen, die Höhe hält', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        hint(
          HintArrow.down,
          text: List<String>.filled(12, 'Wort').join(' '),
          maxBodyHeight: 60,
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.getSize(find.byType(NodeHint)).height, 60 + 8);
    });

    Opacity opacity(WidgetTester tester) => tester.widget<Opacity>(
      find
          .descendant(of: find.byType(NodeHint), matching: find.byType(Opacity))
          .first,
    );

    testWidgets('erscheint mit Einblenden in dur-fast (UI-64)', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, hint(HintArrow.down));
      await tester.pump();
      expect(opacity(tester).opacity, lessThan(1));
      await tester.pump(const Duration(milliseconds: 121));
      expect(opacity(tester).opacity, 1);
    });

    testWidgets('bei reduzierter Bewegung sofort, ohne laufende Animation '
        '(UI-8, UI-64)', (WidgetTester tester) async {
      await _pumpReduced(tester, hint(HintArrow.down));
      expect(opacity(tester).opacity, 1, reason: 'schon im ersten Frame');
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 121));
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('MannyBubble: begrenzte Höhe (Plan 4.6, letzte Stufe)', () {
    testWidgets('mit maxBodyHeight scrollt der Text innen, der Körper hält die '
        'Höhe; ohne bleibt es wie bisher', (WidgetTester tester) async {
      final String long = List<String>.filled(30, 'Wort').join(' ');
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.center,
          child: MannyBubble(
            text: long,
            onClose: () {},
            arrow: BubbleArrow.down,
            maxBodyHeight: 100,
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final Size s = tester.getSize(find.byType(MannyBubble));
      expect(s.height, 100 + CuraComponent.bubbleArrow);
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.center,
          child: MannyBubble(text: long, onClose: () {}),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });
}
