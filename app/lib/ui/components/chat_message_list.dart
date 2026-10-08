// `ChatMessageList` (Ergänzung 2, 2.2, Plan 9): stellt eine Liste von
// `ChatMessage`-Objekten dar (Datenmodell KS-4: Autor, Art, Status), nicht
// fest verdrahtete Widgets.
//
// - Manny: Text `body` `text-1` direkt auf `bg`, **ohne Blase**; vor jedem
//   Manny-Block (aufeinanderfolgende Manny-Nachrichten) das Emblem 26 dp, der
//   Text beginnt 36 dp vom Rand.
// - Nutzer: Blase rechts (`surface-opaque`, `border-hair`, Radius 20, Ecke
//   unten rechts 6 dp, höchstens 80 % der Breite, Innenabstand 12/16).
// - Hinweis (Autor `notice`): Hinweiskarte wie `ExampleNotice`, volle Breite.
// - Art `disclaimer`: Zeile `caption` `text-3` mittig; `escalation` und
//   `bubble` vorläufig wie `text` des jeweiligen Autors (Gestaltung folgt im
//   KI-Brief). Der Status wird in diesem Ausschnitt nicht eigens gestaltet:
//   alle Werte gelten wie `done`.
// - Abstände: 20 dp zwischen Nachrichten, 8 dp innerhalb eines Manny-Blocks.
// - Semantik: „Manny: …“ und „Du: …“.
// Die Darstellung wählt über erschöpfende `switch`-Ausdrücke ohne `default`:
// ein neuer Enum-Wert meldet dem Compiler jede Lücke.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../logic/chat_model.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import 'chat_list_view.dart';
import 'example_notice.dart';
import 'manny.dart';
import 'opaque_surface.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.messages,
    this.leading,
    this.trailing,
    this.controller,
  });

  final List<ChatMessage> messages;

  /// Element vor der ersten Nachricht (scrollt mit).
  final Widget? leading;

  /// Element nach der letzten Nachricht (Hinweiszeile und Disclaimer ab
  /// Textskalierung 1,5).
  final Widget? trailing;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    final Widget? head = leading;
    if (head != null) items.add(head);
    ChatMessage? previous;
    for (final ChatMessage m in messages) {
      final bool sameBlock = _continuesBlock(previous, m);
      final bool first = previous == null && head == null;
      final double gap = first
          ? 0
          : (sameBlock ? CuraSpace.blockGap : CuraSpace.messageGap);
      items.add(
        Padding(
          padding: EdgeInsets.only(top: gap),
          child: _MessageView(message: m, showEmblem: !sameBlock),
        ),
      );
      previous = m;
    }
    final Widget? tail = trailing;
    if (tail != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: CuraSpace.messageGap),
          child: tail,
        ),
      );
    }
    return ChatListView(controller: controller, children: items);
  }

  /// Aufeinanderfolgende Manny-Texte bilden einen Block.
  static bool _continuesBlock(ChatMessage? previous, ChatMessage m) =>
      previous != null &&
      previous.author == ChatAuthor.manny &&
      m.author == ChatAuthor.manny &&
      previous.kind != ChatKind.disclaimer &&
      m.kind != ChatKind.disclaimer;
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.showEmblem});

  final ChatMessage message;
  final bool showEmblem;

  @override
  Widget build(BuildContext context) {
    final ChatMessage m = message;
    // Art zuerst: der Disclaimer ist eine eigene Zeile unabhängig vom Autor.
    return switch (m.kind) {
      ChatKind.disclaimer => _DisclaimerLine(text: m.text),
      ChatKind.text ||
      ChatKind.escalation ||
      ChatKind.bubble => switch (m.author) {
        ChatAuthor.manny => _MannyText(text: m.text, showEmblem: showEmblem),
        ChatAuthor.user => _UserBubble(text: m.text),
        ChatAuthor.notice => ExampleNotice(text: m.text),
      },
    };
  }
}

class _MannyText extends StatelessWidget {
  const _MannyText({required this.text, required this.showEmblem});

  final String text;
  final bool showEmblem;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      label: S.chatFromManny(text),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Das Emblem (26 dp) ragt aus der Textzeile (24 dp) heraus, ohne die
          // Zeilenhöhe zu verändern: der Abstand 8/20 dp gilt von Text zu Text.
          SizedBox(
            width: CuraSpace.mannyTextIndent,
            height: 0,
            child: showEmblem
                ? const OverflowBox(
                    alignment: Alignment.topLeft,
                    minHeight: 0,
                    maxHeight: CuraSize.emblemMessage,
                    child: MannyPlaceholder(
                      height: CuraSize.emblemMessage,
                      crop: MannyCrop.head,
                      excludeSemantics: true,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Text(text, style: type.body.copyWith(color: colors.text1)),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: box.maxWidth * CuraSize.bubbleWidthFactor,
            ),
            child: Semantics(
              container: true,
              label: S.chatFromYou(text),
              excludeSemantics: true,
              child: OpaqueSurface(
                borderRadius: OpaqueSurface.bubbleRadius(ownSide: true),
                padding: const EdgeInsets.symmetric(
                  vertical: CuraSize.bubblePaddingVertical,
                  horizontal: CuraSize.bubblePaddingHorizontal,
                ),
                child: Text(
                  text,
                  style: type.body.copyWith(color: colors.text1),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DisclaimerLine extends StatelessWidget {
  const _DisclaimerLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: type.caption.copyWith(color: colors.text3),
      ),
    );
  }
}
