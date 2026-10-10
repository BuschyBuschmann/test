// Platzierung von Manny-Blase und `NodeHint` (Plan 4.6, UI-75): jede Stufe der
// Rückfallketten einzeln, deterministisch und ohne Widgets.
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/ui/components/manny_bubble.dart' show BubbleArrow;
import 'package:curaone/ui/components/node_hint.dart' show HintArrow;
import 'package:curaone/ui/path/overlay_placement.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Blase ohne Textmessung: feste Körpermaße, der Pfeil kommt dazu.
Size _bubble(BubbleArrow arrow, double maxWidth, {double height = 80}) {
  final double w = maxWidth;
  return arrow == BubbleArrow.left
      ? Size(w, height)
      : Size(w, height + CuraComponent.bubbleArrow);
}

BubbleMeasure _bubbleOf(double height) =>
    (BubbleArrow a, double w) => _bubble(a, w, height: height);

HintMeasure _hintOf(double width, double height) =>
    (double maxWidth) => Size(width < maxWidth ? width : maxWidth, height);

/// Gruppe wie auf dem Pfad: 56 breit, 112 hoch, 16 vom Rand, über der Nav.
Rect _cluster(Size viewport) {
  final double nav = CuraSize.navHeight + CuraSize.navBottomMargin;
  final double bottom = viewport.height - nav - CuraSpace.pageMargin;
  return Rect.fromLTRB(
    viewport.width - CuraSpace.pageMargin - 56,
    bottom - 112,
    viewport.width - CuraSpace.pageMargin,
    bottom,
  );
}

Rect _manny(double left, double top) => Rect.fromLTWH(left, top, 67, 80);

