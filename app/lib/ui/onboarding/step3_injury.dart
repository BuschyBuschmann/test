// Schritt 3: Verletzungstyp (Brief 6.1, UI-14). Vier `ChoiceCard`s,
// Einfachauswahl; bei „Anderes“ erscheint ein optionales Textfeld („Was ist
// passiert?“), „Weiter“ ist trotzdem aktiv. Auswahl und Freitext werden sofort
// gespeichert.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../logic/injury_type.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_metrics.dart';
import '../components/choice_card.dart';
import '../components/cura_text_field.dart';

class Step3Injury extends StatefulWidget {
  const Step3Injury({super.key, required this.prompt});

  final Widget prompt;

  @override
  State<Step3Injury> createState() => _Step3InjuryState();
}

class _Step3InjuryState extends State<Step3Injury> {
  late final TextEditingController _other;

  @override
  void initState() {
    super.initState();
    final String saved =
        context
            .getInheritedWidgetOfExactType<AppScope>()
            ?.notifier
            ?.state
            .onboarding
            .injuryOther ??
        '';
    _other = TextEditingController(text: saved);
  }

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppController c = AppScope.of(context);
    final InjuryType? selected = c.state.onboarding.injuryType;
    Widget card(InjuryType type, String title, {IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: CuraSpace.s3),
        child: ChoiceCard(
          title: title,
          selected: selected == type,
          leadingIcon: icon,
          onPressed: () => c.selectInjury(type),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        widget.prompt,
        const SizedBox(height: CuraSpace.s6),
        card(InjuryType.acl, S.injuryAcl),
        card(InjuryType.ankle, S.injuryAnkle),
        card(InjuryType.muscle, S.injuryMuscle),
        card(InjuryType.other, S.injuryOther, icon: Icons.edit_rounded),
        if (selected == InjuryType.other)
          CuraTextField(
            label: S.injuryOtherLabel,
            controller: _other,
            textInputAction: TextInputAction.done,
            onChanged: c.setInjuryOther,
          ),
      ],
    );
  }
}
