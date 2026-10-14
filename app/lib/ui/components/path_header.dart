// `PathHeader` (Brief 5.9, Ergänzung 1, 3.1, Plan 9): fixe Kopfzeile des Pfads.
// Links „Woche N“ (`title`), „Phase M · Kreuzband“ (`secondary`) und das kleine
// Label „Beispielpfad“ (UI-25, immer); rechts Freeze-Pille, Streak-Pille und
// der Einstieg „Deine Daten“ (`HeaderIconButton`, `person_outline_rounded`).
//
// Zwei Layouts: **Zeile** (Textblock, Freeze, 4 dp, Streak, 4 dp, Icon) und,
// wenn der Textblock links weniger als 150 dp bekäme (320 dp oder große
// Schrift), **Umbruch** (Zeile 1: Textblock und Icon; Zeile 2, 8 dp tiefer:
// beide Pillen linksbündig, dürfen selbst umbrechen). Es wird nichts
// abgeschnitten oder überlagert. Die Pillen sind Schaltflächen (SK-1): ein
// Tipp erklärt Freeze bzw. Streak (`NodeHint`, vom `PathScreen` gezeigt), Hit-
// Area mindestens 48 dp.
//
// Ab Textskalierung 1,5 teilt sich der Kopf (F-1): [PathHeaderBar] bleibt als
// feste schmale Zeile stehen (höchstens 64 dp, „Woche N“ links, „Deine Daten“
// rechts, Schrift auf höchstens 1,3 begrenzt, Fläche `bg`, kein Blur); der Rest
// ([PathHeaderInfo]: Phase, „Beispielpfad“, Freezes, Streak) läuft in der
// Scrollfläche mit. Die Pillen stehen also nie in der festen Zeile (die bliebe
// sonst nicht bei 64 dp); sie sind dort in der Scrollfläche genauso antippbar,
// und ihr Hinweis schließt beim Scrollen wie jeder `NodeHint`.
//
// Streak-Zustände: aktiv (Flamme `accent-hi`), eingefroren (Flamme
// `streak-freeze` plus das Wort „eingefroren“), Reset (Zahl 0, Flamme
// `text-3`). Der Zustand steht nie nur in der Farbe (UI-18).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../logic/plural.dart';
import '../../logic/streak.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import 'cura_label.dart';
import 'header_icon_button.dart';
import 'stat_pill.dart';

/// Einstieg „Deine Daten“ (Icon-Button, 48 dp).
Widget _dataButton(VoidCallback onOpenData, FocusNode? focusNode) =>
    HeaderIconButton(
      icon: Icons.person_outline_rounded,
      tooltip: S.dataSheetOpen,
      focusNode: focusNode,
      onPressed: onOpenData,
    );

/// Feste schmale Kopfzeile ab Textskalierung 1,5 (F-1): „Woche N“ links, das
/// Icon „Deine Daten“ rechts. Höhe höchstens [CuraSize.pathBarHeight], Fläche
/// `bg` ohne Blur, Schrift auf höchstens [CuraSize.pathBarMaxTextScale]
/// begrenzt. Lese- und Fokusreihenfolge: Titel (Überschrift), dann das Icon.
class PathHeaderBar extends StatelessWidget {
  const PathHeaderBar({
    super.key,
    required this.week,
    required this.onOpenData,
    this.dataFocusNode,
  });

  final int week;
  final VoidCallback onOpenData;
  final FocusNode? dataFocusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return ColoredBox(
      color: colors.bg,
      child: SizedBox(
        height: CuraSize.pathBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: CuraSpace.pageMargin),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: CuraSize.pathBarMaxTextScale,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    header: true,
                    container: true,
                    child: Text(
                      S.weekTitle(week),
                      style: type.title.copyWith(color: colors.text1),
                    ),
                  ),
                ),
                const SizedBox(width: CuraSpace.s2),
                _dataButton(onOpenData, dataFocusNode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Der mitlaufende Rest des Kopfes ab Textskalierung 1,5: Phase,
/// „Beispielpfad“, dann Freezes und Streak (die Pillen dürfen umbrechen).
class PathHeaderInfo extends StatelessWidget {
  const PathHeaderInfo({
    super.key,
    required this.phaseLine,
    required this.streak,
    this.onFreezeTap,
    this.onStreakTap,
  });

  final String phaseLine;
  final StreakView streak;

  /// Tipp auf die Pillen (Rechteck der Pille, global).
  final ValueChanged<Rect>? onFreezeTap;
  final ValueChanged<Rect>? onStreakTap;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CuraSpace.pageMargin,
        0,
        CuraSpace.pageMargin,
        CuraSpace.s2,
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              phaseLine,
              style: type.secondary.copyWith(color: colors.text2),
            ),
            const CuraLabel(S.samplePathLabel, header: false),
            const SizedBox(height: CuraSpace.s2),
            _pillWrap(<Widget>[
              _freezePillFor(context, streak, onFreezeTap),
              _streakPillFor(context, streak, onStreakTap),
            ], tappable: onFreezeTap != null || onStreakTap != null),
          ],
        ),
      ),
    );
  }
}

