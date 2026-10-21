// „Alles löschen“ mit Backend (Plan 8.10, M-4): Reihenfolge, Merkzeichen,
// Fehlerregeln (sicher nicht gelöscht / unklar / lokaler Fehler), Wiederaufnahme.
import 'package:curaone/backend/outbox_sender.dart';
import 'package:curaone/data/account_deleter.dart';
import 'package:curaone/data/data_eraser.dart';
import 'package:curaone/data/key_value_store.dart';
import 'package:curaone/data/outbox_store.dart';
import 'package:curaone/data/state_store.dart';
import 'package:curaone/dev/fake_backend.dart';
import 'package:curaone/logic/account.dart';
import 'package:curaone/logic/backend_failure.dart';
import 'package:curaone/logic/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_delegate.dart';

class RecordingEraser implements DataEraser {
  RecordingEraser(this.name, this.log, {this.fail = false, this.kv});

  final String name;
  final List<String> log;
  bool fail;
  final MemoryKeyValueStore? kv;

  @override
  Future<void> eraseAll() async {
    // Das Merkzeichen muss noch da sein, solange ein Löscher läuft.
    log.add('$name(marker=${kv?.values.containsKey(kDeletionStorageKey)})');
    if (fail) throw StateError('$name kaputt');
  }
}

class Rig {
  Rig() {
    store = StoreOutboxStore(kv);
    sender = OutboxSender(store: store, backend: backend);
    marker = StoreDeletionMarkerStore(kv);
    first = RecordingEraser('zustand', log, kv: kv);
    second = RecordingEraser('cache', log, kv: kv);
    deleter = AccountDeleter(
      backend: backend,
      sender: sender,
      marker: marker,
      localErasers: <DataEraser>[first, second],
    );
  }

  final MemoryKeyValueStore kv = MemoryKeyValueStore();
  final FakePatientBackend backend = FakePatientBackend();
  final List<String> log = <String>[];
  late final StoreOutboxStore store;
  late final OutboxSender sender;
  late final StoreDeletionMarkerStore marker;
  late final RecordingEraser first;
  late final RecordingEraser second;
  late final AccountDeleter deleter;
}

OutboxEntry entry() => mannyLookSetEntry(
  entryId: 'e',
  now: DateTime.utc(2026, 10, 7),
  look: 'ohne',
);

