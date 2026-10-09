// `PathHeader` (Brief 5.9, Ergänzung 1, 3.1, Plan 9): fixe Kopfzeile des Pfads.
// Links „Woche N“ (`title`), „Phase M · Kreuzband“ (`secondary`) und das kleine
// Label „Beispielpfad“ (UI-25, immer); rechts Freeze-Pille, Streak-Pille und
// der Einstieg „Deine Daten“ (`HeaderIconButton`, `person_outline_rounded`).
//
// Zwei Layouts: **Zeile** (Textblock, Freeze, 4 dp, Streak, 4 dp, Icon) und,
// wenn der Textblock links weniger als 150 dp bekäme (320 dp oder große
// Schrift), **Umbruch** (Zeile 1: Textblock und Icon; Zeile 2, 8 dp tiefer:
// beide Pillen linksbündig, dürfen selbst umbrechen). Es wird nichts
// abgeschnitten oder überlagert. Die Pillen sind reine Information und kein
// Tap-Ziel (B-8).
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

class PathHeader extends StatelessWidget {
  const PathHeader({
    super.key,
    required this.week,
    required this.phaseLine,
    required this.streak,
    required this.onOpenData,
  });

  final int week;

  /// „Phase 2 · Kreuzband“
  final String phaseLine;
  final StreakView streak;

  /// Einstieg „Deine Daten“ (das Sheet liefert U4).
  final VoidCallback onOpenData;

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

  StatPill _freezePill(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return StatPill(
      icon: Icons.ac_unit_rounded,
      iconColor: colors.streakFreeze,
      value: '${streak.freezes}',
      valueColor: colors.streakFreeze,
      semanticLabel: S.freezesLabel(streak.freezes),
    );
  }

  StatPill _streakPill(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final bool frozen = streak.display == StreakDisplay.frozen;
    final Color flame = switch (streak.display) {
      StreakDisplay.active => colors.accentHi,
      StreakDisplay.frozen => colors.streakFreeze,
      StreakDisplay.reset => colors.text3,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final StatPill freeze = _freezePill(context);
    final StatPill streakPill = _streakPill(context);
    final Widget data = HeaderIconButton(
      icon: Icons.person_outline_rounded,
      tooltip: S.dataSheetOpen,
      onPressed: onOpenData,
    );
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
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: _textBlock(context)),
                const SizedBox(width: CuraSpace.s2),
                freeze,
                const SizedBox(width: CuraSize.statPillGap),
                streakPill,
                const SizedBox(width: CuraSize.statPillGap),
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
              Wrap(
                spacing: CuraSize.statPillGap,
                runSpacing: CuraSize.statPillGap,
                children: <Widget>[freeze, streakPill],
              ),
            ],
          );
        },
      ),
    );
  }
}
