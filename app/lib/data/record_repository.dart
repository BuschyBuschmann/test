// Schreibwege der Patienten-App über die Warteschlange (Plan 8.4 Abhaken,
// 8.9 Termine): jede Änderung wird lokal sofort wirksam (macht die aufrufende
// Stelle) und hier als Eintrag eingereiht und angestoßen. Offline-fähig.
import 'dart:async';

import '../backend/outbox_sender.dart';
import '../logic/clock.dart';
import '../logic/framework.dart';
import '../logic/ids.dart';
import '../logic/json_support.dart';
import '../logic/outbox.dart';

class RecordRepository {
  RecordRepository({
    required this.sender,
    required this.clock,
    required this.patientId,
    String Function()? newId,
  }) : _newId = newId ?? newUuid;

  final OutboxSender sender;
  final Clock clock;
  final String patientId;
  final String Function() _newId;

  /// Sessions, deren Einfüge-Eintrag in dieser Sitzung schon eingereiht wurde.
  final Set<String> _sessionsQueued = <String>{};

  /// Gleichbleibende ID der Checklisten-Session eines Tages (Plan 8.4: „Geräte-ID
  /// je Tag“).
  String checklistSessionId(Object localDay) =>
      uuidFromSeed('session|$patientId|$localDay');

  /// Gleichbleibende ID des Ergebnisses „Position am Tag“, damit „Rückgängig“
  /// es ohne gespeicherten Zustand findet.
  String resultId(Object localDay, String planItemId) =>
      uuidFromSeed('result|$patientId|$localDay|$planItemId');

  /// Häkchen (Ablauf 3): legt bei Bedarf die Checklisten-Session des Tages an
  /// und das Ergebnis `done`. Reihenfolge: Session vor Ergebnis (FIFO).
  /// [todayItems] und [framework] bilden die Momentaufnahme der Session.
  Future<String> markDone({
    required Plan plan,
    required PlanItem item,
    required Exercise? exercise,
    required Object localDay,
    required List<PlanItem> todayItems,
    required Framework framework,
  }) async {
    final String sessionId = checklistSessionId(localDay);
    await _ensureSession(
      plan: plan,
      sessionId: sessionId,
      localDay: localDay,
      todayItems: todayItems,
      framework: framework,
    );
    final String id = resultId(localDay, item.id);
    await sender.enqueue(
      exerciseResultInsertEntry(
        entryId: _newId(),
        now: clock(),
        resultId: id,
        patientId: patientId,
        trainingSessionId: sessionId,
        localDay: localDay,
        status: 'done',
        planItemId: item.id,
        exerciseId: item.exerciseId,
        exerciseName: exercise?.name,
        setsDone: item.sets,
        repsDone: item.reps,
      ),
    );
    unawaited(sender.drain());
    return id;
  }

  /// Rückgängig am selben Tag (B-24): löscht das Ergebnis.
  Future<void> undoDone({
    required PlanItem item,
    required Object localDay,
  }) async {
    await sender.enqueue(
      exerciseResultDeleteEntry(
        entryId: _newId(),
        now: clock(),
        resultId: resultId(localDay, item.id),
      ),
    );
    unawaited(sender.drain());
  }

  Future<void> _ensureSession({
    required Plan plan,
    required String sessionId,
    required Object localDay,
    required List<PlanItem> todayItems,
    required Framework framework,
  }) async {
    if (_sessionsQueued.contains(sessionId)) return;
    final bool pending = sender.outbox.entries.any(
      (OutboxEntry e) =>
          e.kind == OutboxKind.trainingSessionUpsert &&
          e.payload['id'] == sessionId,
    );
    _sessionsQueued.add(sessionId);
    if (pending) return;
    final Phase? phase = plan.currentPhase;
    final DateTime now = clock();
    await sender.enqueue(
      trainingSessionEntry(
        entryId: _newId(),
        now: now,
        sessionId: sessionId,
        patientId: patientId,
        planId: plan.id,
        localDay: localDay,
        mode: 'checklist',
        phaseId: phase?.id,
        planVersion: plan.version,
        items: _snapshot(todayItems, framework),
        startedAt: now,
      ),
    );
  }

  List<Json> _snapshot(List<PlanItem> items, Framework framework) => <Json>[
    for (final PlanItem i in items)
      <String, Object?>{
        'plan_item_id': i.id,
        'exercise_id': i.exerciseId,
        'name': framework.exerciseById(i.exerciseId)?.name,
        'sets': i.sets,
        'reps': i.reps,
        'duration_sec': i.durationSec,
      },
  ];

  /// Eigener Termin (Plan 8.9): neu (ohne [appointmentId]) oder ändern.
  /// Liefert die ID.
  Future<String> saveAppointment({
    String? appointmentId,
    required DateTime startsAt,
    required String title,
    String? treaterId,
    String? location,
  }) async {
    final String id = appointmentId ?? _newId();
    await sender.enqueue(
      appointmentUpsertEntry(
        entryId: _newId(),
        now: clock(),
        appointmentId: id,
        patientId: patientId,
        startsAt: startsAt,
        title: title,
        treaterId: treaterId,
        location: location,
      ),
    );
    unawaited(sender.drain());
    return id;
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await sender.enqueue(
      appointmentDeleteEntry(
        entryId: _newId(),
        now: clock(),
        appointmentId: appointmentId,
      ),
    );
    unawaited(sender.drain());
  }
}