void main() {
  test(
    'Erfolg: Reihenfolge, Merkzeichen zuletzt, Warteschlange verworfen',
    () async {
      final Rig r = Rig();
      await r.sender.enqueue(entry());
      expect(r.kv.values.containsKey(kOutboxStorageKey), isTrue);
      r.backend.accountLook = null;

      final DeletionOutcome out = await r.deleter.run();
      expect(out, DeletionOutcome.done);

      // Backend zuerst, dann abmelden; nichts aus der Warteschlange wurde gesendet.
      expect(r.backend.calls, <String>['deleteMyData', 'signOut']);
      expect(r.backend.sent, isEmpty);
      // Lokale Löscher der Reihe nach, mit noch vorhandenem Merkzeichen.
      expect(r.log, <String>['zustand(marker=true)', 'cache(marker=true)']);
      // Merkzeichen als Letztes entfernt; Warteschlange weg.
      expect(r.kv.values.containsKey(kDeletionStorageKey), isFalse);
      expect(r.kv.values.containsKey(kOutboxStorageKey), isFalse);
      expect(r.sender.outbox.isEmpty, isTrue);
      expect(r.backend.deleted, isTrue);
    },
  );

  test('Merkzeichen requested steht schon vor dem Backend-Aufruf', () async {
    final Rig r = Rig();
    DeletionPhase? during;
    final AccountDeleter d = AccountDeleter(
      backend: DeleteProbe(
        r.backend,
        () async => during = await r.marker.read(),
      ),
      sender: r.sender,
      marker: r.marker,
      localErasers: <DataEraser>[r.first],
    );
    expect(await d.run(), DeletionOutcome.done);
    expect(during, DeletionPhase.requested);
  });

  group('Backend-Fehler', () {
    test('sicher nicht gelöscht (Netz vor dem Senden): Merkzeichen weg, lokal unberührt', () async {
      final Rig r = Rig();
      r.backend.deleteError = const BackendFailure(FailureKind.unreachable);
      expect(await r.deleter.run(), DeletionOutcome.notDeleted);
      expect(await r.marker.read(), isNull);
      expect(r.log, isEmpty);
      expect(r.backend.calls, <String>['deleteMyData']);
      // Sender läuft wieder an.
      expect(r.sender.isPaused, isFalse);
    });

    test('Server lehnt ab (42501): sicher nicht gelöscht', () async {
      final Rig r = Rig();
      r.backend.deleteError = const BackendFailure(
        FailureKind.rejected,
        sqlState: '42501',
      );
      expect(await r.deleter.run(), DeletionOutcome.notDeleted);
      expect(await r.marker.read(), isNull);
    });

    test(
      '5xx mit Datenbankfehler: Transaktion zurückgerollt = nicht gelöscht',
      () async {
        final Rig r = Rig();
        r.backend.deleteError = const BackendFailure(
          FailureKind.server,
          sqlState: '40P01',
        );
        expect(await r.deleter.run(), DeletionOutcome.notDeleted);
      },
    );

    test('Zeitüberschreitung nach dem Senden: unklar, Merkzeichen bleibt requested', () async {
      final Rig r = Rig();
      r.backend.deleteError = const BackendFailure(FailureKind.timeout);
      expect(await r.deleter.run(), DeletionOutcome.unclear);
      expect(await r.marker.read(), DeletionPhase.requested);
      expect(r.log, isEmpty);
      expect(r.sender.isPaused, isFalse);
    });

    test('5xx ohne Datenbankfehler (z. B. 504): unklar', () async {
      final Rig r = Rig();
      r.backend.deleteError = const BackendFailure(FailureKind.server);
      expect(await r.deleter.run(), DeletionOutcome.unclear);
      expect(await r.marker.read(), DeletionPhase.requested);
    });

    test('Wiederholung nach unklarem Ergebnis ist idempotent', () async {
      final Rig r = Rig();
      r.backend.deleteError = const BackendFailure(FailureKind.timeout);
      expect(await r.deleter.run(), DeletionOutcome.unclear);
      // Der Server hat die Löschung doch abgeschlossen: „bereits gelöscht“.
      r.backend.deleteError = null;
      r.backend.deleteResult = DeleteResult.alreadyDeleted;
      expect(await r.deleter.run(), DeletionOutcome.done);
      expect(await r.marker.read(), isNull);
      expect(r.log.length, 2);
    });
  });

  test('401: Sitzung erneuern, dann löschen', () async {
    final Rig r = Rig();
    int calls = 0;
    final FakePatientBackend backend = r.backend;
    backend.deleteError = const BackendFailure(FailureKind.auth);
    // Nach der Erneuerung gelingt der Aufruf.
    final RefreshHook hook = RefreshHook(backend, () => calls++);
    final AccountDeleter d = AccountDeleter(
      backend: hook,
      sender: r.sender,
      marker: r.marker,
      localErasers: <DataEraser>[r.first],
    );
    expect(await d.run(), DeletionOutcome.done);
    expect(calls, 1);
  });

  test('Sitzungserneuerung scheitert, weil das Konto weg ist: bereits gelöscht = Erfolg', () async {
    final Rig r = Rig();
    r.backend.deleteError = const BackendFailure(FailureKind.auth);
    r.backend.refreshResult = SessionRefresh.accountGone;
    expect(await r.deleter.run(), DeletionOutcome.done);
    expect(r.log.length, 2);
    expect(await r.marker.read(), isNull);
  });

  test('401 und Erneuerung nicht möglich: nicht gelöscht (Anfrage wurde abgelehnt)', () async {
    final Rig r = Rig();
    r.backend.deleteError = const BackendFailure(FailureKind.auth);
    r.backend.refreshResult = SessionRefresh.unavailable;
    expect(await r.deleter.run(), DeletionOutcome.notDeleted);
  });

  group('Lokaler Fehler nach erfolgreicher Backend-Löschung', () {
    test('localFailure; Merkzeichen backendDeleted bleibt; Wiederholung setzt lokal fort', () async {
      final Rig r = Rig();
      r.second.fail = true;
      expect(await r.deleter.run(), DeletionOutcome.localFailure);
      expect(await r.marker.read(), DeletionPhase.backendDeleted);
      expect(
        r.backend.calls.where((String c) => c == 'deleteMyData').length,
        1,
      );

      r.second.fail = false;
      r.log.clear();
      expect(await r.deleter.run(), DeletionOutcome.done);
      // Wiederholung beginnt beim lokalen Aufräumen: kein zweiter Backend-Aufruf.
      expect(
        r.backend.calls.where((String c) => c == 'deleteMyData').length,
        1,
      );
      expect(r.log.length, 2);
      expect(await r.marker.read(), isNull);
    });

    test('erster Löscher scheitert: zweiter wird nicht aufgerufen', () async {
      final Rig r = Rig();
      r.first.fail = true;
      expect(await r.deleter.run(), DeletionOutcome.localFailure);
      expect(r.log, <String>['zustand(marker=true)']);
    });
  });

  group('Wiederaufnahme beim Start', () {
    test('ohne Merkzeichen: nichts', () async {
      final Rig r = Rig();
      expect(await r.deleter.resumeOnStart(), DeletionResume.none);
      expect(r.backend.calls, isEmpty);
    });

    test('backendDeleted: lokales Aufräumen vor allem anderen', () async {
      final Rig r = Rig();
      await r.marker.write(DeletionPhase.backendDeleted);
      expect(await r.deleter.resumeOnStart(), DeletionResume.completed);
      expect(r.log.length, 2);
      expect(await r.marker.read(), isNull);
      expect(r.backend.calls, <String>['signOut']);
    });

    test('backendDeleted, lokaler Fehler: localFailure', () async {
      final Rig r = Rig();
      await r.marker.write(DeletionPhase.backendDeleted);
      r.first.fail = true;
      expect(await r.deleter.resumeOnStart(), DeletionResume.localFailure);
      expect(await r.marker.read(), DeletionPhase.backendDeleted);
    });

    test(
      'requested und Konto existiert nicht mehr: Löschung abschließen',
      () async {
        final Rig r = Rig();
        await r.marker.write(DeletionPhase.requested);
        r.backend.bound = false;
        expect(await r.deleter.resumeOnStart(), DeletionResume.completed);
        expect(await r.marker.read(), isNull);
      },
    );

    test(
      'requested und Konto existiert noch: Entscheidung bleibt beim Aufrufer',
      () async {
        final Rig r = Rig();
        await r.marker.write(DeletionPhase.requested);
        expect(
          await r.deleter.resumeOnStart(),
          DeletionResume.accountStillExists,
        );
        expect(await r.marker.read(), DeletionPhase.requested);
        expect(r.log, isEmpty);
      },
    );

    test('requested und offline: unbekannt, Merkzeichen bleibt', () async {
      final Rig r = Rig();
      await r.marker.write(DeletionPhase.requested);
      final AccountDeleter d = AccountDeleter(
        backend: OfflineBackend(r.backend),
        sender: r.sender,
        marker: r.marker,
        localErasers: const <DataEraser>[],
      );
      expect(await d.resumeOnStart(), DeletionResume.unknown);
      expect(await r.marker.read(), DeletionPhase.requested);
    });
  });

  test('Merkzeichen-Speicher: unbekannter Inhalt gilt als requested', () async {
    final MemoryKeyValueStore kv = MemoryKeyValueStore(<String, String>{
      kDeletionStorageKey: 'irgendwas',
    });
    expect(await StoreDeletionMarkerStore(kv).read(), DeletionPhase.requested);
    expect(
      await StoreDeletionMarkerStore(MemoryKeyValueStore()).read(),
      isNull,
    );
  });

  test(
    'Merkzeichen gehört nicht zu den Schlüsseln des lokalen Zustandslöschers',
    () {
      expect(kAllStorageKeys, contains(kDeletionStorageKey));
      expect(kLocalEraseKeys, isNot(contains(kDeletionStorageKey)));
      expect(
        kLocalEraseKeys,
        containsAll(<String>[
          kStateStorageKey,
          kFrameworkStorageKey,
          kOutboxStorageKey,
        ]),
      );
    },
  );
}

/// Backend, dessen erster `deleteMyData`-Aufruf an einen 401 scheitert; die
/// Erneuerung gelingt, der zweite Aufruf auch.
class RefreshHook extends FakePatientBackendDelegate {
  RefreshHook(super.inner, this.onRefresh);

  final void Function() onRefresh;

  @override
  Future<SessionRefresh> refreshSession() async {
    onRefresh();
    inner.deleteError = null;
    return SessionRefresh.refreshed;
  }
}

class OfflineBackend extends FakePatientBackendDelegate {
  OfflineBackend(super.inner);

  @override
  Future<AccountInfo> fetchAccount() =>
      throw const BackendFailure(FailureKind.unreachable);
}

class DeleteProbe extends FakePatientBackendDelegate {
  DeleteProbe(super.inner, this.probe);

  final Future<void> Function() probe;

  @override
  Future<DeleteResult> deleteMyData() async {
    await probe();
    return super.deleteMyData();
  }
}
