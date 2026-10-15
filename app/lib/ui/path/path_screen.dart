// `PathScreen` (Design-Brief v2, 7.1; Ergänzung 1, 3.1/3.5, Plan 4.5, 4.6, 7.2,
// 7.3): das Ziel „Pfad“.
//
// - Kopf-Karte (`HeaderCard`): „Woche N“, „Phase M · Verletzung“, Chips
//   Freeze, Streak und „Beispielpfad“ (die beiden ersten sind antippbar und
//   erklären sich per `NodeHint`), der Wochenbalken „N von 7 Tagen“ und der
//   Einstieg „Deine Daten“. Sie steht fest oben; darunter scrollt der Pfad
//   (Zukunft oben, oben und unten gepolstert, unten mit der Reserve für den
//   Manny-Knopf). Ab Textskalierung 1,5 läuft die Kopf-Karte als erstes
//   Element in der Scrollfläche mit (Marker `scroll-header`): bei 320 × 568 und
//   200 % verbrauchte sie sonst mehr als die Hälfte des Bildschirms (UI-33,
//   UI-34, F-1). `padTop` zieht die Höhe des mitlaufenden Teils ab (F-2).
//   Beim Öffnen und nach einer Neuberechnung (Profil, Fortschritt) steht die
//   aktuelle Kugel auf 55 % der Sichtfläche (`jumpTo`, keine Animation).
// - Manny steht neben der aktuellen Kugel und öffnet bei einem Tipp den
//   Manny-Chat (Ziel bleibt); die Blase und der `NodeHint` sind **feste
//   Overlays über der Liste** (nicht in der Liste), damit die Prüfungen sie
//   in der Ruhelage sehen. Sie werden beim Erscheinen platziert und
//   überdecken den Manny-Knopf nie (Rückfallketten in `overlay_placement.dart`);
//   scrollt der Nutzer, schließen beide (der Bezug zu Manny bzw. zur Kugel
//   ginge sonst verloren).
// - Blasen und Feier beim Sichtbarwerden des Ziels (`onPathVisible`): einmal
//   pro Anlass und Tag; die Feier mit einmaligem Ring-Puls erst, wenn das
//   Rückgängig-Fenster zu ist (Logik aus U1b, hier nur genutzt).
// - Kugel-Tipps: aktuell → Ziel Heute; gesperrt oder erledigt → `NodeHint`
//   (schließt Tipp irgendwo, Scrollen, Escape/Zurück, Zielwechsel, nach 5 s,
//   bei aktivem Screenreader nicht automatisch).
// - Laden und Fehler (Brief 6.2, Erratum E-4: Pfad-Fehler behält „Dein Pfad
//   konnte nicht geladen werden.“) ohne Manny-Knopf (A-43).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart';

import '../../l10n/strings_de.dart';
import '../../logic/app_state.dart';
import '../../logic/manny_occasions.dart'
    show BubbleDecision, MannyOccasion, MannyPose;
import '../../logic/path_generator.dart';
import '../../logic/path_layout.dart';
import '../../logic/path_model.dart';
import '../../logic/plural.dart';
import '../../logic/profile_summary.dart';
import '../../logic/streak.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../state/transient_ui.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import '../components/floating_nav.dart';
import '../components/header_card.dart';
import '../components/header_icon_button.dart';
import '../components/manny_chat_button.dart';
import '../components/manny_bubble.dart';
import '../components/node_hint.dart';
import '../components/path_outlook.dart';
import '../components/probe_keys.dart';
import '../components/size_reporter.dart';
import '../home/home_shell.dart';
import '../start/start_loading_view.dart';
import 'overlay_placement.dart';
import 'path_error_view.dart';
import 'path_source.dart';
import 'path_view.dart';

class PathScreen extends StatefulWidget {
  const PathScreen({super.key, required this.load, required this.onRetry});

  /// Ladezustand (verwaltet die `HomeShell`, die davon die Button-Gruppe
  /// abhängig macht).
  final PathLoadState load;
  final VoidCallback onRetry;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

/// Alles, was eine neue Mittenlage der aktuellen Unit nötig macht.
typedef _Anchor = (
  int mannyIndex,
  int week,
  double w,
  double h,
  double scale,
  double headerH,
  int profileKey,
);

class _PathScreenState extends State<PathScreen> {
  ScrollController? _scroll;
  _Anchor? _anchor;
  PathLayout? _layout;
  PathProgress? _progress;
  Size _viewport = Size.zero;
  double _textScale = 1;
  Rect? _cluster;
  final GlobalKey _viewportKey = GlobalKey();

  /// Die ganze Seite (Kopfzeile und Sichtfläche): Bezug des Hinweises an den
  /// Chips der Kopfzeile, die oberhalb der Sichtfläche stehen.
  final GlobalKey _rootKey = GlobalKey();

  /// Die feste Kopfzeile (Untergrenze für den Hinweis an den Chips).
  final GlobalKey _headerKey = GlobalKey();

