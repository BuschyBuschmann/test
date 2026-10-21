// Unverbindlicher Platzhalter, keine Spec (Brief-Ergänzung 2, K10).
//
// `ChatsScreen` (Design-Brief v2, 7.7): das Ziel „Chats“ der Leiste. Kopf-Karte
// „Chats“, darunter **Manny angeheftet** als oberste Unterhaltung (Kopf auf
// heller Scheibe, Symbol „Angeheftet“ mit Text, nicht entfernbar), die Karte
// „Beispieldaten“ und die Beispielkontakte aus Ergänzung 2 in ihren
// Abschnitten (Physio, Familie, Freunde, Ärzte), je Abschnitt eine Karte.
// Initialen-Avatare, keine Personenfotos. Tipp auf eine Zeile öffnet den
// Vollbild-Chat über der Home-Route (ohne Leiste); der Fokus kehrt auf die
// Zeile zurück. Alles nur zum Ansehen: nichts wird gesendet oder gespeichert.
//
// Die Beispieldaten tragen keinen Ungelesen-Zähler: das Badge der Leiste
// erscheint erst mit echten Chats (V2-20).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../components/cura_label.dart';
import '../components/cura_pressable.dart';
import '../components/example_notice.dart';
import '../components/glass_card.dart';
import '../components/header_card.dart';
import '../components/manny.dart';
import '../components/tab_page.dart';
import '../home/home_shell.dart';
import '../routes/app_routes.dart';
import 'contact_row.dart';
import 'example_contacts.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final FocusNode _mannyFocus = FocusNode(debugLabel: 'Chat Manny');
  final Map<String, FocusNode> _focus = <String, FocusNode>{
    for (final ExampleContact c in kExampleContacts) c.id: FocusNode(),
  };

  @override
  void dispose() {
    _mannyFocus.dispose();
    for (final FocusNode n in _focus.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _openExample(ExampleContact contact) {
    HomeShellScope.of(context).openFullscreen(
      AppRoutes.exampleChat(context, contact),
      _focus[contact.id]!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String vorname = AppScope.of(context).state.onboarding.firstName;
    return TabPage(
      header: const HeaderCard(title: S.chatsTitle),
      children: <Widget>[
        GlassCard(
          padding: const EdgeInsets.all(CuraSpace.s2),
          child: _MannyRow(
            focusNode: _mannyFocus,
            onPressed: () =>
                HomeShellScope.of(context).openChat(trigger: _mannyFocus),
          ),
        ),
        const ExampleNotice(label: S.chatsExampleLabel, text: S.messagesNotice),
        for (final ExampleSection section in ExampleSection.values)
          GlassCard(
            padding: const EdgeInsets.fromLTRB(
              CuraSpace.s2,
              CuraSpace.s4,
              CuraSpace.s2,
              CuraSpace.s2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CuraSpace.s2),
                  child: CuraLabel(section.title),
                ),
                for (final ExampleContact c in exampleContactsIn(section))
                  Padding(
                    // 8 dp zwischen den Zeilen: Ziele liegen nie dichter (UI-32).
                    padding: const EdgeInsets.only(top: CuraSpace.s2),
                    child: ContactRow(
                      contact: c,
                      vorname: vorname,
                      focusNode: _focus[c.id],
                      onPressed: () => _openExample(c),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Manny, angeheftet: Kopf auf heller Scheibe (48 dp), Name, Rolle und die
/// Marke „Angeheftet“ (Symbol **und** Text). Ein Semantik-Knoten.
class _MannyRow extends StatelessWidget {
  const _MannyRow({required this.onPressed, required this.focusNode});

  final VoidCallback onPressed;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return CuraPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      semanticLabel: S.chatsMannyRowLabel,
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
              padding: const EdgeInsets.symmetric(
                horizontal: CuraSpace.s2,
                vertical: CuraSpace.s3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const MannyAvatar(size: CuraSize.avatar),
                  const SizedBox(width: CuraSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          S.chatTitle,
                          style: type.bodyStrong.copyWith(color: colors.text1),
                        ),
                        Text(
                          S.chatSubtitle,
                          style: type.secondary.copyWith(color: colors.text2),
                        ),
                        const SizedBox(height: CuraSpace.s1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.push_pin_rounded,
                              size: CuraSize.hintIcon,
                              color: colors.text2,
                            ),
                            const SizedBox(width: CuraSpace.s1),
                            Flexible(
                              child: Text(
                                S.chatsPinned,
                                style: type.caption.copyWith(
                                  color: colors.text2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