/// Pillen in Zeilen, die umbrechen dürfen. Antippbare Pillen haben schmalere
/// Boxen als ihre sichtbare Form ([StatPill.hitInset]): die Lücken wachsen
/// entsprechend (sichtbar bleiben 4 dp), und der Block rückt um das Maß ein,
/// damit die sichtbare Kante am Seitenrand steht. Zwischen den Zeilen liegen
/// die Ziele 8 dp auseinander.
Widget _pillWrap(List<Widget> pills, {required bool tappable}) {
  final double inset = tappable ? StatPill.hitInset : 0;
  return Padding(
    padding: EdgeInsets.only(left: inset),
    child: Wrap(
      spacing: tappable ? StatPill.boxGap : CuraSize.statPillGap,
      runSpacing: tappable ? CuraSize.minTargetGap : CuraSize.statPillGap,
      children: pills,
    ),
  );
}

StatPill _freezePillFor(
  BuildContext context,
  StreakView streak,
  ValueChanged<Rect>? onPressed,
) {
  final CuraColors colors = CuraColors.of(context);
  return StatPill(
    icon: Icons.ac_unit_rounded,
    iconColor: colors.streakFreeze,
    value: '${streak.freezes}',
    valueColor: colors.streakFreeze,
    semanticLabel: S.freezesLabel(streak.freezes),
    onPressed: onPressed,
  );
}

StatPill _streakPillFor(
  BuildContext context,
  StreakView streak,
  ValueChanged<Rect>? onPressed,
) {
  final CuraColors colors = CuraColors.of(context);
  final bool frozen = streak.display == StreakDisplay.frozen;
  final Color flame = switch (streak.display) {
    StreakDisplay.active => colors.accentText,
    StreakDisplay.frozen => colors.streakFreeze,
    StreakDisplay.reset => colors.text2,
  };
  return StatPill(
    icon: Icons.local_fire_department_rounded,
    iconColor: flame,
    value: '${streak.count}',
    extra: frozen ? S.streakFrozenWord : null,
    extraColor: colors.streakFreeze,
    semanticLabel: frozen
        ? S.streakFrozenLabel(tage(streak.count))
        : S.streakLabel(tage(streak.count)),
    onPressed: onPressed,
  );
}

class PathHeader extends StatelessWidget {
  const PathHeader({
    super.key,
    required this.week,
    required this.phaseLine,
    required this.streak,
    required this.onOpenData,
    this.dataFocusNode,
    this.onFreezeTap,
    this.onStreakTap,
  });

  final int week;

  /// „Phase 2 · Kreuzband“
  final String phaseLine;
  final StreakView streak;

  /// Tipp auf die Pillen (Rechteck der Pille, global): erklärt Freeze bzw.
  /// Streak. `null` = reine Anzeige.
  final ValueChanged<Rect>? onFreezeTap;
  final ValueChanged<Rect>? onStreakTap;

  /// Einstieg „Deine Daten“ (öffnet das Sheet).
  final VoidCallback onOpenData;

  /// Fokusknoten des Icons: Rückgabe des Fokus nach dem Schließen des Sheets.
  final FocusNode? dataFocusNode;

  Widget _textBlock(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            container: true,
            child: Text(
              S.weekTitle(week),
              style: type.title.copyWith(color: colors.text1),
            ),
          ),
          Text(phaseLine, style: type.secondary.copyWith(color: colors.text2)),
          const CuraLabel(S.samplePathLabel, header: false),
        ],
      ),
    );
  }

  StatPill _freezePill(BuildContext context) =>
      _freezePillFor(context, streak, onFreezeTap);

  StatPill _streakPill(BuildContext context) =>
      _streakPillFor(context, streak, onStreakTap);

  @override
  Widget build(BuildContext context) {
    final StatPill freeze = _freezePill(context);
    final StatPill streakPill = _streakPill(context);
    final Widget data = _dataButton(onOpenData, dataFocusNode);
    final bool tappable = onFreezeTap != null || onStreakTap != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CuraSpace.pageMargin,
        CuraSpace.s4,
        CuraSpace.pageMargin,
        CuraSpace.s2,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double pills =
              StatPill.measureWidth(context, value: freeze.value) +
              CuraSize.statPillGap +
              StatPill.measureWidth(
                context,
                value: streakPill.value,
                extra: streakPill.extra,
              ) +
              CuraSize.statPillGap;
          final double left =
              box.maxWidth - pills - CuraSize.touchTarget - CuraSpace.s2;
          if (left >= CuraSize.pathHeaderWrapMinText) {
            // Mit antippbaren Pillen sind die Boxen je Seite um `hitInset`
            // schmaler als die sichtbaren Pillen; die Lücken wachsen um
            // dasselbe Maß, damit die sichtbaren Abstände (4 dp) und Lagen
            // bleiben und die Ziele 8 dp und mehr auseinander liegen.
            final double inset = tappable ? StatPill.hitInset : 0;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: _textBlock(context)),
                SizedBox(width: CuraSpace.s2 + inset),
                freeze,
                SizedBox(
                  width: tappable ? StatPill.boxGap : CuraSize.statPillGap,
                ),
                streakPill,
                SizedBox(width: CuraSize.statPillGap + inset),
                data,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _textBlock(context)),
                  data,
                ],
              ),
              const SizedBox(height: CuraSpace.s2),
              _pillWrap(<Widget>[freeze, streakPill], tappable: tappable),
            ],
          );
        },
      ),
    );
  }
}
