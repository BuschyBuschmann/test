// `CodeField` (Brief-Ergänzung 2, 1.3): Eingabefeld für den Einladungscode.
// Anzeige `XXXXX-XXXXX`; Groß-/Kleinschreibung, Leerzeichen und Bindestriche
// werden toleriert, der Bindestrich nach dem fünften Zeichen kommt von selbst,
// Einfügen funktioniert. Sichtbares Label über dem Feld, Fehlerrand
// zusätzlich mit Symbol und Text darunter (macht der Aufrufer). Keine
// Autokorrektur. Die Schrift skaliert nur bis 130 %.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/invite_code.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'glass_card.dart';

/// Formatiert während des Tippens (`formatInviteCodeInput`) und setzt den
/// Cursor ans Ende.
class InviteCodeFormatter extends TextInputFormatter {
  const InviteCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = formatInviteCodeInput(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CodeField extends StatelessWidget {
  const CodeField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(
            label,
            style: type.secondary.copyWith(color: colors.text2),
          ),
        ),
        const SizedBox(height: CuraComponent.fieldGap),
        GlassCard(
          padding: EdgeInsets.zero,
          radius: CuraComponent.codeFieldRadius,
          lightEdge: false,
          borderColor: hasError ? colors.statusError : colors.controlBorder,
          borderWidth: CuraComponent.codeFieldBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CuraComponent.codeFieldHeight,
            ),
            child: Semantics(
              label: label,
              textField: true,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: CuraComponent.codeMaxTextScale,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  spellCheckConfiguration:
                      const SpellCheckConfiguration.disabled(),
                  inputFormatters: const <TextInputFormatter>[
                    InviteCodeFormatter(),
                  ],
                  style: type.numeral.copyWith(
                    color: colors.text1,
                    letterSpacing: CuraComponent.codeLetterSpacing,
                  ),
                  cursorColor: colors.text1,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: CuraSize.cardPadding,
                      vertical: CuraSpace.s4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
