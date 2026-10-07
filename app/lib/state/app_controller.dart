// Der eine langlebige Zustandshalter (Plan 5): hält den unveränderlichen
// `AppState`, ruft die reine Logik und schreibt über den `StateStore`.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/data_eraser.dart';
import '../data/state_store.dart';
import '../logic/app_state.dart';
import '../logic/clock.dart';
import '../logic/day_program.dart' as program;
import '../logic/day_rollover.dart' as rollover_logic;
import '../logic/injury_type.dart';
import '../logic/json_support.dart' show UnreadableDataException;
import '../logic/manny_context.dart';
import '../logic/manny_occasions.dart' as occasions;
import '../logic/manny_text_source.dart';
import '../logic/placeholder_pools.dart';
import '../logic/profile.dart' as profile_logic;
import '../logic/training.dart' as training_logic;
import '../logic/undo.dart' as undo_logic;
import 'transient_ui.dart';

export '../logic/manny_occasions.dart' show BubbleDecision, MannyOccasion;
export '../logic/undo.dart' show RemovalToken, TrainingSnapshot;

enum LoadStatus { loading, ready, error }

/// Hinweis, der nach dem Neustart des Onboardings einmal gezeigt wird.
enum StartNotice {
  none,

  /// Nach „Alles löschen“ (Snackbar „Alle Daten sind gelöscht.“).
  deleted,

  /// Nach unlesbaren Daten (N-12, A-34).
  unreadable,
}

/// Ergebnis der Tageswechsel-Prüfung. Bei `changed`: Snackbar, Heute-Routen
/// schließen, Undo beenden – das tut die UI (Plan 4.6).
class DayChangeResult {
  const DayChangeResult(this.changed);

  static const DayChangeResult none = DayChangeResult(false);

  final bool changed;
}

class TrainingResult {
  const TrainingResult({required this.snapshot, required this.dayChanged});

  /// Schnappschuss für „Rückgängig“; `null`, wenn nichts eingetragen wurde
  /// oder der Eintrag über Mitternacht ging (dort gibt es kein Fenster).
  final undo_logic.TrainingSnapshot? snapshot;
  final bool dayChanged;
}

class RemoveResult {
  const RemoveResult({required this.token, required this.dayChanged});

  final undo_logic.RemovalToken? token;
  final bool dayChanged;
}

class UndoResult {
  const UndoResult({required this.applied, required this.dayChanged});

  /// `false`: nach einem Tageswechsel abgelehnt bzw. nichts zu tun.
  final bool applied;
  final bool dayChanged;
}

class ProfileUpdateResult {
  const ProfileUpdateResult({
    required this.saved,
    required this.nameChanged,
    required this.pathRecomputed,
    required this.dayChanged,
  });

  /// `false`, wenn der Entwurf nicht speicherbar war (`canSave`).
  final bool saved;
  final bool nameChanged;
  final bool pathRecomputed;
  final bool dayChanged;
}

class PathVisit {
  const PathVisit({required this.bubble, required this.dayChange});

  final occasions.BubbleDecision? bubble;
  final DayChangeResult dayChange;
}

class AppController extends ChangeNotifier {
  AppController({
    required this._clock,
    required this._store,
    required this._mannyText,
    required List<DataEraser> erasers,
    TransientUi? transient,
  }) : _erasers = List<DataEraser>.unmodifiable(erasers),
       _ownsTransient = transient == null,
       _transient = transient ?? TransientUi() {
    _state = AppState.initial(today);
  }

  final Clock _clock;
  final StateStore _store;
  final MannyTextSource _mannyText;
  final List<DataEraser> _erasers;
  final TransientUi _transient;
  final bool _ownsTransient;

  late AppState _state;
  LoadStatus _loadStatus = LoadStatus.loading;
  StartNotice _startNotice = StartNotice.none;
  bool _deleting = false;
  Future<void> _writeChain = Future<void>.value();
  int _customSeq = 0;

  AppState get state => _state;
  LoadStatus get loadStatus => _loadStatus;
  StartNotice get startNotice => _startNotice;
  TransientUi get transient => _transient;
  MannyTextSource get mannyText => _mannyText;

  /// Läuft gerade „Alles löschen“ (Schreiben gesperrt, Dialog `busy`).
  bool get isDeleting => _deleting;

  LocalDay get today => LocalDay.from(_clock());

  MannyContext get mannyContext => MannyContext.from(_state, today);

  /// Text der Blase für eine Entscheidung (aus der austauschbaren Quelle).
  String bubbleText(occasions.BubbleDecision decision) =>
      _mannyText.bubbleText(decision.occasion, mannyContext);

