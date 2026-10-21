// `ProfileScreen` (Design-Brief v2, 7.6, Ergänzung 1, 6b; Plan 3.4): das Ziel
// „Profil“ der Leiste.
//
// - Kopf-Karte mit Avatar-Kugel (Initiale), Name und „Verletzung · Phase ·
//   Woche“ aus dem lokalen Zustand.
// - Drei Kacheln: Streak, Trainingstage (erledigte Trainingstage im Pfad) und
//   Freezes. Alles wird aus dem Zustand abgeleitet, nichts neu gespeichert.
// - Liste (je Zeile ≥ 56 dp, Chevron): Deine Daten (bestehendes Sheet),
//   **Manny-Look** direkt über **Darstellung**, Hilfe und Datenschutz.
//   „Mein Plan und meine Verletzung“ und „Frage an meinen Physio“ kommen mit
//   späteren Lieferungen; „Erinnerungen“ entfällt, bis es eine Spezifikation
//   gibt (Plan 3.4, O-23).
//
// Die Sheets „Manny-Look“ und „Darstellung“ öffnen über der Home-Route; der
// Fokus kehrt auf die Zeile zurück.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../logic/manny_look.dart';
import '../../logic/path_generator.dart';
import '../../logic/profile_summary.dart';
import '../../logic/streak.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../components/avatar_orb.dart';
import '../components/glass_card.dart';
import '../components/header_card.dart';
import '../components/list_row.dart';
import '../components/manny.dart';
import '../components/tab_page.dart';
import '../home/home_shell.dart';
import '../routes/app_routes.dart';
import '../routes/route_focus.dart';
import 'display_sheet.dart';
import 'manny_look_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FocusNode _dataFocus = FocusNode(debugLabel: 'Profil: Deine Daten');
  final FocusNode _lookFocus = FocusNode(debugLabel: 'Profil: Manny-Look');
  final FocusNode _displayFocus = FocusNode(debugLabel: 'Profil: Darstellung');
  final FocusNode _helpFocus = FocusNode(debugLabel: 'Profil: Hilfe');

  @override
  void dispose() {
    _dataFocus.dispose();
    _lookFocus.dispose();
    _displayFocus.dispose();
    _helpFocus.dispose();
    super.dispose();
  }

  Future<void> _open(Route<void> route, FocusNode trigger) =>
      pushReturningFocus<void>(Navigator.of(context), route, trigger: trigger);

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final state = controller.state;
    final progress = computePathProgress(
      injuryDate: state.onboarding.injuryDate,
      today: controller.today,
      completedUnitIds: state.path.completedUnitIds,
    );
    final StreakView streak = StreakEngine.view(state.streak);
    final String name = state.onboarding.firstName.trim();
    final MannyLook look = state.mannyLook;
    final String lookName = look == MannyLook.brille
        ? S.mannyLookWith
        : S.mannyLookWithout;
    return TabPage(
      header: HeaderCard(
        leading: AvatarOrb(initial: nameInitial(name)),
        title: name.isEmpty ? S.navProfile : name,
        subtitle: S.profileSubtitle(
          injuryShortName(state.onboarding.injuryType),
          progress.phase,
          progress.week,
        ),
      ),
      children: <Widget>[
        _ProfileTiles(
          streak: streak.count,
          trainingDays: trainingDaysDone(progress),
          freezes: streak.freezes,
        ),
        ListCard(
          rows: <Widget>[
            ListRow(
              title: S.profileRowData,
              leading: ListRow.iconTile(context, Icons.person_outline_rounded),
              semanticLabel: S.profileRowLabel(S.profileRowData, null),
              focusNode: _dataFocus,
              onPressed: () =>
                  HomeShellScope.of(context).openDataSheet(trigger: _dataFocus),
            ),
            ListRow(
              title: S.profileRowLook,
              value: lookName,
              leading: const MannyAvatar(size: CuraSize.listRowTile),
              semanticLabel: S.profileRowLabel(S.profileRowLook, lookName),
              focusNode: _lookFocus,
              onPressed: () => _open(MannyLookSheet.route(context), _lookFocus),
            ),
            ListRow(
              title: S.profileRowDisplay,
              leading: ListRow.iconTile(context, Icons.palette_outlined),
              semanticLabel: S.profileRowLabel(S.profileRowDisplay, null),
              focusNode: _displayFocus,
              onPressed: () =>
                  _open(DisplaySheet.route(context), _displayFocus),
            ),
            ListRow(
              title: S.profileRowHelp,
              leading: ListRow.iconTile(context, Icons.help_outline_rounded),
              semanticLabel: S.profileRowLabel(S.profileRowHelp, null),
              focusNode: _helpFocus,
              onPressed: () => _open(AppRoutes.privacy(context), _helpFocus),
            ),
          ],
        ),
      ],
    );
  }
}

/// Die drei Kacheln. Passt das längste Label („Trainingstage“) in die Spalte,
/// stehen sie nebeneinander (Symbol, Zahl, Label übereinander); sonst (große
/// Schrift, schmales Gerät) untereinander, je Kachel Symbol, Zahl und Label in
/// einer Zeile. Das Label bricht nie mitten im Wort um.
class _ProfileTiles extends StatelessWidget {
  const _ProfileTiles({
    required this.streak,
    required this.trainingDays,
    required this.freezes,
  });

  final int streak;
  final int trainingDays;
  final int freezes;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final List<_TileData> tiles = <_TileData>[
      _TileData(
        icon: Icons.local_fire_department_rounded,
        iconColor: colors.accentText,
        title: S.profileTileStreak,
        value: streak,
      ),
      _TileData(
        icon: Icons.event_available_rounded,
        iconColor: colors.catUebung,
        title: S.profileTileDays,
        value: trainingDays,
      ),
      _TileData(
        icon: Icons.ac_unit_rounded,
        iconColor: colors.streakFreeze,
        title: S.profileTileFreezes,
        value: freezes,
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: S.profileTileDays, style: type.secondary),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        final double labelWidth = painter.width.ceilToDouble();
        painter.dispose();
        final double inner =
            (box.maxWidth - 2 * CuraSpace.s2) / tiles.length - 2 * CuraSpace.s2;
        final bool side = labelWidth + CuraSize.measureSlack <= inner;
        if (side) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < tiles.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: CuraSpace.s2),
                  Expanded(child: _Tile(data: tiles[i], stacked: true)),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < tiles.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: CuraSpace.s2),
              _Tile(data: tiles[i], stacked: false),
            ],
          ],
        );
      },
    );
  }
}

class _TileData {
  const _TileData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int value;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.data, required this.stacked});

  final _TileData data;

  /// Symbol, Zahl und Label übereinander (sonst in einer Zeile).
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final Widget icon = ExcludeSemantics(
      child: Icon(
        data.icon,
        size: CuraComponent.iconSize,
        color: data.iconColor,
      ),
    );
    final Widget number = Text(
      data.value.toString(),
      style: type.numeral.copyWith(color: colors.text1),
    );
    final Widget label = Text(
      data.title,
      style: type.secondary.copyWith(color: colors.text2),
    );
    return Semantics(
      container: true,
      label: S.profileTileLabel(data.title, data.value),
      excludeSemantics: true,
      child: GlassCard(
        padding: const EdgeInsets.all(CuraSpace.s2),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[icon, number, label],
              )
            : Row(
                children: <Widget>[
                  icon,
                  const SizedBox(width: CuraSpace.s3),
                  number,
                  const SizedBox(width: CuraSpace.s3),
                  Expanded(child: label),
                ],
              ),
      ),
    );
  }
}
