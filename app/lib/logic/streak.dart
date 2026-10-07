// Streak-Regel (Plan 7.1, N-1, N-10, N-11). Reine Dart-Logik.
import 'clock.dart';
import 'json_support.dart';

/// Startzahl der Freezes (N-1). Es gibt kein Verdienen, das Maximum ist 2.
const int kStartFreezes = 2;

enum StreakDisplay { active, frozen, reset }

/// Streak-Zustand (unveränderlich). Persistiert siehe Plan 6.1 `streak`.
class StreakState {
  const StreakState({
    this.count = 0,
    this.freezes = kStartFreezes,
    this.lastTrainingDay,
    this.evaluatedThrough,
    this.coveredInGap = 0,
    this.uncoveredInGap = 0,
    this.resetNoticePending = false,
  });

  factory StreakState.fromJson(Json j) {
    final int count = optInt(j, 'count', 0);
    final int freezes = optInt(j, 'freezes', kStartFreezes);
    final int covered = optInt(j, 'coveredInGap', 0);
    final int uncovered = optInt(j, 'uncoveredInGap', 0);
    if (count < 0 || covered < 0 || uncovered < 0) {
      unreadable('streak: negative Zahl');
    }
    return StreakState(
      count: count,
      freezes: inRange(freezes, 0, kStartFreezes, 'streak.freezes'),
      lastTrainingDay: optDay(j, 'lastTrainingDay'),
      evaluatedThrough: optDay(j, 'evaluatedThrough'),
      coveredInGap: covered,
      uncoveredInGap: uncovered,
      resetNoticePending: optBool(j, 'resetNoticePending', false),
    );
  }

  final int count;
  final int freezes;
  final LocalDay? lastTrainingDay;

  /// Letzter vollständig ausgewerteter Tag.
  final LocalDay? evaluatedThrough;

  /// Per Freeze gedeckte verpasste Tage der aktuellen Lücke.
  final int coveredInGap;

  /// Ungedeckte verpasste Tage der aktuellen Lücke.
  final int uncoveredInGap;

  /// Manny-Neustart-Nachricht ist fällig.
  final bool resetNoticePending;

  StreakState copyWith({
    int? count,
    int? freezes,
    LocalDay? lastTrainingDay,
    LocalDay? evaluatedThrough,
    int? coveredInGap,
    int? uncoveredInGap,
    bool? resetNoticePending,
  }) {
    return StreakState(
      count: count ?? this.count,
      freezes: freezes ?? this.freezes,
      lastTrainingDay: lastTrainingDay ?? this.lastTrainingDay,
      evaluatedThrough: evaluatedThrough ?? this.evaluatedThrough,
      coveredInGap: coveredInGap ?? this.coveredInGap,
      uncoveredInGap: uncoveredInGap ?? this.uncoveredInGap,
      resetNoticePending: resetNoticePending ?? this.resetNoticePending,
    );
  }

  Json toJson() => <String, Object?>{
    'count': count,
    'freezes': freezes,
    'lastTrainingDay': lastTrainingDay?.toString(),
    'evaluatedThrough': evaluatedThrough?.toString(),
    'coveredInGap': coveredInGap,
    'uncoveredInGap': uncoveredInGap,
    'resetNoticePending': resetNoticePending,
  };

  @override
  bool operator ==(Object other) =>
      other is StreakState &&
      other.count == count &&
      other.freezes == freezes &&
      other.lastTrainingDay == lastTrainingDay &&
      other.evaluatedThrough == evaluatedThrough &&
      other.coveredInGap == coveredInGap &&
      other.uncoveredInGap == uncoveredInGap &&
      other.resetNoticePending == resetNoticePending;

  @override
  int get hashCode => Object.hash(
    count,
    freezes,
    lastTrainingDay,
    evaluatedThrough,
    coveredInGap,
    uncoveredInGap,
    resetNoticePending,
  );

  @override
  String toString() => 'StreakState(${toJson()})';
}

