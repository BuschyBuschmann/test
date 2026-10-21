// Schritt 1: „Wie soll Manny aussehen?“ (Design-Brief v2, Ergänzung 1, 6a,
// V2-65 bis V2-67, V2-75). Die zwei Karten `MannyLookPicker` sind Manny selbst:
// keine Figur oben, keine Blase, keine Mikrofon-Zeile. „Mit Brille“ ist
// vorgewählt, „Weiter“ ist immer aktiv. Ein Tipp auf eine Karte speichert die
// Wahl sofort (ein Neustart mitten im Onboarding behält sie); darunter steht die
// Hinweiskarte „Du kannst das jederzeit im Profil ändern.“ (Text auf einer
// Karte, V2-5).
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/strings_de.dart';
import '../../logic/manny_look.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/glass_card.dart';
import '../components/manny_look_picker.dart';

class StepLook extends StatelessWidget {
  const StepLook({super.key});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MannyLookPicker(
          value: controller.state.mannyLook,
          onChanged: (MannyLook look) => _choose(context, look),
        ),
        const SizedBox(height: CuraSpace.s3),
        GlassCard(
          child: Text(
            S.mannyLookHint,
            style: type.body.copyWith(color: colors.text1),
          ),
        ),
      ],
    );
  }
}
