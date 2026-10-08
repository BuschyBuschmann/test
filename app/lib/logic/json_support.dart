// Lesehilfen für das Zustandsdokument (Plan 6.2, Lesetoleranz).
//
// Regel: Ein fehlendes oder `null`-Feld bei optionalen Werten ergibt den
// Standardwert. Ein vorhandenes Feld mit falschem Typ, ein ungültiges Datum
// oder ein Wert außerhalb des Wertebereichs ist **unlesbar** (N-12) und wirft
// [UnreadableDataException]. Unbekannte zusätzliche Felder werden ignoriert.
import 'clock.dart';

typedef Json = Map<String, Object?>;

/// Gespeicherte Daten sind nicht verwendbar (kaputtes JSON, falscher Typ,
/// unbekanntes Schema …). Die App startet dann automatisch neu (N-12).
class UnreadableDataException implements Exception {
  UnreadableDataException(this.message);

  final String message;

  @override
  String toString() => 'UnreadableDataException: $message';
}

Never unreadable(String message) => throw UnreadableDataException(message);

Json asJson(Object? value, String where) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    // `jsonDecode` liefert `Map<String, dynamic>`; fremde Maps mit
    // Nicht-String-Schlüsseln sind unlesbar.
    final Json out = <String, Object?>{};
    for (final MapEntry<Object?, Object?> e in value.entries) {
      final Object? k = e.key;
      if (k is! String) unreadable('$where: Schlüssel ist kein Text');
      out[k] = e.value;
    }
    return out;
  }
  return unreadable('$where: Objekt erwartet');
}

Json? optJson(Json j, String key) {
  final Object? v = j[key];
  return v == null ? null : asJson(v, key);
}

Json reqJson(Json j, String key) {
  final Object? v = j[key];
  if (v == null) unreadable('$key fehlt');
  return asJson(v, key);
}

int reqInt(Json j, String key) {
  final Object? v = j[key];
  if (v is int) return v;
  return unreadable('$key: ganze Zahl erwartet');
}

int optInt(Json j, String key, int fallback) {
  final Object? v = j[key];
  if (v == null) return fallback;
  if (v is int) return v;
  return unreadable('$key: ganze Zahl erwartet');
}

bool reqBool(Json j, String key) {
  final Object? v = j[key];
  if (v is bool) return v;
  return unreadable('$key: Wahrheitswert erwartet');
}

bool optBool(Json j, String key, bool fallback) {
  final Object? v = j[key];
  if (v == null) return fallback;
  if (v is bool) return v;
  return unreadable('$key: Wahrheitswert erwartet');
}

String optString(Json j, String key, String fallback) {
  final Object? v = j[key];
  if (v == null) return fallback;
  if (v is String) return v;
  return unreadable('$key: Text erwartet');
}

String? optStringOrNull(Json j, String key) {
  final Object? v = j[key];
  if (v == null) return null;
  if (v is String) return v;
  return unreadable('$key: Text erwartet');
}

String reqString(Json j, String key) {
  final Object? v = j[key];
  if (v is String) return v;
  return unreadable('$key: Text erwartet');
}

LocalDay? optDay(Json j, String key) {
  final String? text = optStringOrNull(j, key);
  if (text == null) return null;
  return LocalDay.tryParse(text) ?? unreadable('$key: ungültiges Datum');
}

LocalDay reqDay(Json j, String key) =>
    optDay(j, key) ?? unreadable('$key fehlt');

List<String> optStringList(Json j, String key) {
  final Object? v = j[key];
  if (v == null) return <String>[];
  if (v is! List) return unreadable('$key: Liste erwartet');
  final List<String> out = <String>[];
  for (final Object? item in v) {
    if (item is! String) unreadable('$key: Text in Liste erwartet');
    out.add(item);
  }
  return out;
}

List<Json> optJsonList(Json j, String key) {
  final Object? v = j[key];
  if (v == null) return <Json>[];
  if (v is! List) return unreadable('$key: Liste erwartet');
  return <Json>[for (final Object? item in v) asJson(item, key)];
}

/// Prüft einen Wertebereich und wirft sonst [UnreadableDataException].
int inRange(int value, int min, int max, String name) {
  if (value < min || value > max) {
    unreadable('$name: $value außerhalb von $min..$max');
  }
  return value;
}
