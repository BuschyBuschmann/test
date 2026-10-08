// Pfad-Layout (Plan 7.3): Positionen der Units, Polster, Bézier-Strecken.
// Reine Funktion, testbar ohne Widgets. Maße kommen als Parameter (die
// Token-Werte `CuraSize.unit*` übergibt die UI), damit `lib/logic/` keine
// Flutter-Abhängigkeit braucht.
import 'dart:math' as math;

import 'path_model.dart';

/// Anteil der Viewport-Höhe, auf dem die aktuelle Unit steht (Brief 6.2).
const double kPathFocusFraction = 0.55;

/// Eine volle Sinus-Periode der Bahn über so viele Units.
const int kPathWavePeriod = 6;

/// Maße des Layouts in dp.
class PathLayoutMetrics {
  const PathLayoutMetrics({
    required this.small,
    required this.medium,
    required this.large,
    required this.boss,
    required this.sideMargin,
    required this.verticalGap,
  });

  /// Durchmesser je Unit-Art.
  final double small;
  final double medium;
  final double large;
  final double boss;

  /// Seitenrand (Brief 7: 16 dp).
  final double sideMargin;

  /// Lichter Abstand zwischen zwei Units (konstant).
  final double verticalGap;

  double diameterOf(UnitKind kind) {
    switch (kind) {
      case UnitKind.trainingDay:
        return small;
      case UnitKind.weekGoal:
        return medium;
      case UnitKind.phaseEnd:
        return large;
      case UnitKind.boss:
        return boss;
    }
  }
}

class NodePlacement {
  const NodePlacement({required this.center, required this.diameter});

  final math.Point<double> center;
  final double diameter;
}

/// Kubische Bézier-Strecke von Unit [from] zu Unit [to] (Index + 1).
class PathSegment {
  const PathSegment({
    required this.from,
    required this.to,
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
  });

  final int from;
  final int to;
  final math.Point<double> start;
  final math.Point<double> control1;
  final math.Point<double> control2;
  final math.Point<double> end;
}

class PathLayout {
  const PathLayout({
    required this.placements,
    required this.segments,
    required this.totalHeight,
    required this.padTop,
    required this.padBottom,
    required this.viewportHeight,
  });

  /// Gleiche Reihenfolge wie die Units (Index 0 = Woche 1 = unten).
  final List<NodePlacement> placements;
  final List<PathSegment> segments;
  final double totalHeight;
  final double padTop;
  final double padBottom;
  final double viewportHeight;

  /// Größter gültiger Scroll-Offset.
  double get maxScrollExtent => math.max(0, totalHeight - viewportHeight);

  /// Offset, der Unit [index] auf 55 % der Viewport-Höhe setzt (ungeklemmt;
  /// durch das Polster liegt er für **jede** Unit in `0..maxScrollExtent`).
  double scrollOffsetFor(int index) =>
      placements[index].center.y - kPathFocusFraction * viewportHeight;
}

/// Berechnet das Layout. Y wächst nach unten; die letzte Unit (Boss) liegt
/// oben, die erste unten. [bottomReserve] ist der Mindestwert für `padBottom`
/// aus der Button-Gruppe (Plan 4.6, UI-75).
PathLayout layoutPath({
  required List<PathUnit> units,
  required double width,
  required double viewportHeight,
  required PathLayoutMetrics metrics,
  double bottomReserve = 0,
}) {
  final int n = units.length;
  final List<double> diameters = <double>[
    for (final PathUnit u in units) metrics.diameterOf(u.kind),
  ];

  // Polster, damit jede Unit auf 55 % gescrollt werden kann.
  final double topDiameter = n == 0 ? 0 : diameters[n - 1];
  final double bottomDiameter = n == 0 ? 0 : diameters[0];
  final double padTop = math.max(
    0,
    kPathFocusFraction * viewportHeight - topDiameter / 2,
  );
  final double padBottom = math.max(
    math.max(0, (1 - kPathFocusFraction) * viewportHeight - bottomDiameter / 2),
    bottomReserve,
  );

  // Von oben (Index n-1) nach unten (Index 0).
  final List<double> ys = List<double>.filled(n, 0);
  double cursor = padTop;
  for (int i = n - 1; i >= 0; i--) {
    ys[i] = cursor + diameters[i] / 2;
    cursor += diameters[i] + (i > 0 ? metrics.verticalGap : 0);
  }
  final double totalHeight = cursor + padBottom;

  final List<NodePlacement> placements = <NodePlacement>[];
  for (int i = 0; i < n; i++) {
    // Sinuskurve über die volle zulässige Breite dieser Unit.
    final double half = math.max(
      0,
      (width - 2 * metrics.sideMargin - diameters[i]) / 2,
    );
    final double x =
        width / 2 + half * math.sin(2 * math.pi * i / kPathWavePeriod);
    placements.add(
      NodePlacement(
        center: math.Point<double>(x, ys[i]),
        diameter: diameters[i],
      ),
    );
  }

  final List<PathSegment> segments = <PathSegment>[];
  for (int i = 0; i + 1 < n; i++) {
    final math.Point<double> a = placements[i].center;
    final math.Point<double> b = placements[i + 1].center;
    final double midY = (a.y + b.y) / 2;
    segments.add(
      PathSegment(
        from: i,
        to: i + 1,
        start: a,
        control1: math.Point<double>(a.x, midY),
        control2: math.Point<double>(b.x, midY),
        end: b,
      ),
    );
  }

  return PathLayout(
    placements: List<NodePlacement>.unmodifiable(placements),
    segments: List<PathSegment>.unmodifiable(segments),
    totalHeight: totalHeight,
    padTop: padTop,
    padBottom: padBottom,
    viewportHeight: viewportHeight,
  );
}
