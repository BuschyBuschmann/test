// OrbNode (Design-Brief v2, 4 und 3.5): Größen, Zustände mit Symbol und Label,
// Glas-Objekt ohne Blur, Kontraste der Symbole, Hit-Area, Puls, Tastatur.
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/ui/components/orb_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/world_app.dart';

Widget _orb(
  OrbKind kind,
  OrbState state, {
  VoidCallback? onPressed,
  String label = 'Tag 12, erledigt',
  bool pulse = false,
  VoidCallback? onPulseDone,
}) => Center(
  child: OrbNode(
    kind: kind,
    state: state,
    semanticLabel: label,
    onPressed: onPressed ?? () {},
    pulse: pulse,
    onPulseDone: onPulseDone,
  ),
);

void main() {
  group('Größen (Brief 4)', () {
    testWidgets('Trainingstag 56, Wochenziel 62, Phasen-Abschluss 80, aktuell '
        '92, Boss 104', (WidgetTester tester) async {
      final Map<(OrbKind, OrbState), double> expected =
          <(OrbKind, OrbState), double>{
            (OrbKind.day, OrbState.done): 56,
            (OrbKind.day, OrbState.locked): 56,
            (OrbKind.weekGoal, OrbState.locked): 62,
            (OrbKind.weekGoal, OrbState.done): 62,
            (OrbKind.phaseEnd, OrbState.locked): 80,
            (OrbKind.phaseEnd, OrbState.done): 80,
            (OrbKind.day, OrbState.current): 92,
            (OrbKind.weekGoal, OrbState.current): 92,
            (OrbKind.boss, OrbState.locked): 104,
            (OrbKind.boss, OrbState.current): 104,
            (OrbKind.boss, OrbState.done): 104,
          };
      for (final MapEntry<(OrbKind, OrbState), double> e in expected.entries) {
        await pumpWorld(tester, _orb(e.key.$1, e.key.$2));
        expect(
          tester.getSize(find.byType(OrbNode)),
          Size.square(e.value),
          reason: '${e.key.$1.name} ${e.key.$2.name}',
        );
        expect(OrbNode.diameterFor(e.key.$1, e.key.$2), e.value);
      }
      expect(
        <double>[
          CuraSize.orbDay,
          CuraSize.orbWeekGoal,
          CuraSize.orbPhaseEnd,
          CuraSize.orbCurrent,
          CuraSize.orbBoss,
        ],
        <double>[56, 62, 80, 92, 104],
      );
    });

    testWidgets('Hit-Area ≥ 48 dp bei allen Kugeln', (
      WidgetTester tester,
    ) async {
      for (final OrbKind k in OrbKind.values) {
        for (final OrbState s in OrbState.values) {
          await pumpWorld(tester, _orb(k, s));
          final Size size = tester.getSize(find.byType(OrbNode));
          expect(size.width, greaterThanOrEqualTo(CuraSize.touchTarget));
          expect(size.height, greaterThanOrEqualTo(CuraSize.touchTarget));
        }
      }
    });
  });

  group('Zustände: Symbol und Label (nie nur Farbe)', () {
    testWidgets('erledigt: Perlglas, Haken #8A3A0C', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _orb(OrbKind.day, OrbState.done));
      final Icon i = tester.widget(find.byIcon(Icons.check_rounded));
      expect(i.color, const Color(0xFF8A3A0C));
      expect(i.size, 28);
    });

    testWidgets('aktuell: Mandarine-Kugel mit Halo, dunkle Flagge, Ring', (
      WidgetTester tester,
    ) async {
      await pumpWorld(
        tester,
        _orb(OrbKind.day, OrbState.current, label: 'Heute, aktuell'),
      );
      final CuraColors c = colorsAt(tester, find.byType(OrbNode));
      final Icon i = tester.widget(find.byIcon(Icons.flag_rounded));
      expect(i.color, c.onAccent);
      expect(c.orbMandarin.body, const Color(0xFFFF7A2E));
      // Halo: größere Malfläche als die Kugel (Schein und Ring).
      expect(
        find.descendant(
          of: find.byType(OrbNode),
          matching: find.byType(CustomPaint),
        ),
        findsNWidgets(2),
      );
      await pumpWorld(
        tester,
        _orb(OrbKind.day, OrbState.current),
        highContrast: true,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('gesperrt: Grauglas, Schloss ink-2; Phasen-Abschluss: Stern', (
      WidgetTester tester,
    ) async {
      await pumpWorld(
        tester,
        _orb(OrbKind.day, OrbState.locked, label: 'gesperrt'),
      );
      final CuraColors c = colorsAt(tester, find.byType(OrbNode));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.lock_rounded)).color,
        c.text2,
      );
      await pumpWorld(tester, _orb(OrbKind.phaseEnd, OrbState.locked));
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });

    testWidgets('Ziel/Boss: Gold, Stern #B8470F; erledigt mit Haken', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _orb(OrbKind.boss, OrbState.locked));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.star_rounded)).color,
        const Color(0xFFB8470F),
      );
      final CuraColors c = colorsAt(tester, find.byType(OrbNode));
      expect(c.orbGold.body, const Color(0xFFFFC23D));
      await pumpWorld(tester, _orb(OrbKind.boss, OrbState.current));
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      await pumpWorld(tester, _orb(OrbKind.boss, OrbState.done));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('Symbole erreichen 3:1 gegen Körper und Rand der Kugel', (
      WidgetTester tester,
    ) async {
      for (final Brightness b in Brightness.values) {
        final CuraColors c = CuraColors.variant(b);
        final Map<String, (Color, OrbShades)> pairs =
            <String, (Color, OrbShades)>{
              'erledigt': (c.orbCheck, c.orbPearl),
              'aktuell': (c.onAccent, c.orbMandarin),
              'gesperrt': (c.text2, c.orbGlass),
              'Boss': (c.orbStar, c.orbGold),
            };
        for (final MapEntry<String, (Color, OrbShades)> e in pairs.entries) {
          expect(
            contrastRatio(e.value.$1, e.value.$2.body),
            greaterThanOrEqualTo(3),
            reason: '${e.key} auf Körper (${b.name})',
          );
          expect(
            contrastRatio(e.value.$1, e.value.$2.edge),
            greaterThanOrEqualTo(3),
            reason: '${e.key} auf Rand (${b.name})',
          );
        }
      }
    });

    testWidgets('Screenreader: „Tag 12, erledigt“, Schaltfläche, Tipp ruft '
        'onPressed', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int taps = 0;
      await pumpWorld(
        tester,
        _orb(OrbKind.day, OrbState.done, onPressed: () => taps++),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Tag 12, erledigt')),
        matchesSemantics(
          label: 'Tag 12, erledigt',
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.byType(OrbNode));
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });
  });

  group('Glas-Objekt ohne Blur', () {
    testWidgets('kein BackdropFilter in keinem Zustand (V2-10)', (
      WidgetTester tester,
    ) async {
      for (final OrbKind k in OrbKind.values) {
        for (final OrbState s in OrbState.values) {
          await pumpWorld(tester, _orb(k, s));
          expect(backdropCount(tester), 0, reason: '${k.name} ${s.name}');
        }
      }
    });

    testWidgets(
      'Glasgeometrie als Tokens: Glanz oben links, Innenschatten unten',
      (WidgetTester tester) async {
        expect(OrbGeometry.highX, lessThan(0));
        expect(OrbGeometry.highY, lessThan(0));
        expect(OrbGeometry.glossLeft + OrbGeometry.glossWidth, lessThan(0.7));
        expect(OrbGeometry.innerShadowFrom, greaterThan(0.4));
        expect(OrbGeometry.groundWidth, lessThan(1));
      },
    );
  });

  group('Puls und Bewegung', () {
    testWidgets('einmaliger Ring-Puls in dur-slow, danach onPulseDone', (
      WidgetTester tester,
    ) async {
      int done = 0;
      await pumpWorld(
        tester,
        _orb(
          OrbKind.day,
          OrbState.current,
          pulse: true,
          onPulseDone: () => done++,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 400));
      expect(done, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('Bewegung reduzieren: kein Puls, Rückruf sofort', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      int done = 0;
      await pumpWorld(
        tester,
        _orb(
          OrbKind.day,
          OrbState.current,
          pulse: true,
          onPulseDone: () => done++,
        ),
      );
      await tester.pump();
      expect(done, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('Tastatur: Tab fokussiert, Enter und Leertaste lösen aus', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpWorld(
      tester,
      _orb(OrbKind.day, OrbState.done, onPressed: () => taps++),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('alle Welten × Themen × Hoher Kontrast bauen ohne Fehler', (
    WidgetTester tester,
  ) async {
    for (final WorldLook l in allWorldLooks()) {
      await pumpWorld(
        tester,
        Wrap(
          children: <Widget>[
            for (final OrbKind k in OrbKind.values)
              for (final OrbState s in OrbState.values)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: OrbNode(
                    kind: k,
                    state: s,
                    semanticLabel: '${k.name} ${s.name}',
                    onPressed: () {},
                  ),
                ),
          ],
        ),
        phase: l.phase,
        brightness: l.brightness,
        highContrast: l.highContrast,
      );
      expect(tester.takeException(), isNull, reason: l.name);
    }
  });
}
