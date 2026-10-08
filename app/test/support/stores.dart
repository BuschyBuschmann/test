import 'dart:async';

/// Schlüssel des Zustandsdokuments (Plan 6.1, `kAllStorageKeys` in U1b).
const String kTestStateKey = 'curaone.state.v1';

/// Roh-Speicher für **ein** Dokument als Text.
///
/// Die Fakes liegen bewusst auf dieser Ebene, weil `StateStore`/`AppState`
/// erst mit U1b entstehen (Plan 14). Davor hängt `raw_state_store.dart`
/// (`RawBackedStateStore`) einen dünnen Adapter, der den Rohtext parst und bei
/// unlesbarem Inhalt `UnreadableDataException` wirft (löst im `AppController`
/// den Neustart-Pfad aus, N-12).
abstract class RawDocumentStore {
  Future<String?> read();
  Future<void> write(String raw);
  Future<void> deleteAll();
}

/// Hält das Dokument im Arbeitsspeicher; zählt Aufrufe für Assertions.
class InMemoryStore implements RawDocumentStore {
  InMemoryStore([this.raw]);

  String? raw;
  int reads = 0;
  int writes = 0;
  int deletes = 0;

  @override
  Future<String?> read() async {
    reads++;
    return raw;
  }

  @override
  Future<void> write(String value) async {
    writes++;
    raw = value;
  }

  @override
  Future<void> deleteAll() async {
    deletes++;
    raw = null;
  }
}

/// Wirft bei `read` und `deleteAll` (Plattformfehler, Plan 6.2/6.3); `write`
/// wirft nur, wenn `failOnWrite` gesetzt ist.
class FailingStore implements RawDocumentStore {
  FailingStore({this.failOnWrite = false});

  final bool failOnWrite;

  @override
  Future<String?> read() => Future<String?>.error(StateError('read failed'));

  @override
  Future<void> write(String raw) {
    return failOnWrite
        ? Future<void>.error(StateError('write failed'))
        : Future<void>.value();
  }

  @override
  Future<void> deleteAll() => Future<void>.error(StateError('delete failed'));
}

/// Verzögert jede Operation, bis [release] aufgerufen wird (z. B. für den
/// Löschdialog im Ladezustand ab 300 ms, UI-52).
class SlowStore implements RawDocumentStore {
  SlowStore([RawDocumentStore? inner]) : _inner = inner ?? InMemoryStore();

  final RawDocumentStore _inner;
  Completer<void> _gate = Completer<void>();

  int pending = 0;

  /// Gibt alle wartenden und künftigen Operationen frei.
  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  /// Schaltet die Verzögerung wieder ein.
  void hold() {
    if (_gate.isCompleted) _gate = Completer<void>();
  }

  Future<T> _delayed<T>(Future<T> Function() op) async {
    pending++;
    try {
      await _gate.future;
      return await op();
    } finally {
      pending--;
    }
  }

  @override
  Future<String?> read() => _delayed(_inner.read);

  @override
  Future<void> write(String raw) => _delayed(() => _inner.write(raw));

  @override
  Future<void> deleteAll() => _delayed(_inner.deleteAll);
}

/// Liefert beim Lesen einen vorgegebenen Rohtext (kaputtes JSON, falsches
/// Schema, fehlende Pflichtfelder …, N-12). Schreiben und Löschen gehen in den
/// Speicher dahinter.
class CorruptStore implements RawDocumentStore {
  CorruptStore(this.rawText);

  final String rawText;
  bool deleted = false;

  @override
  Future<String?> read() async => deleted ? null : rawText;

  @override
  Future<void> write(String raw) async {}

  @override
  Future<void> deleteAll() async {
    deleted = true;
  }
}
