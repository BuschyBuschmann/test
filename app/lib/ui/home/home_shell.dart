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
import '../components/cura_snackbar.dart';
import '../components/floating_nav.dart';
import '../components/probe_keys.dart';
import '../components/screen_frame.dart';
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

  void _onBack() {
    if (_tab == HomeTab.today) {
      selectTab(HomeTab.path);
      return;
    }
    final AppController c = _controller;
    final BubbleDecision? bubble = c.transient.visibleBubble;
    if (bubble != null) {
      // Weggetippt zählt als gezeigt.
      c.markBubbleShown(bubble.occasion);
      c.transient.dismissBubble();
      return;
    }
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
