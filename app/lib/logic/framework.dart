// Patienten-Framework (Plan 8.2): Verletzung, Plan mit Phasen und Positionen,
// Übungen, Akte. Reine Datenmodelle mit JSON für den Zwischenspeicher
// (`curaone.framework.v1`). Die JSON-Form hier ist die der App (camelCase);
// die Abbildung der Datenbankzeilen liegt in `lib/backend/`.
import 'clock.dart';
import 'json_support.dart';

/// Schmerzschwelle für die Kürzung des Tagesprogramms (E-28, Plan 8.2/8.7):
/// kein Geheimnis, gilt in der App und für `fallbackToday` (L5). Die
/// Warnzeichen-Schwellen (O-2) bleiben serverseitig.
const int kPainShorteningThreshold = 6;

/// Konto-Status des Patienten (Spalte `patients.status`).
enum PatientStatus {
  invited,
  active,
  deleting,
  accessDeleted;

  static PatientStatus? fromDb(String? value) {
    switch (value) {
      case 'invited':
        return PatientStatus.invited;
      case 'active':
        return PatientStatus.active;
      case 'deleting':
        return PatientStatus.deleting;
      case 'access_deleted':
        return PatientStatus.accessDeleted;
    }
    return null;
  }

  String get dbName {
    switch (this) {
      case PatientStatus.invited:
        return 'invited';
      case PatientStatus.active:
        return 'active';
      case PatientStatus.deleting:
        return 'deleting';
      case PatientStatus.accessDeleted:
        return 'access_deleted';
    }
  }
}

class PatientInfo {
  const PatientInfo({
    required this.id,
    required this.firstName,
    this.lastName,
    this.status = PatientStatus.active,
    this.boundAt,
  });

  factory PatientInfo.fromJson(Json j) {
    final PatientStatus? status = PatientStatus.fromDb(
      optString(j, 'status', 'active'),
    );
    if (status == null) unreadable('patient.status: unbekannter Wert');
    return PatientInfo(
      id: reqString(j, 'id'),
      firstName: reqString(j, 'firstName'),
      lastName: optStringOrNull(j, 'lastName'),
      status: status,
      boundAt: optInstant(j, 'boundAt'),
    );
  }

  final String id;
  final String firstName;
  final String? lastName;
  final PatientStatus status;
  final DateTime? boundAt;

  Json toJson() => <String, Object?>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'status': status.dbName,
    'boundAt': boundAt?.toUtc().toIso8601String(),
  };
}

class Injury {
  const Injury({
    required this.id,
    required this.label,
    required this.referenceDate,
    required this.startedOn,
    this.closedOn,
  });

  factory Injury.fromJson(Json j) => Injury(
    id: reqString(j, 'id'),
    label: reqString(j, 'label'),
    referenceDate: reqDay(j, 'referenceDate'),
    startedOn: reqDay(j, 'startedOn'),
    closedOn: optDay(j, 'closedOn'),
  );

  final String id;
  final String label;

  /// Bezugsdatum für „Woche N“ (Plan 8.3 Regel 10).
  final LocalDay referenceDate;
  final LocalDay startedOn;

  /// `null` = aktive Verletzung.
  final LocalDay? closedOn;

  bool get isActive => closedOn == null;

  Json toJson() => <String, Object?>{
    'id': id,
    'label': label,
    'referenceDate': referenceDate.toString(),
    'startedOn': startedOn.toString(),
    'closedOn': closedOn?.toString(),
  };
}

class Phase {
  const Phase({
    required this.id,
    required this.position,
    required this.title,
    required this.plannedWeeks,
  });

  factory Phase.fromJson(Json j) => Phase(
    id: reqString(j, 'id'),
    position: reqInt(j, 'position'),
    title: reqString(j, 'title'),
    plannedWeeks: inRange(reqInt(j, 'plannedWeeks'), 1, 52, 'plannedWeeks'),
  );

  final String id;

  /// Reihenfolge im Plan (aufsteigend, ab 0).
  final int position;
  final String title;

