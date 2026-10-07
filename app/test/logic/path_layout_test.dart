import 'dart:math' as math;

import 'package:curaone/logic/path_generator.dart';
import 'package:curaone/logic/path_layout.dart';
import 'package:curaone/logic/path_model.dart';
import 'package:flutter_test/flutter_test.dart';

// Werte der Tokens (CuraSize.unit*, Brief 3.4); die UI übergibt sie später aus
// `lib/theme/`. Die Logik-Tests geben sie explizit vor.
const PathLayoutMetrics metrics = PathLayoutMetrics(
  small: 48,
  medium: 60,
  large: 72,
  boss: 92,
  sideMargin: 16,
  verticalGap: 24,
);

PathLayout layoutFor(double width, double height, {double reserve = 0}) =>
    layoutPath(
      units: kSamplePath,
      width: width,
      viewportHeight: height,
      metrics: metrics,
      bottomReserve: reserve,
    );

void main() {
  for (final (double w, double h) in <(double, double)>[
    (320, 568),
    (390, 844),
    (430, 932),
  ]) {
    group('Layout $w×$h', () {
      final PathLayout l = layoutFor(w, h);

      test('x innerhalb der Grenzen inkl. Durchmesser (Seitenrand 16)', () {
        for (final NodePlacement p in l.placements) {
          expect(p.center.x - p.diameter / 2, greaterThanOrEqualTo(16 - 1e-9));
          expect(p.center.x + p.diameter / 2, lessThanOrEqualTo(w - 16 + 1e-9));
        }
      });

      test('geschwungen: nicht alle x gleich (UI-20)', () {
        expect(
          l.placements.map((p) => p.center.x.round()).toSet().length,
          greaterThan(3),
        );
      });

      test('y streng monoton: Boss oben, Woche 1 unten', () {
        for (int i = 0; i + 1 < l.placements.length; i++) {
          expect(
            l.placements[i + 1].center.y,
            lessThan(l.placements[i].center.y),
          );
        }
      });

      test('Durchmesser 48/60/72/92 nach Art', () {
        for (int i = 0; i < kSamplePath.length; i++) {
          final double expected = switch (kSamplePath[i].kind) {
            UnitKind.trainingDay => 48,
            UnitKind.weekGoal => 60,
            UnitKind.phaseEnd => 72,
            UnitKind.boss => 92,
          };
          expect(l.placements[i].diameter, expected);
        }
      });

      test('keine Überlappung benachbarter Units', () {
        for (int i = 0; i + 1 < l.placements.length; i++) {
          final double dy =
              l.placements[i].center.y - l.placements[i + 1].center.y;
          expect(
            dy,
            closeTo(
              (l.placements[i].diameter + l.placements[i + 1].diameter) / 2 +
                  24,
              1e-9,
            ),
          );
        }
      });

      test('für erste, letzte und jede Unit existiert ein gültiger Offset auf 55 %', () {
        for (int i = 0; i < l.placements.length; i++) {
          final double off = l.scrollOffsetFor(i);
          expect(off, greaterThanOrEqualTo(-1e-9), reason: 'Unit $i');
          expect(
            off,
            lessThanOrEqualTo(l.maxScrollExtent + 1e-9),
            reason: 'Unit $i',
          );
          expect(l.placements[i].center.y - off, closeTo(0.55 * h, 1e-9));
        }
      });

      test('Gesamthöhe = Polster + Units + Abstände', () {
        final double units =
            l.placements.fold(0.0, (double s, p) => s + p.diameter) +
            (l.placements.length - 1) * 24;
        expect(l.totalHeight, closeTo(l.padTop + units + l.padBottom, 1e-9));
      });

      test('Bézier-Strecken verbinden aufeinanderfolgende Units', () {
        expect(l.segments, hasLength(kSamplePath.length - 1));
        for (final PathSegment s in l.segments) {
          expect(s.start, l.placements[s.from].center);
          expect(s.end, l.placements[s.to].center);
          expect(s.to, s.from + 1);
          expect(s.control1.x, s.start.x);
          expect(s.control2.x, s.end.x);
          expect(s.control1.y, closeTo((s.start.y + s.end.y) / 2, 1e-9));
        }
      });
    });
  }

  test('Gruppen-Reserve: padBottom ≥ bottomReserve (UI-75)', () {
    final PathLayout l = layoutFor(390, 844, reserve: 600);
    expect(l.padBottom, greaterThanOrEqualTo(600));
    for (int i = 0; i < l.placements.length; i++) {
      expect(l.scrollOffsetFor(i), lessThanOrEqualTo(l.maxScrollExtent + 1e-9));
    }
  });

  test('leere Unit-Liste und schmale Breite stürzen nicht ab', () {
    final PathLayout empty = layoutPath(
      units: const <PathUnit>[],
      width: 320,
      viewportHeight: 568,
      metrics: metrics,
    );
    expect(empty.placements, isEmpty);
    final PathLayout narrow = layoutFor(100, 300);
    expect(narrow.placements.every((p) => p.center.x.isFinite), isTrue);
    expect(math.max(0, narrow.maxScrollExtent), greaterThan(0));
  });
}
