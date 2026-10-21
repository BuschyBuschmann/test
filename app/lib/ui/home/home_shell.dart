// `HomeShell` (Design-Brief v2, 5; Plan 3.3, 4.1, 4.3, 4.6): die Home-Route mit
// den vier Zielen Pfad, Heute, Chats und Profil in einem `IndexedStack`
// (Scroll-Position und Zustand bleiben je Ziel erhalten), der schwebenden
// Leiste und dem Snackbar-Host. Jedes Ziel läuft in `TickerMode`: das inaktive
// hält keine Animation (UI-8) und nimmt weder Fokus noch Semantik an.
//
// - Die Ziele sind eine Liste ([HomeDestination]): ein fünftes Ziel (Feed, ab
//   Ausschnitt 4) kommt an Position 3 dazu, indem ein Eintrag in den Enum, in
//   [HomeShellState._item] und in [HomeShellState._page] tritt; bis dahin gibt
//   es kein Feed-Ziel und keinen Platzhalter (V2-15).
// - Leiste (Brief 4.1): sichtbar nur auf der Home-Route. Session, Chat-
//   Vollbilder, Onboarding, Sheets und Dialoge sind Routen **über** der Home-
//   Route: sie decken die Leiste samt Manny-Knopf ab (Scrim, keine Semantik,
//   kein Fokus; V2-19). Der Beginn eines Scrolls im Inhalt macht die Leiste
//   aktiv ([NavActivity]).
// - Zurück (Android-Taste, Browser-Zurück): auf Heute, Chats und Profil → Ziel
//   Pfad; auf Pfad erst eine sichtbare Manny-Blase bzw. einen `NodeHint`
//   schließen, sonst die App schließen (`SystemNavigator.pop`; auf iOS und im
//   Web wirkungslos). Sheets und Dialoge schließt ihre eigene Route.
// - Tageswechsel (Ergänzung 1, 3.4; Plan 4.6): geprüft beim Fortsetzen der App
//   (`AppLifecycleListener.onResume`) und bei jedem Zielwechsel. Reihenfolge:
//   Zustand anwenden (Controller), alle Heute-Routen schließen und das Ende der
//   Entfernung abwarten, dann prüfen, ob Heute aktiv **und** die Home-Route
//   oberste Route ist; nur dann Snackbar „Neuer Tag, neues Programm.“ und Ansage.
// - Zielwechsel beendet das Rückgängig-Fenster, den `NodeHint` und die Snackbar;
//   verlässt man den Pfad, schließt auch die Blase (zählt als gezeigt).
// - Manny-Knopf (Brief 5): Kopf, 56 dp, rechts 18 dp, 16 dp über der Leiste,
//   nur auf **Pfad** (hier) und **Heute** (in der Primärbutton-Reihe des
//   Tabs). Die frühere Button-Gruppe mit Nachrichten-Knopf entfällt: Nachrichten
//   sind das Ziel Chats, Manny zusätzlich dort angeheftet. Auf dem Pfad steht
//   der Knopf nur, wenn der Pfad **bereit** ist (A-43: nicht in Laden und
//   Fehler). Vollbild-Routen, Sheets und Dialoge liegen als Routen darüber.
// - Öffnen von Manny-Chat und Beispiel-Chats ([openFullscreen]): vorher das
//   Rückgängig-Fenster beenden, `NodeHint` und Blase schließen (zählt als
//   gezeigt) und die Snackbar schließen; nach dem Schließen der Route kehrt der
//   Fokus an den auslösenden Knopf bzw. die Zeile zurück (A-38: auch bei
//   Öffnen über Manny auf dem Pfad, der keine eigene Fokusstation hat).
// - Pfad (U3a): `PathScreen`. Der Ladezustand kommt aus der `PathSource`;
//   „Nochmal versuchen“ bereitet den Pfad erneut vor. Escape und Zurück
//   schließen zuerst Blase und Hinweis ([dismissPathOverlays]).
// - Deine Daten (U4): [openDataSheet] öffnet das Sheet über der Home-Route (die
//   Leiste bleibt darunter, unter dem Scrim); der Fokus kehrt an das Symbol in
//   der Kopf-Karte des Pfads ([dataButtonFocus]) bzw. die Profil-Zeile zurück.
// - Heute (U3b): `TodayScreen` baut die Primärbutton-Reihe mit dem Manny-Knopf
//   selbst (nur im Standard-Zustand, A-43) und meldet deren gemessene Höhe über
//   [todayGroupHeight]: die Snackbar auf Heute steht 12 dp über der Reihe.
//   Laden und Fehler kommen wie beim Pfad aus einer Quelle (`TodaySource`). Der
//   Tageswechsel schließt Snackbar, Rückgängig-Fenster und alle Heute-Routen,
//   bevor er die Bedingung prüft ([dayChanged]).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings_de.dart';
import '../../logic/profile_summary.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/tokens.dart';
import '../components/cura_snackbar.dart';
import '../components/floating_nav.dart';
import '../components/manny_chat_button.dart';
import '../components/probe_keys.dart';
import '../components/screen_frame.dart';
import '../data_sheet/data_sheet.dart';
import '../profile/profile_screen.dart';
import '../routes/app_routes.dart';
import '../messages/chats_screen.dart';
import '../path/path_screen.dart';
import '../path/path_source.dart';
import '../routes/route_focus.dart';
import '../today/today_screen.dart';
import '../today/today_source.dart';
import 'today_route_registry.dart';

