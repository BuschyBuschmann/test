// `MannyBubble` (Brief 5.6, Plan 9): Sprechblase E2 mit `CuraBlur`
// (`surface-float`, Radius 20, Rand `border-hair`), Text `bubble` (14,5 sp),
// X-Button oben rechts (Hit-Area 48 dp), höchstens 280 dp breit, Live-Region,
// nicht modal. Platzierung: rechts neben Manny mit Pfeil nach links; bleiben
// rechts weniger als 140 dp, steht sie oberhalb von Manny (Pfeil nach unten),
// siehe [MannyBubble.arrowFor]. Einblenden plus 8 dp Schiebung (`dur-base`);
// bei reduzierter Bewegung höchstens `dur-fast` ohne Schiebung. Kein Schatten.
//
// Schließen: X, Tipp auf die Blase oder ein Tipp irgendwo ([TapAnywhereDismiss]
// um den Inhalt). Beides ruft `onClose`; der Besitzer behandelt `onClose`
// idempotent (die Blase zählt dann als gezeigt).
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import 'cura_blur.dart';
import 'cura_pressable.dart';

enum BubbleArrow { left, down }

class MannyBubble extends StatelessWidget {
  const MannyBubble({
    super.key,
    required this.text,
    required this.onClose,
    this.arrow = BubbleArrow.left,
    this.arrowOffset = CuraSpace.s6,
    this.maxBodyHeight,
  });

  final String text;
  final VoidCallback onClose;
  final BubbleArrow arrow;

  /// Abstand der Pfeilspitze vom Anfang der Blasenkante (oben bei `left`,
  /// links bei `down`), in dp.
  final double arrowOffset;

  /// Höhe des Körpers (ohne Pfeil), wenn der Platz begrenzt ist (Rückfall der
  /// Pfad-Platzierung, Plan 4.6): der Text scrollt dann innen. Ohne Wert so
  /// hoch wie der Text.
  final double? maxBodyHeight;

  /// Platzierung nach Brief 5.6: bleibt rechts neben Manny weniger als
  /// 140 dp, steht die Blase oberhalb.
  static BubbleArrow arrowFor(double spaceRight) =>
      spaceRight < CuraComponent.bubbleMinSideSpace
      ? BubbleArrow.down
      : BubbleArrow.left;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final CuraMotion motion = CuraMotion.of(context);
    final BorderRadius shape = BorderRadius.circular(CuraRadius.bubble);

    final Widget body = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: CuraComponent.bubbleMaxWidth,
        minHeight: CuraSize.touchTarget,
        maxHeight: maxBodyHeight ?? double.infinity,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onClose,
        child: CuraBlur(
          borderRadius: shape,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.floatFill,
              borderRadius: shape,
              border: Border.all(
                color: colors.cardBorder,
                width: CuraSize.hairline,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: CuraSize.bubblePaddingHorizontal,
                      top: CuraSize.bubblePaddingVertical,
                      bottom: CuraSize.bubblePaddingVertical,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: maxBodyHeight == null
                          ? Text(
                              text,
                              style: type.bubble.copyWith(color: colors.text1),
                            )
                          : SingleChildScrollView(
                              child: Text(
                                text,
                                style: type.bubble.copyWith(
                                  color: colors.text1,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                CuraPressable(
                  onPressed: onClose,
                  semanticLabel: S.bubbleClose,
                  tooltip: S.bubbleClose,
                  builder: (BuildContext context, bool pressed) {
                    return SizedBox.square(
                      dimension: CuraSize.touchTarget,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pressed ? colors.pressedOverlay : null,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: CuraComponent.iconSize,
                          color: colors.text2,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Widget arrowShape = ExcludeSemantics(
      child: CustomPaint(
        size: arrow == BubbleArrow.left
            ? const Size(
                CuraComponent.bubbleArrow,
                CuraComponent.bubbleArrowBase,
              )
            : const Size(
                CuraComponent.bubbleArrowBase,
                CuraComponent.bubbleArrow,
              ),
        painter: _ArrowPainter(
          direction: arrow,
          fill: colors.floatFill,
          border: colors.cardBorder,
        ),
      ),
    );

    final Widget shaped = switch (arrow) {
      BubbleArrow.left => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: arrowOffset),
            child: arrowShape,
          ),
          Flexible(child: body),
        ],
      ),
      BubbleArrow.down => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(child: body),
          Padding(
            padding: EdgeInsets.only(left: arrowOffset),
            child: arrowShape,
          ),
        ],
      ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: motion.duration(MotionTokens.base),
      curve: motion.curve,
      child: shaped,
      builder: (BuildContext context, double t, Widget? child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, motion.slide(MotionTokens.bubbleSlide) * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.direction,
    required this.fill,
    required this.border,
  });

  final BubbleArrow direction;
  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path();
    if (direction == BubbleArrow.left) {
      p
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height);
    } else {
      p
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
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
  bool shouldRepaint(_ArrowPainter old) =>
      old.direction != direction || old.fill != fill || old.border != border;
}

/// „Tipp irgendwo schließt“ (Plan 9): durchlässiger `Listener` um den Inhalt.
/// Ein Tipp (ohne Wischen über die Berührungstoleranz) ruft [onDismiss];
/// darunterliegende Elemente erhalten das Ereignis weiterhin (kein Absorbieren).
class TapAnywhereDismiss extends StatefulWidget {
  const TapAnywhereDismiss({
    super.key,
    required this.onDismiss,
    required this.child,
    this.enabled = true,
  });

  final VoidCallback onDismiss;
  final bool enabled;
  final Widget child;

  @override
  State<TapAnywhereDismiss> createState() => _TapAnywhereDismissState();
}

class _TapAnywhereDismissState extends State<TapAnywhereDismiss> {
  int? _pointer;
  Offset? _down;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent e) {
        if (!widget.enabled || _pointer != null) return;
        _pointer = e.pointer;
        _down = e.position;
      },
      onPointerUp: (PointerUpEvent e) {
        if (e.pointer != _pointer) return;
        final bool tap = (e.position - _down!).distance <= kTouchSlop;
        _pointer = null;
        _down = null;
        if (tap && widget.enabled) widget.onDismiss();
      },
      onPointerCancel: (PointerCancelEvent e) {
        if (e.pointer == _pointer) {
          _pointer = null;
          _down = null;
        }
      },
      child: widget.child,
    );
  }
}
