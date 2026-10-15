// `SheetTitleBar`: fester Kopf eines Sheets (Brief v2, 4): Titel (`title`,
// skaliert bis 150 %, Überschrift für den Screenreader) links und die
// Schließen-Schaltfläche (48 dp) rechts. Gemeinsam für „Manny-Look“ und
// „Darstellung“; `DataSheet` und `TrainingModeSheet` bauen denselben Kopf
// selbst (Optik F2-R4).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import 'header_icon_button.dart';

class SheetTitleBar extends StatelessWidget {
  const SheetTitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CuraSpace.pageMargin,
        CuraSpace.s6,
        CuraSpace.s2,
        CuraSpace.s2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: CuraSize.headerTitleMaxTextScale,
                child: Text(
                  title,
                  style: type.title.copyWith(color: colors.text1),
                ),
              ),
            ),
          ),
          HeaderIconButton(
            icon: Icons.close_rounded,
            tooltip: S.close,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
