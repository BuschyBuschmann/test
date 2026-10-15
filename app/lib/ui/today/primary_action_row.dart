// `PrimaryActionRow` (Ergänzung 2, Abschnitt 2 und 3.1, Plan 4.6; Brief v2, 5):
// die feste Primärbutton-Reihe des Tabs Heute. „Training eintragen“ (Primär)
// bzw. „Heute erledigt“ (deaktiviert, mit Haken) teilt sich die Reihe mit dem
// Manny-Knopf: Breite des Primärbuttons = verfügbare Breite − 8 − 56 (bei
// 320 dp genau 224 dp, 96 dp nach Seitenrändern), Höhe 56 dp, unten bündig.
// Bricht der Text um (große Schrift), wächst nur der Primärbutton; der
// Manny-Knopf bleibt unten bündig. Den Nachrichten-Knopf gibt es nicht mehr
// (Nachrichten sind das Ziel Chats).
//
// Fokusreihenfolge: „Training eintragen“, Manny-Knopf, danach die Leiste.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../components/manny_chat_button.dart';
import '../components/pill_button.dart';
import '../components/probe_keys.dart';
import '../home/home_shell.dart';

/// Zustand des Primärbuttons (Brief 6.3).
enum TrainingButtonState {
  /// „Training eintragen“, bedienbar.
  start,

  /// „Heute erledigt“ mit Haken, nicht bedienbar (Erledigt gewinnt auch bei
  /// leerer Liste, B-6).
  done,

  /// „Training eintragen“, deaktiviert (leere Liste).
  disabled,
}

class PrimaryActionRow extends StatelessWidget {
  const PrimaryActionRow({
    super.key,
    required this.state,
    required this.onStart,
    required this.onOpenChat,
    this.startFocusNode,
    this.chatFocusNode,
  });

  final TrainingButtonState state;
  final VoidCallback onStart;
  final VoidCallback onOpenChat;

  final FocusNode? startFocusNode;
  final FocusNode? chatFocusNode;

  @override
  Widget build(BuildContext context) {
    final bool done = state == TrainingButtonState.done;
    final CuraColors colors = CuraColors.of(context);
    final Widget button = PillButton(
      key: ProbeKeys.primary,
      label: done ? S.trainingDone : S.trainingLog,
      // Ohne Symbol im Start-Zustand: das Play-Zeichen versprach einen Start,
      // und „Training eintragen“ passt mit Symbol nicht mehr in 224 dp (UI-73).
      icon: done ? Icons.check_rounded : null,
      onPressed: state == TrainingButtonState.start ? onStart : null,
      focusNode: startFocusNode,
    );
    // Die Reihe steht fest über scrollendem Inhalt: Hinter dem deaktivierten
    // Button (Füllung Weiß 10 %, „Heute erledigt“, leere Liste) scheint sonst
    // der Text der Liste durch. Der Untergrund `bg` darunter hält ihn zurück.
    final Widget primary = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(CuraRadius.pill),
      ),
      child: button,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(HomeShellState.focusOrderStart),
            child: primary,
          ),
        ),
        const SizedBox(width: CuraSpace.clusterGap),
        FocusTraversalOrder(
          order: const NumericFocusOrder(HomeShellState.focusOrderManny),
          child: MannyButton(onPressed: onOpenChat, focusNode: chatFocusNode),
        ),
      ],
    );
  }
}
