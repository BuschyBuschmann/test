// `MannyPlaceholder` (Brief 5.6, Plan 9): Manny als `CustomPainter` aus
// Flutter-Formen. Körper `#34425F` mit Rand Weiß 35 % (1 dp), Flügel, weißer
// Bauch, zwei Augen, Schnabel und Füße in `accent-hi`. Drei statische Posen
// (`neutral`, `motiviert`, `feiernd`), eine Zeichnung für beide Zuschnitte
// (`crop: full | head`, Kopf für Manny-Button und Chat-Emblem). Eine spätere
// Illustration ersetzt nur dieses Widget. Keine Animation (Regel 9).
//
// Die Geometrie liegt in einer Zeichenfläche von 100 × 120 Einheiten
// (Standlinie bei y = 118); diese Datei ist von Regel 2 ausgenommen
// (Painter-Geometrie).
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../l10n/strings_de.dart';
import '../../logic/manny_occasions.dart' show MannyPose;
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';

export '../../logic/manny_occasions.dart' show MannyPose;

enum MannyCrop { full, head }

/// Ein Flügel: gedrehte Ellipse in Zeichenflächen-Einheiten.
class MannyWing {
  const MannyWing(this.cx, this.cy, this.rx, this.ry, this.angle);

  final double cx;
  final double cy;
  final double rx;
  final double ry;

  /// Drehung im Uhrzeigersinn in Bogenmaß.
  final double angle;

  Path path([double grow = 0]) {
    final Path p = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: (rx + grow) * 2,
          height: (ry + grow) * 2,
        ),
      );
    final Matrix4 m = Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..rotateZ(angle)
      ..translateByDouble(-cx, -cy, 0, 1);
    return p.transform(m.storage);
  }
}

/// Geometrie in Zeichenflächen-Einheiten.
abstract final class MannyGeometry {
  static const double width = 100;
  static const double height = 120;
  static const double baseline = 118;

  /// Zuschnitt „Kopf“: Quadrat um Kopf und Schnabel.
  static const Rect headRect = Rect.fromLTWH(16, 14, 68, 68);
  static const Rect fullRect = Rect.fromLTWH(0, 0, width, height);

  static const Rect body = Rect.fromLTRB(16, 22, 84, 114);
  static const Rect belly = Rect.fromLTRB(28, 60, 72, 112);
  static const Rect footLeft = Rect.fromLTRB(27, 108, 46, baseline);
  static const Rect footRight = Rect.fromLTRB(54, 108, 73, baseline);
  static const double footRadius = 5;

  static Rect cropRect(MannyCrop crop) =>
      crop == MannyCrop.head ? headRect : fullRect;

  static List<MannyWing> wings(MannyPose pose) {
    switch (pose) {
      case MannyPose.neutral:
        return const <MannyWing>[
          MannyWing(14, 72, 8, 24, 0.2),
          MannyWing(86, 72, 8, 24, -0.2),
        ];
      case MannyPose.motiviert:
        return const <MannyWing>[
          MannyWing(14, 72, 8, 24, 0.2),
          MannyWing(87, 54, 8, 23, 0.55),
        ];
      case MannyPose.feiernd:
        return const <MannyWing>[
          MannyWing(13, 52, 8, 24, -0.6),
          MannyWing(87, 52, 8, 24, 0.6),
        ];
    }
  }
}

class MannyPlaceholder extends StatefulWidget {
  const MannyPlaceholder({
    super.key,
    required this.height,
    this.pose = MannyPose.neutral,
    this.crop = MannyCrop.full,
    this.onTap,
    this.excludeSemantics = false,
  });

  /// Höhe in dp (Pfad ca. 80, Onboarding 56–64, Kopf im Button 38).
  final double height;
  final MannyPose pose;
  final MannyCrop crop;

  /// Nur auf dem Pfad gesetzt: Tipp auf die Form (plus 8 dp Rand, bis zur
  /// Standlinie) öffnet den Chat. Ohne Wert ist Manny nicht antippbar
  /// (`IgnorePointer`). Manny hat nie eine eigene Fokusstation (Plan 4.6).
  final VoidCallback? onTap;

  /// Bild-Label ausblenden (Manny-Button und Emblem tragen ihr eigenes Label).
  final bool excludeSemantics;

  /// Größe in dp für eine Höhe.
  static Size sizeFor(MannyCrop crop, double height) {
    final Rect r = MannyGeometry.cropRect(crop);
    return Size(height * r.width / r.height, height);
  }

