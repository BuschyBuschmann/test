// Selbsttest des Test-Supports (FakeClock, Stores, Viewports).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_clock.dart';
import 'pump_app.dart';
import 'stores.dart';

void main() {
  group('FakeClock', () {
    test('Standard 2026-10-07 ist ein Mittwoch', () {
      final FakeClock clock = FakeClock();
      expect(clock().year, 2026);
      expect(clock().month, 10);
      expect(clock().day, 7);
      expect(clock().weekday, DateTime.wednesday);
    });

    test('advance, advanceDays, set; als Funktion verwendbar', () {
      final FakeClock clock = FakeClock();
      final DateTime Function() fn = clock.call;
      clock.advance(const Duration(hours: 13));
      expect(fn().day, 8);
      clock.advanceDays(-2);
      expect(clock.now.day, 6);
      expect(clock.now.hour, 1);
      clock.set(DateTime(2026, 3, 29, 23)); // Sommerzeitwechsel Berlin
      clock.advanceDays(1);
      expect(clock.now.day, 30);
      expect(clock.now.hour, 23);
    });
  });

  group('Stores', () {
    test('InMemoryStore: lesen, schreiben, löschen, Zähler', () async {
      final InMemoryStore store = InMemoryStore();
      expect(await store.read(), isNull);
      await store.write('{"a":1}');
      expect(await store.read(), '{"a":1}');
      await store.deleteAll();
      expect(await store.read(), isNull);
      expect(<int>[store.reads, store.writes, store.deletes], <int>[3, 1, 1]);
    });

    test(
      'FailingStore wirft bei read und deleteAll, write nur auf Wunsch',
      () async {
        final FailingStore store = FailingStore();
        await expectLater(store.read(), throwsStateError);
        await expectLater(store.deleteAll(), throwsStateError);
        await store.write('x');
        await expectLater(
          FailingStore(failOnWrite: true).write('x'),
          throwsStateError,
        );
      },
    );

    test('SlowStore hält Operationen bis release()', () async {
      final SlowStore store = SlowStore(InMemoryStore('abc'));
      bool done = false;
      final Future<String?> f = store.read().then((String? v) {
        done = true;
        return v;
      });
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse);
      expect(store.pending, 1);
      store.release();
      expect(await f, 'abc');
      expect(store.pending, 0);
      // nach release läuft alles sofort
      await store.write('neu');
      expect(await store.read(), 'neu');
    });

    test(
      'CorruptStore liefert den vorgegebenen Rohtext bis zum Löschen',
      () async {
        final CorruptStore store = CorruptStore('{kaputt');
        expect(await store.read(), '{kaputt');
        await store.deleteAll();
        expect(store.deleted, isTrue);
        expect(await store.read(), isNull);
      },
    );
  });

  testWidgets('pumpApp setzt Viewport und Textskalierung', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Text(
          '${MediaQuery.sizeOf(context)} ${MediaQuery.textScalerOf(context).scale(10)}',
        ),
      ),
      size: Viewports.small,
      textScale: 2,
    );
    expect(find.text('Size(320.0, 568.0) 20.0'), findsOneWidget);
  });
}
