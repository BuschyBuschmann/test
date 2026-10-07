import 'package:curaone/data/data_eraser.dart';
import 'package:curaone/data/state_store.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/migrations.dart';

import 'stores.dart';

/// Dünner Adapter `RawDocumentStore` → `StateStore` (Aufgabe aus U1a).
///
/// Parst den Rohtext mit demselben Codec wie `PrefsStateStore`
/// (`decodeDocument`); unbrauchbarer Inhalt wirft `UnreadableDataException`
/// und löst im `AppController` den Neustart-Pfad aus (N-12). Plattformfehler
/// der Fakes (`FailingStore`) gehen unverändert durch (Fehlerzustand).
/// Zugleich ein [DataEraser], wie der echte Store.
class RawBackedStateStore implements StateStore, DataEraser {
  RawBackedStateStore(this.raw, {required this.clock});

  final RawDocumentStore raw;
  final Clock clock;

  @override
  Future<AppState?> load() async {
    final String? text = await raw.read();
    if (text == null) return null;
    return decodeDocument(text, LocalDay.from(clock()));
  }

  @override
  Future<void> save(AppState state) => raw.write(encodeDocument(state));

  @override
  Future<void> deleteAll() => raw.deleteAll();

  @override
  Future<void> eraseAll() => deleteAll();
}
