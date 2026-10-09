// Speicher der Prüfumgebung (Plan 12.5): hält den Zustand eines Szenarios im
// Arbeitsspeicher. Beide Speicher sind zugleich Löscher (KS-9), damit der
// echte Löschweg des `AppController` läuft.
import 'dart:async';

import '../data/data_eraser.dart';
import '../data/state_store.dart';
import '../logic/app_state.dart';
import '../logic/json_support.dart' show UnreadableDataException;
import '../ui/path/path_source.dart';

/// Zustand im Arbeitsspeicher; `null` = nichts gespeichert (Erststart).
class MemoryStateStore implements StateStore, DataEraser {
  MemoryStateStore([this.state]);

  AppState? state;

  @override
  Future<AppState?> load() async => state;

  @override
  Future<void> save(AppState value) async => state = value;

  @override
  Future<void> deleteAll() async => state = null;

  @override
  Future<void> eraseAll() => deleteAll();
}

/// Liefert beim Lesen unlesbaren Inhalt, bis er gelöscht wurde (N-12): der
/// Controller verwirft ihn, startet das Onboarding neu und zeigt den Hinweis.
class UnreadableStateStore extends MemoryStateStore {
  bool _unreadable = true;

  @override
  Future<AppState?> load() async {
    if (_unreadable) {
      final Exception e = UnreadableDataException(
        'Szenario: kaputtes Dokument',
      );
      throw e;
    }
    return super.load();
  }

  @override
  Future<void> deleteAll() async {
    _unreadable = false;
    await super.deleteAll();
  }
}

/// Der Speicher wirft beim Lesen einen Plattformfehler (kein unlesbarer
/// Inhalt): der StartGate zeigt den Fehlerzustand mit „Nochmal versuchen“.
class FailingReadStateStore extends MemoryStateStore {
  @override
  Future<AppState?> load() async {
    throw StateError('Szenario: Plattformfehler beim Lesen');
  }
}

/// Pfad-Quelle, die nie fertig wird: der Pfad-Tab bleibt im Ladezustand
/// (`path-loading`, Brief 6.2).
class PendingPathSource implements PathSource {
  const PendingPathSource();

  @override
  Future<void>? prepare() => Completer<void>().future;
}

/// Pfad-Quelle, die scheitert: der Pfad-Tab zeigt den Fehlerzustand mit
/// „Nochmal versuchen“ (`path-error`, Erratum E-4: „Dein Pfad konnte nicht
/// geladen werden.“).
class FailingPathSource implements PathSource {
  const FailingPathSource();

  @override
  Future<void>? prepare() => throw StateError('Szenario: Pfad nicht ladbar');
}