  /// 1–52 (Datenbank-`CHECK`).
  final int plannedWeeks;

  Json toJson() => <String, Object?>{
    'id': id,
    'position': position,
    'title': title,
    'plannedWeeks': plannedWeeks,
  };
}

/// Freischaltung einer Position (Plan 6.7).
enum Release {
  active,
  prepared;

  static Release? fromDb(String? value) {
    for (final Release r in Release.values) {
      if (r.name == value) return r;
    }
    return null;
  }
}

class PlanItem {
  const PlanItem({
    required this.id,
    required this.phaseId,
    required this.exerciseId,
    required this.position,
    this.sets,
    this.reps,
    this.durationSec,
    this.weightKg,
    this.pauseSec,
    this.loadNote,
    this.release = Release.active,
    this.releaseOn,
    this.releaseWithPhaseId,
    this.easierVariantOf,
  });

  factory PlanItem.fromJson(Json j) {
    final Release? release = Release.fromDb(optString(j, 'release', 'active'));
    if (release == null) unreadable('planItem.release: unbekannter Wert');
    return PlanItem(
      id: reqString(j, 'id'),
      phaseId: reqString(j, 'phaseId'),
      exerciseId: reqString(j, 'exerciseId'),
      position: reqInt(j, 'position'),
      sets: optIntOrNull(j, 'sets'),
      reps: optIntOrNull(j, 'reps'),
      durationSec: optIntOrNull(j, 'durationSec'),
      weightKg: optDoubleOrNull(j, 'weightKg'),
      pauseSec: optIntOrNull(j, 'pauseSec'),
      loadNote: optStringOrNull(j, 'loadNote'),
      release: release,
      releaseOn: optDay(j, 'releaseOn'),
      releaseWithPhaseId: optStringOrNull(j, 'releaseWithPhaseId'),
      easierVariantOf: optStringOrNull(j, 'easierVariantOf'),
    );
  }

  final String id;
  final String phaseId;
  final String exerciseId;
  final int position;
  final int? sets;
  final int? reps;

  /// Dauer je Satz in Sekunden (O-17).
  final int? durationSec;
  final double? weightKg;

  /// Pause des Physios in Sekunden; ohne Angabe gilt 60 s (Plan 8.4).
  final int? pauseSec;
  final String? loadNote;
  final Release release;
  final LocalDay? releaseOn;
  final String? releaseWithPhaseId;

  /// Leichtere Variante (E-30): ID der Position, die diese ersetzt.
  final String? easierVariantOf;

  Json toJson() => <String, Object?>{
    'id': id,
    'phaseId': phaseId,
    'exerciseId': exerciseId,
    'position': position,
    'sets': sets,
    'reps': reps,
    'durationSec': durationSec,
    'weightKg': weightKg,
    'pauseSec': pauseSec,
    'loadNote': loadNote,
    'release': release.name,
    'releaseOn': releaseOn?.toString(),
    'releaseWithPhaseId': releaseWithPhaseId,
    'easierVariantOf': easierVariantOf,
  };
}

class Plan {
  Plan({
    required this.id,
    required this.injuryId,
    required this.version,
    required this.currentPhaseId,
    required this.closed,
    required List<Phase> phases,
    required List<PlanItem> items,
  }) : phases = List<Phase>.unmodifiable(
         List<Phase>.of(phases)
           ..sort((Phase a, Phase b) => a.position.compareTo(b.position)),
       ),
       items = List<PlanItem>.unmodifiable(
         List<PlanItem>.of(items)
           ..sort((PlanItem a, PlanItem b) => a.position.compareTo(b.position)),
       );

  factory Plan.fromJson(Json j) => Plan(
    id: reqString(j, 'id'),
    injuryId: reqString(j, 'injuryId'),
    version: reqInt(j, 'version'),
    currentPhaseId: optStringOrNull(j, 'currentPhaseId'),
    closed: optBool(j, 'closed', false),
    phases: <Phase>[
      for (final Json p in reqJsonList(j, 'phases')) Phase.fromJson(p),
    ],
    items: <PlanItem>[
      for (final Json i in reqJsonList(j, 'items')) PlanItem.fromJson(i),
    ],
  );

