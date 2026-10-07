import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/manny_occasions.dart';
import 'package:curaone/logic/manny_state.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/logic/training.dart';
import 'package:curaone/logic/undo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

DateTime at(int hour, [LocalDay day = kToday]) =>
    DateTime(day.year, day.month, day.day, hour);

AppState withStreak(int count) => onboardedState(
  streak: StreakState(count: count, lastTrainingDay: kToday.addDays(-1)),
);

void main() {
  group('Priorität (A-20)', () {
    test('Feier > Neustart > Begrüßung > Streak-Gefahr > Fakt', () {
      AppState s = withStreak(3).copyWith(
        celebration: CelebrationState(day: kToday, streak: 4, unitId: 'w5-d1'),
        manny: const MannyState(greetingPending: true),
        streak: withStreak(3).streak.copyWith(resetNoticePending: true),
      );
      expect(nextBubble(s, at(19))!.occasion, MannyOccasion.celebration);
      s = s.copyWith(clearCelebration: true);
      expect(nextBubble(s, at(19))!.occasion, MannyOccasion.restart);
      s = s.copyWith(streak: s.streak.copyWith(resetNoticePending: false));
      expect(nextBubble(s, at(19))!.occasion, MannyOccasion.greeting);
      s = s.copyWith(manny: const MannyState());
      expect(nextBubble(s, at(19))!.occasion, MannyOccasion.streakDanger);
      expect(nextBubble(s, at(9))!.occasion, MannyOccasion.fact);
    });

    test('Posen: Feier feiernd, Neustart motiviert (A-17)', () {
      final AppState c = onboardedState().copyWith(
        celebration: CelebrationState(day: kToday, streak: 1, unitId: 'w5-d1'),
        path: const PathState(pulsePending: 'w5-d1'),
      );
      final BubbleDecision d = nextBubble(c, at(10))!;
      expect(d.pose, MannyPose.feiernd);
      expect(d.pulseUnitId, 'w5-d1');
      final BubbleDecision r = nextBubble(
        onboardedState().copyWith(
          streak: const StreakState(resetNoticePending: true),
        ),
        at(10),
      )!;
      expect(r.pose, MannyPose.motiviert);
      expect(r.pulseUnitId, isNull);
    });
  });

  group('Streak-Gefahr (N-2)', () {
    test('17:59 nein, 18:00 ja', () {
      final AppState s = withStreak(5);
      expect(
        nextBubble(s, DateTime(2026, 10, 7, 17, 59))?.occasion,
        isNot(MannyOccasion.streakDanger),
      );
      expect(
        nextBubble(s, DateTime(2026, 10, 7, 18))!.occasion,
        MannyOccasion.streakDanger,
      );
      expect(kEveningHour, 18);
    });

    test('nicht bei Streak 0 und nicht nach Training', () {
      expect(
        nextBubble(onboardedState(), at(19))?.occasion,
        isNot(MannyOccasion.streakDanger),
      );
      final AppState done = withStreak(5)
          .copyWith(day: withStreak(5).day.copyWith(done: true));
      expect(nextBubble(done, at(19)), isNull);
    });
  });

  group('einmal pro Tag und am Folgetag wieder (UI-45)', () {
    test(
      'Begrüßung: nach markBubbleShown nicht mehr, Fälligkeit zurückgenommen',
      () {
        AppState s = onboardedState().copyWith(
          manny: const MannyState(greetingPending: true),
        );
        expect(nextBubble(s, at(10))!.occasion, MannyOccasion.greeting);
        s = markBubbleShown(s, MannyOccasion.greeting, kToday);
        expect(s.manny.greetingPending, isFalse);
        expect(s.manny.shownOn(MannyOccasion.greeting, kToday), isTrue);
        // Danach kein Fakt am selben Tag („erster Besuch“, A-22) und keine Begrüßung.
        expect(nextBubble(s, at(10)), isNull);
      },
    );

    test('Streak-Gefahr einmal pro Tag, am Folgetag wieder', () {
      AppState s = withStreak(5);
      s = markBubbleShown(s, MannyOccasion.streakDanger, kToday);
      expect(nextBubble(s, at(20)), isNull);
      final LocalDay tomorrow = kToday.addDays(1);
      expect(
        nextBubble(s, at(20, tomorrow))!.occasion,
        MannyOccasion.streakDanger,
      );
    });

    test('Beispielfakt: einmal pro Tag, am Folgetag wieder', () {
      AppState s = onboardedState();
      expect(nextBubble(s, at(9))!.occasion, MannyOccasion.fact);
      s = markBubbleShown(s, MannyOccasion.fact, kToday);
      expect(nextBubble(s, at(9)), isNull);
      expect(
        nextBubble(s, at(9, kToday.addDays(1)))!.occasion,
        MannyOccasion.fact,
      );
    });

    test('Fakt nur beim ersten Besuch: nicht mehr, wenn heute schon eine Blase kam', () {
      final AppState s = markBubbleShown(
        withStreak(2),
        MannyOccasion.streakDanger,
        kToday,
      );
      expect(nextBubble(s, at(21)), isNull);
    });

    test('Fakt nicht nach Training', () {
      final AppState s = onboardedState().copyWith(
        day: onboardedState().day.copyWith(done: true),
      );
      expect(nextBubble(s, at(9)), isNull);
    });

    test(
      'Neustart-Nachricht: gezeigt → Flag weg; nicht gezeigte bleibt fällig',
      () {
        AppState s = onboardedState().copyWith(
          streak: const StreakState(resetNoticePending: true),
        );
        // Nicht gezeigt: am Folgetag weiterhin fällig.
        expect(
          nextBubble(s, at(10, kToday.addDays(1)))!.occasion,
          MannyOccasion.restart,
        );
        s = markBubbleShown(s, MannyOccasion.restart, kToday);
        expect(s.streak.resetNoticePending, isFalse);
        expect(
          nextBubble(s, at(10, kToday.addDays(1)))!.occasion,
          MannyOccasion.fact,
        );
      },
    );
  });

  group('Feier', () {
    test('nicht während des Rückgängig-Fensters, danach sofort', () {
      final AppState s = applyTraining(withStreak(2), kToday).state;
      expect(nextBubble(s, at(10), undoWindowOpen: true), isNull);
      final BubbleDecision d = nextBubble(s, at(10))!;
      expect(d.occasion, MannyOccasion.celebration);
      expect(d.pulseUnitId, 'w5-d1');
    });

    test('nur am selben Tag (verfällt um Mitternacht)', () {
      final AppState s = applyTraining(withStreak(2), kToday).state;
      expect(
        nextBubble(s, at(0, kToday.addDays(1)))?.occasion,
        isNot(MannyOccasion.celebration),
      );
    });

    test('nach Undo keine Feier', () {
      final TrainingApplied a = applyTraining(withStreak(2), kToday);
      final AppState u = undoTraining(a.state, a.snapshot!);
      expect(nextBubble(u, at(10))?.occasion, isNot(MannyOccasion.celebration));
    });

    test('consumeCelebration verbraucht Feier und Puls; höchstens einmal', () {
      AppState s = applyTraining(withStreak(2), kToday).state;
      s = markBubbleShown(s, MannyOccasion.celebration, kToday);
      s = consumeCelebration(s);
      expect(s.celebration, isNull);
      expect(s.path.pulsePending, isNull);
      expect(consumeCelebration(s), s);
      expect(nextBubble(s, at(10)), isNull);
    });
  });
}
