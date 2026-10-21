// Ausgangswarteschlange, reine Logik (Plan 8.11): Reihenfolge, Fehlerklassen
// (40P01 wiederholbar), Zurückstellen, Dokument, Nutzlasten.
import 'dart:convert';

import 'package:curaone/logic/backend_failure.dart';
import 'package:curaone/logic/json_support.dart';
import 'package:curaone/logic/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime.utc(2026, 10, 7, 10);

OutboxEntry entry(String id, {OutboxKind kind = OutboxKind.mannyLookSet}) =>
    OutboxEntry(
      id: id,
      kind: kind,
      payload: <String, Object?>{'look': 'ohne'},
      createdAt: _now,
    );

BackendFailure failure(
  FailureKind kind, {
  String? sqlState,
  String message = '',
}) => BackendFailure(kind, sqlState: sqlState, message: message);

void main() {
  group('Fehlerklassen (Plan 8.11)', () {
    OutboxVerdict v(
      BackendFailure f, [
      OutboxKind k = OutboxKind.mannyLookSet,
    ]) => classifyFailure(k, f);

    test('Netz, Zeitüberschreitung, 5xx: später erneut', () {
      expect(v(failure(FailureKind.unreachable)), OutboxVerdict.retryLater);
      expect(v(failure(FailureKind.timeout)), OutboxVerdict.retryLater);
      expect(v(failure(FailureKind.server)), OutboxVerdict.retryLater);
    });

    test('40001 und 40P01 (Deadlock) sind wiederholbar', () {
      for (final String state in <String>['40001', '40P01']) {
        expect(
          v(failure(FailureKind.rejected, sqlState: state)),
          OutboxVerdict.retryLater,
          reason: state,
        );
        expect(
          v(failure(FailureKind.server, sqlState: state)),
          OutboxVerdict.retryLater,
          reason: state,
        );
      }
      expect(kRetryableSqlStates, containsAll(<String>['40001', '40P01']));
    });

    test('401: erst Sitzung erneuern', () {
      expect(v(failure(FailureKind.auth)), OutboxVerdict.refreshSession);
    });

    test('23505 (existiert schon) ist Erfolg, auch bei 4xx', () {
      expect(
        v(failure(FailureKind.rejected, sqlState: '23505')),
        OutboxVerdict.success,
      );
    });

    test('42501 und andere 4xx sind dauerhaft', () {
      expect(
        v(failure(FailureKind.rejected, sqlState: '42501')),
        OutboxVerdict.discard,
      );
      expect(v(failure(FailureKind.rejected)), OutboxVerdict.discard);
      expect(
        v(failure(FailureKind.rejected, sqlState: '23503')),
        OutboxVerdict.discard,
      );
    });

    test('already_submitted beim Tages-Check-up ist Erfolg, sonst nicht', () {
      final BackendFailure f = failure(
        FailureKind.rejected,
        sqlState: 'P0001',
        message: 'already_submitted',
      );
      expect(v(f, OutboxKind.dailyCheckupSubmit), OutboxVerdict.success);
      expect(v(f, OutboxKind.questionSubmit), OutboxVerdict.discard);
    });

    test('invalid_local_day wird zurückgestellt, nie verworfen', () {
      for (final OutboxKind k in OutboxKind.values) {
        expect(
          v(
            failure(
              FailureKind.rejected,
              sqlState: '22023',
              message: 'invalid_local_day',
            ),
            k,
          ),
          OutboxVerdict.defer,
          reason: k.wire,
        );
      }
      // Anderes 22023 ist dauerhaft.
      expect(
        v(
          failure(
            FailureKind.rejected,
            sqlState: '22023',
            message: 'invalid_payload',
          ),
        ),
        OutboxVerdict.discard,
      );
    });
  });

  test('Wartezeit steigt und ist begrenzt', () {
    final List<Duration> d = <Duration>[
      for (int i = 1; i <= 12; i++) backoffFor(i),
    ];
    for (int i = 1; i < d.length; i++) {
      expect(d[i] >= d[i - 1], isTrue);
    }
    expect(d.first, const Duration(seconds: 2));
    expect(d.last, const Duration(minutes: 5));
    expect(backoffFor(0), backoffFor(1));
  });

  group('Outbox (FIFO)', () {
    test('Einfügereihenfolge bleibt erhalten', () {
      Outbox o = Outbox();
      for (final String id in <String>['a', 'b', 'c']) {
        o = o.enqueue(entry(id));
      }
      expect(o.entries.map((OutboxEntry e) => e.id), <String>['a', 'b', 'c']);
      expect(o.next()!.id, 'a');
      expect(o.remove('a').next()!.id, 'b');
      expect(o.next(skip: <String>{'a', 'b'})!.id, 'c');
      expect(o.next(skip: <String>{'a', 'b', 'c'}), isNull);
    });

    test(
      'zurückgestellte Einträge blockieren nicht und werden übersprungen',
      () {
        Outbox o = Outbox(<OutboxEntry>[
          entry('a').copyWith(deferred: true),
          entry('b'),
        ]);
        expect(o.next()!.id, 'b');
        expect(o.next(includeDeferred: true)!.id, 'a');
        expect(o.deferred.map((OutboxEntry e) => e.id), <String>['a']);
        expect(o.pendingCount, 1);
        o = o.replace(entry('a'));
        expect(o.deferred, isEmpty);
      },
    );

    test('byId, replace, remove', () {
      final Outbox o = Outbox(<OutboxEntry>[entry('a'), entry('b')]);
      expect(o.byId('b')!.id, 'b');
      expect(o.byId('z'), isNull);
      expect(
        o.replace(entry('b').copyWith(attempts: 3)).byId('b')!.attempts,
        3,
      );
      expect(o.remove('z').length, 2);
    });
  });

  group('Dokument', () {
    test('Roundtrip mit allen Feldern', () {
      final Outbox o = Outbox(<OutboxEntry>[
        entry(
          'a',
          kind: OutboxKind.dailyCheckupSubmit,
        ).copyWith(attempts: 2, deferred: true, lastError: 'invalid_local_day'),
        entry('b'),
      ]);
      final String raw = jsonEncode(o.toJson());
      final ({Outbox outbox, int skipped}) back = decodeOutbox(jsonDecode(raw));
      expect(back.skipped, 0);
      expect(jsonEncode(back.outbox.toJson()), raw);
      expect(back.outbox.entries.first.deferred, isTrue);
      expect(back.outbox.entries.first.attempts, 2);
    });

    test(
      'einzelne unlesbare Einträge werden übersprungen, der Rest bleibt',
      () {
        final ({Outbox outbox, int skipped}) r = decodeOutbox(<String, Object?>{
          'schema': 1,
          'entries': <Object?>[
            entry('a').toJson(),
            <String, Object?>{
              'id': 'x',
              'kind': 'gibt_es_nicht',
              'payload': <String, Object?>{},
            },
            'kaputt',
            entry('b').toJson(),
          ],
        });
        expect(r.outbox.entries.map((OutboxEntry e) => e.id), <String>[
          'a',
          'b',
        ]);
        expect(r.skipped, 2);
      },
    );

    test('Gesamtdokument unbrauchbar → unlesbar', () {
      expect(() => decodeOutbox('x'), throwsA(isA<UnreadableDataException>()));
      expect(
        () => decodeOutbox(<String, Object?>{'entries': 5}),
        throwsA(isA<UnreadableDataException>()),
      );
      expect(decodeOutbox(<String, Object?>{}).outbox.isEmpty, isTrue);
    });

    test('alle Arten haben einen eindeutigen wire-Namen', () {
      final Set<String> names = <String>{
        for (final OutboxKind k in OutboxKind.values) k.wire,
      };
      expect(names.length, OutboxKind.values.length);
      expect(names, contains('manny_look_set'));
      for (final OutboxKind k in OutboxKind.values) {
        expect(OutboxKind.fromWire(k.wire), k);
      }
      expect(OutboxKind.fromWire('x'), isNull);
    });
  });

  group('Nutzlasten je Art', () {
    test('manny_look_set', () {
      final OutboxEntry e = mannyLookSetEntry(
        entryId: 'e',
        now: _now,
        look: 'ohne',
      );
      expect(e.kind, OutboxKind.mannyLookSet);
      expect(e.payload, <String, Object?>{'look': 'ohne'});
    });

    test('training_session_upsert: Spalten der Tabelle, Tag als Text', () {
      final OutboxEntry e = trainingSessionEntry(
        entryId: 'e',
        now: _now,
        sessionId: 's',
        patientId: 'p',
        planId: 'pl',
        localDay: '2026-10-07',
        mode: 'checklist',
        startedAt: _now,
      );
      expect(
        e.payload.keys,
        containsAll(<String>[
          'id',
          'patient_id',
          'plan_id',
          'local_day',
          'mode',
          'items',
          'started_at',
          'ended_at',
          'active_seconds',
          'ended_early',
          'streak_after',
        ]),
      );
      expect(e.payload['local_day'], '2026-10-07');
      expect(e.payload['started_at'], '2026-10-07T10:00:00.000Z');
      expect(e.payload['ended_at'], isNull);
    });

    test('exercise_result_insert und -delete', () {
      final OutboxEntry i = exerciseResultInsertEntry(
        entryId: 'e',
        now: _now,
        resultId: 'r',
        patientId: 'p',
        trainingSessionId: 's',
        localDay: '2026-10-07',
        status: 'done',
        exerciseName: 'Brücke',
      );
      expect(i.payload['status'], 'done');
      expect(i.payload['training_session_id'], 's');
      expect(i.payload['logged_at'], isNotNull);
      final OutboxEntry d = exerciseResultDeleteEntry(
        entryId: 'e2',
        now: _now,
        resultId: 'r',
      );
      expect(d.payload, <String, Object?>{'id': 'r'});
    });

    test('daily_checkup_submit, session_checkup_submit, question_submit', () {
      final OutboxEntry d = dailyCheckupEntry(
        entryId: 'e',
        now: _now,
        checkupId: 'c',
        localDay: '2026-10-07',
        pain: 3,
        wellbeing: 4,
        motivation: 4,
        swelling: 0,
        limitations: 'none',
        mood: 4,
      );
      expect(d.kind, OutboxKind.dailyCheckupSubmit);
      expect(d.payload['limitations'], 'none');
      final OutboxEntry s = sessionCheckupEntry(
        entryId: 'e',
        now: _now,
        checkupId: 'c',
        trainingSessionId: 's',
        localDay: '2026-10-07',
        rating: 4,
      );
      expect(s.payload['items'], isEmpty);
      final OutboxEntry q = questionEntry(
        entryId: 'e',
        now: _now,
        questionId: 'q',
        text: 'Darf ich?',
      );
      expect(q.payload['text'], 'Darf ich?');
    });

    test('appointment_upsert und -delete', () {
      final OutboxEntry u = appointmentUpsertEntry(
        entryId: 'e',
        now: _now,
        appointmentId: 'a',
        patientId: 'p',
        startsAt: DateTime.utc(2026, 11, 1, 9),
        title: 'Kontrolle',
      );
      expect(u.payload['starts_at'], '2026-11-01T09:00:00.000Z');
      expect(u.payload['treater_id'], isNull);
      expect(
        appointmentDeleteEntry(
          entryId: 'e',
          now: _now,
          appointmentId: 'a',
        ).payload['id'],
        'a',
      );
    });

    test('Einträge werden in UTC gestempelt', () {
      final OutboxEntry e = mannyLookSetEntry(
        entryId: 'e',
        now: DateTime(2026, 10, 7, 12),
        look: 'brille',
      );
      expect(e.createdAt.isUtc, isTrue);
    });
  });
}
