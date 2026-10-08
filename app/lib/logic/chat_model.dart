// KS-4 (minimal): Datenmodell einer Chat-Nachricht. Kein JSON, keine
// Persistenz, kein Zeitstempel (N-17). Werte aus Brief-Ergänzung 2, 2.2.

enum ChatAuthor { user, manny, notice }

enum ChatKind { text, escalation, disclaimer, bubble }

enum ChatStatus { sending, streaming, done, aborted, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.author,
    required this.kind,
    required this.status,
    required this.text,
  });

  final String id;
  final ChatAuthor author;
  final ChatKind kind;
  final ChatStatus status;
  final String text;

  ChatMessage copyWith({
    String? id,
    ChatAuthor? author,
    ChatKind? kind,
    ChatStatus? status,
    String? text,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      author: author ?? this.author,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      text: text ?? this.text,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChatMessage &&
      other.id == id &&
      other.author == author &&
      other.kind == kind &&
      other.status == status &&
      other.text == text;

  @override
  int get hashCode => Object.hash(id, author, kind, status, text);

  @override
  String toString() => 'ChatMessage($id, $author, $status)';
}