  final String id;
  final String injuryId;

  /// Erhöht sich bei jeder Planänderung (Heute lädt dann neu, Plan 6.4).
  final int version;
  final String? currentPhaseId;
  final bool closed;

  /// Nach `position` sortiert.
  final List<Phase> phases;

  /// Nach `position` sortiert (Physio-Reihenfolge, gilt je Phase).
  final List<PlanItem> items;

  /// Aktuelle Phase. Fehlt die Angabe oder passt sie zu keiner Phase (die
  /// Datenbank setzt sie beim Löschen der Phase auf `null`), gilt die erste
  /// Phase; ohne Phasen `null`.
  Phase? get currentPhase {
    if (phases.isEmpty) return null;
    for (final Phase p in phases) {
      if (p.id == currentPhaseId) return p;
    }
    return phases.first;
  }

  Phase? phaseById(String id) {
    for (final Phase p in phases) {
      if (p.id == id) return p;
    }
    return null;
  }

  PlanItem? itemById(String id) {
    for (final PlanItem i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  List<PlanItem> itemsOfPhase(String phaseId) => <PlanItem>[
    for (final PlanItem i in items)
      if (i.phaseId == phaseId) i,
  ];

  Json toJson() => <String, Object?>{
    'id': id,
    'injuryId': injuryId,
    'version': version,
    'currentPhaseId': currentPhaseId,
    'closed': closed,
    'phases': <Json>[for (final Phase p in phases) p.toJson()],
    'items': <Json>[for (final PlanItem i in items) i.toJson()],
  };
}

/// Orte einer Übung (Spalte `exercises.locations`).
const Set<String> kExerciseLocations = <String>{'home', 'practice', 'gym'};

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    this.isExample = false,
    this.shortInstruction,
    this.materials = const <String>[],
    this.locations = const <String>[],
  });

  factory Exercise.fromJson(Json j) => Exercise(
    id: reqString(j, 'id'),
    name: reqString(j, 'name'),
    description: reqString(j, 'description'),
    isExample: optBool(j, 'isExample', false),
    shortInstruction: optStringOrNull(j, 'shortInstruction'),
    materials: optStringList(j, 'materials'),
    locations: optStringList(j, 'locations'),
  );

  final String id;
  final String name;
  final String description;

  /// Katalog-Beispiel (O-1): wird gekennzeichnet.
  final bool isExample;
  final String? shortInstruction;
  final List<String> materials;
  final List<String> locations;

  Json toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'description': description,
    'isExample': isExample,
    'shortInstruction': shortInstruction,
    'materials': materials,
    'locations': locations,
  };
}

class Treater {
  const Treater({
    required this.id,
    required this.role,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.note,
  });

  factory Treater.fromJson(Json j) => Treater(
    id: reqString(j, 'id'),
    role: reqString(j, 'role'),
    name: reqString(j, 'name'),
    phone: optStringOrNull(j, 'phone'),
    email: optStringOrNull(j, 'email'),
    address: optStringOrNull(j, 'address'),
    note: optStringOrNull(j, 'note'),
  );

  final String id;
  final String role;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? note;

  Json toJson() => <String, Object?>{
    'id': id,
    'role': role,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'note': note,
  };
}

/// Wer einen Termin angelegt hat (Spalte `created_by_role`); der Patient darf
/// nur seine eigenen ändern (Plan 8.9, DB-T15/T17).
enum AppointmentAuthor {
  physio,
  patient,
  seed;

