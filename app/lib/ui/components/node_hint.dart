// `NodeHint` (Ergänzung 1, 3.5, Plan 9): kleiner Hinweis an einer Pfad-Unit.
// Fläche `surface-opaque`, Rand `border-hair` (Hoher Kontrast
// `border-control-hc`), Radius 16, Innenabstand 12/16, Text `secondary`
// `text-1`, Pfeil 8 dp zur Unit. Breite höchstens min(240, Bildschirmbreite
// minus 32) (die Platzierung wählt die Breite), der Text bricht um. Keine
// Aktion, kein X, kein Blur. Erscheint mit Einblenden (`dur-fast`); bei
// reduzierter Bewegung sofort. Liest sich beim Erscheinen vor (Live-Region).
//
// Schließen (Tipp irgendwo, Scrollen, Escape/Zurück, Tabwechsel, nach 5 s,
// bei aktivem Screenreader nicht automatisch) liegt beim Besitzer
// (`PathScreen`); der Baustein selbst zeigt nur an.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';

/// Kante, an der der Pfeil sitzt, und Richtung, in die er zeigt.
enum HintArrow {
  /// Hinweis steht über der Unit: Pfeil an der Unterkante, zeigt nach unten.
  down,

  /// Hinweis steht unter der Unit: Pfeil an der Oberkante, zeigt nach oben.
  up,

  /// Hinweis steht links der Unit: Pfeil an der rechten Kante.
  right,

  /// Hinweis steht rechts der Unit: Pfeil an der linken Kante.
  left,
}

class NodeHint extends StatelessWidget {
  const NodeHint({
    super.key,
    required this.text,
    required this.arrow,
    required this.arrowCenter,
    this.maxBodyHeight,
  });

  final String text;
  final HintArrow arrow;

  /// Mitte des Pfeils entlang seiner Kante, gemessen vom Anfang der Kante des
  /// ganzen Hinweises (links bei `up`/`down`, oben bei `left`/`right`).
  final double arrowCenter;

  /// Höhe des Körpers (ohne Pfeil), wenn der Platz begrenzt ist: der Text
  /// scrollt dann innen. `null` = so hoch wie der Text.
  final double? maxBodyHeight;

  static const double _arrow = CuraSize.nodeHintArrow;
  static const double _base = CuraComponent.bubbleArrowBase;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final CuraMotion motion = CuraMotion.of(context);
    final BorderRadius shape = BorderRadius.circular(CuraRadius.nodeHint);

    Widget label = Text(
      text,
      style: type.secondary.copyWith(color: colors.text1),
    );
    if (maxBodyHeight != null) {
      label = SingleChildScrollView(child: label);
    }
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceOpaque,
        borderRadius: shape,
        border: Border.all(color: colors.cardBorder, width: CuraSize.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CuraSize.hintPaddingHorizontal,
          vertical: CuraSize.hintPaddingVertical,
        ),
        child: label,
      ),
    );
    if (maxBodyHeight != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxBodyHeight!),
        child: body,
      );
    }

    final bool vertical = arrow == HintArrow.down || arrow == HintArrow.up;
    final Widget arrowShape = ExcludeSemantics(
      child: CustomPaint(
        size: vertical ? const Size(_base, _arrow) : const Size(_arrow, _base),
        painter: _HintArrowPainter(
          direction: arrow,
          fill: colors.surfaceOpaque,
          border: colors.cardBorder,
        ),
      ),
    );
    // Pfeil: Anfang der Basis = Mitte minus halbe Basis.
    final double start = (arrowCenter - _base / 2).clamp(0, double.infinity);
    final Widget shaped = switch (arrow) {
      HintArrow.down => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(child: body),
          Padding(
            padding: EdgeInsets.only(left: start),
            child: arrowShape,
          ),
        ],
      ),
      HintArrow.up => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: start),
            child: arrowShape,
          ),
          Flexible(child: body),
        ],
      ),
      HintArrow.right => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(child: body),
          Padding(
            padding: EdgeInsets.only(top: start),
            child: arrowShape,
          ),
        ],
      ),
      HintArrow.left => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: start),
            child: arrowShape,
          ),
          Flexible(child: body),
        ],
      ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      label: text,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: motion.reduced ? 1 : 0, end: 1),
        duration: motion.reduced ? Duration.zero : MotionTokens.fast,
        curve: motion.curve,
        child: shaped,
        builder: (BuildContext context, double t, Widget? child) =>
            Opacity(opacity: t, child: child),
      ),
    );
  }
}

class _HintArrowPainter extends CustomPainter {
  const _HintArrowPainter({
    required this.direction,
    required this.fill,
    required this.border,
  });

  final HintArrow direction;
  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path();
    switch (direction) {
      case HintArrow.down:
        p
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0);
      case HintArrow.up:
        p
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height);
      case HintArrow.right:
        p
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height);
      case HintArrow.left:
        p
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height);
    }
    canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = CuraSize.hairline
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_HintArrowPainter old) =>
      old.direction != direction || old.fill != fill || old.border != border;
}
