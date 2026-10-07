// ContentFrame, GlowBackground, CuraBlur, GlassCard (U2a, UI-1, UI-6, UI-7, UI-9).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/theme/glow.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:curaone/ui/components/content_frame.dart';
import 'package:curaone/ui/components/cura_blur.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/glow_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

void main() {
  group('ContentFrame (B-3)', () {
    testWidgets('Telefon: volle Breite', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const ContentFrame(child: SizedBox.expand(key: Key('inner'))),
      );
      expect(tester.getSize(find.byKey(const Key('inner'))).width, 390);
    });

    testWidgets('Tablet: mittig auf 560 dp begrenzt, Höhe voll', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const ContentFrame(child: SizedBox.expand(key: Key('inner'))),
        size: Viewports.tablet,
      );
      final Rect r = tester.getRect(find.byKey(const Key('inner')));
      expect(r.width, CuraSize.lineLengthMax);
      expect(r.width, 560);
      expect(r.center.dx, closeTo(768 / 2, 0.01));
      expect(r.height, 1024);
    });
  });

  group('GlowBackground (UI-7, UI-9)', () {
    testWidgets('Baum: ExcludeSemantics > IgnorePointer > RepaintBoundary > '
        'CustomPaint, ohne Animation', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Stack(
          children: <Widget>[Positioned.fill(child: GlowBackground())],
        ),
      );
      final Finder glow = find.byType(GlowBackground);
      expect(
        find.descendant(of: glow, matching: find.byType(ExcludeSemantics)),
        findsOneWidget,
      );
      final Finder chain = find.descendant(
        of: find.descendant(
          of: find.descendant(
            of: glow,
            matching: find.byType(ExcludeSemantics),
          ),
          matching: find.byType(IgnorePointer),
        ),
        matching: find.byType(RepaintBoundary),
      );
      expect(chain, findsWidgets);
      final Finder paint = find.descendant(
        of: glow,
        matching: find.byType(CustomPaint),
      );
      expect(paint, findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('Hoher Kontrast: nicht gebaut', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Stack(
          children: <Widget>[Positioned.fill(child: GlowBackground())],
        ),
        highContrast: true,
      );
      expect(
        find.byType(CustomPaint).evaluate().where((Element e) {
          return e.widget is CustomPaint &&
              (e.widget as CustomPaint).painter is GlowPainter;
        }),
        isEmpty,
      );
    });

    testWidgets('Pixel: Spitze oben links 24 %, unten rechts 14 %, Mitte frei', (
      WidgetTester tester,
    ) async {
      final GlobalKey key = GlobalKey();
      const Size size = Viewports.phone;
      setViewport(tester, size);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: CuraColors.dark.bg,
              child: Theme(
                data: ThemeData(
                  extensions: <ThemeExtension<dynamic>>[CuraColors.dark],
                ),
                child: const SizedBox.expand(child: GlowBackground()),
              ),
            ),
          ),
        ),
      );
      final ui.Image image = (await tester.runAsync(() async {
        final RenderRepaintBoundary b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return b.toImage();
      }))!;
      final ByteData data = (await tester.runAsync<ByteData?>(
        () => image.toByteData(),
      ))!;
      Color pixel(int x, int y) {
        final int i = (y * image.width + x) * 4;
        return Color.fromARGB(
          data.getUint8(i + 3),
          data.getUint8(i),
          data.getUint8(i + 1),
          data.getUint8(i + 2),
        );
      }

      // Erwartung: Ember über bg mit Alpha am Punkt.
      Color expected(double alpha) => Color.alphaBlend(
        CuraColors.dark.glowEmber.withValues(alpha: alpha),
        CuraColors.dark.bg,
      );
      void expectNear(Color a, Color b) {
        expect((a.r * 255 - b.r * 255).abs(), lessThanOrEqualTo(3));
        expect((a.g * 255 - b.g * 255).abs(), lessThanOrEqualTo(3));
        expect((a.b * 255 - b.b * 255).abs(), lessThanOrEqualTo(3));
      }

      const GlowGeometry g = GlowGeometry(390, 844);
      // Pixel (0, 40): Abstand 30 zur Mitte (-30, 40) + Beitrag unten rechts 0.
      expectNear(pixel(0, 40), expected(g.alphaAt(0.5, 40.5)));
      expect(g.alphaAt(0.5, 40.5), closeTo(0.24 * (1 - 30.5 / 182), 0.01));
      // Unten rechts nahe der Mitte (440, 820): Pixel (389, 820).
      expectNear(pixel(389, 820), expected(g.alphaAt(389.5, 820.5)));
      // Bildschirmmitte: kein Glow.
      expectNear(pixel(195, 422), CuraColors.dark.bg);
      expect(GlowTokens.topLeftPeak, 0.24);
      expect(GlowTokens.bottomRightPeak, 0.14);
    });
  });

  group('CuraBlur (UI-6, Regel 3)', () {
    testWidgets('Normal: ein BackdropFilter mit sigma 16', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const CuraBlur(child: SizedBox(width: 40, height: 40)),
      );
      expect(backdropCount(tester), 1);
      final BackdropFilter f = tester.widget(find.byType(BackdropFilter));
      expect(
        f.filter,
        ui.ImageFilter.blur(sigmaX: BlurTokens.sigma, sigmaY: BlurTokens.sigma),
      );
      expect(BlurTokens.sigma, 16);
    });

    testWidgets('Hoher Kontrast: kein Blur', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const CuraBlur(child: SizedBox(width: 40, height: 40)),
        highContrast: true,
      );
      expect(backdropCount(tester), 0);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('GlassCard (Brief 5.1, E1)', () {
    testWidgets('Normal: Verlauf, Rand 1 dp hair, Radius 24, Lichtkante, '
        'kein Blur, kein Schatten', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(child: GlassCard(child: Text('Inhalt'))),
      );
      final Finder card = find.byType(GlassCard);
      final CuraColors c = colorsAt(tester, card);
      final List<BoxDecoration> d = decorationsUnder(tester, card).toList();
      expect(d.first.gradient, c.cardFill);
      expect(d.first.borderRadius, BorderRadius.circular(24));
      final BoxDecoration border = d.firstWhere(
        (BoxDecoration x) => x.border != null,
      );
      expect(border.border, Border.all(color: c.borderHair, width: 1));
      expect(d.every((BoxDecoration x) => x.boxShadow == null), isTrue);
      expect(backdropCount(tester), 0);
      // Lichtkante: ColoredBox 1 dp hoch in `lightEdge`.
      final Finder edge = find.descendant(
        of: card,
        matching: find.byWidgetPredicate(
          (Widget w) => w is ColoredBox && w.color == c.lightEdge,
        ),
      );
      expect(edge, findsOneWidget);
      expect(tester.getSize(edge).height, 1);
      // Innenabstand 16.
      final Rect cardRect = tester.getRect(card);
      final Rect textRect = tester.getRect(find.text('Inhalt'));
      expect(textRect.left - cardRect.left, 16);
      expect(textRect.top - cardRect.top, 16);
    });

    testWidgets('Hoher Kontrast: opak, Rand -hc, keine Lichtkante', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const Center(child: GlassCard(child: Text('Inhalt'))),
        highContrast: true,
      );
      final Finder card = find.byType(GlassCard);
      final CuraColors c = colorsAt(tester, card);
      expect(c.cardFillTop, const Color(0xFF1B2129));
      expect(c.cardFillBottom, const Color(0xFF1B2129));
      final List<BoxDecoration> d = decorationsUnder(tester, card).toList();
      final LinearGradient g = d.first.gradient! as LinearGradient;
      expect(g.colors, <Color>[
        const Color(0xFF1B2129),
        const Color(0xFF1B2129),
      ]);
      expect(
        d.firstWhere((BoxDecoration x) => x.border != null).border,
        Border.all(color: c.borderControlHc, width: 1),
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byWidgetPredicate((Widget w) => w is ColoredBox),
        ),
        findsNothing,
      );
    });
  });
}