  /// Rechteck des angetippten Chips (global) und die zugehörige Platzierung.
  Rect? _statAnchor;
  Object? _statKey;

  /// Höhe der Kopfzeile, wenn sie in der Scrollfläche mitläuft (sonst 0).
  double _headerH = 0;

  // Platzierung der Overlays: beim Erscheinen bestimmt und festgehalten; sie
  // wird nur neu berechnet, wenn sich Maße oder Bezug ändern.
  BubblePlacement? _bubblePlan;
  Object? _bubbleKey;
  HintPlacement? _hintPlan;
  Object? _hintKey;

  AppController? _controllerRef;
  bool _wasActive = false;
  bool _visitScheduled = false;
  String? _pulseUnitId;
  Timer? _hintTimer;
  String? _timedHint;

  /// Im Hinweis wird gescrollt oder getippt: er bleibt dann stehen (F-5).
  bool _hintHeld = false;

  final Map<String, Size> _measures = <String, Size>{};

  AppController get _controller =>
      _controllerRef ??
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;

  TransientUi get _transient => _controller.transient;

  @override
  void initState() {
    super.initState();
    _controllerRef = context
        .getInheritedWidgetOfExactType<AppScope>()!
        .notifier;
    _transient.addListener(_onTransient);
  }

  @override
  void dispose() {
    _transient.removeListener(_onTransient);
    _hintTimer?.cancel();
    _scroll?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tab wird aktiv → Besuch (Blasen, Feier). Hängt am Tabwechsel der Shell.
    final bool active = HomeShellScope.of(context).activeTab == HomeTab.path;
    if (active && !_wasActive) _scheduleVisit();
    _wasActive = active;
  }

  @override
  void didUpdateWidget(PathScreen old) {
    super.didUpdateWidget(old);
    if (widget.load == PathLoadState.ready && old.load != PathLoadState.ready) {
      _scheduleVisit();
    }
  }

  // -------------------------------------------------------------------------
  // Besuch: Blase, Feier
  // -------------------------------------------------------------------------

