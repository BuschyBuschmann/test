// Kreis-Button der Button-Gruppe (Ergänzung 2, Abschnitt 2): `surface-opaque`,
// Rand 1,5 dp `border-control` (Hoher Kontrast `-hc`), Schatten 0/6/16
// Schwarz 40 % (bleibt bei Hoher Kontrast), **kein Blur, kein Glow, kein
// Akzent-Ring**. Pressed: Überlagerung Weiß 10 %. Fokus: `focus-ring`.
// Gemeinsame Basis von `MannyChatButton` und `MessagesButton`.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import 'cura_pressable.dart';

class ActionCircle extends StatelessWidget {
  const ActionCircle({
    super.key,
    required this.diameter,
    required this.label,
    required this.onPressed,
    required this.child,
    this.autofocus = false,
    this.focusNode,
  });

  final double diameter;

  /// Tooltip und Screenreader-Label.
  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: label,
      tooltip: label,
      autofocus: autofocus,
      focusNode: focusNode,
      builder: (BuildContext context, bool pressed) {
        return SizedBox.square(
          dimension: diameter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceOpaque,
              border: Border.all(
                color: colors.controlBorder,
                width: CuraSize.controlBorder,
              ),
              boxShadow: CuraShadow.actionButton,
            ),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pressed ? colors.pressedOverlay : null,
              ),
              child: Center(child: child),
            ),
          ),
        );
      },
    );
  }
}
