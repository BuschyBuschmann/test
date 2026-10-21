// Abbildung der Paket-Exceptions (`supabase_flutter`) auf [BackendFailure]
// (Plan 8.11). Die Pakete liefern bei Datenbankfehlern keinen HTTP-Status,
// sondern `PostgrestException.code`: den SQLSTATE (5 Zeichen), einen
// `PGRSTnnn`-Code oder, ohne Code im Antwortkörper, den Statuscode als Text.
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../logic/backend_failure.dart';
import '../logic/json_support.dart' show UnreadableDataException;

final RegExp _sqlState = RegExp(r'^[0-9A-Z]{5}$');
final RegExp _httpStatus = RegExp(r'^[1-5][0-9]{2}$');

String? _sqlStateOf(String code) =>
    _sqlState.hasMatch(code) && !code.startsWith('PGRST') ? code : null;

/// Fehlerklasse nach SQLSTATE bzw. `PGRST`-Code; unbekannte Codes gelten als
/// vorübergehend ([FailureKind.server]), damit nie Daten verworfen werden, nur
/// weil ein Code unbekannt ist. Verworfen wird nur, was als Ablehnung bekannt
/// ist.
FailureKind _kindOfCode(String code, int? http) {
  if (code == 'PGRST301' || code == 'PGRST302' || code == 'PGRST303') {
    return FailureKind.auth; // JWT fehlt/abgelaufen/ungültig
  }
  if (http == 401) return FailureKind.auth;
  if (http != null) {
    return http >= 500 ? FailureKind.server : FailureKind.rejected;
  }
  if (code.startsWith('PGRST')) {
    // PGRST000–003: Verbindung zur Datenbank; übrige: fehlerhafte Anfrage.
    return code.startsWith('PGRST00')
        ? FailureKind.server
        : FailureKind.rejected;
  }
  final String? state = _sqlStateOf(code);
  if (state == null) return FailureKind.server;
  final String cls = state.substring(0, 2);
  switch (cls) {
    case '22': // Datenfehler (u. a. 22023 invalid_parameter_value)
    case '23': // Integrität (23505 doppelt, 23503 Fremdschlüssel)
    case '42': // Rechte/Syntax (42501)
    case 'P0': // eigene Meldungen (`RAISE EXCEPTION`)
    case '55': // Objekt nicht im erwarteten Zustand (z. B. fehlender Pepper)
      return FailureKind.rejected;
    default:
      // 08 Verbindung, 40 Serialisierung/Deadlock, 53 Ressourcen, 57
      // Betreiber, XX intern …
      return FailureKind.server;
  }
}

BackendFailure failureFromPostgrest(PostgrestException e) {
  final String code = e.code ?? '';
  final int? http = _httpStatus.hasMatch(code) ? int.parse(code) : null;
  final String details = e.details is String ? ' ${e.details}' : '';
  return BackendFailure(
    _kindOfCode(code, http),
    sqlState: _sqlStateOf(code),
    httpStatus: http,
    message: '${e.message}$details',
  );
}

BackendFailure failureFromAuth(AuthException e) {
  final int? http = int.tryParse(e.statusCode ?? '');
  FailureKind kind;
  if (e is AuthRetryableFetchException) {
    kind = FailureKind.unreachable;
  } else if (e is AuthSessionMissingException || e is AuthInvalidJwtException) {
    kind = FailureKind.auth;
  } else if (http == 401) {
    kind = FailureKind.auth;
  } else if (http != null) {
    kind = http >= 500 ? FailureKind.server : FailureKind.rejected;
  } else {
    kind = FailureKind.timeout;
  }
  return BackendFailure(kind, httpStatus: http, message: e.message);
}

/// Führt [operation] aus und bildet jede Exception auf [BackendFailure] ab.
/// [BindingLostException] und [BackendFailure] bleiben unverändert. Unbekannte
/// Ausnahmen (Netzwerkfehler der Plattform, die nur im jeweiligen Paket
/// bekannt sind) gelten als [FailureKind.timeout]: unklar und wiederholbar,
/// niemals „sicher nicht passiert“ und niemals verwerfbar.
Future<T> guardBackend<T>(
  Future<T> Function() operation, {
  required Duration timeout,
}) async {
  try {
    return await operation().timeout(timeout);
  } on BackendFailure {
    rethrow;
  } on BindingLostException {
    rethrow;
  } on PostgrestException catch (e) {
    throw failureFromPostgrest(e);
  } on AuthException catch (e) {
    throw failureFromAuth(e);
  } on TimeoutException {
    throw const BackendFailure(FailureKind.timeout, message: 'timeout');
  } on UnreadableDataException catch (e) {
    throw BackendFailure(
      FailureKind.rejected,
      message: 'unreadable: ${e.message}',
    );
  } on Exception catch (e) {
    throw BackendFailure(FailureKind.timeout, message: e.toString());
  }
}

/// Codes von GoTrue, bei denen das Konto bzw. die Sitzung nicht mehr
/// existiert (Plan 8.11: Sitzungserneuerung scheitert, weil das Konto weg ist).
/// Gegen den echten Stack zu bestätigen (X2-8).
const Set<String> kAccountGoneAuthCodes = <String>{
  'user_not_found',
  'session_not_found',
  'refresh_token_not_found',
};
