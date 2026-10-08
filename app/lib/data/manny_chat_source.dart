// KS-5 (nur lesend): Quelle des Manny-Chat-Verlaufs. Im ersten Ausschnitt ein
// fester Beispielverlauf; nichts wird gespeichert oder gesendet. Kein
// `canSend`, `send`, `cancel`, `retry`, `Stream` (kommt im KI-Ausschnitt).
import '../l10n/strings_de.dart';
import '../logic/chat_model.dart';

abstract class MannyChatSource {
  /// Nachrichten für den Chat; [vorname] ist der getrimmte Name aus dem
  /// Onboarding.
  List<ChatMessage> messages(String vorname);
}

/// Beispielverlauf aus Ergänzung 2, 3.2 (Platzhalter).
class ExampleMannyChatSource implements MannyChatSource {
  const ExampleMannyChatSource();

  @override
  List<ChatMessage> messages(String vorname) => <ChatMessage>[
    ChatMessage(
      id: 'example-1',
      author: ChatAuthor.manny,
      kind: ChatKind.text,
      status: ChatStatus.done,
      text: S.chatExampleManny1(vorname.trim()),
    ),
    const ChatMessage(
      id: 'example-2',
      author: ChatAuthor.user,
      kind: ChatKind.text,
      status: ChatStatus.done,
      text: S.chatExampleUser1,
    ),
    const ChatMessage(
      id: 'example-3',
      author: ChatAuthor.manny,
      kind: ChatKind.text,
      status: ChatStatus.done,
      text: S.chatExampleManny2,
    ),
  ];
}
