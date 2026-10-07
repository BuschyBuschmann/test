// Selbsttest der Matrix-Prüffunktionen (schnell, ohne Tag): jede Prüfung muss
// einen absichtlichen Verstoß erkennen und die korrekte Form durchlassen.
// Sonst wäre eine grüne Matrix wertlos.
import 'package:curaone/dev/scenarios.dart';
import 'package:curaone/dev/text_probe.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/glow_background.dart';

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:flutter_test/flutter_test.dart'
    as flutter_test
    show testWidgets;

import '../support/pump_app.dart';
import 'matrix_checks.dart';
import 'matrix_harness.dart';

Widget _tap(double w, double h, {Key? key}) => Semantics(
  key: key,
  button: true,
  label: 'Ziel',
  onTap: () {},
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {},
    child: SizedBox(width: w, height: h),
  ),
);

Scenario _scenario({bool primary = false}) => Scenario(
  id: 'synthetisch',
  builder: (BuildContext c, ScenarioEnv e) => const SizedBox(),
  expectsPrimary: primary,
);

ProbedText _text(
  String text, {
  required TextGround ground,
  required double glow,
  required Color color,
  double size = 16,
  int weight = 400,
  bool icon = false,
}) => ProbedText(
  text: text,
  rect: const Rect.fromLTWH(0, 0, 10, 10),
  color: color,
  sizeSp: size,
  weight: weight,
  ground: ground,
  glowAlpha: glow,
  onScreen: true,
  isIcon: icon,
);

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {Size? size}) async {
    await pumpApp(tester, child, size: size ?? Viewports.phone);
    await tester.pumpAndSettle();
  }

  // Jeder Test mit Semantik-Baum; ein Handle je Test, am Ende freigegeben.
  void testWidgets(String name, Future<void> Function(WidgetTester) body) {
    flutter_test.testWidgets(name, (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await body(tester);
      } finally {
        handle.dispose();
      }
    });
  }

  group('M-Layout', () {
    testWidgets('Layout-Exception wird erkannt', (WidgetTester tester) async {
      await pump(
        tester,
        Row(
          children: <Widget>[
            SizedBox(width: 500, height: 10),
            SizedBox(width: 500, height: 10),
          ],
        ),
      );
      expect(takeLayoutExceptions(tester), isNotEmpty);
      expect(takeLayoutExceptions(tester), isEmpty);
    });

    testWidgets('Tap-Ziel unter 48 dp', (WidgetTester tester) async {
      await pump(tester, Center(child: _tap(24, 24)));
      expect(await checkTapTargetSize(tester), isNotEmpty);
      await pump(tester, Center(child: _tap(48, 48)));
      expect(await checkTapTargetSize(tester), isEmpty);
    });

    testWidgets('Abstand zwischen Tap-Zielen', (WidgetTester tester) async {
      await pump(
        tester,
        Column(
          children: <Widget>[
            _tap(48, 48),
            const SizedBox(height: 4),
            _tap(48, 48),
          ],
        ),
      );
      expect(checkTapTargetGaps(tester), isNotEmpty);
      await pump(
        tester,
        Column(
          children: <Widget>[
            _tap(48, 48),
            const SizedBox(height: 8),
            _tap(48, 48),
          ],
        ),
      );
      expect(checkTapTargetGaps(tester), isEmpty);
    });

    testWidgets('verschachtelte Tap-Ziele zählen nicht', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        Center(
          child: Semantics(
            onTap: () {},
            child: SizedBox(
              width: 120,
              height: 120,
              child: Center(child: _tap(48, 48)),
            ),
          ),
        ),
      );
      expect(checkTapTargetGaps(tester), isEmpty);
    });

    testWidgets('Schriftgröße und Gewicht', (WidgetTester tester) async {
      await pump(
        tester,
        const Column(
          children: <Widget>[
            Text('klein', style: TextStyle(fontSize: 12)),
            Text(
              'dünn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
            ),
            Text(
              'passt',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      );
      final List<Finding> f = checkTextStyles(probe(tester));
      expect(f.length, 2);
      expect(
        f.map((Finding x) => x.message).join(),
        allOf(contains('klein'), contains('dünn')),
      );
    });

    testWidgets('Primärbutton: fehlt, außerhalb, verdeckt', (
      WidgetTester tester,
    ) async {
      await pump(tester, const SizedBox());
      expect(checkPrimary(tester, _scenario(primary: true)), isNotEmpty);
      expect(checkPrimary(tester, _scenario()), isEmpty);

      await pump(
        tester,
        Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              top: 830,
              child: _tap(100, 56, key: PreviewKeys.primary),
            ),
          ],
        ),
      );
      expect(checkPrimary(tester, _scenario(primary: true)), isNotEmpty);

      await pump(
        tester,
        Stack(
          children: <Widget>[
            Positioned(
              left: 20,
              top: 100,
              child: _tap(100, 56, key: PreviewKeys.primary),
            ),
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
          ],
        ),
      );
      expect(checkPrimary(tester, _scenario(primary: true)), isNotEmpty);

      await pump(
        tester,
        Stack(
          children: <Widget>[
            Positioned(
              left: 20,
              top: 100,
              child: _tap(100, 56, key: PreviewKeys.primary),
            ),
          ],
        ),
      );
      expect(checkPrimary(tester, _scenario(primary: true)), isEmpty);
    });

    testWidgets('Zonen: links frei, rechts nur Gruppe, Gruppe sichtbar', (
      WidgetTester tester,
    ) async {
      Widget board({Widget? extra}) => Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: KeyedSubtree(
              key: PreviewKeys.nav,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 106,
            child: KeyedSubtree(
              key: PreviewKeys.cluster,
              child: const SizedBox(width: 56, height: 112),
            ),
          ),
          ?extra,
        ],
      );
      await pump(tester, board());
      expect(checkZones(tester), isEmpty);

      await pump(
        tester,
        board(
          extra: Positioned(
            left: 16,
            bottom: 110,
            child: KeyedSubtree(
              key: PreviewKeys.bubble,
              child: const SizedBox(width: 100, height: 60),
            ),
          ),
        ),
      );
      expect(
        checkZones(tester).map((Finding f) => f.check),
        contains('Zone unten links frei'),
      );

      await pump(
        tester,
        board(
          extra: Positioned(
            right: 80,
            bottom: 200,
            child: KeyedSubtree(
              key: PreviewKeys.snackbar,
              child: const SizedBox(width: 120, height: 40),
            ),
          ),
        ),
      );
      expect(
        checkZones(tester).map((Finding f) => f.check),
        contains('Zone unten rechts nur Gruppe'),
      );

      await pump(
        tester,
        Stack(
          children: <Widget>[
            Positioned(
              right: 16,
              bottom: -20,
              child: KeyedSubtree(
                key: PreviewKeys.cluster,
                child: const SizedBox(width: 56, height: 112),
              ),
            ),
          ],
        ),
      );
      expect(
        checkZones(tester).map((Finding f) => f.check),
        contains('Button-Gruppe sichtbar'),
      );
    });

    testWidgets('Blase überdeckt die Gruppe', (WidgetTester tester) async {
      await pump(
        tester,
        Stack(
          children: <Widget>[
            Positioned(
              right: 16,
              top: 400,
              child: KeyedSubtree(
                key: PreviewKeys.cluster,
                child: const SizedBox(width: 56, height: 112),
              ),
            ),
            Positioned(
              right: 40,
              top: 450,
              child: KeyedSubtree(
                key: PreviewKeys.bubble,
                child: const SizedBox(width: 100, height: 60),
              ),
            ),
          ],
        ),
      );
      expect(
        checkZones(tester).map((Finding f) => f.check),
        contains('Blase/Hinweis überdeckt Gruppe nicht'),
      );
    });

    testWidgets('Sichtfläche ist ein Richtwert', (WidgetTester tester) async {
      await pump(
        tester,
        Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 100,
              child: KeyedSubtree(
                key: PreviewKeys.header,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 180,
              height: 90,
              child: KeyedSubtree(
                key: PreviewKeys.nav,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      );
      final List<Finding> f = checkVisibleArea(tester);
      expect(f, hasLength(1));
      expect(f.single.advisory, isTrue);
    });

    Widget scrollBoard(double bottomPad) => Stack(
      children: <Widget>[
        SingleChildScrollView(
          key: PreviewKeys.scroll,
          padding: EdgeInsets.only(bottom: bottomPad),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < 14; i++) ...<Widget>[
                _tap(300, 48),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 100,
          child: KeyedSubtree(
            key: PreviewKeys.nav,
            child: const ColoredBox(color: Colors.black),
          ),
        ),
      ],
    );

    testWidgets('Erreichbarkeit nach Scrollen: Reserve fehlt / vorhanden', (
      WidgetTester tester,
    ) async {
      await pump(tester, scrollBoard(0));
      expect(await checkReachability(tester), isNotEmpty);
      await pump(tester, scrollBoard(100));
      expect(await checkReachability(tester), isEmpty);
    });

    testWidgets('BackdropFilter-Grenze', (WidgetTester tester) async {
      Widget blur() => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: const SizedBox(width: 10, height: 10),
      );
      await pump(tester, Column(children: <Widget>[blur(), blur(), blur()]));
      expect(checkBackdrops(tester, 2), isNotEmpty);
      expect(checkBackdrops(tester, 3), isEmpty);
      expect(checkBackdrops(tester, 0), isNotEmpty);
    });

    testWidgets('Chat-Fuß höchstens 40 %', (WidgetTester tester) async {
      Widget footer(double h) => Align(
        alignment: Alignment.bottomCenter,
        child: KeyedSubtree(
          key: PreviewKeys.chatFooter,
          child: SizedBox(width: 390, height: h),
        ),
      );
      await pump(tester, footer(500));
      expect(checkChatFooter(tester), isNotEmpty);
      await pump(tester, footer(300));
      expect(checkChatFooter(tester), isEmpty);
    });
  });

  group('Glow-Regel', () {
    final CuraColors c = CuraColors.dark;
    const Size v = Size(390, 844);

    test('Grenzen nach Untergrund und Farbe (Errata E-1)', () {
      TextProbe p(ProbedText t) =>
          TextProbe(texts: <ProbedText>[t], hasGlow: true, view: v);
      // text-1 auf Glas: 16 % erlaubt, 17 % nicht
      expect(
        checkGlowRule(
          p(_text('a', ground: TextGround.glass, glow: 0.16, color: c.text1)),
          c,
          v,
        ),
        isEmpty,
      );
      expect(
        checkGlowRule(
          p(_text('a', ground: TextGround.glass, glow: 0.17, color: c.text1)),
          c,
          v,
        ),
        isNotEmpty,
      );
      // farbiger Text auf Glas: 12 %
      expect(
        checkGlowRule(
          p(
            _text(
              'a',
              ground: TextGround.glass,
              glow: 0.13,
              color: c.catPhysio,
            ),
          ),
          c,
          v,
        ),
        isNotEmpty,
      );
      // bg: 24 %
      expect(
        checkGlowRule(
          p(_text('a', ground: TextGround.bg, glow: 0.24, color: c.text1)),
          c,
          v,
        ),
        isEmpty,
      );
      expect(
        checkGlowRule(
          p(_text('a', ground: TextGround.bg, glow: 0.25, color: c.text1)),
          c,
          v,
        ),
        isNotEmpty,
      );
      // deckende Flächen: glowfrei, nie ein Befund
      expect(
        checkGlowRule(
          p(_text('a', ground: TextGround.opaque, glow: 0.9, color: c.text1)),
          c,
          v,
        ),
        isEmpty,
      );
      // halbtransparente Schrift (Disabled) ausgenommen
      expect(
        checkGlowRule(
          p(
            _text(
              'a',
              ground: TextGround.glass,
              glow: 0.2,
              color: c.text1.withValues(alpha: 0.38),
            ),
          ),
          c,
          v,
        ),
        isEmpty,
      );
    });

    test('Zusatzbedingung Kontrast ≥ 4,5 bei diesem Alpha', () {
      TextProbe p(ProbedText t) =>
          TextProbe(texts: <ProbedText>[t], hasGlow: true, view: v);
      // accent-hi auf Glas bei 12 % erreicht nur ca. 4,34 (Errata): Befund trotz Grenze 12 %
      final List<Finding> f = checkGlowRule(
        p(_text('a', ground: TextGround.glass, glow: 0.12, color: c.accentHi)),
        c,
        v,
      );
      expect(f.map((Finding x) => x.check), contains('Kontrast bei Glow'));
    });

    testWidgets('Sonde: Untergrund und Glow am nächsten Rechteckpunkt', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const Stack(
          children: <Widget>[
            Positioned.fill(child: GlowBackground()),
            Positioned(
              left: 16,
              top: 60,
              child: GlassCard(child: Text('Glas')),
            ),
            Positioned(left: 16, top: 300, child: Text('Boden')),
            Positioned(
              left: 16,
              top: 500,
              child: CuraDialog(
                title: 'T',
                message: 'Deckend',
                actions: <Widget>[],
              ),
            ),
          ],
        ),
      );
      final TextProbe p = probe(tester);
      final ProbedText glass = p.texts.firstWhere(
        (ProbedText t) => t.text == 'Glas',
      );
      final ProbedText bg = p.texts.firstWhere(
        (ProbedText t) => t.text == 'Boden',
      );
      final ProbedText opaque = p.texts.firstWhere(
        (ProbedText t) => t.text == 'Deckend',
      );
      expect(p.hasGlow, isTrue);
      expect(glass.ground, TextGround.glass);
      expect(glass.glowAlpha, greaterThan(0.1));
      expect(bg.ground, TextGround.bg);
      expect(bg.glowAlpha, lessThan(glass.glowAlpha));
      expect(opaque.ground, TextGround.opaque);
      expect(opaque.glowAlpha, 0);
    });
  });

  group('M-Modus', () {
    testWidgets('Hoher Kontrast: Blur, Glow, Fläche, Schatten', (
      WidgetTester tester,
    ) async {
      await pump(tester, const GlassCard(child: Text('x')));
      // Normaler Modus ist kein gültiger HC-Zustand: Fläche nicht aus surface-opaque.
      expect(
        checkHighContrast(tester).map((Finding f) => f.check),
        contains('HC Fläche opak'),
      );

      await pump(
        tester,
        Stack(
          children: <Widget>[
            const Positioned.fill(child: GlowBackground()),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: const SizedBox(width: 5, height: 5),
            ),
            DecoratedBox(
              decoration: BoxDecoration(boxShadow: CuraShadow.primaryGlow),
              child: const SizedBox(width: 10, height: 10),
            ),
            DecoratedBox(
              decoration: BoxDecoration(boxShadow: CuraShadow.actionButton),
              child: const SizedBox(width: 10, height: 10),
            ),
          ],
        ),
      );
      final Set<String> checks = checkHighContrast(tester)
          .map((Finding f) => f.check)
          .toSet();
      expect(
        checks,
        containsAll(<String>['HC kein Blur', 'HC keine Schatten/Scheine']),
      );
    });

    testWidgets('Bewegung reduzieren: laufende Animation', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, const _Spinner());
      await tester.pump(const Duration(milliseconds: 121));
      expect(
        checkReducedMotion(
          tester,
          allowProgress: false,
        ).map((Finding f) => f.check),
        contains('RM ohne laufende Animation'),
      );
    });

    testWidgets('Fortschrittsanzeige ist erlaubt', (WidgetTester tester) async {
      await pumpApp(tester, const CircularProgressIndicator());
      await tester.pump(const Duration(milliseconds: 121));
      final List<Finding> f = checkReducedMotion(tester, allowProgress: true);
      // CuraMotion.reduced ist hier nicht gesetzt (kein RM-Override): nur dieser Befund
      expect(
        f.map((Finding x) => x.check),
        isNot(contains('RM ohne laufende Animation')),
      );
      expect(
        checkReducedMotion(
          tester,
          allowProgress: false,
        ).map((Finding x) => x.check),
        contains('RM ohne laufende Animation'),
      );
    });
  });

  group('M-Kontrast', () {
    testWidgets('Leitlinie erkennt zu geringen Kontrast', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const ColoredBox(
          color: Color(0xFF777777),
          child: Center(
            child: Text(
              'Blass',
              style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 16),
            ),
          ),
        ),
      );
      expect(await checkTextContrast(tester), isNotEmpty);
    });

    testWidgets(
      'Nav: bekannte Eigenheit der Leitlinie ist ausgenommen, der Rest nicht',
      (WidgetTester tester) async {
        final Scenario nav = scenarioById('cmp-nav-cluster')!;
        await pumpScenario(tester, nav);
        // Die rohe Leitlinie meldet im aktiven Nav-Eintrag ca. 2,27:1 (Icon-Pixel als Text) ...
        final Evaluation raw = await textContrastGuideline.evaluate(tester);
        expect(
          raw.passed,
          isFalse,
          reason: 'Bekannte Eigenheit nicht mehr vorhanden: Ausnahme entfernen',
        );
        expect(raw.reason, contains('2.2'));
        // ... die Matrix-Prüfung lässt sie nur dort zu.
        expect(await checkTextContrast(tester), isEmpty);
      },
    );
  });
}

class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _c, child: const SizedBox(width: 10, height: 10));
}
