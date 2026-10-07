// `MessagesButton` (Ergänzung 2, Abschnitt 2): Kreis 48 dp, sonst wie
// `MannyChatButton`. Icon `chat_bubble_outline_rounded` 24 dp `text-1`.
// Tooltip und Screenreader „Nachrichten“.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import 'action_circle.dart';

class MessagesButton extends StatelessWidget {
  const MessagesButton({
    super.key,
    required this.onPressed,
    this.autofocus = false,
    this.focusNode,
  });

  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return ActionCircle(
      diameter: CuraSize.messagesButton,
      label: S.messagesButton,
      onPressed: onPressed,
      autofocus: autofocus,
      focusNode: focusNode,
      child: Icon(
        Icons.chat_bubble_outline_rounded,
        size: CuraComponent.iconSize,
        color: CuraColors.of(context).text1,
      ),
    );
  }
}
