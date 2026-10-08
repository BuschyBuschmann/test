// `ChatHeader` (Ergänzung 2, Abschnitt 2): Zurück-Pfeil (`HeaderIconButton`,
// 48 dp, `autofocus`: Anfangsfokus der Vollbild-Routen), Avatar oder Manny-
// Emblem 32 bis 36 dp, Titel (`heading`, in den Nachrichten `title`),
// Untertitel (`secondary`, `text-2`). Der Screenreader liest zuerst den Titel
// (Sortierschlüssel), danach den Zurück-Pfeil; die sichtbare Tastatur-
// Reihenfolge beginnt beim Zurück-Pfeil.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import 'header_icon_button.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.largeTitle = false,
    this.backFocusNode,
  });

  final String title;
  final String? subtitle;

  /// Avatar oder Emblem links neben dem Titel.
  final Widget? leading;

  /// Titel im Stil `title` (Nachrichten) statt `heading`.
  final bool largeTitle;
  final FocusNode? backFocusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final String? sub = subtitle;
    final Widget? icon = leading;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CuraSpace.s2,
          CuraSpace.s2,
          CuraSpace.pageMargin,
          CuraSpace.s2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Semantics(
              container: true,
              sortKey: const OrdinalSortKey(1),
              child: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: S.back,
                autofocus: true,
                focusNode: backFocusNode,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(width: CuraSpace.s2),
            if (icon != null) ...<Widget>[
              icon,
              const SizedBox(width: CuraSpace.s3),
            ],
            Expanded(
              child: Semantics(
                container: true,
                header: true,
                sortKey: const OrdinalSortKey(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: (largeTitle ? type.title : type.heading).copyWith(
                        color: colors.text1,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub,
                        style: type.secondary.copyWith(color: colors.text2),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
