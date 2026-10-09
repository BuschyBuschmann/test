// `StatPill` (Brief 5.9, Plan 9): Info-Pille der Pfad-Kopfzeile, Freeze
// (Schneeflocke plus Zahl) und Streak (Flamme plus Zahl, bei „eingefroren“ mit
// dem Wort daneben). **Reine Information**: kein Tap-Ziel, keine Schaltfläche
// (B-8); der Screenreader liest ein Label („Streak: 12 Tage“,
// „Streak-Freezes: 2“). Fläche `surface-opaque` mit Rand `border-hair`
// (Hoher Kontrast `border-control-hc`), also deckend und glowfrei.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import 'opaque_surface.dart';

class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.semanticLabel,
    this.valueColor,
    this.extra,
    this.extraColor,
  });

  final IconData icon;
  final Color iconColor;

  /// Die Zahl.
  final String value;
  final Color? valueColor;

  /// Zusatzwort rechts der Zahl („eingefroren“): Text, nicht nur Farbe.
  final String? extra;
  final Color? extraColor;

  /// Label für den Screenreader (ersetzt den sichtbaren Inhalt).
  final String semanticLabel;

  /// Breite, die die Pille bei der aktuellen Textskalierung einnimmt (für die
  /// Entscheidung zwischen Zeilen- und Umbruch-Layout der Kopfzeile).
  static double measureWidth(
    BuildContext context, {
    required String value,
    String? extra,
  }) {
    final CuraTypography type = CuraTypography.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    double text(String s, TextStyle style) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: s,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final double w = tp.width;
      tp.dispose();
      return w;
    }

    double w =
        2 * CuraSize.statPillPaddingH +
        CuraSize.statPillIcon +
        CuraSize.statPillGap +
        text(value, type.numeral);
    if (extra != null) {
      w += CuraSize.statPillGap + text(extra, type.secondary);
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: OpaqueSurface(
        borderRadius: BorderRadius.circular(CuraRadius.pill),
        padding: const EdgeInsets.symmetric(
          horizontal: CuraSize.statPillPaddingH,
          vertical: CuraSize.statPillPaddingV,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: CuraSize.statPillIcon, color: iconColor),
            const SizedBox(width: CuraSize.statPillGap),
            Text(
              value,
              style: type.numeral.copyWith(color: valueColor ?? colors.text1),
            ),
            if (extra != null) ...<Widget>[
              const SizedBox(width: CuraSize.statPillGap),
              Flexible(
                child: Text(
                  extra!,
                  style: type.secondary.copyWith(
                    color: extraColor ?? colors.text2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
