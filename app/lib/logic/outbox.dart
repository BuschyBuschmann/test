// Ausgangswarteschlange (Plan 8.11, m-4): Einträge, Reihenfolge, Fehlerklassen
// und Wartezeiten. Reine Dart-Logik; Senden steht in `lib/backend/`,
// Speichern in `lib/data/outbox_store.dart`.
//
// Reihenfolge: je Gerät strikt in Einfügereihenfolge (FIFO). Ein Eintrag mit
// dauerhaftem Fehler wird verworfen und blockiert die folgenden nicht; ein
// vorübergehender Fehler beendet die Runde, damit abhängige Einträge (ein
// Ergebnis gehört zu einer Session) nie vor ihrem Vorgänger gesendet werden.
import 'backend_failure.dart';
import 'json_support.dart';

/// Arten von Einträgen (Plan 8.11). Die Namen im Dokument sind die
/// `wire`-Texte.
enum OutboxKind {
  trainingSessionUpsert('training_session_upsert'),
  exerciseResultInsert('exercise_result_insert'),
  exerciseResultDelete('exercise_result_delete'),
  sessionCheckupSubmit('session_checkup_submit'),
  dailyCheckupSubmit('daily_checkup_submit'),
  questionSubmit('question_submit'),
  appointmentUpsert('appointment_upsert'),
  appointmentDelete('appointment_delete'),

  /// Manny-Look im Konto (O-41, L3).
  mannyLookSet('manny_look_set');

  const OutboxKind(this.wire);

  final String wire;

  static OutboxKind? fromWire(String? value) {
    for (final OutboxKind k in OutboxKind.values) {
      if (k.wire == value) return k;
    }
    return null;
  }
}

class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.deferred = false,
    this.lastError,
  });

  /// Unlesbare Einträge wirft [UnreadableDataException]; der Speicher
  /// überspringt sie einzeln (ein kaputter Eintrag darf die anderen nicht
  /// mitreißen).
  factory OutboxEntry.fromJson(Json j) {
    final OutboxKind? kind = OutboxKind.fromWire(reqString(j, 'kind'));
    if (kind == null) unreadable('outbox.kind: unbekannt');
    return OutboxEntry(
      id: reqString(j, 'id'),
      kind: kind,
      payload: reqJson(j, 'payload'),
      createdAt: reqInstant(j, 'createdAt'),
      attempts: inRange(
        optInt(j, 'attempts', 0),
        0,
        1 << 30,
        'outbox.attempts',
      ),
      deferred: optBool(j, 'deferred', false),
      lastError: optStringOrNull(j, 'lastError'),
    );
  }

  /// Eindeutige ID des Eintrags (nicht die der Datenbankzeile).
  final String id;
  final OutboxKind kind;

  /// Spalten bzw. Funktionsparameter, siehe die Bauer-Funktionen unten.
  final Json payload;
  final DateTime createdAt;
  final int attempts;

  /// Zurückgestellt (`invalid_local_day`): bleibt gespeichert, blockiert
  /// nichts, wird bei Start und neuer Verbindung erneut versucht.
  final bool deferred;
  final String? lastError;

  OutboxEntry copyWith({int? attempts, bool? deferred, String? lastError}) =>
      OutboxEntry(
        id: id,
        kind: kind,
        payload: payload,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        deferred: deferred ?? this.deferred,
        lastError: lastError ?? this.lastError,
      );

  Json toJson() => <String, Object?>{
    'id': id,
    'kind': kind.wire,
    'payload': payload,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'attempts': attempts,
    'deferred': deferred,
    'lastError': lastError,
  };
}

/// Die Warteschlange als unveränderlicher Wert (FIFO).
class Outbox {
  Outbox([Iterable<OutboxEntry> entries = const <OutboxEntry>[]])
    : entries = List<OutboxEntry>.unmodifiable(entries);

  final List<OutboxEntry> entries;

  bool get isEmpty => entries.isEmpty;
  int get length => entries.length;

  /// Zurückgestellte Einträge (NIT-2: dem Patienten dezent anzeigen).
  List<OutboxEntry> get deferred => <OutboxEntry>[
    for (final OutboxEntry e in entries)
      if (e.deferred) e,
  ];

  int get pendingCount => entries.length - deferred.length;

  Outbox enqueue(OutboxEntry entry) => Outbox(<OutboxEntry>[...entries, entry]);

  Outbox remove(String entryId) => Outbox(<OutboxEntry>[
    for (final OutboxEntry e in entries)
      if (e.id != entryId) e,
  ]);

  Outbox replace(OutboxEntry entry) => Outbox(<OutboxEntry>[
    for (final OutboxEntry e in entries) e.id == entry.id ? entry : e,
  ]);

  OutboxEntry? byId(String entryId) {
    for (final OutboxEntry e in entries) {
      if (e.id == entryId) return e;
    }
    return null;
  }

