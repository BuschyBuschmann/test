// OutboxSender (Plan 8.11, 8.10): FIFO, Fehlerklassen, 40P01, Zurückstellen
// (Fixture h), 401, Bindung gelöst, pauseAndDrain, Speichern/Laden. Ohne Netz.
import 'dart:async';

import 'package:curaone/backend/outbox_sender.dart';
import 'package:curaone/data/key_value_store.dart';
import 'package:curaone/data/outbox_store.dart';
import 'package:curaone/data/state_store.dart';
import 'package:curaone/dev/fake_backend.dart';
import 'package:curaone/logic/account.dart';
import 'package:curaone/logic/backend_failure.dart';
import 'package:curaone/logic/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/local_day_fixtures.dart';

final DateTime _now = DateTime.utc(2026, 7, 13, 9);

OutboxEntry look(String id, {String value = 'ohne'}) =>
    mannyLookSetEntry(entryId: id, now: _now, look: value);

OutboxEntry checkup(String id, String day, {String checkupId = ''}) =>
    dailyCheckupEntry(
      entryId: id,
      now: _now,
      checkupId: checkupId.isEmpty ? 'c-$id' : checkupId,
      localDay: day,
      pain: 2,
      wellbeing: 4,
      motivation: 4,
      swelling: 0,
      limitations: 'none',
      mood: 4,
    );

const BackendFailure netFail = BackendFailure(FailureKind.unreachable);
const BackendFailure deadlock = BackendFailure(
  FailureKind.server,
  sqlState: '40P01',
  message: 'deadlock detected',
);
const BackendFailure forbidden = BackendFailure(
  FailureKind.rejected,
  sqlState: '42501',
  message: 'not_allowed',
);
const BackendFailure duplicate = BackendFailure(
  FailureKind.rejected,
  sqlState: '23505',
);
const BackendFailure expired = BackendFailure(FailureKind.auth);

class Rig {
  Rig({
    DateTime? serverNow,
    FakePatientBackend? backend,
    MemoryKeyValueStore? kv,
  }) : kv = kv ?? MemoryKeyValueStore(),
       backend =
           backend ??
           FakePatientBackend(
             boundAt: DateTime.utc(2026, 7, 1, 8),
             serverNow: () => serverNow ?? DateTime.utc(2026, 7, 13, 12),
           ) {
    store = StoreOutboxStore(this.kv);
    sender = OutboxSender(
      store: store,
      backend: this.backend,
      onBindingLost: () => bindingLost++,
      onUnreadable: (int n) => unreadable += n,
    );
  }

  final MemoryKeyValueStore kv;
  final FakePatientBackend backend;
  late final StoreOutboxStore store;
  late final OutboxSender sender;
  int bindingLost = 0;
  int unreadable = 0;
}

