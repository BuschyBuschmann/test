// `InfoNote` (SK-1): Hinweiszeile mit Info-Symbol (`text-2`, 18 dp) und Text in
// `secondary` `text-2`, wie die Zeile „Ändern sich Verletzung oder Datum …“ in
// „Deine Daten“. Keine Fläche, keine Aktion. Symbol und Text bilden einen
// einzigen Screenreader-Knoten (Label und Live-Region zusammen). Mit [announce] liest der Screenreader den Text
// beim Erscheinen vor (Live-Region), z. B. wenn er nach einer Auswahl auftaucht.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';

class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.text, this.announce = false});

  final String text;

  /// Als Live-Region lesen (für Hinweise, die erst nach einer Eingabe
  /// erscheinen).
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    // Flag und Label in einem Knoten (wie NodeHint, MannyBubble).
    return Semantics(
      container: true,
      liveRegion: announce,
      label: text,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: CuraSpace.s1),
            child: Icon(
              Icons.info_outline_rounded,
              size: CuraSize.hintIcon,
              color: colors.text2,
            ),
          ),
          const SizedBox(width: CuraSpace.s2),
          Expanded(
            child: Text(
              text,
              style: type.secondary.copyWith(color: colors.text2),
            ),
          ),
        ],
      ),
    );
  }
}
