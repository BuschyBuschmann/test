// `WorldLabelChip` (Design-Brief v2, 3.1 `chip-world`): Label-Chip für
// Beschriftungen, die auf der Welt stehen (z. B. Pfad-Beschriftungen). Er ist
// neben Karte, Kopf-Karte, Leiste, Sheet und Dialog ein erlaubter Untergrund
// für Text (V2-5). Fläche und Textfarbe kommen aus der Welt (Deckkraft
// 72–74 %; Nacht `#1E1626` mit `#FFFFFF`, sonst Weiß mit `#211B16`); der
// Kontrast je Welt ist gemessen (Brief 3.1: 7,0 bis 9,1). Kein Blur.
// Hoher Kontrast: opak `card` mit Rand `border-control-hc`.
import 'package:flutter/material.dart';

import '../../state/world_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../../theme/world_tokens.dart';

class WorldLabelChip extends StatelessWidget {
  const WorldLabelChip(this.text, {super.key, this.semanticLabel});

  final String text;

  /// Screenreader-Text, wenn er vom sichtbaren Text abweicht.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final WorldPalette world = WorldScope.paletteOf(context);
    final bool hc = colors.highContrast;
    return Semantics(
      label: semanticLabel ?? text,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hc ? colors.surfaceOpaque : world.chip,
          borderRadius: BorderRadius.circular(CuraRadius.pill),
          border: hc
              ? Border.all(
                  color: colors.controlBorder,
                  width: CuraSize.controlBorder,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CuraSize.statPillPaddingH,
            vertical: CuraSize.statPillPaddingV,
          ),
          child: Text(
            text,
            style: type.chip.copyWith(
              color: hc ? colors.text1 : world.chipText,
            ),
          ),
        ),
      ),
    );
  }
}
