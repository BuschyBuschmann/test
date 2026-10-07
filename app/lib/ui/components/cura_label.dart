// `CuraLabel` (Brief 3.3, Plan 8.1): Abschnittstitel im Stil `label`
// (13/16, 600, Laufweite 0,06 em). Großbuchstaben nur in der Darstellung: der
// Text wird groß gesetzt gezeigt, der Screenreader liest die normale
// Schreibweise.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_typography.dart';

class CuraLabel extends StatelessWidget {
  const CuraLabel(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.header = true,
  });

  final String text;

  /// Standard `text-2`.
  final Color? color;
  final TextAlign? textAlign;

  /// Als Überschrift für den Screenreader (Abschnittsüberschriften).
  final bool header;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final TextStyle style = CuraTypography.of(context).label
        .copyWith(color: color ?? colors.text2);
    return Semantics(
      label: text,
      header: header,
      excludeSemantics: true,
      child: Text(text.toUpperCase(), textAlign: textAlign, style: style),
    );
  }
}
