// `ChatComposer` (Ergänzung 2, 2.2, Nutzerentscheidung Abschnitt 8): die
// Eingabeleiste **nur im deaktivierten Zustand**. Pill Radius 28, mindestens
// 56 dp hoch, `surface-opaque`, Rand 1 dp `border-hair`, Platzhaltertext
// (`body`, `text-2`), rechts der Senden-Kreis 40 dp (Hit-Area 48) mit Pfeil
// `text-3` auf Weiß 10 %. Die Leiste öffnet keine Tastatur und löst nichts
// aus; sie ist nicht fokussierbar, der Screenreader liest sie vor.
// Dazu die Hinweiszeile über der Leiste und der Disclaimer darunter
// (`ChatHintLine`, `ChatDisclaimer`).
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'opaque_surface.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.placeholder,
    required this.semanticsLabel,
    required this.sendSemanticsLabel,
  });

  /// Platzhaltertext („Schreib Manny“, „Nachricht“).
  final String placeholder;

  /// Screenreader: „Nachricht an Manny, noch nicht verfügbar“.
  final String semanticsLabel;

  /// Screenreader: „Senden, noch nicht verfügbar“.
  final String sendSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return ExcludeFocus(
      child: OpaqueSurface(
        borderRadius: BorderRadius.circular(CuraRadius.composer),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: CuraSize.composerMinHeight,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Semantics(
                  container: true,
                  label: semanticsLabel,
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CuraSpace.s5,
                      vertical: CuraSpace.s2,
                    ),
                    child: Text(
                      placeholder,
                      style: type.body.copyWith(color: colors.text2),
                    ),
                  ),
                ),
              ),
              Semantics(
                container: true,
                button: true,
                enabled: false,
                label: sendSemanticsLabel,
                excludeSemantics: true,
                child: SizedBox.square(
                  dimension: CuraSize.sendCircleHitArea,
                  child: Center(
                    child: SizedBox.square(
                      dimension: CuraSize.sendCircle,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.disabledFill,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: CuraComponent.iconSize,
                          color: colors.text3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CuraSpace.s1),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hinweiszeile über der Leiste: Info-Icon 18 dp plus Text (`secondary`,
/// `text-1`), dauerhaft sichtbar.
class ChatHintLine extends StatelessWidget {
  const ChatHintLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: CuraSpace.s1),
            child: Icon(
              Icons.info_outline_rounded,
              size: CuraSize.hintIcon,
              color: colors.text1,
            ),
          ),
          const SizedBox(width: CuraSpace.s2),
          Expanded(
            child: Text(
              text,
              style: type.secondary.copyWith(color: colors.text1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Disclaimer unter der Leiste: `caption`, `text-3`, mittig.
class ChatDisclaimer extends StatelessWidget {
  const ChatDisclaimer({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: type.caption.copyWith(color: colors.text3),
      ),
    );
  }
}
