// „Training eintragen“ als reine Zustandsfunktion (Plan 7.1 Regel 8, 7.2, 7.5,
// N-11, S25).
import 'app_state.dart';
import 'clock.dart';
import 'path_generator.dart';
import 'streak.dart';
import 'undo.dart';

class TrainingApplied {
  const TrainingApplied({
    required this.state,
    required this.snapshot,
    required this.countedForStreak,
  });

  /// Neuer Zustand (bei Wirkungslosigkeit der alte).
  final AppState state;

  /// Schnappschuss vor dem Eintragen; `null`, wenn nichts geändert wurde.
  final TrainingSnapshot? snapshot;

  /// `false` bei zurückgestellter Uhr (S25): Programm ist erledigt, aber
  /// Streak, Pfad und Feier bleiben unberührt.
  final bool countedForStreak;
}

/// Trägt ein Training für [forDay] ein. [forDay] muss dem Tag des Programms
/// (`state.day.dayKey`) entsprechen, sonst passiert nichts. Ein zweiter
/// Eintrag am selben Tag ist wirkungslos.
///
/// Wertet den Streak intern bis [forDay] aus (N-11). Zählt der Eintrag für den
/// Streak, wird zusätzlich die aktuelle Unit erledigt (UI-30), ein Ring-Puls
/// vorgemerkt und eine Feier erzeugt. Ohne offene Unit (Endfall) zählt der
/// Eintrag nur für den Streak (A-11).
TrainingApplied applyTraining(AppState s, LocalDay forDay) {
  if (forDay != s.day.dayKey || s.day.done) {
    return TrainingApplied(state: s, snapshot: null, countedForStreak: false);
  }
  final TrainingSnapshot snapshot = TrainingSnapshot.capture(s);
  final StreakState evaluated = StreakEngine.evaluate(s.streak, forDay);
  final bool counts = StreakEngine.canCount(evaluated, forDay);

  if (!counts) {
    // S25: Uhr zurückgestellt. Nur das Tagesprogramm ist erledigt.
    return TrainingApplied(
      state: s.copyWith(streak: evaluated, day: s.day.copyWith(done: true)),
      snapshot: snapshot,
      countedForStreak: false,
    );
  }

  final StreakState streak = StreakEngine.logTraining(evaluated, forDay);
  final PathProgress progress = computePathProgress(
    injuryDate: s.onboarding.injuryDate,
    today: forDay,
    completedUnitIds: s.path.completedUnitIds,
  );
  final String? unitId = progress.current?.id;
  return TrainingApplied(
    state: s.copyWith(
      streak: streak,
      path: unitId == null
          ? s.path
          : s.path.copyWith(
              completedUnitIds: <String>[...s.path.completedUnitIds, unitId],
              pulsePending: unitId,
            ),
      day: s.day.copyWith(done: true),
      celebration: CelebrationState(day: forDay, unitId: unitId),
    ),
    snapshot: snapshot,
    countedForStreak: true,
  );
}