/// Ziele der Leiste in ihrer Reihenfolge (V2-15). Ein Eintrag steht für Symbol,
/// Label und Seite; die Position ist der Index im Enum.
enum HomeDestination { path, today, chats, profile }

/// Indizes der Ziele der Home-Route. Sie folgen der Reihenfolge von
/// [HomeDestination] (kommt Feed an Position 3 dazu, rücken Chats und Profil
/// von selbst nach).
abstract final class HomeTab {
  static int get path => HomeDestination.path.index;
  static int get today => HomeDestination.today.index;
  static int get chats => HomeDestination.chats.index;
  static int get profile => HomeDestination.profile.index;
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

  /// Rechteck des Manny-Knopfes auf dem Pfad für Blase und Hinweis (Plan 4.6).
  final GlobalKey mannyButtonKey = GlobalKey();

  /// Aktivität des Inhalts (Beginn eines Scrolls) für die Leiste (Brief 4.1).
  final NavActivity navActivity = NavActivity();

  /// Fokusrückgabe nach dem Manny-Chat (A-38).
  final FocusNode chatButtonFocus = FocusNode(debugLabel: 'Manny-Button');

  /// Fokusrückgabe nach „Deine Daten“ (Icon in der Pfad-Kopfzeile).
  final FocusNode dataButtonFocus = FocusNode(debugLabel: 'Deine Daten');

  final FocusNode _pageFocus = FocusNode(
    debugLabel: 'Home',
    skipTraversal: true,
  );

  /// Ladezustand des Pfad-Tabs (Plan 4.6, A-43).
  PathLoadState _pathLoad = PathLoadState.ready;
  int _pathAttempt = 0;

  /// Ladezustand des Tabs Heute (Plan 4.6, A-43).
  TodayLoadState _todayLoad = TodayLoadState.ready;
  int _todayAttempt = 0;

  /// Gemessene Höhe der Primärbutton-Reihe auf Heute (mit dem Manny-Knopf); 0
  /// solange sie nicht gebaut ist. Der Snackbar-Host liest sie (Snackbar 12 dp
  /// über der Reihe, Plan 4.6, UI-73).
  final ValueNotifier<double> todayGroupHeight = ValueNotifier<double>(0);

  /// Gemessene Höhe der sichtbaren Snackbar (0 ohne Snackbar): Heute vergrößert
  /// die Scroll-Reserve damit, damit die Snackbar den letzten Eintrag nie
  /// überdeckt.
  final ValueNotifier<double> snackbarHeight = ValueNotifier<double>(0);

  /// Aktives Ziel (ein Wert aus [HomeTab]).
  int get activeTab => _tab;

