// `MannyChatScreen` (Ergänzung 2, 3.2): Vollbild-Route mit dem
// **Beispielverlauf**. Kopf (Zurück, Manny-Emblem 34 dp, „Manny“, „Dein
// Reha-Begleiter“), feste Karte „Beispielverlauf“, die Nachrichten aus der
// `MannyChatSource` (Datenobjekte, nicht fest verdrahtete Widgets), unten die
// Hinweiszeile, die deaktivierte Eingabeleiste und der Disclaimer.
//
// Schreiben ist nicht möglich: nichts wird gesendet, gespeichert oder
// abgerufen (UI-82). Der Screen liest nur den Vornamen aus dem Zustand und
// die Nachrichten aus der Quelle. Kein Mikrofon, kein „Neuer Chat“, kein
// Menü, keine Vorschlags-Chips.
import 'package:flutter/material.dart';

import '../../data/manny_chat_source.dart';
import '../../l10n/strings_de.dart';
import '../../logic/chat_model.dart';
import '../../state/app_scope.dart';
import '../../state/chat_source_scope.dart';
import '../../theme/cura_metrics.dart';
import '../components/chat_composer.dart';
import '../components/chat_header.dart';
import '../components/chat_message_list.dart';
import '../components/chat_screen_scaffold.dart';
import '../components/example_notice.dart';
import '../components/manny.dart';
import '../routes/cura_fullscreen_route.dart';

class MannyChatScreen extends StatelessWidget {
  const MannyChatScreen({super.key});

  /// Vollbild-Route „Manny, Chat“.
  static Route<void> route(BuildContext context) => CuraFullscreenRoute<void>(
    context: context,
    routeLabel: S.chatRouteName,
    builder: (BuildContext context) => const MannyChatScreen(),
  );

  @override
  Widget build(BuildContext context) {
    final MannyChatSource source = ChatSourceScope.of(context);
    final String vorname = AppScope.of(context).state.onboarding.firstName;
    final List<ChatMessage> messages = source.messages(vorname);
    return ChatScreenScaffold(
      header: const ChatHeader(
        title: S.chatTitle,
        subtitle: S.chatSubtitle,
        leading: MannyPlaceholder(
          height: CuraSize.emblemHeader,
          crop: MannyCrop.head,
          excludeSemantics: true,
        ),
      ),
      notice: const ExampleNotice(
        label: S.chatNoticeLabel,
        text: S.chatNoticeText,
      ),
      hint: const ChatHintLine(text: S.chatHint),
      composer: const ChatComposer(
        placeholder: S.chatComposerPlaceholder,
        semanticsLabel: S.chatComposerSemantics,
        sendSemanticsLabel: S.chatSendSemantics,
      ),
      disclaimer: const ChatDisclaimer(text: S.chatDisclaimer),
      bodyBuilder: (BuildContext context, ChatScaffoldExtras extras) {
        return ChatMessageList(
          messages: messages,
          leading: extras.leading,
          trailing: extras.trailing,
        );
      },
    );
  }
}
