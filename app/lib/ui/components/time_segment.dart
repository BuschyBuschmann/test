// `TimeSegment` (Brief 5.3, A-23): Zeitwahl 10 / 20 / 30 Min. Drei gleich
// breite Pillen, 48 dp. Nicht gewählt: Glas-Füllung, Rand `border-control`,
// Text `segment` (DM Sans 400, `text-2`). Gewählt: `accent-soft`-Füllung,
// 1,5 dp Rand `accent-hi`, Text `segmentSelected` (700, `text-1`). Der Zustand
// steht nie nur in der Farbe: Gewicht und Rand ändern sich, der Screenreader
// liest „ausgewählt“. Bricht ein Text bei großer Schrift um, wächst die Pille.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';
import 'glass_card.dart';

class TimeSegment extends StatelessWidget {
  const TimeSegment({
    super.key,
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  /// Minuten der Segmente (10, 20, 30).
  final List<int> choices;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: S.timeChoiceGroup,
      // Bricht ein Text bei großer Schrift um, wachsen alle drei Pillen auf
      // dieselbe Höhe.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < choices.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: CuraSize.segmentGap),
              Expanded(
                child: _Segment(
                  minutes: choices[i],
                  selected: choices[i] == selected,
                  onPressed: () => onSelected(choices[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.minutes,
    required this.selected,
    required this.onPressed,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final CuraMotion motion = CuraMotion.of(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: S.timeChoiceLabel(minutes),
      selected: selected,
      ringRadius: CuraRadius.pill,
      builder: (BuildContext context, bool pressed) {
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: selected ? colors.accentHi : colors.controlBorder,
          ),
          duration: motion.duration(motion.fast),
          curve: motion.curve,
          builder: (BuildContext context, Color? border, Widget? child) {
            return GlassCard(
              radius: CuraRadius.pill,
              lightEdge: false,
              padding: const EdgeInsets.symmetric(horizontal: CuraSpace.s2),
              borderColor: border,
              borderWidth: CuraSize.controlBorder,
              overlay: selected
                  ? colors.accentSoft
                  : (pressed ? colors.pressedOverlay : null),
              child: child!,
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CuraSize.chipHeight),
            child: Center(
              child: Text(
                S.timeChoiceText(minutes),
                textAlign: TextAlign.center,
                style: selected ? type.segmentSelected : type.segment,
              ),
            ),
          ),
        );
      },
    );
  }
}
