// `PathView` (Plan 3, 9): der scrollende Inhalt des Pfads: Linien (ein
// `CustomPainter`, für den Screenreader ausgeblendet), die Units als Widgets
// (von oben nach unten: Lese- und Fokusreihenfolge), die Beschriftungen unter
// mittleren, großen und Boss-Units, und Manny auf seiner Unit.
//
// Z-Reihenfolge: Linien unten, Units, dann Manny **direkt hinter seiner
// Unit**: er liegt über ihr und über allem, was darunter folgt, und kommt so
// in der Lesereihenfolge an der richtigen Stelle. Manny nimmt nur Tipps auf
// seiner Form (plus 8 dp Rand, bis zur Standlinie) an; was die Form nicht
// trifft, fällt auf die Unit darunter durch (UI-59, UI-74).
import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';

import '../../logic/path_generator.dart';
import '../../logic/path_layout.dart';
import '../../logic/path_model.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../components/manny.dart';
import '../components/path_node.dart';

/// Beschriftung unter einer Unit (`caption`, `text-3`).
class PathLabel {
  const PathLabel({
    required this.index,
    required this.rect,
    required this.text,
  });

  final int index;
  final Rect rect;
  final String text;
}

/// Zeichenfläche und Lage Mannys auf einer Unit.
class MannyPerch {
  const MannyPerch._();

  /// Abstand der Fußunterkante (Standlinie) von der Oberkante der Zeichnung.
  static double feetFromTop(double height) =>
      height * MannyGeometry.baseline / MannyGeometry.height;

  /// Die gezeichnete Form (ohne Trefferrand) für eine Unit mit [center] und
  /// [diameter]: Füße auf dem oberen Rand des Kreises.
  static Rect drawRect({
    required math.Point<double> center,
    required double diameter,
    double height = CuraSize.mannyPathHeight,
  }) {
    final Size size = MannyPlaceholder.sizeFor(MannyCrop.full, height);
    final double baseline =
        center.y - diameter / 2 + CuraSize.mannyPerchOverlap;
    return Rect.fromLTWH(
      center.x - size.width / 2,
      baseline - feetFromTop(height),
      size.width,
      size.height,
    );
  }

  /// Wie weit Manny über den Kreis hinausragt (für den Abstand der Units).
  static double aboveUnit([double height = CuraSize.mannyPathHeight]) =>
      feetFromTop(height) - CuraSize.mannyPerchOverlap;
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
  final String? pulseUnitId;
  final VoidCallback? onPulseDone;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final int n = progress.units.length;
    final Map<int, PathLabel> labelOf = <int, PathLabel>{
      for (final PathLabel l in labels) l.index: l,
    };
    final List<Widget> children = <Widget>[
      Positioned.fill(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _PathLinesPainter(
                layout: layout,
                statuses: progress.statuses,
                labelRects: <Rect>[for (final PathLabel l in labels) l.rect],
                doneColor: colors.text1,
                futureColor: colors.futureLine,
              ),
            ),
          ),
        ),
      ),
    ];
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
          child: PathNode(
            key: ValueKey<String>('unit:${unit.id}'),
            unit: unit,
            status: status,
            diameter: p.diameter,
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
            width: label.rect.width,
            child: ExcludeSemantics(
              child: Text(
                label.text,
                textAlign: TextAlign.center,
                style: type.caption.copyWith(color: colors.text3),
              ),
            ),
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
    final Rect draw = MannyPerch.drawRect(
      center: p.center,
      diameter: p.diameter,
    );
    final EdgeInsets insets = MannyPlaceholder.tapInsets(draw.size);
    return Positioned(
      left: draw.left - insets.left,
      top: draw.top - insets.top,
      child: MannyPlaceholder(
        key: const ValueKey<String>('path-manny'),
        height: CuraSize.mannyPathHeight,
        pose: mannyPose,
        onTap: onMannyTap,
      ),
    );
  }
}

/// Zeichnet die Verbindungen: erreichte Strecken hell und durchgezogen
/// (`text-1`, 3 dp, runde Enden), zukünftige gepunktet (Weiß 22 %, 3 dp). Die
/// Linien laufen um die Units und die Beschriftungen herum (die gesperrten
/// Units sind durchscheinend, dahinter darf keine Linie stehen).
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
        for (final PathMetric m in path.computeMetrics()) {
          for (double d = 0; d <= m.length; d += CuraSize.pathDotSpacing) {
            final Tangent? t = m.getTangentForOffset(d);
            if (t != null) {
              canvas.drawCircle(t.position, CuraSize.pathLine / 2, dot);
            }
          }
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
    return false;
  }
}
