// Schritt 4: Verletzungstyp (Brief 6.1, UI-14). Vier `ChoiceCard`s,
// Einfachauswahl; bei „Anderes“ erscheint ein optionales Textfeld („Was ist
// passiert?“), „Weiter“ ist trotzdem aktiv. Auswahl und Freitext werden sofort
// gespeichert. Bei allen Typen außer Kreuzband erscheint direkt unter der
// gewählten Karte der Hinweis, dass es noch keinen eigenen Pfad gibt
// (Beispielpfad).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../logic/injury_type.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/tokens.dart';
import '../components/choice_card.dart';
import '../components/cura_text_field.dart';
import '../components/glass_card.dart';
import '../components/info_note.dart';

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
        child: Builder(
          builder: (BuildContext cardContext) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ChoiceCard(
                title: title,
                selected: selected == type,
                leadingIcon: icon,
                onPressed: () => c.selectInjury(type),
              ),
              // Nur der Kreuzband-Pfad ist ausgearbeitet. Der Hinweis steht
              // direkt unter der gewählten Karte: Sie liegt nach dem Tippen im
              // Sichtfeld, also auch der Hinweis, ohne Scrollen und Animation.
              if (selected == type && type != InjuryType.acl) ...<Widget>[
                const SizedBox(height: CuraSpace.s2),
                _RevealNote(target: cardContext),
              ],
            ],
          ),
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
            labelOnWorld: true,
            controller: _other,
            textInputAction: TextInputAction.done,
            onChanged: c.setInjuryOther,
          ),
      ],
    );
  }
}

/// Hinweis „noch keinen eigenen Pfad“: Beim Erscheinen wird die gewählte Karte
/// samt Hinweis in den sichtbaren Bereich gescrollt, falls sie (bei großer
/// Schrift oder kleinem Fenster) am unteren Rand sitzt. Bei reduzierter Bewegung ohne
/// Animation.
class _RevealNote extends StatefulWidget {
  const _RevealNote({required this.target});

  /// Kontext der Karte samt Hinweis; dieser Bereich wird sichtbar gemacht.
  final BuildContext target;

  @override
  State<_RevealNote> createState() => _RevealNoteState();
}

class _RevealNoteState extends State<_RevealNote> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bool reduced = CuraMotion.of(context).reduced;
      Scrollable.ensureVisible(
        widget.target,
        duration: reduced ? Duration.zero : MotionTokens.fast,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Auf der Welt steht der Hinweis auf einer Karte (V2-5).
    return const GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: CuraSize.cardPadding,
        vertical: CuraSpace.s3,
      ),
      child: InfoNote(text: S.injuryNoOwnPath, announce: true),
    );
  }
}
