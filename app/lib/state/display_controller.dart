// Halter der Darstellungs-Einstellungen (Plan 3.4, V2-7): Welt, Thema,
// „Transparenz reduzieren“, Ton, Vibration. Wirkt sofort (Listener), speichert
// jede Änderung über den [DisplayStore] und ist zugleich ein [DataEraser]:
// „Alles löschen“ setzt die Einstellungen auf den Standard zurück (der
// Speicherschlüssel steht in `kAllStorageKeys` und wird vom Zustandsspeicher
// mitgelöscht).
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/data_eraser.dart';
import '../data/display_store.dart';
import '../logic/display_settings.dart';
import '../logic/world_time.dart';

class DisplayController extends ChangeNotifier implements DataEraser {
  DisplayController({
    DisplayStore? store,
    this.worldClock = const WorldClock(),
    DisplaySettings initial = const DisplaySettings(),
  }) : _store = store ?? MemoryDisplayStore(),
       _settings = initial;

  final DisplayStore _store;

  /// Die Uhr der Welt (Brief 3.1); Tests setzen eine feste Uhr.
  final WorldClock worldClock;

  DisplaySettings _settings;
  Future<void> _writeChain = Future<void>.value();

  DisplaySettings get settings => _settings;

  /// Welt zum jetzigen Zeitpunkt (fester Look oder Zeitregel).
  WorldMix worldNow() => worldClock.mixFor(_settings.world);

  /// Liest die gespeicherten Einstellungen (Start). Fehler beim Lesen lassen
  /// den Standard stehen.
  Future<void> load() async {
    try {
      final DisplaySettings loaded = await _store.load();
      _apply(loaded, persist: false);
    } on Exception {
      // Standard bleibt.
    }
  }

  void setWorld(WorldChoice value) => _apply(_settings.copyWith(world: value));

  void setTheme(ThemeChoice value) => _apply(_settings.copyWith(theme: value));

  void setReduceTransparency(bool value) =>
      _apply(_settings.copyWith(reduceTransparency: value));

  void setSound(bool value) => _apply(_settings.copyWith(sound: value));

  void setVibration(bool value) => _apply(_settings.copyWith(vibration: value));

  void _apply(DisplaySettings next, {bool persist = true}) {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    if (!persist) return;
    _writeChain = _writeChain.then((_) async {
      try {
        await _store.save(next);
      } on Exception {
        // Die Einstellung gilt für diese Sitzung weiter.
      }
    });
  }

  /// Für Tests: wartet auf anstehende Schreibvorgänge.
  @visibleForTesting
  Future<void> flush() => _writeChain;

  /// „Alles löschen“: Dokument entfernen und zurück auf den Standard (auch
  /// der Zustandsspeicher löscht den Schlüssel über `kAllStorageKeys`).
  @override
  Future<void> eraseAll() async {
    await _writeChain;
    await _store.erase();
    _apply(const DisplaySettings(), persist: false);
  }
}
