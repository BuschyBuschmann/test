// `PathView` (Design-Brief v2, 7.1; Plan 3, 9): der scrollende Inhalt des Pfads
// auf der Welt: eine geschwungene Linie (ein `CustomPainter`, für den
// Screenreader ausgeblendet), die Kugeln (`OrbNode`) als Widgets (von oben nach
// unten: Lese- und Fokusreihenfolge), die Beschriftungen unter Wochenziel,
// Phasen-Abschluss und Boss als **Label-Chip** (`WorldLabelChip`, Text steht nie
// direkt auf der Welt, V2-5) und Manny **neben der aktuellen Kugel**.
//
// Manny steht rechts von der aktuellen Kugel, bei Platzmangel links; die Füße
// stehen auf der Höhe ihrer Unterkante. Er liegt direkt hinter seiner Kugel in
// der Z-Reihenfolge und damit an der richtigen Stelle der Lesereihenfolge. Manny
// nimmt nur Tipps auf seiner Form (plus 8 dp Rand, bis zur Standlinie) an; was
// die Form nicht trifft, fällt auf die Fläche darunter durch (UI-59, UI-74).
// In der Welt Nacht steht hinter ihm der Halo (Ergänzung 1, 6.4).
import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';

import '../../logic/path_generator.dart';
import '../../logic/path_layout.dart';
import '../../logic/path_model.dart';
import '../../state/world_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/world_tokens.dart';
import '../components/manny.dart';
import '../components/orb_node.dart';
import '../components/path_outlook.dart';
import '../components/world_label_chip.dart';

/// Beschriftung unter einer Kugel: der Label-Chip samt Rechteck.
class PathLabel {
  const PathLabel({
    required this.index,
    required this.rect,
    required this.text,
  });

  final int index;

  /// Rechteck des Chips (nicht nur des Textes).
  final Rect rect;
  final String text;
}

/// Lage Mannys neben der aktuellen Kugel.
class MannyPlacement {
  const MannyPlacement({required this.draw, required this.right});

  /// Die gezeichnete Form (ohne Trefferrand).
  final Rect draw;

  /// Manny steht rechts von der Kugel (sonst links).
  final bool right;
}

class MannyPerch {
  const MannyPerch._();

  /// Abstand der Fußunterkante (Standlinie) von der Oberkante der Zeichnung.
  static double feetFromTop(double height) =>
      MannyIllustration.feetFromTop(height);

  /// Lage für eine Kugel mit [center] und [diameter] bei der Pfad-Breite
  /// [width]: rechts, wenn dort die Zeichnung samt Seitenrand Platz hat, sonst
  /// links. Die Füße stehen auf der Unterkante der Kugel.
  static MannyPlacement place({
    required math.Point<double> center,
    required double diameter,
    required double width,
    double height = CuraSize.mannyPathHeight,
  }) {
    final Size size = MannyIllustration.sizeFor(MannyCrop.full, height);
    final double baseline = center.y + diameter / 2;
    final double top = baseline - feetFromTop(height);
    final double rightLeft = center.x + diameter / 2 + CuraSize.mannyBesideGap;
    final bool right =
        rightLeft + size.width <= width - CuraSpace.pageMargin + 0.01;
    final double left = right
        ? rightLeft
        : center.x - diameter / 2 - CuraSize.mannyBesideGap - size.width;
    return MannyPlacement(
      draw: Rect.fromLTWH(left, top, size.width, size.height),
      right: right,
    );
  }

  /// Wie weit Manny über die Kugel hinausragt (nach oben): die Zeichnung
  /// beginnt nie höher als die Kugel (Abstand der Kugeln unverändert).
  static double aboveUnit(
    double diameter, [
    double height = CuraSize.mannyPathHeight,
  ]) => math.max(0, feetFromTop(height) - diameter);
}

class PathView extends StatelessWidget {
  const PathView({
    super.key,
    required this.layout,
    required this.progress,
    required this.width,
    required this.labels,
    required this.mannyPose,
    required this.onUnitPressed,
    required this.onMannyTap,
    required this.onOutlookPressed,
    this.pulseUnitId,
    this.onPulseDone,
  });

