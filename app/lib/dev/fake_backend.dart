// Backend ohne Netzwerk (Plan 2.1 Regel 4): bildet die Antworten des Servers
// nach, soweit die Datenschicht sie braucht — Idempotenz über Geräte-IDs, die
// Tagesgrenzen für Check-ups (Plan 6.7 Nr. 3), Fremdschlüssel einer Session —
// und lässt sich per Feldern und `scriptedFailures` zum Scheitern bringen.
// Für Tests, Prüfumgebung und die Szenarien der Patienten-App.
import '../backend/patient_backend.dart';
import '../logic/account.dart';
import '../logic/backend_failure.dart';
import '../logic/clock.dart';
import '../logic/framework.dart';
import '../logic/manny_look.dart';
import '../logic/outbox.dart';

class FakePatientBackend implements PatientBackend {
  FakePatientBackend({
    this.framework,
    this.patientId = 'patient-1',
    DateTime? boundAt,
    DateTime Function()? serverNow,
  }) : boundAt = boundAt ?? DateTime.utc(2026, 7, 1, 8),
       _serverNow = serverNow ?? (() => DateTime.now().toUtc());

  // --- Zustand des „Servers“ ----------------------------------------------

  Framework? framework;
  final String patientId;
  DateTime boundAt;
  final DateTime Function() _serverNow;

  /// `false`: es gibt keine Bindung ([BindingLostException]).
  bool bound = true;
  PatientStatus status = PatientStatus.active;

  /// Manny-Look im Konto (`null` = nicht übertragen).
  MannyLook? accountLook;

  final Set<String> sessionIds = <String>{};
  final Set<String> resultIds = <String>{};
  final Set<String> appointmentIds = <String>{};
  final Map<String, Map<String, Object?>> dailyCheckups =
      <String, Map<String, Object?>>{};
  final Set<String> checkupDays = <String>{};
  final List<String> consents = <String>[];

  // --- Aufzeichnung ---------------------------------------------------------

  /// Erfolgreich verarbeitete Einträge in Reihenfolge.
  final List<OutboxEntry> sent = <OutboxEntry>[];

  /// Alle Aufrufe in Reihenfolge (`redeem`, `fetchFramework`, `send:<kind>` …).
  final List<String> calls = <String>[];

  // --- Skripte --------------------------------------------------------------

  RedeemResult redeemResult = RedeemResult.ok;
  Object? redeemError;
  Object? fetchFrameworkError;
  Object? fetchLookError;
  Object? deleteError;
  DeleteResult deleteResult = DeleteResult.ok;
  SessionRefresh refreshResult = SessionRefresh.refreshed;
  bool deleted = false;

  /// Fehler für die nächsten `send`-Aufrufe (einer je Aufruf, `null` = Erfolg).
  /// Wird der Vorrat leer, gelten die Serverregeln.
  final List<Object?> scriptedFailures = <Object?>[];

  /// Wird vor jedem `send` aufgerufen (z. B. um Nebenläufigkeit zu prüfen).
  Future<void> Function(OutboxEntry entry)? onSend;

  // --- Schnittstelle --------------------------------------------------------

  @override
  Future<RedeemResult> redeemInvitation(String normalizedCode) async {
    calls.add('redeem');
    if (redeemError != null) throw redeemError!;
    return redeemResult;
  }

  @override
  Future<AccountInfo> fetchAccount() async {
    calls.add('fetchAccount');
    if (!bound || deleted) throw const BindingLostException('fake');
    return AccountInfo(patientId: patientId, boundAt: boundAt);
  }

  @override
  Future<Framework> fetchFramework() async {
    calls.add('fetchFramework');
    if (fetchFrameworkError != null) throw fetchFrameworkError!;
    if (!bound || deleted) throw const BindingLostException('fake');
    final Framework? f = framework;
    if (f == null) throw const BindingLostException('kein Framework');
    return f;
  }

  @override
  Future<void> acceptConsent(String kind, String version) async {
    calls.add('acceptConsent');
    consents.add('$kind:$version');
  }

