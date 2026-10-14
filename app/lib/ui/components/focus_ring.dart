// `FocusRing` (Brief v2 3.2): `focus-ring` 3 dp (`ink-1`/`text-1`) mit 2 dp
// Außenrand in der Gegenfarbe (`focusRingOuter`), 2 dp Abstand um das
// fokussierte Element. Zeichnet nur, wenn [focused] gesetzt ist; die
// Fokuserkennung (Tastatur/Switch) liegt in `CuraPressable`.
import 'package:flutter/widgets.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';

class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.focused,
    required this.child,
    this.radius = CuraRadius.pill,
  });

  /// Ring sichtbar.
  final bool focused;

  /// Eckenradius des umrahmten Elements (Kreis/Pill: Standard).
  final double radius;

  final Widget child;

  /// Abstand der Ringkante zum Element.
  static const double outset = CuraSize.focusRingGap + CuraSize.focusRingWidth;

  /// Abstand der Außenkante des Außenrandes zum Element.
  static const double outsetOuter = outset + CuraSize.focusRingOuterWidth;

  @override
  Widget build(BuildContext context) {
    if (!focused) return child;
    final CuraColors colors = CuraColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        Positioned(
          left: -outsetOuter,
          top: -outsetOuter,
          right: -outsetOuter,
          bottom: -outsetOuter,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius + outsetOuter),
                  border: Border.all(
                    color: colors.focusRingOuter,
                    width: CuraSize.focusRingOuterWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -outset,
          top: -outset,
          right: -outset,
          bottom: -outset,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius + outset),
                  border: Border.all(
                    color: colors.focusRing,
                    width: CuraSize.focusRingWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
