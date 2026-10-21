// `DiscardDialog` „Änderungen verwerfen?“ (Ergänzung 1, 3.2, UI-57): erscheint,
// wenn „Deine Daten“ mit ungespeicherten Änderungen geschlossen wird (X,
// Zurück, Escape, Scrim, Wegwischen). „Weiter bearbeiten“ (Neutral hell) hat
// den Anfangsfokus, „Verwerfen“ ist ein Umriss-Button. Kein `accent`, kein
// `status-error`: Verwerfen ist keine Warnung, nur eine Entscheidung.
//
// Ergebnis der Route: `true` = verwerfen, sonst (`false`, Scrim, Zurück)
// weiter bearbeiten.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../components/cura_dialog.dart';
import '../components/pill_button.dart';
import '../routes/cura_dialog_route.dart';

class DiscardDialog extends StatelessWidget {
  const DiscardDialog({super.key});

  static CuraDialogRoute<bool> route(BuildContext context) {
    return CuraDialogRoute<bool>(
      context: context,
      builder: (BuildContext context) => const DiscardDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CuraDialog(
      title: S.discardTitle,
      message: S.discardText,
      actions: <Widget>[
        PillButton(
          label: S.discardKeep,
          variant: PillButtonVariant.neutral,
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PillButton(
          label: S.discardConfirm,
          variant: PillButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
