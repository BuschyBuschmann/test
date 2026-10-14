// `CuraChip` (Brief v2, 4 und 3.2): Aktionschip „Tauschen“ / „Entfernen“.
// 13 sp/700 (Stil `chip`), Radius Pille, Füllung `chip-neutral` (`ink-1` 7 % auf
// der Karte, im Thema Dunkel Weiß 10 %), Text und Icon `text-1`, 36 dp sichtbar,
// Hit-Area 48 dp. Pressed: Überlagerung 10 %. Hoher Kontrast: zusätzlich Rand
// `border-control-hc` (die Füllung allein trägt dort keine erkennbare Fläche).
// Neutrale Farben: ein Chip ist eine Handlung (Löschen-ähnliche Aktionen nie in
// Warnfarben, Brief Abschnitt 4). Statusanzeigen siehe `StatusChip`.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';

class CuraChip extends StatelessWidget {
  const CuraChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.focusNode,
  });

  /// Sichtbarer Text („Tauschen“).
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Screenreader-Label („Kniebeuge am Stuhl tauschen“); sonst [label].
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? label,
      focusNode: focusNode,
      ringRadius: CuraRadius.pill,
      builder: (BuildContext context, bool pressed) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: CuraSize.touchTarget,
            minHeight: CuraSize.touchTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.chipFill,
                borderRadius: BorderRadius.circular(CuraRadius.pill),
                border: colors.highContrast
                    ? Border.all(
                        color: colors.controlBorder,
                        width: CuraSize.controlBorder,
                      )
                    : null,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: pressed ? colors.pressedOverlay : null,
                  borderRadius: BorderRadius.circular(CuraRadius.pill),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: CuraSize.chipVisibleHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CuraSpace.s3,
                      vertical: CuraSpace.s1,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ExcludeSemantics(
                          child: Icon(
                            icon,
                            size: CuraSize.hintIcon,
                            color: colors.text1,
                          ),
                        ),
                        const SizedBox(width: CuraSpace.s2),
                        Flexible(
                          child: Text(
                            label,
                            style: type.chip.copyWith(color: colors.text1),
                          ),
                        ),
                      ],
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
