// `MicButton` (Brief 5.9): 56 dp Kreis, Glas, Rand `border-control`,
// Mikrofon-Icon `text-1`. Platzhalter: Antippen löst die Aktion des
// Besitzers aus (Manny-Hinweis „noch nicht verfügbar“). Screenreader:
// „Spracheingabe, noch nicht verfügbar“.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import 'cura_pressable.dart';
import 'glass_card.dart';

class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.onPressed,
    this.autofocus = false,
    this.focusNode,
  });

  final VoidCallback onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: S.micUnavailable,
      tooltip: S.micUnavailable,
      autofocus: autofocus,
      focusNode: focusNode,
      builder: (BuildContext context, bool pressed) {
        return SizedBox.square(
          dimension: CuraSize.micButton,
          child: GlassCard(
            padding: EdgeInsets.zero,
            radius: CuraRadius.pill,
            lightEdge: false,
            borderColor: colors.controlBorder,
            borderWidth: CuraSize.controlBorder,
            overlay: pressed ? colors.pressedOverlay : null,
            child: Center(
              child: Icon(
                Icons.mic_none_rounded,
                size: CuraComponent.iconSize,
                color: colors.text1,
              ),
            ),
          ),
        );
      },
    );
  }
}
