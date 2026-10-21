// Lokaler Speicher der Darstellungs-Einstellungen (Plan 3.4): ein kleines
// JSON-Dokument unter `curaone.display.v1` in `shared_preferences`. Lesen ist
// tolerant (Standard bei allem Unbrauchbaren), Schreibfehler wirft die
// aufrufende Stelle nicht weiter (die Einstellung gilt dann bis zum Ende der
// Sitzung).
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/display_settings.dart';
import 'state_store.dart';

abstract class DisplayStore {
  Future<DisplaySettings> load();

  Future<void> save(DisplaySettings settings);

  /// Entfernt das Dokument („Alles löschen“, B-21).
  Future<void> erase();
}

class PrefsDisplayStore implements DisplayStore {
  PrefsDisplayStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<DisplaySettings> load() async {
    final String? raw = await _prefs.getString(kDisplayStorageKey);
    return DisplaySettings.fromJsonString(raw);
  }

  @override
  Future<void> save(DisplaySettings settings) =>
      _prefs.setString(kDisplayStorageKey, settings.toJsonString());

  @override
  Future<void> erase() => _prefs.remove(kDisplayStorageKey);
}

/// Ohne Plattformspeicher (Prüfumgebung, Tests).
class MemoryDisplayStore implements DisplayStore {
  MemoryDisplayStore([this.settings = const DisplaySettings()]);

  DisplaySettings settings;

  @override
  Future<DisplaySettings> load() async => settings;

  @override
  Future<void> save(DisplaySettings value) async => settings = value;

  @override
  Future<void> erase() async => settings = const DisplaySettings();
}
