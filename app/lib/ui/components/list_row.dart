// `ListRow` (Design-Brief v2, 7.6): Zeile einer Liste auf einer Karte
// (Profil): Symbol-Kachel (48 dp) links, Titel (`body-strong`), darunter ein
// optionaler Wert (`secondary`, bricht um), Chevron rechts. Die **ganze Zeile**
// ist antippbar und mindestens 56 dp hoch; der Screenreader liest einen
// Knoten („Manny-Look, Mit Brille“). Pressed: Überlagerung 10 %, Fokus:
// `focus-ring`. Mehrere Zeilen stehen in einer [ListCard], getrennt durch
// Haarlinien.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';
import 'glass_card.dart';

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    required this.leading,
    required this.onPressed,
    required this.semanticLabel,
    this.value,
    this.focusNode,
  });

  final String title;

  /// Wert unter dem Titel („Mit Brille“); `null` = keiner.
  final String? value;

  /// Inhalt der 48-dp-Kachel (Symbol, Manny-Kopf).
  final Widget leading;
  final VoidCallback onPressed;
  final String semanticLabel;
  final FocusNode? focusNode;

  /// Kachel mit einem Symbol (`chip-neutral`-Fläche, `text-1`).
  static Widget iconTile(BuildContext context, IconData icon) {
    final CuraColors colors = CuraColors.of(context);
    return SizedBox.square(
      dimension: CuraSize.listRowTile,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.chipFill,
          borderRadius: BorderRadius.circular(CuraRadius.chipInner),
          border: colors.highContrast
              ? Border.all(
                  color: colors.controlBorder,
                  width: CuraSize.controlBorder,
                )
              : null,
        ),
        child: Icon(icon, size: CuraComponent.iconSize, color: colors.text1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      ringRadius: CuraRadius.chipInner,
      builder: (BuildContext context, bool pressed) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: CuraSize.listRowMinHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pressed ? colors.pressedOverlay : null,
              borderRadius: BorderRadius.circular(CuraRadius.chipInner),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CuraSpace.s2,
                vertical: CuraSpace.s2,
              ),
              child: Row(
                children: <Widget>[
                  leading,
                  const SizedBox(width: CuraSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          style: type.bodyStrong.copyWith(color: colors.text1),
                        ),
                        if (value != null)
                          Text(
                            value!,
                            style: type.secondary.copyWith(color: colors.text2),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: CuraSpace.s2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: CuraComponent.iconSize,
                    color: colors.text2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Karte (E1) mit mehreren Zeilen, getrennt durch Haarlinien.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(CuraSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0)
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: CuraSpace.s1),
                  child: SizedBox(
                    height: CuraSize.hairline,
                    child: ColoredBox(color: colors.cardBorder),
                  ),
                ),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}
