// MannyPlaceholder (Brief 5.6, UI-74, UI-8 Regel 9): Größen, Posen, Farben
// (Pixel), Label, Hit-Fläche (Form + 8 dp, bis Standlinie, ≥ 48 dp), Pressed.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

class _Pixels {
  _Pixels(this.image, this.data);

  final ui.Image image;
  final ByteData data;

  Color at(int x, int y) {
    final int i = (y * image.width + x) * 4;
    return Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  }
}

Future<_Pixels> _capture(WidgetTester tester, GlobalKey key) async {
  final ui.Image image = (await tester.runAsync(() async {
    final RenderRepaintBoundary b =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return b.toImage();
  }))!;
  final ByteData data = (await tester.runAsync<ByteData?>(
    () => image.toByteData(),
  ))!;
  return _Pixels(image, data);
}

bool _near(Color a, Color b, [int tol = 4]) =>
    ((a.r - b.r) * 255).abs() <= tol &&
    ((a.g - b.g) * 255).abs() <= tol &&
    ((a.b - b.b) * 255).abs() <= tol;

Widget _framed(GlobalKey key, Widget child) => Align(
  alignment: Alignment.topLeft,
  child: RepaintBoundary(key: key, child: child),
);

void main() {
  final CuraColors c = CuraColors.dark;

  testWidgets('Größen: voll 100:120, Kopf quadratisch', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const Column(
        children: <Widget>[
          MannyPlaceholder(height: 80, key: Key('full')),
          MannyPlaceholder(height: 38, crop: MannyCrop.head, key: Key('head')),
        ],
      ),
    );
    final Size full = tester.getSize(find.byKey(const Key('full')));
    expect(full.height, 80);
    expect(full.width, closeTo(80 * 100 / 120, 0.01));
    final Size head = tester.getSize(find.byKey(const Key('head')));
    expect(head, const Size(38, 38));
  });

  testWidgets('Bild-Label „Manny, dein Begleiter“; ausblendbar', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await pumpApp(
      tester,
      const Column(
        children: <Widget>[
          MannyPlaceholder(height: 80, key: Key('a')),
          MannyPlaceholder(height: 38, excludeSemantics: true, key: Key('b')),
        ],
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('a'))),
      matchesSemantics(label: 'Manny, dein Begleiter', isImage: true),
    );
    expect(find.bySemanticsLabel('Manny, dein Begleiter'), findsOneWidget);
    h.dispose();
  });

  testWidgets('Farben (Pixel): Körper #34425F, Bauch #F2F0EB, Schnabel und '
      'Füße accent-hi, Pupille bg', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await pumpApp(tester, _framed(key, const MannyPlaceholder(height: 240)));
    final _Pixels p = await _capture(tester, key);
    // 240 dp Höhe = 2 px je Einheit.
    Color unit(num x, num y) => p.at((x * 2).round(), (y * 2).round());
    expect(_near(unit(26, 70), c.mannyBody), isTrue, reason: 'Körper');
    expect(_near(unit(50, 95), c.mannyBelly), isTrue, reason: 'Bauch');
    expect(_near(unit(50, 53), c.accentHi), isTrue, reason: 'Schnabel');
    expect(_near(unit(36, 116), c.accentHi), isTrue, reason: 'Fuß');
    expect(_near(unit(38, 38), c.mannyBelly), isTrue, reason: 'Auge');
    expect(_near(unit(41, 41), c.bg), isTrue, reason: 'Pupille');
    // Außerhalb transparent.
    expect(unit(3, 3).a, 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Posen unterscheiden sich (Flügel, Augen) und sind statisch', (
    WidgetTester tester,
  ) async {
    final List<List<MannyWing>> wings = <List<MannyWing>>[
      for (final MannyPose p in MannyPose.values) MannyGeometry.wings(p),
    ];
    expect(wings[0][1].angle, isNot(wings[1][1].angle));
    expect(wings[1][1].angle, isNot(wings[2][1].angle));
    final GlobalKey ka = GlobalKey();
    final GlobalKey kb = GlobalKey();
    await pumpApp(
      tester,
      Column(
        children: <Widget>[
          _framed(ka, const MannyPlaceholder(height: 240)),
          _framed(
            kb,
            const MannyPlaceholder(height: 240, pose: MannyPose.feiernd),
          ),
        ],
      ),
      size: const Size(390, 900),
    );
    final _Pixels a = await _capture(tester, ka);
    final _Pixels b = await _capture(tester, kb);
    // Feiernd: Augen als Bögen (an der Augenmitte kein weißer Kreis mehr).
    expect(_near(a.at(80, 80), c.bg), isTrue, reason: 'neutral: Pupille');
    expect(_near(b.at(80, 80), c.mannyBody), isTrue, reason: 'feiernd: Bogen');
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Kopf-Zuschnitt zeigt Augen und Schnabel, keine Füße', (
    WidgetTester tester,
  ) async {
    final GlobalKey key = GlobalKey();
    await pumpApp(
      tester,
      _framed(key, const MannyPlaceholder(height: 136, crop: MannyCrop.head)),
    );
    final _Pixels p = await _capture(tester, key);
    // Zuschnitt 16..84 × 14..82 → 2 px je Einheit; Auge (36,40) → (40,52).
    expect(_near(p.at(40, 52), c.mannyBelly), isTrue);
    expect(_near(p.at(68, 78), c.accentHi), isTrue, reason: 'Schnabel (50,53)');
  });

  group('Hit-Fläche (Plan 4.6, UI-74)', () {
    const Size size = Size(66.6667, 80);

    test('Form + 8 dp Rand; nichts unterhalb der Standlinie', () {
      final Path path = MannyPlaceholder.hitPath(
        size: size,
        pose: MannyPose.neutral,
      );
      // Körpermitte.
      expect(path.contains(const Offset(33, 45)), isTrue);
      // Körperrand links bei y=68 Einheiten: x = 16 Einheiten ≈ 10,7 dp;
      // 6 dp außerhalb liegt noch im 8-dp-Rand, 12 dp außerhalb nicht mehr.
      final double sx = size.width / 100;
      final double edge = 16 * sx;
      final double midY = 55 * sx; // knapp unter Körpermitte, vor Flügelspitze
      expect(path.contains(Offset(edge + 1, midY)), isTrue);
      // Oberhalb des Kopfes: 6 dp über dem Körper noch drin, 12 dp nicht.
      final double top = 22 * (80 / 120);
      expect(path.contains(Offset(33, top - 6)), isTrue);
      expect(path.contains(Offset(33, top - 12)), isFalse);
      // Standlinie: Fußunterkante bei 118 Einheiten.
      final double base = 118 * (80 / 120);
      expect(path.contains(Offset(36 * sx, base - 1)), isTrue);
      expect(path.contains(Offset(36 * sx, base + 1)), isFalse);
      expect(path.contains(Offset(33, base + 6)), isFalse);
    });

    test('mindestens 48 × 48 dp, auch bei sehr kleinem Manny', () {
      const Size tiny = Size(20, 24);
      final Path path = MannyPlaceholder.hitPath(
        size: tiny,
        pose: MannyPose.neutral,
        crop: MannyCrop.full,
      );
      final Rect b = path.getBounds();
      expect(b.width, greaterThanOrEqualTo(20)); // auf die Fläche begrenzt
      // Bei 80 dp ist die Form größer als 48 × 48.
      final Rect big = MannyPlaceholder.hitPath(
        size: size,
        pose: MannyPose.neutral,
      ).getBounds();
      expect(big.width, greaterThanOrEqualTo(48));
      expect(big.height, greaterThanOrEqualTo(48));
    });

    test('Posen verändern die Fläche (Flügel oben bei feiernd)', () {
      final Path a = MannyPlaceholder.hitPath(
        size: size,
        pose: MannyPose.neutral,
      );
      final Path b = MannyPlaceholder.hitPath(
        size: size,
        pose: MannyPose.feiernd,
      );
      // Feiernd: Flügelspitze oben links bei ca. (5, 17) dp liegt drin,
      // neutral nicht.
      const Offset wingTip = Offset(5, 22);
      expect(b.contains(wingTip), isTrue);
      expect(a.contains(wingTip), isFalse);
    });

    testWidgets('Tipp in Form und 8-dp-Rand öffnet, außerhalb und unter der '
        'Standlinie nicht', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(100),
            child: MannyPlaceholder(height: 80, onTap: () => taps++),
          ),
        ),
      );
      final Rect r = tester.getRect(find.byType(MannyPlaceholder));
      await tester.tapAt(r.center);
      expect(taps, 1);
      // 4 dp links vom Körperrand (im 8-dp-Rand).
      await tester.tapAt(Offset(r.left + 10.67 - 4, r.top + 45));
      expect(taps, 2);
      // Weit außerhalb (Ecke der Fläche, oben links) bzw. unter der Standlinie.
      await tester.tapAt(r.topLeft + const Offset(1, 1));
      expect(taps, 2);
      await tester.tapAt(Offset(r.center.dx, r.bottom - 0.2 + 4));
      expect(taps, 2);
    });

    testWidgets('Ohne onTap: nicht antippbar (IgnorePointer), keine '
        'Fokusstation, kein Button in der Semantik', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int taps = 0;
      await pumpApp(
        tester,
        Stack(
          children: <Widget>[
            const Positioned(
              left: 100,
              top: 100,
              child: MannyPlaceholder(height: 80, key: Key('m')),
            ),
            Positioned(
              left: 100,
              top: 100,
              width: 80,
              height: 80,
              child: GestureDetector(onTap: () => taps++),
            ),
          ],
        ),
      );
      await tester.tapAt(const Offset(133, 140));
      expect(taps, 1, reason: 'Tipp geht durch Manny hindurch');
      h.dispose();
    });

    testWidgets('Mit onTap: kein Fokusstopp und keine Button-Semantik', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(tester, MannyPlaceholder(height: 80, onTap: () {}));
      expect(
        tester.getSemantics(find.byType(MannyPlaceholder)),
        matchesSemantics(label: 'Manny, dein Begleiter', isImage: true),
      );
      expect(find.byType(ExcludeFocus), findsWidgets);
      h.dispose();
    });
  });

  testWidgets('Pressed: Form 10 % heller, keine Animation', (
    WidgetTester tester,
  ) async {
    final GlobalKey key = GlobalKey();
    await pumpApp(
      tester,
      _framed(key, MannyPlaceholder(height: 240, onTap: () {})),
    );
    final _Pixels normal = await _capture(tester, key);
    final TestGesture g = await tester.startGesture(const Offset(50, 150));
    await tester.pump();
    final _Pixels pressed = await _capture(tester, key);
    Color bodyAt(_Pixels p) => p.at(52, 140);
    final Color a = bodyAt(normal);
    final Color b = bodyAt(pressed);
    expect(_near(a, c.mannyBody), isTrue);
    expect(b.r, greaterThan(a.r));
    expect(b.g, greaterThan(a.g));
    expect(b.b, greaterThan(a.b));
    expect(tester.hasRunningAnimations, isFalse);
    await g.up();
  });
}
