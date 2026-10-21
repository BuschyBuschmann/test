// Supabase-Anbindung der Patienten-App hinter [PatientBackend] (Plan 5, 8).
// Nur hier und in den Dateien daneben wird `supabase_flutter` importiert
// (Regel C in Plan 12.3). Nicht gegen einen echten Stack ausgeführt (X2-8):
// die Abbildung von Zeilen und Fehlern ist unit-getestet, die Aufrufe selbst
// folgen den Migrationen unter `supabase/migrations/`.
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logic/account.dart';
import '../logic/backend_failure.dart';
import '../logic/framework.dart';
import '../logic/json_support.dart';
import '../logic/manny_look.dart';
import '../logic/outbox.dart';
import 'patient_backend.dart';
import 'row_mapping.dart';
import 'supabase_errors.dart';

class SupabasePatientBackend implements PatientBackend {
  SupabasePatientBackend(
    this._client, {
    this.requestTimeout = const Duration(seconds: 20),
  });

  final SupabaseClient _client;

  /// Zeitlimit je Anfrage (technischer Richtwert, Annahme).
  final Duration requestTimeout;

  Future<T> _guard<T>(Future<T> Function() op) =>
      guardBackend<T>(op, timeout: requestTimeout);

  Json _row(Object? r) => asJson(r, 'Zeile');

  List<Json> _rows(Object? r) {
    if (r is! List) unreadable('Liste erwartet');
    return <Json>[for (final Object? item in r) _row(item)];
  }

  Json _prefixed(Json payload) => <String, Object?>{
    for (final MapEntry<String, Object?> e in payload.entries)
      'p_${e.key}': e.value,
  };

  // -------------------------------------------------------------------------
  // Einlösen und Konto
  // -------------------------------------------------------------------------

  @override
  Future<RedeemResult> redeemInvitation(String normalizedCode) =>
      _guard(() async {
        if (_client.auth.currentSession == null) {
          await _client.auth.signInAnonymously();
        }
        final Object? answer = await _client.rpc(
          'redeem_invitation',
          params: <String, Object?>{'p_code': normalizedCode},
        );
        final RedeemResult? result = RedeemResult.fromWire(
          answer is String ? answer : null,
        );
        if (result == null) {
          throw const BackendFailure(
            FailureKind.rejected,
            message: 'unknown_redeem_result',
          );
        }
        return result;
      });

  @override
  Future<AccountInfo> fetchAccount() => _guard(() async {
    final PatientInfo patient = await _fetchPatient();
    final DateTime? boundAt = patient.boundAt;
    if (boundAt == null) throw const BindingLostException('not_bound');
    return AccountInfo(patientId: patient.id, boundAt: boundAt);
  });

  Future<PatientInfo> _fetchPatient() async {
    final List<Json> rows = _rows(
      await _client.from('patients').select(kPatientColumns).limit(1),
    );
    if (rows.isEmpty) throw const BindingLostException('no_patient_row');
    final PatientInfo patient = patientFromRow(rows.first);
    if (patient.status == PatientStatus.accessDeleted ||
        patient.status == PatientStatus.invited) {
      throw BindingLostException(patient.status.dbName);
    }
    return patient;
  }

  @override
  Future<void> acceptConsent(String kind, String version) => _guard(() async {
    await _client.rpc(
      'accept_consent',
      params: <String, Object?>{'p_kind': kind, 'p_version': version},
    );
  });

  @override
  Future<bool> hasConsent(String kind, String version) => _guard(() async {
    final List<Json> rows = _rows(
      await _client
          .from('consents')
          .select('id')
          .eq('kind', kind)
          .eq('version', version)
          .isFilter('revoked_at', null)
          .limit(1),
    );
    return rows.isNotEmpty;
  });

  @override
  Future<MannyLook?> fetchMannyLook() => _guard(() async {
    final Object? answer = await _client.rpc('get_my_manny_look');
    if (answer is! String) return null;
    for (final MannyLook look in MannyLook.values) {
      if (look.jsonName == answer) return look;
    }
    return null;
  });

