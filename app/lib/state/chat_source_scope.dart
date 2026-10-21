// `ChatSourceScope` (Plan 5, 7.10): stellt die `MannyChatSource` (KS-5)
// bereit. Die Quelle gehört nicht in den `AppController`: Der Chat speichert
// nichts, er liest nur.
import 'package:flutter/widgets.dart';

import '../data/manny_chat_source.dart';

class ChatSourceScope extends InheritedWidget {
  const ChatSourceScope({
    super.key,
    required this.source,
    required super.child,
  });

  final MannyChatSource source;

  static MannyChatSource of(BuildContext context) {
    final ChatSourceScope? scope = context
        .dependOnInheritedWidgetOfExactType<ChatSourceScope>();
    assert(scope != null, 'Kein ChatSourceScope im Widget-Baum');
    return scope!.source;
  }

  @override
  bool updateShouldNotify(ChatSourceScope oldWidget) =>
      source != oldWidget.source;
}
