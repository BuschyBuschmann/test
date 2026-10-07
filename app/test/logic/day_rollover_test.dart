// Tageswechsel, Eintrag über Mitternacht und Rückgängig (Plan 7.5, 7.6, S18,
// S25, N-11).
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/day_program.dart';
import 'package:curaone/logic/day_rollover.dart';
import 'package:curaone/logic/manny_state.dart';
import 'package:curaone/logic/path_generator.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/logic/training.dart';
import 'package:curaone/logic/undo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

LocalDay get next => kToday.addDays(1);

void main() {
  group('rollover', () {
    test('selber Tag: No-op', () {
      final AppState s = onboardedState();
      final RolloverResult r = rollover(s, kToday);
      expect(r.changed, isFalse);
      expect(identical(r.state, s), isTrue);
    });

    test('setzt Tagesänderungen und done zurück, behält Zeitwahl (N-8)', () {
      AppState s = onboardedState();
      s = s.copyWith(
        day: s.day.copyWith(
          removed: <String>['ex-wade'],
          swaps: <String, int>{'ex-kniebeuge': 1},
          custom: <CustomExercise>[
            const CustomExercise(
              id: 'custom-1',
              name: 'X',
              reps: 'r',
              minutes: 1,
            ),
          ],
          done: true,
        ),
        prefs: const PrefsState(timeChoice: 30),
      );
      final RolloverResult r = rollover(s, next);
      expect(r.changed, isTrue);
      expect(r.state.day, DayProgramState.fresh(next));
      expect(r.state.prefs.timeChoice, 30);
    });

    test('rückwärts = Wechsel (frisches Programm für den früheren Tag)', () {
      final AppState s = onboardedState();
      final RolloverResult r = rollover(s, kToday.addDays(-1));
      expect(r.changed, isTrue);
      expect(r.state.day.dayKey, kToday.addDays(-1));
    });

    test('Streak wird beim Wechsel ausgewertet', () {
      final AppState s = onboardedState(
        streak: StreakState(count: 5, lastTrainingDay: kToday.addDays(-1)),
      );
      final RolloverResult r = rollover(s, kToday.addDays(1));
      expect(r.state.streak.freezes, 1);
      expect(StreakEngine.view(r.state.streak).display, StreakDisplay.frozen);
    });

    test('Feier vom Vortag verfällt samt Puls; Feier von heute bleibt', () {
      AppState s = onboardedState().copyWith(
        celebration: CelebrationState(day: kToday, unitId: 'w5-d1'),
        path: const PathState(
          completedUnitIds: <String>['w5-d1'],
          pulsePending: 'w5-d1',
        ),
      );
      final RolloverResult r = rollover(s, next);
      expect(r.state.celebration, isNull);
      expect(r.state.path.pulsePending, isNull);
      expect(r.state.path.completedUnitIds, <String>['w5-d1']);
      // Rückwärts auf den Tag der Feier: bleibt (day == today).
      s = s.copyWith(day: DayProgramState.fresh(next));
      final RolloverResult back = rollover(s, kToday);
      expect(back.state.celebration, isNotNull);
      expect(back.state.path.pulsePending, 'w5-d1');
    });

    test('Manny-Zähler beginnen implizit neu (lastShown ist tagesbezogen)', () {
      final AppState s = onboardedState().copyWith(
        manny: onboardedState().manny.copyWith(
          lastShown: <MannyOccasion, LocalDay>{MannyOccasion.fact: kToday},
        ),
      );
      final AppState n = rollover(s, next).state;
      expect(n.manny.shownOn(MannyOccasion.fact, next), isFalse);
    });
  });

  group('applyTraining', () {
    test('Eintragen: Streak +1, Unit erledigt, done, Feier, Puls', () {
      final AppState s = onboardedState(
        streak: StreakState(count: 12, lastTrainingDay: kToday.addDays(-1)),
      );
      final TrainingApplied a = applyTraining(s, kToday);
      expect(a.countedForStreak, isTrue);
      expect(a.state.streak.count, 13);
      expect(a.state.streak.lastTrainingDay, kToday);
      expect(a.state.day.done, isTrue);
      expect(a.state.path.completedUnitIds, <String>['w5-d1']);
      expect(a.state.path.pulsePending, 'w5-d1');
      expect(
        a.state.celebration,
        CelebrationState(day: kToday, unitId: 'w5-d1'),
      );
      expect(a.snapshot, isNotNull);
    });

    test('zweites Eintragen am selben Tag ist wirkungslos', () {
      final AppState s = onboardedState();
      final AppState once = applyTraining(s, kToday).state;
      final TrainingApplied twice = applyTraining(once, kToday);
      expect(twice.state, once);
      expect(twice.snapshot, isNull);
    });

    test('Eintragen setzt die nächste Unit aktuell (UI-30)', () {
      final AppState s = onboardedState();
      final AppState a = applyTraining(s, kToday).state;
      final PathProgress p = computePathProgress(
        injuryDate: a.onboarding.injuryDate,
        today: kToday,
        completedUnitIds: a.path.completedUnitIds,
      );
      expect(p.current!.id, 'w5-d2');
    });

    test('Endfall ohne offene Unit: zählt nur für den Streak (A-11)', () {
      final AppState s = onboardedState(injuryDate: kToday.addDays(-200))
          .copyWith(
            path: PathState(
              completedUnitIds: <String>[
                for (final u in kSamplePath)
                  if (u.id != 'boss') u.id,
              ],
            ),
          );
      final TrainingApplied a = applyTraining(s, kToday);
      expect(a.state.streak.count, 1);
      expect(a.state.path.completedUnitIds, s.path.completedUnitIds);
      expect(a.state.path.pulsePending, isNull);
      expect(a.state.celebration!.unitId, isNull);
    });

    test('Eintrag für einen fremden Tag wird abgelehnt', () {
      final AppState s = onboardedState();
      final TrainingApplied a = applyTraining(s, next);
      expect(a.state, s);
      expect(a.snapshot, isNull);
    });

    test('S25 Uhr zurück + Tageswechsel: done, Streak unverändert, keine Unit, keine Feier', () {
      // Heute schon trainiert (L = T), Uhr auf T−1 zurück.
      final AppState trained = applyTraining(onboardedState(), kToday).state;
      final LocalDay back = kToday.addDays(-1);
      final AppState rolled = rollover(trained, back).state;
      expect(rolled.day, DayProgramState.fresh(back));
      final TrainingApplied a = applyTraining(rolled, back);
      expect(a.countedForStreak, isFalse);
      expect(a.state.day.done, isTrue);
      expect(a.state.streak, trained.streak);
      expect(
        a.state.path,
        isNot(predicate<PathState>((p) => p.completedUnitIds.length > 1)),
      );
      expect(a.state.path.completedUnitIds, trained.path.completedUnitIds);
      expect(a.state.celebration, isNull);
    });

    test('Eintrag über Mitternacht: zählt für den Vortag, heute nicht verpasst, kein Undo, keine Feier', () {
      // 23:59 Sheet geöffnet am Vortag (Programm = Vortag), 00:01 eintragen.
      final LocalDay openedDay = kToday;
      final AppState s = onboardedState(
        streak: StreakState(count: 4, lastTrainingDay: openedDay.addDays(-1)),
      );
      final TrainingApplied a = applyTraining(s, openedDay);
      expect(a.state.streak.count, 5);
      expect(a.state.streak.lastTrainingDay, openedDay);
      expect(a.state.day.done, isTrue);
      final RolloverResult r = rollover(a.state, next);
      expect(r.changed, isTrue);
      // Programm heute frisch (Training starten), Feier verfällt sofort.
      expect(r.state.day, DayProgramState.fresh(next));
      expect(r.state.celebration, isNull);
      expect(r.state.path.pulsePending, isNull);
      // Streak: Vortag zählte, heute ist nicht verpasst.
      expect(r.state.streak.count, 5);
      expect(r.state.streak.freezes, 2);
      expect(StreakEngine.view(r.state.streak).display, StreakDisplay.active);
      // Unit des Vortags bleibt erledigt.
      expect(r.state.path.completedUnitIds, <String>['w5-d1']);
    });
  });

  group('Rückgängig (7.6)', () {
    test('S18/UI-38: Streak, Unit, done, Feier, Puls wie vorher', () {
      final AppState before = onboardedState(
        streak: StreakState(count: 5, lastTrainingDay: kToday.addDays(-2)),
      );
      // frozen-Zustand wie in S18
      final AppState frozen = before.copyWith(
        streak: StreakEngine.evaluate(before.streak, kToday),
      );
      expect(StreakEngine.view(frozen.streak).display, StreakDisplay.frozen);
      final TrainingApplied a = applyTraining(frozen, kToday);
      expect(a.state, isNot(frozen));
      final AppState undone = undoTraining(a.state, a.snapshot!);
      expect(undone, frozen);
      expect(undone.celebration, isNull);
      expect(undone.path.pulsePending, isNull);
      expect(undone.day.done, isFalse);
      // Erneutes Eintragen ist möglich.
      expect(applyTraining(undone, kToday).state, a.state);
    });

    test('Unit wird wieder aktuell, Feier gestrichen', () {
      final AppState s = onboardedState();
      final TrainingApplied a = applyTraining(s, kToday);
      final AppState u = undoTraining(a.state, a.snapshot!);
      final PathProgress p = computePathProgress(
        injuryDate: u.onboarding.injuryDate,
        today: kToday,
        completedUnitIds: u.path.completedUnitIds,
      );
      expect(p.current!.id, 'w5-d1');
      expect(u.celebration, isNull);
    });

    test('Schnappschuss merkt den Tag (Controller lehnt später ab)', () {
      final TrainingApplied a = applyTraining(onboardedState(), kToday);
      expect(a.snapshot!.day, kToday);
    });

    test('Entfernt: Basisübung und eigene Übung zurück (Position)', () {
      DayProgramState d = DayProgramState.fresh(kToday);
      d = addCustom(
        d,
        const CustomExercise(id: 'custom-1', name: 'A', reps: 'r', minutes: 1),
      );
      d = addCustom(
        d,
        const CustomExercise(id: 'custom-2', name: 'B', reps: 'r', minutes: 1),
      );
      // Basis
      final DayProgramState rb = removeExercise(d, 'ex-wade');
      expect(
        undoRemoval(rb, RemovalToken(day: kToday, exerciseId: 'ex-wade')),
        d,
      );
      // Eigene Übung an Position 0
      final DayProgramState rc = removeExercise(d, 'custom-1');
      final DayProgramState back = undoRemoval(
        rc,
        RemovalToken(
          day: kToday,
          exerciseId: 'custom-1',
          customExercise: d.custom[0],
          customIndex: 0,
        ),
      );
      expect(back.custom.map((c) => c.id), <String>['custom-1', 'custom-2']);
      // bereits vorhanden: unverändert
      expect(
        undoRemoval(
          back,
          RemovalToken(
            day: kToday,
            exerciseId: 'custom-1',
            customExercise: d.custom[0],
          ),
        ),
        back,
      );
    });
  });
}
