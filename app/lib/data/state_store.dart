import '../logic/app_state.dart';

/// Schlüssel des Zustandsdokuments (Plan 6.1).
const String kStateStorageKey = 'curaone.state.v1';

/// Schlüssel der Darstellungs-Einstellungen (Plan 3.4): eigenes Dokument,
/// getrennt vom Zustand; „Alles löschen“ entfernt es mit (B-21).
const String kDisplayStorageKey = 'curaone.display.v1';

/// Alle Speicherschlüssel der App. Wächst mit jeder neuen Einführung eines
/// Schlüssels; `deleteAll` löscht genau diese (exakte Schlüssel, keine
/// Präfixe). Chat und Nachrichten speichern nichts (UI-82).
const Set<String> kAllStorageKeys = <String>{
  kStateStorageKey,
  kDisplayStorageKey,
};

/// Lesen, Schreiben und Löschen des einen Zustandsdokuments.
abstract class StateStore {
  /// `null`: nichts gespeichert (Erststart). Wirft `UnreadableDataException`
  /// bei unbrauchbarem Inhalt (N-12); jede andere Exception ist ein
  /// Plattformfehler beim Lesen (Fehlerzustand mit „Nochmal versuchen“).
  Future<AppState?> load();

  Future<void> save(AppState state);

  Future<void> deleteAll();
}