void main() {
  const Size phone = Size(390, 844);
  const Size small = Size(320, 568);

  group('Blase', () {
    test(
      'rechts neben Manny: Pfeil links, Spitze an Manny, über der Gruppe',
      () {
        final BubblePlacement p = placeBubble(
          manny: _manny(60, 300),
          viewport: phone,
          cluster: _cluster(phone),
          textScale: 1,
          measure: _bubbleOf(60),
        );
        expect(p.arrow, BubbleArrow.left);
        expect(p.rect.left, 60 + 67 + CuraSpace.s1);
        expect(
          p.rect.right,
          lessThanOrEqualTo(phone.width - CuraSpace.pageMargin),
        );
        expect(p.rect.bottom, lessThanOrEqualTo(_cluster(phone).top - 8));
        expect(p.limited, isFalse);
        expect(p.scrollOffsetDelta, 0);
      },
    );

    test('weniger als 140 dp rechts: über Manny (Pfeil nach unten)', () {
      // Manny rechts: 390 - 16 - (250 + 67) = 57 dp Platz.
      final BubblePlacement p = placeBubble(
        manny: _manny(250, 300),
        viewport: phone,
        cluster: _cluster(phone),
        textScale: 1,
        measure: _bubbleOf(60),
      );
      expect(p.arrow, BubbleArrow.down);
      expect(p.rect.bottom, 300, reason: 'Pfeilspitze an Mannys Kopf');
      expect(p.rect.left, greaterThanOrEqualTo(CuraSpace.pageMargin));
      expect(
        p.rect.right,
        lessThanOrEqualTo(phone.width - CuraSpace.pageMargin),
      );
    });

    test(
      'ab Textskalierung 1,5 immer über Manny, auch mit viel Platz rechts',
      () {
        final BubblePlacement p = placeBubble(
          manny: _manny(20, 300),
          viewport: phone,
          cluster: _cluster(phone),
          textScale: 1.5,
          measure: _bubbleOf(60),
        );
        expect(p.arrow, BubbleArrow.down);
        final BubblePlacement below = placeBubble(
          manny: _manny(20, 300),
          viewport: phone,
          cluster: _cluster(phone),
          textScale: 1.49,
          measure: _bubbleOf(60),
        );
        expect(below.arrow, BubbleArrow.left);
      },
    );

    test('rechts würde weniger als 8 dp über der Gruppe enden: über Manny', () {
      final Rect cluster = _cluster(small); // Oberkante 354
      // Blase rechts: Spitze bei Manny 0,4, Höhe 120 → Unterkante > 346.
      final BubblePlacement p = placeBubble(
        manny: _manny(20, 250),
        viewport: small,
        cluster: cluster,
        textScale: 1,
        measure: _bubbleOf(120),
      );
      expect(p.arrow, BubbleArrow.down);
      expect(p.rect.bottom, lessThanOrEqualTo(cluster.top - 8));
      expect(p.rect.top, greaterThanOrEqualTo(kOverlayTopLimit));
    });

    test('über Manny ist kein Platz: der Pfad scrollt nach unten', () {
      // Manny oben (Oberkante 40), Blase 120 hoch: es fehlen ca. 90 dp.
      final BubblePlacement p = placeBubble(
        manny: _manny(100, 40),
        viewport: phone,
        cluster: _cluster(phone),
        textScale: 2,
        measure: _bubbleOf(120),
        mannyBelowExtra: 42,
        scrollOffset: 500,
        allowScroll: true,
      );
      expect(p.arrow, BubbleArrow.down);
      expect(
        p.scrollOffsetDelta,
        lessThan(0),
        reason: 'Inhalt wandert nach unten',
      );
      expect(p.rect.top, greaterThanOrEqualTo(kOverlayTopLimit - 0.01));
      expect(p.limited, isFalse);
      // Nach dem Scrollen steht die Blase an Mannys neuer Lage.
      expect(p.rect.bottom, 40 - p.scrollOffsetDelta);
    });

    test('Scrollen reicht nicht (Offset 0 bzw. Gruppe im Weg): begrenzt, Text scrollt', () {
      final Rect cluster = _cluster(small);
      final BubblePlacement none = placeBubble(
        manny: _manny(100, 90),
        viewport: small,
        cluster: cluster,
        textScale: 2,
        measure: _bubbleOf(300),
        mannyBelowExtra: 42,
        scrollOffset: 0,
        allowScroll: true,
      );
      expect(none.limited, isTrue);
      expect(none.scrollOffsetDelta, 0);
      expect(none.rect.top, greaterThanOrEqualTo(kOverlayTopLimit - 0.01));
      expect(none.rect.bottom, lessThanOrEqualTo(90.01));
      expect(
        none.maxBodyHeight,
        closeTo(none.rect.height - CuraComponent.bubbleArrow, 0.01),
      );
      // Manny steht schon nahe der Gruppe: kaum Spielraum nach unten.
      final BubblePlacement tight = placeBubble(
        manny: _manny(100, 250),
        viewport: small,
        cluster: cluster,
        textScale: 2,
        measure: _bubbleOf(400),
        mannyBelowExtra: 42,
        scrollOffset: 800,
        allowScroll: true,
      );
      expect(tight.limited, isTrue);
      expect(tight.rect.bottom, lessThanOrEqualTo(cluster.top - 8 + 0.01));
    });

    test('ohne erlaubtes Scrollen (Mitlaufen): nie ein Scrollauftrag', () {
      final BubblePlacement p = placeBubble(
        manny: _manny(100, 40),
        viewport: phone,
        cluster: _cluster(phone),
        textScale: 2,
        measure: _bubbleOf(120),
        scrollOffset: 500,
      );
      expect(p.scrollOffsetDelta, 0);
      expect(p.limited, isTrue);
    });

    test(
      'Blase überdeckt die Gruppe in keinem Fall (Gitter aus Lagen und Maßen)',
      () {
        for (final Size viewport in <Size>[
          small,
          phone,
          const Size(430, 932),
        ]) {
          final Rect cluster = _cluster(viewport);
          for (double top = 60; top < cluster.top - 60; top += 37) {
            for (double left = 16; left < viewport.width - 80; left += 41) {
              for (final double h in <double>[48, 120, 260]) {
                for (final double scale in <double>[1, 2]) {
                  final BubblePlacement p = placeBubble(
                    manny: _manny(left, top),
                    viewport: viewport,
                    cluster: cluster,
                    textScale: scale,
                    measure: _bubbleOf(h),
                    mannyBelowExtra: 42,
                    scrollOffset: 300,
                    allowScroll: true,
                  );
                  final Rect r = p.rect.shift(Offset(0, 0));
                  expect(
                    r.bottom,
                    lessThanOrEqualTo(cluster.top - 8 + 0.01),
                    reason: '$viewport Manny($left,$top) h=$h ×$scale: $r',
                  );
                }
              }
            }
          }
        }
      },
    );
  });

  group('NodeHint', () {
    Rect unit(double cx, double cy, [double d = 48]) =>
        Rect.fromCenter(center: Offset(cx, cy), width: d, height: d);

    test('über der Unit, wenn dort mindestens 64 dp frei sind', () {
      final HintPlacement p = placeHint(
        unit: unit(195, 300),
        viewport: phone,
        cluster: _cluster(phone),
        measure: _hintOf(180, 44),
      );
      expect(p.arrow, HintArrow.down);
      expect(p.rect.bottom, 300 - 24, reason: 'Pfeilspitze an der Unit');
      expect(p.arrowCenter, closeTo(195 - p.rect.left, 0.01));
      expect(p.limited, isFalse);
    });

    test('unter der Unit, wenn oben weniger als 64 dp frei sind', () {
      final HintPlacement p = placeHint(
        unit: unit(195, 80), // Oberkante 56
        viewport: phone,
        cluster: _cluster(phone),
        measure: _hintOf(180, 44),
      );
      expect(p.arrow, HintArrow.up);
      expect(p.rect.top, 80 + 24);
    });

    test('bleibt vollständig im Bild: mindestens 16 dp Seitenrand, Pfeil an der Unit', () {
      for (final double cx in <double>[40, 195, 350]) {
        final HintPlacement p = placeHint(
          unit: unit(cx, 300),
          viewport: phone,
          cluster: _cluster(phone),
          measure: _hintOf(240, 44),
        );
        expect(p.rect.left, greaterThanOrEqualTo(CuraSpace.pageMargin));
        expect(
          p.rect.right,
          lessThanOrEqualTo(phone.width - CuraSpace.pageMargin),
        );
        expect(p.rect.left + p.arrowCenter, closeTo(cx, 0.01));
      }
    });

    test('Breite höchstens min(240, Breite - 32)', () {
      final HintPlacement wide = placeHint(
        unit: unit(195, 300),
        viewport: phone,
        cluster: _cluster(phone),
        measure: _hintOf(1000, 44),
      );
      expect(wide.rect.width, 240);
      final HintPlacement narrow = placeHint(
        unit: unit(160, 300),
        viewport: const Size(260, 568),
        cluster: _cluster(const Size(260, 568)),
        measure: _hintOf(1000, 44),
      );
      expect(narrow.rect.width, 260 - 32);
    });

    test('unten wäre die Gruppe im Weg: seitlich der Unit', () {
      final Rect cluster = _cluster(small); // Oberkante 354, Grenze 346
      // Oben nur 40 dp frei, unten 100 → Unterkante 100+52 > ... passt nicht.
      final HintPlacement p = placeHint(
        unit: unit(250, 330), // rechte Bahn, Unterkante 354 > Grenze
        viewport: small,
        cluster: cluster,
        measure: _hintOf(240, 150),
      );
      // Oben: 306 - 158 = 148 ≥ 8 und 306 ≥ 64 → oben passt.
      expect(p.arrow, HintArrow.down);
      // Erzwinge: Unit nahe oben UND nahe der Gruppe (kleine Sichtfläche).
      const Size tiny = Size(320, 300);
      final Rect c = _cluster(tiny); // Oberkante 86 → Grenze 78
      final HintPlacement side = placeHint(
        unit: unit(250, 50),
        viewport: tiny,
        cluster: c,
        measure: _hintOf(240, 40),
      );
      expect(side.arrow, HintArrow.right, reason: 'links neben der Unit');
      expect(side.rect.right, 250 - 24);
      expect(side.rect.left, greaterThanOrEqualTo(CuraSpace.pageMargin));
      expect(side.rect.bottom, lessThanOrEqualTo(78.01));
      final HintPlacement leftLane = placeHint(
        unit: unit(70, 50),
        viewport: tiny,
        cluster: c,
        measure: _hintOf(240, 40),
      );
      expect(leftLane.arrow, HintArrow.left, reason: 'rechts neben der Unit');
      expect(leftLane.rect.left, 70 + 24);
    });

    test(
      'kein Platz oben, unten und seitlich: der Pfad scrollt die Unit hoch',
      () {
        const Size v = Size(320, 500);
        final Rect c = _cluster(v); // Oberkante 312, Grenze 304
        final HintPlacement p = placeHint(
          unit: unit(160, 124), // Oberkante 100: oben passen 188 nicht
          viewport: v,
          cluster: c,
          measure: _hintOf(240, 180),
          scrollOffset: 500,
          maxScrollOffset: 1000,
          allowScroll: true,
        );
        expect(
          p.scrollOffsetDelta,
          greaterThan(0),
          reason: 'Inhalt wandert nach oben',
        );
        expect(p.arrow, HintArrow.up, reason: 'Hinweis darunter');
        expect(p.rect.bottom, lessThanOrEqualTo(304.01));
        expect(p.limited, isFalse);
      },
    );

    test(
      'Scrollen nicht möglich: begrenzt auf die freie Fläche, Text scrollt',
      () {
        const Size v = Size(320, 500);
        final Rect c = _cluster(v);
        final HintPlacement p = placeHint(
          unit: unit(160, 124),
          viewport: v,
          cluster: c,
          measure: _hintOf(240, 180),
          scrollOffset: 0,
          maxScrollOffset: 0,
          allowScroll: true,
        );
        expect(p.scrollOffsetDelta, 0);
        expect(p.limited, isTrue);
        expect(p.rect.bottom, lessThanOrEqualTo(304.01));
        expect(p.rect.top, greaterThanOrEqualTo(kOverlayTopLimit - 0.01));
      },
    );

    test('hohe Marke (Ausblick bei 200 %): die Unit rückt hoch genug, der '
        'Hinweis bleibt über der Gruppe und im Bild', () {
      const Size v = Size(320, 568);
      final Rect c = _cluster(v);
      final Rect tall = Rect.fromLTWH(16, 446, 288, 252);
      final HintPlacement p = placeHint(
        unit: tall,
        viewport: v,
        cluster: c,
        measure: _hintOf(240, 232),
        scrollOffset: 0,
        maxScrollOffset: 1000,
        allowScroll: true,
        topLimit: 48,
      );
      expect(p.scrollOffsetDelta, greaterThan(0));
      expect(p.arrow, HintArrow.down);
      expect(p.rect.bottom, lessThanOrEqualTo(c.top - 8 + 0.01));
      expect(p.rect.top, greaterThanOrEqualTo(48 - 0.01));
      expect(p.limited, isTrue);
    });

    test('Hinweis überdeckt die Gruppe in keinem Fall (Gitter)', () {
      for (final Size viewport in <Size>[small, phone]) {
        final Rect cluster = _cluster(viewport);
        for (double cy = 60; cy < viewport.height - 100; cy += 43) {
          for (double cx = 40; cx < viewport.width - 30; cx += 47) {
            for (final double h in <double>[44, 90, 200]) {
              final HintPlacement p = placeHint(
                unit: unit(cx, cy),
                viewport: viewport,
                cluster: cluster,
                measure: _hintOf(240, h),
                scrollOffset: 400,
                maxScrollOffset: 800,
                allowScroll: true,
              );
              // Nach dem Scrollauftrag steht die Unit um den Offset versetzt;
              // der Hinweis ist in den Koordinaten nach dem Scrollen.
              expect(
                p.rect.bottom,
                lessThanOrEqualTo(cluster.top - 8 + 0.01),
                reason: '$viewport Unit($cx,$cy) h=$h: ${p.rect}',
              );
              expect(
                p.rect.left,
                greaterThanOrEqualTo(CuraSpace.pageMargin - 0.01),
              );
              expect(
                p.rect.right,
                lessThanOrEqualTo(viewport.width - CuraSpace.pageMargin + 0.01),
              );
            }
          }
        }
      }
    });
  });
}