  /// Nächster Eintrag in Einfügereihenfolge, der nicht in [skip] steht und
  /// (bei [includeDeferred] `false`) nicht zurückgestellt ist.
  OutboxEntry? next({
    Set<String> skip = const <String>{},
    bool includeDeferred = false,
  }) {
    for (final OutboxEntry e in entries) {
      if (skip.contains(e.id)) continue;
      if (e.deferred && !includeDeferred) continue;
      return e;
    }
    return null;
  }

  Json toJson() => <String, Object?>{
    'schema': 1,
    'entries': <Json>[for (final OutboxEntry e in entries) e.toJson()],
  };
}

/// Liest das Warteschlangen-Dokument. Unlesbare einzelne Einträge werden
/// übersprungen und gezählt; ein unbrauchbares Gesamtdokument wirft
/// [UnreadableDataException].
({Outbox outbox, int skipped}) decodeOutbox(Object? decoded) {
  final Json doc = asJson(decoded, 'Warteschlange');
  final Object? list = doc['entries'];
  if (list == null) return (outbox: Outbox(), skipped: 0);
  if (list is! List) unreadable('entries: Liste erwartet');
  final List<OutboxEntry> out = <OutboxEntry>[];
  int skipped = 0;
  for (final Object? item in list) {
    try {
      out.add(OutboxEntry.fromJson(asJson(item, 'entry')));
    } on UnreadableDataException {
      skipped++;
    }
  }
  return (outbox: Outbox(out), skipped: skipped);
}

// ---------------------------------------------------------------------------
// Fehlerklassen (Plan 8.11)
// ---------------------------------------------------------------------------

/// Was mit einem Eintrag nach einer Antwort geschieht.
enum OutboxVerdict {
  /// Gesendet oder idempotent bereits vorhanden: entfernen.
  success,

  /// Später erneut (Netz, Zeitüberschreitung, 5xx, `40001`, `40P01`); beendet
  /// die Runde, damit die Reihenfolge erhalten bleibt.
  retryLater,

  /// 401: erst Sitzung erneuern, dann erneut.
  refreshSession,

  /// `invalid_local_day`: zurückstellen, nicht verwerfen.
  defer,

  /// Dauerhaft (`42501`, andere 4xx): verwerfen; blockiert die folgenden nicht.
  discard,
}

/// SQLSTATEs, bei denen die Datenbank selbst zum Wiederholen rät: Serialisierungs-
/// fehler und Deadlock. `40P01` ist wie `40001` wiederholbar (L3-Hinweis aus
/// `supabase/tests/README.md`).
const Set<String> kRetryableSqlStates = <String>{'40001', '40P01'};

/// Ordnet einen Fehler ein. Reihenfolge der Regeln: fachliche Meldung und
/// SQLSTATE vor der HTTP-Art, damit ein `23505` oder `40P01` unabhängig vom
/// Statuscode richtig behandelt wird.
OutboxVerdict classifyFailure(OutboxKind kind, BackendFailure failure) {
  if (failure.hasMessage('invalid_local_day')) return OutboxVerdict.defer;
  if (failure.sqlState == '23505') return OutboxVerdict.success;
  if (kind == OutboxKind.dailyCheckupSubmit &&
      failure.hasMessage('already_submitted')) {
    return OutboxVerdict.success;
  }
  if (kRetryableSqlStates.contains(failure.sqlState)) {
    return OutboxVerdict.retryLater;
  }
  switch (failure.kind) {
    case FailureKind.auth:
      return OutboxVerdict.refreshSession;
    case FailureKind.unreachable:
    case FailureKind.timeout:
    case FailureKind.server:
      return OutboxVerdict.retryLater;
    case FailureKind.rejected:
      return OutboxVerdict.discard;
  }
}

/// Wartezeit nach dem [attempts]-ten gescheiterten Versuch: 2, 4, 8 … Sekunden,
/// höchstens 5 Minuten (technischer Richtwert, Annahme; der Plan verlangt nur
/// „steigende Wartezeit“).
Duration backoffFor(int attempts) {
  final int a = attempts < 1 ? 1 : attempts;
  final int seconds = a >= 8 ? 300 : (1 << a);
  return Duration(seconds: seconds > 300 ? 300 : seconds);
}

// ---------------------------------------------------------------------------
// Bauer-Funktionen: Form der Nutzlast je Art
//
// Die Schlüssel sind die Spaltennamen der Tabellen (snake_case) bzw. die
// Parameternamen der Funktionen ohne das Präfix `p_`. `patient_id` steht in der
// Nutzlast, weil die RLS-Prüfung `patient_id = app.current_patient_id()`
// verlangt; die Warteschlange gehört zur aktuellen Bindung und wird bei
// Neubindung verworfen (B-11).
// ---------------------------------------------------------------------------

String _day(Object day) => day.toString();

OutboxEntry _entry(
  String entryId,
  OutboxKind kind,
  Json payload,
  DateTime now,
) => OutboxEntry(
  id: entryId,
  kind: kind,
  payload: payload,
  createdAt: now.toUtc(),
);

