// `CategoryCard` (Brief 5.2, Plan 9): Glas-Karte (E1) für Termine und
// Übungen. Links ein 4-dp-Streifen in der Kategoriefarbe (14 dp Abstand oben
// und unten, runde Enden), darüber die Kategorie als Icon-Kachel (20 dp,
// Radius 7, Symbol in `on-accent`) plus Label in der Kategoriefarbe, dann der
// Titel (`heading`), optional die Uhrzeit rechts daneben (`numeralLarge`), die
// Meta-Zeile (`secondary`, `text-2`) und eine Aktionsleiste.
//
// Die Kategorie steht nie nur in der Farbe: Streifen **und** Icon **und**
// Label (UI-18, UI-19). Der Screenreader liest [semanticLabel] als einen
// Knoten; die Aktionen darunter bleiben eigene Schaltflächen.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import 'cura_label.dart';
import 'glass_card.dart';

enum CategoryKind { physio, doctor, exercise }

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.kind,
    required this.title,
    required this.semanticLabel,
    this.meta,
    this.time,
    this.actions = const <Widget>[],
  });

  final CategoryKind kind;
  final String title;

  /// Screenreader-Text der Karte (ohne die Aktionen).
  final String semanticLabel;

  /// Meta-Zeile („Köln-Ehrenfeld · Beispiel“, „3 × 12 Wdh. · 6 Min“).
  final String? meta;

  /// Uhrzeit rechts („17:00“), nur bei Terminen.
  final String? time;

  /// Aktionschips; umbrechen bei großer Schrift.
  final List<Widget> actions;

  Color _color(CuraColors c) => switch (kind) {
    CategoryKind.physio => c.catPhysio,
    CategoryKind.doctor => c.catArzt,
    CategoryKind.exercise => c.catUebung,
  };

  IconData get _icon => switch (kind) {
    CategoryKind.physio => Icons.accessibility_new_rounded,
    CategoryKind.doctor => Icons.medical_services_rounded,
    CategoryKind.exercise => Icons.fitness_center_rounded,
  };

  String get _label => switch (kind) {
    CategoryKind.physio => S.categoryPhysio,
    CategoryKind.doctor => S.categoryDoctor,
    CategoryKind.exercise => S.categoryExercise,
  };

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final Color accent = _color(colors);
    final bool stackTime =
        MediaQuery.textScalerOf(context).scale(CuraSize.hairline) >=
        CuraSize.textScaleScrollAlong;

    final Widget kindRow = Row(
      children: <Widget>[
        CategoryIconTile(color: accent, icon: _icon),
        const SizedBox(width: CuraSpace.s2),
        Flexible(child: CuraLabel(_label, color: accent, header: false)),
      ],
    );

    final Widget titleText = Text(
      title,
      style: type.heading.copyWith(color: colors.text1),
    );
    final Widget? timeText = time == null
        ? null
        : Text(time!, style: type.numeralLarge.copyWith(color: colors.text1));

    final Widget titleRow = timeText == null
        ? titleText
        : stackTime
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[titleText, timeText],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(child: titleText),
              const SizedBox(width: CuraSpace.s3),
              timeText,
            ],
          );

    final Widget info = Semantics(
      container: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          kindRow,
          const SizedBox(height: CuraSpace.s2),
          titleRow,
          if (meta != null)
            Text(meta!, style: type.secondary.copyWith(color: colors.text2)),
        ],
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Stack(
        children: <Widget>[
          GlassCard(
            padding: const EdgeInsets.fromLTRB(
              CuraSize.cardPaddingWithStripe,
              CuraSize.cardPadding,
              CuraSize.cardPadding,
              CuraSize.cardPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                info,
                if (actions.isNotEmpty) ...<Widget>[
                  const SizedBox(height: CuraSpace.s2),
                  Wrap(
                    spacing: CuraSpace.s2,
                    runSpacing: CuraSpace.s2,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: CuraSize.categoryStripeEdge,
            top: CuraSize.categoryStripeInset,
            bottom: CuraSize.categoryStripeInset,
            width: CuraSize.categoryStripe,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(CuraRadius.pill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon-Kachel (20 dp, Radius 7) mit dem Kategoriesymbol in `on-accent`. Eine
/// deckende Fläche in der Kategoriefarbe: die Prüfungen rechnen das Symbol
/// gegen sie, nicht gegen das Glas darunter (`TextGround.opaque`).
class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({super.key, required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(CuraRadius.iconTile),
      ),
      child: SizedBox.square(
        dimension: CuraSize.categoryIconTile,
        child: Icon(
          icon,
          size: CuraSize.categoryIconGlyph,
          color: colors.onAccent,
        ),
      ),
    );
  }
}
