// `DateCard` (Ergänzung 1, Abschnitt 2; Onboarding Schritt 4): Karte mit dem
// gewählten Datum (Platzhalter „Datum wählen“), Kalender-Icon links. Antippen
// öffnet die Datumsauswahl des Besitzers. **Eine** Implementierung für
// Onboarding und Sheet (Regel 6).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';
import 'glass_card.dart';

class DateCard extends StatelessWidget {
  const DateCard({
    super.key,
    required this.onPressed,
    this.valueText,
    this.placeholder = S.datePlaceholder,
    this.autofocus = false,
    this.focusNode,
  });

  /// Gewähltes Datum, z. B. „3. September 2026“; `null` = noch keines.
  final String? valueText;
  final String placeholder;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final String text = valueText ?? placeholder;
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: text,
      autofocus: autofocus,
      focusNode: focusNode,
      ringRadius: CuraRadius.card,
      builder: (BuildContext context, bool pressed) {
        return GlassCard(
          borderColor: colors.controlBorder,
          borderWidth: CuraSize.controlBorder,
          overlay: pressed ? colors.pressedOverlay : null,
          padding: const EdgeInsets.symmetric(
            horizontal: CuraSize.cardPadding,
            vertical: CuraSpace.s3,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CuraComponent.choiceInnerMinHeight,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.calendar_today_rounded,
                  size: CuraComponent.iconSize,
                  color: colors.text2,
                ),
                const SizedBox(width: CuraComponent.choiceIconGap),
                Expanded(
                  child: Text(
                    text,
                    style: type.heading.copyWith(
                      color: valueText == null ? colors.text2 : colors.text1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
