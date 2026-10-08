// Schritt 1: Manny und Name (Brief 6.1, UI-12). Die Tastatur öffnet sich erst
// beim Antippen des Feldes. Jede Eingabe wird sofort gespeichert (UI-16);
// „Weiter“ gilt ab einem Zeichen nach dem Trimmen.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_metrics.dart';
import '../components/cura_text_field.dart';

class Step1Name extends StatefulWidget {
  const Step1Name({super.key, required this.prompt, required this.onSubmit});

  /// Manny mit Sprechblase.
  final Widget prompt;

  /// Eingabetaste auf dem Feld: wie „Weiter“.
  final VoidCallback onSubmit;

  @override
  State<Step1Name> createState() => _Step1NameState();
}

class _Step1NameState extends State<Step1Name> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final String saved =
        context
            .getInheritedWidgetOfExactType<AppScope>()
            ?.notifier
            ?.state
            .onboarding
            .name ??
        '';
    _controller = TextEditingController(text: saved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        widget.prompt,
        const SizedBox(height: CuraSpace.s6),
        CuraTextField(
          label: S.nameLabel,
          controller: _controller,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.givenName],
          onChanged: AppScope.of(context).setName,
          onSubmitted: (_) => widget.onSubmit(),
        ),
      ],
    );
  }
}
