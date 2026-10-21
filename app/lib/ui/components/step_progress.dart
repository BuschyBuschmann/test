// `StepProgress` (Brief 5.8, Ergänzung 1, 6a): Text „Schritt X von 5“
// (`secondary`) plus segmentierter Balken (5 Segmente, 4 dp hoch, 4 dp
// Abstand). Erledigt und aktuell `accent`, offen `progress-off`. Der Text
// trägt die Information; der Screenreader liest nur den Text, der Balken ist
// ausgeblendet.
//
// Auf der Kopf-Karte ([onHeaderCard], Onboarding): der Balken steht über dem
// Text, der Text in `#FFFFFF` (`header-ink`), offene Segmente in `header-track`.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';

class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.step,
    this.total = CuraComponent.stepSegments,
    this.onHeaderCard = false,
  }) : assert(step >= 1 && step <= total);

  /// Aktueller Schritt, ab 1.
  final int step;
  final int total;

  /// Auf der Kopf-Karte (weißer Text, Balken über dem Text).
  final bool onHeaderCard;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final String text = S.stepOf(step, total);
    final Widget label = Text(
      text,
      style: CuraTypography.of(context).secondary
          .copyWith(color: onHeaderCard ? colors.headerInk : colors.text2),
    );
    final Widget bar = ExcludeSemantics(
      child: Row(
        children: <Widget>[
          for (int i = 0; i < total; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: CuraSpace.s1),
            Expanded(
              child: SizedBox(
                height: CuraSize.stepBarHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i < step
                        ? colors.accent
                        : (onHeaderCard
                              ? colors.headerTrack
                              : colors.progressOff),
                    borderRadius: BorderRadius.circular(CuraRadius.pill),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (onHeaderCard) ...<Widget>[
          bar,
          const SizedBox(height: CuraSpace.s2),
          label,
        ] else ...<Widget>[label, const SizedBox(height: CuraSpace.s2), bar],
      ],
    );
  }
}
