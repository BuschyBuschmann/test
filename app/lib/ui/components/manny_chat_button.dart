// `MannyButton` (Design-Brief v2, 5 und Ergänzung 1, 6.4): der Manny-Knopf.
// Kreis 56 dp (Hit-Area 56), Kopf (`kopf.png` der gewählten Variante, 86 % =
// ca. 48 dp, nie unter 40 dp) auf **Glas Weiß 78 %** wie die Leiste im Zustand
// Aktiv, auch in der Welt Nacht. Eine der drei zulässigen Blur-Flächen (Leiste,
// Kopf-Karte, Manny-Knopf) über `CuraBlur`. Hoher Kontrast/Transparenz
// reduzieren: opake helle Scheibe, kein Blur. Tooltip und Screenreader „Manny,
// Chat öffnen“; das Bild darin ist ausgeblendet (V2-71). Pressed: Überlagerung
// 10 %. Fokus: `focus-ring`.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import 'cura_blur.dart';
import 'cura_pressable.dart';
import 'manny.dart';

class MannyButton extends StatelessWidget {
  const MannyButton({
    super.key,
    required this.onPressed,
    this.autofocus = false,
    this.focusNode,
  });

  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    const double d = CuraSize.mannyChatButton;
    final BorderRadius shape = BorderRadius.circular(CuraRadius.pill);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: S.mannyChatOpen,
      tooltip: S.mannyChatOpen,
      autofocus: autofocus,
      focusNode: focusNode,
      ringRadius: CuraRadius.pill,
      builder: (BuildContext context, bool pressed) {
        return SizedBox.square(
          dimension: d,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: CuraShadow.actionButton,
            ),
            child: CuraBlur(
              borderRadius: shape,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.mannyButtonGlass,
                  border: Border.all(
                    color: colors.highContrast
                        ? colors.lightSurfaceBorder
                        : colors.lightEdge,
                    width: colors.highContrast
                        ? CuraSize.controlBorder
                        : CuraSize.hairline,
                  ),
                ),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pressed ? colors.pressedOverlay : null,
                  ),
                  child: Center(
                    child: MannyIllustration(
                      height: MannyAvatar.headFor(d),
                      crop: MannyCrop.head,
                      excludeSemantics: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
