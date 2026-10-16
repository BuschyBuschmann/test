// Framework laden und Zwischenspeicher (Plan 8.2): aktuell, nicht aktuell,
// Fehlerzustand, gelöste Bindung, fremder Zwischenspeicher.
import 'package:curaone/backend/patient_backend.dart';
import 'package:curaone/data/framework_cache.dart';
import 'package:curaone/data/framework_repository.dart';
import 'package:curaone/data/key_value_store.dart';
import 'package:curaone/data/state_store.dart';
import 'package:curaone/dev/fake_backend.dart';
import 'package:curaone/logic/account.dart';
import 'package:curaone/logic/backend_failure.dart';
import 'package:curaone/logic/framework.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_clock.dart';
import '../support/fake_delegate.dart';
import '../support/framework_builders.dart';

class Rig {
  Rig({Framework? framework}) {
    backend = FakePatientBackend(framework: framework ?? sampleFramework());
    cache = StoreFrameworkCache(kv);
    clock = FakeClock(DateTime.utc(2026, 10, 7, 10));
    repo = BackendFrameworkRepository(
      backend: backend,
      cache: cache,
      clock: clock.call,
    );
  }

  final MemoryKeyValueStore kv = MemoryKeyValueStore();
  late final FakePatientBackend backend;
  late final StoreFrameworkCache cache;
  late final FakeClock clock;
  late final BackendFrameworkRepository repo;
}

void main() {
  test('Erfolg: Ergebnis aktuell, Zwischenspeicher geschrieben', () async {
    final Rig r = Rig();
    final FrameworkLoad load = await r.repo.load();
    expect(load.stale, isFalse);
    expect(load.framework.plan!.items.length, 4);
    expect(load.loadedAt, DateTime.utc(2026, 10, 7, 10));
    final CachedFramework? cached = await r.cache.read();
    expect(cached, isNotNull);
    expect(cached!.savedAt, DateTime.utc(2026, 10, 7, 10));
    expect(cached.framework.toJson(), load.framework.toJson());
  });

  test('offline mit Zwischenspeicher: „nicht aktuell“', () async {
    final Rig r = Rig();
    await r.repo.load();
    r.clock.set(DateTime.utc(2026, 10, 8, 10));
    r.backend.fetchFrameworkError = const BackendFailure(
      FailureKind.unreachable,
    );
    final FrameworkLoad load = await r.repo.load();
    expect(load.stale, isTrue);
    expect(load.loadedAt, DateTime.utc(2026, 10, 7, 10)); // Alter des Standes
    expect(load.framework.patient.firstName, 'Lena');
  });

  test('Serverfehler mit Zwischenspeicher: ebenfalls nicht aktuell', () async {
    final Rig r = Rig();
    await r.repo.load();
    r.backend.fetchFrameworkError = const BackendFailure(
      FailureKind.server,
      sqlState: '40P01',
    );
    expect((await r.repo.load()).stale, isTrue);
  });

  test('ohne Zwischenspeicher: Fehlerzustand mit Ursache', () async {
    final Rig r = Rig();
    r.backend.fetchFrameworkError = const BackendFailure(FailureKind.timeout);
    await expectLater(
      r.repo.load(),
      throwsA(
        isA<FrameworkLoadException>().having(
          (FrameworkLoadException e) => e.cause.kind,
          'kind',
          FailureKind.timeout,
        ),
      ),
    );
  });

  test('Wiederholen lädt neu und aktualisiert den Zwischenspeicher', () async {
    final Rig r = Rig();
    r.backend.fetchFrameworkError = const BackendFailure(FailureKind.timeout);
    await expectLater(r.repo.load(), throwsA(isA<FrameworkLoadException>()));
    r.backend.fetchFrameworkError = null;
    expect((await r.repo.load()).stale, isFalse);
    expect(await r.cache.read(), isNotNull);
  });

  test(
    'gelöste Bindung: Ausnahme, Zwischenspeicher nicht als Ersatz',
    () async {
      final Rig r = Rig();
      await r.repo.load();
      r.backend.bound = false;
      await expectLater(r.repo.load(), throwsA(isA<BindingLostException>()));
    },
  );

  test('Status access_deleted gilt als gelöste Bindung', () async {
    final Framework f = sampleFramework();
    final Framework gone = Framework(
      patient: PatientInfo(
        id: f.patient.id,
        firstName: f.patient.firstName,
        status: PatientStatus.accessDeleted,
      ),
      injury: f.injury,
      plan: f.plan,
      exercises: f.exercises,
      treaters: f.treaters,
      appointments: f.appointments,
      history: f.history,
    );
    final Rig r = Rig(framework: gone);
    await expectLater(r.repo.load(), throwsA(isA<BindingLostException>()));
    expect(await r.cache.read(), isNull);
  });

  test('Zwischenspeicher eines anderen Patienten wird nicht gezeigt', () async {
    final Rig r = Rig();
    await r.repo.load();
    r.backend.fetchFrameworkError = const BackendFailure(
      FailureKind.unreachable,
    );
    await expectLater(
      r.repo.load(expectedPatientId: 'ein-anderer'),
      throwsA(isA<FrameworkLoadException>()),
    );
    expect((await r.repo.load(expectedPatientId: kPatientId)).stale, isTrue);
  });

  test('401: Sitzung erneuern und erneut laden', () async {
    final Rig r = Rig();
    r.backend.fetchFrameworkError = const BackendFailure(FailureKind.auth);
    final PatientBackend wrapped = _FixAfterRefresh(r.backend);
    final BackendFrameworkRepository repo = BackendFrameworkRepository(
      backend: wrapped,
      cache: r.cache,
      clock: r.clock.call,
    );
    expect((await repo.load()).stale, isFalse);
    expect(r.backend.calls, contains('refreshSession'));
  });

  test('401 mit weggefallenem Konto: gelöste Bindung', () async {
    final Rig r = Rig();
    r.backend.fetchFrameworkError = const BackendFailure(FailureKind.auth);
    r.backend.refreshResult = SessionRefresh.accountGone;
    await expectLater(r.repo.load(), throwsA(isA<BindingLostException>()));
  });

  group('Zwischenspeicher', () {
    test('unlesbarer Inhalt wird verworfen, nicht gemeldet', () async {
      final MemoryKeyValueStore kv = MemoryKeyValueStore(<String, String>{
        kFrameworkStorageKey: '{kaputt',
      });
      final StoreFrameworkCache cache = StoreFrameworkCache(kv);
      expect(await cache.read(), isNull);
      expect(kv.values.containsKey(kFrameworkStorageKey), isFalse);
    });

    test('falsche Struktur wird verworfen', () async {
      final MemoryKeyValueStore kv = MemoryKeyValueStore(<String, String>{
        kFrameworkStorageKey:
            '{"savedAt":"2026-10-07T10:00:00Z","framework":{"patient":5}}',
      });
      expect(await StoreFrameworkCache(kv).read(), isNull);
      expect(kv.values.containsKey(kFrameworkStorageKey), isFalse);
    });

    test('eraseAll entfernt den Schlüssel; leer ist null', () async {
      final Rig r = Rig();
      expect(await r.cache.read(), isNull);
      await r.repo.load();
      await r.cache.eraseAll();
      expect(r.kv.values.containsKey(kFrameworkStorageKey), isFalse);
    });
  });
}

class _FixAfterRefresh extends FakePatientBackendDelegate {
  _FixAfterRefresh(super.inner);

  @override
  Future<SessionRefresh> refreshSession() async {
    inner.fetchFrameworkError = null;
    return super.refreshSession();
  }
}
