// `ChatScreenScaffold` und `ChatFooterLayout` (Ergänzung 2, Abschnitt 2, 2.1,
// 2.2; Plan 4.4, 9): Gerüst der Vollbild-Routen Manny-Chat, Nachrichten und
// Beispiel-Chat, ohne Nav und ohne Button-Gruppe.
//
// Aufbau von oben nach unten: Kopf (opak `bg`, 1 dp `border-hair` unten,
// Marker `header`), optional die feste Hinweiskarte, der Inhalt, optional der
// feste Fuß (Hinweiszeile, Eingabeleiste, Disclaimer; Marker
// `overlay:chat-footer`). Glow wie auf den anderen Screens, **kein**
// `BackdropFilter`. Escape schließt die Route (`DismissIntent` schließt nur
// Modal-Routen, darum ein eigenes `Shortcuts`/`Actions`-Paar).
//
// `ChatFooterLayout`: Der Fuß belegt höchstens 40 % der Höhe. Ab Textskalierung
// 1,5 **oder** bei verfügbarer Höhe unter 400 dp (K6; Route ohne Systemleisten
// und ohne Tastatur) wandern Hinweiszeile und Disclaimer ans Ende der Liste
// (scrollen mit); die Leiste bleibt fest. Unter denselben Bedingungen wandert
// die Hinweiskarte (Manny-Chat, Nachrichten und Beispiel-Chat) als erstes
// Element in die Liste; der Inhalt muss `extras.leading` darum immer zeigen.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import 'probe_keys.dart';
import 'screen_frame.dart';

/// Elemente, die ab Textskalierung 1,5 in die Liste wandern.
class ChatScaffoldExtras {
  const ChatScaffoldExtras({this.leading, this.trailing});

  /// Vor dem ersten Eintrag (Hinweiskarte der Nachrichten).
  final Widget? leading;

  /// Nach dem letzten Eintrag (Hinweiszeile und Disclaimer).
  final Widget? trailing;
}

typedef ChatBodyBuilder = Widget Function(
  BuildContext context,
  ChatScaffoldExtras extras,
);

/// Fester Fuß: Hinweiszeile, Eingabeleiste, Disclaimer (je nach
/// Textskalierung).
class ChatFooterLayout extends StatelessWidget {
  const ChatFooterLayout({
    super.key,
    required this.composer,
    required this.along,
    this.hint,
    this.disclaimer,
  });

  final Widget composer;
  final Widget? hint;
  final Widget? disclaimer;

  /// Hinweiszeile und Disclaimer stehen am Listenende statt im Fuß
  /// ([scrollsAlong], vom Gerüst außerhalb von `SafeArea` ermittelt).
  final bool along;

  /// Verfügbare Höhe der Route: ohne Systemleisten (Status-/Navigationsleiste)
  /// und ohne Tastatur (`size` enthält die View-Insets nie). Außerhalb von
  /// `SafeArea` aufrufen, sonst fehlen die Ränder.
  static double availableHeight(BuildContext context) {
    final MediaQueryData m = MediaQuery.of(context);
    return m.size.height - m.padding.vertical;
  }

  /// K6: ab Textskalierung 1,5 oder bei verfügbarer Höhe unter 400 dp
  /// scrollen Hinweiskarte, Hinweiszeile und Disclaimer mit.
  static bool scrollsAlong(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) >=
          CuraSize.textScaleScrollAlong ||
      availableHeight(context) < CuraSize.chatScrollAlongMaxHeight;

  @override
  Widget build(BuildContext context) {
    final Widget? top = along ? null : hint;
    final Widget? bottom = along ? null : disclaimer;
    return KeyedSubtree(
      key: ProbeKeys.chatFooter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CuraSpace.pageMargin,
          CuraSpace.s2,
          CuraSpace.pageMargin,
          CuraSpace.pageMargin,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (top != null) ...<Widget>[
              top,
              const SizedBox(height: CuraSpace.s2),
            ],
            composer,
            if (bottom != null) ...<Widget>[
              const SizedBox(height: CuraSpace.s2),
              bottom,
            ],
          ],
        ),
      ),
    );
  }
}

class ChatScreenScaffold extends StatelessWidget {
  const ChatScreenScaffold({
    super.key,
    required this.header,
    required this.bodyBuilder,
    this.notice,
    this.hint,
    this.composer,
    this.disclaimer,
  });

  /// `ChatHeader`.
  final Widget header;

  /// Hinweiskarte („Beispielverlauf“ usw.), fest unter dem Kopf; unter den
  /// Bedingungen von [ChatFooterLayout.scrollsAlong] (K6) erstes Listenelement.
  final Widget? notice;

  final Widget? hint;
  final Widget? composer;
  final Widget? disclaimer;

  /// Baut den Inhalt; [ChatScaffoldExtras] trägt, was in die Liste gehört.
  final ChatBodyBuilder bodyBuilder;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final bool along = ChatFooterLayout.scrollsAlong(context);
    final Widget? card = notice;
    final bool noticeInList = along;
    final Widget? hintLine = hint;
    final Widget? disclaimerLine = disclaimer;
    final Widget? input = composer;

    final List<Widget> tail = <Widget>[
      if (along && hintLine != null) hintLine,
      if (along && disclaimerLine != null) disclaimerLine,
    ];
    final ChatScaffoldExtras extras = ChatScaffoldExtras(
      leading: noticeInList ? card : null,
      trailing: tail.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < tail.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: CuraSpace.s2),
                  tail[i],
                ],
              ],
            ),
    );

    // Shortcuts/Actions unterhalb des `Scaffold`: er registriert selbst eine
    // `DismissIntent`-Aktion (Drawer), die sonst vor unserer greift.
    return ScreenFrame(
      resizeToAvoidBottomInset: false,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (DismissIntent _) {
                Navigator.of(context).maybePop();
                return null;
              },
            ),
          },
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                KeyedSubtree(
                  key: ProbeKeys.header,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.bg,
                      border: Border(
                        bottom: BorderSide(
                          color: colors.cardBorder,
                          width: CuraSize.hairline,
                        ),
                      ),
                    ),
                    child: header,
                  ),
                ),
                if (card != null && !noticeInList)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CuraSpace.pageMargin,
                      CuraSpace.s3,
                      CuraSpace.pageMargin,
                      0,
                    ),
                    child: card,
                  ),
                Expanded(child: bodyBuilder(context, extras)),
                if (input != null)
                  ChatFooterLayout(
                    along: along,
                    composer: input,
                    hint: hintLine,
                    disclaimer: disclaimerLine,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
