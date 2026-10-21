// Abhaken, Rückgängig, Termine über die Warteschlange (Plan 8.4, 8.9).
import 'package:curaone/backend/outbox_sender.dart';
import 'package:curaone/data/key_value_store.dart';
import 'package:curaone/data/outbox_store.dart';
import 'package:curaone/data/record_repository.dart';
import 'package:curaone/dev/fake_backend.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/framework.dart';
import 'package:curaone/logic/ids.dart';
import 'package:curaone/logic/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curaone/logic/backend_failure.dart';

import '../support/fake_clock.dart';
import '../support/framework_builders.dart';

const LocalDay day = LocalDay(2026, 10, 7);

class Rig {
  Rig() {
    sender = OutboxSender(store: StoreOutboxStore(kv), backend: backend);
    repo = RecordRepository(
      sender: sender,
      clock: FakeClock(DateTime.utc(2026, 10, 7, 9)).call,
      patientId: kPatientId,
      newId: () => newUuid(),
    );
  }

  final MemoryKeyValueStore kv = MemoryKeyValueStore();
  final FakePatientBackend backend = FakePatientBackend();
  late final OutboxSender sender;
  late final RecordRepository repo;
  final Framework framework = sampleFramework();

  Plan get plan => framework.plan!;
  PlanItem get a => plan.itemById('a')!;
  PlanItem get b => plan.itemById('b')!;

  Future<String> done(PlanItem item) => repo.markDone(
    plan: plan,
    item: item,
    exercise: framework.exerciseById(item.exerciseId),
    localDay: day,
    todayItems: <PlanItem>[a, b],
    framework: framework,
  );
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'Abhaken legt Session (checklist) und Ergebnis an, Session zuerst',
    () async {
      final Rig r = Rig();
      final String resultId = await r.done(r.a);
      await settle();
      await r.sender.drain();
      expect(r.backend.sent.map((OutboxEntry e) => e.kind), <OutboxKind>[
        OutboxKind.trainingSessionUpsert,
        OutboxKind.exerciseResultInsert,
      ]);
      final OutboxEntry session = r.backend.sent.first;
      expect(session.payload['mode'], 'checklist');
      expect(session.payload['local_day'], '2026-10-07');
      expect(session.payload['patient_id'], kPatientId);
      expect(session.payload['plan_id'], 'plan-1');
      expect(session.payload['plan_version'], 1);
      expect(session.payload['phase_id'], 'ph1');
      final List<Object?> items = session.payload['items']! as List<Object?>;
      expect(items.length, 2);
      expect((items.first! as Map<String, Object?>)['name'], 'Übung a');
      final OutboxEntry result = r.backend.sent.last;
      expect(result.payload['id'], resultId);
      expect(result.payload['status'], 'done');
      expect(result.payload['exercise_name'], 'Übung a');
      expect(result.payload['training_session_id'], session.payload['id']);
      expect(r.backend.resultIds, contains(resultId));
    },
  );

  test(
    'weitere Übung am selben Tag: dieselbe Session, nur ein Einfüge-Eintrag',
    () async {
      final Rig r = Rig();
      await r.done(r.a);
      await r.done(r.b);
      await settle();
      await r.sender.drain();
      expect(
        r.backend.sent
            .where(
              (OutboxEntry e) => e.kind == OutboxKind.trainingSessionUpsert,
            )
            .length,
        1,
      );
      expect(r.backend.resultIds.length, 2);
    },
  );

  test(
    'IDs sind gleichbleibend: Session je Tag, Ergebnis je Tag und Position',
    () async {
      final Rig r = Rig();
      expect(r.repo.checklistSessionId(day), r.repo.checklistSessionId(day));
      expect(
        r.repo.checklistSessionId(day),
        isNot(r.repo.checklistSessionId(day.addDays(1))),
      );
      expect(r.repo.resultId(day, 'a'), isNot(r.repo.resultId(day, 'b')));
      expect(isUuid(r.repo.resultId(day, 'a')), isTrue);
      expect(isUuid(r.repo.checklistSessionId(day)), isTrue);
    },
  );

  test('Rückgängig am selben Tag löscht genau dieses Ergebnis', () async {
    final Rig r = Rig();
    final String id = await r.done(r.a);
    await r.done(r.b);
    await settle();
    await r.sender.drain();
    await r.repo.undoDone(item: r.a, localDay: day);
    await settle();
    await r.sender.drain();
    expect(r.backend.resultIds, isNot(contains(id)));
    expect(r.backend.resultIds.length, 1);
  });

  test(
    'Abhaken, Rückgängig und erneutes Abhaken offline bleiben in Reihenfolge',
    () async {
      final Rig r = Rig();
      r.backend.scriptedFailures.add(
        const BackendFailure(FailureKind.unreachable),
      );
      await r.done(r.a);
      await r.repo.undoDone(item: r.a, localDay: day);
      final String again = await r.done(r.a);
      for (int i = 0; i < 3; i++) {
        await settle();
        await r.sender.drain(); // der erste Versuch scheitert am Netz
      }
      expect(r.backend.sent.map((OutboxEntry e) => e.kind), <OutboxKind>[
        OutboxKind.trainingSessionUpsert,
        OutboxKind.exerciseResultInsert,
        OutboxKind.exerciseResultDelete,
        OutboxKind.exerciseResultInsert,
      ]);
      expect(r.backend.resultIds, <String>{again});
      expect(r.sender.outbox.isEmpty, isTrue);
    },
  );

  test('Termine: anlegen, ändern, löschen', () async {
    final Rig r = Rig();
    final String id = await r.repo.saveAppointment(
      startsAt: DateTime.utc(2026, 11, 3, 9, 30),
      title: 'Arzt',
      location: 'Praxis',
    );
    expect(isUuid(id), isTrue);
    final String same = await r.repo.saveAppointment(
      appointmentId: id,
      startsAt: DateTime.utc(2026, 11, 3, 10),
      title: 'Arzt neu',
    );
    expect(same, id);
    await r.repo.deleteAppointment(id);
    await settle();
    await r.sender.drain();
    expect(r.backend.sent.map((OutboxEntry e) => e.kind), <OutboxKind>[
      OutboxKind.appointmentUpsert,
      OutboxKind.appointmentUpsert,
      OutboxKind.appointmentDelete,
    ]);
    expect(r.backend.sent[1].payload['title'], 'Arzt neu');
    expect(r.backend.appointmentIds, isEmpty);
    expect(r.backend.sent.first.payload['patient_id'], kPatientId);
  });
}
