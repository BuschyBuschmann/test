// Persistente Warteschlange (Plan 8.11) und KeyValueStore.
import 'package:curaone/data/key_value_store.dart';
import 'package:curaone/data/outbox_store.dart';
import 'package:curaone/data/state_store.dart';
import 'package:curaone/logic/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

OutboxEntry e(String id) => mannyLookSetEntry(
  entryId: id,
  now: DateTime.utc(2026, 10, 7),
  look: 'ohne',
);

void main() {
  test('Roundtrip; leere Warteschlange entfernt den Schlüssel', () async {
    final MemoryKeyValueStore kv = MemoryKeyValueStore();
    final StoreOutboxStore store = StoreOutboxStore(kv);
    expect((await store.load()).outbox.isEmpty, isTrue);
    await store.save(Outbox(<OutboxEntry>[e('a'), e('b')]));
    expect(kv.values.containsKey(kOutboxStorageKey), isTrue);
    final LoadedOutbox back = await store.load();
    expect(back.outbox.entries.map((OutboxEntry x) => x.id), <String>[
      'a',
      'b',
    ]);
    expect(back.skipped, 0);
    await store.save(Outbox());
    expect(kv.values.containsKey(kOutboxStorageKey), isFalse);
  });

  test('kaputtes Gesamtdokument: leer, skipped = 1', () async {
    final StoreOutboxStore store = StoreOutboxStore(
      MemoryKeyValueStore(<String, String>{kOutboxStorageKey: '[[['}),
    );
    final LoadedOutbox r = await store.load();
    expect(r.outbox.isEmpty, isTrue);
    expect(r.skipped, 1);
  });

  test('eraseAll', () async {
    final MemoryKeyValueStore kv = MemoryKeyValueStore();
    final StoreOutboxStore store = StoreOutboxStore(kv);
    await store.save(Outbox(<OutboxEntry>[e('a')]));
    await store.eraseAll();
    expect(kv.values, isEmpty);
  });

  test('MemoryKeyValueStore', () async {
    final MemoryKeyValueStore kv = MemoryKeyValueStore();
    expect(await kv.read('x'), isNull);
    await kv.write('x', '1');
    expect(await kv.read('x'), '1');
    await kv.remove('x');
    expect(await kv.read('x'), isNull);
  });
}
