// `HeaderIconButton` (Ergänzung 1, Abschnitt 2): 48 × 48 dp Hit-Area, Icon
// 24 dp `text-2`, Fläche transparent, Pressed: Kreis Weiß 10 %. Hoher
// Kontrast: zusätzlich Kreisrand `border-control-hc`. Tooltip bei
// Langdruck/Hover; der Screenreader liest den Tooltip-Text als Label.
// Auf der Kopf-Karte (`onHeaderCard`) steht das Symbol in `#FFFFFF` auf dem
// Glas der Welt, der Kreis zeigt beim Drücken Weiß 18 %.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import 'cura_pressable.dart';

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.onHeaderCard = false,
  });

  final IconData icon;

  /// Der Knopf sitzt auf der Kopf-Karte (weißes Symbol statt `text-2`).
  final bool onHeaderCard;

  /// Tooltip und Screenreader-Label (z. B. „Deine Daten“).
  final String tooltip;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: tooltip,
      tooltip: tooltip,
      autofocus: autofocus,
      focusNode: focusNode,
      builder: (BuildContext context, bool pressed) {
        return SizedBox.square(
          dimension: CuraSize.touchTarget,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed
                  ? (onHeaderCard ? colors.headerEdge : colors.pressedOverlay)
                  : null,
              border: colors.highContrast
                  ? Border.all(
                      color: onHeaderCard
                          ? colors.headerInk
                          : colors.controlBorder,
                      width: CuraSize.controlBorder,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              size: CuraComponent.iconSize,
              color: onHeaderCard ? colors.headerInk : colors.text2,
            ),
          ),
        );
      },
    );
  }
}
