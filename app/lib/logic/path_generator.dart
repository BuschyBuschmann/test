// Beispielpfad und Fortschritt (Plan 7.2). PLATZHALTER: Länge und Phasen sind
// Demo-Werte, keine medizinische Planung (A-10).
import '../l10n/strings_de.dart';
import 'clock.dart';
import 'path_model.dart';
import 'injury_type.dart';

/// Der Pfad ist ein Beispiel und wird immer so beschriftet (UI-25).
const bool kSamplePathIsPlaceholder = true;

const int kPathWeeks = 12;
const int kWeeksPerPhase = 4;
const int kTrainingDaysPerWeek = 3;

/// Baut den Beispielpfad: 12 Wochen in 3 Phasen; je Woche 3 Trainingstage und
/// 1 Wochenziel; nach Woche 4, 8, 12 ein Phasen-Abschluss; danach der Boss.
/// Gesamt 52 Units, gleich für alle Verletzungstypen (N-3).
List<PathUnit> buildSamplePath() {
  final List<PathUnit> units = <PathUnit>[];
  for (int w = 1; w <= kPathWeeks; w++) {
    final int phase = phaseOfWeek(w);
    for (int d = 1; d <= kTrainingDaysPerWeek; d++) {
      units.add(
        PathUnit(
          id: 'w$w-d$d',
          kind: UnitKind.trainingDay,
          week: w,
          phase: phase,
          dayNumber: d,
        ),
      );
    }
    units.add(
      PathUnit(id: 'w$w-goal', kind: UnitKind.weekGoal, week: w, phase: phase),
    );
    if (w % kWeeksPerPhase == 0) {
      units.add(
        PathUnit(
          id: 'p$phase-end',
          kind: UnitKind.phaseEnd,
          week: w,
          phase: phase,
        ),
      );
    }
  }
  units.add(
    const PathUnit(
      id: 'boss',
      kind: UnitKind.boss,
      week: kPathWeeks,
      phase: kPathWeeks ~/ kWeeksPerPhase,
    ),
  );
  return List<PathUnit>.unmodifiable(units);
}

/// Der eine Beispielpfad (unveränderlich).
final List<PathUnit> kSamplePath = buildSamplePath();

/// Phase einer Woche: `ceil(W / 4)`.
int phaseOfWeek(int week) => (week + kWeeksPerPhase - 1) ~/ kWeeksPerPhase;

/// Aktuelle Woche: `floor((today − injuryDate) / 7) + 1`, begrenzt auf 1..12.
/// Datum in der Zukunft (Uhr zurückgestellt) oder unbekannt → 1.
int currentWeek(LocalDay? injuryDate, LocalDay today) {
  if (injuryDate == null) return 1;
  final int days = injuryDate.daysUntil(today);
  if (days < 0) return 1;
  final int w = days ~/ 7 + 1;
  return w > kPathWeeks ? kPathWeeks : w;
}

/// Ergebnis der Fortschrittsberechnung.
class PathProgress {
  const PathProgress({
    required this.units,
    required this.statuses,
    required this.week,
    required this.phase,
    required this.currentIndex,
    required this.mannyIndex,
  });

  final List<PathUnit> units;
  final List<UnitStatus> statuses;

  /// Aktuelle Datumswoche (Kopfzeile, K-1).
  final int week;
  final int phase;

  /// Index der aktuellen Unit; `null`, wenn keine mehr offen ist (Endfall).
  final int? currentIndex;

  /// Index der Unit, auf der Manny sitzt: die aktuelle, im Endfall die letzte
  /// erledigte (A-11).
  final int mannyIndex;

  PathUnit? get current => currentIndex == null ? null : units[currentIndex!];

  /// Status der Unit mit [id]; unbekannte IDs gelten als nicht erledigt.
  bool isDone(String id) {
    final int i = units.indexWhere((PathUnit u) => u.id == id);
    return i >= 0 && statuses[i] == UnitStatus.done;
  }
}

