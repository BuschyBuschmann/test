import 'package:shared_preferences/shared_preferences.dart';

import '../logic/app_state.dart';
import '../logic/clock.dart';
import '../logic/migrations.dart';
import 'data_eraser.dart';
import 'state_store.dart';

/// Speichert das Dokument als JSON-Text in `shared_preferences`
/// (`SharedPreferencesAsync`, kein Cache) und ist zugleich der erste
/// [DataEraser]. Unverschlüsselt; vertretbar für den Prototyp ohne echte
/// Patientendaten (R-3).
class PrefsStateStore implements StateStore, DataEraser {
  PrefsStateStore({required this._clock, SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  final Clock _clock;
  final SharedPreferencesAsync _prefs;

  @override
  Future<AppState?> load() async {
    final String? raw = await _prefs.getString(kStateStorageKey);
    if (raw == null) return null;
    return decodeDocument(raw, LocalDay.from(_clock()));
  }

  @override
  Future<void> save(AppState state) =>
      _prefs.setString(kStateStorageKey, encodeDocument(state));

  /// `clear(allowList:)` arbeitet mit exakten Schlüsseln (n4).
  @override
  Future<void> deleteAll() => _prefs.clear(allowList: kAllStorageKeys);

  @override
  Future<void> eraseAll() => deleteAll();
}
