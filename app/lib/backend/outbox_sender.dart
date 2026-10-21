// Sender der Ausgangswarteschlange (Plan 8.11, 8.10): arbeitet die Einträge
// strikt in Einfügereihenfolge ab, ordnet Fehler nach `classifyFailure` ein und
// speichert nach jeder Änderung.
//
// Auslöser (Start, Fortsetzen, neuer Eintrag, neue Verbindung, Wartezeit
// abgelaufen) liegen bei der aufrufenden Stelle; der Sender hält keinen Timer.
// Zurückgestellte Einträge (`invalid_local_day`) werden nur bei
// `drain(retryDeferred: true)` erneut versucht (Start und neue Verbindung).
import 'dart:async';

import '../data/outbox_store.dart';
import '../logic/account.dart';
import '../logic/backend_failure.dart';
import '../logic/outbox.dart';
import 'patient_backend.dart';

/// Warum eine Runde endete.
enum DrainStop {
  /// Nichts mehr zu senden (außer zurückgestellten Einträgen).
  idle,

  /// Vorübergehender Fehler: später erneut ([DrainReport.retryAfter]).
  retryLater,

  /// `pauseAndDrain` ist aktiv.
  paused,

  /// Die Bindung besteht nicht mehr (Sitzungserneuerung scheitert, Konto weg).
  bindingLost,
}

class DrainReport {
  const DrainReport({
    required this.stop,
    this.sent = 0,
    this.discarded = 0,
    this.deferred = 0,
    this.retryAfter,
  });

  final DrainStop stop;
  final int sent;
  final int discarded;

  /// In dieser Runde zurückgestellt.
  final int deferred;

  /// Wartezeit bis zum nächsten Versuch bei [DrainStop.retryLater].
  final Duration? retryAfter;
}

class OutboxSender {
  OutboxSender({
    required this._store,
    required this._backend,
    this.onBindingLost,
    this.onUnreadable,
  });

  final OutboxStore _store;
  final PatientBackend _backend;

  /// Wird aufgerufen, wenn sich zeigt, dass die Bindung nicht mehr besteht.
  final void Function()? onBindingLost;

  /// Wird beim Laden aufgerufen, wenn Einträge nicht lesbar waren.
  final void Function(int skipped)? onUnreadable;

  final StreamController<Outbox> _changes =
      StreamController<Outbox>.broadcast();
  Outbox _outbox = Outbox();
  Future<void> _writeChain = Future<void>.value();
  Future<DrainReport>? _running;
  bool _paused = false;
  bool _rerun = false;
  bool _rerunDeferred = false;

  Outbox get outbox => _outbox;

  /// Zurückgestellte Einträge (NIT-2).
  int get deferredCount => _outbox.deferred.length;

  bool get isPaused => _paused;

  /// Jede Änderung der Warteschlange.
  Stream<Outbox> get changes => _changes.stream;

  /// Liest die gespeicherte Warteschlange (beim Start).
  Future<void> load() async {
    final LoadedOutbox loaded = await _store.load();
    _outbox = loaded.outbox;
    if (loaded.skipped > 0) onUnreadable?.call(loaded.skipped);
    _changes.add(_outbox);
  }

  /// Hängt einen Eintrag hinten an und speichert. Sendet nicht selbst: der
  /// Aufrufer ruft danach [drain] auf.
  Future<void> enqueue(OutboxEntry entry) async {
    _outbox = _outbox.enqueue(entry);
    _changes.add(_outbox);
    await _persist();
  }

  /// Arbeitet die Warteschlange ab. Läuft bereits eine Runde, wird sie
  /// fortgesetzt (keine zweite parallel) und danach einmal wiederholt.
  Future<DrainReport> drain({bool retryDeferred = false}) {
    final Future<DrainReport>? running = _running;
    if (running != null) {
      _rerun = true;
      _rerunDeferred = _rerunDeferred || retryDeferred;
      return running;
    }
    final Future<DrainReport> run = _runLoop(retryDeferred).whenComplete(() {
      _running = null;
      if (_rerun) {
        // Ein Aufruf kam, als die Runde schon am Ende war: einmal nachholen.
        final bool again = _rerunDeferred;
        _rerun = false;
        _rerunDeferred = false;
        unawaited(drain(retryDeferred: again));
      }
    });
    _running = run;
    return run;
  }

