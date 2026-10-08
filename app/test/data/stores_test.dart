// StateStore-Adapter (RawDocumentStore → StateStore) und PrefsStateStore.
import 'package:curaone/data/state_store.dart';
import 'package:curaone/data/prefs_state_store.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
// Transitive Abhängigkeit von shared_preferences (freigegebenes Paket); nur
// für den In-Memory-Ersatz der Plattform im Test, deshalb kein Eintrag in der
// pubspec.yaml. Risiko: Ein Update von shared_preferences kann das Paket oder
// seinen Pfad ändern oder entfernen; dann bricht dieser Test (nicht die App).
// Bei Bruch: als dev_dependency eintragen (nach Freigabe) oder die Plattform-
// Fakes selbst implementieren.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/builders.dart';
import '../support/fake_clock.dart';
import '../support/raw_state_store.dart';
import '../support/stores.dart';

void main() {
  group('RawBackedStateStore (Adapter auf die Fakes)', () {
    test('nichts gespeichert → null', () async {
      final RawBackedStateStore s = RawBackedStateStore(
        InMemoryStore(),
        clock: FakeClock().call,
      );
      expect(await s.load(), isNull);
    });

    test('save → load Roundtrip, Rohtext ist JSON mit Schema', () async {
      final InMemoryStore raw = InMemoryStore();
      final RawBackedStateStore s = RawBackedStateStore(
        raw,
        clock: FakeClock().call,
      );
      await s.save(expectedV1());
      expect(raw.raw, contains('"schema":1'));
      expect(await s.load(), expectedV1());
    });

    test(
      'unlesbarer Inhalt → UnreadableDataException (CorruptStore)',
      () async {
        for (final String bad in <String>[
          '{kaputt',
          '{"schema":99,"onboarding":{"completed":false,"step":0}}',
          '{"schema":1}',
        ]) {
          final RawBackedStateStore s = RawBackedStateStore(
            CorruptStore(bad),
            clock: FakeClock().call,
          );
          await expectLater(s.load(), throwsA(isA<UnreadableDataException>()));
        }
      },
    );

    test(
      'Plattformfehler beim Lesen: andere Exception (FailingStore)',
      () async {
        final RawBackedStateStore s = RawBackedStateStore(
          FailingStore(),
          clock: FakeClock().call,
        );
        await expectLater(
          s.load(),
          throwsA(isNot(isA<UnreadableDataException>())),
        );
        await expectLater(s.deleteAll(), throwsStateError);
        await expectLater(s.eraseAll(), throwsStateError);
      },
    );

    test('deleteAll/eraseAll leeren den Speicher', () async {
      final InMemoryStore raw = InMemoryStore('x');
      final RawBackedStateStore s = RawBackedStateStore(
        raw,
        clock: FakeClock().call,
      );
      await s.eraseAll();
      expect(raw.raw, isNull);
      expect(raw.deletes, 1);
    });

    test('fehlender dayKey wird mit dem Tag der Uhr ersetzt', () async {
      final RawBackedStateStore s = RawBackedStateStore(
        InMemoryStore('{"schema":1,"onboarding":{"completed":false,"step":0}}'),
        clock: FakeClock(DateTime(2026, 12, 24, 9)).call,
      );
      final AppState? loaded = await s.load();
      expect(loaded!.day.dayKey.toString(), '2026-12-24');
    });
  });

  group('PrefsStateStore (SharedPreferencesAsync, In-Memory-Plattform)', () {
    late InMemorySharedPreferencesAsync platform;
    late SharedPreferencesAsync prefs;

    setUp(() {
      platform = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = platform;
      prefs = SharedPreferencesAsync();
    });

    PrefsStateStore make() =>
        PrefsStateStore(clock: FakeClock().call, prefs: prefs);

    test('Schlüsselliste: genau ein Schlüssel', () {
      expect(kAllStorageKeys, <String>{'curaone.state.v1'});
    });

    test('leer → null; save/load Roundtrip', () async {
      final PrefsStateStore store = make();
      expect(await store.load(), isNull);
      await store.save(expectedV1());
      expect(await prefs.getString(kStateStorageKey), isNotNull);
      expect(await store.load(), expectedV1());
    });

    test('unlesbarer Inhalt → UnreadableDataException', () async {
      await prefs.setString(kStateStorageKey, '{kaputt');
      await expectLater(make().load(), throwsA(isA<UnreadableDataException>()));
    });

    test(
      'deleteAll/eraseAll löscht genau kAllStorageKeys, fremde bleiben',
      () async {
        final PrefsStateStore store = make();
        await store.save(onboardedState());
        await prefs.setString('fremd', 'bleibt');
        await store.eraseAll();
        expect(await prefs.getKeys(), <String>{'fremd'});
        expect(await store.load(), isNull);
        await store.save(onboardedState());
        await store.deleteAll();
        expect(await prefs.getString(kStateStorageKey), isNull);
      },
    );
  });
}
