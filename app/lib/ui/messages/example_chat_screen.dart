// Unverbindlicher Platzhalter, keine Spec (Brief-Ergänzung 2, K10).
//
// `ExampleChatScreen` (Ergänzung 2, 3.4): Vollbild-Route „Beispiel-Chat
// [Name]“. Kopf mit Avatar 36 dp, Name und „[Rolle] · Beispiel“, feste Karte
// „Beispiel-Chat. Nur zum Ansehen.“, Verlauf aus `ChatBubble`s (eigene rechts,
// Gegenüber links, eine Tagesüberschrift), unten die Hinweiszeile „Schreiben
// in Chats folgt bald.“ und die deaktivierte Leiste „Nachricht“, **ohne**
// Disclaimer (der gehört nur in den Manny-Chat). Der Chat sieht bewusst
// anders aus als der Manny-Chat (Blasen beidseitig, kein Emblem), damit KI und
// Mensch nicht verwechselt werden. Nichts wird gesendet oder gespeichert.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../components/chat_avatar.dart';
import '../components/chat_composer.dart';
import '../components/chat_header.dart';
import '../components/chat_list_view.dart';
import '../components/chat_screen_scaffold.dart';
import '../components/cura_label.dart';
import '../components/example_notice.dart';
import '../routes/cura_fullscreen_route.dart';
import 'chat_bubble.dart';
import 'contact_row.dart';
import 'example_contacts.dart';

class ExampleChatScreen extends StatelessWidget {
  const ExampleChatScreen({super.key, required this.contact});

  final ExampleContact contact;

  /// Vollbild-Route „Beispiel-Chat [Name]“.
  static Route<void> route(BuildContext context, ExampleContact contact) =>
      CuraFullscreenRoute<void>(
        context: context,
        routeLabel: S.exampleChatRouteName(contact.name),
        builder: (BuildContext context) => ExampleChatScreen(contact: contact),
      );

  /// Abstand über Blase [i]: 12 dp unter der Tagesüberschrift, 8 dp zwischen
  /// Blasen derselben Seite, 20 dp bei Seitenwechsel.
  static double _gapBefore(List<ExampleLine> lines, int i) {
    if (i == 0) return CuraSpace.s3;
    return lines[i - 1].fromMe == lines[i].fromMe
        ? CuraSpace.blockGap
        : CuraSpace.messageGap;
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final String vorname = AppScope.of(context).state.onboarding.firstName;
    final List<ExampleLine> lines = contact.lines(vorname);
    return ChatScreenScaffold(
      header: ChatHeader(
        title: contact.name,
        subtitle: S.roleExample(contact.role),
        leading: ChatAvatar(
          initials: contact.initials,
          ringColor: ContactRow.ringColor(colors, contact.section),
          size: CuraSize.avatarHeader,
        ),
      ),
      notice: const ExampleNotice(text: S.exampleChatNotice),
      hint: const ChatHintLine(text: S.exampleChatHint),
      composer: ChatComposer(
        placeholder: S.exampleChatPlaceholder,
        semanticsLabel: S.exampleChatComposerSemantics(contact.name),
        sendSemanticsLabel: S.chatSendSemantics,
      ),
      bodyBuilder: (BuildContext context, ChatScaffoldExtras extras) {
        final Widget? tail = extras.trailing;
        return ChatListView(
          children: <Widget>[
            CuraLabel(contact.dayLong(), textAlign: TextAlign.center),
            for (int i = 0; i < lines.length; i++)
              Padding(
                padding: EdgeInsets.only(top: _gapBefore(lines, i)),
                child: ChatBubble(
                  text: lines[i].text,
                  fromMe: lines[i].fromMe,
                  semanticsLabel: lines[i].fromMe
                      ? S.chatFromYou(lines[i].text)
                      : S.chatFromPerson(contact.name, lines[i].text),
                ),
              ),
            if (tail != null)
              Padding(
                padding: const EdgeInsets.only(top: CuraSpace.messageGap),
                child: tail,
              ),
          ],
        );
      },
    );
  }
}