  // -------------------------------------------------------------------------
  // Framework lesen (Plan 8.2): Spalten einzeln, RLS begrenzt auf den Patienten
  // -------------------------------------------------------------------------

  @override
  Future<Framework> fetchFramework() => _guard(() async {
    Framework? last;
    // Ändert der Physio den Plan während des Ladens, passen Phasen und
    // Positionen evtl. nicht zusammen: bis zu drei Versuche, bis die Version
    // vor und nach dem Lesen übereinstimmt.
    for (int attempt = 0; attempt < 3; attempt++) {
      final ({Framework framework, int? versionBefore, int? versionAfter}) r =
          await _fetchFrameworkOnce();
      last = r.framework;
      if (r.versionBefore == r.versionAfter) return last;
    }
    return last!;
  });

  Future<({Framework framework, int? versionBefore, int? versionAfter})>
  _fetchFrameworkOnce() async {
    final PatientInfo patient = await _fetchPatient();

    final List<Json> injuryRows = _rows(
      await _client
          .from('injuries')
          .select(kInjuryColumns)
          .eq('patient_id', patient.id)
          .isFilter('closed_on', null)
          .limit(1),
    );
    final Injury? injury = injuryRows.isEmpty
        ? null
        : injuryFromRow(injuryRows.first);

    Plan? plan;
    int? versionBefore;
    int? versionAfter;
    List<Exercise> exercises = const <Exercise>[];
    if (injury != null) {
      final List<Json> planRows = _rows(
        await _client
            .from('plans')
            .select(kPlanColumns)
            .eq('injury_id', injury.id)
            .limit(1),
      );
      if (planRows.isNotEmpty) {
        final Json planRow = planRows.first;
        versionBefore = reqInt(planRow, 'version');
        final String planId = reqString(planRow, 'id');
        final List<Json> phaseRows = _rows(
          await _client
              .from('phases')
              .select(kPhaseColumns)
              .eq('plan_id', planId)
              .order('position'),
        );
        final List<Json> itemRows = _rows(
          await _client
              .from('plan_items')
              .select(kPlanItemColumns)
              .eq('plan_id', planId)
              .order('position'),
        );
        plan = planFromRows(planRow, phaseRows, itemRows);
        final List<Json> after = _rows(
          await _client.from('plans').select('version').eq('id', planId),
        );
        versionAfter = after.isEmpty ? null : reqInt(after.first, 'version');

        final List<String> exerciseIds = <String>{
          for (final PlanItem i in plan.items) i.exerciseId,
        }.toList();
        if (exerciseIds.isNotEmpty) {
          exercises = <Exercise>[
            for (final Json r in _rows(
              await _client
                  .from('exercises')
                  .select(kExerciseColumns)
                  .inFilter('id', exerciseIds),
            ))
              exerciseFromRow(r),
          ];
        }
      }
    }

    final List<Treater> treaters = <Treater>[
      for (final Json r in _rows(
        await _client.from('treaters').select(kTreaterColumns).order('name'),
      ))
        treaterFromRow(r),
    ];
    final List<Appointment> appointments = <Appointment>[
      for (final Json r in _rows(
        await _client
            .from('appointments')
            .select(kAppointmentColumns)
            .order('starts_at'),
      ))
        appointmentFromRow(r),
    ];
    final List<HistoryEntry> history = <HistoryEntry>[
      for (final Json r in _rows(
        await _client
            .from('history_entries')
            .select(kHistoryColumns)
            .order('occurred_on'),
      ))
        historyFromRow(r),
    ];

    return (
      framework: Framework(
        patient: patient,
        injury: injury,
        plan: plan,
        exercises: exercises,
        treaters: treaters,
        appointments: appointments,
        history: history,
      ),
      versionBefore: versionBefore,
      versionAfter: versionAfter,
    );
  }

  // -------------------------------------------------------------------------
  // Warteschlange (Plan 8.11)
  // -------------------------------------------------------------------------

  /// Spalten, die der Patient an `training_sessions` aktualisieren darf
  /// (Spalten-Grant, Migration 06).
  static const List<String> _sessionEndColumns = <String>[
    'ended_at',
    'active_seconds',
    'ended_early',
    'streak_after',
  ];

