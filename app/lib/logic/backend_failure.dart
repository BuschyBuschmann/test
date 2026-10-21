// Fehler beim Zugriff auf das Backend, unabhängig vom Client-Paket (Plan 8.11,
// Hinweise für L3 aus `supabase/tests/README.md`). Die Abbildung der
// Paket-Exceptions steht in `lib/backend/`. Reine Dart-Logik.

enum FailureKind {
  /// Anfrage nie abgeschickt (keine Verbindung, DNS): sicher nichts passiert.
  unreachable,

  /// Zeitüberschreitung nach dem Senden: Ergebnis unklar.
  timeout,

  /// 401 / abgelaufene oder ungültige Sitzung.
  auth,

  /// 5xx.
  server,

  /// Antwort des Servers mit 4xx oder Datenbankfehler (Regel verletzt, Recht
  /// fehlt, Eingabe ungültig).
  rejected,
}

class BackendFailure implements Exception {
  const BackendFailure(
    this.kind, {
    this.sqlState,
    this.httpStatus,
    this.message = '',
  });

  final FailureKind kind;

  /// SQLSTATE der Datenbank, falls bekannt (`42501`, `23505`, `40P01` …).
  final String? sqlState;
  final int? httpStatus;

  /// Meldungstext der Funktion (z. B. `invalid_local_day`, `already_submitted`).
  final String message;

  /// `false` nur, wenn die Anfrage sicher nicht beim Server ankam.
  bool get requestMayHaveReachedServer => kind != FailureKind.unreachable;

  bool hasMessage(String code) => message.contains(code);

  @override
  String toString() =>
      'BackendFailure($kind, sqlState: $sqlState, http: $httpStatus, $message)';
}

/// Die Bindung des Patienten besteht nicht mehr: Patientenzeile fehlt,
/// `access_deleted`, oder das Auth-Konto existiert nicht mehr (Neubindung auf
/// einem anderen Gerät, „Alles löschen“). Folge: lokale Daten löschen,
/// Startbildschirm (Plan 8.2, B-11).
class BindingLostException implements Exception {
  const BindingLostException([this.reason = '']);

  final String reason;

  @override
  String toString() => 'BindingLostException($reason)';
}
