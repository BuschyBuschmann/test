// Pfad aus den Phasen des Physios (Plan 8.3, O-4; Regeln 1–11 aus v1.2 6.3).
// `path_generator.dart` bleibt für den Beispielpfad (Demo-Modus).
// Reine Dart-Logik.
import 'clock.dart';
import 'framework.dart';
import 'path_generator.dart' show kTrainingDaysPerWeek;
import 'path_model.dart';

/// Anzeigestatus einer Unit im Phasenpfad.
enum PhaseUnitStatus {
  done,
  current,
  locked,

  /// Unit einer früheren Phase, die der Physio vorgeschaltet hat, ohne dass sie
  /// erledigt wurde: nicht erledigt, nicht antippbar (Regel 6).
  skipped,
}

/// Der aus den Phasen gebaute Pfad mit Status und Kopfzeile.
class PhasePath {
  const PhasePath({
    required this.units,
    required this.statuses,
    required this.phaseIds,
    required this.currentIndex,
    required this.mannyIndex,
    required this.week,
    required this.totalWeeks,
    required this.phasePosition,
    required this.phaseTitle,
  });

  /// Leerzustand: keine Phasen (Regel 10).
  static const PhasePath empty = PhasePath(
    units: <PathUnit>[],
    statuses: <PhaseUnitStatus>[],
    phaseIds: <String?>[],
    currentIndex: null,
    mannyIndex: -1,
    week: 0,
    totalWeeks: 0,
    phasePosition: 0,
    phaseTitle: null,
  );

  /// Reihenfolge des Pfads; `PathUnit.week` zählt über alle Phasen (1-basiert),
  /// `PathUnit.phase` ist die Position der Phase (1-basiert, Boss: letzte).
  final List<PathUnit> units;
  final List<PhaseUnitStatus> statuses;

  /// Phasen-ID je Unit; `null` beim Boss.
  final List<String?> phaseIds;

  /// Index der aktuellen Unit; `null`, wenn die aktuelle Phase vollständig
  /// erledigt ist (Regel 5) oder es keinen Pfad gibt.
  final int? currentIndex;

  /// Index der Unit, auf der Manny sitzt: die aktuelle, sonst die letzte
  /// erledigte Unit der aktuellen Phase; `-1` ohne Pfad.
  final int mannyIndex;

  /// Kopfzeile „Woche N“ (Regel 10): Kalenderwoche seit `reference_date`,
  /// begrenzt auf 1 … [totalWeeks]; 0 ohne Pfad.
  final int week;
  final int totalWeeks;

  /// „Phase P“: Position der aktuellen Phase (1-basiert); 0 ohne Pfad.
  final int phasePosition;
  final String? phaseTitle;

  bool get isEmpty => units.isEmpty;

  PathUnit? get current => currentIndex == null ? null : units[currentIndex!];

  /// ID der Unit, die das Training erledigt (T-5, Plan 8.3): die aktuelle.
  String? get unitToComplete => current?.id;
}