  @override
  Future<MannyLook?> fetchMannyLook() async {
    calls.add('fetchMannyLook');
    if (fetchLookError != null) throw fetchLookError!;
    return accountLook;
  }

  @override
  Future<void> send(OutboxEntry entry) async {
    calls.add('send:${entry.kind.wire}');
    await onSend?.call(entry);
    if (scriptedFailures.isNotEmpty) {
      final Object? next = scriptedFailures.removeAt(0);
      if (next != null) throw next;
    } else {
      _applyServerRules(entry);
    }
    _record(entry);
    sent.add(entry);
  }

  void _applyServerRules(OutboxEntry entry) {
    final Map<String, Object?> p = entry.payload;
    switch (entry.kind) {
      case OutboxKind.exerciseResultInsert:
        if (!sessionIds.contains(p['training_session_id'])) {
          throw const BackendFailure(
            FailureKind.rejected,
            sqlState: '23503',
            message: 'foreign key',
          );
        }
      case OutboxKind.dailyCheckupSubmit:
        final LocalDay? day = LocalDay.tryParse('${p['local_day']}');
        if (day == null || !isQueueDayAccepted(day, boundAt, _serverNow())) {
          throw const BackendFailure(
            FailureKind.rejected,
            sqlState: '22023',
            message: 'invalid_local_day',
          );
        }
        final String id = '${p['id']}';
        if (!dailyCheckups.containsKey(id) && checkupDays.contains('$day')) {
          throw const BackendFailure(
            FailureKind.rejected,
            sqlState: 'P0001',
            message: 'already_submitted',
          );
        }
      default:
        break;
    }
  }

  void _record(OutboxEntry entry) {
    final Map<String, Object?> p = entry.payload;
    switch (entry.kind) {
      case OutboxKind.trainingSessionUpsert:
        sessionIds.add('${p['id']}');
      case OutboxKind.exerciseResultInsert:
        resultIds.add('${p['id']}');
      case OutboxKind.exerciseResultDelete:
        resultIds.remove('${p['id']}');
      case OutboxKind.appointmentUpsert:
        appointmentIds.add('${p['id']}');
      case OutboxKind.appointmentDelete:
        appointmentIds.remove('${p['id']}');
      case OutboxKind.dailyCheckupSubmit:
        dailyCheckups['${p['id']}'] = p;
        checkupDays.add('${p['local_day']}');
      case OutboxKind.mannyLookSet:
        accountLook = MannyLook.fromJson(p['look']);
      case OutboxKind.sessionCheckupSubmit:
      case OutboxKind.questionSubmit:
        break;
    }
  }

  @override
  Future<DeleteResult> deleteMyData() async {
    calls.add('deleteMyData');
    if (deleteError != null) throw deleteError!;
    deleted = true;
    accountLook = null;
    return deleteResult;
  }

  @override
  Future<SessionRefresh> refreshSession() async {
    calls.add('refreshSession');
    return refreshResult;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
  }
}

/// Untergrenze/Obergrenze für Warteschlangen-Einträge mit Tagesprüfung
/// (`submit_daily_checkup`, Plan 6.7 Nr. 3): Bindungstag − 1 ≤ `local_day` ≤
/// UTC-Datum + 1. Kein Höchstalter.
bool isQueueDayAccepted(
  LocalDay day,
  DateTime boundAtUtc,
  DateTime serverNowUtc,
) {
  final DateTime b = boundAtUtc.toUtc();
  final DateTime n = serverNowUtc.toUtc();
  final LocalDay lower = LocalDay(b.year, b.month, b.day).addDays(-1);
  final LocalDay upper = LocalDay(n.year, n.month, n.day).addDays(1);
  return !day.isBefore(lower) && !day.isAfter(upper);
}

/// Sofortige Aufrufe (Plan 6.7 Nr. 3): ±1 Tag um das UTC-Datum.
bool isImmediateDayAccepted(LocalDay day, DateTime serverNowUtc) {
  final DateTime n = serverNowUtc.toUtc();
  final LocalDay utc = LocalDay(n.year, n.month, n.day);
  return !day.isBefore(utc.addDays(-1)) && !day.isAfter(utc.addDays(1));
}
