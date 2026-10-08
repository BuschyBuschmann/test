// Unverbindlicher Platzhalter, keine Spec (Brief-Ergänzung 2, K10).
//
// `ChatBubble` (Mensch, Ergänzung 2, Abschnitt 2): Blase im Beispiel-Chat.
// Eigene Nachrichten rechts (`surface-opaque`, Rand `border-hair`), das
// Gegenüber links auf Glas E1 **ohne Blur** (`GlassCard`). Radius 20, Ecke zur
// Absenderseite 6 dp, höchstens 80 % der Breite, Innenabstand 12/16, `body`
// `text-1`. Die Zugehörigkeit steht über Ausrichtung **und** Screenreader-
// Präfix („Du: …“, „[Name]: …“), nie über Farbe allein.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/glass_card.dart';
import '../components/opaque_surface.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.fromMe,
    required this.semanticsLabel,
  });

  final String text;

  /// Eigene Nachricht (rechts); sonst das Gegenüber (links).
  final bool fromMe;

  /// „Du: …“ bzw. „[Name]: …“.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final Widget label = Text(
      text,
      style: type.body.copyWith(color: colors.text1),
    );
    const EdgeInsets padding = EdgeInsets.symmetric(
      vertical: CuraSize.bubblePaddingVertical,
      horizontal: CuraSize.bubblePaddingHorizontal,
    );
    final Widget bubble = fromMe
        ? OpaqueSurface(
            borderRadius: OpaqueSurface.bubbleRadius(ownSide: true),
            padding: padding,
            child: label,
          )
        : GlassCard(
            borderRadius: OpaqueSurface.bubbleRadius(ownSide: false),
            lightEdge: false,
            padding: padding,
            child: label,
          );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        return Align(
          alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: box.maxWidth * CuraSize.bubbleWidthFactor,
            ),
            child: Semantics(
              container: true,
              label: semanticsLabel,
              excludeSemantics: true,
              child: bubble,
            ),
          ),
        );
      },
    );
  }
}
