// ContentFrame, WorldBackground, CuraBlur, GlassCard (U2a, UI-1, UI-6; V2-2, V2-9).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/logic/world_time.dart';
import 'package:curaone/theme/world_painter.dart';
import 'package:curaone/theme/world_tokens.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:curaone/ui/components/content_frame.dart';
import 'package:curaone/ui/components/cura_blur.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/world_background.dart';
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

  group('WorldBackground (V2-2, V2-9, V2-12, V2-14)', () {
    testWidgets('Baum: ExcludeSemantics > IgnorePointer > RepaintBoundary > '
        'CustomPaint, ohne Animation', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Stack(
          children: <Widget>[Positioned.fill(child: WorldBackground())],
        ),
      );
      final Finder world = find.byType(WorldBackground);
      expect(
        find.descendant(of: world, matching: find.byType(ExcludeSemantics)),
        findsOneWidget,
      );
      final Finder chain = find.descendant(
        of: find.descendant(
          of: find.descendant(
            of: world,
            matching: find.byType(ExcludeSemantics),
          ),
          matching: find.byType(IgnorePointer),
        ),
        matching: find.byType(RepaintBoundary),
      );
      expect(chain, findsWidgets);
      final Finder paint = find.descendant(
        of: world,
        matching: find.byType(CustomPaint),
      );
      expect(paint, findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      // Kein BackdropFilter: die Welt ist Gemaltes, kein Blur (V2-11).
      expect(backdropCount(tester), 0);
    });

    testWidgets(
      'Hoher Kontrast: Welt ohne Körnung, Dunst, Sterne, Sonne/Mond',
      (WidgetTester tester) async {
        await pumpApp(
          tester,
          const Stack(
            children: <Widget>[Positioned.fill(child: WorldBackground())],
          ),
          highContrast: true,
        );
        final WorldPainter p =
            tester
                    .widget<CustomPaint>(
                      find.descendant(
                        of: find.byType(WorldBackground),
                        matching: find.byType(CustomPaint),
                      ),
                    )
                    .painter!
                as WorldPainter;
        expect(p.decor, isFalse);
      },
    );

    /// Rendert die Welt [phase] und liefert das Bild (dp = Pixel).
    Future<(ui.Image, ByteData)> render(
      WidgetTester tester,
      WorldPhase phase, {
      bool decor = true,
    }) async {
      final GlobalKey key = GlobalKey();
      const Size size = Viewports.phone;
      setViewport(tester, size);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: SizedBox.fromSize(
              size: size,
              child: CustomPaint(
                painter: WorldPainter(
                  palette: WorldPalette.of(phase),
                  decor: decor,
                ),
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
      return (image, data);
    }

    Color pixel(ui.Image image, ByteData data, int x, int y) {
      final int i = (y * image.width + x) * 4;
      return Color.fromARGB(
        data.getUint8(i + 3),
        data.getUint8(i),
        data.getUint8(i + 1),
        data.getUint8(i + 2),
      );
    }

    int channelDiff(Color a, Color b) {
      int d(double x, double y) => ((x - y) * 255).abs().round();
      return <int>[
        d(a.r, b.r),
        d(a.g, b.g),
        d(a.b, b.b),
      ].reduce((int m, int v) => v > m ? v : m);
    }

    for (final WorldPhase phase in WorldPhase.values) {
      testWidgets('V2-2 Pixel: ${phase.name}: Himmel oben, Boden unten', (
        WidgetTester tester,
      ) async {
        final (ui.Image image, ByteData data) = await render(
          tester,
          phase,
          decor: false,
        );
        final WorldPalette p = WorldPalette.of(phase);
        // Oben links ohne Dekor: Himmelsfarbe oben (Toleranz Rundung).
        expect(
          channelDiff(pixel(image, data, 2, 0), p.skyTop),
          lessThanOrEqualTo(2),
        );
        // Ganz unten: Bodenfarbe (die Ebenen laufen in Transparenz aus).
        expect(
          channelDiff(pixel(image, data, 195, image.height - 1), p.floor),
          lessThanOrEqualTo(3),
        );
      });

      testWidgets(
        'V2-9 Pixel: ${phase.name}: keine harte Kontur zwischen den Ebenen',
        (WidgetTester tester) async {
          final (ui.Image image, ByteData data) = await render(
            tester,
            phase,
            decor: false,
          );
          // Spalten ohne Sonne/Mond; größter Sprung zwischen benachbarten
          // Pixeln (je Kanal, 0 … 255). Eine harte Kontur zwischen Ebenen
          // wäre ein Sprung von dutzenden Stufen.
          int worst = 0;
          for (final int x in <int>[20, 120, 195, 270, 370]) {
            for (int y = 1; y < image.height; y++) {
              final int d = channelDiff(
                pixel(image, data, x, y),
                pixel(image, data, x, y - 1),
              );
              if (d > worst) worst = d;
            }
          }
          expect(worst, lessThanOrEqualTo(8), reason: '${phase.name}: $worst');
        },
      );
    }

    testWidgets('Mitte der Mischung 50:50 liegt zwischen beiden Welten', (
      WidgetTester tester,
    ) async {
      final WorldPalette m = WorldPalette.forMix(
        const WorldMix(WorldPhase.midday, WorldPhase.night, 0.5),
      );
      expect(
        channelDiff(m.skyTop, WorldPalette.midday.skyTop),
        greaterThan(20),
      );
      expect(channelDiff(m.skyTop, WorldPalette.night.skyTop), greaterThan(20));
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
    testWidgets('Normal: card 92 %, Rand 1 dp hair, Radius 28, Lichtkante, '
        'Schatten 0/18/30 ohne Blur', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(child: GlassCard(child: Text('Inhalt'))),
      );
      final Finder card = find.byType(GlassCard);
      final CuraColors c = colorsAt(tester, card);
      final List<BoxDecoration> d = decorationsUnder(tester, card).toList();
      expect(d.first.gradient, c.cardFill);
      expect(d.first.borderRadius, BorderRadius.circular(28));
      final BoxDecoration border = d.firstWhere(
        (BoxDecoration x) => x.border != null,
      );
      expect(border.border, Border.all(color: c.borderHair, width: 1));
      // Schatten der Karte (E1): 0/18/30 mit negativem Spread, warm getönt.
      expect(d.first.boxShadow, CuraShadow.card(dark: false));
      final BoxShadow shadow = d.first.boxShadow!.single;
      expect(shadow.offset, const Offset(0, 18));
      expect(shadow.blurRadius, 30);
      expect(shadow.spreadRadius, lessThan(0));
      expect(shadow.color.toARGB32() & 0xFFFFFF, 0x2A211C);
      expect(d.skip(1).every((BoxDecoration x) => x.boxShadow == null), isTrue);
      // card 92 % (Hell: Weiß), kein Blur (V2-10).
      expect(c.card, const Color(0xFFFFFFFF).withValues(alpha: 0.92));
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
      expect(c.cardFillTop, c.surfaceOpaque);
      expect(c.cardFillBottom, c.surfaceOpaque);
      expect(c.surfaceOpaque.a, 1);
      final List<BoxDecoration> d = decorationsUnder(tester, card).toList();
      final LinearGradient g = d.first.gradient! as LinearGradient;
      expect(g.colors, <Color>[c.surfaceOpaque, c.surfaceOpaque]);
      expect(d.first.boxShadow, isNull, reason: 'kein Schatten bei HC');
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
