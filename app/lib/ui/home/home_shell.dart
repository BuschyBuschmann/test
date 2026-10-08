// `HomeShell` (Plan 4.1, 4.3, 4.6): die Home-Route mit den Tabs Pfad und Heute
// in einem `IndexedStack` (Scrollposition bleibt erhalten), schwebender Nav und
// dem Snackbar-Host. Jeder Tab läuft in `TickerMode`: der inaktive Tab hält
// keine Animation (UI-8) und nimmt weder Fokus noch Semantik an.
//
// - Zurück (Android-Taste, Browser-Zurück): auf Heute → Tab Pfad; auf Pfad
//   erst eine sichtbare Manny-Blase bzw. einen `NodeHint` schließen, sonst die
//   App schließen (`SystemNavigator.pop`; auf iOS und im Web wirkungslos).
//   Sheets und Dialoge schließt ihre eigene Route.
// - Tageswechsel (Ergänzung 1, 3.4; Plan 4.6): geprüft beim Fortsetzen der App
//   (`AppLifecycleListener.onResume`) und bei jedem Tabwechsel. Reihenfolge:
//   Zustand anwenden (Controller), alle Heute-Routen schließen und das Ende der
//   Entfernung abwarten, dann prüfen, ob Heute aktiv **und** die Home-Route
//   oberste Route ist; nur dann Snackbar „Neuer Tag, neues Programm.“ und Ansage.
// - Tabwechsel beendet das Rückgängig-Fenster, den `NodeHint` und die Snackbar.
// - Button-Gruppe (Ergänzung 2, Plan 4.6): `ActionCluster` im Modus `path`
//   über dem Pfad-Tab (rechts 16 dp, Manny-Button 16 dp über der Nav,
//   Nachrichten-Button rechtsbündig 8 dp darüber). Auf Heute übernimmt U3b die
//   Gruppe; [openChat] und [openMessages] gelten für beide Tabs. Die Gruppe
//   liegt im Stack der Home-Route: Vollbild-Routen, Sheets und Dialoge liegen
//   als Routen darüber (Scrim, Semantik und Fokus der Gruppe sind dort blockiert).
// - Öffnen von Manny-Chat und Nachrichten: vorher das Rückgängig-Fenster
//   beenden, `NodeHint` und Blase schließen (zählt als gezeigt) und die
//   Snackbar schließen; nach dem Schließen der Route kehrt der Fokus an den
//   auslösenden Button zurück (A-38: auch bei Öffnen über Manny auf dem Pfad,
//   der keine eigene Fokusstation hat).
// - Ob Pfad und Heute in U2b noch Platzhalter sind, ändert nichts an diesem
//   Gerüst: U3a/U3b ersetzen nur den Inhalt der Tabs.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings_de.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/tokens.dart';
import '../components/action_cluster.dart';
import '../components/cura_snackbar.dart';
import '../components/floating_nav.dart';
import '../components/probe_keys.dart';
import '../components/screen_frame.dart';
import '../routes/app_routes.dart';
import '../routes/route_focus.dart';
import 'tab_placeholders.dart';
import 'today_route_registry.dart';

/// Tab-Indizes der Home-Route.
abstract final class HomeTab {
  static const int path = 0;
  static const int today = 1;
}

/// Stellt Tabs, Snackbar und das Register der Heute-Routen bereit.
class HomeShellScope extends InheritedWidget {
  const HomeShellScope({
    super.key,
    required this.shell,
    required this.tab,
    required super.child,
  });

  final HomeShellState shell;

  /// Aktiver Tab; Abhängige bauen bei einem Wechsel neu.
  final int tab;

  static HomeShellState of(BuildContext context) {
    final HomeShellScope? scope = context
        .dependOnInheritedWidgetOfExactType<HomeShellScope>();
    assert(scope != null, 'Kein HomeShell im Widget-Baum');
    return scope!.shell;
  }

  static HomeShellState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeShellScope>()?.shell;

  @override
  bool updateShouldNotify(HomeShellScope oldWidget) => tab != oldWidget.tab;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  final SnackbarController snackbar = SnackbarController();
  final TodayRouteRegistry todayRoutes = TodayRouteRegistry();
  late final AppLifecycleListener _lifecycle;
  int _tab = HomeTab.path;

  /// Rechteck der Button-Gruppe für Blase und Hinweis (Plan 4.6).
  final GlobalKey clusterKey = GlobalKey();

  /// Fokusrückgabe nach Chat bzw. Nachrichten (A-38).
  final FocusNode chatButtonFocus = FocusNode(debugLabel: 'Manny-Button');
  final FocusNode messagesButtonFocus = FocusNode(
    debugLabel: 'Nachrichten-Button',
  );