  /// Trefferfläche: gezeichnete Form plus [margin] (Plan: 8 dp), mindestens
  /// [minSide] × [minSide], unten an der Standlinie (Fußunterkante)
  /// abgeschnitten. Koordinaten wie das Widget (Ursprung oben links).
  static Path hitPath({
    required Size size,
    required MannyPose pose,
    MannyCrop crop = MannyCrop.full,
    double margin = CuraSize.mannyHitMargin,
    double minSide = CuraSize.touchTarget,
  }) {
    final Rect view = MannyGeometry.cropRect(crop);
    final double s = size.height / view.height;
    final double g = margin / s; // Rand in Einheiten
    final List<Path> parts = <Path>[
      Path()..addOval(MannyGeometry.body.inflate(g)),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          MannyGeometry.footLeft.inflate(g),
          Radius.circular(MannyGeometry.footRadius + g),
        ),
      ),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          MannyGeometry.footRight.inflate(g),
          Radius.circular(MannyGeometry.footRadius + g),
        ),
      ),
      for (final MannyWing w in MannyGeometry.wings(pose)) w.path(g),
    ];
    Path union = parts.first;
    for (final Path p in parts.skip(1)) {
      union = Path.combine(PathOperation.union, union, p);
    }
    final Matrix4 toLocal = Matrix4.identity()
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-view.left, -view.top, 0, 1);
    Path local = union.transform(toLocal.storage);

    final double baseY = (MannyGeometry.baseline - view.top) * s;
    final Rect minRect = Rect.fromCenter(
      center: Offset(size.width / 2, baseY - minSide / 2),
      width: minSide,
      height: minSide,
    );
    local = Path.combine(PathOperation.union, local, Path()..addRect(minRect));
    final Path clip = Path()..addRect(Rect.fromLTRB(0, 0, size.width, baseY));
    return Path.combine(PathOperation.intersect, local, clip);
  }

  @override
  State<MannyPlaceholder> createState() => _MannyPlaceholderState();
}

class _MannyPlaceholderState extends State<MannyPlaceholder> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final Size size = MannyPlaceholder.sizeFor(widget.crop, widget.height);
    final bool tappable = widget.onTap != null;
    Widget art = CustomPaint(
      size: size,
      painter: _MannyPainter(
        colors: colors,
        pose: widget.pose,
        crop: widget.crop,
        size: size,
        pressed: _pressed && tappable,
        hit: tappable,
      ),
    );
    if (tappable) {
      art = ExcludeFocus(
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          excludeFromSemantics: true,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          child: art,
        ),
      );
    } else {
      art = IgnorePointer(child: art);
    }
    if (widget.excludeSemantics) return ExcludeSemantics(child: art);
    return Semantics(label: S.mannyImageLabel, image: true, child: art);
  }
}

class _MannyPainter extends CustomPainter {
  _MannyPainter({
    required this.colors,
    required this.pose,
    required this.crop,
    required this.size,
    required this.pressed,
    required this.hit,
  });

  final CuraColors colors;
  final MannyPose pose;
  final MannyCrop crop;
  final Size size;
  final bool pressed;
  final bool hit;

  Path? _hitPath;

  Path get _path =>
      _hitPath ??= MannyPlaceholder.hitPath(size: size, pose: pose, crop: crop);

  @override
  bool? hitTest(Offset position) => hit ? _path.contains(position) : false;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect view = MannyGeometry.cropRect(crop);
    final double s = size.height / view.height;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(s);
    canvas.translate(-view.left, -view.top);

    final double hair = CuraSize.hairline / s;
    final Paint fill = Paint()..style = PaintingStyle.fill;
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair
      ..color = colors.mannyOutline;

    // Füße (hinter dem Körper).
    for (final Rect foot in <Rect>[
      MannyGeometry.footLeft,
      MannyGeometry.footRight,
    ]) {
      final RRect r = RRect.fromRectAndRadius(
        foot,
        const Radius.circular(MannyGeometry.footRadius),
      );
      canvas.drawRRect(r, fill..color = colors.accentHi);
    }

    // Flügel und Körper.
    final List<MannyWing> wings = MannyGeometry.wings(pose);
    for (final MannyWing w in wings) {
      canvas.drawPath(w.path(), fill..color = colors.mannyBody);
      canvas.drawPath(w.path(), line);
    }
    canvas.drawOval(MannyGeometry.body, fill..color = colors.mannyBody);
    canvas.drawOval(MannyGeometry.body, line);

    // Bauch.
    canvas.drawOval(MannyGeometry.belly, fill..color = colors.mannyBelly);

    // Augen.
    const Offset eyeL = Offset(40, 40);
    const Offset eyeR = Offset(60, 40);
    if (pose == MannyPose.feiernd) {
      final Paint arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = colors.mannyBelly;
      for (final Offset c in <Offset>[eyeL, eyeR]) {
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(0, 3), width: 12, height: 10),
          math.pi,
          math.pi,
          false,
          arc,
        );
      }
    } else {
      final Offset look = pose == MannyPose.motiviert
          ? const Offset(1.5, -1.5)
          : const Offset(1, 1);
      for (final Offset c in <Offset>[eyeL, eyeR]) {
        canvas.drawCircle(c, 7, fill..color = colors.mannyBelly);
        canvas.drawCircle(c + look, 3.2, fill..color = colors.bg);
      }
    }

    // Schnabel.
    final double open = pose == MannyPose.feiernd ? 2 : 0;
    final Path beak = Path()
      ..moveTo(43 - open, 49)
      ..lineTo(57 + open, 49)
      ..lineTo(50, 58 + open)
      ..close();
    canvas.drawPath(beak, fill..color = colors.accentHi);

    // Pressed: Form 10 % heller (keine Animation, keine Pose-Änderung).
    if (pressed) {
      final Paint overlay = Paint()..color = colors.pressedOverlay;
      canvas.drawOval(MannyGeometry.body, overlay);
      for (final MannyWing w in wings) {
        canvas.drawPath(w.path(), overlay);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MannyPainter old) =>
      old.colors != colors ||
      old.pose != pose ||
      old.crop != crop ||
      old.size != size ||
      old.pressed != pressed ||
      old.hit != hit;
}