  void _scheduleVisit() {
    if (_visitScheduled) return;
    _visitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visitScheduled = false;
      if (mounted) _visit();
    });
  }

  int _visitRetries = 0;

  /// Die Mittenlage wurde neu berechnet, der Sprung steht noch aus.
  bool _recenterPending = false;

  void _visit() {
    if (widget.load != PathLoadState.ready) return;
    final HomeShellState shell = HomeShellScope.of(context);
    if (shell.activeTab != HomeTab.path) return;
    // Liegt eine Route über Home (Sheet „Deine Daten“, Chat, Nachrichten),
    // erscheint keine Blase darunter: sie zählte sonst unbemerkt als gezeigt
    // und stünde unter dem Scrim im Blur-Budget (UI-47).
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    // Läuft die Kopfzeile in der Scrollfläche mit, erst nach ihrer Messung und
    // der folgenden Mittenlage platzieren (sonst stünde die Blase falsch).
    final bool scrollsAlong = _headerScrollsAlong(context);
    if ((_recenterPending || (scrollsAlong && _headerH < 1)) &&
        _visitRetries < 10) {
      _visitRetries++;
      _scheduleVisit();
      return;
    }
    _visitRetries = 0;
    final AppController c = _controller;
    // Eine noch sichtbare Blase bleibt; sie wird nicht ersetzt.
    if (c.transient.visibleBubble != null) return;
    final PathVisit visit = c.onPathVisible();
    if (visit.dayChange.changed) shell.dayChanged();
    final BubbleDecision? decision = visit.bubble;
    if (decision != null) _present(decision);
  }

  void _present(BubbleDecision decision) {
    final BubblePlacement? plan = _planBubble(decision, allowScroll: true);
    if (plan != null && plan.scrollOffsetDelta.abs() > 0.01) {
      _scrollBy(plan.scrollOffsetDelta);
    }
    _transient.showBubble(decision);
    if (decision.occasion == MannyOccasion.celebration) {
      // Feier und Puls gelten ab jetzt als gezeigt.
      final String? pulse = decision.pulseUnitId;
      if (pulse != null) setState(() => _pulseUnitId = pulse);
      _controller.consumeCelebration();
    }
  }

  // -------------------------------------------------------------------------
  // Overlays: Hinweis-Zeitgeber, Schließen
  // -------------------------------------------------------------------------

  void _onTransient() {
    final String? hint = _transient.hintUnitId;
    if (hint != _timedHint) {
      _hintTimer?.cancel();
      _hintTimer = null;
      _timedHint = hint;
      _hintHeld = false;
      final bool screenReader =
          context
              .getInheritedWidgetOfExactType<MediaQuery>()
              ?.data
              .accessibleNavigation ??
          false;
      if (hint != null && !screenReader) {
        _hintTimer = Timer(SnackbarTokens.medium, () {
          // Passt der Text nicht ganz hinein (innen scrollbar) oder wird im
          // Hinweis gescrollt, schließt kein Zeitgeber (F-5, R-AB-5).
          if (_hintHeld || (_hintPlan?.limited ?? false)) return;
          _transient.dismissHint();
        });
      }
    }
    if (!mounted) return;
    // Nie mitten im Bauen/Layouten neu bauen lassen.
    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void _holdHint() {
    _hintHeld = true;
    _hintTimer?.cancel();
    _hintTimer = null;
  }

  /// Tipp irgendwo: Blase (zählt als gezeigt) und Hinweis schließen.
  /// Idempotent: das X der Blase ruft ebenfalls.
  void _dismissOverlays() {
    HomeShellScope.of(context).dismissPathOverlays();
  }

  /// Scrollt der **Nutzer** (Ziehen, Auslaufen, Mausrad), schließen Blase und
  /// Hinweis. Programmatisches Scrollen (Mittenlage, Rückfall der Platzierung)
  /// löst keine `UserScrollNotification` aus und lässt sie stehen.
  bool _onScroll(ScrollNotification n) {
    if (n is UserScrollNotification && n.direction != ScrollDirection.idle) {
      HomeShellScope.maybeOf(context)?.dismissPathOverlays();
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Tipps
  // -------------------------------------------------------------------------

  void _onUnitPressed(int index) {
    final HomeShellState shell = HomeShellScope.of(context);
    final PathProgress? progress = _progress;
    if (progress == null) return;
    shell.closeBubble();
    if (progress.statuses[index] == UnitStatus.current) {
      shell.selectTab(HomeTab.today);
      return;
    }
    final HintPlacement? plan = _planHint(index, allowScroll: true);
    if (plan != null && plan.scrollOffsetDelta.abs() > 0.01) {
      _scrollBy(plan.scrollOffsetDelta);
    }
    _transient.showHint(progress.units[index].id);
  }

  /// Tipp auf den Ausblick (Ergänzung 3): wie eine gesperrte Unit, Hinweis
  /// über der Marke; eine Manny-Blase schließt, der Tab bleibt.
  void _onOutlookPressed() {
    final HomeShellState shell = HomeShellScope.of(context);
    if (_layout?.outlook == null) return;
    shell.closeBubble();
    final HintPlacement? plan = _planOutlookHint(allowScroll: true);
    if (plan != null && plan.scrollOffsetDelta.abs() > 0.01) {
      _scrollBy(plan.scrollOffsetDelta);
    }
    _transient.showHint(kPathOutlookHintId);
  }

  /// Tipp auf den Chip Freeze bzw. Streak: kurze Erklärung als `NodeHint` unter
  /// dem Chip (SK-1). Eine Manny-Blase schließt, der Tab bleibt. Der Hinweis
  /// schließt wie jeder andere (Tipp irgendwo, Scrollen, Escape/Zurück,
  /// Tabwechsel, nach 5 s, bei aktivem Screenreader nicht automatisch).
  void _onStatPressed(String id, Rect anchor) {
    HomeShellScope.of(context).closeBubble();
    _statAnchor = anchor;
    _statKey = null;
    _transient.showHint(id);
  }

  void _onMannyTap() {
    // Öffnet den Chat; Blase und Hinweis schließen dabei (HomeShell).
    HomeShellScope.of(context).openChat();
  }

  void _scrollBy(double delta) {
    final ScrollController? c = _scroll;
    if (c == null || !c.hasClients) return;
    final ScrollPosition p = c.position;
    p.jumpTo((p.pixels + delta).clamp(p.minScrollExtent, p.maxScrollExtent));
  }

  double get _offset {
    final ScrollController? c = _scroll;
    if (c == null) return 0;
    return c.hasClients ? c.offset : c.initialScrollOffset;
  }

  // -------------------------------------------------------------------------
  // Maße und Platzierung
  // -------------------------------------------------------------------------

  Size _measureText(
    String text,
    TextStyle style,
    double maxWidth,
    TextScaler scaler,
  ) {
    final String key = '${style.fontSize}|${scaler.scale(1)}|$maxWidth|$text';
    return _measures.putIfAbsent(key, () {
      // Wie `Text`: der geerbte `DefaultTextStyle` (z. B. Zeichenabstand)
      // gehört zur Breite, sonst bricht das Widget knapper als gemessen um.
      final TextStyle effective = DefaultTextStyle.of(context).style
          .merge(style);
      final TextPainter tp = TextPainter(
        text: TextSpan(text: text, style: effective),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: math.max(0, maxWidth));
      // Etwas Luft: knapp gemessene Breiten würden im Widget in eine weitere
      // Zeile umbrechen (Gleitkomma-Rundung der Textbreite).
      final double width = tp.width.ceilToDouble() + CuraSize.measureSlack;
      final Size s = Size(width, tp.height);
      tp.dispose();
      return s;
    });
  }

  Size _bubbleSize(
    String text,
    BubbleArrow arrow,
    double maxWidth,
    CuraTypography type,
    TextScaler scaler,
  ) {
    final bool side = arrow == BubbleArrow.left;
    final double chrome =
        CuraSize.bubblePaddingHorizontal +
        CuraSize.touchTarget +
        (side ? CuraComponent.bubbleArrow : 0);
    final Size t = _measureText(text, type.bubble, maxWidth - chrome, scaler);
    final double body = math.max(
      CuraSize.touchTarget,
      t.height + 2 * CuraSize.bubblePaddingVertical,
    );
    return Size(
      t.width + chrome,
      body + (side ? 0 : CuraComponent.bubbleArrow),
    );
  }

  Size _hintBodySize(
    String text,
    double maxWidth,
    CuraTypography type,
    TextScaler scaler,
  ) {
    final Size t = _measureText(
      text,
      type.secondary,
      maxWidth - 2 * CuraSize.hintPaddingHorizontal,
      scaler,
    );
    final double w = t.width + 2 * CuraSize.hintPaddingHorizontal;
    final double h = t.height + 2 * CuraSize.hintPaddingVertical;
    return Size(w, h);
  }

  /// Die Kopf-Karte läuft in der Scrollfläche mit: ab Textskalierung 1,5 und,
  /// bei vergrößerter Schrift, auf kurzen Bildschirmen (unter 600 dp Höhe). Die
  /// Karte ist mit Chips und Wochenbalken hoch; fest nähme sie dort den Platz
  /// des Pfads (F-1, F-2).
  bool _headerScrollsAlong(BuildContext context) {
    final double scale = MediaQuery.textScalerOf(context)
        .scale(CuraSize.hairline);
    return scale >= CuraSize.textScaleScrollAlong ||
        (scale > CuraSize.hairline &&
            MediaQuery.sizeOf(context).height <
                CuraSize.pathHeaderAlongMaxHeight);
  }

  /// Rechteck des Manny-Knopfes in den Koordinaten der Sichtfläche (`null`,
  /// solange er nicht gebaut ist).
  Rect? _clusterNow() {
    final HomeShellState shell = HomeShellScope.of(context);
    final Rect? global = MannyButton.rectOf(shell.mannyButtonKey);
    final RenderObject? viewport = _viewportKey.currentContext
        ?.findRenderObject();
    if (global == null || viewport is! RenderBox || !viewport.attached) {
      return null;
    }
    return viewport.globalToLocal(global.topLeft) & global.size;
  }

  /// Verschiebung der Pfad-Inhalte gegenüber dem Anfang der Scrollfläche
  /// (Höhe der mitlaufenden Kopfzeile).
  double get _contentTop => _headerH;

  /// Obere Grenze der Overlays. Die feste Kopfzeile (ab Skalierung 1,5 mit
  /// „Deine Daten“) liegt über der Sichtfläche, nicht in ihr.
  double get _overlayTop => kOverlayTopLimit;

  MannyPlacement _mannyPlacement(PathLayout layout, PathProgress progress) {
    final NodePlacement p = layout.placements[progress.mannyIndex];
    final MannyPlacement m = MannyPerch.place(
      center: p.center,
      diameter: p.diameter,
      width: _viewport.width,
    );
    return MannyPlacement(
      draw: m.draw.shift(Offset(0, _contentTop - _offset)),
      right: m.right,
    );
  }

  BubblePlacement? _planBubble(
    BubbleDecision decision, {
    required bool allowScroll,
  }) {
    final PathLayout? layout = _layout;
    final PathProgress? progress = _progress;
    if (layout == null || progress == null || _viewport.isEmpty) return null;
    final CuraTypography type = CuraTypography.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final String text = _controller.bubbleText(decision);
    final MannyPlacement manny = _mannyPlacement(layout, progress);
    return placeBubble(
      manny: manny.draw,
      // Links der Kugel stünde die Blase rechts von Manny über der Kugel.
      allowSide: manny.right,
      viewport: _viewport,
      cluster: allowScroll ? _clusterNow() : _cluster,
      textScale: _textScale,
      measure: (BubbleArrow arrow, double maxWidth) =>
          _bubbleSize(text, arrow, maxWidth, type, scaler),
      scrollOffset: _offset,
      allowScroll: allowScroll,
      topLimit: _overlayTop,
      scrollBottomLimit:
          _viewport.height - FloatingNav.occupiedHeight(context) - CuraSpace.s2,
    );
  }

  HintPlacement? _planOutlookHint({required bool allowScroll}) {
    final PathLayout? layout = _layout;
    final OutlookPlacement? o = layout?.outlook;
    if (layout == null || o == null || _viewport.isEmpty) return null;
    return _placeHintFor(
      Rect.fromCenter(
        center: Offset(o.center.x, o.center.y + _contentTop - _offset),
        width: o.width,
        height: o.height,
      ),
      S.outlookHint,
      layout,
      allowScroll: allowScroll,
    );
  }

  HintPlacement? _placeHintFor(
    Rect unit,
    String text,
    PathLayout layout, {
    required bool allowScroll,
  }) {
    final CuraTypography type = CuraTypography.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final ScrollController? c = _scroll;
    final double max = c != null && c.hasClients
        ? c.position.maxScrollExtent
        : layout.maxScrollExtent;
    // Mindestens drei Zeilen Text samt Innenabstand sollen im Hinweis zu sehen
    // sein, wenn er begrenzt werden muss (F-5).
    final double threeLines =
        _measureText('A\nA\nA', type.secondary, 1000, scaler).height +
        2 * CuraSize.hintPaddingVertical;
    return placeHint(
      minBodyHeight: threeLines,
      unit: unit,
      viewport: _viewport,
      cluster: allowScroll ? _clusterNow() : _cluster,
      measure: (double maxWidth) => _hintBodySize(text, maxWidth, type, scaler),
      scrollOffset: _offset,
      maxScrollOffset: max,
      allowScroll: allowScroll,
      topLimit: _overlayTop,
    );
  }

  HintPlacement? _planHint(int index, {required bool allowScroll}) {
    final PathLayout? layout = _layout;
    final PathProgress? progress = _progress;
    if (layout == null || progress == null || _viewport.isEmpty) return null;
    final String? text = nodeHintText(
      progress.units[index],
      progress.statuses[index],
      progress.week,
    );
    if (text == null) return null;
    final NodePlacement p = layout.placements[index];
    final Rect unit = Rect.fromCenter(
      center: Offset(p.center.x, p.center.y + _contentTop - _offset),
      width: p.diameter,
      height: p.diameter,
    );
    return _placeHintFor(unit, text, layout, allowScroll: allowScroll);
  }

  // -------------------------------------------------------------------------
  // Bauen
  // -------------------------------------------------------------------------

  PathLayoutMetrics _metrics(double gap) => PathLayoutMetrics(
    small: CuraSize.orbDay,
    medium: CuraSize.orbWeekGoal,
    large: CuraSize.orbPhaseEnd,
    boss: CuraSize.orbBoss,
    current: CuraSize.orbCurrent,
    sideMargin: CuraSpace.pageMargin,
    verticalGap: gap,
    outlookMaxWidth: CuraSize.outlookMaxWidth,
    outlookGap: CuraSize.pathUnitGapMin,
  );

  /// Höhe des Ausblicks: Schloss neben oder (bei schmalem Block) über dem Text,
  /// Titel höchstens bei 150 %, Innenabstand, mindestens 72 dp (wächst mit der
  /// Schrift, bricht um). Dieselbe Rechnung wie im Baustein selbst.
  double _outlookHeight(double width, CuraTypography type, TextScaler scaler) {
    final double w = math.max(
      0.0,
      math.min(width - 2 * CuraSpace.pageMargin, CuraSize.outlookMaxWidth),
    );
    return PathOutlook.layoutFor(
      width: w,
      type: type,
      scaler: scaler,
      measure: (String t, TextStyle style, double maxWidth, TextScaler s) =>
          _measureText(t, style, maxWidth, s),
    ).height;
  }

  String? _labelText(PathUnit u) {
    switch (u.kind) {
      case UnitKind.trainingDay:
        return null;
      case UnitKind.weekGoal:
        return S.unitWeekGoal;
      case UnitKind.phaseEnd:
        return S.unitPhaseEnd;
      case UnitKind.boss:
        return S.unitBoss;
    }
  }

  /// Die Kopf-Karte des Pfads (Brief 7.1, V2-35).
  Widget _headerCard(
    PathProgress progress,
    AppState state,
    StreakView streak,
    HomeShellState shell,
  ) {
    final bool frozen = streak.display == StreakDisplay.frozen;
    final int day = dayInPathWeek(
      state.onboarding.injuryDate,
      _controller.today,
    );
    return HeaderCard(
      title: S.weekTitle(progress.week),
      subtitle: phaseLine(progress.phase, state.onboarding.injuryType),
      trailing: HeaderIconButton(
        icon: Icons.person_outline_rounded,
        tooltip: S.dataSheetOpen,
        focusNode: shell.dataButtonFocus,
        onHeaderCard: true,
        onPressed: shell.openDataSheet,
      ),
      chips: <Widget>[
        HeaderChip(
          icon: Icons.ac_unit_rounded,
          label: '${streak.freezes}',
          semanticLabel: S.freezesLabel(streak.freezes),
          onPressed: (Rect r) => _onStatPressed(kStatFreezeHintId, r),
        ),
        HeaderChip(
          icon: Icons.local_fire_department_rounded,
          label: frozen
              ? '${streak.count} ${S.streakFrozenWord}'
              : '${streak.count}',
          semanticLabel: frozen
              ? S.streakFrozenLabel(tage(streak.count))
              : S.streakLabel(tage(streak.count)),
          onPressed: (Rect r) => _onStatPressed(kStatStreakHintId, r),
        ),
        const HeaderChip(
          icon: Icons.info_outline_rounded,
          label: S.samplePathChip,
        ),
      ],
      progress: HeaderProgress(value: day / 7, label: S.weekProgress(day)),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.load) {
      case PathLoadState.loading:
        return const StartLoadingView();
      case PathLoadState.error:
        return PathErrorView(onRetry: widget.onRetry, message: S.pathLoadError);
      case PathLoadState.ready:
        break;
    }
    final AppController controller = AppScope.of(context);
    final AppState state = controller.state;
    final PathProgress progress = computePathProgress(
      injuryDate: state.onboarding.injuryDate,
      today: controller.today,
      completedUnitIds: state.path.completedUnitIds,
    );
    _progress = progress;
    final StreakView streak = StreakEngine.view(state.streak);
    final HomeShellState shell = HomeShellScope.of(context);
    final bool headerScrolls = _headerScrollsAlong(context);
    // Bei großer Schrift läuft die Kopf-Karte als erstes Element mit.
    final Widget headerCard = FocusTraversalOrder(
      order: const NumericFocusOrder(HomeShellState.focusOrderHeader),
      child: _headerCard(progress, state, streak, shell),
    );
    final Widget header = Padding(
      padding: const EdgeInsets.fromLTRB(
        CuraSize.cardMargin,
        CuraSpace.s2,
        CuraSize.cardMargin,
        CuraSpace.s2,
      ),
      child: headerCard,
    );
    if (!headerScrolls && _headerH != 0) _headerH = 0;
    return TapAnywhereDismiss(
      onDismiss: _dismissOverlays,
      child: SafeArea(
        bottom: false,
        child: Stack(
          key: _rootKey,
          fit: StackFit.expand,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!headerScrolls)
                  KeyedSubtree(
                    key: ProbeKeys.header,
                    child: KeyedSubtree(key: _headerKey, child: header),
                  ),
                Expanded(
                  child: _viewportArea(
                    context,
                    progress,
                    scrollHeader: headerScrolls ? header : null,
                  ),
                ),
              ],
            ),
            ?_statHintOverlay(context),
          ],
        ),
      ),
    );
  }

  /// Hinweis an einem Chip der Kopfzeile (Freeze, Streak), über der ganzen
  /// Seite: der Chip steht oberhalb der Sichtfläche, der Hinweis ragt in sie.
  Widget? _statHintOverlay(BuildContext context) {
    final String? id = _transient.hintUnitId;
    final String? text = switch (id) {
      kStatFreezeHintId => S.hintFreeze,
      kStatStreakHintId => S.hintStreak,
      _ => null,
    };
    final Rect? anchorGlobal = _statAnchor;
    if (text == null) {
      _statKey = null;
      return null;
    }
    final RenderObject? root = _rootKey.currentContext?.findRenderObject();
    if (anchorGlobal == null || root is! RenderBox || !root.attached) {
      return null;
    }
    final Size bounds = root.size;
    final Rect anchor =
        root.globalToLocal(anchorGlobal.topLeft) & anchorGlobal.size;
    final HomeShellState shell = HomeShellScope.of(context);
    final Rect? clusterGlobal = MannyButton.rectOf(shell.mannyButtonKey);
    final Rect? cluster = clusterGlobal == null
        ? null
        : root.globalToLocal(clusterGlobal.topLeft) & clusterGlobal.size;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    // Die feste Kopfzeile (mit „Deine Daten“) bleibt frei: der Hinweis steht
    // darunter, nie darüber (sonst überdeckte er ein Bedienelement).
    final RenderObject? header = _headerKey.currentContext?.findRenderObject();
    final double topLimit = header is RenderBox && header.attached
        ? root
              .globalToLocal(
                header.localToGlobal(Offset(0, header.size.height)),
              )
              .dy
        : 0;
    final Object key = (id, bounds, anchor, cluster, scaler, topLimit);
    if (_statKey != key) {
      _statKey = key;
      _hintKey = null;
      final CuraTypography type = CuraTypography.of(context);
      _hintPlan = placeAnchoredHint(
        anchor: anchor,
        bounds: bounds,
        topLimit: topLimit,
        // Über der freien Zone der Button-Gruppe (Gruppe plus Seitenrand) und
        // über der Nav.
        bottomLimit: math.min(
          cluster == null ? bounds.height : cluster.top - CuraSpace.pageMargin,
          bounds.height - FloatingNav.occupiedHeight(context),
        ),
        measure: (double maxWidth) =>
            _hintBodySize(text, maxWidth, type, scaler),
        // Mindestens drei Zeilen Text samt Innenabstand (wie bei Unit-Hinweisen).
        minBodyHeight:
            _measureText('A\nA\nA', type.secondary, 1000, scaler).height +
            2 * CuraSize.hintPaddingVertical,
      );
    }
    final HintPlacement plan = _hintPlan!;
    final bool anchorBottom = plan.arrow == HintArrow.down;
    return Positioned(
      left: plan.rect.left,
      top: anchorBottom ? null : plan.rect.top,
      bottom: anchorBottom ? bounds.height - plan.rect.bottom : null,
      width: plan.rect.width,
      child: KeyedSubtree(
        key: ProbeKeys.hint,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _holdHint(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification n) {
              _holdHint();
              return false;
            },
            child: NodeHint(
              text: text,
              arrow: plan.arrow,
              arrowCenter: plan.arrowCenter,
              maxBodyHeight: plan.maxBodyHeight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewportArea(
    BuildContext context,
    PathProgress progress, {
    Widget? scrollHeader,
  }) {
    final CuraTypography type = CuraTypography.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double textScale = scaler.scale(CuraSize.hairline);
    // Der unterste Teil des Pfads lässt sich über den Manny-Knopf scrollen:
    // Leiste, Abstand, Knopf, Seitenrand.
    final double reserve =
        FloatingNav.occupiedHeight(context) +
        CuraSize.mannyButtonNavGap +
        CuraSize.mannyChatButton +
        CuraSpace.pageMargin;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final Size viewport = box.biggest;
        final double width = viewport.width;

        // Beschriftungen unter Wochenziel, Phasen-Abschluss und Boss als
        // Label-Chip (Text plus Innenabstand des Chips).
        const double chipPadH = CuraSize.statPillPaddingH;
        const double chipPadV = CuraSize.statPillPaddingV;
        Size chipSize(String t) {
          final Size m = _measureText(
            t,
            type.chip,
            width - 2 * CuraSpace.pageMargin - 2 * chipPadH,
            scaler,
          );
          final double w = m.width + 2 * chipPadH;
          final double h = m.height + 2 * chipPadV;
          return Size(w, h);
        }

        double chipHeight = 0;
        for (final PathUnit u in progress.units) {
          final String? t = _labelText(u);
          if (t == null) continue;
          chipHeight = math.max(chipHeight, chipSize(t).height);
        }
        // Lichter Abstand zweier Kugeln: der Label-Chip unter der oberen muss
        // dazwischen passen. Manny steht neben der Kugel und braucht keinen
        // Platz dazwischen.
        final double gap = math.max(
          CuraSize.pathUnitGapMin,
          CuraSize.pathUnitAir +
              CuraSize.pathLabelGap +
              chipHeight +
              CuraSize.pathUnitAir,
        );
        final PathLayout layout = layoutPath(
          units: progress.units,
          width: width,
          viewportHeight: viewport.height,
          metrics: _metrics(gap),
          bottomReserve: reserve,
          outlookHeight: kPathOutlookShown
              ? _outlookHeight(width, type, scaler)
              : null,
          leadingExtent: _headerH,
          currentIndex: progress.currentIndex,
        );
        final List<PathLabel> labels = <PathLabel>[];
        for (int i = 0; i < progress.units.length; i++) {
          final String? t = _labelText(progress.units[i]);
          if (t == null) continue;
          final NodePlacement p = layout.placements[i];
          final Size s = chipSize(t);
          final double left = (p.center.x - s.width / 2).clamp(
            CuraSpace.pageMargin,
            math.max(
              CuraSpace.pageMargin,
              width - CuraSpace.pageMargin - s.width,
            ),
          );
          labels.add(
            PathLabel(
              index: i,
              text: t,
              rect: Rect.fromLTWH(
                left,
                p.center.y + p.diameter / 2 + CuraSize.pathLabelGap,
                s.width,
                s.height,
              ),
            ),
          );
        }

        _layout = layout;
        _viewport = viewport;
        _textScale = textScale;

        // Mittenlage: beim ersten Bau über den Startwert, danach bei jeder
        // Änderung von aktueller Unit, Woche oder Maßen (jumpTo).
        final _Anchor anchor = (
          progress.mannyIndex,
          progress.week,
          viewport.width,
          viewport.height,
          textScale,
          _headerH,
          // Neuberechnung nach „Deine Daten“ (Typ oder Datum): auch bei gleicher
          // Unit und Woche wieder auf die aktuelle Unit zentrieren (UI-55).
          Object.hash(
            _controller.state.onboarding.injuryType,
            _controller.state.onboarding.injuryDate,
          ),
        );
        final double target =
            (layout.scrollOffsetFor(progress.mannyIndex) + _headerH).clamp(
              0,
              layout.maxScrollExtent + _headerH,
            );
        if (_scroll == null) {
          _scroll = ScrollController(initialScrollOffset: target);
          _anchor = anchor;
        } else if (anchor != _anchor) {
          _anchor = anchor;
          _recenterPending = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _recenterPending = false;
            final ScrollController? c = _scroll;
            if (!mounted || c == null || !c.hasClients) return;
            final ScrollPosition p = c.position;
            p.jumpTo(target.clamp(p.minScrollExtent, p.maxScrollExtent));
            // Die Overlays bezogen sich auf die alte Lage: neu platzieren.
            if (_transient.visibleBubble != null ||
                _transient.hintUnitId != null) {
              setState(() {
                _bubbleKey = null;
                _hintKey = null;
              });
            }
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncCluster());

        final BubbleDecision? bubble = _transient.visibleBubble;
        final MannyPose pose = bubble?.pose ?? MannyPose.neutral;
        final PathView view = PathView(
          layout: layout,
          progress: progress,
          width: width,
          labels: labels,
          mannyPose: pose,
          onUnitPressed: _onUnitPressed,
          onMannyTap: _onMannyTap,
          onOutlookPressed: _onOutlookPressed,
          pulseUnitId: _pulseUnitId,
          onPulseDone: () {
            if (mounted) setState(() => _pulseUnitId = null);
          },
        );
        final Widget content = scrollHeader == null
            ? view
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  KeyedSubtree(
                    key: ProbeKeys.scrollHeader,
                    child: SizeReporter(
                      onSize: (Size s) {
                        if (mounted && (s.height - _headerH).abs() > 0.5) {
                          setState(() => _headerH = s.height);
                        }
                      },
                      child: scrollHeader,
                    ),
                  ),
                  view,
                ],
              );
        return Stack(
          key: _viewportKey,
          children: <Widget>[
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: KeyedSubtree(
                key: ProbeKeys.scroll,
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: content,
                ),
              ),
            ),
            // Feste Overlays über der Liste (Platzierung beim Erscheinen).
            ?_bubbleOverlay(bubble, layout, progress, viewport),
            ?_hintOverlay(layout, progress, viewport),
          ],
        );
      },
    );
  }

  void _syncCluster() {
    if (!mounted) return;
    final Rect? now = _clusterNow();
    final Rect? old = _cluster;
    final bool same =
        (now == null && old == null) ||
        (now != null &&
            old != null &&
            (now.topLeft - old.topLeft).distance < 0.5 &&
            (now.size.width - old.size.width).abs() < 0.5 &&
            (now.size.height - old.size.height).abs() < 0.5);
    if (!same) setState(() => _cluster = now);
  }

  Widget? _bubbleOverlay(
    BubbleDecision? bubble,
    PathLayout layout,
    PathProgress progress,
    Size viewport,
  ) {
    if (bubble == null) {
      _bubblePlan = null;
      _bubbleKey = null;
      return null;
    }
    final Object key = (
      bubble,
      viewport,
      _textScale,
      progress.mannyIndex,
      _cluster,
      _headerH,
    );
    if (_bubbleKey != key) {
      _bubbleKey = key;
      _bubblePlan = _planBubble(bubble, allowScroll: false);
    }
    final BubblePlacement? plan = _bubblePlan;
    if (plan == null) return null;
    // Steht die Blase über Manny, hängt sie an ihrer Unterkante (die
    // Pfeilspitze bleibt an Manny, auch wenn die Höhe um einen Hauch abweicht).
    final bool anchorBottom = plan.arrow == BubbleArrow.down;
    return Positioned(
      left: plan.rect.left,
      top: anchorBottom ? null : plan.rect.top,
      bottom: anchorBottom ? viewport.height - plan.rect.bottom : null,
      width: plan.rect.width,
      child: KeyedSubtree(
        key: ProbeKeys.bubble,
        // Eigener Semantik-Knoten: Text (Live-Region) und „Nachricht schließen“
        // verschmelzen sonst mit den Nachbarn der Seite.
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          child: MannyBubble(
            text: _controller.bubbleText(bubble),
            arrow: plan.arrow,
            arrowOffset: plan.arrowOffset,
            maxBodyHeight: plan.maxBodyHeight,
            onClose: _dismissOverlays,
          ),
        ),
      ),
    );
  }

  Widget? _hintOverlay(
    PathLayout layout,
    PathProgress progress,
    Size viewport,
  ) {
    final String? id = _transient.hintUnitId;
    if (id == null) {
      _hintPlan = null;
      _hintKey = null;
      return null;
    }
    final bool outlook = id == kPathOutlookHintId;
    final int index = outlook
        ? -1
        : progress.units.indexWhere((PathUnit u) => u.id == id);
    if (!outlook && index < 0) return null;
    if (outlook && layout.outlook == null) return null;
    final String? text = outlook
        ? S.outlookHint
        : nodeHintText(
            progress.units[index],
            progress.statuses[index],
            progress.week,
          );
    final Object key = (id, viewport, _textScale, _cluster, _headerH);
    if (_hintKey != key) {
      _hintKey = key;
      _hintPlan = outlook
          ? _planOutlookHint(allowScroll: false)
          : _planHint(index, allowScroll: false);
    }
    final HintPlacement? plan = _hintPlan;
    if (text == null || plan == null) return null;
    final bool anchorBottom = plan.arrow == HintArrow.down;
    return Positioned(
      left: plan.rect.left,
      top: anchorBottom ? null : plan.rect.top,
      bottom: anchorBottom ? viewport.height - plan.rect.bottom : null,
      width: plan.rect.width,
      child: KeyedSubtree(
        key: ProbeKeys.hint,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _holdHint(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification n) {
              _holdHint();
              return false;
            },
            child: NodeHint(
              text: text,
              arrow: plan.arrow,
              arrowCenter: plan.arrowCenter,
              maxBodyHeight: plan.maxBodyHeight,
            ),
          ),
        ),
      ),
    );
  }
}
