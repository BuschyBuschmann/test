// `StepProgress` (Brief 5.8): Text „Schritt X von 4“ (`secondary`, `text-2`)
// plus segmentierter Balken (4 Segmente, 4 dp hoch, 4 dp Abstand). Erledigt
// und aktuell `accent`, offen Weiß 18 %. Der Text trägt die Information; der
// Screenreader liest nur den Text, der Balken ist ausgeblendet.
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
  }) : assert(step >= 1 && step <= total);

  /// Aktueller Schritt, ab 1.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final String text = S.stepOf(step, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          text,
          style: CuraTypography.of(context).secondary
              .copyWith(color: colors.text2),
        ),
        const SizedBox(height: CuraSpace.s2),
        ExcludeSemantics(
          child: Row(
            children: <Widget>[
              for (int i = 0; i < total; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: CuraSpace.s1),
                Expanded(
                  child: SizedBox(
                    height: CuraSize.stepBarHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: i < step ? colors.accent : colors.progressOff,
                        borderRadius: BorderRadius.circular(CuraRadius.pill),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