  /// Spalten, die der Patient an `appointments` aktualisieren darf
  /// (Migration 03).
  static const List<String> _appointmentUpdateColumns = <String>[
    'treater_id',
    'starts_at',
    'title',
    'location',
  ];

  @override
  Future<void> send(OutboxEntry entry) => _guard(() async {
    final Json p = entry.payload;
    switch (entry.kind) {
      case OutboxKind.trainingSessionUpsert:
        // Einfügen ohne Ende-Spalten (`ON CONFLICT DO NOTHING`), danach nur die
        // erlaubten Ende-Spalten aktualisieren: ein Upsert mit allen Spalten
        // scheitert am Spalten-Grant (42501).
        await _insertIgnoringDuplicates('training_sessions', <String, Object?>{
          for (final MapEntry<String, Object?> e in p.entries)
            if (!_sessionEndColumns.contains(e.key)) e.key: e.value,
        });
        final Json end = <String, Object?>{
          for (final String c in _sessionEndColumns)
            if (p[c] != null) c: p[c],
        };
        if (end.isNotEmpty) {
          await _client
              .from('training_sessions')
              .update(end)
              .eq('id', reqString(p, 'id'));
        }
      case OutboxKind.exerciseResultInsert:
        await _insertIgnoringDuplicates('exercise_results', p);
      case OutboxKind.exerciseResultDelete:
        await _client
            .from('exercise_results')
            .delete()
            .eq('id', reqString(p, 'id'));
      case OutboxKind.sessionCheckupSubmit:
        await _client.rpc('submit_session_checkup', params: _prefixed(p));
      case OutboxKind.dailyCheckupSubmit:
        await _client.rpc('submit_daily_checkup', params: _prefixed(p));
      case OutboxKind.questionSubmit:
        await _client.rpc('ask_physio', params: _prefixed(p));
      case OutboxKind.appointmentUpsert:
        await _insertIgnoringDuplicates('appointments', p);
        await _client
            .from('appointments')
            .update(<String, Object?>{
              for (final String c in _appointmentUpdateColumns) c: p[c],
            })
            .eq('id', reqString(p, 'id'));
      case OutboxKind.appointmentDelete:
        await _client
            .from('appointments')
            .delete()
            .eq('id', reqString(p, 'id'));
      case OutboxKind.mannyLookSet:
        await _client.rpc('set_manny_look', params: _prefixed(p));
    }
  });

  Future<void> _insertIgnoringDuplicates(String table, Json row) async {
    await _client
        .from(table)
        .upsert(row, onConflict: 'id', ignoreDuplicates: true);
  }

  // -------------------------------------------------------------------------
  // Löschen, Sitzung
  // -------------------------------------------------------------------------

  @override
  Future<DeleteResult> deleteMyData() => _guard(() async {
    final Object? answer = await _client.rpc('delete_my_data');
    final DeleteResult? result = DeleteResult.fromWire(
      answer is String ? answer : null,
    );
    if (result == null) {
      // Unbekannte Antwort: nichts annehmen (Ergebnis unklar).
      throw const BackendFailure(
        FailureKind.timeout,
        message: 'unknown_delete_result',
      );
    }
    return result;
  });

  @override
  Future<SessionRefresh> refreshSession() async {
    try {
      await _client.auth.refreshSession().timeout(requestTimeout);
      return SessionRefresh.refreshed;
    } on AuthSessionMissingException {
      return SessionRefresh.accountGone;
    } on AuthRetryableFetchException {
      return SessionRefresh.unavailable;
    } on AuthException catch (e) {
      return kAccountGoneAuthCodes.contains(e.code)
          ? SessionRefresh.accountGone
          : SessionRefresh.unavailable;
    } on Exception {
      return SessionRefresh.unavailable;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } on Exception {
      // Ist das Konto schon gelöscht, schlägt die Abmeldung am Server fehl;
      // lokal ist die Sitzung trotzdem verworfen.
    }
  }
}
