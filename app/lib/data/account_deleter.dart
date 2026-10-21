// „Alles löschen“ mit Backend (Plan 8.10, M-4, KI-Plan v1.2 Abschnitt 9).
// Kein `DataEraser`: Backend und lokal haben unterschiedliche Fehlerregeln.
//
// Ablauf von [AccountDeleter.run]:
// 1. `OutboxSender.pauseAndDrain()` (nichts Neues senden, laufende Anfrage abwarten);
// 2. Merkzeichen `requested`;
// 3. `delete_my_data()` (setzt auch `patients.manny_look` auf `null`);
//    `ok` und `already_deleted` sind Erfolg;
// 4. Merkzeichen `backendDeleted`, abmelden, Warteschlange verwerfen, alle
//    lokalen Löscher der Reihe nach (Zustand, Zwischenspeicher, Darstellung,
//    Session-Zustand, Manny-Look …);
// 5. Merkzeichen entfernen — als Letztes.
//
// Fehlerregeln: [DeletionOutcome].
import '../backend/backend_errors.dart';
import '../backend/outbox_sender.dart';
import '../backend/patient_backend.dart';
import '../logic/account.dart';
import '../logic/backend_failure.dart';
import 'data_eraser.dart';
import 'key_value_store.dart';
import 'state_store.dart';

/// Stand der Löschung im Merkzeichen `curaone.deletion.v1`.
enum DeletionPhase {
  /// Löschung angefordert, Ergebnis im Backend noch nicht bekannt.
  requested,

  /// Backend gelöscht; es fehlt nur noch das lokale Aufräumen.
  backendDeleted,
}

abstract class DeletionMarkerStore {
  Future<DeletionPhase?> read();

  Future<void> write(DeletionPhase phase);

  Future<void> clear();
}

class StoreDeletionMarkerStore implements DeletionMarkerStore {
  StoreDeletionMarkerStore(this._store);

  final KeyValueStore _store;

  /// Unbekannter Inhalt gilt als `requested`: der Ablauf ist idempotent und
  /// wird dann sicher noch einmal durchlaufen.
  @override
  Future<DeletionPhase?> read() async {
    final String? raw = await _store.read(kDeletionStorageKey);
    if (raw == null) return null;
    return raw == DeletionPhase.backendDeleted.name
        ? DeletionPhase.backendDeleted
        : DeletionPhase.requested;
  }

  @override
  Future<void> write(DeletionPhase phase) =>
      _store.write(kDeletionStorageKey, phase.name);

  @override
  Future<void> clear() => _store.remove(kDeletionStorageKey);
}

enum DeletionOutcome {
  /// Alles gelöscht (Backend und lokal), Merkzeichen entfernt.
  done,

  /// Sicher **nicht** gelöscht (Netz vor dem Senden, Server hat die Anfrage
  /// abgelehnt): Merkzeichen entfernt, nichts geändert. Dialog mit „Nochmal
  /// versuchen“ und „Abbrechen“.
  notDeleted,

  /// Ergebnis unklar (Zeitüberschreitung nach dem Senden): Merkzeichen bleibt
  /// `requested`. Dialog wie bei [notDeleted]; die Wiederholung ist
  /// idempotent.
  unclear,

  /// Backend gelöscht, aber ein lokaler Löscher ist gescheitert. Rückkehr zum
  /// alten Zustand ist sinnlos: nur „Nochmal versuchen“ (setzt beim lokalen
  /// Aufräumen fort), RAM-Daten nicht mehr anzeigen.
  localFailure,
}

/// Ergebnis der Prüfung beim Start.
enum DeletionResume {
  /// Kein Merkzeichen.
  none,

  /// Unterbrochene Löschung wurde abgeschlossen.
  completed,

  /// Wie [DeletionOutcome.localFailure].
  localFailure,

  /// Merkzeichen `requested`, das Konto existiert noch: Löschung ist nicht
  /// geschehen; die Entscheidung (Merkzeichen entfernen oder erneut anbieten)
  /// liegt bei der aufrufenden Stelle.
  accountStillExists,

  /// Prüfung nicht möglich (keine Verbindung): Merkzeichen bleibt.
  unknown,
}

class AccountDeleter {
  AccountDeleter({
    required this.backend,
    required this.sender,
    required this.marker,
    required List<DataEraser> localErasers,
  }) : _erasers = List<DataEraser>.unmodifiable(localErasers);

  final PatientBackend backend;
  final OutboxSender sender;
  final DeletionMarkerStore marker;
  final List<DataEraser> _erasers;

  /// Führt die Löschung aus oder setzt sie fort. Wirft nicht; jede Folge steht
  /// in [DeletionOutcome].
  Future<DeletionOutcome> run() async {
    final DeletionPhase? phase = await marker.read();
    if (phase == DeletionPhase.backendDeleted) {
      return _finishLocally();
    }

    await sender.pauseAndDrain();
    await marker.write(DeletionPhase.requested);

    try {
      await withSessionRefresh<DeleteResult>(backend, backend.deleteMyData);
    } on BindingLostException {
      // Konto existiert nicht mehr: bereits gelöscht = Erfolg.
    } on BackendFailure catch (failure) {
      if (_isCertainlyNotDeleted(failure)) {
        await marker.clear();
        sender.resume();
        return DeletionOutcome.notDeleted;
      }
      sender.resume();
      return DeletionOutcome.unclear;
    } on Object {
      // Unerwartet: Ergebnis unklar, nichts annehmen.
      sender.resume();
      return DeletionOutcome.unclear;
    }

    await marker.write(DeletionPhase.backendDeleted);
    return _finishLocally();
  }

  /// Beim Start vor allem anderen aufrufen (Plan 8.10): schließt eine
  /// unterbrochene Löschung ab.
  Future<DeletionResume> resumeOnStart() async {
    final DeletionPhase? phase = await marker.read();
    if (phase == null) return DeletionResume.none;
    if (phase == DeletionPhase.requested) {
      try {
        await backend.fetchAccount();
        return DeletionResume.accountStillExists;
      } on BindingLostException {
        await marker.write(DeletionPhase.backendDeleted);
      } on Object {
        return DeletionResume.unknown;
      }
    }
    final DeletionOutcome outcome = await _finishLocally();
    return outcome == DeletionOutcome.done
        ? DeletionResume.completed
        : DeletionResume.localFailure;
  }

  /// Der Server hat geantwortet und die Funktion ist gescheitert (die
  /// Transaktion ist zurückgerollt), oder die Anfrage ging nie hinaus.
  /// Zeitüberschreitung und 5xx ohne Datenbankfehler sind unklar.
  bool _isCertainlyNotDeleted(BackendFailure f) {
    switch (f.kind) {
      case FailureKind.unreachable:
      case FailureKind.rejected:
      case FailureKind.auth:
        return true;
      case FailureKind.server:
        return f.sqlState != null;
      case FailureKind.timeout:
        return false;
    }
  }

  Future<DeletionOutcome> _finishLocally() async {
    try {
      await backend.signOut();
      await sender.discardAll();
      for (final DataEraser eraser in _erasers) {
        await eraser.eraseAll();
      }
    } on Object {
      return DeletionOutcome.localFailure;
    }
    // Als Letztes: erst jetzt gilt die Löschung als abgeschlossen.
    try {
      await marker.clear();
    } on Object {
      return DeletionOutcome.localFailure;
    }
    return DeletionOutcome.done;
  }
}
