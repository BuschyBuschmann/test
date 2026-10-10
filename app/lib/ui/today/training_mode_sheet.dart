// `TrainingModeSheet` (Brief 6.3, Spec 2, Plan 4.4): „Wie willst du
// trainieren?“ mit den drei Modi. Im ersten Ausschnitt ist nur **Manuell**
// aktiv („Ich trage es nachher ein“); Passiv und Aktiv sind sichtbar, aber
// deaktiviert mit dem Zusatz „Folgt“. Die Fußleiste „Training eintragen“
// bestätigt den Modus Manuell. Die Feedback-Abfrage gehört nicht in den
// Ausschnitt.
//
// Aufbau: `CuraSheetFrame` (E2, fester Kopf mit Titel und „Schließen“,
// scrollender Mittelteil, feste Fußleiste). Die Route öffnet [TodayScreen]
// über [TrainingModeSheet.route] und meldet sie im Register der Heute-Routen
// an, damit ein Tageswechsel sie schließen kann.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../components/choice_card.dart';
import '../components/glass_card.dart';
import '../components/header_icon_button.dart';
import '../components/pill_button.dart';
import '../components/probe_keys.dart';
import '../routes/cura_sheet_route.dart';

class TrainingModeSheet extends StatelessWidget {
  const TrainingModeSheet({super.key, required this.onLog});

  /// „Training eintragen“.
  final VoidCallback onLog;

  /// Die Sheet-Route; [onLog] bekommt den Kontext der Route (zum Schließen).
  static CuraSheetRoute<void> route(
    BuildContext context, {
    required void Function(BuildContext sheetContext) onLog,
  }) {
    return CuraSheetRoute<void>(
      context: context,
      routeLabel: S.trainingSheetTitle,
      builder: (BuildContext sheetContext) =>
          TrainingModeSheet(onLog: () => onLog(sheetContext)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return CuraSheetFrame(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          CuraSpace.pageMargin,
          CuraSpace.s6,
          CuraSpace.s2,
          CuraSpace.s2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                // Der Titel skaliert bis 150 % mit (wie die Kopfzeilen der
                // Vollbild-Routen): bei 200 % auf 320 dp füllte er sonst den
                // Kopf und ließ den Modi keinen Platz.
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: CuraSize.headerTitleMaxTextScale,
                  child: Text(
                    S.trainingSheetTitle,
                    style: type.title.copyWith(color: colors.text1),
                  ),
                ),
              ),
            ),
            HeaderIconButton(
              icon: Icons.close_rounded,
              tooltip: S.close,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: CuraSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChoiceCard(
              title: S.modeManual,
              subtitle: S.modeManualHint,
              leadingIcon: Icons.edit_note_rounded,
              selected: true,
              onPressed: () {},
            ),
            const SizedBox(height: CuraSpace.s3),
            const _DisabledMode(
              icon: Icons.sensors_rounded,
              title: S.modePassive,
            ),
            const SizedBox(height: CuraSpace.s3),
            const _DisabledMode(
              icon: Icons.play_circle_rounded,
              title: S.modeActive,
            ),
          ],
        ),
      ),
      footer: PillButton(
        key: ProbeKeys.primary,
        label: S.trainingLog,
        onPressed: onLog,
      ),
    );
  }
}

/// Passiv und Aktiv: sichtbar, nicht bedienbar, mit dem Zusatz „Folgt“
/// (Text, nicht nur gedimmt). Nie ein Fokusziel.
class _DisabledMode extends StatelessWidget {
  const _DisabledMode({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      enabled: false,
      label: S.modeDisabledLabel(title),
      excludeSemantics: true,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: CuraSize.cardPadding,
          vertical: CuraSpace.s3,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: CuraComponent.choiceInnerMinHeight,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: CuraComponent.iconSize,
                color: colors.disabledContent,
              ),
              const SizedBox(width: CuraComponent.choiceIconGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: type.heading.copyWith(
                        color: colors.disabledContent,
                      ),
                    ),
                    Text(
                      S.modeSoon,
                      style: type.secondary.copyWith(
                        color: colors.disabledContent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
