// Platzhalter-Inhalte (Plan 7.4, N-4): Übungen, Termine, Manny-Texte, Fakten.
//
// ALLES HIER IST PLATZHALTER. Es steckt keine medizinische Aussage darin; die
// echten Inhalte kommen aus dem Physio-Framework bzw. der KI-Anbindung.
import '../l10n/strings_de.dart';
import 'clock.dart';

/// Kennzeichnung für Review und Tests: Die Pools sind Platzhalter.
const bool kPoolsArePlaceholder = true;

/// Übung der Pools (Basis oder Alternative).
class ExerciseDef {
  const ExerciseDef({
    required this.id,
    required this.name,
    required this.reps,
    required this.minutes,
  });

  final String id;
  final String name;
  final String reps;
  final int minutes;
}

/// Basisübung mit ihren Alternativen für „Tauschen“. Alle Alternativen haben
/// dieselbe Dauer wie die Basis, damit die Summe je Zeitwahl erhalten bleibt.
class ExerciseFamily {
  const ExerciseFamily({required this.base, required this.alternatives});

  final ExerciseDef base;
  final List<ExerciseDef> alternatives;

  /// Zyklisch: 0 Schritte = Basis, 1 = erste Alternative … danach wieder Basis
  /// (A-15).
  ExerciseDef atSwapSteps(int steps) {
    final int n = alternatives.length + 1;
    final int i = steps % n;
    return i == 0 ? base : alternatives[i - 1];
  }
}

const ExerciseFamily _squat = ExerciseFamily(
  base: ExerciseDef(
    id: 'ex-kniebeuge',
    name: S.exSquatName,
    reps: S.repsThreeTwelve,
    minutes: 6,
  ),
  alternatives: <ExerciseDef>[
    ExerciseDef(
      id: 'ex-kniebeuge',
      name: S.exSquatAlt1,
      reps: S.repsThreeTen,
      minutes: 6,
    ),
    ExerciseDef(
      id: 'ex-kniebeuge',
      name: S.exSquatAlt2,
      reps: S.repsThreeTen,
      minutes: 6,
    ),
  ],
);

const ExerciseFamily _calf = ExerciseFamily(
  base: ExerciseDef(
    id: 'ex-wade',
    name: S.exCalfName,
    reps: S.repsThreeFifteen,
    minutes: 4,
  ),
  alternatives: <ExerciseDef>[
    ExerciseDef(
      id: 'ex-wade',
      name: S.exCalfAlt1,
      reps: S.repsThreeTwelve,
      minutes: 4,
    ),
    ExerciseDef(
      id: 'ex-wade',
      name: S.exCalfAlt2,
      reps: S.repsThreeTwelve,
      minutes: 4,
    ),
  ],
);

const ExerciseFamily _bridge = ExerciseFamily(
  base: ExerciseDef(
    id: 'ex-bruecke',
    name: S.exBridgeName,
    reps: S.repsThreeFifteen,
    minutes: 7,
  ),
  alternatives: <ExerciseDef>[
    ExerciseDef(
      id: 'ex-bruecke',
      name: S.exBridgeAlt1,
      reps: S.repsThreeFifteen,
      minutes: 7,
    ),
    ExerciseDef(
      id: 'ex-bruecke',
      name: S.exBridgeAlt2,
      reps: S.repsThreeTwelve,
      minutes: 7,
    ),
  ],
);

const ExerciseFamily _legRaise = ExerciseFamily(
  base: ExerciseDef(
    id: 'ex-beinheben',
    name: S.exLegRaiseName,
    reps: S.repsTwoTwelve,
    minutes: 3,
  ),
  alternatives: <ExerciseDef>[
    ExerciseDef(
      id: 'ex-beinheben',
      name: S.exLegRaiseAlt1,
      reps: S.repsTwoTwelve,
      minutes: 3,
    ),
    ExerciseDef(
      id: 'ex-beinheben',
      name: S.exLegRaiseAlt2,
      reps: S.repsTwoTwelve,
      minutes: 3,
    ),
  ],
);

const ExerciseFamily _lunge = ExerciseFamily(
  base: ExerciseDef(
    id: 'ex-ausfall',
    name: S.exLungeName,
    reps: S.repsThreeEight,
    minutes: 5,
  ),
  alternatives: <ExerciseDef>[
    ExerciseDef(
      id: 'ex-ausfall',
      name: S.exLungeAlt1,
      reps: S.repsThreeTen,
      minutes: 5,
    ),
    ExerciseDef(
      id: 'ex-ausfall',
      name: S.exLungeAlt2,
      reps: S.repsThreeEight,
      minutes: 5,
    ),
  ],
);

