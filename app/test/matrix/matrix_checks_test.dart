// Selbsttest der Matrix-Prüffunktionen (schnell, ohne Tag): jede Prüfung muss
// einen absichtlichen Verstoß erkennen und die korrekte Form durchlassen.
// Sonst wäre eine grüne Matrix wertlos.
import 'package:curaone/dev/scenarios.dart';
import 'package:curaone/dev/text_probe.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/ui/components/content_frame.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/glow_background.dart';
import 'package:curaone/ui/components/messages_button.dart';
import 'package:curaone/ui/routes/cura_sheet_route.dart';

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
    excludeFromSemantics: true,
    onTap: () {},
    child: SizedBox(width: w, height: h),
  ),
);

Scenario _scenario({
  bool primary = false,
  bool nav = false,
  bool cluster = false,
  bool header = false,
  bool chatFooter = false,
}) => Scenario(
  id: 'synthetisch',
  builder: (BuildContext c, ScenarioEnv e) => const SizedBox(),
  expectsPrimary: primary,
  expectsNav: nav,
  expectsCluster: cluster,
  expectsHeader: header,
  expectsChatFooter: chatFooter,
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
      expect(await checkTapTargetGaps(tester), isNotEmpty);
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
      expect(await checkTapTargetGaps(tester), isEmpty);
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
      expect(await checkTapTargetGaps(tester), isEmpty);
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
      expect(checkZones(tester, _scenario()), isEmpty);

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
        checkZones(tester, _scenario()).map((Finding f) => f.check),
        contains('Zone unten links frei'),
      );

      await pump(
        tester,
        board(
          extra: Positioned(
            right: 80,
            bottom: 200,
            child: KeyedSubtree(
              key: const ValueKey<String>('overlay:snackbar'),
              child: const SizedBox(width: 120, height: 40),
            ),
          ),
        ),
      );
      expect(
        checkZones(tester, _scenario()).map((Finding f) => f.check),
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
        checkZones(tester, _scenario()).map((Finding f) => f.check),
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
        checkZones(tester, _scenario()).map((Finding f) => f.check),
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
      final List<Finding> f = checkVisibleArea(tester, _scenario());
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

    testWidgets('feste Bedienelemente im Kopf gelten als erreichbar', (
      WidgetTester tester,
    ) async {
      Widget board({required bool inHeader}) => Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 100,
            child: KeyedSubtree(
              key: PreviewKeys.header,
              child: inHeader
                  ? Align(alignment: Alignment.topLeft, child: _tap(48, 48))
                  : const SizedBox.expand(),
            ),
          ),
          if (!inHeader) Positioned(left: 0, top: 80, child: _tap(48, 48)),
        ],
      );
      // Im Kopf: erlaubt. Ein festes Ziel, das nur teilweise im Kopf liegt
      // oder darüber, bleibt ein Befund.
      await pump(tester, board(inHeader: true));
      expect(await checkReachability(tester), isEmpty);
      await pump(tester, board(inHeader: false));
      expect(await checkReachability(tester), isNotEmpty);
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
      expect(checkChatFooter(tester, _scenario()), isNotEmpty);
      await pump(tester, footer(300));
      expect(checkChatFooter(tester, _scenario()), isEmpty);
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

    testWidgets(
      'Bewegung reduzieren: aufgeschobener LayoutBuilder-Frame ist keine Animation',
      (WidgetTester tester) async {
        final ValueNotifier<int> tab = ValueNotifier<int>(0);
        addTearDown(tab.dispose);
        await pumpApp(
          tester,
          ValueListenableBuilder<int>(
            valueListenable: tab,
            builder: (BuildContext context, int i, Widget? child) {
              return ContentFrame(
                child: Stack(
                  children: <Widget>[
                    for (int k = 0; k < 2; k++)
                      ExcludeFocus(excluding: k != i, child: const Text('Tab')),
                  ],
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();
        tab.value = 1;
        // Wie in der Matrix: 121 ms und ein weiterer Frame.
        await tester.pump(const Duration(milliseconds: 121));
        await tester.pump(const Duration(milliseconds: 1));
        expect(
          checkReducedMotion(
            tester,
            allowProgress: false,
          ).map((Finding f) => f.check),
          isNot(contains('RM ohne laufende Animation')),
        );
      },
    );

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
  group('Gegenproben aus Review R-U2 (E1 bis E4)', () {
    Widget navOverlay() => Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 100,
      child: KeyedSubtree(
        key: PreviewKeys.nav,
        child: const AbsorbPointer(child: ColoredBox(color: Colors.black)),
      ),
    );

    Widget lazyList(double endPad) => Stack(
      children: <Widget>[
        ListView.builder(
          key: PreviewKeys.scroll,
          padding: EdgeInsets.only(bottom: endPad),
          itemCount: 40,
          itemExtent: 56,
          itemBuilder: (BuildContext c, int i) => Center(child: _tap(300, 48)),
        ),
        navOverlay(),
      ],
    );

    testWidgets(
      'E2/MAJOR-1: lazy ListView.builder ohne Endabstand wird erkannt',
      (WidgetTester tester) async {
        await pump(tester, lazyList(0));
        // Nur ein Teil der 40 Einträge ist gebaut: der Scan muss den ganzen Weg gehen.
        final List<Finding> f = await checkReachability(tester);
        expect(f, isNotEmpty, reason: 'letzte Einträge liegen unter der Nav');
        await pump(tester, lazyList(100));
        expect(await checkReachability(tester), isEmpty);
      },
    );

    testWidgets('MAJOR-1: Abstandsprüfung sieht auch nicht gebaute Einträge', (
      WidgetTester tester,
    ) async {
      Widget list(int tight) => ListView.builder(
        key: PreviewKeys.scroll,
        itemCount: 40,
        itemExtent: 56,
        itemBuilder: (BuildContext c, int i) =>
            Center(child: _tap(300, i == tight ? 54 : 48)),
      );
      await pump(tester, list(30));
      expect(
        await checkTapTargetGaps(tester),
        isNotEmpty,
        reason: 'Eintrag 30: 2 dp',
      );
      await pump(tester, list(-1));
      expect(await checkTapTargetGaps(tester), isEmpty);
    });

    testWidgets(
      'Punkt 5: fester Kopf-Button gegen Listeneintrag in der Ruhelage',
      (WidgetTester tester) async {
        Widget board(double top) => Stack(
          children: <Widget>[
            SingleChildScrollView(
              key: PreviewKeys.scroll,
              padding: EdgeInsets.only(top: top),
              child: Column(children: <Widget>[_tap(300, 48)]),
            ),
            Positioned(left: 0, top: 0, child: _tap(48, 48)),
          ],
        );
        await pump(tester, board(50));
        expect(await checkTapTargetGaps(tester), isNotEmpty);
        await pump(tester, board(56));
        expect(await checkTapTargetGaps(tester), isEmpty);
      },
    );

    Widget navDemo() => Align(
      alignment: Alignment.bottomCenter,
      child: KeyedSubtree(
        key: PreviewKeys.nav,
        child: FloatingNav(
          currentIndex: 0,
          onSelected: (_) {},
          items: const <NavItem>[
            NavItem(icon: Icons.route_rounded, label: 'Pfad'),
            NavItem(icon: Icons.event_available_rounded, label: 'Heute'),
          ],
        ),
      ),
    );

    Widget grey(String t, double top) => Positioned(
      left: 20,
      top: top,
      child: ColoredBox(
        color: const Color(0xFF222222),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            t,
            style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 16),
          ),
        ),
      ),
    );

    testWidgets(
      'E3/MAJOR-2: gleichnamiger Inhaltstext mit 2,6:1 bleibt ein Befund',
      (WidgetTester tester) async {
        await pump(
          tester,
          Stack(
            children: <Widget>[
              grey('Heute', 100),
              grey('Woche', 200),
              navDemo(),
            ],
          ),
        );
        final List<Finding> f = await checkTextContrast(tester);
        final String all = f.map((Finding x) => x.message).join('\n');
        expect(
          all,
          contains('"Heute"'),
          reason: 'Inhaltstext "Heute" darf nicht durch die Nav-Ausnahme verschwinden',
        );
        expect(all, contains('"Woche"'));
      },
    );

    testWidgets(
      'MAJOR-2: echter 2,x-Verstoß in der Nav-Zeile außerhalb der Nav bleibt',
      (WidgetTester tester) async {
        // Gleicher Name wie der aktive Eintrag („Pfad“), aber außerhalb der Nav.
        await pump(
          tester,
          Stack(children: <Widget>[grey('Pfad', 100), navDemo()]),
        );
        final List<Finding> f = await checkTextContrast(tester);
        expect(f.map((Finding x) => x.message).join(), contains('"Pfad"'));
      },
    );

    testWidgets(
      'E4/MAJOR-3: Marker fehlt bei gesetztem Flag, Bubble in Zone ohne Gruppe',
      (WidgetTester tester) async {
        await pump(
          tester,
          Stack(
            children: <Widget>[
              navOverlay(),
              Positioned(
                left: 16,
                bottom: 110,
                child: KeyedSubtree(
                  key: PreviewKeys.bubble,
                  child: const SizedBox(width: 100, height: 40),
                ),
              ),
            ],
          ),
        );
        final Set<String> withFlag = checkZones(
          tester,
          _scenario(nav: true, cluster: true),
        ).map((Finding f) => f.check).toSet();
        expect(withFlag, contains('Marker fehlt'));
        // Nav-Marker fehlt bei gesetztem Flag.
        await pump(tester, const SizedBox());
        expect(
          checkZones(tester, _scenario(nav: true)).map((Finding f) => f.check),
          contains('Marker fehlt'),
        );
        expect(
          checkVisibleArea(
            tester,
            _scenario(header: true),
          ).map((Finding f) => f.check),
          contains('Marker fehlt'),
        );
        expect(
          checkChatFooter(
            tester,
            _scenario(chatFooter: true),
          ).map((Finding f) => f.check),
          contains('Marker fehlt'),
        );
        expect(checkZones(tester, _scenario()), isEmpty);
      },
    );

    testWidgets('Snackbar-Leiste zählt als Overlay, nicht der Vollbild-Host', (
      WidgetTester tester,
    ) async {
      final Scenario snack = scenarioById('cmp-snackbar')!;
      await pumpScenario(tester, snack);
      final Rect? r = overlayRects()['snackbar'];
      expect(r, isNotNull);
      expect(r!.height, lessThan(120));
      expect(r.width, lessThan(viewSize(tester).width));
    });
  });

  group('Text-Sonde: Untergrund und Verdeckung (R-U2 Punkt 12)', () {
    testWidgets(
      'Sheet (CuraSheetFrame) gilt als Glas, auch ohne Typnamen (Release-fest)',
      (WidgetTester tester) async {
        await pump(
          tester,
          const Stack(
            children: <Widget>[
              Positioned.fill(child: GlowBackground()),
              Align(
                alignment: Alignment.bottomCenter,
                child: CuraSheetFrame(
                  header: Text('Kopf'),
                  body: Text('Inhalt'),
                ),
              ),
            ],
          ),
        );
        final TextProbe p = probe(tester);
        final Iterable<ProbedText> texts = p.texts.where(
          (ProbedText t) => t.text == 'Kopf' || t.text == 'Inhalt',
        );
        expect(texts, hasLength(2));
        for (final ProbedText t in texts) {
          expect(t.ground, TextGround.glass);
        }
      },
    );

    testWidgets(
      'Text außerhalb des Scroll-Sichtfensters ist nicht sichtbar, angeschnittener nur mit dem sichtbaren Teil',
      (WidgetTester tester) async {
        await pump(
          tester,
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 80, child: Text('Oben')),
                  const SizedBox(height: 40, child: Text('Angeschnitten')),
                  const SizedBox(height: 300),
                  const Text('Weit unten'),
                ],
              ),
            ),
          ),
        );
        final TextProbe p = probe(tester);
        ProbedText byText(String t) =>
            p.texts.firstWhere((ProbedText x) => x.text == t);
        expect(byText('Oben').onScreen, isTrue);
        final ProbedText cut = byText('Angeschnitten');
        expect(cut.onScreen, isTrue);
        expect(cut.rect.bottom, lessThanOrEqualTo(100.5));
        expect(byText('Weit unten').onScreen, isFalse);
      },
    );

    testWidgets('ActionCircle ist eine deckende Fläche', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        Stack(
          children: <Widget>[
            const Positioned.fill(child: GlowBackground()),
            Positioned(
              left: 8,
              top: 8,
              child: MessagesButton(onPressed: () {}),
            ),
          ],
        ),
      );
      final TextProbe p = probe(tester);
      final Iterable<ProbedText> icons = p.texts.where(
        (ProbedText t) => t.isIcon,
      );
      expect(icons, isNotEmpty);
      for (final ProbedText t in icons) {
        expect(t.ground, TextGround.opaque);
        expect(t.glowAlpha, 0);
      }
    });

    testWidgets(
      'Text unter einer anderen Route (Scrim) zählt nicht als sichtbar',
      (WidgetTester tester) async {
        await pump(
          tester,
          Builder(
            builder: (BuildContext context) => Column(
              children: <Widget>[
                const Text('Unten'),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const Dialog(child: Text('Oben')),
                  ),
                  child: const Text('Öffnen'),
                ),
              ],
            ),
          ),
        );
        expect(
          probe(tester).texts
              .firstWhere((ProbedText t) => t.text == 'Unten')
              .onScreen,
          isTrue,
        );
        await tester.tap(find.text('Öffnen'));
        await tester.pumpAndSettle();
        final TextProbe p = probe(tester);
        expect(
          p.texts.firstWhere((ProbedText t) => t.text == 'Oben').onScreen,
          isTrue,
        );
        expect(
          p.texts.firstWhere((ProbedText t) => t.text == 'Unten').onScreen,
          isFalse,
          reason: 'unter dem Scrim',
        );
      },
    );
  });
  group('Gegenproben aus Re-Review R-U2-RR (N1 bis N3)', () {
    Widget navOverlay() => Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 100,
      child: KeyedSubtree(
        key: PreviewKeys.nav,
        child: const AbsorbPointer(child: ColoredBox(color: Colors.black)),
      ),
    );

    testWidgets(
      'N1/E2b: zweiter, nicht markierter Scrollbereich wird geprüft',
      (WidgetTester tester) async {
        Widget board(double endPad) => Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                SizedBox(
                  height: 300,
                  child: SingleChildScrollView(
                    key: PreviewKeys.scroll,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < 3; i++) ...<Widget>[
                          _tap(300, 48),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: endPad),
                    itemCount: 40,
                    itemBuilder: (BuildContext c, int i) => Padding(
                      padding: EdgeInsets.only(bottom: endPad > 0 ? 8 : 2),
                      child: Center(child: _tap(300, 48)),
                    ),
                  ),
                ),
              ],
            ),
            navOverlay(),
          ],
        );
        await pump(tester, board(0));
        expect(
          await checkReachability(tester),
          isNotEmpty,
          reason: 'Ende unter der Nav',
        );
        expect(
          await checkTapTargetGaps(tester),
          isNotEmpty,
          reason: '2 dp Abstand',
        );
        await pump(tester, board(100));
        expect(await checkReachability(tester), isEmpty);
        expect(await checkTapTargetGaps(tester), isEmpty);
      },
    );

    testWidgets('N2/E2c: Ziel höher als der Scrollbereich wird gemeldet', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        ListView(
          key: PreviewKeys.scroll,
          children: <Widget>[
            _tap(300, 1000),
            const SizedBox(height: 8),
            _tap(300, 48),
          ],
        ),
      );
      final List<Finding> reach = await checkReachability(tester);
      expect(
        reach.map((Finding f) => f.check),
        contains('Ziel nicht vollständig sichtbar'),
      );
      // Gegenprobe: ein Ziel, das ganz hineinpasst, ist kein Befund.
      await pump(
        tester,
        ListView(
          key: PreviewKeys.scroll,
          children: <Widget>[
            _tap(300, 700),
            const SizedBox(height: 8),
            _tap(300, 48),
          ],
        ),
      );
      expect(await checkReachability(tester), isEmpty);
    });

    Widget stdList(int tight) => ListView.builder(
      key: PreviewKeys.scroll,
      itemCount: 40,
      itemBuilder: (BuildContext c, int i) => Padding(
        padding: EdgeInsets.only(bottom: i == tight ? 2 : 8),
        child: Center(child: _tap(300, 48)),
      ),
    );

    testWidgets(
      'N3/E2a: Standard-Semantik-Indizes: kein Fehlalarm, echter 2-dp-Verstoß erkannt',
      (WidgetTester tester) async {
        await pump(tester, stdList(-1));
        expect(
          await checkTapTargetGaps(tester),
          isEmpty,
          reason: 'Zellen berühren sich, Ziele 8 dp',
        );
        expect(await checkReachability(tester), isEmpty);
        await pump(tester, stdList(30));
        final List<Finding> f = await checkTapTargetGaps(tester);
        expect(f, isNotEmpty);
        expect(f.first.message, contains('2.0 dp'));
      },
    );
  });

  group('Gegenproben aus Review R-U3 (MAJOR-2, MINOR-1, MINOR-2)', () {
    Widget overlayBox(Key key, double w, double h) => KeyedSubtree(
      key: key,
      child: SizedBox(width: w, height: h),
    );

    testWidgets('MAJOR-2: Kopf-Ziel vollständig unter einem Overlay ist ein '
        'Befund', (WidgetTester tester) async {
      Widget board({required bool covered}) => Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 100,
            child: KeyedSubtree(
              key: PreviewKeys.header,
              child: Align(alignment: Alignment.topLeft, child: _tap(48, 48)),
            ),
          ),
          Positioned(
            left: covered ? 0 : 100,
            top: covered ? 0 : 200,
            child: overlayBox(PreviewKeys.bubble, 200, 60),
          ),
        ],
      );
      await pump(tester, board(covered: true));
      expect(await checkReachability(tester), isNotEmpty);
      await pump(tester, board(covered: false));
      expect(await checkReachability(tester), isEmpty);
    });

    testWidgets('MAJOR-2: festes Inhaltsziel unter einem Overlay ist ein '
        'Befund, teilweise wie vollständig', (WidgetTester tester) async {
      for (final double w in <double>[30, 200]) {
        await pump(
          tester,
          Stack(
            children: <Widget>[
              Positioned(left: 0, top: 300, child: _tap(48, 48)),
              Positioned(
                left: 0,
                top: 300,
                child: overlayBox(PreviewKeys.bubble, w, 48),
              ),
            ],
          ),
        );
        expect(
          await checkReachability(tester),
          isNotEmpty,
          reason: 'Overlay $w dp breit',
        );
      }
    });

    testWidgets('MAJOR-2: Ziel im Overlay-Teilbaum zählt zum Overlay, kein '
        'Befund', (WidgetTester tester) async {
      await pump(
        tester,
        Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              top: 300,
              child: KeyedSubtree(key: PreviewKeys.bubble, child: _tap(48, 48)),
            ),
          ],
        ),
      );
      final List<TapTarget> t = tapTargets(tester);
      expect(t.single.inOverlay, isTrue);
      expect(await checkReachability(tester), isEmpty);
    });

    testWidgets('MINOR-1: lazy Liste mit ungleichen Höhen: das erreichte '
        'Maximum zählt, kein Fehlalarm', (WidgetTester tester) async {
      await pump(
        tester,
        ListView(
          key: PreviewKeys.scroll,
          children: <Widget>[
            for (int i = 0; i < 40; i++)
              SizedBox(
                height: i < 10 ? 56 : 300,
                child: Center(child: _tap(300, 48)),
              ),
          ],
        ),
      );
      final ScrollPosition p = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final double estimate = p.maxScrollExtent;
      final List<ScrollScan> scans = await scanAll(tester);
      expect(
        scans.single.reachedMax,
        greaterThan(estimate),
        reason: 'der Ruhe-Schätzwert liegt unter dem echten Ende',
      );
      expect(await checkReachability(tester), isEmpty);
    });
  });

  group('probeKeyedRects: nur sichtbare Teilbäume (R-U3 MINOR-2)', () {
    const ValueKey<String> mark = ValueKey<String>('overlay:probe-test');

    Widget home() => Center(
      child: KeyedSubtree(
        key: mark,
        child: const SizedBox(width: 40, height: 40),
      ),
    );

    testWidgets('Marker unter einer durchscheinenden Route (Dialog) zählt', (
      WidgetTester tester,
    ) async {
      await pump(tester, home());
      final BuildContext ctx = tester.element(find.byKey(mark));
      showDialog<void>(
        context: ctx,
        builder: (BuildContext c) => const SizedBox(width: 10, height: 10),
      );
      await tester.pumpAndSettle();
      expect(probeKeyedRects(prefix: 'overlay:'), contains(mark.value));
    });

    testWidgets('Marker unter einer opaken Route zählt nicht', (
      WidgetTester tester,
    ) async {
      await pump(tester, home());
      final BuildContext ctx = tester.element(find.byKey(mark));
      Navigator.of(ctx).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();
      expect(probeKeyedRects(prefix: 'overlay:'), isNot(contains(mark.value)));
    });

    testWidgets('Marker in einer lazy Liste im Sichtfenster zählt', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        ListView.builder(
          itemCount: 100,
          itemExtent: 56,
          itemBuilder: (BuildContext c, int i) => i == 1
              ? KeyedSubtree(key: mark, child: const SizedBox(height: 56))
              : const SizedBox(height: 56),
        ),
      );
      expect(probeKeyedRects(prefix: 'overlay:'), contains(mark.value));
    });

    testWidgets('Marker in einem inaktiven Tab ist ausgeschlossen', (
      WidgetTester tester,
    ) async {
      Widget tabs(int index) => IndexedStack(
        index: index,
        children: <Widget>[
          KeyedSubtree(key: mark, child: const SizedBox(width: 40, height: 40)),
          const SizedBox(width: 40, height: 40),
        ],
      );
      await pump(tester, tabs(0));
      expect(probeKeyedRects(prefix: 'overlay:'), contains(mark.value));
      await pump(tester, tabs(1));
      expect(probeKeyedRects(prefix: 'overlay:'), isNot(contains(mark.value)));
    });
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