/// Baut den Pfad. [phases] in beliebiger Reihenfolge (wird nach `position`
/// sortiert), [currentPhaseId] aus dem Plan (unbekannt/`null` → erste Phase),
/// [completedUnitIds] lokal; unbekannte IDs werden ignoriert (Regel 9).
///
/// 1. Aufbau: je Phase `plannedWeeks` Wochen mit 3 Trainingstagen und 1
///    Wochenziel, am Phasenende ein Abschluss, nach der letzten Phase der Boss.
/// 2. IDs: `<phaseId>-w<n>-d<k>`, `<phaseId>-w<n>-goal`, `<phaseId>-end`,
///    `boss` (n zählt je Phase).
/// 3. Erledigt ausschließlich über [completedUnitIds].
/// 4. Aktuell = erste nicht erledigte Unit der aktuellen Phase.
/// 5. Ist die aktuelle Phase vollständig erledigt: keine aktuelle Unit.
/// 6. Frühere Phasen: nicht erledigte Units sind „ausgelassen“.
/// 7./8. Spätere Phasen und der Boss sind gesperrt.
PhasePath buildPathFromPhases({
  required List<Phase> phases,
  required String? currentPhaseId,
  required Iterable<String> completedUnitIds,
  required LocalDay referenceDate,
  required LocalDay today,
}) {
  if (phases.isEmpty) return PhasePath.empty;
  final List<Phase> sorted = List<Phase>.of(phases)
    ..sort((Phase a, Phase b) => a.position.compareTo(b.position));
  int currentPos = sorted.indexWhere((Phase p) => p.id == currentPhaseId);
  if (currentPos < 0) currentPos = 0;
  final Set<String> completed = completedUnitIds.toSet();

  final List<PathUnit> units = <PathUnit>[];
  final List<PhaseUnitStatus> statuses = <PhaseUnitStatus>[];
  final List<String?> phaseIds = <String?>[];
  int? currentIndex;
  int lastDoneInCurrent = -1;
  int firstOfCurrent = -1;
  int globalWeek = 0;

  void add(PathUnit unit, String? phaseId, int phasePos) {
    final bool done = completed.contains(unit.id);
    PhaseUnitStatus status;
    if (done) {
      status = PhaseUnitStatus.done;
    } else if (phaseId == null) {
      status = PhaseUnitStatus.locked; // Boss: immer gesperrt (Regel 8)
    } else if (phasePos < currentPos) {
      status = PhaseUnitStatus.skipped;
    } else if (phasePos == currentPos) {
      if (currentIndex == null) {
        currentIndex = units.length;
        status = PhaseUnitStatus.current;
      } else {
        status = PhaseUnitStatus.locked;
      }
    } else {
      status = PhaseUnitStatus.locked;
    }
    if (phasePos == currentPos && phaseId != null) {
      if (firstOfCurrent < 0) firstOfCurrent = units.length;
      if (done) lastDoneInCurrent = units.length;
    }
    units.add(unit);
    statuses.add(status);
    phaseIds.add(phaseId);
  }

  for (int p = 0; p < sorted.length; p++) {
    final Phase phase = sorted[p];
    for (int n = 1; n <= phase.plannedWeeks; n++) {
      globalWeek++;
      for (int d = 1; d <= kTrainingDaysPerWeek; d++) {
        add(
          PathUnit(
            id: '${phase.id}-w$n-d$d',
            kind: UnitKind.trainingDay,
            week: globalWeek,
            phase: p + 1,
            dayNumber: d,
          ),
          phase.id,
          p,
        );
      }
      add(
        PathUnit(
          id: '${phase.id}-w$n-goal',
          kind: UnitKind.weekGoal,
          week: globalWeek,
          phase: p + 1,
        ),
        phase.id,
        p,
      );
    }
    add(
      PathUnit(
        id: '${phase.id}-end',
        kind: UnitKind.phaseEnd,
        week: globalWeek,
        phase: p + 1,
      ),
      phase.id,
      p,
    );
  }
  add(
    PathUnit(
      id: 'boss',
      kind: UnitKind.boss,
      week: globalWeek,
      phase: sorted.length,
    ),
    null,
    sorted.length,
  );

  final int mannyIndex =
      currentIndex ??
      (lastDoneInCurrent >= 0 ? lastDoneInCurrent : firstOfCurrent);

  // Kopfzeile: Kalenderwoche seit reference_date, begrenzt auf 1..Summe.
  final int days = referenceDate.daysUntil(today);
  int week = days < 0 ? 1 : days ~/ 7 + 1;
  if (week > globalWeek) week = globalWeek;

  return PhasePath(
    units: List<PathUnit>.unmodifiable(units),
    statuses: List<PhaseUnitStatus>.unmodifiable(statuses),
    phaseIds: List<String?>.unmodifiable(phaseIds),
    currentIndex: currentIndex,
    mannyIndex: mannyIndex,
    week: week,
    totalWeeks: globalWeek,
    phasePosition: currentPos + 1,
    phaseTitle: sorted[currentPos].title,
  );
}

/// Fortschritt aus einem Plan (Kurzform für den Aufrufer).
PhasePath buildPathFromPlan({
  required Plan plan,
  required Injury injury,
  required Iterable<String> completedUnitIds,
  required LocalDay today,
}) => buildPathFromPhases(
  phases: plan.phases,
  currentPhaseId: plan.currentPhaseId,
  completedUnitIds: completedUnitIds,
  referenceDate: injury.referenceDate,
  today: today,
);