  /// Der Pfad ist bereit (nicht Laden, nicht Fehler).
  PathLoadState get pathLoad => _pathLoad;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _preparePath();
    _prepareToday();
  }

  /// Bereitet das Tagesprogramm über die [TodaySource] vor (wie [_preparePath]).
  void _prepareToday() {
    final int attempt = ++_todayAttempt;
    final TodaySource source = TodaySourceScope.read(context);
    void set(TodayLoadState state) {
      if (!mounted || attempt != _todayAttempt) return;
      if (state != _todayLoad) setState(() => _todayLoad = state);
    }

    try {
      final Future<void>? pending = source.prepare();
      if (pending == null) {
        _todayLoad = TodayLoadState.ready;
      } else {
        _todayLoad = TodayLoadState.loading;
        pending.then(
          (_) => set(TodayLoadState.ready),
          onError: (Object _) => set(TodayLoadState.error),
        );
      }
    } catch (e) {
      debugPrint('Heute nicht bereit: $e');
      _todayLoad = TodayLoadState.error;
    }
  }

  /// „Nochmal versuchen“ im Fehlerzustand von Heute.
  void retryToday() {
    setState(_prepareToday);
  }

  /// Bereitet den Pfad über die [PathSource] vor: sofort bereit, Laden bis ein
  /// `Future` endet, oder Fehler (Ausnahme).
  void _preparePath() {
    final int attempt = ++_pathAttempt;
    final PathSource source = PathSourceScope.read(context);
    void set(PathLoadState state) {
      if (!mounted || attempt != _pathAttempt) return;
      if (state != _pathLoad) setState(() => _pathLoad = state);
    }

    try {
      final Future<void>? pending = source.prepare();
      if (pending == null) {
        _pathLoad = PathLoadState.ready;
      } else {
        _pathLoad = PathLoadState.loading;
        pending.then(
          (_) => set(PathLoadState.ready),
          onError: (Object _) => set(PathLoadState.error),
        );
      }
    } catch (e) {
      debugPrint('Pfad nicht bereit: $e');
      _pathLoad = PathLoadState.error;
    }
  }

  /// „Nochmal versuchen“ im Fehlerzustand des Pfads.
  void retryPath() {
    setState(_preparePath);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    snackbar.dispose();
    todayGroupHeight.dispose();
    snackbarHeight.dispose();
    navActivity.dispose();
    chatButtonFocus.dispose();
    dataButtonFocus.dispose();
    _pageFocus.dispose();
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
  /// zu rufen, wenn eine Aktion (z. B. „Eintragen“ im Sheet über Mitternacht)
  /// den Wechsel ausgelöst hat.
  Future<void> dayChanged() async {
    _controller.transient.endUndoWindow();
    // Eine offene Snackbar (z. B. „Eingetragen. Rückgängig“) gehört zum Vortag.
    snackbar.close();
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
    // Wer den Pfad verlässt, hat die Blase gesehen: sie zählt als gezeigt und
    // steht beim Zurückkehren nicht mehr da.
    if (_tab == HomeTab.path && index != HomeTab.path) _closeBubble(c);
    snackbar.close();
    if (index != _tab) setState(() => _tab = index);
    if (change.changed) dayChanged();
  }

  /// Schließt eine sichtbare Manny-Blase (zählt als gezeigt); idempotent.
  /// `true`, wenn eine Blase geschlossen wurde.
  bool closeBubble() => _closeBubble(_controller);

  /// Tipp irgendwo: Blase und Hinweis schließen. `true`, wenn etwas offen war.
  bool dismissPathOverlays() {
    final AppController c = _controller;
    final bool bubble = _closeBubble(c);
    final bool hint = c.transient.hintUnitId != null;
    c.transient.dismissHint();
    return bubble || hint;
  }

  /// Escape und Zurück: **ein** Schritt, erst die Blase, dann der Hinweis
  /// (Plan 4.3). `true`, wenn etwas geschlossen wurde.
  bool dismissPathOverlayStep() {
    final AppController c = _controller;
    if (_closeBubble(c)) return true;
    if (c.transient.hintUnitId != null) {
      c.transient.dismissHint();
      return true;
    }
    return false;
  }

  /// Einstieg „Deine Daten“ in der Pfad-Kopfzeile (Ergänzung 1, 3.2): öffnet
  /// das Sheet. Vorher endet das Rückgängig-Fenster, `NodeHint` und Blase
  /// schließen (die Blase zählt als gezeigt, Blur-Budget K3) und die Snackbar
  /// verschwindet. Beim Schließen kehrt der Fokus an das Icon zurück (mit
  /// `mounted`-Prüfung in `pushReturningFocus`). Hat das Speichern einen
  /// Tageswechsel ausgelöst, setzt die Shell dessen Folgen um.
  Future<void> openDataSheet({FocusNode? trigger}) async {
    final AppController c = _controller;
    c.transient.endUndoWindow();
    c.transient.dismissHint();
    _closeBubble(c);
    snackbar.close();
    final ProfileUpdateResult? result =
        await pushReturningFocus<ProfileUpdateResult?>(
          Navigator.of(context),
          DataSheet.route(context),
          trigger: trigger ?? dataButtonFocus,
        );
    if (result != null && result.dayChanged && mounted) {
      unawaited(dayChanged());
    }
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
  // Manny-Chat und Beispiel-Chats (Ergänzung 2, Plan 4.1, 4.4)
  // -------------------------------------------------------------------------

  /// Öffnet den Manny-Chat (Manny-Knopf, Manny auf dem Pfad, angehefteter
  /// Eintrag in Chats); das Ziel bleibt unverändert. Endet mit dem Schließen
  /// der Route. Der Fokus kehrt an [trigger] zurück (Standard: Manny-Knopf).
  Future<void> openChat({FocusNode? trigger}) =>
      openFullscreen(AppRoutes.mannyChat(context), trigger ?? chatButtonFocus);

  /// Öffnet eine Vollbild-Route (Chat) über der Home-Route: ohne Leiste und
  /// ohne Manny-Knopf. Vorher endet das Rückgängig-Fenster (UI-39), Hinweis und
  /// Blase schließen, die Snackbar verschwindet: unter der neuen Route wäre sie
  /// nicht erreichbar. Danach kehrt der Fokus an [trigger] zurück.
  Future<void> openFullscreen(Route<void> route, FocusNode trigger) {
    final AppController c = _controller;
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
    if (_tab != HomeTab.path) {
      selectTab(HomeTab.path);
      return;
    }
    if (dismissPathOverlayStep()) return;
    SystemNavigator.pop();
  }

  Widget _tabPage(int index, Widget page) {
    final bool active = index == _tab;
    return ExcludeFocus(
      excluding: !active,
      child: TickerMode(
        enabled: active,
        // Fokusreihenfolge (Ergänzung 2, 4): Inhalt des Tabs (Pfad: Kopf,
        // Units), dann die Button-Gruppe, dann die Nav.
        child: FocusTraversalOrder(
          order: const NumericFocusOrder(_focusOrderContent),
          child: page,
        ),
      ),
    );
  }

  /// Fokusreihenfolge innerhalb der Home-Route: Kopf (Kopf-Karte), Inhalt (Pfad:
  /// Kugeln), Manny-Knopf, Leiste. Ohne explizite Reihenfolge stünden Kugeln,
  /// die oberhalb des Sichtfensters liegen, vor dem Kopf (die Lesereihenfolge
  /// folgt den Rechtecken).
  static const double focusOrderHeader = 1;
  static const double _focusOrderContent = 2;

  /// Pfad: Manny-Knopf nach dem Inhalt. Heute (Primärbutton-Reihe):
  /// „Training eintragen“, dann der Manny-Knopf, dann die Leiste.
  static const double focusOrderManny = 3.2;
  static const double focusOrderStart = 3.1;
  static const double _focusOrderNav = 4;

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
        // Escape schließt Blase und Hinweis (Plan 4.3); der Fokus der Seite
        // fängt die Taste auch ohne fokussiertes Element ab. Ohne eigenen
        // Semantik-Knoten, sonst verschmilzt `Focus` die Seite zu einem Knoten.
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (_tab == HomeTab.path) dismissPathOverlayStep();
            },
          },
          child: Focus(
            focusNode: _pageFocus,
            autofocus: true,
            includeSemantics: false,
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: ScreenFrame(
                // Auf Home steht kein Eingabefeld; Dialoge über Heute stellen
                // ihre Tastatur selbst frei. Die Nav bleibt unten stehen.
                resizeToAvoidBottomInset: false,
                overlays: <Widget>[
                  Positioned.fill(
                    child: ValueListenableBuilder<double>(
                      valueListenable: todayGroupHeight,
                      builder: (BuildContext context, double group, _) {
                        // Heute: 12 dp über der Primärbutton-Reihe; sonst über
                        // der Leiste (Pfad: keine Snackbar, Plan 4.6).
                        final double above =
                            _tab == HomeTab.today &&
                                _todayLoad == TodayLoadState.ready
                            ? CuraSpace.pageMargin + group
                            : 0;
                        return SnackbarHost(
                          controller: snackbar,
                          onHeightChanged: (double h) =>
                              snackbarHeight.value = h,
                          bottomOffset:
                              FloatingNav.occupiedHeight(context) +
                              above +
                              CuraSpace.snackbarGap,
                        );
                      },
                    ),
                  ),
                  if (_tab == HomeTab.path && _pathLoad == PathLoadState.ready)
                    Positioned(
                      right: CuraSize.mannyButtonSideMargin,
                      bottom:
                          FloatingNav.occupiedHeight(context) +
                          CuraSize.mannyButtonNavGap,
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(focusOrderManny),
                        child: KeyedSubtree(
                          key: ProbeKeys.mannyButton,
                          child: KeyedSubtree(
                            key: mannyButtonKey,
                            child: MannyButton(
                              onPressed: openChat,
                              focusNode: chatButtonFocus,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(_focusOrderNav),
                      child: KeyedSubtree(
                        key: ProbeKeys.nav,
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (BuildContext context, Widget? _) {
                            final String initial = nameInitial(
                              _controller.state.onboarding.firstName,
                            );
                            return FloatingNav(
                              currentIndex: _tab,
                              onSelected: selectTab,
                              activity: navActivity,
                              items: <NavItem>[
                                for (final HomeDestination d
                                    in HomeDestination.values)
                                  _item(d, initial),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
                child: NavScrollListener(
                  activity: navActivity,
                  child: IndexedStack(
                    index: _tab,
                    sizing: StackFit.expand,
                    children: <Widget>[
                      for (final HomeDestination d in HomeDestination.values)
                        _tabPage(d.index, _page(d)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Die Seite eines Ziels.
  Widget _page(HomeDestination d) => switch (d) {
    HomeDestination.path => PathScreen(load: _pathLoad, onRetry: retryPath),
    HomeDestination.today => TodayScreen(load: _todayLoad, onRetry: retryToday),
    HomeDestination.chats => const ChatsScreen(),
    HomeDestination.profile => const ProfileScreen(),
  };

  /// Eintrag der Leiste für ein Ziel (Symbol und Label; Chats mit Zähler,
  /// Profil mit der Initiale als Avatar).
  NavItem _item(HomeDestination d, String initial) => switch (d) {
    HomeDestination.path => const NavItem(
      icon: Icons.route_rounded,
      label: S.navPath,
    ),
    HomeDestination.today => const NavItem(
      icon: Icons.event_available_rounded,
      label: S.navToday,
    ),
    // Der Zähler erscheint, sobald es echte Chats mit ungelesenen
    // Nachrichten gibt (V2-20); die Beispieldaten haben keine.
    HomeDestination.chats => const NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      label: S.navChats,
    ),
    HomeDestination.profile => NavItem(
      icon: Icons.person_outline_rounded,
      label: S.navProfile,
      avatarInitials: initial.isEmpty ? null : initial,
    ),
  };
}
