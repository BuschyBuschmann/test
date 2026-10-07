// `ChoiceCard` (Brief 5.7): Onboarding-Auswahlkarte. Glas-Karte (E1), volle
// Breite, mindestens 64 dp hoch, Text `heading`, optional Untertitel
// `secondary`. Nicht gewählt: Rand `border-control`. Gewählt: Füllung
// `accent-soft`, 2 dp Rand `accent-hi`, Haken-Icon rechts (zusätzlich zur
// Farbe). Randwechsel in `dur-fast`. Die Escape-Hatch-Karte „Anderes /
// selbst eingeben“ trägt ein Stift-Icon links. Einfachauswahl.
// **Eine** Implementierung für Onboarding und Sheet (Regel 6).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';
import 'glass_card.dart';

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onPressed,
    this.subtitle,
    this.leadingIcon,
    this.autofocus = false,
    this.focusNode,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onPressed;

  /// Stift-Icon der Karte „Anderes / selbst eingeben“.
  final IconData? leadingIcon;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final CuraMotion motion = CuraMotion.of(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: S.choiceLabel(title, selected),
      autofocus: autofocus,
      focusNode: focusNode,
      ringRadius: CuraRadius.card,
      builder: (BuildContext context, bool pressed) {
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: selected ? colors.accentHi : colors.controlBorder,
          ),
          duration: motion.duration(motion.fast),
          curve: motion.curve,
          builder: (BuildContext context, Color? border, Widget? child) {
            return GlassCard(
              borderColor: border,
              borderWidth: selected
                  ? CuraSize.selectedBorder
                  : CuraSize.controlBorder,
              overlay: selected
                  ? colors.accentSoft
                  : (pressed ? colors.pressedOverlay : null),
              padding: const EdgeInsets.symmetric(
                horizontal: CuraSize.cardPadding,
                vertical: CuraSpace.s3,
              ),
              child: child!,
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CuraComponent.choiceInnerMinHeight,
            ),
            child: Row(
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  Icon(
                    leadingIcon,
                    size: CuraComponent.iconSize,
                    color: colors.text2,
                  ),
                  const SizedBox(width: CuraComponent.choiceIconGap),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style: type.heading.copyWith(color: colors.text1),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: type.secondary.copyWith(color: colors.text2),
                        ),
                    ],
                  ),
                ),
                if (selected) ...<Widget>[
                  const SizedBox(width: CuraComponent.choiceIconGap),
                  Icon(
                    Icons.check_circle_rounded,
                    size: CuraComponent.iconSize,
                    color: colors.accentHi,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
