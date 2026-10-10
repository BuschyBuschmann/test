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
    this.outlookMaxWidth = 300,
    this.outlookGap = 84,
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

  /// Höchstbreite des Ausblicks (Ergänzung 3, 2.1: 300 dp).
  final double outlookMaxWidth;

  /// Kleinster lichter Abstand zwischen Boss-Oberkante und Unterkante des
  /// Ausblicks (Ergänzung 3, 2.2: `pathUnitGapMin`, 84 dp).
  final double outlookGap;

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

/// Lage des Ausblicks `PathOutlook` (Ergänzung 3): Abschnittsmarke, **keine
/// Unit**, mittig im Pfadbereich, oberstes Element. Platzhalter, die volle
/// Phase folgt mit eigener Spec.
class OutlookPlacement {
  const OutlookPlacement({
    required this.center,
    required this.width,
    required this.height,
  });

  final math.Point<double> center;
  final double width;
  final double height;

  double get top => center.y - height / 2;
  double get bottom => center.y + height / 2;
  double get left => center.x - width / 2;
  double get right => center.x + width / 2;
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
    this.outlook,
    this.outlookSegment,
  });

  /// Gleiche Reihenfolge wie die Units (Index 0 = Woche 1 = unten).
  final List<NodePlacement> placements;
  final List<PathSegment> segments;
  final double totalHeight;
  final double padTop;
  final double padBottom;
  final double viewportHeight;

  /// Ausblick über dem Boss (`null`, wenn nicht gezeigt).
  final OutlookPlacement? outlook;

  /// Zukunftslinie vom Boss (`from` = letzte Unit) zur Unterkante des
  /// Ausblicks, Mitte (`to` = Länge der Unit-Liste; keine Unit).
  final PathSegment? outlookSegment;

  /// Größter gültiger Scroll-Offset.
  double get maxScrollExtent => math.max(0, totalHeight - viewportHeight);

  /// Offset, der Unit [index] auf 55 % der Viewport-Höhe setzt (ungeklemmt;
  /// durch das Polster liegt er für **jede** Unit in `0..maxScrollExtent`).
  double scrollOffsetFor(int index) =>
      placements[index].center.y - kPathFocusFraction * viewportHeight;

  /// Offset, der den Ausblick auf 55 % der Viewport-Höhe setzt.
  double? get scrollOffsetForOutlook {
    final OutlookPlacement? o = outlook;
    return o == null ? null : o.center.y - kPathFocusFraction * viewportHeight;
  }
}

/// Berechnet das Layout. Y wächst nach unten; die letzte Unit (Boss) liegt
/// oben, die erste unten. [bottomReserve] ist der Mindestwert für `padBottom`
/// aus der Button-Gruppe (Plan 4.6, UI-75). [outlookHeight] (gemessen von der
/// UI, mindestens 72 dp) schaltet den Ausblick ein: er steht zentriert über dem
/// Boss, `padTop` bezieht sich auf ihn.
PathLayout layoutPath({
  required List<PathUnit> units,
  required double width,
  required double viewportHeight,
  required PathLayoutMetrics metrics,
  double bottomReserve = 0,
  double? outlookHeight,
}) {
  final int n = units.length;
  final List<double> diameters = <double>[
    for (final PathUnit u in units) metrics.diameterOf(u.kind),
  ];

  // Polster, damit jede Unit auf 55 % gescrollt werden kann.
  final double topDiameter = n == 0 ? 0 : diameters[n - 1];
  final double bottomDiameter = n == 0 ? 0 : diameters[0];
  final double? oh = n == 0 ? null : outlookHeight;
  final double padTop = math.max(
    0,
    kPathFocusFraction * viewportHeight - (oh ?? topDiameter) / 2,
  );
  final double padBottom = math.max(
    math.max(0, (1 - kPathFocusFraction) * viewportHeight - bottomDiameter / 2),
    bottomReserve,
  );

  // Von oben (Index n-1) nach unten (Index 0).
  final List<double> ys = List<double>.filled(n, 0);
  double cursor = padTop;
  OutlookPlacement? outlook;
  if (oh != null) {
    final double w = math.max(
      0,
      math.min(width - 2 * metrics.sideMargin, metrics.outlookMaxWidth),
    );
    outlook = OutlookPlacement(
      center: math.Point<double>(width / 2, cursor + oh / 2),
      width: w,
      height: oh,
    );
    cursor += oh + metrics.outlookGap;
  }
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

  PathSegment? outlookSegment;
  if (outlook != null) {
    final math.Point<double> boss = placements[n - 1].center;
    final math.Point<double> end = math.Point<double>(
      outlook.center.x,
      outlook.bottom,
    );
    final double midY = (boss.y + end.y) / 2;
    outlookSegment = PathSegment(
      from: n - 1,
      to: n,
      start: boss,
      control1: math.Point<double>(boss.x, midY),
      control2: math.Point<double>(end.x, midY),
      end: end,
    );
  }

  return PathLayout(
    outlook: outlook,
    outlookSegment: outlookSegment,
    placements: List<NodePlacement>.unmodifiable(placements),
    segments: List<PathSegment>.unmodifiable(segments),
    totalHeight: totalHeight,
    padTop: padTop,
    padBottom: padBottom,
    viewportHeight: viewportHeight,
  );
}