  final PathLayout layout;
  final PathProgress progress;
  final double width;
  final List<PathLabel> labels;
  final MannyPose mannyPose;
  final void Function(int index) onUnitPressed;
  final VoidCallback onMannyTap;

  /// Tipp auf den Ausblick (Ergänzung 3): zeigt dessen `NodeHint`.
  final VoidCallback onOutlookPressed;
  final String? pulseUnitId;
  final VoidCallback? onPulseDone;

  static OrbKind orbKindOf(UnitKind kind) => switch (kind) {
    UnitKind.trainingDay => OrbKind.day,
    UnitKind.weekGoal => OrbKind.weekGoal,
    UnitKind.phaseEnd => OrbKind.phaseEnd,
    UnitKind.boss => OrbKind.boss,
  };

  static OrbState orbStateOf(UnitStatus status) => switch (status) {
    UnitStatus.done => OrbState.done,
    UnitStatus.current => OrbState.current,
    UnitStatus.locked => OrbState.locked,
  };

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final WorldPalette world = WorldScope.paletteOf(context);
    final int n = progress.units.length;
    final Map<int, PathLabel> labelOf = <int, PathLabel>{
      for (final PathLabel l in labels) l.index: l,
    };
    // Die Linie liegt auf der Welt: `nav-ink` der Welt (dunkel am Tag, hell in
    // der Nacht), künftige Strecken schwächer; Hoher Kontrast `text-1`.
    final Color line = colors.highContrast ? colors.text1 : world.navInk;
    final List<Widget> children = <Widget>[
      Positioned.fill(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _PathLinesPainter(
                layout: layout,
                statuses: progress.statuses,
                labelRects: <Rect>[for (final PathLabel l in labels) l.rect],
                doneColor: line,
                futureColor: line.withValues(
                  alpha: WorldGeometry.pathLineFutureAlpha,
                ),
              ),
            ),
          ),
        ),
      ),
    ];
    // Der Ausblick ist das oberste Element: zuerst in Lese- und Fokus-
    // reihenfolge, dann der Boss und die übrigen Kugeln von oben nach unten.
    final OutlookPlacement? outlook = layout.outlook;
    if (outlook != null) {
      children.add(
        Positioned(
          left: outlook.left,
          top: outlook.top,
          width: outlook.width,
          child: PathOutlook(
            key: const ValueKey<String>('outlook'),
            onPressed: onOutlookPressed,
          ),
        ),
      );
    }
    for (int i = n - 1; i >= 0; i--) {
      final PathUnit unit = progress.units[i];
      final NodePlacement p = layout.placements[i];
      final UnitStatus status = progress.statuses[i];
      final Rect box = Rect.fromCenter(
        center: Offset(p.center.x, p.center.y),
        width: p.diameter,
        height: p.diameter,
      );
      children.add(
        Positioned(
          left: box.left,
          top: box.top,
          width: box.width,
          height: box.height,
          child: OrbNode(
            key: ValueKey<String>('unit:${unit.id}'),
            kind: orbKindOf(unit.kind),
            state: orbStateOf(status),
            semanticLabel: unitSemanticsLabel(unit, status),
            onPressed: () => onUnitPressed(i),
            pulse: unit.id == pulseUnitId,
            onPulseDone: onPulseDone,
          ),
        ),
      );
      final PathLabel? label = labelOf[i];
      if (label != null) {
        children.add(
          Positioned(
            left: label.rect.left,
            top: label.rect.top,
            child: ExcludeSemantics(child: WorldLabelChip(label.text)),
          ),
        );
      }
      if (i == progress.mannyIndex) {
        children.add(_manny(p));
      }
    }
    return SizedBox(
      width: width,
      height: layout.totalHeight,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  Widget _manny(NodePlacement p) {
    final Rect draw = MannyPerch.place(
      center: p.center,
      diameter: p.diameter,
      width: width,
    ).draw;
    final EdgeInsets insets = MannyIllustration.tapInsets(draw.size);
    return Positioned(
      left: draw.left - insets.left,
      top: draw.top - insets.top,
      child: MannyIllustration(
        key: const ValueKey<String>('path-manny'),
        height: CuraSize.mannyPathHeight,
        pose: mannyPose,
        onTap: onMannyTap,
        onWorld: true,
      ),
    );
  }
}

