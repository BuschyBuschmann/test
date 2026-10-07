// `ActionCluster` (Ergänzung 2, Abschnitt 2, Plan 4.6): Anordnung der beiden
// Buttons. Modus `path`: Nachrichten-Button rechtsbündig 8 dp über dem
// Manny-Button (die Gruppe selbst setzt der `HomeShell`: rechts 16 dp, Manny-
// Button 16 dp über der Nav). Modus `today`: nur der Nachrichten-Button (der
// Manny-Button sitzt in der Primärbutton-Reihe, `PrimaryActionRow`); der
// Besitzer setzt ihn 8 dp über die Oberkante des Manny-Buttons.
//
// Das Rechteck der Gruppe stellt [rectKey] bereit (für Blase und Hinweis,
// die der Gruppe ausweichen); [rectOf] liest es in globalen Koordinaten.
import 'package:flutter/widgets.dart';

import '../../theme/cura_metrics.dart';
import 'manny_chat_button.dart';
import 'messages_button.dart';

enum ActionClusterMode { path, today }

class ActionCluster extends StatelessWidget {
  const ActionCluster({
    super.key,
    required this.mode,
    required this.onOpenMessages,
    this.onOpenChat,
    this.rectKey,
    this.messagesFocusNode,
    this.chatFocusNode,
  }) : assert(mode == ActionClusterMode.today || onOpenChat != null);

  final ActionClusterMode mode;
  final VoidCallback onOpenMessages;

  /// Nur im Modus `path` (im Modus `today` liegt der Manny-Button in der Reihe).
  final VoidCallback? onOpenChat;

  /// Schlüssel für das Rechteck der Gruppe.
  final GlobalKey? rectKey;
  final FocusNode? messagesFocusNode;

  /// Fokusrückgabe nach dem Chat (A-38: auch bei Öffnen über Manny im Pfad).
  final FocusNode? chatFocusNode;

  /// Rechteck der Gruppe in globalen Koordinaten, `null` solange nicht
  /// gebaut.
  static Rect? rectOf(GlobalKey key) {
    final RenderObject? object = key.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.attached || !object.hasSize) {
      return null;
    }
    return object.localToGlobal(Offset.zero) & object.size;
  }

  @override
  Widget build(BuildContext context) {
    final Widget messages = MessagesButton(
      onPressed: onOpenMessages,
      focusNode: messagesFocusNode,
    );
    return Column(
      key: rectKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        messages,
        if (mode == ActionClusterMode.path) ...<Widget>[
          const SizedBox(height: CuraSpace.clusterGap),
          MannyChatButton(onPressed: onOpenChat, focusNode: chatFocusNode),
        ],
      ],
    );
  }
}