  /// Aktiver Tab (`HomeTab.path` oder `HomeTab.today`).
  int get activeTab => _tab;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    snackbar.dispose();
    chatButtonFocus.dispose();
    messagesButtonFocus.dispose();
    super.dispose();
  }

  AppController get _controller =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;

  // -------------------------------------------------------------------------
  // Tageswechsel
  // -------------------------------------------------------------------------

  void _onResume() {
    if (!mounted) return;
    if (_controller.checkDayChange().changed) dayChanged();
  }

  /// Folgen eines Tageswechsels in der UI (Plan 4.6). Auch von den Heute-Screens
  /// zu rufen, wenn eine Aktion (z. B. „Training eintragen“ über Mitternacht)
  /// den Wechsel ausgelöst hat.
  Future<void> dayChanged() async {
    _controller.transient.endUndoWindow();
    // (2) alle Heute-Routen schließen und das Ende der Entfernung abwarten.
    todayRoutes.closeAll();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    // (3) Heute aktiv und die Home-Route oberste Route?
    final bool visible =
        _tab == HomeTab.today && (ModalRoute.of(context)?.isCurrent ?? false);
    if (!visible) return;
    // (4) Snackbar und Ansage.
    snackbar.show(
      CuraSnackbarMessage(
        text: S.newDaySnackbar,
        duration: SnackbarTokens.medium,
      ),
    );
    SemanticsService.sendAnnouncement(
      View.of(context),
      S.newDayAnnouncement,
      Directionality.of(context),
    );
  }

  // -------------------------------------------------------------------------
  // Tabs und Zurück
  // -------------------------------------------------------------------------

  /// Wechselt den Tab. Prüft zuerst den Tageswechsel, beendet das
  /// Rückgängig-Fenster, den Hinweis und die Snackbar des bisherigen Tabs.
  void selectTab(int index) {
    final AppController c = _controller;
    final DayChangeResult change = c.checkDayChange();
    c.transient.endUndoWindow();
    c.transient.dismissHint();
    snackbar.close();
    if (index != _tab) setState(() => _tab = index);
    if (change.changed) dayChanged();
  }

  /// Schließt eine sichtbare Manny-Blase; weggetippt zählt als gezeigt.
  /// `true`, wenn eine Blase geschlossen wurde.
  bool _closeBubble(AppController c) {
    final BubbleDecision? bubble = c.transient.visibleBubble;
    if (bubble == null) return false;
    c.markBubbleShown(bubble.occasion);
    c.transient.dismissBubble();
    return true;
  }

  // -------------------------------------------------------------------------
  // Manny-Chat und Nachrichten (Ergänzung 2, Plan 4.1, 4.4)
  // -------------------------------------------------------------------------

  /// Öffnet den Manny-Chat (Manny-Button, später auch Manny auf dem Pfad);
  /// der Tab bleibt unverändert. Endet mit dem Schließen der Route.
  Future<void> openChat() =>
      _openFullscreen(AppRoutes.mannyChat(context), chatButtonFocus);

  /// Öffnet die Nachrichten-Übersicht (Nachrichten-Button).
  Future<void> openMessages() =>
      _openFullscreen(AppRoutes.messages(context), messagesButtonFocus);

  Future<void> _openFullscreen(Route<void> route, FocusNode trigger) {
    final AppController c = _controller;
    // Das Rückgängig-Fenster endet (UI-39), Hinweis und Blase schließen, die
    // Snackbar verschwindet: unter der neuen Route wäre sie nicht erreichbar.
    c.transient.endUndoWindow();
    c.transient.dismissHint();
    _closeBubble(c);
    snackbar.close();
    return pushReturningFocus<void>(
      Navigator.of(context),
      route,
      trigger: trigger,
    );
  }

  void _onBack() {
    if (_tab == HomeTab.today) {
      selectTab(HomeTab.path);
      return;
    }
    final AppController c = _controller;
    if (_closeBubble(c)) return;
    if (c.transient.hintUnitId != null) {
      c.transient.dismissHint();
      return;
    }
    SystemNavigator.pop();
  }

  Widget _tabPage(int index, Widget page) {
    final bool active = index == _tab;
    return ExcludeFocus(
      excluding: !active,
      child: TickerMode(enabled: active, child: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _onBack();
      },
      child: HomeShellScope(
        shell: this,
        tab: _tab,
        child: ScreenFrame(
          overlays: <Widget>[
            Positioned.fill(
              child: SnackbarHost(
                controller: snackbar,
                bottomOffset:
                    FloatingNav.occupiedHeight(context) + CuraSpace.snackbarGap,
              ),
            ),
            if (_tab == HomeTab.path)
              Positioned(
                right: CuraSpace.pageMargin,
                bottom:
                    FloatingNav.occupiedHeight(context) + CuraSpace.pageMargin,
                child: KeyedSubtree(
                  key: ProbeKeys.cluster,
                  child: ActionCluster(
                    mode: ActionClusterMode.path,
                    rectKey: clusterKey,
                    onOpenChat: openChat,
                    onOpenMessages: openMessages,
                    chatFocusNode: chatButtonFocus,
                    messagesFocusNode: messagesButtonFocus,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: KeyedSubtree(
                key: ProbeKeys.nav,
                child: FloatingNav(
                  currentIndex: _tab,
                  onSelected: selectTab,
                  items: const <NavItem>[
                    NavItem(icon: Icons.route_rounded, label: S.navPath),
                    NavItem(
                      icon: Icons.event_available_rounded,
                      label: S.navToday,
                    ),
                  ],
                ),
              ),
            ),
          ],
          child: IndexedStack(
            index: _tab,
            sizing: StackFit.expand,
            children: <Widget>[
              _tabPage(HomeTab.path, const PathTabPlaceholder()),
              _tabPage(HomeTab.today, const TodayTabPlaceholder()),
            ],
          ),
        ),
      ),
    );
  }
}
