// Abbildung der Datenbankzeilen (snake_case, PostgREST) auf die Modelle der App.
// Rein; wirft [UnreadableDataException] bei unbrauchbaren Zeilen. Die Spalten
// stehen hier einzeln (Spalten-Grants: `select=*` auf `patients` scheitert).
import '../logic/framework.dart';
import '../logic/json_support.dart';

// Spaltenlisten für die Abfragen (`select`), je Tabelle genau die gelesenen.
const String kPatientColumns = 'id,first_name,last_name,status,bound_at';
const String kInjuryColumns = 'id,label,reference_date,started_on,closed_on';
const String kPlanColumns = 'id,injury_id,current_phase_id,version,closed';
const String kPhaseColumns = 'id,position,title,planned_weeks';
const String kPlanItemColumns =
    'id,phase_id,exercise_id,position,sets,reps,duration_sec,weight_kg,'
    'pause_sec,load_note,release,release_on,release_with_phase_id,'
    'easier_variant_of';
const String kExerciseColumns =
    'id,name,description,is_example,short_instruction,materials,locations';
const String kTreaterColumns = 'id,role,name,phone,email,address,note';
const String kAppointmentColumns =
    'id,treater_id,starts_at,title,location,created_by_role';
const String kHistoryColumns = 'id,kind,title,occurred_on,note';

PatientInfo patientFromRow(Json r) {
  final PatientStatus? status = PatientStatus.fromDb(reqString(r, 'status'));
  if (status == null) unreadable('patients.status: unbekannter Wert');
  return PatientInfo(
    id: reqString(r, 'id'),
    firstName: reqString(r, 'first_name'),
    lastName: optStringOrNull(r, 'last_name'),
    status: status,
    boundAt: optInstant(r, 'bound_at'),
  );
}

Injury injuryFromRow(Json r) => Injury(
  id: reqString(r, 'id'),
  label: reqString(r, 'label'),
  referenceDate: reqDay(r, 'reference_date'),
  startedOn: reqDay(r, 'started_on'),
  closedOn: optDay(r, 'closed_on'),
);

Phase phaseFromRow(Json r) => Phase(
  id: reqString(r, 'id'),
  position: reqInt(r, 'position'),
  title: reqString(r, 'title'),
  plannedWeeks: inRange(reqInt(r, 'planned_weeks'), 1, 52, 'planned_weeks'),
);

PlanItem planItemFromRow(Json r) {
  final Release? release = Release.fromDb(reqString(r, 'release'));
  if (release == null) unreadable('plan_items.release: unbekannter Wert');
  return PlanItem(
    id: reqString(r, 'id'),
    phaseId: reqString(r, 'phase_id'),
    exerciseId: reqString(r, 'exercise_id'),
    position: reqInt(r, 'position'),
    sets: optIntOrNull(r, 'sets'),
    reps: optIntOrNull(r, 'reps'),
    durationSec: optIntOrNull(r, 'duration_sec'),
    weightKg: optDoubleOrNull(r, 'weight_kg'),
    pauseSec: optIntOrNull(r, 'pause_sec'),
    loadNote: optStringOrNull(r, 'load_note'),
    release: release,
    releaseOn: optDay(r, 'release_on'),
    releaseWithPhaseId: optStringOrNull(r, 'release_with_phase_id'),
    easierVariantOf: optStringOrNull(r, 'easier_variant_of'),
  );
}

Plan planFromRows(Json planRow, List<Json> phaseRows, List<Json> itemRows) =>
    Plan(
      id: reqString(planRow, 'id'),
      injuryId: reqString(planRow, 'injury_id'),
      version: reqInt(planRow, 'version'),
      currentPhaseId: optStringOrNull(planRow, 'current_phase_id'),
      closed: optBool(planRow, 'closed', false),
      phases: <Phase>[for (final Json p in phaseRows) phaseFromRow(p)],
      items: <PlanItem>[for (final Json i in itemRows) planItemFromRow(i)],
    );

Exercise exerciseFromRow(Json r) => Exercise(
  id: reqString(r, 'id'),
  name: reqString(r, 'name'),
  description: reqString(r, 'description'),
  isExample: optBool(r, 'is_example', false),
  shortInstruction: optStringOrNull(r, 'short_instruction'),
  materials: optStringList(r, 'materials'),
  locations: <String>[
    for (final String l in optStringList(r, 'locations'))
      if (kExerciseLocations.contains(l)) l,
  ],
);

Treater treaterFromRow(Json r) => Treater(
  id: reqString(r, 'id'),
  role: reqString(r, 'role'),
  name: reqString(r, 'name'),
  phone: optStringOrNull(r, 'phone'),
  email: optStringOrNull(r, 'email'),
  address: optStringOrNull(r, 'address'),
  note: optStringOrNull(r, 'note'),
);

Appointment appointmentFromRow(Json r) {
  final AppointmentAuthor? author = AppointmentAuthor.fromDb(
    reqString(r, 'created_by_role'),
  );
  if (author == null) unreadable('appointments.created_by_role: unbekannt');
  return Appointment(
    id: reqString(r, 'id'),
    startsAt: reqInstant(r, 'starts_at'),
    title: reqString(r, 'title'),
    author: author,
    treaterId: optStringOrNull(r, 'treater_id'),
    location: optStringOrNull(r, 'location'),
  );
}

HistoryEntry historyFromRow(Json r) => HistoryEntry(
  id: reqString(r, 'id'),
  kind: reqString(r, 'kind'),
  title: reqString(r, 'title'),
  occurredOn: optDay(r, 'occurred_on'),
  note: optStringOrNull(r, 'note'),
);
