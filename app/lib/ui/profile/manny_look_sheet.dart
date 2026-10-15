// `MannyLookSheet` (Design-Brief v2, Ergänzung 1, 6b): das Sheet der Profil-
// Zeile „Manny-Look“. Opak (`card` 100 %, kein Blur), mit denselben zwei
// Karten wie im Onboarding (`MannyLookPicker`), dem Hinweis „Gilt für die ganze
// App.“ und dem Button „Fertig“.
//
// **Wechsel ohne Neustart:** Ein Tipp auf eine Karte speichert die Wahl sofort
// (`AppController.setMannyLook`); die Zeile im Hintergrund, Pfad, Heute, Chats,
// Chat-Vollbild und Manny-Knopf lesen die Variante aus dem Zustand und zeigen
// sie ohne weiteres Zutun. Der Screenreader hört „Manny-Look: Ohne Brille“.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/strings_de.dart';
import '../../logic/manny_look.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/manny_look_picker.dart';
import '../components/primary_pill.dart';
import '../components/probe_keys.dart';
import '../components/sheet_title_bar.dart';
import '../routes/cura_sheet_route.dart';

class MannyLookSheet extends StatelessWidget {
  const MannyLookSheet({super.key});

  static CuraSheetRoute<void> route(BuildContext context) {
    return CuraSheetRoute<void>(
      context: context,
      routeLabel: S.lookSheetTitle,
      builder: (BuildContext context) => const MannyLookSheet(),
    );
  }

  void _choose(BuildContext context, MannyLook look) {
    AppScope.of(context).setMannyLook(look);
    SemanticsService.sendAnnouncement(
      View.of(context),
      S.mannyLookEcho(
        look == MannyLook.brille ? S.mannyLookWith : S.mannyLookWithout,
      ),
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return CuraSheetFrame(
      header: const SheetTitleBar(title: S.lookSheetTitle),
      body: Padding(
        padding: const EdgeInsets.only(bottom: CuraSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MannyLookPicker(
              value: controller.state.mannyLook,
              onChanged: (MannyLook look) => _choose(context, look),
            ),
            const SizedBox(height: CuraSpace.s4),
            Text(
              S.lookSheetHint,
              style: type.secondary.copyWith(color: colors.text2),
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
