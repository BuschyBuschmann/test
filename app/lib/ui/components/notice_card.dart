// `NoticeCard` (Brief-Ergänzung 2, 1.1): Hinweiskarte mit Symbolkreis, Titel,
// Text und optionaler Aktion. Symbol steht immer mit Text (V2-29). Varianten:
// `info`, `stale` („Nicht aktuell“), `error`, `sync` („Ein Eintrag konnte nicht
// gesendet werden“) und `fixedHint` (fester Hinweis). `error` und `fixedHint`
// folgen dem Warnkontext: neutral, keine Mandarine-Aktion; Aktionen sind
// `GlassPill`s. Eine Karte ([GlassCard], Text steht nie direkt auf der Welt).
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';
import 'glass_card.dart';
import 'glass_pill.dart';

enum NoticeKind { info, stale, error, sync, fixedHint }

class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.kind,
    required this.text,
    this.title,
    this.detail,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.dismissLabel,
    this.live = false,
  });

  final NoticeKind kind;
  final String text;
  final String? title;

  /// Zweite, leisere Zeile unter dem Text.
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// X zum Ausblenden (nur lokal); [dismissLabel] ist die Beschriftung für den
  /// Screenreader.
  final VoidCallback? onDismiss;
  final String? dismissLabel;

  /// Als Live-Region ansagen (Fehler, Statuswechsel).
  final bool live;

  IconData get _icon => switch (kind) {
    NoticeKind.info => Icons.info_outline_rounded,
    NoticeKind.stale || NoticeKind.sync => Icons.sync_rounded,
    NoticeKind.error => Icons.error_outline_rounded,
    NoticeKind.fixedHint => Icons.priority_high_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final bool error = kind == NoticeKind.error;
    final Color circle = colors.chipFill;
    final Color ink = error ? colors.statusError : colors.text1;
    final Color? border = switch (kind) {
      NoticeKind.error => colors.statusError,
      NoticeKind.fixedHint => colors.text1,
      NoticeKind.stale || NoticeKind.sync => colors.controlBorder,
      NoticeKind.info => null,
    };
    final double borderWidth = switch (kind) {
      NoticeKind.error => CuraComponent.noticeBorderError,
      NoticeKind.fixedHint => CuraComponent.noticeBorderFixed,
      _ => CuraSize.controlBorder,
    };
    final Widget symbol = ExcludeSemantics(
      child: SizedBox.square(
        dimension: CuraComponent.noticeCircle,
        child: DecoratedBox(
          decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
          child: Icon(_icon, size: CuraComponent.iconSize, color: ink),
        ),
      ),
    );
    // Nur die Texte sind eine Live-Region; die Aktion bleibt ein eigenes
    // Ziel (sonst verschmilzt sie mit dem Text zu einem einzigen Knoten).
    final Widget message = Semantics(
      container: true,
      liveRegion: live,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Semantics(
              header: true,
              child: Text(title!, style: type.heading.copyWith(color: ink)),
            ),
            const SizedBox(height: CuraSpace.s1),
          ],
          Text(text, style: type.bodyStrong.copyWith(color: ink)),
          if (detail != null) ...<Widget>[
            const SizedBox(height: CuraSpace.s1),
            Text(detail!, style: type.secondary.copyWith(color: colors.text2)),
          ],
        ],
      ),
    );
    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        message,
        if (actionLabel != null && onAction != null) ...<Widget>[
          const SizedBox(height: CuraSpace.s3),
          GlassPill(label: actionLabel!, onPressed: onAction, expand: false),
        ],
      ],
    );
    final Widget? dismiss = onDismiss == null
        ? null
        : CuraPressable(
            semanticLabel: dismissLabel,
            onPressed: onDismiss,
            builder: (BuildContext context, bool pressed) => SizedBox.square(
              dimension: CuraSize.touchTarget,
              child: Icon(
                Icons.close_rounded,
                size: CuraComponent.iconSize,
                color: colors.text1,
              ),
            ),
          );
    return GlassCard(
      borderColor: border,
      borderWidth: borderWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          symbol,
          const SizedBox(width: CuraSpace.s3),
          Expanded(child: body),
          ?dismiss,
        ],
      ),
    );
  }
}