/// Start oder Ende einer Session (`training_sessions`). Ohne Ende-Felder nur
/// Einfügen; mit Ende-Feldern zusätzlich Aktualisieren der vier erlaubten
/// Spalten (`ended_at`, `active_seconds`, `ended_early`, `streak_after`).
/// `mode`: `guided` oder `checklist`.
OutboxEntry trainingSessionEntry({
  required String entryId,
  required DateTime now,
  required String sessionId,
  required String patientId,
  required String planId,
  required Object localDay,
  required String mode,
  String? phaseId,
  int? planVersion,
  List<Json> items = const <Json>[],
  DateTime? startedAt,
  DateTime? endedAt,
  int? activeSeconds,
  bool? endedEarly,
  int? streakAfter,
}) => _entry(entryId, OutboxKind.trainingSessionUpsert, <String, Object?>{
  'id': sessionId,
  'patient_id': patientId,
  'plan_id': planId,
  'local_day': _day(localDay),
  'phase_id': phaseId,
  'plan_version': planVersion,
  'items': items,
  'mode': mode,
  'started_at': startedAt?.toUtc().toIso8601String(),
  'ended_at': endedAt?.toUtc().toIso8601String(),
  'active_seconds': activeSeconds,
  'ended_early': endedEarly,
  'streak_after': streakAfter,
}, now);

/// Ergebnis einer Übung (`exercise_results`), `status`: `done` oder `skipped`.
OutboxEntry exerciseResultInsertEntry({
  required String entryId,
  required DateTime now,
  required String resultId,
  required String patientId,
  required String trainingSessionId,
  required Object localDay,
  required String status,
  String? planItemId,
  String? exerciseId,
  String? exerciseName,
  int? setsDone,
  int? repsDone,
}) => _entry(entryId, OutboxKind.exerciseResultInsert, <String, Object?>{
  'id': resultId,
  'patient_id': patientId,
  'training_session_id': trainingSessionId,
  'local_day': _day(localDay),
  'plan_item_id': planItemId,
  'exercise_id': exerciseId,
  'exercise_name': exerciseName,
  'status': status,
  'sets_done': setsDone,
  'reps_done': repsDone,
  'logged_at': now.toUtc().toIso8601String(),
}, now);

/// Rückgängig am selben Tag (B-24).
OutboxEntry exerciseResultDeleteEntry({
  required String entryId,
  required DateTime now,
  required String resultId,
}) => _entry(entryId, OutboxKind.exerciseResultDelete, <String, Object?>{
  'id': resultId,
}, now);

/// `submit_daily_checkup` (L5).
OutboxEntry dailyCheckupEntry({
  required String entryId,
  required DateTime now,
  required String checkupId,
  required Object localDay,
  required int pain,
  required int wellbeing,
  required int motivation,
  required int swelling,
  required String limitations,
  required int mood,
}) => _entry(entryId, OutboxKind.dailyCheckupSubmit, <String, Object?>{
  'id': checkupId,
  'local_day': _day(localDay),
  'pain': pain,
  'wellbeing': wellbeing,
  'motivation': motivation,
  'swelling': swelling,
  'limitations': limitations,
  'mood': mood,
}, now);

/// `submit_session_checkup` (L4).
OutboxEntry sessionCheckupEntry({
  required String entryId,
  required DateTime now,
  required String checkupId,
  required String trainingSessionId,
  required Object localDay,
  required int rating,
  List<Json> items = const <Json>[],
}) => _entry(entryId, OutboxKind.sessionCheckupSubmit, <String, Object?>{
  'id': checkupId,
  'training_session_id': trainingSessionId,
  'local_day': _day(localDay),
  'rating': rating,
  'items': items,
}, now);

/// `ask_physio` (L5).
OutboxEntry questionEntry({
  required String entryId,
  required DateTime now,
  required String questionId,
  required String text,
}) => _entry(entryId, OutboxKind.questionSubmit, <String, Object?>{
  'id': questionId,
  'text': text,
}, now);

/// Eigener Termin (`appointments`): Einfügen, bei vorhandener ID zusätzlich
/// Aktualisieren von `treater_id`, `starts_at`, `title`, `location`.
OutboxEntry appointmentUpsertEntry({
  required String entryId,
  required DateTime now,
  required String appointmentId,
  required String patientId,
  required DateTime startsAt,
  required String title,
  String? treaterId,
  String? location,
}) => _entry(entryId, OutboxKind.appointmentUpsert, <String, Object?>{
  'id': appointmentId,
  'patient_id': patientId,
  'treater_id': treaterId,
  'starts_at': startsAt.toUtc().toIso8601String(),
  'title': title,
  'location': location,
}, now);

OutboxEntry appointmentDeleteEntry({
  required String entryId,
  required DateTime now,
  required String appointmentId,
}) => _entry(entryId, OutboxKind.appointmentDelete, <String, Object?>{
  'id': appointmentId,
}, now);

/// `set_manny_look(look)`; `look`: `brille` oder `ohne`.
OutboxEntry mannyLookSetEntry({
  required String entryId,
  required DateTime now,
  required String look,
}) => _entry(entryId, OutboxKind.mannyLookSet, <String, Object?>{
  'look': look,
}, now);
