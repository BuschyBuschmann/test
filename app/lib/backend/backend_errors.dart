// Gemeinsame Fehlerbehandlung über der Schnittstelle (Plan 8.11: 401 → erst
// Sitzung erneuern; scheitert die Erneuerung, weil das Konto nicht mehr
// existiert → Bindung gelöst).
import '../logic/account.dart';
import '../logic/backend_failure.dart';
import 'patient_backend.dart';

/// Führt [operation] aus. Meldet das Backend einen 401, wird die Sitzung
/// **einmal** erneuert und die Operation wiederholt. Existiert das Konto nicht
/// mehr, wird [BindingLostException] geworfen; ist die Erneuerung nicht
/// möglich, bleibt es beim ursprünglichen [BackendFailure].
Future<T> withSessionRefresh<T>(
  PatientBackend backend,
  Future<T> Function() operation,
) async {
  try {
    return await operation();
  } on BackendFailure catch (failure) {
    if (failure.kind != FailureKind.auth) rethrow;
    switch (await backend.refreshSession()) {
      case SessionRefresh.refreshed:
        return operation();
      case SessionRefresh.accountGone:
        throw const BindingLostException('Konto existiert nicht mehr');
      case SessionRefresh.unavailable:
        rethrow;
    }
  }
}
