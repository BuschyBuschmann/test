// `SwitchRow` (Design-Brief v2, 7.6 „Darstellung“): Zeile mit Titel, Erklärung
// und Schalter (Transparenz reduzieren, Ton, Vibration). Die **ganze Zeile**
// schaltet und ist mindestens 56 dp hoch. Der Zustand steht nie nur in der
// Farbe: der Knopf sitzt links (aus) bzw. rechts (an) und daneben steht das
// Wort „An“ bzw. „Aus“. An: Spur `accent`, Knopf `on-accent`; aus: neutrale
// Spur mit Rand `border-control`, Knopf `text-2`. Screenreader: Schalter
// „Ton, An“. Das Umlegen dauert höchstens `dur-fast`.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.hint,
    this.focusNode,
  });

  final String title;

  /// Erklärung unter dem Titel.
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final CuraMotion motion = CuraMotion.of(context);
    return CuraPressable(
      onPressed: () => onChanged(!value),
      semanticLabel: S.displaySwitchLabel(title, value),
      toggled: value,
      focusNode: focusNode,
      ringRadius: CuraRadius.chipInner,
      builder: (BuildContext context, bool pressed) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: CuraSize.listRowMinHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pressed ? colors.pressedOverlay : null,
              borderRadius: BorderRadius.circular(CuraRadius.chipInner),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CuraSpace.s2,
                vertical: CuraSpace.s2,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          style: type.bodyStrong.copyWith(color: colors.text1),
                        ),
                        if (hint != null)
                          Text(
                            hint!,
                            style: type.secondary.copyWith(color: colors.text2),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: CuraSpace.s3),
                  Text(
                    value ? S.switchOn : S.switchOff,
                    style: type.segmentSelected.copyWith(color: colors.text1),
                  ),
                  const SizedBox(width: CuraSpace.s2),
                  _Track(on: value, colors: colors, motion: motion),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.on, required this.colors, required this.motion});

  final bool on;
  final CuraColors colors;
  final CuraMotion motion;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: motion.duration(motion.fast),
      curve: motion.curve,
      width: CuraSize.switchTrackWidth,
      height: CuraSize.switchTrackHeight,
      padding: const EdgeInsets.all(CuraSize.switchTrackPadding),
      decoration: BoxDecoration(
        color: on ? colors.accent : colors.chipFill,
        borderRadius: BorderRadius.circular(CuraRadius.pill),
        border: Border.all(
          color: on ? colors.accent : colors.controlBorder,
          width: CuraSize.controlBorder,
        ),
      ),
      child: AnimatedAlign(
        duration: motion.duration(motion.fast),
        curve: motion.curve,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox.square(
          dimension: CuraSize.switchKnob,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? colors.onAccent : colors.text2,
            ),
          ),
        ),
      ),
    );
  }
}
