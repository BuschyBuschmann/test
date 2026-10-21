// Versionierung, Migration und Lesetoleranz (Plan 6.2, N-12).
//
// Versionsregel: `schema` steigt bei jeder inkompatiblen Änderung (Feld
// umbenannt/entfernt, Typ oder Bedeutung geändert). Ein neues optionales Feld
// mit Standardwert erhöht die Version nicht.
import 'dart:convert';

import 'app_state.dart';
import 'clock.dart';
import 'json_support.dart';
import 'manny_look.dart';

export 'app_state.dart' show kCurrentSchema;
export 'json_support.dart' show UnreadableDataException;

/// Migrationen: Schlüssel n bringt ein Dokument von Schema n auf n + 1.
/// Jede neue Version ergänzt hier eine Funktion **und** ein Fixture
/// `test/fixtures/state_v<n>*.json`.
const Map<int, Json Function(Json)> kMigrations = <int, Json Function(Json)>{
  1: migrateV1ToV2,
  2: migrateV2ToV3,
};

/// Schema 2 → 3 (Plan 8.1, L3): Abschnitt `account {patientId, boundAt}` kommt
/// hinzu. Bestandsdaten haben keine Bindung (`account` fehlt → Startbildschirm,
/// außer im Demo-Modus); `mannyLook` und alles Übrige bleiben unverändert.
Json migrateV2ToV3(Json doc) {
  final Json out = Json.of(doc);
  out['schema'] = 3;
  return out;
}

/// Schema 1 → 2 (Plan 3.5, Brief-Ergänzung 1, 10): Das Onboarding bekommt vor
/// dem Namen den Look-Schritt, aus dem alten Schritt n wird Schritt n + 1.
/// - nicht abgeschlossenes Onboarding: `step` + 1 (alter Bereich 0..3);
/// - `mannyLook` = `brille` für alle Bestandsdaten;
/// - wer das Onboarding abgeschlossen hat, wird nicht erneut gefragt (der
///   Schritt bleibt unverändert; er wird nie wieder angezeigt).
Json migrateV1ToV2(Json doc) {
  final Json out = Json.of(doc);
  final Object? onboarding = doc['onboarding'];
  if (onboarding is Map && onboarding['completed'] == false) {
    final Object? step = onboarding['step'];
    if (step is int) {
      // Außerhalb des alten Bereichs war schon Schema 1 unlesbar; ohne diese
      // Prüfung würde `3 + 1 = 4` einen kaputten Wert gültig machen.
      if (step < 0 || step > 3) unreadable('onboarding.step: $step');
      out['onboarding'] = <String, Object?>{
        for (final MapEntry<Object?, Object?> e in onboarding.entries)
          if (e.key is String) e.key! as String: e.value,
        'step': step + 1,
      };
    }
  }
  out['mannyLook'] = MannyLook.defaultLook.jsonName;
  out['schema'] = 2;
  return out;
}

/// Bringt [doc] per Migrationskette auf [currentSchema]. `schema` fehlt, ist
/// kein `int`, liegt über [currentSchema] oder es fehlt eine Migration →
/// [UnreadableDataException].
Json migrateToCurrent(
  Json doc, {
  int currentSchema = kCurrentSchema,
  Map<int, Json Function(Json)> migrations = kMigrations,
}) {
  Json json = doc;
  int schema = reqInt(json, 'schema');
  if (schema < 1 || schema > currentSchema) {
    unreadable('schema $schema wird nicht unterstützt');
  }
  while (schema < currentSchema) {
    final Json Function(Json)? step = migrations[schema];
    if (step == null) {
      unreadable('keine Migration von Schema $schema');
    }
    json = step(json);
    final int next = reqInt(json, 'schema');
    if (next != schema + 1) {
      unreadable('Migration $schema: Schema nicht erhöht');
    }
    schema = next;
  }
  return json;
}

/// Liest ein gespeichertes Dokument. Wirft [UnreadableDataException] bei
/// jedem Inhalt, der nicht verwendbar ist (kein JSON, falsche Struktur,
/// unbekanntes Schema, Pflichtfelder fehlen, falsche Typen, ungültiges Datum).
AppState decodeDocument(
  String raw,
  LocalDay today, {
  int currentSchema = kCurrentSchema,
  Map<int, Json Function(Json)> migrations = kMigrations,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    throw UnreadableDataException('kein gültiges JSON: ${e.message}');
  }
  try {
    final Json doc = asJson(decoded, 'Dokument');
    final Json migrated = migrateToCurrent(
      doc,
      currentSchema: currentSchema,
      migrations: migrations,
    );
    return AppState.fromJson(migrated, today);
  } on UnreadableDataException {
    rethrow;
  } on Exception catch (e) {
    // Nur `Exception`-Typen (z. B. `FormatException` einer Migration) gelten
    // als Datenfehler → unlesbar → Neustart (N-12). `Error`-Typen
    // (`TypeError`, `StateError`, `ArgumentError`, `RangeError` …) sind
    // Programmierfehler: "Bug ≠ Datenverlust". Sie werden nicht gefangen und
    // führen im Controller zum Fehlerzustand mit „Nochmal versuchen“; die Daten
    // bleiben erhalten. Legitime Datenfehler melden `json_support.dart` und die
    // `fromJson`-Konstruktoren ausschließlich über explizite `is`-Prüfungen
    // als `UnreadableDataException` (keine Casts auf fremde JSON-Werte).
    throw UnreadableDataException('Dokument nicht verarbeitbar: $e');
  }
}

/// Schreibt den Zustand als Dokument.
String encodeDocument(AppState state) => jsonEncode(state.toJson());
