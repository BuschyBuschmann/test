// Unverbindlicher Platzhalter, keine Spec (Brief-Ergänzung 2, K10).
//
// `ContactRow` (Ergänzung 2, 3.3, Plan 9): Zeile der Nachrichten-Übersicht,
// mindestens 72 dp hoch, die **ganze Zeile** antippbar, `focus-ring`, Pressed
// Weiß 10 %. Avatar 48 dp mit Initialen (Ring Physio `cat-physio`, Ärzte
// `cat-arzt`, sonst Weiß 30 %), Name `body-strong`, darunter die letzte
// Nachricht (`secondary`, `text-2`, **bricht um**), rechts die Zeitangabe
// (`caption`, `text-3`). Kein Badge, keine Zähler. Ein Semantik-Knoten:
// „Beispielkontakt [Name], [Abschnitt]. Letzte Nachricht: …, [Tag]. Öffnet
// Beispiel-Chat.“
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../components/chat_avatar.dart';
import '../components/cura_pressable.dart';
import 'example_contacts.dart';

class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.contact,
    required this.vorname,
    required this.onPressed,
    this.focusNode,
  });

  final ExampleContact contact;

  /// Vorname aus dem Onboarding (für die Vorschau und das Label).
  final String vorname;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  /// Ringfarbe des Avatars nach Abschnitt (Farbe ist nie das einzige Signal:
  /// der Abschnitt steht als Text).
  static Color ringColor(CuraColors colors, ExampleSection section) =>
      switch (section) {
        ExampleSection.physio => colors.catPhysio,
        ExampleSection.doctors => colors.catArzt,
        ExampleSection.family ||
        ExampleSection.friends => colors.avatarRingNeutral,
      };

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return CuraPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      semanticLabel: exampleContactLabel(contact, vorname),
      ringRadius: CuraRadius.chipInner,
      builder: (BuildContext context, bool pressed) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: CuraSize.contactRowMin),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pressed ? colors.pressedOverlay : null,
              borderRadius: BorderRadius.circular(CuraRadius.chipInner),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: CuraSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ChatAvatar(
                    initials: contact.initials,
                    ringColor: ringColor(colors, contact.section),
                  ),
                  const SizedBox(width: CuraSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          contact.name,
                          style: type.bodyStrong.copyWith(color: colors.text1),
                        ),
                        Text(
                          contact.lastMessage(vorname),
                          style: type.secondary.copyWith(color: colors.text2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: CuraSpace.s2),
                  Text(
                    contact.dayShort(),
                    style: type.caption.copyWith(color: colors.text3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
