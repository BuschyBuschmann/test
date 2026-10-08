// `MannyChatButton` (Ergänzung 2, Abschnitt 2): Kreis 56 dp (Hit-Area 56),
// Manny-Kopf (Pose neutral, ca. 38 dp, aus `MannyPlaceholder`, nicht doppelt
// gezeichnet). Tooltip und Screenreader „Manny, Chat öffnen“. Aussehen und
// Verhalten siehe `ActionCircle`.
import 'package:flutter/widgets.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_metrics.dart';
import 'action_circle.dart';
import 'manny.dart';

class MannyChatButton extends StatelessWidget {
  const MannyChatButton({
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
      diameter: CuraSize.mannyChatButton,
      label: S.mannyChatOpen,
      onPressed: onPressed,
      autofocus: autofocus,
      focusNode: focusNode,
      child: const MannyPlaceholder(
        height: CuraSize.mannyHeadInButton,
        crop: MannyCrop.head,
        excludeSemantics: true,
      ),
    );
  }
}
