// Löschfehler im Dialog „Alles löschen?“ (Ergänzung 1, 3.2, UI-52): Icon
// `error_outline_rounded` in `status-error` plus Text in `text-1`. Hier ist
// `status-error` Status, nie Handlungsfarbe: die Datei trägt kein Element mit
// Aktion (Code-Regel 4, Allowlist).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';

class DeleteErrorNotice extends StatelessWidget {
  const DeleteErrorNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: Icon(
              Icons.error_outline_rounded,
              size: CuraComponent.iconSize,
              color: colors.statusError,
            ),
          ),
          const SizedBox(width: CuraComponent.choiceIconGap),
          Expanded(
            child: Text(
              S.deleteError,
              style: type.body.copyWith(color: colors.text1),
            ),
          ),
        ],
      ),
    );
  }
}
