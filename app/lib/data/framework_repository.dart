// Framework laden (Plan 8.2): vom Backend, mit Zwischenspeicher als Rückfall.
//
// - Erfolg: Zwischenspeicher aktualisieren, Ergebnis „aktuell“.
// - Fehler oder offline: Zwischenspeicher mit „nicht aktuell“ ([stale]); ohne
//   Zwischenspeicher [FrameworkLoadException] (Fehlerzustand mit „Nochmal
//   versuchen“).
// - Bindung gelöst (`access_deleted`, Konto weg): [BindingLostException]
//   durchreichen; die aufrufende Stelle löscht die lokalen Daten.
import '../backend/backend_errors.dart';
import '../backend/patient_backend.dart';
import '../logic/backend_failure.dart';
import '../logic/clock.dart';
import '../logic/framework.dart';
import 'framework_cache.dart';

class FrameworkLoad {
  const FrameworkLoad({
    required this.framework,
    required this.loadedAt,
    required this.stale,
  });

  final Framework framework;

  /// Zeitpunkt des Ladens vom Server (UTC); bei [stale] der des Zwischenspeichers.
  final DateTime loadedAt;

  /// `true`: Zwischenspeicher, Hinweis „nicht aktuell“.
  final bool stale;
}

class FrameworkLoadException implements Exception {
  const FrameworkLoadException(this.cause);

  final BackendFailure cause;

  @override
  String toString() => 'FrameworkLoadException($cause)';
}

abstract class FrameworkRepository {
  /// [expectedPatientId]: Konto der App; ein Zwischenspeicher eines anderen
  /// Patienten wird verworfen.
  Future<FrameworkLoad> load({String? expectedPatientId});
}

class BackendFrameworkRepository implements FrameworkRepository {
  BackendFrameworkRepository({
    required this.backend,
    required this.cache,
    required this.clock,
  });

  final PatientBackend backend;
  final FrameworkCache cache;
  final Clock clock;

  @override
  Future<FrameworkLoad> load({String? expectedPatientId}) async {
    try {
      final Framework framework = await withSessionRefresh<Framework>(
        backend,
        backend.fetchFramework,
      );
      if (framework.patient.status == PatientStatus.accessDeleted) {
        throw const BindingLostException('access_deleted');
      }
      final DateTime now = clock().toUtc();
      await cache.write(framework, now);
      return FrameworkLoad(framework: framework, loadedAt: now, stale: false);
    } on BackendFailure catch (failure) {
      final CachedFramework? cached = await cache.read();
      if (cached != null &&
          (expectedPatientId == null ||
              cached.framework.patient.id == expectedPatientId)) {
        return FrameworkLoad(
          framework: cached.framework,
          loadedAt: cached.savedAt,
          stale: true,
        );
      }
      throw FrameworkLoadException(failure);
    }
  }
}