/// Zeichnet die Verbindungen: erreichte Strecken durchgezogen (3 dp, runde
/// Enden), zukünftige gepunktet. Die Linien laufen um die Kugeln und die
/// Label-Chips herum (die Kugeln sind teils durchscheinend, dahinter darf keine
/// Linie stehen).
class _PathLinesPainter extends CustomPainter {
  _PathLinesPainter({
    required this.layout,
    required this.statuses,
    required this.labelRects,
    required this.doneColor,
    required this.futureColor,
  });

  final PathLayout layout;
  final List<UnitStatus> statuses;
  final List<Rect> labelRects;
  final Color doneColor;
  final Color futureColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Path hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final NodePlacement p in layout.placements) {
      hole.addOval(
        Rect.fromCircle(
          center: Offset(p.center.x, p.center.y),
          radius: p.diameter / 2 + CuraSize.pathLineClipUnit,
        ),
      );
    }
    for (final Rect r in labelRects) {
      hole.addRect(r.inflate(CuraSize.pathLineClipLabel));
    }
    final OutlookPlacement? outlook = layout.outlook;
    if (outlook != null) {
      hole.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            outlook.left,
            outlook.top,
            outlook.right,
            outlook.bottom,
          ).inflate(CuraSize.pathLineClipUnit),
          const Radius.circular(CuraRadius.card + CuraSize.pathLineClipUnit),
        ),
      );
    }
    canvas.clipPath(hole);

    final Paint solid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = CuraSize.pathLine
      ..strokeCap = StrokeCap.round
      ..color = doneColor;
    final Paint dot = Paint()
      ..style = PaintingStyle.fill
      ..color = futureColor;
    for (final PathSegment s in layout.segments) {
      final Path path = Path()
        ..moveTo(s.start.x, s.start.y)
        ..cubicTo(
          s.control1.x,
          s.control1.y,
          s.control2.x,
          s.control2.y,
          s.end.x,
          s.end.y,
        );
      // Erreicht: die obere Unit der Strecke ist erledigt oder aktuell.
      if (statuses[s.to] != UnitStatus.locked) {
        canvas.drawPath(path, solid);
      } else {
        _dots(canvas, path, dot);
      }
    }
    // Vom Boss weiter zur Unterkante des Ausblicks (Mitte), dort Ende. Der
    // Ausblick ist immer gesperrt, die Linie also immer gepunktet.
    final PathSegment? out = layout.outlookSegment;
    if (out != null) {
      _dots(
        canvas,
        Path()
          ..moveTo(out.start.x, out.start.y)
          ..cubicTo(
            out.control1.x,
            out.control1.y,
            out.control2.x,
            out.control2.y,
            out.end.x,
            out.end.y,
          ),
        dot,
      );
    }
  }

  void _dots(Canvas canvas, Path path, Paint dot) {
    for (final PathMetric m in path.computeMetrics()) {
      for (double d = 0; d <= m.length; d += CuraSize.pathDotSpacing) {
        final Tangent? t = m.getTangentForOffset(d);
        if (t != null) {
          canvas.drawCircle(t.position, CuraSize.pathLine / 2, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PathLinesPainter old) {
    if (old.doneColor != doneColor ||
        old.futureColor != futureColor ||
        old.layout.totalHeight != layout.totalHeight ||
        old.layout.placements.length != layout.placements.length ||
        old.statuses.length != statuses.length ||
        old.labelRects.length != labelRects.length) {
      return true;
    }
    for (int i = 0; i < statuses.length; i++) {
      if (old.statuses[i] != statuses[i]) return true;
    }
    for (int i = 0; i < layout.placements.length; i++) {
      final NodePlacement a = old.layout.placements[i];
      final NodePlacement b = layout.placements[i];
      if (a.center != b.center || a.diameter != b.diameter) return true;
    }
    for (int i = 0; i < labelRects.length; i++) {
      if (old.labelRects[i] != labelRects[i]) return true;
    }
    final OutlookPlacement? a = old.layout.outlook;
    final OutlookPlacement? b = layout.outlook;
    if ((a == null) != (b == null)) return true;
    if (a != null &&
        b != null &&
        (a.center != b.center || a.width != b.width || a.height != b.height)) {
      return true;
    }
    return false;
  }
}