void main() {
  test(
    'sendet in Einfügereihenfolge und entfernt gesendete Einträge',
    () async {
      final Rig r = Rig();
      for (final String id in <String>['a', 'b', 'c']) {
        await r.sender.enqueue(look(id, value: id == 'b' ? 'brille' : 'ohne'));
      }
      final DrainReport rep = await r.sender.drain();
      expect(rep.stop, DrainStop.idle);
      expect(rep.sent, 3);
      expect(r.backend.sent.map((OutboxEntry e) => e.id), <String>[
        'a',
        'b',
        'c',
      ]);
      expect(r.sender.outbox.isEmpty, isTrue);
      // Gespeichert: leere Warteschlange entfernt den Schlüssel.
      expect(r.kv.values.containsKey(kOutboxStorageKey), isFalse);
    },
  );

  test(
    'Einträge sind nach dem Einreihen gespeichert und überleben den Neustart',
    () async {
      final Rig r = Rig();
      await r.sender.enqueue(look('a'));
      await r.sender.enqueue(look('b'));
      expect(r.kv.values[kOutboxStorageKey], isNotNull);

      final Rig again = Rig(kv: r.kv, backend: r.backend);
      await again.sender.load();
      expect(again.sender.outbox.entries.map((OutboxEntry e) => e.id), <String>[
        'a',
        'b',
      ]);
      await again.sender.drain();
      expect(r.backend.sent.map((OutboxEntry e) => e.id), <String>['a', 'b']);
    },
  );

  group('Fehlerklassen', () {
    test(
      'Netzfehler: Eintrag bleibt, Runde endet, Reihenfolge erhalten',
      () async {
        final Rig r = Rig();
        await r.sender.enqueue(look('a'));
        await r.sender.enqueue(look('b'));
        r.backend.scriptedFailures.add(netFail);
        final DrainReport rep = await r.sender.drain();
        expect(rep.stop, DrainStop.retryLater);
        expect(rep.retryAfter, backoffFor(1));
        expect(r.backend.sent, isEmpty);
        expect(r.sender.outbox.entries.map((OutboxEntry e) => e.id), <String>[
          'a',
          'b',
        ]);
        expect(r.sender.outbox.entries.first.attempts, 1);
        // „b“ wurde nicht vor „a“ versucht.
        expect(
          r.backend.calls.where((String c) => c.startsWith('send')).length,
          1,
        );

        final DrainReport again = await r.sender.drain();
        expect(again.stop, DrainStop.idle);
        expect(r.backend.sent.map((OutboxEntry e) => e.id), <String>['a', 'b']);
      },
    );

    test('Wartezeit steigt mit den Versuchen', () async {
      final Rig r = Rig();
      await r.sender.enqueue(look('a'));
      r.backend.scriptedFailures.addAll(<Object?>[netFail, netFail, netFail]);
      final List<Duration?> waits = <Duration?>[
        (await r.sender.drain()).retryAfter,
        (await r.sender.drain()).retryAfter,
        (await r.sender.drain()).retryAfter,
      ];
      expect(waits, <Duration>[backoffFor(1), backoffFor(2), backoffFor(3)]);
      expect(r.sender.outbox.entries.single.attempts, 3);
    });

    test('40P01 (Deadlock) wird wiederholt, nicht verworfen', () async {
      final Rig r = Rig();
      await r.sender.enqueue(look('a'));
      r.backend.scriptedFailures.add(deadlock);
      final DrainReport first = await r.sender.drain();
      expect(first.stop, DrainStop.retryLater);
      expect(first.discarded, 0);
      expect(r.sender.outbox.length, 1);
      final DrainReport second = await r.sender.drain();
      expect(second.sent, 1);
      expect(r.sender.outbox.isEmpty, isTrue);
    });

    test('23505 zählt als Erfolg', () async {
      final Rig r = Rig();
      await r.sender.enqueue(look('a'));
      await r.sender.enqueue(look('b'));
      r.backend.scriptedFailures.add(duplicate);
      final DrainReport rep = await r.sender.drain();
      expect(rep.sent, 2);
      expect(rep.discarded, 0);
      expect(r.sender.outbox.isEmpty, isTrue);
    });

    test('42501 wird verworfen und blockiert die folgenden nicht', () async {
      final Rig r = Rig();
      await r.sender.enqueue(look('a'));
      await r.sender.enqueue(look('b'));
      r.backend.scriptedFailures.add(forbidden);
      final DrainReport rep = await r.sender.drain();
      expect(rep.discarded, 1);
      expect(rep.sent, 1);
      expect(r.backend.sent.single.id, 'b');
      expect(r.sender.outbox.isEmpty, isTrue);
    });

    test('unbekannter Fehler (kein BackendFailure): nichts verwerfen, später erneut', () async {
      final Rig r = Rig();
      await r.sender.enqueue(look('a'));
      r.backend.scriptedFailures.add(StateError('Programmfehler'));
      final DrainReport rep = await r.sender.drain();
      expect(rep.stop, DrainStop.retryLater);
      expect(r.sender.outbox.length, 1);
      expect(
        r.sender.outbox.entries.single.lastError,
        contains('Programmfehler'),
      );
    });
  });

  group('401', () {
    test('erst Sitzung erneuern, dann derselbe Eintrag erneut', () async {
      final Rig r = Rig();
      await r.sender.enqueue(look('a'));
      r.backend.scriptedFailures.add(expired);
      final DrainReport rep = await r.sender.drain();
      expect(rep.sent, 1);
      expect(r.backend.calls, <String>[
        'send:manny_look_set',
        'refreshSession',
        'send:manny_look_set',
      ]);
    });

    test(
      'Erneuerung scheitert, weil das Konto weg ist → Bindung gelöst',
      () async {
        final Rig r = Rig();
        r.backend.refreshResult = SessionRefresh.accountGone;
        await r.sender.enqueue(look('a'));
        r.backend.scriptedFailures.add(expired);
        final DrainReport rep = await r.sender.drain();
        expect(rep.stop, DrainStop.bindingLost);
        expect(r.bindingLost, 1);
        expect(r.sender.outbox.length, 1); // nichts still verworfen
      },
    );

    test('Erneuerung nicht möglich → später erneut', () async {
      final Rig r = Rig();
      r.backend.refreshResult = SessionRefresh.unavailable;
      await r.sender.enqueue(look('a'));
      r.backend.scriptedFailures.add(expired);
      final DrainReport rep = await r.sender.drain();
      expect(rep.stop, DrainStop.retryLater);
      expect(r.bindingLost, 0);
      expect(r.sender.outbox.length, 1);
    });

    test(
      'BindingLostException aus dem Backend meldet die gelöste Bindung',
      () async {
        final Rig r = Rig();
        await r.sender.enqueue(look('a'));
        r.backend.scriptedFailures.add(const BindingLostException('x'));
        expect((await r.sender.drain()).stop, DrainStop.bindingLost);
        expect(r.bindingLost, 1);
      },
    );
  });

  group('invalid_local_day: zurückgestellt (Plan 6.7 Nr. 3, Fixture h)', () {
    final Map<String, dynamic> h = readLocalDayFixture('h_late_checkup.json');
    final DateTime boundAt = DateTime.parse(h['bound_at'] as String);
    final List<dynamic> cases = h['cases'] as List<dynamic>;
    final Map<String, dynamic> late = cases[0] as Map<String, dynamic>;
    final Map<String, dynamic> early = cases[1] as Map<String, dynamic>;
    final DateTime sentAt = DateTime.parse(late['sent_at'] as String);

    test('Check-up 3 Tage verspätet wird angenommen', () async {
      final Rig r = Rig(
        backend: FakePatientBackend(boundAt: boundAt, serverNow: () => sentAt),
      );
      expect(late['expect'], 'accepted');
      await r.sender.enqueue(checkup('a', late['local_day'] as String));
      final DrainReport rep = await r.sender.drain();
      expect(rep.sent, 1);
      expect(rep.deferred, 0);
      expect(r.backend.dailyCheckups.length, 1);
      expect(r.sender.outbox.isEmpty, isTrue);
    });

    test('Tag vor Bindungstag − 1: zurückgestellt statt verworfen', () async {
      final Rig r = Rig(
        backend: FakePatientBackend(boundAt: boundAt, serverNow: () => sentAt),
      );
      expect(early['expect'], 'invalid_local_day');
      expect(early['app'], 'deferred');
      await r.sender.enqueue(checkup('a', early['local_day'] as String));
      await r.sender.enqueue(look('b'));
      final DrainReport rep = await r.sender.drain();
      expect(rep.deferred, 1);
      expect(rep.discarded, 0);
      // Blockiert den folgenden Eintrag nicht.
      expect(rep.sent, 1);
      expect(r.backend.sent.single.id, 'b');
      // Bleibt gespeichert, als zurückgestellt gekennzeichnet (NIT-2).
      expect(r.sender.outbox.length, 1);
      final OutboxEntry e = r.sender.outbox.entries.single;
      expect(e.id, 'a');
      expect(e.deferred, isTrue);
      expect(e.attempts, 1);
      expect(r.sender.deferredCount, 1);
      expect(r.kv.values[kOutboxStorageKey], contains('"deferred":true'));
    });

    test(
      'wird nur bei Start/neuer Verbindung erneut versucht (retryDeferred)',
      () async {
        final Rig r = Rig(
          backend: FakePatientBackend(
            boundAt: boundAt,
            serverNow: () => sentAt,
          ),
        );
        await r.sender.enqueue(checkup('a', early['local_day'] as String));
        await r.sender.drain();
        final int sendsBefore = r.backend.calls
            .where((String c) => c.startsWith('send'))
            .length;

        await r.sender.drain(); // normale Runde: kein neuer Versuch
        expect(
          r.backend.calls.where((String c) => c.startsWith('send')).length,
          sendsBefore,
        );

        final DrainReport retry = await r.sender.drain(retryDeferred: true);
        expect(retry.deferred, 1); // weiterhin ungültig, bleibt zurückgestellt
        expect(r.sender.outbox.entries.single.attempts, 2);
        expect(r.sender.deferredCount, 1);
      },
    );

    test('geht durch, sobald der Server den Tag annimmt (z. B. Geräteuhr korrigiert)', () async {
      DateTime serverNow = sentAt;
      final FakePatientBackend backend = FakePatientBackend(
        boundAt: boundAt,
        serverNow: () => serverNow,
      );
      final Rig r = Rig(backend: backend);
      await r.sender.enqueue(checkup('a', early['local_day'] as String));
      await r.sender.drain();
      expect(r.sender.deferredCount, 1);
      // Bindung rückdatiert: der Tag liegt jetzt im erlaubten Bereich.
      backend.boundAt = DateTime.utc(2026, 6, 20);
      final DrainReport retry = await r.sender.drain(retryDeferred: true);
      expect(retry.sent, 1);
      expect(r.sender.outbox.isEmpty, isTrue);
    });

    test('„Alles löschen“ entfernt zurückgestellte Einträge', () async {
      final Rig r = Rig(
        backend: FakePatientBackend(boundAt: boundAt, serverNow: () => sentAt),
      );
      await r.sender.enqueue(checkup('a', early['local_day'] as String));
      await r.sender.drain();
      await r.sender.discardAll();
      expect(r.sender.outbox.isEmpty, isTrue);
      expect(r.sender.deferredCount, 0);
      expect(r.kv.values.containsKey(kOutboxStorageKey), isFalse);
    });

    test('zweiter Check-up am selben Tag mit anderer ID: already_submitted = Erfolg', () async {
      final Rig r = Rig(
        backend: FakePatientBackend(boundAt: boundAt, serverNow: () => sentAt),
      );
      await r.sender.enqueue(checkup('a', '2026-07-10', checkupId: 'one'));
      await r.sender.enqueue(checkup('b', '2026-07-10', checkupId: 'two'));
      final DrainReport rep = await r.sender.drain();
      expect(rep.sent, 2);
      expect(rep.discarded, 0);
      expect(r.sender.outbox.isEmpty, isTrue);
    });
  });

  group('Abhängigkeiten in der Reihenfolge', () {
    test('Ergebnis nach Session: gelingt nur in Einfügereihenfolge', () async {
      final Rig r = Rig();
      await r.sender.enqueue(
        trainingSessionEntry(
          entryId: 'e1',
          now: _now,
          sessionId: 's1',
          patientId: 'p',
          planId: 'pl',
          localDay: '2026-07-13',
          mode: 'checklist',
        ),
      );
      await r.sender.enqueue(
        exerciseResultInsertEntry(
          entryId: 'e2',
          now: _now,
          resultId: 'r1',
          patientId: 'p',
          trainingSessionId: 's1',
          localDay: '2026-07-13',
          status: 'done',
        ),
      );
      // Netzfehler bei der Session: das Ergebnis darf nicht vorgezogen werden
      // (es würde am Fremdschlüssel scheitern und verworfen).
      r.backend.scriptedFailures.add(netFail);
      await r.sender.drain();
      expect(
        r.backend.calls.where((String c) => c.startsWith('send')).length,
        1,
      );
      await r.sender.drain();
      expect(r.backend.sessionIds, contains('s1'));
      expect(r.backend.resultIds, contains('r1'));
      expect(r.sender.outbox.isEmpty, isTrue);
    });
  });

  group('pauseAndDrain (Plan 8.10)', () {
    test(
      'ohne laufende Anfrage sofort bereit; danach startet nichts Neues',
      () async {
        final Rig r = Rig();
        expect(await r.sender.pauseAndDrain(), isTrue);
        expect(r.sender.isPaused, isTrue);
        await r.sender.enqueue(look('a'));
        final DrainReport rep = await r.sender.drain();
        expect(rep.stop, DrainStop.paused);
        expect(r.backend.sent, isEmpty);
        r.sender.resume();
        expect((await r.sender.drain()).sent, 1);
      },
    );

    test('wartet auf die laufende Anfrage', () async {
      final Rig r = Rig();
      final Completer<void> gate = Completer<void>();
      r.backend.onSend = (OutboxEntry e) => gate.future;
      await r.sender.enqueue(look('a'));
      await r.sender.enqueue(look('b'));
      final Future<DrainReport> run = r.sender.drain();
      await Future<void>.delayed(Duration.zero);
      bool done = false;
      final Future<bool> paused = r.sender.pauseAndDrain().then((bool v) {
        done = true;
        return v;
      });
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse); // Anfrage läuft noch
      gate.complete();
      expect(await paused, isTrue);
      final DrainReport rep = await run;
      expect(rep.stop, DrainStop.paused);
      // Die laufende Anfrage wurde abgeschlossen, „b“ nicht mehr gestartet.
      expect(r.backend.sent.map((OutboxEntry e) => e.id), <String>['a']);
      expect(r.sender.outbox.entries.map((OutboxEntry e) => e.id), <String>[
        'b',
      ]);
    });

    test('Zeitlimit: false, die Anfrage gilt als unklar', () async {
      final Rig r = Rig();
      final Completer<void> never = Completer<void>();
      r.backend.onSend = (OutboxEntry e) => never.future;
      await r.sender.enqueue(look('a'));
      unawaited(r.sender.drain());
      await Future<void>.delayed(Duration.zero);
      expect(
        await r.sender.pauseAndDrain(timeout: const Duration(milliseconds: 20)),
        isFalse,
      );
    });
  });

  test('parallele drain-Aufrufe teilen sich eine Runde', () async {
    final Rig r = Rig();
    await r.sender.enqueue(look('a'));
    final Future<DrainReport> a = r.sender.drain();
    final Future<DrainReport> b = r.sender.drain();
    await Future.wait(<Future<DrainReport>>[a, b]);
    expect(r.backend.sent.length, 1);
  });

  test('Eintrag während der laufenden Runde wird noch gesendet', () async {
    final Rig r = Rig();
    final Completer<void> gate = Completer<void>();
    r.backend.onSend = (OutboxEntry e) async {
      if (e.id == 'a') await gate.future;
    };
    await r.sender.enqueue(look('a'));
    final Future<DrainReport> run = r.sender.drain();
    await Future<void>.delayed(Duration.zero);
    await r.sender.enqueue(look('b'));
    unawaited(r.sender.drain());
    gate.complete();
    await run;
    await Future<void>.delayed(Duration.zero);
    expect(r.backend.sent.map((OutboxEntry e) => e.id), <String>['a', 'b']);
  });

  test('Änderungen werden gemeldet', () async {
    final Rig r = Rig();
    final List<int> lengths = <int>[];
    final StreamSubscription<Outbox> sub = r.sender.changes.listen(
      (Outbox o) => lengths.add(o.length),
    );
    await r.sender.enqueue(look('a'));
    await r.sender.drain();
    await Future<void>.delayed(Duration.zero);
    expect(lengths, <int>[1, 0]);
    await sub.cancel();
  });

  test(
    'unlesbare gespeicherte Einträge werden gemeldet und übersprungen',
    () async {
      final MemoryKeyValueStore kv = MemoryKeyValueStore(<String, String>{
        kOutboxStorageKey:
            '{"schema":1,"entries":[{"id":"x","kind":"nix","payload":{}},'
            '{"id":"a","kind":"manny_look_set","payload":{"look":"ohne"},"createdAt":"2026-07-13T09:00:00Z"}]}',
      });
      final Rig r = Rig(kv: kv);
      await r.sender.load();
      expect(r.unreadable, 1);
      expect(r.sender.outbox.entries.single.id, 'a');
    },
  );
}
