// `PathScreen` (Brief 6.2, Ergänzung 1, 3.1/3.5, Ergänzung 2, 3.1, Plan 4.5,
// 4.6, 7.2, 7.3): der Tab „Pfad“.
//
// - Kopfzeile fix (`PathHeader`), darunter der Pfad scrollt (Zukunft oben,
//   oben und unten gepolstert, unten mit der Reserve für die Button-Gruppe).
//   Ab Textskalierung 1,5 wandert die Kopfzeile als erstes Element in die
//   Scrollfläche (Marker `scroll-header`): bei 320 × 568 und 200 % verbrauchte
//   sie sonst mehr als die Hälfte des Bildschirms, und Units der rechten Bahn
//   ließen sich nicht mehr frei von Kopf, Button-Gruppe und Nav scrollen
//   (UI-33, UI-34; gleiche Regel wie im Onboarding).
//   Beim Öffnen und nach einer Neuberechnung (Profil, Fortschritt) steht die
//   aktuelle Unit auf 55 % der Sichtfläche (`jumpTo`, keine Animation).
// - Manny sitzt auf der aktuellen Unit und öffnet bei einem Tipp den
//   Manny-Chat (Tab bleibt); die Blase und der `NodeHint` sind **feste
//   Overlays über der Liste** (nicht in der Liste), damit die Prüfungen sie
//   in der Ruhelage sehen. Sie werden beim Erscheinen platziert und
//   überdecken die Button-Gruppe nie (Rückfallketten in
//   `overlay_placement.dart`); scrollt der Nutzer, schließen beide (der
//   Bezug zu Manny bzw. zur Unit ginge sonst verloren).
// - Blasen und Feier beim Sichtbarwerden des Tabs (`onPathVisible`): einmal
//   pro Anlass und Tag; die Feier mit einmaligem Ring-Puls erst, wenn das
//   Rückgängig-Fenster zu ist (Logik aus U1b, hier nur genutzt).
// - Unit-Tipps: aktuell → Tab Heute; gesperrt oder erledigt → `NodeHint`
//   (schließt Tipp irgendwo, Scrollen, Escape/Zurück, Tabwechsel, nach 5 s,
//   bei aktivem Screenreader nicht automatisch).
// - Laden und Fehler (Brief 6.2, Erratum E-4: Pfad-Tab-Fehler behält „Dein
//   Pfad konnte nicht geladen werden.“) ohne Button-Gruppe (A-43).
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
import '../../logic/streak.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../state/transient_ui.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import '../components/action_cluster.dart';
import '../components/floating_nav.dart';
import '../components/manny_bubble.dart';
import '../components/node_hint.dart';
import '../components/path_header.dart';
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
    // Läuft die Kopfzeile in der Scrollfläche mit, erst nach ihrer Messung und
    // der folgenden Mittenlage platzieren (sonst stünde die Blase falsch).
    final bool scrollsAlong =
        MediaQuery.textScalerOf(context).scale(CuraSize.hairline) >=
        CuraSize.textScaleScrollAlong;
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
      final bool screenReader =
          context
              .getInheritedWidgetOfExactType<MediaQuery>()
              ?.data
              .accessibleNavigation ??
          false;
      if (hint != null && !screenReader) {
        _hintTimer = Timer(SnackbarTokens.medium, _transient.dismissHint);
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

  Rect? _clusterNow() {
    final HomeShellState shell = HomeShellScope.of(context);
    final Rect? global = ActionCluster.rectOf(shell.clusterKey);
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

  /// Obere Grenze der Overlays: läuft die Kopfzeile mit, bleibt oben der Platz
  /// für „Deine Daten“ frei.
  double get _overlayTop =>
      _headerH > 0 ? CuraSize.touchTarget : kOverlayTopLimit;

  Rect _mannyRect(PathLayout layout, PathProgress progress) {
    final NodePlacement p = layout.placements[progress.mannyIndex];
    return MannyPerch.drawRect(
      center: p.center,
      diameter: p.diameter,
    ).shift(Offset(0, _contentTop - _offset));
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
    final NodePlacement unit = layout.placements[progress.mannyIndex];
    return placeBubble(
      manny: _mannyRect(layout, progress),
      viewport: _viewport,
      cluster: allowScroll ? _clusterNow() : _cluster,
      textScale: _textScale,
      measure: (BubbleArrow arrow, double maxWidth) =>
          _bubbleSize(text, arrow, maxWidth, type, scaler),
      mannyBelowExtra: unit.diameter - CuraSize.mannyPerchOverlap,
      scrollOffset: _offset,
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
    final CuraTypography type = CuraTypography.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final NodePlacement p = layout.placements[index];
    final Rect unit = Rect.fromCenter(
      center: Offset(p.center.x, p.center.y + _contentTop - _offset),
      width: p.diameter,
      height: p.diameter,
    );
    final ScrollController? c = _scroll;
    final double max = c != null && c.hasClients
        ? c.position.maxScrollExtent
        : layout.maxScrollExtent;
    return placeHint(
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

  // -------------------------------------------------------------------------
  // Bauen
  // -------------------------------------------------------------------------

  PathLayoutMetrics _metrics(double gap) => PathLayoutMetrics(
    small: CuraSize.unitSmall,
    medium: CuraSize.unitMedium,
    large: CuraSize.unitLarge,
    boss: CuraSize.unitBoss,
    sideMargin: CuraSpace.pageMargin,
    verticalGap: gap,
  );

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
    final double textScale = MediaQuery.textScalerOf(context)
        .scale(CuraSize.hairline);
    final bool headerScrolls = textScale >= CuraSize.textScaleScrollAlong;
    final Widget header = FocusTraversalOrder(
      order: const NumericFocusOrder(HomeShellState.focusOrderHeader),
      child: PathHeader(
        week: progress.week,
        phaseLine: phaseLine(progress.phase, state.onboarding.injuryType),
        streak: streak,
        onOpenData: shell.openDataSheet,
      ),
    );
    if (!headerScrolls && _headerH != 0) _headerH = 0;
    return TapAnywhereDismiss(
      onDismiss: _dismissOverlays,
      child: SafeArea(
        bottom: false,
        child: headerScrolls
            ? _viewportArea(context, progress, scrollHeader: header)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  KeyedSubtree(key: ProbeKeys.header, child: header),
                  Expanded(child: _viewportArea(context, progress)),
                ],
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
    final double reserve =
        FloatingNav.occupiedHeight(context) +
        CuraSpace.pageMargin +
        CuraSize.mannyChatButton +
        CuraSpace.clusterGap +
        CuraSize.messagesButton +
        CuraSpace.pageMargin;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final Size viewport = box.biggest;
        final double width = viewport.width;

        // Beschriftungen unter mittleren, großen und Boss-Units.
        double labelHeight = 0;
        for (final PathUnit u in progress.units) {
          final String? t = _labelText(u);
          if (t == null) continue;
          labelHeight = math.max(
            labelHeight,
            _measureText(
              t,
              type.caption,
              width - 2 * CuraSpace.pageMargin,
              scaler,
            ).height,
          );
        }
        // Lichter Abstand: Manny und die Beschriftung der Unit darüber müssen
        // zwischen zwei Units passen.
        final double gap = math.max(
          CuraSize.pathUnitGapMin,
          MannyPerch.aboveUnit() +
              CuraSize.pathUnitAir +
              CuraSize.pathLabelGap +
              labelHeight,
        );
        final PathLayout layout = layoutPath(
          units: progress.units,
          width: width,
          viewportHeight: viewport.height,
          metrics: _metrics(gap),
          bottomReserve: reserve,
        );
        final List<PathLabel> labels = <PathLabel>[];
        for (int i = 0; i < progress.units.length; i++) {
          final String? t = _labelText(progress.units[i]);
          if (t == null) continue;
          final NodePlacement p = layout.placements[i];
          final Size s = _measureText(
            t,
            type.caption,
            width - 2 * CuraSpace.pageMargin,
            scaler,
          );
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
    final int index = progress.units.indexWhere((PathUnit u) => u.id == id);
    if (index < 0) return null;
    final String? text = nodeHintText(
      progress.units[index],
      progress.statuses[index],
      progress.week,
    );
    final Object key = (id, viewport, _textScale, _cluster, _headerH);
    if (_hintKey != key) {
      _hintKey = key;
      _hintPlan = _planHint(index, allowScroll: false);
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
        child: NodeHint(
          text: text,
          arrow: plan.arrow,
          arrowCenter: plan.arrowCenter,
          maxBodyHeight: plan.maxBodyHeight,
        ),
      ),
    );
  }
}