const ExerciseFamily _stretch = ExerciseFamily(
  base: ExerciseDef(
    id: 'ex-dehnung',
    name: S.exStretchName,
    reps: S.repsThirtySeconds,
    minutes: 5,
  ),
  alternatives: <ExerciseDef>[
    ExerciseDef(
      id: 'ex-dehnung',
      name: S.exStretchAlt1,
      reps: S.repsThirtySeconds,
      minutes: 5,
    ),
    ExerciseDef(
      id: 'ex-dehnung',
      name: S.exStretchAlt2,
      reps: S.repsThirtySeconds,
      minutes: 5,
    ),
  ],
);

/// Erlaubte Zeitwahlen in Minuten (Spec 2).
const List<int> kTimeChoices = <int>[10, 20, 30];

/// Standard bei Erststart und nach Löschen (N-8).
const int kDefaultTimeChoice = 20;

/// Basisübungen je Zeitwahl. 10 ⊂ 20 ⊂ 30 mit gleichen IDs, damit
/// Tagesänderungen beim Zeitwechsel per ID erhalten bleiben. Die Summe der
/// Basis-Dauern ist genau 10, 20 bzw. 30 Minuten.
const Map<int, List<ExerciseFamily>> kBaseExercises =
    <int, List<ExerciseFamily>>{
      10: <ExerciseFamily>[_squat, _calf],
      20: <ExerciseFamily>[_squat, _bridge, _calf, _legRaise],
      30: <ExerciseFamily>[_squat, _bridge, _calf, _legRaise, _lunge, _stretch],
    };

/// Sucht die Familie einer Basis-ID (über alle Zeitwahlen).
ExerciseFamily? familyById(String id) {
  for (final List<ExerciseFamily> list in kBaseExercises.values) {
    for (final ExerciseFamily f in list) {
      if (f.base.id == id) return f;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Termine (N-14)
// ---------------------------------------------------------------------------

enum AppointmentCategory { physio, doctor }

class Appointment {
  const Appointment({
    required this.category,
    required this.hour,
    required this.minute,
    required this.title,
    required this.meta,
  });

  final AppointmentCategory category;
  final int hour;
  final int minute;
  final String title;

  /// Meta-Zeile mit „Beispiel“-Kennzeichnung.
  final String meta;

  /// „17:00“
  String get timeText =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get categoryText => category == AppointmentCategory.physio
      ? S.categoryPhysio
      : S.categoryDoctor;

  /// Screenreader (A-16).
  String get semanticsLabel =>
      S.appointmentLabel(categoryText, title, timeText);
}

const Appointment _physio = Appointment(
  category: AppointmentCategory.physio,
  hour: 17,
  minute: 0,
  title: S.apptPhysioTitle,
  meta: S.apptPhysioMeta,
);

const Appointment _doctor = Appointment(
  category: AppointmentCategory.doctor,
  hour: 9,
  minute: 30,
  title: S.apptDoctorTitle,
  meta: S.apptDoctorMeta,
);

/// Beispieltermine des Tages, nach Uhrzeit sortiert: Physio Mo–Fr 17:00,
/// zusätzlich Fr 09:30 Arzt, Sa/So keine.
List<Appointment> appointmentsFor(LocalDay day) {
  final int wd = day.weekday;
  if (wd == DateTime.saturday || wd == DateTime.sunday) {
    return const <Appointment>[];
  }
  if (wd == DateTime.friday) return const <Appointment>[_doctor, _physio];
  return const <Appointment>[_physio];
}

// ---------------------------------------------------------------------------
// Fakten (KS-2)
// ---------------------------------------------------------------------------

/// Fakt mit stabiler ID und Text.
class FactRef {
  const FactRef({required this.id, required this.text});

  final String id;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is FactRef && other.id == id && other.text == text;

  @override
  int get hashCode => Object.hash(id, text);
}

/// Beispielfakt (kein Rotieren, Platzhalter bis zum Physio-Pool).
const FactRef kExampleFact = FactRef(
  id: S.factTissueId,
  text: S.factTissueText,
);

/// Alle bekannten Fakten (für den Eindeutigkeitstest der IDs).
const List<FactRef> kAllFacts = <FactRef>[kExampleFact];

// ---------------------------------------------------------------------------
// Manny-Texte im Onboarding
// ---------------------------------------------------------------------------

/// Manny-Satz für Onboarding-Schritt [step] (0..3).
String onboardingMannyText(int step, String name) {
  final String n = name.trim();
  switch (step) {
    case 0:
      return S.onboardingStep1;
    case 1:
      return S.onboardingStep2(n);
    case 2:
      return S.onboardingStep3(n);
    default:
      return S.onboardingStep4;
  }
}

/// Hinweis nach Tipp auf den Mikrofon-Button.
const String kMicHint = S.micHint;
