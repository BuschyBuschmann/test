// Versionierung, Migration und Lesetoleranz (Plan 6.2, N-12).
//
// Versionsregel: `schema` steigt bei jeder inkompatiblen Änderung (Feld
// umbenannt/entfernt, Typ oder Bedeutung geändert). Ein neues optionales Feld
// mit Standardwert erhöht die Version nicht.
import 'dart:convert';

import 'app_state.dart';
import 'clock.dart';
import 'json_support.dart';

export 'app_state.dart' show kCurrentSchema;
export 'json_support.dart' show UnreadableDataException;

/// Migrationen: Schlüssel n bringt ein Dokument von Schema n auf n + 1.
/// Noch leer (nur Schema 1 existiert); jede neue Version ergänzt hier eine
/// Funktion **und** ein Fixture `test/fixtures/state_v<n>.json`.
const Map<int, Json Function(Json)> kMigrations = <int, Json Function(Json)>{};

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
  } catch (e) {
    // Fehler einer (künftigen) Migrationsfunktion oder unerwartete Typen:
    // gehören zum Inhalt, nicht zur Plattform (sonst Fehlerzustand mit
    // „Nochmal versuchen“ statt Neustart).
    throw UnreadableDataException('Dokument nicht verarbeitbar: $e');
  }
}

/// Schreibt den Zustand als Dokument.
String encodeDocument(AppState state) => jsonEncode(state.toJson());
