// Persistente Ausgangswarteschlange (Plan 8.11): ein Dokument unter
// `curaone.outbox.v1`. Nur lesen/schreiben/löschen; die Reihenfolge und die
// Fehlerregeln stehen in `lib/logic/outbox.dart`.
import 'dart:convert';

import '../logic/json_support.dart';
import '../logic/outbox.dart';
import 'data_eraser.dart';
import 'key_value_store.dart';
import 'state_store.dart';

class LoadedOutbox {
  const LoadedOutbox({required this.outbox, this.skipped = 0});

  final Outbox outbox;

  /// Einträge, die nicht gelesen werden konnten und übersprungen wurden.
  final int skipped;
}

abstract class OutboxStore implements DataEraser {
  Future<LoadedOutbox> load();

  Future<void> save(Outbox outbox);
}

class StoreOutboxStore implements OutboxStore {
  StoreOutboxStore(this._store);

  final KeyValueStore _store;

  /// Fehlt das Dokument, ist die Warteschlange leer. Ein Gesamtdokument, das
  /// nicht lesbar ist, ergibt eine leere Warteschlange mit `skipped = 1`
  /// (es gibt nichts zu retten; der Aufrufer kann das melden).
  @override
  Future<LoadedOutbox> load() async {
    final String? raw = await _store.read(kOutboxStorageKey);
    if (raw == null) return LoadedOutbox(outbox: Outbox());
    try {
      final ({Outbox outbox, int skipped}) r = decodeOutbox(jsonDecode(raw));
      return LoadedOutbox(outbox: r.outbox, skipped: r.skipped);
    } on FormatException {
      return LoadedOutbox(outbox: Outbox(), skipped: 1);
    } on UnreadableDataException {
      return LoadedOutbox(outbox: Outbox(), skipped: 1);
    }
  }

  @override
  Future<void> save(Outbox outbox) => outbox.isEmpty
      ? _store.remove(kOutboxStorageKey)
      : _store.write(kOutboxStorageKey, jsonEncode(outbox.toJson()));

  @override
  Future<void> eraseAll() => _store.remove(kOutboxStorageKey);
}