/// Sicht für die Kopfzeile des Pfads.
class StreakView {
  const StreakView({
    required this.count,
    required this.freezes,
    required this.display,
  });

  final int count;
  final int freezes;
  final StreakDisplay display;

  @override
  bool operator ==(Object other) =>
      other is StreakView &&
      other.count == count &&
      other.freezes == freezes &&
      other.display == display;

  @override
  int get hashCode => Object.hash(count, freezes, display);
}

abstract final class StreakEngine {
  /// Wertet alle vollständig vergangenen Tage vor [today] aus (Regeln 1–7, 9,
  /// 10). Idempotent und nachholend; bei zurückgestellter Uhr keine Wirkung.
  static StreakState evaluate(StreakState s, LocalDay today) {
    final LocalDay lastToEvaluate = today.addDays(-1);
    final LocalDay? through = s.evaluatedThrough;
    // Nichts Neues (auch: Uhr rückwärts, `today` < `evaluatedThrough` oder
    // `today` < `lastTrainingDay`): keine Auswertung, kein Verbrauch.
    if (through != null && !lastToEvaluate.isAfter(through)) return s;
    final LocalDay? last = s.lastTrainingDay;
    if (last != null && today.isBefore(last)) return s;

    // Streak 0: keine Freeze-Nutzung (Regel 6, A-8). Nach einem Reset ist die
    // Lücke abgeschlossen (Regel 7).
    if (s.count == 0 || last == null) {
      return s.copyWith(evaluatedThrough: lastToEvaluate);
    }

    int count = s.count;
    int freezes = s.freezes;
    int covered = s.coveredInGap;
    int uncovered = s.uncoveredInGap;
    bool notice = s.resetNoticePending;

    final LocalDay from = (through != null && through.isAfter(last))
        ? through
        : last;
    LocalDay day = from.addDays(1);
    while (!day.isAfter(lastToEvaluate)) {
      if (freezes > 0) {
        freezes--;
        covered++;
      } else {
        uncovered++;
        if (uncovered >= 2) {
          // Reset beim 2. ungedeckten verpassten Tag (N-10).
          count = 0;
          notice = true;
          break;
        }
      }
      day = day.addDays(1);
    }

    return StreakState(
      count: count,
      freezes: freezes,
      lastTrainingDay: last,
      evaluatedThrough: lastToEvaluate,
      coveredInGap: covered,
      uncoveredInGap: uncovered,
      resetNoticePending: notice,
    );
  }

  /// Zählt ein Eintrag für [day] überhaupt für den Streak? Nein bei
  /// zurückgestellter Uhr (Tag liegt nicht nach dem letzten Trainingstag bzw.
  /// nicht nach dem ausgewerteten Zeitraum) und beim zweiten Eintrag am selben
  /// Tag.
  static bool canCount(StreakState s, LocalDay day) {
    final LocalDay? last = s.lastTrainingDay;
    final LocalDay? through = s.evaluatedThrough;
    return (last == null || day.isAfter(last)) &&
        (through == null || day.isAfter(through));
  }

  /// Trägt ein Training für [day] ein. Wertet intern zuerst bis [day] aus
  /// (Regel 8, N-11), erhöht dann um 1 (nach Reset: 1) und schließt die Lücke.
  static StreakState logTraining(StreakState s, LocalDay day) {
    final StreakState e = evaluate(s, day);
    if (!canCount(e, day)) return e;
    return StreakState(
      count: e.count + 1,
      freezes: e.freezes,
      lastTrainingDay: day,
      evaluatedThrough: e.evaluatedThrough,
      coveredInGap: 0,
      uncoveredInGap: 0,
      resetNoticePending: e.resetNoticePending,
    );
  }

  static StreakView view(StreakState s) {
    final StreakDisplay display;
    if (s.count == 0) {
      display = StreakDisplay.reset;
    } else if (s.coveredInGap + s.uncoveredInGap > 0) {
      display = StreakDisplay.frozen;
    } else {
      display = StreakDisplay.active;
    }
    return StreakView(count: s.count, freezes: s.freezes, display: display);
  }
}
