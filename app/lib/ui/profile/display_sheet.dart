// `DisplaySheet` (Design-Brief v2, 3.1, 3.2, 3.5, 7.6; Plan 3.4): das Sheet
// „Darstellung“ aus dem Profil. Opak (`card` 100 %, kein Blur). Es bündelt
//
// - **Welt:** Automatisch (folgt der Tageszeit) oder fest Morgen, Mittag, Abend,
//   Nacht;
// - **Thema:** System, Hell, Dunkel (unabhängig von der Welt);
// - **Transparenz reduzieren**, **Ton** und **Vibration** als Schalter.
//
// Jede Änderung wirkt sofort und wird über den [DisplayController] gespeichert
// (`curaone.display.v1`); das Sheet schließt mit „Fertig“. Ton und Vibration
// wirken erst, wenn es Töne und Rückmeldungen gibt (ab L4); Standard ist an.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../logic/display_settings.dart';
import '../../logic/world_time.dart';
import '../../state/display_controller.dart';
import '../../state/display_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/cura_label.dart';
import '../components/option_chips.dart';
import '../components/primary_pill.dart';
import '../components/probe_keys.dart';
import '../components/sheet_title_bar.dart';
import '../components/switch_row.dart';
import '../routes/cura_sheet_route.dart';

class DisplaySheet extends StatelessWidget {
  const DisplaySheet({super.key});

  static CuraSheetRoute<void> route(BuildContext context) {
    return CuraSheetRoute<void>(
      context: context,
      routeLabel: S.displayTitle,
      builder: (BuildContext context) => const DisplaySheet(),
    );
  }

  static const List<OptionChipData<WorldChoice>> _worlds =
      <OptionChipData<WorldChoice>>[
        OptionChipData<WorldChoice>(WorldChoice.automatic, S.worldAutomatic),
        OptionChipData<WorldChoice>(WorldChoice.morning, S.worldMorning),
        OptionChipData<WorldChoice>(WorldChoice.midday, S.worldMidday),
        OptionChipData<WorldChoice>(WorldChoice.evening, S.worldEvening),
        OptionChipData<WorldChoice>(WorldChoice.night, S.worldNight),
      ];

  static const List<OptionChipData<ThemeChoice>> _themes =
      <OptionChipData<ThemeChoice>>[
        OptionChipData<ThemeChoice>(ThemeChoice.system, S.themeSystem),
        OptionChipData<ThemeChoice>(ThemeChoice.light, S.themeLight),
        OptionChipData<ThemeChoice>(ThemeChoice.dark, S.themeDark),
      ];

  @override
  Widget build(BuildContext context) {
    final DisplayController display = DisplayScope.of(context);
    final DisplaySettings settings = display.settings;
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    Widget hint(String text) => Padding(
      padding: const EdgeInsets.only(top: CuraSpace.s2),
      child: Text(text, style: type.secondary.copyWith(color: colors.text2)),
    );
    return CuraSheetFrame(
      header: const SheetTitleBar(title: S.displayTitle),
      body: Padding(
        padding: const EdgeInsets.only(bottom: CuraSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const CuraLabel(S.displayWorldLabel),
            const SizedBox(height: CuraSpace.s2),
            OptionChips<WorldChoice>(
              options: _worlds,
              value: settings.world,
              groupLabel: S.displayWorldLabel,
              onChanged: display.setWorld,
            ),
            hint(S.displayWorldHint),
            const SizedBox(height: CuraSpace.s6),
            const CuraLabel(S.displayThemeLabel),
            const SizedBox(height: CuraSpace.s2),
            OptionChips<ThemeChoice>(
              options: _themes,
              value: settings.theme,
              groupLabel: S.displayThemeLabel,
              onChanged: display.setTheme,
            ),
            hint(S.displayThemeHint),
            const SizedBox(height: CuraSpace.s6),
            const CuraLabel(S.displayOptionsLabel),
            const SizedBox(height: CuraSpace.s2),
            SwitchRow(
              title: S.displayReduceTransparency,
              hint: S.displayReduceTransparencyHint,
              value: settings.reduceTransparency,
              onChanged: display.setReduceTransparency,
            ),
            const SizedBox(height: CuraSpace.s2),
            SwitchRow(
              title: S.displaySound,
              hint: S.displaySoundHint,
              value: settings.sound,
              onChanged: display.setSound,
            ),
            const SizedBox(height: CuraSpace.s2),
            SwitchRow(
              title: S.displayVibration,
              hint: S.displayVibrationHint,
              value: settings.vibration,
              onChanged: display.setVibration,
            ),
          ],
        ),
      ),
      footer: PrimaryPill(
        key: ProbeKeys.primary,
        label: S.done,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