  static AppointmentAuthor? fromDb(String? value) {
    for (final AppointmentAuthor a in AppointmentAuthor.values) {
      if (a.name == value) return a;
    }
    return null;
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.startsAt,
    required this.title,
    required this.author,
    this.treaterId,
    this.location,
  });

  factory Appointment.fromJson(Json j) {
    final AppointmentAuthor? author = AppointmentAuthor.fromDb(
      reqString(j, 'author'),
    );
    if (author == null) unreadable('appointment.author: unbekannter Wert');
    return Appointment(
      id: reqString(j, 'id'),
      startsAt: reqInstant(j, 'startsAt'),
      title: reqString(j, 'title'),
      author: author,
      treaterId: optStringOrNull(j, 'treaterId'),
      location: optStringOrNull(j, 'location'),
    );
  }

  final String id;
  final DateTime startsAt;
  final String title;
  final AppointmentAuthor author;
  final String? treaterId;
  final String? location;

  bool get isOwn => author == AppointmentAuthor.patient;

  Json toJson() => <String, Object?>{
    'id': id,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'title': title,
    'author': author.name,
    'treaterId': treaterId,
    'location': location,
  };
}

/// Krankengeschichte (Akte, nur lesend für den Patienten).
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.kind,
    required this.title,
    this.occurredOn,
    this.note,
  });

  factory HistoryEntry.fromJson(Json j) => HistoryEntry(
    id: reqString(j, 'id'),
    kind: reqString(j, 'kind'),
    title: reqString(j, 'title'),
    occurredOn: optDay(j, 'occurredOn'),
    note: optStringOrNull(j, 'note'),
  );

  final String id;
  final String kind;
  final String title;
  final LocalDay? occurredOn;
  final String? note;

  Json toJson() => <String, Object?>{
    'id': id,
    'kind': kind,
    'title': title,
    'occurredOn': occurredOn?.toString(),
    'note': note,
  };
}

/// Alles, was die Patienten-App vom Backend liest (Plan 8.2).
class Framework {
  Framework({
    required this.patient,
    required this.injury,
    required this.plan,
    required List<Exercise> exercises,
    required List<Treater> treaters,
    required List<Appointment> appointments,
    required List<HistoryEntry> history,
  }) : exercises = List<Exercise>.unmodifiable(exercises),
       treaters = List<Treater>.unmodifiable(treaters),
       appointments = List<Appointment>.unmodifiable(appointments),
       history = List<HistoryEntry>.unmodifiable(history);

  factory Framework.fromJson(Json j) {
    final Json? injury = optJson(j, 'injury');
    final Json? plan = optJson(j, 'plan');
    return Framework(
      patient: PatientInfo.fromJson(reqJson(j, 'patient')),
      injury: injury == null ? null : Injury.fromJson(injury),
      plan: plan == null ? null : Plan.fromJson(plan),
      exercises: <Exercise>[
        for (final Json e in optJsonList(j, 'exercises')) Exercise.fromJson(e),
      ],
      treaters: <Treater>[
        for (final Json t in optJsonList(j, 'treaters')) Treater.fromJson(t),
      ],
      appointments: <Appointment>[
        for (final Json a in optJsonList(j, 'appointments'))
          Appointment.fromJson(a),
      ],
      history: <HistoryEntry>[
        for (final Json h in optJsonList(j, 'history'))
          HistoryEntry.fromJson(h),
      ],
    );
  }

  final PatientInfo patient;

  /// Aktive Verletzung; `null`, wenn der Physio noch keine angelegt hat.
  final Injury? injury;

  /// Plan der aktiven Verletzung; `null` = „Dein Physio stellt deinen Plan
  /// noch zusammen“ (Plan 8.3 Regel 10).
  final Plan? plan;
  final List<Exercise> exercises;
  final List<Treater> treaters;
  final List<Appointment> appointments;
  final List<HistoryEntry> history;

  Exercise? exerciseById(String id) {
    for (final Exercise e in exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  Json toJson() => <String, Object?>{
    'patient': patient.toJson(),
    'injury': injury?.toJson(),
    'plan': plan?.toJson(),
    'exercises': <Json>[for (final Exercise e in exercises) e.toJson()],
    'treaters': <Json>[for (final Treater t in treaters) t.toJson()],
    'appointments': <Json>[
      for (final Appointment a in appointments) a.toJson(),
    ],
    'history': <Json>[for (final HistoryEntry h in history) h.toJson()],
  };
}
