// Unverbindlicher Platzhalter, keine Spec (Brief-Ergänzung 2, K10).
//
// `MessagesScreen` (Ergänzung 2, 3.3): Vollbild-Route „Nachrichten“ mit der
// festen Karte „Beispiel-Ansicht. Echte Chats folgen.“ (ab Textskalierung 1,5
// als erstes Element der Liste) und vier Abschnitten (Physio, Familie,
// Freunde, Ärzte; Überschriften für den Screenreader) mit den sechs
// Beispielkontakten. Weder Badge noch Suche noch „Neuer Chat“. Tipp auf eine
// Zeile öffnet den Beispiel-Chat über dieser Route; Zurück führt hierher, der
// Fokus kehrt auf die Zeile zurück (Plan 4.4). Alles nur zum Ansehen: nichts
// wird gesendet oder gespeichert.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../l10n/strings_de.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_metrics.dart';
import '../components/chat_header.dart';
import '../components/chat_screen_scaffold.dart';
import '../components/cura_label.dart';
import '../components/example_notice.dart';
import '../components/probe_keys.dart';
import '../routes/cura_fullscreen_route.dart';
import '../routes/route_focus.dart';
import 'contact_row.dart';
import 'example_chat_screen.dart';
import 'example_contacts.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  /// Vollbild-Route „Nachrichten“.
  static Route<void> route(BuildContext context) => CuraFullscreenRoute<void>(
    context: context,
    routeLabel: S.messagesTitle,
    builder: (BuildContext context) => const MessagesScreen(),
  );

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final Map<String, FocusNode> _focus = <String, FocusNode>{
    for (final ExampleContact c in kExampleContacts) c.id: FocusNode(),
  };

  @override
  void dispose() {
    for (final FocusNode n in _focus.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _open(ExampleContact contact) {
    pushReturningFocus<void>(
      Navigator.of(context),
      ExampleChatScreen.route(context, contact),
      trigger: _focus[contact.id],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String vorname = AppScope.of(context).state.onboarding.firstName;
    return ChatScreenScaffold(
      header: const ChatHeader(title: S.messagesTitle, largeTitle: true),
      notice: const ExampleNotice(text: S.messagesNotice),
      noticeScrollsAlong: true,
      bodyBuilder: (BuildContext context, ChatScaffoldExtras extras) {
        final Widget? head = extras.leading;
        return ListView(
          key: ProbeKeys.scroll,
          // Sechs feste Kontakte: vollständig bauen (exakte Höhen, jede Zeile
          // vorhanden und erreichbar).
          scrollCacheExtent: const ScrollCacheExtent.pixels(
            CuraSize.smallListCacheExtent,
          ),
          padding: const EdgeInsets.fromLTRB(
            CuraSpace.pageMargin,
            CuraSpace.s3,
            CuraSpace.pageMargin,
            CuraSpace.pageMargin,
          ),
          children: <Widget>[
            ?head,
            for (final ExampleSection section
                in ExampleSection.values) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  top: CuraSpace.s5,
                  bottom: CuraSpace.s1,
                ),
                child: CuraLabel(section.title),
              ),
              for (final ExampleContact c in exampleContactsIn(
                section,
              )) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: CuraSpace.s2),
                  child: ContactRow(
                    contact: c,
                    vorname: vorname,
                    focusNode: _focus[c.id],
                    onPressed: () => _open(c),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
