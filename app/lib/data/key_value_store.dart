// Kleiner Schlüssel-Text-Speicher für die Dokumente der Datenschicht
// (Zwischenspeicher, Warteschlange, Merkzeichen). Hinter einer Schnittstelle,
// damit alle Tests ohne Plattformspeicher laufen.
import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

/// Produktion: `SharedPreferencesAsync` (kein Cache, wie `PrefsStateStore`).
class PrefsKeyValueStore implements KeyValueStore {
  PrefsKeyValueStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Ohne Plattformspeicher (Prüfumgebung, Tests).
class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore([Map<String, String>? initial])
    : values = initial ?? <String, String>{};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}
