// `OptionChips` (Design-Brief v2, 7.6 „Darstellung“): Einfachauswahl aus
// wenigen Werten (Welt, Thema) als Pillen, die umbrechen. Jede Pille ist
// mindestens 48 dp hoch, der Abstand beträgt 8 dp. Gewählt: Füllung
// `accent-soft`, 2 dp Rand `accent`, Haken vor dem Text und Gewicht 700 (der
// Zustand steht nie nur in der Farbe); nicht gewählt: neutrale Füllung mit Rand
// `border-control`. Screenreader: „Hell, ausgewählt“. Die Auswahl wirkt sofort.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';

class OptionChipData<T> {
  const OptionChipData(this.value, this.label);

  final T value;
  final String label;
}

class OptionChips<T> extends StatelessWidget {
  const OptionChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.groupLabel,
  });

  final List<OptionChipData<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Name der Gruppe für den Screenreader („Welt“).
  final String groupLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: groupLabel,
      child: Wrap(
        spacing: CuraSpace.s2,
        runSpacing: CuraSpace.s2,
        children: <Widget>[
          for (final OptionChipData<T> o in options)
            _Chip(
              label: o.label,
              selected: o.value == value,
              onPressed: () => onChanged(o.value),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final CuraMotion motion = CuraMotion.of(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: S.displayChoiceLabel(label, selected),
      selected: selected,
      ringRadius: CuraRadius.pill,
      builder: (BuildContext context, bool pressed) {
        return AnimatedContainer(
          duration: motion.duration(motion.fast),
          curve: motion.curve,
          constraints: const BoxConstraints(
            minWidth: CuraSize.touchTarget,
            minHeight: CuraSize.touchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: CuraSpace.s4),
          decoration: BoxDecoration(
            color: selected
                ? colors.accentSoft
                : (pressed ? colors.pressedOverlay : colors.chipFill),
            borderRadius: BorderRadius.circular(CuraRadius.pill),
            border: Border.all(
              color: selected ? colors.accent : colors.controlBorder,
              width: selected
                  ? CuraSize.selectedBorder
                  : CuraSize.controlBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (selected) ...<Widget>[
                Icon(
                  Icons.check_rounded,
                  size: CuraSize.hintIcon,
                  color: colors.accentText,
                ),
                const SizedBox(width: CuraSpace.s1),
              ],
              Flexible(
                child: Text(
                  label,
                  style: (selected ? type.segmentSelected : type.segment)
                      .copyWith(color: colors.text1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
