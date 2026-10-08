// KS-3: MannyContext.
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/injury_type.dart';
import 'package:curaone/logic/manny_context.dart';
import 'package:curaone/logic/path_generator.dart';
import 'package:curaone/logic/profile.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/logic/training.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

void main() {
  final AppState base =
      onboardedState(
        streak: StreakState(count: 12, lastTrainingDay: kToday.addDays(-1)),
      ).copyWith(
        onboarding: onboardedState().onboarding.copyWith(
          name: '  Jakob ',
          injuryOther: 'geheimer Freitext',
        ),
      );

  test('Felder, Vorname getrimmt, Woche/Phase wie die Kopfzeile', () {
    final MannyContext c = MannyContext.from(base, kToday);
    expect(c.firstName, 'Jakob');
    expect(c.injuryType, InjuryType.acl);
    expect(c.injuryDate, kToday.addDays(-30));
    final PathProgress p = computePathProgress(
      injuryDate: base.onboarding.injuryDate,
      today: kToday,
      completedUnitIds: base.path.completedUnitIds,
    );
    expect(c.week, p.week);
    expect(c.phase, p.phase);
    expect(c.week, 5);
    expect(c.phase, 2);
    expect(c.streak, 12);
    expect(c.freezes, 2);
    expect(c.doneToday, isFalse);
    expect(c.timeChoice, 20);
    expect(c.exerciseCount, 4);
  });

  test('nach Training: heute erledigt, Streak +1', () {
    final MannyContext c = MannyContext.from(
      applyTraining(base, kToday).state,
      kToday,
    );
    expect(c.doneToday, isTrue);
    expect(c.streak, 13);
  });

  test('nach Reset: Streak 0, Freezes 0', () {
    final AppState s = base.copyWith(
      streak: StreakEngine.evaluate(
        StreakState(count: 5, freezes: 0, lastTrainingDay: kToday.addDays(-4)),
        kToday,
      ),
    );
    final MannyContext c = MannyContext.from(s, kToday);
    expect(c.streak, 0);
    expect(c.freezes, 0);
  });

  test('nach Profiländerung: Woche/Phase/Typ neu, Streak bleibt (N-7)', () {
    final AppState s = applyProfile(
      base,
      ProfileDraft.fromState(base).copyWith(
        injuryType: InjuryType.muscle,
        injuryDate: kToday.addDays(-60),
      ),
      kToday,
    ).state;
    final MannyContext c = MannyContext.from(s, kToday);
    expect(c.week, 9);
    expect(c.phase, 3);
    expect(c.injuryType, InjuryType.muscle);
    expect(c.streak, 12);
  });

  test('Übungsanzahl folgt Zeitwahl und Entfernen', () {
    final AppState s = base.copyWith(
      prefs: const PrefsState(timeChoice: 30),
      day: base.day.copyWith(removed: <String>['ex-wade']),
    );
    expect(MannyContext.from(s, kToday).exerciseCount, 5);
  });

  test('toJson: feste Feldnamen, stabil, ohne „Anderes“-Freitext', () {
    final Map<String, Object?> j = MannyContext.from(base, kToday).toJson();
    expect(j, <String, Object?>{
      'vorname': 'Jakob',
      'injuryType': 'acl',
      'injuryDate': '2026-09-07',
      'woche': 5,
      'phase': 2,
      'streak': 12,
      'freezes': 2,
      'heuteTrainiert': false,
      'zeitwahl': 20,
      'uebungenHeute': 4,
    });
    expect(j.toString().contains('geheimer'), isFalse);
    expect(MannyContext.from(base, kToday).toJson(), j);
  });
}