  /// Leerlauf der seriellen Schreibschlange (für Tests und `deleteAll`).
  Future<void> get idle => _writeChain;

  // -------------------------------------------------------------------------
  // Laden
  // -------------------------------------------------------------------------

  /// Lädt den Zustand. Unlesbare Daten (N-12): verwerfen, Onboarding Schritt
  /// 1 mit [StartNotice.unreadable]. Plattformfehler beim Lesen (oder beim
  /// Verwerfen): [LoadStatus.error], „Nochmal versuchen“ → [retryLoad].
  Future<void> load() async {
    _loadStatus = LoadStatus.loading;
    notifyListeners();
    try {
      final AppState? loaded = await _store.load();
      _state = loaded ?? AppState.initial(today);
      _startNotice = StartNotice.none;
      // Tageswechsel beim App-Start: still anwenden.
      final bool changed = _applyRollover().changed;
      if (changed) _enqueueWrite();
      _loadStatus = LoadStatus.ready;
    } on UnreadableDataException catch (e) {
      debugPrint('Gespeicherte Daten unlesbar, Neustart: $e');
      try {
        await _eraseAll();
        _state = AppState.initial(today);
        _startNotice = StartNotice.unreadable;
        _loadStatus = LoadStatus.ready;
      } catch (err) {
        debugPrint('Verwerfen unlesbarer Daten fehlgeschlagen: $err');
        _loadStatus = LoadStatus.error;
      }
    } catch (e) {
      debugPrint('Lesefehler: $e');
      _loadStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> retryLoad() => load();

  /// Der Hinweis wurde gezeigt.
  void clearStartNotice() {
    if (_startNotice == StartNotice.none) return;
    _startNotice = StartNotice.none;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Tageswechsel zuerst (N-11)
  // -------------------------------------------------------------------------

  DayChangeResult _applyRollover() {
    final rollover_logic.RolloverResult r = rollover_logic.rollover(
      _state,
      today,
    );
    if (!r.changed) return DayChangeResult.none;
    _state = r.state;
    _transient.endUndoWindow();
    return const DayChangeResult(true);
  }

  /// Gemeinsamer Wrapper: Jede mutierende Methode wendet **zuerst** einen
  /// Tageswechsel an, danach wirkt [change] auf dem neuen Tag.
  DayChangeResult _mutate(AppState Function(AppState current) change) {
    final DayChangeResult dc = _applyRollover();
    _commit(change(_state), force: dc.changed);
    return dc;
  }

  void _commit(AppState next, {bool force = false}) {
    if (!force && next == _state) return;
    _state = next;
    _enqueueWrite();
    notifyListeners();
  }

  /// Wendet einen Tageswechsel an (App-Start, Resume, Tabwechsel).
  DayChangeResult checkDayChange() => _mutate((AppState s) => s);

  // -------------------------------------------------------------------------
  // Schreiben (serielle Schlange, A-4)
  // -------------------------------------------------------------------------

  void _enqueueWrite() {
    if (_deleting) return;
    final AppState snapshot = _state;
    _writeChain = _writeChain.then((_) async {
      if (_deleting) return;
      try {
        await _store.save(snapshot);
      } catch (e) {
        // Keine UI; der nächste Schreibvorgang versucht es erneut (A-4).
        debugPrint('Speichern fehlgeschlagen: $e');
      }
    });
  }

  // -------------------------------------------------------------------------
  // Onboarding
  // -------------------------------------------------------------------------

  void setName(String name) => _mutate(
    (AppState s) => s.copyWith(onboarding: s.onboarding.copyWith(name: name)),
  );

  void setStep(int step) => _mutate(
    (AppState s) =>
        s.copyWith(onboarding: s.onboarding.copyWith(step: step.clamp(0, 3))),
  );

  /// Speichert die Einwilligung (UTC-Zeitstempel, Version `prototype-0`);
  /// erneutes Bestätigen überschreibt den Zeitstempel (A-2).
  void acceptConsent() => _mutate(
    (AppState s) => s.copyWith(
      consent: ConsentState(
        acceptedAt: _clock().toUtc(),
        version: ConsentState.kVersion,
      ),
    ),
  );

  void selectInjury(InjuryType type) => _mutate(
    (AppState s) =>
        s.copyWith(onboarding: s.onboarding.copyWith(injuryType: type)),
  );

  void setInjuryOther(String text) => _mutate(
    (AppState s) =>
        s.copyWith(onboarding: s.onboarding.copyWith(injuryOther: text)),
  );

  void setInjuryDate(LocalDay day) => _mutate(
    (AppState s) =>
        s.copyWith(onboarding: s.onboarding.copyWith(injuryDate: day)),
  );

  /// Schließt das Onboarding ab (Begrüßung wird fällig, A-21). Fehlt Name,
  /// Verletzungstyp, Datum oder Einwilligung, passiert nichts (`false`).
  bool completeOnboarding() {
    final AppState s = _state;
    final OnboardingState o = s.onboarding;
    if (o.firstName.isEmpty ||
        o.injuryType == null ||
        o.injuryDate == null ||
        s.consent == null) {
      return false;
    }
    _mutate(
      (AppState cur) => cur.copyWith(
        onboarding: cur.onboarding.copyWith(
          completed: true,
          step: 3,
          injuryOther: cur.onboarding.injuryType == InjuryType.other
              ? cur.onboarding.injuryOther
              : '',
        ),
        manny: cur.manny.copyWith(greetingPending: true),
      ),
    );
    return true;
  }

  // -------------------------------------------------------------------------
  // Heute
  // -------------------------------------------------------------------------

  /// Zeitwahl 10/20/30; andere Werte werden ignoriert.
  DayChangeResult selectTime(int minutes) => _mutate(
    (AppState s) => kTimeChoices.contains(minutes)
        ? s.copyWith(prefs: PrefsState(timeChoice: minutes))
        : s,
  );

  DayChangeResult swapExercise(String id) =>
      _mutate((AppState s) => s.copyWith(day: program.swapExercise(s.day, id)));

  /// Entfernt eine Übung. Mit Token: ein Rückgängig-Fenster ist offen.
  RemoveResult removeExercise(String id) {
    undo_logic.RemovalToken? token;
    final DayChangeResult dc = _mutate((AppState s) {
      final program.DayProgramState before = s.day;
      final program.DayProgramState after = program.removeExercise(before, id);
      if (after == before) return s;
      final int index = before.custom.indexWhere(
        (program.CustomExercise c) => c.id == id,
      );
      token = undo_logic.RemovalToken(
        day: before.dayKey,
        exerciseId: id,
        customExercise: index >= 0 ? before.custom[index] : null,
        customIndex: index < 0 ? 0 : index,
      );
      return s.copyWith(day: after);
    });
    final undo_logic.RemovalToken? result = token;
    if (result != null) _transient.startUndoWindow(RemovalUndo(result));
    return RemoveResult(token: result, dayChanged: dc.changed);
  }

  /// Nimmt „Entfernt“ zurück; nach einem Tageswechsel abgelehnt.
  UndoResult undoRemove(undo_logic.RemovalToken token) {
    bool applied = false;
    final DayChangeResult dc = _mutate((AppState s) {
      if (token.day != s.day.dayKey) return s;
      applied = true;
      return s.copyWith(day: undo_logic.undoRemoval(s.day, token));
    });
    _transient.endUndoWindow();
    return UndoResult(applied: applied, dayChanged: dc.changed);
  }

  /// Fügt eine eigene Übung hinzu (Dialog „Eigene Übung“). Leerer Name:
  /// nichts passiert. Leere Wiederholungen/Dauer fallen auf die Vorgaben
  /// zurück (N-16).
  DayChangeResult addCustomExercise({
    required String name,
    String reps = '',
    String minutes = '',
  }) {
    return _mutate((AppState s) {
      int seq = _customSeq;
      for (final program.CustomExercise c in s.day.custom) {
        final int? n = int.tryParse(c.id.replaceFirst('custom-', ''));
        if (n != null && n > seq) seq = n;
      }
      final program.CustomExercise? e = program.CustomExercise.fromInput(
        id: 'custom-${seq + 1}',
        name: name,
        reps: reps,
        minutes: minutes,
      );
      if (e == null) return s;
      _customSeq = seq + 1;
      return s.copyWith(day: program.addCustom(s.day, e));
    });
  }

  /// „Training eintragen“ für [forDay] (der Tag, an dem das Trainings-Sheet
  /// geöffnet wurde, N-11).
  ///
  /// - `forDay` ≥ heute: erst Tageswechsel, dann Eintrag.
  /// - `forDay` < heute (Eintrag über Mitternacht): **erst** der Eintrag für
  ///   `forDay` (zählt für den Vortag), **danach** der Tageswechsel; kein
  ///   Rückgängig-Fenster, die Feier verfällt mit dem Wechsel.
  /// - Passt `forDay` nicht zum Programm des Zustands, wird nichts eingetragen
  ///   (kein Eintrag auf den falschen Tag).
  TrainingResult logTraining({required LocalDay forDay}) {
    final LocalDay now = today;
    if (forDay.isBefore(now)) {
      final training_logic.TrainingApplied applied = training_logic
          .applyTraining(_state, forDay);
      final rollover_logic.RolloverResult r = rollover_logic.rollover(
        applied.state,
        now,
      );
      _transient.endUndoWindow();
      _commit(r.state, force: r.changed);
      return TrainingResult(snapshot: null, dayChanged: r.changed);
    }
    final DayChangeResult dc = _applyRollover();
    final training_logic.TrainingApplied applied = training_logic.applyTraining(
      _state,
      forDay,
    );
    _commit(applied.state, force: dc.changed);
    final undo_logic.TrainingSnapshot? snapshot = applied.snapshot;
    if (snapshot != null) _transient.startUndoWindow(TrainingUndo(snapshot));
    return TrainingResult(snapshot: snapshot, dayChanged: dc.changed);
  }

  /// Rückgängig für „Training eintragen“; nach einem Tageswechsel abgelehnt.
  UndoResult undoTraining(undo_logic.TrainingSnapshot snapshot) {
    bool applied = false;
    final DayChangeResult dc = _mutate((AppState s) {
      if (snapshot.day != s.day.dayKey) return s;
      applied = true;
      return undo_logic.undoTraining(s, snapshot);
    });
    _transient.endUndoWindow();
    return UndoResult(applied: applied, dayChanged: dc.changed);
  }

  // -------------------------------------------------------------------------
  // Pfad und Manny
  // -------------------------------------------------------------------------

  /// Beim Sichtbarwerden des Pfads: Tageswechsel prüfen, dann die nächste
  /// Blase bzw. Feier bestimmen (nicht während des Rückgängig-Fensters).
  PathVisit onPathVisible() {
    final DayChangeResult dc = _mutate((AppState s) => s);
    return PathVisit(
      bubble: occasions.nextBubble(
        _state,
        _clock(),
        undoWindowOpen: _transient.undoWindowOpen,
      ),
      dayChange: dc,
    );
  }

  /// Die Blase des Anlasses wurde gezeigt (oder weggetippt, zählt als gezeigt).
  void markBubbleShown(occasions.MannyOccasion occasion) =>
      _mutate((AppState s) => occasions.markBubbleShown(s, occasion, today));

  /// Feier und Puls wurden gezeigt.
  void consumeCelebration() => _mutate(occasions.consumeCelebration);

  // -------------------------------------------------------------------------
  // Profil
  // -------------------------------------------------------------------------

  ProfileUpdateResult updateProfile(profile_logic.ProfileDraft draft) {
    profile_logic.ProfileUpdate? update;
    final DayChangeResult dc = _mutate((AppState s) {
      if (!draft.canSave(s, today)) return s;
      update = profile_logic.applyProfile(s, draft, today);
      return update!.state;
    });
    final profile_logic.ProfileUpdate? u = update;
    return ProfileUpdateResult(
      saved: u != null,
      nameChanged: u?.nameChanged ?? false,
      pathRecomputed: u?.pathRecomputed ?? false,
      dayChanged: dc.changed,
    );
  }

  // -------------------------------------------------------------------------
  // Löschen (Plan 6.3, n4)
  // -------------------------------------------------------------------------

  Future<void> _eraseAll() async {
    for (final DataEraser e in _erasers) {
      await e.eraseAll();
    }
  }

  /// „Alles löschen“: (1) Schreiben sperren, (2) auf das Leerlaufen der
  /// Schreibschlange warten, (3) alle Löscher der Reihe nach, (4) Erfolg:
  /// Zustand zurücksetzen, Transientes verwerfen; das Schreiben bleibt gesperrt,
  /// bis die UI nach dem Neuaufbau des Onboardings [completeDeletion] ruft;
  /// (5) Fehler: Zustand unverändert, Schreiben wieder erlaubt, Fehler wird
  /// weitergereicht. Ein zweiter Aufruf während des Löschens tut nichts.
  Future<void> deleteAll() async {
    if (_deleting) return;
    _deleting = true;
    notifyListeners();
    try {
      await _writeChain;
      await _eraseAll();
    } catch (_) {
      _deleting = false;
      notifyListeners();
      rethrow;
    }
    _state = AppState.initial(today);
    _transient.reset();
    _startNotice = StartNotice.deleted;
    notifyListeners();
  }

  /// Hebt die Schreibsperre nach erfolgreichem Löschen auf (Neuaufbau ist
  /// erfolgt).
  void completeDeletion() {
    if (!_deleting) return;
    _deleting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_ownsTransient) _transient.dispose();
    super.dispose();
  }
}
