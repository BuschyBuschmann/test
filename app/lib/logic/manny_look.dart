// Manny-Look (Design-Brief v2, Ergänzung 1, 6a/6b; Plan 3.5): Mit oder ohne
// Brille. Gilt für die ganze App, wird sofort gespeichert und bleibt über den
// Neustart erhalten. Vorbelegung ist „Mit Brille“. Reine Dart-Logik.
import 'json_support.dart';

enum MannyLook {
  /// Mit Brille (Vorbelegung, Bestandsdaten).
  brille,

  /// Ohne Brille.
  ohne;

  static const MannyLook defaultLook = MannyLook.brille;

  /// Name im Dokument.
  String get jsonName => name;

  /// Fehlt der Wert, gilt die Vorbelegung. Ein vorhandener unbekannter Wert
  /// ist unlesbar (N-12, wie alle Felder des Zustandsdokuments).
  static MannyLook fromJson(Object? value) {
    if (value == null) return defaultLook;
    for (final MannyLook look in MannyLook.values) {
      if (look.name == value) return look;
    }
    return unreadable('mannyLook: unbekannter Wert');
  }
}
