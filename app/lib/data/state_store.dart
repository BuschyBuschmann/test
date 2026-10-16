import '../logic/app_state.dart';

/// Schlüssel des Zustandsdokuments (Plan 6.1).
const String kStateStorageKey = 'curaone.state.v1';

/// Schlüssel der Darstellungs-Einstellungen (Plan 3.4): eigenes Dokument,
/// getrennt vom Zustand; „Alles löschen“ entfernt es mit (B-21).
const String kDisplayStorageKey = 'curaone.display.v1';

/// Zwischenspeicher des Frameworks (Plan 8.1/8.2): abgeleitete Daten, jederzeit
/// verwerfbar.
const String kFrameworkStorageKey = 'curaone.framework.v1';

/// Ausgangswarteschlange (Plan 8.11).
const String kOutboxStorageKey = 'curaone.outbox.v1';

/// Merkzeichen der Löschung mit Backend (Plan 8.10): `requested` oder
/// `backendDeleted`. Es wird **zuletzt** und nur vom `AccountDeleter` entfernt,
/// damit eine unterbrochene Löschung beim nächsten Start erkannt wird.
const String kDeletionStorageKey = 'curaone.deletion.v1';

/// Alle Speicherschlüssel der App. Wächst mit jeder neuen Einführung eines
/// Schlüssels; `deleteAll` löscht genau diese (exakte Schlüssel, keine
/// Präfixe). Chat und Nachrichten speichern nichts (UI-82).
const Set<String> kAllStorageKeys = <String>{
  kStateStorageKey,
  kDisplayStorageKey,
  kFrameworkStorageKey,
  kOutboxStorageKey,
  kDeletionStorageKey,
};

/// Die Schlüssel, die der lokale Löscher des Zustands mit entfernt: alle außer
/// dem Merkzeichen der Backend-Löschung (das bleibt bis zum letzten Schritt).
final Set<String> kLocalEraseKeys = kAllStorageKeys.difference(<String>{
  kDeletionStorageKey,
});

/// Lesen, Schreiben und Löschen des einen Zustandsdokuments.
abstract class StateStore {
  /// `null`: nichts gespeichert (Erststart). Wirft `UnreadableDataException`
  /// bei unbrauchbarem Inhalt (N-12); jede andere Exception ist ein
  /// Plattformfehler beim Lesen (Fehlerzustand mit „Nochmal versuchen“).
  Future<AppState?> load();

  Future<void> save(AppState state);

  Future<void> deleteAll();
}