/// Status je Unit:
/// - erledigt ⇔ `unit.week < W` oder ID in `completedUnitIds`;
/// - aktuell = erste nicht erledigte Unit in Pfadreihenfolge, **außer Boss**;
/// - sonst gesperrt (der Boss bleibt immer gesperrt, wenn nicht erledigt).
PathProgress computePathProgress({
  required LocalDay? injuryDate,
  required LocalDay today,
  required Iterable<String> completedUnitIds,
  List<PathUnit>? units,
}) {
  final List<PathUnit> path = units ?? kSamplePath;
  final Set<String> completed = completedUnitIds.toSet();
  final int week = currentWeek(injuryDate, today);
  final List<UnitStatus> statuses = List<UnitStatus>.filled(
    path.length,
    UnitStatus.locked,
  );
  int? current;
  int lastDone = 0;
  for (int i = 0; i < path.length; i++) {
    final PathUnit u = path[i];
    final bool done = u.week < week || completed.contains(u.id);
    if (done) {
      statuses[i] = UnitStatus.done;
      if (u.kind != UnitKind.boss) lastDone = i;
    } else if (current == null && u.kind != UnitKind.boss) {
      current = i;
      statuses[i] = UnitStatus.current;
    }
  }
  return PathProgress(
    units: path,
    statuses: List<UnitStatus>.unmodifiable(statuses),
    week: week,
    phase: phaseOfWeek(week),
    currentIndex: current,
    mannyIndex: current ?? lastDone,
  );
}

/// Kurzname des Verletzungstyps für die Kopfzeile (A-13).
String injuryShortName(InjuryType? type) {
  switch (type) {
    case InjuryType.acl:
      return S.injuryShortAcl;
    case InjuryType.ankle:
      return S.injuryShortAnkle;
    case InjuryType.muscle:
      return S.injuryShortMuscle;
    case InjuryType.other:
    case null:
      return S.injuryShortOther;
  }
}

/// „Phase 2 · Kreuzband“
String phaseLine(int phase, InjuryType? type) =>
    S.phaseLine(phase, injuryShortName(type));

String _kindText(PathUnit u) {
  switch (u.kind) {
    case UnitKind.trainingDay:
      return S.unitTrainingDay(u.dayNumber);
    case UnitKind.weekGoal:
      return S.unitWeekGoal;
    case UnitKind.phaseEnd:
      return S.unitPhaseEnd;
    case UnitKind.boss:
      return S.unitBoss;
  }
}

String _statusText(UnitStatus s) {
  switch (s) {
    case UnitStatus.done:
      return S.statusDone;
    case UnitStatus.current:
      return S.statusCurrent;
    case UnitStatus.locked:
      return S.statusLocked;
  }
}

/// Hinweistext beim Tippen auf eine Unit (Ergänzung 1, 3.5); `null` bei der
/// aktuellen Unit (sie öffnet Heute, kein Hinweis).
String? nodeHintText(PathUnit unit, UnitStatus status, int currentWeek) {
  switch (status) {
    case UnitStatus.current:
      return null;
    case UnitStatus.done:
      return S.hintDone;
    case UnitStatus.locked:
      if (unit.kind == UnitKind.boss && unit.week == currentWeek) {
        return S.hintBossGoal; // Nutzerentscheidung: eigener Text in Woche 12
      }
      if (unit.week == currentWeek) {
        return S.hintThisWeek;
      }
      switch (unit.kind) {
        case UnitKind.trainingDay:
        case UnitKind.weekGoal:
          return S.hintComesInWeek(unit.week);
        case UnitKind.phaseEnd:
          return S.hintPhaseEndComesInWeek(unit.week);
        case UnitKind.boss:
          return S.hintBossComesInWeek(unit.week);
      }
  }
}

/// Screenreader-Label einer Unit (A-14): „Woche 5, Trainingstag 3, aktuell.
/// Öffnet Heute.“, „Return to Sport, gesperrt.“
String unitSemanticsLabel(PathUnit unit, UnitStatus status) {
  final String status0 = _statusText(status);
  final String base = unit.kind == UnitKind.boss
      ? S.bossLabel(status0)
      : S.unitLabel(S.weekTitle(unit.week), _kindText(unit), status0);
  return status == UnitStatus.current ? '$base ${S.opensToday}' : base;
}
