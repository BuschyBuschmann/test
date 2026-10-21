// `TodayScreen` (Design-Brief v2, 7.2; Brief 6.3, Ergänzung 1 3.3/3.4,
// Ergänzung 2 K3 bis K5, Plan 4.5, 4.6, 7.4 bis 7.6): der Tab „Heute“.
//
// - Kopf-Karte (`HeaderCard`, V2-5: kein Text direkt auf der Welt): „Heute,
//   [Name]“, Datum und der Streak als Chip. Darunter scrollt der Inhalt
//   (`TabPage`): Zeitwahl 10/20/30, Termine (Beispieltermine als
//   `CategoryCard`s oder „Heute keine Termine.“ auf einer Karte), Übungen ·
//   ca. N Min (Übungskarten mit Tauschen/Entfernen, Leerkarte „Heute noch
//   nichts geplant.“) und „+ Eigene Übung“. Die Abschnittsüberschriften sind
//   Label-Chips (erlaubter Untergrund für Text auf der Welt).
//   Check-up-Karte, Session und Abhaken kommen in L3 bis L5; bis dahin gilt
//   das Verhalten aus Ausschnitt 1 („Training eintragen“).
// - Fest über der Nav (nur im Standard-Zustand, A-43): die Primärbutton-Reihe
//   („Training eintragen“ / „Heute erledigt“ + Manny-Knopf, `PrimaryActionRow`;
//   den Nachrichten-Knopf gibt es nicht mehr, F2-R3). Die Scroll-Reserve am
//   Listenende ist aus der **gemessenen** Höhe der Reihe gerechnet (Reihe + Nav
//   samt Abstand + 16 dp + 8 dp Luft), nicht aus festen Pixelwerten; die
//   Snackbar steht 12 dp über der Reihe (`HomeShellState.todayGroupHeight`). Solange eine Snackbar
//   steht, kommt ihre gemessene Höhe samt 12 dp dazu (`snackbarHeight`), damit
//   sie den letzten Eintrag nie überdeckt.
// - „Training eintragen“ öffnet das Sheet „Wie willst du trainieren?“; es merkt
//   sich beim Öffnen den Tag (`openedDay`). „Eintragen“ im Sheet trägt für
//   diesen Tag ein (auch über Mitternacht, N-11), schließt das Sheet und zeigt
//   „Eingetragen. Rückgängig“ (8 s). „Entfernen“ zeigt „Entfernt. Rückgängig“.
//   Nach jeder Aktion, die einen Tageswechsel ausgelöst hat, übernimmt
//   `HomeShellState.dayChanged` die Folgen (Routen schließen, Snackbar, Ansage).
// - Laden und Fehler (Brief 6.3) ohne Primärbutton-Reihe; der Fehler nutzt die
//   gemeinsame Fehleransicht mit „Nochmal versuchen“.
//
// Die Logik (Tagesprogramm, Eintragen, Rückgängig, Tageswechsel) kommt
// unverändert aus `lib/logic/` und dem `AppController`.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../state/backend_controller.dart';
import '../../state/backend_scope.dart';
import '../components/notice_card.dart';
import '../../l10n/strings_de.dart';
import '../../logic/app_state.dart';
import '../../logic/clock.dart';
import '../../logic/date_format.dart';
import '../../logic/day_program.dart';
import '../../logic/placeholder_pools.dart';
import '../../logic/plural.dart';
import '../../logic/streak.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../state/transient_ui.dart';
import '../../state/world_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import '../../theme/world_tokens.dart';
import '../components/category_card.dart';
import '../components/cura_chip.dart';
import '../components/cura_snackbar.dart';
import '../components/dashed_action.dart';
import '../components/floating_nav.dart';
import '../components/glass_card.dart';
import '../components/header_card.dart';
import '../components/probe_keys.dart';
import '../components/size_reporter.dart';
import '../components/tab_page.dart';
import '../components/time_segment.dart';
import '../components/world_label_chip.dart';
import '../home/home_shell.dart';
import '../path/path_error_view.dart';
import '../routes/route_focus.dart';
import 'custom_exercise_dialog.dart';
import 'primary_action_row.dart';
import 'today_loading_view.dart';
import 'today_source.dart';
import 'training_mode_sheet.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.load, required this.onRetry});

  /// Ladezustand (verwaltet die `HomeShell`).
  final TodayLoadState load;
  final VoidCallback onRetry;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final FocusNode _startFocus = FocusNode(debugLabel: 'Training eintragen');
  final FocusNode _customFocus = FocusNode(debugLabel: 'Eigene Übung');

  /// Fokusknoten von „Tauschen“ je Übung (nur für den Fokus nach „Entfernen“).
  final Map<String, FocusNode> _swapFocus = <String, FocusNode>{};

  FocusNode _swapNode(String id) =>
      _swapFocus.putIfAbsent(id, () => FocusNode(debugLabel: 'Tauschen $id'));

  /// Gemessene Höhe der Primärbutton-Reihe (mit dem Manny-Knopf).
  double _groupHeight = 0;

  /// Mindesthöhe der Reihe vor der ersten Messung: der Manny-Knopf.
  static const double _groupMinHeight = CuraSize.mannyChatButton;

  @override
  void dispose() {
    _startFocus.dispose();
    _customFocus.dispose();
    for (final FocusNode n in _swapFocus.values) {
      n.dispose();
    }
    super.dispose();
  }

  AppController get _controller =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;

  HomeShellState get _shell => HomeShellScope.of(context);

  // -------------------------------------------------------------------------
  // Aktionen
  // -------------------------------------------------------------------------

  /// Folgen eines Tageswechsels, den eine Aktion ausgelöst hat (Plan 4.6).
  void _afterMutation(DayChangeResult change) {
    if (change.changed) unawaited(_shell.dayChanged());
  }

  void _selectTime(int minutes) =>
      _afterMutation(_controller.selectTime(minutes));

  void _swap(DisplayedExercise exercise) =>
      _afterMutation(_controller.swapExercise(exercise.id));

  void _remove(DisplayedExercise exercise) {
    final AppController c = _controller;
    final HomeShellState shell = _shell;
    final List<DisplayedExercise> before = _currentExercises();
    final int index = before.indexWhere(
      (DisplayedExercise e) => e.id == exercise.id,
    );
    final RemoveResult result = c.removeExercise(exercise.id);
    final RemovalToken? token = result.token;
    if (token != null) _focusAfterRemove(index);
    if (result.dayChanged) {
      // Der Tag hat gewechselt: kein Rückgängig für einen Eintrag, der auf
      // dem neuen Tag wirkte (Ergänzung 1, 3.4: das Fenster endet).
      unawaited(shell.dayChanged());
      c.transient.endUndoWindow();
      return;
    }
    if (token == null) return;
    _showUndo(
      text: S.removedSnackbar,
      actionSemantics: S.undoRemovedLabel,
      owns: (UndoEntry? e) => e is RemovalUndo && identical(e.token, token),
      onUndo: () {
        final UndoResult r = c.undoRemove(token);
        if (r.dayChanged) unawaited(shell.dayChanged());
      },
    );
  }

  List<DisplayedExercise> _currentExercises() {
    final AppState state = _controller.state;
    return deriveExercises(state.day, state.prefs.timeChoice);
  }

  /// Fokus nach „Entfernen“ (F-7): Die Karte, die an die Stelle der entfernten
  /// rückt, übernimmt ihn auf „Tauschen“; fehlt sie oder hat sie kein
  /// „Tauschen“, geht er auf „+ Eigene Übung“. Der entfernte Knopf ist weg,
  /// der Fokus fiele sonst an den Anfang der Seite.
  void _focusAfterRemove(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final List<DisplayedExercise> now = _currentExercises();
      if (index >= 0 && index < now.length && now[index].canSwap) {
        _swapNode(now[index].id).requestFocus();
      } else {
        _customFocus.requestFocus();
      }
    });
  }

  /// Zeigt „… Rückgängig“ (8 s). Die Snackbar entscheidet über das Ende des
  /// Fensters (Ablauf mit Pause bei Fokus und Zeiger, kein Ablauf bei
  /// Screenreader); wenn sie endet, endet das Fenster, sofern es noch ihrem
  /// Eintrag gehört (eine neue Snackbar ersetzt die alte, deren Fenster dann
  /// schon durch das neue ersetzt wurde).
  void _showUndo({
    required String text,
    required String actionSemantics,
    required bool Function(UndoEntry? entry) owns,
    required VoidCallback onUndo,
  }) {
    final TransientUi transient = _controller.transient;
    transient.holdUndoWindow();
    _shell.snackbar.show(
      CuraSnackbarMessage(
        text: text,
        duration: SnackbarTokens.long,
        actionLabel: S.undo,
        actionSemanticsLabel: actionSemantics,
        onAction: onUndo,
        onClosed: (SnackbarCloseReason _) {
          if (owns(transient.undo)) transient.endUndoWindow();
        },
      ),
    );
  }

  Future<void> _startTraining() async {
    final HomeShellState shell = _shell;
    // Der Tag, den der Nutzer sieht (Plan 7.5): auf ihn trägt das Sheet ein,
    // auch wenn bis zum Tipp auf „Eintragen“ Mitternacht vergeht.
    final LocalDay openedDay = _controller.state.day.dayKey;
    bool handled = false;
    final Route<void> route = TrainingModeSheet.route(
      context,
      onLog: (BuildContext sheetContext) {
        if (handled) return;
        handled = true;
        _logTraining(sheetContext, openedDay);
      },
    );
    shell.todayRoutes.register(route);
    await pushReturningFocus<void>(
      Navigator.of(context),
      route,
      trigger: _startFocus,
    );
  }

  void _logTraining(BuildContext sheetContext, LocalDay openedDay) {
    final AppController c = _controller;
    final HomeShellState shell = _shell;
    final TrainingResult result = c.logTraining(forDay: openedDay);
    if (result.dayChanged) {
      // Eintrag über Mitternacht: `dayChanged` schließt das Sheet, wartet das
      // Ende der Entfernung ab und prüft dann die Bedingung für Snackbar und
      // Ansage (Plan 4.6, Reihenfolge).
      unawaited(shell.dayChanged());
      return;
    }
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    final TrainingSnapshot? snapshot = result.snapshot;
    if (snapshot == null) return;
    _showUndo(
      text: S.loggedSnackbar,
      actionSemantics: S.undoLoggedLabel,
      owns: (UndoEntry? e) =>
          e is TrainingUndo && identical(e.snapshot, snapshot),
      onUndo: () {
        final UndoResult r = c.undoTraining(snapshot);
        if (r.applied && mounted) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            S.loggedUndoneAnnouncement,
            Directionality.of(context),
          );
        }
        if (r.dayChanged) unawaited(shell.dayChanged());
      },
    );
  }

  Future<void> _addCustom() async {
    final HomeShellState shell = _shell;
    final Route<CustomExerciseInput?> route = CustomExerciseDialog.route(
      context,
    );
    shell.todayRoutes.register(route);
    final CustomExerciseInput? input =
        await pushReturningFocus<CustomExerciseInput?>(
          Navigator.of(context),
          route,
          trigger: _customFocus,
        );
    if (input == null || !mounted) return;
    _afterMutation(
      _controller.addCustomExercise(
        name: input.name,
        reps: input.reps,
        minutes: input.minutes,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Aufbau
  // -------------------------------------------------------------------------

  CategoryKind _kindOf(Appointment a) =>
      a.category == AppointmentCategory.physio
      ? CategoryKind.physio
      : CategoryKind.doctor;

  Widget _exerciseCard(DisplayedExercise e) {
    return CategoryCard(
      key: ValueKey<String>('exercise:${e.id}'),
      kind: CategoryKind.exercise,
      title: e.name,
      meta: S.exerciseMeta(e.reps, e.minutes),
      semanticLabel: S.exerciseLabel(e.name, e.reps, e.minutes),
      actions: <Widget>[
        if (e.canSwap)
          CuraChip(
            label: S.exerciseSwap,
            icon: Icons.swap_horiz_rounded,
            semanticLabel: S.exerciseSwapLabel(e.name),
            focusNode: _swapNode(e.id),
            onPressed: () => _swap(e),
          ),
        CuraChip(
          label: S.exerciseRemove,
          icon: Icons.close_rounded,
          semanticLabel: S.exerciseRemoveLabel(e.name),
          onPressed: () => _remove(e),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.load) {
      case TodayLoadState.loading:
        return const TodayLoadingView();
      case TodayLoadState.error:
        return PathErrorView(
          onRetry: widget.onRetry,
          message: S.todayLoadError,
        );
      case TodayLoadState.ready:
        break;
    }
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final AppController controller = AppScope.of(context);
    final AppState state = controller.state;
    final HomeShellState shell = HomeShellScope.of(context);
    final bool active = shell.activeTab == HomeTab.today;

    final LocalDay day = state.day.dayKey;
    final List<DisplayedExercise> exercises = deriveExercises(
      state.day,
      state.prefs.timeChoice,
    );
    final List<Appointment> appointments = appointmentsFor(day);
    final TrainingButtonState button = state.day.done
        ? TrainingButtonState.done
        : (exercises.isEmpty
              ? TrainingButtonState.disabled
              : TrainingButtonState.start);
    final StreakView streak = StreakEngine.view(state.streak);
    final bool frozen = streak.display == StreakDisplay.frozen;

    // Reserve unter dem Inhalt: Primärbutton-Reihe (gemessen) samt Luft; die
    // Leiste samt Abstand legt `TabPage` selbst dazu.
    final double group = math.max(_groupHeight, _groupMinHeight);
    final double reserveBase = group + CuraSize.todayEndAir;

    final Widget header = HeaderCard(
      title: S.todayTitle(state.onboarding.firstName),
      subtitle: formatDateLong(day),
      chips: <Widget>[
        HeaderChip(
          icon: Icons.local_fire_department_rounded,
          label: frozen
              ? '${streak.count} ${S.streakFrozenWord}'
              : '${streak.count}',
          semanticLabel: frozen
              ? S.streakFrozenLabel(tage(streak.count))
              : S.streakLabel(tage(streak.count)),
        ),
      ],
    );

    final BackendController? backend = BackendScope.maybeOf(context);
    final List<Widget> content = <Widget>[
      // Zurückgestellte Warteschlangen-Einträge (NIT-2, A10): dezent, nicht
      // modal, ohne Werte.
      if (backend != null && backend.deferredNoticeVisible)
        NoticeCard(
          kind: NoticeKind.sync,
          text: backend.deferredCount == 1
              ? S.syncNoticeOne
              : S.syncNoticeMany(backend.deferredCount),
          detail: backend.deferredCount == 1
              ? S.syncNoticeDetail
              : S.syncNoticeDetailMany,
          actionLabel: S.syncResend,
          onAction: backend.resendDeferred,
          onDismiss: backend.dismissDeferredNotice,
          dismissLabel: S.syncHide,
        ),
      TimeSegment(
        choices: kTimeChoices,
        selected: state.prefs.timeChoice,
        onSelected: _selectTime,
      ),
      _section(
        label: S.appointmentsHeading,
        children: <Widget>[
          if (appointments.isEmpty)
            GlassCard(
              child: Text(
                S.noAppointments,
                style: type.body.copyWith(color: colors.text1),
              ),
            )
          else
            for (final Appointment a in appointments)
              CategoryCard(
                kind: _kindOf(a),
                title: a.title,
                meta: a.meta,
                time: a.timeText,
                semanticLabel: a.semanticsLabel,
              ),
        ],
      ),
      _section(
        label: exercisesHeading(exercises),
        children: <Widget>[
          if (exercises.isEmpty)
            GlassCard(
              child: Text(
                S.emptyExercises,
                style: type.body.copyWith(color: colors.text1),
              ),
            )
          else
            for (final DisplayedExercise e in exercises) _exerciseCard(e),
          DashedAction(
            label: S.customAdd,
            semanticLabel: S.customAddLabel,
            focusNode: _customFocus,
            onPressed: _addCustom,
          ),
        ],
      ),
    ];

    return Stack(
      children: <Widget>[
        Positioned.fill(
          // Solange eine Snackbar steht, gehört ihre gemessene Höhe samt
          // 12 dp Abstand zur Reserve: sie überdeckt den letzten Eintrag nie.
          child: ValueListenableBuilder<double>(
            valueListenable: shell.snackbarHeight,
            builder: (BuildContext context, double snack, Widget? _) {
              return TabPage(
                header: header,
                extraReserve: snack > 0
                    ? reserveBase + CuraSpace.snackbarGap + snack
                    : reserveBase,
                children: content,
              );
            },
          ),
        ),
        if (active) _buttonRowVeil(context),
        if (active)
          Positioned(
            left: CuraSpace.pageMargin,
            right: CuraSpace.pageMargin,
            bottom: FloatingNav.occupiedHeight(context) + CuraSpace.pageMargin,
            child: SizeReporter(
              onSize: (Size size) {
                shell.todayGroupHeight.value = size.height;
                if (mounted && size.height != _groupHeight) {
                  setState(() => _groupHeight = size.height);
                }
              },
              child: KeyedSubtree(
                key: ProbeKeys.primaryRow,
                child: PrimaryActionRow(
                  state: button,
                  onStart: _startTraining,
                  onOpenChat: shell.openChat,
                  startFocusNode: _startFocus,
                  chatFocusNode: shell.chatButtonFocus,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Schleier hinter der festen Knopfzeile (N2): Ohne ihn schneidet die Zeile
  /// scrollenden Inhalt mitten in der Zeile ab. Er läuft über 8 dp von 0 auf
  /// `world-floor` zu 70 % und deckt dahinter die Zeile; rein gemalt, nie
  /// Treffer, nicht in der Semantik.
  Widget _buttonRowVeil(BuildContext context) {
    final Color floor = WorldScope.paletteOf(context).floor;
    return Positioned(
      left: 0,
      right: 0,
      bottom: FloatingNav.occupiedHeight(context) + CuraSpace.pageMargin,
      height: CuraSize.todayVeilFade + math.max(_groupHeight, _groupMinHeight),
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  floor.withValues(alpha: 0),
                  floor.withValues(alpha: WorldGeometry.navVeilAlpha),
                  floor.withValues(alpha: WorldGeometry.navVeilAlpha),
                ],
                stops: <double>[
                  0,
                  CuraSize.todayVeilFade /
                      (CuraSize.todayVeilFade +
                          math.max(_groupHeight, _groupMinHeight)),
                  1,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Abschnitt mit Label-Chip als Überschrift (V2-5: Text auf der Welt steht
  /// nur auf einem Label-Chip), darunter die Karten mit 12 dp Abstand.
  Widget _section({required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: WorldLabelChip(label, header: true),
        ),
        const SizedBox(height: CuraSpace.s2),
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: CuraSpace.s3),
          children[i],
        ],
      ],
    );
  }
}
