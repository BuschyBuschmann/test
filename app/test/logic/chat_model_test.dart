// KS-4 (Gleichheit/copyWith) und KS-5 (Beispielverlauf).
import 'package:curaone/data/manny_chat_source.dart';
import 'package:curaone/logic/chat_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/text_checks.dart';

void main() {
  const ChatMessage m = ChatMessage(
    id: 'a',
    author: ChatAuthor.manny,
    kind: ChatKind.text,
    status: ChatStatus.streaming,
    text: 'Moin',
  );

  group('ChatMessage (KS-4)', () {
    test('Gleichheit und hashCode', () {
      const ChatMessage same = ChatMessage(
        id: 'a',
        author: ChatAuthor.manny,
        kind: ChatKind.text,
        status: ChatStatus.streaming,
        text: 'Moin',
      );
      expect(m, same);
      expect(m.hashCode, same.hashCode);
      expect(m == m.copyWith(text: 'Moin!'), isFalse);
    });

    test('copyWith ändert genau ein Feld', () {
      expect(m.copyWith(status: ChatStatus.done).status, ChatStatus.done);
      expect(m.copyWith(status: ChatStatus.done).text, 'Moin');
      expect(m.copyWith(text: 'neu').text, 'neu');
      expect(m.copyWith(author: ChatAuthor.user).author, ChatAuthor.user);
      expect(m.copyWith(kind: ChatKind.disclaimer).kind, ChatKind.disclaimer);
      expect(m.copyWith(id: 'b').id, 'b');
      expect(m.copyWith(), m);
    });

    test('Enum-Werte aus Brief-Ergänzung 2', () {
      expect(ChatAuthor.values.map((e) => e.name), <String>[
        'user',
        'manny',
        'notice',
      ]);
      expect(ChatKind.values.map((e) => e.name), <String>[
        'text',
        'escalation',
        'disclaimer',
        'bubble',
      ]);
      expect(ChatStatus.values.map((e) => e.name), <String>[
        'sending',
        'streaming',
        'done',
        'aborted',
        'failed',
      ]);
    });
  });

  group('ExampleMannyChatSource (KS-5)', () {
    const MannyChatSource source = ExampleMannyChatSource();

    test('Beispielverlauf mit Namen aus dem Onboarding', () {
      final List<ChatMessage> l = source.messages('Jakob');
      expect(l, hasLength(3));
      expect(l.map((e) => e.author), <ChatAuthor>[
        ChatAuthor.manny,
        ChatAuthor.user,
        ChatAuthor.manny,
      ]);
      expect(l[0].text, 'Moin Jakob. Wie läuft dein Tag?');
      expect(l[1].text, 'Ich hab heute keine Zeit.');
      expect(
        l[2].text,
        'Dann machen wir die 10-Minuten-Variante. Das schaffst du. Sag mir kurz Bescheid, wenn du durch bist.',
      );
      expect(l.every((e) => e.kind == ChatKind.text), isTrue);
      expect(l.every((e) => e.status == ChatStatus.done), isTrue);
      expect(l.map((e) => e.id).toSet(), hasLength(3));
    });

    test('neuer Name nach Löschen: gleicher Verlauf, anderer Name', () {
      expect(
        source.messages(' Lena ').first.text,
        'Moin Lena. Wie läuft dein Tag?',
      );
      expect(
        source.messages('Jakob').skip(1).toList(),
        source.messages('Lena').skip(1).toList(),
      );
    });

    test('ist reiner Lesezugriff: gleiche Eingabe, gleiche Ausgabe', () {
      expect(source.messages('A'), source.messages('A'));
    });

    test('Satzzahl des letzten Manny-Texts (Chat darf mehr als Blasen)', () {
      expect(countSentences(source.messages('A')[2].text), 3);
    });
  });
}
