// `ChatAvatar` (Ergänzung 2, 3.3, 3.4): Kreis mit Initialen, Füllung
// `surface-opaque`, Ring 2 dp. Das Bild ist dekorativ (der Name steht daneben
// als Text und im Label der Zeile); die Kategorie wird zusätzlich als Text
// getragen, Farbe ist nie das einzige Signal. Hoher Kontrast: Ring
// `border-control-hc`. Die Initialen skalieren bis 130 % mit (wie die
// Nav-Beschriftung), damit sie im festen Kreis nicht abgeschnitten werden.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.initials,
    required this.ringColor,
    this.size = CuraSize.avatar,
  });

  final String initials;

  /// Ringfarbe (Hoher Kontrast: wird durch `border-control-hc` ersetzt).
  final Color ringColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surfaceOpaque,
            border: Border.all(
              color: colors.highContrast ? colors.controlBorder : ringColor,
              width: CuraSize.selectedBorder,
            ),
          ),
          child: Center(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: CuraSize.navLabelMaxTextScale,
              child: Text(
                initials,
                style: type.heading.copyWith(color: colors.text1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
