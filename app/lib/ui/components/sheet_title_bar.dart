// `SheetTitleBar`: fester Kopf eines Sheets (Brief v2, 4): Titel (`title`,
// skaliert bis 150 %, Überschrift für den Screenreader) links und die
// Schließen-Schaltfläche (48 dp) rechts, optional mit Untertitel (`secondary`,
// „Deine Daten“). Gemeinsam für „Manny-Look“, „Darstellung“, „Deine Daten“ und
// „Wie willst du trainieren?“.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import 'header_icon_button.dart';

class SheetTitleBar extends StatelessWidget {
  const SheetTitleBar({super.key, required this.title, this.subtitle});

  final String title;

  /// Zeile unter dem Titel; `null` = keine (bei großer Schrift oder wenig Platz
  /// steht sie im Scrollbereich des Besitzers).
  final String? subtitle;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: CuraSize.headerTitleMaxTextScale,
                    child: Text(
                      title,
                      style: type.title.copyWith(color: colors.text1),
                    ),
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: CuraSpace.s1),
                  Text(
                    subtitle!,
                    style: type.secondary.copyWith(color: colors.text2),
                  ),
                ],
              ],
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
