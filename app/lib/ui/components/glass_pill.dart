// `GlassPill` (Design-Brief v2, 4): Sekundärbutton. Weiß 90 % **ohne Blur**,
// 52 dp hoch, Rand `border-control`, Text `ink-1`. Die Pille bleibt in beiden
// Themen hell mit dunkler Tinte (Annahme: Brief nennt nur `ink-1`; im Thema
// Dunkel wäre `text-1` auf Weiß nicht lesbar). Die Umsetzung liegt in
// `PillButton` (gemeinsame Bedienbasis mit `PrimaryPill`).
import 'package:flutter/widgets.dart';

import '../../l10n/strings_de.dart';
import 'pill_button.dart';

class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.busyStatus = S.busyStatusDefault,
    this.expand = true,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;

  /// `null` = deaktiviert.
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final String busyStatus;
  final bool expand;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return PillButton(
      label: label,
      variant: PillButtonVariant.neutral,
      onPressed: onPressed,
      icon: icon,
      busy: busy,
      busyStatus: busyStatus,
      expand: expand,
      autofocus: autofocus,
      focusNode: focusNode,
    );
  }
}
