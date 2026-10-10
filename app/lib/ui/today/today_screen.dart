// `TodayScreen` (Brief 6.3, Ergänzung 1 3.3/3.4, Ergänzung 2 K3 bis K5,
// Plan 4.5, 4.6, 7.4 bis 7.6): der Tab „Heute“.
//
// - Inhalt (scrollt): Datum, „Heute, [Name]“, Zeitwahl 10/20/30, TERMINE
//   (Beispieltermine als `CategoryCard`s oder „Heute keine Termine.“), ÜBUNGEN
//   · CA. N MIN (Übungskarten mit Tauschen/Entfernen, Leerkarte „Heute noch
//   nichts geplant.“) und „+ Eigene Übung“.
// - Fest über der Nav (nur im Standard-Zustand, A-43): die Primärbutton-Reihe
//   („Training starten“ / „Heute erledigt“ + Manny-Button) und der
//   Nachrichten-Button 8 dp über der Oberkante des Manny-Buttons
//   (`PrimaryActionRow`). Die Scroll-Reserve am Listenende ist aus der
//   **gemessenen** Höhe der Gruppe gerechnet (Gruppe + Nav samt Abstand +
//   16 dp + 8 dp Luft), nicht aus festen Pixelwerten; die Snackbar steht 12 dp
//   über der Gruppe (`HomeShellState.todayGroupHeight`). Solange eine Snackbar
//   steht, kommt ihre gemessene Höhe samt 12 dp dazu (`snackbarHeight`), damit
//   sie den letzten Eintrag nie überdeckt.
// - „Training starten“ öffnet das Sheet „Wie willst du trainieren?“; es merkt
//   sich beim Öffnen den Tag (`openedDay`). „Training eintragen“ trägt für
//   diesen Tag ein (auch über Mitternacht, N-11), schließt das Sheet und zeigt
//   „Eingetragen. Rückgängig“ (8 s). „Entfernen“ zeigt „Entfernt. Rückgängig“.
//   Nach jeder Aktion, die einen Tageswechsel ausgelöst hat, übernimmt
//   `HomeShellState.dayChanged` die Folgen (Routen schließen, Snackbar, Ansage).
// - Laden und Fehler (Brief 6.3) ohne Button-Gruppe; der Fehler nutzt die
//   gemeinsame Fehleransicht mit „Nochmal versuchen“.
//
// Die Logik (Tagesprogramm, Eintragen, Rückgängig, Tageswechsel) kommt
// unverändert aus `lib/logic/` und dem `AppController`.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/strings_de.dart';
import '../../logic/app_state.dart';
import '../../logic/clock.dart';
import '../../logic/date_format.dart';
import '../../logic/day_program.dart';
import '../../logic/placeholder_pools.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../state/transient_ui.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import '../components/action_cluster.dart';
import '../components/category_card.dart';
import '../components/cura_chip.dart';
import '../components/cura_label.dart';
import '../components/cura_snackbar.dart';
import '../components/dashed_action.dart';
import '../components/floating_nav.dart';
import '../components/glass_card.dart';
import '../components/probe_keys.dart';
import '../components/size_reporter.dart';
import '../components/time_segment.dart';
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
  final FocusNode _startFocus = FocusNode(debugLabel: 'Training starten');
  final FocusNode _customFocus = FocusNode(debugLabel: 'Eigene Übung');

  /// Gemessene Höhe der Button-Gruppe (Reihe samt Nachrichten-Button).
  double _groupHeight = 0;

  /// Mindesthöhe der Gruppe vor der ersten Messung: Manny-Button plus Abstand
  /// plus Nachrichten-Button.
  static const double _groupMinHeight =
      CuraSize.mannyChatButton + CuraSpace.clusterGap + CuraSize.messagesButton;

  @override
  void dispose() {
    _startFocus.dispose();
    _customFocus.dispose();
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
    final RemoveResult result = c.removeExercise(exercise.id);
    final RemovalToken? token = result.token;
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
    // auch wenn bis zum Tipp auf „Training eintragen“ Mitternacht vergeht.
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

    final double group = math.max(_groupHeight, _groupMinHeight);
    final double reserveBase =
        FloatingNav.occupiedHeight(context) +
        CuraSpace.pageMargin +
        group +
        CuraSize.todayEndAir;

    final List<Widget> content = <Widget>[
      // Linksbündig und nur so breit wie der Text: ein Knoten über die ganze
      // Breite täuscht Prüfungen, die den Untergrund aus dem Bild lesen.
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          formatDateLong(day),
          style: type.secondary.copyWith(color: colors.text2),
        ),
      ),
      Semantics(
        header: true,
        child: Text(
          S.todayTitle(state.onboarding.firstName),
          style: type.display.copyWith(color: colors.text1),
        ),
      ),
      const SizedBox(height: CuraSpace.s4),
      TimeSegment(
        choices: kTimeChoices,
        selected: state.prefs.timeChoice,
        onSelected: _selectTime,
      ),
      const SizedBox(height: CuraSpace.s6),
      const CuraLabel(S.appointmentsHeading),
      const SizedBox(height: CuraSpace.s3),
      if (appointments.isEmpty)
        Text(S.noAppointments, style: type.body.copyWith(color: colors.text2))
      else
        for (final Appointment a in appointments) ...<Widget>[
          CategoryCard(
            kind: _kindOf(a),
            title: a.title,
            meta: a.meta,
            time: a.timeText,
            semanticLabel: a.semanticsLabel,
          ),
          const SizedBox(height: CuraSpace.s3),
        ],
      const SizedBox(height: CuraSpace.s3),
      CuraLabel(exercisesHeading(exercises)),
      const SizedBox(height: CuraSpace.s3),
      if (exercises.isEmpty) ...<Widget>[
        GlassCard(
          child: Text(
            S.emptyExercises,
            style: type.body.copyWith(color: colors.text1),
          ),
        ),
        const SizedBox(height: CuraSpace.s3),
      ] else
        for (final DisplayedExercise e in exercises) ...<Widget>[
          _exerciseCard(e),
          const SizedBox(height: CuraSpace.s3),
        ],
      DashedAction(
        label: S.customAdd,
        semanticLabel: S.customAddLabel,
        focusNode: _customFocus,
        onPressed: _addCustom,
      ),
    ];

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            // Solange eine Snackbar steht, gehört ihre gemessene Höhe samt
            // 12 dp Abstand zur Reserve: sie überdeckt den letzten Eintrag nie.
            child: ValueListenableBuilder<double>(
              valueListenable: shell.snackbarHeight,
              builder: (BuildContext context, double snack, Widget? child) {
                final double reserve = snack > 0
                    ? reserveBase + CuraSpace.snackbarGap + snack
                    : reserveBase;
                return SingleChildScrollView(
                  key: ProbeKeys.scroll,
                  padding: EdgeInsets.fromLTRB(
                    CuraSpace.pageMargin,
                    CuraSpace.s6,
                    CuraSpace.pageMargin,
                    reserve,
                  ),
                  child: child,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: content,
              ),
            ),
          ),
        ),
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
                  messagesButton: KeyedSubtree(
                    key: ProbeKeys.cluster,
                    child: ActionCluster(
                      mode: ActionClusterMode.today,
                      onOpenMessages: shell.openMessages,
                      messagesFocusNode: shell.messagesButtonFocus,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
