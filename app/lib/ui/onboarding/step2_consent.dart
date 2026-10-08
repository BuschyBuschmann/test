// Schritt 2: Datenschutz (Brief 6.1, UI-13). Glas-Karte mit drei
// Kurzabschnitten, Link „Datenschutzerklärung lesen“. Der Text ist
// Platzhalter und wird vor dem echten Einsatz juristisch ersetzt (Brief 6.0).
// Nicht überspringbar: „Verstanden, weiter“ speichert Zeitstempel und Version.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/cura_label.dart';
import '../components/cura_pressable.dart';
import '../components/glass_card.dart';

class Step2Consent extends StatelessWidget {
  const Step2Consent({
    super.key,
    required this.prompt,
    required this.onOpenPrivacy,
  });

  final Widget prompt;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    Widget section(String label, String text) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CuraLabel(label),
          const SizedBox(height: CuraSpace.s1),
          Text(text, style: type.body.copyWith(color: colors.text1)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        prompt,
        const SizedBox(height: CuraSpace.s6),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              section(S.consentStoredLabel, S.consentStoredText),
              const SizedBox(height: CuraSpace.s4),
              section(S.consentDurationLabel, S.consentDurationText),
              const SizedBox(height: CuraSpace.s4),
              section(S.consentRightLabel, S.consentRightText),
              const SizedBox(height: CuraSpace.s4),
              Text(
                S.consentPlaceholderNote,
                style: type.caption.copyWith(color: colors.text3),
              ),
            ],
          ),
        ),
        const SizedBox(height: CuraSpace.s2),
        Align(
          alignment: Alignment.centerLeft,
          child: CuraPressable(
            onPressed: onOpenPrivacy,
            semanticLabel: S.privacyLink,
            ringRadius: CuraRadius.chipInner,
            builder: (BuildContext context, bool pressed) {
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: CuraSize.touchTarget,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    S.privacyLink,
                    style: type.bodyStrong.copyWith(
                      color: pressed ? colors.text1 : colors.accentHi,
                      decoration: TextDecoration.underline,
                      decorationColor: pressed ? colors.text1 : colors.accentHi,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
