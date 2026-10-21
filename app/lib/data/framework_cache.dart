// Zwischenspeicher des Frameworks (Plan 8.2): letzter erfolgreicher Stand für
// Fehler und fehlende Verbindung. Abgeleitete Daten: ein unlesbarer
// Zwischenspeicher wird verworfen, nie als Fehler gemeldet.
import 'dart:convert';

import '../logic/framework.dart';
import '../logic/json_support.dart';
import 'data_eraser.dart';
import 'key_value_store.dart';
import 'state_store.dart';

class CachedFramework {
  const CachedFramework({required this.framework, required this.savedAt});

  final Framework framework;

  /// Zeitpunkt des Ladens (UTC).
  final DateTime savedAt;
}

abstract class FrameworkCache implements DataEraser {
  /// `null`: nichts oder Unbrauchbares gespeichert.
  Future<CachedFramework?> read();

  Future<void> write(Framework framework, DateTime savedAt);
}

class StoreFrameworkCache implements FrameworkCache {
  StoreFrameworkCache(this._store);

  final KeyValueStore _store;

  @override
  Future<CachedFramework?> read() async {
    final String? raw = await _store.read(kFrameworkStorageKey);
    if (raw == null) return null;
    try {
      final Json doc = asJson(jsonDecode(raw), 'Zwischenspeicher');
      return CachedFramework(
        framework: Framework.fromJson(reqJson(doc, 'framework')),
        savedAt: reqInstant(doc, 'savedAt'),
      );
    } on FormatException {
      await _store.remove(kFrameworkStorageKey);
      return null;
    } on UnreadableDataException {
      await _store.remove(kFrameworkStorageKey);
      return null;
    }
  }

  @override
  Future<void> write(Framework framework, DateTime savedAt) => _store.write(
    kFrameworkStorageKey,
    jsonEncode(<String, Object?>{
      'schema': 1,
      'savedAt': savedAt.toUtc().toIso8601String(),
      'framework': framework.toJson(),
    }),
  );

  @override
  Future<void> eraseAll() => _store.remove(kFrameworkStorageKey);
}
