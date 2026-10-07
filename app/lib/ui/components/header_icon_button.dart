// `HeaderIconButton` (Ergänzung 1, Abschnitt 2): 48 × 48 dp Hit-Area, Icon
// 24 dp `text-2`, Fläche transparent, Pressed: Kreis Weiß 10 %. Hoher
// Kontrast: zusätzlich Kreisrand `border-control-hc`. Tooltip bei
// Langdruck/Hover; der Screenreader liest den Tooltip-Text als Label.
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
  });

  final IconData icon;

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
              color: pressed ? colors.pressedOverlay : null,
              border: colors.highContrast
                  ? Border.all(
                      color: colors.controlBorder,
                      width: CuraSize.controlBorder,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              size: CuraComponent.iconSize,
              color: colors.text2,
            ),
          ),
        );
      },
    );
  }
}
