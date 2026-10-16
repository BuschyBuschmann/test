import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/framework.dart';

const String kPatientId = '11111111-1111-4111-8111-111111111111';

Phase phase(String id, int position, {int weeks = 2, String? title}) => Phase(
  id: id,
  position: position,
  title: title ?? 'Phase $id',
  plannedWeeks: weeks,
);

PlanItem item(
  String id, {
  String phaseId = 'ph1',
  int position = 0,
  int? sets,
  int? reps,
  int? durationSec,
  int? pauseSec,
  Release release = Release.active,
  LocalDay? releaseOn,
  String? releaseWithPhaseId,
}) => PlanItem(
  id: id,
  phaseId: phaseId,
  exerciseId: 'ex-$id',
  position: position,
  sets: sets,
  reps: reps,
  durationSec: durationSec,
  pauseSec: pauseSec,
  release: release,
  releaseOn: releaseOn,
  releaseWithPhaseId: releaseWithPhaseId,
);

Plan plan({
  List<Phase>? phases,
  List<PlanItem>? items,
  String? currentPhaseId = 'ph1',
  int version = 1,
}) => Plan(
  id: 'plan-1',
  injuryId: 'inj-1',
  version: version,
  currentPhaseId: currentPhaseId,
  closed: false,
  phases: phases ?? <Phase>[phase('ph1', 0), phase('ph2', 1)],
  items: items ?? <PlanItem>[item('a', sets: 3, reps: 10)],
);

Framework sampleFramework({Plan? plan0, String patientId = kPatientId}) {
  final Plan p =
      plan0 ??
      plan(
        items: <PlanItem>[
          item('a', position: 0, sets: 3, reps: 10),
          item('b', position: 1, durationSec: 30, sets: 2, pauseSec: 30),
          item(
            'c',
            position: 2,
            release: Release.prepared,
            releaseOn: const LocalDay(2026, 10, 20),
          ),
          item('d', phaseId: 'ph2', position: 3),
        ],
      );
  return Framework(
    patient: PatientInfo(
      id: patientId,
      firstName: 'Lena',
      boundAt: DateTime.utc(2026, 10, 1, 8),
    ),
    injury: const Injury(
      id: 'inj-1',
      label: 'Kreuzband',
      referenceDate: LocalDay(2026, 9, 7),
      startedOn: LocalDay(2026, 9, 7),
    ),
    plan: p,
    exercises: <Exercise>[
      for (final PlanItem i in p.items)
        Exercise(
          id: i.exerciseId,
          name: 'Übung ${i.id}',
          description: 'Beschreibung ${i.id}',
          materials: const <String>['Band'],
          locations: const <String>['home'],
        ),
    ],
    treaters: const <Treater>[
      Treater(id: 't1', role: 'Physio', name: 'Dr. Muster'),
    ],
    appointments: <Appointment>[
      Appointment(
        id: 'ap1',
        startsAt: DateTime.utc(2026, 10, 12, 9),
        title: 'Kontrolle',
        author: AppointmentAuthor.physio,
      ),
    ],
    history: const <HistoryEntry>[
      HistoryEntry(
        id: 'h1',
        kind: 'op',
        title: 'Operation',
        occurredOn: LocalDay(2026, 9, 8),
      ),
    ],
  );
}
