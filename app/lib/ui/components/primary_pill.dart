// `PrimaryPill` (Design-Brief v2, 4): Primärbutton. Verlauf Mandarine, Text
// `on-accent` (≥ 6,5:1), 56 dp hoch, Lichtkante oben, Schein unten, kein harter
// Rand; gedrückt 2 % kleiner mit halbem Schein; deaktiviert Weiß 50 % mit
// `ink-2`-Text und Rand (V2-31). Die Umsetzung liegt in `PillButton`
// (gemeinsame Bedienbasis mit `GlassPill`).
import 'package:flutter/widgets.dart';

import '../../l10n/strings_de.dart';
import 'pill_button.dart';

class PrimaryPill extends StatelessWidget {
  const PrimaryPill({
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