  /// Für „Alles löschen“ (Plan 8.10): startet nichts Neues und wartet auf die
  /// laufende Anfrage. `true`, wenn nichts mehr läuft; `false` nach [timeout]
  /// (die Anfrage gilt dann als unklar, der Server-Lock schützt trotzdem).
  Future<bool> pauseAndDrain({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _paused = true;
    final Future<DrainReport>? running = _running;
    if (running == null) return true;
    try {
      await running.timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  /// Hebt die Pause auf (nach abgebrochener Löschung).
  void resume() => _paused = false;

  /// Verwirft die Warteschlange und löscht den Speicher (nach „Alles löschen“
  /// oder Neubindung, B-11).
  Future<void> discardAll() async {
    _outbox = Outbox();
    _changes.add(_outbox);
    await _persist();
    await _store.eraseAll();
  }

  Future<void> dispose() async {
    await _changes.close();
  }

  Future<void> _persist() {
    final Outbox snapshot = _outbox;
    _writeChain = _writeChain.then((_) => _store.save(snapshot));
    return _writeChain;
  }

  Future<DrainReport> _runLoop(bool retryDeferred) async {
    int sent = 0;
    int discarded = 0;
    int deferred = 0;
    final bool includeDeferred = retryDeferred;
    DrainStop stop = DrainStop.idle;
    Duration? retryAfter;
    final Set<String> skip = <String>{};
    bool refreshedOnce = false;

    while (true) {
      if (_paused) {
        stop = DrainStop.paused;
        break;
      }
      final OutboxEntry? entry = _outbox.next(
        skip: skip,
        includeDeferred: includeDeferred,
      );
      if (entry == null) break;

      OutboxVerdict verdict;
      String? error;
      try {
        await _backend.send(entry);
        verdict = OutboxVerdict.success;
      } on BackendFailure catch (failure) {
        verdict = classifyFailure(entry.kind, failure);
        error = failure.toString();
      } on BindingLostException {
        stop = DrainStop.bindingLost;
        onBindingLost?.call();
        break;
      } on Object catch (e) {
        // Unbekannter Fehler (kein Netzproblem, kein Serverfehler): nichts
        // verwerfen, später erneut.
        verdict = OutboxVerdict.retryLater;
        error = e.toString();
      }

      if (verdict == OutboxVerdict.refreshSession) {
        if (refreshedOnce) {
          verdict = OutboxVerdict.retryLater;
        } else {
          refreshedOnce = true;
          final SessionRefresh refresh = await _backend.refreshSession();
          if (refresh == SessionRefresh.refreshed) continue; // erneut versuchen
          if (refresh == SessionRefresh.accountGone) {
            stop = DrainStop.bindingLost;
            onBindingLost?.call();
            break;
          }
          verdict = OutboxVerdict.retryLater;
        }
      }

      switch (verdict) {
        case OutboxVerdict.success:
          sent++;
          _outbox = _outbox.remove(entry.id);
        case OutboxVerdict.discard:
          discarded++;
          _outbox = _outbox.remove(entry.id);
        case OutboxVerdict.defer:
          deferred++;
          skip.add(entry.id);
          _outbox = _outbox.replace(
            entry.copyWith(
              attempts: entry.attempts + 1,
              deferred: true,
              lastError: error,
            ),
          );
        case OutboxVerdict.retryLater:
        case OutboxVerdict.refreshSession:
          final OutboxEntry updated = entry.copyWith(
            attempts: entry.attempts + 1,
            lastError: error,
          );
          _outbox = _outbox.replace(updated);
          retryAfter = backoffFor(updated.attempts);
          stop = DrainStop.retryLater;
      }
      _changes.add(_outbox);
      await _persist();
      if (stop == DrainStop.retryLater) break;
    }
    return DrainReport(
      stop: stop,
      sent: sent,
      discarded: discarded,
      deferred: deferred,
      retryAfter: retryAfter,
    );
  }
}
